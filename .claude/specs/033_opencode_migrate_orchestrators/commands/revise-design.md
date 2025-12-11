# Architecture Design: /revise Command

## Purpose
The `/revise` command is used to update existing documents—primarily plans or reports—based on new information, user feedback, or "drift" discovered during implementation.

## Opencode Approach
In the legacy system, `/revise` was a complex state-machine transition. In OpenCode, it is a direct instruction to the `plan-architect` (or generic `writer` agent) to read a specific file and apply changes based on user input.

## Workflow
1.  **Invocation**: User runs `/revise "path/to/file" "instructions on what to change"`.
2.  **Context Loading**: Template accepts `$ARGUMENTS` which should ideally be parsed or treated as a single instruction string.
3.  **Agent Delegation**: Activates `plan-architect`.
4.  **Execution**:
    *   Agent reads the target file.
    *   Agent interprets the revision instructions.
    *   Agent edits the file using `Edit` or `Write` tools.
    *   Agent verifies the changes align with the instructions.
5.  **Completion**: Agent confirms the file has been updated.

## Agent Dependency
*   **Agent**: `plan-architect` (primary), but could theoretically route to others based on file type (e.g. `research-specialist` for reports).

## Key Simplifications
*   **Direct Interaction**: Removes the abstraction of "phases" (e.g., "we are going back to planning phase"). It just modifies the artifact directly.
*   **No Drift Detection Logic**: Does not automatically calculate "drift score". The user (or another agent) identifies the need for revision, and this command executes it.
