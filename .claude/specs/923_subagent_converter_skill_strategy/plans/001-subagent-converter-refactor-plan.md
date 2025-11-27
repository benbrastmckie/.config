# /convert-docs Subagent-First Refactor Plan

## Metadata

- **Date**: 2025-11-23
- **Feature**: Refactor /convert-docs to use subagent as primary approach with skill support
- **Scope**: Command restructure, agent updates, standards alignment
- **Estimated Phases**: 4 (0-3)
- **Estimated Hours**: 5-7
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 42 (Tier 2)
- **Revision History**:
  - 2025-11-23: Plan created
- **Research Reports**:
  - [Skills Usage Analysis](/home/benjamin/.config/.claude/specs/922_skills_convert_docs_usage/reports/001_skills_usage_analysis.md)
  - [Subagent Architecture Analysis](/home/benjamin/.config/.claude/specs/923_subagent_converter_skill_strategy/reports/001_subagent_architecture_analysis.md)
  - [Standards Conformance Analysis](/home/benjamin/.config/.claude/specs/923_subagent_converter_skill_strategy/reports/002_standards_conformance_analysis.md)
  - [Convert Docs Fidelity Plan](/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md)

## Overview

Refactor `/convert-docs` to implement a **subagent-first architecture** where:

1. **Primary Path**: Command invokes converter subagent via Task tool
2. **Skill Loading**: Agent has `skills: document-converter` in frontmatter
3. **Parallel Default**: Conversions run in parallel by default (--sequential to disable)
4. **Script Fallback**: Falls back to script if agent invocation fails
5. **Simplified Structure**: Remove STEP 0/STEP 3.5, use natural STEP numbering (1-6)
6. **Standards Alignment**: Console summary uses 4-section format, documentation updated

## Architecture

```
/convert-docs <input> <output> [--no-api] [--sequential]
                    |
                    v
          +------------------+
          | STEP 1: Init     |
          | Error Logging    |
          +--------+---------+
                   |
                   v
          +------------------+
          | STEP 2: Parse    |
          | Arguments        |
          +--------+---------+
                   |
                   v
          +------------------+
          | STEP 3: Validate |
          | Input Path       |
          +--------+---------+
                   |
                   v
          +------------------+
          | STEP 4: Invoke   |
          | Converter Agent  |<---- Agent has skills: document-converter
          | (parallel mode)  |      Parallel by default
          +--------+---------+
                   |
              [success?]
              /        \
           Yes          No
            |            |
            v            v
     +----------+  +-----------+
     | STEP 6:  |  | STEP 5:   |
     | Summary  |  | Script    |
     +----------+  | Fallback  |
                   +-----+-----+
                         |
                         v
                   +----------+
                   | STEP 6:  |
                   | Summary  |
                   +----------+
```

## Success Criteria

### Functional Requirements
- [ ] Subagent invocation is default (no flag required)
- [ ] Agent correctly loads document-converter skill
- [ ] All 6 conversion directions work (PDF/DOCX/MD bidirectional)
- [ ] --no-api flag passes through to agent
- [ ] Parallel processing is default (--sequential disables)
- [ ] Script fallback activates on agent failure

### Architecture Requirements
- [ ] STEP 0 (skill check) removed from command
- [ ] STEP 3.5 (skill delegation) removed from command
- [ ] --use-agent flag removed
- [ ] STEP numbering uses natural integers (1-6)
- [ ] Agent frontmatter verified (`skills: document-converter`)
- [ ] Skill contains complete conversion matrix
- [ ] Standards documentation updated to reflect agent-based skill loading

### Standards Compliance
- [ ] Error logging preserved (STEP 1 initialization)
- [ ] Console summary uses 4-section format (Summary/Artifacts/Next Steps)
- [ ] Three-tier library sourcing in fallback script
- [ ] Role clarification aligned with behavioral-injection.md orchestrator pattern
- [ ] All documentation updated (5+ files)

## Implementation Phases

### Phase 0: Validate Current State [COMPLETE]
dependencies: []

**Objective**: Verify current implementation state and identify exact changes needed

**Complexity**: Low

Tasks:
- [x] Read `/convert-docs` command and identify all STEPs
- [x] Verify `doc-converter.md` has `skills: document-converter`
- [x] Verify `document-converter` skill has complete conversion matrix
- [x] Document STEP 0/STEP 0.5/STEP 3/STEP 3.5 code to be removed
- [x] Create backup of files before modification

