# Phase 5: Fix High-Priority Commands - Detailed Implementation

## Metadata
- **Phase Number**: 5
- **Parent Plan**: 001_execution_enforcement_fix.md
- **Objective**: Apply execution enforcement to most critical commands beyond /orchestrate
- **Dependencies**: [Phase 4]
- **Complexity**: High
- **Risk**: Medium
- **Estimated Time**: 12-16 hours
- **Status**: PENDING

## Overview

This phase applies execution enforcement to 5 high-priority commands identified through research. Each command delegates work to multiple agents and requires enforcement at agent invocation points, verification checkpoints, and fallback mechanisms.

### Priority Commands

1. **/implement** (6-8h) - 9 agent invocations, adaptive planning, hierarchy updates
2. **/plan** (4-5h) - 5 agent invocations, parallel research, complexity analysis
3. **/expand** (3-4h) - Auto-analysis mode, parallel coordination, complexity estimation
4. **/debug** (3-4h) - Parallel hypothesis investigation, report creation
5. **/document** (2-3h) - Documentation updates, cross-reference verification

### Common Enforcement Patterns

All commands need:
- **Agent Invocation**: "**THIS EXACT TEMPLATE (No modifications)**" markers
- **Verification**: "**MANDATORY VERIFICATION**" after agent completion
- **Checkpoints**: "**CHECKPOINT REQUIREMENT**" at phase boundaries
- **Fallbacks**: Safety nets for agent non-compliance

## Command 1: /implement

**Location**: `.claude/commands/implement.md`

**Current Problems** (Research Findings):
- 9 distinct agent invocations (most of any command)
- Adaptive planning triggers may be skipped
- Hierarchy updates not verified
- Phase completion checkpoints missing

**Key Enforcement Points**:

### 1. Standards Discovery (lines ~50-100)

Add enforcement:
```markdown
**EXECUTE NOW - Discover and Load Standards**

BEFORE implementing any code, YOU MUST discover and load coding standards:

\`\`\`bash
# Search for CLAUDE.md
CLAUDE_MD=$(find_claude_md "$PWD")

if [ -z "$CLAUDE_MD" ]; then
  echo "⚠️  WARNING: No CLAUDE.md found"
  echo "Using language-specific defaults"
else
  echo "✓ Standards found: $CLAUDE_MD"
  # Extract Code Standards, Testing Protocols
fi
\`\`\`

**MANDATORY**: Standards discovery MUST execute before code generation.
```

### 2. Plan Parsing (lines ~150-200)

Add verification:
```markdown
**MANDATORY VERIFICATION - Plan File Exists and Parseable**

\`\`\`bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ ERROR: Plan file not found: $PLAN_PATH"
  exit 1
fi

# Parse plan structure
source .claude/lib/plan-core-bundle.sh
PHASES=$(parse_plan_file "$PLAN_PATH")

if [ -z "$PHASES" ]; then
  echo "❌ ERROR: Plan file not parseable"
  exit 1
fi

echo "✓ VERIFIED: Plan has ${#PHASES[@]} phases"
\`\`\`
```

### 3. Implementation-Researcher Agent (complex phases)

Strengthen invocation:
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE**

For phases with complexity ≥8, delegate codebase exploration:

**THIS IS NOT AN EXAMPLE - USE THIS EXACT CODE**:

\`\`\`yaml
Task {
  subagent_type: "general-purpose"
  description: "Explore codebase for Phase [N] implementation context"
  prompt: "
    **ABSOLUTE REQUIREMENT - Create Exploration Artifact**

    Read and follow behavioral guidelines from:
    $CLAUDE_PROJECT_DIR/.claude/agents/implementation-researcher.md

    You are acting as an Implementation Researcher.

    **STEP 1 (REQUIRED): CREATE ARTIFACT FILE FIRST**

    Use Write tool to create artifact at this EXACT path:
    **Artifact Path**: [CALCULATED ABSOLUTE PATH]

    **STEP 2: EXPLORE CODEBASE**

    [Phase-specific exploration requirements]

    **STEP 3: RETURN CONFIRMATION**

    Return ONLY:
    \`\`\`
    ARTIFACT_CREATED: [ABSOLUTE PATH]
    \`\`\`

    **CRITICAL**: DO NOT return summary. Orchestrator reads artifact file.
  "
}
\`\`\`

**ENFORCEMENT**: Copy this template verbatim. Only replace [BRACKETED] variables.
```

