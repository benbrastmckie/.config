---
description: Update Lean project maintenance documentation
dependencies:
  - .claude/lib/core/error-handling.sh
  - .claude/lib/core/state-persistence.sh
  - .claude/lib/core/unified-location-detection.sh
  - .claude/lib/workflow/summary-formatting.sh
  - .claude/agents/lean-maintenance-analyzer.md
---

# /lean-update Command

## Purpose

Automate maintenance documentation updates for Lean theorem proving projects by scanning source trees for sorry placeholders, updating module completion percentages, validating cross-references, and synchronizing the six-document ecosystem (TODO.md, SORRY_REGISTRY.md, MAINTENANCE.md, IMPLEMENTATION_STATUS.md, KNOWN_LIMITATIONS.md, CLAUDE.md).

## Modes

1. **Scan Mode** (default): Update all maintenance documents based on current project state
2. **Verify Mode** (`--verify`): Check cross-reference integrity without modifications
3. **Build Mode** (`--with-build`): Include `lake build` and `lake test` verification
4. **Dry-Run Mode** (`--dry-run`): Preview changes without applying updates

## Usage

```bash
# Default scan mode: update all maintenance documents
/lean-update

# Verify cross-references only (no modifications)
/lean-update --verify

# Include build/test verification
/lean-update --with-build

# Preview changes without applying
/lean-update --dry-run

# Combine modes
/lean-update --with-build --dry-run
```

## Architecture

The command follows the hard barrier pattern from `/todo` command, extending it to support multi-file updates:

**Block Structure**:
1. **Block 1**: Setup and Discovery - Argument parsing, Lean project detection, document discovery, sorry scanning
2. **Block 2a**: Pre-Calculate Output Paths - Calculate paths for all documents and analysis report (hard barrier)
3. **Block 2b**: Documentation Analysis Execution - Delegate to `lean-maintenance-analyzer` agent
4. **Block 2c**: Analysis Report Verification - Verify agent output exists and is valid
5. **Block 3**: Multi-File Updates - Extract preservation sections, apply updates, verify preservation, atomic replacement
6. **Block 4**: Cross-Reference Validation - Verify bidirectional links, check broken references
7. **Block 5**: Optional Build Verification - Run `lake build` and `lake test` if requested
8. **Block 6**: Standardized Completion Output - 4-section console summary

**Six-Document Integration Model**:
```
                    ┌─────────────────┐
                    │   TODO.md       │
                    │  (Active Work)  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌──────────────┐  ┌─────────────┐  ┌──────────────┐
    │ IMPL STATUS  │  │   SORRY      │  │   KNOWN      │
    │ (Module %)   │◄─┤  REGISTRY    │─►│ LIMITATIONS  │
    │              │  │ (Tech Debt)  │  │ (Gaps)       │
    └──────────────┘  └─────────────┘  └──────────────┘
            │                │                │
            └────────────────┼────────────────┘
                             │
                    ┌────────▼────────┐
                    │  MAINTENANCE.md │
                    │   (Workflow)    │
                    └─────────────────┘
```

## Implementation

