# Implementation Plan: Task #48

- **Task**: 48 - Add Phase Checkpoint Protocol to neovim-implementation-agent
- **Status**: [IMPLEMENTING]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: meta
- **Lean Intent**: false
- **Date**: 2026-02-05
- **Feature**: Add missing Phase Checkpoint Protocol, Stage 6a, and completion_data patterns to neovim agent and skill
- **Estimated Hours**: 1-2 hours
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: [research-001.md](../reports/research-001.md)

## Overview

The neovim-implementation-agent and its invoking skill (skill-neovim-implementation) are missing several patterns that all other implementation agents/skills already have: the Phase Checkpoint Protocol (per-phase git commits), Stage 6a (Generate Completion Data), completion_data in metadata, and completion_data extraction/propagation in the skill postflight. This plan adds all 8 identified gaps (4 agent-level, 4 skill-level) by adapting the proven patterns from the general-implementation-agent and skill-implementer as reference implementations.

### Research Integration

The research report identified 8 specific gaps organized into agent-level (G1-G4) and skill-level (S1-S4) categories. All gaps have exact line-number references for insertion points and proven code patterns from reference files. The neovim agent's Stage 4 already handles plan file status markers correctly; the missing pieces are the per-phase git commits, completion_data generation, and skill-side data propagation.

## Goals & Non-Goals

**Goals**:
- Add Phase Checkpoint Protocol section to neovim-implementation-agent.md with per-phase git commits
- Add Stage 6a: Generate Completion Data to neovim-implementation-agent.md
- Add completion_data field to the agent's Stage 7 metadata JSON template
- Add partial_progress update directive to the agent's Critical Requirements
- Add subagent return format validation (Stage 5a) to skill-neovim-implementation/SKILL.md
- Add completion_data extraction from metadata file to the skill's Stage 6
- Add completion_data propagation to state.json in the skill's Stage 7
- Add concrete partial plan file status update code to the skill's Stage 7

**Non-Goals**:
- Modifying any reference agents/skills (general, LaTeX, Typst)
- Changing the neovim agent's existing Stage 4 execution loop structure
- Adding meta-task completion_data patterns (neovim tasks are always non-meta)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Edit tool uniqueness failures due to similar markdown patterns | M | M | Use sufficiently large context strings in old_string to ensure uniqueness |
| Structural inconsistency with reference agents | M | L | Verify final structure matches latex-implementation-agent section ordering |
| Accidental modification of existing Stage 4 logic | H | L | Only add new sections; do not modify existing Stage 4 A/B/C/D sub-steps |

## Implementation Phases

### Phase 1: Add Agent-Level Gaps (G1-G4) [COMPLETED]

**Goal**: Add the four missing sections/fields to neovim-implementation-agent.md

**Tasks**:
- [ ] G2: Insert Stage 6a (Generate Completion Data) between current Stage 6 and Stage 7
- [ ] G3: Add completion_data field to the Stage 7 metadata JSON template
- [ ] G4: Add "Update partial_progress after each phase completion" to MUST DO list in Critical Requirements
- [ ] G1: Insert Phase Checkpoint Protocol section between Error Handling and Critical Requirements

**Timing**: 0.75 hours

**Files to modify**:
- `.claude/agents/neovim-implementation-agent.md` - Add G1, G2, G3, G4

**Steps**:

1. **G2 - Add Stage 6a between Stage 6 and Stage 7**: Insert new "Stage 6a: Generate Completion Data" section after the implementation summary section (Stage 6) and before the metadata file section (Stage 7). Use the latex-implementation-agent pattern (non-meta variant with completion_summary and roadmap_items) adapted with Neovim-specific examples.

2. **G3 - Add completion_data to Stage 7 JSON**: Insert the completion_data field into the JSON template in Stage 7, between the artifacts array and the metadata object. Add the Note about including completion_data when status is implemented.

3. **G4 - Add partial_progress to Critical Requirements**: Add item 9 "Update partial_progress after each phase completion" to the MUST DO list, and add item 7 "Skip Stage 0 early metadata creation" to the MUST NOT list (renumbering as needed to match the general-implementation-agent pattern).

4. **G1 - Add Phase Checkpoint Protocol section**: Insert the Phase Checkpoint Protocol section after the Error Handling section and before the Critical Requirements section. Use the general-implementation-agent pattern with "Execute Neovim configuration changes" as the domain-specific step 3 description, and "Failed phases can be retried from beginning" as the ensures bullet.

**Verification**:
- Read the modified file and verify all four sections are present
- Verify Stage numbering is sequential (6, 6a, 7, 8)
- Verify Phase Checkpoint Protocol section matches the 6-step structure from reference agents
- Verify completion_data JSON structure matches latex-implementation-agent pattern
- Verify Critical Requirements MUST DO list has partial_progress item

---

### Phase 2: Add Skill-Level Gaps (S1-S4) [NOT STARTED]

**Goal**: Add the four missing code blocks/sections to skill-neovim-implementation/SKILL.md

