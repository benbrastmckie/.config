# /research Command - Complete Guide

**Executable**: `.claude/commands/research.md`

**Quick Start**: Run `/research "<topic>"` - creates research reports without planning or implementation.

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

The `/research` command provides a research-only workflow that creates comprehensive research reports without planning or implementation phases. It's ideal for investigation, analysis, and understanding codebases or technologies before committing to implementation.

### When to Use

- **Codebase exploration**: Understanding existing systems, patterns, or architectures
- **Technology investigation**: Researching libraries, frameworks, or approaches
- **Feasibility analysis**: Investigating whether an approach is viable
- **Knowledge gathering**: Building understanding before planning implementation

### When NOT to Use

- **Creating implementation plans**: Use `/plan` for research + planning
- **Debugging issues**: Use `/debug` for debug-focused workflows
- **Full implementation**: Use `/coordinate` for research + plan + implement
- **Modifying plans**: Use `/revise` for plan revision with new research

---

## Architecture

### Design Principles

1. **Research-Only Focus**: Creates only research artifacts, no plans or implementation
2. **Complexity-Aware**: Adjustable research depth (1-4) based on investigation needs
3. **Terminal at Research**: Workflow ends after research phase completes
4. **Topic-Based Organization**: Creates numbered topic directories in specs/
5. **Hierarchical Supervision**: Automatically uses sub-supervisor for complexity ≥4

### Patterns Used

- **State-Based Orchestration**: (state-based-orchestration-overview.md) Single-state workflow
- **Hard Barrier Subagent Delegation**: (hard-barrier-subagent-delegation.md) Mandatory subagent invocation with validation
- **Behavioral Injection**: (behavioral-injection.md) Agent behavior separated from orchestration
- **Fail-Fast Verification**: (Standard 0) File-level verification with minimum size checks
- **Topic-Based Structure**: (directory-protocols.md) Numbered topic directories

### Subagent Delegation Architecture

The `/research` command uses the **Hard Barrier Pattern** to enforce mandatory delegation to the research-specialist subagent:

```
Block 1c: Topic Path Initialization
    │
    ▼
Block 1d: Report Path Pre-Calculation (bash)
    │   • Calculate REPORT_PATH = ${RESEARCH_DIR}/001-${REPORT_SLUG}.md
    │   • Persist REPORT_PATH to workflow state
    ▼
Block 1d-exec: Research Specialist Invocation (Task)
    │   • Pass REPORT_PATH as explicit contract
    │   • Agent receives absolute path requirement
    ▼
Block 1e: Agent Output Validation (bash) ← HARD BARRIER
    │   • Verify REPORT_PATH file exists (exit 1 if missing)
    │   • Validate report has minimum size
    │   • Validate report contains required sections
    ▼
Block 2: Verification and Completion (defensive checks)
```

**Why This Pattern?**:
1. **REPORT_PATH Pre-Calculation**: The orchestrator calculates the exact output path before invoking the subagent
2. **Explicit Contract**: The Task prompt passes `REPORT_PATH` as a mandatory requirement
3. **Hard Barrier**: Block 1e validates the exact pre-calculated path exists (not a search/find operation)
4. **Fail-Fast**: If the report is missing, the workflow halts with error logging

**Without This Pattern** (the problem this solves):
- The primary agent bypasses Task invocation and performs research directly
- This wastes context (40-60% more tokens used)
- Research logic is not reusable across workflows
- Subagent specialization is lost

See [Hard Barrier Subagent Delegation Pattern](../../concepts/patterns/hard-barrier-subagent-delegation.md) for full documentation.

### Workflow States

```
┌──────────────┐
│   RESEARCH   │ ← Single phase (terminal state)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   COMPLETE   │
└──────────────┘
```

### Integration Points

- **State Machine**: workflow-state-machine.sh (>=2.0.0) for state management
- **Research**: research-specialist agent for report creation
- **Supervision**: research-sub-supervisor agent for complexity ≥4
- **Output**: `.claude/specs/{NNN_topic}/reports/` directory

### Data Flow

1. **Input**: Workflow description + optional complexity (default: 2)
2. **State Initialization**: sm_init() with workflow_type="research-only"
3. **Research Phase**: research-specialist creates investigation reports
4. **Output**: Research reports in specs/{topic}/reports/

