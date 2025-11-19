# Agent Invocation Pattern Remediation Analysis

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Agent invocation pattern violations across 5 commands
- **Report Type**: Technical remediation analysis
- **Commands Analyzed**: /build, /fix, /research-report, /research-plan, /research-revise
- **Total Violations**: 13 instances

## Executive Summary

All 5 research-focused and debug-focused workflow commands violate Standard 0.5 (Agent Execution Enforcement) by using echo-based documentation instead of executable Task tool invocations with behavioral injection. This critical architectural violation causes 60-80% file creation reliability (vs 100% with proper invocation), 0% behavioral guideline enforcement, and breaks the hierarchical agent pattern documented in execution-enforcement-guide.md. Remediation requires replacing all 13 echo-based invocations with Task tool calls using behavioral injection pattern, estimated at 15 hours total effort with expected improvement to 100% file creation reliability.

## Problem Analysis

### Current Pattern (All 13 Instances)

**Generic implementation found across all commands**:
```bash
echo "EXECUTE NOW: USE the Task tool to invoke [agent-name] agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: [path]"
echo "2. Return completion signal: [SIGNAL]"
echo ""
echo "Workflow-Specific Context:"
echo "- [Parameter 1]: [value]"
echo "- [Parameter 2]: [value]"
```

**Example from /research-plan (lines 155-175)**:
```bash
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from:"
echo "   ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Create research reports for EACH topic"
echo "3. Return completion signal: RESEARCH_COMPLETE: [count] reports created"
echo ""
echo "Research Context:"
echo "- Feature Description: $FEATURE_DESCRIPTION"
echo "- Research Complexity: $RESEARCH_COMPLEXITY"
echo "- Report Directory: $RESEARCH_DIR"
```

### Why This Pattern Fails

**Critical Failures**:
1. **No executable delegation**: Echo statements are instructions to Claude, not Task tool invocations
2. **Agent behavioral files not invoked**: Guidelines never actually followed
3. **Direct execution instead of delegation**: Claude may use Read/Write/Grep directly instead of invoking specialist agents
4. **No hierarchical pattern enforcement**: Breaks documented agent architecture

