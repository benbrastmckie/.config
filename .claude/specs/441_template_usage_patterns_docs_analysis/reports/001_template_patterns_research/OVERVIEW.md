# Research Overview: Template Usage Patterns in .claude/docs/

## Metadata
- **Date**: 2025-10-24
- **Agent**: research-synthesizer
- **Topic Number**: 441
- **Individual Reports**: 3 reports synthesized
- **Reports Directory**: /home/benjamin/.config/.claude/specs/441_template_usage_patterns_docs_analysis/reports/001_template_patterns_research/

## Executive Summary

Documentation analysis reveals a critical architectural distinction: **inline structural templates are mandatory** (Task invocations, bash scripts, JSON schemas) while **inline behavioral duplication is absolutely prohibited**. The system achieves 90% code reduction per agent invocation through the behavioral injection pattern, maintaining single source of truth in `.claude/agents/*.md` files while keeping execution-critical structural templates complete and copy-paste ready in command files. No exceptions exist for duplicating agent behavioral guidelines inline - all 28 analyzed documentation files consistently enforce behavioral file references as the universal pattern.

## Research Structure

1. **[Inline Template Patterns and Usage](./001_inline_template_patterns_and_usage.md)** - Analysis of when templates should be inline in command files (execution blocks, verification checkpoints, structural patterns) vs anti-pattern of duplicating agent behavioral files
2. **[Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md)** - Documentation of the "Read and follow ALL behavioral guidelines from:" pattern, demonstrating 90% reduction and single source of truth maintenance
3. **[Template vs Behavioral Decision Criteria](./003_template_vs_behavioral_decision_criteria.md)** - Comprehensive decision framework showing ZERO legitimate use cases for inline behavioral duplication, with quantified impact metrics (71% context reduction, 100% file creation rate)

## Cross-Report Findings

### 1. Absolute Architectural Principle: Two Types of Inline Content

All three reports converge on a critical distinction that resolves apparent contradictions in the documentation:

**✅ REQUIRED INLINE: Structural Templates**
- Task tool invocation structure (complete, not truncated)
- Bash execution blocks with utility function calls
- JSON/YAML schema definitions
- Verification checkpoint bash blocks
- Parsing patterns (regex, jq queries)
- Critical warnings (CRITICAL, IMPORTANT, NEVER markers)

As noted in [Inline Template Patterns](./001_inline_template_patterns_and_usage.md), these are documented in Command Architecture Standards (lines 79-164) as "execution-critical patterns" that must be present for immediate Claude execution.

**❌ PROHIBITED INLINE: Behavioral Content**
- Agent behavioral guidelines (STEP-by-STEP procedures)
- File creation enforcement statements (PRIMARY OBLIGATION)
- Detailed execution procedures from agent files
- Output format specifications from agent definitions

As documented in [Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md), duplicating 646 lines of research-specialist.md into command files violates single source of truth and creates 800+ lines of maintenance burden.

### 2. Terminology Ambiguity Resolved

The phrase "inline template" appears ambiguous across documentation because it historically referred to both acceptable patterns (structural templates) and anti-patterns (behavioral duplication).

**Recommended Terminology** (from [Decision Criteria](./003_template_vs_behavioral_decision_criteria.md)):
- **"Tool invocation templates"** → Structural patterns (Task blocks, bash scripts)
- **"Agent behavioral duplication"** → Anti-pattern (embedding full agent files)
- **"Context injection templates"** → Lightweight Task prompts with file references

This resolves confusion where "complete agent prompts must be inline" (Command Architecture Standards line 1093) actually means "Task structure must be complete" (not truncated), NOT "duplicate behavioral file content inline."

### 3. Quantified Impact of Behavioral Injection Pattern

All three reports reference consistent metrics demonstrating pattern effectiveness:

**Context Reduction** (from [Decision Criteria](./003_template_vs_behavioral_decision_criteria.md), lines 443-449):
- Before (inline): 85% context usage
- After (reference): 25% context usage
- **Improvement**: 71% reduction

**Code Reduction** (from [Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md), lines 215-220):
- Before: 150 lines per invocation
- After: 15 lines per invocation
- **Improvement**: 90% reduction per invocation

**Maintenance Burden** (from [Decision Criteria](./003_template_vs_behavioral_decision_criteria.md), lines 83-88):
- Inline approach: 150N lines (N = number of invocations)
- Reference approach: 15N + 646 lines (behavioral file)
- **Breakeven**: 1.7 invocations
- **Typical usage** (N=5-10): 50-67% reduction

