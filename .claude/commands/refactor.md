---
allowed-tools: Read, Write, Bash, Grep, Glob, Task
argument-hint: [file/directory/module] [specific-concerns]
description: Analyze code for refactoring opportunities based on project standards and generate detailed report
command-type: primary
dependent-commands: report, plan, implement
---

# Refactoring Analysis Report

I'll analyze the specified part of the project (or the entire project if unspecified) for refactoring opportunities based on CLAUDE.md standards and any specific concerns provided.

## Target Scope
$ARGUMENTS

## Process

### 1. Scope Determination
I'll identify what to analyze:
- If specific file/directory provided: Focus on that area
- If module name provided: Find all related files for that module
- If no arguments: Analyze entire project structure
- Parse any specific concerns or new feature descriptions provided

### 2. Location Determination and Registration
I'll determine the specs directory location using this process:

**Step 1: Detect Project Directory**
- Identify the scope of refactoring (file, directory, module, or entire project)
- Find the deepest directory that encompasses the refactoring scope
- This becomes the "project directory" for this refactoring report

**Step 2: Check SPECS.md Registry**
- Read `.claude/SPECS.md` to see if this project is already registered
- Look for a section matching the project directory path

**Step 3: Use Registered or Auto-Detect**
- If found in SPECS.md: Use the registered specs directory
- If not found: Auto-detect best location (project-dir/specs/) and register it

**Step 4: Register in SPECS.md**
- If new project: Create new section in SPECS.md with project path and specs directory
- Update "Last Updated" date and increment "Reports" count
- Use Edit tool to update SPECS.md

### 3. Standards Review
I'll load and apply standards from:
- **CLAUDE.md**: Project conventions and standards
- **Nix Development Standards**: Code style, organization, testing
- **Documentation Standards**: Specs directory protocol
- **Application Configurations**: From docs/applications.md
- **Package Management**: Best practices from docs/packages.md

### 3. Code Analysis Phase
I'll systematically examine:

#### Code Quality Issues
- **Duplication**: Repeated code that could be abstracted
- **Complexity**: Functions/modules that are too complex
- **Dead Code**: Unused functions, variables, imports
- **Inconsistent Patterns**: Deviations from established patterns

#### Nix-Specific Issues
- **Indentation**: Not using 2 spaces for Nix files
- **Line Length**: Lines exceeding 80 characters
- **File Organization**: Misplaced configurations
- **Import Structure**: Circular or inefficient dependencies
- **Package Definitions**: Non-idiomatic Nix expressions

#### Structure and Architecture
- **Module Boundaries**: Poorly defined or violated boundaries
- **Coupling**: Tight coupling that should be loosened
- **Cohesion**: Low cohesion modules that should be split
- **Layering**: Violations of architectural layers

#### Testing Gaps
- **Missing Tests**: Components without test coverage
- **Test Quality**: Tests that don't follow testing.md standards
- **Test Organization**: Misplaced or poorly organized tests

#### Documentation Issues
- **Missing Documentation**: Undocumented complex logic
- **Outdated Docs**: Documentation not matching implementation
- **Spec Compliance**: Missing plans/reports/summaries per protocol

### 4. Opportunity Identification
I'll categorize refactoring opportunities by:

#### Priority Levels
- **Critical**: Breaking standards, causing bugs, security issues
- **High**: Significant maintainability or performance issues
- **Medium**: Quality improvements, better adherence to standards
- **Low**: Nice-to-have improvements, minor inconsistencies

#### Effort Estimation
- **Quick Win**: < 30 minutes, isolated changes
- **Small**: 30 min - 2 hours, single file/module
- **Medium**: 2-8 hours, multiple files, some testing
- **Large**: 8+ hours, architectural changes, extensive testing

#### Risk Assessment
- **Safe**: No functional changes, purely cosmetic
- **Low Risk**: Minor functional changes, well-tested
- **Medium Risk**: Significant changes, needs thorough testing
- **High Risk**: Core functionality changes, breaking changes possible

### 5. Specific Concern Analysis
If user provides specific concerns (e.g., new feature requirements):
- Analyze how existing code conflicts with new requirements
- Identify components that need modification
- Suggest preparatory refactoring to ease feature implementation
- Highlight architectural changes needed

### 6. Report Generation
I'll create a comprehensive refactoring report in `specs/reports/`:

#### Report Number Assignment
- Check existing reports in appropriate `specs/reports/` directory
- Use next sequential number (NNN format with leading zeros)
- Name format: `NNN_refactoring_[scope].md`

#### Report Structure

Refactoring reports follow the standard structure defined in `.claude/templates/refactor-structure.md`.

Key sections include:
- **Executive Summary**: High-level findings and overall assessment
- **Critical Issues**: Must-fix problems (bugs, security, major standards violations)
- **Refactoring Opportunities**: Categorized findings (duplication, complexity, standards, architecture, testing, docs)
- **Implementation Roadmap**: Phased approach with effort and risk estimates
- **Testing Strategy**: How to verify refactoring doesn't break functionality
- **Migration Path**: Step-by-step guide for applying refactorings
- **Metrics**: Files analyzed, issues found, effort estimates

For complete refactoring report structure and analysis guidelines, see `.claude/templates/refactor-structure.md`

### 7. Actionable Output
The report will provide:
- Clear, prioritized list of refactoring tasks
- Specific code examples of problems and solutions
- Integration points with new features (if applicable)
- Commands to run for validation
- Links to create follow-up plans with `/plan` command

## Success Criteria
- All code analyzed against CLAUDE.md standards
- Every finding includes specific location and solution
- Priorities align with project goals and user concerns
- Report enables immediate action via `/plan` or `/implement`

## Agent Usage

This command delegates code analysis to the `code-reviewer` agent:

### code-reviewer Agent
- **Purpose**: Standards compliance review and quality analysis
- **Tools**: Read, Grep, Glob, Bash
- **Invocation**: Single agent for each refactoring analysis
- **Read-Only**: Never modifies code, only reviews and reports

### Invocation Pattern
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Analyze [scope] for refactoring opportunities using code-reviewer protocol"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/code-reviewer.md

          You are acting as a Code Reviewer with the tools and constraints
          defined in that file.

          Code Review Task: Analyze for refactoring

          Context:
          - Scope: [file/directory/module from user]
          - Concerns: [specific concerns if provided]
          - Project Standards: CLAUDE.md

          Analysis Required:
          1. Standards Compliance Check
             - Indentation (2 spaces, no tabs)
             - Naming conventions (snake_case)
             - Line length (<100 chars)
             - Error handling (pcall usage)
             - No emojis in code

          2. Code Quality Assessment
             - Code duplication
             - Overly complex functions
             - Unused variables/imports
             - Potential bugs
             - Organization issues

          3. Refactoring Opportunities
             - Extract repeated code
             - Simplify complex logic
             - Improve naming
             - Better error handling
             - Module structure improvements

          Output Format:
          Structured review with severity levels:
          - Blocking: Must fix (tabs, emojis, critical issues)
          - Warning: Should fix (length, naming, duplication)
          - Suggestion: Consider improving (comments, optimization)

          Report includes:
          - Specific file:line references
          - Explanation of each issue
          - Recommended fix
          - Priority ranking
  "
}
```

### Agent Benefits
- **Systematic Analysis**: Consistent review process across all code
- **Standards Enforcement**: Automatic checking against CLAUDE.md
- **Severity Classification**: Clear prioritization of issues
- **Actionable Feedback**: Specific fixes, not just problems
- **Non-Destructive**: Analysis only, no unintended modifications

### Workflow Integration
1. User invokes `/refactor` with scope and optional concerns
2. Command delegates to `code-reviewer` agent
3. Agent analyzes code against standards and quality criteria
4. Agent generates structured report with findings
5. Command returns report for review
6. User can use findings to create `/plan` for fixes

### Review Output Format
```markdown
Code Review: [Module/File]

Blocking Issues (0):
[None found or list with file:line references]

Warnings (N):
  1. file.lua:42 - Line length exceeds 100 characters (actual: 120)
     Suggestion: Break into multiple lines

  2. file.lua:67 - Variable 'someVar' uses camelCase, should be snake_case
     Suggestion: Rename to 'some_var'

Suggestions (M):
  1. file.lua:15 - Missing function documentation
     Suggestion: Add docstring explaining purpose

Standards Compliance Summary:
  ✓ Indentation: Compliant
  ✓ Error handling: Adequate
  ⚠ Line length: 3 violations
  ⚠ Naming: 2 inconsistencies

Overall: PASS with warnings
```

Let me begin analyzing the specified scope for refactoring opportunities.
