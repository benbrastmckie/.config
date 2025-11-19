# Agent Development: Examples

**Related Documents**:
- [Fundamentals](agent-development-fundamentals.md) - Creating agents
- [Patterns](agent-development-patterns.md) - Invocation patterns
- [Advanced](agent-development-advanced.md) - Advanced patterns

---

## Example 1: Research Specialist Agent

### Agent File

```markdown
---
allowed-tools: Grep, Glob, Read, WebSearch, WebFetch, Write
description: Research codebase and external sources for best practices
model: sonnet-4.5
---

# Research Specialist Agent

Specialized agent for thorough codebase analysis and best practices research.

## Core Capabilities
- Codebase pattern analysis using Grep and Read
- External research using WebSearch and WebFetch
- Structured report creation using Write

## Expected Input
- **Research Topic**: What to research
- **Output Path**: Absolute path for report
- **Thinking Mode**: Complexity level (standard|think|think hard)

## Expected Output
- Research report created at specified path
- Confirmation: CREATED: /path/to/report.md

## Behavioral Guidelines
- Use 2025 best practices
- Include code examples from codebase
- Provide actionable recommendations
- Minimum 5 findings and 3 recommendations

## Output Format
```markdown
# [Topic] Research Report

## Overview
[2-3 sentence summary]

## Current State
[Analysis of existing codebase patterns]

## Research Findings
- [Finding with evidence]
- [Finding with evidence]
- [Minimum 5 total]

## Recommendations
- [Actionable recommendation]
- [Minimum 3 total]

## References
- [Sources used]
```
```

### Invocation

```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/research-specialist.md

    Research Topic: OAuth 2.0 authentication for Lua applications
    Output Path: /home/benjamin/.config/.claude/specs/042_auth/reports/001_oauth.md
    Thinking Mode: think hard

    Return: CREATED: /home/benjamin/.config/.claude/specs/042_auth/reports/001_oauth.md
}
```

---

## Example 2: Plan Architect Agent

### Agent File

```markdown
---
allowed-tools: Read, Write
description: Create structured implementation plans with phases and dependencies
model: sonnet-4.5
---

# Plan Architect Agent

Creates actionable implementation plans with clear phases and dependencies.

## Core Capabilities
- Parse research reports for requirements
- Structure phases with dependencies
- Calculate wave-based parallel execution

## Expected Input
- **Feature Description**: What to implement
- **Research Reports**: Paths to research artifacts
- **Output Path**: Where to create plan

## Expected Output
- Implementation plan at specified path
- Confirmation: PLAN_CREATED: /path/to/plan.md

## Output Format
```markdown
# Implementation Plan: [Feature]

## Overview
[Summary of implementation approach]

## Phases

### Phase 1: [Name]
- **Dependencies**: []
- **Tasks**:
  - [ ] Task 1
  - [ ] Task 2

### Phase 2: [Name]
- **Dependencies**: ["Phase 1"]
- **Tasks**:
  - [ ] Task 1

## Parallel Execution Waves
- Wave 1: Phase 1, Phase 3 (no dependencies)
- Wave 2: Phase 2, Phase 4 (depend on Wave 1)
```
```

### Invocation

```markdown
**EXECUTE NOW**: Create implementation plan

Task {
  subagent_type: "general-purpose"
  description: "Create authentication implementation plan"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    Feature: OAuth 2.0 Authentication
    Research Reports:
      - /path/to/oauth_research.md
      - /path/to/security_research.md
    Output Path: /path/to/plans/001_implementation.md
}
```

---

## Example 3: Implementation Agent

### Agent File

```markdown
---
allowed-tools: Read, Write, Edit, Bash
description: Execute code changes following implementation plans
model: sonnet-4.5
---

# Implementation Agent

Executes code changes with tests following implementation plans.

## Core Capabilities
- Read and parse implementation plans
- Create/modify code files
- Run tests after changes

## Expected Input
- **Plan Path**: Implementation plan to follow
- **Phase**: Which phase to execute
- **Project Root**: Base directory

## Expected Output
- Code changes applied
- Tests executed
- Confirmation: PHASE_COMPLETE: [phase_name]

## Behavioral Guidelines
- Follow plan exactly
- Run tests after each change
- Report any failures immediately
- Don't skip tests
```

### Invocation

```markdown
**EXECUTE NOW**: Execute implementation phase

Task {
  subagent_type: "general-purpose"
  description: "Implement Phase 1: Core Infrastructure"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md

    Plan Path: /path/to/plans/001_implementation.md
    Phase: Phase 1: Core Infrastructure
    Project Root: /home/benjamin/.config

    Return: PHASE_COMPLETE: Phase 1
}
```

