# Command Dependency Loading Implementation Plan

## Metadata
- **Date**: 2025-10-08
- **Feature**: Accurate command dependency loading for `<leader>ac` picker
- **Scope**: Picker and parser modules in claude commands system
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: None (original request included non-existent report path)

## Revision History

### 2025-10-08 - Revision 1
**Changes**: Refocused plan from changing loading behavior to verifying/enhancing accuracy
**Reason**: User prefers current loading behavior (dependents down-tree only), wants accuracy verification instead
**Key Adjustments**:
- Phase 1: Changed from "fix loading" to "audit dependencies" - systematically verify all command metadata
- Phase 2: Changed from "parent loading" to "agent loading" - automatically load agents with commands
- Phase 3: Kept validation system - detect stale metadata over time
- Phase 4: Changed from "dynamic detection" to "documentation" - make phase 4 optional docs work
**Impact**: Plan now preserves existing loading behavior while ensuring metadata accuracy and agent integration

### 2025-10-08 - Revision 2
**Changes**: Eliminated all code changes to picker/utilities; plan now focuses purely on metadata audit
**Reason**: Frontmatter metadata is user-maintained; system is working correctly, just needs verification
**Key Adjustments**:
- Phase 1: Kept as audit/verification phase - check all command metadata accuracy
- Phase 2: REMOVED - no code changes to picker needed
- Phase 3: REMOVED - no validation system needed (user maintains metadata)
- Phase 4: REMOVED - no implementation to document
- Plan simplified to single audit/report phase
**Impact**: Plan is now a metadata verification exercise, not an implementation project

### 2025-10-08 - Revision 3
**Changes**: Added keyboard shortcuts help text verification and update to Phase 1
**Reason**: User wants to verify all available shortcuts and update help text shown in picker preview
**Key Adjustments**:
- Phase 1: Added tasks to identify all keyboard shortcuts and verify help text accuracy
- Phase 1: Added task to update keyboard shortcuts help text in picker.lua
- Phase 2: Added keyboard shortcuts help review and update to manual corrections phase
- Success Criteria: Added keyboard shortcuts verification criteria
**Impact**: Plan now includes both metadata audit AND keyboard shortcuts help accuracy

## Overview

The `<leader>ac` picker's dependency loading system is working correctly. Commands maintain their dependency metadata in frontmatter (`dependent-commands:` field), and this is the user's responsibility to keep accurate.

The purpose of this plan is to **audit and verify** that the existing metadata and help information is accurate and complete. This includes both command dependency metadata and the keyboard shortcuts help text displayed in the picker.

This plan focuses on:
- Auditing all primary commands to check `dependent-commands` metadata accuracy
- Verifying that commands like /document and /setup have correct dependency lists
- Identifying any discrepancies between declared dependencies and actual command invocations
- **Verifying all keyboard shortcuts available in the picker**
- **Updating the [Keyboard Shortcuts] help text to be accurate and complete**
- Providing a report for user review and manual correction if needed
- Documenting agent and hook relationships for reference

## Success Criteria
- [ ] All primary commands in .claude/commands/ have been audited
- [ ] Audit report clearly identifies accurate vs inaccurate metadata
- [ ] Commands like /document, /setup, /orchestrate are explicitly verified
- [ ] Discrepancies (missing or extra dependencies) are documented
- [ ] Agent relationships are documented for reference
- [ ] Hook relationships are documented for reference
- [ ] All keyboard shortcuts in picker identified and verified
- [ ] Keyboard shortcuts help text updated to be accurate and complete
- [ ] User has actionable report for manual metadata corrections

## Technical Design

### Current State Analysis

