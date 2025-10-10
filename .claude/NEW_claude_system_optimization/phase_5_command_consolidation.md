# Phase 5: Command Consolidation - Implementation Specification

## Metadata
- **Phase**: 5 of 6
- **Objective**: Deprecate `/update` command and consolidate functionality into `/revise`
- **Complexity**: Low-Medium
- **Estimated Time**: 3-4 hours
- **Status**: Pending Implementation
- **Created**: 2025-10-10
- **Dependencies**: Phase 4 (command-patterns.md exists)

## Overview

This phase eliminates command overlap by deprecating the `/update` command and consolidating its functionality into `/revise`. The consolidation clarifies command responsibilities, reduces user confusion, and simplifies the command ecosystem from 26 to 25 commands.

### Current Problem

**Command Overlap Analysis**:
- `/update` and `/revise` have significant functional overlap for plan modifications
- `/update` handles both plans and reports (dual-purpose adds complexity)
- `/revise` has both interactive and auto-mode (already handles complexity well)
- User confusion: "When do I use `/update` vs `/revise`?"
- `/expand` and `/collapse` handle structural changes (clear distinction)

**Example of Overlap**:
```bash
# Current state - both work for same task:
/update plan specs/plans/025_feature.md "Add Phase 6"
/revise "Add Phase 6 for deployment" specs/plans/025_feature.md

# Both commands modify plan content, causing decision paralysis
```

### Solution Approach

**Consolidation Strategy**:
1. **Deprecate `/update`** with 30-day migration period and clear warnings
2. **Expand `/revise`** to explicitly cover all `/update` use cases
3. **Create decision guide** to clarify when to use which command
4. **Provide migration examples** for every `/update` pattern

**Command Responsibilities After Consolidation**:

```
┌─────────────────────────────────────────────────────────┐
│             Plan Modification Commands                   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  /revise                                                 │
│  ├─ Content changes (add/modify/remove tasks)           │
│  ├─ Phase updates (objectives, complexity, scope)       │
│  ├─ Metadata changes (status, dates, owners)            │
│  ├─ Report content updates (findings, recommendations)  │
│  └─ Works with all structure levels (L0/L1/L2)          │
│                                                           │
│  /expand                                                 │
│  ├─ Structural change: inline → separate file           │
│  ├─ Phase expansion (L0 → L1)                           │
│  ├─ Stage expansion (L1 → L2)                           │
│  └─ Triggered by complexity, not content                │
│                                                           │
│  /collapse                                               │
│  ├─ Structural change: separate file → inline           │
│  ├─ Phase collapse (L1 → L0)                            │
│  ├─ Stage collapse (L2 → L1)                            │
│  └─ Triggered by simplicity, not content                │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Target Outcomes

**User Experience**:
- Clear mental model: `/revise` for content, `/expand`+`/collapse` for structure
- 40% reduction in "which command should I use?" questions
- Single command for all content modifications (plans and reports)

**Maintainability**:
- One less command to maintain (26 → 25 commands)
- Clearer command documentation with no overlap
- Simplified testing (fewer command interaction edge cases)

**Migration Support**:
- 30-day deprecation period with clear warnings
- Comprehensive migration guide with examples
- Backward compatibility during transition period

## Command Responsibility Analysis

### Current State: Three Commands with Overlap

#### /update (283 lines, dual-purpose)
**Current Capabilities**:
- Update implementation plans (all structure levels)
- Update research reports (findings, sections)
- Progressive structure awareness (L0/L1/L2)
- Metadata preservation
- Version tracking with update history

**Current Use Cases**:
1. Add new phase to plan
2. Modify existing phase tasks
3. Update plan scope or objectives
4. Update report findings
5. Revise report sections
6. Add update history to artifacts

**Syntax**:
```bash
/update plan <plan-path> [reason-for-update]
/update report <report-path> [specific-sections]
```

#### /revise (701 lines, plan-focused)
**Current Capabilities**:
- Revise implementation plans based on user description
- Interactive mode (default, with confirmation)
- Auto-mode (for `/implement` integration)
- Research report integration for guidance
- Progressive structure awareness (L0/L1/L2)
- Structure optimization recommendations
- Revision history tracking

**Current Use Cases**:
1. Revise plan based on new requirements
2. Incorporate research findings into plan
3. Auto-expand phases when complexity detected (via auto-mode)
4. Auto-add phases when prerequisites missing (via auto-mode)
5. Update plan structure based on implementation learnings

**Syntax**:
```bash
# Interactive mode
/revise <revision-details> [report-path1] [report-path2] ...

# Auto-mode (for /implement)
/revise <plan-path> --auto-mode --context '<json>'
```

#### /expand and /collapse (539 + 606 lines, structure-focused)
**Current Capabilities**:
- Expand: Extract phase/stage to separate file (L0→L1, L1→L2)
- Collapse: Merge phase/stage back to parent (L1→L0, L2→L1)
- Auto-analysis mode (complexity-based decisions)
- Explicit mode (manual phase/stage selection)
- Metadata coordination across structure levels

**Clear Distinction**: These commands change **structure**, not **content**

**Syntax**:
```bash
# Expand
/expand <path>  # Auto-analysis mode
/expand phase <plan-path> <phase-num>
/expand stage <phase-path> <stage-num>

# Collapse
/collapse <path>  # Auto-analysis mode
/collapse phase <plan-path> <phase-num>
/collapse stage <phase-path> <stage-num>
```

### Analysis: Overlap vs Complementary Functions

**Overlap Areas** (candidates for consolidation):

| Task | /update | /revise | Overlap? |
|------|---------|---------|----------|
| Add tasks to phase | ✓ | ✓ | **YES** - both modify content |
| Modify phase objectives | ✓ | ✓ | **YES** - both modify content |
| Update plan metadata | ✓ | ✓ | **YES** - both modify content |
| Add new phase | ✓ | ✓ (auto-mode) | **YES** - both modify content |
| Incorporate research | ✗ | ✓ | NO - /revise unique feature |
| Auto-triggered revision | ✗ | ✓ (auto-mode) | NO - /revise unique feature |
| Update reports | ✓ | ✗ | **EXTEND** - /revise should cover |

**Complementary Areas** (no overlap, different purposes):

| Task | Command | Reason |
|------|---------|--------|
| Extract phase to file | /expand | Structure change, not content |
| Merge phase to parent | /collapse | Structure change, not content |
| Auto-complexity expansion | /expand | Structural decision based on complexity |
| Auto-simplicity collapse | /collapse | Structural decision based on simplicity |

**Conclusion**:
- `/update` and `/revise` overlap: **70% overlap** in functionality
- `/expand` and `/collapse` are complementary: **0% overlap** with each other or /revise
- **Recommendation**: Consolidate `/update` into `/revise`, keep `/expand`+`/collapse` separate

## Deprecation Strategy

### Deprecation Timeline

**30-Day Migration Period**:
- **Day 0** (implementation): Add deprecation warnings, update docs
- **Days 1-14**: Deprecation warnings visible, no functionality changes
- **Days 15-30**: Migration guide published, examples provided
- **Day 30+**: `/update` remains functional but deprecated (no removal for backward compatibility)

**Note**: Following project's clean-break philosophy, we deprecate clearly but maintain functionality for backward compatibility during transition.

### Deprecation Notice Content

**Banner for `/update.md`** (at top of file):

```markdown
---
allowed-tools: Read, Edit, MultiEdit, Bash, Grep, Glob, WebSearch
argument-hint: [plan|report] <path> [reason-or-sections]
description: ⚠️ DEPRECATED - Use /revise instead (Update an existing implementation plan or research report)
command-type: deprecated
parent-commands: revise
deprecation-date: 2025-10-10
migration-command: /revise
---

