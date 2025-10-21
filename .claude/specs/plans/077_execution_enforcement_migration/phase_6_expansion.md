# Phase 6 Expansion: Command Migration - /implement

## Phase Metadata
- **Phase Number**: 6
- **Phase Name**: Command Migration - Tier 1 Critical (/implement)
- **Parent Plan**: 077_execution_enforcement_migration.md
- **Complexity**: Very High (9/10)
- **Duration**: 14 hours
- **Wave**: Week 3-4 (Day 5, Week 4 Days 1-2)
- **Critical Feature**: Triple role (coordinator, executor, orchestrator)

## Overview

This phase migrates the `/implement` command to full execution enforcement compliance using Standard 0 patterns, with special emphasis on Phase 0 role clarification for its unique triple-role architecture. The `/implement` command is the most complex command in the system, acting as:

1. **Phase Coordinator** (always): Manages workflow state, checkpoints, progress tracking
2. **Direct Executor** (simple phases, complexity <8): Executes implementation directly using Read/Edit/Write tools
3. **Agent Orchestrator** (complex phases, complexity ≥8): Delegates to specialized agents (implementation-researcher, code-writer, debug-specialist, doc-writer)

This complexity requires careful Phase 0 implementation to clarify when Claude executes directly vs. when it orchestrates agents, preventing the root cause issue: ambiguous language leading to direct execution when orchestration is intended.

## Objectives

### Primary Objectives
1. Add comprehensive Phase 0 role clarification with adaptive YOUR ROLE section
2. Add Phase 0 enforcement before all agent invocation sections
3. Transform all section headers to STEP N format with EXECUTE NOW markers
4. Verify all agent invocation templates include enforcement markers
5. Ensure existing enforcement patterns (Patterns 1-4) remain intact
6. Achieve audit score ≥95/100 and 100% file creation rate

### Success Criteria
- [ ] Phase 0 opening clearly distinguishes all three roles
- [ ] Adaptive YOUR ROLE section present with complexity-based guidance
- [ ] Phase 0 enforcement before implementation-researcher invocation
- [ ] Phase 0 enforcement before debug-specialist invocation
- [ ] Phase 0 enforcement before doc-writer invocation
- [ ] All section headers converted to STEP N (REQUIRED BEFORE STEP N+1) format
- [ ] EXECUTE NOW markers present on all bash code blocks
- [ ] AGENT INVOCATION markers before all Task blocks
- [ ] All 5 agent invocation types verified (implementation-researcher, code-writer, debug-specialist, doc-writer, spec-updater)
- [ ] Existing patterns verified intact (path pre-calculation, verification checkpoints, fallback mechanisms, checkpoint reporting)
- [ ] Audit score ≥95/100
- [ ] File creation rate 100% (10/10 test runs)
- [ ] All three roles tested independently (coordinator, executor, orchestrator)

## Technical Context

### Command Architecture

The `/implement` command is 1796 lines and contains:
- **Workflow coordination**: Checkpoint management, progress tracking, resume logic
- **Direct execution**: Read/Edit/Write operations for simple phases
- **Agent orchestration**: 5 different agent types invoked conditionally
- **Adaptive planning**: Automatic replanning via /revise --auto-mode
- **Wave execution**: Parallel phase execution with dependency management
- **Hierarchical updates**: Spec-updater integration for plan hierarchy
- **Error handling**: 4-level tiered recovery with automatic debug integration

### Agent Invocation Points

1. **Implementation-Researcher** (Step 1.57, lines ~690-906)
   - Trigger: Complexity ≥8 OR task count >10
   - Purpose: Codebase exploration before complex phases
   - Template: Lines 736-773

2. **Code-Writer** (Step 1.6, lines ~356-414)
   - Trigger: Complexity 3-10 (mandatory for score ≥3)
   - Purpose: Phase implementation
   - Template: Lines 369-410

3. **Debug-Specialist** (Step 3.3, lines ~948-1091)
   - Trigger: Test failures
   - Purpose: Automated root cause analysis
   - Template: Lines 993-1033

4. **Doc-Writer** (Agent Selection, special case)
   - Trigger: Documentation phases (regardless of complexity)
   - Purpose: Documentation creation/updates
   - Template: Referenced in agent selection logic

5. **Spec-Updater** (Plan Hierarchy Update, lines ~433-553)
   - Trigger: After every phase completion
   - Purpose: Update plan checkboxes across hierarchy
   - Template: Lines 442-473

### Existing Enforcement Patterns

**Pattern 1: Path Pre-calculation** (Multiple locations)
- EXECUTE NOW blocks before agent invocations
- Pre-calculate artifact paths, specs directories, file lists
- Examples: Lines 87-132, 449-589, 722-751

**Pattern 2: Verification Checkpoints** (Multiple locations)
- MANDATORY VERIFICATION blocks after critical operations
- Fallback mechanisms for 100% success
- Examples: Lines 118-142, 487-553, 791-834

**Pattern 3: Fallback Mechanisms** (Multiple locations)
- Direct utility invocation if agent fails
- Guaranteed completion via alternative paths
- Examples: Lines 506-512, 812-834, 1009-1033

**Pattern 4: Checkpoint Reporting** (Multiple locations)
- CHECKPOINT REQUIREMENT blocks
- Progress visibility and workflow monitoring
- Examples: Lines 1183-1207, 1404-1437, 1605-1616

### Complexity-Based Agent Selection

From Step 1.5 (Hybrid Complexity Evaluation):
- Threshold-based scoring (complexity-utils.sh)
- Agent evaluation for borderline cases (≥7 OR ≥8 tasks)
- Exported $COMPLEXITY_SCORE used downstream

Agent selection logic (Step 1.6):
- Score 0-2: Direct execution (no agent)
- Score 3-5: code-writer agent (standard)
- Score 6-7: code-writer + extended thinking
- Score 8-9: code-writer + deep analysis
- Score 10+: code-writer + maximum reasoning

Special overrides:
- Documentation phases → doc-writer (regardless of score)
- Testing phases → test-specialist (regardless of score)
- Debug phases → debug-specialist (regardless of score)

## Detailed Task Breakdown

### Task Group 6.1: Add Phase 0 Opening (3 hours)

**Objective**: Replace ambiguous opening with clear triple-role clarification

#### 6.1.1: Analyze Current Opening (30 minutes)

**Current State** (lines 11-18):
```markdown
**YOU MUST perform systematic implementation following this exact process:**

**CRITICAL INSTRUCTIONS**:
- Execute phases in EXACT sequential order
- DO NOT skip testing after each phase
- DO NOT skip git commits
- DO NOT proceed if tests fail (unless debugging mode)
- MANDATORY: Update plan file after each phase
```

**Issues**:
- No role clarification (orchestrator vs executor)
- Ambiguous "perform systematic implementation"
- Doesn't explain when to use agents vs direct execution
- Missing adaptive behavior description

#### 6.1.2: Draft Phase 0 Opening (1 hour)

**New Opening Structure**:

