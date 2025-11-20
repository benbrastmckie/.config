# Architecture Standards Overview

**Document Type**: Architecture Standards Index
**Scope**: All files in `.claude/commands/` and `.claude/agents/`
**Status**: ACTIVE - Must be followed for all modifications
**Last Updated**: 2025-11-17 (Split from monolithic document)

---

## Purpose

This document establishes architectural standards for Claude Code command and agent files to ensure they remain **directly executable by Claude** while avoiding code duplication and maintaining clear organization.

**Key Principle**: Command and agent files are **AI prompts that drive execution**, not traditional software code. Refactoring patterns that work for code may break AI execution.

---

## Standards Index

This overview serves as a navigation hub for the architecture standards, which have been split for maintainability:

| Standard | Document | Description |
|----------|----------|-------------|
| 0, 0.5 | [Execution Enforcement](validation.md) | Imperative language, verification checkpoints, subagent prompts |
| 1-5 | [Core Standards](documentation.md) | Inline requirements, reference patterns, template completeness |
| 11 | [Agent Invocation](integration.md) | Imperative agent invocation pattern |
| 12-14 | [Dependencies](dependencies.md) | Content separation, project directory, file separation |
| 15-16 | [Error Handling](error-handling.md) | Library sourcing, return code verification |
| Testing | [Testing Standards](testing.md) | Validation, review checklists, enforcement |

---

## Fundamental Understanding

### Command Files Are AI Execution Scripts

**What Command Files Are**:
- Step-by-step execution instructions that Claude reads and follows
- Direct tool invocation patterns with specific parameters
- Decision flowcharts that guide AI behavior
- Critical warnings and constraints that must be visible during execution
- Inline templates for agent prompts, JSON structures, and bash commands

**What Command Files Are NOT**:
- Traditional software that can be refactored using standard DRY principles
- Documentation that can be replaced with links to external references
- Code that can delegate implementation details to imported modules
- Static reference material that users read linearly

### Why External References Don't Work for Execution

When Claude executes a command:
1. User invokes `/commandname "task description"`
2. Claude loads `.claude/commands/commandname.md` into working context
3. Claude **immediately** needs to see execution steps, tool calls, parameters
4. Claude **cannot effectively** load and process multiple external files mid-execution
5. Context switches to external files break execution flow and lose state

**Analogy**: A command file is like a cooking recipe. You can't replace the instructions with "See cookbook on shelf for how to cook this" - the instructions must be present when you need them.

---

## Core Standards Summary

### Standard 0: Execution Enforcement

Commands must use imperative language ("YOU MUST", "EXECUTE NOW") and include verification checkpoints and fallback mechanisms.

**Full Documentation**: [Execution Enforcement](validation.md#standard-0-execution-enforcement)

### Standard 0.5: Subagent Prompt Enforcement

Agent files must use imperative enforcement patterns for file creation, sequential dependencies, and template compliance.

**Full Documentation**: [Subagent Prompt Enforcement](validation.md#standard-05-subagent-prompt-enforcement)

### Standards 1-5: Documentation Requirements

- **Standard 1**: Executable instructions must be inline
- **Standard 2**: Reference pattern (instructions first, reference after)
- **Standard 3**: Critical information density
- **Standard 4**: Template completeness
- **Standard 5**: Structural annotations

**Full Documentation**: [Core Standards](documentation.md)

### Standard 11: Imperative Agent Invocation

All Task invocations must use imperative instructions with behavioral file references and no code block wrappers.

**Full Documentation**: [Agent Invocation](integration.md#standard-11-imperative-agent-invocation-pattern)

### Standards 12-14: Content Separation

- **Standard 12**: Structural vs behavioral content separation
- **Standard 13**: Project directory detection (CLAUDE_PROJECT_DIR)
- **Standard 14**: Executable/documentation file separation

**Full Documentation**: [Dependencies](dependencies.md)

### Standards 15-16: Error Handling

- **Standard 15**: Library sourcing order
- **Standard 16**: Critical function return code verification

**Full Documentation**: [Error Handling](error-handling.md)

---

## Quick Reference Card

**When Refactoring Command Files**:

**DO**:
- Keep execution steps inline and numbered
- Include complete tool invocation examples
- Preserve critical warnings and constraints
- Provide copy-paste ready templates
- Add references to supplemental content AFTER inline instructions
- Test commands after refactoring
- Use structural annotations

**DON'T**:
- Replace execution steps with "See external file"
- Truncate templates with references to agent definitions
- Remove critical warnings for brevity
- Assume Claude can effectively load external files mid-execution
- Prioritize DRY principles over execution clarity
- Reduce file size below minimum thresholds
- Extract content without validation testing

**Testing After Changes**:
1. Temporarily remove `.claude/commands/shared/`
2. Execute the modified command
3. If it fails, restore inline content
4. Add references only after execution works

---

## Related Documentation

- [Validation and Enforcement](validation.md)
- [Error Handling](error-handling.md)
- [Dependencies](dependencies.md)
- [Testing Standards](testing.md)
- [Documentation Standards](documentation.md)
- [Integration Patterns](integration.md)

---

## Version History

- **2025-11-17**: Split into multiple files for maintainability
- **2025-10-27**: Spec 497 - Unified orchestration improvements
- **2025-10-16**: Initial version based on refactoring damage analysis

---

**Remember**: Command files are AI execution scripts, not traditional code. When in doubt, keep content inline.
