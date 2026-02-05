# Research Report: Task #48

**Task**: Add Phase Checkpoint Protocol to neovim-implementation-agent
**Date**: 2026-02-05
**Focus**: Research the Phase Checkpoint Protocol pattern used in implementation agents and determine what changes are needed for neovim-implementation-agent

## Summary

The neovim-implementation-agent is missing the "Phase Checkpoint Protocol" section and two related features that all three other implementation agents (general, LaTeX, Typst) have: (1) a dedicated protocol section with per-phase git commits, and (2) Stage 6a "Generate Completion Data" for producing `completion_data` in the metadata file. Additionally, the neovim skill is missing completion_data extraction and propagation in its postflight. These are the only gaps; the agent's Stage 4 execution loop already handles the `[IN PROGRESS]` / `[COMPLETED]` plan file updates correctly.

## Findings

### Agents With Phase Checkpoint Protocol

Three implementation agents have an explicit "Phase Checkpoint Protocol" section:

| Agent | Location | Lines |
|-------|----------|-------|
| general-implementation-agent.md | Line 307-329 | 23 lines |
| latex-implementation-agent.md | Line 333-355 | 23 lines |
| typst-implementation-agent.md | Line 309-331 | 23 lines |

All three sections are structurally identical, differing only in step 3's action description:

```markdown
## Phase Checkpoint Protocol

For each phase in the implementation plan:

1. **Read plan file**, identify current phase
2. **Update phase status** to `[IN PROGRESS]` in plan file
3. **Execute {domain-specific} steps** as documented
4. **Update phase status** to `[COMPLETED]` or `[BLOCKED]` or `[PARTIAL]`
5. **Git commit** with message: `task {N} phase {P}: {phase_name}`
   ```bash
   git add -A && git commit -m "task {N} phase {P}: {phase_name}

   Session: {session_id}

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```
6. **Proceed to next phase** or return if blocked

**This ensures**:
- Resume point is always discoverable from plan file
- Git history reflects phase-level progress
- Failed {domain action}s can be retried from beginning
```

The domain-specific variations in step 3:
- **general**: "Execute phase steps"
- **latex**: "Execute LaTeX creation/modification"
- **typst**: "Execute Typst creation/modification"

### Agents With Stage 6a: Generate Completion Data

Three implementation agents have "Stage 6a: Generate Completion Data":

| Agent | Location | Lines |
|-------|----------|-------|
| general-implementation-agent.md | Line 203-248 | 46 lines |
| latex-implementation-agent.md | Line 240-267 | 28 lines |
| typst-implementation-agent.md | Line 223-243 | 21 lines |

The general agent has the most comprehensive version since it handles both meta and non-meta tasks. The key difference is:

- **general-implementation-agent**: Handles `completion_summary`, `claudemd_suggestions` (meta tasks), and `roadmap_items` (non-meta tasks)
- **latex-implementation-agent**: Handles `completion_summary` and `roadmap_items` (never meta)
- **typst-implementation-agent**: Handles `completion_summary` and `roadmap_items` (never meta)

Since neovim tasks are non-meta, the neovim agent needs `completion_summary` and `roadmap_items` (matching the LaTeX/Typst pattern).

### The neovim-implementation-agent: Current State

The neovim-implementation-agent (350 lines) has:

**Present (correct)**:
- Stage 0: Initialize Early Metadata (lines 55-81)
- Stage 1: Parse Delegation Context (lines 83-102)
- Stage 2: Load and Parse Implementation Plan (lines 104-111)
- Stage 3: Find Resume Point (lines 113-119)
- Stage 4: Execute Implementation Loop (lines 121-155) -- includes A/B/C/D sub-steps for marking phases `[IN PROGRESS]` and `[COMPLETED]`
- Stage 5: Run Final Verification (lines 157-167)
- Stage 6: Create Implementation Summary (lines 169-197)
- Stage 7: Write Metadata File (lines 199-230)
- Stage 8: Return Brief Text Summary (lines 232-245)
- Neovim-Specific Implementation Patterns (lines 247-284)
- Verification Commands (lines 286-306)
- Error Handling (lines 308-330)
- Critical Requirements (lines 332-350)

