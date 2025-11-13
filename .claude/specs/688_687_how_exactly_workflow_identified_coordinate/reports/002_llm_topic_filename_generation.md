# LLM Topic and Filename Generation Enhancement Analysis

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: LLM classification enhancements for topic and filename generation
- **Report Type**: Implementation analysis and design proposals
- **Related Reports**:
  - 687/001_workflow_identification.md
  - 687/002_research_topic_handling.md

## Executive Summary

The current LLM classifier (`classify_workflow_llm_comprehensive()`) generates **descriptive topic names** (subtopics field) but relies on **generic placeholder filenames** (`001_topic1.md`) that are later reconciled via filesystem discovery. This creates a tension between semantic topic descriptions and filesystem artifacts. This report analyzes the current implementation, identifies the disconnect between topic generation and filename allocation, and proposes three enhancement strategies: (1) **LLM-generated filenames** via separate JSON field, (2) **sanitized topic derivation** using existing `sanitize_topic_name()`, and (3) **hybrid approach** with LLM suggestions validated through sanitization.

## Findings

### 1. Current LLM Classifier Output Structure

**Function**: `classify_workflow_llm_comprehensive()` (`.claude/lib/workflow-llm-classifier.sh:99-146`)

**Current JSON Response Schema**:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": [
    "Implementation architecture",
    "Integration patterns and best practices"
  ],
  "reasoning": "User wants to understand implementation patterns"
}
```

**Field Definitions**:

| Field | Type | Purpose | Validation |
|-------|------|---------|------------|
| `workflow_type` | string | Workflow scope classification | Must be one of 5 valid scopes |
| `confidence` | float | Classification confidence (0.0-1.0) | Must be ≥0.7 threshold |
| `research_complexity` | integer | Number of research subtopics (1-4) | Must match subtopics array length |
| `subtopics` | array[string] | **Descriptive topic names** for agent prompts | Length must equal complexity |
| `reasoning` | string | Brief classification explanation | Required for diagnostics |

**Key Characteristics**:
- **Subtopics are semantic descriptions**: E.g., "Implementation architecture", not filenames
- **Length constraint**: Subtopics array must exactly match `research_complexity` (validation at line 328)
- **No filename guidance**: LLM returns human-readable descriptions, not filesystem-safe strings

**LLM Prompt Instructions** (lines 181-182):
```
"subtopics (array of descriptive subtopic names matching complexity count), ...
Subtopics should be descriptive and actionable (not generic 'Topic N')."
```

**Critical Observation**: The prompt emphasizes **descriptive names** but does not request **filename-safe alternatives**. This is by design—subtopics serve agent prompts, not filesystem operations.

---

### 2. Current Filename Generation Mechanism

#### 2.1 Generic Placeholder Allocation

**Function**: `initialize_workflow_paths()` (`.claude/lib/workflow-initialization.sh:383-408`)

**Algorithm**:
```bash
# Line 394-397: Just-in-time dynamic allocation
local -a report_paths
for i in $(seq 1 "$research_complexity"); do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done
```

**Generated Filenames**:
- Pattern: `NNN_topicN.md` where `NNN` is zero-padded number (001, 002, etc.)
- Example: `001_topic1.md`, `002_topic2.md`, `003_topic3.md`, `004_topic4.md`
- **Rationale**: Provides stable initial paths before agents create files

**Limitations**:
- **Generic naming**: `_topic1`, `_topic2` provides no semantic context
- **Filesystem pollution**: Creates expectation of placeholder filenames
- **Discovery overhead**: Requires post-research reconciliation (see section 2.3)

#### 2.2 Research-Specialist Agent File Creation

**Agent**: `research-specialist.md` (`.claude/agents/research-specialist.md`)

**Current Behavior**:
- Receives `REPORT_PATH` from invoking command (e.g., `/path/reports/001_topic1.md`)
- **Does NOT rename or override the path** - uses exact path provided
- Creates file with metadata header including topic description

**Key Constraint**: Agents follow exact paths from orchestrators (Standard 11: Imperative Agent Invocation Pattern). Agents do not have authority to override filesystem paths.

**Observation**: Currently, research-specialist creates files at generic paths like `001_topic1.md`, NOT descriptive paths like `001_implementation_architecture.md`.

**Evidence from filesystem** (bash command output):
```bash
./687_how_exactly_workflow_identified_coordinate/reports/001_workflow_identification.md
./687_how_exactly_workflow_identified_coordinate/reports/002_research_topic_handling.md
```

These are **descriptive filenames**, but investigation shows they were created by research-specialist agents that received pre-calculated descriptive paths from older code iterations, NOT from current generic placeholder system.

#### 2.3 Dynamic Discovery and Reconciliation

**Function**: Dynamic discovery in `/coordinate` (`.claude/commands/coordinate.md:685-714`)

**Algorithm**:
```bash
# Lines 689-710: Find agent-created files matching NNN_*.md pattern
DISCOVERED_REPORTS=()
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  PATTERN=$(printf '%03d' $i)
  FOUND_FILE=$(find "$REPORTS_DIR" -maxdepth 1 -name "${PATTERN}_*.md" -type f | head -1)

  if [ -n "$FOUND_FILE" ]; then
    DISCOVERED_REPORTS+=("$FOUND_FILE")
  else
    # Keep original generic path if no file discovered
    DISCOVERED_REPORTS+=("${REPORT_PATHS[$i-1]}")
  fi
