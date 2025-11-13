# Clean-Break Requirements Analysis for Regex Fallback Removal and LLM Enhancements

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: User requirements clarification for clean-break approach to plan 001
- **Report Type**: Requirements clarification and impact analysis
- **Related Reports**:
  - [001_fallback_removal_analysis.md](001_fallback_removal_analysis.md)
  - [002_llm_topic_filename_generation.md](002_llm_topic_filename_generation.md)
- **Related Plan**: [001_fallback_removal_llm_enhancements.md](../plans/001_fallback_removal_llm_enhancements.md)

## Executive Summary

The user requests a **clean-break approach** to remove regex fallback mechanisms entirely, eliminating backwards compatibility concerns. The current plan (001) confuses two distinct concepts: (1) **regex-only mode** (intentional standalone mode for offline development) vs (2) **regex fallback mechanism** (automatic safety net when LLM fails). The user wants to remove the **fallback mechanism** from hybrid/llm-only modes while **preserving regex-only mode** as a configuration option. Additionally, the user wants LLM to return **detailed research topics** plus **filesystem-safe filename slugs** to streamline research agent prompt creation by providing both semantic descriptions and ready-to-use filenames simultaneously.

## Findings

### 1. Confusion in Current Plan: "Regex-Only Mode" vs "Regex Fallback Mechanism"

#### 1.1 Two Distinct Concepts

**Concept A: Regex Fallback Mechanism** (what user wants to REMOVE)
- **Definition**: Automatic fallback behavior invoked when LLM classification fails
- **Location**: 6 invocation points in `.claude/lib/workflow-scope-detection.sh`
- **Function**: `fallback_comprehensive_classification()` (lines 114-141)
- **Behavior**: Gracefully degrades LLM failure → regex-based classification
- **Used in modes**: `hybrid` mode (primary use), `llm-only` mode (lines 82-85, contradicts mode intention), error handlers (lines 54-57, 100-104)

**Invocation Points**:
1. Empty description validation (line 56) - ERROR handler
2. Hybrid mode LLM failure (line 76) - PRIMARY fallback use case
3. LLM-only mode failure (line 84) - CONTRADICTS llm-only semantics
4. Invalid mode configuration (line 102) - ERROR handler
5. State machine initialization (`.claude/lib/workflow-state-machine.sh:367-376`) - initialization fallback
6. *Intentional usage in regex-only mode* (line 96) - see Concept B below

**Concept B: Regex-Only Mode** (what user wants to PRESERVE)
- **Definition**: Explicit configuration option to use **only** regex classification (no LLM attempts)
- **Location**: Case statement in `classify_workflow_comprehensive()` (lines 93-97)
- **Configuration**: `WORKFLOW_CLASSIFICATION_MODE="regex-only"`
- **Use Case**: Offline development, testing, LLM API unavailable
- **Behavior**: Directly invokes `fallback_comprehensive_classification()` as the PRIMARY classifier (not a fallback)

```bash
# Line 93-97: regex-only mode (PRESERVE THIS)
regex-only)
  # Regex + heuristic only - no LLM
  log_scope_detection "regex-only" "comprehensive-fallback" ""
  fallback_comprehensive_classification "$workflow_description"
  return 0
  ;;
```

**Key Distinction**:
- **Fallback mechanism** = *automatic* safety net in hybrid/llm-only modes
- **Regex-only mode** = *intentional* primary classification method when configured

#### 1.2 Plan Confusion Analysis

**Phase 3 Task Contradiction** (lines 312-318):
```
- [ ] Delete `fallback_comprehensive_classification()` function (lines 114-141)
- [ ] Delete `classify_workflow_regex()` function (lines 212-268) - EXCEPT preserve for regex-only mode
- [ ] Preserve `regex-only` mode case (lines 93-97) for offline development
```

**Problem**: Cannot both "delete fallback_comprehensive_classification()" AND "preserve regex-only mode" because regex-only mode **calls** `fallback_comprehensive_classification()` (line 96).

