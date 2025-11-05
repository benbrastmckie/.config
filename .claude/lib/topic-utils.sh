#!/usr/bin/env bash
# topic-utils.sh - Topic directory management utilities for .claude/ system
#
# Purpose: Deterministic topic directory creation and management
# Used by: /supervise, /orchestrate, /report, /plan commands
#
# Functions:
#   get_next_topic_number(specs_root)     - Find max topic number and increment
#   sanitize_topic_name(raw_name)         - Convert workflow description to snake_case
#   create_topic_structure(topic_path)    - Create 6 subdirectories with verification
#   find_matching_topic(topic_desc)       - Search for existing related topics (optional)

set -eo pipefail  # Match workflow-initialization.sh: removed -u for defensive variable refs

# Get the next sequential topic number in the specs directory
# Usage: get_next_topic_number "/path/to/specs"
# Returns: "001" for empty directory, or next number (e.g., "006" if max is 005)
get_next_topic_number() {
  local specs_root="$1"

  # Find all directories matching NNN_* pattern and extract numbers
  local max_num
  max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # If no topics found, start at 001
  if [ -z "$max_num" ]; then
    echo "001"
  else
    # Increment the max number (use 10# to force decimal interpretation)
    printf "%03d" $((10#$max_num + 1))
  fi
}

# Get topic number for a given topic name (idempotent - reuses existing if found)
# Usage: get_or_create_topic_number "/path/to/specs" "research_auth_patterns"
# Returns: Existing topic number if topic with matching name exists, otherwise next number
#
# This function solves the topic inconsistency issue where multiple bash blocks
# would increment the topic number on each invocation. Now it checks for existing
# topics first and reuses them if found.
get_or_create_topic_number() {
  local specs_root="$1"
  local topic_name="$2"

  # Check for existing topic with exact name match (pattern: NNN_topicname)
  local existing
  existing=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_"${topic_name}" 2>/dev/null | head -1 || echo "")

  if [ -n "$existing" ]; then
    # Extract and return the existing topic number
    basename "$existing" | sed 's/^\([0-9][0-9][0-9]\)_.*/\1/'
  else
    # No existing topic found - get next number
    get_next_topic_number "$specs_root"
  fi
}

# Sanitize a workflow description into a valid topic name
# Usage: sanitize_topic_name "Research the /home/benjamin/.config/nvim/docs directory/"
# Returns: "nvim_docs_directory"
#
# Algorithm:
#   1. Extract path components (last 2-3 meaningful segments)
#   2. Remove full paths from description
#   3. Convert to lowercase
#   4. Remove filler prefixes ("carefully research", "analyze", etc.)
#   5. Remove stopwords (preserving action verbs and technical terms)
#   6. Combine path components with cleaned description
#   7. Clean up formatting (multiple underscores, leading/trailing)
#   8. Intelligent truncation (preserve whole words, max 50 chars)
#
# Examples:
#   "Research the /home/user/nvim/docs directory" → "nvim_docs_directory"
#   "fix the token refresh bug" → "fix_token_refresh_bug"
#   "research authentication patterns to create implementation plan" → "authentication_patterns_create_implementation"
sanitize_topic_name() {
  local raw_name="$1"

  # Stopword list (40+ common English words to filter)
  local stopwords="the a an and or but to for of in on at by with from as is are was were be been being have has had do does did will would should could may might must can about through during before after above below between among into onto upon"

  # Filler prefix patterns (research context words to remove)
  local filler_prefixes="carefully research|research the|research|analyze the|investigate the|explore the|examine the"

  # Step 1: Extract path components if input contains paths
  local path_components=""
  if echo "$raw_name" | grep -qE '/[a-zA-Z0-9_\-]+/'; then
    # Extract last 2-3 meaningful path segments (skip "home", "user", common dirs)
    path_components=$(echo "$raw_name" | grep -oE '/[^/]+/[^/]+/?[^/]*/?$' | sed 's|^/||; s|/$||' | tr '/' '_')
    # Filter out common meaningless segments and config-like dirs
    path_components=$(echo "$path_components" | sed 's/home_[^_]*_//; s/usr_[^_]*_//; s/opt_[^_]*_//; s/config_//')
  fi

  # Step 2: Remove full paths and trailing words like "directory" from description
  local description=$(echo "$raw_name" | sed 's|/[^ ]*||g; s/ directory$//; s/ file$//; s/ folder$//')

  # Step 3: Convert to lowercase
  description=$(echo "$description" | tr '[:upper:]' '[:lower:]')
  path_components=$(echo "$path_components" | tr '[:upper:]' '[:lower:]')

  # Step 4: Remove filler prefixes
  description=$(echo "$description" | sed -E "s/^($filler_prefixes) //")

  # Step 5: Remove stopwords while preserving action verbs and technical terms
  local cleaned_words=""
  for word in $description; do
    # Skip if word is in stopword list
    if echo " $stopwords " | grep -qw "$word"; then
      continue
    fi
    # Keep word if it's meaningful
    if [ ${#word} -gt 2 ]; then
      cleaned_words="$cleaned_words $word"
    fi
  done

  # Step 6: Combine path components with cleaned description
  local combined=""
  if [ -n "$path_components" ]; then
    combined="${path_components}_${cleaned_words}"
  else
    combined="$cleaned_words"
  fi

  # Step 7: Clean up formatting
  combined=$(echo "$combined" | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/__*/_/g' | \
    sed 's/^_*//;s/_*$//')

  # Step 8: Intelligent truncation (preserve whole words, max 50 chars)
  if [ ${#combined} -gt 50 ]; then
    # Truncate at 50 and then trim to last complete word
    combined=$(echo "$combined" | cut -c1-50 | sed 's/_[^_]*$//')
  fi

  echo "$combined"
}

# Create the topic directory with lazy subdirectory creation
# Usage: create_topic_structure "/path/to/specs/082_topic_name"
# Creates: Only the topic root directory
# Returns: 0 on success, 1 on failure
#
# Note: Subdirectories (reports/, plans/, summaries/, debug/, scripts/, outputs/)
#       are created on-demand when files are written. This prevents empty directories.
#
# Verification: Checks that topic root directory exists after creation
create_topic_structure() {
  local topic_path="$1"

  # Create only the topic root directory
  mkdir -p "$topic_path"

  # Verification checkpoint (required by Verification and Fallback pattern)
  if [ ! -d "$topic_path" ]; then
    echo "ERROR: Failed to create topic directory: $topic_path" >&2
    return 1
  fi

  return 0
}

# Find existing topics that match a given description
# Usage: find_matching_topic "authentication patterns"
# Returns: List of matching topic directories (one per line)
#
# Optional function for future use (intelligent topic merging)
# Currently not used by /supervise Phase 0 optimization
find_matching_topic() {
  local topic_desc="$1"
  local specs_root="${2:-${CLAUDE_CONFIG}/.claude/specs}"

  # Extract keywords from description (split on spaces, lowercase)
  local keywords
  keywords=$(echo "$topic_desc" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | sort -u)

  # Search for matching directory names
  local matches=()
  while IFS= read -r topic_dir; do
    local topic_name
    topic_name=$(basename "$topic_dir" | sed 's/^[0-9][0-9][0-9]_//')

    # Check if any keyword appears in topic name
    for keyword in $keywords; do
      if [[ "$topic_name" == *"$keyword"* ]]; then
        matches+=("$topic_dir")
        break
      fi
    done
  done < <(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null || true)

  # Return matches (if any)
  if [ ${#matches[@]} -gt 0 ]; then
    printf "%s\n" "${matches[@]}"
  fi
}

# Usage examples:
#
# Example 1: Get next topic number
#   NEXT_NUM=$(get_next_topic_number "/path/to/specs")
#   echo "Next topic: $NEXT_NUM"  # Output: "083"
#
# Example 2: Sanitize topic name
#   TOPIC_NAME=$(sanitize_topic_name "Research: OAuth2 Authentication")
#   echo "Sanitized: $TOPIC_NAME"  # Output: "research_oauth2_authentication"
#
# Example 3: Create topic root (subdirectories created on-demand)
#   TOPIC_PATH="/path/to/specs/083_auth_research"
#   if create_topic_structure "$TOPIC_PATH"; then
#     echo "Topic root created successfully"
#     # Subdirectories created when files are written
#   else
#     echo "Failed to create topic root" >&2
#     exit 1
#   fi
#
# Example 4: Find matching topics
#   MATCHES=$(find_matching_topic "authentication")
#   if [ -n "$MATCHES" ]; then
#     echo "Found existing topics:"
#     echo "$MATCHES"
#   fi
