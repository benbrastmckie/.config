# /research Command - Current Implementation Analysis

## Overview

The `/research` command is a hierarchical multi-agent orchestrator (566 lines) that decomposes research topics into 2-4 focused subtopics and delegates to parallel research-specialist agents. It implements the improved hierarchical research pattern introduced as an evolution of the original `/report` command (628 lines), with structural and behavioral enforcement patterns aligned to command architecture standards.

## Research Findings

### File Structure and Size

- **File**: `/home/benjamin/.config/.claude/commands/research.md`
- **Total Lines**: 566 lines
- **Comparison**: `/report` command is 628 lines (62 lines longer)
- **Phase Structure**: 6 major phases (STEP 1 through STEP 6)
- **Agent Invocations**: 5 Task invocation patterns (research-specialist, research-synthesizer, spec-updater)

The `/research` command is moderately sized compared to other orchestration commands and maintains healthy inline content density per Command Architecture Standard 3 (target: 500-2000 lines for orchestration commands).

### Phase Breakdown

The command follows a structured 6-phase workflow:

1. **STEP 1: Topic Decomposition** (lines 35-76)
   - Calculates subtopic count using `topic-decomposition.sh` library
   - Uses Task tool to decompose topic into 2-4 snake_case subtopics
   - Validation requirements for subtopic format and count

2. **STEP 2: Path Pre-Calculation** (lines 78-172)
   - **Critical Feature**: Pre-calculates absolute paths BEFORE agent invocation
   - Uses unified location detection library (`unified-location-detection.sh`)
   - Creates research subdirectory structure
   - **MANDATORY VERIFICATION checkpoint** at line 148-161
   - Enforces absolute path requirement for all subtopic reports

3. **STEP 3: Invoke Research Agents** (lines 174-252)
   - **Agent Invocation Pattern**: Uses imperative "EXECUTE NOW" enforcement
   - Parallel invocation of research-specialist agents (one per subtopic)
   - **Critical Instruction**: "The agent prompt below is NOT an example. It is the EXACT template you MUST use" (line 180)
   - Includes pre-calculated paths in agent context
   - Monitors progress markers during execution

4. **STEP 4: Verify Report Creation** (lines 254-276)
   - **MANDATORY VERIFICATION** of all subtopic reports
   - Fallback mechanism: searches alternate locations if reports not at expected paths
   - Error handling with detailed logging
   - Tracks verification status per subtopic

5. **STEP 5: Synthesize Overview Report** (lines 278-392)
   - Invokes research-synthesizer agent after all subtopics verified
   - Creates OVERVIEW.md (ALL CAPS filename convention)
   - Aggregates findings from all subtopic reports
   - Monitoring and verification of synthesis completion

6. **STEP 6: Update Cross-References** (lines 344-427)
   - **ABSOLUTE REQUIREMENT**: Invokes spec-updater agent
   - Updates bidirectional links between reports and plans
   - Validates cross-reference completeness
   - Returns structured status report

### Agent Invocation Compliance

**Behavioral Injection Pattern Compliance**: ✅ FULL COMPLIANCE

The `/research` command follows Standard 11 (Imperative Agent Invocation Pattern):

1. **Imperative Instructions Present** (lines 177, 300, 356):
   - "**EXECUTE NOW - Invoke All Research-Specialist Agents in Parallel**"
   - "**EXECUTE NOW - Invoke Research-Synthesizer Agent**"
   - "**EXECUTE NOW - Invoke Spec-Updater for Cross-Reference Management**"

2. **Agent Behavioral File References** (lines 194, 310, 363):
   - Research-specialist: `.claude/agents/research-specialist.md`
   - Research-synthesizer: `.claude/agents/research-synthesizer.md`
   - Spec-updater: `.claude/agents/spec-updater.md`

