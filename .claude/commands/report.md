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

### 4. Spec-Updater Agent Invocation

**IMPORTANT**: After the report file is created and written, invoke the spec-updater agent to update cross-references and link the report to related plans.

This step ensures the report is properly integrated into the topic structure and cross-referenced with related artifacts.

#### Step 4.1: Invoke Spec-Updater Agent

Use the Task tool to invoke the spec-updater agent:

```
Task tool invocation:
subagent_type: general-purpose
description: "Update cross-references for new report"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/spec-updater.md

  You are acting as a Spec Updater Agent.

  Context:
  - Report created at: {report_path}
  - Topic directory: {topic_dir}
  - Related plan (if exists): {plan_path}
  - Operation: report_creation

  Tasks:
  1. Check if a plan exists in the topic's plans/ subdirectory

  2. If related plan exists:
     - Add report reference to plan metadata
     - Update plan's "Research Reports" section
     - Use relative path (e.g., ../reports/NNN_report.md)

  3. If no plan exists yet:
     - Note that report is standalone research
     - Report can be referenced when plan is created later

  4. Validate cross-references are bidirectional:
     - Report includes link to plan (if applicable)
     - Plan includes link to report (if applicable)

  5. Verify topic subdirectories are present

  Return:
  - Cross-reference update status
  - Plan files modified (if any)
  - Confirmation that report is ready for use
  - Any warnings or issues encountered
```

#### Step 4.2: Handle Spec-Updater Response

After spec-updater completes:
- Display cross-reference status to user
- If plan was updated: Show which plan file was modified
- If warnings/issues: Show them and suggest fixes
- If successful: Confirm report is ready

**Example Output**:
```
Cross-references updated:
✓ Report linked to plan: specs/042_auth/plans/001_implementation.md
✓ Plan metadata updated with report reference
✓ All links validated
```

or if no plan exists:

```
Report created successfully:
✓ Standalone research report (no plan yet)
✓ Report will be available for future plan creation
✓ Topic structure verified
```

### 5. Research Phase
I'll conduct thorough research by:
- **Code Analysis**: Examining relevant source files
- **Documentation Review**: Reading existing docs and comments
- **Pattern Recognition**: Identifying implementation patterns and architectures
- **Dependency Mapping**: Understanding relationships between components
- **Web Research** (if needed): Gathering external context and best practices

### 6. Report Structure

Reports follow the standard structure defined in `.claude/templates/report-structure.md`.

Key sections include:
- **Executive Summary**: Brief overview of findings
- **Background**: Context and problem space
- **Analysis**: Detailed research findings organized by area
- **Technical Details**: Implementation patterns, dependencies, constraints
- **Recommendations**: Prioritized actionable suggestions
- **Implementation Status**: Tracking for when recommendations are implemented
- **References**: Links to relevant files and resources

### 7. Report Metadata

Each report includes standardized metadata:
- **Topic Directory**: Path to the topic directory (e.g., `specs/042_authentication/`)
- **Report Number**: Three-digit number within this topic's reports/ subdirectory
- Creation date, research scope, files analyzed

**Path Format**: `specs/{NNN_topic}/reports/NNN_report_name.md`

For complete report structure and section guidelines, see `.claude/templates/report-structure.md`

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
