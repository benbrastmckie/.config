# Extraction Strategies

This document describes the smart extraction system used by /setup to optimize CLAUDE.md by moving detailed content to auxiliary files.

**Referenced by**: [setup.md](../../../commands/setup.md)

**Contents**:
- Smart Section Extraction
- Extraction Preferences
- Extraction Preview (Dry-Run Mode)
- Optimal CLAUDE.md Structure

---

## Smart Section Extraction

[Used by: Standard Mode (optional), Cleanup Mode (always)]

This extraction process optimizes CLAUDE.md by moving detailed content to auxiliary files while keeping essential information inline.

### Extraction Mapping

For sections that would benefit from extraction, content is moved to dedicated files:

| Section Type | Suggested File | Extraction Trigger |
|-------------|---------------|-------------------|
| Testing Standards | `docs/TESTING.md` | >20 lines of test details |
| Code Style Guide | `docs/CODE_STYLE.md` | Detailed formatting rules |
| Documentation Guide | `docs/DOCUMENTATION.md` | Template examples |
| Command Reference | `docs/COMMANDS.md` | >10 commands |
| Architecture | `docs/ARCHITECTURE.md` | Complex diagrams |

### Interactive Extraction Process

For each extractable section, the command asks:

```
Found: Testing Standards (45 lines) in CLAUDE.md

Would you like to:
[E]xtract to docs/TESTING.md and link it
[K]eep in CLAUDE.md as-is
[S]implify in place without extraction
```

If you choose extraction:
1. Create the auxiliary file with the content
2. Replace the section in CLAUDE.md with a concise summary and link
3. Add navigation links between files

### Decision Criteria

**Recommend extraction when**:
- Section is >30 lines of detailed content
- Content is reference material (not daily use)
- Multiple examples or templates present
- Complex configuration rarely changed

**Keep inline when**:
- Quick reference commands (<10 lines)
- Critical navigation/index information
- Specs protocol (core to Claude)
- Daily-use information

### File Organization

```
project/
├── CLAUDE.md              # Concise index
├── docs/
│   ├── TESTING.md        # Extracted test details
│   ├── CODE_STYLE.md     # Extracted style guide
│   └── ...               # Other extracted sections
└── specs/
    ├── plans/
    ├── reports/
    └── summaries/
```

### Benefits

**Concise CLAUDE.md:**
- Quick to scan and navigate
- Focuses on essential info
- Easy to maintain
- Clear hierarchy

**Auxiliary Files:**
- Detailed documentation without length constraints
- Topic-focused organization
- Better version control (smaller diffs)
- Can be referenced from multiple places

---

## Extraction Preferences

[Shared by: Standard Mode (with auto-detection), Cleanup Mode]

Control extraction behavior across all modes that use extraction functionality.

### Threshold Settings

| Threshold | Line Trigger | Use Case | Effect | Usage |
|-----------|--------------|----------|--------|-------|
| Aggressive | >20 lines | Very large CLAUDE.md (>300 lines) | Maximum extraction, smallest main file | `--threshold aggressive` |
| Balanced (default) | >30 lines | Moderate CLAUDE.md (200-300 lines) | Extract significantly detailed sections | `--cleanup` (default) |
| Conservative | >50 lines | Manageable CLAUDE.md (150-250 lines) | Minimal extraction, keep content inline | `--threshold conservative` |
| Manual | N/A | Full extraction control | Interactive choice for each section | `--threshold manual` |

### Directory and Naming Preferences

| Preference | Options | Default | Usage |
|------------|---------|---------|-------|
| Target directory | `docs/` (default), custom path, per-type | `docs/` | `--target-dir=documentation/` |
| File naming | CAPS.md, lowercase.md, Mixed.md | CAPS.md | `--naming lowercase` |
| Link descriptions | Include/omit descriptions | Include | `--links minimal` |
| Quick references | Include/omit quick refs | Include | `--links descriptions-only` |

**Link Style Examples**:
```markdown
# With descriptions (default)
See [Testing Standards](../../../TESTING.md) for test configuration, commands, and CI/CD.

# Minimal
See [Testing Standards](../../../TESTING.md).

# With quick reference (default)
Quick reference: Run tests with `npm test`
See [Testing Standards](../../../TESTING.md) for complete documentation.
```

### Applying Preferences

**Standard Mode**: Preferences apply when user accepts cleanup prompt
**Cleanup Mode**: Preferences always applied
**Preview**: Use `--dry-run` to see impact before applying

