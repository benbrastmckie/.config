# Executable vs Guide Content - Quick Reference

**Purpose**: Fast decision support for content placement when creating or maintaining commands/agents

**Context**: The executable/documentation separation pattern requires strict separation between lean executable files and comprehensive guide files. This reference helps determine where specific content belongs.

---

## Decision Tree

### Should this content be in executable or guide?

```
Content Classification
│
├─ Is it bash code or tool invocation?
│  └─ YES → Executable
│
├─ Is it a phase marker or execution directive?
│  └─ YES → Executable
│
├─ Is it imperative instruction ("EXECUTE NOW", "YOU MUST")?
│  └─ YES → Executable
│
├─ Is it minimal inline comment explaining WHAT (not WHY)?
│  └─ YES → Executable
│
├─ Is it architecture explanation or design rationale?
│  └─ YES → Guide
│
├─ Is it troubleshooting information?
│  └─ YES → Guide
│
├─ Is it usage example with expected output?
│  └─ YES → Guide
│
├─ Is it performance consideration or optimization tip?
│  └─ YES → Guide
│
├─ Is it historical context or design decision history?
│  └─ YES → Guide
│
└─ Is it cross-reference to documentation?
   └─ BOTH → Single-line reference in executable, detailed cross-references in guide
```

---

## Content Type Matrix

### Executable File Content

| Content Type | Location | Rationale |
|--------------|----------|-----------|
| Bash blocks | Executable | Direct execution required |
| Tool invocations | Executable | Must be inline for AI to execute |
| Phase markers | Executable | Structure execution flow |
| Execution directives | Executable | Must be visible during execution |
| Minimal WHAT comments | Executable | Brief clarification only |
| Role statement | Executable | Forces execution mindset |
| Single-line doc reference | Executable | Points to comprehensive docs |
| Verification checkpoints | Executable | Execution-critical validation |
| JSON schemas | Executable | Data structure specs for execution |
| Agent invocation templates | Executable | Must be inline per Standard 11 |

**Size Limit**: <250 lines (simple commands), <400 lines (complex agents), <1,200 lines (orchestrators)

**Guiding Principle**: "Would removing this prevent the command from executing?"
- If YES → Executable
- If NO → Guide

### Guide File Content

| Content Type | Location | Rationale |
|--------------|----------|-----------|
| Architecture explanations | Guide | Understanding-oriented |
| Design decisions | Guide | Historical context not needed for execution |
| Troubleshooting guides | Guide | Problem-solving reference |
| Usage examples | Guide | Learning and reference |
| Performance considerations | Guide | Optimization guidance |
| Integration patterns | Guide | How to use with other systems |
| Advanced topics | Guide | Deep dives beyond basics |
| WHY comments | Guide | Rationale not needed during execution |
| Comprehensive cross-references | Guide | Navigation and discoverability |
| Alternative approaches | Guide | Context for design choices |

**Size Limit**: Unlimited (typically 500-5,000 lines)

**Guiding Principle**: "Does this help humans understand the system?"
- If YES → Guide
- If execution-critical → Executable (even if it helps understanding)

---

## Edge Cases

### 1. Large Inline Templates

**Scenario**: Agent prompt template is 50+ lines but must be inline per Standard 1 (Executable Instructions Must Be Inline)

**Decision**: Keep in executable using HEREDOC

**Example**:
```bash
# Correct approach - Inline with HEREDOC
AGENT_PROMPT="$(cat <<'EOF'
Read and follow ALL behavioral guidelines from:
/path/to/agent-behavioral.md

**Workflow-Specific Context**:
- Topic: ${TOPIC}
- Output Path: ${OUTPUT_PATH}
[... 50 more lines ...]
EOF
)"
```

**Rationale**: Template is structural content (Standard 12) that must be inline for execution. HEREDOC keeps it readable without bloating line count excessively.

### 2. Agent Invocation Templates

**Scenario**: Task tool invocation with context injection is 30-40 lines

**Decision**: Keep in executable (inline per Standard 11)

