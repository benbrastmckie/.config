# Directory Naming Infrastructure Improvement Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Enhanced topic name sanitization and standards enforcement
- **Scope**: Clean-break improvements to directory naming infrastructure for all directory-creating commands
- **Estimated Phases**: 6
- **Estimated Hours**: 16-20 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 72.0
- **Research Reports**:
  - [Spec Directory Naming Analysis](../reports/001_spec_directory_naming_analysis.md)
  - [Directory Naming Infrastructure Improvement](../reports/001_directory_naming_infrastructure_improvement.md)
  - [Commands Creating Spec Directories](../reports/002_commands_creating_spec_directories.md)

## Overview

This plan implements clean-break improvements to the directory naming infrastructure used by all commands that create spec directories: `/plan`, `/research`, `/debug`, and `/optimize-claude`. The `/revise` command reuses existing directories (does not create new ones) and is not affected. Rather than renaming existing directories (38% have naming violations), we enhance the `sanitize_topic_name()` function to prevent future violations through four targeted improvements: artifact reference stripping, extended stopword filtering, reduced length limits, and enhanced documentation standards.

**Affected Commands**:
- `/plan` - Creates topic root + reports/ + plans/ subdirectories
- `/research` - Creates topic root + reports/ subdirectory only
- `/debug` - Creates topic root + reports/ + plans/ + debug/ subdirectories
- `/optimize-claude` - Creates topic root + reports/ + plans/ subdirectories (via perform_location_detection)

**Single Point of Enhancement**: All commands funnel through `sanitize_topic_name()` (via `initialize_workflow_paths()` or `perform_location_detection()`), making this function the single point of improvement for all future directory names.

**Goals**:
1. Eliminate artifact references from future topic names (e.g., `claude_planoutputmd`, `001_`, `.md`)
2. Reduce average topic name length from 42 to 30-35 characters
3. Improve semantic clarity with expanded stopword filtering
4. Document anti-patterns and best practices in directory-protocols.md
5. Achieve 95%+ standards compliance for all new directories across all directory-creating commands
6. Enable zero-disruption deployment (no existing directory changes)

**Philosophy Alignment**: Follows clean-break approach from writing-standards.md—improve infrastructure forward-looking, let legacy age out naturally, no migration burden.

## Research Summary

Research analysis (specs 856 and 862) revealed:

**Current State**:
- 27 of 69 spec directories (39%) contain naming violations
- Primary issues: artifact references (32%), excessive length (32%), verbose meta-words (30%)
- Root cause: `sanitize_topic_name()` preserves file basenames and lacks planning-context stopwords

**Commands Creating Spec Directories** (from reports 002 and 002_setup_optimize_revise_analysis):
- **Four commands create new directories**: `/plan`, `/research`, `/debug`, `/optimize-claude`
- **One command reuses existing**: `/revise` (extracts topic from existing plan path, does NOT create directories)
- **Shared infrastructure**: All funnel through `sanitize_topic_name()` (via `initialize_workflow_paths()` or `perform_location_detection()`)
- **Subdirectory patterns**:
  - `/plan`: reports/, plans/
  - `/research`: reports/ only
  - `/debug`: reports/, plans/, debug/
  - `/optimize-claude`: reports/, plans/

**Key Findings**:
- Single point of improvement: All commands use `sanitize_topic_name()` in topic-utils.sh
- Four enhancements fix 78% of violation patterns
- Performance impact: +4ms (17ms → 21ms, acceptable for human workflows)
- Clean-break approach preferred over legacy directory migration

**Recommended Approach**:
1. Enhance sanitization function with artifact stripping and expanded stopwords
2. Reduce length limit from 50 to 35 characters
3. Add anti-patterns section to directory-protocols.md
4. Create comprehensive test suite (60+ test cases)
5. Test integration with all four directory-creating commands
6. Monitor first 20 new directories post-deployment for validation

## Success Criteria

- [ ] All four sanitization enhancements implemented and tested
- [ ] Zero new directories with artifact references post-deployment
- [ ] Average topic name length ≤35 characters for new directories
- [ ] 95%+ semantic clarity rating for new topic names
- [ ] directory-protocols.md updated with anti-patterns and best practices
- [ ] 60+ unit tests passing with 100% coverage of enhancement areas
- [ ] Performance overhead ≤25% (target: 21ms total allocation time)
- [ ] Integration tests passing for all four directory-creating commands (/plan, /research, /debug, /optimize-claude)
- [ ] First 20 new directories validate standards compliance across all commands
- [ ] Zero naming-related user complaints during validation period