done

REPORT_PATHS=("${DISCOVERED_REPORTS[@]}")
```

**Purpose**: Reconcile pre-calculated generic paths with actual agent-created filenames

**Problem**: This pattern assumes agents create files with **different names** than provided paths. But research-specialist agents use **exact paths** from prompts. This creates a circular dependency:
- Orchestrator provides `001_topic1.md` → Agent creates `001_topic1.md` → Discovery finds `001_topic1.md` → No change

**Result**: Current system generates generic filenames that persist through entire workflow.

---

### 3. Relationship Between Subtopics and Filenames

#### 3.1 Two-Tier System Architecture

**Tier 1: Semantic Layer** (`RESEARCH_TOPICS_JSON`)
- **Source**: LLM classification (`classify_workflow_llm_comprehensive()`)
- **Format**: JSON array of descriptive strings
- **Purpose**: Human-readable topic names for agent prompts
- **Example**: `["Implementation architecture", "Integration patterns"]`
- **Consumption**: Exported as `RESEARCH_TOPIC_1`, `RESEARCH_TOPIC_2`, etc. for agent prompts

**Tier 2: Filesystem Layer** (`REPORT_PATHS`)
- **Source**: Path pre-calculation (`initialize_workflow_paths()`)
- **Format**: Array of absolute file paths
- **Purpose**: Target file locations for agent outputs
- **Example**: `["/path/specs/NNN_topic/reports/001_topic1.md", ...]`
- **Consumption**: Exported as `AGENT_REPORT_PATH_1`, `AGENT_REPORT_PATH_2`, etc.

**Current Mapping** (`.claude/commands/coordinate.md:503-523`):
```bash
# Reconstruct RESEARCH_TOPICS array from JSON state
mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')