**File Creation Rate** (from [Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md), lines 130-141):
- Before: 70% (7/10 files created in correct location)
- After: 100% (10/10 files created in correct location)
- **Improvement**: 43% increase

### 4. Zero Exceptions to Behavioral Reference Requirement

[Decision Criteria](./003_template_vs_behavioral_decision_criteria.md) systematically searched for legitimate exceptions and found NONE:

**Searched Exception Contexts**:
- Teaching/tutorial contexts → Use behavioral references in examples
- Troubleshooting scenarios → Reference architectural patterns, not inline templates
- Debugging contexts → Use metadata extraction (reference-based)
- Custom agents → Create behavioral files, never inline definitions
- Prototyping/experimentation → No documentation suggests inline templates

**Documented Exceptions in Other Contexts** (for comparison):
- Debug reports committed to git (exception to gitignore policy)
- Temporal language allowed in code/logs (exception to timeless writing)
- Command files have special refactoring rules (exception to standard DRY)

**Behavioral templates**: NO EXCEPTIONS

### 5. Pattern Integration with System Architecture

The behavioral injection pattern is foundational to hierarchical agent architecture:

**Enabled Capabilities** (from [Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md), lines 112-119):
- **Path Control**: Commands calculate artifact locations, inject absolute paths
- **Topic Organization**: Enforces specs/{NNN_topic}/ directory structure
- **Context Reduction**: 95% reduction via metadata-only passing
- **Parallel Execution**: Independent agents with isolated context injection
- **Hierarchical Supervision**: Recursive subagent coordination (10+ agents)

**Pattern Relationships** (from [Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md), lines 176-184):
```
Agent Coordination Layer:
  Behavioral Injection ←→ Hierarchical Supervision ←→ Forward Message
           ↓                      ↓                         ↓
Context Management Layer:
  Metadata Extraction ←→ Context Management
```

Shows behavioral injection as base layer upon which all other coordination patterns depend.

### 6. Documentation Coverage and Consistency

**Pattern Documentation Across System** (from [Behavioral Injection Reference Patterns](./002_behavioral_injection_reference_patterns.md)):
- Primary definition: `behavioral-injection.md` (414 lines)
- Agent Development Guide: "Option B (Simpler)" - behavioral file reference
- Command Development Guide: Complete examples with 90% reduction metrics
- Command Architecture Standards: Standard 0 and 0.5 integration
- Pattern Catalog: Listed as foundational coordination pattern
- Troubleshooting Guides: Standard solution pattern for delegation issues

**Consistent Terminology** (found in 4+ documentation files):
- "Read and follow ALL behavioral guidelines from:" - Universal invocation pattern
- "Option B (Simpler)" - Preferred approach annotation
- "Single source of truth" - Architectural rationale phrase

**Cross-References**: 28 files reference behavioral injection pattern (from [Inline Template Patterns](./001_inline_template_patterns_and_usage.md), line 423).

## Detailed Findings by Topic

### Inline Template Patterns and Usage

**Key Findings**:
- Command files require complete structural templates (Task invocation syntax, bash blocks, YAML/JSON schemas) to remain inline for immediate execution
- Three documented inline patterns: Direct Execution Blocks, Mandatory Verification Checkpoints, Agent Invocation Templates (structure only)
- 21 files contain STEP-by-STEP patterns, but these refer to command execution procedures (not agent behavioral procedures)
- Anti-pattern explicitly documented: Duplicating 646 lines of agent behavioral file creates 150 lines per invocation + synchronization burden

**Recommendations**:
- Clarify "inline template" terminology (use "tool invocation templates" vs "behavioral duplication")
- Add visual distinction markers (✅ INLINE PATTERN vs ❌ ANTI-PATTERN) across all guides
- Create size guidelines: Task invocation 10-30 lines acceptable, agent procedures >50 lines require external reference
- Audit existing commands for oversized inline prompts (>100 lines suggests behavioral duplication)

[Full Report](./001_inline_template_patterns_and_usage.md)

### Behavioral Injection Reference Patterns

**Key Findings**:
- Pattern extensively documented as "Option B (Simpler)" across agent and command development guides
- Achieves 90% reduction per invocation (150 lines → 15 lines) while maintaining single source of truth
- Foundation for 100% file creation rates (commands pre-calculate paths and inject absolute locations)
- Enables hierarchical supervision (10+ agents across 3 levels) through clear role separation
- Consistent template: "Read and follow ALL behavioral guidelines from: .claude/agents/{agent}.md" + workflow context injection

