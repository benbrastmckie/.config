# Orchestrator Migration Command Designs

This directory contains the high-level architecture designs for migrating core orchestrator commands to an OpenCode-native workflow. These designs prioritize simplicity, interactivity, and the use of OpenCode's agent capabilities over the legacy complex bash/state-machine architecture.

## Design Files

*   **[/research](./research-design.md)**
    *   **Description**: A simplified workflow that delegates topic research and report generation to the `research-specialist` agent in a single session, removing the need for state tracking.

*   **[/create-plan](./create-plan-design.md)**
    *   **Description**: Invokes the `plan-architect` to synthesize research into a structured implementation plan, leveraging the agent's ability to locate context dynamically.

*   **[/implement](./implement-design.md)**
    *   **Description**: Replaces wave-based parallel execution with a sequential, interactive coding session led by the `implementation-executor`, focusing on step-by-step application of the plan.

*   **[/revise](./revise-design.md)**
    *   **Description**: A direct instruction wrapper for the `plan-architect` to modify existing artifacts based on user feedback, removing complex drift-detection logic.

*   **[/debug](./debug-design.md)**
    *   **Description**: Leverages real-time terminal output and the `implementation-executor`'s coding skills to reproduce, analyze, and fix errors interactively, replacing historical log parsing.