**Resolution Needed**:
1. **Rename** `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()` (clarifies it's the regex-based comprehensive classifier)
2. **Preserve** this function as the implementation for regex-only mode
3. **Remove** all automatic fallback invocations in hybrid/llm-only modes (6 invocation points → 1 intentional usage in regex-only mode)
4. **Preserve** `classify_workflow_regex()` function (needed by regex-only mode)

### 2. What User Wants to Remove: Backwards Compatibility Items

#### 2.1 Hybrid Mode Automatic Fallback (REMOVE)

**Current Behavior** (lines 63-78):
```bash
hybrid)
  # Try LLM first, fallback to regex + heuristic on error/timeout/low-confidence
  local llm_result
  if llm_result=$(classify_workflow_llm_comprehensive "$workflow_description" 2>/dev/null); then
    # LLM classification succeeded - validate and return
    if echo "$llm_result" | jq -e '.workflow_type' >/dev/null 2>&1; then
      log_scope_detection "hybrid" "llm-comprehensive" "$(echo "$llm_result" | jq -r '.workflow_type')"
      echo "$llm_result"
      return 0
    fi
  fi

  # LLM failed - fallback to regex + heuristic
  log_scope_detection "hybrid" "comprehensive-fallback" ""
  fallback_comprehensive_classification "$workflow_description"
  return 0
  ;;
```

**User Requirement**: REMOVE hybrid mode entirely (lines 62-78), no backwards compatibility
- Reason: "I don't need backwards compatibility and prefer clean-break"
- Action: Delete entire case statement block
- Result: Only two modes remain: `llm-only` (default) and `regex-only` (offline/testing)

#### 2.2 LLM-Only Mode Fallback (REMOVE)

**Current Behavior** (lines 80-91):
```bash
llm-only)
  # LLM only - fail fast on errors
  if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
    echo "ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode" >&2
    fallback_comprehensive_classification "$workflow_description"  # ← CONTRADICTORY FALLBACK
    return 1
  fi
  # ...
  ;;
```

**Problem**: Mode says "llm-only" and "fail fast" but **still falls back** to regex classification (line 84)

**User Requirement**: REMOVE fallback invocation (line 84), enforce true fail-fast
- Replace with: Direct `return 1` after error message
- Result: LLM failure → immediate workflow failure with clear error message

#### 2.3 Error Handler Fallbacks (REMOVE)

**Empty Description Handler** (lines 54-57):
```bash
if [ -z "$workflow_description" ]; then
  echo "ERROR: classify_workflow_comprehensive: workflow_description parameter is empty" >&2
  fallback_comprehensive_classification "$workflow_description"  # ← User wants this removed
  return 1
fi
```

**Invalid Mode Handler** (lines 100-104):
```bash
*)
  echo "ERROR: classify_workflow_comprehensive: invalid WORKFLOW_CLASSIFICATION_MODE='$WORKFLOW_CLASSIFICATION_MODE'" >&2
  fallback_comprehensive_classification "$workflow_description"  # ← User wants this removed
  return 1
  ;;
```

**User Requirement**: REMOVE all fallback invocations, replace with direct `return 1`
- Rationale: Configuration errors should fail immediately, not silently degrade
- Follows fail-fast philosophy from CLAUDE.md

#### 2.4 State Machine Initialization Fallback (REMOVE)

**Location**: `.claude/lib/workflow-state-machine.sh:367-376`
```bash
else
  # Fallback: Use regex-only classification if comprehensive fails
  echo "WARNING: Comprehensive classification failed, falling back to regex-only mode" >&2
  WORKFLOW_SCOPE=$(classify_workflow_regex "$workflow_desc" 2>/dev/null || echo "full-implementation")
  RESEARCH_COMPLEXITY=2  # Default moderate complexity
  RESEARCH_TOPICS_JSON='["Topic 1", "Topic 2"]'
  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
fi
```

**User Requirement**: REMOVE fallback block (lines 368-376), replace with fail-fast error
- Replace with: `echo "CRITICAL ERROR: Workflow classification failed" >&2; return 1`
- Rationale: State machine initialization must succeed or workflow cannot proceed

#### 2.5 Configuration Changes (SIMPLIFY)

**Default Mode Change**:
- Current: `WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"`
- New: `WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"`
- Remove documentation/support for hybrid mode

**Valid Modes Reduced**:
- Before: `hybrid`, `llm-only`, `regex-only`
- After: `llm-only` (default), `regex-only` (offline/testing only)

#### 2.6 Migration Path Removal (SIMPLIFY)

**Current Plan Phase 7** includes migration guide (lines 553-610)
- Documents "breaking changes"
- Provides "rollback procedure" (set mode back to hybrid)
- Explains "impact" on existing workflows

**User Requirement**: Simplify migration documentation
- No need to document hybrid → llm-only migration (hybrid deleted entirely)
- Focus documentation on: llm-only (default), regex-only (explicit opt-in for offline)
- Remove "rollback to hybrid mode" instructions (mode no longer exists)

### 3. LLM Response Enhancement: Detailed Topics + Filename Slugs

#### 3.1 Current LLM Response Structure (From Report 002)

**Existing Schema**:
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

**Field Purposes**:
- `subtopics`: **Descriptive topic names** for agent prompts (human-readable, spaces allowed)
- Used to populate agent context: "Research topic: Implementation architecture"

**Problem**: Subtopics are semantic but not filesystem-safe
- Example: "Integration patterns and best practices" → filename needs to be `integration_patterns_best_practices.md`
- Current solution: Generic placeholders (`001_topic1.md`, `002_topic2.md`)

#### 3.2 User Requirement: Add Filename Slugs Field

**Enhanced Schema** (proposed by plan, user confirms):
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": [
    "Implementation architecture",
    "Integration patterns and best practices"
  ],
  "filename_slugs": [
    "implementation_architecture",
    "integration_patterns_best_practices"
  ],
  "reasoning": "User wants to understand implementation patterns"
}
```

**New Field Specification**:
- **Field Name**: `filename_slugs`
- **Type**: `array[string]`
- **Length Constraint**: Must match `research_complexity` exactly (same as subtopics)
- **Content Constraint**: Filesystem-safe slugs (lowercase alphanumeric + underscores only)
- **Validation Regex**: `^[a-z0-9_]{1,50}$` per slug
- **Purpose**: Provide ready-to-use filenames for report paths

**Dual-Purpose Design**:
1. **`subtopics`**: Human-readable descriptions for agent prompts (unchanged from current)
2. **`filename_slugs`**: Machine-readable slugs for filesystem paths (new field)

**Example Agent Prompt Enhancement**:
```bash
# Current approach (only descriptive topic)
RESEARCH_TOPIC_1="Implementation architecture"

