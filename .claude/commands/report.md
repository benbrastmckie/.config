---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task
argument-hint: <topic or question>
description: Research a topic and create a comprehensive report in the appropriate specs/reports/ directory
---

# Generate Research Report

I'll research the specified topic and create a comprehensive report in the most appropriate location.

## Topic/Question
$ARGUMENTS

## Process

### 1. Topic Analysis
First, I'll analyze the topic to determine:
- Key concepts and scope
- Relevant files and directories in the codebase
- Most appropriate location for the specs/reports/ directory

### 2. Location Determination
I'll find the deepest directory that encompasses all relevant files by:
- Searching for files related to the topic
- Identifying common parent directories
- Selecting the most specific directory that includes all relevant content

### 3. Research Phase
I'll conduct thorough research by:
- **Code Analysis**: Examining relevant source files
- **Documentation Review**: Reading existing docs and comments
- **Pattern Recognition**: Identifying implementation patterns and architectures
- **Dependency Mapping**: Understanding relationships between components
- **Web Research** (if needed): Gathering external context and best practices

### 4. Report Structure
The report will include:
- **Executive Summary**: Brief overview of findings
- **Background**: Context and problem space
- **Current State Analysis**: How things currently work
- **Key Findings**: Important discoveries and insights
- **Technical Details**: In-depth technical analysis
- **Recommendations**: Suggested improvements or next steps
- **References**: Links to relevant files and resources

### 5. Report Creation
I'll create the report as a markdown file:
- Located in `[relevant-dir]/specs/reports/[topic-name]-[date].md`
- Following professional documentation standards
- Including diagrams and code examples where helpful
- Cross-referencing relevant files with precise locations

### 6. Report Metadata
Each report will include:
- Creation date and time
- Research scope and boundaries
- Files analyzed
- Search queries used
- Time investment estimate

## Output Format

The report will be formatted as:

```markdown
# [Topic] Research Report

## Metadata
- **Date**: [YYYY-MM-DD]
- **Scope**: [Description of research scope]
- **Primary Directory**: [Location of report]
- **Files Analyzed**: [Count and key files]

## Executive Summary
[Brief overview of findings]

## Analysis
[Detailed research findings]

## Recommendations
[Actionable insights and suggestions]

## References
[Links to relevant files and resources]
```

Let me begin researching your topic and determining the best location for the report.