**Missing**:
1. **Phase Checkpoint Protocol section** (should go between Error Handling and Critical Requirements, or after Stage 6 like the other agents). The Stage 4 loop does A. Mark In Progress and D. Mark Complete, but it does NOT include per-phase git commits (step 5 of the protocol).
2. **Stage 6a: Generate Completion Data** (should go between Stage 6 and Stage 7). Without this, the metadata file's `completion_data` field is never populated.
3. **`completion_data` field in Stage 7 metadata template** -- the JSON template in Stage 7 does not include the `completion_data` field.

### The skill-neovim-implementation: Comparison

Comparing skill-neovim-implementation against skill-implementer (the most complete reference):

**skill-implementer has (that skill-neovim-implementation is missing)**:

1. **Stage 5a: Validate Subagent Return Format** (lines 175-196) -- checks if subagent accidentally returned JSON to console
2. **completion_data extraction in Stage 6** (lines 214-217) -- extracts `completion_summary`, `claudemd_suggestions`, `roadmap_items` from metadata file
3. **completion_data propagation in Stage 7** (lines 241-261) -- adds `completion_summary` and `roadmap_items` (or `claudemd_suggestions` for meta) to state.json
4. **Plan file update in Stage 7** (lines 266-281) -- updates plan file status to `[COMPLETED]` with dual-pattern sed + verification

**skill-neovim-implementation already has**:
- Stage 2: Preflight plan file status update to `[IMPLEMENTING]` (lines 82-91)
- Stage 7: Postflight plan file status update to `[COMPLETED]` (lines 191-207)
- Both use dual-pattern sed with verification (already patched in task 44/45 era)

**skill-neovim-implementation is missing**:
1. **Subagent return format validation** (Stage 5a equivalent)
2. **completion_data field extraction from metadata file** in Stage 6 (lines 162-167 only extract status, phases_completed, phases_total -- no completion_data)
3. **completion_data propagation to state.json** in Stage 7 (lines 174-186 only set status/timestamps -- no completion_summary or roadmap_items)
4. **Partial plan file status update** -- when status is "partial", no plan file update to `[PARTIAL]` is done (the section says "On partial/failed: Keep status as 'implementing' for resume. Update plan file to [PARTIAL] or leave as [IMPLEMENTING] for retry." but does not include actual code)

## Gap Summary

### Agent-Level Gaps (neovim-implementation-agent.md)

| Gap | What | Where to Add | Reference Agent |
|-----|------|-------------|-----------------|
| G1 | Phase Checkpoint Protocol section | After current Error Handling section (line 330) | general-implementation-agent.md lines 307-329 |
| G2 | Stage 6a: Generate Completion Data | Between Stage 6 (line 197) and Stage 7 (line 199) | latex-implementation-agent.md lines 240-267 |
| G3 | `completion_data` field in Stage 7 metadata JSON | Inside the JSON template at line 219 | latex-implementation-agent.md lines 295-298 |
| G4 | `partial_progress` update directive in Critical Requirements | MUST DO list item 10 is missing | general-implementation-agent.md line 479 |

### Skill-Level Gaps (skill-neovim-implementation/SKILL.md)

| Gap | What | Where to Add | Reference Skill |
|-----|------|-------------|-----------------|
| S1 | completion_data extraction from metadata file | Stage 6 (Parse Subagent Return), line 165 | skill-implementer Stage 6 lines 214-217 |
| S2 | completion_data propagation to state.json | Stage 7 (Update Task Status), line 180 | skill-implementer Stage 7 lines 241-261 |
| S3 | Subagent return format validation | New Stage 5a between Stage 5 and Stage 6 | skill-implementer Stage 5a lines 175-196 |
| S4 | Partial plan file status update code block | Stage 7 "On partial/failed" section, line 209 | skill-implementer Stage 7 lines 288-314 |