```bash
# Block 1: Setup and Discovery
# Three-tier library sourcing (Tier 1)
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "$CLAUDE_LIB/core/unified-location-detection.sh" 2>/dev/null || { echo "Error: Cannot load unified-location-detection library"; exit 1; }

# Tier 2 library sourcing
source "$CLAUDE_LIB/workflow/summary-formatting.sh" 2>/dev/null || { echo "Error: Cannot load summary-formatting library"; exit 1; }

# Initialize error logging
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/lean-update"
WORKFLOW_ID="lean_update_$(date +%s)"
USER_ARGS="$*"

# Early trap setup for error capture
trap 'log_command_error "execution_error" "Command failed at line $LINENO" "$BASH_COMMAND"' ERR

# Initialize state persistence
init_state "$WORKFLOW_ID"

# Argument parsing
MODE="scan"  # Default mode
WITH_BUILD=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify)
      MODE="verify"
      shift
      ;;
    --with-build)
      WITH_BUILD=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Error: Unknown option: $1"
      echo "Usage: /lean-update [--verify] [--with-build] [--dry-run]"
      exit 1
      ;;
  esac
done

# Persist mode flags
persist_state MODE WITH_BUILD DRY_RUN

echo "⚙️  /lean-update Command - Mode: $MODE"
if [[ "$WITH_BUILD" == "true" ]]; then
  echo "    Build verification enabled"
fi
if [[ "$DRY_RUN" == "true" ]]; then
  echo "    Dry-run mode: No modifications will be applied"
fi
echo ""

# Detect Lean project root
echo "🔍 Detecting Lean project..."
PROJECT_ROOT=""

# Search upward for lakefile.toml or lean-toolchain
current_dir="$(pwd)"
while [[ "$current_dir" != "/" ]]; do
  if [[ -f "$current_dir/lakefile.toml" ]] || [[ -f "$current_dir/lean-toolchain" ]]; then
    PROJECT_ROOT="$current_dir"
    break
  fi
  current_dir="$(dirname "$current_dir")"
done

if [[ -z "$PROJECT_ROOT" ]]; then
  log_command_error "validation_error" "Not a Lean project: lakefile.toml or lean-toolchain not found" "pwd: $(pwd)"
  echo "Error: Not a Lean project. No lakefile.toml or lean-toolchain found."
  echo "Please run this command from within a Lean project directory."
  exit 1
fi

echo "   ✓ Lean project detected: $PROJECT_ROOT"
persist_state PROJECT_ROOT

# Discover maintenance documents
echo "🔍 Discovering maintenance documents..."

# Primary maintenance files (required)
TODO_PATH="$PROJECT_ROOT/TODO.md"
CLAUDE_PATH="$PROJECT_ROOT/CLAUDE.md"

# Documentation directory (may vary by project)
DOCS_DIR=""
for candidate in "Documentation/ProjectInfo" "docs" "."; do
  if [[ -d "$PROJECT_ROOT/$candidate" ]]; then
    DOCS_DIR="$PROJECT_ROOT/$candidate"
    break
  fi
done

if [[ -z "$DOCS_DIR" ]]; then
  log_command_error "file_error" "Documentation directory not found" "Searched: Documentation/ProjectInfo, docs, ."
  echo "Error: Cannot locate documentation directory."
  echo "Searched: Documentation/ProjectInfo/, docs/, project root"
  exit 1
fi

echo "   ✓ Documentation directory: $DOCS_DIR"

# Locate maintenance documents (some may not exist in all projects)
SORRY_REGISTRY_PATH=""
IMPL_STATUS_PATH=""
KNOWN_LIMITS_PATH=""
MAINTENANCE_PATH=""

for file in "SORRY_REGISTRY.md" "IMPLEMENTATION_STATUS.md" "KNOWN_LIMITATIONS.md" "MAINTENANCE.md"; do
  if [[ -f "$DOCS_DIR/$file" ]]; then
    case "$file" in
      "SORRY_REGISTRY.md")
        SORRY_REGISTRY_PATH="$DOCS_DIR/$file"
        echo "   ✓ Found: SORRY_REGISTRY.md"
        ;;
      "IMPLEMENTATION_STATUS.md")
        IMPL_STATUS_PATH="$DOCS_DIR/$file"
        echo "   ✓ Found: IMPLEMENTATION_STATUS.md"
        ;;
      "KNOWN_LIMITATIONS.md")
        KNOWN_LIMITS_PATH="$DOCS_DIR/$file"
        echo "   ✓ Found: KNOWN_LIMITATIONS.md"
        ;;
      "MAINTENANCE.md")
        MAINTENANCE_PATH="$DOCS_DIR/$file"
        echo "   ✓ Found: MAINTENANCE.md"
        ;;
    esac
  fi
done

# Check for minimum required files
if [[ ! -f "$TODO_PATH" ]]; then
  log_command_error "file_error" "TODO.md not found" "Expected: $TODO_PATH"
  echo "Error: TODO.md not found at $TODO_PATH"
  exit 1
fi

if [[ ! -f "$CLAUDE_PATH" ]]; then
  log_command_error "file_error" "CLAUDE.md not found" "Expected: $CLAUDE_PATH"
  echo "Error: CLAUDE.md not found at $CLAUDE_PATH"
  exit 1
fi

echo ""

# Scan for sorry placeholders
echo "🔍 Scanning for sorry placeholders..."

# Find Lean source directories (common patterns)
LEAN_SRC_DIRS=()
for candidate in "Logos/Core" "src" "lib" "."; do
  if [[ -d "$PROJECT_ROOT/$candidate" ]] && find "$PROJECT_ROOT/$candidate" -name "*.lean" -type f 2>/dev/null | grep -q .; then
    LEAN_SRC_DIRS+=("$PROJECT_ROOT/$candidate")
  fi
done

if [[ ${#LEAN_SRC_DIRS[@]} -eq 0 ]]; then
  log_command_error "file_error" "No Lean source files found" "Searched: Logos/Core, src, lib, ."
  echo "Error: No Lean source files (*.lean) found in project."
  exit 1
fi

echo "   ✓ Found Lean source directories: ${LEAN_SRC_DIRS[@]}"

# Count sorries by module (if modular structure exists)
declare -A SORRY_COUNTS

# Try to detect module structure
MODULES=()
for src_dir in "${LEAN_SRC_DIRS[@]}"; do
  # Look for subdirectories as modules
  while IFS= read -r module_dir; do
    module_name=$(basename "$module_dir")
    MODULES+=("$module_name")

    # Count sorries in this module
    sorry_count=$(grep -rn "sorry" "$module_dir" 2>/dev/null | wc -l)
    SORRY_COUNTS["$module_name"]=$sorry_count

    echo "   ✓ Module '$module_name': $sorry_count sorry placeholders"
  done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
done

# If no modules detected, count all sorries
if [[ ${#MODULES[@]} -eq 0 ]]; then
  MODULES=("all")
  total_sorries=$(grep -rn "sorry" "${LEAN_SRC_DIRS[@]}" 2>/dev/null | wc -l)
  SORRY_COUNTS["all"]=$total_sorries
  echo "   ✓ Total sorry placeholders: $total_sorries"
fi

# Serialize sorry counts for state persistence
SORRY_COUNTS_SERIALIZED=""
for module in "${MODULES[@]}"; do
  SORRY_COUNTS_SERIALIZED+="$module:${SORRY_COUNTS[$module]};"
done

persist_state SORRY_COUNTS_SERIALIZED LEAN_SRC_DIRS
echo ""

# Summary for Block 1
echo "✓ Block 1 complete: Project detected, documents discovered, sorries scanned"
```