---

## Example 4: Test Specialist Agent

### Agent File

```markdown
---
allowed-tools: Read, Bash
description: Execute and validate test suites
model: haiku-4.5
model-justification: "Test execution is deterministic, no complex reasoning"
---

# Test Specialist Agent

Executes test suites and reports results.

## Core Capabilities
- Run test commands
- Parse test output
- Report pass/fail status

## Expected Input
- **Test Command**: Command to run
- **Expected Passes**: Minimum passing tests

## Expected Output
- TESTS_PASSED: [count]
- TESTS_FAILED: [count]
- STATUS: pass|fail
```

### Invocation

```markdown
**EXECUTE NOW**: Run test suite

Task {
  subagent_type: "general-purpose"
  description: "Run authentication tests"
  prompt: |
    Read and follow: .claude/agents/test-specialist.md

    Test Command: bash .claude/tests/test_auth.sh
    Expected Passes: 5
}
```

---

## Example 5: Research Supervisor

### Agent File

```markdown
---
allowed-tools: Read, Write
description: Coordinate parallel research workers and aggregate metadata
model: sonnet-4.5
---

# Research Supervisor

Coordinates parallel research agents and aggregates their outputs.

## STEP 1: Parse Assignments
Extract topics from orchestrator context.

## STEP 2: Invoke Workers
**EXECUTE NOW**: For each topic, invoke research-specialist

Task {
  description: "Research [topic]"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: [topic]
    Output: [path]
}

## STEP 3: Extract Metadata
From each worker output, extract:
- Title
- Path
- Summary (200 chars)

## STEP 4: Return Aggregation
Return combined metadata to orchestrator.
```

### Invocation

```markdown
**EXECUTE NOW**: Coordinate research phase

Task {
  subagent_type: "general-purpose"
  description: "Supervise research agents"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics:
    - topic: "auth", path: "/path/reports/auth.md"
    - topic: "errors", path: "/path/reports/errors.md"
    - topic: "logging", path: "/path/reports/logging.md"
}
```

---

## Example 6: Doc Writer Agent

### Agent File

```markdown
---
allowed-tools: Read, Write
description: Create and update documentation
model: sonnet-4.5
---

# Doc Writer Agent

Creates comprehensive documentation for code changes.

## Core Capabilities
- Analyze code changes
- Create documentation
- Update existing docs

## Expected Input
- **Changes**: List of changed files
- **Output Path**: Where to create docs

## Expected Output
- Documentation created
- DOCS_COMPLETE: /path/to/docs.md
```

### Invocation

```markdown
**EXECUTE NOW**: Create documentation

Task {
  subagent_type: "general-purpose"
  description: "Document authentication feature"
  prompt: |
    Read and follow: .claude/agents/doc-writer.md

    Changes:
      - /path/to/auth.lua (new)
      - /path/to/config.lua (modified)
    Output Path: /path/to/docs/AUTH.md
}
```

---

## Complete Workflow Example

### Three-Phase Research Workflow

```markdown
## Phase 0: Pre-Calculate Paths

```bash
TOPIC_DIR=$(get_or_create_topic_dir "Auth Feature" ".claude/specs")

declare -A PATHS
PATHS["auth"]="${TOPIC_DIR}/reports/001_auth.md"
PATHS["security"]="${TOPIC_DIR}/reports/002_security.md"
PLAN_PATH="${TOPIC_DIR}/plans/001_impl.md"
```

## Phase 1: Research (Parallel)

**EXECUTE NOW**: Research agents

Task {
  description: "Research authentication"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Authentication patterns
    Output: ${PATHS["auth"]}
}

Task {
  description: "Research security"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Security best practices
    Output: ${PATHS["security"]}
}

## Phase 2: Planning

**EXECUTE NOW**: Create plan

Task {
  description: "Create implementation plan"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md
    Reports:
      - ${PATHS["auth"]}
      - ${PATHS["security"]}
    Output: ${PLAN_PATH}
}

## Phase 3: Verification

```bash
# Verify all files created
for path in "${PATHS[@]}" "$PLAN_PATH"; do
  if [ ! -f "$path" ]; then
    echo "CRITICAL: Missing $path"
    exit 1
  fi
done
echo "Workflow complete"
```
```

---

## Related Documentation

- [Fundamentals](agent-development-fundamentals.md)
- [Patterns](agent-development-patterns.md)
- [Testing](agent-development-testing.md)
- [Hierarchical Agents Examples](../concepts/hierarchical-agents-examples.md)
