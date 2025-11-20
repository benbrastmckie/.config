# README.md Revision Analysis Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: README.md revision for adaptive plan structures, standards discovery, and examples consolidation
- **Report Type**: codebase analysis

## Executive Summary

The /home/benjamin/.config/.claude/commands/README.md requires targeted revisions to improve three key sections: Adaptive Plan Structures needs workflow-focused description with expansion results, Standards Discovery requires consolidation with links to existing documentation resources, and Examples should be distributed inline with their respective commands in Available Commands section.

## Findings

### 1. Current README.md Structure Analysis

**File Location**: `/home/benjamin/.config/.claude/commands/README.md` (816 lines)

**Key Sections Identified**:
- `## Adaptive Plan Structures` (lines 476-533): Documents progressive organization but lacks workflow description and expansion results
- `## Standards Discovery` (lines 535-566): Contains inline documentation that duplicates existing resources
- `## Documentation Standards` (lines 637-647): Brief section that could be merged into Standards Discovery
- `## Examples` (lines 725-815): Standalone section with examples not tied to specific commands
- `## Available Commands` (lines 103-201): Individual command documentation without inline examples

**Section Analysis**:

**Adaptive Plan Structures (lines 476-533)**:
- Documents Level 0/1/2 structure
- Lists parsing utilities
- Missing: workflow description (how /expand and /collapse work), example expansion results, progressive workflow narrative

**Standards Discovery (lines 535-566)**:
- Contains inline Standards Sections Used list
- Duplicates content from CLAUDE.md sections
- No links to actual documentation files
- Redundant with existing resources in .claude/docs/

**Examples (lines 725-815)**:
- 91 lines of examples in standalone section
- Categories: Running Implementation, Research Workflows, Progressive Plan Management, Full Workflow Examples, Using Flags
- Better suited inline with each command in Available Commands section

### 2. Existing Documentation Resources

**Key resources in .claude/docs/ that overlap with Standards Discovery content**:

| Resource | Path | Overlap with Standards Discovery |
|----------|------|----------------------------------|
| Directory Protocols | `.claude/docs/concepts/directory-protocols.md` | Topic-based organization, artifact directories |
| Code Standards | `.claude/docs/reference/code-standards.md` | Indentation, naming, error handling |
| Writing Standards | `.claude/docs/concepts/writing-standards.md` | Documentation standards, timeless writing |
| Output Formatting | `.claude/docs/reference/output-formatting-standards.md` | Output suppression, block consolidation |
| Command Reference | `.claude/docs/reference/command-reference.md` | Full command catalog |
| Testing Protocols | `.claude/docs/reference/testing-protocols.md` | Test patterns, coverage |
| Adaptive Planning Guide | `.claude/docs/workflows/adaptive-planning-guide.md` | Plan structures, complexity, checkpointing |
| Adaptive Planning Config | `.claude/docs/reference/adaptive-planning-config.md` | Thresholds, configuration |

**Resources for Documentation Standards**:
- `.claude/docs/concepts/writing-standards.md` (lines 46-66): Documentation Standards section with present-focused writing, no historical markers
- Code Standards in CLAUDE.md includes documentation policy

### 3. Plan Expansion Workflow Analysis

**How /expand works** (from `/home/benjamin/.config/.claude/commands/expand.md`):

**Workflow Description**:
1. **Input**: Plan file path (Level 0) or plan directory (Level 1)
2. **Analysis**: Detect structure level and complexity
3. **Execution**:
   - Auto mode: Invoke complexity-estimator agent to identify phases >=8 complexity
   - Explicit mode: Expand specified phase/stage
4. **Output**: Creates expanded files with detailed implementation specifications

**Results of Progressive Expansion**:

**Level 0 to Level 1 (Phase Expansion)**:
- Input: `specs/plans/007_feature.md` (single file)
- Output: `specs/plans/007_feature/` directory containing:
  - `007_feature.md` (main plan with phase summaries)
  - `phase_2_components.md` (expanded phase, 300-500 lines)
- Metadata updates: Structure Level: 0 to 1, Expanded Phases list
- Phase transformed from 30-50 line outline to 300-500+ line specification