# Export variables for agent invocations
for i in $(seq 1 4); do
  topic_index=$((i-1))
  export "RESEARCH_TOPIC_${i}=${RESEARCH_TOPICS[$topic_index]}"  # Semantic name
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"            # Generic path
done
```

**Key Disconnect**: `RESEARCH_TOPIC_1` is descriptive ("Implementation architecture") but `AGENT_REPORT_PATH_1` is generic (`/path/reports/001_topic1.md`). The filename does not reflect the topic name.

#### 3.2 Agent Prompt Context Injection

**Template** (`.claude/commands/coordinate.md:537-554`):
```markdown
**Workflow-Specific Context**:
- Research Topic: $RESEARCH_TOPIC_1           # Descriptive: "Implementation architecture"
- Report Path: $AGENT_REPORT_PATH_1           # Generic: "/path/001_topic1.md"
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Complexity Level: $RESEARCH_COMPLEXITY
```

**Observation**: Agents see **both** semantic topic name and generic filepath. The semantic name guides research focus, but the generic path controls output location.

**Missed Opportunity**: Could pass **suggested filename** derived from topic name to guide agent file creation.

---

### 4. Existing Sanitization Infrastructure

#### 4.1 `sanitize_topic_name()` Function

**Location**: `.claude/lib/topic-utils.sh:60-141`

**Purpose**: Convert workflow descriptions into filesystem-safe snake_case names

**Algorithm** (8 steps):
1. **Extract path components**: Last 2-3 meaningful segments from any paths in input
2. **Remove full paths**: Strip absolute paths from description
3. **Convert to lowercase**: Normalize casing
4. **Remove filler prefixes**: Strip "research the", "analyze the", etc.
5. **Remove stopwords**: Filter 40+ common English words (the, a, an, and, or, etc.)
6. **Combine components**: Merge path segments with cleaned description
7. **Clean formatting**: Remove non-alphanumeric except underscores, collapse multiple underscores
8. **Intelligent truncation**: Preserve whole words, max 50 characters

**Examples**:
```bash
sanitize_topic_name "Research the /home/user/nvim/docs directory"
# → "nvim_docs_directory"

sanitize_topic_name "fix the token refresh bug"
# → "fix_token_refresh_bug"

sanitize_topic_name "research authentication patterns to create implementation plan"
# → "authentication_patterns_create_implementation"
```

**Key Features**:
- **Preserves action verbs**: "fix", "create", "implement" retained
- **Preserves technical terms**: "authentication", "token", "refresh" retained
- **Removes noise**: Stopwords and filler phrases eliminated
- **Filesystem-safe**: Only lowercase alphanumeric + underscores
- **Length-bounded**: Max 50 characters with intelligent word boundary truncation

**Current Usage**: Topic directory naming (`NNN_topicname/` directories)

**Potential for Reuse**: Could sanitize LLM-generated subtopics into filenames

#### 4.2 Sanitization Validation Requirements

**Character Constraints**:
- **Allowed**: `[a-z0-9_]` (lowercase alphanumeric + underscore)
- **Disallowed**: Spaces, punctuation, special characters, uppercase
- **Max length**: 50 characters (preserves whole words at boundaries)

**Uniqueness Constraints**:
- **Sequential numbering**: `NNN_` prefix ensures uniqueness (001, 002, 003, 004)
- **Collision handling**: Not required—prefix provides uniqueness
- **Idempotency**: `get_or_create_topic_number()` reuses existing topic numbers

**Validation Checklist**:
- [ ] No path separators (`/`, `\`)
- [ ] No whitespace
- [ ] No special shell characters (`$`, `*`, `?`, `&`, etc.)
- [ ] Length within filesystem limits (255 bytes for most filesystems)
- [ ] Human-readable (snake_case preferred over CamelCase or kebab-case)

---

### 5. Proposed Enhancement Strategies

#### Strategy 1: LLM-Generated Filenames (Separate JSON Field)

**Approach**: Extend LLM classifier to return both descriptive topic names AND filename-safe strings

**Modified JSON Schema**:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": [
    "Implementation architecture and design patterns",
    "Integration approach and best practices"
  ],
  "filename_slugs": [                           // NEW FIELD
    "implementation_architecture",
    "integration_approach"
  ],
  "reasoning": "User wants to research implementation details"
}
```

**LLM Prompt Enhancement** (`.claude/lib/workflow-llm-classifier.sh:181-182`):
```json
{
  "instructions": "... subtopics (array of descriptive subtopic names),
  filename_slugs (array of filesystem-safe slug versions matching subtopics count,
  using lowercase alphanumeric and underscores only, max 50 chars each,
  e.g., 'implementation_architecture' for subtopic 'Implementation Architecture'), ..."
}
```