**Recommendations**:
- Always use behavioral file reference pattern as default for agent invocations
- Pre-calculate artifact paths in commands, inject into agents (orchestrator controls organization)
- Combine with verification and fallback for 100% reliability (defense-in-depth)
- Maintain behavioral files as comprehensive, self-contained "living documentation"
- Avoid inline behavioral duplication to eliminate maintenance burden and synchronization overhead

[Full Report](./002_behavioral_injection_reference_patterns.md)

### Template vs Behavioral Decision Criteria

**Key Findings**:
- System has ZERO legitimate use cases for inline behavioral templates in command files (absolute prohibition)
- Critical distinction: Structural templates (execution syntax) MUST be inline and complete; behavioral content (agent procedures) MUST be referenced
- Three core principles: Single source of truth (90% reduction), maintenance burden elimination (50-67% reduction for N=5-10), context window optimization (71% reduction)
- Validation criteria: ≥90/100 audit score, no SlashCommand tool for agent invocation, path pre-calculation, NO behavioral file content duplication

**When to Use Inline** (ONLY for structural patterns):
- Tool invocation examples (Bash, Task, JSON/YAML)
- Decision flowcharts with if/then logic
- Parsing patterns (regex, jq, grep)
- Critical warnings (CRITICAL/IMPORTANT/NEVER)
- Verification checkpoint structures

**When to Use References** (ALWAYS for agent behavior):
- Agent invocation in commands (ALL cases without exception)
- Behavioral guidelines (step-by-step procedures)
- File creation enforcement (PRIMARY OBLIGATION statements)
- Output format specifications from agent definitions

[Full Report](./003_template_vs_behavioral_decision_criteria.md)

## Recommended Approach

### 1. Universal Pattern for Agent Invocation

**Implementation**:
```bash
# Phase 0: Pre-calculate paths (command orchestrator role)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE" "specs")
ARTIFACT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")

# Phase 1: Invoke agent with behavioral reference + context injection
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

# Phase 2: Verify and extract metadata
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "CRITICAL: Agent didn't create file"
  # Fallback creation from agent output
fi
METADATA=$(extract_report_metadata "$ARTIFACT_PATH")
```

**Key Elements**:
- ✅ Structural template (Task invocation) is complete and inline
- ✅ Behavioral content is referenced, not duplicated
- ✅ Context injection includes workflow-specific parameters only
- ✅ Path pre-calculated by command (orchestrator controls organization)
- ✅ Verification and fallback guarantee 100% file creation

### 2. Terminology Standardization

**Replace Ambiguous Terms**:
- ❌ "Inline template" → Ambiguous (could mean structure OR content)
- ✅ "Tool invocation template" → Structural pattern (Task, Bash, JSON/YAML)
- ✅ "Behavioral file reference" → Agent execution guidelines via file read
- ✅ "Context injection" → Workflow parameters passed to agent

**Visual Markers**:
```markdown
✅ INLINE PATTERN - Tool Invocation Template
```bash
Task { ... }
```

❌ ANTI-PATTERN - Agent Behavioral Duplication
```bash
Task {
  prompt: "**STEP 1**: [150 lines from agent file]..."
}
```
```

### 3. Size Guidelines for Inline Content

**Acceptable Inline Templates**:
- Task invocation: 10-30 lines (structure + context injection)
- Bash execution block: 5-50 lines (utility function calls)
- Verification checkpoint: 10-30 lines (file checks, error handling)
- JSON/YAML schema: 10-40 lines (data structure definition)

**Requires External Reference**:
- Agent behavioral guidelines: 100-700 lines → Reference `.claude/agents/*.md`
- Detailed procedures: >50 lines → Extract to `shared/` or agent file
- Reusable patterns: Used in 3+ commands → Extract to `docs/`

### 4. Validation and Enforcement

**Audit Commands**:
```bash
# Check for behavioral file references (GOOD)
BEHAVIORAL_REFS=$(grep -c "Read and follow.*agents/.*\.md" "$COMMAND_FILE")

# Check for inline behavioral duplication (BAD)
INLINE_STEPS=$(grep -c "STEP [0-9] (REQUIRED BEFORE STEP" "$COMMAND_FILE")
INLINE_OBLIGATIONS=$(grep -c "PRIMARY OBLIGATION" "$COMMAND_FILE")

if [ "$INLINE_STEPS" -gt 0 ] || [ "$INLINE_OBLIGATIONS" -gt 0 ]; then
  if [ "$BEHAVIORAL_REFS" -eq 0 ]; then
    echo "❌ VIOLATION: Inline behavioral duplication detected"
    exit 1
  fi
fi
```

