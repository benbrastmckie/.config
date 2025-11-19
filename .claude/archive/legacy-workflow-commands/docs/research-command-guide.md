# /research Command - Complete Guide

**Executable**: `.claude/commands/research.md`

**Quick Start**: Run `/research "topic or question"` to generate a comprehensive research report.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

The `/research` command generates comprehensive research reports using a hierarchical multi-agent pattern. It decomposes complex topics into subtopics, delegates research to specialized agents, and synthesizes findings into a cohesive report.

### Key Features

- Hierarchical multi-agent research pattern
- Automatic topic decomposition (2-4 subtopics)
- Parallel subtopic investigation
- Pre-calculated artifact paths
- Synthesis and overview generation

### When to Use

- Investigating new technologies or patterns
- Analyzing codebase architecture
- Understanding complex systems
- Preparing for implementation planning
- Exploring options and alternatives

### When NOT to Use

- Simple factual questions (ask directly)
- When you need immediate answers
- When the topic is already well-documented locally

---

## Architecture

### Design Principles

- **Orchestrator Pattern**: You coordinate, agents research
- **Parallel Processing**: Subtopics investigated concurrently
- **Pre-calculated Paths**: All artifact locations determined upfront
- **Verification Focus**: Verify outputs, don't read research content

### Patterns Used

- Hierarchical multi-agent pattern
- Topic decomposition pattern
- Parallel task execution
- Artifact path calculation

### Integration Points

- **research-specialist agents**: Perform actual research
- **topic-decomposition.sh**: Breaks down complex topics
- **unified-location-detection.sh**: Calculates artifact paths
- **Plan command**: Uses research outputs for planning

### Data Flow

```
Topic → Decomposition → Path Calculation → Agent Delegation
                                                  ↓
Overview Report ← Synthesis ← Verification ← Subtopic Reports
```

---

## Usage Examples

### Example 1: Basic Research

```bash
/research "authentication best practices for web applications"
```

**Expected Output**:
```
PROGRESS: Analyzing topic complexity...
PROGRESS: Decomposed into 3 subtopics:
  - oauth_jwt_patterns
  - session_management
  - security_headers
PROGRESS: Calculating artifact paths...
PROGRESS: Invoking research-specialist agents...
PROGRESS: Agent 1/3 complete: oauth_jwt_patterns
PROGRESS: Agent 2/3 complete: session_management
PROGRESS: Agent 3/3 complete: security_headers
PROGRESS: Synthesizing overview...
RESEARCH_COMPLETE: 3 reports generated
Overview: specs/042_auth_research/reports/001_overview.md
```

**Explanation**:
The orchestrator decomposes the topic, invokes parallel agents, and synthesizes an overview report.

### Example 2: Codebase Analysis

```bash
/research "analyze the error handling patterns in this project"
```

**Expected Output**:
```
PROGRESS: Analyzing topic...
PROGRESS: Subtopics:
  - error_classification
  - recovery_mechanisms
  - logging_patterns
PROGRESS: Invoking agents with codebase access...
RESEARCH_COMPLETE: 3 reports + overview
```

**Explanation**:
Research agents have Read/Grep/Glob access to analyze the actual codebase.

### Example 3: Technology Comparison

```bash
/research "compare React state management options: Redux vs Zustand vs Jotai"
```

**Expected Output**:
```
PROGRESS: Decomposed into comparison subtopics:
  - redux_analysis
  - zustand_analysis
  - jotai_analysis
  - comparison_matrix
PROGRESS: Agents investigating in parallel...
RESEARCH_COMPLETE: 4 detailed reports
```

**Explanation**:
Comparison topics automatically include a matrix/summary subtopic.

### Example 4: Focused Research

```bash
/research "best practices for testing async JavaScript"
```

**Expected Output**:
```
PROGRESS: Subtopic count: 2 (focused topic)
  - async_testing_patterns
  - mocking_timing_strategies
RESEARCH_COMPLETE: 2 reports + overview
```

**Explanation**:
Simpler topics get fewer subtopics (2 instead of 3-4).

---

## Advanced Topics

### Performance Considerations

- 2-4 subtopics typical (based on complexity)
- Parallel agent execution maximizes efficiency
- Pre-calculated paths avoid redundant computation
- Verification-only approach reduces context usage

### Subtopic Count Determination

Complexity factors:
- Number of distinct concepts
- Breadth vs depth of topic
- Comparison requirements
- Codebase analysis scope

Typical ranges:
- Simple focused topics: 2 subtopics
- Standard topics: 3 subtopics
- Complex/comparison topics: 4 subtopics

### Report Structure

Each subtopic report includes:
- Executive summary
- Key findings
- Code examples (if applicable)
- Recommendations
- References

Overview report includes:
- Synthesized findings
- Cross-subtopic patterns
- Actionable conclusions
- Related plan recommendation

### Phase-Based Tool Usage

**Delegation Phase (Steps 1-3)**:
- Task + Bash tools only
- No Read/Write for research

**Verification Phase (Steps 4-6)**:
- Bash + Read for verification
- Confirm files exist
- Synthesize overview

---

## Troubleshooting

### Common Issues

#### Issue 1: Agent Timeout

**Symptoms**:
- "Agent invocation timed out" error
- Partial reports generated

**Cause**:
Complex subtopic requiring extensive research

**Solution**:
```bash
# Check which agents completed
ls -la .claude/specs/*/reports/

# Re-run for remaining subtopics
# (command will resume incomplete research)
/research "same topic"
```

#### Issue 2: No Subtopics Generated

**Symptoms**:
- "Failed to decompose topic" error
- SUBTOPIC_COUNT = 0

**Cause**:
Topic too vague or decomposition failed

**Solution**:
```bash
# Be more specific with topic
/research "authentication patterns using JWT tokens in Node.js"

# Instead of
/research "security"
```

#### Issue 3: Duplicate Topic Directory

**Symptoms**:
- "Topic directory already exists" warning
- Research appends to existing directory

**Cause**:
Similar topic researched previously

**Solution**:
```bash
# Check existing research
ls -la .claude/specs/*auth*/

# Use distinct topic name or archive old
/research "authentication v2 patterns"
```

#### Issue 4: Missing Overview

**Symptoms**:
- Subtopic reports exist but no overview
- "Synthesis failed" message

**Cause**:
Overview synthesis step failed

**Solution**:
```bash
# Check subtopic reports
ls -la .claude/specs/*/reports/

# Manually synthesize or re-run
/research "same topic"
```

### Debug Mode

Check research orchestration:
```bash
# View research progress
grep "PROGRESS" .claude/tmp/*.txt

# Check agent completion signals
grep "REPORT_CREATED" .claude/tmp/*.txt
```

### Getting Help

- Check [Command Reference](.claude/docs/reference/command-reference.md) for quick syntax
- Review [Hierarchical Agent Architecture](.claude/docs/concepts/hierarchical_agents.md)
- See related commands: `/plan`, `/research-plan`, `/research-report`

---

## See Also

- [Hierarchical Agent Architecture](.claude/docs/concepts/hierarchical_agents.md)
- [Topic Decomposition Library](.claude/lib/topic-decomposition.sh)
- [Command Reference](.claude/docs/reference/command-reference.md)
