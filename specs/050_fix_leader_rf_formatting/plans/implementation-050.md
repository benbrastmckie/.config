# Implementation Plan: Task #50 - Fix <leader>rf Formatting for Astro and Other Filetypes

## Overview

This plan addresses the issue where the `<leader>rf` formatting keymap fails to work properly for `.astro` files and other filetypes. The root cause is missing filetype configurations in conform.nvim and missing formatter installations via Mason. The implementation will add the `astro` filetype to the formatters configuration, install required formatters through Mason, and optionally relocate the keymap for better maintainability.

## Goals & Non-Goals

### Goals
- Add `astro` filetype support to conform.nvim formatters configuration
- Add other missing web filetypes (svelte, graphql, handlebars) for completeness
- Install required formatters (prettier, jq, shfmt, clang-format, latexindent) via Mason
- Ensure `<leader>rf` keymap works correctly across all configured filetypes
- Maintain backward compatibility with existing configurations

### Non-Goals
- Adding new LSP servers (astro-ls) - will rely on LSP fallback for unconfigured filetypes
- Changing the format-on-save default behavior (remains disabled)
- Modifying formatter-specific options beyond what's necessary
- Adding formatters for filetypes not currently in use

## Implementation Phases

### Phase 1: Add Missing Filetypes to Conform.nvim [NOT STARTED]

- **Goal:** Update `formatters_by_ft` to include astro and other web filetypes
- **Tasks:**
  - [ ] Add `astro = { "prettier" }` to formatters_by_ft in `lua/neotex/plugins/editor/formatting.lua`
  - [ ] Add `svelte = { "prettier" }` for Svelte file support
  - [ ] Add `graphql = { "prettier" }` for GraphQL support
  - [ ] Add `handlebars = { "prettier" }` for Handlebars templates
  - [ ] Verify prettier formatter configuration supports these filetypes
- **Timing:** 15-20 minutes
- **Verification:** Check that the filetype entries are properly formatted and follow existing patterns

### Phase 2: Install Formatters via Mason [NOT STARTED]

- **Goal:** Update Mason tool installer to include all required formatters
- **Tasks:**
  - [ ] Add `"prettier"` to ensure_installed in `lua/neotex/plugins/lsp/mason.lua`
  - [ ] Add `"jq"` for JSON formatting
  - [ ] Add `"shfmt"` for shell script formatting
  - [ ] Add `"clang-format"` for C/C++ formatting
  - [ ] Add `"latexindent"` for LaTeX formatting
  - [ ] Verify all formatter names match Mason registry names exactly
- **Timing:** 15-20 minutes
- **Verification:** Run `:MasonToolsInstall` to verify tools can be installed (may require manual confirmation)

### Phase 3: Relocate Keymap to Conform.nvim Spec [NOT STARTED]

- **Goal:** Move the `<leader>rf` keymap from which-key.lua to conform.nvim for better cohesion
- **Tasks:**
  - [ ] Add `keys` table to conform.nvim plugin spec in `lua/neotex/plugins/editor/formatting.lua`
  - [ ] Define `<leader>rf` keymap with proper mode ({ "n", "v" })
  - [ ] Copy the format function: `require("conform").format({ async = true, lsp_fallback = true })`
  - [ ] Add descriptive comment explaining the keymap
  - [ ] Remove the keymap from `lua/neotex/plugins/editor/which-key.lua` (line 592)
  - [ ] Update which-key group description if needed
- **Timing:** 20-30 minutes
- **Verification:** Ensure keymap loads correctly and appears in which-key popup

### Phase 4: Testing and Validation [NOT STARTED]

- **Goal:** Verify the formatting keymap works across all filetypes
- **Tasks:**
  - [ ] Test `<leader>rf` in a `.astro` file (should format with prettier)
  - [ ] Test `<leader>rf` in a `.md` file (should format with prettier)
  - [ ] Test `<leader>rf` in a `.lua` file (should format with stylua)
  - [ ] Test `<leader>rf` in a `.py` file (should format with isort + black)
  - [ ] Test `<leader>rf` in a `.js` file (should format with prettier)
  - [ ] Test `<leader>rf` in a `.json` file (should format with jq)
  - [ ] Test visual mode formatting (select lines, press `<leader>rf`)
  - [ ] Verify `:ConformInfo` shows correct formatters for each filetype
- **Timing:** 20-30 minutes
- **Verification:** All tests pass, no errors in `:messages`

## Testing & Validation

### Build/Type Checks
- [ ] Lua syntax validation passes for all modified files
- [ ] No errors on Neovim startup
- [ ] No errors when running `:checkhealth conform`
- [ ] No errors when running `:checkhealth mason`

### Manual Testing Steps
1. Open an `.astro` file and run `<leader>rf` - should format without errors
2. Open a `.md` file and run `<leader>rf` - should format without errors
3. Run `:ConformInfo` to verify formatters are detected correctly
4. Run `:Mason` to verify all formatters are installed
5. Test visual mode selection formatting in each filetype

### Expected Behavior
- `<leader>rf` formats the current buffer or selection asynchronously
- LSP fallback works when no formatter is configured
- No error messages appear during formatting
- Formatting respects .editorconfig if present

## Artifacts & Outputs

### Files to Modify
1. `lua/neotex/plugins/editor/formatting.lua` - Add filetypes and keymap
2. `lua/neotex/plugins/lsp/mason.lua` - Add formatter installations
3. `lua/neotex/plugins/editor/which-key.lua` - Remove relocated keymap

### Directories to Create
- None (all modifications are to existing files)

### Dependencies
- Mason must be available to install formatters
- conform.nvim must be installed (already present)
- which-key.nvim must be installed (already present)

## Risk Assessment

### Low Risk
- Adding new filetypes to existing formatter configuration
- Installing formatters via Mason (can be uninstalled if issues arise)

### Medium Risk
- Moving keymap location could affect which-key display order
- Formatter installation may fail on some systems (network issues, missing dependencies)

### Mitigation
- Keep backup of original which-key.lua keymap until testing confirms success
- Document manual installation steps in case Mason fails
- Test on representative filetypes before considering complete

## Rollback Plan

If issues are encountered:
1. Revert keymap location by restoring which-key.lua entry
2. Remove new filetypes from formatters_by_ft if they cause issues
3. Uninstall problematic formatters via `:Mason` if needed

## References

- Research Report: `specs/050_fix_leader_rf_formatting/reports/research-050.md`
- Conform.nvim Documentation: https://github.com/stevearc/conform.nvim
- Mason Registry: https://mason-registry.dev/registry/list