**Level 1 to Level 2 (Stage Expansion)**:
- Input: `specs/plans/007_feature/phase_2_components.md`
- Output: `specs/plans/007_feature/phase_2_components/` directory containing:
  - `phase_2_components.md` (overview)
  - `stage_1_setup.md`, `stage_2_impl.md` (stage files)
- Three-way metadata update: stage to phase to main plan

**Key Expansion Benefits**:
- 30-50 line outlines become 300-500+ line specifications
- Concrete implementation details, code examples, testing specifications
- Architecture decisions, error handling patterns, performance considerations

**How /collapse works** (from README.md lines 227-243):
- Reverses expansion: merges content back to parent
- Level 2 to 1 or Level 1 to 0 transitions
- Directory cleanup and metadata updates

### 4. Documentation Standards Content

**Current Documentation Standards section** (lines 637-647):
```markdown
## Documentation Standards

All commands follow documentation standards:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **Complete workflows** from start to finish
- **CommonMark** specification

See [Neovim Code Standards](../../nvim/docs/CODE_STANDARDS.md) for complete standards.
```

**Should be integrated into Standards Discovery because**:
- Related to standards that commands should follow
- Could reference `.claude/docs/concepts/writing-standards.md` for comprehensive documentation
- Brevity maintained while providing navigation to full documentation

### 5. Available Commands Lacking Inline Examples

Commands in Available Commands section (lines 103-201) that could benefit from inline examples:

| Command | Has Example | Recommended Example |
|---------|-------------|---------------------|
| /build | No | `/build specs/plans/007_dark_mode.md` |
| /debug | No | `/debug "Login tests failing with timeout"` |
| /plan | No | `/plan "Add dark mode toggle"` |
| /research | No | `/research "Authentication best practices"` |
| /expand | No | `/expand phase specs/plans/015.md 2` |
| /collapse | No | `/collapse specs/plans/015_dashboard/ 5` |
| /revise | No | `/revise "Add Phase 9 to specs/plans/015.md"` |
| /setup | No | `/setup --analyze` |
| /convert-docs | No | `/convert-docs ./docs ./output` |

## Recommendations

### Recommendation 1: Revise Adaptive Plan Structures Section

**Current Issue**: Section describes structure levels but doesn't explain the workflow or show results.

**Proposed Structure**:

```markdown
## Adaptive Plan Structures

Commands support progressive plan organization that grows based on actual complexity discovered during implementation.

### Expansion Workflow

Plans grow organically as complexity emerges:

1. **All plans start as Level 0** (single file)
2. **Run `/expand phase <plan> <phase-num>`** when a phase becomes too complex
3. **Run `/expand stage <phase> <stage-num>`** when phases need multi-stage breakdown
4. **Use `/collapse`** commands to simplify structure when phases are reduced

### Structure Levels

**Level 0: Single File**
- Format: `specs/plans/001_feature.md`
- All phases and tasks inline
- Example: `/plan "Add button fix"` creates `specs/plans/001_button_fix.md`

**Level 1: Phase Expansion**
- Format: `specs/plans/015_dashboard/`
- Main plan with phase summaries + separate phase files
- Example: `/expand phase specs/plans/015_dashboard.md 2` creates:
  - `015_dashboard.md` (main plan with Phase 2 summary)
  - `phase_2_components.md` (300-500 line detailed specification)

**Level 2: Stage Expansion**
- Format: `specs/plans/020_refactor/phase_1_analysis/`
- Phase directories with stage subdirectories
- Example: `/expand stage specs/plans/020_refactor/phase_1_analysis.md 1` creates stage files

### Expansion Results

When a phase is expanded:
- **Input**: 30-50 line phase outline
- **Output**: 300-500+ line implementation specification with:
  - Concrete implementation details and code examples
  - Specific testing specifications
  - Architecture and design decisions
  - Error handling patterns
  - Performance considerations

### Parsing Utility
[Keep existing parsing utility section]
```

### Recommendation 2: Consolidate Standards Discovery Section

**Current Issue**: Contains inline content that duplicates existing documentation. Lacks clear links to resources.

**Proposed Structure**:

```markdown
## Standards Discovery

Commands discover and apply project standards through CLAUDE.md and its linked documentation.

### Discovery Process

1. **Locate CLAUDE.md**: Search upward from working directory
2. **Parse Sections**: Extract relevant `[Used by: commands]` sections
3. **Check Subdirectories**: Look for directory-specific CLAUDE.md overrides
4. **Apply Fallbacks**: Use language-specific defaults if standards missing

### Key Standards Resources

| Standard | Resource | Used By |
|----------|----------|---------|
| Code Standards | [Code Standards](../docs/reference/code-standards.md) | /plan, /build, /refactor |
| Testing Protocols | [Testing Protocols](../docs/reference/testing-protocols.md) | /build, /test |
| Output Formatting | [Output Formatting](../docs/reference/output-formatting-standards.md) | All commands |
| Directory Protocols | [Directory Protocols](../docs/concepts/directory-protocols.md) | /plan, /research, /build |
| Writing Standards | [Writing Standards](../docs/concepts/writing-standards.md) | /document, /plan |
| Adaptive Planning | [Adaptive Planning Guide](../docs/workflows/adaptive-planning-guide.md) | /expand, /collapse, /build |

### Documentation Standards

All commands produce documentation following these standards:
- **NO emojis** in file content (UTF-8 encoding issues)
- **Unicode box-drawing** for diagrams
- **Clear examples** with syntax highlighting
- **Complete workflows** from start to finish
- **CommonMark** specification
- **Present-focused writing** (no historical markers)

See [Writing Standards](../docs/concepts/writing-standards.md) for comprehensive documentation guidelines.
```

### Recommendation 3: Distribute Examples to Available Commands

**Current Issue**: Examples are in a standalone section, requiring users to scroll down to find usage patterns.

**Implementation Approach**:

For each command in Available Commands, add a brief inline example after Features:

```markdown
#### /build
**Purpose**: Build-from-plan workflow...

**Usage**: `/build [plan-file] [starting-phase] [--dry-run]`

**Type**: primary

**Example**:
```bash
/build specs/plans/007_dark_mode_implementation.md
```

**Dependencies**: ...
```

**Examples to distribute**:
- `/build`: `/build specs/plans/007_dark_mode_implementation.md`
- `/debug`: `/debug "Login tests failing with timeout error"`
- `/plan`: `/plan "Add dark mode toggle to settings"`
- `/research`: `/research "Authentication best practices"`
- `/revise`: `/revise "Add Phase 9 to specs/plans/015_api.md"`
- `/expand`: `/expand phase specs/plans/015_dashboard.md 2`
- `/collapse`: `/collapse specs/plans/015_dashboard/ 5`
- `/setup`: `/setup --analyze`
- `/convert-docs`: `/convert-docs ./docs ./output`

**Remove Examples Section**: Delete lines 725-815 after distributing examples.

### Recommendation 4: Create Implementation Plan Structure

The plan should include these phases:

**Phase 1: Revise Adaptive Plan Structures**
- Read current section
- Rewrite with workflow description
- Add expansion results details
- Include concrete examples

**Phase 2: Consolidate Standards Discovery**
- Extract redundant content
- Create resource table with links
- Merge Documentation Standards
- Verify all links work

**Phase 3: Distribute Examples**
- Add inline example to each command
- Verify example syntax matches command usage
- Remove standalone Examples section

**Phase 4: Validate and Test**
- Run link validation
- Test example commands
- Review for completeness

### Recommendation 5: Preserve Key Information

During revision, preserve:
- Parsing Utility section (lines 512-533) - advanced users need this
- Command Architecture diagram (lines 54-100)
- Command Definition Format (lines 438-475)
- Creating Custom Commands (lines 569-594)

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-816)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 1-1124)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 1-1149)
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` (lines 1-118)
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558)
- `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md` (lines 1-299)
- `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md` (lines 1-477)

### Related Documentation
- [Command Reference](../docs/reference/command-reference.md) - Full command documentation
- [Adaptive Planning Config](../docs/reference/adaptive-planning-config.md) - Complexity thresholds
- [CLAUDE.md](../../CLAUDE.md) - Project standards index

### Implementation Notes

**Estimated Changes**:
- Adaptive Plan Structures: Expand from ~57 lines to ~80 lines (add workflow, examples)
- Standards Discovery: Reduce from ~32 lines to ~40 lines (consolidate, add table)
- Examples section: Remove ~91 lines
- Available Commands: Add ~27 lines (9 examples, 3 lines each)
- Net change: -43 lines (improved organization)
