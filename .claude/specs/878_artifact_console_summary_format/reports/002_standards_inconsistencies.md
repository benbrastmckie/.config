# Standards Documentation Inconsistencies Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Documentation standards inconsistencies and gaps
- **Report Type**: codebase analysis
- **Related Plan**: /home/benjamin/.config/.claude/specs/878_artifact_console_summary_format/plans/001_artifact_console_summary_format_plan.md

## Executive Summary

Research examining .claude/docs/ standards documentation identified three major inconsistencies: (1) output-formatting.md lacks console summary format specifications while focusing on suppression patterns, (2) emoji usage policy conflicts between code-standards.md ("no emojis") and actual command implementations (emoji-rich console output), and (3) missing documentation on artifact path presentation patterns. The plan proposes emoji-based artifact highlighting, but no standards document authorizes or standardizes emoji vocabulary for terminal output, creating a documentation gap requiring resolution.

## Findings

### Finding 1: Output Formatting Standards Gap - Console Summary Formats

**Location**: /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md

**Analysis**: The output-formatting.md standards document comprehensively covers output suppression patterns (lines 40-157), block consolidation (lines 160-224), and comment standards (lines 228-269), but contains NO guidance on final console summary format structure, artifact path presentation, or user-facing completion messages.

**Current Coverage**:
- ✓ Library sourcing suppression (lines 42-54)
- ✓ Directory operations suppression (lines 97-105)
- ✓ Single summary line pattern (lines 107-129)
- ✓ Block consolidation targets (2-3 blocks, lines 163-171)
- ✓ WHAT not WHY comment enforcement (lines 228-269)

**Missing Coverage**:
- ✗ Console summary structure (no section on final output format)
- ✗ Artifact path highlighting patterns
- ✗ Next steps presentation format
- ✗ Phase status display conventions
- ✗ Distinction between interim suppression vs final summaries

**Evidence from Commands**: Analysis of 8 commands shows inconsistent final output blocks (see 001_artifact_commands_analysis.md:39-100) ranging from minimal key-value pairs (/research:622-630) to structured phase summaries (/build:1422-1458) to checkpoint-based output (/expand, /collapse).

**Impact**: Without standards for final console summaries, each command develops ad-hoc output formats, leading to inconsistent user experience across the .claude/ ecosystem.

**Recommendation**: Add new section to output-formatting.md titled "Console Summary Standards" documenting:
- Standardized section structure (Summary, Phases, Artifacts, Next Steps)
- Artifact path presentation requirements (absolute paths, visual highlighting)
- Phase status display conventions
- Terminal vs file summary distinction (concise vs comprehensive)

---

### Finding 2: Emoji Policy Contradiction

**Locations**:
- /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md:10
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md (no emoji restrictions mentioned)
- /home/benjamin/.config/.claude/specs/878_artifact_console_summary_format/plans/001_artifact_console_summary_format_plan.md:82-90

**Contradiction Analysis**:

**Policy Statement** (code-standards.md:10):
```
- **Character Encoding**: UTF-8 only, no emojis in file content
```

**Interpretation Ambiguity**: The phrase "in file content" could mean:
1. **Narrow interpretation**: No emojis in saved .md/.lua/.sh files (file artifacts)
2. **Broad interpretation**: No emojis anywhere, including terminal stdout

**Plan Specification** (001_artifact_console_summary_format_plan.md:82-90):
```markdown
**Emoji Vocabulary:**
- 📄 Plan files (.md in plans/)
- 📊 Research reports (.md in reports/)
- ✅ Implementation summaries (.md in summaries/)
- 🔧 Debug artifacts (files in debug/)
- 📁 Directory with multiple files
- ✓ Complete phase
- • In-progress/pending phase
```

**Current Command Usage**: Existing commands use checkmark emoji in phase output:
- /build:1422-1458 shows "✓ Phase N: Complete" format
- /debug:1241-1251 uses structured output without emoji
- No commands currently use 📄 📊 ✅ 🔧 emoji markers

**Policy Rationale** (inferred from context):
- UTF-8 encoding issues: Some systems/tools may not render emoji correctly
- File portability: Emoji in saved files creates display inconsistencies
- Terminal vs file distinction: Terminal output typically has better emoji support

