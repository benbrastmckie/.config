# Standards Analysis and Report Application

This document provides comprehensive documentation for the standards analysis and report application features in the /setup command.

**Referenced by**: [setup.md](../../../commands/setup.md)

**Contents**:
- Analysis Mode Workflow
- Report Application Mode
- Integration Examples
- Best Practices

---

## Analysis Mode (--analyze)

Analyzes three sources to detect discrepancies:

| Source | What's Analyzed | Method |
|--------|----------------|--------|
| **CLAUDE.md** | Documented standards | Parse sections with `[Used by: ...]` metadata → Extract field values |
| **Codebase** | Actual patterns | Sample files → Detect indentation, naming, error handling, test patterns → Calculate confidence |
| **Config Files** | Tool configurations | Parse `.editorconfig`, `package.json`, `stylua.toml`, etc. → Extract tool settings |

### Discrepancy Types

| Type | Description | Detection | Priority |
|------|-------------|-----------|----------|
| 1 | Documented ≠ Followed | CLAUDE.md value ≠ codebase pattern (>50% confidence) | Critical |
| 2 | Followed but undocumented | Codebase pattern (>70% confidence) not in CLAUDE.md | High |
| 3 | Config ≠ CLAUDE.md | Config file value ≠ CLAUDE.md value | High |
| 4 | Missing section | Required section not in CLAUDE.md | Medium |
| 5 | Incomplete section | Section exists but missing required fields | Medium |

**Confidence Scoring**: High (>80%), Medium (50-80%), Low (<50%) based on consistency across sampled files.

### Generated Report Structure

Report saved to `specs/reports/NNN_standards_analysis_report.md`:

1. **Metadata**: Date, project dir, files analyzed, languages detected
2. **Executive Summary**: Discrepancy counts, key findings, overall status
3. **Current State**: 3-way comparison (CLAUDE.md vs Codebase vs Config Files)
4. **Discrepancy Analysis**: 5 sections (one per type) with examples, impact, recommendations
5. **Gap Analysis**: Critical/High/Medium gaps, organized by priority
6. **Interactive Gap Filling**: `[FILL IN: Field Name]` sections with:
   - Context (current state, detected patterns, recommendations)
   - User decision field
   - Rationale field
7. **Recommendations**: Prioritized action items (immediate/short-term/medium-term)
8. **Implementation Plan**: Manual editing vs automated `--apply-report` workflow

### Analysis Workflow

```
User: /setup --analyze [project-dir]

Claude:
1. Discover standards (parse CLAUDE.md + sample codebase + read configs)
2. Detect discrepancies (5 types, calculate confidence, prioritize)
3. Generate report with [FILL IN: ...] gap markers

User:
4. Review report
5. Fill [FILL IN: ...] sections with decisions and rationale

User: /setup --apply-report specs/reports/NNN_report.md

Claude:
6. Parse filled report
7. Backup CLAUDE.md
8. Apply decisions (update fields, add sections, reconcile discrepancies)
9. Validate structure
10. Report changes made
```

### Example Analysis

**Indentation Discrepancy (Type 1 - Critical)**:
- CLAUDE.md: "2 spaces" (line 42)
- Codebase: 4 spaces (85% confidence, 40/47 files)
- .editorconfig: `indent_size = 4`
- Report fills: `[FILL IN: Indentation]` with context, recommendation ("Update to 4 spaces")

**Error Handling Gap (Type 2 - High)**:
- CLAUDE.md: Not documented
- Codebase: `pcall()` used in 92% of error-prone operations
- Report fills: `[FILL IN: Error Handling]` with recommendation ("Use pcall for operations that might fail")

**Testing Section Missing (Type 4 - Medium)**:
- CLAUDE.md: No Testing Protocols section
- Codebase: `*_spec.lua` pattern (100% of test files), plenary.nvim detected
- Report fills: `[FILL IN: Testing Protocols]` with suggested section content

---

## Report Application Mode (--apply-report)

### Overview

Parses completed analysis report (`[FILL IN: ...]` sections filled by user) and updates CLAUDE.md with reconciled standards.

**Usage**: `/setup --apply-report <report-path> [project-directory]`

### Parsing Algorithm