**Tasks**:
- [ ] S3: Insert Stage 5a (Validate Subagent Return Format) between Stage 5 and Stage 6
- [ ] S1: Add completion_data extraction to Stage 6 (Parse Subagent Return)
- [ ] S2: Add completion_data propagation to Stage 7 (Update Task Status) for the "implemented" case
- [ ] S4: Add concrete partial plan file status update code to Stage 7 for the "partial/failed" case

**Timing**: 0.5 hours

**Files to modify**:
- `.claude/skills/skill-neovim-implementation/SKILL.md` - Add S1, S2, S3, S4

**Steps**:

1. **S3 - Add Stage 5a**: Insert new "Stage 5a: Validate Subagent Return Format" section between the current Stage 5 (Invoke Subagent) and Stage 6 (Parse Subagent Return). Copy the pattern from skill-implementer lines 175-196.

2. **S1 - Add completion_data extraction to Stage 6**: Append the completion_data field extraction lines (completion_summary and roadmap_items) to the existing bash block in Stage 6 that reads the metadata file. These go after the phases_total extraction line.

3. **S2 - Add completion_data propagation to Stage 7**: After the existing state.json status/timestamp update in the "implemented" case, add the completion_summary propagation block and the roadmap_items propagation block. Since neovim is never meta, omit the claudemd_suggestions block (unlike skill-implementer which handles meta).

4. **S4 - Add partial plan file status update code**: Replace the text-only "On partial/failed" description with a concrete code block that updates the plan file status to [PARTIAL], using the dual-pattern sed + verification approach already used in the [COMPLETED] case above it.

**Verification**:
- Read the modified file and verify all four additions are present
- Verify Stage numbering is sequential (5, 5a, 6, 7, ...)
- Verify completion_data extraction in Stage 6 has both completion_summary and roadmap_items
- Verify completion_data propagation in Stage 7 uses the jq "| not" safe pattern where applicable
- Verify partial plan file update uses the same dual-pattern sed + grep verification as the [COMPLETED] case

---

### Phase 3: Cross-Validation [NOT STARTED]

**Goal**: Verify structural consistency between the modified neovim files and their reference counterparts

**Tasks**:
- [ ] Compare neovim-implementation-agent.md section structure against latex-implementation-agent.md
- [ ] Compare skill-neovim-implementation/SKILL.md stage structure against skill-implementer/SKILL.md
- [ ] Verify no accidental modifications to existing logic

**Timing**: 0.25 hours

**Files to modify**: None (read-only verification)

**Steps**:

1. **Agent structure comparison**: Read both neovim-implementation-agent.md and latex-implementation-agent.md. Verify the neovim agent now has all the same major sections: Stage 0-8 (including 6a), Phase Checkpoint Protocol, and Critical Requirements with partial_progress item. Note any structural differences and fix if needed.

2. **Skill structure comparison**: Read both skill-neovim-implementation/SKILL.md and skill-implementer/SKILL.md. Verify the neovim skill now has: Stage 5a, completion_data extraction in Stage 6, completion_data propagation in Stage 7, and partial plan file update code in Stage 7. Note that the neovim skill correctly omits meta-task patterns (claudemd_suggestions) since neovim tasks are never meta.

3. **Regression check**: Verify that the neovim agent's Stage 4 (Execute Implementation Loop) with its A/B/C/D sub-steps is unchanged. Verify the skill's existing Stage 2 (preflight plan status update) and Stage 7 (COMPLETED plan status update) code blocks are unchanged.

**Verification**:
- Section count matches expectations (agent has Stages 0-8 including 6a, plus Phase Checkpoint Protocol)
- Skill has Stages 1-11 including 5a
- No existing code blocks were accidentally modified
- Neovim-specific patterns preserved (nvim --headless verification, plugin spec patterns, etc.)

## Testing & Validation

- [ ] Agent file has all 8 standard stages plus Stage 6a
- [ ] Agent file has Phase Checkpoint Protocol section with 6-step structure
- [ ] Agent file has completion_data in Stage 7 JSON template
- [ ] Agent file has partial_progress in Critical Requirements MUST DO list
- [ ] Skill file has Stage 5a (subagent return validation)
- [ ] Skill file has completion_data extraction in Stage 6
- [ ] Skill file has completion_data propagation (completion_summary + roadmap_items) in Stage 7
- [ ] Skill file has concrete partial plan file update code in Stage 7

## Artifacts & Outputs

- Modified: `.claude/agents/neovim-implementation-agent.md` (4 additions)
- Modified: `.claude/skills/skill-neovim-implementation/SKILL.md` (4 additions)
- Created: `specs/048_add_phase_checkpoint_protocol_to_neovim/summaries/implementation-summary-20260205.md`

## Rollback/Contingency

Both target files are under git version control. If implementation introduces errors:
1. `git diff .claude/agents/neovim-implementation-agent.md` to review changes
2. `git checkout -- .claude/agents/neovim-implementation-agent.md` to revert agent
3. `git checkout -- .claude/skills/skill-neovim-implementation/SKILL.md` to revert skill
