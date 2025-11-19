# Execution Enforcement Markers Implementation Guide

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Execution enforcement marker requirements across 5 commands
- **Report Type**: Implementation guide
- **Standard**: Standard 0 (Command Execution Enforcement)
- **Missing Instances**: 26 total (13 EXECUTE NOW, 13 MANDATORY VERIFICATION)

## Executive Summary

All 5 workflow commands lack formal execution enforcement markers required by Standard 0, using echo-based documentation instead of structured "EXECUTE NOW" and "MANDATORY VERIFICATION" headers. This absence causes reliance on Claude interpretation rather than formal enforcement contracts, leading to inconsistent execution across different Claude instances and unclear requirements for critical operations. Adding formal markers to all 26 missing instances (13 EXECUTE NOW for critical bash operations, 13 MANDATORY VERIFICATION for checkpoints) will provide explicit execution contracts, improve consistency, and achieve Standard 0 compliance. Estimated effort: 14 hours total (30-45 minutes per marker).

## Standard 0 Requirements

### From execution-enforcement-guide.md:84-92

**Standard 0: Command Execution Enforcement**

Commands (`.claude/commands/*.md`) must use:
- **"EXECUTE NOW" markers** for critical operations
- **"MANDATORY VERIFICATION" checkpoints** for file creation
- **Fallback mechanisms** for agent-dependent operations
- **"THIS EXACT TEMPLATE" markers** for agent invocations
- **"CHECKPOINT REQUIREMENT" blocks** for major steps

### Purpose

Execution enforcement transforms optional, descriptive guidance into mandatory, executable directives.

**Before** (Descriptive):
```markdown
You should verify the report file was created.
```

**After** (Enforcement):
```markdown
**MANDATORY VERIFICATION - Report File Creation**

After research phase, YOU MUST verify:

```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL ERROR: Report not created at $REPORT_PATH"
  exit 1
fi
echo "✓ VERIFIED: Report exists at $REPORT_PATH"
```

**CHECKPOINT**: Report file must exist before proceeding.
```

## Missing Marker Analysis

### Missing "EXECUTE NOW" Markers (13 Instances)

**Category 1: Project Directory Detection (5 instances)**

All 5 commands have bash code blocks for CLAUDE_PROJECT_DIR detection without formal markers.

**Current pattern** (generic):
```bash
# Bootstrap CLAUDE_PROJECT_DIR detection
if command -v git &>/dev/null; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback logic
fi
```

**Expected pattern**:
```markdown
### STEP 1 - Project Directory Detection

**EXECUTE NOW - Detect Project Directory**

YOU MUST run this code block NOW to establish the project root:

```bash
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR
echo "✓ Project directory: $CLAUDE_PROJECT_DIR"
```

**WHY THIS MATTERS**: All subsequent library sourcing depends on correct project directory. Failure here causes cascading failures.
```

**Category 2: Directory Creation Operations (5 instances)**

Commands create artifact directories (reports/, plans/, debug/) without formal markers.

**Current pattern** (generic):
```bash
mkdir -p "$RESEARCH_DIR"
mkdir -p "$PLANS_DIR"
```

**Expected pattern**:
```markdown
### STEP 2 - Artifact Directory Creation

**EXECUTE NOW - Create Artifact Directories**

YOU MUST create required directories NOW:

```bash
# Research reports directory
RESEARCH_DIR="${SPECS_DIR}/reports"
mkdir -p "$RESEARCH_DIR" || {
  echo "ERROR: Failed to create research directory: $RESEARCH_DIR" >&2
  exit 1
}

# Implementation plans directory
PLANS_DIR="${SPECS_DIR}/plans"
mkdir -p "$PLANS_DIR" || {
  echo "ERROR: Failed to create plans directory: $PLANS_DIR" >&2
  exit 1
}

echo "✓ Artifact directories created:"
echo "  - Research: $RESEARCH_DIR"
echo "  - Plans: $PLANS_DIR"
```

**WHY THIS MATTERS**: Agent invocations depend on these directories existing. Failure here causes agent file creation failures.
```

**Category 3: Path Calculation Operations (3 instances)**

Commands calculate critical paths (PLAN_PATH, REPORT_PATH) without formal markers.

**Current pattern** (generic):
```bash
PLAN_FILENAME="${TOPIC_SLUG}_plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"
```

