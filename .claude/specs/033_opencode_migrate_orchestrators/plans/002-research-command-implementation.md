# Implementation Plan: /research Command Port

## Metadata
- **Feature**: Port `/research` command to OpenCode
- **Design Reference**: `commands/research-design.md`
- **Architecture**: Coordinator-Worker (Sequential)
- **Status**: Planning

## Overview
This plan details the steps to implement the `/research` command in OpenCode. The implementation follows the "Coordinator-Worker" pattern where a primary coordinator agent manages project structure and delegation, while specialist agents perform the actual research tasks sequentially.

## Directory Structure
Target locations for new files:
- Command definition: `.opencode/command/research.md`
- Agent definitions: `.opencode/agent/research-coordinator.md`, `.opencode/agent/research-specialist.md`
- Documentation:
    - `.opencode/docs/commands/research.md`
    - `.opencode/docs/subagents/research-coordinator.md`
    - `.opencode/docs/subagents/research-specialist.md`
- State/Locking: `.opencode/specs/next_project_id`

## Phases

### Phase 1: Infrastructure & State Setup
Ensure the necessary directory structure and state files exist to support the coordinator's locking mechanism.

1.  **Create Directories**:
    -   Ensure `.opencode/command/` exists.
    -   Ensure `.opencode/agent/` exists.
    -   Ensure `.opencode/docs/commands/` exists.
    -   Ensure `.opencode/docs/subagents/` exists.
    -   Ensure `.opencode/specs/` exists.

2.  **Initialize Lock File**:
    -   Create `.opencode/specs/next_project_id` with initial value `001` if it does not exist.

### Phase 2: Agent Implementation
Create the agent definitions that define the behavior of the Coordinator and Specialist.

3.  **Create Research Specialist Agent** (`.opencode/agent/research-specialist.md`):
    -   **Frontmatter Config**:
        -   `description`: "Conducts deep research on specific topics and produces structured reports."
        -   `mode`: `subagent`
        -   `model`: `google/gemini-3-deep-think` (Reasoning-heavy)
        -   `maxSteps`: 20
        -   `permissions`:
            -   `bash`: `deny` (Safety restriction)
            -   `edit`: `deny` (Safety restriction)
            -   `websearch`: `allow`
            -   `webfetch`: `allow`
    -   **Prompt Logic**:
        -   **Role**: Specialized researcher.
        -   **Input**: A file path to a report definition.
        -   **Action**: Read prompt from file, execute research (web/codebase), write findings to the report file (using `write`).
        -   **Output**: Append summary to `OVERVIEW.md`.

4.  **Create Research Coordinator Agent** (`.opencode/agent/research-coordinator.md`):
    -   **Frontmatter Config**:
        -   `description`: "Coordinates research workflows, manages project structure, and delegates tasks."
        -   `mode`: `subagent`
        -   `model`: `google/gemini-2.5-flash-lite` (Fast/Cost-effective)
        -   `permissions`:
            -   `bash`:
                -   `mkdir -p .opencode/specs/*`: `allow`
                -   `cat .opencode/specs/*`: `allow`
                -   `echo * > .opencode/specs/*`: `allow`
                -   `ls .opencode/specs/*`: `allow`
                -   `*`: `deny`
    -   **Prompt Logic**:
        -   Step 1: Read/Update `next_project_id` and create project directory `NNN_slug`.
        -   Step 2: Create `OVERVIEW.md` with original prompt.
        -   Step 3: Decompose prompt into 1-5 sub-report files.
        -   Step 4: Sequentially invoke `@research-specialist` for each sub-report.
        -   Step 5: Review final `OVERVIEW.md` and report to user.

### Phase 3: Command Implementation
Create the command interface that users will interact with.

5.  **Create Command Definition** (`.opencode/command/research.md`):
    -   **Frontmatter Config**:
        -   `description`: "Research a topic and generate a structured report."
        -   `agent`: `research-coordinator`
        -   `subtask`: `true` (Isolate context)
    -   **Template**: Injects `$ARGUMENTS` (topic) and delegates control to `research-coordinator`.

### Phase 4: Documentation
Document the system for users and developers.

6.  **Command Documentation** (`.opencode/docs/commands/research.md`):
    -   Usage instructions (`/research "Topic"`).
    -   Explanation of the folder structure created (`.opencode/specs/NNN_...`).
    -   Workflow description.

7.  **Subagent Documentation**:
    -   `research-coordinator.md`: Explain role, locking logic, and decomposition strategy.
    -   `research-specialist.md`: Explain capability, permissions (no bash), and expected input format.

### Phase 5: Verification
8.  **Safety Test**:
    -   Invoke `research-specialist` manually: `@research-specialist run "ls -la"` -> Should fail/deny.
9.  **Workflow Test**:
    -   Execute `/research "OpenCode Agent Patterns"`.
    -   Verify `.opencode/specs/NNN_opencode_agent_patterns` is created.
    -   Verify `OVERVIEW.md` and sub-reports are generated.
    -   Verify `next_project_id` incremented.

## Execution Order
1. Phase 1 (Infrastructure)
2. Phase 2 (Agents)
3. Phase 3 (Command)
4. Phase 4 (Documentation)
5. Phase 5 (Verification)
