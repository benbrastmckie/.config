# Research Command Debugging Report (Updated)

**Date**: 2025-12-11

**Author**: OpenCode Agent

**Status**: Complete

## 1. Summary

This report details the investigation and resolution of a critical error affecting the new `/research` command located in the `.opencode/` directory. The command failed with an "Invalid Invalid Tool" error, preventing all research-related workflows from executing. The root cause was identified as the use of a deprecated pseudo-syntax for invoking the `Task` tool, a remnant from a legacy "Claude Code" system. The issue has been resolved by updating the command to use the correct, native `Task` tool invocation syntax for OpenCode.

## 2. Problem Description

When executing the `/research` command, the `research-coordinator` agent fails to launch, returning the following error:

```
Invalid Invalid Tool
```

This error indicates that the `Task` tool was called with an invalid `subagent_type`. The user's session logs confirmed that the `subagent_type: "general-purpose"` was being used.

## 3. Investigation

The investigation followed these steps:

1.  **Initial Misdirection:** The investigation initially focused on the `.claude/` directory, where a similar `/research` command exists. Edits were made to this file, but the user correctly pointed out that the issue was with a *new* command in the `.opencode/` directory. The incorrect edits were reverted.

2.  **Locating the Correct Command:** The file `/home/benjamin/.config/.opencode/command/research.md` was identified as the correct command definition.

3.  **Identifying the Pseudo-Syntax:** The command was found to be using a `Task { ... }` block, which is a pseudo-syntax from the legacy "Claude Code" platform and is not compatible with the native OpenCode `Task` tool.

4.  **Discovering the Correct Syntax:** A review of the OpenCode documentation revealed that the correct way to invoke the `Task` tool is with the directive: `**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.`

5.  **Confirming the `subagent_type`:** The frontmatter of the command file specified `agent: research-coordinator`, indicating that this is the correct `subagent_type` to use.

## 4. Root Cause

The root cause of the error is a compatibility issue. The new `/research` command in the `.opencode/` directory was written using a deprecated pseudo-syntax (`Task { ... }`) from a different platform ("Claude Code"). The OpenCode `Task` tool does not understand this syntax, leading to a parser error that manifests as the cryptic "Invalid Invalid Tool" message.

## 5. Resolution

The issue was resolved by performing the following action:

1.  **Edited the command definition:** The file `/home/benjamin/.config/.opencode/command/research.md` was edited to replace the `Task { ... }` block with the correct `Task` tool invocation, and the `subagent_type` was set to `research-coordinator` as specified in the file's frontmatter.

This change aligns the command with the correct `Task` tool invocation syntax for the OpenCode platform and resolves the "Invalid Invalid Tool" error.

## 6. Verification

The fix can be verified by re-running the `/research` command. The command should now execute successfully, launching the `research-coordinator` agent and proceeding with the research workflow.
