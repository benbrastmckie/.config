# Settings.local.json Sync Strategy Research Report

## Metadata
- **Date**: 2025-12-04
- **Agent**: research-specialist
- **Topic**: settings.local.json sync strategy
- **Report Type**: codebase analysis

## Executive Summary

The current settings.local.json file contains both universally applicable configurations (hooks structure) and project-specific permissions (absolute paths to /home/benjamin/.config). According to Claude Code's official documentation, settings.local.json is intended for personal, machine-specific preferences that should NOT be version controlled or synced between projects. The sync utility currently treats it as a regular artifact, which could propagate project-specific permissions to other projects. Recommended approach: exclude settings.local.json from sync operations and document its purpose as a local-only configuration file.

## Findings

### Current State Analysis

**File Location**: `/home/benjamin/.config/.claude/settings.local.json`

**Structure** (lines 1-79):
```json
{
  "permissions": {
    "allow": [28 entries],
    "deny": [],
    "ask": []
  },
  "hooks": {
    "Stop": [...],
    "Notification": [...],
    "SubagentStop": [...]
  }
}
```

**Content Breakdown**:
1. **Permissions Section** (28 entries):
   - 4 entries contain hardcoded absolute paths specific to `/home/benjamin/.config`
   - Examples (lines from settings.local.json):
     - `Read(//home/benjamin/.local/share/nvim/lazy/claude-code.nvim/**)`
     - `Bash(do echo "=== $test ===" head -5 "/home/benjamin/.config/.claude/tests/$test.sh")`
     - `Bash(EXISTING_PLAN_PATH="/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md")`
     - `Bash(source /home/benjamin/.config/.claude/tmp/workflow_coordinate_1763180944.sh)`
   - 6 entries are generic command permissions that could apply universally:
     - `Bash(grep:*)`, `Bash(bash:*)`, `Bash(awk:*)`, `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git checkout:*)`
   - Remaining 18 entries are workflow-specific permissions accumulated over time

2. **Hooks Section** (lines 36-78):
   - Uses `$CLAUDE_PROJECT_DIR` environment variable for path resolution
   - Hook commands reference: `$CLAUDE_PROJECT_DIR/.claude/hooks/post-command-metrics.sh`
   - This structure is PROJECT-PORTABLE (environment variable resolves per-project)
   - 3 hook types configured: Stop, Notification, SubagentStop
   - 5 unique hook scripts referenced

**Key Finding**: The hooks section is universally applicable because it uses `$CLAUDE_PROJECT_DIR`, but the permissions section contains project-specific absolute paths that would break if synced to other projects.

### Sync Utility Analysis

**Current Sync Behavior** (sync.lua:619, 871):
```lua
local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")
```

**Scan Logic** (scan.lua:192):
- Settings file is scanned with empty subdir (`""`) meaning it's in `.claude/` root
- Treated identically to other artifacts (commands, agents, hooks)
- No special handling or exclusion logic

**Sync Strategies Available** (sync.lua:972-1001):
1. **Replace + add new**: Overwrites local settings.local.json with global version
2. **Add new only**: Copies settings.local.json if it doesn't exist locally
3. **Interactive**: Prompts user per-file (including settings.local.json)
4. **Clean copy**: Removes all artifacts including settings.local.json (line 511), then replaces with global versions

**Critical Issue** (sync.lua:774):
```lua
local set_count = sync_files(settings, false, merge_only)
```
Settings file is synced using the same `sync_files()` function as all other artifacts, with NO special logic.

**Clean Replace Behavior** (sync.lua:511, 536-548):
```lua
local settings_file = claude_dir .. "/settings.local.json"
if vim.fn.filereadable(settings_file) == 1 then
  local result = vim.fn.delete(settings_file)
  -- Deletes settings.local.json entirely
end
```

**Implication**: Syncing settings.local.json to another project would:
- Copy permissions with hardcoded paths (e.g., `/home/benjamin/.config/...`)
- These paths won't exist in the target project
- Permissions would fail or grant access to wrong directories
- Hooks section would work correctly (uses $CLAUDE_PROJECT_DIR)

### Settings File Content Analysis

**Section-by-Section Analysis**:

1. **Permissions Section** - MIXED PORTABILITY:
   - Generic command permissions (6/28): PORTABLE
     - `Bash(grep:*)`, `Bash(git add:*)`, etc. - work anywhere
   - Absolute path permissions (4/28): NON-PORTABLE
     - `/home/benjamin/.config/...` - fail in other projects
   - Workflow-specific permissions (18/28): SESSION-SPECIFIC
     - Accumulated from individual command executions
     - Examples: `Bash(while read test)`, `Bash(timeout 120 ./run_all_tests.sh:*)`
     - Likely granted during interactive prompts, not intended for long-term storage

2. **Hooks Section** - FULLY PORTABLE:
   - All hooks use `$CLAUDE_PROJECT_DIR` variable
   - Hook commands are relative to project root: `$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh`
   - Would work identically in any project with same hook scripts
   - 3 hook types (Stop, Notification, SubagentStop) are Claude Code standard events

**Recommended Sections for Settings Types**:

**settings.local.json (LOCAL ONLY, NOT SYNCED)**:
- Session-specific permissions accumulated during work
- Project-specific absolute paths
- Machine-specific overrides
- Experimental permissions

**settings.json (SHARED, VERSION CONTROLLED)**:
- Team-approved permission rules
- Standard hook configurations (portable)
- Project-wide security policies

**~/.claude/settings.json (USER GLOBAL)**:
- Generic command permissions (grep, git, bash)
- User preference for hook behavior
- Personal tool configurations

### Alternative Approaches

**Option A: Exclude settings.local.json from Sync**

**Implementation**:
```lua
-- In scan.lua line 192, remove settings scan
-- OR in sync.lua, filter out settings before syncing
local function filter_settings(artifacts)
  return vim.tbl_filter(function(file)
    return file.name ~= "settings.local.json"
  end, artifacts)
end
```

**Pros**:
- Aligns with official Claude Code intent (local-only file)
- Prevents accidental propagation of project-specific permissions
- Simple to implement (single line change)
- No breaking changes to existing workflows

**Cons**:
- Users wanting to sync hooks configuration must manually copy
- Loss of convenience for initial project setup

**Suitability**: RECOMMENDED - Aligns with official Claude Code design

---

**Option B: Selective Section Merging**

**Implementation**:
```lua
local function merge_settings(global_settings, local_settings)
  local merged = vim.deepcopy(local_settings)
  -- Only merge hooks section (portable)
  if global_settings.hooks then
    merged.hooks = global_settings.hooks
  end
  -- Preserve local permissions (non-portable)
  return merged
end
```

**Pros**:
- Syncs portable configurations (hooks) while preserving local permissions
- More sophisticated than blanket exclusion
- Users get hook configurations automatically

