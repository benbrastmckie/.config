# Fix /research Command Allowed-Tools Configuration

## Metadata
- **Date**: 2025-10-24
- **Feature**: Fix /research command tool permissions to enforce delegation pattern
- **Scope**: Modify allowed-tools configuration in /research command
- **Estimated Phases**: 3
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Issue**: Research command conducting primary agent research instead of delegating to subagents

## Overview

The `/research` command is currently configured with excessive tool permissions that allow the orchestrator agent to conduct research directly, bypassing the intended hierarchical multi-agent delegation pattern. The command includes research tools (WebSearch, WebFetch, Read, Grep, Glob) in its `allowed-tools` list, which contradicts its architectural role as an orchestrator that should ONLY delegate work to specialized research-specialist subagents.

**Root Cause**: Tool availability overrides behavioral instructions. Despite explicit instructions "DO NOT execute research yourself," the agent uses available research tools to complete tasks directly because it's more efficient than delegation.

**Solution**: Remove research tools from allowed-tools, keeping only Task (for delegation) and Bash (for setup scripts), enforcing the architectural constraint at the permission level.

## Success Criteria
- [ ] /research command uses only Task and Bash tools
- [ ] Primary agent cannot conduct research directly (verified by tool constraints)
- [ ] Orchestrator successfully delegates to research-specialist subagents
- [ ] All research activities occur in subagent context
- [ ] Path pre-calculation and setup scripts still function (Bash retained)
- [ ] Test case confirms delegation pattern is enforced

## Technical Design

### Current Configuration
```yaml
# .claude/commands/research.md (line 2)
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task
```

**Problem**: 7 tools available, 6 of which enable direct research

### Target Configuration
```yaml
# .claude/commands/research.md (line 2)
allowed-tools: Task, Bash
```

**Rationale**:
- **Task**: Required for delegating to research-specialist and research-synthesizer agents
- **Bash**: Required for executing decomposition scripts, path calculation, verification checkpoints
- **Removed**: Read, Write, Grep, Glob, WebSearch, WebFetch (research tools that bypass delegation)

### Workflow Impact Analysis

**Preserved Capabilities** (Bash + Task):
1. Topic decomposition via bash scripts (lines 40-50)
2. Path pre-calculation via bash scripts (lines 82-160)
3. Directory verification checkpoints (lines 99-106, 122-126)
4. Subtopic report path calculation (lines 131-144)
5. Agent invocation via Task tool (lines 172-225, 321-360, 376-430)
6. Report verification via bash (lines 238-300)

**Removed Capabilities** (intentionally restricted):
1. Direct file reading (Read tool)
2. Direct file writing (Write tool)
3. Direct codebase searching (Grep/Glob tools)
4. Direct web research (WebSearch/WebFetch tools)

**Agent Delegation Requirements**:
All research activities must occur through:
- `research-specialist` agents (parallel, one per subtopic)
- `research-synthesizer` agent (single, for overview synthesis)

### Enforcement Mechanism

**Before Fix**:
```
Agent sees instruction: "DO NOT research yourself"
Agent has tools: WebSearch, Read, Grep, etc.
Agent decision: "I'll use available tools anyway" ❌
```

**After Fix**:
```
Agent sees instruction: "DO NOT research yourself"
Agent has tools: Task, Bash only
Agent decision: "I must delegate (no research tools)" ✅
```

### Testing Strategy

Create test case that verifies:
1. /research invocation triggers Task tool usage (not research tools)
2. Primary agent output contains agent invocation markers
3. No WebSearch/Read/Grep operations in primary agent context
4. Research activities occur in subagent outputs only

## Implementation Phases

### Phase 1: Modify Allowed-Tools Configuration
**Objective**: Update /research command frontmatter to restrict tool permissions
**Complexity**: Low

Tasks:
- [ ] Read current /research command configuration (.claude/commands/research.md:1-7)
- [ ] Update allowed-tools from `Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task` to `Task, Bash`
- [ ] Verify frontmatter syntax is valid (YAML format)
- [ ] Verify no other command-level configuration needs adjustment
- [ ] Document the change rationale in git commit message

Testing:
```bash
# Verify allowed-tools contains only Task and Bash
head -10 /home/benjamin/.config/.claude/commands/research.md | grep "allowed-tools:"
# Expected: allowed-tools: Task, Bash
```

**Files Modified**:
- `.claude/commands/research.md:2` (allowed-tools line)

### Phase 2: Validate Command Workflow Compatibility
**Objective**: Ensure command workflow still functions with restricted tools
**Complexity**: Medium

