# Refactoring Analysis Report Template

This template defines the standard structure for refactoring analysis reports created by the `/refactor` command.

## File Location

Refactoring reports are created in the topic-based directory structure:
```
specs/{NNN_topic}/reports/NNN_refactoring_scope.md
```

Where:
- `{NNN_topic}`: Three-digit numbered topic directory (e.g., `001_cleanup`)
- `NNN`: Next sequential number within the topic's `reports/` subdirectory
- `scope`: Snake_case description of refactoring scope (file, module, or area)

## Standard Refactoring Report Structure

```markdown
# Refactoring Analysis: [Scope]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Topic Directory**: [specs/{NNN_topic}/]
- **Report Number**: [NNN] (within topic)
- **Scope**: [Files/directories analyzed]
- **Standards Applied**: CLAUDE.md, [other relevant docs]
- **Specific Concerns**: [User-provided concerns if any]
- **Analysis Method**: [Code review, metrics, pattern detection, etc.]

## Executive Summary

[High-level overview of findings and recommendations - 2-3 paragraphs]

**Key Findings**:
- [Major finding 1]
- [Major finding 2]
- [Major finding 3]

**Overall Assessment**: [Good|Needs Improvement|Requires Significant Refactoring]

## Scope Analysis

### Files Analyzed
[List of files examined with brief description]

### Standards Reference
[Which CLAUDE.md standards were applied]

### User Concerns
[User-provided specific concerns or new feature requirements that triggered this analysis]

## Critical Issues

[Must-fix problems that violate core standards, cause bugs, or present security risks]

### Issue 1: [Title]
- **Location**: `file.ext:line-line`
- **Severity**: Critical
- **Category**: [Bug|Security|Standards Violation]
- **Current State**: [Detailed description of the problem]
- **Impact**: [Why this is critical]
- **Proposed Solution**: [Specific refactoring required]
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe|Low|Medium|High]

## Refactoring Opportunities

### Category 1: Code Duplication

#### Finding 1.1: [Specific duplication issue]
- **Location**:
  - `file1.ext:line-line`
  - `file2.ext:line-line`
- **Current State**: [Description of duplicated code]
- **Pattern**: [What pattern is repeated]
- **Proposed Solution**: [Extract to shared function/module/utility]
- **Benefits**:
  - [Benefit 1]
  - [Benefit 2]
- **Priority**: High|Medium|Low
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe|Low|Medium|High]

#### Finding 1.2: [Another duplication issue]
[Same structure]

### Category 2: Code Complexity

#### Finding 2.1: [Complex function or module]
- **Location**: `file.ext:line-line`
- **Current State**: [Description of complexity]
- **Metrics**:
  - Lines: [count]
  - Cyclomatic Complexity: [score if calculated]
  - Nested Levels: [count]
- **Proposed Solution**: [Break into smaller functions, extract logic, etc.]
- **Benefits**: [Improved readability, testability, maintainability]
- **Priority**: High|Medium|Low
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe|Low|Medium|High]

### Category 3: Standards Compliance

#### Finding 3.1: [Standards violation]
- **Location**: `file.ext:line-line`
- **Standard Violated**: [Reference to CLAUDE.md section]
- **Current State**: [What violates the standard]
- **Proposed Solution**: [How to bring into compliance]
- **Priority**: High|Medium|Low
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe|Low|Medium|High]

### Category 4: Architecture Issues

#### Finding 4.1: [Structural or architectural concern]
- **Location**: [Multiple files or modules]
- **Current State**: [Description of architecture issue]
- **Impact**: [How it affects system]
- **Proposed Solution**: [Architectural change needed]
- **Benefits**: [Better separation of concerns, looser coupling, etc.]
- **Priority**: High|Medium|Low
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe|Low|Medium|High]

### Category 5: Testing Gaps

#### Finding 5.1: [Missing or inadequate tests]
- **Location**: `file.ext` (missing tests)
- **Current State**: [What testing is missing]
- **Coverage Impact**: [How it affects overall coverage]
- **Proposed Solution**: [Tests to add]
- **Priority**: High|Medium|Low
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe|Low|Medium|High]

### Category 6: Documentation Issues

#### Finding 6.1: [Documentation problem]
- **Location**: `file.ext` or `directory/`
- **Current State**: [What documentation is missing or outdated]
- **Proposed Solution**: [Documentation to add or update]
- **Priority**: High|Medium|Low
- **Effort**: [Quick Win|Small|Medium|Large]
- **Risk**: [Safe]

## Integration with New Features

[If user provided new feature requirements or specific concerns]

### Feature Compatibility Analysis
[How existing code conflicts with new requirements]

### Preparatory Refactoring
[Refactorings that should be done before implementing new feature]

### Components Requiring Modification
[Which parts of the codebase will need changes for the new feature]

### Recommended Approach
[Strategy for refactoring + feature implementation]

## Implementation Roadmap

### Phase 1: Critical Fixes
**Objective**: Address blocking issues and security concerns

**Tasks**:
1. [Critical fix 1]
2. [Critical fix 2]

**Estimated Effort**: [hours]
**Dependencies**: None
**Risk**: [Assessment]

### Phase 2: High Priority Refactoring
**Objective**: Address major quality and maintainability issues

**Tasks**:
1. [High priority refactoring 1]
2. [High priority refactoring 2]
3. [High priority refactoring 3]

**Estimated Effort**: [hours]
**Dependencies**: Phase 1 complete
**Risk**: [Assessment]

### Phase 3: Standards Compliance
**Objective**: Bring all code into compliance with CLAUDE.md standards

**Tasks**:
1. [Standards fix 1]
2. [Standards fix 2]

**Estimated Effort**: [hours]
**Dependencies**: Phase 2 complete
**Risk**: [Assessment]

### Phase 4: Enhancement Refactoring
**Objective**: Nice-to-have improvements and optimizations

**Tasks**:
1. [Enhancement 1]
2. [Enhancement 2]

**Estimated Effort**: [hours]
**Dependencies**: Phase 3 complete
**Risk**: [Assessment]

## Testing Strategy

### Existing Test Verification
[How to ensure existing functionality isn't broken]

### New Tests Required
[Tests to add as part of refactoring]

### Test Coverage Goals
- **Current Coverage**: [XX%]
- **Target Coverage**: [XX%]

### Regression Prevention
[Strategy to prevent introducing bugs during refactoring]

## Migration Path

### Step-by-Step Guide
1. **Preparation**
   - [Prep step 1]
   - [Prep step 2]

2. **Refactoring Execution**
   - [Refactoring step 1]
   - [Refactoring step 2]

3. **Validation**
   - [Validation step 1]
   - [Validation step 2]

4. **Deployment**
   - [Deployment consideration 1]
   - [Deployment consideration 2]

### Rollback Plan
[How to rollback if issues are discovered]

### Breaking Changes
[Any breaking changes and how to handle them]

## Metrics

### Analysis Scope
- **Files Analyzed**: [count]
- **Lines of Code**: [count]
- **Modules/Components**: [count]

### Issues Found
- **Critical**: [count]
- **High Priority**: [count]
- **Medium Priority**: [count]
- **Low Priority**: [count]
- **Total**: [count]

### Effort Estimation
- **Quick Wins**: [count] issues, [hours] total
- **Small Tasks**: [count] issues, [hours] total
- **Medium Tasks**: [count] issues, [hours] total
- **Large Tasks**: [count] issues, [hours] total
- **Total Estimated Effort**: [hours]

### Expected Benefits
- **Code Reduction**: [estimated lines removed]
- **Complexity Reduction**: [qualitative assessment]
- **Test Coverage Improvement**: [XX% → XX%]
- **Maintainability**: [qualitative improvement]

## Priority Matrix

| Priority | Effort | Risk | Issues |
|----------|--------|------|--------|
| Critical | Any | Any | [count] |
| High | Quick Win | Safe/Low | [count] |
| High | Small | Safe/Low | [count] |
| Medium | Any | Safe/Low | [count] |
| Low | Any | Any | [count] |

## Implementation Status
- **Status**: Analysis Complete
- **Plan**: None yet | [Link to implementation plan]
- **Implementation**: Not started | In Progress | Complete
- **Date**: [YYYY-MM-DD]

*This section will be updated if/when refactoring recommendations are implemented.*

## References

### Codebase Files
- [file1.ext](relative/path/to/file1.ext) - [Brief description]
- [file2.ext](relative/path/to/file2.ext) - [Brief description]

### Standards Documentation
- [CLAUDE.md](relative/path/to/CLAUDE.md) - [Relevant sections]
- [CODE_STANDARDS.md](relative/path/to/CODE_STANDARDS.md) - [If exists]

### Related Artifacts
- Plan: [../plans/NNN_plan.md](../plans/NNN_plan.md) (if implementation plan exists)
- Other reports: [../reports/NNN_report.md](../reports/NNN_report.md) (if related)

## Appendix

### Code Examples

#### Example 1: [Problem demonstration]
```language
# Current code (problematic)
[Code snippet]