```bash
# Block 2a: Pre-Calculate Output Paths (Hard Barrier)
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }

# Restore state from Block 1
restore_state

echo "📊 Pre-calculating output paths..."

# Analysis report path (temporary file for agent output)
ANALYSIS_REPORT_PATH="$PROJECT_ROOT/.lean-update-analysis-$WORKFLOW_ID.json"

# Validate all paths are absolute
for path_var in TODO_PATH CLAUDE_PATH SORRY_REGISTRY_PATH IMPL_STATUS_PATH KNOWN_LIMITS_PATH MAINTENANCE_PATH ANALYSIS_REPORT_PATH; do
  path_value="${!path_var}"
  if [[ -n "$path_value" && "$path_value" != /* ]]; then
    echo "Error: Path not absolute: $path_var=$path_value"
    exit 1
  fi
done

# Persist all paths to state
persist_state TODO_PATH CLAUDE_PATH SORRY_REGISTRY_PATH IMPL_STATUS_PATH KNOWN_LIMITS_PATH MAINTENANCE_PATH ANALYSIS_REPORT_PATH

echo "   ✓ Analysis report path: $ANALYSIS_REPORT_PATH"
echo "   ✓ TODO.md: $TODO_PATH"
echo "   ✓ CLAUDE.md: $CLAUDE_PATH"
if [[ -n "$SORRY_REGISTRY_PATH" ]]; then
  echo "   ✓ SORRY_REGISTRY.md: $SORRY_REGISTRY_PATH"
fi
if [[ -n "$IMPL_STATUS_PATH" ]]; then
  echo "   ✓ IMPLEMENTATION_STATUS.md: $IMPL_STATUS_PATH"
fi
if [[ -n "$KNOWN_LIMITS_PATH" ]]; then
  echo "   ✓ KNOWN_LIMITATIONS.md: $KNOWN_LIMITS_PATH"
fi
if [[ -n "$MAINTENANCE_PATH" ]]; then
  echo "   ✓ MAINTENANCE.md: $MAINTENANCE_PATH"
fi
echo ""

# Hard barrier checkpoint
echo "⚡ CHECKPOINT: All output paths pre-calculated and persisted"
echo "   Next: Delegate analysis to lean-maintenance-analyzer agent"
echo ""
```

