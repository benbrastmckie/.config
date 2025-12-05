# Lean Command Naming Standardization - Reference Analysis

## Research Metadata
- **Date**: 2025-12-03
- **Research Type**: Codebase Analysis
- **Complexity**: 3
- **Scope**: Find all references to `/lean_plan` and `/lean:build` commands

## Executive Summary

This report documents ALL references to the Lean commands that need to be renamed for naming standardization:
- `/lean_plan` (underscore) → `/lean-plan` (hyphen)
- `/lean:build` (colon) → `/lean-build` (hyphen)

**Total Files Affected**: 18 files
- **Command Files**: 2 files (lean_plan.md, lean:build.md)
- **Agent Files**: 1 file (lean-plan-architect.md)
- **Documentation Files**: 2 files (command-reference.md, lean-plan-command-guide.md)
- **Spec Files**: 13 files (plans, reports, summaries, outputs)

## 1. Command Files

### 1.1 /lean_plan Command File

**File**: `/home/benjamin/.config/.claude/commands/lean_plan.md`

**Action Required**: Rename to `/home/benjamin/.config/.claude/commands/lean-plan.md`

**Internal References**:
- Line 41: `TEMP_FILE="${HOME}/.claude/tmp/lean_plan_arg_$(date +%s%N).txt"`
- Line 44: `echo "$TEMP_FILE" > "${HOME}/.claude/tmp/lean_plan_arg_path.txt"`
- Line 213: `setup_bash_error_trap "/lean:plan" "lean_plan_early_$(date +%s)" "early_init"`
- Line 222: `WORKFLOW_ID="lean_plan_$(date +%s)"`
- Line 224: `STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"`
- Line 357: `STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"`
- Line 517: `STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"`
- Line 621: `STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"`
- Line 899: `STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"`
- Line 908: `WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "lean_plan")`
- Line 914: `USER_ARGS="${FEATURE_DESCRIPTION:-lean_plan_workflow}"`
- Line 1306: `STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"`
- Line 1315: `WORKFLOW_ID=$(validate_workflow_id "$WORKFLOW_ID" "lean_plan")`
- Line 1321: `USER_ARGS="${FEATURE_DESCRIPTION:-lean_plan_workflow}"`

**Frontmatter References**:
- Line 9: `agents: lean-plan-architect`
- Line 13: `documentation: See .claude/docs/guides/commands/lean-plan-command-guide.md`

### 1.2 /lean:build Command File

**File**: `/home/benjamin/.config/.claude/commands/lean:build.md`

**Action Required**: Rename to `/home/benjamin/.config/.claude/commands/lean-build.md`

**Internal References**:
- Line 19: `# /lean:build - Lean Theorem Proving Command` (title)

## 2. Agent Files

### 2.1 lean-plan-architect Agent

