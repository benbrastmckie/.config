# README.md Revision Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Commands README.md revision for adaptive plan structures, standards discovery, and examples consolidation
- **Scope**: Revise specific sections of /home/benjamin/.config/.claude/commands/README.md
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 20.5
- **Research Reports**:
  - [README Revision Analysis](../reports/001_readme_revision_analysis.md)

## Overview

Revise the commands README.md to improve three key sections: transform Adaptive Plan Structures into a workflow-focused description with expansion results, consolidate Standards Discovery with links to existing documentation resources, and distribute the standalone Examples section inline with each command in Available Commands.

## Research Summary

Key findings from the research report:

- **Adaptive Plan Structures (lines 476-533)**: Currently documents Level 0/1/2 structure but lacks workflow description, expansion results, and progressive workflow narrative. Needs to describe how /expand and /collapse work in practice.

- **Standards Discovery (lines 535-566)**: Contains inline content that duplicates resources in .claude/docs/. Should provide concise links to: Code Standards, Testing Protocols, Output Formatting, Directory Protocols, Writing Standards, and Adaptive Planning Guide.

- **Documentation Standards (lines 637-647)**: Brief section that should be merged into Standards Discovery for consolidation.

- **Examples (lines 725-815)**: 91 lines in standalone section. Better suited as brief inline examples with each command. Net reduction of ~43 lines after redistribution.

- **Existing resources**: Six key documentation files in .claude/docs/ overlap with Standards Discovery content and should be linked rather than duplicated.

## Success Criteria

- [ ] Adaptive Plan Structures section describes progressive expansion workflow (Level 0 to 1 to 2)
- [ ] Adaptive Plan Structures includes expansion results (30-50 lines become 300-500+ line specifications)
- [ ] Standards Discovery consolidated to ~40 lines with resource table linking to .claude/docs/
- [ ] Documentation Standards merged into Standards Discovery section
- [ ] All links in Standards Discovery verified working
- [ ] Each command in Available Commands has inline example
- [ ] Standalone Examples section (lines 725-815) removed
- [ ] Net line reduction of approximately 40-50 lines
- [ ] No duplicate information between sections
- [ ] All code blocks use proper syntax highlighting

## Technical Design

### Section Modifications

**Adaptive Plan Structures Revision**:
- Add "Expansion Workflow" subsection describing /expand and /collapse usage
- Add "Expansion Results" subsection showing transformation (outline to specification)
- Retain "Parsing Utility" subsection for advanced users
- Expand from ~57 lines to ~80 lines

**Standards Discovery Consolidation**:
- Replace inline Standards Sections list with resource table
- Add links to .claude/docs/ resources
- Merge Documentation Standards content
- Include present-focused writing guideline
- Reduce from ~32 lines to ~40 lines (including merged content)

**Examples Distribution**:
- Add one-line example after "Type" field for each command
- Use consistent format: `**Example**: \`\`\`bash\n/command args\n\`\`\``
- Remove standalone Examples section entirely
- Add ~27 lines to Available Commands, remove ~91 lines from Examples

### File Structure

Target file: `/home/benjamin/.config/.claude/commands/README.md` (816 lines)

Line ranges for modification:
- Adaptive Plan Structures: 476-533 (replace)
- Standards Discovery: 535-566 (replace)
- Documentation Standards: 637-647 (remove - merged into Standards Discovery)
- Available Commands inline examples: 107-330 (insert after Type fields)
- Examples section: 725-815 (remove)

## Implementation Phases

### Phase 1: Revise Adaptive Plan Structures Section [COMPLETE]
dependencies: []

**Objective**: Transform the Adaptive Plan Structures section into a workflow-focused description with expansion results.

**Complexity**: Medium

Tasks:
- [x] Read current Adaptive Plan Structures section (lines 476-533)
- [x] Draft new section with Expansion Workflow subsection
  - Describe how plans start at Level 0
  - Explain when and how to use /expand phase command
  - Explain when and how to use /expand stage command
  - Explain how to use /collapse commands
- [x] Draft Expansion Results subsection
  - Show input (30-50 line outline)
  - Show output (300-500+ line specification with details)
  - List what expanded phases contain (code examples, testing specs, architecture decisions, error handling, performance)