**Validation Requirements** (`.claude/lib/workflow-llm-classifier.sh:290-332`):
```bash
# Additional validation for comprehensive classification
filename_slugs=$(echo "$llm_output" | jq -r '.filename_slugs // empty')

# Validate filename_slugs array exists
if [ -z "$filename_slugs" ]; then
  echo "ERROR: missing required field: filename_slugs" >&2
  return 1
fi

# Validate filename_slugs count matches complexity
local slugs_count
slugs_count=$(echo "$llm_output" | jq -r '.filename_slugs | length')
if [ "$slugs_count" -ne "$research_complexity" ]; then
  echo "ERROR: filename_slugs count ($slugs_count) != research_complexity ($research_complexity)" >&2
  return 1
fi

# Validate each slug is filesystem-safe (lowercase alphanumeric + underscores only)
local invalid_slugs
invalid_slugs=$(echo "$llm_output" | jq -r '.filename_slugs[]' | grep -Ev '^[a-z0-9_]+$' || true)
if [ -n "$invalid_slugs" ]; then
  echo "ERROR: invalid filename_slugs (must be lowercase alphanumeric + underscores): $invalid_slugs" >&2
  return 1
fi

# Validate slug length constraints (max 50 chars)
local long_slugs
long_slugs=$(echo "$llm_output" | jq -r '.filename_slugs[]' | awk 'length($0) > 50')
if [ -n "$long_slugs" ]; then
  echo "ERROR: filename_slugs exceed 50 character limit: $long_slugs" >&2
  return 1
fi
```

**Path Allocation Integration** (`.claude/lib/workflow-initialization.sh:394-408`):
```bash
# Extract filename slugs from classification result
local filename_slugs
if [ -n "${RESEARCH_TOPICS_JSON:-}" ]; then
  filename_slugs=$(echo "$classification_result" | jq -r '.filename_slugs // []')
fi

# Dynamic allocation with descriptive filenames
local -a report_paths
for i in $(seq 1 "$research_complexity"); do
  local slug
  slug=$(echo "$filename_slugs" | jq -r ".[$((i-1))] // \"topic${i}\"")
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_${slug}.md")
done
```

**Advantages**:
- **Semantic filenames from start**: No generic placeholders, no discovery needed
- **LLM expertise**: Leverages Claude Haiku's language understanding for slug generation
- **Single source of truth**: LLM generates both semantic names and filesystem-safe versions
- **Minimal code changes**: Primarily adds validation and extraction logic

**Disadvantages**:
- **LLM reliability risk**: If LLM generates invalid slugs (spaces, special chars), validation fails
- **Fallback complexity**: Need robust fallback when LLM slug generation fails
- **Token overhead**: Additional output field increases prompt/response size slightly
- **Confidence threshold interaction**: Slug validation failures could trigger regex fallback unnecessarily

---

#### Strategy 2: Sanitized Topic Derivation (Reuse Existing Infrastructure)

**Approach**: Apply `sanitize_topic_name()` to LLM-generated subtopics

**Algorithm**:
```bash
# Extract subtopics from LLM classification
mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')

# Generate filename slugs via sanitization
local -a filename_slugs
for topic in "${RESEARCH_TOPICS[@]}"; do
  slug=$(sanitize_topic_name "$topic")
  filename_slugs+=("$slug")
done

# Dynamic allocation with sanitized filenames
local -a report_paths
for i in $(seq 0 $((research_complexity - 1))); do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $((i+1)))_${filename_slugs[$i]}.md")
done
```

**Example Transformation**:
```
Input (LLM subtopic):  "Implementation architecture and design patterns"
Sanitization steps:
  1. Lowercase:        "implementation architecture and design patterns"
  2. Remove stopwords: "implementation architecture design patterns"
  3. Replace spaces:   "implementation_architecture_design_patterns"
  4. Truncate (50 ch): "implementation_architecture_design_patterns"
Output (filename):     "001_implementation_architecture_design_patterns.md"
```

