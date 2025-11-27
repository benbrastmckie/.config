# Research Report: Skills Usage in /convert-docs Command

**Research Topic**: Are Claude Code skills actually used in the /convert-docs command, and is there a better way to use them?

**Date**: 2025-11-23

---

## Executive Summary

The `/convert-docs` command **does implement skill integration**, but the integration approach has significant issues that prevent skills from being used as intended by the Claude Code architecture.

**Key Findings**:
1. The command includes STEP 0 and STEP 3.5 for skill detection and delegation, following the documented patterns
2. However, the delegation mechanism uses **natural language delegation** within a bash block context, which cannot work
3. The actual skill (document-converter) is well-documented but the command-to-skill bridge is broken
4. There are better approaches that would preserve functionality while properly leveraging skills

---

## Part 1: Current Implementation Analysis

### What the Command Does

The `/convert-docs` command (`.claude/commands/convert-docs.md`) implements a three-path execution model:

1. **Skill Mode** (STEP 3.5): Intended to delegate to the `document-converter` skill
2. **Script Mode** (STEP 4): Direct invocation of `.claude/lib/convert/convert-core.sh`
3. **Agent Mode** (STEP 5): Task delegation to `doc-converter` agent

### Skill Detection (STEP 0)

The command correctly implements skill availability checking:

```bash
# Check if document-converter skill exists
SKILL_AVAILABLE=false
SKILL_PATH="${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md"

if [[ -f "$SKILL_PATH" ]]; then
  SKILL_AVAILABLE=true
  echo "DETECTED: document-converter skill available"
fi
```

This follows the documented pattern from `skills-authoring.md`.

### Skill Delegation Attempt (STEP 3.5)

The command attempts skill delegation with:

```markdown
When skill is available, use natural language delegation to invoke it:

I'm delegating this conversion to the document-converter skill.

Use the document-converter skill to convert files from $input_dir to $output_dir.
```

**CRITICAL ISSUE**: This approach is fundamentally broken. The natural language delegation text is embedded within the command's markdown instructions but:
1. It's inside a conditional block that depends on bash variable state
2. Claude cannot "speak" natural language mid-execution of a bash workflow
3. The skill invocation mechanism (Skill tool) requires explicit tool usage, not inline text

---

## Part 2: How Skills Are Actually Supposed to Work

### Claude Code Skills Architecture

According to the documentation and the Skill tool definition:

1. **Skills are model-invoked**: Claude detects relevant needs and invokes skills automatically
2. **Skill tool mechanism**: The `Skill` tool explicitly loads a skill's SKILL.md content
3. **Progressive disclosure**: Metadata is scanned first, full instructions loaded when relevant

### Correct Skill Invocation Patterns

**Pattern 1: Autonomous Invocation**
Claude detects the need (e.g., "convert PDFs") and internally loads the skill without explicit user command. This happens at the model level, not through explicit tool calls.

**Pattern 2: Explicit Skill Tool Usage**
The Skill tool loads a skill's markdown content into the conversation context. Per the tool documentation:

```
Use Skill tool with skill="document-converter" to load the skill's instructions
```

**Pattern 3: Agent Auto-Loading**
Agents can specify `skills: skill-name` in frontmatter to have skills auto-loaded. The `doc-converter` agent already does this:

```yaml
---
skills: document-converter
---
```

### The Gap in Command Integration

The current `/convert-docs` command cannot use the Skill tool because:
1. Commands are markdown templates expanded by Claude
2. Tool calls must be made by Claude during execution
3. The command tries to embed "natural language" delegation in markdown, but Claude doesn't interpret markdown blocks as requests to make tool calls

---

## Part 3: Analysis of Current Skill Usage

### Is the Skill Actually Used?

**Answer: No, not effectively.**

When `/convert-docs` runs:
1. STEP 0: Skill detection runs and sets `SKILL_AVAILABLE=true` (works correctly)
2. STEP 3: Mode detection runs (works correctly)
3. STEP 3.5: The "skill delegation" text is interpreted as markdown documentation, not as an action
4. STEP 4/5: Script or Agent mode runs (actual execution happens here)

The skill's SKILL.md content is never loaded into Claude's context during `/convert-docs` execution.

### What Currently Works

The **Agent Mode** (STEP 5) does effectively use the skill because:
- It invokes the `doc-converter` agent via Task tool
- The agent has `skills: document-converter` in its frontmatter
- When the agent is loaded, the skill context is available

### What Doesn't Work

**Script Mode with Skill** (STEP 3.5 + STEP 4):
- Skill availability is detected but never acted upon
- The "natural language delegation" has no effect
- Execution falls through to Script Mode (STEP 4)

---

## Part 4: Recommended Approaches

### Option A: Remove Skill Delegation from Command (Simplest)

**Rationale**: Commands are inherently limited in their ability to dynamically invoke skills. The skill architecture is designed for autonomous model-level behavior, not command orchestration.

**Changes**:
1. Remove STEP 0 (skill availability check)
2. Remove STEP 3.5 (skill delegation)
3. Keep Script Mode (STEP 4) as default
4. Keep Agent Mode (STEP 5) for orchestrated workflows

**Pros**:
- Simple, removes broken code
- Agent mode already provides skill integration
- Script mode is fast and reliable

**Cons**:
- Skills are only accessible via Agent mode
- Loss of theoretical "skill-first" architecture

### Option B: Reframe Command as Skill Trigger (Recommended)

