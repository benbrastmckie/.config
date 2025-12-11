# Architecture Design: /implement Command

## Purpose
The `/implement` command executes the coding tasks described in a plan. It is the bridge between design and code.

## Opencode Approach
The legacy `/implement` used complex "wave-based" parallel execution with checkpoints. The OpenCode native approach embraces the "interactive session" model. It invokes the `implementation-executor` to work through the plan step-by-step. While it loses background parallelism, it gains interactivity and immediate error correction.

## Workflow
1.  **Invocation**: User runs `/implement "path/to/plan.md"`.
2.  **Context Loading**: Template loads the plan path.
3.  **Agent Delegation**: Activates `implementation-executor`.
4.  **Execution**:
    *   Agent reads the plan.
    *   Agent breaks down the "Implementation" section.
    *   Agent systematically executes changes:
        *   Create/Edit files.
        *   Run linting/verification commands (if specified in plan or standards).
    *   Agent marks steps as complete (mentally or by updating a tracking list if requested).
5.  **Completion**: Agent reports that the implementation tasks are finished.

## Agent Dependency
*   **Agent**: `implementation-executor`
*   **Capabilities**: Coding, Testing, Shell execution, Error analysis.

## Key Simplifications
*   **Sequential Execution**: Replaces complex parallel waves with sequential, monitored execution.
*   **No Checkpoint System**: Relies on the chat session history. If the session crashes, the user starts a new one and says "continue from step X".
*   **Interactive**: User can intervene if the agent gets stuck on a specific step.