**Integration Point** (`.claude/lib/workflow-initialization.sh:394-408`):
```bash
# Source topic utilities for sanitization
source "$SCRIPT_DIR/topic-utils.sh"

# Extract subtopics and sanitize for filenames
local -a report_paths
mapfile -t subtopics < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')

for i in $(seq 0 $((research_complexity - 1))); do
  local subtopic="${subtopics[$i]}"
  local sanitized_slug

  if [ -n "$subtopic" ]; then
    sanitized_slug=$(sanitize_topic_name "$subtopic")
  else
    sanitized_slug="topic$((i+1))"  # Fallback to generic
  fi

  report_paths+=("${topic_path}/reports/$(printf '%03d' $((i+1)))_${sanitized_slug}.md")
done
```

**Advantages**:
- **Zero LLM changes**: No prompt modification, no response schema change
- **Proven infrastructure**: `sanitize_topic_name()` already tested and reliable
- **Deterministic**: No LLM variability in slug generation
- **Simple fallback**: If topic extraction fails, fall back to generic names
- **No discovery needed**: Eliminates 685-714 reconciliation code

**Disadvantages**:
- **Less control**: Sanitization algorithm may produce non-optimal slugs
- **Truncation issues**: Long subtopics may lose semantic meaning after 50-char truncation
- **Stopword sensitivity**: Important words might be filtered (e.g., "the" in "the OAuth flow")
- **No uniqueness guarantee**: Two similar topics could produce identical slugs (though NNN_ prefix prevents collision)

---

#### Strategy 3: Hybrid Approach (LLM Suggestion + Validation Fallback)

**Approach**: LLM generates suggested slugs, sanitization validates and corrects if needed

**Algorithm**:
```bash
# Step 1: Extract LLM-suggested filename slugs (if available)
local filename_slugs_raw
filename_slugs_raw=$(echo "$classification_result" | jq -r '.filename_slugs // []')

# Step 2: Validate and sanitize each slug
local -a validated_slugs
mapfile -t raw_slugs < <(echo "$filename_slugs_raw" | jq -r '.[]')
mapfile -t subtopics < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')

for i in $(seq 0 $((research_complexity - 1))); do
  local raw_slug="${raw_slugs[$i]:-}"
  local subtopic="${subtopics[$i]:-}"
  local validated_slug

  # Validation: Check if slug is filesystem-safe
  if echo "$raw_slug" | grep -Eq '^[a-z0-9_]{1,50}$'; then
    # LLM slug is valid - use it
    validated_slug="$raw_slug"
  else
    # LLM slug invalid or missing - sanitize subtopic
    if [ -n "$subtopic" ]; then
      validated_slug=$(sanitize_topic_name "$subtopic")
    else
      validated_slug="topic$((i+1))"  # Ultimate fallback
    fi
  fi

  validated_slugs+=("$validated_slug")
done

# Step 3: Allocate paths with validated slugs
local -a report_paths
for i in $(seq 0 $((research_complexity - 1))); do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $((i+1)))_${validated_slugs[$i]}.md")
done
```

**Validation Flow**:
```
┌─────────────────────────────────────────────────────────────────┐
│ LLM Classification Result                                       │
│ {                                                               │
│   "subtopics": ["Implementation Architecture", ...],           │
│   "filename_slugs": ["implementation_architecture", ...] ←─┐   │
│ }                                                          │   │
└────────────────────────────────────────────────────────────┼───┘
                                                             │
                                      ┌──────────────────────┘
                                      ▼
                          ┌───────────────────────┐
                          │ Validate Each Slug    │
                          │ ^[a-z0-9_]{1,50}$    │
                          └───────────┬───────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼ VALID                             ▼ INVALID
          ┌──────────────────┐               ┌───────────────────┐
          │ Use LLM Slug     │               │ Sanitize Subtopic │
          │ (Preferred)      │               │ (Fallback)        │
          └─────────┬────────┘               └─────────┬─────────┘
                    │                                  │
                    └──────────────┬───────────────────┘
                                   ▼
                      ┌────────────────────────┐
                      │ Final Filename:        │
                      │ NNN_validated_slug.md  │
                      └────────────────────────┘
```

**Advantages**:
- **Best of both worlds**: LLM expertise + deterministic validation
- **Graceful degradation**: Invalid LLM slugs automatically corrected via sanitization
- **High quality defaults**: LLM likely generates good slugs most of the time
- **Zero operational risk**: Validation ensures filesystem-safe filenames always
- **Backward compatible**: If LLM doesn't return slugs, falls back to sanitization