## Specific Code to Add

### G1: Phase Checkpoint Protocol (for agent)

Add after the Error Handling section (line 330), before Critical Requirements:

```markdown
## Phase Checkpoint Protocol

For each phase in the implementation plan:

1. **Read plan file**, identify current phase
2. **Update phase status** to `[IN PROGRESS]` in plan file
3. **Execute Neovim configuration changes** as documented
4. **Update phase status** to `[COMPLETED]` or `[BLOCKED]` or `[PARTIAL]`
5. **Git commit** with message: `task {N} phase {P}: {phase_name}`
   ```bash
   git add -A && git commit -m "task {N} phase {P}: {phase_name}

   Session: {session_id}

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```
6. **Proceed to next phase** or return if blocked

**This ensures**:
- Resume point is always discoverable from plan file
- Git history reflects phase-level progress
- Failed phases can be retried from beginning
```

### G2: Stage 6a (for agent)

Add between Stage 6 and Stage 7:

```markdown
### Stage 6a: Generate Completion Data

**CRITICAL**: Before writing metadata, prepare the `completion_data` object.

1. Generate `completion_summary`: A 1-3 sentence description of what was accomplished
   - Focus on the configuration outcome
   - Include key plugins or features configured
   - Example: "Configured telescope.nvim with fzf-native, added 6 keybindings, and set up lazy loading via cmd and keys."

2. Optionally generate `roadmap_items`: Array of explicit ROAD_MAP.md item texts this task addresses
   - Only include if the task clearly maps to specific roadmap items
   - Example: `["Configure telescope.nvim for fuzzy finding"]`

**Example completion_data for Neovim task**:
```json
{
  "completion_summary": "Configured telescope.nvim with fzf-native sorter. Added 6 keybindings for file/grep/buffer operations. Lazy loads via cmd and keys.",
  "roadmap_items": ["Set up telescope.nvim"]
}
```
```

### G3: completion_data in Stage 7 metadata JSON (for agent)

Add `completion_data` field to the JSON template in Stage 7:

```json
  "completion_data": {
    "completion_summary": "1-3 sentence description of configuration changes",
    "roadmap_items": ["Optional: roadmap item text this task addresses"]
  },
```

### S1-S2: completion_data extraction and propagation (for skill)

Add to Stage 6 (Parse Subagent Return):
```bash
    # Extract completion_data fields (if present)
    completion_summary=$(jq -r '.completion_data.completion_summary // ""' "$metadata_file")
    roadmap_items=$(jq -c '.completion_data.roadmap_items // []' "$metadata_file")
```

Add to Stage 7 (Update Task Status), after the status/timestamp update for "implemented":
```bash
# Add completion_summary (always required for completed tasks)
if [ -n "$completion_summary" ]; then
    jq --arg summary "$completion_summary" \
      '(.active_projects[] | select(.project_number == '$task_number')).completion_summary = $summary' \
      specs/state.json > /tmp/state.json && mv /tmp/state.json specs/state.json
fi

# Add roadmap_items (if present and non-empty)
if [ "$roadmap_items" != "[]" ] && [ -n "$roadmap_items" ]; then
    jq --argjson items "$roadmap_items" \
      '(.active_projects[] | select(.project_number == '$task_number')).roadmap_items = $items' \
      specs/state.json > /tmp/state.json && mv /tmp/state.json specs/state.json
fi
```

### S3: Subagent return format validation (for skill)

Add as new Stage 5a (between current Stages 5 and 6):

