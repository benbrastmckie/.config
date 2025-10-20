# Phase 2.5: Fix Priority Subagent Prompts - Detailed Implementation

## Metadata
- **Phase Number**: 2.5
- **Parent Plan**: 001_execution_enforcement_fix.md
- **Objective**: Strengthen 6 priority subagent prompts with execution enforcement patterns
- **Dependencies**: [Phase 1]
- **Complexity**: Medium
- **Risk**: Low (agents are invoked by commands, not standalone)
- **Estimated Time**: 8-10 hours
- **Status**: PENDING

## Overview

This phase applies execution enforcement patterns to 6 priority subagent prompt files identified through research. Each agent suffers from similar issues: descriptive "I am" language, optional file creation, passive voice, and conditional directives.

### Priority Agents (Based on Research)

1. **research-specialist.md** - Most frequently invoked, critical file creation gap
2. **plan-architect.md** - Extensive docs but lacks enforcement markers
3. **code-writer.md** - Describes capabilities but no step sequencing enforcement
4. **spec-updater.md** - "Verify links" is optional, should be mandatory
5. **implementation-researcher.md** - Good structure but missing "EXECUTE NOW"
6. **debug-analyst.md** - Clear format but no execution enforcement

### Common Enforcement Patterns

**Pattern 1: Role Description**
- **Before**: "I am a specialized agent focused on..."
- **After**: "**YOU MUST perform these exact steps:**"

**Pattern 2: File Creation**
- **Before**: "Create structured markdown report files using Write tool"
- **After**: "**EXECUTE NOW - Create Report File** (ABSOLUTE REQUIREMENT)"

**Pattern 3: Verification**
- **Before**: "Verify links after moving"
- **After**: "**MANDATORY VERIFICATION - All Links Functional**"

**Pattern 4: Sequential Steps**
- **Before**: Numbered list without dependencies
- **After**: "**STEP N (REQUIRED BEFORE STEP N+1)**"

**Pattern 5: Conditional Language**
- **Before**: "should", "may", "can"
- **After**: "MUST", "WILL", "SHALL"

## Agent-Specific Implementations

### Agent 1: research-specialist.md

**Location**: `.claude/agents/research-specialist.md`

**Current Problems**:
- Uses "I am" declaration
- File creation described but not enforced
- No path pre-calculation enforcement
- No verification checkpoint

**Specific Changes**:

**1. Replace Role Section (lines ~1-15)**

**Before**:
```markdown
I am a specialized agent focused on thorough research and analysis.

My role is to:
- Investigate the codebase for patterns
- Create structured markdown report files using Write tool
- Emit progress markers during research
```

**After**:
```markdown
**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)

---

## Research Execution Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Pre-Calculate Report Path

**EXECUTE NOW - Calculate Exact File Path**

BEFORE conducting any research, YOU MUST calculate the exact absolute path where you will write the report:

\`\`\`bash
# This path will be provided by the invoking command
# Example: REPORT_PATH="/home/user/.claude/specs/067_topic/reports/001_patterns.md"
REPORT_PATH="[PATH PROVIDED BY INVOKING COMMAND]"

echo "Report will be written to: $REPORT_PATH"
\`\`\`

**VERIFICATION**: Confirm path is absolute (starts with /)

---

### STEP 2 (REQUIRED BEFORE STEP 3) - Create Report File FIRST

**EXECUTE NOW - Create Report File** (Do this BEFORE research)

**ABSOLUTE REQUIREMENT**: YOU MUST create the report file NOW using the Write tool. Create it with initial structure, then fill in findings during research.

\`\`\`markdown
# [Topic] Research Report

## Metadata
- **Date**: [current date]
- **Agent**: research-specialist
- **Topic**: [topic]

## Findings

[Research findings will be added below]

## Recommendations

[Recommendations will be added after analysis]
\`\`\`

**CRITICAL**: Use Write tool with the EXACT path from Step 1. File MUST exist before proceeding.

---

### STEP 3 (REQUIRED BEFORE STEP 4) - Conduct Research

**NOW that file is created**, YOU MUST conduct the research:

1. Search for relevant files and patterns
2. Analyze findings
3. WRITE findings DIRECTLY into the report file (use Edit tool to update)
4. Document recommendations

**PROGRESS MARKERS** (Emit these as you work):
\`\`\`
PROGRESS: Starting research for [topic]
PROGRESS: Found [N] relevant files
PROGRESS: Analyzing patterns...
PROGRESS: Writing findings to report
PROGRESS: Research complete
\`\`\`

---

### STEP 4 (ABSOLUTE REQUIREMENT) - Verify and Confirm

**MANDATORY VERIFICATION - Report File Exists**

After completing research, YOU MUST verify the report file exists:

\`\`\`bash
# Verify file exists at expected path
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL ERROR: Report file not found at: $REPORT_PATH"
  exit 1
fi

echo "✓ VERIFIED: Report file exists"
\`\`\`

**CHECKPOINT REQUIREMENT**: Return ONLY this confirmation:

\`\`\`
REPORT_CREATED: [EXACT ABSOLUTE PATH FROM STEP 1]
\`\`\`

**DO NOT** return summary text. The orchestrator will read your report file.
```

