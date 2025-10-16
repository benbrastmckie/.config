# nvim-autopairs Migration Plan

## Executive Summary

Migrate from mini.pairs back to nvim-autopairs to restore essential language-specific features for LaTeX and Lean mathematics work, while maintaining blink.cmp integration through a community-developed workaround.

**Updated**: Based on comprehensive research of GitHub repositories and community solutions.

## Current State Analysis

### Active Configuration
- **Plugin**: mini.pairs (basic bracket pairing only)
- **Location**: `lua/neotex/plugins/tools/mini.lua`
- **Features**: Basic `()`, `[]`, `{}` + custom quote handling
- **Limitations**: No LaTeX `$` pairs, no Lean unicode, no treesitter integration

### Deprecated Configuration  
- **Plugin**: nvim-autopairs (comprehensive language support)
- **Location**: `lua/neotex/deprecated/autopairs.lua`
- **Features**: LaTeX spacing rules, Lean unicode pairs, treesitter integration
- **Issue**: Configured for nvim-cmp, not blink.cmp

### Integration Challenge
- **Current**: No direct nvim-autopairs + blink.cmp integration
- **Status**: Open GitHub issue (#477) from Oct 2024 with 24+ community upvotes
- **Research Finding**: blink.cmp has experimental auto-brackets for function completions
- **Solution**: Community-proposed callback workaround + hybrid approach

## Language-Specific Requirements

### LaTeX/TeX
```lua
-- Critical features to restore:
Rule("$", "$", "tex")                          -- Dollar sign pairs
Rule(' ', ' '):with_pair(function(opts)        -- Spacing in $$, (), {}, []
  return vim.tbl_contains({ '$$', '()', '{}', '[]', '<>' }, pair)
end)
Rule("$ ", " ", "tex"):with_pair(cond.not_after_regex(" "))  -- Context-aware spacing
```

### Lean Mathematics
```lua
-- Unicode mathematical pairs:
Rule("�", "�", "lean"),  -- Angle brackets
Rule("�", "�", "lean"),  -- Guillemets  
Rule("�", "�", "lean"),  -- Mathematical left/right double angle bracket
Rule("�", "�", "lean"),  -- Mathematical left/right white curly bracket
```

### Python/JavaScript/Lua
```lua
-- Treesitter integration:
ts_config = {
  lua = { "string" },                 -- Don't pair in lua strings
  javascript = { "template_string" }, -- Don't pair in JS template strings
}
```

## Implementation Strategy

### Phase 1: Enable blink.cmp Auto-Brackets

**File**: `lua/neotex/plugins/lsp/blink-cmp.lua`

**Changes**:
```lua
completion = {
  accept = {
    auto_brackets = {
      enabled = true,
      default_brackets = { '(', ')' },
      kind_resolution = {
        enabled = true,
        blocked_filetypes = { 'tex', 'latex' }  -- Avoid conflicts with LaTeX
      },
      semantic_token_resolution = {
        enabled = true,
        blocked_filetypes = { 'tex', 'latex', 'lean' },
        timeout_ms = 400
      }
    }
  }
}
```

**Purpose**: Handle completion-triggered function brackets via blink.cmp's built-in system.

### Phase 2: Create autopairs.lua

**File**: `lua/neotex/plugins/tools/autopairs.lua` (new)

**Configuration**:
```lua
return {
  "windwp/nvim-autopairs",
  event = { "InsertEnter" },
  config = function()
    local autopairs = require("nvim-autopairs")
    local Rule = require('nvim-autopairs.rule')
    local cond = require('nvim-autopairs.conds')

    -- Basic setup
    autopairs.setup({
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        java = false,
        lean = false,
      },
      disable_filetype = { "TelescopePrompt", "spectre_panel" },
      disable_in_macro = true,
      disable_in_replace_mode = true,
      enable_moveright = true,
      ignored_next_char = "",
      enable_check_bracket_line = true,
    })

    -- Lean-specific unicode pairs
    local lean_rules = {
      Rule("�", "�", "lean"),
      Rule("(", ")", "lean"),
      Rule("[", "]", "lean"),
      Rule("{", "}", "lean"),
      Rule("`", "`", "lean"),
      Rule("'", "'", "lean"),
      Rule("�", "�", "lean"),
      Rule("�", "�", "lean"),
      Rule("�", "�", "lean"),
    }

    for _, rule in ipairs(lean_rules) do
      autopairs.add_rule(rule)
    end

    -- LaTeX-specific rules
    autopairs.add_rules({
      -- TeX backtick to apostrophe
      Rule("`", "'", "tex"),
      
      -- Dollar sign pairs
      Rule("$", "$", "tex"),
      
      -- Space handling for pairs
      Rule(' ', ' ')
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col, opts.col + 1)
            return vim.tbl_contains({ '$$', '()', '{}', '[]', '<>' }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({ '$  $', '(  )', '{  }', '[  ]', '<  >' }, context)
          end),
      
      -- Context-aware spacing rules
      Rule("$ ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
      Rule("[ ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
      Rule("{ ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
      Rule("( ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
      Rule("< ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
    })

    -- Enhanced dollar sign behavior
    autopairs.get_rule('$'):with_move(function(opts)
      return opts.char == opts.next_char:sub(1, 1)
    end)

    -- blink.cmp integration using community workaround
    setup_blink_integration()
  end,
}
```

### Phase 3: Update mini.lua

**File**: `lua/neotex/plugins/tools/mini.lua`

**Changes**:
```lua
-- Remove mini.pairs configuration (lines 36-62)
-- Keep: mini.cursorword, mini.comment, mini.ai
-- Remove: custom quote handling keymaps
```

### Phase 4: Custom blink.cmp Integration

**File**: `lua/neotex/plugins/tools/autopairs.lua` (addition)

**Research-Based Integration** (from GitHub issue #477):
```lua
-- Custom blink.cmp integration using community workaround
local function setup_blink_integration()
  local ok, _ = pcall(require, 'blink.cmp')
  if not ok then return end

  -- Use community-proposed solution from issue #477
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  
  -- Override CR keymap to include autopairs callback
  vim.keymap.set('i', '<CR>', function()
    local blink = require('blink.cmp')
    if blink.visible() then
      return blink.accept({ 
        callback = cmp_autopairs.on_confirm_done({
          filetypes = {
            tex = false, -- Disable for tex (conflicts with LaTeX rules)
            lean = true  -- Enable for lean
          }
        })
      })
    else
      return '<CR>'
    end
  end, { expr = true, silent = true })
end

setup_blink_integration()
```

### Phase 5: Update Plugin Loading

**File**: `lua/neotex/plugins/tools/init.lua`

**Ensure autopairs.lua is loaded**:
```lua
return {
  { import = "neotex.plugins.tools.autopairs" },
  -- other tool imports...
}
```

## Testing Protocol

### Pre-Migration Testing
1. **Document current behavior**:
   - Test basic bracket pairing in each language
   - Note which features work/don't work with mini.pairs
   - Screenshot/record current LaTeX and Lean workflows

### Post-Migration Testing

#### LaTeX Testing
```latex
% Test cases:
\begin{equation}
  E = mc^2  % Test $ pair insertion
\end{equation}

% Test spacing rules:
$a + b$           % Should create proper spacing
\frac{1}{2}       % Test {} spacing
\sqrt[n]{x}       % Test [] and {} combinations
```

#### Lean Testing  
```lean
-- Test unicode pairs:
theorem test : �a, b� = �b, a� := by sorry
def func : �input� � �output� := sorry
example : �A� ) �B� = �A ) B� := by sorry
variable {� : Type} [�Group ��]
```

#### Programming Languages Testing
```python
# Test string detection:
print("test string with (parentheses)")  # Should not auto-pair inside
f"template {variable}"                    # Test template strings

