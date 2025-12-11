# Architecture Design: /create-plan Command

## Purpose
The `/create-plan` command generates a comprehensive implementation plan for a requested feature or task. It synthesizes requirements (and optional research) into a structured roadmap for developers.

## Opencode Approach
This command uses a template to invoke the `plan-architect` agent. It relies on the agent's ability to locate context (existing research reports or codebase files) and structure a document according to project standards.

## Workflow
1.  **Invocation**: User runs `/create-plan "Feature Name"`.
2.  **Context Loading**: The template injects the `$ARGUMENTS`.
3.  **Agent Delegation**: The template activates the `plan-architect` agent.
4.  **Execution**:
    *   Agent searches for existing research in `.claude/specs/`.
    *   Agent analyzes the codebase to understand impact.
    *   Agent drafts a plan following the standard template (Metadata, Overview, Proposed Changes, Verification).
    *   Agent writes the plan to `.claude/specs/{feature_slug}/plans/001-plan.md`.
5.  **Completion**: Agent presents the plan location to the user.

## Agent Dependency
*   **Agent**: `plan-architect`
*   **Capabilities**: High-level architectural reasoning, file writing, comprehensive understanding of project standards.

## Key Simplifications
*   **No Pre-computation**: Does not pre-calculate paths or IDs in bash; the agent handles naming conventions dynamically.
*   **Flexible Input**: Can accept a research report path or just a raw idea string.
*   **No Rigid Dependencies**: Does not force a "research" phase first; the agent decides if it has enough info or needs to look things up.