# Proposed refactoring
[Improved code]
```

#### Example 2: [Another example]
[Same structure]

### Standards Reference

#### [Standard Name]
From CLAUDE.md:
```
[Relevant standard text]
```

Current violations:
- [File:line]
- [File:line]
```

## Section Guidelines

### Executive Summary
- Brief overview suitable for decision makers
- 3-5 key findings
- Overall assessment of code quality
- Recommended priority for action

### Critical Issues
- Only truly critical items (security, bugs, major standards violations)
- Must-fix before proceeding with new development
- Each issue with clear impact and solution

### Refactoring Opportunities
- Organized by category (duplication, complexity, standards, architecture, testing, docs)
- Each finding includes location, current state, proposed solution
- Priority, effort, and risk assessment for each
- Balance ideal solutions with practical constraints

### Implementation Roadmap
- Phased approach with clear phases
- Dependencies between phases identified
- Effort estimates for each phase
- Risk assessment per phase

### Testing Strategy
- How to maintain confidence during refactoring
- New tests to add
- Coverage goals
- Regression prevention

### Migration Path
- Step-by-step guide for applying refactorings
- Rollback plan
- Breaking changes handled explicitly
- Deployment considerations

### Metrics
- Quantify the analysis scope
- Count issues by priority
- Estimate total effort
- Project expected benefits