**Gap**: No documentation clarifies whether "file content" excludes terminal stdout or whether emoji is acceptable in ephemeral console output vs persistent file artifacts.

**Recommendation**: Update code-standards.md to explicitly distinguish:
- **File Artifacts** (.md, .lua, .sh saved files): NO emoji (current policy)
- **Terminal Output** (stdout/stderr during command execution): ALLOWED with standardized vocabulary
- Add emoji vocabulary specification for terminal output as standards appendix

**Alternative**: If emoji in terminal output violates project philosophy, revise plan to use ASCII symbols:
- `[PLAN]` instead of 📄
- `[REPORT]` instead of 📊
- `[OK]` instead of ✅
- `[DEBUG]` instead of 🔧

---

### Finding 3: Missing Artifact Path Presentation Standards

**Observation**: Commands present artifact paths inconsistently with no documented standard:

**Pattern A: Bare Directory Paths** (/research:624)
```
Reports Directory: /home/user/.claude/specs/NNN_topic/reports
```

**Pattern B: Embedded in Actions** (/debug:1250)
```
- Review debug strategy: cat $PLAN_PATH
```

**Pattern C: Key-Value with Count** (/repair:649)
```
Error Analysis Reports: 2 reports in $RESEARCH_DIR
```

**Pattern D: Structured List** (/build shows phases but not artifacts prominently)

**Gap in Documentation**: No standards document specifies:
- Whether to show directories or individual files
- How to present multi-file artifact collections
- Whether to use absolute or variable paths in output
- Visual highlighting requirements (bold, color, emoji, etc.)
- Grouping conventions (by type, by workflow phase, chronological)

**Plan Proposal** (001_plan.md:68-75):
```markdown
Artifacts:
  📄 Plan: /absolute/path/to/plan.md
  📊 Reports: /absolute/path/to/reports/ (N files)
  ✅ Summary: /absolute/path/to/summary.md
```

**Issue**: This format assumes:
1. Emoji are permitted in terminal output (see Finding 2)
2. Absolute paths should be shown (not documented in standards)
3. Multi-file collections show directory + count (not documented)
4. Artifacts grouped by type, not chronologically (not documented)

**Recommendation**: Add "Artifact Path Presentation" section to output-formatting.md or create new artifact-output-standards.md documenting:
- Absolute path requirement for copy-paste usability
- Directory vs file path decision matrix
- Multi-file collection format: `<emoji> <type>: <path> (N files)`
- Grouping order: reports → plans → summaries → debug (workflow sequence)
- Visual hierarchy: indentation for file lists under directory headings

---

### Finding 4: Command Guide Coverage Gap

**Analysis**: Command guides exist for all 8 artifact-producing commands (lines 391-713 across guide files), but none document expected output format as part of command behavior specification.

**Command Guide Structure** (consistent across all guides):
1. Overview (Purpose, When to Use, When NOT to Use)
2. Architecture (Design Principles, Patterns, States, Integration Points)
3. Usage Examples (with "Expected Output" sections)
4. Advanced Topics
5. Troubleshooting
6. See Also

**Gap in "Expected Output" Sections**:

Example from research-command-guide.md:93-99:
```markdown
### Example 1: Basic Research

/research "authentication patterns in codebase"

**Expected Output**:
=== Research-Only Workflow ===
Description: authentication patterns in codebase
Complexity: 2
```

**Observation**: The "Expected Output" shows initialization, not final console summary. Final summary format is undocumented in command guides.

**Impact**: Users and developers have no reference for what constitutes correct final output format, making it difficult to:
- Verify command behavior during testing
- Identify regressions in output format
- Understand expected user experience
- Design new commands with consistent output

**Recommendation**: Update all command guides to include complete "Expected Output" sections showing:
- Initial workflow messages (current coverage)
- Final console summary (NEW - currently missing)
- Example of complete end-to-end output

This aligns with executable/documentation separation pattern: guides show complete behavior examples while executable files remain lean.

---

### Finding 5: Inconsistency Between Summary .md Files and Console Output

**Analysis**: Implementation summary .md files (created by implementer-coordinator agent) have well-defined comprehensive structure (150-250 lines), but console summaries have no documented target length or conciseness requirements.