```bash
# Default balanced extraction
/setup --cleanup

# Aggressive extraction with custom directory
/setup --cleanup --threshold aggressive --target-dir=documentation/

# Preview conservative extraction
/setup --cleanup --dry-run --threshold conservative
```

---

## Extraction Preview (--dry-run)

Preview extraction changes without modifying files. Helpful for planning, understanding impact, and team review.

### Usage

```bash
# Preview cleanup extraction
/setup --cleanup --dry-run [project-directory]

# Requires --cleanup mode
/setup --dry-run              # Error: requires --cleanup
/setup --analyze --dry-run    # Error: dry-run only with cleanup
```

### Preview Output

Shows for each extraction candidate:
- Section name, current line count, target file
- Rationale (why it qualifies for extraction)
- Impact (lines saved, % reduction)
- Content summary

**Interactive Selection**: Even in dry-run, you can toggle selections, preview different combinations, and see updated impact calculations.

**Comparison**: Generate preview with `/setup --cleanup --dry-run > preview.txt`, then run actual cleanup and compare results.

### Example Preview Output

```
=== Extraction Preview ===

CLAUDE.md: 310 lines

Extraction Candidates (--threshold balanced, >30 lines):

1. Testing Standards (52 lines) → docs/TESTING.md
   Rationale: Detailed test configuration exceeds threshold
   Impact: -52 lines (16.8% reduction)
   Content: Test commands, framework setup, CI/CD integration

2. Code Style Guide (38 lines) → docs/CODE_STYLE.md
   Rationale: Formatting rules and examples exceed threshold
   Impact: -38 lines (12.3% reduction)
   Content: Indentation, naming, error handling patterns

3. Architecture Diagram (44 lines) → docs/ARCHITECTURE.md
   Rationale: Complex ASCII diagrams exceed threshold
   Impact: -44 lines (14.2% reduction)
   Content: System architecture, data flow, component relationships

Total Impact: 310 → 176 lines (43.2% reduction)

No files will be modified (dry-run mode)
```

### Workflow Integration

**Planning Phase**:
1. Run dry-run to preview changes
2. Review extraction candidates and impact
3. Adjust threshold if needed
4. Run actual cleanup when satisfied

**Team Review**:
1. Generate preview output: `/setup --cleanup --dry-run > extraction-plan.txt`
2. Share with team for feedback
3. Adjust preferences based on feedback
4. Apply cleanup: `/setup --cleanup`

**Iterative Refinement**:
```bash
# Try different thresholds
/setup --cleanup --dry-run --threshold aggressive    # See maximum extraction
/setup --cleanup --dry-run --threshold balanced      # See default extraction
/setup --cleanup --dry-run --threshold conservative  # See minimal extraction

# Choose preferred threshold and apply
/setup --cleanup --threshold balanced
```

---

## Optimal CLAUDE.md Structure

### Goal: Command-Parseable Standards File

```markdown
# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index.

## Code Standards
[Used by: /implement, /refactor, /plan]

### General Principles
- **Indentation**: [detected or user-specified]
- **Line Length**: [detected or default]
- **Naming**: [language-appropriate conventions]
- **Error Handling**: [language-specific patterns]

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
[How commands should find tests]

### [Project Type] Testing
- **Test Commands**: [detected test commands]
- **Test Pattern**: [detected test file patterns]
- **Coverage Requirements**: [suggested thresholds]

## Documentation Policy
[Used by: /document, /plan]

### README Requirements
[Standard requirements for documentation]

## Standards Discovery
[Used by: all commands]

### Discovery Method
[Standard discovery explanation]

## Specs Directory Protocol
[Kept inline - essential for spec workflow]
```

### Structure Benefits

**For Commands**:
- Parseable sections with `[Used by: ...]` metadata
- Consistent field format: `**Field**: value`
- Predictable section organization

**For Humans**:
- Quick navigation with clear hierarchy
- Essential information readily visible
- Detailed docs linked when needed
- Manageable file size for easy scanning

**For Maintenance**:
- Clear separation of concerns
- Smaller diffs in version control
- Easier to update specific topics
- Reduced merge conflicts

---

## See Also

- [Setup Command Guide](../../commands/setup-command-guide.md) - Main setup documentation
- [Setup Modes](setup-modes-detailed.md) - Command mode details
- [Standards Analysis](standards-analysis.md) - Analysis and report application
- [Bloat Detection](bloat-detection.md) - Automatic optimization detection