**Disadvantages**:
- **Increased complexity**: Two-stage validation and fallback logic
- **Debugging overhead**: Need to track which slugs came from LLM vs sanitization
- **Performance**: Slight overhead from validation regex + potential sanitization calls
- **Code maintenance**: More complex error handling paths

---

### 6. Recommended Implementation Path

**Recommendation**: **Strategy 3 (Hybrid Approach)** for production implementation

**Rationale**:
1. **Reliability**: Validation ensures zero risk of invalid filenames reaching filesystem
2. **Quality**: LLM generates semantically optimal slugs when possible
3. **Resilience**: Automatic fallback to proven sanitization maintains functionality
4. **Gradual rollout**: Can test LLM slug generation quality without disrupting existing workflows
5. **Future-proof**: Easy to adjust validation rules or sanitization fallback as patterns emerge

**Implementation Phases**:

#### Phase 1: LLM Prompt Enhancement
- **File**: `.claude/lib/workflow-llm-classifier.sh:181-182`
- **Change**: Add `filename_slugs` field to instructions
- **Validation**: Add response validation for new field (lines 290-332)
- **Test cases**:
  - Valid slugs: `["auth_patterns", "integration_approach"]`
  - Invalid slugs: `["Auth Patterns!", "integration-approach"]` (trigger fallback)
  - Missing field: `null` or omitted (trigger fallback)

#### Phase 2: Validation and Fallback Logic
- **File**: `.claude/lib/workflow-initialization.sh:394-408`
- **Change**: Replace generic `_topicN` with validated slugs
- **Fallback chain**:
  1. LLM-provided slug (if valid)
  2. Sanitized subtopic (if slug invalid)
  3. Generic `topicN` (if both fail)
- **Logging**: Debug log which strategy produced each filename

#### Phase 3: Remove Discovery Reconciliation
- **File**: `.claude/commands/coordinate.md:685-714`
- **Change**: Remove dynamic discovery code (no longer needed)
- **Rationale**: Filenames pre-calculated correctly from start
- **Benefit**: Eliminates 30 lines of reconciliation logic

#### Phase 4: Testing and Validation
- **Test suite**: `.claude/tests/test_topic_filename_generation.sh` (new)
- **Test cases**:
  - LLM returns valid slugs → use LLM slugs
  - LLM returns invalid slugs → sanitize subtopics
  - LLM omits filename_slugs → sanitize subtopics
  - Empty/null subtopics → generic fallback
- **Integration test**: Run full `/coordinate` workflow and verify filenames

---

### 7. Example Transformations

#### Example 1: Simple Research Request

**Input**: `/coordinate "research authentication patterns"`

**LLM Classification**:
```json
{
  "workflow_type": "research-only",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": [
    "Current authentication patterns and standards",
    "Security best practices and implementation examples"
  ],
  "filename_slugs": [
    "authentication_patterns_standards",
    "security_best_practices"
  ]
}
```

**Validation Results**:
- Slug 1: `authentication_patterns_standards` ✓ Valid (matches `^[a-z0-9_]{1,50}$`)
- Slug 2: `security_best_practices` ✓ Valid

**Generated Filenames**:
```
specs/NNN_research_authentication_patterns/reports/001_authentication_patterns_standards.md
specs/NNN_research_authentication_patterns/reports/002_security_best_practices.md
```

#### Example 2: Complex Implementation Plan

**Input**: `/coordinate "implement OAuth 2.0 flow with PKCE for mobile clients"`

**LLM Classification**:
```json
{
  "workflow_type": "full-implementation",
  "confidence": 0.98,
  "research_complexity": 3,
  "subtopics": [
    "OAuth 2.0 PKCE specification and requirements",
    "Mobile client implementation patterns",
    "Testing strategies and security considerations"
  ],
  "filename_slugs": [
    "oauth_pkce_specification",
    "mobile_client_patterns",
    "testing_security"
  ]
}
```

**Validation Results**:
- All slugs valid ✓