**Summary .md Structure** (from 001_artifact_commands_analysis.md:130-169):
- Work Status (completion percentage)
- Metadata (date, plan, metrics)
- Implementation Results > Summary (narrative)
- Phases Completed (detailed breakdown)
- Test Results (metrics)
- Changes Made (files with line numbers)
- Success Criteria Status
- Technical Highlights
- Git Information
- Work Remaining
- Recommendations

**Console Summary Structure** (current, undocumented):
- Variable length (8-25 lines observed across commands)
- Inconsistent sections across commands
- No documented relationship to summary .md files

**Plan Proposal** (001_plan.md:25):
```
Users may need to update scripts that parse command output (rare)
```

**Gap**: Documentation doesn't clarify:
- Console summaries are terse navigation aids (10-25 lines)
- Summary .md files are archival documentation (150-250 lines)
- Console points to summary .md for comprehensive details
- Two distinct artifact types with different purposes

**Risk**: Without clear distinction, implementations may:
- Make console output too verbose (replicating .md content)
- Make summary .md files too terse (missing archival details)
- Create redundancy between the two formats

**Recommendation**: Add "Output Artifact Types" section to directory-protocols.md or output-formatting.md documenting:
- **Console Summary**: Terse (15-25 lines), scannable, highlights artifacts and next steps
- **Summary .md File**: Comprehensive (150-250 lines), archival, complete implementation record
- **Relationship**: Console references summary .md for details
- **Creation**: Console by command, summary .md by implementer-coordinator agent

---

### Finding 6: CLAUDE.md Quick Reference Accuracy

**Location**: /home/benjamin/.config/CLAUDE.md:74-84

**Current CLAUDE.md Quick Reference**:
```markdown
## Output Formatting Standards
[Used by: /implement, /build, all commands and agents]

See [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md) for output suppression patterns, block consolidation rules, and comment standards (WHAT not WHY).

**Quick Reference**:
- Suppress library sourcing with `2>/dev/null` while preserving error handling
- Target 2-3 bash blocks per command (Setup/Execute/Cleanup)
- Single summary line per block instead of multiple progress messages
- Comments describe WHAT code does, not WHY it was designed that way
```

**Analysis**: Quick reference accurately summarizes output-formatting.md content but:
1. Doesn't mention console summary format standards (because they don't exist yet)
2. "Single summary line per block" could be misinterpreted as "single line for final output"
3. No reference to artifact path presentation

**Impact**: After implementing console summary standards, CLAUDE.md quick reference will be outdated and may confuse developers who rely on it for quick lookups.

**Recommendation**: After adding console summary standards to output-formatting.md, update CLAUDE.md quick reference to include:
```markdown
- Suppress library sourcing with `2>/dev/null` while preserving error handling
- Target 2-3 bash blocks per command (Setup/Execute/Cleanup)
- Single summary line per block for interim output; structured summary for final output
- Console summaries use standardized sections (Summary/Phases/Artifacts/Next Steps)
- Comments describe WHAT code does, not WHY it was designed that way
```

---

### Finding 7: Missing Standards Section Metadata

**Observation**: Standards files in .claude/docs/reference/standards/ lack consistent [Used by: ...] metadata showing which commands/agents reference each standard.

**Current Coverage**:
- ✓ CLAUDE.md sections have [Used by: ...] metadata (lines 45, 61, 67, etc.)
- ✓ code-standards.md has some subsection metadata (line 2, 18, 32, 66)
- ✗ output-formatting.md lacks [Used by: ...] metadata entirely
- ✗ testing-protocols.md lacks metadata
- ✗ adaptive-planning.md lacks metadata

**Impact**: Developers can't quickly determine:
- Which commands depend on a standard
- What the impact radius of a standard change would be
- Whether a standard is actively used or deprecated

**Recommendation**: Add [Used by: ...] metadata to all major sections in standards files:
```markdown
## Console Summary Standards
[Used by: /research, /plan, /debug, /build, /revise, /repair, /expand, /collapse]
```

This aligns with existing CLAUDE.md pattern and improves discoverability.

## Recommendations

### Recommendation 1: Extend output-formatting.md with Console Summary Standards

**Priority**: HIGH (required for plan implementation)

**Action**: Add new section to /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md

