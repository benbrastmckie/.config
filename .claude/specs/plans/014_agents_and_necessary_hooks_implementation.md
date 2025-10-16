# Agents and Necessary Hooks Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All 5 phases successfully implemented and committed. The agent system is fully operational with:
- 8 specialized agents in `.claude/agents/`
- 2 necessary hooks in `.claude/hooks/`
- All primary and secondary commands refactored
- Comprehensive integration guide created

See implementation summary below for details.

---

## Metadata
- **Date**: 2025-10-01
- **Feature**: Implement 8 specialized agents and strictly necessary hooks for agent support
- **Scope**: Create agents directory with all 8 agents, implement only hooks required for agent functionality, refactor existing commands to use agents
- **Estimated Phases**: 5 phases
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/.claude/specs/reports/015_agents_and_hooks_extension_opportunities.md
- **Dependencies**: None (agents and hooks are foundational)

## Overview

This plan implements the foundational agent system and strictly necessary hooks to support agent functionality. The scope includes:

1. **8 Specialized Agents**: All agents identified in report 015
   - research-specialist, code-writer, test-specialist, doc-writer
   - code-reviewer, debug-specialist, plan-architect, metrics-specialist

2. **Strictly Necessary Hooks**: Only hooks required for agent operation
   - **post-command-metrics** - Required by metrics-specialist agent (plan 013 infrastructure)
   - **session-start-restore** - Required for workflow continuity (plan 013 infrastructure)

3. **Command Refactoring**: Update existing commands to use specialized agents
   - Primary focus: `/orchestrate`, `/implement`, `/debug`, `/plan`, `/document`, `/refactor`, `/test`

**Rationale for Minimal Hooks**: Starting with only hooks that are strictly necessary for agent functionality allows us to:
- Validate agent system works correctly
- Avoid overwhelming the system with automation
- Add more hooks incrementally based on actual usage patterns
- Focus on agent integration first

## Success Criteria

