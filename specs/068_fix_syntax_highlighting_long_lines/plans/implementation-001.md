# Implementation Plan: Task #68

- **Task**: 68 - Fix Syntax Highlighting on Long Lines
- **Status**: [COMPLETED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

The syntax highlighting issue on long lines is caused by `synmaxcol=200` limiting regex-based highlighting to 200 columns, combined with TypeScript parsers not being in the treesitter auto-install list. The fix involves adding TypeScript/TSX parsers to treesitter, creating ftplugin overrides for TypeScript files, and optionally enabling the snacks.nvim bigfile module for performance protection.

### Research Integration

Key findings from research:
- Root cause: `synmaxcol=200` in `options.lua` limits regex-based syntax highlighting
- Treesitter bypasses this limitation when active, but TypeScript parsers are missing
- Existing pattern in `after/ftplugin/tex.lua` shows how to override synmaxcol per filetype
- snacks.nvim bigfile module (currently disabled) can provide performance protection

## Goals & Non-Goals

**Goals**:
- Enable full syntax highlighting on long lines in TypeScript files
- Ensure treesitter is properly configured for TypeScript/TSX
- Maintain performance protection for very large files
- Follow existing configuration patterns

**Non-Goals**:
- Changing global synmaxcol (would affect all filetypes)
- Disabling treesitter for performance reasons
- Adding parsers for all possible filetypes

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Performance degradation with synmaxcol=0 on large TS files | Medium | Low | Enable snacks.nvim bigfile module as fallback |
| Treesitter parser installation failure | Low | Low | Keep regex syntax as automatic fallback; synmaxcol override still helps |
| Conflicts with existing configuration | Medium | Low | Follow established patterns from tex.lua ftplugin |

## Implementation Phases

### Phase 1: Add TypeScript Parsers to Treesitter [COMPLETED]

**Goal**: Ensure treesitter TypeScript/TSX parsers are installed and active

**Estimated effort**: 0.25 hours

**Objectives**:
1. Add TypeScript and TSX parsers to the auto-install list
2. Verify parser installation works correctly

**Files to modify**:
- `lua/neotex/plugins/editor/treesitter.lua` - Add typescript and tsx to parsers list

**Steps**:
1. Open `lua/neotex/plugins/editor/treesitter.lua`
2. Locate the `parsers` table (around line 4-7)
3. Add `"typescript"` and `"tsx"` to the list
4. Save the file

**Verification**:
- Run `nvim --headless -c "lua print(vim.inspect(require('nvim-treesitter.parsers').get_parser_configs()['typescript']))" -c "q"` to verify parser config exists
- Open a TypeScript file and run `:InspectTree` to confirm treesitter parsing is active

---

### Phase 2: Create TypeScript ftplugin Override [COMPLETED]

**Goal**: Set synmaxcol=0 for TypeScript files following the existing tex.lua pattern

**Estimated effort**: 0.25 hours

**Objectives**:
1. Create ftplugin for TypeScript with synmaxcol override
2. Create ftplugin for TypeScript React (tsx) with same override

**Files to modify**:
- `after/ftplugin/typescript.lua` - New file for TypeScript overrides
- `after/ftplugin/typescriptreact.lua` - New file for TSX overrides

**Steps**:
1. Create `after/ftplugin/typescript.lua` with:
   ```lua
   -- TypeScript-specific settings
   -- Allow full syntax highlighting on long lines (treesitter bypasses this, but fallback may need it)
   vim.opt_local.synmaxcol = 0
   ```
2. Create `after/ftplugin/typescriptreact.lua` with same content
3. Verify files are placed in correct directory

**Verification**:
- Open a TypeScript file and run `:setlocal synmaxcol?` to confirm it's set to 0
- Open a TSX file and verify the same

---

### Phase 3: Enable snacks.nvim Bigfile Module [COMPLETED]

**Goal**: Enable performance protection for very large files

**Estimated effort**: 0.25 hours

**Objectives**:
1. Enable the bigfile module in snacks.nvim configuration
2. Configure appropriate size and line length thresholds

**Files to modify**:
- `lua/neotex/plugins/tools/snacks/init.lua` - Enable bigfile module

**Steps**:
1. Open `lua/neotex/plugins/tools/snacks/init.lua`
2. Locate the `bigfile` configuration section
3. Change `enabled = false` to `enabled = true`
4. Optionally adjust `size` threshold (currently 100KB is reasonable)
5. Add `line_length` threshold if not present (recommend 1000)

**Verification**:
- Run `:lua print(require('snacks').config.bigfile.enabled)` to verify module is enabled
- Create a large test file (>100KB) and verify bigfile mode activates

---

### Phase 4: Verification and Testing [COMPLETED]

**Goal**: Verify the fix works end-to-end

**Estimated effort**: 0.25 hours

**Objectives**:
1. Test syntax highlighting on long TypeScript lines
2. Verify treesitter is active
3. Confirm performance is acceptable

**Files to modify**:
- None (testing only)

**Steps**:
1. Install treesitter parsers: `:TSInstall typescript tsx`
2. Open a TypeScript file with long lines (or create a test file)
3. Navigate to a long line that wraps across multiple screen lines
4. Verify syntax highlighting continues past column 200
5. Run `:InspectTree` to confirm treesitter is parsing the file
6. Check `:setlocal synmaxcol?` shows 0

**Verification**:
- Visual confirmation: syntax highlighting extends past column 200 on long lines
- `:InspectTree` shows valid treesitter parse tree
- `:setlocal synmaxcol?` returns `synmaxcol=0`
- No noticeable performance degradation during editing

## Testing & Validation

- [ ] TypeScript parser installs successfully (`:TSInstall typescript`)
- [ ] TSX parser installs successfully (`:TSInstall tsx`)
- [ ] synmaxcol=0 is set in TypeScript files
- [ ] synmaxcol=0 is set in TSX files
- [ ] Syntax highlighting works on lines >200 columns
- [ ] Treesitter is active for TypeScript (`:InspectTree` works)
- [ ] Bigfile module is enabled
- [ ] No performance regression in normal TypeScript files

## Artifacts & Outputs

- Modified: `lua/neotex/plugins/editor/treesitter.lua`
- Created: `after/ftplugin/typescript.lua`
- Created: `after/ftplugin/typescriptreact.lua`
- Modified: `lua/neotex/plugins/tools/snacks/init.lua`

## Rollback/Contingency

If the implementation causes issues:

1. **Remove ftplugin overrides**: Delete `after/ftplugin/typescript.lua` and `after/ftplugin/typescriptreact.lua`
2. **Revert treesitter changes**: Remove `"typescript"` and `"tsx"` from the parsers list
3. **Disable bigfile module**: Set `enabled = false` in snacks.nvim config
4. **Alternative approach**: If treesitter solution fails, increase global `synmaxcol` to 500 or 1000 as a broader workaround
