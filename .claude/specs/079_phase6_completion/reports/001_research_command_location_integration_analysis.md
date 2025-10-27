# /research Command Location Detection Integration Analysis

## Executive Summary

**Should /research be integrated with unified-location-detection.sh?** YES - Conditional High Priority

The /research command performs topic-based location detection using the EXACT same pattern as /report (topic decomposition → path calculation → subtopic file creation). Analysis reveals:

- **Current Implementation**: Uses ad-hoc utilities (topic-decomposition.sh, artifact-operations.sh) for location detection - approximately 60 lines of location logic per invocation
- **Integration Feasibility**: HIGH - /research location logic is virtually identical to /report, making it a prime candidate for unified library integration
- **Token Reduction**: Estimated 10-15% reduction via standardization (minimal AI involvement in location detection)
- **Priority**: HIGH for consistency, MEDIUM for optimization (location logic already uses utilities, not AI agents)
- **Estimated Effort**: 30-45 minutes (very similar to /report integration in Phase 1)

**Recommendation**: Integrate /research into unified location detection system as **Phase 1B** (parallel with or immediately after /report Phase 1). The commands share nearly identical location detection patterns and should be standardized together.

**Critical Finding**: /research is described in CLAUDE.md as "improved /report" using hierarchical multi-agent pattern. The two commands have parallel structures and should use the same location detection library for consistency.

## Current /research Implementation

### Location Detection Logic

The /research command (lines 77-154 in research.md) uses topic-based location detection with these steps:

**Step 1: Topic Extraction and Directory Creation** (lines 81-98)
```bash
# Extract topic from research question
TOPIC_DESC=$(extract_topic_from_question "$RESEARCH_TOPIC")

# Check for existing topics that match
EXISTING_TOPIC=$(find_matching_topic "$TOPIC_DESC")

if [ -n "$EXISTING_TOPIC" ]; then
  TOPIC_DIR="$EXISTING_TOPIC"
else
  # Create new topic directory
  TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC_DESC" ".claude/specs")
  # Creates: .claude/specs/{NNN_topic}/ with subdirectories
fi
```

**Step 2: Path Pre-Calculation for Subtopic Reports** (lines 100-154)
```bash
# MANDATORY: Calculate absolute paths for each subtopic
declare -A SUBTOPIC_REPORT_PATHS

# Create subdirectory for this research task (groups related subtopic reports)
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/$(printf "%03d" $(get_next_artifact_number "${TOPIC_DIR}/reports"))_${TOPIC_DESC}"
mkdir -p "$RESEARCH_SUBDIR"

for subtopic in "${SUBTOPICS[@]}"; do
  # Calculate next number within research subdirectory
  NEXT_NUM=$(get_next_artifact_number "$RESEARCH_SUBDIR")

  # Create absolute path
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"

  # Store in associative array
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
done
```

**Dependencies**:
- `topic-decomposition.sh`: Topic extraction and decomposition utilities
- `artifact-operations.sh`: Path calculation and artifact numbering
- `template-integration.sh`: Template loading utilities

### Key Observations

1. **Topic Directory Detection**: Identical pattern to /report (extract topic → find existing or create new → verify structure)

2. **Path Format**: Uses same topic-based structure as other commands:
   - `specs/{NNN_topic}/reports/{NNN_research}/NNN_subtopic.md`
   - `specs/{NNN_topic}/reports/{NNN_research}/OVERVIEW.md`

3. **Absolute Path Requirements**: MANDATORY absolute paths for agent delegation (lines 102-104, 136-140)

4. **Location Logic Complexity**: Approximately 60 lines of bash logic for location detection (similar to /report before Phase 1 refactoring)

5. **No AI Involvement**: Location detection uses bash utilities, not AI agents (unlike /orchestrate pre-Phase 3)

### Differences from /report

**Hierarchical Structure**:
- /research creates subdirectory: `reports/{NNN_research}/` containing multiple subtopic files
- /report creates single file: `reports/{NNN_report}.md`
- Both use same topic directory and numbering system

**Research Subdirectory Naming**:
```bash
# /research uses research-specific subdirectory
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/001_research"

# /report creates flat file
REPORT_PATH="${TOPIC_DIR}/reports/001_topic_name.md"
```

**Verification Checkpoints**:
- /research has MANDATORY VERIFICATION at lines 132-145 (verifies paths are absolute)
- Pattern matches verification-fallback.md standards

## Integration Feasibility Analysis

### Technical Compatibility

**HIGH Compatibility** with unified-location-detection.sh:

1. **Core Functions Already Available**:
   - `detect_project_root()` - /research needs this (line 93 references ".claude/specs")
   - `detect_specs_directory()` - /research needs this (determines specs/ vs .claude/specs/)
   - `sanitize_topic_name()` - /research needs this (converts research topic to topic_desc)
   - `get_next_topic_number()` - /research needs this (creates new topic directories)
   - `create_topic_structure()` - /research needs this (ensures 6 subdirectories exist)

2. **Extension Required for Hierarchical Reports**:
   - New function needed: `create_research_subdirectory(topic_path, research_name)`
   - Returns: Absolute path to research subdirectory with numbering
   - Example: `specs/082_auth/reports/001_auth_patterns/`

3. **JSON Output Integration**:
   - Current: /research uses bash variables and associative arrays
   - Target: Extract paths from `perform_location_detection()` JSON output
   - Migration: Replace ad-hoc utilities with unified library calls

### Benefits of Integration

**Consistency Gains**:
- /report, /research, /plan, /orchestrate all use same location detection logic
- Single source of truth for topic directory creation
- Standardized error handling and fallback mechanisms
- Uniform MANDATORY VERIFICATION checkpoints

**Token Reduction**:
- Estimated 10-15% reduction in /research command size
- /research currently ~575 lines, location logic ~60 lines
- Reduction: 60 lines → ~10 lines (library sourcing + function calls)
- Minimal impact on overall system tokens (already utility-based, not AI)

**Maintainability**:
- Bug fixes to location logic propagate to all commands
- Standardized subdirectory structure across all commands
- Easier testing (single library vs 4 command-specific implementations)

### Risks and Challenges

**Low Risk Integration**:

1. **Breaking Changes**: MINIMAL
   - /research location logic already uses utilities (artifact-operations.sh)
   - Migration path: Replace utility calls with unified library calls
   - Backward compatibility: Legacy utilities remain for 2 release cycles

2. **Hierarchical Structure Handling**: MINOR EXTENSION NEEDED
   - Unified library creates topic directory with 6 subdirectories
   - /research needs subdirectory WITHIN reports/ for grouped subtopics
   - Solution: Add `create_research_subdirectory()` function to unified library

3. **Path Calculation Complexity**: MINIMAL
   - /research uses nested numbering (topic number → research number → subtopic number)
   - Unified library already handles topic-level numbering
   - Extension handles research-level numbering

4. **Testing Requirements**: MEDIUM
   - Must verify hierarchical report creation works correctly
   - Test parallel subtopic file creation (5+ files per /research invocation)
   - Validate absolute paths for agent delegation

### Code Changes Required

**Unified Library Extension** (unified-location-detection.sh):

Add new function after `create_topic_structure()`:

```bash
# create_research_subdirectory(topic_path, research_name)
# Purpose: Create numbered subdirectory within topic's reports/ for hierarchical research
# Arguments:
#   $1: topic_path - Absolute path to topic directory
#   $2: research_name - Sanitized research topic name (snake_case)
# Returns: Absolute path to research subdirectory
# Creates: {topic_path}/reports/{NNN_research_name}/
#
# Usage:
#   RESEARCH_DIR=$(create_research_subdirectory "$TOPIC_PATH" "auth_patterns")
#   # Result: /path/to/specs/082_auth/reports/001_auth_patterns/
create_research_subdirectory() {
  local topic_path="$1"
  local research_name="$2"

  # Get next number in reports/ subdirectory
  local next_num
  next_num=$(ls -1d "${topic_path}/reports"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  # Handle empty directory (first research)
  if [ -z "$next_num" ]; then
    next_num="001"
  else
    next_num=$(printf "%03d" $((10#$next_num + 1)))
  fi

  # Create research subdirectory
  local research_dir="${topic_path}/reports/${next_num}_${research_name}"
  mkdir -p "$research_dir" || {
    echo "ERROR: Failed to create research subdirectory: $research_dir" >&2
    return 1
  }

  echo "$research_dir"
  return 0
}
```

**Research Command Refactoring** (research.md):

Replace lines 77-154 with unified library integration:

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Perform topic-level location detection
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "true")

# Extract topic path
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
else
  # Fallback without jq
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# MANDATORY VERIFICATION checkpoint
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - topic directory not created"
  exit 1
fi

# Create research subdirectory for hierarchical reports
RESEARCH_DIR=$(create_research_subdirectory "$TOPIC_PATH" "$TOPIC_NAME")

# MANDATORY VERIFICATION checkpoint
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research subdirectory creation failed"
  exit 1
fi

# Calculate subtopic report paths
declare -A SUBTOPIC_REPORT_PATHS