**Changes Made**:
- Removed "I am" declaration
- Added "**YOU MUST perform these exact steps**"
- Added 4-step process with dependencies
- Added "**EXECUTE NOW**" markers for file operations
- Added "**MANDATORY VERIFICATION**" checkpoint
- Added "**ABSOLUTE REQUIREMENT**" language
- Added path pre-calculation step
- Added file-first approach (create before research)
- Added verification before returning

---

### Agent 2: plan-architect.md

**Location**: `.claude/agents/plan-architect.md`

**Current Problems**:
- Extensive documentation but weak enforcement
- No explicit "create plan file" requirement
- Complexity calculation not enforced
- Report verification advisory

**Key Changes**:

**Add After Role Description**:
```markdown
## Plan Generation Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Verify Research Reports

**MANDATORY VERIFICATION - All Research Reports Exist**

YOU MUST verify ALL research reports listed in the /plan command invocation exist before proceeding:

\`\`\`bash
# Research report paths provided by command
RESEARCH_REPORTS=([paths from command])

for report in "${RESEARCH_REPORTS[@]}"; do
  if [ ! -f "$report" ]; then
    echo "CRITICAL ERROR: Research report not found: $report"
    exit 1
  fi
  echo "✓ Verified: $report"
done

echo "✓ VERIFIED: All ${#RESEARCH_REPORTS[@]} research reports exist"
\`\`\`

---

### STEP 2 (REQUIRED BEFORE STEP 3) - Calculate Plan Path

**EXECUTE NOW - Calculate Plan File Path**

\`\`\`bash
# Plan path will be calculated by /plan command
# You will be provided the exact path
PLAN_PATH="[PATH PROVIDED BY /PLAN COMMAND]"

echo "Plan will be created at: $PLAN_PATH"
\`\`\`

---

### STEP 3 (ABSOLUTE REQUIREMENT) - Create Plan File

**EXECUTE NOW - Create Plan File at Exact Path**

YOU MUST use the Write tool to create the plan file at the path from Step 2.

[Include standard plan template]

**CRITICAL**: File MUST exist at $PLAN_PATH when you complete.

---

### STEP 4 (MANDATORY) - Calculate Complexity

**MANDATORY - Complexity Calculation MUST Execute**

After creating the plan, YOU MUST calculate complexity for each phase:

[Complexity calculation logic]

**This is NOT optional**. Plans without complexity scores are incomplete.

---

### STEP 5 (VERIFICATION) - Verify Plan Complete

**MANDATORY VERIFICATION - Plan File Created**

\`\`\`bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "CRITICAL ERROR: Plan file not created"
  exit 1
fi

# Verify required sections exist
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases")
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    echo "ERROR: Missing section: $section"
    exit 1
  fi
done

echo "✓ VERIFIED: Plan file complete"
\`\`\`

**CHECKPOINT**: Return plan path confirmation
```

**Changes Made**:
- Added 5-step sequential process
- Added research report verification (Step 1)
- Added plan path calculation (Step 2)
- Made file creation mandatory (Step 3)
- Made complexity calculation mandatory (Step 4)
- Added verification checkpoint (Step 5)

---

### Agent 3: code-writer.md

**Location**: `.claude/agents/code-writer.md`

