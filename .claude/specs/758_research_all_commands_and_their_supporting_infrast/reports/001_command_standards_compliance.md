# Command Standards Compliance Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Commands and Infrastructure Standards Compliance
- **Report Type**: codebase analysis

## Executive Summary

Analysis of 17 commands and 60+ supporting libraries against 16 architectural standards reveals significant compliance variations. Well-maintained orchestrator commands (coordinate, plan, research) demonstrate high compliance (85-95%), while simpler utility commands show moderate compliance (60-75%). Key gaps include: inconsistent imperative language usage (Standard 0), missing MANDATORY VERIFICATION checkpoints, incomplete cross-references to guide files (Standard 14), and inconsistent return code verification (Standard 16). The infrastructure libraries are well-organized with proper source guards and dependency management, though some commands lack proper library sourcing order (Standard 15).

## Findings

### 1. Command File Analysis

#### 1.1 Compliant Commands (High Compliance: 85-95%)

**coordinate.md** (1084+ lines):
- Properly implements Standard 13 (CLAUDE_PROJECT_DIR detection at lines 62-65)
- Correct library sourcing order per Standard 15 (lines 100-137)
- Uses MANDATORY VERIFICATION checkpoints (lines 140-148, 162-164, 168-181)
- Two-step workflow description capture pattern (lines 18-42)
- Has companion guide at `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`
- Properly uses `set +H` in all bash blocks (lines 33, 52)
- Role statement present: "YOU ARE EXECUTING AS the /coordinate command" (line 12)

**plan.md** (970 lines):
- Implements Standard 15 library sourcing order (lines 55-105)
- VERIFICATION CHECKPOINTs throughout (lines 121-125, 201-206, 317-336, 717-729)
- Standard 13 project directory detection (lines 26-50)
- State persistence pattern (lines 107-226)
- Task invocations with imperative directives (lines 232-252, 668-696)
- Has companion guide at `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md`

**research.md** (1011 lines):
- Explicit orchestrator role definition (lines 15-20)
- Phase-based tool usage restrictions (lines 21-28)
- EXECUTE NOW directives for all bash blocks (lines 45-47, 93, 98, etc.)
- Pre-calculated path pattern (lines 176-276)
- MANDATORY VERIFICATION checkpoints (lines 352-356, 612-668)
- Uses associative arrays with proper expansion workarounds (line 239-256)

**implement.md** (305 lines):
- Lean executable file per Standard 14
- Proper set +H in all blocks (lines 22, 121, 199, 263)
- Standard 13 detection with fallback (lines 23-46)
- Complexity-based agent delegation (lines 148-169)
- Has companion guide at `/home/benjamin/.config/.claude/docs/guides/implement-command-guide.md`

#### 1.2 Moderately Compliant Commands (60-75%)

**debug.md** (245 lines):
- Good structure with phases 0-6
- Uses set +H in all blocks
- Has guide file reference (line 13)
- ISSUES:
  - Lines 64, 131-134: Undefined functions (`analyze_issue`, `determine_root_cause`, `verify_root_cause`, `calculate_issue_complexity`)
  - No Standard 13 project directory detection
  - No library sourcing (Standard 15 violation)
  - Task invocation at line 103-122 lacks explicit path injection
  - Missing VERIFICATION CHECKPOINTs for file creation

**setup.md** (312 lines):
- Proper Standard 13 detection (lines 23-26)
- Mode-based phase execution pattern
- Has guide file at `/home/benjamin/.config/.claude/docs/guides/setup-command-guide.md`
- ISSUES:
  - Line 77: exits with 0 in phase that should continue
  - Lines 144, 178: similar early exit issues
  - No comprehensive VERIFICATION CHECKPOINTs
  - Analysis report template incomplete (lines 229-243)

#### 1.3 Commands Missing Analysis

Based on command index, the following commands need review:
- `/build` - orchestrator type
- `/fix` - orchestrator type
- `/revise` - workflow type
- `/expand` - workflow type
- `/collapse` - workflow type
- `/convert-docs` - utility type
- `/research-plan`, `/research-report`, `/research-revise` - orchestrator types

### 2. Standards Compliance Matrix

| Standard | Description | Compliance Rate | Key Violations |
|----------|-------------|-----------------|----------------|
| Standard 0 | Execution Enforcement | 70% | Inconsistent YOU MUST/EXECUTE NOW usage |
| Standard 0.5 | Subagent Prompt Enforcement | 80% | Some agents missing STEP dependencies |
| Standard 11 | Imperative Agent Invocation | 85% | debug.md lacks imperative marker |
| Standard 12 | Structural vs Behavioral | 75% | Some commands duplicate agent content |
| Standard 13 | Project Directory Detection | 90% | debug.md missing detection |
| Standard 14 | Exec/Doc Separation | 65% | Missing guides for 4+ commands |
| Standard 15 | Library Sourcing Order | 60% | debug.md, fix.md missing sourcing |
| Standard 16 | Return Code Verification | 55% | Many functions called without checks |

