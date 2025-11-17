# /research-plan and /research-revise Commands Compliance Analysis

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Commands Analyzed**: /research-plan (research-plan.md), /research-revise (research-revise.md)
- **Report Type**: Comparative compliance assessment against .claude/docs/ standards

## Executive Summary

Both /research-plan and /research-revise commands demonstrate near-identical implementation patterns with excellent state machine integration (100%), proper workflow type configuration, and comprehensive file verification. They share the same critical compliance gaps as /build, /fix, and /research-report: agent invocations use echo statements instead of Task tool, lack behavioral injection pattern, and missing formal execution enforcement markers.

**Compliance Score**:
- **/research-plan**: 75/100
- **/research-revise**: 73/100

**Shared Strengths**:
- Perfect state-based orchestration architecture implementation
- Correct workflow types ("research-and-plan", "research-and-revise")
- Excellent two-phase execution (Research → Plan, Research → Revise)
- Comprehensive file verification with three-level checks
- Proper backup creation before plan revision (/research-revise)

**Shared Critical Gaps**:
- Agent invocations use echo statements, NOT Task tool (violates Standard 0.5)
- No behavioral injection pattern (agent files not referenced in Task prompts)
- Missing "EXECUTE NOW" and "MANDATORY VERIFICATION" formal markers
- No checkpoint reporting between phases

**Unique Features**:
- **/research-plan**: Creates NEW plan from research (proper plan number calculation)
- **/research-revise**: Modifies EXISTING plan with backup creation and modification verification

## Comparative Analysis

### Common Implementation Pattern

Both commands share 85% identical structure:
1. **Part 1**: Feature/revision description capture with complexity parsing
2. **Part 2**: State machine initialization with proper workflow type
3. **Part 3**: Research phase execution (identical across both)
4. **Part 4**: Planning phase (different: create vs revise)
5. **Part 5**: Completion and cleanup

This demonstrates good code reuse and consistent patterns.

---

## Detailed Compliance Assessment

### 1. State-Based Orchestration Architecture ✅ (Excellent - 100%)

**Standard**: [workflow-state-machine.md](../../.claude/docs/architecture/workflow-state-machine.md)

**Compliance Status**: FULLY COMPLIANT (Both Commands)

**Evidence - /research-plan**:
- Lines 87-94: Proper library sourcing in dependency order
- Lines 96-101: Library version verification
- Lines 103-126: State machine init with "research-and-plan" workflow type, "plan" terminal state
- Lines 135-138, 214-217: State transitions with return code verification
- Lines 204-208, 267-271: Proper state persistence

**Evidence - /research-revise**:
- Lines 106-113: Proper library sourcing
- Lines 115-120: Library version verification
- Lines 122-144: State machine init with "research-and-revise" workflow type, "plan" terminal state
- Lines 153-156, 226-229: State transitions with return code verification
- Lines 215-220, 306-310: Proper state persistence

**Unique Workflow Types**:

**/research-plan** (Lines 103-106):
```bash
WORKFLOW_TYPE="research-and-plan"
TERMINAL_STATE="plan"
COMMAND_NAME="research-plan"
```

**/research-revise** (Lines 122-125):
```bash
WORKFLOW_TYPE="research-and-revise"
TERMINAL_STATE="plan"
COMMAND_NAME="research-revise"
```

Both correctly use "plan" terminal state (not "complete"), demonstrating understanding of workflow scope integration.

**Assessment**: Perfect implementation - both commands serve as excellent reference for proper workflow type configuration.

---

### 2. Directory Protocols ✅ (Excellent - 95%)

**Standard**: [directory-protocols.md](../../.claude/docs/concepts/directory-protocols.md)

**Compliance Status**: FULLY COMPLIANT (Both Commands)

**Evidence - /research-plan**:
- Lines 143-149: Topic directory creation with slug generation
- Lines 150-153: RESEARCH_DIR and PLANS_DIR creation
- Lines 222-225: Plan path pre-calculation with proper numbering

**Evidence - /research-revise**:
- Lines 162-163: Derives SPECS_DIR from existing plan path (excellent path manipulation)
- Lines 166-171: Research report numbering for revision insights
- Lines 235-242: Backup directory creation with timestamped filename

