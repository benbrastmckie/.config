# Reference Documentation

## Purpose

Information-oriented quick lookup documentation for commands, agents, schemas, and standards. Use this section when you need rapid access to specific technical details, API signatures, or architectural requirements.

## Navigation

- [← Documentation Index](../README.md)
- [Guides](../guides/) - Task-focused how-to documentation
- [Concepts](../concepts/) - Understanding-oriented architectural explanations
- [Workflows](../workflows/) - Step-by-step workflow tutorials

## Documents in This Section

### [Command Quick Reference](../reference/command-reference.md)
**Purpose**: Alphabetical listing of all Claude Code slash commands with usage syntax, arguments, agents used, and output descriptions.

**Use Cases**:
- When you need to quickly look up command syntax or available arguments
- To discover which commands use which agents for workflow planning
- To find the right command for a specific development task
- When building new commands that need to reference existing commands

**See Also**: [Creating Commands](../guides/command-development-guide.md), [Command Patterns](../guides/command-patterns.md)

---

### [Agent Reference](agent-reference.md)
**Purpose**: Directory of all specialized agents with capabilities, tool restrictions, and usage contexts.

**Use Cases**:
- When selecting an appropriate agent for a specific task in command development
- To understand which tools are available to each agent
- To discover which commands use a particular agent
- When designing multi-agent workflows and need to understand agent specializations

**See Also**: [Creating Agents](../guides/agent-development-guide.md), [Using Agents](../guides/agent-development-guide.md)

---

### [CLAUDE.md Section Schema](../reference/claude-md-section-schema.md)
**Purpose**: Standard format specification for CLAUDE.md sections ensuring machine-parseable standards discovery.

**Use Cases**:
- When adding new sections to CLAUDE.md files
- To understand how commands parse and discover project standards
- When implementing standards integration in new commands
- To debug standards discovery issues in existing commands

**See Also**: [Standards Integration Guide](../guides/standards-integration.md), [Command Architecture Standards](command_architecture_standards.md)

---

### [Command Architecture Standards](command_architecture_standards.md)
**Purpose**: Comprehensive architectural requirements for command and agent file design, covering inline execution requirements, context preservation, and AI execution script principles.

**Use Cases**:
- Before creating or modifying any command or agent file (REQUIRED reading)
- When refactoring commands to ensure AI executability is preserved
- To understand why certain patterns are required in command files
- When debugging command execution failures or context issues

**See Also**: [Creating Commands](../guides/command-development-guide.md), [Creating Agents](../guides/agent-development-guide.md), [Command Patterns](../guides/command-patterns.md)

---

### [Phase Dependencies Guide](../reference/phase_dependencies.md)
**Purpose**: Complete specification for dependency syntax, wave calculation algorithms, and parallel execution patterns in implementation plans.

**Use Cases**:
- When declaring phase dependencies in implementation plans
- To understand how wave-based parallel execution is calculated
- When optimizing implementation performance through parallelization
- To debug dependency validation errors or circular dependency issues

**See Also**: [Orchestration Guide](../workflows/orchestration-guide.md), [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md)

---

### [Library API Reference](library-api.md)
**Purpose**: Quick lookup reference for all `.claude/lib/` utility libraries with function signatures, return formats, and performance characteristics.

**Use Cases**:
- When you need to call a specific utility function in a command or agent
- To understand the API and return format of an existing library
- To discover available libraries before implementing new logic
- When optimizing command performance by replacing agent calls with library calls

**See Also**: [Using Utility Libraries](../guides/using-utility-libraries.md), [Command Development Guide](../guides/command-development-guide.md)

---

### [Template vs Behavioral Distinction](template-vs-behavioral-distinction.md)
**Purpose**: Critical architectural principle defining when to use inline templates vs behavioral file references in commands and agents.

**Key Principle**: Structural templates inline, behavioral content referenced

**Metrics**: 90% code reduction, 71% context savings, 100% file creation rate

**Zero Exceptions**: No documented exceptions to behavioral duplication prohibition

**Use Cases**:
- Before creating any command or agent file (CRITICAL reading)
- When unsure whether content should be inline or referenced
- To understand the 5 categories of structural templates (Task syntax, bash blocks, schemas, checkpoints, warnings)
- When refactoring commands to eliminate behavioral duplication
- To debug inline duplication anti-pattern (150+ line agent invocations)

**See Also**: [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md), [Command Architecture Standards](command_architecture_standards.md) - Standard 12, [Inline Template Duplication Troubleshooting](../troubleshooting/inline-template-duplication.md)

---

## Quick Start

### Look Up a Command
```bash
# Open command reference and search for command name
less .claude/docs/reference/command-reference.md
# Search: /commandname
```

### Find the Right Agent
```bash
# Open agent reference and browse by capability
less .claude/docs/reference/agent-reference.md
# Look for "Capabilities" sections
```

### Check Standards Schema
```bash
# View section format requirements
less .claude/docs/reference/claude-md-section-schema.md
# Look for "Standard Sections" for examples
```

## Directory Structure

```
reference/
├── README.md                              (this file)
├── command-reference.md                   Quick command lookup
├── agent-reference.md                     Agent directory
├── claude-md-section-schema.md            Standards format specification
├── command_architecture_standards.md      Command/agent design requirements
├── template-vs-behavioral-distinction.md  Inline vs reference decision criteria
├── phase_dependencies.md                  Dependency syntax and wave calculation
└── library-api.md                         Utility library API reference
```

## Related Documentation

**Other Categories**:
- [Guides](../guides/) - Task-focused how-to guides build on reference specifications
- [Concepts](../concepts/) - Architectural concepts explain the design rationale behind reference standards
- [Workflows](../workflows/) - Step-by-step workflows apply reference specifications to real tasks

**External Directories**:
- [Commands](../../commands/) - Command implementation files
- [Agents](../../agents/) - Agent implementation files
- [Libraries](../../lib/) - Utility libraries referenced in standards
- [Templates](../../templates/) - Reusable templates and patterns