**Current Problems**:
- Describes capabilities but doesn't enforce execution
- Test running is optional
- No sequential step enforcement

**Key Changes**:

**Add Implementation Process**:
```markdown
## Code Implementation Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Read Current Code

**EXECUTE NOW - Read Files to Modify**

YOU MUST read all files you will modify BEFORE making changes:

\`\`\`bash
for file in "${FILES_TO_MODIFY[@]}"; do
  # Read tool will error if file doesn't exist
  echo "Reading: $file"
done

echo "✓ All files read"
\`\`\`

---

### STEP 2 (REQUIRED BEFORE STEP 3) - Apply Code Changes

**EXECUTE NOW - Apply Changes to Files**

For each file, YOU MUST apply the specified changes using Edit or Write tool:

**CRITICAL**: Follow coding standards from CLAUDE.md

---

### STEP 3 (ABSOLUTE REQUIREMENT) - Run Tests

**YOU MUST RUN TESTS - Non-Negotiable Verification**

After ALL code changes applied, YOU MUST run tests:

\`\`\`bash
# Test command from CLAUDE.md or plan
TEST_COMMAND="[from standards or plan]"

echo "Running tests..."
$TEST_COMMAND

# Capture test result
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo "❌ TESTS FAILED"
  echo "Exit code: $TEST_EXIT_CODE"
  # Return failure status
else
  echo "✓ TESTS PASSED"
fi
\`\`\`

**MANDATORY**: Tests MUST run. Do NOT skip this step.

---

### STEP 4 (VERIFICATION) - Confirm Changes Applied

**MANDATORY VERIFICATION - All Changes Applied and Tested**

\`\`\`bash
# Verify all files modified
for file in "${FILES_TO_MODIFY[@]}"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: File missing: $file"
    exit 1
  fi
done

echo "✓ VERIFIED: All files modified"
echo "✓ VERIFIED: Tests executed"
echo "Test result: [PASSED/FAILED]"
\`\`\`

**CHECKPOINT**: Return status with test results
```

**Changes Made**:
- Added 4-step sequential process
- Made reading files first (Step 1)
- Made changes explicit (Step 2)
- Made test running MANDATORY (Step 3)
- Added verification checkpoint (Step 4)
- Added "**YOU MUST RUN TESTS**" enforcement

---

### Agent 4: spec-updater.md

**Location**: `.claude/agents/spec-updater.md`

**Current Problems**:
- "Verify links" is advisory
- No mandatory utility sourcing
- No fallback for verification failures

**Key Changes**:

**Add At Beginning**:
```markdown
## Spec Update Process

### STEP 1 (ABSOLUTE REQUIREMENT) - Source Utilities FIRST

**MANDATORY: Source Utilities BEFORE Any Operations**

YOU MUST source required utilities BEFORE performing any spec updates:

\`\`\`bash
# CRITICAL: Source utilities first
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-hierarchy-utils.sh"

echo "✓ Utilities sourced"
\`\`\`

**If sourcing fails**, DO NOT proceed with spec updates.

---

### STEP 2 (REQUIRED) - Perform Spec Updates

[Existing spec update logic]

---

### STEP 3 (ABSOLUTE REQUIREMENT) - Verify All Links Functional

**MANDATORY VERIFICATION - All Links Functional**

After moving or updating files, YOU MUST verify ALL links are functional:

\`\`\`bash
# Verify links in updated files
BROKEN_LINKS=()

for file in "${UPDATED_FILES[@]}"; do
  # Extract all markdown links
  LINKS=$(grep -oP '\[.*?\]\(\K[^\)]+' "$file")

  for link in $LINKS; do
    # Convert relative to absolute
    if [[ ! "$link" =~ ^/ ]] && [[ ! "$link" =~ ^http ]]; then
      link="$(dirname "$file")/$link"
    fi

    # Check if link target exists
    if [[ "$link" =~ ^http ]]; then
      # Skip URL links (can't verify)
      continue
    elif [ ! -f "$link" ] && [ ! -d "$link" ]; then
      BROKEN_LINKS+=("$file: $link")
    fi
  done
done

if [ ${#BROKEN_LINKS[@]} -gt 0 ]; then
  echo "❌ BROKEN LINKS DETECTED:"
  for broken in "${BROKEN_LINKS[@]}"; do
    echo "  - $broken"
  done

  # FALLBACK: Try to fix broken links
  echo "Attempting to fix broken links..."
  [fix logic]
fi

echo "✓ VERIFIED: All links functional"
\`\`\`

**FALLBACK**: If verification fails and auto-fix fails, return error status.

**This verification is NOT optional**.
```