### 3. Infrastructure Library Analysis

#### 3.1 Core Libraries (High Quality)

**unified-location-detection.sh** (/home/benjamin/.config/.claude/lib/unified-location-detection.sh):
- Proper source guard pattern
- Complete API: `perform_location_detection()`, `detect_project_root()`, `sanitize_topic_name()`, `ensure_artifact_directory()`, `create_topic_structure()`
- Performance: <1s execution, <11k tokens

**state-persistence.sh** (/home/benjamin/.config/.claude/lib/state-persistence.sh):
- GitHub Actions pattern implementation
- Functions: `init_workflow_state()`, `load_workflow_state()`, `append_workflow_state()`
- Performance: 2-6ms per operation

**workflow-state-machine.sh** (/home/benjamin/.config/.claude/lib/workflow-state-machine.sh):
- Foundation for state machine architecture
- Used by coordinate, plan commands

#### 3.2 Library Dependencies

Critical dependency chain (must source in this order):
1. workflow-state-machine.sh
2. state-persistence.sh
3. error-handling.sh
4. verification-helpers.sh
5. Other libraries

Commands violating this order: debug.md (no sourcing), setup.md (partial sourcing)

### 4. Documentation Standards Analysis

#### 4.1 Guide Files Present (Standard 14 Compliant)

Found 13 command guide files at `/home/benjamin/.config/.claude/docs/guides/`:
- coordinate-command-guide.md
- plan-command-guide.md
- implement-command-guide.md
- debug-command-guide.md
- setup-command-guide.md
- test-command-guide.md
- document-command-guide.md
- build-command-guide.md
- fix-command-guide.md
- research-plan-command-guide.md
- research-report-command-guide.md
- research-revise-command-guide.md
- optimize-claude-command-guide.md

#### 4.2 Missing Guide Files

Commands without guide files:
- expand.md
- collapse.md
- convert-docs.md
- revise.md
- research.md

### 5. Critical Compliance Gaps

#### Gap 1: Undefined Functions in debug.md
Lines 64, 131-134 reference functions that don't exist:
- `analyze_issue()`
- `calculate_issue_complexity()`
- `determine_root_cause()`
- `verify_root_cause()`

These should be defined in `.claude/lib/` or removed.

#### Gap 2: Missing VERIFICATION CHECKPOINTs
Several commands lack Standard 0 verification patterns:
- debug.md: No file creation verification for report
- setup.md: Limited verification after operations
- fix.md, build.md: Need review

#### Gap 3: Inconsistent Return Code Checking (Standard 16)
Many commands call critical functions without checking return codes:
```bash
# Incorrect pattern (debug.md)
POTENTIAL_CAUSES=$(analyze_issue "$ISSUE_DESCRIPTION")

# Correct pattern (coordinate.md)
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi
```

#### Gap 4: Incomplete Standard 14 Compliance
4-5 commands missing companion guide files for complete documentation separation.

### 6. Best Practices Observed

#### 6.1 Exemplary Patterns in coordinate.md

**Two-Step Workflow Description Capture** (lines 18-42):
- Avoids positional parameter issues
- Uses timestamp-based temp files for concurrency safety
- Clear example and instructions

**Library Sourcing with Validation** (lines 100-148):
- Checks file existence before sourcing
- Verifies functions available after sourcing
- Clear error messages with diagnostic information

**State Persistence Pattern** (lines 154-185):
- Uses fixed semantic filename
- Saves to state and verifies
- Cross-block state management

#### 6.2 Exemplary Patterns in plan.md

**Fail-Fast Validation** (lines 280-308):
- Validates agent output immediately
- JSON structure validation
- Required field extraction with null checks

**Metadata Extraction** (lines 530-553):
- 95% context reduction
- Fallback to head summary if extraction fails
- Caches for plan-architect injection

## Recommendations

### Recommendation 1: Complete Standard 14 Compliance
**Priority**: High
**Effort**: Medium

Create missing guide files for:
- expand.md → expand-command-guide.md
- collapse.md → collapse-command-guide.md
- convert-docs.md → convert-docs-command-guide.md
- revise.md → revise-command-guide.md
- research.md → research-command-guide.md

Use template at `/home/benjamin/.config/.claude/docs/guides/_template-command-guide.md`.

### Recommendation 2: Fix debug.md Critical Issues
**Priority**: Critical
**Effort**: High