**Expected pattern**:
```markdown
### STEP 3 - Plan Path Calculation

**EXECUTE NOW - Calculate Plan File Path**

YOU MUST calculate the exact plan file path NOW:

```bash
PLAN_NUMBER="001"  # or calculate next number
PLAN_FILENAME="${PLAN_NUMBER}_${TOPIC_SLUG}.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

echo "✓ Plan path calculated: $PLAN_PATH"
```

**WHY THIS MATTERS**: Agent invocations receive this exact path. Incorrect calculation causes file creation at wrong location.
```

### Missing "MANDATORY VERIFICATION" Headers (13 Instances)

**Category 1: Research Artifacts Verification (3 instances)**

Commands using research-specialist verify reports without formal headers.

**Current pattern** (generic):
```bash
# FAIL-FAST VERIFICATION
echo "Verifying research reports..."
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research directory not found"
  exit 1
fi
REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" | wc -l)
```

**Expected pattern**:
```markdown
**MANDATORY VERIFICATION - Research Reports Created**

After research phase, YOU MUST verify:

```bash
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "CRITICAL ERROR: Research directory not found: $RESEARCH_DIR" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name "*.md" 2>/dev/null | wc -l)

if [ "$REPORT_COUNT" -eq 0 ]; then
  echo "CRITICAL ERROR: No research reports created in $RESEARCH_DIR" >&2
  echo "Expected at least 1 report, found 0" >&2
  exit 1
fi

echo "✓ VERIFIED: $REPORT_COUNT research reports created"
```

**CHECKPOINT**: At least 1 research report must exist before proceeding to planning phase.
```

**Category 2: Plan File Verification (2 instances)**

Commands using plan-architect verify plans without formal headers.

**Current pattern** (generic):
```bash
echo "Verifying plan file..."
if [ ! -f "$PLAN_PATH" ]; then
  echo "WARNING: Plan file not created"
fi
```

**Expected pattern**:
```markdown
**MANDATORY VERIFICATION - Implementation Plan Created**

After planning phase, YOU MUST verify:

```bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "CRITICAL ERROR: Plan file not created at $PLAN_PATH" >&2
  exit 1
fi

PLAN_SIZE=$(wc -c < "$PLAN_PATH" 2>/dev/null || echo 0)
if [ "$PLAN_SIZE" -lt 500 ]; then
  echo "WARNING: Plan file suspiciously small (${PLAN_SIZE} bytes)" >&2
  echo "Expected >500 bytes for complete plan" >&2
fi

echo "✓ VERIFIED: Plan file created at $PLAN_PATH ($PLAN_SIZE bytes)"
```

**CHECKPOINT**: Plan file must exist with substantial content before proceeding to implementation.
```

**Category 3: Implementation Verification (1 instance)**

/build command verifies implementation without formal header.

**Expected pattern**:
```markdown
**MANDATORY VERIFICATION - Implementation Complete**

After implementation phase, YOU MUST verify:

```bash
# Check for actual code changes
CHANGES=$(git diff --name-only)

if [ -z "$CHANGES" ]; then
  echo "CRITICAL ERROR: Implementation phase produced no changes" >&2
  echo "This indicates agent non-compliance or execution failure" >&2
  exit 1
fi

echo "✓ VERIFIED: Implementation produced changes:"
echo "$CHANGES" | sed 's/^/  - /'
```

**CHECKPOINT**: Implementation must produce code changes before proceeding to test phase.
```

**Category 4: Test Verification (1 instance)**

/build command verifies tests without formal header.

**Expected pattern**:
```markdown
**MANDATORY VERIFICATION - Tests Executed and Passed**

After test phase, YOU MUST verify:

```bash
# Check test framework exit code
if [ "${TEST_EXIT_CODE:-1}" -ne 0 ]; then
  echo "CRITICAL ERROR: Tests failed with exit code $TEST_EXIT_CODE" >&2
  echo "Cannot proceed to documentation/commit phase" >&2
  exit 1
fi

echo "✓ VERIFIED: All tests passed"
```

**CHECKPOINT**: Tests must pass before committing changes.
```

**Category 5: Debug Artifacts Verification (1 instance)**

/fix command verifies debug artifacts without formal header.