**Changes Made**:
- Added Step 1: MANDATORY utility sourcing
- Changed "Verify links" to "**MANDATORY VERIFICATION**"
- Added broken link detection code
- Added fallback mechanism
- Made verification non-optional

---

### Agent 5: implementation-researcher.md

**Location**: `.claude/agents/implementation-researcher.md`

**Current Problems**:
- Good structure but missing enforcement markers
- No explicit artifact creation requirement
- No verification checkpoint

**Key Changes**:

**Add Exploration Process**:
```markdown
## Codebase Exploration Process

### STEP 1 (REQUIRED) - Explore Codebase

[Existing exploration logic]

---

### STEP 2 (ABSOLUTE REQUIREMENT) - Create Exploration Artifact

**EXECUTE NOW - Create Exploration Artifact File**

**ABSOLUTE REQUIREMENT**: YOU MUST create an exploration artifact file documenting your findings.

\`\`\`bash
# Artifact path provided by command
ARTIFACT_PATH="[PATH PROVIDED BY COMMAND]"

echo "Creating exploration artifact at: $ARTIFACT_PATH"
\`\`\`

**Use Write tool to create artifact**:

[Artifact template]

**CRITICAL**: File MUST exist at $ARTIFACT_PATH before returning.

---

### STEP 3 (VERIFICATION) - Verify Artifact Created

**MANDATORY VERIFICATION - Artifact Exists**

\`\`\`bash
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "CRITICAL ERROR: Artifact not created"
  exit 1
fi

echo "✓ VERIFIED: Artifact exists"
\`\`\`

**CHECKPOINT - Artifact Path Confirmed**

Return confirmation:
\`\`\`
ARTIFACT_CREATED: [ABSOLUTE PATH]
\`\`\`
```

**Changes Made**:
- Added Step 2: ABSOLUTE REQUIREMENT for artifact creation
- Added "**EXECUTE NOW**" marker
- Added Step 3: Verification checkpoint
- Made artifact creation non-optional

---

### Agent 6: debug-analyst.md

**Location**: `.claude/agents/debug-analyst.md`

**Current Problems**:
- Clear format but no execution enforcement
- Issue reproduction not enforced
- Debug report creation optional

**Key Changes**:

**Add Debug Process**:
```markdown
## Debug Analysis Process

### STEP 1 (ABSOLUTE REQUIREMENT) - Reproduce Issue FIRST

**EXECUTE NOW - Reproduce Issue BEFORE Analysis**

YOU MUST reproduce the issue BEFORE analyzing root cause:

\`\`\`bash
# Attempt to reproduce the issue
echo "Attempting to reproduce issue..."

[Reproduction steps from description]

# Document reproduction status
if [issue reproduced]; then
  echo "✓ Issue reproduced"
  REPRODUCED=true
else
  echo "⚠️  Could not reproduce issue"
  REPRODUCED=false
fi
\`\`\`

**YOU MUST document exact steps to reproduce** (or why reproduction failed).

---

### STEP 2 (REQUIRED) - Analyze Root Cause

[Existing analysis logic]

---

### STEP 3 (ABSOLUTE REQUIREMENT) - Create Debug Report

**MANDATORY - Create Debug Report File**

**EXECUTE NOW - Create Debug Report**

\`\`\`bash
DEBUG_REPORT_PATH="[PATH PROVIDED BY COMMAND]"

echo "Creating debug report at: $DEBUG_REPORT_PATH"
\`\`\`

**Use Write tool to create report**:

[Debug report template]

**CRITICAL**: File MUST exist at $DEBUG_REPORT_PATH.

---

### STEP 4 (VERIFICATION) - Verify Report Created

**MANDATORY VERIFICATION - Debug Report Exists**

\`\`\`bash
if [ ! -f "$DEBUG_REPORT_PATH" ]; then
  echo "CRITICAL ERROR: Debug report not created"
  exit 1
fi

echo "✓ VERIFIED: Debug report exists"
\`\`\`

**CHECKPOINT**: Return confirmation
```