### 4. Spec-Updater Agent (hierarchy updates)

Add verification:
```markdown
**MANDATORY VERIFICATION - Hierarchy Updates Applied**

After spec-updater agent completes:

\`\`\`bash
# Verify checkboxes updated in parent plan
if grep -q "\\[x\\]" "$PARENT_PLAN"; then
  echo "✓ VERIFIED: Parent plan checkboxes updated"
else
  echo "⚠️  WARNING: No checkboxes marked complete"
fi

# Verify links updated
BROKEN_LINKS=$(check_plan_links "$PARENT_PLAN")
if [ -n "$BROKEN_LINKS" ]; then
  echo "❌ ERROR: Broken links detected"
  exit 1
fi

echo "✓ VERIFIED: All links functional"
\`\`\`
```

### 5. Phase Completion Checkpoints

Add to each phase completion:
```markdown
**CHECKPOINT REQUIREMENT - Phase [N] Complete**

After completing phase [N], YOU MUST report:

\`\`\`
CHECKPOINT: Phase [N] complete
- Phase name: [name]
- Tasks completed: [M/M]
- Files modified: [count]
- Tests run: ✓
- Tests passing: ✓/✗
- Git commit: [hash]
- Next phase: [N+1]
\`\`\`

**MANDATORY**: DO NOT proceed to next phase without this checkpoint.
```

### 6. Adaptive Planning Triggers

Strengthen triggers:
```markdown
**ADAPTIVE PLANNING TRIGGER - Complexity Threshold Exceeded**

If phase complexity >8 OR task count >10:

**YOU MUST invoke /revise --auto-mode** to expand the phase:

\`\`\`bash
# MANDATORY: Trigger adaptive planning
if [ $PHASE_COMPLEXITY -gt 8 ] || [ $TASK_COUNT -gt 10 ]; then
  echo "Complexity threshold exceeded: $PHASE_COMPLEXITY"
  echo "MANDATORY: Invoking /revise for phase expansion"

  /revise --auto-mode --context "{\"phase\": $PHASE_NUM, \"trigger\": \"complexity\"}"

  # Verify revised plan exists
  if [ ! -f "$REVISED_PLAN" ]; then
    echo "❌ ERROR: Adaptive planning failed"
    exit 1
  fi

  echo "✓ Plan revised, reloading..."
fi
\`\`\`

**This is NOT optional**. High-complexity phases MUST be expanded.
```

---

## Command 2: /plan

**Location**: `.claude/commands/plan.md`

**Current Problems** (Research Findings):
- 5 agent invocations (parallel research-specialists)
- Step 0.5 research delegation may be skipped
- Complexity pre-analysis not enforced
- Plan file creation not verified

**Key Enforcement Points**:

### 1. Step 0.5 Research Delegation (if ambiguous feature)

Add trigger:
```markdown
**CONDITIONAL - Research Delegation for Ambiguous Features**

If feature description is ambiguous (lacks specific technical requirements):

**YOU MUST delegate to 2-3 research-specialist agents**:

\`\`\`bash
# Detect ambiguity (heuristics)
AMBIGUITY_SCORE=$(calculate_ambiguity "$FEATURE_DESCRIPTION")

if [ $AMBIGUITY_SCORE -gt 5 ]; then
  echo "Feature is ambiguous (score: $AMBIGUITY_SCORE)"
  echo "MANDATORY: Delegating to research agents"

  # Invoke 2-3 parallel research agents
  # [Use Task tool with THIS EXACT TEMPLATE pattern]

  echo "✓ Research delegation complete"
fi
\`\`\`

**ENFORCEMENT**: Ambiguous features MUST have research before planning.
```

### 2. Parallel Research Agent Invocation

Strengthen pattern:
```markdown
**AGENT INVOCATION - Parallel Research Pattern**

**CRITICAL**: Invoke ALL research agents in SINGLE message for parallel execution.

**THIS EXACT PATTERN**:

\`\`\`
# Single message with 3 Task calls
Task { [research-specialist: pattern 1] }
Task { [research-specialist: pattern 2] }
Task { [research-specialist: pattern 3] }
\`\`\`

**VERIFICATION BEFORE INVOCATION**:
- [ ] All agent prompts use exact template from Phase 1
- [ ] All report paths pre-calculated (absolute)
- [ ] All Task calls in SINGLE message

**DO NOT** invoke sequentially (defeats parallelism).
```