1. **Locate Gaps**: Find `[FILL IN: <field>]` sections → Extract field name, context, user decision, rationale
2. **Map to CLAUDE.md**:
   - "Indentation" → Code Standards section, Indentation field
   - "Error Handling" → Code Standards section (add if missing)
   - "Testing Protocols" → New section (create if doesn't exist)
3. **Parse Decisions**:
   - Explicit value ("4 spaces") → Use value
   - Blank (`___`) → Skip this gap
   - `[Accept]` → Use recommended value from context
4. **Validate**: Check critical gaps filled → Verify format → Warn on pattern overrides

### Update Strategy

**Backup**: Always create `CLAUDE.md.backup.YYYYMMDD_HHMMSS` first

**Update Cases**:
| Case | Action |
|------|--------|
| Field exists | Locate → Replace value → Log change |
| Section exists, field missing | Insert field → Log addition |
| Section missing | Create section + metadata → Add fields → Log creation |

**Preservation**: Unaffected content unchanged → Standard section order maintained → `[Used by: ...]` metadata preserved

### Edge Cases

| Scenario | Handling |
|----------|----------|
| No CLAUDE.md exists | Create from scratch using report |
| Partially filled report | Apply filled only, skip blanks, log count |
| Invalid decision | Skip gap, warn, continue |
| Report/path issues | Error with helpful suggestion |
| Validation fails | Don't write, report errors, backup safe |

### Workflow Example

```bash
/setup --analyze                    # Generate analysis report
# Edit report, fill [FILL IN: ...] sections
/setup --apply-report specs/reports/034_*.md
# Output: Backup created, sections updated, validation passed
/validate-setup                     # Confirm structure
```

**Rollback**: Restore from backup: `cp CLAUDE.md.backup.TIMESTAMP CLAUDE.md`

---

## Integration Examples

### Complete Analysis-to-Application Workflow

```
Step 1: Initial Analysis
────────────────────────
/setup --analyze /path/to/project

Output: specs/reports/042_standards_analysis_report.md
Content: 5 discrepancies detected, 12 gaps identified


Step 2: Review and Fill Report
───────────────────────────────
Open: specs/reports/042_standards_analysis_report.md

Find sections like:
  [FILL IN: Indentation]
  Context: CLAUDE.md says "2 spaces", codebase uses 4 spaces (85% confidence)
  Recommendation: Update to "4 spaces" to match codebase
  Decision: _______________
  Rationale: _______________

Fill with:
  Decision: 4 spaces
  Rationale: Match existing codebase convention


Step 3: Apply Reconciliation
─────────────────────────────
/setup --apply-report specs/reports/042_standards_analysis_report.md

Output:
  Backup created: CLAUDE.md.backup.20250115_143022
  Updated 3 fields, added 2 sections
  Validation passed


Step 4: Verify Changes
──────────────────────
/setup --validate

Output: All sections valid, all links verified
```

### Partial Report Application

If you fill only some gaps:

```bash
/setup --analyze
# Fill only critical gaps in report, leave medium priority blank
/setup --apply-report specs/reports/042_*.md
# Output: Applied 3/12 gaps, skipped 9 blank gaps
```

**Benefit**: Incremental reconciliation - address critical issues first, defer lower-priority gaps

### Report Regeneration After Code Changes

```bash
# Initial analysis
/setup --analyze
# Fill report, apply changes
/setup --apply-report specs/reports/042_*.md

# ... 3 months later, code evolves ...

# Re-analyze to detect new drift
/setup --analyze
# New report: specs/reports/043_*.md
# Shows new discrepancies since last analysis
```

**Benefit**: Ongoing standards maintenance - catch drift as code evolves

---

## Best Practices

### When to Use Analysis Mode

**Good Use Cases**:
- Inheriting unfamiliar codebase
- CLAUDE.md out of sync with code
- Merging divergent team standards
- Preparing for refactoring
- Audit compliance verification

**Not Needed When**:
- Fresh project with no code yet
- CLAUDE.md created and maintained actively
- Standards already well-aligned

### Gap Filling Strategy

**Priority Order**:
1. **Critical discrepancies** (Type 1): CLAUDE.md contradicts code - high confusion risk
2. **High discrepancies** (Type 2, 3): Missing docs or config mismatches - medium risk
3. **Medium gaps** (Type 4, 5): Missing/incomplete sections - low risk, defer if time-limited

**Decision Guidelines**:
- **Code majority wins**: If 80%+ of codebase uses one pattern, document it
- **Config alignment**: Match CLAUDE.md to config files (`.editorconfig`, etc.)
- **Team consensus**: For subjective choices (naming, style), consult team
- **Leave blank**: For uncertain decisions, defer rather than guess

### Rollback and Recovery

**Before Applying**:
```bash
# Always preview impact first
cat specs/reports/042_*.md | grep "Decision:"  # Check what you filled
```

**After Applying**:
```bash
# If unhappy with results
cp CLAUDE.md.backup.20250115_143022 CLAUDE.md

# Or selectively undo specific changes
git diff CLAUDE.md                   # Review changes
git checkout -- CLAUDE.md            # Revert if using git
```

**Best Practice**: Commit CLAUDE.md before applying reports for easy rollback:
```bash
git add CLAUDE.md && git commit -m "Pre-analysis baseline"
/setup --apply-report specs/reports/042_*.md
# Review changes
git diff                              # See exactly what changed
git reset --hard HEAD                 # Revert if needed
```

---

## See Also

- [Setup Command Guide](../../commands/setup-command-guide.md) - Main setup documentation
- [Setup Modes](setup-modes-detailed.md) - Command mode details
- [Extraction Strategies](extraction-strategies.md) - CLAUDE.md optimization
- [Bloat Detection](bloat-detection.md) - Automatic optimization detection
