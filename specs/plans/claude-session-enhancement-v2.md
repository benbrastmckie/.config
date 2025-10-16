# Claude Session Enhancement - Minimal Refactor Plan (v2)

## Overview
**REVISED PLAN**: Minimal, surgical improvements to the existing Claude session functionality. Focus on fixing the specific `<C-c>` picker issue without breaking working features.

## Core Principle: "If It Works, Don't Break It"
The previous refactor failed because it tried to rebuild everything from scratch. This plan takes the opposite approach - make the smallest possible changes to achieve the desired outcome.

## Timeline: 1 Week (Incremental)
**Start Date**: When ready
**Approach**: Small, tested commits that can be reverted individually

## Success Criteria
- [ ] `<C-c>` shows simplified 3-option picker when appropriate
- [ ] All existing functionality continues to work
- [ ] No breaking changes or new dependencies
- [ ] Each change is independently testable and revertible

---

## Implementation Strategy

### What We're NOT Doing
❌ **NO complete architecture overhaul**
❌ **NO new dependency injection frameworks**
❌ **NO breaking existing working functions**
❌ **NO Claude CLI dependency for basic functionality**
❌ **NO complex error handling layers**
❌ **NO moving files around unnecessarily**

### What We ARE Doing
✅ **Surgical fix to the picker logic only**
✅ **Keep all existing file locations**
✅ **Preserve all working functionality**
✅ **Add simple session filtering logic**
✅ **Test each small change before proceeding**

---

## Phase 1: Understand Current State (Day 1)

### Tasks
1. **Analyze the current working implementation**
   - [ ] Map out how `smart_toggle()` currently works
   - [ ] Identify where it shows all sessions
   - [ ] Find the minimal change point

2. **Document current behavior**
   - [ ] What triggers the full session list?
   - [ ] Where is the picker created?
   - [ ] What data structure holds sessions?

### Deliverable
- Brief analysis document showing the exact function that needs modification

---

## Phase 2: Add Simple Filtering (Day 2)

### Tasks
1. **Create a simple filter function**
   ```lua
   -- Add to existing claude-worktree.lua or claude-session.lua
   local function get_top_sessions(sessions, max_count)
     -- Sort by most recent
     -- Return top N sessions
     -- NO complex scoring algorithms
   end
   ```

2. **Test the filter independently**
   - [ ] Verify it returns correct number of sessions
   - [ ] Ensure it doesn't break with empty lists
   - [ ] Check it handles edge cases

### Files to Modify
- **ONLY** the file containing the session picker logic (likely `claude-worktree.lua`)
- **NO** new files or modules

---

## Phase 3: Update Picker Logic (Day 3)

### Tasks
1. **Modify the existing picker call**
   ```lua
   -- BEFORE:
   telescope_ui:session_picker(sessions, callback)

   -- AFTER:
   local display_sessions = #sessions > 3 and get_top_sessions(sessions, 3) or sessions
   telescope_ui:session_picker(display_sessions, callback)
   ```

2. **Add "Show All" option if filtered**
   ```lua
   if #sessions > 3 then
     table.insert(display_sessions, {
       id = "show_all",
       name = "Show all sessions...",
       action = function() show_full_picker(sessions) end
     })
   end
   ```

### Testing Checklist
- [ ] With 0 sessions: Shows "No sessions"
- [ ] With 1-3 sessions: Shows all sessions
- [ ] With 4+ sessions: Shows top 3 + "Show all" option
- [ ] "Show all" opens full picker
- [ ] No existing keybindings broken

---

## Phase 4: Add Context Awareness (Day 4) - OPTIONAL

**Only if Phase 3 works perfectly**

### Tasks
1. **Add simple context detection**
   ```lua
   local function get_current_context()
     -- Just get current git branch
     -- Return simple string, not complex object
   end
   ```

2. **Prefer matching sessions**
   ```lua
   local function prefer_matching_branch(sessions, branch)
     -- Simple: put matching branch sessions first
     -- Then sort by recency
   end
   ```

### Critical Rule
- If context detection fails, **fall back to showing all sessions**
- Never break functionality for "smart" features

---

## Phase 5: Testing & Refinement (Day 5)

### Manual Testing Protocol
1. Test `<C-c>` with:
   - [ ] No sessions
   - [ ] 1 session
   - [ ] 3 sessions
   - [ ] 10 sessions

2. Test other mappings still work:
   - [ ] `<leader>as` - Shows all sessions
   - [ ] `<leader>av` - Shows worktrees
   - [ ] `<leader>aw` - Creates worktree
   - [ ] `<leader>ar` - Restores session

3. Edge cases:
   - [ ] Non-git directories
   - [ ] Corrupted session files
   - [ ] Very long session names

### Rollback Plan
- Each change should be a separate commit
- If anything breaks, revert that specific commit
- Never commit changes that break existing functionality

---

## Implementation Guidelines

### Code Changes
1. **Modify in place** - Don't create new files unless absolutely necessary
2. **Preserve signatures** - Don't change function parameters or returns
3. **Add, don't replace** - New logic should supplement, not replace existing
4. **Comment thoroughly** - Mark all changes with comments

### Example Safe Change
```lua
-- In existing smart_toggle or session_picker function

-- ADDED: Simple session filtering for better UX
local function should_show_simple_picker(sessions)
  return #sessions > 3
end

if should_show_simple_picker(sessions) then
  -- NEW: Show filtered view
  local top_sessions = {}
  for i = 1, math.min(3, #sessions) do
    table.insert(top_sessions, sessions[i])
  end

  -- Add "show all" option
  table.insert(top_sessions, {
    id = "show_all",
    name = "Show all " .. #sessions .. " sessions...",
    -- ... rest of option
  })

  show_picker(top_sessions)  -- Use existing picker
else
  -- EXISTING: Show all sessions as before
  show_picker(sessions)
end
```

---

## Risk Mitigation

### Red Flags to Avoid
1. **"Let's reorganize the architecture"** - NO
2. **"We should use dependency injection"** - NO
3. **"This needs a new module"** - Probably NO
4. **"Let's make it more elegant"** - Focus on working first

### Safe Practices
1. **Test after every change**
2. **Commit working states frequently**
3. **Keep backup of working configuration**
4. **Document what changed and why**

---

## Alternative: Config-Only Solution

If code changes prove risky, consider a pure configuration approach:

```lua
-- In user's config or which-key setup
vim.g.claude_simple_picker_max = 3  -- Show simple picker if > 3 sessions
vim.g.claude_simple_picker_enabled = true  -- Enable/disable feature
```

Then check these variables in existing code with minimal changes.

---

## Success Metrics

### Must Have
- [ ] `<C-c>` behavior improved for many sessions
- [ ] Zero functionality regression
- [ ] All changes are revertible

### Nice to Have
- [ ] Branch-aware session ordering
- [ ] "Recent sessions" in simple picker
- [ ] Remember last used session

### Won't Have (This Iteration)
- [ ] Complex scoring algorithms
- [ ] Claude CLI integration
- [ ] New architecture patterns
- [ ] Complete rewrite of any module

---

## Post-Implementation Review

After implementation, document:
1. What was actually changed (file:line references)
2. Why each change was made
3. What could break and how to fix it
4. How to revert if needed

---

## Summary

This plan focuses on **fixing the specific problem** (too many sessions in picker) with **minimal risk** to working functionality. The previous refactor failed because it tried to improve everything at once. This plan succeeds by improving one thing carefully.

**Remember**: Working code that could be better > Broken code with perfect architecture

---

*Plan created: 2025-09-24*
*Status: Ready for careful implementation*
*Approach: Minimal intervention, maximum preservation*