# Enhanced approach (both descriptive + filename)
RESEARCH_TOPIC_1="Implementation architecture"
RESEARCH_SLUG_1="implementation_architecture"
REPORT_PATH_0="/path/reports/001_implementation_architecture.md"
```

**Benefit**: Research agent prompt can reference both:
- Semantic topic for context: "Research topic: Implementation architecture"
- Descriptive filename for clarity: "Report will be saved as: 001_implementation_architecture.md"

#### 3.3 Why User Wants This: Streamline Research Agent Prompt Creation

**Current Problem** (from discovery reconciliation analysis):

**Step 1**: LLM generates subtopics:
```json
["Implementation architecture", "Integration patterns"]
```

**Step 2**: Initialize workflow paths with generic placeholders:
```bash
REPORT_PATH_0="/path/reports/001_topic1.md"
REPORT_PATH_1="/path/reports/002_topic2.md"
```

**Step 3**: Research agent receives prompt:
```
Research Topic: Implementation architecture
Report Path: /path/reports/001_topic1.md  # ← DISCONNECT: topic is descriptive, filename is generic
```

**Step 4**: Agent creates file at generic path
- Agent follows exact path provided (Standard 11: Imperative Agent Invocation)
- Creates file: `001_topic1.md` (generic, not descriptive)

**Step 5**: Post-research discovery reconciliation (lines 685-714):
- Command searches for files matching `001_*.md` pattern
- Finds `001_topic1.md`
- Updates path array (but name is still generic)

**Result**: Workflow ends with generic filenames that don't convey semantic meaning

**Enhanced Solution with filename_slugs**:

**Step 1**: LLM generates subtopics + slugs:
```json
{
  "subtopics": ["Implementation architecture", "Integration patterns"],
  "filename_slugs": ["implementation_architecture", "integration_patterns"]
}
```

**Step 2**: Initialize workflow paths with descriptive filenames:
```bash
REPORT_PATH_0="/path/reports/001_implementation_architecture.md"
REPORT_PATH_1="/path/reports/002_integration_patterns.md"
```

**Step 3**: Research agent receives enhanced prompt:
```
Research Topic: Implementation architecture
Report Path: /path/reports/001_implementation_architecture.md  # ← ALIGNED: topic matches filename
```

**Step 4**: Agent creates file at descriptive path
- Creates file: `001_implementation_architecture.md` (semantic, clear)

**Step 5**: No discovery reconciliation needed (lines 685-714 can be REMOVED)
- Pre-calculated paths are correct from the start
- Eliminates ~30 lines of discovery code

**Benefits for Research Agent Prompt Creation**:
1. **Clarity**: Agent sees semantic filename matching research topic
2. **Efficiency**: No mental translation from "topic1" to actual topic
3. **Reduced complexity**: Eliminates discovery reconciliation step
4. **Better artifacts**: Filenames convey meaning (e.g., `001_implementation_architecture.md` vs `001_topic1.md`)

#### 3.4 Three-Tier Validation Strategy (From Plan Phase 2)

**Hybrid Filename Generation Approach** (Strategy 3 from report 002):

**Tier 1: Use LLM-Generated Slug (Preferred)**
- Extract `filename_slugs[i]` from LLM response
- Validate against regex: `^[a-z0-9_]{1,50}$`
- If valid → use slug directly
- Log: "Using LLM-generated slug: implementation_architecture"

**Tier 2: Sanitize Subtopic (Fallback)**
- If LLM slug invalid/missing → call `sanitize_topic_name(subtopics[i])`
- Sanitization handles: uppercase → lowercase, spaces → underscores, special chars → removed
- Validate sanitized result against same regex
- Log: "Invalid LLM slug, sanitized subtopic: implementation_architecture"

**Tier 3: Generic Fallback (Ultimate Fallback)**
- If subtopic empty/missing → use generic `topicN` pattern
- Ensures zero operational failures (always produces valid filename)
- Log: "Missing subtopic, using generic fallback: topic1"

**Zero Operational Risk Design**:
- Tier 1 (LLM) provides semantic quality (target: >90% success rate)
- Tier 2 (sanitization) provides robustness (handles LLM format errors)
- Tier 3 (generic) provides reliability (absolute safety net)

**Measurement**: Track LLM slug acceptance rate via structured logging
- Target: >90% of slugs pass Tier 1 validation
- If acceptance <90% → tune LLM prompt to improve slug quality

### 4. Items to Remove from Plan (Clean-Break Simplifications)

#### 4.1 Phase 3 Simplifications

**Current Tasks** (lines 308-320):
```
- [ ] Change WORKFLOW_CLASSIFICATION_MODE default from `hybrid` to `llm-only`
- [ ] Remove fallback call at empty description validation (lines 54-57)
- [ ] Remove fallback call in llm-only mode failure (lines 82-85)
- [ ] Delete `fallback_comprehensive_classification()` function (lines 114-141)  # ← WRONG
- [ ] Delete `classify_workflow_regex()` function (lines 212-268) - EXCEPT preserve for regex-only mode
- [ ] Preserve `regex-only` mode case (lines 93-97) for offline development
```

**Clean-Break Adjustments**:
- **Remove entire hybrid mode block** (lines 62-78) - not just "change default", delete the case
- **Rename** (don't delete) `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()`
- **Remove hybrid mode from all documentation** (not just change default, eliminate references)
- **Simplify valid modes**: Only `llm-only` and `regex-only` (2 modes, not 3)

#### 4.2 Phase 7 Simplifications (Documentation)

**Current Documentation Plan** (lines 560-610):
- Migration guide explaining hybrid → llm-only transition
- Rollback procedure (set mode back to hybrid)
- Breaking change warnings
- When to use hybrid vs llm-only vs regex-only

**Clean-Break Adjustments**:
- **Remove**: Hybrid mode documentation entirely (mode deleted)
- **Remove**: Migration from hybrid mode (no longer exists)
- **Remove**: Rollback to hybrid instructions (impossible, mode deleted)
- **Simplify**: Document only 2 modes (llm-only default, regex-only offline)
- **Focus**: Configuration guide for when to explicitly use regex-only

#### 4.3 Testing Simplifications

**Current Test Plan** (lines 499-534):
- Remove hybrid mode tests
- Remove regex-only mode tests (except preservation test)
- Add LLM failure scenario tests

**Clean-Break Adjustments**:
- **Remove**: All hybrid mode test cases (lines 499-500, not just "remove tests", remove entire test section)
- **Preserve**: Regex-only mode functional tests (ensure mode still works as primary classifier)
- **Remove**: A/B comparison tests between hybrid and other modes (hybrid deleted)
- **Add**: Tests verifying hybrid mode no longer exists (configuration error if mode=hybrid)

## Recommendations

### 1. Clarify Plan Terminology: "Remove Fallback Mechanism" vs "Preserve Regex-Only Mode"

**Action**: Update plan to clearly distinguish:
- **Remove**: Fallback *mechanism* (automatic safety net behavior)
- **Preserve**: Regex-only *mode* (intentional primary classification option)

**Implementation**:
1. **Rename function**: `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()`
   - Clarifies it's the regex-based comprehensive classifier (not just a fallback)
   - Preserves function for regex-only mode usage
   - Removes semantic confusion

2. **Remove automatic invocations**: Delete all 5 automatic fallback calls
   - Lines 56, 76, 84, 102 in workflow-scope-detection.sh
   - Lines 367-376 in workflow-state-machine.sh

3. **Preserve intentional usage**: Keep line 96 (regex-only mode case)
   - Update call to use renamed function: `classify_workflow_regex_comprehensive()`

### 2. Eliminate Hybrid Mode Entirely (Not Just Change Default)

**Action**: Remove hybrid mode as a configuration option (clean-break approach)

**Implementation Changes**:
1. **Delete hybrid mode case block** (lines 62-78) entirely
2. **Configuration**: Change default AND remove hybrid from valid modes
   ```bash
   # Before: WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"
   # After:  WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"

   # Add validation:
   case "$WORKFLOW_CLASSIFICATION_MODE" in
     llm-only|regex-only) ;;  # Valid modes
     hybrid) echo "ERROR: hybrid mode removed in clean-break update" >&2; return 1 ;;
     *) echo "ERROR: invalid mode (use llm-only or regex-only)" >&2; return 1 ;;
   esac
   ```

3. **Documentation**: Remove all hybrid mode references
   - Delete hybrid examples from user guides
   - Remove hybrid vs llm-only comparison tables
   - Document only 2 modes: llm-only (default), regex-only (offline)

4. **Tests**: Remove hybrid mode test suite
   - Delete Section 2 from test_scope_detection.sh (hybrid mode tests)
   - Add test verifying hybrid mode is rejected (configuration error)

### 3. Enhance LLM Prompt with Filename Slug Instructions

**Action**: Add `filename_slugs` field to LLM classifier prompt with specific format requirements

**Implementation** (Phase 1):
Update `.claude/lib/workflow-llm-classifier.sh:181-182`:

**Current**:
```json
"subtopics (array of descriptive subtopic names matching complexity count), ..."
```

**Enhanced**:
```json
"subtopics (array of descriptive subtopic names matching complexity count),
 filename_slugs (array of filesystem-safe slug versions of subtopics, MUST match subtopics array length exactly, use lowercase alphanumeric and underscores only, max 50 chars each, no spaces/dashes/special chars, e.g., 'implementation_architecture_patterns' for subtopic 'Implementation Architecture & Patterns'),
 ..."