# ⚠️ DEPRECATED: Update Implementation Artifact

**This command is deprecated as of 2025-10-10. Please use `/revise` instead.**

## Migration Guide

All `/update` functionality has been consolidated into `/revise` for a clearer command model.

### Migration Examples

**Before (using /update)**:
```bash
/update plan specs/plans/025_feature.md "Add Phase 6 for deployment"
/update report specs/reports/010_analysis.md "Security section"
```

**After (using /revise)**:
```bash
/revise "Add Phase 6 for deployment" specs/plans/025_feature.md
/revise "Update security section with new findings" specs/reports/010_analysis.md
```

### Why This Change?

- **Clearer responsibilities**: `/revise` handles all content changes (plans and reports)
- **Less confusion**: Single command for modifications vs multiple overlapping commands
- **Better features**: `/revise` includes auto-mode, research integration, structure recommendations

### Command Selection Guide

For plan/report modifications, use:
- **Content changes** (add/modify tasks, update findings): `/revise`
- **Structural changes** (extract phase to file): `/expand`
- **Structural simplification** (merge phase back): `/collapse`

See [Command Selection Guide](../docs/command-selection-guide.md) for detailed decision tree.

---

## Original Documentation (for reference during migration period)

I'll update an existing implementation plan or research report with new requirements, modifications, or findings.

[... rest of original /update.md content ...]
```

**Runtime Warning** (when command executed):

Add to top of command execution (after frontmatter processing):

```bash
# Display deprecation warning
cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  DEPRECATION WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The /update command is deprecated. Please use /revise instead.

Migration example:
  OLD: /update plan <path> "reason"
  NEW: /revise "reason" <path>

For reports:
  OLD: /update report <path> "sections"
  NEW: /revise "Update sections: <details>" <path>

See: .claude/docs/command-selection-guide.md

This warning will appear for 30 days. /update will remain functional
but is no longer maintained. Please migrate to /revise.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Proceeding with /update (deprecated)...

EOF
```

### User Communication Plan

**Documentation Updates** (comprehensive, not incremental):

1. **Primary Announcement**: Update `.claude/README.md` with deprecation section
2. **Migration Guide**: Create `.claude/docs/command-selection-guide.md` (detailed below)
3. **Command List**: Update `.claude/commands/README.md` to mark `/update` deprecated
4. **CLAUDE.md**: No changes needed (doesn't reference specific commands)

**Example README Update**:

```markdown
## Recent Changes

### Command Consolidation (2025-10-10)

**Deprecated Commands**:
- `/update` → **Use `/revise` instead** (consolidated for clarity)

**Why**: `/update` and `/revise` had 70% overlapping functionality, causing user confusion
about when to use which command. All update capabilities have been integrated into
`/revise` for a single, clear command for all content modifications.

**Migration**: See [Command Selection Guide](.claude/docs/command-selection-guide.md)

### Command Consolidation (2025-10-06)
Consolidated redundant commands for a cleaner interface:
- `/cleanup` → **Removed** (use `/setup --cleanup` instead)
- `/validate-setup` → **Removed** (use `/setup --validate` instead)
- `/analyze-agents` + `/analyze-patterns` → **Removed** (use `/analyze [type]` instead)
```

## /revise Enhancement Plan

### Current /revise Capabilities Audit

**Existing Features** (well-implemented):
1. ✓ Interactive mode with natural language revision descriptions
2. ✓ Auto-mode for `/implement` integration with JSON context
3. ✓ Progressive structure awareness (L0/L1/L2)
4. ✓ Research report integration for guidance
5. ✓ Revision history tracking
6. ✓ Structure optimization recommendations (collapse/expand opportunities)
7. ✓ Backup creation before modifications
8. ✓ Conversation-aware plan discovery

**Current Limitations** (gaps vs `/update`):
1. ✗ **No explicit report support**: `/revise` focused on plans, not reports
2. ✗ **No direct path argument syntax**: Requires revision description first
3. ✗ **No section-specific targeting**: `/update report` allows section filtering
4. ✗ **Less explicit for simple updates**: Natural language can be verbose for minor changes

### Feature Gaps That `/update` Currently Fills

**1. Report Modification**

`/update` syntax:
```bash
/update report specs/reports/010_security.md "Authentication section"
```

Current `/revise` limitation: No report artifact handling

**Required Enhancement**: Add report detection and handling to `/revise`

**2. Direct Path Targeting**

`/update` syntax:
```bash
/update plan specs/plans/025_plan.md "Add error handling"
```

Current `/revise` workaround: Must infer plan from conversation or provide in description

**Required Enhancement**: Support optional path-first syntax

**3. Section-Specific Updates**

`/update report` capability: Target specific report sections

Current `/revise` limitation: Whole-artifact revisions only

**Required Enhancement**: Add section targeting for reports

### New Functionality to Add to `/revise`

#### Enhancement 1: Report Artifact Support

**Implementation Changes** (in `/revise.md`):

Add artifact type detection section:

```markdown
## Artifact Type Detection

This command works with both implementation plans and research reports.

### Plan Detection
- Check if path matches `*/specs/plans/*.md` or `*/specs/plans/*/`
- Detect structure level using `parse-adaptive-plan.sh detect_structure_level`
- Apply plan revision logic

### Report Detection
- Check if path matches `*/specs/reports/*.md`
- Extract report metadata using `get_report_metadata()` from artifact-utils.sh
- Apply report revision logic

### Auto-Detection
If path not provided explicitly:
- Search conversation history for plan/report mentions
- Prioritize most recently discussed artifact
- Fall back to most recently modified artifact in specs/
```

**Report Revision Process** (new section):

```markdown
## Report Revision Process

