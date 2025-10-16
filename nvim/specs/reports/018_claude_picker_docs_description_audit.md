# Claude Commands Picker Docs Description Audit

## Metadata
- **Date**: 2025-10-08
- **Audit Scope**: [Docs] entries in `<leader>ac` Claude commands picker
- **Parser Location**: nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:163-202
- **Status**: ✅ FIXED (2025-10-08, commit 78792e7)

## Executive Summary

All docs files in `.claude/docs/` have meaningful descriptions on line 3 (plain text after title). The description parser has been updated to extract plain text instead of headings, significantly improving the picker UX.

**Status**: ✅ Fixed - All 17 docs now display meaningful descriptions in picker.

## Parser Behavior Analysis

### Current Logic (picker.lua:189-197)
```lua
elseif line:match("^#%s+") then
  -- Found a heading
  if not after_title then
    after_title = true  -- Skip the title
  else
    -- Second heading is likely a description
    local heading = line:match("^#%s+(.+)$")
    return heading:sub(1, 40)
  end
end
```

**Issue**: This only extracts **headings** (lines with `#`), not plain text.

### Actual Docs Format
All docs follow this pattern:
```markdown
# Title
Plain text description here
## Overview
```

**Result**: Parser extracts "Overview" instead of the plain text description.

## Docs File Inventory

### Files Audited (17 total)

| File | Title (Line 1) | Description (Line 3) | Second Heading (Line 5) |
|------|----------------|----------------------|-------------------------|
| adaptive-plan-structures.md | Adaptive Plan Structures Guide | Comprehensive guide to the three-tier... | ## Overview |
| agent-development-guide.md | Agent Development Guide | Guide for creating and maintaining... | ## Overview |
| agent-integration-guide.md | Agent Integration Guide | Comprehensive guide for integrating... | ## Overview |
| checkpointing-guide.md | Workflow Checkpointing Guide | Complete guide to workflow checkpointing... | ## Overview |
| claude-md-section-schema.md | CLAUDE.md Section Schema | This document defines the standard format... | ## Schema Overview |
| command-standardization-checklist.md | Command Standardization Checklist | This document provides a checklist... | ## Standardization Status |
| command-standards-flow.md | Command Standards Flow | This document illustrates how standards... | ## Complete Workflow Diagram |
| efficiency-guide.md | Workflow Efficiency Guide | This guide documents the efficiency... | ## Overview |
| error-enhancement-guide.md | Error Enhancement Guide | Complete guide to enhanced error messages... | ## Overview |
| migration-guide-adaptive-plans.md | Migration Guide: Adopting Adaptive... | Guide for migrating existing single-file... | ## Overview |
| parallel-execution-example.md | Parallel Execution Example Plan | This is an example implementation plan... | ## Overview |
| README.md | Docs Directory | Comprehensive documentation and integration... | ## Purpose |
| standards-integration-examples.md | Standards Integration Examples | This document provides concrete examples... | ## Example 1: Discovering CLAUDE.md |
| standards-integration-pattern.md | Standards Integration Pattern for Commands | This document provides a reusable template... | ## Overview |
| template-system-guide.md | Template System Guide | Comprehensive guide for creating and using... | ## Table of Contents |
| tts-integration-guide.md | TTS Integration Guide | Comprehensive guide for Claude Code... | ## Overview |
| tts-message-examples.md | TTS Message Examples | Complete reference of TTS message templates... | ## Uniform Message Format |

### Summary
- **Total docs**: 17
- **With plain text descriptions**: 17 (100%)
- **Parser extracting correctly**: 0 (0%)
- **Parser extracting headings instead**: 17 (100%)

## Implementation

### ✅ Fix Applied (Commit 78792e7)

Updated parser to extract plain text between title and first `##` heading:

```lua
local function parse_doc_description(filepath)
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    return ""
  end

  local success, lines = pcall(vim.fn.readfile, filepath, "", 30)
  if not success or not lines then
    return ""
  end

  local in_frontmatter = false
  local after_title = false

  for _, line in ipairs(lines) do
    -- Check for YAML frontmatter
    if line == "---" then
      if not in_frontmatter then
        in_frontmatter = true
      else
        in_frontmatter = false
      end
    elseif in_frontmatter then
      local desc = line:match("^description:%s*(.+)$")
      if desc then
        return desc:sub(1, 40)
      end
    elseif line:match("^#%s+[^#]") then
      -- Found a heading (# Title, not ## Subheading)
      after_title = true
    elseif after_title and line ~= "" and not line:match("^#") then
      -- Plain text after title, before any subheading
      return line:sub(1, 40)
    end
  end

  return ""
end
```

**Result**: Successfully captures actual description text, much more informative than "Overview".

## Testing Results

After implementing the fix:

✅ **All 17 docs verified** - Descriptions extracted correctly:

| File | Description Extracted (40 char limit) |
|------|--------------------------------------|
| adaptive-plan-structures | Comprehensive guide to the three-tier ad |
| agent-development-guide | Guide for creating and maintaining custo |
| agent-integration-guide | Comprehensive guide for integrating and |
| checkpointing-guide | Complete guide to workflow checkpointing |
| claude-md-section-schema | This document defines the standard forma |
| command-standardization-checklist | This document provides a checklist for e |
| command-standards-flow | This document illustrates how standards |
| efficiency-guide | This guide documents the efficiency enha |
| error-enhancement-guide | Complete guide to enhanced error message |
| migration-guide-adaptive-plans | Guide for migrating existing single-file |
| parallel-execution-example | This is an example implementation plan d |
| README | Comprehensive documentation and integrat |
| standards-integration-examples | This document provides concrete examples |
| standards-integration-pattern | This document provides a reusable templa |
| template-system-guide | Comprehensive guide for creating and usi |
| tts-integration-guide | Comprehensive guide for Claude Code text |
| tts-message-examples | Complete reference of TTS message templa |

**Success Rate**: 17/17 (100%)

## Conclusion

✅ **Fix successfully implemented**. All docs files now display meaningful descriptions in the picker, significantly improving user experience. The simple parser update immediately improved all 17 entries without requiring any doc file modifications.