Tasks:
- [ ] Review bash script blocks in command (lines 40-50, 82-160, 238-300, 308-318)
- [ ] Verify bash scripts don't require removed tools (Read, Write, Grep, Glob, WebSearch, WebFetch)
- [ ] Confirm Task tool invocations remain unchanged (lines 172-225, 321-360, 376-430)
- [ ] Check verification checkpoints use bash commands only (lines 99-106, 122-126, 147-161)
- [ ] Verify agent prompt templates reference correct tools for subagents
- [ ] Confirm fallback mechanisms still work (lines 264-290 - uses bash cat/heredoc)

Testing:
```bash
# Verify bash scripts in command are syntactically valid
bash -n /home/benjamin/.config/.claude/commands/research.md 2>&1 | grep -v "command substitution"

# Check for any direct tool usage that would fail with new restrictions
grep -E "(Read|Write|Grep|Glob|WebSearch|WebFetch)\(" /home/benjamin/.config/.claude/commands/research.md
# Should return empty or only references in agent prompt templates
```

**Analysis Points**:
- Decomposition scripts: Use bash source/function calls only ✓
- Path calculation: Use bash string manipulation only ✓
- Verification: Use bash test operators and find commands ✓
- Fallback reports: Use bash cat with heredoc ✓
- Agent invocations: Use Task tool (retained) ✓

### Phase 3: Integration Testing and Validation
**Objective**: Verify delegation pattern is enforced in practice
**Complexity**: Medium

Tasks:
- [ ] Create test script for /research delegation verification
- [ ] Run /research with sample topic and capture execution trace
- [ ] Verify primary agent uses only Task and Bash tools
- [ ] Verify research-specialist agents receive correct prompts and paths
- [ ] Verify research activities occur in subagent context only
- [ ] Check that reports are created by subagents at correct paths
- [ ] Verify overview synthesis occurs via research-synthesizer agent
- [ ] Confirm no regression in report quality or structure
- [ ] Document test results and validation evidence

Testing:
```bash
# Create test script
cat > /home/benjamin/.config/.claude/tests/test_research_delegation.sh <<'EOF'
#!/bin/bash
# Test: Verify /research enforces delegation pattern

set -e

TOPIC="Test authentication patterns"
EXECUTION_LOG="/tmp/research_delegation_test.log"

echo "Testing /research delegation enforcement..."

# This would be invoked through Claude Code interface
# Manual verification steps:
# 1. Run: /research "test authentication patterns"
# 2. Check execution log for:
#    - Task tool invocations (should be present)
#    - WebSearch/Read/Grep in primary context (should be absent)
#    - PROGRESS markers from subagents (should be present)
#    - Report creation by subagents (should be present)

echo "Manual verification required:"
echo "1. Invoke: /research '$TOPIC'"
echo "2. Verify primary agent output contains Task invocations"
echo "3. Verify NO WebSearch/Read/Grep in primary agent context"
echo "4. Verify research activities occur in subagent outputs"
echo "5. Verify reports created at correct paths"

# Automated checks (post-execution)
# Verify allowed-tools configuration
ALLOWED_TOOLS=$(grep "^allowed-tools:" /home/benjamin/.config/.claude/commands/research.md | cut -d: -f2 | tr -d ' ')

if [[ "$ALLOWED_TOOLS" == "Task,Bash" ]]; then
  echo "✓ PASS: allowed-tools correctly restricted to Task, Bash"
else
  echo "✗ FAIL: allowed-tools = '$ALLOWED_TOOLS' (expected: Task,Bash)"
  exit 1
fi

echo "✓ Configuration test passed"
echo "Run manual delegation verification to complete testing"
EOF

chmod +x /home/benjamin/.config/.claude/tests/test_research_delegation.sh

# Run configuration test
/home/benjamin/.config/.claude/tests/test_research_delegation.sh
```

**Validation Criteria**:
- [ ] Primary agent execution trace shows Task tool usage only (no research tools)
- [ ] Agent invocation prompts appear in execution log
- [ ] PROGRESS markers from subagents visible in output
- [ ] Research reports created at correct paths by subagents
- [ ] No WebSearch/Read/Grep operations in primary agent context
- [ ] Overview synthesis occurs via research-synthesizer invocation

**Files Created**:
- `.claude/tests/test_research_delegation.sh` (test script)

## Testing Strategy

### Unit Testing
- Verify allowed-tools configuration syntax
- Validate bash script blocks are syntactically correct
- Check agent prompt templates reference correct tools

### Integration Testing
- Run /research with test topic
- Verify delegation pattern enforcement
- Confirm report creation workflow
- Validate cross-references and metadata

### Regression Testing
- Compare report structure before/after change
- Verify no functionality loss in research quality
- Confirm path calculation and verification still work

