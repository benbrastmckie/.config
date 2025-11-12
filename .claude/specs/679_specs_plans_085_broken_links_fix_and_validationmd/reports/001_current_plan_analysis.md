# Plan 085 Current Scope Analysis

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Current scope analysis of plan 085_broken_links_fix_and_validation.md
- **Report Type**: codebase analysis

## Executive Summary

Plan 085 targets 1,443 broken internal links across active documentation directories (.claude/docs/, .claude/commands/, .claude/agents/) with a three-pronged strategy: automated pattern fixes (~200 links), selective manual fixes for high-value files (~150 links), and prevention infrastructure via validation tooling. The plan explicitly excludes .claude/archive/ directories and preserves historical integrity of .claude/specs/ files. No link validation tasks are currently scoped for specs/ directories beyond preserving their historical state.

## Findings

### 1. Current Scope Definition

Plan 085 defines a **four-tier priority system** for broken link fixes:

**Priority 1 (Manual)**: Active documentation directories
- .claude/docs/guides/ (command and agent guides)
- .claude/docs/reference/ (reference documentation)
- .claude/docs/concepts/ (pattern documentation)
- .claude/docs/workflows/ (workflow guides)
- .claude/commands/*.md (command definitions)
- .claude/agents/*.md (agent definitions)

**Priority 2 (Automated)**: Systematic pattern fixes
- Absolute path duplications (~120 links)
- Renamed file references (~30 links)
- Archive path updates (docs/archive/ → docs/)

**Priority 3 (Skip)**: Historical documentation
- .claude/specs/**/reports/ (research reports)
- .claude/specs/**/plans/ (implementation plans, except active)
- .claude/specs/**/summaries/ (completion summaries)
- **Rationale**: "Document historical states, broken links are often intentional" (line 77)

**Priority 4 (Never Fix)**: Template placeholders
- Patterns with {variables}, regex, NNN_ prefixes
- Example: `[Plan](specs/NNN_topic/plans/001_plan.md)`

### 2. Directories Currently In Scope

**Explicit inclusions** (from validation scripts, lines 763-770):
- `.claude/docs/` (all subdirectories)
- `.claude/commands/`
- `.claude/agents/`
- `README.md` (root)
- `docs/` (general documentation)
- `nvim/docs/` (Neovim-specific docs)

**Explicit exclusions** (from validation logic, lines 790, 970):
- `.claude/specs/**/reports/` - skipped via regex pattern
- `.claude/specs/**/plans/` - skipped via regex pattern
- Template files with NNN_, {}, $VAR patterns

### 3. Archive Directory References

**Current plan mentions archive in two contexts**:

1. **Priority 2 automated fix pattern** (line 71):
   - Pattern: `docs/archive/concepts/ → docs/concepts/`
   - This is a **link target update**, not directory exclusion
   - Example in link conventions guide (lines 1181-1184): updating links FROM archive paths TO current paths

2. **No .claude/archive/ directory scope**:
   - Searched plan for `.claude/archive` - **zero matches**
   - Checked filesystem: `/home/benjamin/.config/.claude/archive/` exists but is **empty**
   - **Conclusion**: .claude/archive/ is not in current plan scope

### 4. Specs Directory Treatment

**Explicit preservation policy** (Priority 3, lines 73-77):
- .claude/specs/**/reports/ - **SKIP** (historical research)
- .claude/specs/**/plans/ - **SKIP** (except active plans)
- .claude/specs/**/summaries/ - **SKIP** (completion summaries)

**Validation scripts exclude specs** (lines 790, 970):
```bash
# Skip spec reports and plans (historical docs)
if [[ "$file" =~ /specs/.*/reports/ ]] || [[ "$file" =~ /specs/.*/plans/ ]]; then
  continue
fi
```

**No validation tasks for specs directories**:
- No tasks to fix links IN specs/ files
- No tasks to validate links IN specs/ files
- Only task: preserve historical integrity (line 1721: "no changes to specs/")

### 5. Phase Breakdown

**Phase 2: Automated Fixes** (lines 274-473)
- Task 2.1: Fix duplicate absolute paths (~120 links)
- Task 2.2: Convert absolute to relative paths (~50 links)
- Task 2.3: Fix renamed file references (~30 links)
- **Total automated**: ~200 links
- **Scope**: Only `.claude/docs/`, `.claude/commands/`, `.claude/agents/`