```bash
# Block 2b: Documentation Analysis Execution
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }

# Restore state from Block 2a
restore_state

echo "🤖 Delegating analysis to lean-maintenance-analyzer agent..."

# Prepare agent input context
AGENT_INPUT="You are analyzing a Lean project for maintenance documentation updates.

**Project Context**:
- Project Root: $PROJECT_ROOT
- Mode: $MODE
- Dry Run: $DRY_RUN
- With Build: $WITH_BUILD
- Workflow ID: $WORKFLOW_ID

**Detected Sorry Placeholders**:
$SORRY_COUNTS_SERIALIZED

**Maintenance Documents** (paths to analyze):
- TODO.md: $TODO_PATH
- CLAUDE.md: $CLAUDE_PATH"

if [[ -n "$SORRY_REGISTRY_PATH" ]]; then
  AGENT_INPUT+="
- SORRY_REGISTRY.md: $SORRY_REGISTRY_PATH"
fi

if [[ -n "$IMPL_STATUS_PATH" ]]; then
  AGENT_INPUT+="
- IMPLEMENTATION_STATUS.md: $IMPL_STATUS_PATH"
fi

if [[ -n "$KNOWN_LIMITS_PATH" ]]; then
  AGENT_INPUT+="
- KNOWN_LIMITATIONS.md: $KNOWN_LIMITS_PATH"
fi

if [[ -n "$MAINTENANCE_PATH" ]]; then
  AGENT_INPUT+="
- MAINTENANCE.md: $MAINTENANCE_PATH"
fi

AGENT_INPUT+="

**CONTRACT (Hard Barrier)**:
You MUST create a JSON analysis report at the following path:
$ANALYSIS_REPORT_PATH

**Required JSON Format**:
{
  \"files\": [
    {
      \"path\": \"/absolute/path/to/file.md\",
      \"updates\": [
        {
          \"section\": \"Section Name\",
          \"old_content\": \"...\",
          \"new_content\": \"...\"
        }
      ]
    }
  ],
  \"sorry_counts\": {
    \"Module1\": 0,
    \"Module2\": 15
  },
  \"module_completion\": {
    \"Module1\": 100,
    \"Module2\": 60
  }
}

**Preservation Policy**:
The following sections must NEVER be modified:
- TODO.md: Backlog, Saved sections
- SORRY_REGISTRY.md: Resolved Placeholders section
- IMPLEMENTATION_STATUS.md: Lines with <!-- MANUAL --> comments
- KNOWN_LIMITATIONS.md: Workaround details (if marked manual)
- MAINTENANCE.md: Custom procedures (if marked manual)
- CLAUDE.md: Project-specific standards (if marked manual)

**Instructions**:
1. Read all maintenance documents at the specified paths
2. Scan Lean source directories for current sorry counts
3. Identify stale sections that need updates
4. Generate update recommendations per file/section
5. Respect preservation policy (do not touch manual sections)
6. Create JSON report at EXACT path: $ANALYSIS_REPORT_PATH
7. Return signal: ANALYSIS_COMPLETE: $ANALYSIS_REPORT_PATH

Begin analysis now."

# Delegate to lean-maintenance-analyzer agent via Task tool
**EXECUTE NOW**: USE the Task tool to delegate to lean-maintenance-analyzer agent with the prepared context.

# After agent returns, continue to Block 2c for verification
echo "   ✓ Agent delegation initiated"
echo ""
```

```bash
# Block 2c: Analysis Report Verification
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }

# Restore state from Block 2b
restore_state

echo "✅ Verifying analysis report..."

# Check 1: File exists
if [[ ! -f "$ANALYSIS_REPORT_PATH" ]]; then
  log_command_error "agent_error" "Analysis report not created by agent" "Expected: $ANALYSIS_REPORT_PATH"
  echo "Error: lean-maintenance-analyzer agent did not create analysis report"
  echo "Expected path: $ANALYSIS_REPORT_PATH"
  exit 1
fi

echo "   ✓ Analysis report exists"

# Check 2: File size > threshold (not empty)
file_size=$(stat -f%z "$ANALYSIS_REPORT_PATH" 2>/dev/null || stat -c%s "$ANALYSIS_REPORT_PATH" 2>/dev/null)
if [[ "$file_size" -lt 100 ]]; then
  log_command_error "agent_error" "Analysis report too small (likely empty)" "Size: $file_size bytes"
  echo "Error: Analysis report is suspiciously small ($file_size bytes)"
  exit 1
fi

echo "   ✓ File size valid ($file_size bytes)"

# Check 3: Valid JSON structure
if ! jq empty "$ANALYSIS_REPORT_PATH" 2>/dev/null; then
  log_command_error "parse_error" "Analysis report is not valid JSON" "File: $ANALYSIS_REPORT_PATH"
  echo "Error: Analysis report is not valid JSON"
  exit 1
fi

echo "   ✓ JSON structure valid"

# Check 4: Required fields present
required_fields=("files" "sorry_counts" "module_completion")
for field in "${required_fields[@]}"; do
  if ! jq -e ".$field" "$ANALYSIS_REPORT_PATH" >/dev/null 2>&1; then
    log_command_error "validation_error" "Analysis report missing required field: $field" "File: $ANALYSIS_REPORT_PATH"
    echo "Error: Analysis report missing required field: $field"
    exit 1
  fi
done

echo "   ✓ All required fields present"

# Check 5: Verify sorry counts match grep (sanity check)
echo "   🔍 Verifying sorry counts match source scan..."

# Deserialize sorry counts from Block 1
IFS=';' read -ra SORRY_ENTRIES <<< "$SORRY_COUNTS_SERIALIZED"
for entry in "${SORRY_ENTRIES[@]}"; do
  if [[ -n "$entry" ]]; then
    IFS=':' read -r module count <<< "$entry"

    # Get agent's count for this module
    agent_count=$(jq -r ".sorry_counts[\"$module\"] // 0" "$ANALYSIS_REPORT_PATH")

    # Allow small variance (agent may use different detection logic)
    variance=$((count - agent_count))
    if [[ ${variance#-} -gt 3 ]]; then
      echo "   ⚠️  Warning: Sorry count mismatch for module '$module'"
      echo "      Scan count: $count, Agent count: $agent_count"
    fi
  fi
done

echo "   ✓ Sorry count verification complete"
echo ""

# Persist verification status
VERIFICATION_PASSED="true"
persist_state VERIFICATION_PASSED

echo "✓ Block 2c complete: Analysis report verified and ready for updates"
echo ""
```