**Example**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory artifact creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /path/to/research-specialist.md

    **Workflow-Specific Context**:
    [... context injection ...]
  "
}
```

**Rationale**: Standard 11 (Imperative Agent Invocation Pattern) requires agent invocations inline with imperative instructions. Context injection is structural template content.

### 3. Complex Bash with Extensive Comments

**Scenario**: Bash block has 20+ lines of WHY comments explaining algorithm

**Decision**: Extract explanation to guide, keep minimal WHAT comments in executable

**Before** (problematic):
```bash
# This algorithm uses a two-phase approach because we discovered that
# single-phase detection fails in edge cases where git worktrees are
# nested. Historical context: This was implemented in Plan 042 after
# three incidents where nested worktrees caused path detection failures.
# The two-phase approach first checks git, then falls back to pwd.
# Performance impact: Negligible (< 10ms overhead).
# [15 more lines of WHY comments]

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
```

**After** (correct):
```bash
# Detect project directory (git-aware, handles worktrees)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

# Architecture and rationale: See guide Section 3.2
```

**Guide Section 3.2**:
```markdown
### Project Directory Detection Algorithm

**Two-Phase Approach**:
1. Git-based detection (primary)
2. PWD fallback (secondary)

**Rationale**: Single-phase detection fails when git worktrees are nested...
[Comprehensive explanation with historical context]
```

### 4. Cross-Reference Links

**Scenario**: Need to reference related patterns, commands, or documentation

**Decision**: Minimal in executable, comprehensive in guide

**Executable** (single line):
```markdown
**Documentation**: See `.claude/docs/guides/command-name-command-guide.md`
```

**Guide** (comprehensive):
```markdown
## Cross-References

**Related Patterns**:
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Verification Fallback Pattern](../concepts/patterns/verification-fallback.md)
- [Context Management Pattern](../concepts/patterns/context-management.md)

**Related Commands**:
- `/orchestrate` - Full workflow orchestration
- `/implement` - Phase-by-phase implementation
- `/plan` - Create implementation plans