```

**Validation Requirements** (add to parse function):
```bash
# Extract filename_slugs field
filename_slugs=$(echo "$llm_response" | jq -r '.filename_slugs // empty')

# Validate field exists
[ -z "$filename_slugs" ] && { echo "ERROR: LLM response missing filename_slugs field" >&2; return 1; }

# Validate count matches research_complexity
slugs_count=$(echo "$filename_slugs" | jq 'length')
[ "$slugs_count" -ne "$research_complexity" ] && { echo "ERROR: filename_slugs count ($slugs_count) != research_complexity ($research_complexity)" >&2; return 1; }

# Validate each slug format
for i in $(seq 0 $((research_complexity - 1))); do
  slug=$(echo "$filename_slugs" | jq -r ".[$i]")
  if ! echo "$slug" | grep -Eq '^[a-z0-9_]{1,50}$'; then
    echo "ERROR: Invalid filename_slug[$i]: '$slug' (must be lowercase alphanumeric + underscores, 1-50 chars)" >&2
    return 1
  fi
done
```

### 4. Implement Three-Tier Filename Validation with Logging

**Action**: Create `validate_and_generate_filename_slugs()` function in workflow-initialization.sh

**Implementation** (Phase 2):
```bash
validate_and_generate_filename_slugs() {
  local classification_result="$1"
  local research_complexity="$2"

  # Extract arrays from classification result
  local llm_slugs=$(echo "$classification_result" | jq -r '.filename_slugs // empty')
  local subtopics=$(echo "$classification_result" | jq -r '.subtopics // empty')

  local -a validated_slugs

  for i in $(seq 0 $((research_complexity - 1))); do
    # Tier 1: Try LLM-generated slug
    local llm_slug=$(echo "$llm_slugs" | jq -r ".[$i] // empty")
    if [ -n "$llm_slug" ] && echo "$llm_slug" | grep -Eq '^[a-z0-9_]{1,50}$'; then
      validated_slugs+=("$llm_slug")
      log_slug_generation "INFO" "tier1_llm" "$llm_slug" "Using LLM-generated slug"
      continue
    fi

    # Tier 2: Sanitize subtopic
    local subtopic=$(echo "$subtopics" | jq -r ".[$i] // empty")
    if [ -n "$subtopic" ]; then
      local sanitized=$(sanitize_topic_name "$subtopic")
      if [ -n "$sanitized" ] && echo "$sanitized" | grep -Eq '^[a-z0-9_]{1,50}$'; then
        validated_slugs+=("$sanitized")
        log_slug_generation "WARN" "tier2_sanitize" "$sanitized" "Invalid LLM slug, sanitized subtopic: $subtopic"
        continue
      fi
    fi

    # Tier 3: Generic fallback
    local generic="topic$((i + 1))"
    validated_slugs+=("$generic")
    log_slug_generation "ERROR" "tier3_generic" "$generic" "Missing/invalid subtopic, using generic fallback"
  done

  # Return validated slugs as JSON array
  printf '%s\n' "${validated_slugs[@]}" | jq -R . | jq -s .
}
```

**Update Path Initialization** (line 396):
```bash
# Before: report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
# After:
validated_slugs=$(validate_and_generate_filename_slugs "$classification_result" "$research_complexity")
for i in $(seq 1 "$research_complexity"); do
  slug=$(echo "$validated_slugs" | jq -r ".[$((i-1))]")
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_${slug}.md")
done
```

### 5. Remove Discovery Reconciliation Code (Phase 5)

**Action**: Delete dynamic discovery block in /coordinate (lines 685-714), replace with assertion

**Implementation**:
```bash
# Before: Dynamic discovery loop (30 lines)