```markdown
# Execute Implementation Plan

**YOU MUST orchestrate or execute implementation following this exact process:**

**YOUR ROLE - ADAPTIVE BASED ON PHASE COMPLEXITY**:

You are the implementation manager with THREE distinct roles that activate conditionally:

1. **Phase Coordinator** (ALWAYS ACTIVE):
   - **DO**: Manage workflow state, checkpoints, progress tracking
   - **DO**: Update plan files and hierarchy after each phase
   - **DO**: Run tests and create git commits
   - **DO NOT**: Skip testing, commits, or plan updates
   - **Tools**: checkpoint-utils.sh, checkbox-utils.sh, progress-dashboard.sh

2. **Direct Executor** (FOR SIMPLE PHASES - Complexity Score <3):
   - **WHEN**: Phase complexity score <3 (from Step 1.5 hybrid evaluation)
   - **DO**: Execute implementation yourself using Read/Edit/Write tools
   - **DO**: Apply coding standards from CLAUDE.md
   - **DO NOT**: Invoke agents for simple tasks
   - **Tools**: Read, Edit, Write, Bash

3. **Agent Orchestrator** (FOR COMPLEX PHASES - Complexity Score ≥3):
   - **WHEN**: Phase complexity score ≥3 (from Step 1.5 hybrid evaluation)
   - **DO**: Delegate implementation to specialized agents
   - **DO**: Invoke implementation-researcher for exploration (score ≥8)
   - **DO**: Invoke code-writer for implementation (score 3-10)
   - **DO**: Invoke debug-specialist for test failures
   - **DO**: Invoke doc-writer for documentation phases
   - **DO NOT**: Execute complex implementation yourself
   - **DO NOT**: Use Read/Grep/Write for tasks requiring agent expertise
   - **Tools**: Task tool with behavioral injection

**CRITICAL ROLE SWITCHING**:
- Role switches automatically based on $COMPLEXITY_SCORE from Step 1.5
- YOU WILL NOT see implementation details when orchestrating (agents work independently)
- YOUR JOB when orchestrating: Invoke agents → Verify outputs → Update plan
- YOUR JOB when executing: Read files → Make changes → Test changes

**EXECUTION FLOW**:
1. STEP 1: Evaluate phase complexity (hybrid_complexity_evaluation)
2. STEP 2: Switch to appropriate role based on complexity score
3. STEP 3: Execute or orchestrate implementation
4. STEP 4: Run tests and verify success
5. STEP 5: Update plan hierarchy and create git commit
```

**Key Additions**:
- Explicit role enumeration with activation conditions
- Clear DO/DO NOT directives for each role
- Complexity score as the switching mechanism
- Tool lists for each role
- Role switching explanation
- Execution flow overview

#### 6.1.3: Add Adaptive YOUR ROLE Section (1 hour)

**Location**: After opening, before "Plan Information" section (insert after line 18)

**Content**:

```markdown
## Adaptive Role Clarification

**BEFORE EACH PHASE, YOU MUST:**

1. **Read complexity score** from Step 1.5 hybrid evaluation ($COMPLEXITY_SCORE)
2. **Identify active role** based on score and phase type
3. **Switch execution mode** to match role

**Role Decision Tree**:

```
┌─────────────────────────────────────────────────────────┐
│ Phase Complexity Evaluation (Step 1.5)                  │
│ → $COMPLEXITY_SCORE exported                            │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ $COMPLEXITY_SCORE ?  │
              └──────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
     Score 0-2      Score 3-7      Score 8-10
  ┌─────────────┐ ┌────────────┐ ┌─────────────┐
  │   Direct    │ │ Orchestrate│ │ Orchestrate │
  │  Execution  │ │ code-writer│ │ code-writer │
  │             │ │            │ │ + researcher│
  └─────────────┘ └────────────┘ └─────────────┘
       │              │              │
       └──────────────┼──────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
  Special Overrides        Tests Fail?
  ┌──────────────┐         ┌──────────┐
  │ Doc phase?   │─Yes─→   │ Invoke   │
  │ → doc-writer │         │  debug   │
  └──────────────┘         └──────────┘
```

**Special Case Overrides** (TAKE PRECEDENCE over complexity score):
- Documentation phase → Use doc-writer agent (any complexity)
- Testing phase → Use test-specialist agent (any complexity)
- Debug phase → Use debug-specialist agent (any complexity)
- Test failure → Auto-invoke debug-specialist (Step 3.3)
- After phase complete → Invoke spec-updater (Plan Hierarchy Update)

**Example Phase Execution**:

**Simple Phase** (complexity 2):
```
Phase 4: Add utility function
→ Complexity: 2/10 (threshold calculation)
→ Role: Direct Executor
→ Action: Read utils.sh → Add function → Test → Commit
→ Tools: Read, Edit, Write, Bash
```

**Complex Phase** (complexity 8):
```
Phase 3: Database integration
→ Complexity: 8/10 (hybrid: threshold=7, agent=9, reconciled=8)
→ Role: Agent Orchestrator
→ Action: Invoke implementation-researcher → Invoke code-writer → Verify outputs
→ Tools: Task (with behavioral injection)
```

**Documentation Phase** (complexity 5, but special override):
```
Phase 6: Update documentation
→ Complexity: 5/10
→ Role: Agent Orchestrator (override)
→ Action: Invoke doc-writer agent
→ Reason: Documentation phases always use doc-writer (special case override)
```
```

**Key Features**:
- Visual decision tree for role selection
- Concrete examples for each role
- Special case overrides clearly marked
- Complexity score integration

#### 6.1.4: Test Opening Updates (30 minutes)

**Test Plan**:

1. **Visual inspection**:
   - Read updated opening section
   - Verify three roles clearly enumerated
   - Check decision tree renders correctly
   - Confirm examples are concrete

2. **Audit score check**:
   ```bash
   .claude/lib/audit-execution-enforcement.sh .claude/commands/implement.md | grep "Phase 0"
   # Expected: Phase 0 score improved (baseline → 10/15 points)
   ```

3. **Comprehension test**:
   - Manually walk through decision tree with test cases
   - Verify role selection logic is unambiguous
   - Confirm special overrides are clear

**Deliverable**:
- Updated opening section (lines 11-18 → ~80 lines)
- Adaptive YOUR ROLE section (new, ~100 lines)
- Phase 0 score: 0/15 → 10/15 (baseline established)

---

### Task Group 6.2: Add Phase 0 to Complex Phase Sections (4 hours)

**Objective**: Add Phase 0 enforcement before all agent invocation sections

#### 6.2.1: Before Implementation-Researcher Invocation (1.5 hours)

**Location**: Step 1.57 (lines 688-906)

**Current State**:
- Section titled "### 1.57. Implementation Research Agent Invocation"
- Contains threshold checks, agent invocation template, metadata extraction
- Missing Phase 0 role clarification

**Phase 0 Addition** (insert before line 688):