**Best Practice - /research-revise Backup Pattern** (Lines 235-242):
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$EXISTING_PLAN_PATH")/backups"
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

mkdir -p "$BACKUP_DIR"
cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH"
```

This aligns with backup retention policy from directory-protocols.md (backups/ subdirectory, timestamped files).

**Minor Enhancement**: Both could use `ensure_artifact_directory` for consistency, though current implementation is compliant.

---

### 3. Agent Invocation Patterns ❌ (Poor - 25%)

**Standard**: [execution-enforcement-guide.md](../../.claude/docs/guides/execution-enforcement-guide.md) - Behavioral Injection

**Compliance Status**: NON-COMPLIANT (Both Commands)

**Critical Violations - Identical Across Both Commands**:

**Research-Specialist Invocation**:

**/research-plan** (Lines 156-167):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Workflow-Specific Context:"
echo "- Research Complexity: $RESEARCH_COMPLEXITY"
echo "- Feature Description: $FEATURE_DESCRIPTION"
echo "- Output Directory: $RESEARCH_DIR"
echo "- Workflow Type: research-and-plan"
```

**/research-revise** (Lines 174-186):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Workflow-Specific Context:"
echo "- Research Complexity: $RESEARCH_COMPLEXITY"
echo "- Revision Details: $REVISION_DETAILS"
echo "- Output Directory: $RESEARCH_DIR"
echo "- Workflow Type: research-and-revise"
echo "- Existing Plan: $EXISTING_PLAN_PATH"
```

**Problem**: Identical to /build, /fix, /research-report - uses echo statements, NOT Task tool.

**Plan-Architect Invocation**:

**/research-plan** (Lines 232-245):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke plan-architect agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
echo "2. Use Write tool to create plan at: $PLAN_PATH"
echo "3. Return completion signal: PLAN_CREATED: \${PLAN_PATH}"
```

**/research-revise** (Lines 263-277):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke plan-architect agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
echo "2. Use Edit tool to modify plan at: $EXISTING_PLAN_PATH"
echo "3. Return completion signal: PLAN_REVISED: \${PLAN_PATH}"
```

**Problem**: Same violation - documentation instead of executable Task invocation.

**Expected Pattern** (applies to all 4 agent invocations):
```markdown
# AGENT INVOCATION - Use THIS EXACT TEMPLATE

Task {
  subagent_type: "general-purpose"
  description: "[Agent] - [Purpose]"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **ABSOLUTE REQUIREMENT**: [Primary task]

    **CONTEXT**:
    [context parameters]

    **CRITICAL**: [Critical directive]

    Return completion signal: [SIGNAL]: [VALUE]
  "
}
```

**Impact**: Identical to other commands - breaks hierarchical pattern, no file creation guarantee, behavioral guidelines not enforced.

---

### 4. Execution Enforcement ❌ (Poor - 35%)

**Standard**: [execution-enforcement-guide.md](../../.claude/docs/guides/execution-enforcement-guide.md) - Standard 0

**Compliance Status**: PARTIALLY COMPLIANT (Both Commands)

**Missing Patterns - Shared Across Both**:

**"EXECUTE NOW" Markers**: Only in echo statements, NOT for bash operations:
- Project directory detection (lines 64-83 in both)
- Topic directory creation (lines 143-153 in /research-plan, 162-166 in /research-revise)
- Report path collection (lines 227-229 in both)

**"MANDATORY VERIFICATION" Blocks**: Good verification logic but lacks formal headers:

**/research-plan** (Lines 178-198):
```bash
# FAIL-FAST VERIFICATION (no fallback, exit 1 on failure)
echo ""
echo "Verifying research artifacts..."
```

Should be:
```markdown
**MANDATORY VERIFICATION - Research Artifacts Created**

