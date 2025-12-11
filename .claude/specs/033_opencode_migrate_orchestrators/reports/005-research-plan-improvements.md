# Report: Improvements for Research Command Implementation Plan

## Metadata
- **Report ID**: 005-research-plan-improvements
- **Refers To**: `plans/002-research-command-implementation.md`
- **Source**: `reports/004-opencode-best-practices.md`
- **Status**: Ready for Review

## Executive Summary
The initial implementation plan provides a solid structural foundation but lacks specific configuration details regarding permissions, model selection, and context management identified in the best practices report. Integrating these will improve safety, cost-efficiency, and user experience.

## Recommended Improvements

### 1. Refine Agent Definitions (Phase 2)

#### 1.1. Research Specialist (`research-specialist.md`)
*   **Permission Scoping**:
    *   *Current*: Lists tools generically.
    *   *Improvement*: Explicitly **deny** `bash` access to prevent the specialist from executing arbitrary code. Only `websearch`, `webfetch`, `read`, and `write` (for reports) are needed.
    *   *Action*: Add `permission` block to frontmatter denying `bash` and `edit` (prefer `write` for appending/creating reports).
*   **Model Selection**:
    *   *Improvement*: Specify **`google/gemini-3-deep-think`** (or `google/gemini-3-pro`) to leverage state-of-the-art reasoning for high-quality research synthesis.
*   **Safety Limits**:
    *   *Improvement*: Set `maxSteps: 20` to prevent the specialist from getting stuck in a research loop.

#### 1.2. Research Coordinator (`research-coordinator.md`)
*   **Tool Access**:
    *   *Current*: Needs `bash`.
    *   *Improvement*: Restrict `bash` access using glob patterns. Only allow commands needed for locking/scaffolding (e.g., `mkdir`, `cat`, `echo`, `ls`). Deny `rm` or other destructive commands.
    *   *Action*: Add `permission.bash` configuration.
*   **Model Selection**:
    *   *Improvement*: Use **`google/gemini-2.5-flash-lite`** (or `google/gemini-2.5-flash`) for extremely fast and cost-efficient logic routing and file management.

### 2. Refine Command Definition (Phase 3)

#### 2.1. Command Context (`research.md`)
*   **Subtask Isolation**:
    *   *Current*: Implicit routing.
    *   *Improvement*: Explicitly set `subtask: true` in the command frontmatter (or implied by agent mode). This ensures the research session is isolated from the main chat context, keeping the primary history clean.
*   **Frontmatter Completeness**:
    *   *Improvement*: Ensure `description` is descriptive for the UI (e.g., "Research a topic and generate a structured report").

### 3. Refine Verification (Phase 5)

#### 3.1. Safety Validation
*   *Improvement*: Add a test case to verify that the `research-specialist` *cannot* execute bash commands (e.g., try to make it run `ls`).
*   *Improvement*: Verify that the `research-coordinator` creates the lock file correctly and handles the case where the ID file is missing (initialization logic).

## Updated Plan Checklist items
- [ ] Add `permission` blocks to all agent definitions.
- [ ] Configure `model` fields: Coordinator (`gemini-2.5-flash-lite`) vs Specialist (`gemini-3-deep-think`).
- [ ] Set `maxSteps` for the Specialist.
- [ ] Enable `subtask: true` for the `/research` command.
- [ ] Add safety verification steps to the test plan.