- [x] Add brief inline examples for /expand and /collapse
- [x] Preserve Parsing Utility subsection
- [x] Replace lines 476-533 with new content using Edit tool

Testing:
```bash
# Verify section structure
grep -n "^## Adaptive Plan Structures" /home/benjamin/.config/.claude/commands/README.md
grep -n "^### Expansion Workflow" /home/benjamin/.config/.claude/commands/README.md
grep -n "^### Expansion Results" /home/benjamin/.config/.claude/commands/README.md
grep -n "^### Parsing Utility" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 0.75 hours

---

### Phase 2: Consolidate Standards Discovery Section [COMPLETE]
dependencies: [1]

**Objective**: Consolidate Standards Discovery with linked resources and merge Documentation Standards.

**Complexity**: Medium

Tasks:
- [x] Read current Standards Discovery section (lines 535-566)
- [x] Read current Documentation Standards section (lines 637-647)
- [x] Verify all target documentation files exist:
  - /home/benjamin/.config/.claude/docs/reference/code-standards.md
  - /home/benjamin/.config/.claude/docs/reference/testing-protocols.md
  - /home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md
  - /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md
  - /home/benjamin/.config/.claude/docs/concepts/writing-standards.md
  - /home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md
- [x] Draft new Standards Discovery section with:
  - Brief Discovery Process subsection (4 numbered steps)
  - Key Standards Resources table with columns: Standard, Resource, Used By
  - Documentation Standards subsection (merged content with link to Writing Standards)
- [x] Replace lines 535-566 with new content using Edit tool
- [x] Remove standalone Documentation Standards section (lines 637-647)

Testing:
```bash
# Verify all linked files exist
test -f /home/benjamin/.config/.claude/docs/reference/code-standards.md && echo "code-standards OK"
test -f /home/benjamin/.config/.claude/docs/reference/testing-protocols.md && echo "testing-protocols OK"
test -f /home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md && echo "output-formatting OK"
test -f /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md && echo "directory-protocols OK"
test -f /home/benjamin/.config/.claude/docs/concepts/writing-standards.md && echo "writing-standards OK"
test -f /home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md && echo "adaptive-planning OK"

# Verify section structure
grep -n "^## Standards Discovery" /home/benjamin/.config/.claude/commands/README.md
grep -n "^### Key Standards Resources" /home/benjamin/.config/.claude/commands/README.md
grep -n "^### Documentation Standards" /home/benjamin/.config/.claude/commands/README.md

# Verify standalone Documentation Standards removed
! grep -n "^## Documentation Standards" /home/benjamin/.config/.claude/commands/README.md && echo "Standalone section removed OK"
```

**Expected Duration**: 0.75 hours

---

### Phase 3: Distribute Inline Examples to Commands [COMPLETE]
dependencies: [1]

**Objective**: Add brief inline examples to each command in Available Commands and remove standalone Examples section.

**Complexity**: Medium

Tasks:
- [x] Add inline example to /build (after Type: primary, line ~113)
  - Example: `/build specs/plans/007_dark_mode_implementation.md`
- [x] Add inline example to /debug (after Type: primary, line ~145)
  - Example: `/debug "Login tests failing with timeout error"`
- [x] Add inline example to /plan (after Type: primary, line ~167)
  - Example: `/plan "Add dark mode toggle to settings"`
- [x] Add inline example to /research (after Type: primary, line ~189)
  - Example: `/research "Authentication best practices"`
- [x] Add inline example to /expand (after Type: workflow, line ~211)
  - Example: `/expand phase specs/plans/015_dashboard.md 2`
- [x] Add inline example to /collapse (after Type: workflow, line ~233)
  - Example: `/collapse phase specs/plans/015_dashboard/ 5`
- [x] Add inline example to /revise (after Type: workflow, line ~253)
  - Example: `/revise "Add Phase 9 to specs/plans/015_api.md"`
- [x] Add inline example to /setup (after Type: utility, line ~275)
  - Example: `/setup --analyze`
- [x] Add inline example to /convert-docs (after Type: primary, line ~297)
  - Example: `/convert-docs ./docs ./output`
- [x] Remove standalone Examples section (lines 725-815)

Testing:
```bash
# Verify inline examples added
grep -A3 "^#### /build" /home/benjamin/.config/.claude/commands/README.md | grep "Example"
grep -A3 "^#### /debug" /home/benjamin/.config/.claude/commands/README.md | grep "Example"
grep -A3 "^#### /plan" /home/benjamin/.config/.claude/commands/README.md | grep "Example"

