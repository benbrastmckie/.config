# Research Report: Subagent-First Converter Architecture

**Research Topic**: Optimal architecture for /convert-docs using subagents as primary approach with skills support

**Date**: 2025-11-23

---

## Executive Summary

This report analyzes how to restructure `/convert-docs` to use a converter subagent as the primary approach, with scripts as backup. Based on previous research (922_skills_convert_docs_usage), the current skill integration is broken and needs restructuring.

**Key Recommendation**: Use **Agent-First with Skill Loading** architecture where:
1. The command always delegates to a converter subagent (via Task tool)
2. The subagent has `skills: document-converter` in its frontmatter
3. Script fallback only activates if agent invocation fails
4. Remove the broken STEP 0/STEP 3.5 skill detection from the command

---

## Part 1: Current Architecture Problems

### Problem 1: Broken Skill Integration

From research report 922:
- STEP 0 detects skill availability (works)
- STEP 3.5 attempts "natural language delegation" (broken - has no effect)
- The skill's SKILL.md is never loaded into Claude's context

### Problem 2: Script-First is Suboptimal

Current default path:
1. Parse arguments
2. Check mode (agent_mode flag)
3. If no --use-agent flag: run convert-core.sh directly
4. Agent only used with explicit flag

This means:
- Skills never used in default mode
- No orchestration benefits (progress tracking, error handling)
- No adaptive tool selection based on file content

### Problem 3: Three Competing Execution Paths

Current execution paths:
1. **Skill Mode** (STEP 3.5) - Broken, never executes
2. **Script Mode** (STEP 4) - Default, no skill/agent benefits
3. **Agent Mode** (STEP 5) - Works but requires --use-agent flag

This creates confusion and the skill mode is dead code.

---

## Part 2: Proposed Architecture

### Agent-First with Skill Loading

```
/convert-docs <input> <output> [flags]
        |
        v
+------------------+
| Parse Arguments  |
| Validate Inputs  |
+--------+---------+
         |
         v
+------------------+
| Invoke Converter |
| Subagent (Task)  |
+--------+---------+
         |
    [success?]
    /        \
  Yes         No
   |           |
   v           v
+-------+  +----------+
| Done  |  | Fallback |
+-------+  | Script   |
           +----------+
```

### Key Design Decisions

**1. Subagent is Primary**
- Always use Task tool to invoke converter agent
- Agent has `skills: document-converter` in frontmatter
- Agent loads skill context automatically

**2. Skill Stays in Agent**
- Do NOT try to load skills from command
- Agent frontmatter `skills:` field is the correct mechanism
- Skill provides conversion instructions to agent

**3. Script is Backup Only**
- Only used if agent invocation fails (rare)
- Direct bash execution without orchestration
- Preserved for edge cases and debugging

**4. No More Broken STEP 0/3.5**
- Remove skill detection from command
- Remove "natural language delegation" attempt
- Simplify command to: parse args -> invoke agent

---

## Part 3: Conversion Matrix Implementation

From the referenced plan (895_convert_docs_fidelity_llm_practices):

| From -> To | Default Mode | Offline Mode (--no-api) |
|-----------|--------------|-------------------------|
| PDF -> Markdown | Gemini API | PyMuPDF4LLM -> MarkItDown |
| PDF -> DOCX | pdf2docx | pdf2docx |
| DOCX -> Markdown | MarkItDown | MarkItDown |
| DOCX -> PDF | via Markdown | via Markdown |
| Markdown -> DOCX | Pandoc | Pandoc |
| Markdown -> PDF | Pandoc + Typst | Pandoc + Typst |

### Where This Logic Lives

**Current**: Split between convert-core.sh and doc-converter.md

**Proposed**:
1. **Skill (SKILL.md)**: Documents the conversion matrix and tool selection
2. **Agent**: Loads skill, executes conversions following skill instructions
3. **Script**: Contains same logic as backup (unchanged)

---

## Part 4: Skill vs No-Skill Analysis

### Option A: Keep document-converter Skill

**Pros**:
- Single source of truth for conversion logic
- Agent auto-loads via `skills:` frontmatter
- Supports autonomous skill invocation (Claude can use skill without command)
- Already exists and is well-documented

**Cons**:
- Adds one layer of indirection
- Skill needs to stay in sync with scripts

### Option B: Remove Skill, Use Agent Directly

**Pros**:
- Simpler architecture
- Agent contains all conversion logic
- One less component to maintain

**Cons**:
- Loses autonomous skill invocation
- Agent file becomes very large
- No skill reuse in other contexts

### Recommendation: Keep Skill (Option A)

Reasons:
1. **Autonomous invocation**: Claude can use skill when user says "convert this PDF" without explicit command
2. **Separation of concerns**: Skill = instructions, Agent = orchestration
3. **Already implemented**: Skill exists and works when agent loads it
4. **Documentation benefits**: SKILL.md serves as user-facing documentation

---

## Part 5: Implementation Strategy

### Phase 1: Restructure Command (Primary Work)

1. Remove broken STEP 0 (skill availability check)
2. Remove broken STEP 3.5 (skill delegation)
3. Make agent invocation the default (not requiring --use-agent)
4. Add script fallback only on agent failure

### Phase 2: Update Agent

1. Ensure `skills: document-converter` in frontmatter
2. Agent reads skill instructions on load
3. Agent implements conversion matrix from skill

### Phase 3: Update Skill (if needed)

1. Verify SKILL.md has complete conversion matrix
2. Ensure tool priority is documented
3. Add any missing conversion directions

### Phase 4: Update Standards (if needed)

1. Update skills-authoring.md if command-skill integration pattern changes
2. Document that skills work via agents, not commands
3. Remove or clarify the broken STEP 0/STEP 3.5 pattern

---

## Part 6: Standards Compliance Review

### Current Standards (skills-authoring.md)

The current standard says:
```markdown
Commands that delegate to skills MUST follow this pattern:

**STEP 0**: Check for skill availability
**STEP 3.5**: Delegate to skill if available
```

This standard is **problematic** because:
- Commands cannot make tool calls mid-execution
- "Natural language delegation" has no effect
- The pattern doesn't actually work

### Proposed Standard Update

Replace with:
```markdown
Commands that need skill capabilities should:

**Option 1 (Recommended)**: Delegate to an agent that has the skill
- Use Task tool to invoke agent
- Agent loads skill via `skills:` frontmatter
- Agent executes using skill instructions

**Option 2**: Instruct Claude to load skill
- Command can include instruction: "Use Skill tool with skill=X"
- Claude makes tool call, skill loads into context
- Requires explicit instruction, not "natural language"
```

---

## Part 7: File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `.claude/commands/convert-docs.md` | Major | Remove STEP 0/3.5, make agent default |
| `.claude/agents/doc-converter.md` | Minor | Verify skills: field present |
| `.claude/skills/document-converter/SKILL.md` | Minor | Verify conversion matrix complete |
| `.claude/docs/reference/standards/skills-authoring.md` | Minor | Update command-skill integration pattern |
| `.claude/skills/README.md` | Minor | Update usage examples |

---

## Conclusion

The optimal architecture for `/convert-docs` is:

1. **Agent-First**: Always delegate to converter agent via Task tool
2. **Skill via Agent**: Agent loads skill via `skills:` frontmatter (working pattern)
3. **Script as Backup**: Only used if agent invocation fails
4. **Remove Broken Code**: Delete STEP 0/3.5 from command
5. **Update Standards**: Document that skills work via agents, not direct command delegation

This preserves all functionality while fixing the broken skill integration and making the codebase simpler and more maintainable.