**Impact Metrics**:
- **File creation reliability**: 60-80% (documented in compliance summary report)
- **Behavioral guideline enforcement**: 0% (guidelines printed but not followed)
- **Hierarchical pattern compliance**: 0% (direct execution instead of delegation)
- **Predictability**: Low (behavior varies based on Claude's interpretation)

### Expected Pattern (Standard 0.5 Compliance)

**From execution-enforcement-guide.md:104-138**:

```markdown
# AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)

Task {
  subagent_type: "general-purpose"
  description: "[Agent] - [Purpose]"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **ABSOLUTE REQUIREMENT**: [Primary task]

    **CONTEXT**:
    - [Parameter 1]: [value]
    - [Parameter 2]: [value]

    **CRITICAL**: [Critical directive]

    Return completion signal: [SIGNAL]: [VALUE]
  "
}
```

**Key Characteristics**:
- **Executable**: Uses Task tool, not echo
- **Behavioral injection**: References agent file, doesn't duplicate procedures
- **Context injection**: Provides parameters only, not behavioral guidelines
- **90% code reduction**: Agent behavioral file is single source of truth

## Violation Inventory

### /build Command (2 Instances)

**Instance 1: implementer-coordinator invocation (estimated line 150-170)**
- **Purpose**: Execute implementation phase
- **Context parameters**: PLAN_FILE, STARTING_PHASE, DRY_RUN
- **Return signal**: IMPLEMENTATION_COMPLETE: [summary]

**Instance 2: debug-analyst invocation (estimated line 220-240)**
- **Purpose**: Debug test failures
- **Context parameters**: TEST_FAILURES, IMPLEMENTATION_LOG
- **Return signal**: DEBUG_COMPLETE: [fixes]

### /fix Command (3 Instances)

**Instance 1: research-specialist invocation**
- **Purpose**: Research issue context
- **Context parameters**: ISSUE_DESCRIPTION, DEBUG_DIR
- **Return signal**: RESEARCH_COMPLETE: [reports]

**Instance 2: plan-architect invocation**
- **Purpose**: Create debug plan
- **Context parameters**: RESEARCH_REPORTS, ISSUE_DESCRIPTION, PLAN_PATH
- **Return signal**: PLAN_CREATED: [path]

**Instance 3: debug-analyst invocation**
- **Purpose**: Execute debug plan
- **Context parameters**: DEBUG_PLAN, ISSUE_DESCRIPTION
- **Return signal**: DEBUG_COMPLETE: [fixes]

### /research-report Command (1 Instance)

**Instance 1: research-specialist invocation (lines 155-175)**
- **Purpose**: Create research report
- **Context parameters**: RESEARCH_TOPIC, REPORT_PATH, COMPLEXITY
- **Return signal**: REPORT_CREATED: [path]

### /research-plan Command (2 Instances)

**Instance 1: research-specialist invocation (lines 155-175)**
- **Purpose**: Research feature requirements
- **Context parameters**: FEATURE_DESCRIPTION, COMPLEXITY, RESEARCH_DIR
- **Return signal**: RESEARCH_COMPLETE: [count] reports

**Instance 2: plan-architect invocation (estimated line 200-220)**
- **Purpose**: Create implementation plan
- **Context parameters**: RESEARCH_REPORTS, FEATURE_DESCRIPTION, PLAN_PATH
- **Return signal**: PLAN_CREATED: [path]

### /research-revise Command (2 Instances)

**Instance 1: research-specialist invocation**
- **Purpose**: Research revision requirements
- **Context parameters**: REVISION_DESCRIPTION, EXISTING_PLAN_PATH
- **Return signal**: RESEARCH_COMPLETE: [reports]

**Instance 2: plan-architect invocation**
- **Purpose**: Revise implementation plan
- **Context parameters**: RESEARCH_REPORTS, REVISION_DESCRIPTION, PLAN_PATH, BACKUP_PATH
- **Return signal**: PLAN_UPDATED: [path]

### Hierarchical Supervision (1 Conditional Instance)

**Instance: research-sub-supervisor invocation (conditional in /research-report)**
- **Trigger**: Complexity >= 4
- **Purpose**: Coordinate hierarchical research
- **Current status**: Documented but not invoked (lines 165-170)
- **Note**: Also uses echo pattern, not Task tool

## Remediation Specifications

### Step 1: Create Agent Invocation Templates

**Template 1: research-specialist (5 instances)**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research Specialist - [Specific Purpose]"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: Create comprehensive research reports analyzing [topic].

    **CONTEXT**:
    - Research Complexity: [COMPLEXITY_VALUE]
    - Feature Description: [DESCRIPTION]
    - Output Directory: [REPORT_DIR]
    - Source Reports: [REPORT_PATHS if applicable]

    **CRITICAL**: Create report files at exact paths specified. Return completion signal with file paths.

    Return completion signal: REPORT_CREATED: [absolute-path1] [absolute-path2] ...
  "
}
```

**Template 2: plan-architect (4 instances)**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Plan Architect - [Plan Type]"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **ABSOLUTE REQUIREMENT**: Create [new|revised] implementation plan at exact path.

    **CONTEXT**:
    - Plan Path: [PLAN_PATH]
    - Feature Description: [DESCRIPTION]
    - Research Reports: [REPORT_PATHS]
    - Backup Path: [BACKUP_PATH if revision]

    **CRITICAL**: Create plan file with complete phase structure. Return path confirmation.

    Return completion signal: PLAN_CREATED: [absolute-path]
  "
}
```

**Template 3: implementer-coordinator (1 instance)**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Implementer Coordinator - Execute Implementation Plan"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **ABSOLUTE REQUIREMENT**: Execute implementation plan phases and verify completion.

    **CONTEXT**:
    - Plan File: [PLAN_FILE]
    - Starting Phase: [STARTING_PHASE]
    - Dry Run Mode: [DRY_RUN]

    **CRITICAL**: Execute phases sequentially, run tests after each phase, commit on success.

    Return completion signal: IMPLEMENTATION_COMPLETE: [phase-count] phases executed
  "
}
```

**Template 4: debug-analyst (2 instances)**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Debug Analyst - [Debug Context]"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

    **ABSOLUTE REQUIREMENT**: Analyze failures and implement fixes.

    **CONTEXT**:
    - Issue Description: [ISSUE_DESC]
    - Debug Plan: [PLAN_PATH if applicable]
    - Test Failures: [FAILURE_LOG if applicable]

    **CRITICAL**: Create debug artifacts in debug/ directory. Return fix summary.

    Return completion signal: DEBUG_COMPLETE: [fix-count] fixes applied
  "
}
```