```markdown
---

**PHASE 0 ROLE CLARIFICATION - Implementation Research**

**YOUR ROLE (for complex phases requiring research)**:

You are the RESEARCH ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS FOR STEP 1.57**:

1. **DO NOT execute research yourself** when complexity ≥8 OR tasks >10
   - DO NOT use Read/Grep tools to explore codebase
   - DO NOT analyze existing implementations directly
   - DO NOT identify patterns yourself

2. **ONLY use Task tool** to delegate to implementation-researcher agent
   - Agent will explore codebase and identify patterns
   - Agent will create artifact with findings
   - You will receive metadata only (path + summary)

3. **YOUR JOB**:
   - Calculate complexity threshold (Step 1.5 result)
   - Check if RESEARCH_NEEDED = true
   - Invoke implementation-researcher via Task tool
   - Extract artifact metadata via forward_message pattern
   - Store metadata for on-demand loading during implementation

**YOU WILL NOT see full research findings**:
- Agent returns metadata only (artifact path + 50-word summary)
- Full artifact loaded on-demand during implementation (if needed)
- Context reduction: 95% (2000 tokens → 100 tokens)

**WHEN THIS SECTION APPLIES**:
- Complexity score ≥8 (from Step 1.5)
- OR task count >10
- Purpose: Gather codebase context before implementation

**WHEN TO SKIP THIS SECTION**:
- Complexity score <8 AND task count ≤10
- Simple phases don't need research
- Continue to Step 1.6 (agent selection for implementation)

---
```

**Key Features**:
- Clear role: RESEARCH ORCHESTRATOR (not researcher)
- Three DO NOT directives (no direct research)
- ONLY use Task tool directive
- YOUR JOB enumeration (4 specific tasks)
- Metadata-only explanation
- When applies / when to skip conditions

**Testing**:
```bash
# Test 1: Verify Phase 0 presence
grep -A 20 "PHASE 0 ROLE CLARIFICATION - Implementation Research" .claude/commands/implement.md
# Expected: Phase 0 block found with all elements

# Test 2: Verify orchestration language
grep -E "(DO NOT execute research|ONLY use Task tool)" .claude/commands/implement.md
# Expected: Both directives present
```

#### 6.2.2: Before Debug-Specialist Invocation (1.5 hours)

**Location**: Step 3.3 (lines 948-1091) and Step E (lines 984-1039)

**Current State**:
- Section titled "### 3.3. Automatic Debug Integration (if tests fail)"
- Contains error classification, tiered recovery, /debug invocation
- Missing Phase 0 role clarification

**Phase 0 Addition** (insert before line 948):

```markdown
---

**PHASE 0 ROLE CLARIFICATION - Debug Integration**

**YOUR ROLE (when test failures occur)**:

You are the DEBUG ORCHESTRATOR, not the debugger.

**CRITICAL INSTRUCTIONS FOR STEP 3.3**:

1. **DO NOT debug failures yourself** when Level 4 triggered
   - DO NOT analyze error messages directly
   - DO NOT investigate root causes manually
   - DO NOT propose fixes yourself

2. **ONLY use SlashCommand tool** to invoke /debug command
   - /debug will coordinate debug-analyst agents
   - /debug will create structured debug report
   - You will receive report path for user choices

3. **YOUR JOB**:
   - Classify error type (error-handling.sh)
   - Execute tiered recovery (Levels 1-3)
   - Invoke /debug for Level 4 (complex failures)
   - Present user choices: (r)evise, (c)ontinue, (s)kip, (a)bort
   - Execute chosen action

**TIERED RECOVERY LEVELS**:
- **Level 1**: Error classification + suggestions (no retry)
- **Level 2**: Transient retry (timeout, busy, locked errors)
- **Level 3**: Tool fallback (reduced toolset retry)
- **Level 4**: Auto-invoke /debug (orchestration mode) ← THIS IS WHERE YOU ORCHESTRATE

**YOU WILL NOT see debug analysis directly**:
- /debug command creates report artifact
- You receive report path only
- User chooses action based on report
- If (r)evise chosen: Invoke /revise --auto-mode with debug findings

**WHEN THIS SECTION APPLIES**:
- Test failures in any phase
- Automatic trigger (no manual invocation needed)
- Applies after Levels 1-3 if still failing

**FALLBACK MECHANISM**:
- If /debug fails: Use analyze-error.sh utility (guaranteed report creation)
- Non-blocking: User choices presented regardless

---
```

**Additional Phase 0** (insert before STEP E, line 984):

```markdown
---

**STEP E (REQUIRED FOR TEST FAILURES) - Automatic /debug Invocation**

**PHASE 0 REMINDER - You are the DEBUG ORCHESTRATOR**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke /debug command when Level 4 triggered. This is NOT optional.

**WHY THIS MATTERS**: Automated root cause analysis identifies underlying issues systematically, reducing debugging time by 50%.

**WHAT YOU DO (orchestration only)**:
1. Invoke /debug via SlashCommand tool
2. Extract debug report path from response
3. Verify report created (or trigger fallback)
4. Present user choices with report context

**WHAT YOU DO NOT DO**:
- Analyze error yourself
- Investigate root causes directly
- Propose fixes without /debug analysis

---
```

**Key Features**:
- Clear role: DEBUG ORCHESTRATOR (not debugger)
- Three DO NOT directives (no direct debugging)
- ONLY use SlashCommand directive
- Tiered recovery levels enumeration
- Report path handling explanation
- Fallback mechanism guarantee

**Testing**:
```bash
# Test 1: Verify both Phase 0 blocks
grep -c "PHASE 0 ROLE CLARIFICATION - Debug" .claude/commands/implement.md
# Expected: 1 (main section)

grep -c "PHASE 0 REMINDER - You are the DEBUG ORCHESTRATOR" .claude/commands/implement.md
# Expected: 1 (STEP E section)

# Test 2: Verify orchestration directives
grep -E "(DO NOT debug|ONLY use SlashCommand)" .claude/commands/implement.md
# Expected: Both present
```

#### 6.2.3: Before Doc-Writer Invocation (1 hour)

**Location**: Agent Selection special case (lines ~360-368)

**Current State**:
- Special case override: "Documentation phases: Use doc-writer agent (regardless of score)"
- Referenced in agent selection logic but not implemented as separate section
- Need to add Phase 0 for clarity

**Phase 0 Addition** (insert in adaptive role section, after decision tree):

```markdown
**PHASE 0 ROLE CLARIFICATION - Documentation Phases**

**YOUR ROLE (when phase type = documentation)**:

You are the DOCUMENTATION ORCHESTRATOR, not the documentation writer.

**CRITICAL INSTRUCTIONS FOR DOCUMENTATION PHASES**:

1. **DO NOT write documentation yourself** regardless of complexity score
   - DO NOT use Write tool to create .md files
   - DO NOT update README files directly
   - DO NOT generate documentation content yourself

2. **ONLY use Task tool** to delegate to doc-writer agent
   - Agent will create/update documentation files
   - Agent will follow Documentation Policy from CLAUDE.md
   - You will verify documentation created

3. **YOUR JOB**:
   - Detect documentation phase (phase name contains "document", "docs", "README")
   - Invoke doc-writer agent via Task tool with phase context
   - Verify documentation files created (fallback if needed)
   - Update plan hierarchy after completion

**SPECIAL CASE OVERRIDE**:
- Documentation phases ALWAYS use doc-writer agent
- Complexity score IGNORED for this phase type
- Even simple documentation (complexity 2) uses agent
- Reason: Consistency in documentation format and standards compliance

**WHEN THIS APPLIES**:
- Phase name/description contains: "document", "docs", "README", "documentation"
- Phase tasks include creating/updating .md files
- Regardless of complexity score

**Agent Invocation Template** (use THIS EXACT TEMPLATE):
```
Task {
  subagent_type: "general-purpose"
  description: "Create/update documentation for Phase ${PHASE_NUM}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent.

    Create/update documentation for Phase ${PHASE_NUM}: ${PHASE_NAME}

    Plan: ${PLAN_PATH}
    Phase Tasks: ${TASK_LIST}
    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Follow Documentation Policy from standards.
    Return: List of files created/updated
}
```
```

