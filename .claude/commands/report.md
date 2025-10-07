---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task
argument-hint: <topic or question>
description: Research a topic and create a comprehensive report in the appropriate specs/reports/ directory
command-type: primary
dependent-commands: update, list
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

### 2. Location Determination and Registration
I'll determine the specs directory location using this process:

**Step 1: Detect Project Directory**
- Analyze the topic and search for relevant files
- Identify the deepest directory that encompasses all relevant content
- This becomes the "project directory" for this report

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

### 3. Report Numbering
I'll determine the report number by:
- Checking for existing reports in the target `specs/reports/` directory
- Finding the highest numbered report (e.g., `002_*.md`)
- Incrementing to the next number (e.g., `003`)
- Using `001` if no numbered reports exist
- Ensuring consistent three-digit format with leading zeros

### 4. Research Phase
I'll conduct thorough research by:
- **Code Analysis**: Examining relevant source files
- **Documentation Review**: Reading existing docs and comments
- **Pattern Recognition**: Identifying implementation patterns and architectures
- **Dependency Mapping**: Understanding relationships between components
- **Web Research** (if needed): Gathering external context and best practices

### 5. Report Structure
The report will include:
- **Executive Summary**: Brief overview of findings
- **Background**: Context and problem space
- **Current State Analysis**: How things currently work
- **Key Findings**: Important discoveries and insights
- **Technical Details**: In-depth technical analysis
- **Recommendations**: Suggested improvements or next steps
- **References**: Links to relevant files and resources

### 6. Report Creation
I'll create the report as a markdown file with automatic numbering:

#### Numbering System
- Format: `NNN_topic_name.md` where NNN is a three-digit number
- I'll find the highest numbered report in the target directory
- The new report will use the next sequential number (e.g., 001, 002, 003...)
- If no reports exist, start with 001
- Example: `003_terminal_compatibility_analysis.md`

#### File Creation
- Located in `[relevant-dir]/specs/reports/NNN_[topic-name].md`
- Topic name will be converted to lowercase with underscores
- Following professional documentation standards
- Including diagrams and code examples where helpful
- Cross-referencing relevant files with precise locations

### 7. Report Metadata
Each report will include:
- **Specs Directory**: Path to the specs/ directory (for consistency with related plans/summaries)
- **Report Number**: Three-digit number within this specs directory
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
- **Specs Directory**: [path/to/specs/]
- **Report Number**: [NNN]
- **Scope**: [Description of research scope]
- **Primary Directory**: [Location of report]
- **Files Analyzed**: [Count and key files]

## Executive Summary
[Brief overview of findings]

## Analysis
[Detailed research findings]

## Recommendations
[Actionable insights and suggestions]

## Implementation Status
- **Status**: Research Complete
- **Plan**: None yet
- **Implementation**: Not started
- **Date**: [YYYY-MM-DD]

*This section will be updated if/when recommendations are implemented.*

## References
[Links to relevant files and resources]
```

## Agent Usage

This command can optionally delegate research to the `research-specialist` agent:

### research-specialist Agent (Optional)
- **Purpose**: Focused codebase analysis and best practices research
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **When Used**: For complex topics requiring systematic investigation
- **Output**: Concise research summaries (max 200 words)

### Current Implementation
The `/report` command typically executes research directly for optimal context management and report generation. Agent delegation is beneficial for `/orchestrate` workflows where multiple research topics are investigated in parallel.

### Potential Agent Integration Pattern
For complex, multi-faceted topics:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [specific aspect] of [topic] using research-specialist protocol"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/research-specialist.md

          You are acting as a Research Specialist with the tools and constraints
          defined in that file.

          Research Task: [Aspect] investigation

          Context:
          - Topic: [User's topic]
          - Focus Area: [Specific aspect to research]
          - Project Standards: CLAUDE.md

          Investigation:
          1. Codebase Analysis
             - Search for existing implementations
             - Identify patterns and conventions
             - Note relevant file locations

          2. Best Practices Research
             - Industry standards (2025)
             - Framework-specific recommendations
             - Trade-offs and considerations

          Output: Max 150-word summary with:
          - Key findings
          - Existing patterns
          - Recommendations
          - File references
  "
}
```

### When to Use Agents
- **Use Agent**: When `/orchestrate` invokes `/report` as part of larger workflow
- **Direct Execution**: When user directly invokes `/report` for single-topic investigation

### Benefits of Direct Execution
- **Comprehensive Reports**: Full context for detailed analysis
- **Integrated Writing**: Seamless report generation
- **Flexible Structure**: Adapt report format to topic needs
- **Complete Control**: Fine-grained control over research depth

Let me begin researching your topic and determining the best location for the report.
