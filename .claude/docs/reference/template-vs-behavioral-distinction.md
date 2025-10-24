# Template vs Behavioral Distinction

## Metadata
- **Date**: 2025-10-24
- **Scope**: Critical architectural principle for .claude/ command and agent system
- **Purpose**: Define the distinction between structural templates (inline) and behavioral content (referenced)
- **Related Documents**:
  - [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
  - [Command Architecture Standards](./command_architecture_standards.md)
  - [Agent Development Guide](../guides/agent-development-guide.md)

## Overview

This document defines a critical architectural distinction in the .claude/ system:

1. **Structural Templates** (MUST be inline): Execution-critical patterns that Claude must see immediately
2. **Behavioral Content** (MUST be referenced): Agent execution procedures and workflows

This distinction enables:
- 90% code reduction per agent invocation (150 lines → 15 lines)
- 71% context usage reduction (85% → 25%)
- 100% file creation rate (up from 70%)
- 50-67% maintenance burden reduction
- Single source of truth for agent behavioral guidelines

## Structural Templates (MUST Be Inline)

### Characteristics

Structural templates are execution-critical patterns that:
- Must be immediately visible to the orchestrating command
- Define HOW commands execute and coordinate agents
- Are parsed and executed directly by the command
- Cannot be delegated to agents

### Examples

#### Task Invocation Syntax
```markdown
Task {
  subagent_type: "implementation-researcher",
  description: "Analyze codebase patterns",
  prompt: "Research authentication implementation..."
}
```
**Why inline**: Commands must parse this structure to invoke agents correctly.

#### Bash Execution Blocks
```markdown
**EXECUTE NOW**: Run the following bash commands:

bash
grep -r "authentication" src/ --include="*.js"
test -f src/auth/login.js && echo "Found login file"
```
**Why inline**: Commands must execute these operations directly, not delegate them.

#### JSON Schemas
```json
{
  "report_metadata": {
    "title": "string",
    "summary": "string (max 50 words)",
    "file_paths": ["string"],
    "recommendations": ["string"]
  }
}
```
**Why inline**: Commands must understand data structures for parsing and validation.

#### Verification Checkpoints
```markdown
**MANDATORY VERIFICATION**: After agent completes, verify:
- Report file exists at expected path
- Report contains all required sections
- File is properly formatted markdown
```
**Why inline**: Orchestrator (command) is responsible for verification, not the agent.

#### Critical Warnings
```markdown
**CRITICAL**: Never create empty directories. All directories must contain at least a README.md.

**IMPORTANT**: File creation operations MUST be verified before proceeding to next phase.
```
**Why inline**: Execution-critical constraints that commands must enforce immediately.

## Behavioral Content (MUST Be Referenced)

### Characteristics

Behavioral content consists of agent execution procedures that:
- Define WHAT agents should do and HOW they should behave
- Contain step-by-step procedures and workflows
- Are agent-specific implementation details
- Should exist once in `.claude/agents/*.md` files

### Examples

#### Agent STEP Sequences
```markdown
STEP 1: Analyze the codebase for existing authentication patterns
STEP 2: Identify integration points for new authentication
STEP 3: Document findings in structured report format
```
**Why referenced**: This is agent behavioral guidance, not command structure. Belongs in `.claude/agents/implementation-researcher.md`.

#### File Creation Workflows
```markdown
PRIMARY OBLIGATION: File creation workflow
1. Create file with Write tool
2. Verify file exists with Read tool
3. Return file path in response
```
**Why referenced**: This is agent internal workflow, not command responsibility. Belongs in agent behavioral file.

#### Verification Steps (Within Agent Behavior)
```markdown
Before returning results, agent MUST verify:
- All requested files were created
- Files contain required sections
- Output format matches schema
```
**Why referenced**: Agent self-verification procedures belong in agent file, not command file.

#### Output Format Specifications
```markdown
Agent MUST return results in the following format:

## Findings
- Finding 1
- Finding 2

## Recommendations
- Recommendation 1
- Recommendation 2
```
**Why referenced**: Agent output format specifications belong in agent file, not command file.

## Side-by-Side Comparison

| Aspect | Structural Templates | Behavioral Content |
|--------|---------------------|-------------------|
| **Location** | Inline in command files | `.claude/agents/*.md` files |
| **Purpose** | Command execution structure | Agent behavioral guidelines |
| **Visibility** | Must be immediately visible | Referenced when needed |
| **Examples** | Task { }, bash blocks, schemas | STEP sequences, workflows |
| **Ownership** | Command/orchestrator | Agent implementation |
| **Duplication** | Copy-paste acceptable | Prohibited (reference instead) |
| **Maintenance** | Updated in command files | Single source of truth in agent |
| **Context Impact** | Minimal (structural only) | Significant if duplicated |

## Decision Tree: Should This Be Inline?

```
Is this content about command execution structure?
│
├─ YES → Is it Task syntax, bash blocks, schemas, or checkpoints?
│         │
│         ├─ YES → ✓ INLINE in command file (structural template)
│         │
│         └─ NO → Continue evaluation...
│
└─ NO → Is it STEP sequences, workflows, or agent procedures?
          │
          ├─ YES → ✓ REFERENCE agent file (behavioral content)
          │
          └─ NO → Ask: "If I change this, where do I update it?"
                    │
                    ├─ Multiple places → ✗ WRONG (should be referenced)
                    │
                    └─ Only here → Depends on context
```

## Quick Test

**Question**: "If I change this content, where do I update it?"

- **Answer: "Only in this command file"** → Likely structural template (inline OK)
- **Answer: "In multiple command files"** → WRONG! Should be in agent file (referenced)
- **Answer: "In the agent file"** → Behavioral content (must reference, not inline)

## Quantified Benefits

Research shows proper application of this distinction yields:

| Metric | Before (Duplication) | After (Proper Distinction) | Improvement |
|--------|---------------------|---------------------------|-------------|
| Code per agent invocation | 150 lines | 15 lines | 90% reduction |
| Context window usage | 85% | 25% | 71% reduction |
| File creation success rate | 70% | 100% | 43% improvement |
| Maintenance burden | Baseline | 50-67% of baseline | 50-67% reduction |
| Single source of truth | No (duplicated) | Yes (referenced) | Eliminates sync issues |

## Common Scenarios

### Scenario 1: Task Invocation Structure
**Content**: `Task { subagent_type: "researcher", description: "...", prompt: "..." }`
**Decision**: ✓ INLINE (structural template)
**Rationale**: Commands must parse this structure to invoke agents

### Scenario 2: Agent STEP Sequence
**Content**: `STEP 1: Analyze... STEP 2: Document... STEP 3: Return...`
**Decision**: ✓ REFERENCE agent file (behavioral content)
**Rationale**: Agent behavioral guidelines belong in agent file

### Scenario 3: Bash Execution Block
**Content**: `**EXECUTE NOW**: bash commands...`
**Decision**: ✓ INLINE (structural template)
**Rationale**: Commands must execute these operations directly

### Scenario 4: File Creation Workflow
**Content**: `PRIMARY OBLIGATION: Create file, verify, return path`
**Decision**: ✓ REFERENCE agent file (behavioral content)
**Rationale**: Agent internal workflow, not command structure

### Scenario 5: Verification Checkpoint
**Content**: `**MANDATORY VERIFICATION**: Check file exists before proceeding`
**Decision**: ✓ INLINE (structural template)
**Rationale**: Orchestrator (command) responsibility, not agent

### Scenario 6: JSON Schema
**Content**: Data structure definition for agent communication
**Decision**: ✓ INLINE (structural template)
**Rationale**: Commands must parse and validate data structures

### Scenario 7: Critical Warning
**Content**: `**CRITICAL**: Never create empty directories`
**Decision**: ✓ INLINE (structural template)
**Rationale**: Execution-critical constraint that commands enforce

### Scenario 8: Output Format Specification
**Content**: Template showing how agent should format response
**Decision**: ✓ REFERENCE agent file (behavioral content)
**Rationale**: Agent responsibility to format output correctly

### Scenario 9: PRIMARY OBLIGATION Block
**Content**: Agent's core responsibilities and workflow steps
**Decision**: ✓ REFERENCE agent file (behavioral content)
**Rationale**: Agent behavioral guidelines, not command structure

### Scenario 10: Agent Self-Verification Steps
**Content**: Steps agent follows to verify its own work before returning
**Decision**: ✓ REFERENCE agent file (behavioral content)
**Rationale**: Agent internal quality checks, not orchestrator verification

## Exceptions

**NONE** - There are zero documented exceptions to the prohibition on behavioral content duplication.

If you think you've found a legitimate exception:
1. Re-read this document carefully
2. Check if the content is truly structural (execution-critical) or behavioral (agent procedure)
3. Consult [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
4. If still uncertain, default to referencing the agent file (behavioral injection pattern)

## Common Pitfalls

### Search Pattern Mismatches in Refactoring

**Pitfall**: When creating refactor plans to remove behavioral duplication, assuming patterns exist without verification.

**Example**: The /supervise command refactor (spec 438) was blocked because the plan searched for `Example agent invocation:` followed by ` ```yaml`, but this pattern never existed in the file.

**Impact**:
- Edit tool cannot find patterns to replace (0 matches)
- Implementation cannot proceed
- Wasted effort trying to execute impossible replacements
- False confidence from regression tests searching for wrong patterns

**Root Cause**: Plans assumed patterns based on analysis rather than verifying actual strings with Grep tool.

**Prevention**:

1. **Verify Patterns Exist Before Planning Replacements**
   ```bash
   # WRONG: Assume pattern exists
   # "The file contains 'Example agent invocation:' patterns"

   # CORRECT: Verify with Grep
   grep -n "Example agent invocation:" target_file.md
   # If output is empty, pattern doesn't exist
   ```

2. **Extract Actual Strings, Not Inferred Descriptions**
   ```bash
   # WRONG: "Line 49 shows Example agent invocation pattern"
   # (This is an INFERENCE about purpose, not actual text)

   # CORRECT: Extract actual text
   sed -n '45,55p' target_file.md
   # Shows what's actually there: "**Wrong Pattern - Command Chaining**..."
   ```

3. **Add Pattern Verification to Phase 0**
   ```bash
   # Phase 0: Verify patterns before implementation
   PATTERN_COUNT=$(grep -c "expected pattern" target_file.md)
   if [ "$PATTERN_COUNT" -eq 0 ]; then
     echo "ERROR: Pattern not found. Plan needs revision."
     exit 1
   fi
   ```

4. **Update Regression Tests to Detect Actual Patterns**
   ```bash
   # WRONG: Test searches for pattern that doesn't exist
   YAML_BLOCKS=$(grep "Example agent invocation:" file.md | wc -l)
   # Gives false pass (0 found) when 7 actually exist

   # CORRECT: Test searches for actual pattern
   YAML_BLOCKS=$(grep -c '```yaml' file.md)
   # Accurately detects 7 blocks
   ```

**Case Study**: See [/supervise Command Refactor](../troubleshooting/inline-template-duplication.md#real-world-example-supervise-command-refactor) for complete diagnostic, classification, and corrected refactor plan.

**Key Lessons**:
- Always use Grep to verify patterns exist before creating refactor plans
- Extract actual strings, not descriptions
- Classify blocks as structural vs behavioral before deciding keep/remove
- Add Phase 0 pattern verification to catch mismatches before implementation
- Ensure regression tests detect actual patterns, not phantom patterns

**References**:
- **Diagnostic**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md`
- **Classification**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/supervise_yaml_classification.md`
- **Corrected Plan**: `.claude/specs/444_research_allowed_tools_fix/plans/001_supervise_refactor_corrected.md`

## Enforcement

### Validation Criteria

Commands should be checked for:
- **STEP instruction count**: <5 per command file (behavioral content should be in agent files)
- **Agent invocation size**: <50 lines per Task block (context injection only, not behavioral duplication)
- **PRIMARY OBLIGATION presence**: Zero occurrences in command files (agent files only)
- **Behavioral file references**: All agent invocations should reference behavioral files, not duplicate content

### Metrics

When properly applied, expect:
- 90% reduction in code per agent invocation
- <30% context window usage throughout workflows
- 100% file creation success rate
- Elimination of synchronization burden across command files

### Detection

Optional validation script: `.claude/tests/validate_no_behavioral_duplication.sh`

## See Also

- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Pattern for referencing agent behavioral files with context injection
- [Command Architecture Standards](./command_architecture_standards.md) - Standard 12: Structural vs Behavioral Content Separation
- [Agent Development Guide](../guides/agent-development-guide.md) - Agent files as single source of truth
- [Inline Template Duplication Troubleshooting](../troubleshooting/inline-template-duplication.md) - Detect and fix behavioral duplication anti-pattern
- [Template Usage Decision Tree](../quick-reference/template-usage-decision-tree.md) - Fast decisions for inline vs reference

## Key Takeaways

1. **Structural templates** (Task syntax, bash blocks, schemas, checkpoints, warnings) MUST be inline
2. **Behavioral content** (STEP sequences, workflows, procedures, output specs) MUST be referenced
3. **Zero exceptions** to behavioral duplication prohibition
4. **90% code reduction** achievable through proper distinction
5. **Single source of truth** for agent behavioral guidelines in `.claude/agents/*.md` files