**Proposed Section Structure**:
```markdown
## Console Summary Standards
[Used by: /research, /plan, /debug, /build, /revise, /repair, /expand, /collapse]

### Purpose

Final console summaries provide terse, scannable navigation to workflow artifacts and next actions. They are distinct from comprehensive summary .md files (created by agents) and interim progress messages (suppressed per output suppression standards).

### Structure Requirements

All commands producing artifacts MUST use this 4-section format:

1. **Summary** (2-3 sentences): Narrative of what was accomplished and why
2. **Phases** (bullet list, optional): Phase status if workflow has phases
3. **Artifacts** (highlighted paths): Visually distinguished artifact locations
4. **Next Steps** (actionable): Specific commands with full paths

### Length Target

Console summaries SHOULD be 15-25 lines:
- Terse enough to scan quickly
- Comprehensive enough to understand completion
- Clearly reference detailed artifacts for more information

### Artifact Path Format

**Requirements**:
- Use absolute paths (not relative or variable references)
- Show directories with file count for multi-file artifacts: `(N files)`
- Group by artifact type in workflow order: reports → plans → summaries → debug
- Use consistent visual markers (see Emoji Vocabulary below)

**Example**:
```
Artifacts:
  📊 Reports: /home/user/.claude/specs/NNN_topic/reports/ (2 files)
  📄 Plan: /home/user/.claude/specs/NNN_topic/plans/001_plan.md
  ✅ Summary: /home/user/.claude/specs/NNN_topic/summaries/001_summary.md
```

### Emoji Vocabulary for Terminal Output

**Clarification**: The code-standards.md "no emojis in file content" policy applies to saved file artifacts (.md, .lua, .sh). Terminal stdout MAY use emoji for visual hierarchy if terminal environment supports it.

**Standardized Emoji**:
- 📄 Plan files (.md in plans/)
- 📊 Research reports (.md in reports/)
- ✅ Implementation summaries (.md in summaries/)
- 🔧 Debug artifacts (files in debug/)
- 📁 Directory (multi-file collections)
- ✓ Complete phase
- • In-progress/pending phase

**Fallback**: If terminal environment doesn't support emoji, commands MAY fall back to ASCII markers: [PLAN], [REPORT], [OK], [DEBUG], [DIR].

### Relationship to Summary .md Files

**Console Summary**:
- Created by: Command (final bash block)
- Length: 15-25 lines
- Purpose: Quick navigation and next actions
- Audience: User reviewing command completion

**Summary .md File**:
- Created by: implementer-coordinator agent
- Length: 150-250 lines
- Purpose: Archival documentation of implementation
- Audience: Future developers, auditing, detailed review

Console summaries SHOULD reference summary .md files in Next Steps for users who need comprehensive details.
```

**Related Updates**:
- Update CLAUDE.md quick reference (Finding 6)
- Add metadata to new section: `[Used by: ...]`

---

### Recommendation 2: Clarify Emoji Policy in code-standards.md

**Priority**: MEDIUM (resolves policy ambiguity)

**Action**: Revise /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md:10

**Current Text**:
```markdown
- **Character Encoding**: UTF-8 only, no emojis in file content
```

**Proposed Revision**:
```markdown
- **Character Encoding**: UTF-8 only
- **Emoji Policy**:
  - **File Artifacts** (.md, .lua, .sh files): NO emoji (portability/compatibility)
  - **Terminal Output** (stdout during command execution): ALLOWED with standardized vocabulary (see output-formatting.md)
  - **Exception**: Saved markdown files MAY use Unicode box-drawing characters for diagrams (not emoji)
```

**Rationale**:
- Clarifies "file content" means saved artifacts, not terminal output
- Aligns with existing practice (/build uses ✓ emoji in console)
- References output-formatting.md for terminal emoji vocabulary
- Preserves existing box-drawing character allowance

---

### Recommendation 3: Document Artifact Output Types in Directory Protocols

**Priority**: MEDIUM (architectural clarity)

**Action**: Add new section to /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md