**Expected pattern**:
```markdown
**MANDATORY VERIFICATION - Debug Artifacts Created**

After debug phase, YOU MUST verify:

```bash
DEBUG_ARTIFACT_COUNT=$(find "$DEBUG_DIR" -name "*.md" 2>/dev/null | wc -l)

if [ "$DEBUG_ARTIFACT_COUNT" -eq 0 ]; then
  echo "CRITICAL ERROR: No debug artifacts created in $DEBUG_DIR" >&2
  echo "Expected at least 1 debug report or fix summary" >&2
  exit 1
fi

echo "✓ VERIFIED: $DEBUG_ARTIFACT_COUNT debug artifacts created"
```

**CHECKPOINT**: Debug artifacts must exist documenting fixes applied.
```

**Category 6: Directory Verification (5 instances)**

All commands verify directories without formal headers (same as Category 1-5 combined).

## Implementation Patterns

### Pattern 1: "EXECUTE NOW" Marker Template

**Structure**:
```markdown
### STEP [N] - [Operation Name]

**EXECUTE NOW - [Action Description]**

YOU MUST run this code block NOW:

```bash
# Critical operation code
[bash code block]
```

**WHY THIS MATTERS**: [Rationale explaining criticality and consequences of failure]
```

**Usage Guidelines**:
- Use for critical bash operations that MUST execute
- Include error handling in bash block (exit on failure)
- Explain WHY operation is critical (downstream dependencies)
- Keep WHY explanation to 1-2 sentences

### Pattern 2: "MANDATORY VERIFICATION" Template

**Structure**:
```markdown
**MANDATORY VERIFICATION - [What is Being Verified]**

After [operation], YOU MUST verify:

```bash
# Verification checks
if [ ! -f "$FILE_PATH" ]; then
  echo "CRITICAL ERROR: [Error message]" >&2
  exit 1
fi

# Additional checks (size, content, permissions)
[additional verification code]

echo "✓ VERIFIED: [Success message]"
```

**CHECKPOINT**: [Requirement statement for proceeding to next step]
```

**Usage Guidelines**:
- Use after critical operations (file creation, agent execution, state transitions)
- Include fail-fast error handling (exit 1 on verification failure)
- Add supplementary checks (file size, content validation)
- End with explicit CHECKPOINT requirement

### Pattern 3: Combined Pattern (Operation + Verification)

**Structure**:
```markdown
### STEP [N] - [Operation Name]

**EXECUTE NOW - [Action Description]**

YOU MUST run this operation NOW:

```bash
[operation code]
```

**WHY THIS MATTERS**: [Rationale]

**MANDATORY VERIFICATION - [Verification Target]**

After operation, YOU MUST verify:

```bash
[verification code]
```

**CHECKPOINT**: [Requirement]
```

**When to Use**: For operations requiring immediate verification (file creation, directory creation)

## Command-Specific Implementation

### /research-report (Simplest - 2-3 hours)

**Missing markers**:
- 1 EXECUTE NOW: Project directory detection
- 1 EXECUTE NOW: Directory creation
- 1 MANDATORY VERIFICATION: Report created

**Approach**: Use as template for other commands (simplest pattern)

### /research-plan (3 hours)

**Missing markers**:
- 1 EXECUTE NOW: Project directory detection
- 1 EXECUTE NOW: Directory creation
- 1 EXECUTE NOW: Path calculation
- 1 MANDATORY VERIFICATION: Research reports
- 1 MANDATORY VERIFICATION: Plan file

**Approach**: Add markers sequentially following STEP order

### /research-revise (3 hours)

**Missing markers**:
- 1 EXECUTE NOW: Project directory detection
- 1 EXECUTE NOW: Directory creation
- 1 EXECUTE NOW: Backup creation
- 1 MANDATORY VERIFICATION: Backup file
- 1 MANDATORY VERIFICATION: Plan file

**Approach**: Similar to /research-plan with backup verification

### /build (4 hours)

**Missing markers**:
- 1 EXECUTE NOW: Project directory detection
- 1 EXECUTE NOW: Plan path calculation
- 1 MANDATORY VERIFICATION: Plan file exists
- 1 MANDATORY VERIFICATION: Implementation changes
- 1 MANDATORY VERIFICATION: Tests passed

**Approach**: Focus on implementation and test verification patterns

### /fix (4 hours)