**Generated Filenames**:
```
specs/NNN_implement_oauth_flow_pkce_mobile/reports/001_oauth_pkce_specification.md
specs/NNN_implement_oauth_flow_pkce_mobile/reports/002_mobile_client_patterns.md
specs/NNN_implement_oauth_flow_pkce_mobile/reports/003_testing_security.md
```

#### Example 3: Invalid LLM Slugs (Fallback Scenario)

**Input**: `/coordinate "fix the file upload bug with large PDFs"`

**LLM Classification** (with invalid slugs):
```json
{
  "workflow_type": "full-implementation",
  "confidence": 0.92,
  "research_complexity": 2,
  "subtopics": [
    "File upload implementation analysis",
    "Large PDF handling optimization strategies"
  ],
  "filename_slugs": [
    "File-Upload Implementation!",     // Invalid: uppercase, hyphens, special chars
    "large PDF handling"               // Invalid: spaces, uppercase
  ]
}
```

**Validation Results**:
- Slug 1: `File-Upload Implementation!` ✗ Invalid → Sanitize subtopic
  - Input: "File upload implementation analysis"
  - Sanitized: `file_upload_implementation_analysis`
- Slug 2: `large PDF handling` ✗ Invalid → Sanitize subtopic
  - Input: "Large PDF handling optimization strategies"
  - Sanitized: `large_pdf_handling_optimization_strategies`

**Generated Filenames**:
```
specs/NNN_fix_file_upload_bug_large_pdfs/reports/001_file_upload_implementation_analysis.md
specs/NNN_fix_file_upload_bug_large_pdfs/reports/002_large_pdf_handling_optimization_strategies.md
```

---

## Recommendations

### 1. Adopt Hybrid Approach for Production

**Action**: Implement Strategy 3 (LLM suggestion + validation fallback)

**Rationale**:
- **Zero operational risk**: Validation ensures filesystem-safe filenames always
- **High quality**: LLM generates semantically optimal slugs when reliable
- **Proven fallback**: `sanitize_topic_name()` provides deterministic safety net
- **Backward compatible**: Graceful degradation maintains existing workflows

**Success Criteria**:
- 100% filesystem-safe filenames (validated via regex)
- >90% LLM slug acceptance rate (measure in production logs)
- Zero file creation failures due to invalid paths
- Reduced discovery reconciliation code (eliminate lines 685-714)

### 2. Add Structured Logging for Slug Generation

**Action**: Implement debug logging to track slug generation strategies

**Logging Points**:
```bash
# When LLM slug is valid
log_slug_generation "INFO" "Using LLM-generated slug: $validated_slug (topic: $subtopic)"

# When falling back to sanitization
log_slug_generation "WARN" "Invalid LLM slug '$raw_slug', sanitizing subtopic: $subtopic → $validated_slug"

# When using ultimate fallback
log_slug_generation "ERROR" "Missing subtopic, using generic fallback: $validated_slug"
```

**Benefits**:
- Track LLM slug quality over time
- Identify patterns in failed slugs (improve prompt)
- Debug filename generation issues
- Measure hybrid strategy effectiveness

**Implementation**: Extend `.claude/lib/unified-logger.sh` with `log_slug_generation()` function

### 3. Monitor LLM Slug Acceptance Rate

**Action**: Collect metrics on how often LLM slugs pass validation

**Metrics to Track**:
- **Acceptance rate**: `valid_slugs / total_slugs`
- **Fallback rate**: `sanitized_slugs / total_slugs`
- **Generic fallback rate**: `generic_slugs / total_slugs`
- **Common failure patterns**: Invalid characters, length violations, etc.

**Target**: >90% LLM slug acceptance rate

**If acceptance < 90%**:
- Refine LLM prompt instructions (add examples, clarify constraints)
- Adjust validation regex (may be too strict)
- Improve sanitization algorithm (may be too aggressive)

### 4. Validate Against Filesystem Limits

**Action**: Add explicit filesystem constraint validation