### 3. Complexity Estimator Agent (pre-analysis)

Make mandatory:
```markdown
**MANDATORY - Complexity Pre-Analysis**

BEFORE generating plan phases, YOU MUST invoke complexity_estimator:

\`\`\`yaml
Task {
  subagent_type: "general-purpose"
  description: "Estimate feature complexity for phase planning"
  prompt: "[EXACT template with feature context]"
}
\`\`\`

**ENFORCEMENT**: Plans without complexity analysis are incomplete.

**MANDATORY VERIFICATION - Complexity Estimate Received**:

\`\`\`bash
COMPLEXITY_SCORE=$(extract_complexity_from_agent_output)

if [ -z "$COMPLEXITY_SCORE" ]; then
  echo "❌ ERROR: No complexity estimate"
  exit 1
fi

echo "✓ Feature complexity: $COMPLEXITY_SCORE"
\`\`\`
```

### 4. Plan File Creation

Add verification:
```markdown
**MANDATORY VERIFICATION - Plan File Created**

After generating plan:

\`\`\`bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: Plan file not created"
  exit 1
fi

# Verify structure
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases")
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    echo "❌ ERROR: Missing section: $section"
    exit 1
  fi
done

echo "✓ VERIFIED: Plan complete at $PLAN_PATH"
\`\`\`
```

---

## Command 3: /expand

**Location**: `.claude/commands/expand.md`

**Current Problems** (Research Findings):
- Auto-analysis mode agent coordination may be skipped
- Complexity_estimator invocation not enforced
- Phase expansion file creation not verified
- Parallel agent invocations may be sequential

**Key Enforcement Points**:

### 1. Auto-Analysis Mode Trigger

Strengthen:
```markdown
**AUTO-ANALYSIS MODE - Complexity Evaluation**

When invoked with single plan path (no phase number):

**YOU MUST analyze ALL phases for expansion**:

\`\`\`bash
# MANDATORY: Analyze all phases
echo "Auto-analysis mode activated"
echo "MANDATORY: Analyzing all phases for complexity"

source .claude/lib/auto-analysis-utils.sh
PHASES=$(parse_phases_from_plan "$PLAN_PATH")

echo "✓ Found ${#PHASES[@]} phases to analyze"
\`\`\`

**This is NOT optional**. Auto-mode MUST analyze all phases.
```

### 2. Complexity Estimator Agent

Make mandatory:
```markdown
**MANDATORY - Invoke Complexity Estimator**

**YOU MUST invoke complexity_estimator agent** to analyze phases:

\`\`\`yaml
Task {
  subagent_type: "general-purpose"
  description: "Analyze plan phases for expansion recommendations"
  prompt: "[EXACT template from auto-analysis-utils.sh]"
}
\`\`\`

**ENFORCEMENT**: Auto-analysis requires complexity estimation.

**MANDATORY VERIFICATION - Recommendations Received**:

\`\`\`bash
RECOMMENDATIONS=$(parse_agent_recommendations)

if [ -z "$RECOMMENDATIONS" ]; then
  echo "❌ ERROR: No expansion recommendations"
  exit 1
fi

echo "✓ Received recommendations for ${#RECOMMENDATIONS[@]} phases"
\`\`\`
```

### 3. Parallel Phase Expansion

Add enforcement:
```markdown
**PARALLEL EXPANSION - Multiple Phases**

For phases recommended for expansion:

**CRITICAL**: Invoke all plan_expander agents in PARALLEL:

\`\`\`
# Single message with multiple Task calls
Task { [plan_expander: phase 2] }
Task { [plan_expander: phase 3] }
Task { [plan_expander: phase 5] }
\`\`\`

**Time savings**: 60-70% vs sequential execution
```

### 4. Expanded File Verification

Add checkpoint:
```markdown
**MANDATORY VERIFICATION - All Expanded Files Created**

\`\`\`bash
for phase_num in "${EXPANDED_PHASES[@]}"; do
  EXPANDED_FILE="$PLAN_DIR/phase_${phase_num}_*.md"

  if [ ! -f $EXPANDED_FILE ]; then
    echo "❌ ERROR: Expanded file not created for phase $phase_num"
    exit 1
  fi

  echo "✓ VERIFIED: Phase $phase_num expanded"
done

echo "✓ All ${#EXPANDED_PHASES[@]} phases expanded successfully"
\`\`\`
```