**Missing markers**:
- 1 EXECUTE NOW: Project directory detection
- 1 EXECUTE NOW: Directory creation (debug/)
- 1 MANDATORY VERIFICATION: Research reports
- 1 MANDATORY VERIFICATION: Debug plan
- 1 MANDATORY VERIFICATION: Debug artifacts

**Approach**: Three-phase verification (research → plan → debug)

## Implementation Strategy

### Phase 1: Template Creation (2 hours)
1. Create "EXECUTE NOW" template (30 minutes)
2. Create "MANDATORY VERIFICATION" template (30 minutes)
3. Create combined pattern template (30 minutes)
4. Document usage guidelines (30 minutes)

### Phase 2: Sequential Command Implementation (12 hours)
1. /research-report: 2.5 hours (template validation)
2. /research-plan: 3 hours
3. /research-revise: 3 hours
4. /build: 4 hours
5. /fix: 4 hours
6. Buffer: 1.5 hours

**Total: 14 hours**

### Advantages of Sequential Approach

1. **Template refinement**: First implementation validates templates
2. **Pattern consistency**: Apply learned improvements to subsequent commands
3. **Risk reduction**: Test each command before moving to next
4. **Quality assurance**: Thorough testing per command

## Testing and Validation

### Test Protocol per Marker

**For EXECUTE NOW markers**:
```bash
# Test: Verify bash block executes
/[command-name] "test input" 2>&1 | grep "✓ Project directory:"
# Expected: Success message appears

# Test: Verify error handling
# (simulate failure condition)
# Expected: CRITICAL ERROR message and exit 1
```

**For MANDATORY VERIFICATION markers**:
```bash
# Test: Verify checkpoint executes
/[command-name] "test input" 2>&1 | grep "✓ VERIFIED:"
# Expected: Verification success message

# Test: Verify fail-fast on missing file
# (delete expected file before verification)
# Expected: CRITICAL ERROR message and exit 1
```

### Success Criteria

**Per Command**:
- [ ] All EXECUTE NOW markers added with WHY explanations
- [ ] All MANDATORY VERIFICATION markers added with CHECKPOINT statements
- [ ] All bash blocks include error handling
- [ ] All verifications include fail-fast logic
- [ ] Command executes successfully with all markers

**Overall Project**:
- [ ] 13/13 EXECUTE NOW markers added
- [ ] 13/13 MANDATORY VERIFICATION markers added
- [ ] 100% of critical operations have formal markers
- [ ] Standard 0 compliance: 100%

## Expected Outcomes

### Before Remediation

- **Formal enforcement**: 0% (no markers)
- **Execution consistency**: Variable (depends on Claude interpretation)
- **Error clarity**: Low (generic error messages)
- **Standard 0 compliance**: 36%

### After Remediation

- **Formal enforcement**: 100% (all markers present)
- **Execution consistency**: High (formal contracts)
- **Error clarity**: High (specific error messages with context)
- **Standard 0 compliance**: 95%+

### ROI Analysis

**Investment**: 14 hours
**Return**:
- Improved execution consistency
- Better error messages
- Clearer requirements
- Standard compliance
- Reduced debugging time (clearer failure points)

**Payback period**: Immediate (first debugging session)

## References

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (lines 84-92: Standard 0 requirements)
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (lines 353-386: Verification Checkpoints pattern)
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (lines 272-311: EXECUTE NOW pattern)

### Source Reports
- `/home/benjamin/.config/.claude/specs/15_research_the_compliance_of_build_fix_research_repo/reports/005_compliance_summary_and_recommendations.md` (lines 135-195: Missing enforcement markers)
- `/home/benjamin/.config/.claude/specs/15_research_the_compliance_of_build_fix_research_repo/debug/002_compliance_issues_summary.md` (lines 119-149: Execution enforcement gap)

### Reference Implementation
- `/home/benjamin/.config/.claude/commands/debug.md` (100/100 compliance - reference model)
- `/home/benjamin/.config/.claude/commands/expand.md` (100/100 compliance - excellent verification patterns)

## Conclusion

Adding execution enforcement markers to all 26 missing instances across 5 commands will transform optional guidance into formal execution contracts, improving consistency, error clarity, and Standard 0 compliance. The sequential implementation strategy (starting with simplest command) enables template validation and pattern refinement before scaling to more complex commands. The 14-hour investment provides immediate ROI through improved execution reliability and reduced debugging time, with long-term benefits from standardized enforcement patterns across all workflow commands.