**Key Features**:
- Clear role: DOCUMENTATION ORCHESTRATOR
- Three DO NOT directives (no direct writing)
- ONLY use Task tool directive
- Special case override explanation
- Detection logic (phase name patterns)
- Agent invocation template embedded

**Testing**:
```bash
# Test 1: Verify Phase 0 presence
grep -A 10 "PHASE 0 ROLE CLARIFICATION - Documentation" .claude/commands/implement.md
# Expected: Phase 0 block with all elements

# Test 2: Verify special override explanation
grep "Documentation phases ALWAYS use doc-writer" .claude/commands/implement.md
# Expected: Override clearly stated
```

**Deliverable**:
- Phase 0 before implementation-researcher (new, ~40 lines)
- Phase 0 before debug-specialist (new, ~50 lines)
- Phase 0 REMINDER at STEP E (new, ~20 lines)
- Phase 0 for documentation phases (new, ~50 lines)
- Total: ~160 lines added

---

### Task Group 6.3: Update Section Headers (3 hours)

**Objective**: Transform all major section headers to STEP N format with EXECUTE NOW markers

#### 6.3.1: Audit Current Headers (30 minutes)

**Scan for headers requiring transformation**:

```bash
# Extract all section headers (### level)
grep -n "^###" .claude/commands/implement.md

# Expected categories:
# 1. Workflow steps (STEP 1-5)
# 2. Sub-steps (1.4, 1.5, 1.55, 1.57, 1.6, 3.3, 3.4, 3.5, 5.5)
# 3. Special sections (Plan Hierarchy Update, Testing, Git Commit, Summary Generation)
```

**Create transformation checklist**:

| Line | Current Header | New Format | Priority |
|------|----------------|------------|----------|
| 172 | ### STEP 1 - Utility Initialization | ✓ Already compliant | Low |
| 254 | ### Progressive Plan Support | → Add STEP number | High |
| 555 | ### 1.4. Check Expansion Status | → STEP 1.4 (REQUIRED BEFORE STEP 1.5) | High |
| 575 | ### 1.5. Hybrid Complexity Evaluation | ✓ Already compliant | Low |
| 672 | ### 1.55. Proactive Expansion Check | → STEP 1.55 (REQUIRED BEFORE STEP 1.6) | High |
| 688 | ### 1.57. Implementation Research Agent Invocation | → STEP 1.57 (REQUIRED BEFORE STEP 1.6) | High |
| 914 | ### 1.6. Parallel Wave Execution | ✓ Already compliant | Low |
| 928 | ### STEP 2 - Implementation | ✓ Already compliant | Low |
| 939 | ### STEP 3 - Testing | ✓ Already compliant | Low |
| 948 | ### 3.3. Automatic Debug Integration | → STEP 3.3 (CONDITIONAL - IF TESTS FAIL) | High |
| 1095 | ### 3.4. Adaptive Planning Detection | → STEP 3.4 (CONDITIONAL - IF TRIGGERS DETECTED) | High |
| 1109 | ### 3.5. Update Debug Resolution | → STEP 3.5 (CONDITIONAL - IF PREVIOUSLY DEBUGGED) | High |
| 1138 | ### STEP 4 - Git Commit | ✓ Already compliant | Low |
| 1209 | ### STEP 5 - Plan Update | ✓ Already compliant | Low |
| 1220 | ### 5.5. Automatic Collapse Detection | → STEP 5.5 (CONDITIONAL - IF PHASE EXPANDED) | High |

**Priority classification**:
- High: Sub-steps and conditional sections (10 headers)
- Low: Already compliant main steps (5 headers)

#### 6.3.2: Transform High-Priority Headers (1.5 hours)

**Transformation pattern**:

```markdown
# OLD FORMAT
### 1.55. Proactive Expansion Check

# NEW FORMAT
### STEP 1.55 (REQUIRED BEFORE STEP 1.6) - Proactive Expansion Check
```

**Apply to each high-priority header**:

1. **Line 254** (Progressive Plan Support):
```markdown
### STEP 0.5 (REQUIRED BEFORE STEP 1) - Progressive Plan Support
```

2. **Line 555** (Check Expansion Status):
```markdown
### STEP 1.4 (REQUIRED BEFORE STEP 1.5) - Check Expansion Status
```

3. **Line 672** (Proactive Expansion Check):
```markdown
### STEP 1.55 (REQUIRED BEFORE STEP 1.6) - Proactive Expansion Check
```

4. **Line 688** (Implementation Research Agent Invocation):
```markdown
### STEP 1.57 (REQUIRED BEFORE STEP 1.6) - Implementation Research Agent Invocation
```

5. **Line 948** (Automatic Debug Integration):
```markdown
### STEP 3.3 (CONDITIONAL - IF TESTS FAIL) - Automatic Debug Integration
```

6. **Line 1095** (Adaptive Planning Detection):
```markdown
### STEP 3.4 (CONDITIONAL - IF TRIGGERS DETECTED) - Adaptive Planning Detection
```

7. **Line 1109** (Update Debug Resolution):
```markdown
### STEP 3.5 (CONDITIONAL - IF PREVIOUSLY DEBUGGED) - Update Debug Resolution
```

8. **Line 1220** (Automatic Collapse Detection):
```markdown
### STEP 5.5 (CONDITIONAL - IF PHASE EXPANDED) - Automatic Collapse Detection
```

**Use Edit tool for each transformation** (8 edits total)

#### 6.3.3: Add EXECUTE NOW Markers (1 hour)

**Pattern**: Add "**EXECUTE NOW - [Action Description]**" before all bash code blocks

**Locations to add markers**:

1. **Utility initialization** (line ~175):
```markdown
**EXECUTE NOW - Initialize Required Utilities**

(existing content follows)
```

2. **Path pre-calculation** (multiple locations):
```markdown
**EXECUTE NOW - Calculate Artifact Paths**

```bash
# existing bash block
```
```

3. **Agent invocations** (before Task blocks):
```markdown
**EXECUTE NOW - Invoke Implementation-Researcher Agent**

```
Task {
  ...
}
```
```

4. **Verification checkpoints** (before verification bash blocks):
```markdown
**EXECUTE NOW - Verify Artifact Created**

```bash
# verification bash block
```
```

**Systematic scan and edit**:

```bash
# Find all bash blocks without EXECUTE NOW markers
grep -B 2 '^```bash' .claude/commands/implement.md | grep -v "EXECUTE NOW"

