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

### 2. Topic-Based Location Determination
I'll determine the topic directory location using the uniform structure:

**Step 1: Source Required Utilities**
```bash
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
```

**Step 2: Determine Topic from Research Question**
- Analyze the research topic/question
- Extract key concepts for topic naming
- Search for existing topic directories that match
- If found: Use existing topic directory
- If not found: Create new topic directory using `get_or_create_topic_dir()`

**Step 3: Get or Create Topic Directory**
```bash
# Extract topic from research question
TOPIC_DESC=$(extract_topic_from_question "$RESEARCH_TOPIC")

# Check for existing topics that match
EXISTING_TOPIC=$(find_matching_topic "$TOPIC_DESC")

if [ -n "$EXISTING_TOPIC" ]; then
  TOPIC_DIR="$EXISTING_TOPIC"
else
  # Create new topic directory
  TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC_DESC" "specs")
  # Creates: specs/{NNN_topic}/ with subdirectories
fi
```

**Step 4: Verify Topic Structure**
- Ensure topic directory has all standard subdirectories:
  - `reports/` - Research reports
  - `plans/` - Implementation plans
  - `summaries/` - Implementation summaries
  - `debug/` - Debug reports
  - Other subdirectories as needed

### 3. Report Creation Using Uniform Structure
I'll create the report using `create_topic_artifact()`:

**Step 1: Get Next Report Number Within Topic**
```bash
# Get next number in topic's reports/ subdirectory
NEXT_NUM=$(get_next_artifact_number "${TOPIC_DIR}/reports")
```

**Step 2: Generate Report Name**
- Convert research topic to snake_case (e.g., "API Patterns" → "api_patterns")
- Truncate to reasonable length (50 chars)

**Step 3: Create Report File**
```bash
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$REPORT_NAME" "$REPORT_CONTENT")
# Creates: ${TOPIC_DIR}/reports/NNN_report_name.md
# Auto-numbers, registers in artifact registry
```

**Benefits of Uniform Structure**:
- All artifacts for a topic in one directory
- Easy to find related plans, reports, summaries
- Consistent numbering within topic
- Automatic subdirectory creation
- Single utility manages all artifact creation

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

### 6. Report Metadata
Each report will include:
- **Topic Directory**: Path to the topic directory (e.g., `specs/042_authentication/`)
- **Report Number**: Three-digit number within this topic's reports/ subdirectory
- Creation date and time
- Research scope and boundaries
- Files analyzed
- Search queries used
- Time investment estimate

**Path Format**:
- Located in `specs/{NNN_topic}/reports/NNN_report_name.md`
- Topic: `{NNN_topic}` = three-digit numbered topic (e.g., `042_authentication`)
- Report name converted to lowercase with underscores
- Following professional documentation standards
- Including diagrams and code examples where helpful
- Cross-referencing relevant files with precise locations

## Output Format

The report will be formatted as:

```markdown
# [Topic] Research Report

## Metadata
- **Date**: [YYYY-MM-DD]
- **Topic Directory**: [specs/{NNN_topic}/ or .claude/specs/{NNN_topic}/]
- **Report Number**: [NNN] (within topic)
- **Scope**: [Description of research scope]
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