for subtopic in "${SUBTOPICS[@]}"; do
  # Calculate next number within research subdirectory
  NEXT_NUM=$(get_next_artifact_number "$RESEARCH_DIR")

  # Create absolute path
  REPORT_PATH="${RESEARCH_DIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"

  # Store in associative array
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
done

# MANDATORY VERIFICATION - All paths are absolute
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
    echo "CRITICAL ERROR: Path for '$subtopic' is not absolute: ${SUBTOPIC_REPORT_PATHS[$subtopic]}"
    exit 1
  fi
done

echo "✓ VERIFIED: All paths are absolute"
echo "✓ VERIFIED: ${#SUBTOPIC_REPORT_PATHS[@]} report paths calculated"
```

**Token Impact**: 77 lines → 45 lines (32 line reduction, ~42% reduction in location logic)

## Comparison with Other Commands

### /research vs /report

**Similarities**:
- Both use topic-based directory structure
- Both create reports in `specs/{NNN_topic}/reports/`
- Both use artifact numbering utilities
- Both use hierarchical multi-agent pattern (as of /report refactoring)
- Both require absolute paths for agent delegation
- Both have MANDATORY VERIFICATION checkpoints

**Differences**:
- /research creates subdirectory with multiple files (hierarchical)
- /report creates single file (flat)
- /research invokes 2-4 parallel research-specialist agents
- /report invokes 2-4 parallel research-specialist agents (SAME pattern)

**Critical Insight**: CLAUDE.md describes /research as "improved /report" (line 4 of research.md frontmatter). The two commands should use identical location detection logic for consistency.

### /research vs /plan

**Similarities**:
- Both use topic-based directory structure
- Both create numbered artifacts within topic subdirectories
- Both can reference research reports (cross-references)
- Both use MANDATORY VERIFICATION checkpoints

**Differences**:
- /plan creates files in `plans/` subdirectory
- /research creates files in `reports/` subdirectory
- /plan has optional research delegation (Step 0.5, lines 94-338 in plan.md)
- /research IS the research delegation

### /research vs /orchestrate

**Similarities**:
- Both orchestrate multi-agent workflows
- Both use hierarchical agent patterns
- Both create topic-based directory structures
- Both delegate to research-specialist agents

**Differences**:
- /orchestrate has 7 phases (research is phase 1)
- /orchestrate Phase 1 INVOKES /research (line 564 in orchestrate.md: "uses the SAME hierarchical multi-agent pattern")
- /orchestrate uses location-specialist agent (75.6k tokens, pre-Phase 3 refactoring)
- /research uses bash utilities (already optimized)

**Critical Finding**: /orchestrate's research phase (Phase 1) delegates to /research command. If /orchestrate is refactored to use unified location detection (Phase 3), /research MUST also be refactored to maintain consistency.

### Use Case Differences

**When to use /research**:
- Deep-dive research into specific topic with multiple subtopics
- Creating comprehensive research documentation
- Parallel investigation of 2-4 related research areas
- Standalone research not tied to immediate implementation

**When to use /report**:
- Quick research report on single topic
- Research as part of larger workflow (/orchestrate)
- Single-perspective analysis
- Research tied to immediate planning/implementation

**Location Detection Similarity**: Both commands need the SAME location logic (topic directory, numbering, structure creation). Use case differences don't affect location detection requirements.

## Recommendation

### Clear Recommendation: YES - Integrate /research

**Justification**:

1. **Technical Feasibility**: HIGH
   - Location logic nearly identical to /report
   - Unified library already provides 90% of needed functions
   - Minor extension needed (create_research_subdirectory function)
   - Estimated effort: 30-45 minutes

2. **Consistency Imperative**: HIGH
   - /research described as "improved /report" in CLAUDE.md
   - Two commands share hierarchical multi-agent pattern
   - Should use identical location detection for maintainability
   - Bug fixes propagate to both commands

3. **System-Wide Standardization**: MEDIUM-HIGH
   - /orchestrate Phase 1 invokes /research
   - /orchestrate Phase 3 refactoring uses unified library
   - /research MUST use unified library for consistency
   - Prevents location logic fragmentation

4. **Token Reduction**: LOW-MEDIUM
   - Estimated 10-15% reduction in /research command size
   - Already uses utilities (not AI agents)
   - Impact on system-wide tokens: minimal
   - Benefit: consistency > optimization

5. **Risk Assessment**: LOW
   - Migration path clear (similar to /report Phase 1)
   - Backward compatibility maintained via feature flag
   - Testing requirements straightforward
   - Rollback procedure simple

### Priority Level: HIGH (for consistency) / MEDIUM (for optimization)

**Phase Placement Recommendation**: Phase 1B (parallel with or immediately after /report)

**Rationale**:
- /report and /research are sibling commands (both create research artifacts)
- Both use hierarchical multi-agent pattern
- Both have identical location detection needs
- Should be refactored together for consistency
- Phase 1 validation gate already tests /report; extend to /research

**Alternative**: Separate mini-plan (if Phase 1B too complex)
- Create standalone plan: `002_integrate_research_command.md`
- Estimated duration: 30-45 minutes (very low complexity)
- No dependencies on other phases (can run independently)

### Implementation Approach

**Step 1: Extend Unified Library** (10-15 minutes)
- Add `create_research_subdirectory()` function to unified-location-detection.sh
- Add unit tests for research subdirectory creation
- Verify function works with existing topic structure

**Step 2: Refactor /research Command** (15-20 minutes)
- Replace lines 77-154 with unified library integration
- Source unified-location-detection.sh at command start
- Replace ad-hoc utilities with library function calls
- Maintain MANDATORY VERIFICATION checkpoints

**Step 3: Integration Testing** (10-15 minutes)
- Test /research with diverse research topics (5 test cases)
- Verify hierarchical report creation
- Verify absolute paths for agent delegation
- Verify topic structure compliance
- Test backward compatibility with existing research reports

**Step 4: Update Documentation** (5 minutes)
- Update /research command documentation
- Add unified library reference
- Update CLAUDE.md with /research integration note

**Total Estimated Effort**: 30-45 minutes (similar to /report Phase 1)

## Implementation Estimate

**Recommended Integration**: YES - Phase 1B (parallel with /report Phase 1)

**Estimated Time**: 30-45 minutes

**Breakdown**:
- Unified library extension: 10-15 minutes
- /research command refactoring: 15-20 minutes
- Integration testing: 10-15 minutes
- Documentation updates: 5 minutes

**Phase Placement**:
- **Option 1**: Phase 1B (extend Phase 1 to include /research)
  - Pro: Consistent refactoring of sibling commands
  - Pro: Single validation gate for both /report and /research
  - Pro: Leverages Phase 1 testing infrastructure
  - Con: Slightly increases Phase 1 complexity

- **Option 2**: Separate mini-plan after Phase 1
  - Pro: Keeps Phase 1 focused on /report only
  - Pro: Allows independent execution
  - Con: Requires separate validation gate
  - Con: Delays standardization of sibling commands

**Testing Requirements**:

**Unit Tests** (unified-location-detection.sh):
- Test `create_research_subdirectory()` function
- Verify research subdirectory numbering
- Verify nested directory creation
- Test edge cases (empty reports/, collision handling)

**Integration Tests** (/research command):
```bash
# Test 1: Simple research topic
/research "authentication patterns"
# Verify: specs/{NNN}_auth_patterns/reports/001_research/ created
# Verify: Subtopic reports created with correct numbering