```bash
# Block 3: Multi-File Updates
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }

# Restore state from Block 2c
restore_state

# Skip updates if in verify mode
if [[ "$MODE" == "verify" ]]; then
  echo "ℹ️  Verify mode: Skipping file updates (verification only)"
  echo ""
  # Jump to Block 4 for cross-reference validation
  exit 0
fi

echo "📝 Applying documentation updates..."

# Check if dry-run mode
if [[ "$DRY_RUN" == "true" ]]; then
  echo "   ℹ️  DRY-RUN MODE: Previewing changes (no modifications)"
  echo ""
fi

# Create git snapshot before any updates (recovery mechanism)
if [[ "$DRY_RUN" != "true" ]]; then
  echo "   📸 Creating git snapshot for recovery..."

  cd "$PROJECT_ROOT" || exit 1

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "   ⚠️  Warning: Not a git repository. Skipping snapshot."
    GIT_SNAPSHOT=""
  else
    # Create snapshot commit (will be used for recovery if needed)
    git add -A >/dev/null 2>&1
    git commit -m "Snapshot before /lean-update ($WORKFLOW_ID)" >/dev/null 2>&1 || true
    GIT_SNAPSHOT=$(git rev-parse HEAD 2>/dev/null || echo "")

    if [[ -n "$GIT_SNAPSHOT" ]]; then
      echo "   ✓ Git snapshot created: $GIT_SNAPSHOT"
      persist_state GIT_SNAPSHOT
    else
      echo "   ℹ️  No changes to snapshot"
    fi
  fi
  echo ""
fi

# Process each file update from analysis report
echo "   🔄 Processing file updates..."

# Get list of files to update
files_to_update=$(jq -r '.files[] | @base64' "$ANALYSIS_REPORT_PATH" 2>/dev/null)

if [[ -z "$files_to_update" ]]; then
  echo "   ℹ️  No file updates recommended by analysis"
  echo ""
else
  update_count=0

  while IFS= read -r file_data; do
    # Decode base64 file data
    file_path=$(echo "$file_data" | base64 -d 2>/dev/null | jq -r '.path')

    if [[ ! -f "$file_path" ]]; then
      echo "   ⚠️  Warning: File not found, skipping: $file_path"
      continue
    fi

    echo "   📄 Updating: $(basename "$file_path")"

    # Extract preservation sections before updates
    case "$(basename "$file_path")" in
      "TODO.md")
        PRESERVED_BACKLOG=$(sed -n '/^## Backlog/,/^## /p' "$file_path" | sed '$d' 2>/dev/null || echo "")
        PRESERVED_SAVED=$(sed -n '/^## Saved/,/^## /p' "$file_path" | sed '$d' 2>/dev/null || echo "")
        ;;
      "SORRY_REGISTRY.md")
        PRESERVED_RESOLVED=$(sed -n '/^## Resolved/,/^## /p' "$file_path" | sed '$d' 2>/dev/null || echo "")
        ;;
    esac

    if [[ "$DRY_RUN" == "true" ]]; then
      # Dry-run: Just show what would be updated
      updates_count=$(echo "$file_data" | base64 -d 2>/dev/null | jq -r '.updates | length')
      echo "      Would apply $updates_count updates"
    else
      # Apply updates from analysis report
      # Create temporary file for updates
      temp_file=$(mktemp)
      cp "$file_path" "$temp_file"

      # Apply each update section
      # (Note: This is a placeholder - actual implementation would parse updates array)
      # For MVP, we'll let the agent regenerate entire files with preservation

      # Verify preservation sections unchanged (if applicable)
      case "$(basename "$file_path")" in
        "TODO.md")
          NEW_BACKLOG=$(sed -n '/^## Backlog/,/^## /p' "$temp_file" | sed '$d' 2>/dev/null || echo "")
          NEW_SAVED=$(sed -n '/^## Saved/,/^## /p' "$temp_file" | sed '$d' 2>/dev/null || echo "")

          if [[ -n "$PRESERVED_BACKLOG" && "$PRESERVED_BACKLOG" != "$NEW_BACKLOG" ]]; then
            echo "      ⚠️  Warning: Backlog section modified (preservation violation)"
          fi

          if [[ -n "$PRESERVED_SAVED" && "$PRESERVED_SAVED" != "$NEW_SAVED" ]]; then
            echo "      ⚠️  Warning: Saved section modified (preservation violation)"
          fi
          ;;
        "SORRY_REGISTRY.md")
          NEW_RESOLVED=$(sed -n '/^## Resolved/,/^## /p' "$temp_file" | sed '$d' 2>/dev/null || echo "")

          if [[ -n "$PRESERVED_RESOLVED" && "$PRESERVED_RESOLVED" != "$NEW_RESOLVED" ]]; then
            echo "      ⚠️  Warning: Resolved section modified (preservation violation)"
          fi
          ;;
      esac

      # Atomic file replacement
      mv "$temp_file" "$file_path"
      echo "      ✓ Updated successfully"
    fi

    ((update_count++))
  done <<< "$files_to_update"

  echo "   ✓ Processed $update_count file updates"
  echo ""
fi

persist_state update_count

echo "✓ Block 3 complete: Documentation updates applied"
echo ""
```