**Validation Checks**:
```bash
# Maximum filename length (255 bytes for most filesystems)
local full_filename="${PATTERN}_${validated_slug}.md"
if [ ${#full_filename} -gt 255 ]; then
  echo "ERROR: Filename exceeds filesystem limit: $full_filename (${#full_filename} bytes)" >&2
  # Truncate slug intelligently
  validated_slug=$(echo "$validated_slug" | cut -c1-$((255 - ${#PATTERN} - 4)) | sed 's/_[^_]*$//')
fi

# Path separator injection prevention
if echo "$validated_slug" | grep -q '/'; then
  echo "ERROR: Slug contains path separator: $validated_slug" >&2
  validated_slug=$(echo "$validated_slug" | tr '/' '_')
fi
```

**Rationale**: Even with validation regex, edge cases (extremely long slugs, path injection) could occur

### 5. Deprecate Discovery Reconciliation

**Action**: Remove dynamic discovery code after hybrid approach stabilizes

**Files to Update**:
- `.claude/commands/coordinate.md:685-714` - Remove discovery block
- `.claude/commands/orchestrate.md` - Remove similar discovery patterns
- `.claude/commands/supervise.md` - Remove discovery (if present)

**Benefits**:
- **Code reduction**: ~30 lines per orchestrator
- **Simplified logic**: No reconciliation between pre-calculated and discovered paths
- **Performance**: Eliminate filesystem `find` operations
- **Maintainability**: Single source of truth for filenames

**Migration Path**:
1. Deploy hybrid approach with logging
2. Monitor for 2-4 weeks (verify 100% success rate)
3. Remove discovery code (replace with assertion that files exist at pre-calculated paths)
4. Update tests to verify no discovery needed

### 6. Document Filename Generation Logic

**Action**: Create comprehensive guide for filename generation patterns

**Documentation Structure**:
- **File**: `.claude/docs/guides/filename-generation-guide.md`
- **Sections**:
  - Overview of hybrid strategy
  - LLM slug generation rules
  - Sanitization fallback algorithm
  - Validation constraints
  - Examples and edge cases
  - Troubleshooting common issues

**Target Audience**:
- Developers extending orchestration commands
- Agent developers needing filename guidance
- Maintainers debugging filename issues

---

## References

### Primary Source Files

- **LLM Classifier**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`
  - `classify_workflow_llm_comprehensive()`: Lines 99-146
  - `build_llm_classifier_input()`: Lines 148-208
  - `parse_llm_classifier_response()`: Lines 267-379

- **Workflow Initialization**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`
  - `initialize_workflow_paths()`: Lines 168-548
  - Dynamic path allocation: Lines 383-408

- **Topic Utilities**: `/home/benjamin/.config/.claude/lib/topic-utils.sh`
  - `sanitize_topic_name()`: Lines 60-141
  - `get_or_create_topic_number()`: Lines 36-58

- **State Machine**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`
  - `sm_init()`: Lines 334-452
  - `generate_descriptive_topics_from_plans()`: Lines 214-279
  - `generate_descriptive_topics_from_description()`: Lines 281-332

- **Coordinate Command**: `/home/benjamin/.config/.claude/commands/coordinate.md`
  - Topic variable export: Lines 503-523
  - Agent invocation templates: Lines 535-623
  - Dynamic discovery: Lines 685-714

### Related Documentation

- **Existing Reports**:
  - 687/001_workflow_identification.md - Workflow classification architecture
  - 687/002_research_topic_handling.md - Topic identification and prompt construction

- **Patterns**:
  - Phase 0 Optimization: `.claude/docs/guides/phase-0-optimization.md`
  - Bash Block Execution Model: `.claude/docs/concepts/bash-block-execution-model.md`

- **Tests**:
  - `.claude/tests/test_topic_naming.sh` - Topic name sanitization tests
  - `.claude/tests/test_orchestration_commands.sh` - Orchestration integration tests

### Related Specs

- **Spec 678**: Haiku classification integration (comprehensive mode implementation)
- **Spec 687**: Workflow identification analysis (this spec series)
- **Spec 640**: Plan naming implementation (similar filename generation patterns)