## Documentation Requirements

### Command Documentation
- Update /research command description if needed (currently accurate)
- Ensure behavioral instructions remain clear
- Document tool restriction rationale in commit message

### Architecture Documentation
- Reference this fix in hierarchical agent architecture docs
- Update troubleshooting guide with delegation pattern enforcement
- Document the principle: "Tool constraints enforce architectural patterns"

## Dependencies

### Prerequisites
- Bash shell available in execution environment
- Task tool functional and able to invoke general-purpose agents
- research-specialist agent definition exists (.claude/agents/research-specialist.md)
- research-synthesizer agent definition exists (.claude/agents/research-synthesizer.md)

### External Dependencies
None - this is a configuration change only

## Research Reports

This plan was informed by comprehensive research analyzing tool restriction approaches, enforcement mechanisms, and post-delegation flexibility requirements.

### Overview Report
- [Research Command Tool Restrictions Analysis](../../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/OVERVIEW.md) - Multi-perspective architectural analysis of tool restriction effectiveness and phase-based tool requirements

### Subtopic Reports
1. [Current Plan Tool Restriction Analysis](../../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/001_current_plan_tool_restriction_analysis.md) - Analysis of the proposed tool restriction approach
2. [Alternative Delegation Enforcement Mechanisms](../../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/002_alternative_delegation_enforcement_mechanisms.md) - Survey of enforcement patterns in the codebase
3. [Post-Research Primary Agent Flexibility Requirements](../../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/003_post_research_primary_agent_flexibility_requirements.md) - Analysis of tool requirements after delegation
4. [Tool Permission Architecture Tradeoffs](../../../467_the_research_command_to_see_if_homebenjaminconfigc/reports/001_research_command_tool_restrictions_analysis_research/004_tool_permission_architecture_tradeoffs.md) - Tradeoffs between different enforcement approaches

### Key Research Findings
- Tool restrictions provide psychological enforcement but are not technically enforced by Claude API
- Multi-layered enforcement (tool restrictions + role clarification + verification checkpoints) is necessary
- Post-delegation verification requires Bash, Read, and Write tools for 100% file creation reliability
- Phase-based tool access model balances delegation enforcement with post-delegation flexibility

## Risk Assessment

### Low Risk
- **Change Scope**: Single line configuration change
- **Reversibility**: Easily reverted if issues discovered
- **Testing**: Can validate without impacting other commands

### Potential Issues
1. **Bash scripts might fail**: If scripts inadvertently use removed tools
   - **Mitigation**: Phase 2 validates all bash blocks
   - **Fallback**: Add Read tool back if absolutely required for verification

2. **Agent invocation might fail**: If Task tool has issues
   - **Mitigation**: Test Task tool separately before deployment
   - **Fallback**: Add minimal tools back if Task delegation broken

3. **Performance impact**: More agent invocations might increase latency
   - **Mitigation**: This is architectural intent (parallel subagents)
   - **Benefit**: Enforced delegation ensures hierarchical pattern works as designed

## Success Metrics

### Functional Success
- [x] Configuration change applied
- [ ] Tests pass (delegation enforced)
- [ ] Reports generated via subagents only
- [ ] No primary agent research detected

### Architectural Success
- [ ] Delegation pattern enforced at tool level
- [ ] Hierarchical multi-agent pattern validated
- [ ] Agent behavioral injection working correctly
- [ ] Tool constraints align with architectural role

## Notes

### Design Principle Validated
This fix demonstrates the principle: **"Tool constraints should enforce architectural patterns, not rely on behavioral instructions alone."**

When an agent has tools available, it will use them even when instructed not to. Architectural enforcement must occur at the permission level.

### Future Improvements
1. Consider applying same principle to other orchestrator commands
2. Review /orchestrate allowed-tools for similar issues
3. Document pattern in command development guide
4. Create linting rule to detect orchestrator commands with research tools

### Related Issues
- /orchestrate may have similar allowed-tools configuration issues
- All commands following behavioral injection pattern should be reviewed
- Agent development guide should document tool restriction patterns

## Rollback Plan

If issues discovered after deployment:

```bash
# Restore original configuration
cd /home/benjamin/.config/.claude/commands
git diff research.md  # Review changes
git checkout HEAD -- research.md  # Restore original

# Or manual restoration
sed -i 's/^allowed-tools: Task, Bash$/allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task/' research.md
```

**Rollback Criteria**:
- Task delegation fails consistently
- Bash scripts fail due to missing tools
- Report quality significantly degraded
- Workflow broken with no quick fix

**Rollback Testing**:
After rollback, verify original behavior returns (primary agent conducts research directly).