**Pre-Commit Hook**:
- Run validation script on all `.claude/commands/*.md` files
- Reject commits with inline behavioral duplication
- Enforce audit score ≥90/100 on execution enforcement

### 5. Documentation Enhancement

**Add to Command Development Guide**:
- Section clarifying structural templates vs behavioral content
- Visual distinction markers (✅/❌) for examples
- Explicit note: "This Task template is a lightweight invocation structure (15 lines). This is NOT the same as duplicating the full agent behavioral file (646 lines)."

**Update Command Architecture Standards**:
- Clarify "complete agent prompts must be inline" means structural completeness (all Task fields present), not content duplication
- Add size guidelines section (inline patterns 10-50 lines, behavioral references for >50 lines)

**Create Quick Reference**:
```markdown
## When to Use Inline vs Reference

| Content Type | Inline? | Reason |
|--------------|---------|--------|
| Task invocation structure | ✅ YES | Execution-critical syntax |
| Bash command blocks | ✅ YES | Direct execution by Claude |
| JSON/YAML schemas | ✅ YES | Data structure definition |
| Verification checkpoints | ✅ YES | Mandatory validation logic |
| Agent behavioral guidelines | ❌ NO | Single source of truth in .claude/agents/ |
| STEP-by-STEP procedures (from agent files) | ❌ NO | Maintenance burden + sync overhead |
| Output format specs (from agent files) | ❌ NO | Duplication of behavioral content |
```

## Constraints and Trade-offs

### 1. Structural Template Completeness Requirement

**Constraint**: Task invocation templates must be structurally complete (all required fields present), not truncated with "See external file."

**Rationale**: Claude must execute commands immediately without context switches to external files (Command Architecture Standards, lines 38-45).

**Trade-off**: Slightly larger command files (10-30 lines per invocation) vs ability to execute without loading multiple external files mid-execution.

**Mitigation**: Behavioral content is referenced (not duplicated), so Task invocation remains lightweight (15 lines with reference vs 150 lines with inline duplication).

### 2. Behavioral File Comprehensiveness

**Constraint**: Agent behavioral files must be self-contained and comprehensive (all execution procedures documented).

**Rationale**: Commands reference behavioral files with "Read and follow ALL behavioral guidelines," so files must contain complete instructions.

**Trade-off**: Larger behavioral files (400-700 lines) vs ability to use "Option B (Simpler)" pattern without inline duplication.

**Mitigation**:
- Behavioral files are maintained once, referenced by N commands (breakeven at 1.7 invocations)
- For N=5-10 typical usage: 50-67% reduction in total lines to maintain
- Updates to behavioral file automatically propagate to all invocations

### 3. Path Pre-calculation Requirement

**Constraint**: Commands must calculate artifact paths before invoking agents (agents receive absolute paths via context injection).

**Rationale**: Orchestrator maintains control over artifact organization, enables verification at expected locations, supports topic-based directory structure enforcement.

**Trade-off**: Additional bash code in commands (5-10 lines for path calculation) vs 100% file creation rate and consistent organization.

**Mitigation**: Utilities in `.claude/lib/artifact-creation.sh` standardize path calculation (single source of truth for path logic).

### 4. Learning Curve for Pattern Distinction

**Constraint**: Developers must understand structural templates (inline) vs behavioral content (referenced) distinction.

**Risk**: Initial confusion when documentation says "templates must be inline" (structural) but also "never duplicate agent guidelines inline" (behavioral).

**Trade-off**: Upfront learning investment vs long-term maintenance burden reduction (50-67%).

**Mitigation**:
- Clear terminology standardization ("tool invocation templates" vs "behavioral file references")
- Visual markers in documentation (✅ INLINE PATTERN vs ❌ ANTI-PATTERN)
- Size guidelines (10-50 lines inline acceptable, >50 lines requires reference)
- Quick reference table in Command Development Guide

### 5. No Legitimate Exceptions

**Constraint**: Zero exceptions exist for inline behavioral duplication (absolute prohibition across all contexts).

**Rationale**: Teaching, troubleshooting, debugging, and prototyping contexts all use behavioral file references.

**Trade-off**: Less flexibility for one-off custom agents vs architectural consistency and maintenance burden elimination.