# For each result:
# 1. Determine action description from context
# 2. Add EXECUTE NOW marker before code block
# 3. Use Edit tool to apply change
```

**Expected additions**: ~25-30 EXECUTE NOW markers

#### 6.3.4: Verify Header Hierarchy (30 minutes)

**Test Plan**:

1. **Extract all headers and verify STEP format**:
```bash
grep -n "^###" .claude/commands/implement.md | grep "STEP"
# Expected: All major sections have STEP format
```

2. **Verify REQUIRED BEFORE dependencies**:
```bash
grep "REQUIRED BEFORE" .claude/commands/implement.md
# Expected: All sequential steps have dependency markers
```

3. **Verify CONDITIONAL markers**:
```bash
grep "CONDITIONAL" .claude/commands/implement.md
# Expected: All conditional sections marked (3.3, 3.4, 3.5, 5.5)
```

4. **Count EXECUTE NOW markers**:
```bash
grep -c "EXECUTE NOW" .claude/commands/implement.md
# Expected: 25-30 markers
```

**Deliverable**:
- 10 headers transformed to STEP format
- 25-30 EXECUTE NOW markers added
- All sequential dependencies clarified
- All conditional sections marked

---

### Task Group 6.4: Verify Agent Invocations (2.5 hours)

**Objective**: Ensure all 5 agent invocation types have enforcement markers

#### 6.4.1: Implementation-Researcher Verification (30 minutes)

**Location**: STEP C (lines 727-789)

**Check for**:
1. **AGENT INVOCATION marker** before Task block:
```markdown
**STEP C (REQUIRED BEFORE STEP D) - Invoke Implementation-Researcher Agent**

**EXECUTE NOW - Invoke Research Agent for Complex Phase**
```

2. **THIS EXACT TEMPLATE marker** in Task block header:
```markdown
**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):
```

3. **ABSOLUTE REQUIREMENT** in step header:
```markdown
**ABSOLUTE REQUIREMENT**: YOU MUST invoke implementation-researcher agent when complexity thresholds met. This is NOT optional.
```

4. **WHY THIS MATTERS** explanation:
```markdown
**WHY THIS MATTERS**: Complex phases benefit from codebase exploration before implementation. Research identifies reusable patterns and integration challenges, reducing rework.
```

5. **Behavioral injection** in Task prompt:
```markdown
Read and follow behavioral guidelines from:
${CLAUDE_PROJECT_DIR}/.claude/agents/implementation-researcher.md

You are acting as an Implementation Researcher Agent.
```

6. **Template variables** documentation:
```markdown
**Template Variables** (ONLY allowed modifications):
- `${CLAUDE_PROJECT_DIR}`: Project directory path
- `${CURRENT_PHASE}`: Current phase number
...

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
...
```

**Verification commands**:
```bash
# Check for all enforcement elements
grep -A 5 "STEP C.*Implementation-Researcher" .claude/commands/implement.md | grep "EXECUTE NOW"
grep -A 10 "Agent Invocation Template" .claude/commands/implement.md | grep "THIS EXACT TEMPLATE"
grep "ABSOLUTE REQUIREMENT.*implementation-researcher" .claude/commands/implement.md
grep "WHY THIS MATTERS" .claude/commands/implement.md | grep -i "research"
grep "Read and follow behavioral guidelines" .claude/commands/implement.md | grep "implementation-researcher"
```

**If missing**: Add enforcement markers using Edit tool

#### 6.4.2: Code-Writer Verification (30 minutes)

**Location**: Step 1.6, Agent Invocation Template (lines 369-410)

**Check for**:
1. **MANDATORY AGENT DELEGATION** header with complexity mapping
2. **Agent Invocation Template** with THIS EXACT TEMPLATE marker
3. **Template Variables** with ONLY allowed modifications
4. **DO NOT modify** list
5. **Behavioral injection** (line 378-379)

**Verification commands**:
```bash
grep "MANDATORY AGENT DELEGATION" .claude/commands/implement.md
grep -A 3 "Agent Invocation Template.*code-writer" .claude/commands/implement.md
grep "behavioral guidelines.*code-writer" .claude/commands/implement.md
```

**If missing**: Add enforcement markers

#### 6.4.3: Debug-Specialist Verification (30 minutes)

**Location**: STEP E (lines 984-1039)

**Check for**:
1. **STEP E** header with REQUIRED qualifier
2. **EXECUTE NOW** marker
3. **THIS EXACT TEMPLATE** marker
4. **SlashCommand invocation** (not direct agent):
```markdown
SlashCommand {
  command: "/debug \"Phase $CURRENT_PHASE failure: $ERROR_TYPE\" \"$PLAN_PATH\""
}
```

5. **Fallback mechanism** with MANDATORY verification:
```markdown
# MANDATORY: Verify debug report created
if [ -z "$DEBUG_REPORT_PATH" ] || [ ! -f "$DEBUG_REPORT_PATH" ]; then
  echo "⚠️  DEBUG REPORT NOT FOUND - Triggering fallback mechanism"
  ...
fi
```

**Verification commands**:
```bash
grep "STEP E.*REQUIRED" .claude/commands/implement.md
grep -A 5 "EXECUTE NOW.*debug" .claude/commands/implement.md
grep "SlashCommand.*debug" .claude/commands/implement.md
grep "MANDATORY: Verify debug report" .claude/commands/implement.md
```

**If missing**: Add enforcement markers

#### 6.4.4: Doc-Writer Verification (30 minutes)

**Location**: Special case override in adaptive role section (added in 6.2.3)

**Check for**:
1. **Agent Invocation Template** embedded in Phase 0 section
2. **THIS EXACT TEMPLATE** marker
3. **Behavioral injection**
4. **Template variables** documentation

**Verification commands**:
```bash
grep -A 20 "PHASE 0.*Documentation" .claude/commands/implement.md | grep "Agent Invocation Template"
grep "behavioral guidelines.*doc-writer" .claude/commands/implement.md
```

**If missing**: Add to Phase 0 section created in 6.2.3

#### 6.4.5: Spec-Updater Verification (30 minutes)

**Location**: STEP A (lines 433-484), Plan Hierarchy Update section

**Check for**:
1. **STEP A** header with REQUIRED qualifier
2. **EXECUTE NOW** marker
3. **THIS EXACT TEMPLATE** marker
4. **ABSOLUTE REQUIREMENT** in header
5. **WHY THIS MATTERS** explanation
6. **Behavioral injection**
7. **Template variables** documentation
8. **STEP B** fallback mechanism

**Verification commands**:
```bash
grep "STEP A.*REQUIRED" .claude/commands/implement.md
grep -A 5 "EXECUTE NOW.*Spec-Updater" .claude/commands/implement.md
grep "THIS EXACT TEMPLATE.*spec-updater" .claude/commands/implement.md
grep "ABSOLUTE REQUIREMENT.*spec-updater" .claude/commands/implement.md
grep "behavioral guidelines.*spec-updater" .claude/commands/implement.md
grep "STEP B.*REQUIRED AFTER STEP A" .claude/commands/implement.md
```

**If missing**: Add enforcement markers

**Deliverable**:
- All 5 agent types verified with enforcement markers
- Missing markers added via Edit tool
- Enforcement checklist completed:
  - [ ] AGENT INVOCATION markers present (5 locations)
  - [ ] THIS EXACT TEMPLATE markers present (5 locations)
  - [ ] ABSOLUTE REQUIREMENT headers present (4 locations: C, E, A, F)
  - [ ] WHY THIS MATTERS explanations present (4 locations)
  - [ ] Behavioral injection present (5 locations)
  - [ ] Template variables documented (5 locations)
  - [ ] Fallback mechanisms present (4 locations: D, G, B, spec-updater)

---

### Task Group 6.5: Verify Existing Patterns (2.5 hours)

**Objective**: Ensure Patterns 1-4 remain intact after Phase 0 additions

#### 6.5.1: Pattern 1 - Path Pre-calculation Verification (45 minutes)

**Pattern Description**: EXECUTE NOW blocks that calculate paths before agent invocations

**Locations to verify**:

1. **Implementation Research** (lines ~743-751):
```bash
# EXECUTE NOW block should exist
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"