---

## Command 4: /debug

**Location**: `.claude/commands/debug.md`

**Current Problems** (Research Findings):
- Parallel hypothesis investigation may be sequential
- Debug-analyst agent invocations lack enforcement
- Debug report creation not verified
- Investigation completion not checkpointed

**Key Enforcement Points**:

### 1. Parallel Hypothesis Investigation

Strengthen:
```markdown
**PARALLEL INVESTIGATION - Multiple Hypotheses**

For complex bugs, investigate hypotheses in PARALLEL:

**CRITICAL**: Invoke ALL debug-analyst agents in SINGLE message:

\`\`\`
# Parallel investigation (60-70% time savings)
Task { [debug-analyst: hypothesis 1 - auth failure] }
Task { [debug-analyst: hypothesis 2 - state corruption] }
Task { [debug-analyst: hypothesis 3 - race condition] }
\`\`\`

**ENFORCEMENT**: Parallel investigation is MANDATORY for >2 hypotheses.
```

### 2. Debug-Analyst Agent Template

Add enforcement:
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE**

\`\`\`yaml
Task {
  subagent_type: "general-purpose"
  description: "Investigate [HYPOTHESIS] as root cause"
  prompt: "
    **ABSOLUTE REQUIREMENT - Create Debug Report**

    Read and follow: $CLAUDE_PROJECT_DIR/.claude/agents/debug-analyst.md

    **STEP 1: REPRODUCE ISSUE** (MANDATORY)

    YOU MUST attempt to reproduce the issue before analysis.

    **STEP 2: ANALYZE ROOT CAUSE**

    [Hypothesis-specific analysis]

    **STEP 3: CREATE DEBUG REPORT**

    Use Write tool at EXACT path:
    **Report Path**: [CALCULATED PATH]

    **STEP 4: RETURN CONFIRMATION**

    \`\`\`
    DEBUG_REPORT_CREATED: [ABSOLUTE PATH]
    \`\`\`
  "
}
\`\`\`

**ENFORCEMENT**: Use exact template. No simplification.
```

### 3. Debug Report Verification

Add checkpoint:
```markdown
**MANDATORY VERIFICATION - All Debug Reports Created**

\`\`\`bash
for hypothesis in "${HYPOTHESES[@]}"; do
  REPORT_PATH="${DEBUG_REPORT_PATHS[$hypothesis]}"

  if [ ! -f "$REPORT_PATH" ]; then
    echo "❌ ERROR: Debug report missing: $hypothesis"
    exit 1
  fi

  echo "✓ VERIFIED: Report for $hypothesis"
done

echo "✓ All ${#HYPOTHESES[@]} debug reports created"
\`\`\`
```

### 4. Investigation Completion Checkpoint

Add:
```markdown
**CHECKPOINT REQUIREMENT - Investigation Complete**

\`\`\`
CHECKPOINT: Debug investigation complete
- Hypotheses investigated: ${#HYPOTHESES[@]}
- Reports created: ${#DEBUG_REPORT_PATHS[@]}
- Root cause identified: [yes/no]
- Recommended fixes: [count]
- All reports verified: ✓
\`\`\`
```

---

## Command 5: /document

**Location**: `.claude/commands/document.md**

**Current Problems**:
- Documentation updates may be skipped
- Cross-reference verification optional
- Doc update completion not checkpointed

**Key Enforcement Points**:

### 1. Documentation Update Enforcement

Add:
```markdown
**EXECUTE NOW - Update Affected Documentation**

YOU MUST identify and update ALL affected documentation:

\`\`\`bash
# Identify affected docs
AFFECTED_DOCS=$(find_affected_documentation "$CHANGES_DESCRIPTION")

echo "Affected documentation files: ${#AFFECTED_DOCS[@]}"

# Update each doc
for doc in "${AFFECTED_DOCS[@]}"; do
  echo "Updating: $doc"
  [apply updates]
done

echo "✓ All documentation updated"
\`\`\`

**MANDATORY**: Documentation updates are NOT optional.
```

### 2. Cross-Reference Verification