---

## Usage Examples

### Example 1: Basic Research

```bash
/research"authentication patterns in codebase"
```

**Expected Output**:
```
=== Research-Only Workflow ===
Description: authentication patterns in codebase
Complexity: 2

✓ State machine initialized

=== Phase 1: Research ===

EXECUTE NOW: USE the Task tool to invoke research-specialist agent

Workflow-Specific Context:
- Research Complexity: 2
- Workflow Description: authentication patterns in codebase
- Output Directory: /home/user/.config/.claude/specs/750_authentication_patterns/reports
- Workflow Type: research-only

✓ Research phase complete (4 reports created)

=== Research Complete ===

Workflow Type: research-only
Reports Directory: .claude/specs/750_authentication_patterns/reports
Report Count: 4

Next Steps:
- Review reports in: .claude/specs/750_authentication_patterns/reports
- Use /plan to create implementation plan from research
- Use /coordinate for full workflow (research + plan + implement)
```

**Explanation**:
Creates comprehensive research reports about authentication patterns. Reports saved in numbered topic directory for easy reference.

### Example 2: Higher Complexity Research

```bash
/research"React performance optimization techniques --complexity 3"
```

**Expected Output**:
```
=== Research-Only Workflow ===
Description: React performance optimization techniques
Complexity: 3

✓ State machine initialized

=== Phase 1: Research ===

EXECUTE NOW: USE the Task tool to invoke research-specialist agent

✓ Research phase complete (7 reports created)

=== Research Complete ===

Workflow Type: research-only
Reports Directory: .claude/specs/751_react_performance_optimization/reports
Report Count: 7
```

**Explanation**:
Higher complexity (3) produces more reports with deeper analysis. Useful for complex topics requiring comprehensive investigation.

### Example 3: Hierarchical Supervision Mode

```bash
/research"microservices architecture migration strategy --complexity 4"
```

**Expected Output**:
```
=== Research-Only Workflow ===
Description: microservices architecture migration strategy
Complexity: 4

✓ State machine initialized

=== Phase 1: Research ===

NOTE: Hierarchical supervision mode (complexity ≥4)
Invoke research-sub-supervisor agent to coordinate multiple sub-agents
Supervisor Agent: /home/user/.config/.claude/agents/research-sub-supervisor.md

✓ Research phase complete (12 reports created)

=== Research Complete ===
```

**Explanation**:
Complexity 4 triggers hierarchical supervision with research-sub-supervisor coordinating multiple specialized research agents for comprehensive coverage.

---

## Advanced Topics

### Performance Considerations

**Complexity Levels**:
- **Level 1**: Quick scan, 1-2 reports, high-level overview
- **Level 2** (default): Standard research, 3-5 reports, moderate depth
- **Level 3**: Deep research, 6-8 reports, comprehensive analysis
- **Level 4**: Exhaustive research, 9+ reports, hierarchical investigation

**Research Duration**:
- Complexity 1: ~5-10 minutes
- Complexity 2: ~10-20 minutes
- Complexity 3: ~20-40 minutes
- Complexity 4: ~40-90 minutes (hierarchical)

**Report Organization**:
- Sequential numbering: 001_topic1.md, 002_topic2.md, etc.
- Topic-based directory: specs/{NNN_description}/reports/
- Minimum file size: 100 bytes (enforced)

### Customization

**Complexity Specification**:
```bash
# Embedded in description (recommended)
/research"topic --complexity 3"

# Complexity defaults by research type:
# - Quick exploration: Use complexity 1
# - Standard investigation: Use default (2)
# - Comprehensive analysis: Use complexity 3
# - Exhaustive research: Use complexity 4
```

**Description Best Practices**:
- Be specific about scope: "authentication patterns in src/auth/" vs "authentication"
- Include context: "for migrating to OAuth2" vs just "OAuth2"
- Specify focus areas: "performance optimization for large datasets"

### Integration with Other Workflows

**Research → Plan Chain**:
```bash
/research"user authentication approaches"
# Review reports
/plan "implement JWT authentication"  # Create plan based on research
```

**Research → Research-Plan Chain**:
```bash
# Alternative: Combined workflow
/plan "implement JWT authentication"  # Does research + planning in one command
```