**Cons**:
- Complex implementation requiring JSON parsing and merging
- Unclear user expectations (which sections sync, which don't?)
- Requires settings file format awareness
- Harder to maintain as settings schema evolves

**Suitability**: POSSIBLE but complex - requires careful design

---

**Option C: Template-Based Settings**

**Implementation**:
```lua
-- settings.template.json (synced, version controlled)
{
  "hooks": {
    "Stop": [...]  // Standard hooks
  },
  "permissions": {
    "allow": [
      "Bash(git *:*)",
      "Bash(grep:*)"
    ]
  }
}

-- User runs: claude setup-settings
-- Creates settings.local.json from template
```

**Pros**:
- Clear separation: template (synced) vs instance (local)
- Documentation through example
- Users can customize after initialization
- Aligns with common config file patterns (.env.example)

**Cons**:
- Requires new setup command/workflow
- Users must manually run setup
- Template can become outdated if not maintained
- Adds complexity to project structure

**Suitability**: OVERKILL for current use case

---

**Option D: Settings Layering (Advanced)**

**Implementation**:
```lua
-- Load order:
-- 1. ~/.claude/settings.json (user defaults)
-- 2. .claude/settings.json (project shared)
-- 3. .claude/settings.local.json (project local overrides)
-- Merge with deep merge strategy
```

**Pros**:
- Maximum flexibility
- Follows industry patterns (VS Code, ESLint)
- Clear precedence hierarchy
- Different concerns in different files

**Cons**:
- Claude Code already implements this hierarchy (official docs confirm)
- Doesn't solve the sync problem
- Not in scope for sync utility changes

**Suitability**: ALREADY EXISTS in Claude Code

---

**Option E: Sync with Confirmation Dialog**

**Implementation**:
```lua
-- When settings.local.json detected in sync:
if has_settings_file then
  local choice = vim.fn.confirm(
    "settings.local.json contains local preferences.\n" ..
    "Syncing may copy project-specific permissions.\n\n" ..
    "What would you like to do?",
    "&Skip\n&Replace\n&View diff"
  )
end
```

**Pros**:
- User awareness and control
- Doesn't prevent syncing for users who want it
- Educational (explains the issue)

**Cons**:
- Friction in sync workflow
- Users may not understand the implications
- Still allows problematic syncs
- Doesn't solve root issue

**Suitability**: SUPPLEMENTARY - could pair with Option A

### Claude Code Official Patterns

**Official Documentation Sources**:
- https://code.claude.com/docs/en/settings (official settings documentation)
- https://docs.claude.com/en/docs/claude-code/settings (redirects to above)

**Key Findings from Official Docs**:

1. **Settings Hierarchy** (Precedence Order):
   ```
   1. Enterprise managed policies (highest)
   2. Command line arguments
   3. Local project settings (.claude/settings.local.json)
   4. Shared project settings (.claude/settings.json)
   5. User settings (~/.claude/settings.json) (lowest)
   ```

2. **File Purposes**:

   **`.claude/settings.json`** (Shared Project Settings):
   - "Intended for team collaboration and source control"
   - "Checked into version control"
   - "Contains project-specific configurations shared across the team"

   **`.claude/settings.local.json`** (Personal Project Settings):
   - "For individual machine-specific preferences"
   - "NOT checked into version control"
   - "Claude Code automatically configures git to ignore this file upon creation"
   - "Useful for personal experimentation and local overrides"

3. **Configuration Sections**:
   - Both files support identical structures for permissions and hooks
   - Allows "flexible configuration at appropriate levels"
   - Team consistency through shared settings.json
   - Individual customization through settings.local.json

**Critical Design Intent**:
`.claude/settings.local.json` is EXPLICITLY designed to be:
- Local to the machine
- NOT shared between projects
- NOT version controlled
- For personal experimentation

**Current Sync Behavior Violates This Intent**: The sync utility treating settings.local.json as a regular artifact contradicts the official Claude Code design where this file should remain local and personal.

**Best Practice Pattern**:
```
~/.claude/settings.json           → Generic user preferences (all projects)
project/.claude/settings.json     → Team-shared project config (version controlled)
project/.claude/settings.local.json → Personal overrides (gitignored, local-only)
```

## Recommendations

### 1. Exclude settings.local.json from Sync Operations (PRIORITY: HIGH)

**Rationale**:
- Aligns with official Claude Code design intent
- Prevents propagation of project-specific permissions
- Maintains clear distinction between shared and local configurations

**Implementation**:
```lua
-- In sync.lua, remove settings from scanned artifacts:
-- Line 871 and 619: DELETE or comment out:
-- local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")

-- In load_all_with_strategy(), remove settings parameter and sync call
-- Line 774: DELETE:
-- local set_count = sync_files(settings, false, merge_only)

-- Update function signature and callers to remove settings parameter
```

**Files to Modify**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` (lines 619, 774, 871)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` (line 192, optional)

**Impact**:
- Sync operations will skip settings.local.json entirely
- Users must manually configure hooks in new projects (or use settings.json)
- Existing local settings files remain untouched

### 2. Document settings.local.json Purpose (PRIORITY: MEDIUM)

**Create documentation**: `.claude/docs/guides/configuration/settings-files-guide.md`

**Content**:
- Explain three-tier settings hierarchy (user, project shared, project local)
- When to use settings.json vs settings.local.json
- Examples of portable vs non-portable configurations
- How to set up hooks in shared settings.json for team use
- Migration guide for moving hooks from .local.json to .json

**Reference from**:
- `.claude/README.md` (settings.local.json section, line 475)
- Nvim sync README (`nvim/lua/neotex/plugins/ai/claude/commands/README.md`, line 159)

### 3. Migrate Hooks to Shared settings.json (PRIORITY: MEDIUM)

**Current State**: Hooks are in settings.local.json, not shared with team

**Recommended Action**:
```bash
# Extract hooks section from settings.local.json
jq '.hooks' .claude/settings.local.json > .claude/settings.json

# Verify portability (all paths use $CLAUDE_PROJECT_DIR)
grep -v '\$CLAUDE_PROJECT_DIR' .claude/settings.json && echo "WARN: Hardcoded paths found"

# Commit to version control
git add .claude/settings.json
git commit -m "Add shared hook configurations"
```

**Rationale**:
- Hooks using `$CLAUDE_PROJECT_DIR` are fully portable
- Should be shared with team for consistent experience
- Aligns with Claude Code best practices

### 4. Clean Up Accumulated Permissions (PRIORITY: LOW)

**Current State**: 28 permission entries, many session-specific

**Recommended Action**:
```bash
# Review permissions and keep only intentional ones
jq '.permissions.allow = [
  "Bash(git *:*)",
  "Bash(grep:*)",
  "Read(//tmp/**)"
]' .claude/settings.local.json > .claude/settings.local.json.new

# Move to settings.local.json after review
```

**Rationale**:
- Most permissions were granted during interactive prompts
- Not meant for long-term storage
- Reduces clutter and potential security issues

### 5. Consider Adding settings.json Template (PRIORITY: LOW)

**Implementation**:
```bash
# Create .claude/settings.json with standard hooks
cat > .claude/settings.json <<'EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-command-metrics.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ]
  }
}
EOF
```

**Benefit**:
- Other projects can sync this file
- Provides standard hook setup
- Documents expected hook configuration

## References

**Configuration Files**:
- `/home/benjamin/.config/.claude/settings.local.json` (lines 1-79) - Current settings file with mixed portable/non-portable content
- `/home/benjamin/.config/.claude/hooks/README.md` (lines 427, 491, 721) - Hook registration documentation

**Sync Utility Code**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` (lines 464, 511, 619, 774, 871) - Settings file sync logic
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` (lines 37-89, 192) - Directory scanning for sync operations

**Previous Research**:
- `/home/benjamin/.config/.claude/specs/038_nvim_sync_clean_replace/reports/001-nvim-sync-clean-replace-research.md` (lines 138, 164, 247, 328) - Clean replace documentation showing settings.local.json handling

**Official Documentation**:
- [Claude Code Settings Documentation](https://code.claude.com/docs/en/settings) - Official settings hierarchy and file purposes
- [A developer's guide to settings.json in Claude Code (2025)](https://www.eesel.ai/blog/settings-json-claude-code) - Settings file best practices
- [Claude Code Configuration Guide](https://claudelog.com/configuration/) - Configuration patterns and examples