def function():  # Test completion + autopairs
    pass
```

#### Completion Integration Testing
1. **Function completions**: Type `print` + completion should add `()`
2. **Method completions**: Object methods should auto-bracket
3. **No conflicts**: Ensure blink.cmp and autopairs don't double-bracket

## Risk Assessment & Mitigation

### High Risk
- **Autopairs conflicts**: blink.cmp auto-brackets vs nvim-autopairs
  - *Mitigation*: Carefully configure filetype exclusions
  - *Fallback*: Disable one system if conflicts arise

### Medium Risk  
- **Performance impact**: Adding nvim-autopairs increases plugin overhead
  - *Mitigation*: Lazy loading on InsertEnter
  - *Monitoring*: Check startup time before/after

### Low Risk
- **Keymap conflicts**: Custom integration may override existing bindings
  - *Mitigation*: Test all completion keymaps thoroughly
  - *Fallback*: Revert to mini.pairs if integration fails

## Rollback Plan

If the migration fails or causes issues:

1. **Immediate rollback**:
   ```bash
   git checkout HEAD~1  # Revert to previous commit
   ```

2. **Partial rollback**:
   - Move autopairs.lua back to deprecated/
   - Restore mini.pairs configuration
   - Disable blink.cmp auto-brackets

3. **Alternative approach**:
   - Keep nvim-autopairs for LaTeX/Lean only
   - Use mini.pairs for other languages
   - Separate configurations by filetype

## Success Criteria

-  LaTeX `$` pairs work with proper spacing
-  Lean unicode pairs function correctly  
-  blink.cmp completions trigger brackets appropriately
-  No double-bracketing or conflicts
-  Treesitter integration prevents pairing in strings
-  Performance remains acceptable
-  All language workflows restored to previous functionality

## Future Considerations

### When Official Integration Arrives
- **Monitor**: GitHub issue #477 for nvim-autopairs blink.cmp support
- **Upgrade**: Replace custom integration with official solution
- **Test**: Ensure compatibility with existing language rules

### Alternative Solutions
- **blink.pairs**: Monitor alpha development for future migration
- **Other plugins**: Evaluate alternatives if current solution proves problematic

## Research Summary

### GitHub Investigation Results
- **nvim-autopairs**: Active project with extensive treesitter integration and custom rules
- **blink.cmp**: Modern completion plugin with experimental auto-brackets feature
- **Integration Status**: No official support, but community workaround exists (issue #477)
- **Community Solution**: Use blink.cmp's callback system with nvim-autopairs handlers

### Key Technical Findings
1. **blink.cmp auto-brackets**: Uses semantic tokens for intelligent function bracket insertion
2. **Callback system**: `accept({ callback = function })` allows custom post-completion actions
3. **Filetype exclusions**: Can prevent conflicts between auto-bracket systems
4. **Community adoption**: 24+ upvotes on integration request shows demand

## Implementation Timeline

1. **Phase 1**: Enable blink.cmp auto-brackets with LaTeX/Lean exclusions
2. **Phase 2**: Create autopairs.lua with all LaTeX/Lean rules
3. **Phase 3**: Remove mini.pairs configuration
4. **Phase 4**: Implement community workaround for completion integration
5. **Testing**: Comprehensive validation across all languages
6. **Commit**: Document changes and create commit

---

**Research Completed**: December 2024  
**Status**: Ready for implementation  
**Based on**: GitHub issues #477, official documentation, community solutions