- [ ] All 8 agents created in `.claude/agents/` with proper frontmatter and instructions
- [ ] 2 necessary hooks created in `.claude/hooks/` with executable permissions
- [ ] Hook configuration added to `.claude/settings.local.json`
- [ ] `/orchestrate` command refactored to use specialized agents (research-specialist, plan-architect, code-writer, test-specialist, debug-specialist, doc-writer)
- [ ] `/implement` command refactored to use code-writer and test-specialist
- [ ] `/debug` command refactored to use debug-specialist
- [ ] `/plan` command refactored to use research-specialist and plan-architect
- [ ] `/document` command refactored to use doc-writer
- [ ] `/refactor` command refactored to use code-reviewer
- [ ] `/test` command refactored to use test-specialist
- [ ] All refactored commands tested with agent delegation
- [ ] Metrics collected via hook demonstrate agent usage
- [ ] Documentation updated for agent usage patterns

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ Existing Commands (19)                                  │
│ /orchestrate, /implement, /plan, /debug, etc.          │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Task tool invocations
                 │ subagent_type: <agent-name>
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Specialized Agents (.claude/agents/)                    │
├─────────────────────────────────────────────────────────┤
│ • research-specialist   → Read, Grep, Glob, WebSearch   │
│ • code-writer          → Read, Write, Edit, Bash        │
│ • test-specialist      → Bash, Read, Grep               │
│ • doc-writer           → Read, Write, Edit, Grep, Glob  │
│ • code-reviewer        → Read, Grep, Glob, Bash         │
│ • debug-specialist     → Read, Bash, Grep, Glob, WebSrc │
│ • plan-architect       → Read, Write, Grep, Glob, WebSrc│
│ • metrics-specialist   → Read, Bash, Grep               │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Events
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Necessary Hooks (.claude/hooks/)                        │
├─────────────────────────────────────────────────────────┤
│ • post-command-metrics.sh  → Stop event                 │
│ • session-start-restore.sh → SessionStart event         │
└─────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Infrastructure (from plan 013)                          │
├─────────────────────────────────────────────────────────┤
│ • .claude/data/metrics/*.jsonl  (metrics collection)         │
│ • .claude/state/*.json     (workflow state)             │
└─────────────────────────────────────────────────────────┘
```

### Agent Design Patterns

Each agent follows this structure:

```markdown
---
allowed-tools: <comma-separated list>
description: <one-line description>
---

# <Agent Name>

<Purpose and responsibilities>

## Core Capabilities

<What this agent can do>

## Standards Compliance

<Instructions for following project standards>

## Behavioral Guidelines

<How the agent should operate>

## Example Usage

<Example Task tool invocations>
```

### Hook Design Patterns

Hooks follow this structure:

```bash
#!/bin/bash
# <Hook name>
# Purpose: <what it does>

# Environment variables available:
# - $CLAUDE_PROJECT_DIR
# - $CLAUDE_COMMAND (for Stop hook)
# - $CLAUDE_DURATION_MS (for Stop hook)
# - $CLAUDE_STATUS (for Stop hook)

# Hook logic here

exit 0  # Always exit 0 for non-blocking hooks
```

### Command Refactoring Pattern

Current pattern (general-purpose):
```markdown
I'll use the Task tool to delegate this work.

Task {
  subagent_type = "general-purpose",
  description = "Research authentication patterns",
  prompt = "Analyze codebase for authentication patterns..."
}
```

New pattern (specialized agent):
```markdown
I'll use the Task tool to delegate this research work to the research-specialist agent.

Task {
  subagent_type = "research-specialist",
  description = "Research authentication patterns",
  prompt = "Analyze the codebase for authentication patterns. Focus on:
  - Existing auth modules and their organization
  - Common authentication flows
  - Security patterns used
  Provide a concise summary (200 words max)."
}
```

## Implementation Phases

### Phase 1: Foundation - Create Agent Directory and Core Agents [COMPLETED]
**Objective**: Create agents directory and implement the 4 most critical agents
**Complexity**: Low

Tasks:
- [x] Create `.claude/agents/` directory
- [x] Create `.claude/agents/research-specialist.md`
  - allowed-tools: Read, Grep, Glob, WebSearch, WebFetch
  - Focus on read-only research capabilities
  - Instructions for concise summaries (200 words max)
  - Standards: Follow research patterns from existing `/report` command
- [x] Create `.claude/agents/code-writer.md`
  - allowed-tools: Read, Write, Edit, Bash, TodoWrite
  - Instructions to always check CLAUDE.md for standards
  - Emphasis on 2-space indentation, snake_case naming
  - Include test execution after modifications
- [x] Create `.claude/agents/test-specialist.md`
  - allowed-tools: Bash, Read, Grep
  - Parse test output for failures
  - Categorize errors (compilation, runtime, assertion)
  - Provide actionable suggestions
- [x] Create `.claude/agents/plan-architect.md`
  - allowed-tools: Read, Write, Grep, Glob, WebSearch
  - Instructions for phased planning
  - Emphasis on testing strategy per phase
  - Include checkboxes for `/implement` compatibility

Testing:
```bash
# Verify agent files created
ls -la .claude/agents/

# Verify agent frontmatter is valid YAML
for f in .claude/agents/*.md; do head -10 "$f" | grep -A 5 "^---$"; done

# Test research-specialist invocation manually (if possible)
# This would require Claude Code agent invocation support
```

**Expected Duration**: 2-3 hours

### Phase 2: Specialized Agents - Quality and Analysis Agents [COMPLETED]
**Objective**: Create remaining 4 specialized agents
**Complexity**: Low

Tasks:
- [x] Create `.claude/agents/doc-writer.md`
  - allowed-tools: Read, Write, Edit, Grep, Glob
  - Follow Documentation Policy from CLAUDE.md
  - Instructions for Unicode box-drawing (not ASCII art)
  - No emojis in content (UTF-8 encoding)
  - Cross-reference specs properly
- [x] Create `.claude/agents/code-reviewer.md`
  - allowed-tools: Read, Grep, Glob, Bash
  - Checklist: indentation (2 spaces), naming (snake_case), error handling (pcall), line length (<100)
  - Output format: structured review with severity levels
  - Non-blocking suggestions vs blocking issues
- [x] Create `.claude/agents/debug-specialist.md`
  - allowed-tools: Read, Bash, Grep, Glob, WebSearch
  - Focus on evidence gathering (logs, error messages, stack traces)
  - Propose multiple solutions with pros/cons
  - Never modify code directly (read-only debugging)
- [x] Create `.claude/agents/metrics-specialist.md`
  - allowed-tools: Read, Bash, Grep
  - Parse JSONL files from `.claude/data/metrics/*.jsonl`
  - Calculate statistics (avg, p50, p95, p99)
  - Identify bottlenecks and suggest optimizations
  - Note: Requires infrastructure from plan 013

Testing:
```bash
# Verify all 8 agents exist
ls .claude/agents/*.md | wc -l
# Should output: 8

# Verify each agent has proper frontmatter
for f in .claude/agents/*.md; do
  echo "Checking $f..."
  grep -q "^allowed-tools:" "$f" && grep -q "^description:" "$f" && echo "  ✓ Valid" || echo "  ✗ Invalid"
done
```

**Expected Duration**: 2-3 hours

### Phase 3: Necessary Hooks - Metrics and State Management [COMPLETED]
**Objective**: Implement only hooks required for agent operation
**Complexity**: Medium

Tasks:
- [x] Create `.claude/hooks/` directory
- [x] Create `.claude/hooks/post-command-metrics.sh`
  - Make executable: `chmod +x`
  - Trigger on Stop event
  - Collect: timestamp, command name, duration, status
  - Append to `.claude/data/metrics/YYYY-MM.jsonl`
  - Create metrics directory if not exists
  - Non-blocking (always exit 0)
- [x] Create `.claude/hooks/session-start-restore.sh`
  - Make executable: `chmod +x`
  - Trigger on SessionStart (startup|resume)
  - Check for `.claude/state/*.json` files
  - Display helpful message if interrupted workflows found
  - Non-blocking (always exit 0)
- [x] Update `.claude/settings.local.json` with hook configuration
  - Add hooks section if not exists
  - Configure post-command-metrics for Stop event
  - Configure session-start-restore for SessionStart event
  - Preserve existing settings (permissions, etc.)
- [x] Create `.claude/data/metrics/` directory (if not exists from plan 013)
- [x] Test post-command-metrics hook
  - Run a simple command
  - Verify metrics JSONL file created
  - Verify JSON format is valid
- [x] Test session-start-restore hook
  - Create dummy `.claude/state/test.json` file
  - Restart Claude Code session (or simulate)
  - Verify message displayed

Hook Configuration (`.claude/settings.local.json`):
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-command-metrics.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start-restore.sh"
          }
        ]
      }
    ]
  }
}
```

Testing:
```bash
# Verify hooks directory and files
ls -la .claude/hooks/

# Verify hooks are executable
test -x .claude/hooks/post-command-metrics.sh && echo "✓ Metrics hook executable"
test -x .claude/hooks/session-start-restore.sh && echo "✓ Restore hook executable"

# Verify hook configuration in settings
cat .claude/settings.local.json | jq '.hooks'

# Test metrics collection (manual trigger)
export CLAUDE_PROJECT_DIR="$PWD"
export CLAUDE_COMMAND="/test"
export CLAUDE_DURATION_MS="1234"
export CLAUDE_STATUS="success"
.claude/hooks/post-command-metrics.sh

# Verify metrics file created
ls -la .claude/data/metrics/*.jsonl
cat .claude/data/metrics/*.jsonl | tail -1 | jq .
```

**Expected Duration**: 2-3 hours

### Phase 4: Command Refactoring - Primary Commands [COMPLETED]
**Objective**: Refactor primary commands to use specialized agents
**Complexity**: High

Tasks:
- [x] Refactor `/orchestrate` command (commands/orchestrate.md)
  - Phase 1 (Research): Use `research-specialist` instead of `general-purpose`
  - Phase 2 (Planning): Use `plan-architect` instead of `general-purpose`
  - Phase 3 (Implementation): Use `code-writer` instead of `general-purpose`
  - Phase 3 (Testing): Use `test-specialist` for test execution
  - Phase 4 (Debugging): Use `debug-specialist` in debugging loop
  - Phase 5 (Documentation): Use `doc-writer` instead of `general-purpose`
  - Update all Task tool invocations with agent-specific prompts
  - Add agent usage notes to command documentation
- [x] Refactor `/implement` command (commands/implement.md)
  - Phase execution: Use `code-writer` for implementation tasks
  - Testing validation: Use `test-specialist` after each phase
  - Optional: Use `code-reviewer` for standards check before marking phase complete
  - Update Task tool invocations
  - Note: /implement executes directly without agents for performance
- [x] Refactor `/debug` command (commands/debug.md)
  - Delegate investigation to `debug-specialist`
  - Provide structured prompt with issue description and context
  - Parse debug-specialist output for diagnostic report
- [x] Refactor `/plan` command (commands/plan.md)
  - Research phase: Use `research-specialist` for codebase analysis
  - Planning phase: Use `plan-architect` for plan generation
  - Update Task tool invocations
- [x] Refactor `/document` command (commands/document.md)
  - Delegate documentation updates to `doc-writer`
  - Provide context about recent changes
  - Specify affected documentation files

Testing per command:
```bash
# Test /orchestrate with agents
/orchestrate "Add simple test feature"
# Verify: research-specialist, plan-architect, code-writer, test-specialist used
# Check metrics: .claude/data/metrics/*.jsonl should show subagent invocations

# Test /implement with agents
/implement specs/plans/001_test_plan.md
# Verify: code-writer and test-specialist used

# Test /debug with agents
/debug "Error in module X"
# Verify: debug-specialist used

# Test /plan with agents
/plan "New feature Y"
# Verify: research-specialist and plan-architect used

# Test /document with agents
/document
# Verify: doc-writer used
```

**Expected Duration**: 6-8 hours

### Phase 5: Command Refactoring - Dependent and Secondary Commands [COMPLETED]
**Objective**: Refactor remaining commands to use specialized agents
**Complexity**: Medium

Tasks:
- [x] Refactor `/refactor` command (commands/refactor.md)
  - Analysis phase: Use `code-reviewer` for standards compliance analysis
  - Provide detailed analysis output
- [x] Refactor `/test` command (commands/test.md)
  - Delegate test execution to `test-specialist`
  - Parse and format test results
  - Optional direct execution mode for quick tests
- [x] Refactor `/test-all` command (commands/test-all.md)
  - Delegate full test suite execution to `test-specialist`
  - Aggregate results from multiple test runs
  - Coverage analysis integration
- [x] Review remaining commands for agent opportunities
  - `/report`: Documented optional `research-specialist` usage
  - `/revise`: No agent delegation needed (plan manipulation)
  - Other commands: Evaluated - most work best with direct execution
- [x] Update command documentation
  - Add "Agent Usage" section to each refactored command
  - Document which agents are used and when
  - Provide examples of agent invocations
- [x] Create `.claude/docs/agent-integration-guide.md`
  - Document agent integration patterns
  - Provide examples for each agent type
  - Include troubleshooting tips
  - Document how to add new agents

Testing:
```bash
# Test /refactor with agents
/refactor path/to/code.lua
# Verify: code-reviewer used

# Test /test with agents
/test feature_x
# Verify: test-specialist used

# Test /test-all with agents
/test-all
# Verify: test-specialist used

# Verify all refactored commands documented
grep -l "Agent Usage" .claude/commands/*.md

# Integration test: Full workflow with agents
/orchestrate "Complete feature with all agents"
# Should use: research-specialist, plan-architect, code-writer, test-specialist, doc-writer
# Verify metrics collected: cat .claude/data/metrics/*.jsonl | grep -c "subagent"
```

**Expected Duration**: 4-5 hours

## Testing Strategy

### Unit Testing (Per Agent)
For each agent:
1. Verify frontmatter is valid YAML
2. Verify allowed-tools list is correct
3. Verify description is concise and accurate
4. Review agent instructions for completeness

### Integration Testing (Command + Agent)
For each refactored command:
1. Run command with simple test case
2. Verify correct agent is invoked
3. Verify agent produces expected output
4. Verify command handles agent output correctly

### Hook Testing
For each hook:
1. Verify hook is executable
2. Verify hook runs without errors
3. Verify hook produces expected side effects (metrics file, console output)
4. Verify hook is non-blocking (exits 0)

### End-to-End Testing
1. Run full `/orchestrate` workflow
2. Verify all agents used in correct sequence
3. Verify metrics collected for each agent invocation
4. Verify workflow completes successfully

### Performance Testing
1. Compare command execution time before/after agent refactoring
2. Measure agent invocation overhead
3. Verify agent specialization improves focus (subjective)

## Documentation Requirements

### Agent Documentation
Each agent includes:
- Purpose and capabilities
- Allowed tools explanation
- Standards compliance instructions
- Example usage patterns

### Command Documentation
Update each refactored command with:
- "Agent Usage" section
- List of agents used
- When each agent is invoked
- Example agent invocations

### Integration Guide
Create `.claude/docs/agent-integration-guide.md`:
- Overview of agent system
- How to use agents in commands
- Agent selection criteria
- Troubleshooting guide
- How to add new agents

### Hook Documentation
Create `.claude/docs/hook-guide.md`:
- Overview of hook system
- Available hook types
- Necessary hooks vs optional hooks
- How to add new hooks
- Debugging hook failures

## Dependencies

### System Dependencies
- **Bash**: For hook scripts (already available)
- **jq** (optional): For metrics JSON parsing
- **grep, sed, awk**: For hook scripts (already available)

### Infrastructure Dependencies
- **`.claude/data/metrics/` directory**: Created in Phase 3, used by post-command-metrics hook
- **`.claude/state/` directory**: From plan 013, used by session-start-restore hook (optional, hook handles missing directory gracefully)

### Claude Code Version
- **Claude Code v2.0.1+**: Required for `.claude/agents/` and `.claude/hooks/` support

## Risk Assessment and Mitigation

### Risk 1: Agent Invocation Failure
**Impact**: High (command fails if agent doesn't work)
**Likelihood**: Medium
**Mitigation**:
- Always provide fallback to `general-purpose` agent
- Test agent invocations thoroughly
- Document agent capabilities clearly
- Graceful degradation in commands

### Risk 2: Hook Execution Failure
**Impact**: Medium (hook failure could break commands)
**Likelihood**: Low
**Mitigation**:
- All hooks exit 0 (non-blocking)
- Extensive error handling in hooks
- Test hooks independently
- Document hook dependencies

### Risk 3: Agent Tool Restrictions Too Limiting
**Impact**: Medium (agent can't complete task)
**Likelihood**: Medium
**Mitigation**:
- Start with broader tool access
- Iterate based on actual usage
- Keep `general-purpose` as fallback
- Monitor agent failures

### Risk 4: Metrics Collection Overhead
**Impact**: Low (slight performance impact)
**Likelihood**: Low
**Mitigation**:
- Keep metrics collection minimal (JSONL append)
- Async hook execution (if supported)
- Monitor metrics file size
- Implement rotation (plan 013)

### Risk 5: Command Refactoring Breaks Existing Behavior
**Impact**: High (commands don't work as expected)
**Likelihood**: Medium
**Mitigation**:
- Test each refactored command thoroughly
- Incremental refactoring (phase by phase)
- Git commits after each command refactoring
- Rollback plan if issues found

## Rollout Plan

### Phase 1: Foundation (Day 1)
- Create agents directory
- Implement 4 core agents
- Test agent file structure

### Phase 2: Specialized Agents (Day 1-2)
- Implement remaining 4 agents
- Validate all agent definitions

### Phase 3: Necessary Hooks (Day 2)
- Create hooks directory
- Implement 2 necessary hooks
- Test hook execution
- Configure hooks in settings

### Phase 4: Primary Command Refactoring (Day 3-4)
- Refactor `/orchestrate` (most complex)
- Refactor `/implement`, `/debug`, `/plan`, `/document`
- Test each command with agents

### Phase 5: Remaining Commands (Day 5)
- Refactor `/refactor`, `/test`, `/test-all`
- Review other commands
- Update documentation
- End-to-end testing

### Total Estimated Time: 5 days (20-24 hours)

## Success Metrics

After implementation, measure:
- **Agent Usage**: % of Task tool invocations using specialized agents (target: >80%)
- **Command Performance**: Average command execution time (should be comparable or faster)
- **Metrics Collection**: % of commands with metrics collected (target: 100%)
- **Agent Success Rate**: % of agent invocations that complete successfully (target: >95%)
- **Code Quality**: Standards compliance rate (measured by code-reviewer, target: >90%)

## Notes

### Design Decisions

**Why only 2 hooks?**
- Focus on agent integration first
- Metrics collection is essential for observability (supports plan 013)
- Session restore improves UX but doesn't interfere with workflow
- More hooks can be added incrementally based on actual needs

**Why refactor commands instead of creating new ones?**
- Preserve existing command interfaces
- Users don't need to learn new commands
- Incremental improvement (backward compatible)
- Can add new agent-specific commands later if needed

**Why start with all 8 agents?**
- Agents are lightweight (just markdown files)
- Creating all agents establishes the agent taxonomy
- Commands can choose which agents to use
- Unused agents don't cause any overhead

### Future Enhancements (Out of Scope)

These will be added later based on report 015:
- **pre-write-standards-check** hook (quality enforcement)
- **post-write-format** hook (auto-formatting)
- **pre-commit-validate** hook (quality gates)
- **user-prompt-context** hook (workflow guidance)
- **session-end-backup** hook (state preservation)
- **post-implement-test** hook (automatic testing)

### Compatibility

This implementation:
- ✅ Maintains backward compatibility (commands work without agents)
- ✅ Graceful degradation (fallback to general-purpose)
- ✅ Non-breaking (hooks are non-blocking)
- ✅ Incremental (agents can be adopted gradually)

---

*This plan implements foundational agent system from report 015*
*Estimated completion: 5 days*
*Follow-up: Add optional hooks based on usage patterns*