Testing:
```bash
# Verify agent has skills field
grep -A5 "^---" .claude/agents/doc-converter.md | grep skills

# Verify skill exists
ls -la .claude/skills/document-converter/SKILL.md

# Document current steps in command
grep -n "STEP" .claude/commands/convert-docs.md | head -20
```

**Expected Duration**: 0.5 hours

---

### Phase 1: Restructure Command [COMPLETE]
dependencies: [0]

**Objective**: Remove STEP 0/3.5 skill integration, make agent invocation default with parallel by default, update console summary format

**Complexity**: Medium

#### 1.1 Remove Skill Detection and Delegation

Tasks:
- [x] Remove STEP 0 (skill availability check) from convert-docs.md
  - Location: Lines with `SKILL_AVAILABLE`, `SKILL_PATH`
  - Remove the entire bash block for skill detection
- [x] Remove STEP 3.5 (skill delegation) from convert-docs.md
  - Location: Section with "natural language delegation"
  - Remove entire conditional block
- [x] Remove `skip_to_step_6` variable and related logic
- [x] Remove `--use-agent` flag handling

#### 1.2 Renumber STEPs (Natural Numbering)

STEP structure:
```
STEP 1: Environment Initialization + Error Logging
STEP 2: Parse Arguments
STEP 3: Validate Input Path
STEP 4: Invoke Converter Agent
STEP 5: Fallback Script Mode
STEP 6: Verification and Summary
```

**Critical**: Include error logging initialization in STEP 1:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "CRITICAL ERROR: Cannot load error-handling library"
  exit 1
}
ensure_error_log_exists
COMMAND_NAME="/convert-docs"
WORKFLOW_ID="convert_$(date +%s)"
USER_ARGS="$*"
```

#### 1.3 Implement Agent-First with Parallel Default

Tasks:
- [x] Change `--parallel` flag to `--sequential` (invert the default)
- [x] Pass `parallel_mode=true` by default to agent
- [x] Add `--sequential` flag to disable parallel processing

STEP 4 structure:
```markdown
### STEP 4 (REQUIRED) - Invoke Converter Agent

**EXECUTE NOW**: Use Task tool to invoke converter agent with parsed arguments.

Task {
  subagent_type: "general-purpose"
  description: "Convert documents from $input_dir to $output_dir"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-converter.md

    REQUIRED PARAMETERS:
    - Input Directory: $input_dir
    - Output Directory: $output_dir
    - Offline Mode: $offline_flag (--no-api was passed: true/false)
    - Parallel Mode: $parallel_flag (default: true, --sequential sets to false)
    - File Count: $file_count files to convert

    Execute conversion and return:
    CONVERSION_COMPLETE: $output_dir ($success_count files converted)
}
```

#### 1.4 Add Script Fallback

STEP 5 structure:
```markdown
### STEP 5 (FALLBACK) - Script Mode

**EXECUTE ONLY IF**: Agent invocation in STEP 4 failed

**FALLBACK TRIGGER**: If STEP 4 did not return CONVERSION_COMPLETE signal

Execute script-based conversion:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"
main_conversion "$input_dir" "$OUTPUT_DIR_ABS"
```
```

#### 1.5 Update Console Summary Format (STEP 6)

**Requirement**: STEP 6 output uses output-formatting.md 4-section standard.

Format:
```markdown
### STEP 6 (REQUIRED) - Verification and Summary

**OUTPUT FORMAT** (4-section standard):

=== Document Conversion Complete ===

Summary: Converted $output_count of $file_count files from $input_dir to $output_dir using agent-based conversion with document-converter skill.

Artifacts:
  Converted: $output_dir/ ($output_count files)
  Log: $output_dir/conversion.log

Next Steps:
  Review log: cat $output_dir/conversion.log
  Check quality: ls -la $output_dir/
```

#### 1.6 Update Role Clarification

Update YOUR ROLE section to align with behavioral-injection.md orchestrator pattern:
```markdown
**YOUR ROLE**: You are the CONVERSION COORDINATOR.
- **Primary Path**: Invoke doc-converter agent via Task tool
- **Fallback Path**: Only invoke convert-core.sh script if agent fails
- **DO NOT** execute conversion yourself using Read/Write/Bash tools
```

Testing:
```bash
# Test default path (should use agent with parallel)
/convert-docs test/ output/
# Should show agent invocation with parallel mode

# Test with offline flag
/convert-docs test/ output/ --no-api
# Should pass --no-api to agent

# Test sequential mode
/convert-docs test/ output/ --sequential
# Should disable parallel processing

# Verify error logging preserved
/convert-docs nonexistent/ output/
/errors --command /convert-docs --limit 1
# Should show logged error
```