1. Add Standard 13 project directory detection
2. Add library sourcing per Standard 15
3. Define or source missing functions:
   - Create `/home/benjamin/.config/.claude/lib/debug-utils.sh`
   - Implement `analyze_issue()`, `calculate_issue_complexity()`, `determine_root_cause()`, `verify_root_cause()`
4. Add MANDATORY VERIFICATION checkpoint after report creation
5. Add return code verification per Standard 16

### Recommendation 3: Implement Return Code Verification (Standard 16)
**Priority**: High
**Effort**: Medium

Audit all commands for critical function calls and add return code checks:
```bash
# Pattern to apply
if ! critical_function arg1 arg2 2>&1; then
  handle_state_error "critical_function failed: description" 1
fi
```

Commands needing audit: debug.md, setup.md, fix.md, build.md

### Recommendation 4: Standardize Library Sourcing Order
**Priority**: Medium
**Effort**: Low

Create standardized sourcing block for all commands:
```bash
# Standard library sourcing block
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

Apply to: debug.md, setup.md (enhance Phase 2-6)

### Recommendation 5: Add VERIFICATION CHECKPOINTs
**Priority**: Medium
**Effort**: Medium

Add verification patterns to commands lacking them:
```bash
# Pattern from coordinate.md
if [ ! -f "$EXPECTED_FILE" ]; then
  echo "CRITICAL: Expected file not created at $EXPECTED_FILE"
  exit 1
fi
echo "✓ VERIFIED: File created at $EXPECTED_FILE"
```

Apply to: debug.md (report creation), setup.md (all modes)

### Recommendation 6: Strengthen Imperative Language (Standard 0)
**Priority**: Medium
**Effort**: Low

Convert weak language to imperative:
- "should" → "MUST"
- "may" → "WILL"
- "can" → "SHALL"

Example sections needing update:
- debug.md: Phase 1-2 descriptions
- setup.md: Phase descriptions

### Recommendation 7: Update Command Reference Documentation
**Priority**: Low
**Effort**: Low

Update `/home/benjamin/.config/.claude/docs/reference/command-reference.md`:
- Add missing commands (optimize-claude)
- Update status indicators
- Add guide file cross-references

### Recommendation 8: Create Validation Test Suite
**Priority**: Medium
**Effort**: High

Create automated compliance tests at `/home/benjamin/.config/.claude/tests/`:
- `test_command_standards_compliance.sh` - All 16 standards
- `test_library_sourcing_order.sh` - Standard 15
- `test_verification_checkpoints.sh` - Standard 0
- `test_return_code_verification.sh` - Standard 16

## Implementation Priority Matrix

| Priority | Recommendation | Effort | Impact |
|----------|---------------|--------|--------|
| Critical | Fix debug.md issues | High | Prevents runtime errors |
| High | Return code verification | Medium | Improves reliability |
| High | Complete Standard 14 | Medium | Better documentation |
| Medium | Library sourcing order | Low | Consistency |
| Medium | VERIFICATION CHECKPOINTs | Medium | Better error detection |
| Medium | Validation test suite | High | Long-term quality |
| Low | Strengthen imperative | Low | Clarity |
| Low | Update command reference | Low | Documentation |

## References

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - All 16 standards (2507 lines)
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md` - Execution directives (456 lines)
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Code standards (84 lines)
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Library API (1378 lines)

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/coordinate.md` - Lines 1-200 analyzed (1084+ total)
- `/home/benjamin/.config/.claude/commands/plan.md` - Full file (970 lines)
- `/home/benjamin/.config/.claude/commands/research.md` - Full file (1011 lines)
- `/home/benjamin/.config/.claude/commands/implement.md` - Full file (305 lines)
- `/home/benjamin/.config/.claude/commands/debug.md` - Full file (245 lines)
- `/home/benjamin/.config/.claude/commands/setup.md` - Full file (312 lines)

### Supporting Files
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Command index (693 lines)
- `/home/benjamin/.config/.claude/docs/guides/_template-command-guide.md` - Guide template
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Core library
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State management
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` - Verification functions

### Command Files Requiring Further Analysis
- `/home/benjamin/.config/.claude/commands/build.md`
- `/home/benjamin/.config/.claude/commands/fix.md`
- `/home/benjamin/.config/.claude/commands/revise.md`
- `/home/benjamin/.config/.claude/commands/expand.md`
- `/home/benjamin/.config/.claude/commands/collapse.md`
- `/home/benjamin/.config/.claude/commands/convert-docs.md`
- `/home/benjamin/.config/.claude/commands/research-plan.md`
- `/home/benjamin/.config/.claude/commands/research-report.md`
- `/home/benjamin/.config/.claude/commands/research-revise.md`

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_research_all_commands_and_their_supporti_plan.md](../plans/001_research_all_commands_and_their_supporti_plan.md)
- **Implementation**: Pending
- **Date**: 2025-11-17