**Mitigation**:
- Agent Development Guide shows how to create behavioral files quickly
- Template-based agent creation reduces overhead
- Benefits (90% reduction per invocation) outweigh costs for any agent used >1 time

## Integration Points

### 1. Hierarchical Agent Architecture

Behavioral injection enables multi-level agent coordination:
- Supervisors invoke subagents via Task + behavioral file reference
- Each level maintains role clarity (orchestrator calculates paths, executor follows behavioral guidelines)
- Metadata-only passing between levels (95% context reduction)
- Supports 10+ agents across 3 levels vs 4 agents with inline duplication

### 2. Verification and Fallback Pattern

Defense-in-depth approach for 100% file creation:
- Behavioral file defines ideal execution path (agent creates file at injected path)
- Verification checkpoint confirms file exists at expected location
- Fallback creates file from agent output if verification fails
- Combination achieves 100% file creation rate (up from 70% before behavioral injection)

### 3. Metadata Extraction Pattern

Context reduction workflow:
- Agent creates artifact at pre-calculated path (behavioral file enforces this)
- Command verifies file creation
- Command extracts metadata (title + 50-word summary)
- Only metadata passed to next phase (not full content)
- 99% reduction: 5000 tokens → 250 tokens

### 4. Adaptive Planning Integration

Replanning workflow uses behavioral injection:
- /implement detects complexity score >8
- Invokes /revise --auto-mode (command, not agent)
- /revise invokes plan-reviser agent with behavioral file reference
- Agent updates plan structure at injected path
- /implement receives metadata-only response (updated complexity, phase count)

### 5. Template-Based Planning

Plan generation uses behavioral file references:
- /plan-from-template calculates plan path
- Invokes plan-architect agent with template variables + behavioral file reference
- Agent follows behavioral guidelines + template structure
- Returns metadata (path, phase count, complexity)
- Template system benefits from same 90% reduction as other workflows

## Performance Metrics

### Context Reduction
- **Target**: <30% context usage throughout workflows
- **Achieved**: 25% average (71% reduction from 85% baseline)
- **Method**: Behavioral file references + metadata-only passing

### Code Reduction
- **Per Invocation**: 90% (150 lines → 15 lines)
- **System-Wide** (N=5-10 typical): 50-67% maintenance burden reduction
- **Breakeven**: 1.7 invocations per agent

### File Creation Rate
- **Before**: 70% (7/10 files in correct location)
- **After**: 100% (10/10 files in correct location)
- **Method**: Path pre-calculation + behavioral file enforcement + verification + fallback

### Hierarchical Coordination
- **Before**: 4 parallel agents (context limit)
- **After**: 10+ agents across 3 levels
- **Time Savings**: 40-60% with parallel execution

## References

### Primary Research Reports
- [001_inline_template_patterns_and_usage.md](./001_inline_template_patterns_and_usage.md) - Analysis of inline patterns vs anti-patterns (294 lines)
- [002_behavioral_injection_reference_patterns.md](./002_behavioral_injection_reference_patterns.md) - Documentation of behavioral file reference pattern (431 lines)
- [003_template_vs_behavioral_decision_criteria.md](./003_template_vs_behavioral_decision_criteria.md) - Decision framework with ZERO exceptions policy (516 lines)

### Source Documentation Files
- `.claude/docs/concepts/patterns/behavioral-injection.md` (414 lines) - Authoritative pattern definition
- `.claude/docs/reference/command_architecture_standards.md` (1760 lines) - Standard 0 and 0.5 integration
- `.claude/docs/guides/command-development-guide.md` (839 lines) - "Option B (Simpler)" examples
- `.claude/docs/guides/agent-development-guide.md` (884 lines) - Behavioral file creation guidelines
- `.claude/docs/concepts/writing-standards.md` (200+ lines) - Refactoring principles for command files

### Related Patterns
- [Metadata Extraction Pattern](../../../.claude/docs/concepts/patterns/metadata-extraction.md) - 99% context reduction
- [Verification and Fallback Pattern](../../../.claude/docs/concepts/patterns/verification-fallback.md) - 100% file creation rate
- [Hierarchical Supervision Pattern](../../../.claude/docs/concepts/patterns/hierarchical-supervision.md) - Multi-level agent coordination
- [Context Management Pattern](../../../.claude/docs/concepts/patterns/context-management.md) - Context pruning and reduction

### Validation Tools
- `.claude/tests/validate_behavioral_injection.sh` - Check for inline duplication violations
- `.claude/lib/audit-execution-enforcement.sh` - Score command compliance (target ≥90/100)