After research-specialist execution, YOU MUST verify:
[verification code]
```

Same issue in /research-revise (lines 195-214).

**"CHECKPOINT REQUIREMENT" Blocks**: Completely absent in both commands
- No checkpoint after research phase
- No checkpoint after planning/revision phase

**Recommendation**: Add formal execution enforcement markers following execution-enforcement-guide.md patterns.

---

### 5. Error Handling ⚠️ (Moderate - 70%)

**Standard**: [error-enhancement-guide.md](../../.claude/docs/guides/error-enhancement-guide.md)

**Compliance Status**: PARTIALLY COMPLIANT (Both Commands)

**Excellent Error Handling - Shared Pattern**:

**State Machine Init** (/research-plan lines 110-125, /research-revise lines 128-143):
```bash
if ! sm_init \
  "$FEATURE_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "[]" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Feature Description: $FEATURE_DESCRIPTION" >&2
  echo "  - Command Name: $COMMAND_NAME" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE" >&2
  echo "  - Research Complexity: $RESEARCH_COMPLEXITY" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Library version incompatibility (require workflow-state-machine.sh >=2.0.0)" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  exit 1
fi
```

**Pattern**: ERROR + DIAGNOSTIC + POSSIBLE CAUSES (excellent)

**Verification Errors** (Both commands, research phase):
```bash
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  exit 1
fi

if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
  exit 1
fi

# File size check
UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  echo "DIAGNOSTIC: Files: $UNDERSIZED_FILES" >&2
  exit 1
fi
```

**Unique to /research-revise - Backup Verification** (Lines 244-253):
```bash
# FAIL-FAST BACKUP VERIFICATION
if [ ! -f "$BACKUP_PATH" ]; then
  echo "ERROR: Backup creation failed at $BACKUP_PATH" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$BACKUP_PATH")
if [ "$FILE_SIZE" -lt 100 ]; then
  echo "ERROR: Backup file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "✓ Backup created: $BACKUP_PATH"
```

Excellent fail-fast pattern for backup creation.

**Unique to /research-revise - Plan Modification Verification** (Lines 289-294):
```bash
# Verify plan was actually modified (must be different from backup)
if cmp -s "$EXISTING_PLAN_PATH" "$BACKUP_PATH"; then
  echo "ERROR: Plan file not modified (identical to backup)" >&2
  echo "DIAGNOSTIC: Plan revision must make changes based on research insights" >&2
  echo "SOLUTION: Review research reports and ensure agent applies revisions" >&2
  exit 1
fi
```

Outstanding verification - ensures plan actually changed!

**Gaps - Shared**:
- State transition errors generic (no diagnostic context)
- No error type classification or enhancement integration

**Assessment**: Both commands have excellent verification patterns, especially /research-revise with backup and modification checks.

---

### 6. Workflow Structure ✅ (Excellent - 95%)

**Standard**: Inferred from orchestration patterns

**Compliance Status**: FULLY COMPLIANT (Both Commands)

**Evidence - /research-plan**:
- Lines 132-208: Research phase with verification
- Lines 210-271: Planning phase with plan creation
- Lines 273-296: Completion with next steps

**Evidence - /research-revise**:
- Lines 150-220: Research phase (identical to /research-plan)
- Lines 222-310: Plan revision phase with backup and modification verification
- Lines 312-337: Completion with comparison guidance

**Workflow Differentiation**:

| Aspect | /research-plan | /research-revise |
|--------|----------------|------------------|
| **Workflow Type** | research-and-plan | research-and-revise |
| **Terminal State** | plan | plan |
| **Input** | Feature description | Revision details + existing plan path |
| **Phase 2 Action** | Create NEW plan (Write tool) | Modify EXISTING plan (Edit tool) |
| **Verification** | Plan file existence + size | Backup creation + modification + size |
| **Output Signal** | PLAN_CREATED | PLAN_REVISED |

**Best Practice - Path Extraction** (/research-revise lines 54-62):
```bash
# Extract existing plan path from revision description
# Matches: /path/to/file.md or ./relative/path.md or ../relative/path.md or .claude/path.md
EXISTING_PLAN_PATH=$(echo "$REVISION_DESCRIPTION" | grep -oE '[./][^ ]+\.md' | head -1)