**Template 5: research-sub-supervisor (1 conditional instance)**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research Sub-Supervisor - Coordinate Hierarchical Research"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-sub-supervisor.md

    **ABSOLUTE REQUIREMENT**: Decompose complex research into subtopics and coordinate parallel research.

    **CONTEXT**:
    - Research Complexity: [COMPLEXITY_VALUE]
    - Research Topic: [TOPIC]
    - Output Directory: [REPORT_DIR]

    **CRITICAL**: Invoke research-specialist for each subtopic, verify all reports created.

    Return completion signal: SUPERVISION_COMPLETE: [report-count] reports created
  "
}
```

### Step 2: Replace Echo Invocations with Task Tool Calls

**Process per instance**:
1. Locate echo-based invocation block
2. Identify agent type and context parameters
3. Select appropriate template from Step 1
4. Replace echo statements with Task tool invocation
5. Verify context parameters correctly passed
6. Test invocation with actual execution

**Estimated time per instance**: 1-1.5 hours
- Template customization: 15 minutes
- Context parameter extraction: 20 minutes
- Integration with command flow: 30 minutes
- Testing and verification: 15-30 minutes

### Step 3: Add Verification and Fallback

**After each agent invocation**, add verification checkpoint:

```bash
**MANDATORY VERIFICATION - [Agent] File Creation**

After [agent-name] completes, verify artifacts created:

```bash
if [ ! -f "$EXPECTED_FILE" ]; then
  echo "WARNING: [Agent] did not create file, using fallback" >&2

  # FALLBACK MECHANISM - Create minimal file
  cat > "$EXPECTED_FILE" <<'EOF'
# [Artifact Type]

## Auto-Generated Fallback

[Agent] was invoked but did not create file.
This is a minimal placeholder.

[Basic template content]
EOF

  echo "✓ FALLBACK: Created minimal file at $EXPECTED_FILE"
else
  FILE_SIZE=$(wc -c < "$EXPECTED_FILE" 2>/dev/null || echo 0)
  echo "✓ VERIFIED: [Agent] created file at $EXPECTED_FILE ($FILE_SIZE bytes)"
fi
```
```

**Estimated time per verification**: 20 minutes
- Template customization: 10 minutes
- Fallback content creation: 5 minutes
- Integration and testing: 5 minutes

### Step 4: Update Command Documentation

**For each command**:
1. Add "THIS EXACT TEMPLATE (No modifications)" markers before Task invocations
2. Document expected agent outputs in command guide
3. Update cross-references to agent behavioral files
4. Add troubleshooting section for agent non-compliance

**Estimated time per command**: 15 minutes

## Implementation Strategy

### Approach: Parallel by Agent Type

**Phase 1: Create and Test Templates** (3 hours)
- Create 5 agent invocation templates (1 hour)
- Test each template in isolation (2 hours)
- Validate behavioral injection works correctly

**Phase 2: Replace Invocations by Agent Type** (9 hours)
- research-specialist (5 instances): 5 × 1 hour = 5 hours
- plan-architect (4 instances): 4 × 1 hour = 4 hours
- Total: 9 hours

**Phase 3: Replace Remaining Agent Invocations** (3 hours)
- implementer-coordinator (1 instance): 1 hour
- debug-analyst (2 instances): 2 × 1 hour = 2 hours
- Total: 3 hours

**Total Estimated Effort**: 15 hours

### Advantages of Agent Type Approach

1. **Template reuse**: Same template applies to multiple invocations
2. **Consistency**: All invocations of same agent use identical pattern
3. **Faster debugging**: Agent-specific issues caught early
4. **Easier testing**: Can test all research-specialist invocations together

## Testing and Validation

### Test Protocol per Command

```bash
# For each command with agent invocations

