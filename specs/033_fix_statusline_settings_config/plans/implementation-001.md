# Implementation Plan: Task #33

- **Task**: 33 - Fix Claude Code settings.json statusLine configuration
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None (task 32 sidebar display depends on this fix)
- **Research Inputs**: specs/033_fix_statusline_settings_config/reports/research-001.md
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Fix the Claude Code settings.json by moving `statusLine` from incorrectly nested `hooks` object to its correct top-level position. The current configuration has `statusLine` inside `hooks`, but `statusLine` is NOT a hook event - it is a separate top-level configuration field. Additionally, update the statusline-push.sh script to use official JSON field names from the Claude Code schema.

### Research Integration

Key findings from research-001.md:
- `statusLine` must be a top-level field, not nested inside `hooks`
- Known bug (GitHub #13517): external script paths may not be invoked in certain versions
- Workaround: use inline commands if external scripts fail
- Script uses incorrect field names (`context_window.context_used`) vs official schema (`context_window.used_percentage`)

## Goals and Non-Goals

**Goals**:
- Fix settings.json structure by moving statusLine to top-level
- Update script field names to match official Claude Code JSON schema
- Verify statusline functionality end-to-end
- Provide fallback inline command if external script fails

**Non-Goals**:
- Modifying the Neovim lualine integration (covered by task 32)
- Adding new statusline features beyond fixing current configuration
- Addressing other hooks configurations

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| External script not invoked (bug #13517) | H | M | Prepare inline command fallback |
| Field names differ from actual runtime JSON | M | L | Test with debug logging to capture actual input |
| Script permissions or path issues | L | L | Use absolute path, verify executable permission |

## Implementation Phases

### Phase 1: Fix settings.json Structure [NOT STARTED]

**Goal**: Move statusLine from hooks object to top-level field

**Tasks**:
- [ ] Read current ~/.claude/settings.json
- [ ] Create corrected settings.json with statusLine at top-level
- [ ] Remove statusLine from hooks object (keep hooks object empty or remove if no other hooks)
- [ ] Verify JSON syntax is valid

**Timing**: 15 minutes

**Files to modify**:
- `~/.claude/settings.json` - Move statusLine to top-level

**Expected result**:
```json
{
  "model": "sonnet",
  "statusLine": {
    "type": "command",
    "command": "/home/benjamin/.claude/hooks/statusline-push.sh",
    "padding": 0
  }
}
```

**Verification**:
- JSON is valid (jq parse succeeds)
- statusLine is at root level, not inside hooks
- No "Invalid key in record" error from Claude Code

---

### Phase 2: Update Script Field Names [NOT STARTED]

**Goal**: Update statusline-push.sh to use official Claude Code JSON schema field names

**Tasks**:
- [ ] Update `context_window.context_used` references to use `context_window.current_usage` fields or `used_percentage`
- [ ] Update `context_window.context_limit` to `context_window.context_window_size`
- [ ] Update `model` field path (may be `.model.display_name` instead of `.model`)
- [ ] Update `current_cost.total_cost` to `cost.total_cost_usd`
- [ ] Add debug logging option to capture actual JSON input

**Timing**: 30 minutes

**Files to modify**:
- `~/.claude/hooks/statusline-push.sh` - Update jq field paths

**Official field paths** (from research):
```
.model.display_name        # Model display name
.context_window.used_percentage           # Pre-calculated percentage
.context_window.context_window_size       # Total context limit
.context_window.current_usage.input_tokens + output_tokens  # Current usage
.cost.total_cost_usd       # Total cost
```

**Verification**:
- Script executes without jq errors
- Test with sample JSON input matching official schema

---

### Phase 3: Test External Script Invocation [NOT STARTED]

**Goal**: Verify if Claude Code invokes the external script path

**Tasks**:
- [ ] Start a Claude Code session
- [ ] Send a prompt to trigger statusline update
- [ ] Check if /tmp/claude-context.json is created/updated
- [ ] If not created, note that bug #13517 applies

**Timing**: 15 minutes

**Files to modify**:
- None (testing phase)

**Verification**:
- /tmp/claude-context.json exists and has recent timestamp
- OR: Document that external script invocation fails

---

### Phase 4: Apply Inline Command Fallback (If Needed) [NOT STARTED]

**Goal**: If external script not invoked, use inline command workaround

**Tasks**:
- [ ] Only execute if Phase 3 shows external script not working
- [ ] Update settings.json to use inline command instead of script path
- [ ] Inline command should: read stdin, write to /tmp/claude-context.json, output statusline

**Timing**: 20 minutes (conditional)

**Files to modify**:
- `~/.claude/settings.json` - Replace command path with inline script

**Inline command format**:
```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); echo \"$input\" > /tmp/claude-context.json; MODEL=$(echo \"$input\" | jq -r '.model.display_name // \"Claude\"'); PERCENT=$(echo \"$input\" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1); printf \"%s | %d%%\" \"$MODEL\" \"$PERCENT\"",
    "padding": 0
  }
}
```

**Verification**:
- /tmp/claude-context.json is created after Claude Code prompt
- Statusline displays in Claude Code terminal

---

### Phase 5: End-to-End Verification [NOT STARTED]

**Goal**: Verify complete statusline pipeline works

**Tasks**:
- [ ] Start Claude Code session
- [ ] Send several prompts to update context usage
- [ ] Verify /tmp/claude-context.json updates with each prompt
- [ ] Verify JSON contains expected fields (percentage, model, cost)
- [ ] If task 32 lualine is implemented, verify Neovim displays context

**Timing**: 15 minutes

**Files to modify**:
- None (verification phase)

**Verification**:
- /tmp/claude-context.json updates in real-time
- JSON structure matches expected format
- No errors in Claude Code or script execution

## Testing and Validation

- [ ] JSON syntax validation: `jq . ~/.claude/settings.json`
- [ ] Script syntax validation: `bash -n ~/.claude/hooks/statusline-push.sh`
- [ ] Script execution test with sample input
- [ ] Claude Code session test: statusline appears
- [ ] File output test: /tmp/claude-context.json created and updated

## Artifacts and Outputs

- Updated `~/.claude/settings.json` with correct statusLine configuration
- Updated `~/.claude/hooks/statusline-push.sh` with official field names
- Optional: inline command fallback if external script fails

## Rollback/Contingency

If implementation fails:
1. Restore original settings.json (backup before modification)
2. Original script remains functional for future fix attempts
3. Task 32 (lualine integration) can proceed with manual testing

Backup command:
```bash
cp ~/.claude/settings.json ~/.claude/settings.json.backup
cp ~/.claude/hooks/statusline-push.sh ~/.claude/hooks/statusline-push.sh.backup
```