**Standards**:
- [Standard 11: Imperative Agent Invocation](../reference/architecture/overview.md#standard-11)
- [Standard 14: Executable/Documentation Separation](../reference/architecture/overview.md#standard-14)
```

### 5. Migration Checklist

**Scenario**: Command file being refactored from monolithic to separated pattern

**Decision**: Checklist goes in guide, execution proceeds from lean executable

**Executable**: No migration checklist (file focused on execution)

**Guide**: Complete migration checklist with before/after examples (see Command Development Guide Section 2.4)

**Rationale**: Migration is a learning/maintenance task, not an execution task. Developers reference guide when migrating.

---

## Quick Validation Checklist

Use this checklist when creating or reviewing commands/agents:

### Executable File

- [ ] File size under limit (250 for commands, 400 for agents, 1,200 for orchestrators)
- [ ] Contains only bash blocks, phase markers, minimal comments
- [ ] No prose documentation (no paragraphs explaining WHY)
- [ ] Role statement present: "YOU ARE EXECUTING AS..."
- [ ] Single-line documentation reference present
- [ ] All imperative instructions inline (not referenced)
- [ ] Templates inline where required (agent prompts, schemas)

### Guide File

- [ ] File exists at correct path (`.claude/docs/guides/[name]-command-guide.md` or `-agent-guide.md`)
- [ ] Contains comprehensive documentation (architecture, examples, troubleshooting)
- [ ] Cross-reference to executable file present
- [ ] Table of contents for navigation
- [ ] All WHY explanations and design decisions documented
- [ ] Usage examples with expected output
- [ ] Troubleshooting section with common issues

### Cross-References

- [ ] Executable → Guide reference valid path
- [ ] Guide → Executable reference valid path
- [ ] CLAUDE.md references guide file
- [ ] Pattern catalog includes pattern (if applicable)
- [ ] Validation script checks pass

### Testing

- [ ] Command executes without meta-confusion
- [ ] No recursive invocation attempts
- [ ] All phases execute in sequence
- [ ] Guide content accessible to developers
- [ ] Validation script passes all three layers

---

## Common Mistakes

### ❌ Anti-Pattern 1: Architecture in Executable

**Problem**: Extensive architecture explanations in command file

```markdown
## Phase 1: Research

This phase uses a hierarchical multi-agent pattern that emerged from
our work on Plan 001. The pattern provides 40-60% time savings by
enabling parallel research delegation instead of sequential execution.

We considered several alternative approaches:
1. Sequential single-agent research (rejected: too slow)
2. Simple parallel invocation (rejected: no coordination)
3. Hierarchical supervision (selected: optimal balance)

Historical context: The supervision pattern was proven in...
[300 more lines of architecture discussion]
```

**Solution**: Move to guide, keep only execution instructions

```markdown
## Phase 1: Research

[EXECUTION-CRITICAL: Invoke research agents in parallel]

**EXECUTE NOW**: USE the Task tool...

**Architecture**: See guide Section 3.1 for hierarchical pattern details
```

### ❌ Anti-Pattern 2: Minimal Guide

**Problem**: Creating lean executable but stub guide

```markdown
# /command Command - Guide

**Executable**: `.claude/commands/command.md`

## Overview
This command does stuff.

## Usage
Run the command.
```

**Solution**: Comprehensive guide with all standard sections

```markdown
# /command Command - Complete Guide

**Executable**: `.claude/commands/command.md`

## Table of Contents
[Complete navigation]

## Overview
### Purpose
[Detailed explanation...]

### When to Use
[Specific scenarios...]

### When NOT to Use
[Anti-patterns...]

[Continue with Architecture, Examples, Troubleshooting, etc.]
```

### ❌ Anti-Pattern 3: Broken Cross-References

**Problem**: Files don't reference each other

**Solution**: Always establish bidirectional links

---

## Integration with Standards

### Standard 12: Structural vs Behavioral

**Relationship**: Standard 12 determines WHAT content (structural templates vs behavioral guidelines), this pattern determines WHERE content goes (executable vs guide)

**Combined Decision Matrix**:
- Structural templates (inline per Standard 12) → Executable file
- Behavioral content (referenced per Standard 12) → Agent file
- Architecture explanations → Guide file
- Usage examples → Guide file

### Standard 14: Executable/Documentation File Separation

**Relationship**: This quick reference implements Standard 14

**Standard 14 Requirements**:
- Commands MUST separate executable logic from documentation
- Executable files <250 lines (or <1,200 for orchestrators)
- Guide files unlimited
- Cross-references bidirectional

**Enforcement**: Automated via `.claude/tests/validate_executable_doc_separation.sh`

---

## See Also

**Pattern Documentation**:
- [Executable/Documentation Separation Pattern](../concepts/patterns/executable-documentation-separation.md) - Complete pattern with case studies

**Implementation Guides**:
- [Command Development Guide - Section 2.4](../guides/development/command-development/command-development-fundamentals.md#24-executabledocumentation-separation-pattern) - Practical migration instructions
- [Agent Development Guide - Section 1.6](../guides/development/agent-development/agent-development-fundamentals.md#16-agent-behavioralusage-separation-pattern) - Agent-specific guidance

**Standards**:
- [Standard 14: Executable/Documentation File Separation](../reference/architecture/overview.md#standard-14-executabledocumentation-file-separation) - Formal requirement
- [Standard 12: Structural vs Behavioral Content Separation](../reference/architecture/overview.md#standard-12-structural-vs-behavioral-content-separation) - Complementary pattern

**Templates**:
- [Executable Command Template](../guides/templates/_template-executable-command.md) - Quick-start template
- [Command Guide Template](../guides/templates/_template-command-guide.md) - Documentation structure

**Validation**:
- `.claude/tests/validate_executable_doc_separation.sh` - Automated compliance checking

---

**Quick Reference Version**: 1.0
**Last Updated**: 2025-11-07
**Maintained By**: Claude Code project team