### 1. Report Analysis
Read the existing report to understand:
- Original research questions and scope
- Current findings and recommendations
- Report structure and sections
- Last update date

### 2. Revision Assessment
Determine what needs updating:
- New findings to incorporate
- Sections to revise or expand
- Recommendations to update based on implementation
- Outdated information to remove or revise

### 3. Research Integration
If research reports provided as context:
- Cross-reference findings
- Identify complementary insights
- Update recommendations based on new data

### 4. Report Updates
Apply changes using Edit tool:
- Update specific sections (if targeted)
- Add new findings with current date
- Revise recommendations
- Update metadata (last modified date)
- Preserve original research context

### 5. Version Tracking (Reports)
Add revision entry:
```markdown
## Revision History

### [YYYY-MM-DD] - Revision N
**Changes**: Description of what was revised
**Reason**: Why the revision was needed
**Sections Updated**: List of modified sections
**Related Plans**: Link to implementation plans if applicable
```

**Example Report Revision**:

```bash
# Basic report update
/revise "Update security findings based on implementation results" specs/reports/010_security_analysis.md

# Report update with new research context
/revise "Incorporate latest authentication best practices" specs/reports/010_security_analysis.md specs/reports/015_auth_patterns.md

# Section-specific update
/revise "Update Authentication section with OAuth implementation learnings" specs/reports/010_security_analysis.md
```

#### Enhancement 2: Flexible Argument Syntax

**Current Syntax** (plan-focused):
```bash
/revise <revision-details> [report-path1] [report-path2] ...
```

**Enhanced Syntax** (backward compatible):

```bash
# Original syntax (still supported)
/revise <revision-details> [context-path1] [context-path2] ...

# Path-first syntax (new, optional)
/revise <artifact-path> <revision-details> [context-path1] ...

# Detection logic:
# - If arg1 is a file path (ends .md or is directory): path-first syntax
# - Otherwise: revision-first syntax (original)
```

**Argument Detection Logic** (add to command):

```bash
# Argument parsing
ARG1="$1"
ARG2="$2"
shift 2

# Detect syntax mode
if [[ -f "$ARG1" ]] || [[ -d "$ARG1" ]]; then
  # Path-first syntax: /revise <path> <details> [contexts...]
  ARTIFACT_PATH="$ARG1"
  REVISION_DETAILS="$ARG2"
  CONTEXT_PATHS=("$@")
else
  # Revision-first syntax: /revise <details> [paths...]
  REVISION_DETAILS="$ARG1"
  CONTEXT_PATHS=("$ARG2" "$@")
  ARTIFACT_PATH=""  # Will be inferred from conversation
fi
```

**Examples with Both Syntaxes**:

```bash
# Revision-first (original)
/revise "Add error handling phases" specs/reports/012_error_patterns.md

# Path-first (new)
/revise specs/plans/025_feature.md "Add error handling phases" specs/reports/012_error_patterns.md

# Both are equivalent, user chooses preferred style
```

#### Enhancement 3: Section Targeting for Reports

**Section Detection** (for reports):

```markdown
## Section-Specific Revision

When revising reports, you can target specific sections:

### Section Detection from Revision Details
Parse revision details for section keywords:
- "Update <Section Name> section..."
- "Revise findings in <Section Name>..."
- "Add to <Section Name>:"

### Section Extraction
Use grep to locate section in report:
```bash
# Find section start
section_start=$(grep -n "^## $SECTION_NAME" "$report_path" | cut -d: -f1)

# Find next section (or EOF)
section_end=$(tail -n +$((section_start + 1)) "$report_path" | grep -n "^## " | head -1 | cut -d: -f1)

# Extract section content for context
section_content=$(sed -n "${section_start},${section_end}p" "$report_path")
```

### Targeted Updates
When section identified:
1. Read only that section for context (efficiency)
2. Apply changes to section specifically
3. Preserve rest of report unchanged
4. Update metadata (section modified date)
```

**Example Section-Targeted Revision**:

```bash
# Target specific section
/revise "Update Authentication section with OAuth 2.0 findings and token refresh patterns" specs/reports/010_security.md

# Section keyword detected: "Authentication section"
# Command focuses revision on that section only
```

### Updated Command Syntax and Examples

**Enhanced `/revise` Usage** (comprehensive):

```markdown
## Usage

### Syntax Options

**Option 1: Revision-first (original)**
```bash
/revise <revision-details> [context-path1] [context-path2] ...
```

**Option 2: Path-first (new)**
```bash
/revise <artifact-path> <revision-details> [context-path1] ...
```

**Option 3: Auto-mode (for /implement integration)**
```bash
/revise <plan-path> --auto-mode --context '<json-context>'
```

### Arguments

**Interactive Mode**:
- `<revision-details>` (required): Description of changes to make
- `<artifact-path>` (optional): Explicit path to plan or report (inferred if omitted)
- `[context-path1] [context-path2] ...` (optional): Research reports to guide revision

**Auto-Mode**:
- `<plan-path>` (required): Path to plan file
- `--auto-mode` (required): Enable automated revision
- `--context '<json>'` (required): Structured revision context

### Artifact Types Supported

- **Plans**: Implementation plans (all structure levels: L0/L1/L2)
- **Reports**: Research reports (single-file)

## Examples

### Plan Revisions

#### Add Phase to Plan
```bash
# Revision-first syntax
/revise "Add Phase 6 for deployment and monitoring"

# Path-first syntax
/revise specs/plans/025_feature.md "Add Phase 6 for deployment and monitoring"
```

#### Modify Phase Tasks
```bash
# With research context
/revise "Update Phase 3 tasks based on performance findings" specs/reports/018_performance.md

# Path-first with context
/revise specs/plans/025_feature/ "Update Phase 3 tasks" specs/reports/018_performance.md
```

#### Update Plan Metadata
```bash
# Simple metadata update
/revise "Update complexity to High and add security risk assessment"

# Explicit path
/revise specs/plans/025_feature.md "Update complexity to High"
```

### Report Revisions (New)

#### Update Report Findings
```bash
# Basic report revision
/revise "Update findings based on implementation results" specs/reports/010_analysis.md

# With additional research context
/revise specs/reports/010_analysis.md "Incorporate new security patterns" specs/reports/015_security.md
```

#### Section-Specific Update
```bash
# Target specific section
/revise "Update Authentication section with OAuth implementation learnings" specs/reports/010_security.md