**Expected Duration**: 2-2.5 hours

---

### Phase 2: Verify Agent and Skill Configuration [COMPLETE]
dependencies: [1]

**Objective**: Confirm agent and skill work correctly with parallel-by-default

**Complexity**: Low

**Note**: `doc-converter.md` has `skills: document-converter` in frontmatter. This phase focuses on parallel default handling.

#### 2.1 Verify Agent Configuration (Confirmation Only)

Tasks:
- [x] Confirm `doc-converter.md` has `skills: document-converter` in frontmatter
- [x] Confirm agent references skill for conversion logic

**Expected**: No changes needed.

#### 2.2 Update Agent for Parallel Default Handling

Tasks:
- [x] Update agent to expect `parallel_mode=true` as default parameter
- [x] Add parameter handling documentation for inverted flag:
  ```markdown
  ## Parameter Handling

  When invoked by /convert-docs, I receive:
  - Input/Output directories
  - Offline Mode flag (use local tools only)
  - Parallel Mode flag (default: true, --sequential sets to false)
  ```
- [x] Verify agent handles both sequential and parallel modes correctly

#### 2.3 Verify Skill Completeness (Confirmation Only)

Tasks:
- [x] Confirm SKILL.md has complete conversion matrix (all 6 directions)
- [x] Confirm tool priority documented:
  - PDF->MD: Gemini API (default) / PyMuPDF4LLM (offline)
  - PDF->DOCX: pdf2docx
  - DOCX->MD: MarkItDown
  - DOCX->PDF: via Markdown
  - MD->DOCX: Pandoc
  - MD->PDF: Pandoc + Typst
- [x] Confirm dependencies section includes google-genai (optional)

**Expected**: No changes needed.

Testing:
```bash
# Test agent with parallel default
/convert-docs test/ output/
# Agent should use parallel mode

# Test agent with sequential override
/convert-docs test/ output/ --sequential
# Agent should use sequential mode
```

**Expected Duration**: 0.5-1 hour

---

### Phase 3: Update Standards Documentation [COMPLETE]
dependencies: [1, 2]

**Objective**: Update ALL documentation to reflect agent-based skill loading architecture

**Complexity**: MEDIUM (affects 5+ files with architectural implications)

**Critical**: This phase affects architectural understanding across the project. All files must be updated consistently to avoid documentation drift.

#### 3.1 Update skills-authoring.md (PRIMARY)

File: `.claude/docs/reference/standards/skills-authoring.md`
Lines: 233-363

Tasks:
- [x] Locate "Command Delegation Pattern" section (lines 233-256)
- [x] Remove STEP 0/STEP 3.5 pattern documentation
- [x] Document agent-based skill loading pattern:

```markdown
### Command Delegation Pattern

Commands that need skill capabilities delegate to agents:

1. Command invokes agent via Task tool
2. Agent has `skills: skill-name` in frontmatter
3. Agent receives skill context automatically
4. Agent executes using skill instructions

**Example** (convert-docs):
```yaml
# .claude/agents/doc-converter.md
---
skills: document-converter
---
```

```markdown
# .claude/commands/convert-docs.md
Task {
  subagent_type: "general-purpose"
  prompt: "Read and follow: .claude/agents/doc-converter.md ..."
}
```
```

#### 3.2 Update skills/README.md

File: `.claude/skills/README.md`
Lines: 162-171

Tasks:
- [x] Update "From Commands" section to reflect agent delegation
- [x] Remove direct command-skill integration example

```markdown
### From Commands

Commands delegate to agents that load skills:

```bash
/convert-docs ./documents ./output
# 1. Command invokes doc-converter agent
# 2. Agent has skills: document-converter
# 3. Agent loads skill and executes conversion
```

Commands do NOT load skills directly. Skill context is loaded
by agents via the `skills:` frontmatter field.
```

#### 3.3 Update directory-organization.md

File: `.claude/docs/concepts/directory-organization.md`
Lines: 174-178

Tasks:
- [x] Update "Integration Patterns" section
- [x] Remove command delegation pattern

```markdown
**Integration Patterns**:
1. **Autonomous**: Claude detects need and loads skill automatically
2. **Agent Auto-Loading**: Agents use `skills:` frontmatter field
```

#### 3.4 Update CLAUDE.md skills_architecture Section

File: `CLAUDE.md`
Section: `<!-- SECTION: skills_architecture -->`

Tasks:
- [x] Review skills_architecture section
- [x] Ensure it documents agent-based skill loading as primary pattern
- [x] Remove STEP 0/STEP 3.5 command pattern references
- [x] Update integration patterns table:

```markdown
**Integration Patterns**:
1. **Autonomous**: Claude detects need and loads skill automatically
2. **Agent Auto-Loading**: Agents use `skills:` frontmatter field
```

#### 3.5 Update behavioral-injection.md (If Applicable)

File: `.claude/docs/concepts/patterns/behavioral-injection.md`

Tasks:
- [x] Check if file references skill patterns
- [x] If so, ensure consistency with updated patterns
- [x] Verify orchestrator role description aligns with convert-docs.md update

Testing:
```bash
# Verify STEP 0/STEP 3.5 removed from all documentation
grep -r "STEP 0" .claude/docs/ .claude/skills/
# Should find no references

grep -r "STEP 3.5" .claude/docs/ .claude/skills/
# Should find no references

# Verify agent-based pattern documented
grep -r "skills:" .claude/agents/*.md
# Should show agents that load skills
```

**Expected Duration**: 1.5-2 hours

---

## Testing Strategy

### Unit Tests
- [ ] Argument parsing with --sequential flag
- [ ] Agent invocation with parameter passing
- [ ] Fallback trigger on agent failure
- [ ] Error logging initialization verification

### Integration Tests
- [ ] Full conversion flow via agent (default path)
- [ ] All 6 conversion directions
- [ ] Offline mode (--no-api)
- [ ] Sequential mode (--sequential)
- [ ] Parallel mode (default)

### Regression Tests
- [ ] Existing convert tests pass (update expected behavior)
- [ ] Error logging still works
- [ ] Console summary format uses 4-section standard

### Documentation Consistency Test (Recommended)
- [ ] Validate no STEP 0/STEP 3.5 patterns remain in documentation
- [ ] Validate agent-based skill loading is documented consistently

### Test Commands
```bash
# Basic conversion (should use agent with parallel)
/convert-docs test/pdf/ output/

# Offline mode
/convert-docs test/pdf/ output/ --no-api

# Sequential mode (disable parallel)
/convert-docs test/batch/ output/ --sequential

# Combined flags
/convert-docs test/batch/ output/ --no-api --sequential

# Error case (should show error logging)
/convert-docs nonexistent/ output/
/errors --command /convert-docs --limit 1

# Fallback test (simulate agent failure)
# Manual test: modify agent to return error, verify script fallback

# Documentation consistency check
grep -r "STEP 0" .claude/docs/ .claude/skills/
# Should return empty (no STEP 0 references)
```

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Agent invocation overhead | Low | Low | Agent is fast, skill loading is cached |
| Fallback not triggering | Low | Medium | Explicit error checking before fallback |
| Skill not loading in agent | Low | High | Verify skills field present in agent frontmatter |
| Documentation inconsistency | Medium | Medium | Phase 3 comprehensive update, grep validation |
| Error logging not working | Low | High | Ensure error logging in STEP 1 |

## Dependencies

### Files Modified
| File | Change Type | Complexity |
|------|-------------|------------|
| `.claude/commands/convert-docs.md` | Major restructure | High |
| `.claude/agents/doc-converter.md` | Minor (parallel default only) | Low |
| `.claude/skills/document-converter/SKILL.md` | None (verification only) | None |
| `.claude/docs/reference/standards/skills-authoring.md` | Medium (update pattern) | Medium |
| `.claude/skills/README.md` | Minor (update examples) | Low |
| `.claude/docs/concepts/directory-organization.md` | Minor (update patterns) | Low |
| `CLAUDE.md` | Minor (skills_architecture section) | Low |
| `.claude/docs/concepts/patterns/behavioral-injection.md` | Minor (if applicable) | Low |

### No Changes Required
- `.claude/lib/convert/convert-core.sh` - Used as fallback, unchanged
- `.claude/lib/convert/*.sh` - Conversion scripts unchanged

## Summary

| Aspect | Target State |
|--------|--------------|
| Default path | Agent invocation via Task tool |
| Skill loading | Via agent frontmatter (`skills: document-converter`) |
| Execution paths | 2 paths (agent primary, script fallback) |
| Parallel mode | Default enabled (--sequential to disable) |
| Flags | --no-api, --sequential |
| STEP numbering | Natural integers (1-6) |
| Console summary | 4-section standard format |
| Documentation | Agent-based skill loading pattern |
| Error logging | Initialized in STEP 1 |

---

**Plan Generated**: 2025-11-23
**Plan Architect**: Claude (plan-architect agent)
**Complexity Level**: 42 (Tier 2)
**Status**: [NOT STARTED]