CONTEXT_BEFORE=$(track_context_usage "before" "phase_${CURRENT_PHASE}_research" "")
FILE_LIST=$(echo "$PHASE_CONTENT" | grep -oE '[a-zA-Z0-9_/.-]+\.(js|py|lua|sh|md|yaml)' | sort -u | head -20 | tr '\n' ', ')
```

2. **Plan Hierarchy Update** (lines ~449-589):
```bash
# Path pre-calculation for checkpoint data should exist
CHECKPOINT_DATA='{
  "workflow_description":"implement",
  "plan_path":"'$PLAN_PATH'",
  ...
}'
```

3. **Summary Generation** (lines ~1390-1410):
```bash
# Summary path calculation should exist
SUMMARY_PATH="[specs-dir]/summaries/NNN_implementation_summary.md"
```

**Verification script**:
```bash
# Check for EXECUTE NOW markers before path calculations
grep -B 2 "source.*artifact-operations" .claude/commands/implement.md | grep "EXECUTE NOW"
grep -B 2 "CHECKPOINT_DATA=" .claude/commands/implement.md | grep "EXECUTE NOW"
grep -B 2 "SUMMARY_PATH=" .claude/commands/implement.md | grep "EXECUTE NOW"
```

**If missing**: Add EXECUTE NOW markers (don't modify calculation logic)

#### 6.5.2: Pattern 2 - Verification Checkpoints (45 minutes)

**Pattern Description**: MANDATORY VERIFICATION blocks after critical file operations

**Locations to verify**:

1. **Implementation Research Artifact** (STEP D, lines ~791-834):
```bash
# MANDATORY: Verify artifact file exists
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "⚠️  ARTIFACT NOT FOUND - Triggering fallback mechanism"
  # Fallback logic
fi
```

2. **Debug Report Creation** (STEP E, lines ~1008-1033):
```bash
# MANDATORY: Verify debug report created
if [ -z "$DEBUG_REPORT_PATH" ] || [ ! -f "$DEBUG_REPORT_PATH" ]; then
  echo "⚠️  DEBUG REPORT NOT FOUND - Triggering fallback mechanism"
  # Fallback logic
fi
```

3. **Plan Hierarchy Update** (STEP B, lines ~487-553):
```bash
# MANDATORY VERIFICATION - Confirm Hierarchy Updated
# Verification steps with fallback
```

4. **PR Creation** (STEP G, lines ~1547-1602):
```bash
# MANDATORY: Verify PR exists
if [ -z "$PR_URL" ]; then
  echo "⚠️  PR URL NOT FOUND - Triggering fallback mechanism"
  # Fallback logic
fi
```

**Verification script**:
```bash
# Check for all MANDATORY VERIFICATION blocks
grep -c "MANDATORY.*VERIFICATION" .claude/commands/implement.md
# Expected: 4 blocks

# Check for fallback triggers
grep -c "Triggering fallback mechanism" .claude/commands/implement.md
# Expected: 4 triggers
```

**If missing**: Add MANDATORY VERIFICATION headers (don't modify verification logic)

#### 6.5.3: Pattern 3 - Fallback Mechanisms (45 minutes)

**Pattern Description**: Guaranteed completion via alternative paths when agents fail

**Locations to verify**:

1. **Spec-Updater Fallback** (STEP B, lines ~506-512):
```bash
# Direct utility invocation if agent fails
source .claude/lib/checkbox-utils.sh
mark_phase_complete "$PLAN_PATH" "$PHASE_NUM"
verify_checkbox_consistency "$PLAN_PATH" "$PHASE_NUM"
```

2. **Research Artifact Fallback** (STEP D, lines ~812-834):
```bash
# Fallback: Create minimal research artifact from agent output
FALLBACK_PATH="specs/${TOPIC_DIR}/artifacts/phase_${CURRENT_PHASE}_exploration.md"
# Create artifact with agent output
```

3. **Debug Report Fallback** (STEP E, lines ~1013-1033):
```bash
# Fallback: Use analyze-error.sh utility
source .claude/lib/analyze-error.sh
DEBUG_ANALYSIS=$(analyze_error "$ERROR_TYPE" "$TEST_OUTPUT" "$CURRENT_PHASE")
# Create fallback debug report
```

4. **PR Creation Fallback** (STEP G, lines ~1562-1580):
```bash
# Fallback: Provide manual gh command
echo "Manual PR Creation Required"
echo "Run this command:"
echo "gh pr create ..."
```

**Verification script**:
```bash
# Check for all fallback mechanisms
grep -A 10 "Fallback:" .claude/commands/implement.md | grep -E "(source|create|echo)"
# Expected: 4 fallback implementations

# Verify fallback guarantees
grep "Guarantees 100%" .claude/commands/implement.md
# Expected: At least 3 guarantees mentioned
```

**If missing**: Document fallback guarantees (don't modify fallback logic)

#### 6.5.4: Pattern 4 - Checkpoint Reporting (45 minutes)

**Pattern Description**: CHECKPOINT REQUIREMENT blocks for progress visibility

**Locations to verify**:

1. **Phase Completion** (lines ~1183-1207):
```markdown
**CHECKPOINT REQUIREMENT - Report Phase Completion**

CHECKPOINT: Phase ${PHASE_NUM} Complete
- Phase: ${PHASE_NAME}
- Tests: ✓ PASSED
- Commit: ${COMMIT_HASH}
...
```

2. **Implementation Complete** (lines ~1410-1437):
```markdown
**CHECKPOINT REQUIREMENT - Report Implementation Complete**

CHECKPOINT: Implementation Complete
- Plan: ${PLAN_NAME}
- Phases: ${TOTAL_PHASES}/${TOTAL_PHASES} (100%)
...
```

3. **PR Creation** (lines ~1605-1616):
```markdown
**CHECKPOINT REQUIREMENT - Report PR Creation**

CHECKPOINT: Pull Request Created
- PR: #${PR_NUMBER}
- URL: ${PR_URL}
...
```

**Verification script**:
```bash
# Check for all CHECKPOINT REQUIREMENT blocks
grep -c "CHECKPOINT REQUIREMENT" .claude/commands/implement.md
# Expected: 3 blocks

# Check for checkpoint formats
grep "CHECKPOINT:" .claude/commands/implement.md
# Expected: Multiple checkpoint markers
```

**If missing**: Add CHECKPOINT REQUIREMENT headers (don't modify checkpoint content)

**Deliverable**:
- Pattern 1 verified: 3 path pre-calculation blocks intact
- Pattern 2 verified: 4 verification checkpoints intact
- Pattern 3 verified: 4 fallback mechanisms intact
- Pattern 4 verified: 3 checkpoint reporting blocks intact
- Missing enforcement headers added (non-invasive)

---

## Testing Protocol

### Test 1: Audit Score Verification (30 minutes)

**Objective**: Verify audit score ≥95/100

**Procedure**:
```bash
# Run audit script
.claude/lib/audit-execution-enforcement.sh .claude/commands/implement.md > audit_results.txt

