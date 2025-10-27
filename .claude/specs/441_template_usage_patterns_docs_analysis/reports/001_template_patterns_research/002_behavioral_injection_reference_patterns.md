# Behavioral Injection Reference Patterns Research Report

## Metadata
- **Date**: 2025-10-24
- **Agent**: research-specialist
- **Topic**: Behavioral Injection Pattern Documentation in .claude/docs/
- **Report Type**: codebase analysis

## Executive Summary

The behavioral injection pattern is extensively documented across .claude/docs/ as the preferred approach for agent invocation. The pattern emphasizes referencing agent behavioral files (.claude/agents/*.md) with context injection rather than duplicating agent guidelines inline. Documentation consistently presents this as "Option B (Simpler)" and demonstrates 90% reduction in invocation code (150 lines → 15 lines) while maintaining single source of truth principle. The pattern is foundational to achieving 100% file creation rates and 95% context reduction.

## Findings

### 1. Primary Pattern Documentation

**Location**: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`

This is the authoritative definition of the behavioral injection pattern with comprehensive examples.

**Key Sections**:
- **Definition** (lines 7-14): Separates command orchestration from agent execution via file content reads
- **Anti-Pattern Example 0** (lines 188-248): Demonstrates "Reference Behavioral File, Inject Context Only" pattern
- **Context Reduction Metrics** (lines 215-220): Documents 90% reduction (150 lines → 15 lines per invocation)
- **Single Source of Truth Principle** (lines 242-248): Explains maintenance benefits of behavioral file references

**Example Template** (lines 223-241):
```markdown
✅ GOOD - Reference behavioral file with context injection:

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Project Standards: ${STANDARDS_FILE}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Rationale Documentation** (lines 242-248):
- 90% reduction in code per invocation
- Single source of truth maintained in behavioral file
- No synchronization needed between command and behavioral file
- Updates to behavioral file automatically apply to all invocations

### 2. Agent Development Guide Integration

**Location**: `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md`

**Section**: "The Behavioral Injection Pattern" (lines 61-108)

**Two Options Documented** (lines 78-108):

**Option A: Load and Inject Behavioral Prompt** (lines 78-102)
- When to use: Need to modify agent behavior programmatically
- Implementation: Load behavioral file content, append context
- Use case: Dynamic prompts, custom instructions

**Option B: Reference Agent File (Simpler)** (lines 104-108)
- When to use: Agent behavioral file is complete
- Implementation: Reference file path in Task prompt
- Use case: Standard invocations, cleaner command code
- **Marked as preferred approach** with "(Simpler)" annotation

**Benefits Listed** (lines 112-119):
- Path Control: Commands control exact artifact locations
- Topic Organization: Enforces specs/{NNN_topic}/ structure
- Consistent Numbering: Sequential NNN across artifact types
- Context Reduction: 95% reduction via metadata-only passing
- No Recursion: Agents never invoke commands that invoked them
- Architectural Consistency: All commands follow same pattern

### 3. Command Development Guide Reinforcement

**Location**: `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`

**Section**: "5.2 Behavioral Injection Pattern" (lines 424-488)

**Option B Presentation** (lines 459-488):
- Labeled "Reference Agent File (Simpler)"
- When to use criteria clearly listed
- Complete implementation example provided
- Cross-referenced to behavioral injection pattern documentation

**Example Pattern** (lines 467-487):
```bash
# Calculate path (still required)
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "security" "")

# Invoke agent with file reference
Task {
  subagent_type: "general-purpose"
  description: "Research security patterns for ${FEATURE}"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    **Research Focus**: Security patterns
    **Feature**: ${FEATURE_DESCRIPTION}
    **Report Output Path**: ${REPORT_PATH}

    Create the research report at the exact path provided.
    Return metadata: {path, summary, key_findings}
}
```

**Section**: "7.1 Example: Research Command with Agent Delegation" (lines 721-786)

**Critical Pattern Documentation** (lines 739-766):
- Shows complete behavioral file reference invocation
- Documents "Why This Pattern Works" rationale
- Highlights reduction metrics: ~150 lines → ~15 lines (90% reduction)
- Emphasizes single source of truth: "research-specialist.md contains complete behavioral guidelines (646 lines)"

### 4. Command Architecture Standards Integration

**Location**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`

**Standard 0: Execution Enforcement** (lines 50-418)

**Phase 0 Pattern** (lines 309-417):
- Orchestrator role clarification
- Anti-pattern: Command-to-command invocation via SlashCommand
- Correct pattern: Agent invocation via Task with behavioral file reference

**Example** (lines 395-402):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read: .claude/agents/plan-architect.md

    **Plan Output Path**: ${PLAN_PATH}  # ← Orchestrator controls path
    **Feature**: ${FEATURE_DESCRIPTION}

    Create plan at exact path provided.
    Return metadata: {path, phase_count, complexity}
}
```

**Standard 0.5: Subagent Prompt Enforcement** (lines 419-928)

**Agent Template Enforcement** (lines 844-866):
- Behavioral file reference required in agent invocations
- "Read and follow: .claude/agents/research-specialist.md" pattern
- Context injection separate from behavioral guidelines
- "THIS EXACT TEMPLATE" enforcement for consistency

### 5. Pattern Catalog Authority

**Location**: `/home/benjamin/.config/.claude/docs/concepts/patterns/README.md`

**Catalog Entry** (line 13):
```markdown
1. **[Behavioral Injection](./behavioral-injection.md)** - Commands inject context into agents via file reads instead of tool invocations
```

**Usage Guidance** (lines 49-55):
- For Command Development: "Use Behavioral Injection to invoke agents (not SlashCommand tool)"
- Listed as first pattern to implement when creating commands
- Cross-referenced as foundational pattern for agent coordination

**Pattern Relationships** (lines 32-45):
```
Agent Coordination Layer:
  Behavioral Injection ←→ Hierarchical Supervision ←→ Forward Message
           ↓                      ↓                         ↓
Context Management Layer:
  Metadata Extraction ←→ Context Management
```

Shows behavioral injection as base layer for all agent coordination patterns.

### 6. Troubleshooting Guide Examples

**Location**: `/home/benjamin/.config/.claude/docs/troubleshooting/command-not-delegating-to-agents.md`

**Solution Example** (lines 329-335):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "[Brief description with mandatory file creation]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
```

Used as the standard solution pattern for fixing delegation issues.

### 7. Consistent Terminology

**Phrase Analysis Across Documentation**:

**"Read and follow ALL behavioral guidelines from:"** - Found in 4+ documentation files
- behavioral-injection.md (line 230)
- command-development-guide.md (line 746)
- troubleshooting/command-not-delegating-to-agents.md (line 332)
- command_architecture_standards.md (referenced in examples)

**"Option B (Simpler)"** - Found in 2 guides
- agent-development-guide.md (line 84: "Option B - Simpler")
- command-development-guide.md (line 459: "Option B: Reference Agent File (Simpler)")

**"Single source of truth"** - Referenced in multiple locations
- behavioral-injection.md (line 219: "Violates 'single source of truth' principle")
- Discussed in context of maintenance burden and synchronization

### 8. Recently Updated Documentation

Based on patterns observed in behavioral-injection.md and command_architecture_standards.md, recent enhancements include:

**Standard 0 and 0.5 Integration** (October 2025):
- Execution enforcement patterns integrated with behavioral injection
- "EXECUTE NOW" markers combined with behavioral file references
- Verification and fallback mechanisms documented alongside injection patterns

**Anti-Pattern Documentation** (lines 188-289 in behavioral-injection.md):
- Example Violation 0: "Inline Template Duplication" - NEW comprehensive anti-pattern
- Demonstrates exactly what NOT to do (duplicating 646 lines of behavioral guidelines)
- Shows correct pattern side-by-side with rationale

### 9. Cross-Reference Network

The behavioral injection pattern is referenced by:
- Hierarchical Agent Architecture Guide
- Orchestration Guide
- Execution Enforcement Guide
- Agent Reference (quick reference)
- Command Reference (quick reference)
- All workflow documentation

This extensive cross-referencing indicates it's a foundational pattern that other patterns build upon.

## Recommendations

### 1. Use Behavioral File Reference Pattern as Default

**Action**: Always use "Read and follow ALL behavioral guidelines from:" pattern when invoking agents.

**Rationale**:
- 90% code reduction per invocation (150 lines → 15 lines)
- Single source of truth maintained in .claude/agents/*.md
- No synchronization needed between commands and agent definitions
- Automatic propagation of behavioral file updates

**Implementation**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "[Clear description with mandatory file creation]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context variable 1]: ${VALUE_1}
    - [Context variable 2]: ${VALUE_2}
    - Output Path: ${ARTIFACT_PATH} (absolute, pre-calculated)

    Execute per behavioral guidelines.
    Return: [EXPECTED_RETURN_FORMAT]
  "
}
```

### 2. Avoid Inline Behavioral Duplication

**Action**: Never duplicate agent behavioral guidelines inline in command files.

**Rationale**:
- Creates maintenance burden (must sync command and agent file)
- Violates single source of truth principle
- Adds unnecessary bloat (800+ lines across command file)
- Behavioral file becomes out of sync with inline versions

**Anti-Pattern to Avoid**:
```yaml
# ❌ BAD - Duplicating agent instructions
Task {
  prompt: "
    **STEP 1**: Create file first
    [... 30 lines of instructions ...]
    **STEP 2**: Conduct research
    [... 40 lines of instructions ...]
    **STEP 3**: Populate file
    [... 30 lines of instructions ...]
  "
}
```

**Correct Pattern**:
```yaml
# ✅ GOOD - Reference behavioral file
Task {
  prompt: "
    Read and follow: .claude/agents/research-specialist.md
    Context: [minimal context only]
  "
}
```

### 3. Pre-Calculate Paths Before Agent Invocation

**Action**: Commands must calculate and inject artifact paths, not delegate path calculation to agents.

**Rationale**:
- Orchestrator maintains control over artifact organization
- Enables topic-based directory structure enforcement
- Allows verification at expected locations
- Supports metadata extraction with known paths

**Pattern**:
```bash
# Phase 0: Calculate paths BEFORE invoking agents
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")

# Phase 1: Inject calculated path into agent
Task {
  prompt: "
    Read and follow: .claude/agents/research-specialist.md
    Output Path: ${REPORT_PATH}  # ← Orchestrator controls location
  "
}
```

### 4. Combine with Verification and Fallback

**Action**: Use behavioral injection with mandatory verification checkpoints and fallback creation.

**Rationale**:
- Behavioral file defines ideal execution path
- Verification ensures compliance
- Fallback guarantees artifact creation regardless of agent behavior
- Defense-in-depth approach achieves 100% file creation rate

**Pattern**:
```bash
# Invoke agent with behavioral file reference
Task { prompt: "Read and follow: .claude/agents/research-specialist.md ..." }

# MANDATORY VERIFICATION after agent completes
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent didn't create file"
  # Fallback: Create from agent output
  cat > "$EXPECTED_PATH" <<EOF
# Fallback Report
${AGENT_OUTPUT}
EOF
fi
```

### 5. Maintain Behavioral Files as Living Documentation

**Action**: Keep agent behavioral files comprehensive, up-to-date, and self-contained.

**Rationale**:
- Behavioral files are "single source of truth" for agent behavior
- All commands reference these files, so quality matters
- Changes propagate automatically to all invocations
- Comprehensive behavioral files enable Option B (Simpler) pattern

**Checklist for Behavioral Files**:
- [ ] Complete step-by-step execution procedures
- [ ] Imperative language (YOU MUST, not "I am")
- [ ] File creation marked as PRIMARY OBLIGATION
- [ ] Template-based output enforcement
- [ ] Verification checkpoints included
- [ ] Completion criteria checklist present
- [ ] 95+/100 on enforcement rubric

## References

### Primary Documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (414 lines)
  - Lines 7-14: Pattern definition
  - Lines 188-248: Anti-Pattern Example 0 (inline duplication)
  - Lines 223-241: Correct pattern template
  - Lines 242-248: Single source of truth rationale

### Development Guides
- `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md` (884 lines)
  - Lines 61-108: Behavioral injection pattern overview
  - Lines 84-108: Option B (Simpler) - behavioral file reference
  - Lines 112-119: Benefits enumeration

- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (839 lines)
  - Lines 424-488: Behavioral injection pattern
  - Lines 459-488: Option B: Reference Agent File (Simpler)
  - Lines 721-786: Complete example with rationale

### Architecture Standards
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (1760 lines)
  - Lines 50-418: Standard 0 - Execution enforcement with behavioral injection
  - Lines 309-417: Phase 0 orchestrator pattern
  - Lines 419-928: Standard 0.5 - Agent execution enforcement
  - Lines 844-866: Agent template enforcement examples

### Pattern Catalog
- `/home/benjamin/.config/.claude/docs/concepts/patterns/README.md` (105 lines)
  - Line 13: Catalog entry for behavioral injection
  - Lines 49-55: Command development usage guidance
  - Lines 32-45: Pattern relationship diagram

### Troubleshooting
- `/home/benjamin/.config/.claude/docs/troubleshooting/command-not-delegating-to-agents.md`
  - Lines 329-335: Standard solution pattern using behavioral file reference

### Files Documenting Pattern
Total files referencing behavioral injection: 28 files found via grep
Key files analyzed: 6 comprehensive documentation files above

### Related Patterns
- Metadata Extraction Pattern (complements by reducing context after behavioral execution)
- Verification and Fallback Pattern (combines with for 100% reliability)
- Hierarchical Supervision Pattern (enabled by behavioral injection's role separation)
- Forward Message Pattern (passes subagent outputs without re-summarization)
