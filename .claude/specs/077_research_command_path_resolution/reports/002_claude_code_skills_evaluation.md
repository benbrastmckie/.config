# Claude Code Skills Feasibility for Path Resolution

## Metadata
- **Date**: 2025-10-23
- **Agent**: research-specialist
- **Topic**: Claude Code Skills Feasibility for Path Resolution
- **Report Type**: best practices

## Executive Summary

Claude Code skills are model-invoked modular capabilities that extend Claude's functionality through SKILL.md files with YAML frontmatter. While skills can encapsulate bash utilities and provide automatic context-aware invocation, they are NOT appropriate for path calculation logic in the /research command. Skills are designed for repeatable task patterns with higher-level expertise, while path calculation is a low-level utility function best handled by dedicated bash libraries that commands source directly.

## Findings

### What Are Claude Code Skills?

Claude Code skills are autonomous capabilities stored in `.claude/skills/` (project-level) or `~/.claude/skills/` (personal). Each skill consists of:

- **Required**: `SKILL.md` with YAML frontmatter (name, description, allowed-tools) and Markdown instructions
- **Optional**: Supporting files including scripts, templates, and reference documentation

**Key Characteristic - Model-Invoked Activation**: Skills are autonomously activated by Claude based on relevance to the user's request and the skill's description. Claude decides when to deploy them without explicit user commands. This is fundamentally different from slash commands (user-invoked) or library functions (command-invoked).

**Source**: https://docs.claude.com/en/docs/claude-code/skills

### Skills Structure and Capabilities

Skills support bash utilities and function exports:

1. **SKILL.md** contains instructions in Markdown format
2. **scripts/** directory can contain bash utilities (`.sh` files)
3. **templates/** directory can contain reusable templates
4. **allowed-tools** frontmatter limits which tools Claude can use when skill is active

**Example Use Cases** (from web research):
- Excel file processing workflows
- Organization-specific brand guidelines enforcement
- Specialized data formatting tasks
- Custom testing protocols

**Source**: https://www.anthropic.com/engineering/claude-code-best-practices

### Current Path Calculation Implementation

The `/research` command currently uses dedicated bash library functions for path calculation:

**File**: `/home/benjamin/.config/.claude/commands/research.md` (lines 42-44)
```bash
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
```

**File**: `/home/benjamin/.config/.claude/lib/artifact-creation.sh` (lines 134-157)

The `get_next_artifact_number()` function:
- Scans directory for existing `NNN_*.md` files
- Finds highest number using grep pattern matching
- Returns next number with zero-padding (printf "%03d")
- Handles octal interpretation edge cases (10#$num forces base-10)

This is a **low-level utility function** that's sourced by multiple commands.

### Skills vs Library Functions Comparison

| Aspect | Skills | Library Functions |
|--------|--------|-------------------|
| **Invocation** | Model-invoked (automatic) | Command-invoked (manual source) |
| **Scope** | Task-level expertise | Low-level utilities |
| **Discovery** | Claude scans descriptions | Commands explicitly source |
| **Complexity** | Higher-level workflows | Simple helper functions |
| **Sharing** | Git-committed, team-wide | Git-committed, team-wide |
| **Use Case** | Repeatable patterns | Common utilities |

**Source**: https://skywork.ai/blog/ai-agent/claude-skills-vs-mcp-vs-llm-tools-comparison-2025/

### Would Skills Reduce /research Command Complexity?

**Analysis**:

1. **Automatic Invocation is a Liability**: Path calculation must happen at PRECISE moments in command execution flow (Step 2, before agent invocation in Step 3). Model-invoked skills could trigger at wrong times, breaking the orchestration sequence.

2. **Skills Add Indirection**: Instead of directly sourcing `.claude/lib/artifact-creation.sh` and calling `get_next_artifact_number()`, commands would need to prompt Claude to "use the path calculation skill" and parse its output. This is MORE complex, not less.

3. **No Context-Awareness Benefit**: Path calculation doesn't need contextual triggering. It's a deterministic operation: "given this directory, find next number". There's no ambiguity that benefits from Claude's judgment.

4. **Function Export Works Fine**: The current implementation uses `export -f get_next_artifact_number` (line 265 of artifact-creation.sh), making the function available to all sourced commands. This is simpler and more reliable than skill invocation.

**Counter-Example - Where Skills Excel**:
Skills are ideal for tasks like "format this data according to our organization's style guide" where Claude needs to recognize the task AND apply complex, multi-step logic. Path calculation is neither ambiguous nor complex enough to benefit.

**File References**:
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh:134-157` (get_next_artifact_number implementation)
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh:265` (function export)
- `/home/benjamin/.config/.claude/commands/research.md:42-44` (library sourcing)
- `/home/benjamin/.config/.claude/commands/research.md:100-129` (path pre-calculation logic)

### Existing Skills in Codebase

**Search Result**: No existing skills found in `.claude/skills/` directory.

This confirms the project has not yet adopted skills for any workflows. All current automation uses slash commands (`/research`, `/plan`, `/implement`) and sourced bash libraries.

## Recommendations

### 1. DO NOT Use Skills for Path Calculation Logic

**Rationale**: Path calculation is a low-level, deterministic utility that must execute at precise moments in command orchestration. Skills' model-invoked activation model creates timing ambiguity and adds unnecessary indirection. The current approach (sourced bash library with exported functions) is optimal for this use case.

**Evidence**: The `/research` command explicitly pre-calculates paths in Step 2 (lines 100-129) with mandatory verification checkpoints (lines 131-150) before invoking research-specialist agents in Step 3. Skills cannot guarantee this execution ordering.

**Action**: Keep path calculation in `.claude/lib/artifact-creation.sh` as exported bash functions.

### 2. Consider Skills for Higher-Level Research Workflows

**Rationale**: Skills excel at repeatable task patterns that require Claude's contextual judgment. Example: A "research-depth-analyzer" skill that automatically determines optimal subtopic count (2-4) based on topic complexity, replacing manual decomposition.

**Potential Use Case**:
```yaml
---
name: research-depth-analyzer
description: Analyze research topic complexity and recommend optimal decomposition strategy (2-4 subtopics)
allowed-tools: Read, Grep, Glob, WebSearch
---
```

This would be invoked automatically when `/research` receives a new topic, reducing orchestrator complexity.

**Action**: Prototype skills for research decomposition and topic matching (find existing vs create new), NOT for path calculation.

### 3. Document Decision in Architecture Guide

**Rationale**: Future developers may be tempted to "modernize" path calculation by converting to skills. Document why this is explicitly rejected to prevent regressions.

**Suggested Documentation**:
```markdown
## Why Not Use Skills for Path Calculation?

Path calculation (`get_next_artifact_number()`) is a **deterministic utility**
that must execute at precise moments in command workflows. Skills' model-invoked
activation creates timing ambiguity incompatible with orchestration requirements.

Use skills for: Contextual task recognition and complex multi-step workflows
Use libraries for: Low-level utilities requiring precise execution timing
```

**Action**: Add section to `.claude/docs/concepts/hierarchical_agents.md` or create new `.claude/docs/guides/skills-vs-libraries.md`.

### 4. Audit Other Commands for Skills Opportunities

**Rationale**: While skills are wrong for path calculation, they may be ideal for other workflows. Example candidates:

- **Plan complexity analysis**: Automatically determine if plan needs phase expansion
- **Debugging pattern recognition**: Identify common error patterns and suggest fixes
- **Documentation style enforcement**: Ensure reports follow project standards

**Action**: Review `/orchestrate`, `/plan`, `/implement` for tasks that would benefit from Claude's contextual judgment rather than deterministic execution.

## References

### Codebase Files Analyzed
- `/home/benjamin/.config/.claude/commands/research.md:1-150` - Path pre-calculation implementation
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh:1-267` - Path calculation utilities
- `/home/benjamin/.config/.claude/agents/research-specialist.md:1-643` - Agent behavioral guidelines
- `/home/benjamin/.config/.claude/skills/` - No existing skills found (empty directory check)

### External Sources
- https://docs.claude.com/en/docs/claude-code/skills - Official skills documentation
- https://www.anthropic.com/engineering/claude-code-best-practices - Best practices guide
- https://skywork.ai/blog/ai-agent/claude-skills-vs-mcp-vs-llm-tools-comparison-2025/ - Skills comparison analysis
- https://simonwillison.net/2025/Oct/16/claude-skills/ - Skills capabilities overview
