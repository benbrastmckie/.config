# /plan Command - Complete Guide

**Executable**: `.claude/commands/plan.md`

**Quick Start**: Run `/plan "<feature-description>"` - creates research reports and implementation plan.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)
6. [See Also](#see-also)

---

## Overview

### Purpose

The `/plan` command provides a research-and-plan workflow that creates comprehensive research reports and then generates a new implementation plan based on those findings. It bridges investigation and action by producing both understanding (research) and actionable steps (plan).

### When to Use

- **Feature planning with research**: When you need to research before planning implementation
- **Informed decision-making**: Creating plans based on investigation findings
- **New feature development**: Starting with research to understand context, then planning
- **Architecture decisions**: Researching options before committing to implementation approach

### When NOT to Use

- **Research-only tasks**: Use `/research` if you don't need a plan
- **Existing plan revision**: Use `/revise` to update existing plans
- **Debugging**: Use `/debug` for debug-focused workflows
- **Direct implementation**: Use `/build` if you already have a plan

---

## Architecture

### Design Principles

1. **Two-Phase Workflow**: Research → Plan (no implementation)
2. **Terminal at Plan**: Workflow ends after plan creation
3. **Research-Informed Planning**: Plan-architect uses research reports for context
4. **Complexity-Aware Research**: Adjustable research depth (default: 3 for planning workflows)
5. **New Plan Creation**: Creates new plans (not revisions)

### Patterns Used

- **State-Based Orchestration**: (state-based-orchestration-overview.md) Two-state workflow
- **Behavioral Injection**: (behavioral-injection.md) Agent behavior separated from orchestration
- **Fail-Fast Verification**: (Standard 0) File and size verification
- **Topic-Based Structure**: (directory-protocols.md) Numbered topic directories with plans/ and reports/

### Workflow States

```
┌──────────────┐
│   RESEARCH   │ ← Feature investigation
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     PLAN     │ ← Implementation plan creation (terminal state)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   COMPLETE   │
└──────────────┘
```

### Integration Points

- **State Machine**: workflow-state-machine.sh (>=2.0.0) for state management
- **Research**: research-specialist agent for investigation reports
- **Planning**: plan-architect agent for implementation plan creation
- **Supervision**: research-sub-supervisor agent for complexity ≥4
- **Output**: specs/{NNN_topic}/reports/ and specs/{NNN_topic}/plans/

### Data Flow

1. **Input**: Feature description + optional complexity (default: 3)
2. **State Initialization**: sm_init() with workflow_type="research-and-plan"
3. **Research Phase**: research-specialist creates investigation reports
4. **Planning Phase**: plan-architect creates implementation plan from research
5. **Output**: Research reports + implementation plan ready for /build or /implement

---

## Usage Examples

### Example 1: Basic Feature Planning

```bash
/plan"implement user authentication with JWT tokens"
```

**Expected Output**:
```
=== Research-and-Plan Workflow ===
Feature: implement user authentication with JWT tokens
Research Complexity: 3

✓ State machine initialized

=== Phase 1: Research ===

EXECUTE NOW: USE the Task tool to invoke research-specialist agent

Workflow-Specific Context:
- Research Complexity: 3
- Feature Description: implement user authentication with JWT tokens
- Output Directory: /home/user/.config/.claude/specs/752_implement_user_authentication/reports
- Workflow Type: research-and-plan

✓ Research phase complete (6 reports created)

=== Phase 2: Planning ===

EXECUTE NOW: USE the Task tool to invoke plan-architect agent

Workflow-Specific Context:
- Feature Description: implement user authentication with JWT tokens
- Output Path: .claude/specs/752_implement_user_authentication/plans/001_implement_user_authentication_plan.md
- Research Reports: [".claude/specs/752_implement_user_authentication/reports/001_topic1.md", ...]
- Workflow Type: research-and-plan
- Operation Mode: new plan creation

✓ Planning phase complete (plan: 001_implement_user_authentication_plan.md)

=== Research-and-Plan Complete ===

Workflow Type: research-and-plan
Specs Directory: .claude/specs/752_implement_user_authentication
Research Reports: 6 reports in .claude/specs/752_implement_user_authentication/reports
Implementation Plan: .claude/specs/752_implement_user_authentication/plans/001_implement_user_authentication_plan.md

Next Steps:
- Review plan: cat .claude/specs/752_implement_user_authentication/plans/001_implement_user_authentication_plan.md
- Implement plan: /implement .claude/specs/752_implement_user_authentication/plans/001_implement_user_authentication_plan.md
- Use /build to execute implementation phases
```

**Explanation**:
Researches JWT authentication approaches, then creates detailed implementation plan based on findings. Plan includes phases, tasks, success criteria, and technical design informed by research.

### Example 2: Complex Feature with Higher Complexity

```bash
/plan"implement real-time collaborative editing --complexity 4"
```

**Expected Output**:
```
=== Research-and-Plan Workflow ===
Feature: implement real-time collaborative editing
Research Complexity: 4

✓ State machine initialized

=== Phase 1: Research ===

NOTE: Hierarchical supervision mode (complexity ≥4)
Invoke research-sub-supervisor agent to coordinate multiple sub-agents

✓ Research phase complete (11 reports created)

=== Phase 2: Planning ===
...
✓ Planning phase complete

=== Research-and-Plan Complete ===
```

**Explanation**:
Higher complexity (4) triggers hierarchical supervision for comprehensive research. Creates extensive research reports and detailed implementation plan for complex feature.

### Example 3: Architecture Decision with Research

```bash
/plan"migrate from REST API to GraphQL"
```

**Expected Output**:
```
=== Research-and-Plan Workflow ===
Feature: migrate from REST API to GraphQL
Research Complexity: 3

✓ State machine initialized

=== Phase 1: Research ===
✓ Research phase complete (7 reports created)

=== Phase 2: Planning ===
✓ Planning phase complete (plan: 001_migrate_from_rest_api_to_plan.md)

=== Research-and-Plan Complete ===

Specs Directory: .claude/specs/753_migrate_from_rest_api_to
Research Reports: 7 reports
Implementation Plan: .claude/specs/753_migrate_from_rest_api_to/plans/001_migrate_from_rest_api_to_plan.md
```

**Explanation**:
Researches GraphQL migration approaches, patterns, and gotchas. Creates phased migration plan based on research findings, including risk mitigation and rollback strategies.

---

## Advanced Topics

### Performance Considerations

**Default Complexity**:
- Research-and-plan workflows default to complexity 3 (higher than research-only's default of 2)
- Rationale: Planning requires deeper understanding of implementation details

**Complexity Selection Guide**:
- **Complexity 2**: Simple, well-understood features with clear implementation
- **Complexity 3** (default): Most features requiring moderate investigation
- **Complexity 4**: Complex features, architecture changes, or unfamiliar domains

**Phase Duration**:
- Research phase (complexity 3): ~20-40 minutes
- Planning phase: ~10-20 minutes
- Total: ~30-60 minutes for typical feature

### Customization

**Complexity Override**:
```bash
# Lower for well-understood features
/plan"add new API endpoint --complexity 2"

# Higher for complex architectures
/plan"implement event sourcing --complexity 4"
```

**Feature Description Best Practices**:
- Include scope: "implement user authentication" vs "add login button"
- Specify technology: "using JWT tokens" vs generic "authentication"
- Provide context: "for multi-tenant SaaS application"

### Integration with Other Workflows

**Research-Plan → Build Chain**:
```bash
/plan"implement caching layer"
# Review plan
/build  # Auto-detects and executes plan
```

**Research-Plan → Review → Build**:
```bash
/plan"add rate limiting"
# Manual review of plan
# Adjust plan if needed with /revise
/build
```

**Iterative Research-Plan**:
```bash
/research "caching strategies"  # Initial investigation
/plan"implement Redis caching"  # Focused plan based on findings
```

**Split Workflow Alternative**:
```bash
# Alternative to /plan: do research and planning separately
/research "authentication approaches"
# Review research
/plan "implement OAuth2 authentication"
```

### Standards Integration

The `/plan` command automatically extracts and injects project standards from CLAUDE.md into the plan-architect agent prompt. This ensures generated plans align with established conventions or explicitly propose standards changes.

**How It Works**:
1. Command extracts 6 planning-relevant sections from CLAUDE.md (code_standards, testing_protocols, documentation_policy, error_logging, clean_break_development, directory_organization)
2. Standards formatted with markdown headers and injected into agent prompt
3. Plan-architect references standards in Technical Design, Testing Strategy, Documentation Requirements
4. If approach conflicts with standards, agent creates Phase 0 (standards revision)
5. Command detects Phase 0 and displays warning to user

**Standards-Compliant Plan** (typical case):
```bash
$ /plan "Add user authentication with JWT"

Extracted 6 standards sections for plan-architect
Plan will be created at: .claude/specs/042_auth/plans/001-auth-plan.md

[plan-architect generates plan aligned with standards]

Plan verified: 15234 bytes
✓ Plan created successfully
```

**Divergent Plan** (Phase 0 required):
```bash
$ /plan "Refactor to TypeScript configuration system"

Extracted 6 standards sections for plan-architect
Plan will be created at: .claude/specs/043_typescript/plans/001-typescript-plan.md

[plan-architect detects divergence from Bash/Lua standards]

Plan verified: 18456 bytes

⚠️  STANDARDS DIVERGENCE DETECTED
This plan proposes changes to project standards (see Phase 0).
Review carefully before proceeding with implementation.

Affected Sections: code_standards, testing_protocols
Justification: Current Bash-only standards prevent TypeScript adoption for improved type safety

✓ Plan created with Phase 0 (standards revision required)
```

**What is Phase 0?**

Phase 0 is a special pre-implementation phase that documents and justifies proposed changes to project-wide standards. It includes:
- Divergence summary (current standard vs proposed change)
- Detailed justification (limitations, benefits, migration path, risks)
- Tasks to update CLAUDE.md and affected command/agent files
- User warning about standards changes requiring review

**When to Approve Phase 0**:
- Justification addresses real limitations of current standards
- Benefits outweigh migration costs
- Migration path is feasible and documented
- Risks are understood and acceptable

**When to Reject Phase 0**:
- Changes are unnecessary or overly ambitious
- Migration would break existing workflows
- Alternative approaches exist within current standards
- Timing is poor (mid-project, insufficient resources)

If you reject Phase 0, use `/revise` to modify the plan to work within existing standards.

**Graceful Degradation**:

If CLAUDE.md not found or extraction fails, command continues without standards (backward compatibility):
```bash
WARNING: CLAUDE.md not found, standards extraction skipped
No standards extracted (graceful degradation)
```

For more details on the standards integration pattern, see [Standards Integration Pattern](.claude/docs/guides/patterns/standards-integration.md).

---

## Troubleshooting

### Common Issues

#### Issue 1: Plan File Too Small

**Symptoms**:
- Error: "Plan file too small (XXX bytes)"
- Plan created but lacks detail

**Cause**:
Insufficient research reports or plan-architect encountered errors.

**Solution**:
```bash
# Verify research reports exist and have content
ls -lh .claude/specs/*/reports/

# Re-run with higher complexity for better research
/plan"feature description --complexity 4"

# Check if feature description is specific enough
# Bad: "add feature"
# Good: "implement user authentication with JWT and refresh tokens"
```

#### Issue 2: Research Phase Failed

**Symptoms**:
- Error: "Research phase failed to create report files"
- No reports directory or empty reports

**Cause**:
Research-specialist agent failed or feature description too vague.

**Solution**:
```bash
# Make feature description more specific
/plan"implement JWT authentication with bcrypt password hashing for Express.js API"

# Check research-specialist agent file
cat .claude/agents/research-specialist.md
```

#### Issue 3: Planning Phase Failed

**Symptoms**:
- Error: "Planning phase failed to create plan file"
- Plan file missing or empty

**Cause**:
Plan-architect didn't receive research reports or encountered errors.

**Solution**:
```bash
# Verify research reports exist
find .claude/specs -path "*/reports/*.md"

# Check if reports have sufficient content (>100 bytes)
find .claude/specs -path "*/reports/*.md" -size -100c

# Manually review reports to ensure quality
cat .claude/specs/*/reports/*.md
```

#### Issue 4: Feature Description Too Vague

**Symptoms**:
- Generic research reports
- Shallow implementation plan
- Missing technical details

**Cause**:
Feature description lacks specificity or context.

**Solution**:
Improve feature description:
- **Add technologies**: "using React hooks" vs just "React"
- **Specify scope**: "for admin dashboard" vs generic feature
- **Include constraints**: "must support offline mode"
- **Provide context**: "migrating from class components"

Example:
```bash
# Before (too vague)
/plan"add notifications"

# After (specific)
/plan"implement real-time push notifications using WebSocket for user activity alerts in multi-tenant application"
```

### Debug Mode

Enable verbose output:

```bash
# Bash debugging
set -x
/plan"feature description"
set +x
```

**Artifact Verification**:
```bash
# Verify research reports exist
find .claude/specs -path "*/reports/*.md" | head -20

# Check report sizes
du -h .claude/specs/*/reports/*.md

# Verify plan file exists and has content
find .claude/specs -path "*/plans/*.md"
ls -lh .claude/specs/*/plans/*.md

# Check plan size (should be >500 bytes)
find .claude/specs -path "*/plans/*.md" -size -500c
```

**State Inspection**:
```bash
# Check workflow state
cat ~/.claude/data/state/workflow_state.json | jq .

# Verify workflow type
cat ~/.claude/data/state/workflow_state.json | jq '.workflow_type'
# Should output: "research-and-plan"

# Check completed states
cat ~/.claude/data/state/workflow_state.json | jq '.completed_states'
```

### Getting Help

- Check [Command Reference](../reference/standards/command-reference.md) for quick syntax
- Review [Plan-Architect Agent](../../agents/plan-architect.md) for planning patterns
- See related commands: `/research`, `/revise`, `/plan`
- Review [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md) for plan structure

---

## See Also

- [Research-Specialist Agent](../../agents/research-specialist.md)
- [Plan-Architect Agent](../../agents/plan-architect.md)
- [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md)
- [Directory Protocols](../concepts/directory-protocols.md)
- [Command Reference](../reference/standards/command-reference.md)
- Related Commands: `/research`, `/revise`, `/build`, `/implement`