**Iterative Research**:
```bash
/research"API design patterns"           # Initial investigation
# Review findings, identify gaps
/research"REST vs GraphQL comparison"    # Deeper dive on specific aspect
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Hard Barrier Failed - Report Not Created

**Symptoms**:
- Error: "HARD BARRIER FAILED - Report file not found at: [path]"
- Block 1e validation exits with agent_error

**Cause**:
Research-specialist subagent did not create the report at the pre-calculated `REPORT_PATH`. This usually means:
1. Task invocation in Block 1d-exec was not executed
2. Subagent encountered an error during file creation
3. Subagent created the report at a different path

**Solution**:
```bash
# Check recent error logs
/errors --command /research --since 1h

# Verify the expected report path was calculated
grep "REPORT_PATH" ~/.claude/tmp/workflow_research_*.sh

# Check if any report was created (different path)
find .claude/specs -name "*.md" -mmin -5

# Re-run with more specific description
/research"specific topic description"
```

**Note**: This error is by design - it prevents the orchestrator from bypassing subagent delegation.

#### Issue 2: No Reports Created (Block 2 Defensive Check)

**Symptoms**:
- Error: "Research phase failed to create report files"
- Research directory exists but empty

**Cause**:
Research-specialist agent failed or workflow description too vague.

**Solution**:
```bash
# Make description more specific
/research"JWT authentication implementation in src/auth module"

# Increase complexity for better coverage
/research"authentication patterns --complexity 3"

# Check if research directory was created
ls .claude/specs/
```

#### Issue 3: Reports Too Small

**Symptoms**:
- Error: "Research report(s) too small (< 100 bytes)"
- Reports created but minimal content

**Cause**:
Research-specialist encountered errors or found insufficient information.

**Solution**:
```bash
# Verify topic is researchable (not too narrow)
# Bad: "the foo function" (too specific)
# Good: "foo module architecture" (appropriate scope)

# Increase complexity for deeper investigation
/research"topic --complexity 3"
```

#### Issue 4: State Machine Initialization Failed

**Symptoms**:
- Error: "State machine initialization failed"
- Diagnostic shows library incompatibility

**Cause**:
workflow-state-machine.sh version <2.0.0.

**Solution**:
```bash
# Check version
grep VERSION= .claude/lib/workflow/workflow-state-machine.sh

# Ensure version >=2.0.0
```

#### Issue 5: Workflow Description Invalid

**Symptoms**:
- Error: "Workflow description required"
- Command exits immediately

**Cause**:
Empty or missing description argument.

**Solution**:
```bash
# Provide description in quotes
/research"topic description here"

# Not:
/research

# Examples of good descriptions:
/research"authentication patterns in Express.js applications"
/research"React hooks best practices for state management"
/research"database indexing strategies for PostgreSQL"
```

### Debug Mode

Enable verbose output:

```bash
# Bash debugging
set -x
/research"topic"
set +x
```

**Report Verification**:
```bash
# Find all research reports
find .claude/specs -path "*/reports/*.md"

# Check report sizes
find .claude/specs -path "*/reports/*.md" -exec du -h {} \;

# View report count for specific topic
ls .claude/specs/750_topic_name/reports/ | wc -l

# Verify minimum size (>100 bytes)
find .claude/specs -path "*/reports/*.md" -size -100c
```

**State Inspection**:
```bash
# Check workflow state
cat ~/.claude/data/state/workflow_state.json | jq .

# Verify workflow type
cat ~/.claude/data/state/workflow_state.json | jq '.workflow_type'
# Should output: "research-only"
```

### Getting Help

- Check [Command Reference](../reference/standards/command-reference.md) for quick syntax
- Review [Research-Specialist Agent](../../agents/research-specialist.md) for research patterns
- See related commands: `/plan`, `/debug`, `/coordinate`
- Review [Directory Protocols](../concepts/directory-protocols.md) for specs organization

---

## See Also

- [Research-Specialist Agent](../../agents/research-specialist.md)
- [Research-Sub-Supervisor Agent](../../agents/research-sub-supervisor.md)
- [Directory Protocols](../concepts/directory-protocols.md)
- [State-Based Orchestration Overview](../architecture/state-based-orchestration-overview.md)
- [Command Reference](../reference/standards/command-reference.md)
- Related Commands: `/plan`, `/revise`, `/debug`, `/coordinate`
