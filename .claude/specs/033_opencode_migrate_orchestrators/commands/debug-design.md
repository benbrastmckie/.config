# Architecture Design: /debug Command

## Purpose
The `/debug` command helps identify and fix errors in code or failing tests. It provides a focused context for troubleshooting.

## Opencode Approach
The legacy system relied on parsing structured JSONL error logs. The OpenCode native approach leverages the immediate terminal output and the `implementation-executor`'s ability to run commands and analyze results in real-time.

## Workflow
1.  **Invocation**: User runs `/debug "command that failed" "optional error context"`.
2.  **Context Loading**: Template loads the command and context.
3.  **Agent Delegation**: Activates `implementation-executor`.
4.  **Execution**:
    *   Agent runs the failing command to reproduce the error (and capture output).
    *   Agent analyzes the stack trace/error message.
    *   Agent locates relevant source code.
    *   Agent hypothesizes a fix and applies it.
    *   Agent re-runs the command to verify the fix.
5.  **Completion**: Agent confirms the error is resolved.

## Agent Dependency
*   **Agent**: `implementation-executor`
*   **Capabilities**: Coding, Shell execution, Log analysis.

## Key Simplifications
*   **Real-time Analysis**: Analyzes live output rather than parsing historical log files.
*   **Interactive Loop**: The "Run -> Fail -> Fix -> Retry" loop happens naturally within the conversation flow, rather than being a scripted loop in bash.
