---
description: Analyze codebase and update registries
allowed-tools: Read(specs/*), Edit(specs/TODO.md), Bash(jq:*), Bash(git:*), Read, Glob, Grep, Read(/tmp/*.json), Bash(rm:*)
---

# /review Command

Analyze the codebase for issues, patterns, and improvement opportunities.

## Usage

```
/review
```

## Workflow

1. **Explore Codebase**: Use @explore to analyze structure
2. **Identify Issues**: Find code smells, anti-patterns, bugs
3. **Check Standards**: Verify adherence to project patterns
4. **Delegate Review**: Send specific files to @code-reviewer
5. **Create Tasks**: Generate tasks for identified issues
6. **Update Registries**: Refresh code pattern documentation

## Review Areas

- **Architecture**: Component organization, dependencies
- **Code Quality**: Duplication, complexity, naming
- **Security**: Input validation, secrets management
- **Performance**: Bundle size, loading patterns
- **Accessibility**: ARIA labels, keyboard navigation
- **Standards**: TypeScript strictness, linting

## Example

User: `/review`

Agent:

- Explores src/ directory
- Finds 3 unused imports
- Finds 1 accessibility issue
- Delegates detailed review to @code-reviewer
- Creates task 43: "Fix accessibility issues in navigation"
- Creates task 44: "Remove unused imports"
- Reports: "Review complete. Created 2 tasks."
