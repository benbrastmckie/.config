# Hierarchical Agent Architecture: Communication

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Coordination](hierarchical-agents-coordination.md) - Multi-agent coordination
- [Patterns](hierarchical-agents-patterns.md) - Design patterns

---

## Agent Communication Protocols

### Request Format

Standard format for invoking subordinate agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Brief task description"
  prompt: |
    Read and follow: .claude/agents/[agent-type].md

    **Task Context**:
    - Primary Goal: [specific objective]
    - Output Path: [absolute path]
    - Input Resources: [paths to input files]

    **Constraints**:
    - Time Budget: [estimated tokens]
    - Thinking Mode: [standard/think/think hard]

    **Expected Output**:
    Return: [SIGNAL_NAME]: [value]
}
```

### Response Format

Standard format for agent responses:

```
SIGNAL: VALUE
SIGNAL: VALUE
...

[Optional verbose output]
```

**Example**:
```
CREATED: /home/benjamin/.config/.claude/specs/042_auth/reports/001_patterns.md
TITLE: Authentication Patterns Analysis
SUMMARY: Analyzed 12 existing patterns, recommending JWT with refresh tokens
STATUS: complete
```

### Signal Types

| Signal | Purpose | Example |
|--------|---------|---------|
| `CREATED` | File creation confirmation | `CREATED: /path/to/file.md` |
| `TITLE` | Output title/name | `TITLE: Authentication Report` |
| `SUMMARY` | Brief summary (200 chars) | `SUMMARY: Key findings...` |
| `STATUS` | Completion status | `STATUS: complete` |
| `ERROR` | Error description | `ERROR: Failed to access URL` |
| `COUNT` | Numeric count | `COUNT: 15` |

## Behavioral Injection Protocol

### Pattern

Inject behavior through file reference + context:

```markdown
**Agent Behavioral File** (.claude/agents/research-specialist.md):
Contains:
- Role definition
- STEP sequences
- Output format requirements
- Quality criteria

**Command Invocation**:
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Topic: [specific topic]
    - Output: [specific path]
}
```

### Benefits

1. **No Duplication**: Behavior defined once
2. **Easy Updates**: Change agent file, all invocations updated
3. **Context Efficiency**: Inject only workflow-specific data
4. **Clear Separation**: Behavior vs context clearly separated

### Anti-Pattern: Inline Behavioral Duplication

```yaml
# WRONG: Duplicating behavior inline
Task {
  prompt: |
    You are a research specialist.
    You MUST create files at specified paths.
    Your steps are:
    1. Analyze topic
    2. Search codebase
    3. Create report
    ...
    [200+ lines duplicated from agent file]
}
```

## Metadata Extraction

### Purpose

Extract summary information to reduce context overhead when passing results up the hierarchy.

### Pattern

```bash
extract_metadata() {
  local agent_output="$1"

  # Parse standard signals
  CREATED=$(echo "$agent_output" | grep -oP 'CREATED:\s*\K.+')
  TITLE=$(echo "$agent_output" | grep -oP 'TITLE:\s*\K.+')
  SUMMARY=$(echo "$agent_output" | grep -oP 'SUMMARY:\s*\K.+')

  # Return as JSON
  jq -n \
    --arg path "$CREATED" \
    --arg title "$TITLE" \
    --arg summary "$SUMMARY" \
    '{path: $path, title: $title, summary: $summary}'
}
```

### Context Reduction Example

```
Worker Output: 2,500 tokens
  - Full report content
  - Research findings
  - Code examples
  - References

Extracted Metadata: 110 tokens
  - Path: /path/to/report.md
  - Title: Authentication Patterns
  - Summary: Found 12 patterns...

Reduction: 95.6%
```

## Structured Output Formats

### JSON Output

For machine-readable results:

```json
{
  "status": "complete",
  "artifacts": [
    {
      "path": "/path/to/report1.md",
      "type": "research_report",
      "title": "Authentication Patterns",
      "summary": "Analyzed 12 patterns..."
    },
    {
      "path": "/path/to/report2.md",
      "type": "research_report",
      "title": "Logging Patterns",
      "summary": "Found 8 logging..."
    }
  ],
  "metrics": {
    "files_analyzed": 45,
    "time_elapsed": "2.3s"
  }
}
```

### Table Output

For human-readable summaries:

```
| Topic | Status | Path | Summary |
|-------|--------|------|---------|
| Auth | done | /path/auth.md | Found 12 patterns... |
| Logging | done | /path/log.md | Found 8 patterns... |
```

## Error Communication

### Error Reporting Format

```
ERROR: [Category] - [Description]
CONTEXT: [Relevant context]
RECOVERY: [Suggested action]
```

**Example**:
```
ERROR: FILE_NOT_FOUND - Cannot read input plan at /path/to/plan.md
CONTEXT: Phase 2 of implementation workflow
RECOVERY: Verify plan exists and path is correct
```

### Error Categories

| Category | Description | Example |
|----------|-------------|---------|
| `FILE_NOT_FOUND` | Missing required file | Plan file doesn't exist |
| `PARSE_ERROR` | Cannot parse input | Invalid JSON/YAML |
| `NETWORK_ERROR` | External resource failure | WebSearch timeout |
| `VALIDATION` | Output doesn't meet requirements | Missing required section |
| `TIMEOUT` | Operation exceeded time limit | Agent took too long |

## Progress Reporting

### Progress Signals

```
PROGRESS: [Phase] - [Status]
```

**Examples**:
```
PROGRESS: Research - Starting codebase analysis
PROGRESS: Research - Analyzed 15/30 files
PROGRESS: Research - Completing external research
PROGRESS: Research - Creating report
```

### Checkpoint Signals

```
CHECKPOINT: [Phase] complete
- Artifacts: [count]
- Status: [summary]
```

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Coordination](hierarchical-agents-coordination.md)
- [Examples](hierarchical-agents-examples.md)
- [Troubleshooting](hierarchical-agents-troubleshooting.md)
