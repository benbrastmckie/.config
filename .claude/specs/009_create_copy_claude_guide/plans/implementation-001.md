# Implementation Plan: Task #9

**Task**: Create copy-claude-directory.md Guide
**Version**: 001
**Created**: 2026-01-10
**Language**: meta

## Overview

Create a copy-claude-directory.md guide adapted for this Neovim configuration project. The guide will provide instructions for copying the `.claude/` agent system to other projects, referencing this project's GitHub repository (`benbrastmckie/.config`) and describing the Neovim/Lua development context.

Based on research findings, the implementation requires:
1. Creating the guide file with adapted content
2. Updating docs/README.md to include the guide in the documentation map

## Phases

### Phase 1: Create copy-claude-directory.md Guide

**Estimated effort**: 30 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Create the guide file with all required sections
2. Replace ModelChecker references with .config repository
3. Update context descriptions for Neovim/Lua development

**Files to create**:
- `.claude/docs/guides/copy-claude-directory.md` - Main guide file

**Steps**:
1. Create copy-claude-directory.md in `.claude/docs/guides/`
2. Add navigation header linking to README.md, user-installation.md, commands
3. Write "What is the .claude/ System?" section describing Neovim development focus:
   - Task management commands for Neovim plugin development
   - Specialized skills for Lua development
   - Context files for Neovim API patterns
   - State tracking across sessions
4. Add Prerequisites section (Git, Claude Code - same as source)
5. Add Installation Instructions for macOS/Linux:
   - Full clone method using `https://github.com/benbrastmckie/.config.git`
   - Sparse checkout method
6. Add Installation Instructions for Windows PowerShell:
   - Full clone method
   - Sparse checkout method
7. Add "Using Claude Code to Install" section with prompt
8. Add Verification section:
   - Directory structure check
   - Key files check (TODO.md, state.json)
   - Restart Claude Code reminder
   - Test commands
9. Add Troubleshooting section (permission errors, git issues, commands not available)
10. Add Next Steps section linking to:
    - Commands Reference (../commands/README.md)
    - User Installation (user-installation.md)
    - Documentation Hub (../README.md)

**Verification**:
- File exists at correct path
- All navigation links are valid relative paths
- GitHub URLs reference correct repository
- Example commands use Neovim-relevant context

---

### Phase 2: Update docs/README.md

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Add copy-claude-directory.md to the documentation map
2. Add entry to guides section

**Files to modify**:
- `.claude/docs/README.md` - Add guide reference

**Steps**:
1. Read current docs/README.md
2. Locate the Documentation Map section
3. Add `copy-claude-directory.md` entry under guides/ in the tree diagram
4. Locate the guides section in the document
5. Add table entry or bullet for copy-claude-directory.md with description

**Verification**:
- docs/README.md includes reference to copy-claude-directory.md
- Documentation map tree reflects the new file
- Navigation section properly lists the guide

---

### Phase 3: Verify and Test

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Verify all links work correctly
2. Verify GitHub URLs are accessible
3. Test that instructions are clear and complete

**Files to review**:
- `.claude/docs/guides/copy-claude-directory.md` - Verify content
- `.claude/docs/README.md` - Verify integration

**Steps**:
1. Verify all relative links in copy-claude-directory.md resolve correctly:
   - `../README.md` points to docs/README.md
   - `user-installation.md` exists in same directory
   - `../commands/README.md` points to commands documentation
2. Verify GitHub repository URL is correct:
   - `https://github.com/benbrastmckie/.config.git`
3. Verify raw content URL format is correct for potential future use:
   - `https://raw.githubusercontent.com/benbrastmckie/.config/master/.claude/docs/guides/copy-claude-directory.md`
4. Review content for clarity and completeness

**Verification**:
- All internal links resolve to existing files
- GitHub URLs are correctly formatted
- Instructions are complete and coherent

## Dependencies

- None - this task is independent

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Broken links | Low | Low | Verify all links before completion |
| GitHub branch name mismatch | Medium | Low | Verify default branch (master vs main) |
| Outdated user-installation.md | Low | Medium | Note that user-installation.md may need separate update |

## Success Criteria

- [ ] copy-claude-directory.md exists in .claude/docs/guides/
- [ ] Guide contains all required sections (prerequisites, installation, verification, troubleshooting)
- [ ] All internal links resolve correctly
- [ ] GitHub URLs reference benbrastmckie/.config repository
- [ ] docs/README.md includes reference to new guide
- [ ] Content describes Neovim/Lua development context (not Python/Z3)

## Rollback Plan

If implementation fails:
1. Delete copy-claude-directory.md
2. Revert docs/README.md changes
3. Task returns to [RESEARCHED] status