# Verify Examples section removed
! grep -n "^## Examples$" /home/benjamin/.config/.claude/commands/README.md && echo "Examples section removed OK"

# Count total lines (should be reduced)
wc -l /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 1.0 hours

---

### Phase 4: Validation and Documentation [COMPLETE]
dependencies: [2, 3]

**Objective**: Validate all changes, verify links work, and ensure consistency.

**Complexity**: Low

Tasks:
- [x] Verify all internal links work (relative paths to .claude/docs/)
- [x] Check all code blocks have proper syntax highlighting
- [x] Verify no duplicate information between sections
- [x] Count final line total (should be ~770-780 lines, down from 816)
- [x] Review section transitions for readability
- [x] Verify Available Commands section maintains consistent format
- [x] Test that command examples match actual command usage syntax

Testing:
```bash
# Validate markdown structure
grep -c "^## " /home/benjamin/.config/.claude/commands/README.md
grep -c "^### " /home/benjamin/.config/.claude/commands/README.md
grep -c "^#### " /home/benjamin/.config/.claude/commands/README.md

# Check code block syntax highlighting
grep -c "\`\`\`bash" /home/benjamin/.config/.claude/commands/README.md
grep -c "\`\`\`markdown" /home/benjamin/.config/.claude/commands/README.md

# Verify final line count
wc -l /home/benjamin/.config/.claude/commands/README.md

# Check no broken internal links
grep -o "\](../docs/[^)]*)" /home/benjamin/.config/.claude/commands/README.md | while read link; do
  path=$(echo "$link" | sed 's/](\.\./\/home\/benjamin\/.config\/.claude/' | sed 's/)//')
  test -f "$path" && echo "OK: $path" || echo "BROKEN: $path"
done
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Per-Phase Testing
Each phase includes specific test commands to verify:
- Section structure (grep for headings)
- File existence (test -f for linked resources)
- Content removal (! grep for removed sections)
- Line counts (wc -l for reduction verification)

### Final Validation
- Markdown linting for proper formatting
- Link validation for all internal references
- Manual review of section transitions
- Comparison of before/after line counts

### Success Metrics
- All linked documentation files exist and are accessible
- Net reduction of 40-50 lines from 816
- No duplicate content between sections
- Consistent formatting in Available Commands
- All code examples have syntax highlighting

## Documentation Requirements

### Updates Required
- This plan documents the README.md revision (no external docs needed)

### Cross-References
- Update any external references to removed sections (Examples, Documentation Standards)
- Verify CLAUDE.md references to commands/README.md still valid

### No New Documentation
- This is a consolidation task; no new documentation files created
- Existing .claude/docs/ files are linked, not duplicated

## Dependencies

### External Files (Must Exist)
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md`
- `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md`
- `/home/benjamin/.config/.claude/docs/reference/output-formatting-standards.md`
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md`
- `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md`

### Internal Dependencies
- Phase 2 depends on Phase 1 (Standards Discovery follows Adaptive Plan Structures)
- Phase 3 can run in parallel with Phase 2 (independent work areas)
- Phase 4 depends on Phases 2 and 3 (validation after all edits)

### Tools Required
- Edit tool for file modifications
- Read tool for verification
- Bash tool for testing commands

## Risk Mitigation

### Potential Issues
1. **Link breakage**: Verify all .claude/docs/ files exist before creating links
2. **Content loss**: Use Edit tool carefully with exact string matching
3. **Format inconsistency**: Follow established patterns in Available Commands

### Rollback Strategy
- Git tracks changes; can revert if issues found
- Keep backup of original README.md content mentally noted for reference
