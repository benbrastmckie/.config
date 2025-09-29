---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob
argument-hint: [project-directory]
description: Setup or improve CLAUDE.md with links to standards and specs directory protocols
command-type: primary
dependent-commands: validate-setup
---

# Setup Project Standards

I'll create or improve the CLAUDE.md file to properly document project standards and establish protocols for specs directories.

## Target Directory
$1 (or current directory)

## Process

### 1. Analyze Project Structure
I'll examine the project to find:
- Existing CLAUDE.md file
- Standards documentation (GUIDELINES.md, STANDARDS.md, etc.)
- Testing configuration files and documentation
- Documentation standards or templates
- Existing specs/ directories

### 2. Discover Standards Files
I'll search for common standards patterns:

#### Code Standards
- `GUIDELINES.md`, `STANDARDS.md`, `STYLE.md`
- `docs/standards/`, `docs/guidelines/`
- `.editorconfig`, `.prettierrc`, `.eslintrc`
- Language-specific style guides

#### Testing Standards
- `TESTING.md`, `docs/testing/`
- Test configuration files
- CI/CD test configurations
- Test directory structures

#### Documentation Standards
- `CONTRIBUTING.md`, `docs/documentation/`
- README templates
- API documentation patterns
- Comment style guides

### 3. Create/Update CLAUDE.md
The CLAUDE.md file will be concise with links to detailed standards:

```markdown
# Project Standards and Protocols

## Quick Reference
- **Code Standards**: [Link to standards file]
- **Testing Protocols**: [Link to testing docs]
- **Documentation Guidelines**: [Link to docs standards]

## Commands
[Project-specific commands for common tasks]

## Specs Directory Protocol

### Structure
Create `specs/` directories at the deepest relevant level containing:
- `plans/` - Implementation plans (NNN_*.md format)
- `reports/` - Research reports (NNN_*.md format)
- `summaries/` - Implementation summaries (NNN_*.md format)

### Numbering Convention
All specs files use `NNN_descriptive_name.md` format:
- Three-digit numbers with leading zeros (001, 002, etc.)
- Increment from highest existing number
- Lowercase with underscores for names

### Location Guidelines
Place specs/ in the most specific directory that encompasses all relevant files:
- Feature-specific: In the feature's root directory
- Module-wide: In the module's directory
- Project-wide: In the project root

## Project-Specific Configuration
[Any project-specific settings or overrides]
```

### 4. Interactive Standards Creation
If standards files don't exist, I'll:
1. Prompt for code style preferences
2. Ask about testing framework and commands
3. Request documentation format preferences
4. Create appropriate standards files
5. Link them in CLAUDE.md

### 5. Create Missing Standards Files
Based on project type and user input:

#### Code Standards Template
```markdown
# Code Standards

## Style Guide
[Language-specific style rules]

## File Organization
[Project structure guidelines]

## Naming Conventions
[Variable, function, file naming rules]

## Best Practices
[Project-specific patterns]
```

#### Testing Standards Template
```markdown
# Testing Standards

## Test Organization
[Test file structure and naming]

## Test Commands
- Unit tests: [command]
- Integration tests: [command]
- Full suite: [command]

## Coverage Requirements
[Minimum coverage expectations]

## CI/CD Integration
[How tests run in CI]
```

#### Documentation Standards Template
```markdown
# Documentation Standards

## Code Comments
[Comment style and requirements]

## README Structure
[Template for README files]

## API Documentation
[How to document APIs]

## Specs Documentation
[How to write plans, reports, summaries]
```

### 6. Validate Setup
After creation/update, I'll:
- Verify all linked files exist
- Check that paths are correct
- Ensure specs protocol is clear
- Test that commands work

## Interactive Prompts

If standards don't exist, I'll ask:

1. **Code Style**
   - Indentation (spaces/tabs, size)
   - Line length limits
   - Naming conventions preference

2. **Testing**
   - Test framework/runner
   - Test file patterns
   - Coverage tools

3. **Documentation**
   - Comment style preference
   - README requirements
   - API doc format

## Output

I'll create/update:
1. `CLAUDE.md` - Main configuration file
2. Standards files (if needed)
3. Directory structure documentation
4. Command reference

Let me analyze your project and set up proper standards documentation.