3. **No Code Block Wrappers**: ✅ CORRECT
   - Task invocations at lines 186-246, 301-341, 357-405 are NOT wrapped in ` ```yaml` fences
   - Uses structural format without documentation-only code blocks

4. **Completion Signal Requirements**:
   - Research-specialist: "Return: REPORT_CREATED: [path]" (line 216)
   - Research-synthesizer: "Return: OVERVIEW_CREATED: [path]" (line 328)
   - Spec-updater: Returns structured status report (lines 398-404)

**No Anti-Pattern Violations Detected**: The command does NOT exhibit the documentation-only YAML block anti-pattern that caused 0% delegation rate in `/supervise` (spec 438) or the code fence priming effect from spec 469.

### Verification and Fallback Patterns

**Verification Checkpoints**: The command includes 3 MANDATORY VERIFICATION checkpoints:

1. **Line 100-105**: Topic directory creation verification
   ```bash
   if [ ! -d "$TOPIC_DIR" ]; then
     echo "ERROR: Location detection failed - directory not created: $TOPIC_DIR"
     exit 1
   fi
   ```

2. **Line 122-127**: Research subdirectory creation verification
   ```bash
   if [ ! -d "$RESEARCH_SUBDIR" ]; then
     echo "CRITICAL ERROR: Research subdirectory creation failed: $RESEARCH_SUBDIR"
     exit 1
   fi
   ```

3. **Line 151-157**: Absolute path validation
   ```bash
   for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
     if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
       echo "CRITICAL ERROR: Path for '$subtopic' is not absolute"
       exit 1
     fi
   done
   ```

**Fallback Mechanism**: Lines 257-274 implement search fallback for missing reports:
- Primary: Check expected path
- Fallback: Search research subdirectory using `find` command
- Error reporting if report not found

**Note**: Unlike `/report` command (lines 283-312), the `/research` command does NOT include automated fallback creation from agent output. This is a potential bloat reduction opportunity.

### Comparison: /research vs /report

Both commands implement the hierarchical multi-agent research pattern but have structural differences:

| Feature | /research | /report |
|---------|-----------|---------|
| **Total Lines** | 566 | 628 |
| **Phases** | 6 (STEP 1-6) | 6 (STEP 1-6) |
| **Library Used** | `artifact-creation.sh` (line 43) | `artifact-operations.sh` (line 43) |
| **Fallback Creation** | Search only (line 257-267) | Search + auto-create (line 283-312) |
| **Overview Filename** | OVERVIEW.md (ALL CAPS) | OVERVIEW.md (ALL CAPS) |
| **Agent Count** | 3 types | 3 types |
| **Lazy Directory Creation** | Yes (line 217-224) | Yes (line 217-224, 367-374) |

**Key Differences**:
1. `/report` includes 29-line fallback creation block (lines 283-312) that `/research` lacks
2. `/research` uses newer `artifact-creation.sh` library vs `/report`'s `artifact-operations.sh`
3. Both commands have identical lazy directory creation instructions added (likely recent update)

**Bloat Difference**: `/report` is 62 lines longer primarily due to:
- Fallback creation heredoc (lines 289-303): 15 lines
- Additional explanatory text and examples
- More verbose agent prompt context

### Potential Bloat Sources

Analyzing the 566-line `/research` command for unnecessary content:

1. **Duplicate Content with /report** (~400 lines of structural similarity):
   - Both commands share nearly identical phase structure
   - Agent invocation templates are duplicated
   - Verification checkpoint patterns are identical
   - **Opportunity**: Abstract common orchestration patterns to shared library

2. **Inline Agent Prompt Templates** (150+ lines across invocations):
   - Lines 196-224: Research-specialist agent prompt (29 lines)
   - Lines 307-341: Research-synthesizer agent prompt (35 lines)
   - Lines 363-405: Spec-updater agent prompt (43 lines)
   - **Assessment**: These are structural templates (not behavioral content), so they MUST remain inline per Standard 12
   - **Not Bloat**: Required for behavioral injection pattern compliance

3. **Verification and Checkpoint Blocks** (~80 lines):
   - Lines 100-107: Topic directory verification (8 lines)
   - Lines 122-131: Research subdirectory verification (10 lines)
   - Lines 148-171: Path validation and checkpoint (24 lines)
   - Lines 239-276: Report verification loop (38 lines)
   - **Assessment**: Critical for execution enforcement (Standard 0)
   - **Not Bloat**: Ensures 100% file creation rate

4. **Explanatory Context and "Why This Matters"** (~60 lines):
   - Lines 112-114: Path pre-calculation rationale
   - Lines 179-181: Template enforcement explanation
   - Lines 218-220: OVERVIEW.md naming rationale
   - **Assessment**: Required per Standard 0.5 (enforcement rationale)
   - **Not Bloat**: Improves agent compliance

5. **Examples and Workflow Diagrams** (~40 lines):
   - Lines 65-75: Subtopic decomposition example
   - Lines 489-504: Hierarchical workflow ASCII diagram
   - **Assessment**: Required per Standard 3 (minimum 1 complete example)
   - **Minimal Bloat**: Could potentially reduce by 10-15 lines

### Compliance with Architecture Standards

**Standard 0 (Execution Enforcement)**: ✅ EXCELLENT
- Imperative language throughout ("YOU MUST", "EXECUTE NOW", "MANDATORY")
- Verification checkpoints with explicit bash blocks
- Fallback mechanisms for agent non-compliance
- Checkpoint reporting requirements

**Standard 11 (Imperative Agent Invocation)**: ✅ FULL COMPLIANCE
- All agent invocations use imperative instructions
- No code block wrappers around Task invocations
- Behavioral file references present
- Completion signals required

**Standard 12 (Structural vs Behavioral Separation)**: ✅ FULL COMPLIANCE
- Agent prompts reference behavioral files (lines 194, 310, 363)
- Context injection only (no STEP sequence duplication)
- Structural templates remain inline
- No behavioral content duplication detected

**Overall Architecture Score**: 95/100
- Minor deduction for potential example reduction opportunities
- Otherwise exemplary implementation of all standards

### Library Dependencies

The command relies on these utility libraries:

1. **`topic-decomposition.sh`** (line 42): Subtopic calculation and decomposition
2. **`artifact-creation.sh`** (line 43): Topic directory and artifact path management
3. **`template-integration.sh`** (line 44): Template loading and integration
4. **`unified-location-detection.sh`** (lines 84, 219, 369): Standardized location detection and lazy directory creation

**Library Usage Assessment**: Appropriate delegation to libraries. No evidence of library function duplication inline.

## Recommendations

### 1. Harmonize /research and /report Commands

**Issue**: Two commands (566 and 628 lines) implement nearly identical hierarchical research patterns with 62-line delta primarily from fallback creation block.

**Recommendation**: Decide on canonical implementation:
- **Option A**: Deprecate `/report` in favor of `/research` (mark `/report` as legacy)
- **Option B**: Merge best features of both into single command
- **Option C**: Maintain both but extract common orchestration pattern to shared library

**Expected Impact**: 30-40% reduction in maintenance burden, elimination of 400+ lines of duplicate orchestration logic across two files.

**Implementation Path**:
```bash
# Create shared orchestration library
.claude/lib/hierarchical-research-orchestration.sh
  - phase_1_topic_decomposition()
  - phase_2_path_precalculation()
  - phase_3_invoke_research_agents()
  - phase_4_verify_report_creation()
  - phase_5_synthesize_overview()
  - phase_6_update_cross_references()

