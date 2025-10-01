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

### 2. Standards Review
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
```markdown
# Refactoring Analysis: [Scope]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Scope**: [Files/directories analyzed]
- **Standards Applied**: CLAUDE.md, [other relevant docs]
- **Specific Concerns**: [User-provided concerns if any]

## Executive Summary
[High-level overview of findings and recommendations]

## Critical Issues
[Must-fix problems that violate core standards or cause bugs]

## Refactoring Opportunities

### Category 1: [e.g., Code Duplication]
#### Finding 1.1: [Specific issue]
- **Location**: file.nix:lines
- **Current State**: [Problem description]
- **Proposed Solution**: [Specific refactoring]
- **Priority**: Critical/High/Medium/Low
- **Effort**: Quick Win/Small/Medium/Large
- **Risk**: Safe/Low/Medium/High

### Category 2: [e.g., Architecture Improvements]
[Continue with findings...]

## Implementation Roadmap
1. **Phase 1 - Critical Fixes**: [What to do first]
2. **Phase 2 - High Priority**: [Next steps]
3. **Phase 3 - Improvements**: [Nice to have]

## Testing Strategy
[How to verify refactoring doesn't break functionality]

## Migration Path
[Step-by-step guide for applying refactorings]

## Metrics
- **Files Analyzed**: [count]
- **Issues Found**: [count by priority]
- **Estimated Total Effort**: [hours]
- **Test Coverage Impact**: [expected changes]

## References
- [Links to relevant files]
- [Documentation references]
- [Related plans/reports]
```

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
  subagent_type: "code-reviewer"
  description: "Analyze [scope] for refactoring opportunities"
  prompt: "
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
