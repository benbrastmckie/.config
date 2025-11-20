# Template Usage Decision Tree

## Metadata
- **Purpose**: Fast decision guidance for inline vs reference
- **Scope**: All .claude/ command and agent development
- **Related**: [Template vs Behavioral Distinction](../architecture/template-vs-behavioral.md)

## Quick Decision Tree

```
Should this content be inline in command file?
│
├─ Is it STRUCTURAL? (Task syntax, bash blocks, schemas, checkpoints)
│  │
│  ├─ YES → ✓ INLINE in command file (structural template)
│  │         Examples: Task { }, bash execution, JSON schemas,
│  │                   MANDATORY VERIFICATION, CRITICAL warnings
│  │
│  └─ NO → Continue evaluation...
│
└─ Is it BEHAVIORAL? (STEP sequences, workflows, procedures)
   │
   ├─ YES → ✓ REFERENCE agent file (behavioral content)
   │         Examples: STEP 1/2/3, PRIMARY OBLIGATION,
   │                   agent verification, output formats
   │
   └─ NO → Ask: "If I change this, where do I update it?"
             │
             ├─ Multiple places → ✗ WRONG (should be referenced)
             │
             └─ Only here → Depends on context
                            (likely structural if truly unique)
```

## Common Scenarios Quick Reference

| Content Type | Inline? | Rationale | Example |
|--------------|---------|-----------|---------|
| **Task invocation structure** | YES | Structural execution | `Task { subagent_type, description, prompt }` |
| **Bash execution blocks** | YES | Command must execute | `**EXECUTE NOW**: bash code` |
| **Verification checkpoints** | YES | Orchestrator responsibility | `**MANDATORY VERIFICATION**: file check` |
| **JSON schemas** | YES | Data structure parsing | `{ "field": "value" }` |
| **Critical warnings** | YES | Execution-critical | `**CRITICAL**: error condition` |
| **Agent STEP sequences** | NO | Behavioral guidelines | Reference `.claude/agents/[name].md` |
| **File creation workflows** | NO | Agent procedures | Reference `.claude/agents/[name].md` |
| **PRIMARY OBLIGATION blocks** | NO | Agent behavioral | Reference `.claude/agents/[name].md` |
| **Output format templates** | NO | Agent responsibility | Reference `.claude/agents/[name].md` |
| **Agent verification steps** | NO | Agent self-checks | Reference `.claude/agents/[name].md` |

## Quick Test

**Question**: "If I change this content, where do I update it?"

### Answer Interpretation

**"Only in this command file"** → Likely structural template (inline OK)
- Verify it's truly execution-critical (Task syntax, bash, schemas, checkpoints)
- If it's agent procedures, it's WRONG (should be in agent file)

**"In multiple command files"** → WRONG! Should be in agent file (referenced)
- Extract to `.claude/agents/[name].md`
- Update commands to reference agent file with context injection

**"In the agent file"** → Behavioral content (must reference, not inline)
- Command should say: "Read and follow: .claude/agents/[name].md"
- Command injects context (parameters) only, not procedures

## Decision Examples

### Example 1: Task Invocation Block

**Content:**
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

**Question**: Should this be inline?

**Decision**: ✓ YES (structural template)

**Rationale**: Commands must parse this structure to invoke agents. This is command execution structure, not agent behavioral content.

---

### Example 2: STEP Sequence

**Content:**
```markdown
STEP 1: Analyze codebase patterns
STEP 2: Document findings in report
STEP 3: Verify file created
```

**Question**: Should this be inline?

**Decision**: ✓ NO (reference agent file)

**Rationale**: Agent behavioral guidelines belong in `.claude/agents/*.md` files. Commands reference agent files, inject context only.

---

### Example 3: Bash Execution Block

**Content:**
```bash
# EXECUTE NOW
source .claude/lib/artifact/artifact-creation.sh
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001" "")
```

**Question**: Should this be inline?

**Decision**: ✓ YES (structural template)

**Rationale**: Commands must execute these operations directly. This is orchestrator responsibility, not delegated to agents.

---

### Example 4: File Creation Workflow

**Content:**
```markdown
PRIMARY OBLIGATION: File creation workflow

1. Use Write tool to create file at provided path
2. Verify file exists with Read tool
3. Return file path in response
```

**Question**: Should this be inline?

**Decision**: ✓ NO (reference agent file)

**Rationale**: Agent internal workflow procedures belong in agent behavioral file. Commands provide the path (context), agent follows workflow.

---

### Example 5: Verification Checkpoint

**Content:**
```markdown
**MANDATORY VERIFICATION**: After agent completes, verify:
- Report file exists at $REPORT_PATH
- Report contains all required sections
- File is properly formatted markdown
```