# Test 2: Multi-word topic with special characters
/research "Research: OAuth 2.0 Security Best Practices"
# Verify: Sanitized to oauth_20_security_best_practices
# Verify: Hierarchical structure created correctly

# Test 3: Existing topic reuse
# Create specs/042_test manually, then:
/research "test topic"
# Verify: Reuses existing topic, creates 001_research/ subdirectory

# Test 4: Multiple research invocations on same topic
/research "test topic"
/research "test topic"
# Verify: Creates 001_research/ and 002_research/ subdirectories

# Test 5: Agent delegation with absolute paths
/research "complex topic requiring agent delegation"
# Verify: Agents receive absolute paths
# Verify: Reports created at correct locations
```

**Validation Criteria**:
- 5/5 integration tests pass
- Hierarchical report structure created correctly
- Absolute paths provided to agents
- No regression in existing /research functionality
- Topic structure compliance verified
- Backward compatibility maintained

**Rollback Procedure**:

If integration fails:
```bash
# Restore /research command
cp .claude/commands/research.md.backup-unified-integration .claude/commands/research.md

# Rollback unified library (if extension causes issues)
git checkout .claude/lib/unified-location-detection.sh

# Verify rollback
./.claude/tests/test_research_location.sh
# Expected: 100% pass rate with legacy implementation
```

**Success Metrics**:
- /research uses unified library for all location detection
- Code reduction: ~32 lines (42% reduction in location logic)
- Consistency: /report and /research use identical location detection
- Zero regressions in existing workflows
- Token reduction: 10-15% in /research command
- System-wide standardization: 4/4 commands use unified library (/supervise, /report, /research, /plan)