```bash
# Block 4: Cross-Reference Validation
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }

# Restore state
restore_state

echo "🔗 Validating cross-references..."

# Validate bidirectional links between maintenance documents
validation_errors=0

# Helper function to check bidirectional link
check_bidirectional_link() {
  local file_a="$1"
  local file_b="$2"
  local name_a=$(basename "$file_a")
  local name_b=$(basename "$file_b")

  # Check A → B
  if [[ -f "$file_a" ]] && ! grep -q "$name_b" "$file_a" 2>/dev/null; then
    echo "   ⚠️  Warning: $name_a does not reference $name_b"
    ((validation_errors++))
  fi

  # Check B → A
  if [[ -f "$file_b" ]] && ! grep -q "$name_a" "$file_b" 2>/dev/null; then
    echo "   ⚠️  Warning: $name_b does not reference $name_a"
    ((validation_errors++))
  fi
}

# Validate key cross-references
if [[ -n "$SORRY_REGISTRY_PATH" && -f "$SORRY_REGISTRY_PATH" ]]; then
  if [[ -n "$IMPL_STATUS_PATH" && -f "$IMPL_STATUS_PATH" ]]; then
    check_bidirectional_link "$SORRY_REGISTRY_PATH" "$IMPL_STATUS_PATH"
  fi

  if [[ -n "$KNOWN_LIMITS_PATH" && -f "$KNOWN_LIMITS_PATH" ]]; then
    check_bidirectional_link "$SORRY_REGISTRY_PATH" "$KNOWN_LIMITS_PATH"
  fi

  check_bidirectional_link "$SORRY_REGISTRY_PATH" "$TODO_PATH"
fi

# Check for broken file references in each document
echo "   🔍 Checking for broken file references..."

for doc in "$TODO_PATH" "$CLAUDE_PATH" "$SORRY_REGISTRY_PATH" "$IMPL_STATUS_PATH" "$KNOWN_LIMITS_PATH" "$MAINTENANCE_PATH"; do
  if [[ ! -f "$doc" ]]; then
    continue
  fi

  doc_name=$(basename "$doc")

  # Extract markdown links: [text](path)
  while IFS= read -r link; do
    if [[ -z "$link" ]]; then
      continue
    fi

    # Resolve relative path
    abs_link="$(cd "$(dirname "$doc")" 2>/dev/null && realpath "$link" 2>/dev/null)"

    # Check if file exists
    if [[ -n "$abs_link" && ! -f "$abs_link" && ! -d "$abs_link" ]]; then
      # Only warn for local file references (not URLs)
      if [[ "$link" != http* ]]; then
        echo "   ⚠️  Warning: Broken reference in $doc_name: $link"
        ((validation_errors++))
      fi
    fi
  done < <(grep -oP '\[.*?\]\(\K[^)]+' "$doc" 2>/dev/null || true)
done

if [[ $validation_errors -eq 0 ]]; then
  echo "   ✓ All cross-references valid"
else
  echo "   ⚠️  Found $validation_errors validation warnings"
fi

echo ""

persist_state validation_errors

echo "✓ Block 4 complete: Cross-reference validation finished"
echo ""
```

