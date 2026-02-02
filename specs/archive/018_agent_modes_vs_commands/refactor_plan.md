# Refactoring Plan: Consolidate to a Single Research-Mode

## 1. Objective
Refactor the current agent implementation to expose a single, user-facing `research`. This mode will act as a high-level orchestrator, delegating all complex logic to a hierarchy of internal sub-agents (`research-coordinator` and `research-specialist`) to ensure a clean user experience and robust context preservation, following OpenCode's hierarchical agent architecture best practices.

## 2. Analysis of Current State
- **Problem**: Multiple research-related agents (`research-coordinator`, `research-specialist`) are likely registered as primary, user-facing agents, causing confusion and a cluttered interface.
- **Desired State**: Only one primary agent, `research`, should be visible to the user. All other research agents should be internal sub-agents, invoked via the `task` tool.

## 3. Refactoring Plan

### Phase 1: Define the Primary Orchestrator (`research`)
This will be the new, simplified entry point for the user.

- **Action**: Create a new agent definition file: `.opencode/agents/research.md`.
- **Agent Logic**: This agent will be extremely simple. Its only job is to capture the user's request and immediately delegate it to the `research-coordinator`. This follows the "Three-Tier Coordination Pattern" where a command-like agent hands off to a coordinator.

    ```markdown
    # .opencode/agents/research.md

    You are the Research Mode orchestrator. Your sole function is to receive a research request from the user and delegate it to the `research-coordinator` sub-agent for execution.

    1.  **Receive Request**: Accept the user's research topic as input.
    2.  **Delegate Immediately**: Use the `task` tool to invoke the `research-coordinator` agent. Pass the user's full request to the coordinator.
    3.  **Stream Output**: Stream the output from the `research-coordinator` directly back to the user.
    ```

### Phase 2: Solidify the Coordinator Sub-Agent (`research-coordinator`)
This agent will remain the "brains" of the operation, but it will no longer be a primary, user-facing mode.

- **File Location**: `.opencode/agents/research-coordinator.md` (no move necessary).
- **Action**: Verify its logic matches the established workflow:
    1.  Receives a request from `research`.
    2.  Initializes the project directory and `OVERVIEW.md`.
    3.  Decomposes the request into sub-topics.
    4.  Delegates each sub-topic to a `research-specialist` sub-agent in parallel using the `task` tool.
    5.  Waits for all specialists to complete.
    6.  Reads the `OVERVIEW.md` (now populated with specialist summaries).
    7.  Writes the final `## Executive Summary` to the top of `OVERVIEW.md`.
    8.  Returns the final summary and project location to its parent (`research`).

### Phase 3: Verify the Specialist Sub-Agent (`research-specialist`)
This agent is already an internal worker and its logic is correct.

- **File Location**: `.opencode/agents/research-specialist.md` (no move necessary).
- **Action**: No changes are required. Its role remains the same:
    1.  Receive a single, focused research task.
    2.  Perform the research.
    3.  Write the detailed report to its assigned file.
    4.  Append its summary and a link to the shared `OVERVIEW.md`.

### Phase 4: Update the Agent Registry
This is the most critical step to ensure the user interface is clean.

- **File**: `.claude/agents/agent-registry.json`
- **Actions**:
    1.  **Add `research`**: Add a new entry for `research` and define it as a primary, user-facing agent.
    2.  **Re-classify Coordinators/Specialists**: Find the entries for `research-coordinator` and `research-specialist`. Change their `type` from `hierarchical` or `specialized` (if they are listed as primary) to an internal designation. If no such "internal" type exists, the best practice is to simply **remove them from the registry**. Agents can be invoked by the `task` tool without being in the registry; the registry is primarily for user-facing, tab-completable agents. Removing them is the cleanest solution.

## 4. Verification Plan
1.  **Restart OpenCode**: Ensure the new agent registry changes are loaded.
2.  **Check Tab Completion**: Attempt to tab-complete agent modes. Only `research` should appear. `research-coordinator` and `research-specialist` should NOT be available.
3.  **Execute Workflow**: Run a research task using the new `research`.
4.  **Monitor Execution**: Observe the output. It should show the `research` agent starting, then immediately delegating to the coordinator, which then orchestrates the specialists.
5.  **Validate Artifacts**: At the end of the process, verify that:
    - The spec directory and `OVERVIEW.md` are created correctly.
    - All specialist reports are generated.
    - The `OVERVIEW.md` contains an executive summary at the top, followed by links to all the specialist reports.