# Check overall score
grep "Overall Score" audit_results.txt
# Expected: ≥95/100

# Check Phase 0 score
grep "Phase 0" audit_results.txt
# Expected: ≥14/15 points (near perfect)

# Check Pattern scores
grep -E "Pattern (1|2|3|4)" audit_results.txt
# Expected: All patterns ≥18/20 points

# Check Agent Invocation scores
grep "Agent Invocation" audit_results.txt
# Expected: ≥24/25 points
```

**Acceptance Criteria**:
- Overall score ≥95/100
- Phase 0 score ≥14/15
- All patterns ≥18/20
- Agent invocations ≥24/25

### Test 2: File Creation Rate Testing (1 hour)

**Objective**: Verify 100% file creation rate across all three roles

**Test Scenarios**:

#### Scenario 1: Simple Phase (Direct Execution)
```bash
# Create test plan with simple phase (complexity 2)
cat > /tmp/test_plan_simple.md <<'EOF'
# Test Plan - Simple Feature

## Metadata
- **Date**: 2025-10-20
- **Complexity**: Low

## Phases

### Phase 1: Add Utility Function
**Objective**: Add simple string utility
**Complexity**: 2/10

#### Tasks
- [ ] Create utils/string.sh
- [ ] Add trim_whitespace function
- [ ] Add tests
- [ ] Update documentation

## Testing
```bash
bash tests/test_string_utils.sh
```
EOF

# Test 10 runs
for i in {1..10}; do
  echo "Run $i:"
  /implement /tmp/test_plan_simple.md 1
  [ $? -eq 0 ] && echo "✓ Success" || echo "✗ Failed"
done

# Expected: 10/10 successes, direct execution mode
```

#### Scenario 2: Complex Phase (Agent Orchestration)
```bash
# Create test plan with complex phase (complexity 8)
cat > /tmp/test_plan_complex.md <<'EOF'
# Test Plan - Complex Feature

## Metadata
- **Date**: 2025-10-20
- **Complexity**: High

## Phases

### Phase 1: Database Integration
**Objective**: Integrate PostgreSQL with connection pooling
**Complexity**: 8/10

#### Tasks
- [ ] Configure database connection
- [ ] Implement connection pool
- [ ] Create migration system
- [ ] Add health checks
- [ ] Implement retry logic
- [ ] Add monitoring
- [ ] Create backup strategy
- [ ] Update documentation
- [ ] Add integration tests
- [ ] Performance testing
- [ ] Security audit
- [ ] Deployment guide

## Testing
```bash
bash tests/test_database_integration.sh
```
EOF

# Test 10 runs
for i in {1..10}; do
  echo "Run $i:"
  /implement /tmp/test_plan_complex.md 1
  # Verify implementation-researcher invoked
  # Verify code-writer invoked
  [ $? -eq 0 ] && echo "✓ Success" || echo "✗ Failed"
done

# Expected: 10/10 successes, orchestration mode (Task tool invocations visible)
```

#### Scenario 3: Documentation Phase (Special Override)
```bash
# Create test plan with documentation phase (complexity 5 but override)
cat > /tmp/test_plan_docs.md <<'EOF'
# Test Plan - Documentation Update

## Metadata
- **Date**: 2025-10-20
- **Complexity**: Medium

## Phases

### Phase 1: Update API Documentation
**Objective**: Create comprehensive API docs
**Complexity**: 5/10

#### Tasks
- [ ] Create api/README.md
- [ ] Document all endpoints
- [ ] Add usage examples
- [ ] Create architecture diagram
- [ ] Update main README

## Testing
```bash
# Verify all docs created
ls -la api/README.md
```
EOF

# Test 10 runs
for i in {1..10}; do
  echo "Run $i:"
  /implement /tmp/test_plan_docs.md 1
  # Verify doc-writer agent invoked (not direct execution)
  [ $? -eq 0 ] && echo "✓ Success" || echo "✗ Failed"
done

# Expected: 10/10 successes, doc-writer agent invoked despite medium complexity
```

**Acceptance Criteria**:
- Simple phases: 10/10 success, direct execution confirmed
- Complex phases: 10/10 success, agent orchestration confirmed (Task tool visible)
- Documentation phases: 10/10 success, doc-writer agent confirmed (override working)

### Test 3: Role Switching Verification (45 minutes)

**Objective**: Verify correct role activation based on complexity

**Procedure**:
```bash
# Instrument /implement with role detection logging
# Add after Step 1.5 (complexity evaluation):

echo "DEBUG: Complexity Score = $COMPLEXITY_SCORE"
echo "DEBUG: Phase Type = $PHASE_TYPE"

# Determine role
if [ "$PHASE_TYPE" = "documentation" ]; then
  ACTIVE_ROLE="Agent Orchestrator (doc-writer override)"
elif [ "$COMPLEXITY_SCORE" -lt 3 ]; then
  ACTIVE_ROLE="Direct Executor"
else
  ACTIVE_ROLE="Agent Orchestrator (code-writer)"
fi