## Best Practices

### Analysis Approach
- Start with critical issues (bugs, security)
- Use automated tools when available (linters, complexity metrics)
- Apply CLAUDE.md standards systematically
- Consider user's specific concerns or new features
- Balance thoroughness with practicality

### Prioritization
- Critical issues always first
- Quick wins with high impact next
- Consider dependencies between refactorings
- Balance effort vs. benefit
- Risk assessment guides implementation order

### Solution Design
- Provide specific, actionable solutions
- Show code examples when helpful
- Consider multiple approaches for complex issues
- Explain trade-offs clearly
- Estimate effort realistically

### Communication
- Be objective and factual
- Explain "why" not just "what"
- Support claims with evidence
- Use concrete examples
- Avoid blame or judgment

## Output Pattern

When refactoring report is complete, use minimal output pattern:

```
✓ Refactoring Analysis Complete
Artifact: /absolute/path/to/specs/{topic}/reports/NNN_refactoring_scope.md
Summary: Found [N] critical issues, [M] high-priority opportunities, total effort: [X-Y hours]
```

See `.claude/templates/output-patterns.md` for complete output standards.

## Notes

- Refactoring reports are gitignored by default (part of specs/reports/ structure)
- Reports guide implementation plan creation via `/plan` command
- Implementation status updated when refactoring work begins/completes
- Cross-references maintained by spec-updater agent
- Metrics help prioritize and schedule refactoring work
- Migration path ensures safe application of refactorings