**Rationale**: Instead of trying to call the skill from within bash, redesign the command to trigger autonomous skill usage.

**Changes**:
1. Simplify STEP 0 to just check prerequisites
2. Remove STEP 3.5 entirely
3. Add a new instruction block that tells Claude to use the Skill tool if conditions warrant

**Implementation**:
```markdown
### STEP 3.5 (SKILL DELEGATION) - Conditional

**EXECUTE ONLY IF**: SKILL_AVAILABLE=true AND agent_mode=false

You should now use the Skill tool to load the document-converter skill:

[Claude would call Skill tool here with skill="document-converter"]

After loading the skill, follow its instructions to complete the conversion.
```

The key difference: The instruction tells Claude to make a tool call, rather than embedding pseudo-natural-language that gets ignored.

**Pros**:
- Proper skill integration
- Skill context loaded into conversation
- Claude can then follow skill instructions

**Cons**:
- More complex command structure
- May not work reliably across all contexts

### Option C: Use Agent-Only for Skill Integration (Most Reliable)

**Rationale**: Accept that skills work best with agents, not commands directly.

**Changes**:
1. Remove skill-related steps from command (STEP 0, STEP 3.5)
2. Document that skill usage is via Agent mode (`--use-agent` flag)
3. Keep Script mode for fast, simple conversions
4. Agent mode provides full skill capabilities

**Implementation**:
Update command documentation:
```markdown
## Execution Modes

**Script Mode** (default): Fast, direct tool invocation
- No skill loading, minimal overhead
- Best for: Quick batch conversions

**Agent Mode** (--use-agent): Full orchestration with skill integration
- Loads document-converter skill automatically
- Best for: Quality-critical conversions, audits, troubleshooting
```

**Pros**:
- Clear separation of concerns
- Reliable skill integration via agent
- Simplest command structure

**Cons**:
- Users must opt-in to Agent mode for skill benefits
- Agent mode has startup overhead

### Option D: Restructure as Skill-Native Command

**Rationale**: Make the command primarily a wrapper that invokes the skill.

**Changes**:
1. Command starts by immediately using Skill tool
2. Skill provides all conversion logic
3. Command just handles argument parsing and output formatting

**Implementation Approach**:
The entire command becomes:
```markdown
### STEP 1: Parse Arguments
[bash to validate inputs]

### STEP 2: Load Skill
Use the Skill tool with skill="document-converter"

### STEP 3: Follow Skill Instructions
The skill's SKILL.md will now be loaded. Follow its conversion workflow.
```

**Pros**:
- True skill-native approach
- Single source of conversion logic
- Easy to maintain

**Cons**:
- Significant restructure required
- May not fit command paradigm well
- Skills are meant to be autonomous, not command-driven

---

## Part 5: Final Recommendations

### Primary Recommendation: Option C (Agent-Only for Skills)

This is the most pragmatic approach because:
1. It acknowledges the architectural reality (skills work with agents, not commands)
2. It preserves all existing functionality
3. It requires minimal changes
4. Users get clear guidance on when to use each mode

### Implementation Steps

1. **Remove broken skill integration** from `/convert-docs`:
   - Delete STEP 0 (skill availability check)
   - Delete STEP 3.5 (skill delegation)
   - Keep STEP 4 (Script Mode) and STEP 5 (Agent Mode)

2. **Update documentation**:
   - Clarify that Script mode is for fast, simple conversions
   - Clarify that Agent mode provides skill integration
   - Document that `--use-agent` flag enables full orchestration

3. **Keep skill and agent as-is**:
   - `document-converter` skill works correctly
   - `doc-converter` agent correctly loads skill via `skills:` field
   - No changes needed to these components

### Alternative: Option B If Skill-First Is Required

If the goal is truly "skill-first" architecture, implement Option B but with proper tool call instructions. This would require testing to ensure Claude reliably makes the Skill tool call when instructed.

---

## Appendix: File References

| Component | Path | Status |
|-----------|------|--------|
| Command | `.claude/commands/convert-docs.md` | Has broken skill integration |
| Skill | `.claude/skills/document-converter/SKILL.md` | Works correctly |
| Agent | `.claude/agents/doc-converter.md` | Works correctly with `skills:` field |
| Script | `.claude/lib/convert/convert-core.sh` | Works correctly |
| Skills README | `.claude/skills/README.md` | Documents architecture |
| Skills Standards | `.claude/docs/reference/standards/skills-authoring.md` | Defines patterns |

---

## Appendix: Key Documentation Excerpts

### From skills-authoring.md - Command Delegation Pattern

```markdown
Commands that delegate to skills MUST follow this pattern:

**STEP 0**: Check for skill availability
**STEP 3.5**: Delegate to skill if available
```

The issue: The documented pattern assumes Claude can act on natural language delegation instructions, but in practice, Claude executes bash blocks sequentially and cannot interrupt to make tool calls.

### From Skills README - Using Skills from Commands

```markdown
Commands can delegate to skills when available:

/convert-docs ./documents ./output
--> Checks for document-converter skill
--> Delegates to skill if available
--> Falls back to script mode if not
```

The issue: "Delegates to skill" is aspirational but not implemented correctly.

### From doc-converter.md Agent - Skill Integration

```yaml
---
skills: document-converter
---

**SKILL INTEGRATION**: I automatically load the `document-converter` skill
(via `skills:` field in frontmatter).
```

This is the correct and working skill integration pattern.