# Multiple sections
/revise "Revise Recommendations and Future Work sections based on completed implementation" specs/reports/010_analysis.md
```

#### Add New Findings
```bash
# Add to existing report
/revise "Add performance benchmark results to Performance section" specs/reports/012_optimization.md
```

### Auto-Mode (Existing, Unchanged)

```bash
# Triggered by /implement for complexity
/revise specs/plans/025_plan.md --auto-mode --context '{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity exceeds threshold",
  "complexity_metrics": {"tasks": 12, "score": 9.2}
}'
```
```

### Auto-Mode vs Interactive Mode Clarification

**Add Comparison Table** (new section in `/revise.md`):

```markdown
## Mode Comparison

| Aspect | Interactive Mode | Auto-Mode |
|--------|------------------|-----------|
| **Trigger** | User explicitly calls `/revise` | `/implement` detects trigger condition |
| **Input** | Natural language description | Structured JSON context |
| **Confirmation** | Presents changes, asks confirmation (optional) | No confirmation, deterministic execution |
| **Use Case** | User-driven plan changes | Automated plan adjustments during implementation |
| **Revision Types** | Any content change | Specific types: expand_phase, add_phase, split_phase, update_tasks, collapse_phase |
| **History Format** | Detailed rationale and context | Concise audit trail with trigger info |
| **Artifact Support** | Plans and reports | Plans only |
| **Context** | Research reports (optional) | JSON context with metrics |

### When to Use Each Mode

**Use Interactive Mode When**:
- Incorporating new requirements from stakeholders
- Revising based on research findings
- Making strategic plan changes
- Updating reports with new findings
- You want visibility and control over changes

**Use Auto-Mode When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Automated structure optimization needed
- You're building automated workflows

**Auto-Mode is NOT Suitable For**:
- Strategic plan changes requiring human judgment
- Major scope changes or pivots
- Report modifications
- Initial plan creation
```

## Command Selection Guide

### Decision Matrix: When to Use Which Command

Create new file: `.claude/docs/command-selection-guide.md`

```markdown
# Command Selection Guide

Guide for choosing the right command for plan and report modification tasks.

## Quick Decision Tree

```
Need to modify plan or report?
│
├─ Content changes (add/modify/remove information)?
│  └─ Use: /revise
│
└─ Structural changes (reorganize files)?
   ├─ Make phase/stage MORE detailed (separate file)?
   │  └─ Use: /expand
   └─ Make phase/stage LESS detailed (merge to parent)?
      └─ Use: /collapse
```

## Comprehensive Command Responsibility Matrix

### Plan Modification Commands

| Task | Command | Reason | Example |
|------|---------|--------|---------|
| Add tasks to phase | `/revise` | Content change | `/revise "Add database migration task to Phase 2"` |
| Modify phase objectives | `/revise` | Content change | `/revise "Update Phase 3 objective to include caching"` |
| Add new phase | `/revise` | Content change | `/revise "Add Phase 6 for deployment"` |
| Remove phase | `/revise` | Content change | `/revise "Remove Phase 4 as it's no longer needed"` |
| Update plan metadata | `/revise` | Content change | `/revise "Update complexity to High and add security risks"` |
| Change phase order | `/revise` | Content change | `/revise "Move Phase 5 before Phase 4"` |
| Update success criteria | `/revise` | Content change | `/revise "Add performance benchmarks to success criteria"` |
| Incorporate research | `/revise` | Content change with context | `/revise "Update based on findings" specs/reports/010_*.md` |
| **Split phase to file** | `/expand` | **Structural change** | `/expand phase specs/plans/025_*.md 3` |
| **Extract stage to file** | `/expand` | **Structural change** | `/expand stage specs/plans/025_*/phase_2_*.md 1` |
| **Merge phase to parent** | `/collapse` | **Structural change** | `/collapse phase specs/plans/025_*/ 3` |
| **Merge stage to parent** | `/collapse` | **Structural change** | `/collapse stage specs/plans/025_*/phase_2_*/ 1` |
| Auto-expand complex phase | `/expand` | Complexity trigger | `/expand specs/plans/025_*.md` (auto-analysis) |
| Auto-collapse simple phase | `/collapse` | Simplicity trigger | `/collapse specs/plans/025_*/ ` (auto-analysis) |

### Report Modification Commands

| Task | Command | Reason | Example |
|------|---------|--------|---------|
| Update findings | `/revise` | Content change | `/revise "Update security findings" specs/reports/010_*.md` |
| Add new research | `/revise` | Content change | `/revise "Add OAuth 2.0 analysis" specs/reports/010_*.md` |
| Revise section | `/revise` | Content change | `/revise "Update Recommendations section" specs/reports/010_*.md` |
| Update metadata | `/revise` | Content change | `/revise "Update last modified date and status" specs/reports/010_*.md` |
| Incorporate new data | `/revise` | Content change with context | `/revise "Integrate performance data" specs/reports/010_*.md specs/reports/012_*.md` |

**Note**: Reports do not have structural commands (always single-file)

## Common Scenarios with Command Recommendations

### Scenario 1: Phase Tasks Growing Too Long

**Situation**: Phase 3 has 15 tasks and is hard to track

**Question**: Should I use `/revise` or `/expand`?

**Answer**: `/expand` - This is a structural problem, not content

**Command**:
```bash
/expand phase specs/plans/025_feature.md 3
```

**Result**: Phase 3 extracted to `phase_3_name.md` for better organization

---

### Scenario 2: Need to Add Error Handling Phase

**Situation**: Implementation revealed missing error handling

**Question**: Which command adds a phase?

**Answer**: `/revise` - Adding a phase is a content change

**Command**:
```bash
/revise "Add Phase 5 for error handling and recovery patterns"
```

**Result**: New Phase 5 added inline (later expand if it grows complex)

---

### Scenario 3: Phase Completed and Now Simple

**Situation**: Phase 4 was expanded, but after completion it's only 3 tasks

**Question**: How do I simplify the structure?

**Answer**: `/collapse` - Merge expanded phase back to main plan

**Command**:
```bash
/collapse phase specs/plans/025_feature/ 4
```

**Result**: Phase 4 merged back into main plan, directory cleaned up

---

### Scenario 4: Update Report with Implementation Results

**Situation**: Implementation complete, need to update research report

**Question**: Do I use `/update` or `/revise`?

**Answer**: `/revise` - `/update` is deprecated, use `/revise` for all content changes

**Command**:
```bash
/revise "Update findings based on implementation results" specs/reports/010_analysis.md
```

**Result**: Report updated with implementation learnings

---

### Scenario 5: Change Phase Objectives

**Situation**: Phase 2 objective needs to include caching layer

**Question**: Modify content or structure?

**Answer**: `/revise` - Changing objective is content, not structure

**Command**:
```bash
/revise "Update Phase 2 objective to include Redis caching layer implementation"
```

**Result**: Phase 2 objective updated in appropriate file (main plan or phase file)

---

## Anti-Patterns: What NOT to Do

### ❌ DON'T: Use /expand for Content Changes

**Wrong**:
```bash
/expand phase specs/plans/025_feature.md 2  # Trying to add tasks
```

**Why Wrong**: `/expand` changes structure (creates files), not content

**Right**:
```bash
/revise "Add database migration tasks to Phase 2"
```

---

### ❌ DON'T: Use /revise for Structural Reorganization

**Wrong**:
```bash
/revise "Move Phase 3 to separate file because it's too long"
```

**Why Wrong**: Creating separate files is structural, not content

**Right**:
```bash
/expand phase specs/plans/025_feature.md 3
```

---

### ❌ DON'T: Use /collapse to Remove Content

**Wrong**:
```bash
/collapse phase specs/plans/025_feature/ 4  # Trying to delete phase
```

**Why Wrong**: `/collapse` merges structure, doesn't remove content

**Right**:
```bash
/revise "Remove Phase 4 as it's no longer needed"
```

---

### ❌ DON'T: Use /update (Deprecated)

**Wrong**:
```bash
/update plan specs/plans/025_feature.md "Add tasks"
```

**Why Wrong**: `/update` is deprecated, use `/revise` instead

**Right**:
```bash
/revise "Add authentication tasks to Phase 2" specs/plans/025_feature.md
```

---

## Migration from /update to /revise

### All /update Patterns → /revise Equivalents

#### Pattern 1: Update Plan with Reason

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md "Add security requirements"
```