**Files Involved:**
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` - Main picker implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Dependency parsing and hierarchy building

**Key Functions:**
- `load_command_locally(command, silent)` (picker.lua:1268-1381) - Loads command and dependencies recursively
- `build_hierarchy(commands)` (parser.lua:158-217) - Creates parent/dependent relationship tree
- `build_agent_dependencies(commands, agents)` (parser.lua:483-527) - Dynamic agent scanning
- Ctrl-l handler (picker.lua:2694-2735) - Triggers loading based on selection type

**Current Behavior:**
1. Parent commands: Load themselves + all `dependent_commands` recursively (lines 1343-1378)
2. Dependent commands: Load only themselves (lines 1268-1342)
3. Agent detection: Dynamic scanning for `subagent_type:` patterns (parser.lua:483-527)
4. Hook loading: Event-based, not command-invoked (picker.lua:2706-2710)

**The Audit Need:**
1. Verify that `dependent-commands` metadata in frontmatter matches actual command invocations
2. Document agent relationships (which commands invoke which agents)
3. Document hook relationships (which hooks exist and their triggers)
4. Provide user with verification report for manual review

### Audit Approach

```
┌──────────────────────────────────────────────────────────────┐
│              Metadata Verification Audit                     │
│   Read-only analysis of command metadata accuracy           │
│                                                              │
│   Step 1: Scan all command files in .claude/commands/       │
│   Step 2: For each command:                                  │
│     - Extract frontmatter dependent-commands field           │
│     - Scan content for /command invocations                  │
│     - Compare declared vs actual invocations                 │
│   Step 3: Generate comprehensive audit report                │
│   Step 4: Document agent and hook relationships              │
│                                                              │
│   Output: Audit report for user review                      │
│   No code changes to picker or utilities                    │
└──────────────────────────────────────────────────────────────┘
```

**Key Design Decisions:**

1. **Read-only audit**: No modifications to any code files
2. **User responsibility**: Metadata maintenance is user's job, we just verify
3. **Comprehensive scan**: Check all primary commands systematically
4. **Actionable report**: Clear findings for user to act on
5. **Reference documentation**: Document agent/hook relationships for clarity

### Audit Flow

```
Audit Execution:
  Read command files → Extract frontmatter metadata
  → Scan content for /command invocations → Compare declared vs actual
  → Generate audit report → User reviews and corrects metadata manually

Agent/Hook Documentation:
  Scan commands for agent references → Document relationships
  → List hooks and their triggers → Create reference documentation
```

## Audit Phases

### Phase 1: Command Dependency Audit and Keyboard Shortcuts Update
**Objective**: Verify dependency metadata accuracy and update picker help information
**Complexity**: Low-Medium

Tasks:

**Command Dependency Audit:**
- [ ] Identify all primary commands in .claude/commands/
  - Use: Grep or Glob to find command files
  - Exclude: Backup files, templates, non-command files
  - Focus: Primary commands (not dependent-type commands)
- [ ] For each command, extract and compare:
  - Frontmatter: Read `dependent-commands:` field
  - Content: Scan for `/command-name` invocations using pattern matching
  - Exclude: Invocations in comments (#), code blocks (```), quoted strings
  - Compare: Declared dependencies vs actual invocations found
- [ ] Generate comprehensive audit report
  - Location: specs/reports/036_command_dependency_audit.md
  - Format: Table with columns: Command | Declared Deps | Actual Invocations | Status | Notes
  - Status values: ✓ Accurate | ⚠ Missing Deps | ⚠ Extra Deps | ⚠ Both
  - Special focus: /document, /setup, /orchestrate, /implement
