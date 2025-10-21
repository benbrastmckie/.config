# Development Philosophy

[Used by: /refactor, /implement, /plan, /document]

## Clean-Break Refactors

- **Prioritize coherence over compatibility**: Clean, well-designed refactors are preferred over maintaining backward compatibility
- **System integration**: What matters is that existing commands and agents work well together in the current implementation
- **No legacy burden**: Don't compromise current design to support old formats or deprecated patterns
- **Migration is acceptable**: Breaking changes are acceptable when they improve system quality
- **Exception - Command Files**: Command and agent files require special refactoring rules (see [Command Architecture Standards](../reference/command_architecture_standards.md)) because they are AI prompts, not traditional code

## Documentation Standards

- **Present-focused**: Document the current implementation accurately and clearly
- **No historical reporting**: Don't document changes, updates, or migration paths in main documentation
- **What, not when**: Focus on what the system does now, not how it evolved
- **Clean narrative**: Documentation should read as if the current implementation always existed
- **Ban historical markers**: Never use labels like "(New)", "(Old)", "(Original)", "(Current)", "(Updated)", or version indicators in feature descriptions
- **Timeless writing**: Avoid phrases like "previously", "now supports", "recently added", "in the latest version"
- **No migration guides**: Do not create migration guides or compatibility documentation for refactors

## Rationale

This project values:
1. **Clarity**: Clean, consistent documentation that accurately reflects current state
2. **Quality**: Well-designed systems over backward-compatible compromises
3. **Coherence**: Commands, agents, and utilities that work seamlessly together
4. **Maintainability**: Code that is easy to understand and modify today

When refactoring, prefer to:
- Create clean, consistent interfaces
- Remove deprecated patterns entirely
- Update documentation to reflect only current implementation
- Ensure all components work together harmoniously

Backward compatibility is secondary to these goals.
