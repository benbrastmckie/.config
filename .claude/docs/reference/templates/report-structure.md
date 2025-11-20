# Research Report Template

This template defines the standard structure for research reports created by the `/report` command.

## File Location

Reports are created in the topic-based directory structure:
```
specs/{NNN_topic}/reports/NNN_report_name.md
```

Where:
- `{NNN_topic}`: Three-digit numbered topic directory (e.g., `042_authentication`)
- `NNN`: Next sequential number within the topic's `reports/` subdirectory
- `report_name`: Snake_case conversion of the research topic

## Standard Report Structure

```markdown
# [Topic] Research Report

## Metadata
- **Date**: [YYYY-MM-DD]
- **Topic Directory**: [specs/{NNN_topic}/ or .claude/specs/{NNN_topic}/]
- **Report Number**: [NNN] (within topic)
- **Scope**: [Description of research scope]
- **Files Analyzed**: [Count and key files]

## Executive Summary
[Brief overview of findings - 2-3 paragraphs maximum]

Key Points:
- [Major finding 1]
- [Major finding 2]
- [Major finding 3]

## Background
[Context and problem space - explains why this research was needed]

### Current State
[How things currently work or the current situation]

### Research Questions
1. [Question 1]
2. [Question 2]
3. [Question 3]

## Analysis

### [Analysis Area 1]
[Detailed findings for first major area]

#### Key Findings
- [Finding 1]
- [Finding 2]

#### Evidence
[Code examples, file references, data]

### [Analysis Area 2]
[Detailed findings for second major area]

#### Key Findings
- [Finding 1]
- [Finding 2]

#### Evidence
[Code examples, file references, data]

### [Additional Analysis Areas as Needed]

## Technical Details

### Implementation Patterns
[Patterns discovered in the codebase]

### Dependencies
[Module dependencies, external dependencies]

### Constraints
[Technical constraints, limitations]

### Trade-offs
[Design trade-offs identified]

## Recommendations

### High Priority
1. [Recommendation 1 with rationale]
2. [Recommendation 2 with rationale]

### Medium Priority
1. [Recommendation 1 with rationale]

### Future Considerations
1. [Long-term consideration 1]

## Implementation Considerations

### Approach Options
**Option 1: [Name]**
- Pros: [List]
- Cons: [List]
- Effort: [Estimate]

**Option 2: [Name]**
- Pros: [List]
- Cons: [List]
- Effort: [Estimate]

### Recommended Approach
[Which option and why]

### Prerequisites
[What needs to be in place first]

### Risks
[Potential risks and mitigation strategies]

## Implementation Status
- **Status**: Research Complete
- **Plan**: None yet | [Link to related plan]
- **Implementation**: Not started | In Progress | Complete
- **Date**: [YYYY-MM-DD]

*This section will be updated if/when recommendations are implemented.*

## References

### Codebase Files
- [file1.ext](relative/path/to/file1.ext) - [Brief description]
- [file2.ext](relative/path/to/file2.ext) - [Brief description]

### Documentation
- [doc1.md](relative/path/to/doc1.md) - [Brief description]

### External Resources
- [Resource title](https://url) - [Brief description]

### Related Artifacts
- Plan: [../plans/NNN_plan.md](../plans/NNN_plan.md) (if exists)
- Debug reports: [../debug/NNN_debug.md](../debug/NNN_debug.md) (if exists)
```

## Section Guidelines

### Executive Summary
- 2-3 paragraphs maximum
- Bullet list of 3-5 key findings
- Should stand alone if reader only reads this section

### Background
- Provides context for why research was needed
- Describes current state or situation
- Lists specific research questions addressed

### Analysis
- Divided into logical areas or themes
- Each area has findings and supporting evidence
- Use code examples, file references, diagrams
- Be specific with file paths and line numbers

### Technical Details
- In-depth technical information
- Implementation patterns discovered
- Dependencies and constraints
- Design trade-offs

### Recommendations
- Prioritized (High/Medium/Future)
- Actionable and specific
- Include rationale for each
- Link to implementation considerations

### Implementation Considerations
- Multiple approach options with pros/cons
- Recommended approach with justification
- Prerequisites and risks identified
- Effort estimates provided

### Implementation Status
- Tracks lifecycle of recommendations
- Updated by spec-updater agent when plan created
- Updated when implementation begins/completes
- Maintains history without removing old status

### References
- Organized by type (codebase, docs, external)
- Use relative paths for internal references
- Include brief description for each link
- Cross-reference related artifacts in same topic

## Best Practices

### Writing Style
- Present tense for current state
- Clear, concise language
- Technical but accessible
- No historical commentary (see CLAUDE.md Development Philosophy)

### Code Examples
- Include relevant context (surrounding lines)
- Show file path and approximate line numbers
- Use syntax highlighting
- Keep examples focused and minimal

### File References
- Always use relative paths from report location
- Include brief description of file's purpose
- Link to specific sections when relevant
- Note file size for large files

### Evidence
- Support claims with concrete examples
- Reference specific files and line numbers
- Include relevant data or metrics
- Show patterns across multiple files

### Recommendations
- Start with action verb (Add, Remove, Refactor, etc.)
- Explain the "why" not just the "what"
- Consider implementation difficulty
- Balance ideal vs. practical solutions

## Cross-Referencing

### Within Topic
Use relative paths for artifacts in the same topic:
- Plans: `../plans/NNN_plan.md`
- Debug reports: `../debug/NNN_debug.md`
- Other reports: `./NNN_other_report.md` or `NNN_other_report.md`
- Summaries: `../summaries/NNN_summary.md`

### Across Topics
Use relative paths from current topic to other topics:
- Other topic report: `../../{other_topic}/reports/NNN_report.md`
- Other topic plan: `../../{other_topic}/plans/NNN_plan.md`

### External Files
Use relative paths from report to codebase:
- Source files: `../../../path/to/file.ext`
- Documentation: `../../../docs/document.md`

## Integration with Commands

### /report Command
Creates reports using this structure automatically.

### /plan Command
References reports in plan metadata:
```yaml
Research Reports:
  - ../reports/001_report_name.md
  - ../reports/002_other_report.md
```

### /implement Command
Updates Implementation Status section when work begins/completes.

### spec-updater Agent
- Creates bidirectional links between reports and plans
- Updates Implementation Status
- Maintains cross-references within topic

## Metadata Fields

### Required Fields
- **Date**: Report creation date (YYYY-MM-DD format)
- **Topic Directory**: Full path to topic directory
- **Report Number**: Three-digit number within topic
- **Scope**: Brief description of research scope

### Optional Fields
- **Files Analyzed**: Count and key files (helpful for scope understanding)
- **Time Investment**: Estimate of research hours
- **Research Method**: Techniques used (code analysis, web research, etc.)
- **Confidence Level**: High/Medium/Low for recommendations

## Output Pattern

When report is complete, use minimal output pattern:

```
✓ Report Complete
Artifact: /absolute/path/to/specs/{topic}/reports/NNN_report.md
Summary: [1-2 line summary of key findings]
```

See `.claude/templates/output-patterns.md` for complete output standards.

## Notes

- Research reports are gitignored by default (part of specs/reports/ structure)
- Debug reports in specs/{topic}/debug/ are NOT gitignored (committed to git)
- Reports maintain "living document" status - updated when implementation occurs
- Implementation Status section preserves history without removing old information
- Cross-references are bidirectional and maintained by spec-updater agent