echo "DEBUG: Active Role = $ACTIVE_ROLE"
```

**Test Cases**:

| Phase Type | Complexity | Expected Role | Expected Agent |
|------------|-----------|---------------|----------------|
| Implementation | 2 | Direct Executor | None |
| Implementation | 5 | Agent Orchestrator | code-writer |
| Implementation | 8 | Agent Orchestrator | code-writer + researcher |
| Documentation | 3 | Agent Orchestrator | doc-writer (override) |
| Testing | 6 | Agent Orchestrator | test-specialist (override) |
| Debug | 4 | Agent Orchestrator | debug-specialist |

**Run test suite**:
```bash
for test_case in test_cases/*.md; do
  echo "Testing: $test_case"
  /implement "$test_case" 2>&1 | grep "DEBUG: Active Role"
  # Verify role matches expectation
done
```

**Acceptance Criteria**:
- Role switches correctly for all 6 test cases
- Direct execution only when score <3 AND not special override
- Agent orchestration when score ≥3 OR special override
- Correct agent selected based on phase type

### Test 4: Adaptive Planning Integration (30 minutes)

**Objective**: Verify /revise --auto-mode still works after Phase 0 additions

**Test Scenario**: Trigger complexity-based replanning

```bash
# Create plan with phase exceeding threshold
cat > /tmp/test_adaptive_plan.md <<'EOF'
# Test Plan - Adaptive Planning

## Metadata
- **Date**: 2025-10-20

## Phases

### Phase 1: Initial Implementation
**Complexity**: 9/10 (threshold: 8)

#### Tasks
[15 tasks listed - exceeds 10 task threshold]

## Testing
```bash
echo "Tests"
```
EOF

# Run implementation
/implement /tmp/test_adaptive_plan.md 1 2>&1 | tee adaptive_test.log

# Verify adaptive planning triggered
grep "Complexity threshold exceeded" adaptive_test.log
grep "Invoking /revise --auto-mode" adaptive_test.log

# Verify plan updated
grep "Phase 1 expanded" /tmp/test_adaptive_plan.md

# Verify implementation continued with revised plan
grep "Resuming with revised plan" adaptive_test.log
```

**Acceptance Criteria**:
- Complexity trigger detected (score >8)
- /revise --auto-mode invoked automatically
- Plan structure updated (phase expanded)
- Implementation resumed without errors
- Replan counter incremented
- Limit enforcement working (max 2 replans per phase)

### Test 5: Regression Testing (1 hour)

**Objective**: Ensure existing functionality unchanged

**Test Suite**:
```bash
# Run full test suite
cd /home/benjamin/.config
bash .claude/tests/run_all_tests.sh

# Expected results:
# - All tests pass (same as pre-migration)
# - No new failures introduced
# - Performance within 10% of baseline

# Specific tests to verify:
bash .claude/tests/test_artifact_utils.sh           # Artifact operations intact
bash .claude/tests/test_complexity_estimator.sh     # Hybrid complexity working
bash .claude/tests/test_shared_utilities.sh         # Checkpoint utils intact
bash .claude/tests/test_adaptive_planning.sh        # Adaptive planning intact
bash .claude/tests/test_hierarchical_agents.sh      # Agent delegation intact
```

**Acceptance Criteria**:
- All existing tests pass
- No performance regressions (within 10% of baseline)
- Agent delegation still functional
- Checkpoint management working
- Adaptive planning working

---

## Integration Points

### Dependencies
- **Requires completed**: Phase 2 (Wave 1 agents: doc-writer, debug-specialist, test-specialist)
- **Requires completed**: Phase 3 (Wave 2 agents: spec-updater)
- **Used by**: Phase 7 (testing /implement for orchestration patterns)

### Modified Files
- `.claude/commands/implement.md` (~200 lines added, ~15 lines modified)

### New Files
- None (all changes to existing command file)

### Testing Artifacts
- `/tmp/test_plan_simple.md` (simple phase test)
- `/tmp/test_plan_complex.md` (complex phase test)
- `/tmp/test_plan_docs.md` (documentation override test)
- `/tmp/test_adaptive_plan.md` (adaptive planning test)
- `audit_results.txt` (audit score output)
- `adaptive_test.log` (adaptive planning trace)

---

## Risk Mitigation

### Risk 1: Breaking Adaptive Planning
**Impact**: High - Automatic replanning could fail
**Mitigation**:
- Test adaptive planning triggers before and after migration
- Verify /revise --auto-mode integration intact
- Test complexity threshold detection
- Verify replan counter enforcement

### Risk 2: Agent Invocation Failures
**Impact**: High - Complex phases could fail to delegate
**Mitigation**:
- Test all 5 agent types independently
- Verify fallback mechanisms trigger correctly
- Test behavioral injection for each agent
- Verify metadata extraction working

### Risk 3: Role Confusion
**Impact**: Medium - Claude might execute when should orchestrate
**Mitigation**:
- Clear Phase 0 language (YOU MUST/DO NOT)
- Visual decision tree for role selection
- Concrete examples for each role
- Testing scenarios covering all three roles

### Risk 4: Performance Regression
**Impact**: Low - Additional Phase 0 sections could slow execution
**Mitigation**:
- Keep Phase 0 additions concise
- Use conditional sections (skip when not needed)
- Monitor execution time during testing
- Verify within 10% of baseline performance

---

## Deliverables

### Modified Command File
- `.claude/commands/implement.md`
  - Phase 0 opening (~80 lines)
  - Adaptive YOUR ROLE section (~100 lines)
  - Phase 0 before implementation-researcher (~40 lines)
  - Phase 0 before debug-specialist (~50 lines)
  - Phase 0 REMINDER at STEP E (~20 lines)
  - Phase 0 for documentation phases (~50 lines)
  - 10 header transformations (STEP N format)
  - 25-30 EXECUTE NOW markers
  - Agent invocation verification updates (~20 lines)
  - Total additions: ~360-400 lines
  - Total modifications: ~35 lines

### Test Results
- Audit score report: ≥95/100
- File creation rate: 100% (30/30 across 3 scenarios)
- Role switching validation: 6/6 test cases pass
- Adaptive planning verification: All triggers working
- Regression test results: All tests pass

### Documentation Updates
- Tracking spreadsheet updated with:
  - Baseline audit score (pre-migration)
  - Post-migration audit score (≥95/100)
  - File creation rate (100%)
  - Test execution time (baseline comparison)
  - Patterns verified (1-4 intact)
  - Agent invocations verified (5 types)

---

## Success Metrics

### Quantitative Metrics
- Audit score: ≥95/100 (Target: 95-100)
- File creation rate: 100% (Target: 10/10 all scenarios)
- Phase 0 score: ≥14/15 (Target: 14-15)
- Pattern scores: ≥18/20 each (Target: 18-20)
- Agent invocation score: ≥24/25 (Target: 24-25)
- Test suite pass rate: 100% (Target: no regressions)
- Execution time variance: ≤10% (Target: within baseline)

### Qualitative Metrics
- Role clarification clarity (review by team)
- Decision tree usability (manual walkthrough)
- Phase 0 comprehensiveness (all scenarios covered)
- Agent delegation reliability (no ambiguous cases)

---

## Timeline

| Task Group | Duration | Dependencies |
|------------|----------|--------------|
| 6.1: Phase 0 Opening | 3 hours | None |
| 6.2: Phase 0 Complex Sections | 4 hours | 6.1 complete |
| 6.3: Section Headers | 3 hours | 6.2 complete |
| 6.4: Agent Invocations | 2.5 hours | 6.3 complete |
| 6.5: Pattern Verification | 2.5 hours | 6.4 complete |
| Testing Protocol | 3 hours | 6.5 complete |

**Total Duration**: 14 hours (as estimated in parent plan)
**Critical Path**: Linear sequence (all tasks sequential)

---

## Notes

### Key Implementation Decisions

1. **Triple-role architecture preserved**: The /implement command's unique ability to switch between coordinator, executor, and orchestrator roles is maintained and clarified, not simplified.

2. **Complexity score as switching mechanism**: Using $COMPLEXITY_SCORE from Step 1.5 as the role selection trigger provides objective, consistent switching without manual intervention.

3. **Special case overrides explicit**: Documentation, testing, and debug phases always use specialized agents regardless of complexity score, ensuring consistency in these critical areas.

4. **Phase 0 repeated at invocation points**: Phase 0 role clarification appears both at command opening (general) and before each agent invocation section (specific), reinforcing correct behavior.

5. **Existing patterns non-invasive**: Patterns 1-4 verification focuses on adding enforcement headers (EXECUTE NOW, MANDATORY VERIFICATION) without modifying the underlying logic.

### Lessons for Future Phases

1. **Visual decision trees helpful**: The complexity-to-role decision tree provides clear guidance without ambiguity.

2. **Concrete examples essential**: Showing simple/complex/documentation phase examples makes role switching concrete.

3. **Fallback mechanisms critical**: Every agent invocation should have a documented fallback for 100% success rate.

4. **Testing all roles separately**: Testing coordinator, executor, and orchestrator roles independently ensures comprehensive coverage.

### Migration Guide Updates

After Phase 6 completion, update migration guide with:
- Triple-role pattern (coordinator + executor + orchestrator)
- Adaptive YOUR ROLE section template
- Complexity-based role switching pattern
- Special case override pattern (documentation, testing, debug)
- Visual decision tree template