**Proposed Section**:
```markdown
## Output Artifact Types

### Console Summaries

**Format**: Terminal stdout text (ephemeral)
**Created by**: Commands (final bash block)
**Length**: 15-25 lines (terse, scannable)
**Structure**: Summary, Phases, Artifacts, Next Steps
**Purpose**: Navigation aid, immediate user feedback
**Standards**: See [Console Summary Standards](../reference/standards/output-formatting.md#console-summary-standards)

### Summary .md Files

**Format**: Markdown files in specs/{topic}/summaries/
**Created by**: implementer-coordinator agent during /build
**Length**: 150-250 lines (comprehensive)
**Structure**: Work Status, Metadata, Phases, Test Results, Changes, Recommendations
**Purpose**: Archival documentation, audit trail
**Standards**: See [implementer-coordinator agent behavioral guidelines](../../agents/implementer-coordinator.md)

### Relationship

Console summaries point to summary .md files for comprehensive details. Console answers "What happened and what's next?" while summary .md answers "How was it implemented and what changed?"
```

---

### Recommendation 4: Update Command Guides with Complete Output Examples

**Priority**: LOW (documentation completeness, not blocking)

**Action**: Update all 8 command guides to include final console summary in "Expected Output" sections

**Example Update** (research-command-guide.md:93-99):

**Before**:
```markdown
**Expected Output**:
=== Research-Only Workflow ===
Description: authentication patterns in codebase
Complexity: 2
```

**After**:
```markdown
**Expected Output**:
=== Research-Only Workflow ===
Description: authentication patterns in codebase
Complexity: 2

[... agent execution output ...]

=== Research Complete ===

Summary: Analyzed authentication patterns across 15 codebase files and
identified 3 implementation strategies. Research validates OAuth2 + JWT
approach with session management layer.

Artifacts:
  📊 Reports: /home/user/.claude/specs/123_auth/reports/ (2 files)

Next Steps:
  • Review research: cat /home/user/.claude/specs/123_auth/reports/001_auth_patterns.md
  • Create plan: /plan "implement OAuth2 based on research"
```

**Files to Update**:
- research-command-guide.md (391 lines)
- plan-command-guide.md (429 lines)
- debug-command-guide.md (484 lines)
- build-command-guide.md (667 lines)
- revise-command-guide.md (493 lines)
- repair-command-guide.md (586 lines)
- expand-command-guide.md (237 lines)
- collapse-command-guide.md (248 lines)

---

### Recommendation 5: Add [Used by: ...] Metadata to Standards Files

**Priority**: LOW (discoverability improvement)

**Action**: Add subsection metadata to output-formatting.md, testing-protocols.md, adaptive-planning.md

**Example** (output-formatting.md):
```markdown
## Output Suppression Patterns
[Used by: all commands, all agents]

## Block Consolidation Patterns
[Used by: all commands]

## Console Summary Standards
[Used by: /research, /plan, /debug, /build, /revise, /repair, /expand, /collapse]
```

This creates consistency with CLAUDE.md's metadata pattern and improves standard discoverability.

## References

### Standards Files Analyzed
- /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md (339 lines)
- /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md (199 lines)
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md (558 lines)
- /home/benjamin/.config/CLAUDE.md (lines 74-84, output formatting section)

### Command Files Examined
- /home/benjamin/.config/.claude/commands/research.md:622-630 (final output block)
- /home/benjamin/.config/.claude/commands/plan.md:896-905 (final output block)
- /home/benjamin/.config/.claude/commands/debug.md:1241-1251 (final output block)
- /home/benjamin/.config/.claude/commands/build.md:1422-1458 (final output block)
- /home/benjamin/.config/.claude/commands/revise.md:926-936 (final output block)
- /home/benjamin/.config/.claude/commands/repair.md:645-655 (final output block)

### Command Guides Examined
- /home/benjamin/.config/.claude/docs/guides/commands/research-command-guide.md:93-99
- /home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md (667 lines)
- All 14 command guides in /home/benjamin/.config/.claude/docs/guides/commands/

### Related Research
- /home/benjamin/.config/.claude/specs/878_artifact_console_summary_format/reports/001_artifact_commands_analysis.md (complete analysis of current command output formats)
- /home/benjamin/.config/.claude/specs/878_artifact_console_summary_format/plans/001_artifact_console_summary_format_plan.md (implementation plan requiring these standards updates)

### Patterns Referenced
- Executable/Documentation Separation: .claude/docs/concepts/patterns/executable-documentation-separation.md
- Directory Protocols: .claude/docs/concepts/directory-protocols.md
- Output Formatting: .claude/docs/reference/standards/output-formatting.md
