# Architecture Design: /research Command

## Purpose
The `/research` command initiates a structured investigation into a specific topic, technology, or codebase area. It uses a coordinator-worker pattern to decompose complex topics into manageable sub-investigations, ensuring comprehensive coverage and structured output.

## Opencode Approach
The command utilizes a **Coordinator Agent** to manage the workflow state and file structure, and **Specialist Agents** to perform the actual research. This separates the concern of "managing the project structure" from "doing the research."

## Workflow

1.  **Invocation**:
    *   User runs `/research "Topic Name"`.
    *   Command template injects `$ARGUMENTS` and delegates to the `research-coordinator`.

2.  **Coordinator Initialization**:
    *   **Project Numbering & Locking**:
        *   The `research-coordinator` reads `.opencode/specs/next_project_id` (defaulting to `001` if missing).
        *   It implements a simple lock by attempting to create a directory `.opencode/specs/lock` or similar. *Note: Native atomic locking is not fully supported in OpenCode, so file-system based locking is used.*
        *   It increments the ID in the file for the next use.
    *   **Scaffolding**:
        *   Generates a descriptive directory slug (e.g., `NNN_topic_name`).
        *   Creates the directory structure: `.opencode/specs/NNN_topic_name/reports/`.
        *   Creates `.opencode/specs/NNN_topic_name/OVERVIEW.md`.
        *   Writes the original research prompt into a `## Prompt` section in `OVERVIEW.md`.

3.  **Decomposition & Assignment**:
    *   The Coordinator analyzes the prompt and divides it into 1-5 distinct subtopics.
    *   For each subtopic:
        *   Creates a report file: `.opencode/specs/NNN_topic_name/reports/report_{subtopic_slug}.md`.
        *   Writes the specific subtopic prompt into a `## Prompt` section of that file.

4.  **Research Execution**:
    *   **Baseline (Sequential)**: The Coordinator invokes a `research-specialist` subagent for each subtopic report sequentially. This is the default OpenCode behavior.
    *   **Future Extension (Parallel)**: See "Future Extensions for Parallelism" below for workarounds.
    *   **Instruction to Specialist**:
        *   Read the assigned report file to get the prompt.
        *   Conduct research (WebSearch, Codebase Analysis).
        *   Write findings directly into the report file.
        *   Append a brief summary and a link to the report in the `OVERVIEW.md` file.

5.  **Completion & Review**:
    *   Once all subagents finish, the Coordinator reviews the `OVERVIEW.md` file to ensure coherence.
    *   The Coordinator returns a final response to the user with a link to `OVERVIEW.md` and a high-level summary.

## Agent Dependencies

### 1. Research Coordinator (`research-coordinator`)
*   **Role**: Project Manager.
*   **Capabilities**: File system management, decomposition, delegation, synthesis.
*   **Responsibilities**: Naming, scaffolding, prompt splitting, reviewing final output.
*   **Tools**: `bash` (for locking/scaffolding), `read`, `write`.

### 2. Research Specialist (`research-specialist`)
*   **Role**: Researcher.
*   **Capabilities**: Deep research, technical writing, file editing.
*   **Responsibilities**: Executing specific sub-prompts, writing detailed findings, updating the central overview.
*   **Tools**: `websearch`, `webfetch`, `grep`, `glob`, `read`, `write`.

## Concerns & Limitations
*   **Sequential Execution Latency**: Since OpenCode does not natively run subagents in parallel, the total time for a research task is the sum of all sub-tasks. Users should be advised to limit subtopics to 3-5 to prevent excessive wait times.
*   **Locking Race Conditions**: Without a native database or atomic lock service, file-based locking has a small window for race conditions if multiple users/agents try to create a project simultaneously.
*   **Context Window**: While the file-system approach reduces context load, the Coordinator still maintains the session history. For very large decompositions (e.g., >10 subtopics), the Coordinator's context might saturate. Limiting to 1-5 subtopics is a crucial design constraint.

## Future Extensions for Parallelism

To mitigate sequential execution latency, two workarounds can be implemented:

### 1. Bash Orchestrator (Recommended)
This approach shifts parallelism to the OS level by spawning independent OpenCode CLI instances.
*   **Mechanism**: The Coordinator generates a bash script (e.g., `run_research.sh`) that contains commands to run multiple OpenCode instances in the background:
    ```bash
    opencode --model "anthropic/claude-sonnet-4" --prompt-file "prompt_A.md" &
    opencode --model "anthropic/claude-sonnet-4" --prompt-file "prompt_B.md" &
    wait
    ```
*   **Pros**: True parallel execution; utilizes OS multitasking.
*   **Cons**: Each CLI instance has no shared memory with the Coordinator; higher API cost; requires non-interactive CLI configuration.

### 2. Custom MCP Server for Concurrency
This approach uses a custom Model Context Protocol (MCP) server to handle background tasks.
*   **Mechanism**: Create an MCP tool `start_background_research(topic)` that spawns a detached process (Node.js/Python) to execute the research logic. The tool returns immediately, allowing the Coordinator to proceed or poll for status via `check_research_status()`.
*   **Pros**: Keeps the OpenCode session responsive; cleaner architecture than raw bash scripts.
*   **Cons**: Requires developing and maintaining a custom MCP server codebase.