## Technical Design

### Architecture

**Component Hierarchy**:
```
Commands (/plan, /research, /debug) → initialize_workflow_paths()
Command (/optimize-claude) → perform_location_detection()
    ↓
sanitize_topic_name() [topic-utils.sh] - SINGLE POINT OF ENHANCEMENT
    ↓
Enhanced Pipeline:
1. strip_artifact_references() [NEW]
2. extract path components
3. remove full paths
4. lowercase conversion
5. remove filler prefixes
6. extended stopword filtering [ENHANCED]
7. format cleanup
8. intelligent truncation [REDUCED LIMIT]
    ↓
create_topic_structure() [creates topic root directory]
    ↓
Command-specific subdirectory creation:
  - /plan: mkdir -p reports/ plans/
  - /research: mkdir -p reports/
  - /debug: mkdir -p reports/ plans/ debug/
  - /optimize-claude: mkdir -p reports/ plans/ (lazy creation by agents)
```

**Infrastructure Flow** (from reports 002 and 002_setup_optimize_revise_analysis):
1. **Commands call**:
   - `/plan`, `/research`, `/debug`: `initialize_workflow_paths("$DESCRIPTION", "$WORKFLOW_SCOPE", "$COMPLEXITY", "$CLASSIFICATION")`
   - `/optimize-claude`: `perform_location_detection("$DESCRIPTION")`
2. **Path pre-calculation**: Both flows call `sanitize_topic_name()` to generate topic slug
3. **Topic number allocation**: Calls `get_or_create_topic_number()` (idempotent)
4. **Directory creation**: Calls `create_topic_structure()` to create topic root
5. **Subdirectory creation**: Commands individually create needed subdirectories

**Key Design Decisions**:
1. **No Legacy Migration**: Clean-break approach—improve forward, ignore existing directories
2. **Single Enhancement Point**: All improvements in `sanitize_topic_name()` function
3. **Universal Impact**: Enhancing one function fixes all four commands automatically
4. **Additive Changes**: New function `strip_artifact_references()`, extended stopword list
5. **Backward Compatible**: Enhanced function produces better names but maintains same interface
6. **Test-Driven**: 60+ unit tests plus integration tests for each command

### Enhancement 1: Artifact Reference Stripping

**New Function**: `strip_artifact_references()`

**Location**: topic-utils.sh, line ~141 (before `sanitize_topic_name()`)

**Implementation Pattern**:
```bash
strip_artifact_references() {
  local text="$1"

  # Remove artifact numbering patterns (001_, 002_, etc.)
  text=$(echo "$text" | sed 's/[0-9]\{3\}_//g')

  # Remove artifact directory names
  text=$(echo "$text" | sed 's/\(reports\|plans\|summaries\|debug\|scripts\|outputs\|artifacts\|backups\)_//g')

  # Remove file extensions
  text=$(echo "$text" | sed 's/\.\(md\|txt\|sh\|json\|yaml\)//g')

  # Remove common file basenames (case-insensitive)
  text=$(echo "$text" | sed 's/\b\(readme\|claude\|output\|plan\|report\|summary\)\b//gi')

  # Remove topic number references (NNN_ pattern)
  text=$(echo "$text" | sed 's/\b[0-9]\{3\}_//g')

  echo "$text"
}
```

**Integration Point**: Call in `sanitize_topic_name()` after path extraction (line 158), before lowercase conversion (line 163):
```bash
# After Step 2 (line 161)
description=$(strip_artifact_references "$description")
path_components=$(strip_artifact_references "$path_components")
# Continue with Step 3 (line 163)
```

**Impact**: Fixes 21 of 27 naming violations (78%)

### Enhancement 2: Extended Stopword List

**Location**: Line 146 (stopword list variable)