Strengthen:
```markdown
**MANDATORY VERIFICATION - Cross-References Accurate**

\`\`\`bash
# Verify all cross-references
BROKEN_REFS=()

for doc in "${UPDATED_DOCS[@]}"; do
  REFS=$(extract_cross_references "$doc")

  for ref in $REFS; do
    if ! verify_reference_exists "$ref"; then
      BROKEN_REFS+=("$doc: $ref")
    fi
  done
done

if [ ${#BROKEN_REFS[@]} -gt 0 ]; then
  echo "❌ ERROR: Broken cross-references:"
  for broken in "${BROKEN_REFS[@]}"; do
    echo "  - $broken"
  done
  exit 1
fi

echo "✓ VERIFIED: All cross-references accurate"
\`\`\`

**This verification is MANDATORY**.
```

### 3. Doc Update Completion Checkpoint

Add:
```markdown
**CHECKPOINT REQUIREMENT - Documentation Update Complete**

\`\`\`
CHECKPOINT: Documentation phase complete
- Documentation files updated: ${#UPDATED_DOCS[@]}
- Cross-references verified: ✓
- README updates: [count]
- Spec updates: [count]
- All verification passed: ✓
\`\`\`
```

---

## Testing Strategy

### Test Scenarios

**Test 1: Individual Command Testing**
```bash
# Test each command with enforcement patterns
/implement <test-plan>
/plan "<test-feature>"
/expand <test-plan>
/debug "<test-issue>"
/document "<test-changes>"

# Verify: All enforcement patterns execute
# Verify: All checkpoints report
# Verify: File creation rate = 100%
```

**Test 2: Command Interaction Testing**
```bash
# Test command workflows
/plan "feature" → /implement <plan> → /document "changes"
/debug "issue" → /implement <debug-plan>
/expand <plan> → /implement <expanded-plan>

# Verify: Context passes correctly between commands
# Verify: No regressions in workflows
```

**Test 3: Simulated Agent Non-Compliance**
```bash
# Simulate agents that skip file creation
# Verify: Fallback mechanisms trigger
# Verify: Verification detects missing files
# Verify: 100% file creation via fallbacks
```

## Validation Checklist

Before marking Phase 5 complete:

### Enforcement Markers
- [ ] All agent invocations use "THIS EXACT TEMPLATE"
- [ ] All critical operations have "EXECUTE NOW"
- [ ] All verifications marked "MANDATORY"
- [ ] All checkpoints marked "REQUIRED"

### /implement Command
- [ ] 9 agent invocations strengthened
- [ ] Adaptive planning triggers enforced
- [ ] Hierarchy update verification added
- [ ] Phase completion checkpoints added

### /plan Command
- [ ] Step 0.5 research delegation enforced
- [ ] Parallel research agents enforced
- [ ] Complexity pre-analysis mandatory
- [ ] Plan file creation verified

### /expand Command
- [ ] Auto-analysis mode enforced
- [ ] Complexity estimator invocation mandatory
- [ ] Parallel expansion enforced
- [ ] Expanded file verification added

### /debug Command
- [ ] Parallel investigation enforced
- [ ] Debug-analyst template strengthened
- [ ] Report creation verified
- [ ] Investigation checkpoint added

### /document Command
- [ ] Documentation updates enforced
- [ ] Cross-reference verification mandatory
- [ ] Update completion checkpoint added

### Testing
- [ ] All commands tested individually
- [ ] Command interactions tested
- [ ] Agent non-compliance simulated
- [ ] File creation rate: 100%
- [ ] No regressions detected

## Success Metrics

**Agent Invocation Compliance**:
- Before: ~60-80% (templates simplified/paraphrased)
- After: 100% (exact template enforcement)

**File Creation Rate**:
- Before: ~70-90% (varies by command and agent)
- After: 100% (guaranteed by enforcement + fallbacks)

**Checkpoint Reporting**:
- Before: 0% (no checkpoints)
- After: 100% (all commands report progress)

**Command Interaction Success**:
- Before: ~85% (/plan → /implement may fail context passing)
- After: 100% (explicit context preservation)

## Next Phase

After completing Phase 5:
- Proceed to Phase 6: Documentation, Testing, and Workflow Integration
- Update all command documentation
- Run comprehensive test suite
- Create migration guide
- Update CHANGELOG.md

---

**Phase 5 Status**: PENDING
**Last Updated**: 2025-10-19
**Parent Plan**: 001_execution_enforcement_fix.md