**Phase 3: Manual Fixes** (lines 475-648)
- Task 3.2: Fix .claude/docs/guides/
- Task 3.3: Fix .claude/docs/reference/
- Task 3.4: Fix .claude/commands/*.md
- Task 3.5: Fix .claude/agents/*.md
- **Total manual**: ~150 links
- **Scope**: Same as Phase 2 (active docs only)

**Phase 4: Validation Tooling** (lines 651-1029)
- Install markdown-link-check
- Create validation scripts
- Configure exclusions for specs/, templates
- Optional: GitHub Actions, pre-commit hooks

**Phase 5: Documentation** (lines 1032-1497)
- Link conventions guide
- Troubleshooting guide
- CLAUDE.md updates

**Phase 6-7: Verification and Commit** (lines 1500-2125)
- Validation runs
- Git commits
- Implementation summary

### 6. Key Findings Summary

1. **Archive directory**: Only referenced as old link TARGET (docs/archive/), not as scope directory (.claude/archive/)
2. **Specs directories**: Explicitly excluded from all fixes and validation (Priority 3)
3. **No specs validation**: Zero tasks to check or fix links within .claude/specs/ files
4. **Preservation rationale**: Historical documentation should reflect system evolution, including file moves/renames
5. **Total fixes**: ~373 links (200 automated + 150 manual) out of 1,443 remaining broken links
6. **Remaining broken**: ~1,070 links intentionally preserved in historical specs/

## Recommendations

### 1. Clarify Archive Directory Scope

**Issue**: Plan mentions "archive removals" (line 71) but doesn't specify whether .claude/archive/ directory should be validated or excluded.

**Recommendation**: Add explicit statement about .claude/archive/ status:
- If empty and unused: Document that it's excluded (no markdown files to validate)
- If contains active docs: Add to Priority 1 scope
- If historical: Add to Priority 3 exclusions

### 2. Document Specs Preservation Policy

**Issue**: Priority 3 excludes specs/ but doesn't explain what "except active plans" means (line 75).

**Recommendation**: Define criteria for "active plans":
- Plans with status: "In Progress" in metadata?
- Plans modified in last N days?
- Plans explicitly marked for validation?
- Current understanding: Plan 085 itself would be "active" but all others skipped

### 3. Consider Partial Specs Validation

**Issue**: Zero validation tasks for specs/ means broken links in active specs go undetected.

**Recommendation**: Add optional Phase 3.7 task:
- Validate links in specs/ plans marked "Status: In Progress"
- Validate links in reports created in last 30 days
- Use more permissive validation (allow historical paths)
- **Rationale**: Recent specs likely reference current file locations

### 4. Quantify Archive Path Updates

**Issue**: Priority 2 mentions "Archive removals: docs/archive/concepts/ → docs/concepts/" but doesn't estimate affected links.

**Recommendation**: Add Task 2.3.1 to:
```bash
# Count links pointing to docs/archive/
grep -r "docs/archive/" --include="*.md" .claude/docs/ .claude/commands/ .claude/agents/ | wc -l
```
- Update estimated fixes if significant
- Document pattern in fix-renamed-files.sh

### 5. Add Validation Scope Diagram

**Issue**: Four priority tiers scattered across multiple sections make scope boundaries unclear.

**Recommendation**: Add visual diagram in Technical Design section:
```
Repository Structure
├── .claude/
│   ├── archive/          [EMPTY - No validation needed]
│   ├── docs/             [Priority 1 - Manual + Automated]
│   ├── commands/         [Priority 1 - Manual + Automated]
│   ├── agents/           [Priority 1 - Manual + Automated]
│   └── specs/
│       ├── reports/      [Priority 3 - SKIP]
│       ├── plans/        [Priority 3 - SKIP (except active)]
│       └── summaries/    [Priority 3 - SKIP]
├── docs/                 [Validation scope - included]
├── nvim/docs/            [Validation scope - included]
└── README.md             [Validation scope - included]
```

### 6. Define "Active Plan" Detection

**Recommendation**: Add Task 3.8 to create script for identifying active plans:
```bash
# Option A: Metadata-based
grep -l "Status.*In Progress" .claude/specs/**/plans/*.md

# Option B: Time-based (modified in last 30 days)
find .claude/specs -path "*/plans/*.md" -mtime -30

# Option C: Manual list in plan
ACTIVE_PLANS=(
  ".claude/specs/679_*/plans/*.md"  # Current plan
)
```

## References

### Plan File
- `/home/benjamin/.config/.claude/specs/plans/085_broken_links_fix_and_validation.md` (entire file analyzed)

### Key Sections
- Lines 60-82: Priority tier definitions (4 tiers)
- Lines 274-278: Phase 2 scope (automated fixes)
- Lines 475-479: Phase 3 scope (manual fixes)
- Lines 763-770: Validation script directory list
- Lines 790, 970: Specs directory exclusion logic
- Line 71: Archive path update pattern
- Line 77: Historical preservation rationale
- Lines 74-76: Specs subdirectory exclusions
- Line 1721: Preservation confirmation ("no changes to specs/")

### Filesystem Checks
- `/home/benjamin/.config/.claude/archive/` - Directory exists, empty (no files)
- No `.claude/archive/` references found in plan text

### Statistics
- Total broken links: 1,443 (line 18)
- Automated fixes: ~200 links (lines 281-341)
- Manual fixes: ~150 links (lines 475-648)
- Total fixes: ~373 links
- Preserved broken: ~1,070 links (in specs/)