**After (/revise)**:
```bash
# Option 1: Revision-first (infer path from context)
/revise "Add security requirements"

# Option 2: Path-first (explicit path)
/revise specs/plans/025_feature.md "Add security requirements"
```

**Migration**: Both options work, choose based on preference

---

#### Pattern 2: Update Report Sections

**Before (/update)**:
```bash
/update report specs/reports/010_security.md "Authentication section"
```

**After (/revise)**:
```bash
/revise "Update Authentication section with OAuth 2.0 implementation" specs/reports/010_security.md
```

**Migration**: Be more specific in revision details for clarity

---

#### Pattern 3: Update Expanded Plan (Level 1)

**Before (/update)**:
```bash
/update plan specs/plans/025_feature/ "Revise Phase 4 scope"
```

**After (/revise)**:
```bash
/revise "Revise Phase 4 scope to include API rate limiting" specs/plans/025_feature/
```

**Migration**: Works identically, /revise handles all structure levels

---

#### Pattern 4: Update with No Specific Reason

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md
```

**After (/revise)**:
```bash
/revise "Update plan based on recent changes" specs/plans/025_feature.md
```

**Migration**: /revise requires revision details for clarity (better UX)

---

## Quick Reference Card

**Print-friendly summary for users**:

```
┌─────────────────────────────────────────────────────────────┐
│             Plan/Report Modification Commands                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  /revise                                                     │
│  Purpose: Modify content (tasks, objectives, findings)       │
│  Works with: Plans (L0/L1/L2), Reports                       │
│  Example: /revise "Add error handling phase"                │
│                                                               │
│  /expand                                                     │
│  Purpose: Extract phase/stage to separate file               │
│  Works with: Plans only                                      │
│  Example: /expand phase specs/plans/025_*.md 3              │
│                                                               │
│  /collapse                                                   │
│  Purpose: Merge phase/stage back to parent                   │
│  Works with: Plans only                                      │
│  Example: /collapse phase specs/plans/025_*/ 3              │
│                                                               │
│  Decision Rule:                                              │
│  - Content change (add/modify/remove) → /revise             │
│  - Structural change (reorganize files) → /expand or /collapse│
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Additional Resources

- **Command Patterns**: [command-patterns.md](command-patterns.md)
- **Adaptive Plan Structures**: [adaptive-plan-structures.md](adaptive-plan-structures.md)
- **Migration Guide**: [migration-guide-adaptive-plans.md](migration-guide-adaptive-plans.md)
- **Commands README**: [../commands/README.md](../commands/README.md)

## Notes

- This guide reflects the command consolidation as of 2025-10-10
- `/update` deprecated, all functionality consolidated into `/revise`
- `/expand` and `/collapse` remain separate (clear structural role)
- Command selection based on **intent** (content vs structure) not **artifact type**
```

## Migration Guide

### Migration Examples for All `/update` Use Cases

#### Use Case 1: Add New Phase to Plan

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md "Add Phase 6: Deployment"
```

**After (/revise)**:
```bash
# Option A: Natural language (revision-first)
/revise "Add Phase 6 for deployment automation and monitoring"

# Option B: Explicit path (path-first)
/revise specs/plans/025_feature.md "Add Phase 6 for deployment automation"
```

**Notes**:
- More descriptive revision details provide better context
- Path can be inferred from conversation or specified explicitly
- Revision history will be clearer with detailed descriptions

---

#### Use Case 2: Modify Existing Phase Tasks

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md "Update Phase 3 with caching layer"
```

**After (/revise)**:
```bash
/revise "Add Redis caching implementation tasks to Phase 3"
```

**Notes**:
- Specific revision details improve revision history
- Works with all plan structure levels (L0/L1/L2)
- No syntax change needed, just clearer descriptions

---

#### Use Case 3: Update Plan Scope and Objectives

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md "Expand scope to include mobile app"
```

**After (/revise)**:
```bash
/revise "Expand scope to include mobile app (iOS and Android native)"
```

**Notes**:
- Metadata changes work identically
- More detail in description provides better audit trail

---

#### Use Case 4: Update Report Findings

**Before (/update)**:
```bash
/update report specs/reports/010_security.md "Authentication section"
```

**After (/revise)**:
```bash
/revise "Update Authentication section with OAuth 2.0 best practices and token management patterns" specs/reports/010_security.md
```

**Notes**:
- Section targeting works by including section name in description
- /revise detects "Authentication section" keyword and focuses on that section
- More explicit than /update's terse syntax

---

#### Use Case 5: Update Report with New Research

**Before (/update)**:
```bash
/update report specs/reports/010_optimization.md "Add new benchmark data"
```

**After (/revise)**:
```bash
/revise "Add Redis vs Memcached benchmark results to Performance section" specs/reports/010_optimization.md
```

**Notes**:
- Descriptive updates create better revision history
- Can include context reports for cross-referencing

---

#### Use Case 6: Update Expanded Plan (Level 1)

**Before (/update)**:
```bash
/update plan specs/plans/025_feature/ "Revise Phase 4"
```