**File**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`

**References**:
- Line 220: `bash .claude/lib/util/dependency-analyzer.sh "$PLAN_PATH" > /tmp/lean_plan_deps.json`
- Line 221: `CYCLE_CHECK=$(jq -r '.errors[] | select(.type == "circular_dependency")' /tmp/lean_plan_deps.json`

**Note**: These are internal variable names, not command invocations. May need to update for consistency.

## 3. Documentation Files

### 3.1 Command Reference

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`

**References**:
- Lines 482-511: Complete `/lean:plan` command documentation entry

**Example**:
```markdown
### /lean:plan
**Purpose**: Create Lean-specific implementation plan for theorem proving projects with Mathlib research and proof strategies

**Usage**: `/lean:plan "<description>" [--file <path>] [--complexity 1-4] [--project <path>]`
```

**Action Required**: Change all `/lean:plan` to `/lean-plan`

### 3.2 Lean Plan Command Guide

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md`

**References**: Multiple references throughout the guide
- Line 306: `**Cause**: lean-plan-architect didn't include **Lean File** field in metadata`
- Line 388: Reference to lean-plan-architect usage
- Line 448: Link to infrastructure research in specs/032

**Action Required**: Update all command syntax examples and agent references

## 4. Specification Files

### 4.1 Spec 032: lean_plan Command Implementation

**Directory**: `/home/benjamin/.config/.claude/specs/032_lean_plan_command/`

**Files Affected**:

#### 4.1.1 Reports

**File**: `reports/001-lean-infrastructure-research.md`
- Line 330: Topic naming example `032_lean_plan_command`
- Line 677: `└─ Invoke lean-plan-architect agent via Task tool`
- Line 708: `bash "$CLAUDE_PROJECT_DIR/.claude/lib/util/dependency-analyzer.sh" "$PLAN_PATH" > /tmp/lean_plan_deps.json`
- Line 758: `**lean-plan-architect Agent** (Modified from plan-architect):`
- Line 846: `- File: `.claude/commands/lean_plan.md``
- Line 865: `2. Modify `plan-architect` for Lean support (or create `lean-plan-architect`)`
- Line 879: `- File: `.claude/docs/guides/commands/lean-plan-command-guide.md``
- Line 899: `PLAN_AGENT="lean-plan-architect"`
- Line 923: `2. **Agent Reuse**: Create `lean-research-specialist` (new) and `lean-plan-architect` (modified from plan-architect)`

**File**: `reports/002-lean-planning-best-practices.md`
- Line 812: Reference to research report 001

#### 4.1.2 Plans

**File**: `plans/001-lean-plan-command-plan.md`
- Line 15: Link to lean planning best practices
- Line 23: Description of lean-plan-architect
- Line 113: Workflow diagram showing lean-plan-architect
- Line 140: Agent hierarchy showing lean-plan-architect
- Line 254: Dependency analysis example
- Line 279: `- [x] Create `.claude/commands/lean_plan.md` file`
- Line 298: `- New: `.claude/commands/lean_plan.md``
- Line 381: `### Phase 3: Agent Creation - lean-plan-architect [COMPLETE]`
- Line 389: `- [x] Create `.claude/agents/lean-plan-architect.md` file`
- Line 431: `- New: `.claude/agents/lean-plan-architect.md``
- Line 460: `- [x] Implement Block 1b: Topic Name Pre-Calculation (in `.claude/commands/lean_plan.md`)`
- Line 488: `- [x] Invoke lean-plan-architect via Task tool with all context`
- Line 499: `- Modified: `.claude/commands/lean_plan.md``
- Line 534: `- [x] Create command guide file: `.claude/docs/guides/commands/lean-plan-command-guide.md``
- Line 568: `- New: `.claude/docs/guides/commands/lean-plan-command-guide.md``
- Line 593: `- Phase 3: lean-plan-architect theorem specification validation`
- Line 645: `### Command Guide (.claude/docs/guides/commands/lean-plan-command-guide.md)`
- Line 682: Link to lean-plan-command-guide.md
- Line 696: `- Existing `plan-architect` agent (template for lean-plan-architect)`
- Line 727: Risk mitigation for lean-plan-architect failures

#### 4.1.3 Summaries

**File**: `summaries/001-lean-plan-implementation-summary.md`
- Line 20: `- Created `.claude/commands/lean_plan.md` with Lean-specific argument parsing`
- Line 34: `**Phase 3: lean-plan-architect Agent** ✓ COMPLETE`
- Line 35: `- Created `.claude/agents/lean-plan-architect.md``
- Line 45: `- Integrated lean-plan-architect delegation (Block 2)`
- Line 51: `- Created `.claude/docs/guides/commands/lean-plan-command-guide.md``
- Line 62: Link to lean_plan.md
- Line 66: Link to lean-plan-architect.md
- Line 69: Link to lean-plan-command-guide.md
- Line 99: Agent features for lean-plan-architect
- Line 163: Phase 3 reference to lean-plan-architect
- Line 277: Link to lean-plan-command-guide.md
- Line 279: Link to lean planning best practices
- Line 340: `- 1 new command file (lean_plan.md)`
- Line 341: `- 2 new agents (lean-research-specialist, lean-plan-architect)`
- Line 342: `- 1 new guide (lean-plan-command-guide.md)`

#### 4.1.4 Outputs

**File**: `outputs/test_results_iter1_1764822026.md`
- Line 15: `✓ PASS: Command file exists at .claude/commands/lean_plan.md`
- Line 17: `✓ PASS: Planning agent exists at .claude/agents/lean-plan-architect.md`
- Line 18: `✓ PASS: Documentation exists at .claude/docs/guides/commands/lean-plan-command-guide.md`
- Line 25: `✓ PASS: Command invokes lean-plan-architect agent`
- Line 71: Reference to lean_plan.md
- Line 82: Reference to lean-plan-architect.md
- Line 87: Reference to lean-plan-command-guide.md

### 4.2 Spec 033: lean:build Command Implementation

**Directory**: `/home/benjamin/.config/.claude/specs/033_lean_command_build_improve/`

**Files Affected**:

#### 4.2.1 Reports

**File**: `reports/001-lean-command-analysis-and-improvements.md`
- Line 5: Description of `/lean` command rename to `/lean:build`
- Line 21: Question 4 about naming convention for `/lean:build`
- Line 73: Plan path example
- Line 303: `## 4. Command Naming: /lean:build vs Alternatives`
- Line 329: Table showing `/lean:build` with colon namespace
- Line 330: Table entry showing `/lean-build` with hyphen (comparison)
- Line 334: `### Recommendation: `/lean:build` with Extensibility`
- Line 336: `**Primary Command**: `/lean:build` - Build proofs for all sorry markers`
- Line 348: Backward compatibility mention of `/lean` → `/lean:build` alias
- Line 403: Re-run example `/lean:build [plan]`
- Line 483: Command reference `/lean:build [file | plan]`
- Line 484: Alias reference `/lean` → `/lean:build`
- Line 537: Rename instruction `/lean.md` to `/lean:build.md`
- Line 576: Documentation of `/lean:build` vs `/lean` alias
- Line 632: `/lean:build` invocation example
- Line 718: `/lean:build` - Build proofs
- Line 755: **MEDIUM-TERM**: Rename to `/lean:build` with `/lean` alias

**File**: `reports/002-lean-command-revision-research.md`
- Line 326: `- Primary command: `/lean:build.md``
- Line 333-349: Multiple references to `/lean:build` command
- Line 366-512: Extensive discussion of renaming to `/lean:build`

#### 4.2.2 Plans

**File**: `plans/001-lean-command-build-improve-plan.md`
- Line 6: Feature description mentioning rename to `/lean:build`
- Line 22: Solution approach mentioning `/lean:build` rename
- Line 330: Consistent two-agent architecture for `/lean:build`
- Line 333: `/lean:build command` diagram
- Line 354: File-based mode example `/lean:build ProofChecker/Truth.lean`
- Line 695: 2-tier discovery mechanism for `/lean:build`
- Line 827: Test discovery with `/lean:build [plan]`
- Line 835: `## Phase 3: Command Rename to /lean:build (Clean Break) [COMPLETE]`
- Lines 837-1095: Extensive documentation of rename to `/lean:build`
- Line 1162: `### /lean:build` usage documentation
- Line 1164: Syntax specification
- Lines 1190-1196: Command examples using `/lean:build`
- Line 1222: Verification of `/lean:build` syntax
- Line 1242: Command examples validation
- Line 1294: Documentation of alias
- Line 1328: Alias resolution test

**File**: `plans/backups/001-lean-command-build-improve-plan_20251203_181845.md`
- Same references as above (backup copy)

#### 4.2.3 Summaries

**File**: `summaries/001-lean-command-build-improve-summary.md`
- Line 17: Phase 3 title mentioning `/lean:build`
- Line 58: `lean:build.md` reference
- Line 66: File path to lean:build.md
- Line 82: lean:build.md simplification
- Line 100: File path reference
- Line 111: `### Phase 3: Command Rename to /lean:build (Clean Break)`
- Line 113: Objective for rename to `/lean:build`
- Line 118: Renamed file reference
- Line 130-136: Multiple command name updates
- Line 176: Command file renamed to lean:build.md
- Line 179: All command references updated to /lean:build
- Line 184: File path to lean:build.md
- Line 207-225: Test plan references
- Line 304: Monitor error logs for `/lean:build`
- Line 347-350: File modifications summary

#### 4.2.4 Outputs

**File**: `outputs/test_results_iter1_1764822687.md`
- Contains test results referencing lean:build.md

### 4.3 Other Spec References

**File**: `/home/benjamin/.config/.claude/specs/028_lean_subagent_orchestration/summaries/001-phase1-implementation-summary.md`
- Line 67: `Created test plan template at `/tmp/test_lean_plan.md``
- Line 241: Reference to test plan template

**File**: `/home/benjamin/.config/.claude/specs/030_lean_metadata_phase_header_update/reports/001_research_report.md`
- Line 317: Plan path example

**File**: `/home/benjamin/.config/.claude/specs/026_lean_command_orchestrator_implementation/reports/001-lean-command-orchestrator-design.md`
- Line 310: `/implement [lean-plan.md]` reference
- Line 466: `create_lean_plan_from_file` function

## 5. Agent References to Commands

### 5.1 lean-coordinator Agent

**File**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**References**:
- Line 41: `plan_path: /path/to/specs/028_lean/plans/001-lean-plan.md`
- Line 338: Same plan path example
- Line 368: Same plan path example
- Line 398: Same plan path example
- Line 565: `- Plan: /path/to/specs/028_lean/plans/001-lean-plan.md (markers updated)`

**Note**: These are example paths, not command invocations. Context uses "lean-plan" with hyphen already.

### 5.2 lean-research-specialist Agent

**File**: `/home/benjamin/.config/.claude/agents/lean-research-specialist.md`

**References**:
- Line 403: `The lean-plan-architect agent will consume this report to create theorem-level implementation plans.`

### 5.3 lean-implementer Agent

**File**: `/home/benjamin/.config/.claude/agents/lean-implementer.md`

**References**:
- Line 497: `build_output=$(uvx --from lean-lsp-mcp lean-build "$LEAN_FILE" 2>&1)`

**Note**: This is the MCP tool `lean-build`, NOT the slash command `/lean-build`

## 6. Output Files

### 6.1 plan-output.md

**File**: `/home/benjamin/.config/.claude/output/plan-output.md`

**References**:
- Line 7: `the /lean command to /lean:build. Research all of these changes and the existing infrastructure`
- Line 124: `3. Command Rename to /lean:build - With backward-compatible /lean alias`
- Line 251: `- Renamed to /lean:build with NO backward-compatible alias`
- Line 252: `- All documentation references /lean:build only`

## 7. Summary of Changes Required

### 7.1 File Renames (2 files)

1. `/home/benjamin/.config/.claude/commands/lean_plan.md` → `/home/benjamin/.config/.claude/commands/lean-plan.md`
2. `/home/benjamin/.config/.claude/commands/lean:build.md` → `/home/benjamin/.config/.claude/commands/lean-build.md`

### 7.2 Internal Variable Updates (lean_plan.md → lean-plan.md)

All internal variables using `lean_plan` prefix should be changed to `lean-plan`:
- `TEMP_FILE` paths: `/tmp/lean_plan_arg_*` → `/tmp/lean-plan_arg_*`
- `STATE_ID_FILE` paths: `/tmp/lean_plan_state_id.txt` → `/tmp/lean-plan_state_id.txt`
- `WORKFLOW_ID` values: `lean_plan_*` → `lean-plan_*`
- Error trap names: `lean_plan_early_*` → `lean-plan_early_*`
- Fallback args: `lean_plan_workflow` → `lean-plan_workflow`

### 7.3 Command Title Updates

1. `lean-plan.md`: Title should reference `/lean-plan` not `/lean:plan`
2. `lean-build.md`: Title should reference `/lean-build` not `/lean:build`

### 7.4 Documentation Updates (2 files)

1. `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
   - Change `/lean:plan` to `/lean-plan` throughout entry (lines 482-511)

2. `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md`
   - Update all command syntax examples
   - Update all command invocation examples
   - File should potentially be renamed to `lean-plan-command-guide.md` (already correct)

### 7.5 Specification Files (13 files)

All spec files referencing the old command names should be updated for historical accuracy:
- Reports: 3 files (001-lean-infrastructure-research.md, 002-lean-planning-best-practices.md, 002-lean-command-revision-research.md)
- Plans: 2 files (001-lean-plan-command-plan.md, 001-lean-command-build-improve-plan.md)
- Summaries: 2 files (001-lean-plan-implementation-summary.md, 001-lean-command-build-improve-summary.md)
- Outputs: 2 files (test_results from both specs)
- Output: 1 file (plan-output.md)
- Other specs: 3 files (various references)

**Note**: Spec files document historical implementation decisions. They may be left as-is or updated to reflect the standardization. Recommend updating for consistency.

### 7.6 Agent Internal References (1 file)

`/home/benjamin/.config/.claude/agents/lean-plan-architect.md`
- Line 220-221: Update `/tmp/lean_plan_deps.json` to `/tmp/lean-plan_deps.json` (for consistency)

**Note**: Agent name `lean-plan-architect` is already correct with hyphen.

## 8. Files NOT Requiring Changes

### 8.1 Agent Names (Already Use Hyphens)
- `lean-coordinator.md` ✓
- `lean-implementer.md` ✓
- `lean-plan-architect.md` ✓
- `lean-research-specialist.md` ✓

### 8.2 MCP Tool References
- `lean-build` in lean-implementer.md is the MCP tool, not the slash command

### 8.3 CLAUDE.md
- No references to `/lean_plan` or `/lean:build` found
- SlashCommand listings are auto-generated

## 9. Recommended Implementation Order

1. **Rename Command Files** (2 files)
   - Rename `lean_plan.md` → `lean-plan.md`
   - Rename `lean:build.md` → `lean-build.md`

2. **Update Command File Internals** (2 files)
   - Update all internal variables in `lean-plan.md`
   - Update title in `lean-build.md`

3. **Update Core Documentation** (2 files)
   - Update `command-reference.md`
   - Update `lean-plan-command-guide.md`

4. **Update Agent References** (1 file)
   - Update temp file paths in `lean-plan-architect.md`

5. **Update Specification Files** (13 files - optional)
   - Update for historical accuracy and consistency
   - Can be done in bulk using search/replace

## 10. Risk Assessment

### 10.1 Breaking Changes
- **User Impact**: Users invoking `/lean_plan` or `/lean:build` will get command not found
- **State Files**: Existing workflow state files using old paths may be orphaned
- **Error Logs**: Error logs may reference old command names

### 10.2 Mitigation Strategies
1. **Alias Support**: Consider temporary alias support during transition
2. **State Migration**: Provide script to migrate existing state files
3. **Documentation**: Clear migration guide for users
4. **Deprecation Notice**: Add deprecation warning before removal

### 10.3 Testing Requirements
1. Verify command discovery after rename
2. Test workflow state initialization with new names
3. Verify error logging uses new command names
4. Test agent delegation still works
5. Verify documentation links remain valid

## 11. Search Patterns Used

```bash
# Pattern 1: Direct command name search
grep -r "lean_plan" .claude/ --include="*.md"
grep -r "lean:build" .claude/ --include="*.md"

# Pattern 2: Hyphenated variants (for completeness)
grep -r "lean-plan" .claude/ --include="*.md"
grep -r "lean-build" .claude/ --include="*.md"

# Pattern 3: File discovery
find .claude -name "*.md" -type f -exec grep -l "/lean_plan\|/lean:build" {} \;
```

## 12. Conclusion

This standardization requires updates to:
- **2 command files** (rename + internal updates)
- **2 documentation files** (command references)
- **1 agent file** (internal temp file paths)
- **13 specification files** (historical accuracy - optional)

Total effort: **~2 hours** for core changes, **+1 hour** for spec file updates if desired.

The standardization will improve consistency with Claude Code's naming conventions (hyphens for multi-word commands) and align with the existing agent naming pattern (all lean agents already use hyphens).

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/034_lean_command_naming_standardization/reports/001-lean-command-references.md