**Implementation**:
```bash
# Original 40 stopwords
local stopwords="the a an and or but to for of in on at by with from as is are was were be been being have has had do does did will would should could may might must can about through during before after above below between among into onto upon"

# Add 32 planning/command context stopwords
local planning_stopwords="create update research plan fix implement analyze review investigate explore examine identify evaluate order accordingly appropriately exactly carefully detailed comprehensive command file document directory topic spec artifact report summary which want need make ensure check verify"

# Combine
local stopwords="$stopwords $planning_stopwords"
```

**Impact**: 15-25% reduction in average name length (42 chars → 30-35 chars)

### Enhancement 3: Reduced Length Limit

**Location**: Line 198-202 (truncation logic)

**Change**:
```bash
# OLD: 50 character limit
if [ ${#combined} -gt 50 ]; then
  combined=$(echo "$combined" | cut -c1-50 | sed 's/_[^_]*$//')
fi

# NEW: 35 character limit
if [ ${#combined} -gt 35 ]; then
  combined=$(echo "$combined" | cut -c1-35 | sed 's/_[^_]*$//')
fi
```

**Rationale**: 35 chars provides adequate description while improving command-line usability

### Enhancement 4: Documentation Updates

**File**: `.claude/docs/concepts/directory-protocols.md`

**Additions**:

1. **Anti-Patterns Section** (after line 85):
   - Table showing bad patterns vs good alternatives
   - Real examples from existing directories
   - Explanation of why each pattern is problematic

2. **Best Practices Expansion** (update section at lines 1132-1180):
   - Good vs poor name comparisons
   - Target characteristics (15-35 chars, semantic terms, no artifacts)
   - Clear examples with justification

3. **Sanitization Function Reference** (new section):
   - How automatic name generation works
   - Example transformations table
   - Behavior documentation

## Implementation Phases

### Phase 1: Artifact Reference Stripping Implementation [COMPLETE]
dependencies: []

**Objective**: Add `strip_artifact_references()` function and integrate into sanitization pipeline

**Complexity**: Medium

**Tasks**:
- [x] Create `strip_artifact_references()` function in topic-utils.sh (before line 142)
- [x] Implement artifact numbering pattern removal (sed: `[0-9]\{3\}_`)
- [x] Implement artifact directory name removal (sed: reports|plans|summaries|debug|scripts|outputs|artifacts|backups)
- [x] Implement file extension removal (sed: `.md|.txt|.sh|.json|.yaml`)
- [x] Implement common basename removal (sed case-insensitive: readme|claude|output|plan|report|summary)
- [x] Implement topic reference removal (sed: `[0-9]\{3\}_` at word boundaries)
- [x] Integrate into `sanitize_topic_name()`: call after step 2 (line 161), apply to both `description` and `path_components`
- [x] Add inline comments documenting each sed pattern

**Testing**:
```bash
# Unit tests for artifact stripping patterns
.claude/tests/test_topic_name_sanitization.sh --test-category=artifact-stripping

# Verify patterns:
# "reports/001_analysis.md" → "analysis"
# ".claude/plan-output.md" → ""
# "794_001_comprehensive.md" → "comprehensive"
# "README" → ""
```

**Expected Duration**: 3 hours

### Phase 2: Extended Stopword List Implementation [COMPLETE]
dependencies: [1]

**Objective**: Expand stopword list with 32 planning/command context terms

**Complexity**: Low

**Tasks**:
- [x] Add `planning_stopwords` variable definition (line ~147, after original stopwords)
- [x] Define 32 planning context terms: create, update, research, plan, fix, implement, analyze, review, investigate, explore, examine, identify, evaluate, order, accordingly, appropriately, exactly, carefully, detailed, comprehensive, command, file, document, directory, topic, spec, artifact, report, summary, which, want, need, make, ensure, check, verify
- [x] Combine original and planning stopwords: `local stopwords="$stopwords $planning_stopwords"`
- [x] Add inline comment explaining planning context filtering
- [x] Validate existing technical terms NOT in stopword list (authentication, jwt, token, config, async, etc.)

**Testing**:
```bash
# Test stopword filtering preserves technical terms
.claude/tests/test_topic_name_sanitization.sh --test-category=stopwords

# Verify:
# "create plan to implement authentication" → "authentication"
# "research jwt token patterns" → "jwt_token_patterns"
# "carefully fix the bug in config" → "bug_config"
```