**Question**: Should this be inline?

**Decision**: ✓ YES (structural template)

**Rationale**: Orchestrator (command) responsibility to verify agent completed successfully. This is command-level verification, not agent self-checks.

---

### Example 6: JSON Schema

**Content:**
```json
{
  "report_metadata": {
    "title": "string",
    "summary": "string (max 50 words)",
    "file_paths": ["string"]
  }
}
```

**Question**: Should this be inline?

**Decision**: ✓ YES (structural template)

**Rationale**: Commands must parse and validate data structures. Agent returns data matching this schema, command validates it.

---

### Example 7: Critical Warning

**Content:**
```markdown
**CRITICAL**: Never create empty directories. All directories must
contain at least a README.md file.
```

**Question**: Should this be inline?

**Decision**: ✓ YES (structural template)

**Rationale**: Execution-critical constraint that commands must enforce immediately. This is command-level requirement, not agent behavior.

---

### Example 8: Output Format Specification

**Content:**
```markdown
Agent MUST return results in the following format:

## Findings
- Finding 1
- Finding 2

## Recommendations
- Recommendation 1
```

**Question**: Should this be inline?

**Decision**: ✓ NO (reference agent file)

**Rationale**: Agent output format specifications belong in agent behavioral file. Agent is responsible for formatting output correctly.

---

### Example 9: PRIMARY OBLIGATION Block

**Content:**
```markdown
**PRIMARY OBLIGATION**: Your core responsibility is to create the
report file at the exact path provided before any other operations.
```

**Question**: Should this be inline?

**Decision**: ✓ NO (reference agent file)

**Rationale**: Agent behavioral guidelines belong in agent file. Commands reference agent file, inject the path (context parameter).

---

### Example 10: Agent Self-Verification Steps

**Content:**
```markdown
Before returning your response, YOU MUST:
1. Verify file exists using Read tool
2. Confirm file contains all sections
3. Report any discrepancies
```

**Question**: Should this be inline?

**Decision**: ✓ NO (reference agent file)

**Rationale**: Agent internal quality checks belong in agent behavioral file. This is agent self-verification, not orchestrator verification.

## Summary Flowchart

```
┌─────────────────────────────────────────┐
│ Is this about HOW the command executes? │
│ (Task blocks, bash, verification)       │
└─────────────┬───────────────────────────┘
              │
         YES  │  NO
              │
              ├─────────────────────────────┐
              │                             │
              ▼                             ▼
    ┌──────────────────┐      ┌─────────────────────────┐
    │ INLINE in        │      │ Is this about WHAT      │
    │ command file     │      │ agents should do?       │
    │                  │      │ (STEP sequences,        │
    │ (Structural      │      │  workflows)             │
    │  template)       │      └──────────┬──────────────┘
    └──────────────────┘                 │
                                    YES  │  NO
                                         │
                              ┌──────────┴──────────┐
                              │                     │
                              ▼                     ▼
                    ┌──────────────────┐  ┌─────────────────┐
                    │ REFERENCE agent  │  │ Ask: Multiple   │
                    │ file via         │  │ places to       │
                    │ behavioral       │  │ update?         │
                    │ injection        │  └────────┬────────┘
                    │                  │           │
                    │ (Behavioral      │      YES  │  NO
                    │  content)        │           │
                    └──────────────────┘           │
                                        ┌──────────┴─────────┐
                                        │                    │
                                        ▼                    ▼
                              ┌──────────────────┐  ┌───────────────┐
                              │ WRONG!           │  │ Context-      │
                              │ Extract to       │  │ dependent     │
                              │ agent file       │  │ (likely       │
                              └──────────────────┘  │  structural)  │
                                                    └───────────────┘
```

## Key Principles

1. **Structural templates** define HOW commands execute → Inline required
2. **Behavioral content** defines WHAT agents do → Reference agent files
3. **Single source of truth** for agent behavior → Agent files only
4. **Context injection** provides parameters → Commands inject, don't duplicate
5. **90% reduction** achievable through proper distinction → 150 lines → 15 lines

## When in Doubt

If uncertain whether content should be inline:

1. **Read** [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md)
2. **Check** if it's in the structural templates list (Task, bash, schemas, checkpoints, warnings)
3. **Ask** "Does the command need to parse/execute this directly?" (YES = inline)
4. **Default** to referencing agent file if it involves agent procedures
5. **Measure** expected reduction (if you don't get ~90% reduction per invocation, likely wrong)

## Related Documentation

- [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md) - Complete reference with all details
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - How to reference agent files correctly
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 12 enforcement criteria
- [Inline Template Duplication Troubleshooting](../troubleshooting/inline-template-duplication.md) - Fix duplication anti-pattern
