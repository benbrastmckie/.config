# Commands README Update Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Commands README Systematic Update
- **Scope**: Update /home/benjamin/.config/.claude/commands/README.md to accurately reflect current command catalog with proper documentation conventions
- **Estimated Phases**: 5
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 37.5
- **Research Reports**:
  - [Commands Directory Analysis](../reports/001_commands_directory_analysis.md)
  - [Documentation Conventions](../reports/002_documentation_conventions.md)

## Overview

This plan provides a systematic approach to updating the commands README.md to accurately document the 12 active command files in the `.claude/commands/` directory. The update will remove references to archived/non-existent commands, apply timeless writing standards, use proper relative path links to documentation, and organize commands into appropriate categories.

## Research Summary

Key findings from research reports:

**From Commands Directory Analysis**:
- 12 active command files exist: build.md, collapse.md, convert-docs.md, coordinate.md, debug.md, expand.md, optimize-claude.md, plan.md, research.md, revise.md, setup.md
- Commands categorize into: Primary Orchestrators (7), Workflow Managers (2), Utilities (2)
- Current README references non-existent commands: /test, /test-all, /document, /refactor, /analyze, /plan-wizard, /plan-from-template, /list-plans, /list-reports, /list-summaries

**From Documentation Conventions**:
- All internal links must use relative paths (e.g., `../docs/guides/plan-command-guide.md`)
- Timeless writing required: no temporal markers like "(New)", "(Updated)", "previously", "recently"
- Required README sections: Purpose, Module Documentation, Usage Examples, Navigation Links
- Cross-reference authoritative sources rather than duplicating content

Recommended approach: Restructure README with accurate command inventory, remove obsolete references, apply timeless writing, and use proper relative path links throughout.

## Success Criteria
- [ ] README accurately lists all 12 active command files
- [ ] All references to non-existent commands removed
- [ ] All internal links use relative paths (no absolute filesystem paths)
- [ ] No temporal markers present (validated against writing standards)
- [ ] Commands organized into correct categories (Primary, Workflow, Utility)
- [ ] Each command entry includes: Purpose, Usage, Type, Agents, Documentation link
- [ ] Navigation section links to actual command files only
- [ ] Link validation passes: `.claude/scripts/validate-links-quick.sh`

## Technical Design

### Architecture Overview

The README update involves restructuring content while preserving valuable architectural documentation:

```
Commands README Structure:
+-------------------------+
| Title & Overview        | <- Keep, update count
+-------------------------+
| Command Highlights      | <- Keep /coordinate emphasis
+-------------------------+
| Purpose                 | <- Revise categories
+-------------------------+
| Command Architecture    | <- Keep diagram
+-------------------------+
| Available Commands      | <- MAJOR: Rewrite entirely
+-------------------------+
| Command Definition      | <- Keep format docs
+-------------------------+
| Command Types           | <- Update categories
+-------------------------+
| Standards Discovery     | <- Keep
+-------------------------+
| Custom Commands         | <- Keep
+-------------------------+
| Best Practices          | <- Keep
+-------------------------+
| Navigation              | <- MAJOR: Update links
+-------------------------+
| Examples                | <- Update to valid commands
+-------------------------+
```

### Key Changes

1. **Available Commands Section**: Complete rewrite with accurate inventory
2. **Navigation Section**: Update to only reference existing files
3. **Examples Section**: Update to use only valid command names
4. **Link Format**: All relative paths from commands/ directory

### Link Convention

All links from commands/README.md must use relative paths:
- To docs: `../docs/guides/command-guide.md`
- To agents: `../agents/README.md`
- To specs: `../specs/README.md`
- Local files: `./plan.md` or just `plan.md`

## Implementation Phases

### Phase 1: Content Audit and Backup
dependencies: []

**Objective**: Analyze current README structure and create reference backup

**Complexity**: Low

Tasks:
- [ ] Read current README.md and identify all command references (file: /home/benjamin/.config/.claude/commands/README.md)
- [ ] Create list of non-existent commands that need removal: /test, /test-all, /document, /refactor, /analyze, /plan-wizard, /plan-from-template, /list-plans, /list-reports, /list-summaries, /cleanup, /validate-setup, /analyze-agents, /fix, /research-report, /research-revise, /research-plan
- [ ] Document sections to preserve vs restructure
- [ ] Verify frontmatter from all 12 command files for accurate metadata

Testing:
```bash
# Verify command file count
ls -1 /home/benjamin/.config/.claude/commands/*.md | grep -v README | wc -l
# Expected: 11 (12 - README)
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Update Available Commands Section
dependencies: [1]

**Objective**: Rewrite Available Commands with accurate inventory following standardized format

**Complexity**: High

Tasks:
- [ ] Remove all entries for non-existent commands from Available Commands section
- [ ] Create Primary Commands subsection with entries for: /plan, /build, /research, /debug, /coordinate, /revise, /setup (file: /home/benjamin/.config/.claude/commands/README.md)
- [ ] Create Workflow Commands subsection with entries for: /expand, /collapse
- [ ] Create Utility Commands subsection with entries for: /convert-docs, /optimize-claude
- [ ] For each command entry, include: Purpose (from description), Usage (from argument-hint), Type, Dependent Agents (from frontmatter), Documentation link (relative path to guide)
- [ ] Apply timeless writing: remove all "(New)", "(Updated)", "(Legacy)" markers
- [ ] Ensure all documentation links use relative paths: `../docs/guides/{command}-command-guide.md`

Testing:
```bash
# Check for absolute paths in README
grep -E '/home/|/Users/' /home/benjamin/.config/.claude/commands/README.md
# Expected: no matches