**Changes Made**:
- Added Step 1: MANDATORY issue reproduction
- Added "**YOU MUST document exact steps**"
- Added Step 3: MANDATORY report creation
- Added Step 4: Verification checkpoint

---

## Testing Strategy

### Test Scenarios

**Test 1: Invoke Each Agent Through Parent Command**
```bash
# Test research-specialist through /orchestrate or /report
# Test plan-architect through /plan
# Test code-writer through /implement
# Test spec-updater through /implement (hierarchy updates)
# Test implementation-researcher through /implement (complex phases)
# Test debug-analyst through /debug

# Expected: All agents create required files
# Metric: File creation rate = 100%
```

**Test 2: Verify File Creation Rate**
```bash
# Invoke each agent 10 times
# Count successful file creations
# Target: 100% (10/10 for each agent)
```

**Test 3: Verify Checkpoint Reporting**
```bash
# Verify each agent returns required confirmation format
# Example: "REPORT_CREATED: /path/to/file.md"
# Verify orchestrator can parse confirmations
```

**Test 4: Verify Sequential Step Enforcement**
```bash
# Verify agents execute steps in order
# Verify dependencies respected (STEP N before STEP N+1)
# Verify file creation happens before research (not after)
```

**Test 5: Test Fallback Mechanisms**
```bash
# For agents with fallbacks (spec-updater link verification)
# Simulate failure conditions
# Verify fallback triggers
# Verify fallback succeeds
```

## Validation Checklist

Before marking Phase 2.5 complete:

### Language Conversion
- [ ] All "I am" declarations removed
- [ ] All converted to "YOU MUST" directives
- [ ] All passive voice eliminated
- [ ] All conditional language ("should", "may") replaced with "MUST"

### File Creation Enforcement
- [ ] All file operations have "EXECUTE NOW" markers
- [ ] Path pre-calculation added where applicable
- [ ] File-first approach enforced (create before processing)
- [ ] All file creation marked "ABSOLUTE REQUIREMENT"

### Verification Checkpoints
- [ ] All agents have "MANDATORY VERIFICATION" sections
- [ ] Verification code provided (not just description)
- [ ] Checkpoint reporting added (return confirmation)
- [ ] Fallback mechanisms added where applicable

### Sequential Steps
- [ ] All agents use "STEP N (REQUIRED BEFORE STEP N+1)" format
- [ ] Dependencies explicitly stated
- [ ] No ambiguous ordering

### File Updates
- [ ] All 6 agent files updated
- [ ] research-specialist.md: 4-step process
- [ ] plan-architect.md: 5-step process
- [ ] code-writer.md: 4-step process with test enforcement
- [ ] spec-updater.md: 3-step process with link verification
- [ ] implementation-researcher.md: 3-step process with artifact creation
- [ ] debug-analyst.md: 4-step process with reproduction enforcement

### Testing
- [ ] All 5 test scenarios executed
- [ ] File creation rate: 100% for all agents
- [ ] Checkpoint reporting: 100% compliance
- [ ] Sequential steps: Verified in order
- [ ] Fallbacks: Tested and working

## Success Metrics

**File Creation Rate**:
- Before: ~60-80% (varies by agent and context)
- After: 100% (guaranteed by enforcement + orchestrator fallback)
- Improvement: +20-40 percentage points

**Agent Compliance**:
- Step execution: 100% (sequential enforcement)
- Checkpoint reporting: 100% (mandatory)
- Verification execution: 100% (mandatory)

**Context Reduction** (maintained):
- Agents still return confirmations only (not full content)
- Orchestrator reads files directly
- No degradation in context management

## Next Phase

After completing Phase 2.5:
- Proceed to Phase 3: Create Command Audit Framework
- Phases 3 and 4 do NOT need expansion (straightforward)
- Proceed to Phase 5: Fix High-Priority Commands (needs expansion)

---

**Phase 2.5 Status**: PENDING
**Last Updated**: 2025-10-19
**Parent Plan**: 001_execution_enforcement_fix.md