# Validate plan path exists
if [ -z "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: No plan path found in revision description" >&2
  echo "USAGE: /research-revise \"revise plan at /path/to/plan.md based on INSIGHTS\"" >&2
  exit 1
fi
```

Excellent regex-based path extraction with validation.

**Assessment**: Both commands have well-structured workflows appropriate to their purposes.

---

### 7. Plan File Verification ✅ (Excellent - 95%)

**Standard**: Inferred from verification patterns

**Compliance Status**: FULLY COMPLIANT (Both Commands)

**Evidence - /research-plan** (Lines 250-262):
```bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  echo "DIAGNOSTIC: Expected file: $PLAN_PATH" >&2
  echo "SOLUTION: Check plan-architect agent behavioral file compliance" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Plan file may be incomplete or empty" >&2
  exit 1
fi

echo "✓ Planning phase complete (plan: $PLAN_PATH)"
```

**Evidence - /research-revise** (Lines 280-301):
```bash
if [ ! -f "$EXISTING_PLAN_PATH" ]; then
  echo "ERROR: Plan file disappeared during revision: $EXISTING_PLAN_PATH" >&2
  echo "DIAGNOSTIC: Restore from backup: $BACKUP_PATH" >&2
  exit 1
fi

# Verify plan was actually modified (must be different from backup)
if cmp -s "$EXISTING_PLAN_PATH" "$BACKUP_PATH"; then
  echo "ERROR: Plan file not modified (identical to backup)" >&2
  echo "DIAGNOSTIC: Plan revision must make changes based on research insights" >&2
  echo "SOLUTION: Review research reports and ensure agent applies revisions" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$EXISTING_PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "ERROR: Plan file too small after revision ($FILE_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Plan may have been corrupted, restore from: $BACKUP_PATH" >&2
  exit 1
fi

echo "✓ Plan revision complete: $EXISTING_PLAN_PATH"
```

**/research-revise verification is superior**:
- Includes backup restoration guidance
- Verifies actual modification occurred (not just existence)
- Three-level check: existence → modification → size

**Best Practice**: The modification verification (`cmp -s`) is excellent - ensures agent actually revised plan, not just reported completion.

---

### 8. Code Standards - Library Usage ✅ (Excellent - 95%)

**Standard**: [library-api.md](../../.claude/docs/reference/library-api.md)

**Compliance Status**: FULLY COMPLIANT (Both Commands)

**Evidence - Both Commands**:
- Proper library sourcing in dependency order
- Library version verification with requirements
- Correct sm_init signatures for workflow types
- Proper state persistence with error handling

**Complexity Parsing** (Identical pattern in both):
```bash
DEFAULT_COMPLEXITY=3  # research-and-plan/revise default
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

# Support both embedded and explicit flag formats
if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Validation
if ! echo "$RESEARCH_COMPLEXITY" | grep -Eq "^[1-4]$"; then
  echo "ERROR: Invalid research complexity: $RESEARCH_COMPLEXITY (must be 1-4)" >&2
  exit 1
fi
```

**Best Practice**: Default complexity 3 (higher than /research-report's 2) makes sense for plan creation workflows.

---

### 9. Documentation Standards ✅ (Good - 80%)

**Standard**: [documentation-policy](../../CLAUDE.md#documentation_policy)

**Compliance Status**: MOSTLY COMPLIANT (Both Commands)

**Strengths**:
- Complete frontmatter in both commands
- Troubleshooting sections present
- Usage examples in troubleshooting

**Gaps**:
- Missing cross-references to command guides
- No references to agent behavioral files
- Could reference related patterns (behavioral-injection, verification-fallback)

**Recommendation**: Add "Related Documentation" sections to both commands.

---

## Specific Violations and Recommendations

### Critical Issue 1: Agent Invocations Use Echo Statements (Both Commands, 4 Total)

**Locations**:
- **/research-plan**: Lines 156-167 (research-specialist), 232-245 (plan-architect)
- **/research-revise**: Lines 174-186 (research-specialist), 263-277 (plan-architect)

**Current Implementation** (all 4 instances identical pattern):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke [agent-name] agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: [path]"
echo "2. Return completion signal: [SIGNAL]"
```

**Required Fix - Research-Specialist** (/research-plan):
```bash
# AGENT INVOCATION - Use THIS EXACT TEMPLATE

Task {
  subagent_type: "general-purpose"
  description: "Research-specialist - Feature research for planning"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: Create research reports for feature planning.

    **CONTEXT**:
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Feature Description: $FEATURE_DESCRIPTION
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: research-and-plan

    **CRITICAL**: YOU MUST create report files in \$RESEARCH_DIR.

    Return completion signal: REPORT_CREATED: \${REPORT_PATH}
  "
}
```

**Required Fix - Plan-Architect** (/research-plan):
```bash
# AGENT INVOCATION - Use THIS EXACT TEMPLATE

Task {
  subagent_type: "general-purpose"
  description: "Plan-architect - Create implementation plan from research"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **ABSOLUTE REQUIREMENT**: Create implementation plan using Write tool.

    **CONTEXT**:
    - Feature Description: $FEATURE_DESCRIPTION
    - Output Path: $PLAN_PATH
    - Research Reports: $(echo "$REPORT_PATHS" | jq -R . | jq -s .)
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation

    **CRITICAL**: YOU MUST use Write tool to create plan at exact path.

    Return completion signal: PLAN_CREATED: \${PLAN_PATH}
  "
}
```

Apply similar fixes to /research-revise (with "Edit tool" and "plan revision" mode).

**Standard Reference**: execution-enforcement-guide.md lines 122-135

---

### Medium Issue 2: Missing Formal Verification Headers (Both Commands)

**Locations**:
- Research artifacts: /research-plan lines 178, /research-revise lines 195
- Plan files: /research-plan lines 249, /research-revise lines 280

**Current Implementation** (/research-plan lines 178-198):
```bash
# FAIL-FAST VERIFICATION (no fallback, exit 1 on failure)
echo ""
echo "Verifying research artifacts..."
```

**Required Fix**:
```bash
**MANDATORY VERIFICATION - Research Artifacts Created**

After research-specialist execution, YOU MUST verify:

[existing verification code]

echo "✓ VERIFIED: Research artifacts complete ($REPORT_COUNT reports created)"
```

Apply to both commands' research and plan verification blocks.

**Standard Reference**: execution-enforcement-guide.md lines 361-386

---

### Medium Issue 3: Missing Checkpoint Reporting (Both Commands)

**Locations**:
- After research phase: /research-plan line 208, /research-revise line 220
- After plan phase: /research-plan line 271, /research-revise line 310

**Required Addition** (/research-plan after line 208):
```bash
**CHECKPOINT REQUIREMENT - Research Phase Status**

YOU MUST report phase status:
```
CHECKPOINT: Research phase complete
- Feature: $FEATURE_DESCRIPTION
- Complexity: $RESEARCH_COMPLEXITY
- Reports Created: $REPORT_COUNT
- Output Directory: $RESEARCH_DIR
- All files verified: ✓
- Proceeding to: Planning phase
```
```

**Required Addition** (/research-plan after line 271):
```bash
**CHECKPOINT REQUIREMENT - Planning Phase Status**

YOU MUST report phase status:
```
CHECKPOINT: Planning phase complete
- Plan Path: $PLAN_PATH
- Research Reports Used: $REPORT_COUNT
- Plan Size: $FILE_SIZE bytes
- All files verified: ✓
- Workflow complete
```
```

Apply similar checkpoints to /research-revise (with revision-specific metrics).

**Standard Reference**: execution-enforcement-guide.md lines 995-1013

---

### Low Issue 4: Documentation Cross-References (Both Commands)

**Location**: End of both files

**Required Addition**:
```markdown
---

## Related Documentation

### Command Guides
- [Research-Plan Command Guide](.claude/docs/guides/research-plan-command-guide.md) - Complete usage
- [Research-Revise Command Guide](.claude/docs/guides/research-revise-command-guide.md) - Revision workflow

### Agent Behavioral Guidelines
- [Research Specialist](.claude/agents/research-specialist.md) - Research and report creation
- [Plan Architect](.claude/agents/plan-architect.md) - Plan creation and revision

### Pattern Documentation
- [Behavioral Injection](.claude/docs/concepts/patterns/behavioral-injection.md) - Agent invocation
- [Verification Fallback](.claude/docs/concepts/patterns/verification-fallback.md) - File creation guarantee

### Reference Documentation
- [Plan Structure](.claude/docs/reference/plan-structure.md) - Implementation plan format
- [Workflow State Machine](.claude/docs/architecture/workflow-state-machine.md) - State transitions
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Artifact organization
```

**Standard Reference**: documentation-policy from CLAUDE.md

---

## Summary of Compliance Gaps

### /research-plan

| Standard Area | Compliance Level | Priority | Effort |
|--------------|------------------|----------|--------|
| State Machine Architecture | ✅ Excellent | N/A | N/A |
| Directory Protocols | ✅ Excellent | N/A | N/A |
| Agent Invocation Patterns | ❌ Poor | **CRITICAL** | 3 hours |
| Execution Enforcement | ❌ Poor | **HIGH** | 2.5 hours |
| Error Handling | ⚠️ Moderate | Medium | 1.5 hours |
| Workflow Structure | ✅ Excellent | N/A | N/A |
| Plan Verification | ✅ Excellent | N/A | N/A |
| Library Usage | ✅ Excellent | N/A | N/A |
| Documentation | ✅ Good | Low | 1 hour |

**Total Estimated Remediation Time**: 8 hours

### /research-revise

| Standard Area | Compliance Level | Priority | Effort |
|--------------|------------------|----------|--------|
| State Machine Architecture | ✅ Excellent | N/A | N/A |
| Directory Protocols | ✅ Excellent | N/A | N/A |
| Agent Invocation Patterns | ❌ Poor | **CRITICAL** | 3 hours |
| Execution Enforcement | ❌ Poor | **HIGH** | 2.5 hours |
| Error Handling | ⚠️ Moderate | Medium | 1.5 hours |
| Workflow Structure | ✅ Excellent | N/A | N/A |
| Plan Verification | ✅ Excellent | N/A | N/A |
| Library Usage | ✅ Excellent | N/A | N/A |
| Documentation | ✅ Good | Low | 1 hour |

**Total Estimated Remediation Time**: 8 hours

---

## Recommended Action Plan

### Shared Remediation (Both Commands)

Since both commands share 85% identical structure, remediate in parallel:

### Phase 1: Critical Fixes (Priority 1) - 3 hours per command (6 hours total)

1. **Replace echo-based instructions with Task invocations**
   - Research-specialist invocation (lines 156-167 in /research-plan, 174-186 in /research-revise)
   - Plan-architect invocation (lines 232-245 in /research-plan, 263-277 in /research-revise)
   - Use behavioral injection pattern with CONTEXT sections

2. **Add formal MANDATORY VERIFICATION headers**
   - Research artifacts verification (lines 178 in /research-plan, 195 in /research-revise)
   - Plan file verification (lines 249 in /research-plan, 280 in /research-revise)

### Phase 2: High Priority (Priority 2) - 2.5 hours per command (5 hours total)

3. **Add CHECKPOINT REQUIREMENT blocks**
   - Research phase checkpoint (after lines 208/220)
   - Plan phase checkpoint (after lines 271/310)

4. **Add EXECUTE NOW markers**
   - Directory creation operations
   - Report path collection
   - Backup creation (/research-revise only)

5. **Enhance state transition errors**
   - Add diagnostic context to all sm_transition failures

### Phase 3: Medium Priority (Priority 3) - 1.5 hours per command (3 hours total)

6. **Enhance error messages**
   - Add SOLUTION sections where missing
   - Include error type classification

### Phase 4: Low Priority (Enhancements) - 1 hour per command (2 hours total)

7. **Add cross-references section**
   - Reference command guides
   - Link to agent behavioral files
   - Link to pattern documentation

**Combined Total Remediation Time**: 16 hours (8 hours per command, parallel execution possible)

---

## References

### Standards Documents Analyzed
- `/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md` (Full document)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (Sections 1-7)
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (Sections 1-4)
- `/home/benjamin/.config/.claude/docs/guides/error-enhancement-guide.md` (Sections 1-3)

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/research-plan.md` (307 lines, all sections reviewed)
- `/home/benjamin/.config/.claude/commands/research-revise.md` (348 lines, all sections reviewed)

### Agent Behavioral Files Referenced
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (Should be invoked via Task tool)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (Should be invoked via Task tool)

---

**Analysis Complete**: 2025-11-17
**Confidence Level**: High (95%) - Analysis based on direct comparison with documented standards and comparative assessment
**Recommended Next Steps**: Begin Phase 1 critical fixes for both commands in parallel, prioritizing Task tool invocation pattern compliance