# Check for temporal markers
grep -iE '\(New\)|\(Updated\)|\(Legacy\)|previously|recently' /home/benjamin/.config/.claude/commands/README.md
# Expected: no matches
```

**Expected Duration**: 2 hours

---

### Phase 3: Update Command Types and Navigation
dependencies: [2]

**Objective**: Update categorization and fix navigation links to reflect actual files

**Complexity**: Medium

Tasks:
- [ ] Update Command Types section to reflect actual categories:
  - Primary: /plan, /build, /research, /debug, /coordinate, /revise, /setup
  - Workflow: /expand, /collapse
  - Utility: /convert-docs, /optimize-claude
- [ ] Rewrite Navigation section with only existing command files (file: /home/benjamin/.config/.claude/commands/README.md, lines 614-640)
- [ ] Remove navigation entries for: analyze.md, collapse-phase.md, collapse-stage.md, document.md, expand-phase.md, expand-stage.md, fix.md, list.md, plan-from-template.md, plan-wizard.md, refactor.md, research-plan.md, research-report.md, research-revise.md, test.md, test-all.md
- [ ] Add correct navigation entries for actual files: build.md, collapse.md, convert-docs.md, coordinate.md, debug.md, expand.md, optimize-claude.md, plan.md, research.md, revise.md, setup.md
- [ ] Update Related section links to use relative paths: `../README.md`, `../agents/README.md`, `../specs/README.md`

Testing:
```bash
# Verify all navigation links point to existing files
for f in build collapse convert-docs coordinate debug expand optimize-claude plan research revise setup; do
  test -f "/home/benjamin/.config/.claude/commands/${f}.md" || echo "Missing: ${f}.md"
done
```

**Expected Duration**: 1.5 hours

---

### Phase 4: Update Examples and Fix References
dependencies: [3]

**Objective**: Update all examples to use valid command names and fix any remaining incorrect references

**Complexity**: Medium

Tasks:
- [ ] Update Examples section to use only valid commands (file: /home/benjamin/.config/.claude/commands/README.md, lines 642-698)
- [ ] Replace `/research-report` with `/research` in examples
- [ ] Replace `/research-revise` with `/revise` in examples
- [ ] Replace `/fix` with `/debug` in examples
- [ ] Remove examples using non-existent commands: /list-plans, /test, /test-all
- [ ] Update Progressive Plan Management examples to use valid commands
- [ ] Remove or update Parsing Utility section if referencing non-existent utilities
- [ ] Update any remaining cross-references throughout document

Testing:
```bash
# Check for references to non-existent commands
grep -E '/test-all|/test[^i]|/document|/refactor|/analyze|/plan-wizard|/plan-from-template|/list-plans|/list-reports|/list-summaries|/research-report|/research-revise|/fix' /home/benjamin/.config/.claude/commands/README.md
# Expected: no matches (except in historical context if preserved)
```

**Expected Duration**: 1 hour

---

### Phase 5: Validation and Final Review
dependencies: [4]

**Objective**: Validate all links, verify documentation standards compliance, and perform final review

**Complexity**: Low

Tasks:
- [ ] Run link validation script to check all relative paths resolve (file: /home/benjamin/.config/.claude/scripts/validate-links-quick.sh)
- [ ] Verify no absolute filesystem paths remain in document
- [ ] Verify no temporal markers remain (New, Updated, Legacy, etc.)
- [ ] Verify all 12 commands are documented with required fields
- [ ] Check command count in opening statement matches actual count
- [ ] Verify README follows required sections: Purpose, Module Documentation, Usage Examples, Navigation Links
- [ ] Final read-through for consistency and clarity

Testing:
```bash
# Run link validation
/home/benjamin/.config/.claude/scripts/validate-links-quick.sh /home/benjamin/.config/.claude/commands/README.md

# Verify command count statement
grep -o "12 active commands" /home/benjamin/.config/.claude/commands/README.md
# Expected: matches

# Final check for absolute paths
grep -E '^.*\(/home/|^.*\(/Users/' /home/benjamin/.config/.claude/commands/README.md | head -5
# Expected: no matches
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Validate each link resolves to existing file
- Check for forbidden patterns (absolute paths, temporal markers)
- Verify frontmatter accuracy for each command entry

### Integration Testing
- Run full link validation script on completed README
- Cross-reference with command-reference.md for consistency
- Verify navigation works from parent directory

### Validation Commands
```bash
# Primary validation
.claude/scripts/validate-links-quick.sh commands/README.md

# Check for absolute paths
grep -n '/home/' commands/README.md

# Check for temporal markers
grep -inE '\(new\)|\(updated\)|previously|recently|now supports' commands/README.md

# Verify command file references
for cmd in build collapse convert-docs coordinate debug expand optimize-claude plan research revise setup; do
  grep -q "$cmd.md" commands/README.md || echo "Missing reference: $cmd.md"
done
```

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/commands/README.md` - Main target of this plan

### Cross-References to Verify
- Links to `.claude/docs/guides/*-command-guide.md` files
- Links to `.claude/docs/reference/command-reference.md`
- Links to `.claude/agents/README.md`
- Parent link to `.claude/README.md`

### Standards Compliance
- Follow timeless writing principles from `.claude/docs/concepts/writing-standards.md`
- Apply link conventions from `.claude/docs/reference/code-standards.md`
- Maintain README requirements from CLAUDE.md documentation_policy section

## Dependencies

### Prerequisites
- All 12 command files must be present in commands/ directory
- Documentation guides should exist for cross-references (or note if missing)
- Link validation script must be available

### External Dependencies
None - this is a documentation-only update

### Related Documentation
- [Writing Standards](../docs/concepts/writing-standards.md) - Timeless writing guidelines
- [Code Standards](../docs/reference/code-standards.md) - Link conventions
- [Command Reference](../docs/reference/command-reference.md) - Authoritative command syntax