- [ ] Document agent relationships
  - Scan: Each command for agent protocol references (.claude/agents/*.md)
  - List: Which commands use which agents
  - Format: Table showing command → agents mapping
- [ ] Document hook relationships
  - List: All hooks in .claude/hooks/
  - Document: Event triggers for each hook
  - Clarify: Hooks are event-based, not command-invoked

**Keyboard Shortcuts Help Update:**
- [ ] Identify all keyboard shortcuts in picker
  - Location: picker.lua mappings section (lines ~2600-2800)
  - Read: All i (insert mode) and n (normal mode) mappings
  - Extract: Key binding → action mapping for each
  - Focus: Picker-specific shortcuts (Ctrl-l, Ctrl-e, Ctrl-u, Ctrl-s, Ctrl-n, etc.)
- [ ] Verify current help text accuracy
  - Location: picker.lua help text generation (lines ~848-894)
  - Read: Current [Keyboard Shortcuts] help content
  - Compare: Declared shortcuts in help vs actual mappings in code
  - Identify: Missing shortcuts, incorrect descriptions, outdated info
- [ ] Update keyboard shortcuts help text
  - Location: picker.lua, function that generates help entries
  - Update: Help text to accurately reflect all available shortcuts
  - Format: Consistent with existing help style
  - Include: All functional shortcuts with accurate descriptions
  - Remove: Any documented shortcuts that no longer exist
  - Group: Related shortcuts together (Navigation, Selection, File Operations, etc.)

Validation:
- [ ] All primary commands scanned successfully
- [ ] Report clearly identifies accurate vs inaccurate metadata
- [ ] False positives minimized (comments/examples excluded)
- [ ] Agent and hook relationships documented
- [ ] Report is actionable for user to make corrections
- [ ] All keyboard shortcuts identified and documented
- [ ] Help text matches actual picker functionality
- [ ] No missing or outdated shortcuts in help

### Phase 2: User Review and Manual Corrections
**Objective**: User reviews audit findings and manually corrects inaccurate metadata and help text
**Complexity**: Low (User-driven)

Tasks:

**Metadata Corrections:**
- [ ] Review audit report findings
  - Examine: Each command flagged with discrepancies
  - Verify: Whether findings are accurate (not false positives)
  - Decide: Which metadata corrections are needed
- [ ] Update command frontmatter manually
  - Location: .claude/commands/*.md files
  - Field: `dependent-commands:` in YAML frontmatter
  - Update: Add missing dependencies or remove incorrect ones
  - Examples:
    - If /document invokes /list but doesn't declare it: add "list" to dependent-commands
    - If /setup declares dependencies but doesn't invoke any: remove dependent-commands field

**Keyboard Shortcuts Help Corrections:**
- [ ] Review keyboard shortcuts findings
  - Examine: Differences between help text and actual mappings
  - Verify: Which shortcuts are missing or incorrectly described
  - Decide: What updates are needed to help text
- [ ] Update keyboard shortcuts help text
  - Location: picker.lua, help text generation section
  - Update: Help content to match actual functionality
  - Add: Any missing shortcuts
  - Remove: Any obsolete shortcuts
  - Clarify: Descriptions for accuracy

**Verification:**
- [ ] Re-scan commands to verify metadata corrections
  - Check: Audit report status changes to ✓ Accurate
- [ ] Test keyboard shortcuts help in picker
  - Open: <leader>ac picker
  - Navigate: To [Keyboard Shortcuts] entry
  - Verify: Help text is accurate and complete
- [ ] Commit changes (if any)
  - Git add: Modified command files and picker.lua
  - Git commit: "fix: Update command metadata and keyboard shortcuts help based on audit"
  - Message: Reference audit report number

Notes:
- This phase is entirely user-driven, no automated corrections
- User decides what's accurate based on their understanding of command behavior
- Some invocations may be conditional or examples, user judgment required

### Phase 3: Final Verification and Summary
**Objective**: Verify all metadata and help text is now accurate and document findings
**Complexity**: Low

Tasks:
- [ ] Re-run audit after corrections
  - Scan: All commands again with same audit process
  - Verify: All commands now show ✓ Accurate status
  - Document: Any remaining discrepancies with rationale
- [ ] Verify keyboard shortcuts help in picker
  - Open: <leader>ac picker in Neovim
  - Navigate: To [Keyboard Shortcuts] entry
  - Verify: All shortcuts documented accurately
  - Test: A few key shortcuts to confirm they work as described
- [ ] Create summary document
  - Location: specs/summaries/036_command_dependency_audit_summary.md
  - Content:
    - Total commands audited
    - Commands that were accurate from start
    - Commands that needed corrections
    - List of corrections made
    - Keyboard shortcuts verified and updated
    - Agent and hook relationship documentation
  - Format: Clear, concise summary for future reference
- [ ] Code changes verification
  - Confirm: Keyboard shortcuts help text updated in picker.lua (intentional)
  - Confirm: No modifications to parser.lua
  - Confirm: Only command frontmatter updated (user-maintained)
  - Note: Help text update is the only code change (documentation fix)

## Audit Strategy

### Audit Execution Approach

**Phase 1: Automated Scanning**
- [ ] Use Grep/Read tools to scan all .claude/commands/*.md files
- [ ] Extract frontmatter `dependent-commands:` field from each
- [ ] Search content for `/command-name` patterns
- [ ] Exclude: Comments, code blocks, quoted strings
- [ ] Compare declared vs actual for each command

**Phase 2: Manual Review**
- [ ] Review audit report findings
- [ ] Verify each flagged discrepancy
- [ ] Distinguish true issues from false positives
- [ ] Update command frontmatter as needed
- [ ] Commit corrections with clear message

**Phase 3: Verification**
- [ ] Re-run audit on corrected commands
- [ ] Confirm all metadata now accurate
- [ ] Document findings in summary
- [ ] Archive audit report for reference

### False Positive Handling
Common patterns to exclude from scan:
- Comments: `# /command-name`
- Code blocks: ` ```bash\n/command\n``` `
- Quoted examples: `"/command-name"`
- Documentation references: "See /command for..."

User judgment required for:
- Conditional invocations (may or may not execute)
- Example invocations (in help text, not actual calls)
- Deprecated invocations (old patterns being phased out)

## Documentation Requirements

### Audit Report
- [ ] Generate comprehensive audit report
  - Location: specs/reports/036_command_dependency_audit.md
  - Format: Markdown tables with clear status indicators
  - Sections: Commands, Agents, Hooks
  - Actionable: User knows exactly what to fix

### Summary Documentation
- [ ] Create audit summary
  - Location: specs/summaries/036_command_dependency_audit_summary.md
  - Content: Findings, corrections made, final status
  - Metrics: Commands audited, accuracy rate, corrections needed
  - References: Link to audit report

### Reference Documentation (Optional)
- [ ] Agent relationship reference
  - Which commands use which agents
  - Helps understand system architecture
- [ ] Hook trigger reference
  - List all hooks and their event triggers
  - Clarifies hook vs command dependency distinction

## Dependencies

### Tools Required
- Read tool - To read command files and extract metadata
- Grep tool - To search for command invocations
- Glob tool - To find all command files

### No Code Dependencies
This is a read-only audit - no dependencies on existing code, no modifications needed

## Risk Assessment

### Low Risk - Audit Only

**False Positives**:
- Risk: Scan might flag invocations that are examples/comments
- Mitigation: Exclude comments, code blocks, strings from scan
- Impact: Low - user reviews findings and makes judgment call

**Manual Correction Errors**:
- Risk: User might incorrectly update metadata
- Mitigation: Provide clear audit report with evidence
- Impact: Low - user can re-run audit to verify corrections

**No Technical Risk**:
- No code changes = no risk of breaking existing functionality
- No performance impact
- No compatibility concerns
- Worst case: User doesn't update metadata (system continues working)

## Notes

### Design Rationale
- **Audit-only approach**: System is working, just verify metadata accuracy
- **User responsibility**: Metadata is user-maintained, we just provide verification
- **No code changes**: Preserves existing functionality completely
- **Manual corrections**: User judgment required for edge cases

### Future Enhancements (If Desired)
- Periodic automated audits (monthly/quarterly)
- Integration with /setup command to verify on setup
- Automated metadata correction (optional, user-approved)
- Dependency graph visualization

### Alternative Approaches Not Taken
1. **Automated metadata correction**: Rejected - user should control metadata
2. **Validation in picker**: Rejected - adds complexity, user maintains metadata
3. **Dynamic dependency detection**: Rejected - frontmatter is source of truth

### No Migration Needed
- No code changes = no migration
- Metadata corrections are straightforward frontmatter edits
- System continues working during and after audit