# After: Simple assertion (5 lines)
# ============================================================================
# Verify Report Files Exist
# ============================================================================
# Report paths pre-calculated with validated slugs from Phase 0 classification.
# No dynamic discovery needed - files created at pre-calculated paths by agents.

for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
  report_path_var="REPORT_PATH_$i"
  report_path="${!report_path_var}"

  if [ ! -f "$report_path" ]; then
    echo "ERROR: Expected report file not found: $report_path" >&2
    echo "  Agent may have failed to create file at specified path" >&2
    return 1
  fi
done

echo "✓ All $REPORT_PATHS_COUNT report files verified at pre-calculated paths"
```

**Benefit**:
- Removes 30 lines of discovery code
- Fails fast if agent didn't create expected file
- Clearer error messages (missing file = agent failure, not path mismatch)

### 6. Simplify Phase 7 Documentation (Clean-Break Focus)

**Action**: Rewrite documentation to focus on 2-mode system (not 3-mode with migration)

**Documentation Structure**:

**File**: `.claude/docs/guides/workflow-classification-guide.md` (rename from llm-classification-pattern.md)

**Sections**:
1. **Overview**: LLM-only classification (default), regex-only for offline
2. **LLM-Only Mode**: How it works, when it fails, error handling
3. **Regex-Only Mode**: When to use (offline development, testing), limitations
4. **Filename Generation**: Dual-purpose design (subtopics + slugs), validation tiers
5. **Configuration**: WORKFLOW_CLASSIFICATION_MODE environment variable
6. **Troubleshooting**: LLM timeout, API errors, low confidence scenarios
7. **Migration from Pre-688 Systems**: Hybrid mode removed, use regex-only for offline workflows

**Remove**:
- Hybrid mode documentation
- Rollback instructions (no hybrid to roll back to)
- Comparison tables (hybrid vs llm-only vs regex-only)
- Backward compatibility notes (clean-break approach)

## References

### Code Files Analyzed

- `.claude/lib/workflow-scope-detection.sh:1-292` - Classification routing, fallback mechanism, regex classifier
- `.claude/lib/workflow-llm-classifier.sh:1-379` - LLM classifier, prompt building, response parsing
- `.claude/lib/workflow-initialization.sh:380-408` - Path allocation, generic placeholder generation
- `.claude/lib/workflow-state-machine.sh:367-376` - State machine initialization fallback
- `.claude/lib/topic-utils.sh:60-200` - Sanitization function for filename generation
- `.claude/commands/coordinate.md:685-714` - Dynamic discovery reconciliation code

### Research Reports Referenced

- [001_fallback_removal_analysis.md](001_fallback_removal_analysis.md) - Fallback mechanism architecture (6 invocation points)
- [002_llm_topic_filename_generation.md](002_llm_topic_filename_generation.md) - Current placeholder generation, three-tier validation strategy

### Implementation Plan

- [001_fallback_removal_llm_enhancements.md](../plans/001_fallback_removal_llm_enhancements.md) - 7-phase implementation plan requiring clarification