```markdown
### Stage 5a: Validate Subagent Return Format

**IMPORTANT**: Check if subagent accidentally returned JSON to console (v1 pattern) instead of writing to file (v2 pattern).

If the subagent's text return parses as valid JSON, log a warning:

```bash
# Check if subagent return looks like JSON (starts with { and is valid JSON)
subagent_return="$SUBAGENT_TEXT_RETURN"
if echo "$subagent_return" | grep -q '^{' && echo "$subagent_return" | jq empty 2>/dev/null; then
    echo "WARNING: Subagent returned JSON to console instead of writing metadata file."
    echo "This indicates the agent may have outdated instructions (v1 pattern instead of v2)."
    echo "The skill will continue by reading the metadata file, but this should be fixed."
fi
```
```

### S4: Partial plan file status update (for skill)

Add concrete code block for the "On partial/failed" case in Stage 7:

```bash
# On partial: update plan file to [PARTIAL]
plan_file=$(ls -1 "specs/${padded_num}_${project_name}/plans/implementation-"*.md 2>/dev/null | sort -V | tail -1)
if [ -n "$plan_file" ] && [ -f "$plan_file" ]; then
    sed -i 's/^\- \*\*Status\*\*: \[.*\]$/- **Status**: [PARTIAL]/' "$plan_file"
    sed -i 's/^\*\*Status\*\*: \[.*\]$/**Status**: [PARTIAL]/' "$plan_file"
    if grep -qE '^\*\*Status\*\*: \[PARTIAL\]|^\- \*\*Status\*\*: \[PARTIAL\]' "$plan_file"; then
        echo "Plan file status updated to [PARTIAL]"
    else
        echo "WARNING: Could not verify plan file status update"
    fi
fi
```

## Recommendations

1. **Add Phase Checkpoint Protocol section to neovim-implementation-agent.md** -- This is the primary gap. Without it, the agent lacks explicit instructions for per-phase git commits, which means phase-level progress is not captured in git history and resume after interruption relies solely on plan file markers (no git safety net).

2. **Add Stage 6a to neovim-implementation-agent.md** -- Without this, `/todo` command cannot annotate ROAD_MAP.md for neovim tasks because `completion_summary` is never populated in state.json.

3. **Update Stage 7 metadata JSON template in neovim-implementation-agent.md** -- Add `completion_data` field so the agent knows to include it.

4. **Update skill-neovim-implementation/SKILL.md with completion_data extraction and propagation** -- Even if the agent produces completion_data, the skill must extract and write it to state.json.

5. **Add Stage 5a (subagent return validation) to skill-neovim-implementation/SKILL.md** -- Defensive check for v1/v2 agent pattern mismatch.

6. **Add concrete partial plan file update code to skill-neovim-implementation/SKILL.md** -- The current text mentions updating to [PARTIAL] but lacks the actual code block.

## Effort Estimate

- Agent changes: ~45 minutes (adding 3 sections with known patterns)
- Skill changes: ~30 minutes (adding 4 code blocks with known patterns)
- Verification: ~15 minutes (diff against reference agents/skills)
- **Total**: ~1.5 hours

## References

- `/home/benjamin/.config/nvim/.claude/agents/general-implementation-agent.md` -- Reference agent with all patterns
- `/home/benjamin/.config/nvim/.claude/agents/latex-implementation-agent.md` -- Reference for non-meta completion_data
- `/home/benjamin/.config/nvim/.claude/agents/typst-implementation-agent.md` -- Reference for non-meta completion_data
- `/home/benjamin/.config/nvim/.claude/agents/neovim-implementation-agent.md` -- Target agent (missing patterns)
- `/home/benjamin/.config/nvim/.claude/skills/skill-implementer/SKILL.md` -- Reference skill with all patterns
- `/home/benjamin/.config/nvim/.claude/skills/skill-neovim-implementation/SKILL.md` -- Target skill (missing patterns)
- `/home/benjamin/.config/nvim/specs/045_fix_logosweb_agent_gaps_from_task_44/reports/research-001.md` -- Parent task research establishing gap categories

## Next Steps

Run `/plan 48` to create an implementation plan based on these findings.