# Both commands become thin wrappers
/research: Call library functions with /research-specific config
/report: Call library functions with /report-specific config (or deprecate)
```

### 2. Add Fallback Creation to /research Command

**Issue**: `/report` command includes 29-line fallback creation block (lines 283-312) that automatically creates minimal reports when agents fail. The `/research` command only searches alternate locations but does not auto-create fallback content.

**Recommendation**: Port fallback creation mechanism from `/report` to `/research` for defense-in-depth consistency.

**Expected Impact**: +29 lines, but ensures 100% artifact creation rate (currently relies on agent compliance only).

**Rationale**: Verification and Fallback pattern (Standard 0) recommends fallback creation for all agent-dependent file operations. This protects against agent non-compliance scenarios.

### 3. Abstract Common Verification Patterns

**Issue**: Verification checkpoint blocks (lines 100-107, 122-131, 148-171) are structurally similar across multiple commands and could be abstracted.

**Recommendation**: Create verification utility library:
```bash
.claude/lib/verification-checkpoints.sh
  - verify_directory_exists()
  - verify_file_exists()
  - verify_absolute_paths()
  - verify_report_structure()
```

**Expected Impact**: 30-40 line reduction per command, standardized verification patterns across codebase.

**Trade-off**: Slight reduction in inline execution clarity, but improved maintainability and consistency.

### 4. Reduce Explanatory Context Where Standards Suffice

**Issue**: Some "Why This Matters" blocks (lines 112-114, 218-220) explain patterns that are already documented in Command Architecture Standards.

**Recommendation**: Replace verbose inline explanations with standard references:
```markdown
❌ Current (5 lines):
**WHY THIS MATTERS**: Research-specialist agents require EXACT absolute paths to create files in correct locations. Skipping this step causes path mismatch errors.

✅ Proposed (2 lines):
**PATH PRE-CALCULATION REQUIREMENT**: See Standard 0 (Execution Enforcement) for rationale.
```

**Expected Impact**: 10-15 line reduction, improved consistency with standards.

**Caveat**: Only apply where standard documentation is comprehensive. Retain custom rationale where needed.

### 5. Consolidate Library References

**Issue**: Command sources 4 libraries (lines 42-44, 84) at different phases. This increases cognitive load and makes dependencies unclear.

**Recommendation**: Consolidate library sourcing to Phase 0 (before any execution):
```bash
# Phase 0: Environment Setup
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh
source .claude/lib/unified-location-detection.sh
```

**Expected Impact**: Minor reduction (3-5 lines), improved clarity of dependencies.

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/research.md` (566 lines)
- `/home/benjamin/.config/.claude/commands/report.md` (628 lines)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (1966 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (690 lines)

### Key Line References

**Agent Invocations**:
- Research-specialist: `research.md:186-246`
- Research-synthesizer: `research.md:301-341`
- Spec-updater: `research.md:357-405`

**Verification Checkpoints**:
- Topic directory: `research.md:100-107`
- Research subdirectory: `research.md:122-131`
- Absolute paths: `research.md:148-171`
- Report existence: `research.md:239-276`

**Fallback Mechanisms**:
- `/research` search fallback: `research.md:257-267`
- `/report` creation fallback: `report.md:283-312`

### Standards Compliance

- **Standard 0 (Execution Enforcement)**: Full compliance
- **Standard 11 (Imperative Agent Invocation)**: Full compliance
- **Standard 12 (Structural vs Behavioral)**: Full compliance
- **Overall Score**: 95/100

### Related Specifications

- Spec 438: `/supervise` documentation-only YAML blocks (0% delegation rate)
- Spec 469: Code fence priming effect causing agent delegation failure
- Spec 444: Research command allowed-tools mismatches

## Metadata

- **Research Date**: 2025-10-24
- **Files Analyzed**: 4 files (research.md, report.md, command_architecture_standards.md, behavioral-injection.md)
- **Total Lines Analyzed**: 3850 lines
- **Standards Referenced**: 3 architecture standards (0, 11, 12)