**After (/revise)**:
```bash
/revise "Update Phase 4 testing approach to include load testing" specs/plans/025_feature/
```

**Notes**:
- Works identically for expanded plans
- /revise automatically detects structure level
- Updates appropriate file (main plan or phase file)

---

#### Use Case 7: Incorporate Research into Plan

**Before** (couldn't do with /update):
```bash
# Had to use /revise already
/revise "Update based on research" specs/reports/012_patterns.md
```

**After** (still /revise):
```bash
/revise "Incorporate authentication patterns from research" specs/plans/025_feature.md specs/reports/012_patterns.md
```

**Notes**:
- Research integration was already a /revise feature
- No migration needed for this use case

---

### Edge Cases and How to Handle Them

#### Edge Case 1: Update with Minimal Context

**Before (/update)**:
```bash
/update plan specs/plans/025_feature.md
```

**After (/revise)**:
```bash
# /revise requires revision details for clarity
/revise "Update plan based on recent implementation changes" specs/plans/025_feature.md
```

**Why**: /revise encourages explicit revision descriptions for better history

---

#### Edge Case 2: Batch Updates to Multiple Plans

**Before (/update)**:
```bash
# Would need multiple commands
/update plan specs/plans/025_a.md "Add logging"
/update plan specs/plans/025_b.md "Add logging"
```

**After (/revise)**:
```bash
# Still requires multiple commands, but consider consolidation
/revise "Add structured logging to all phases" specs/plans/025_a.md
/revise "Add structured logging to all phases" specs/plans/025_b.md

# Alternative: Consider if these should be one plan
```

**Why**: No change in workflow, but prompts consideration of plan structure

---

#### Edge Case 3: Update Plan and Report Together

**Before** (required two commands):
```bash
/update plan specs/plans/025_feature.md "Add security phase"
/update report specs/reports/010_security.md "Update recommendations"
```

**After** (still two commands, but consistent):
```bash
/revise "Add Phase 5 for security hardening" specs/plans/025_feature.md
/revise "Update Recommendations section with implemented security controls" specs/reports/010_security.md
```

**Why**: Clearer separation of concerns, both using same command pattern

---

### Troubleshooting Common Migration Issues

#### Issue 1: "Which syntax should I use?"

**Question**: Revision-first or path-first?

**Answer**: Either works, choose based on context:
- **Revision-first**: When plan is in current conversation context
- **Path-first**: When switching context or being explicit

**Example**:
```bash
# In active conversation about plan XYZ
/revise "Add deployment phase"  # Inferred from context

# Starting new task
/revise specs/plans/025_feature.md "Add deployment phase"  # Explicit
```

---

#### Issue 2: "How do I target report sections?"

**Question**: Old `/update report path "section"` was explicit

**Answer**: Include section name in revision description

**Example**:
```bash
# Section targeting via keywords
/revise "Update Authentication section with OAuth implementation" specs/reports/010_security.md

# /revise detects "Authentication section" and targets that section
```

---

#### Issue 3: "Can I still use /update?"

**Question**: Will /update stop working?

**Answer**: No, /update remains functional (deprecated, not removed)

**Recommendation**: Migrate to /revise for:
- Better features (research integration, auto-mode, structure recommendations)
- Consistent command model
- Future enhancements (only /revise will be maintained)

---

## Documentation Updates

### Files to Modify

#### 1. `.claude/commands/update.md`

**Changes**:
- Add deprecation banner (frontmatter + top of content)
- Add migration guide section
- Add runtime deprecation warning
- Update `command-type: deprecated` in frontmatter
- Update `description` to include deprecation notice
- Keep original documentation for reference during migration period

**Lines Changed**: ~50 lines added (banner, guide, warning)

---

#### 2. `.claude/commands/revise.md`

**Changes**:
- Add artifact type detection section (plans and reports)
- Add report revision process section
- Add flexible argument syntax (path-first option)
- Add section targeting for reports
- Add enhanced examples (plans and reports)
- Add mode comparison table (interactive vs auto-mode)
- Update usage section with both syntaxes

**Lines Added**: ~200 lines (comprehensive report support)

---

#### 3. `.claude/commands/README.md`

**Changes**:
- Update `/update` entry to mark as deprecated
- Update `/revise` description to mention report support
- Add recent changes section (command consolidation entry)
- Update command count (26 → 25)
- Add link to command-selection-guide.md

**Lines Changed**: ~30 lines

---

#### 4. `.claude/README.md`

**Changes**:
- Add command consolidation announcement
- Update command list with deprecation note
- Add link to command-selection-guide.md

**Lines Changed**: ~15 lines

---

#### 5. Create `.claude/docs/command-selection-guide.md`

**New File**: Comprehensive guide for command selection

**Content** (as detailed in specification above):
- Quick decision tree
- Command responsibility matrix
- Common scenarios with examples
- Anti-patterns
- Migration from /update to /revise
- Quick reference card

**Lines**: ~400 lines (new file)

---

### Cross-Reference Updates

**Search for /update references** and update:

```bash
# Find all references to /update in docs and commands
grep -r "/update" .claude/ --include="*.md" | grep -v "update.md"
```

**Expected locations**:
- `.claude/docs/efficiency-guide.md` - Example workflow references
- `.claude/docs/migration-guide-adaptive-plans.md` - Command examples
- `.claude/commands/implement.md` - May reference /update in workflow
- `.claude/commands/orchestrate.md` - Workflow examples

**Update strategy**:
- Replace `/update` examples with `/revise`
- Add note: "(/update deprecated, use /revise)"
- Update workflow diagrams if any

**Estimated**: 10-15 references to update

---

## Detailed Task Breakdown

### Task 1: Update `/update.md` with Deprecation Notice

**Objective**: Add comprehensive deprecation information to /update command

**Files to Modify**:
- `.claude/commands/update.md`

**Changes Required**:
1. Update frontmatter:
   ```yaml
   description: ⚠️ DEPRECATED - Use /revise instead (Update an existing implementation plan or research report)
   command-type: deprecated
   deprecation-date: 2025-10-10
   migration-command: /revise
   ```

2. Add deprecation banner at top of content (after frontmatter)

3. Add migration guide section with before/after examples

4. Add runtime deprecation warning (bash script to display warning)

5. Preserve original documentation below migration guide

**Validation Criteria**:
- [ ] Deprecation banner visible at top of file
- [ ] Migration guide includes all common use cases
- [ ] Runtime warning displays when command executed
- [ ] Original documentation remains accessible

**Testing**:
```bash
# Verify deprecation banner in file
head -30 .claude/commands/update.md | grep "DEPRECATED"

# Test runtime warning
/update plan specs/plans/test.md "test"
# Should display warning before execution
```

**Estimated Time**: 30 minutes

---

### Task 2: Enhance `/revise.md` with Report Support

**Objective**: Add full report artifact support to /revise command

**Files to Modify**:
- `.claude/commands/revise.md`

**Changes Required**:
1. Add artifact type detection section
   - Plan detection logic
   - Report detection logic
   - Auto-detection fallback

2. Add report revision process section
   - Report analysis
   - Revision assessment
   - Research integration
   - Report updates
   - Version tracking for reports

3. Add flexible argument syntax
   - Document path-first syntax option
   - Add argument detection logic (bash)
   - Maintain backward compatibility

4. Add section targeting for reports
   - Section detection from revision details
   - Section extraction logic
   - Targeted update process

5. Update examples section
   - Add plan revision examples
   - Add report revision examples (NEW)
   - Add section-specific examples (NEW)

6. Add mode comparison table
   - Interactive vs Auto-mode
   - When to use each

**Validation Criteria**:
- [ ] Artifact detection logic clear and comprehensive
- [ ] Report revision process documented step-by-step
- [ ] Both syntax options documented with examples
- [ ] Section targeting explained with examples
- [ ] Mode comparison table accurate

**Testing**:
```bash
# Test report detection (manual review of command logic)
# Test path-first syntax
/revise specs/plans/test.md "Add phase"

# Test revision-first syntax
/revise "Add phase to test plan"

# Verify both work identically
```

**Estimated Time**: 1.5 hours

---

### Task 3: Create Command Selection Guide

**Objective**: Provide comprehensive decision guide for command selection

**Files to Create**:
- `.claude/docs/command-selection-guide.md`

**Content Required**:
1. Quick decision tree (visual)
2. Comprehensive command responsibility matrix
3. Common scenarios with recommendations
4. Anti-patterns (what NOT to do)
5. Migration from /update to /revise
6. Quick reference card

**Validation Criteria**:
- [ ] Decision tree covers all major use cases
- [ ] Matrix includes all modification tasks
- [ ] Scenarios representative of real usage
- [ ] Anti-patterns clearly explained
- [ ] Migration guide covers all /update patterns
- [ ] Quick reference card print-friendly

**Testing**:
```bash
# Verify file created
ls -lh .claude/docs/command-selection-guide.md

# Verify content comprehensive (rough check)
wc -l .claude/docs/command-selection-guide.md
# Should be ~400 lines

# Verify all sections present
grep "^## " .claude/docs/command-selection-guide.md
```

**Estimated Time**: 1 hour

---

### Task 4: Update Command Documentation

**Objective**: Update all command documentation to reflect consolidation

**Files to Modify**:
- `.claude/commands/README.md`
- `.claude/README.md`

**Changes Required**:

**`.claude/commands/README.md`**:
1. Update command count (26 → 25)
2. Mark `/update` as deprecated in command list
3. Update `/revise` description to mention reports
4. Add recent changes section entry
5. Add link to command-selection-guide.md

**`.claude/README.md`**:
1. Add command consolidation announcement
2. Update command overview
3. Add link to command-selection-guide.md

**Validation Criteria**:
- [ ] Command count accurate (25 active + 1 deprecated)
- [ ] Deprecation clearly marked
- [ ] Links to selection guide working
- [ ] Recent changes section updated

**Testing**:
```bash
# Verify command count
grep -c "^#### /" .claude/commands/README.md

# Verify deprecation marked
grep "deprecated" .claude/commands/README.md

# Verify links work
grep "command-selection-guide.md" .claude/README.md
```

**Estimated Time**: 30 minutes

---

### Task 5: Update Cross-References

**Objective**: Find and update all references to /update in documentation

**Files to Search and Modify**:
- All `.md` files in `.claude/docs/`
- All `.md` files in `.claude/commands/`
- Exclude `.claude/commands/update.md` (already handled)

**Search Command**:
```bash
grep -r "/update" .claude/ --include="*.md" | grep -v "update.md" | grep -v "command-selection-guide.md"
```

**Changes Required**:
1. Replace `/update` examples with `/revise`
2. Add deprecation note where appropriate
3. Update workflow diagrams if any
4. Verify all examples still valid

**Validation Criteria**:
- [ ] All /update references found
- [ ] All examples updated to /revise
- [ ] Deprecation notes added where helpful
- [ ] No broken examples remain

**Testing**:
```bash
# Verify all references updated
grep -r "/update" .claude/ --include="*.md" | grep -v "update.md" | grep -v "DEPRECATED" | wc -l
# Should be 0 (all references either in update.md or noted as deprecated)
```

**Estimated Time**: 45 minutes

---

### Task 6: Integration Testing

**Objective**: Verify all changes work together correctly

**Testing Procedures**:

1. **Test /update deprecation warning**:
   ```bash
   /update plan specs/plans/test.md "test update"
   # Verify warning displays
   # Verify command still functional
   ```

2. **Test /revise with plans (existing)**:
   ```bash
   /revise "Add test phase" specs/plans/test.md
   # Verify works as before
   ```

3. **Test /revise with reports (NEW)**:
   ```bash
   /revise "Update findings section" specs/reports/test_report.md
   # Verify report detection works
   # Verify report updated correctly
   ```

4. **Test /revise path-first syntax (NEW)**:
   ```bash
   /revise specs/plans/test.md "Add test phase"
   # Verify argument detection works
   ```

5. **Test /revise section targeting (NEW)**:
   ```bash
   /revise "Update Authentication section with new findings" specs/reports/test.md
   # Verify section detection works
   ```

6. **Test command selection guide**:
   ```bash
   cat .claude/docs/command-selection-guide.md
   # Manual review for accuracy and completeness
   ```

7. **Verify documentation links**:
   ```bash
   # Check all links in updated files resolve
   grep -o '\[.*\](.*\.md)' .claude/commands/update.md
   grep -o '\[.*\](.*\.md)' .claude/commands/revise.md
   grep -o '\[.*\](.*\.md)' .claude/docs/command-selection-guide.md
   ```

**Validation Criteria**:
- [ ] All tests pass without errors
- [ ] Deprecation warnings display correctly
- [ ] Report support works as documented
- [ ] Path-first syntax works correctly
- [ ] Section targeting works for reports
- [ ] All documentation links resolve

**Estimated Time**: 30 minutes

---

## Testing Specifications

### Test 1: Deprecation Warning Display

**Test File**: Manual test (no automated test needed)

**Procedure**:
```bash
# Execute deprecated command
/update plan specs/plans/test_plan.md "Test deprecation"

# Expected output: Deprecation warning banner before execution
# Expected: Command still executes normally after warning
```

**Pass Criteria**:
- Warning banner displays with migration guidance
- Command executes after warning
- Warning mentions /revise as replacement

---

### Test 2: /revise Report Support

**Test File**: Create test report for validation

**Procedure**:
```bash
# Create test report
cat > specs/reports/999_test_report.md << 'EOF'
# Test Research Report

## Metadata
- Date: 2025-10-10
- Topic: Test Report

## Findings
Initial findings here.

## Recommendations
Initial recommendations.
EOF

# Test report revision
/revise "Update Findings section with new data" specs/reports/999_test_report.md

# Expected: Report updated with revision history added
```

**Pass Criteria**:
- Report detected correctly as artifact type
- Findings section updated
- Revision history added to report
- Metadata updated (last modified date)

---

### Test 3: Path-First Syntax

**Test File**: Manual test with existing plan

**Procedure**:
```bash
# Test path-first syntax
/revise specs/plans/test_plan.md "Add Phase 4 for testing"

# Expected: Plan revised with Phase 4 added
# Same result as: /revise "Add Phase 4 for testing" specs/plans/test_plan.md
```

**Pass Criteria**:
- Argument detection works correctly
- Plan revised successfully
- Revision history accurate

---

### Test 4: Section Targeting

**Test File**: Use test report created in Test 2

**Procedure**:
```bash
# Test section-specific targeting
/revise "Update Recommendations section with implementation results" specs/reports/999_test_report.md

# Expected: Only Recommendations section modified, Findings unchanged
```

**Pass Criteria**:
- Section name detected from revision description
- Only targeted section modified
- Other sections preserved
- Revision history notes section modified

---

### Test 5: Documentation Link Validation

**Test File**: Bash script for link checking

**Procedure**:
```bash
# Extract all markdown links from updated files
for file in .claude/commands/update.md .claude/commands/revise.md .claude/docs/command-selection-guide.md; do
  echo "Checking links in $file..."
  grep -oP '\[.*?\]\(\K[^)]+' "$file" | while read link; do
    # Resolve relative links
    if [[ ! "$link" =~ ^http ]]; then
      link_path=$(dirname "$file")/"$link"
      if [[ ! -f "$link_path" ]]; then
        echo "  BROKEN: $link"
      fi
    fi
  done
done
```

**Pass Criteria**:
- All internal documentation links resolve
- No broken relative links
- All referenced files exist

---

## Success Criteria

### Functional Success Criteria

- [ ] `/update` command displays deprecation warning when executed
- [ ] `/update` remains functional during migration period (backward compatibility)
- [ ] `/revise` successfully handles plan revisions (existing functionality)
- [ ] `/revise` successfully handles report revisions (new functionality)
- [ ] `/revise` supports both revision-first and path-first syntax
- [ ] `/revise` detects and targets report sections correctly
- [ ] Command selection guide created and comprehensive
- [ ] All documentation updated with deprecation notices
- [ ] All cross-references to /update updated to /revise

### Quality Success Criteria

- [ ] Deprecation warning clear and helpful
- [ ] Migration guide includes all common use cases
- [ ] Command selection guide easy to understand
- [ ] Decision tree covers all scenarios
- [ ] No functionality lost in consolidation
- [ ] Documentation clear and consistent

### User Experience Success Criteria

- [ ] Migration path obvious and straightforward
- [ ] /revise syntax intuitive for both plans and reports
- [ ] Command selection less confusing (3 commands with clear roles)
- [ ] Examples comprehensive and representative

## Post-Implementation Validation

### Validation Checklist

After implementing all tasks, verify:

**Documentation**:
- [ ] Deprecation notice visible in /update.md
- [ ] Migration guide in /update.md comprehensive
- [ ] /revise.md includes report support documentation
- [ ] Command selection guide created and linked
- [ ] README files updated with consolidation announcement
- [ ] All cross-references updated

**Functionality**:
- [ ] /update displays deprecation warning
- [ ] /update still functional
- [ ] /revise works with plans (L0/L1/L2)
- [ ] /revise works with reports
- [ ] /revise supports both syntax options
- [ ] /revise section targeting works

**Testing**:
- [ ] Manual tests pass (5 test procedures)
- [ ] Documentation links validated
- [ ] No broken references
- [ ] Examples work as documented

**User Communication**:
- [ ] Deprecation timeline clear (30 days)
- [ ] Migration examples cover all use cases
- [ ] Command selection guide accessible
- [ ] Quick reference card helpful

## Notes and Considerations

### Design Philosophy Alignment

This phase follows the project's clean-break refactor philosophy:
- **Deprecating cleanly**: Clear warnings, comprehensive migration guide
- **No partial support**: /revise fully supports all /update use cases
- **Documentation focus**: Present state (what to use now), not historical commentary
- **User-focused**: Decision guide based on intent, not implementation details

### Backward Compatibility

- `/update` remains functional indefinitely (deprecated, not removed)
- 30-day migration period for users to transition
- No breaking changes to existing workflows
- Deprecation warnings educate without blocking

### Future Enhancements (Not in This Phase)

Potential future improvements deferred:
- Interactive migration assistant (`/migrate-to-revise`)
- Automated /update → /revise translation
- Usage analytics to track migration progress
- Auto-deprecation removal after 6 months

### Maintenance Considerations

- `/revise` becomes single source of truth for content modifications
- Only one command to enhance for new artifact types
- Clearer testing (fewer command interaction cases)
- Simpler documentation (clear command boundaries)

## Implementation Summary

**Total Estimated Time**: 3-4 hours

**Task Breakdown**:
1. Update /update.md with deprecation: 30 min
2. Enhance /revise.md with report support: 1.5 hours
3. Create command selection guide: 1 hour
4. Update command documentation: 30 min
5. Update cross-references: 45 min
6. Integration testing: 30 min

**Files Created**: 1
- `.claude/docs/command-selection-guide.md` (~400 lines)

**Files Modified**: 4
- `.claude/commands/update.md` (~50 lines added)
- `.claude/commands/revise.md` (~200 lines added)
- `.claude/commands/README.md` (~30 lines changed)
- `.claude/README.md` (~15 lines changed)

**Documentation Impact**:
- Command ecosystem simplified (26 → 25 active commands)
- Clearer command responsibilities (content vs structure)
- Comprehensive migration support
- Improved user decision-making

**User Impact**:
- **Minimal disruption**: /update still works, deprecation warnings educate
- **Improved clarity**: Single command for content changes
- **Better features**: /revise has research integration, auto-mode, structure recommendations
- **Easier learning**: Clear decision tree for command selection

---

This specification provides a complete implementation roadmap for Phase 5: Command Consolidation, with concrete steps, examples, testing procedures, and success criteria.