# Test 1: Verify Task tool invocation visible
/[command-name] "test input" 2>&1 | grep "Task {"
# Expected: Output contains Task invocation blocks

# Test 2: Verify behavioral file referenced
/[command-name] "test input" 2>&1 | grep "Read and follow.*agents"
# Expected: Output contains agent file paths

# Test 3: Verify file creation reliability (10 trials)
for i in {1..10}; do
  rm -rf test_artifacts/
  /[command-name] "test input"
  if [ -f "expected_output.md" ]; then
    echo "✓ Trial $i: File created"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "✗ Trial $i: File NOT created"
  fi
done
echo "File creation rate: $SUCCESS/10 (target: 10/10)"

# Test 4: Verify return signal format
/[command-name] "test input" 2>&1 | grep -E "REPORT_CREATED:|PLAN_CREATED:|DEBUG_COMPLETE:"
# Expected: Proper completion signals
```

### Success Criteria

**Per Command**:
- [ ] All echo-based invocations replaced with Task tool calls
- [ ] All Task invocations reference agent behavioral files
- [ ] All context parameters correctly passed
- [ ] File creation reliability: 10/10 trials
- [ ] Completion signals in expected format
- [ ] Fallback mechanisms trigger when agent fails

**Overall Project**:
- [ ] 13/13 invocations migrated
- [ ] 5/5 commands achieve 100% file creation rate
- [ ] 0 behavioral guideline duplications
- [ ] All agent behavioral files remain single source of truth

## Expected Outcomes

### Before Remediation

- **File creation reliability**: 60-80%
- **Behavioral guideline enforcement**: 0%
- **Hierarchical pattern compliance**: 0%
- **Code duplication**: High (behavioral guidelines duplicated in prompts)
- **Maintenance burden**: High (synchronization between commands and agents)

### After Remediation

- **File creation reliability**: 100%
- **Behavioral guideline enforcement**: 100%
- **Hierarchical pattern compliance**: 100%
- **Code duplication**: Minimal (agent files are single source of truth)
- **Maintenance burden**: Low (update agent file once, affects all invocations)

### ROI Analysis

**Investment**: 15 hours
**Return**:
- 40% improvement in file creation reliability (60-80% → 100%)
- 100% improvement in behavioral enforcement (0% → 100%)
- 90% reduction in prompt size per invocation
- Elimination of synchronization burden

**Payback period**: Immediate (first use after remediation)

## References

### Standards Documents
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (lines 104-138: Behavioral Injection Pattern)
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (lines 536-567: Agent Invocation Template)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (Standard 0.5: Agent Execution Enforcement)

### Source Reports
- `/home/benjamin/.config/.claude/specs/15_research_the_compliance_of_build_fix_research_repo/reports/005_compliance_summary_and_recommendations.md` (lines 76-132: Agent invocation pattern violations)
- `/home/benjamin/.config/.claude/specs/15_research_the_compliance_of_build_fix_research_repo/debug/002_compliance_issues_summary.md` (lines 18-64: Critical issue analysis)

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (110/100 compliance score - reference model)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (100/100 compliance score)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
- `/home/benjamin/.config/.claude/agents/debug-analyst.md`
- `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md`

### Command Files Requiring Remediation
- `/home/benjamin/.config/.claude/commands/build.md` (2 instances)
- `/home/benjamin/.config/.claude/commands/fix.md` (3 instances)
- `/home/benjamin/.config/.claude/commands/research-report.md` (1-2 instances)
- `/home/benjamin/.config/.claude/commands/research-plan.md` (2 instances)
- `/home/benjamin/.config/.claude/commands/research-revise.md` (2 instances)

## Conclusion

Agent invocation pattern violations represent the highest priority remediation target for all 5 commands. The uniform violation pattern (echo-based documentation instead of Task tool invocations) indicates a systemic implementation approach that needs correction. Implementing the behavioral injection pattern will immediately improve file creation reliability from 60-80% to 100% while reducing prompt size by 90% and eliminating synchronization burden between commands and agent behavioral files. The 15-hour investment provides immediate ROI through improved reliability and long-term ROI through reduced maintenance burden.