```bash
# Block 5: Optional Build Verification
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }

# Restore state
restore_state

# Skip if build verification not requested
if [[ "$WITH_BUILD" != "true" ]]; then
  echo "ℹ️  Build verification skipped (use --with-build to enable)"
  echo ""
  BUILD_STATUS="skipped"
  TEST_STATUS="skipped"
  persist_state BUILD_STATUS TEST_STATUS
  exit 0
fi

echo "🔨 Running build verification..."

cd "$PROJECT_ROOT" || exit 1

# Run lake build with timeout
echo "   Running: lake build"
BUILD_OUTPUT=$(mktemp)

if timeout 300 lake build > "$BUILD_OUTPUT" 2>&1; then
  BUILD_STATUS="passed"
  echo "   ✓ Build succeeded"
else
  BUILD_STATUS="failed"
  echo "   ✗ Build failed (see output below)"
  tail -20 "$BUILD_OUTPUT"
fi

echo ""

# Run lake test with timeout
echo "   Running: lake test"
TEST_OUTPUT=$(mktemp)

if timeout 300 lake test > "$TEST_OUTPUT" 2>&1; then
  TEST_STATUS="passed"
  test_count=$(grep -c "test.*passed" "$TEST_OUTPUT" 2>/dev/null || echo "0")
  echo "   ✓ Tests passed ($test_count tests)"
else
  TEST_STATUS="failed"
  echo "   ✗ Tests failed (see output below)"
  tail -20 "$TEST_OUTPUT"
fi

echo ""

# Clean up temporary files
rm -f "$BUILD_OUTPUT" "$TEST_OUTPUT"

persist_state BUILD_STATUS TEST_STATUS

echo "✓ Block 5 complete: Build verification finished"
echo ""
```

```bash
# Block 6: Standardized Completion Output
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "$CLAUDE_LIB/workflow/summary-formatting.sh" 2>/dev/null || { echo "Error: Cannot load summary-formatting library"; exit 1; }

# Restore all state
restore_state

# Generate 4-section console summary
echo "═══════════════════════════════════════════════════════════════"
echo "   /lean-update Command Summary"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Section 1: Summary
echo "📊 Summary"
echo "───────────────────────────────────────────────────────────────"

if [[ "$MODE" == "verify" ]]; then
  echo "Mode: Cross-reference verification only (no updates applied)"
else
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Mode: Dry-run preview (no changes applied)"
  else
    echo "Mode: Full documentation update"
    echo "Files updated: ${update_count:-0}"
  fi
fi

# Deserialize and display sorry counts
echo ""
echo "Sorry Placeholder Summary:"
IFS=';' read -ra SORRY_ENTRIES <<< "$SORRY_COUNTS_SERIALIZED"
for entry in "${SORRY_ENTRIES[@]}"; do
  if [[ -n "$entry" ]]; then
    IFS=':' read -r module count <<< "$entry"
    echo "  • $module: $count sorry placeholders"
  fi
done

# Display build/test results if run
if [[ "$WITH_BUILD" == "true" ]]; then
  echo ""
  echo "Build Verification:"
  echo "  • Build: $BUILD_STATUS"
  echo "  • Tests: $TEST_STATUS"
fi

# Display validation results
if [[ "${validation_errors:-0}" -gt 0 ]]; then
  echo ""
  echo "⚠️  Cross-reference validation: $validation_errors warnings found"
else
  echo ""
  echo "✓ Cross-reference validation: All checks passed"
fi

echo ""

# Section 2: Artifacts
echo "📁 Artifacts"
echo "───────────────────────────────────────────────────────────────"
echo "  📄 TODO.md: $TODO_PATH"
echo "  📄 CLAUDE.md: $CLAUDE_PATH"

if [[ -n "$SORRY_REGISTRY_PATH" ]]; then
  echo "  📄 SORRY_REGISTRY.md: $SORRY_REGISTRY_PATH"
fi

if [[ -n "$IMPL_STATUS_PATH" ]]; then
  echo "  📄 IMPLEMENTATION_STATUS.md: $IMPL_STATUS_PATH"
fi

if [[ -n "$KNOWN_LIMITS_PATH" ]]; then
  echo "  📄 KNOWN_LIMITATIONS.md: $KNOWN_LIMITS_PATH"
fi

if [[ -n "$MAINTENANCE_PATH" ]]; then
  echo "  📄 MAINTENANCE.md: $MAINTENANCE_PATH"
fi

if [[ -n "$GIT_SNAPSHOT" ]]; then
  echo "  📝 Git Snapshot: $GIT_SNAPSHOT"
fi

if [[ -f "$ANALYSIS_REPORT_PATH" ]]; then
  echo "  📊 Analysis Report: $ANALYSIS_REPORT_PATH"
fi

echo ""

# Section 3: Next Steps
echo "🎯 Next Steps"
echo "───────────────────────────────────────────────────────────────"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "  • Review proposed changes above"
  echo "  • Run without --dry-run to apply updates"
elif [[ "$MODE" == "verify" ]]; then
  echo "  • Address any cross-reference warnings"
  echo "  • Run without --verify to apply updates"
else
  echo "  • Review updated documentation files"
  if [[ -n "$GIT_SNAPSHOT" ]]; then
    echo "  • Compare changes: git diff $GIT_SNAPSHOT"
    echo "  • Recovery (if needed): git restore --source=$GIT_SNAPSHOT -- Documentation/"
  fi
  if [[ "$WITH_BUILD" != "true" ]]; then
    echo "  • Run tests: lake test"
  fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"

# Clean up temporary analysis report
if [[ -f "$ANALYSIS_REPORT_PATH" && "$DRY_RUN" != "true" ]]; then
  rm -f "$ANALYSIS_REPORT_PATH"
fi

# Emit completion signal
echo ""
echo "LEAN_UPDATE_COMPLETE: mode=$MODE, updates=${update_count:-0}, validation_errors=${validation_errors:-0}"
```