**Expected Duration**: 2 hours

### Phase 3: Length Limit Reduction [COMPLETE]
dependencies: [1, 2]

**Objective**: Reduce maximum topic name length from 50 to 35 characters

**Complexity**: Low

**Tasks**:
- [x] Modify truncation threshold at line 198: change `50` to `35`
- [x] Update truncation command at line 200: change `cut -c1-50` to `cut -c1-35`
- [x] Add comment explaining 35-char target for command-line usability
- [x] Verify word-boundary preservation logic unchanged (sed: `s/_[^_]*$//')

**Testing**:
```bash
# Test length limit enforcement
.claude/tests/test_topic_name_sanitization.sh --test-category=length-limit

# Verify:
# 35 chars exactly: preserved as-is
# 36-40 chars: truncated at word boundary
# 50+ chars: truncated to <35 chars
# Word boundaries preserved (no partial words)
```

**Expected Duration**: 1 hour

### Phase 4: Documentation Anti-Patterns and Best Practices [COMPLETE]
dependencies: []

**Objective**: Update directory-protocols.md with anti-patterns section and expanded best practices

**Complexity**: Medium

**Tasks**:
- [x] Add anti-patterns section after line 85 in directory-protocols.md
- [x] Create anti-pattern comparison table: pattern | example | problem | better alternative
- [x] Include 5 categories: artifact refs, file extensions, topic number refs, excessive length, meta-words
- [x] Add "Why These Matter" explanation section
- [x] Expand best practices section (lines 1132-1180): add good vs poor name comparisons
- [x] Add target characteristics subsection (15-35 chars, semantic terms, snake_case)
- [x] Create sanitization function reference section: how automatic generation works, example transformations table
- [x] Add 10+ before/after transformation examples

**Testing**:
```bash
# Validate documentation completeness
grep -A 50 "Anti-Patterns" .claude/docs/concepts/directory-protocols.md
grep -A 50 "Best Practices" .claude/docs/concepts/directory-protocols.md

# Verify:
# - Anti-patterns table exists with 5 categories
# - Best practices expanded with comparisons
# - Sanitization reference section exists
# - Example transformations table present
```

**Expected Duration**: 4 hours

### Phase 5: Comprehensive Test Suite [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Create 60+ unit tests covering all enhancement areas, edge cases, and integration tests for all directory-creating commands

**Complexity**: High

**Tasks**:

**Unit Tests** (topic-utils.sh function testing):
- [x] Create test file: `.claude/tests/test_topic_name_sanitization.sh`
- [x] Add test harness with categories: artifact-stripping, stopwords, length-limit, edge-cases
- [x] Implement 20 artifact stripping tests: file extensions, numbering, subdirectories, basenames, topic refs
- [x] Implement 15 extended stopword tests: planning terms filtered, technical terms preserved
- [x] Implement 10 length limit tests: 35 chars preserved, >35 truncated, word boundary preservation
- [x] Implement 15 edge case tests: empty input, only stopwords, only artifacts, all caps, special chars, unicode, very short, path-only, mixed case
- [x] Add test summary reporting: total tests, passed, failed, coverage percentage
- [x] Integrate with existing test framework (sourcing, error handling)
- [x] Add test documentation header explaining coverage areas

**Integration Tests** (command-level testing):
- [x] Create integration test file: `.claude/tests/test_directory_naming_integration.sh`
- [x] Implement /plan integration tests: 3 test cases (artifact refs, verbose description, length limit)
- [x] Implement /research integration tests: 3 test cases (artifact path, meta-words, file extensions)
- [x] Implement /debug integration tests: 3 test cases (error description, artifact reference, verbose meta-words)
- [x] Implement /optimize-claude integration tests: 2 test cases (meta-words, artifact references)
- [x] Verify subdirectory patterns: /plan (reports/, plans/), /research (reports/ only), /debug (reports/, plans/, debug/), /optimize-claude (reports/, plans/)
- [x] Add cleanup logic: remove test directories after validation

**Testing**:
```bash
# Run unit test suite
.claude/tests/test_topic_name_sanitization.sh

# Expected output:
# ========================================
# Topic Name Sanitization Test Suite
# ========================================
#
# Artifact Stripping: 20/20 passed
# Extended Stopwords: 15/15 passed
# Length Limit: 10/10 passed
# Edge Cases: 15/15 passed
#
# TOTAL: 60/60 passed (100%)

# Run integration tests
.claude/tests/test_directory_naming_integration.sh

# Expected output:
# ========================================
# Directory Naming Integration Test Suite
# ========================================
#
# /plan command: 3/3 passed
# /research command: 3/3 passed
# /debug command: 3/3 passed
# /optimize-claude command: 2/2 passed
#
# TOTAL: 11/11 passed (100%)
```

**Expected Duration**: 6 hours (increased from 5 hours to accommodate integration tests)

### Phase 6: Validation and Monitoring [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Deploy enhancements, monitor first 20 new directories across all commands, validate compliance

**Complexity**: Low

**Tasks**:
- [x] Deploy enhanced topic-utils.sh to production
- [x] Create monitoring script: `.claude/scripts/monitor_topic_naming.sh`
- [x] Implement tracking: log all new topic names created, track which command created each (plan/research/debug/optimize-claude), calculate compliance metrics
- [x] Set monitoring period: 3 weeks post-deployment
- [x] Define validation criteria: zero artifact refs, avg length ≤35 chars, 95%+ semantic clarity
- [x] Run monitoring script daily during validation period
- [x] Collect first 20 new topic directories created post-deployment (across all commands)
- [x] Analyze compliance by command: /plan directories, /research directories, /debug directories, /optimize-claude directories
- [x] Verify subdirectory patterns: /plan (reports/, plans/), /research (reports/ only), /debug (reports/, plans/, debug/), /optimize-claude (reports/, plans/)
- [x] Generate validation report: compliance rate per command, violation categories, command-specific patterns
- [x] Address any edge cases discovered during validation

**Testing**:
```bash
# Monitor new directories
.claude/scripts/monitor_topic_naming.sh --report

# Expected output:
# Topic Naming Compliance Report
# Period: 2025-11-20 to 2025-11-27
#
# New Directories: 20
# - /plan: 7 directories (35%)
# - /research: 6 directories (30%)
# - /debug: 5 directories (25%)
# - /optimize-claude: 2 directories (10%)
#
# Artifact References: 0 (0%)
# Average Length: 32.4 chars
# Length Violations (>35 chars): 0 (0%)
# Semantic Clarity: 19/20 (95%)
#
# Command-Specific Analysis:
# - /plan: 7/7 compliant (100%)
# - /research: 6/6 compliant (100%)
# - /debug: 4/5 compliant (80%) - 1 length violation
# - /optimize-claude: 2/2 compliant (100%)
#
# Subdirectory Verification:
# - /plan: reports/ + plans/ ✓
# - /research: reports/ only ✓
# - /debug: reports/ + plans/ + debug/ ✓
# - /optimize-claude: reports/ + plans/ ✓
#
# COMPLIANCE: PASS (100% artifact-free, 95% semantic, 95% overall)
```

**Expected Duration**: 3 hours + 3 weeks monitoring

## Testing Strategy

### Unit Testing

**Test Categories** (60+ tests):
1. **Artifact Stripping** (20 tests):
   - File extensions: `.md`, `.txt`, `.sh`, `.json`, `.yaml`
   - Artifact numbering: `001_`, `042_`, `999_`
   - Subdirectories: `reports_`, `plans_`, `summaries_`, `debug_`, `scripts_`, `outputs_`, `artifacts_`, `backups_`
   - Common basenames: `README`, `claude`, `output`, `plan`, `report`, `summary`
   - Topic references: `816_`, `822_`, multiple refs

2. **Extended Stopwords** (15 tests):
   - Planning terms filtered: `create`, `research`, `plan`, `implement`, `carefully`, `detailed`
   - Meta-words filtered: `command`, `file`, `document`, `directory`, `spec`, `artifact`
   - Technical terms preserved: `authentication`, `jwt`, `token`, `async`, `config`, `database`

3. **Length Limit** (10 tests):
   - Exactly 35 chars: preserved
   - 36-40 chars: truncated at word boundary
   - 50+ chars: truncated to <35
   - Word boundary preservation: no partial words

4. **Edge Cases** (15 tests):
   - Empty input
   - Only stopwords: "the a an and"
   - Only artifacts: "001_reports_readme.md"
   - All caps: "FIX JWT TOKEN BUG"
   - Special characters: "@#$%^&*()"
   - Unicode characters
   - Very short: "ab"
   - Path-only: "/home/user/.claude/lib"
   - Mixed case: "Fix JWT Token Bug"

**Test Execution**:
```bash
# Run all tests
.claude/tests/test_topic_name_sanitization.sh

# Run specific category
.claude/tests/test_topic_name_sanitization.sh --test-category=artifact-stripping

# Verbose output
.claude/tests/test_topic_name_sanitization.sh --verbose
```

### Integration Testing

**Commands to Test**: All four directory-creating commands

**1. /plan Command Integration Tests**:
```bash
# Test /plan with artifact reference in description
/plan "Research .claude/commands/README.md and update flags"
# Expected topic: NNN_commands_readme_flags_update (no 'claude', no '.md')
# Expected subdirectories: reports/, plans/

# Test /plan with verbose description
/plan "carefully create a detailed plan to implement user authentication"
# Expected topic: NNN_user_authentication (stopwords filtered)
# Expected subdirectories: reports/, plans/

# Test /plan with long description
/plan "fix the state machine transition error in build command that occurs during phase execution"
# Expected topic: NNN_state_machine_transition_error (truncated at 35 chars)
# Expected subdirectories: reports/, plans/
```

**2. /research Command Integration Tests**:
```bash
# Test /research with artifact path
/research "research reports/001_analysis.md findings"
# Expected topic: NNN_analysis_findings (no 'reports', no '001_', no '.md')
# Expected subdirectories: reports/ only (no plans/)

# Test /research with planning meta-words
/research "carefully research authentication patterns to create comprehensive analysis"
# Expected topic: NNN_authentication_patterns (stopwords filtered)
# Expected subdirectories: reports/ only

# Test /research with file extension
/research "analyze error-handling.sh patterns in lib directory"
# Expected topic: NNN_error_handling_patterns_lib (no '.sh')
# Expected subdirectories: reports/ only
```

**3. /debug Command Integration Tests**:
```bash
# Test /debug with error description
/debug "timeout errors occurring in production environment"
# Expected topic: NNN_timeout_errors_production (concise, clear)
# Expected subdirectories: reports/, plans/, debug/

# Test /debug with artifact reference
/debug "investigate 001_build_failure.md from debug/ directory"
# Expected topic: NNN_build_failure (no '001_', no '.md', no 'debug/')
# Expected subdirectories: reports/, plans/, debug/

# Test /debug with verbose meta-words
/debug "carefully examine the bug in state machine transitions"
# Expected topic: NNN_bug_state_machine_transitions (stopwords filtered)
# Expected subdirectories: reports/, plans/, debug/
```

**4. /optimize-claude Command Integration Tests**:
```bash
# Test /optimize-claude with meta-words
/optimize-claude --balanced
# Expected topic: NNN_optimize_claude_structure (stopwords filtered)
# Expected subdirectories: reports/, plans/

# Test /optimize-claude with artifact references (edge case)
# Note: /optimize-claude uses fixed description "optimize CLAUDE.md structure"
# This test validates the sanitization works correctly for the command's internal description
# Expected topic: NNN_optimize_claude_structure (no '.md', stopwords filtered)
```

### Performance Testing

**Benchmarks**:
- Baseline: 17ms (current sanitization + allocation)
- Target: ≤21ms (enhanced sanitization + allocation)
- Acceptable: ≤25ms (47% overhead max)

**Test Procedure**:
```bash
# Benchmark sanitization performance
time for i in {1..1000}; do
  sanitize_topic_name "Research the authentication patterns and create implementation plan"
done

# Expected: <10ms per call (10 seconds total for 1000 calls)
```

### Validation Testing

**Post-Deployment**:
- Monitor first 20 new directories
- Calculate compliance metrics
- Validate zero artifact references
- Check average length ≤35 chars
- Assess semantic clarity (95%+ target)

**Success Criteria**:
- 0% artifact reference rate (current: 32%)
- 32.4 avg chars (current: 42 chars)
- 95%+ semantic clarity rating
- Zero naming-related complaints

## Documentation Requirements

### Code Documentation

**Files to Update**:
1. **topic-utils.sh**:
   - Add docstring for `strip_artifact_references()` function
   - Update docstring for `sanitize_topic_name()` noting enhancements
   - Add inline comments explaining each sed pattern

**Example**:
```bash
# strip_artifact_references()
# Removes artifact references from topic name input to prevent misleading directory names
#
# Strips:
# - Artifact numbering: 001_, 002_, NNN_
# - Artifact subdirectories: reports_, plans_, summaries_, debug_, scripts_, outputs_, artifacts_, backups_
# - File extensions: .md, .txt, .sh, .json, .yaml
# - Common basenames: readme, claude, output, plan, report, summary
# - Topic references: NNN_ patterns
#
# Args:
#   $1 - Raw text containing potential artifact references
# Returns:
#   Cleaned text with artifacts removed
```

### Standards Documentation

**Files to Update**:
1. **directory-protocols.md**:
   - Add "Topic Naming Anti-Patterns" section (after line 85)
   - Expand "Best Practices" section (lines 1132-1180)
   - Add "Automatic Topic Name Generation" reference section

2. **CLAUDE.md**:
   - Update directory_protocols section reference (if needed)
   - No changes required (links to directory-protocols.md)

### Test Documentation

**Files to Create**:
1. **test_topic_name_sanitization.sh**:
   - Header explaining test suite purpose
   - Category documentation
   - Expected behavior documentation

**Example Header**:
```bash
#!/usr/bin/env bash
#
# Topic Name Sanitization Test Suite
#
# Tests the enhanced sanitize_topic_name() function with four improvement areas:
# 1. Artifact reference stripping (20 tests)
# 2. Extended stopword filtering (15 tests)
# 3. Reduced length limit (10 tests)
# 4. Edge case handling (15 tests)
#
# Usage:
#   ./test_topic_name_sanitization.sh              # Run all tests
#   ./test_topic_name_sanitization.sh --verbose    # Verbose output
#   ./test_topic_name_sanitization.sh --test-category=artifact-stripping
```

## Dependencies

### Internal Dependencies
- **topic-utils.sh**: Core sanitization function to enhance (lines 142-200)
- **workflow-initialization.sh**: Calls sanitize_topic_name() via initialize_workflow_paths() (lines 364-794)
- **unified-location-detection.sh**: Calls sanitize_topic_name() via perform_location_detection()
- **Commands Using Topic Allocation**:
  - `/plan` - Creates research-and-plan workflows (calls initialize_workflow_paths at line 222)
  - `/research` - Creates research-only workflows (calls initialize_workflow_paths at line 205)
  - `/debug` - Creates debug-only workflows (calls initialize_workflow_paths at line 411)
  - `/optimize-claude` - Creates optimization workflows (calls perform_location_detection at line 124)

### External Dependencies
- None (pure bash implementation)

### Prerequisite Knowledge
- Bash sed/grep/tr string manipulation
- Directory naming standards from directory-protocols.md
- Clean-break development philosophy from writing-standards.md
- Workflow initialization patterns from workflow-initialization.sh
- Unified location detection patterns from unified-location-detection.sh
- Command subdirectory creation patterns (plan: reports/+plans/, research: reports/, debug: reports/+plans/+debug/, optimize-claude: reports/+plans/)

## Risk Analysis

### Technical Risks

**Risk 1: Semantic Information Loss** (Medium)
- **Description**: Aggressive stopword filtering or artifact stripping removes semantic content
- **Impact**: Topic names become too generic or unclear
- **Mitigation**:
  - Comprehensive test suite validates technical terms preserved
  - 35-char limit allows adequate description
  - Validation phase monitors semantic clarity

**Risk 2: Performance Degradation** (Low)
- **Description**: Additional string processing increases allocation time
- **Impact**: Slower topic creation (17ms → 21ms estimated)
- **Mitigation**:
  - Benchmark tests validate ≤25% overhead acceptable
  - Human workflow commands tolerate 21ms easily
  - Performance testing in Phase 5

**Risk 3: Edge Case Handling** (Medium)
- **Description**: Unexpected input patterns cause sanitization failures
- **Impact**: Topic names with special chars, unicode, or edge patterns
- **Mitigation**:
  - 15 edge case tests cover unusual inputs
  - Validation phase identifies real-world edge cases
  - Graceful degradation (preserve input if sanitization fails)

### Operational Risks

**Risk 4: Command Integration Issues** (Low)
- **Description**: Enhanced naming causes unexpected behavior in /optimize-claude or other commands
- **Impact**: Commands fail to create directories or use incorrect paths
- **Mitigation**:
  - Integration tests validate all four directory-creating commands
  - Path parsing logic is robust across all commands
  - Test cases cover edge cases (short names, artifact-free names)
  - Validation phase monitors all command usage patterns

**Risk 5: User Confusion** (Low)
- **Description**: Users expect old naming patterns, confused by new shorter names
- **Impact**: Questions about topic name changes
- **Mitigation**:
  - No communication needed (clean-break, no "this changed" messaging)
  - Names are objectively better (shorter, clearer)
  - Validation phase includes user feedback collection

**Risk 6: Incomplete Testing** (Low)
- **Description**: Test suite misses important edge cases
- **Impact**: Production issues with specific input patterns
- **Mitigation**:
  - 60+ unit tests cover broad input space
  - 11 integration tests cover all four commands
  - 3-week validation period catches real-world issues
  - Monitoring script identifies violation patterns

## Rollback Procedures

### Rollback Trigger Conditions
- Semantic clarity <80% (target: 95%)
- Average length >40 chars (target: ≤35 chars)
- Artifact reference rate >10% (target: 0%)
- Performance >30ms (target: ≤21ms)

### Rollback Procedure

**Step 1: Revert topic-utils.sh**
```bash
# Restore previous version from git
cd /home/benjamin/.config
git checkout HEAD~1 .claude/lib/plan/topic-utils.sh

# Verify revert
git diff .claude/lib/plan/topic-utils.sh
```

**Step 2: Verify Commands**
```bash
# Test topic allocation with reverted function
/plan "Test rollback of topic naming changes"

# Should create topic with old naming patterns
```

**Step 3: Analyze Failure**
```bash
# Review monitoring logs
cat .claude/logs/topic_naming_monitor.log

# Identify specific failure patterns
grep "VIOLATION" .claude/logs/topic_naming_monitor.log
```

**Step 4: Iterative Fix**
- Address specific failure pattern
- Re-run test suite
- Deploy targeted fix
- Resume monitoring

## Maintenance Notes

### Post-Deployment Monitoring

**Duration**: 3 weeks (covers typical project usage)

**Monitoring Script**: `.claude/scripts/monitor_topic_naming.sh`

**Metrics to Track**:
- New directory count (total and per command)
- Command distribution (/plan, /research, /debug, /optimize-claude usage patterns)
- Artifact reference rate (target: 0%)
- Average length (target: 30-35 chars)
- Length violations >35 chars (target: 0%)
- Semantic clarity rating (target: 95%+)
- Subdirectory pattern compliance (reports/, plans/, debug/)

**Command-Specific Monitoring**:
- Track which command created each directory
- Analyze naming patterns by command (do certain commands produce better names?)
- Identify command-specific edge cases
- Validate subdirectory creation: /plan (reports/+plans/), /research (reports/), /debug (reports/+plans/+debug/), /optimize-claude (reports/+plans/)

**Monitoring Frequency**: Daily logs, weekly summary reports

### Iterative Improvements

**Based on Validation Findings**:
1. Identify violation patterns in new directories
2. Analyze root causes (missing stopword, incomplete artifact pattern, etc.)
3. Add test case for violation pattern
4. Implement targeted fix
5. Re-run test suite
6. Deploy fix
7. Continue monitoring

**Example Iteration**:
- **Finding**: New directory `NNN_backend_api_development` (25 chars, clear)
- **Analysis**: "backend" and "api" preserved correctly, "development" stopword not filtered
- **Action**: Add "development" to planning_stopwords if pattern repeats

### Long-Term Maintenance

**Quarterly Review**:
- Analyze topic naming trends
- Identify new artifact patterns
- Update stopword list if needed
- Refresh anti-patterns documentation

**Annual Review**:
- Evaluate overall naming quality
- Consider length limit adjustments
- Update best practices with real examples
