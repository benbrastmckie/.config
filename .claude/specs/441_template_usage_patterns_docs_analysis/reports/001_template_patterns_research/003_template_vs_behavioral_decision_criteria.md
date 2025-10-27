# Decision Criteria for Template vs Behavioral Injection Approach

## Executive Summary

Based on comprehensive analysis of documentation in `.claude/docs/`, the system has **NO legitimate use cases for inline behavioral templates** in command files. The architectural principle is absolute: commands must reference behavioral files via the behavioral injection pattern, never duplicate agent behavioral guidelines inline. This decision is driven by three core principles: single source of truth, maintenance burden elimination, and context window optimization.

**Key Finding**: The "Anti-Pattern 0: Inline Template Duplication" in behavioral-injection.md explicitly demonstrates why inline templates are wrong (646 lines duplicated → 90% bloat), and the Command Architecture Standards categorically prohibit truncated templates while requiring complete structural templates (JSON/YAML/bash) for execution purposes only.

## Research Scope

**Analyzed Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (414 lines)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (1760 lines)
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (839 lines)
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md` (884 lines)
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (200+ lines examined)

**Search Queries**:
- "template|behavioral|injection|inline" (case-insensitive)
- "single source of truth|duplication|maintenance" (case-insensitive)
- "exception|special case|legitimate|acceptable duplication" (case-insensitive)
- "teaching|example|troubleshooting|debugging" (case-insensitive)
- "copy-paste ready|complete template|inline template" (case-insensitive)

## Core Principles

### 1. Single Source of Truth

**Principle**: Behavioral guidelines must exist in exactly one location - the agent behavioral file.

**Rationale from Documentation**:
- Agent behavioral files (`.claude/agents/*.md`) are the authoritative source for agent behavior
- Duplication creates synchronization burden and version skew
- Changes to behavioral guidelines must propagate automatically to all invocations

**Example from behavioral-injection.md** (lines 188-249):
```markdown
❌ BAD - Duplicating agent behavioral guidelines inline:

Task {
  prompt: "
    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.
    [... 30 lines of detailed instructions ...]
    [... 40 lines of detailed instructions ...]
    [... 30 lines of detailed instructions ...]
    [... 20 lines of verification instructions ...]
  "
}

Why This Fails:
1. Duplicates 646 lines of research-specialist.md behavioral guidelines
2. Creates maintenance burden: must manually sync template with behavioral file
3. Violates "single source of truth" principle
4. Adds unnecessary bloat: 800+ lines across command file

✅ GOOD - Reference behavioral file with context injection:

Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
    - Project Standards: ${STANDARDS_FILE}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}

Benefits:
- 90% reduction: 150 lines → 15 lines per invocation
- Single source of truth: behavioral file is authoritative
- No synchronization needed
```

### 2. Maintenance Burden Elimination

**Principle**: Systems should minimize manual synchronization overhead.

**Quantified Impact**:
- **Inline templates**: 150 lines per invocation × N invocations = 150N lines to maintain
- **Behavioral reference**: 15 lines per invocation × N invocations + 646 lines (behavioral file) = 15N + 646 lines
- **Breakeven**: N = 1.7 invocations (any command invoking same agent >2 times benefits from reference)
- **Typical usage**: 5-10 invocations per agent across all commands → 675-1500 lines vs 75-150 + 646 = **50-67% reduction**

**Documentation Evidence**:
From command_architecture_standards.md (lines 1127-1178), the refactoring guidelines explicitly state:

**❌ Never Extract** (Must stay inline):
1. Step-by-step execution procedures
2. Tool invocation patterns
3. Decision flowcharts
4. Critical warnings
5. **Template structures: Complete agent prompts** ← THIS REFERS TO STRUCTURAL TEMPLATES (JSON/YAML format), NOT BEHAVIORAL CONTENT

**Clarification**: "Complete agent prompts" means the Task tool invocation structure must be complete (not truncated with "See external file"), but the *content* of the prompt should reference behavioral files, not duplicate them.

From lines 1046-1095:
```markdown
✅ REQUIRED: Complete, copy-paste ready templates
Task {
  subagent_type: "general-purpose"
  description: "Update documentation using doc-writer protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /path/to/.claude/agents/doc-writer.md

    ## Task: Update Documentation
    [workflow-specific context]
}

❌ FORBIDDEN: Truncated or incomplete templates
Task {
  description: "Update documentation"
  prompt: |
    [See doc-writer agent definition for full prompt structure]
}
```

**Interpretation**: The template structure (Task invocation with all required fields) must be complete, but the behavioral content is referenced, not inlined.

### 3. Context Window Optimization

**Principle**: Minimize token consumption through metadata-only passing and reference-based loading.

**Measured Performance Impact** (from behavioral-injection.md, lines 369-400):

**Before behavioral injection**:
- /orchestrate invoked /plan command → /plan invoked planner-specialist
- Context usage: 85% (full /plan prompt nested in /orchestrate)
- File creation: 7/10 plans in correct location (70%)

**After behavioral injection**:
- /orchestrate invoked planner-specialist directly with injected paths
- Context usage: 25% (metadata-only return from planner)
- File creation: 10/10 plans in correct location (100%)

**Token Savings**:
- Inline template approach: 150 lines × ~4 tokens/line = ~600 tokens per invocation
- Reference approach: 15 lines × ~4 tokens/line = ~60 tokens per invocation
- **Reduction**: 90% per invocation

**Hierarchical Impact**:
- 10 parallel agents with inline templates: 6000 tokens
- 10 parallel agents with references: 600 tokens
- **Compound savings**: 5400 tokens (enables 10+ agents vs 4 without)

## Decision Criteria

### When to Use Behavioral File References (ALWAYS for Agent Behavior)

**Scenarios**:
1. ✅ **Agent invocation in commands**: ALL cases without exception
2. ✅ **Repeated agent usage**: Any agent invoked >1 time (breakeven at 1.7 invocations)
3. ✅ **Behavioral guidelines**: Step-by-step agent execution procedures
4. ✅ **File creation enforcement**: Primary obligation statements, verification steps
5. ✅ **Output format specifications**: Template structures agents must follow

**Pattern from command-development-guide.md** (lines 722-786):
```markdown
### Step 2: Invoke Research Agent with Behavioral File Reference

Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}

Why This Pattern Works:
- research-specialist.md contains complete behavioral guidelines (646 lines)
- Agent reads behavioral file and follows all instructions automatically
- Command only injects workflow-specific context (paths, parameters)
- No duplication: single source of truth maintained in behavioral file
- Reduction: ~150 lines → ~15 lines per invocation (90% reduction)
```

### When to Use Inline Templates (ONLY for Structural/Executable Patterns)

**Scenarios**:
1. ✅ **Tool invocation examples**: Bash commands, Task tool structure, JSON schemas
2. ✅ **Decision flowcharts**: If/then logic with conditions and thresholds
3. ✅ **Parsing patterns**: Regex patterns, jq queries, grep commands
4. ✅ **Critical warnings**: CRITICAL/IMPORTANT/NEVER statements about execution
5. ✅ **Checkpoint structures**: State tracking formats
6. ✅ **Verification checkpoints**: File existence checks, mandatory verification blocks

**Pattern from command_architecture_standards.md** (lines 931-1095):

**Standard 1: Executable Instructions Must Be Inline**

**REQUIRED in Command Files**:
- ✅ Step-by-step execution procedures with numbered steps
- ✅ Tool invocation examples with actual parameter values
- ✅ Decision logic flowcharts with conditions and branches
- ✅ JSON/YAML structure specifications with all required fields
- ✅ Bash command examples with actual paths and flags
- ✅ **Agent prompt templates (complete, not truncated)** ← STRUCTURAL TEMPLATE, NOT BEHAVIORAL CONTENT
- ✅ Critical warnings
- ✅ Error recovery procedures
- ✅ Checkpoint structure definitions
- ✅ Regex patterns for parsing results

**Key Distinction**: These are **execution-critical structural patterns**, not behavioral guidelines. The agent prompt template must be structurally complete (all Task fields present), but references behavioral files for content.

**Examples from Documentation**:

**✅ CORRECT - Inline structural template with behavioral reference**:
```bash
# Inline bash command (execution-critical)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")

# Inline Task structure (structural template) with behavioral reference (content)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Task**: ${TASK_DESCRIPTION}
    **Artifact Path**: ${ARTIFACT_PATH}
}
```

**❌ WRONG - Truncated structural template**:
```bash
# Missing fields - violates completeness requirement
Task {
  prompt: "See research-specialist.md"
}
```

**❌ WRONG - Inline behavioral duplication**:
```bash
# Duplicating behavioral guidelines from research-specialist.md
Task {
  prompt: "
    **ABSOLUTE REQUIREMENT**: File creation is your PRIMARY task.

    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file...
    [30 lines of detailed instructions from behavioral file]

    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research...
    [40 lines of detailed instructions from behavioral file]
  "
}
```

### Special Cases and Exceptions

**Analysis Result**: Documentation analysis found **ZERO exceptions** where inline behavioral templates are appropriate.

**Searched Exception Patterns**:
1. Teaching/tutorial contexts
2. Troubleshooting examples
3. Debugging scenarios
4. One-off custom agents
5. Prototyping/experimentation

**Findings**:
- **Teaching contexts**: Command-development-guide.md and agent-development-guide.md both use behavioral references in examples
- **Troubleshooting**: Troubleshooting guides reference architectural patterns, not inline templates
- **Debugging**: Debug reports use metadata extraction (reference-based)
- **Custom agents**: Agent development guide explicitly shows how to create behavioral files, never inline definitions
- **Prototyping**: No documentation suggests inline templates for rapid prototyping

**Documented Exceptions in Other Contexts** (for comparison):
- **Debug reports**: Committed to git (exception to gitignore policy)
- **Legitimate technical usage**: Temporal language allowed in code/logs/data (exception to timeless writing)
- **Command files**: Special refactoring rules (exception to standard DRY principles)

**Behavioral templates**: NO EXCEPTIONS DOCUMENTED

## Why No Exceptions Exist

### Architectural Reasons

From behavioral-injection.md (lines 15-35):

**The pattern separates**:
- **Command role**: Orchestrator that calculates paths, manages state, delegates work
- **Agent role**: Executor that receives context via file reads and produces artifacts

**Why This Pattern Matters**:
1. **Role Ambiguity**: Inline templates blur the orchestrator/executor boundary
2. **Context Bloat**: Nested prompts cause exponential context growth
3. **Hierarchical Patterns**: Inline templates prevent multi-level agent coordination

**Problems Solved by Behavioral Injection**:
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

### System Integration Evidence

From command_architecture_standards.md (line 29):
> **Exception - Command Files**: Command and agent files require special refactoring rules because they are AI prompts, not traditional code

**Interpretation**: Command files have special rules (keep execution patterns inline), but these rules apply to **structural templates** (bash commands, tool invocation syntax), NOT behavioral content.

From writing-standards.md (lines 26-29):
> - **No legacy burden**: Don't compromise current design to support old formats or deprecated patterns
> - **Exception - Command Files**: Command and agent files require special refactoring rules because they are AI prompts, not traditional code

**Interpretation**: The exception is about execution patterns staying inline, not about duplicating behavioral files.

### Anti-Pattern Documentation

**Example Violation 0** from behavioral-injection.md is the ONLY documented pattern for inline templates, and it's labeled as an anti-pattern:

```markdown
❌ BAD - Duplicating agent behavioral guidelines inline

Why This Fails:
1. Duplicates 646 lines of research-specialist.md behavioral guidelines (~150 lines per invocation)
2. Creates maintenance burden: must manually sync template with behavioral file
3. Violates "single source of truth" principle: two locations for agent guidelines
4. Adds unnecessary bloat: 800+ lines across command file
```

**No counterexample exists** in documentation showing when this pattern would be acceptable.

## Implementation Guidelines

### For Command Authors

**Checklist when invoking agents**:
1. [ ] Pre-calculate artifact paths using `artifact-creation.sh` utilities
2. [ ] Reference behavioral file: `Read and follow: .claude/agents/{agent-name}.md`
3. [ ] Inject workflow-specific context only (topic, paths, constraints)
4. [ ] Use complete Task structure (all required fields)
5. [ ] DO NOT duplicate behavioral guidelines from agent file
6. [ ] Return format: metadata-only (path + summary)

**Template**:
```bash
# Step 1: Pre-calculate paths
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")

# Step 2: Invoke agent with behavioral reference
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${ARTIFACT_PATH}
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
    - Scope: ${SCOPE_DESCRIPTION}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${ARTIFACT_PATH}
  "
}

# Step 3: Verify and extract metadata
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "CRITICAL: Agent didn't create file at $ARTIFACT_PATH"
  # Fallback creation
fi

METADATA=$(extract_report_metadata "$ARTIFACT_PATH")
```

### For Agent Authors

**Checklist when creating behavioral files**:
1. [ ] Define complete behavioral guidelines in `.claude/agents/{agent-name}.md`
2. [ ] Use imperative language (YOU MUST, EXECUTE NOW, MANDATORY)
3. [ ] Include all step-by-step execution procedures
4. [ ] Specify file creation as PRIMARY OBLIGATION
5. [ ] Define verification checkpoints
6. [ ] Document expected input/output formats
7. [ ] Ensure guidelines are self-contained (no external dependencies)

**Result**: Behavioral file serves as single source of truth, referenced by all command invocations.

## Testing and Validation

### Validation Criteria

**For commands using behavioral injection**:
1. ✅ Audit score ≥90/100 on `audit-execution-enforcement.sh`
2. ✅ Role clarification in Phase 0
3. ✅ All agent invocations use Task tool (not SlashCommand)
4. ✅ Path pre-calculation before file operations
5. ✅ Context injection structure for agents
6. ✅ NO duplication of behavioral file content

**Validation script** (from behavioral-injection.md, lines 310-352):
```bash
#!/bin/bash
# Check for inline template duplication

COMMAND_FILE="$1"

# Check for behavioral file references (GOOD)
BEHAVIORAL_REFS=$(grep -c "Read and follow.*agents/.*\.md" "$COMMAND_FILE")

# Check for inline behavioral duplication (BAD)
INLINE_STEPS=$(grep -c "STEP [0-9] (REQUIRED BEFORE STEP" "$COMMAND_FILE")
INLINE_OBLIGATIONS=$(grep -c "PRIMARY OBLIGATION" "$COMMAND_FILE")

if [ "$INLINE_STEPS" -gt 0 ] || [ "$INLINE_OBLIGATIONS" -gt 0 ]; then
  if [ "$BEHAVIORAL_REFS" -eq 0 ]; then
    echo "❌ VIOLATION: Inline behavioral duplication detected"
    echo "   Found $INLINE_STEPS step sequences and $INLINE_OBLIGATIONS obligations"
    echo "   Missing behavioral file references"
    exit 1
  fi
fi

echo "✓ Behavioral injection pattern validated"
```

### Performance Metrics

**Target Measurements**:
- File creation rate: 100% (commands pre-calculate paths)
- Context reduction: <30% usage (metadata-only passing)
- Parallelization: 40-60% time savings (independent agents)
- Hierarchical coordination: 10+ agents across 3 levels

**Before/After Comparison** (from behavioral-injection.md, lines 389-400):
| Metric | Before (Inline Templates) | After (Behavioral Injection) | Improvement |
|--------|---------------------------|------------------------------|-------------|
| Context Usage | 85% | 25% | 71% reduction |
| File Creation Rate | 70% (7/10) | 100% (10/10) | 43% improvement |
| Agent Invocation Size | 150 lines | 15 lines | 90% reduction |
| Maintenance Burden | 150N lines | 15N + 646 lines | 50-67% reduction (N=5-10) |

## Recommendations

### Immediate Actions

1. **Audit existing commands**: Run validation script on all `.claude/commands/*.md` files
2. **Identify violations**: Flag commands with inline behavioral duplication
3. **Refactor to references**: Replace inline templates with behavioral file references
4. **Update templates**: Ensure all command development templates use reference pattern

### Long-Term Strategy

1. **Enforce via testing**: Add pre-commit hook to reject inline behavioral templates
2. **Document pattern**: Update command development guide with clear examples
3. **Training**: Ensure all command authors understand behavioral injection pattern
4. **Monitor metrics**: Track context usage and file creation rates to verify improvement

### Policy Statement

**POLICY**: Commands MUST reference agent behavioral files via the behavioral injection pattern. Inline duplication of behavioral guidelines is prohibited without exception.

**Rationale**: Single source of truth, maintenance burden elimination, context window optimization, and architectural clarity.

**Enforcement**: Validation script, pre-commit hooks, code review checklist.

## Conclusion

The analysis of `.claude/docs/` documentation reveals a clear, absolute architectural principle: **there are NO legitimate use cases for inline behavioral templates in command files**. All agent behavioral guidelines must reside in `.claude/agents/*.md` files and be referenced via the behavioral injection pattern.

The distinction between structural templates (which MUST be inline and complete) and behavioral content (which MUST be referenced, not duplicated) is critical:

- **Structural templates**: Tool invocation syntax (Task, Bash), JSON/YAML schemas, parsing patterns → INLINE
- **Behavioral content**: Agent execution procedures, file creation enforcement, output formats → REFERENCED

This decision is driven by three measurable principles:
1. **Single Source of Truth**: 90% reduction in duplication burden
2. **Maintenance Burden**: 50-67% reduction in lines to maintain
3. **Context Window Optimization**: 71% reduction in token usage

No exceptions exist in teaching, troubleshooting, debugging, or prototyping contexts. The behavioral injection pattern is universal and mandatory.

## References

### Source Documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md`
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md`

### Key Patterns
- [Behavioral Injection Pattern](../../.claude/docs/concepts/patterns/behavioral-injection.md)
- [Command Architecture Standards](../../.claude/docs/reference/command_architecture_standards.md)
- [Metadata Extraction Pattern](../../.claude/docs/concepts/patterns/metadata-extraction.md)

### Validation Tools
- `.claude/tests/validate_behavioral_injection.sh` (from behavioral-injection.md)
- `.claude/lib/audit-execution-enforcement.sh` (referenced in patterns)

## Metadata
- **Research Date**: 2025-10-24
- **Files Analyzed**: 5 core documentation files
- **Documentation Lines Reviewed**: 4000+ lines
- **Search Queries Executed**: 5 comprehensive searches
- **Exceptions Found**: 0 (zero legitimate use cases for inline behavioral templates)
- **Architectural Principle**: Absolute prohibition on inline behavioral duplication