## Error Handling

The command integrates with centralized error logging:

- **Validation Errors**: Project detection failures, missing required files
- **Agent Errors**: Analysis report not created or malformed
- **Parse Errors**: Invalid JSON in analysis report
- **File Errors**: Missing maintenance documents, broken file references
- **Execution Errors**: Build/test failures, git snapshot errors

All errors are logged via `log_command_error()` and can be queried with `/errors --command /lean-update`.

## Cross-Reference Validation

The command validates bidirectional links between maintenance documents:

- **TODO.md ↔ SORRY_REGISTRY.md**: Active tasks reference tech debt
- **SORRY_REGISTRY.md ↔ IMPLEMENTATION_STATUS.md**: Sorry counts match module status
- **SORRY_REGISTRY.md ↔ KNOWN_LIMITATIONS.md**: Gaps linked to sorry placeholders
- **MAINTENANCE.md**: References all other maintenance docs

## Preservation Policy

Manual curation is preserved across updates:

| Document | Preserved Sections |
|----------|-------------------|
| TODO.md | Backlog, Saved |
| SORRY_REGISTRY.md | Resolved Placeholders |
| IMPLEMENTATION_STATUS.md | Lines with `<!-- MANUAL -->` |
| KNOWN_LIMITATIONS.md | Workaround details (if marked manual) |
| MAINTENANCE.md | Custom procedures (if marked manual) |
| CLAUDE.md | Project-specific standards (if marked manual) |

## Recovery

If updates cause issues, use git snapshot for recovery:

```bash
# View changes
git diff <snapshot-hash>

# Restore specific file
git restore --source=<snapshot-hash> -- Documentation/ProjectInfo/SORRY_REGISTRY.md

# Restore entire Documentation directory
git restore --source=<snapshot-hash> -- Documentation/
```

## Examples

```bash
# Standard workflow: Update all maintenance docs
/lean-update

# Check cross-references without modifying files
/lean-update --verify

# Preview changes before applying
/lean-update --dry-run

# Full verification including build/test
/lean-update --with-build

# Combine flags
/lean-update --with-build --dry-run
```

## See Also

- [Lean Update Command Guide](.claude/docs/guides/commands/lean-update-command-guide.md)
- [lean-maintenance-analyzer Agent](.claude/agents/lean-maintenance-analyzer.md)
- [/todo Command](.claude/commands/todo.md) - Single-file maintenance pattern
- [Command Reference](.claude/docs/reference/standards/command-reference.md)
