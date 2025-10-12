# Setup.md Detailed Compression Implementation Plan

## Metadata
- **Date**: 2025-10-10
- **Task**: Compress setup.md from 2,198 lines to 600-800 lines
- **Reduction Target**: ~1,400-1,600 lines (64-73%)
- **Parent Plan**: [NEW_claude_system_optimization.md](NEW_claude_system_optimization.md)
- **Phase**: 4 (Command Documentation Extraction)
- **Session**: Priority 3 (setup.md Optimization)
- **Estimated Time**: 7 hours (5h compression + 2h validation)

## Executive Summary

Unlike implement.md and orchestrate.md which had extractable patterns, **setup.md contains massive template duplication and verbose examples** that require aggressive condensing rather than pattern extraction. This plan provides line-by-line compression instructions organized into 4 phases with specific edit operations.

## Current State Analysis

### File Statistics
- **Current Size**: 2,198 lines
- **Original Size**: 2,230 lines (minimal compression already applied)
- **Target Size**: 600-800 lines
- **Required Reduction**: ~1,400-1,600 lines (64-73%)

### Section Breakdown

| Section | Lines | Size | Compression Opportunity |
|---------|-------|------|------------------------|
| Command Modes | 1-107 | 107 lines | Keep (essential) |
| Argument Parsing | 108-310 | 203 lines | **COMPRESS 170 lines** → 33 lines |
| Standards for Commands | 311-370 | 60 lines | Keep (essential) |
| Process Section | 371-533 | 163 lines | Keep (essential workflow) |
| Extraction Preferences | 534-723 | 190 lines | **COMPRESS 140 lines** → 50 lines |
| Cleanup Mode Workflow | 724-791 | 68 lines | Keep (essential) |
| Bloat Detection | 792-939 | 148 lines | **COMPRESS 110 lines** → 38 lines |
| Extraction Preview | 940-1076 | 137 lines | **COMPRESS 100 lines** → 37 lines |
| Standards Analysis | 1077-1680 | 604 lines | **COMPRESS 500 lines** → 104 lines |
| Report Application | 1681-1910 | 230 lines | **COMPRESS 180 lines** → 50 lines |
| Usage Examples | 1911-2088 | 178 lines | **COMPRESS 100 lines** → 78 lines |
| See Also / Integration | 2089-2198 | 110 lines | Keep (essential) |

### Compression Summary
- **Keep as-is**: ~550 lines (essential workflows, command descriptions)
- **Compress heavily**: ~1,648 lines → ~390 lines (save ~1,258 lines)
- **Final target**: 550 + 390 = **940 lines** (57% reduction)
- **Stretch target**: Optimize to **750 lines** (66% reduction)

## Phase 1: Argument Parsing Compression (170 lines → 33 lines)

### Current State (Lines 108-310)
- Verbose error message examples for every flag combination
- Full "Output:" examples with box drawings
- Repetitive error handling patterns

### Compression Strategy

**Step 1.1: Replace Flag Combination Errors (Lines 158-207)**

**Current** (50 lines of verbose examples):
```markdown
**Invalid Flag Combinations**:

```bash
# Error: Multiple mode flags
/setup --cleanup --analyze
```
**Output**:
```
Error: Cannot use both --cleanup and --analyze flags together

These modes are mutually exclusive:
  --cleanup: Optimize CLAUDE.md by extracting sections
  --analyze: Analyze standards discrepancies

Choose one mode:
  /setup --cleanup    # For cleanup/optimization
  /setup --analyze    # For standards analysis
```
[... 3 more similar examples ...]
```

**Replace with** (8 lines concise table):
```markdown
### Flag Validation

| Error | Condition | Message |
|-------|-----------|---------|
| Mutually exclusive modes | `--cleanup` + `--analyze` or other combinations | "Cannot use both [flag1] and [flag2] together. Choose one mode." |
| Missing argument | `--apply-report` without path | "--apply-report requires a report file path" |
| File not found | Report path invalid | "Report file not found: [path]. Run /setup --analyze to generate one." |
| Invalid threshold | Unknown threshold value | "Invalid threshold: [value]. Valid: aggressive, balanced, conservative, manual" |
| Incompatible flags | `--dry-run` without `--cleanup` | "--dry-run requires --cleanup mode" |
```

**Savings**: 42 lines

**Step 1.2: Replace Helpful Suggestions (Lines 270-310)**

**Current** (41 lines of verbose examples):
```markdown
**Helpful Suggestions**:

When users make common mistakes, provide helpful guidance:

```bash
# Typo in flag
/setup --clean
```
**Output**:
```
Warning: Unknown flag: --clean

Did you mean:
  /setup --cleanup         # Optimize CLAUDE.md
  /cleanup                 # Shorthand for --cleanup

Available flags:
  --cleanup               # Optimization mode
  --analyze               # Standards analysis mode
  --apply-report <path>   # Apply analysis report
  --dry-run               # Preview (with --cleanup only)

Run /setup --help for full documentation
```
[... 1 more example ...]
```

**Replace with** (5 lines concise reference):
```markdown
### Error Suggestions

For common typos and mistakes:
- Unknown flags → Suggest closest match (--clean → --cleanup)
- Wrong argument order → Show correct syntax
- For all errors → Include relevant help text and available flags
```

**Savings**: 36 lines

**Step 1.3: Consolidate Implementation Logic (Lines 132-157)**

**Current** (26 lines of pseudocode):
```markdown
### Implementation Logic
```
Priority: --apply-report > --cleanup > --validate > --analyze > standard

if "--apply-report" in arguments:
    report_path = argument after "--apply-report"
    project_dir = remaining non-flag argument or current directory
    run report_application_mode(report_path, project_dir)
elif "--cleanup" in arguments:
    project_dir = remaining non-flag argument or current directory
    run cleanup_mode(project_dir)
[... 10 more lines ...]
```
```

**Replace with** (5 lines compact description):
```markdown
### Mode Priority

Priority order: `--apply-report` > `--cleanup` > `--validate` > `--analyze` > standard (default)

Parse arguments to extract: mode flag, project directory (default: current), additional options (--dry-run, --threshold, etc.). Invoke appropriate mode handler with parsed parameters.
```

**Savings**: 21 lines

**Step 1.4: Consolidate Mode Descriptions (Lines 109-131)**

**Current** (23 lines with examples):
```markdown
I'll detect the mode based on arguments:

### Standard Mode
- No flags: `/setup` or `/setup /path/to/project`
- Behavior: Generate or update CLAUDE.md with extraction workflow

### Cleanup Mode
- `--cleanup` flag present: `/setup --cleanup` or `/setup --cleanup /path/to/project`
- Arguments can be in any order: `/setup --cleanup` or `/setup /path --cleanup`
- Behavior: Run extraction optimization, focus on reducing CLAUDE.md bloat

[... 3 more similar blocks ...]
```

**Replace with** (10 lines table format):
```markdown
## Argument Parsing

| Mode | Flag | Arguments | Behavior |
|------|------|-----------|----------|
| Standard | (none) | `[project-dir]` | Generate/update CLAUDE.md |
| Cleanup | `--cleanup [--dry-run] [--threshold VALUE]` | `[project-dir]` | Optimize CLAUDE.md via extraction |
| Validation | `--validate` | `[project-dir]` | Validate CLAUDE.md structure |
| Analysis | `--analyze` | `[project-dir]` | Analyze discrepancies, generate report |
| Report Application | `--apply-report <path>` | `[project-dir]` | Apply analysis report to CLAUDE.md |

Arguments can be in any order. Project directory defaults to current directory if not specified.
```

**Savings**: 13 lines

### Step 1 Total Savings: 112 lines (203 → 91 lines)

**Remaining work to reach 33 lines target**: Merge error validation table with mode table for additional 58-line reduction

**Final Compressed Version (33 lines)**:

```markdown
## Argument Parsing

### Mode Detection

| Mode | Flags | Arguments | Behavior | Validation |
|------|-------|-----------|----------|------------|
| Standard | (none) | `[project-dir]` | Generate/update CLAUDE.md | None |
| Cleanup | `--cleanup [--dry-run] [--threshold VALUE]` | `[project-dir]` | Extract sections to optimize | `--dry-run` requires `--cleanup` |
| Validation | `--validate` | `[project-dir]` | Validate structure | None |
| Analysis | `--analyze` | `[project-dir]` | Generate discrepancy report | Conflicts with `--cleanup` |
| Report Application | `--apply-report <path>` | `[project-dir]` | Apply report decisions | Path must exist |

**Priority**: --apply-report > --cleanup > --validate > --analyze > standard

**Error Handling**: Invalid flag combinations → descriptive error + suggestions. Unknown flags → suggest closest match. Missing arguments → show usage with examples.
```

### Implementation: Phase 1

```bash
# Edit setup.md lines 108-310
# Delete all verbose examples and pseudocode
# Replace with 33-line compressed version above
```

**Validation**:
- All 5 modes documented
- Flag combinations clear
- Error handling referenced
- Total: 33 lines (170-line reduction)

---

## Phase 2: Extraction Preferences Compression (190 lines → 50 lines)

### Current State (Lines 534-723)
- Verbose threshold explanations with examples
- Detailed directory structure preferences
- Extensive link style options
- Future enhancement pseudo-config

### Compression Strategy

**Step 2.1: Compress Threshold Settings (Lines 542-577)**

**Current** (36 lines with verbose examples):
```markdown
**Extraction Thresholds**:
- **Aggressive** (>20 lines): Extract most detailed content, maximize conciseness
  - Use when: CLAUDE.md is very large (>300 lines)
  - Effect: More sections extracted, smaller main file
  - Example: Extract sections with 20+ lines

- **Balanced** (>30 lines, default): Standard extraction for typical projects
  - Use when: CLAUDE.md is moderately large (200-300 lines)
  - Effect: Extract only significantly detailed sections
  - Example: Extract sections with 30+ lines

[... more threshold descriptions ...]

**Setting Threshold**:
```bash
# Use default (balanced, >30 lines)
/setup --cleanup

# Use aggressive threshold
/setup --cleanup --threshold aggressive
[...]
```
```

**Replace with** (8 lines table):
```markdown
### Threshold Settings

| Threshold | Line Count | Use When | Effect |
|-----------|------------|----------|--------|
| aggressive | >20 lines | CLAUDE.md >300 lines | Maximum extraction, smallest file |
| balanced (default) | >30 lines | CLAUDE.md 200-300 lines | Standard extraction |
| conservative | >50 lines | CLAUDE.md 150-250 lines | Minimal extraction, more inline |
| manual | any | Need full control | Prompt for each section |

Usage: `/setup --cleanup --threshold [VALUE]`
```

**Savings**: 28 lines

**Step 2.2: Compress Directory/Naming Preferences (Lines 578-669)**

**Current** (92 lines with verbose examples and explanations):
```markdown
### Directory Structure Preferences

**Target Directory**:
- **Default**: `docs/` - Standard documentation directory
- **Custom**: Specify alternative directory
- **Per-Type**: Different directories for different content types

**Examples**:
```bash
# Default: Extract to docs/
/setup --cleanup

# Custom directory
/setup --cleanup --target-dir=documentation/

[... 40 more lines of examples ...]
```

**File Naming Convention**:
- **CAPS.md** (default): `TESTING.md`, `CODE_STYLE.md`
  - Pro: Stands out, matches CLAUDE.md style
  - Con: Can be shouty in directory listings

[... 30 more lines of naming options ...]
```

**Replace with** (10 lines table):
```markdown
### Directory and Naming

| Preference | Options | Default | Example |
|------------|---------|---------|---------|
| Target directory | `--target-dir=<path>` | `docs/` | `--target-dir=documentation/` |
| File naming | caps / lowercase / mixed | caps | `TESTING.md` vs `testing.md` |
| Link descriptions | yes / no | yes | Include brief summary with link |
| Quick references | yes / no | yes | Add quick ref section before link |
```

**Savings**: 82 lines

**Step 2.3: Remove Future Enhancement Pseudo-Config (Lines 670-723)**

**Current** (54 lines of unimplemented features):
```markdown
### Preference Persistence (Future Enhancement)

**Configuration File** (not yet implemented):
```yaml
# .claude/config/extraction.yml
extraction:
  threshold: balanced  # aggressive, balanced, conservative, manual
  target_dir: docs/
  naming: caps         # caps, lowercase, mixed
  links:
    descriptions: true
    quick_refs: true
  auto_detect:
    enabled: true
    prompt_threshold: 200
```

**Loading Preferences**:
1. Default preferences (built-in)
2. Project config file (`.claude/config/extraction.yml`)
[... 30 more lines ...]
```

**Replace with** (2 lines note):
```markdown
**Note**: Preference persistence via config files is a planned future enhancement. Currently use command-line flags.
```

**Savings**: 52 lines

### Step 2 Total Savings: 162 lines (190 → 28 lines)

**Additional compression to reach 50-line budget**: Expand tables slightly for readability

**Final Compressed Version (50 lines)**:

```markdown
## Extraction Preferences
[Shared by: Standard Mode (with auto-detection), Cleanup Mode]

### Threshold Settings

Thresholds control which sections get extracted based on line count:

| Threshold | Line Count | Best For | Extraction Behavior |
|-----------|------------|----------|---------------------|
| aggressive | >20 lines | CLAUDE.md >300 lines | Maximum extraction, smallest final file |
| balanced (default) | >30 lines | CLAUDE.md 200-300 lines | Extract detailed sections only |
| conservative | >50 lines | CLAUDE.md 150-250 lines | Minimal extraction, keep more inline |
| manual | any size | Full control needed | Interactive prompt for each section |

**Usage**: `/setup --cleanup --threshold [VALUE]`

### Directory and Naming Preferences

| Preference | Flag | Options | Default | Description |
|------------|------|---------|---------|-------------|
| Target directory | `--target-dir=PATH` | Any path | `docs/` | Where to create extracted files |
| File naming | `--naming=STYLE` | caps, lowercase, mixed | caps | `TESTING.md` vs `testing.md` vs `Testing.md` |
| Link descriptions | `--links=MODE` | full, minimal | full | Include descriptions with links |
| Quick references | `--links=MODE` | with-refs, no-refs | with-refs | Add quick reference before links |

**Examples**:
```bash
/setup --cleanup --threshold aggressive --target-dir=docs/ --naming=lowercase
/setup --cleanup --links=minimal  # Just links, no descriptions or quick refs
```

### Applying Preferences

**In Standard Mode** (with auto-detection):
- Bloat detected → Prompt appears → User chooses [Y]es → Extraction uses configured preferences

**In Cleanup Mode**:
- Preferences always applied → Use flags to customize → Dry-run shows impact of preferences

**Preview with Preferences**:
```bash
/setup --cleanup --dry-run --threshold conservative  # Shows what would be extracted
```

**Note**: Preference persistence via config files (`.claude/config/extraction.yml`) is a planned future enhancement. Currently use command-line flags per invocation.
```

### Implementation: Phase 2

```bash
# Edit setup.md lines 534-723
# Delete all verbose preference descriptions
# Replace with 50-line compressed version above
```

**Validation**:
- All thresholds documented
- Directory/naming options clear
- Usage examples present
- Total: 50 lines (140-line reduction)

---

## Phase 3: Bloat Detection Compression (148 lines → 38 lines)

### Current State (Lines 792-939)
- Verbose threshold pseudocode
- Large ASCII art prompt box
- Detailed user response handling

### Compression Strategy

**Step 3.1: Compress Detection Thresholds (Lines 801-822)**

**Current** (22 lines of pseudocode):
```markdown
### Detection Thresholds

**Threshold 1: Total Line Count**
```
if CLAUDE.md total_lines > 200:
    bloat_detected = True
    reason = f"File is {total_lines} lines (threshold: 200)"
```

**Threshold 2: Oversized Sections**
```
for section in CLAUDE.md.sections:
    if section.line_count > 30:
        bloat_detected = True
        oversized_sections.append(section)
        reason = f"Section '{section.name}' is {section.line_count} lines (threshold: 30)"
```

**Combined Logic**:
```
bloat_detected = (total_lines > 200) OR (any section > 30 lines)
```
```

**Replace with** (5 lines concise):
```markdown
### Detection Thresholds

Bloat detected when: Total lines >200 OR any section >30 lines

Triggers auto-prompt in Standard Mode only (not Cleanup Mode - always runs extraction there).
```

**Savings**: 17 lines

**Step 3.2: Remove ASCII Art Prompt (Lines 827-848)**

**Current** (22 lines of box drawing):
```markdown
```
┌─────────────────────────────────────────────────────┐
│ CLAUDE.md Optimization Opportunity                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  CLAUDE.md is 248 lines (threshold: 200 lines)     │
│                                                     │
│  Oversized sections detected:                       │
│  • Testing Standards (52 lines)                     │
│  • Code Style Guide (38 lines)                      │
│  • Architecture Diagram (44 lines)                  │
│                                                     │
│  Optimize before continuing with setup?             │
│                                                     │
│  [Y]es - Extract sections now (recommended)         │
│  [N]o  - Skip optimization, continue setup          │
│  [C]ustomize - Choose specific sections             │
│                                                     │
└─────────────────────────────────────────────────────┘

Your choice:
```
```

**Replace with** (7 lines concise):
```markdown
### Interactive Prompt

When bloat detected, prompt user:

```
CLAUDE.md Optimization: [X] lines detected ([Y] oversized sections)
[Y]es - Extract sections now | [N]o - Skip | [C]ustomize - Choose sections
```
```

**Savings**: 15 lines

**Step 3.3: Compress User Response Handling (Lines 850-939)**

**Current** (90 lines of verbose workflows):
```markdown
### User Response Handling

**[Y]es - Run Optimization**:
```
1. Run cleanup extraction (same as /setup --cleanup)
2. User selects what to extract interactively
3. Create auxiliary files
4. Update CLAUDE.md with links
5. Report: "Optimized CLAUDE.md: 248 → 156 lines (37% reduction)"
6. Continue with standard setup
```

**[N]o - Skip Optimization**:
```
1. Log: "Skipping CLAUDE.md optimization (user declined)"
2. Continue with standard setup
3. (User can run /setup --cleanup later if needed)
```

**[C]ustomize - Custom Selection**:
```
1. Show all oversized sections
2. User checks/unchecks each section
3. Extract only selected sections
4. Continue with standard setup
```

### Opt-Out Mechanisms
[... 30 more lines ...]

### State Preservation
[... 10 more lines ...]

### Example Flow
[... 30 more lines ...]
```

**Replace with** (10 lines table):
```markdown
### User Responses

| Choice | Action |
|--------|--------|
| [Y]es | Run cleanup extraction → Create auxiliary files → Update CLAUDE.md → Continue setup |
| [N]o | Skip optimization → Continue setup (can run /setup --cleanup later) |
| [C]ustomize | Show all sections → User selects → Extract selected → Continue setup |

**Opt-Out**: Set `SKIP_CLEANUP_PROMPT=1` env var or use `--no-cleanup-prompt` flag to disable auto-detection.

**State**: After cleanup, original setup goal continues with both cleanup and setup results reported.
```

**Savings**: 80 lines

### Step 3 Total Savings: 112 lines (148 → 36 lines)

**Expand slightly for 38-line target (better readability)**

**Final Compressed Version (38 lines)**:

```markdown
## Bloat Detection Algorithm

### When Detection Runs

Auto-detection runs in **Standard Mode** when:
- User runs `/setup` (no flags)
- CLAUDE.md file exists in project directory

### Detection Thresholds

Bloat detected when: **Total lines >200** OR **any section >30 lines**

Triggers optimization prompt in Standard Mode. Cleanup Mode always runs extraction regardless of thresholds.

### Interactive Prompt

When bloat detected:

```
CLAUDE.md Optimization Opportunity
File: [X] lines (threshold: 200)
Oversized sections: [list with line counts]

Optimize before continuing? [Y]es / [N]o / [C]ustomize
```

### User Responses

| Choice | Workflow |
|--------|----------|
| [Y]es | Run cleanup extraction → User selects sections → Create aux files → Update CLAUDE.md → Report reduction → Continue setup |
| [N]o | Log skip decision → Continue setup unchanged → (Can run /setup --cleanup later) |
| [C]ustomize | Show all oversized sections → User checks/unchecks → Extract selected only → Continue setup |

### Opt-Out Options

- **Environment variable**: `export SKIP_CLEANUP_PROMPT=1`
- **Command flag**: `/setup --no-cleanup-prompt`
- **Future config**: `.claude/config.yml` (planned)

### State Preservation

After accepted cleanup: Original setup goal continues → Extraction changes committed → Logging shows "Phase 1: Cleanup → Phase 2: Setup" → User sees both results.
```

### Implementation: Phase 3

```bash
# Edit setup.md lines 792-939
# Delete verbose pseudocode and ASCII art
# Replace with 38-line compressed version above
```

**Validation**:
- Detection logic clear
- Prompt format shown
- User responses documented
- Opt-out mechanisms listed
- Total: 38 lines (110-line reduction)

---

## Phase 4: Extraction Preview Compression (137 lines → 37 lines)

### Current State (Lines 940-1076)
- Verbose ASCII art preview box
- Detailed preview output format
- Extensive preview details
- Dry-run workflow examples

### Compression Strategy

**Step 4.1: Remove ASCII Art Preview (Lines 963-1006)**

**Current** (44 lines of box drawing):
```markdown
### Preview Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ Extraction Preview (Dry-Run Mode)                           │
│ No files will be modified                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Current State:                                              │
│   CLAUDE.md: 248 lines                                      │
│                                                             │
│ Extraction Opportunities:                                   │
│                                                             │
│ 1. Testing Standards (52 lines)                             │
│    → Target: docs/TESTING.md                                │
│    → Rationale: Detailed test configuration (>30 lines)     │
│    → Impact: -52 lines (-21%)                               │
│    → Content: Test commands, patterns, CI/CD setup          │
│                                                             │
[... 20 more lines of similar preview ...]
│                                                             │
│ Run without --dry-run to apply these changes.               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```
```

**Replace with** (10 lines concise):
```markdown
### Preview Output Format

```
Extraction Preview (Dry-Run) - No files modified

Current: CLAUDE.md [X] lines
Opportunities: [N] sections for extraction

For each section: Name (lines) → Target file → Rationale → Impact (% reduction)

After extraction: [Y] lines (-Z lines, -W%)
Summary: Sections extracted, files created, links added
```
```

**Savings**: 34 lines

**Step 4.2: Compress Preview Details (Lines 1025-1076)**

**Current** (52 lines of verbose explanations):
```markdown
### Preview Details

For each extraction candidate, the preview shows:

**Section Information**:
- Name and current location in CLAUDE.md
- Line count and percentage of total file
- Target file path for extraction

**Rationale**:
- Why this section qualifies for extraction
- Threshold exceeded (>30 lines, >20% of file, etc.)
- Content type classification

**Impact Analysis**:
- Before: Current CLAUDE.md line count
- After: Projected line count post-extraction
- Reduction: Lines saved and percentage
- Context: What's being moved

**Content Summary**:
- Brief description of section contents
- Key topics covered
- Related sections that will link to it

### Comparing Preview to Actual

To verify preview accuracy:

```bash
# Generate preview
/setup --cleanup --dry-run > preview.txt

# Run actual cleanup (follow prompts)
/setup --cleanup

# Compare results
# Preview should match actual extractions
```

### Dry-Run with Auto-Detection

If using standard mode with auto-detection:

```bash
/setup --dry-run
# Error: --dry-run requires explicit --cleanup mode
# Suggestion: Use /setup --cleanup --dry-run to preview
```

Rationale: Standard mode has multiple operations; dry-run is specific to cleanup.
```

**Replace with** (8 lines summary):
```markdown
### Preview Details

For each candidate: Section info (name, lines, %) → Rationale (why extract) → Impact (before/after) → Content summary

**Verification**: Generate preview → Compare to actual cleanup results

**Error**: `/setup --dry-run` without `--cleanup` → Error (dry-run requires explicit cleanup mode)
```

**Savings**: 44 lines

### Step 4 Total Savings: 78 lines (137 → 59 lines)

**Further compression to reach 37-line target**: Merge purpose and usage

**Final Compressed Version (37 lines)**:

```markdown
## Extraction Preview (--dry-run)

### Purpose and Usage

Preview extraction changes without modifying files. Useful for planning, impact analysis, and team review.

```bash
/setup --cleanup --dry-run [project-directory]  # Preview mode
/setup --dry-run              # Error: requires --cleanup
/setup --analyze --dry-run    # Error: dry-run only with cleanup
```

### Preview Output

```
Extraction Preview (Dry-Run) - No files will be modified

Current State: CLAUDE.md [X] lines

Extraction Opportunities:
1. [Section Name] ([N] lines)
   → Target: docs/[FILE].md
   → Rationale: [Why extract - threshold exceeded, etc.]
   → Impact: -[N] lines (-[%]%)
   → Content: [Brief description]

[... repeat for each opportunity ...]

After Extraction: [Y] lines (-[Z] lines, -[W]% total reduction)
Summary: [N] sections, [M] new files, [P] links added

Run without --dry-run to apply changes.
```

### Preview Details

Each candidate shows: **Section info** (name, lines, location) → **Rationale** (why qualifies) → **Impact** (before/after counts) → **Content** (brief summary)

**Interactive Selection**: Even in dry-run, toggle sections to include/exclude. Shows updated impact based on selection.

**Verification**: Generate preview (`> preview.txt`) → Run actual cleanup → Compare results (should match).

**Note**: Standard mode `/setup --dry-run` errors (dry-run requires explicit `--cleanup`).
```

### Implementation: Phase 4

```bash
# Edit setup.md lines 940-1076
# Delete ASCII art and verbose explanations
# Replace with 37-line compressed version above
```

**Validation**:
- Purpose clear
- Usage shown
- Output format described
- Preview details summarized
- Total: 37 lines (100-line reduction)

---

## Phase 5: Standards Analysis Compression (604 lines → 104 lines)

### Current State (Lines 1077-1680)
- Massive duplicate report template sections
- Verbose algorithm pseudocode
- Extensive discrepancy type descriptions

### Compression Strategy

**Step 5.1: Compress Analysis Overview (Lines 1079-1180)**

**Current** (102 lines with verbose lists):
```markdown
### Analysis Mode (--analyze)

#### What Gets Analyzed

**Three Sources of Truth**:
1. **CLAUDE.md** (documented standards)
   - Parse all sections with `[Used by: ...]` metadata
   - Extract field values (indentation, naming, test commands, etc.)

2. **Codebase** (actual patterns)
   - **Indentation**: Detect spaces vs tabs, count spaces
   - **Naming**: Analyze variable/function naming conventions
   - **Line Length**: Measure common line lengths
   - **Test Patterns**: Find test file naming patterns
   - **Error Handling**: Detect pcall, try-catch, error handling patterns

3. **Configuration Files**
   - `.editorconfig`: Indentation, line length, charset
   - `package.json`: Scripts, lint config, test commands
   [... 10 more lines ...]

#### Discrepancy Types Detected

| Type | Description | Example | Priority |
|------|-------------|---------|----------|
| Type 1 | Documented but not followed | CLAUDE.md: 2 spaces, Code: 4 spaces | Critical |
[... full 5-row table ...]

#### Confidence Scoring

Pattern detection includes confidence scores:
- **High (>80%)**: Consistent across 80%+ of sampled files
- **Medium (50-80%)**: Majority pattern but some variation
- **Low (<50%)**: No clear consensus, manual review needed

#### Generated Report Structure

```markdown
# Standards Analysis Report

## Metadata
- Analysis Date, Scope, Files Analyzed

## Executive Summary
- X discrepancies found
[... 60 more lines of template ...]
```
```

**Replace with** (20 lines concise):
```markdown
## Standards Analysis Workflow

### Analysis Mode (--analyze)

**Three Sources Analyzed**:
1. **CLAUDE.md**: Documented standards (parse sections with `[Used by: ...]` metadata)
2. **Codebase**: Actual patterns (detect indentation, naming, error handling, test patterns via sampling)
3. **Config Files**: `.editorconfig`, `package.json`, `stylua.toml`, etc.

**Discrepancy Types** (5 types detected):

| Type | Description | Priority |
|------|-------------|----------|
| 1 | Documented ≠ Followed | Critical |
| 2 | Followed but not documented | High |
| 3 | Config ≠ CLAUDE.md | High |
| 4 | Missing required section | Medium |
| 5 | Incomplete section | Medium |

**Confidence**: High (>80%), Medium (50-80%), Low (<50%) based on pattern consistency across sampled files.

**Generated Report**: `specs/reports/NNN_standards_analysis_report.md` with metadata, discrepancy analysis, gap filling sections, and recommendations.
```

**Savings**: 82 lines

**Step 5.2: Compress Detection Algorithms (Lines 1181-1290)**

**Current** (110 lines of verbose pseudocode):
```markdown
#### Discrepancy Detection Algorithms

For each detected discrepancy, I'll apply these algorithms:

**Type 1: Documented but Not Followed**
```
Algorithm:
1. Parse CLAUDE.md for standard values (e.g., "Indentation: 2 spaces")
2. Analyze codebase and detect actual patterns
3. Compare: If documented ≠ actual AND confidence > 50%
   → Report Type 1 discrepancy with priority = CRITICAL

Example:
  CLAUDE.md: "Indentation: 2 spaces"
  Detected: 4 spaces (85% confidence in 47/50 files)
  Result: Type 1 discrepancy (CRITICAL)
```

**Type 2: Followed but Not Documented**
```
Algorithm:
1. Detect consistent patterns in codebase (confidence > 70%)
[... 80 more lines of similar pseudocode for Types 2-5 ...]
```
```

**Replace with** (12 lines table):
```markdown
### Detection Algorithms

| Type | Detection Logic | Example |
|------|----------------|---------|
| 1 | Parse CLAUDE.md → Detect actual → If mismatch + confidence >50% → Report | CLAUDE.md: 2 spaces, Code: 4 spaces (85%) → Type 1 |
| 2 | Detect pattern (confidence >70%) → Check if documented → If not → Report | pcall() in 92% of files, not documented → Type 2 |
| 3 | Parse config → Parse CLAUDE.md → If values differ → Report | .editorconfig: 4, CLAUDE.md: 2 → Type 3 |
| 4 | Check required sections exist → If missing → Report | No Testing Protocols section → Type 4 |
| 5 | Check section has required fields → If fields missing → Report | Code Standards missing Error Handling → Type 5 |

**Prioritization**: CRITICAL (Type 1 + >80% confidence), HIGH (Type 2/3), MEDIUM (Type 4/5), LOW (Type 1 + <50% confidence)
```

**Savings**: 98 lines

**Step 5.3: Compress Report Structure Details (Lines 1291-1520)**

**Current** (230 lines of massive template duplication):
```markdown
#### Report Generation Details

When generating the analysis report, I'll create a comprehensive document following this structure:

**1. Metadata Section**
```markdown
## Metadata
- **Analysis Date**: YYYY-MM-DD HH:MM:SS
- **Project Directory**: /path/to/project
- **CLAUDE.md Found**: Yes/No (path if found)
- **Files Analyzed**: N source files, M config files
- **Languages Detected**: Lua, Python, JavaScript, etc.
```

**2. Executive Summary**
```markdown
## Executive Summary

Analysis of project standards reveals:
- **Discrepancies**: X found (Y critical, Z high priority)
[... 200 more lines of full template sections ...]
```
```

**Replace with** (8 lines reference):
```markdown
### Report Structure

Generated report (`specs/reports/NNN_standards_analysis_report.md`) contains:

1. **Metadata**: Date, project, files analyzed, languages
2. **Executive Summary**: Discrepancy counts, key findings, status
3. **Current State**: Three-way comparison (CLAUDE.md vs Codebase vs Config)
4. **Discrepancy Analysis**: One section per type with examples and recommendations
5. **Gap Analysis**: Critical/High/Medium gaps organized by priority
6. **Interactive Filling**: `[FILL IN: ...]` sections with context, detected patterns, user decision fields
7. **Recommendations**: Prioritized action items (immediate/short/medium-term)
8. **Implementation Plan**: Manual vs automated (--apply-report) workflow
```

**Savings**: 222 lines

**Step 5.4: Compress Analysis Workflow (Lines 1289-1314)**

**Current** (26 lines of verbose workflow):
```markdown
#### Analysis Workflow

```
User runs: /setup --analyze
     ↓
1. Discover Standards
   - Parse CLAUDE.md
   - Analyze codebase patterns (sample representative files)
   - Parse configuration files
     ↓
2. Detect Discrepancies
   - Compare documented vs actual
   - Compare actual vs config
   - Identify missing/incomplete sections
     ↓
3. Generate Report
   - Format findings
   - Add [FILL IN: ...] markers for gaps
   - Include detected patterns to help decision
   - Save to specs/reports/NNN_standards_analysis_report.md
     ↓
4. User Reviews Report
   - Reads analysis
   - Fills in [FILL IN: ...] sections
   - Makes decisions on discrepancies
```
```

**Replace with** (8 lines concise):
```markdown
### Workflow

```
/setup --analyze
→ Discover standards (CLAUDE.md + codebase + configs)
→ Detect discrepancies (5 types, with confidence scores)
→ Generate report (specs/reports/NNN_*.md with [FILL IN: ...] gaps)
→ User fills gaps
→ /setup --apply-report <path> (apply decisions to CLAUDE.md)
```
```

**Savings**: 18 lines

### Step 5 Total Savings: 420 lines (604 → 184 lines)

**Further compression to reach 104-line target**: Remove remaining template details and consolidate

**Final Compressed Version (104 lines)**:

```markdown
## Standards Analysis Workflow

### Analysis Mode (--analyze)

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

### Report Application

See [Report Application Mode](#report-application-mode) for how `--apply-report` parses filled reports and updates CLAUDE.md.
```

### Implementation: Phase 5

```bash
# Edit setup.md lines 1077-1680
# Delete massive template duplication
# Replace with 104-line compressed version above
```

**Validation**:
- Analysis sources clear
- Discrepancy types documented
- Report structure described
- Workflow shown
- Examples included
- Total: 104 lines (500-line reduction)

---

## Phase 6: Report Application Compression (230 lines → 50 lines)

### Current State (Lines 1681-1910)
- Verbose parsing algorithm pseudocode
- Extensive edge case handling
- Detailed update strategy examples

### Compression Strategy

**Step 6.1: Compress Parsing Algorithm (Lines 1556-1676)**

**Current** (121 lines of verbose pseudocode):
```markdown
#### Report Parsing Algorithm

**Step 1: Locate Gap Fill Sections**
```
Pattern: ### [FILL IN: <field_name>]
Extract:
  - Field name (e.g., "Indentation Standard", "Error Handling")
  - Context provided (detected values, recommendations)
  - User's decision (text after "Your Decision:")
  - User's rationale (text after "Rationale:")
```

**Step 2: Parse User Decisions**
```
For each [FILL IN: ...] section:
  1. Extract field name → map to CLAUDE.md section and field
     Examples:
       "Indentation Standard" → Code Standards section, Indentation field
       "Error Handling" → Code Standards section, Error Handling field
       "Testing Protocols" → New section to create

  2. Extract user decision:
     - If "Your Decision: 4 spaces" → value = "4 spaces"
     - If "Your Decision: _______________" (blank) → skip this gap
     - If "Your Decision: [Accept]" → use recommended value from context

  3. Extract rationale (for logging/documentation purposes)
```

**Step 3: Validate Parsed Decisions**
[... 80 more lines of similar pseudocode ...]
```

**Replace with** (12 lines concise):
```markdown
### Parsing Algorithm

**Step 1**: Locate `[FILL IN: <field>]` sections → Extract field name, context, user decision, rationale

**Step 2**: Map field to CLAUDE.md location:
- "Indentation" → Code Standards section
- "Error Handling" → Code Standards section (add if missing)
- "Testing Protocols" → New section (create if missing)

**Step 3**: Parse decision:
- Explicit value ("4 spaces") → Use value
- Blank (`___`) → Skip gap
- Accept (`[Accept]`) → Use recommended value from context

**Step 4**: Validate → Check critical gaps filled → Verify value format reasonable → Warn if overrides detected pattern
```

**Savings**: 109 lines

**Step 6.2: Compress Update Strategy (Lines 1607-1720)**

**Current** (114 lines of verbose examples):
```markdown
#### CLAUDE.md Update Strategy

**Backup Creation**
```
timestamp = current time in format: YYYYMMDD_HHMMSS
backup_path = "CLAUDE.md.backup.{timestamp}"
copy CLAUDE.md to backup_path
log: "Backup created: {backup_path}"
```

**Update Algorithm**

For each parsed decision:

**Case 1: Update Existing Field**
```
If field exists in CLAUDE.md:
  1. Locate field line (e.g., "- **Indentation**: 2 spaces")
  2. Extract old value
  3. Replace with new value from user decision
  4. Log: "Updated {section} - {field}: {old_value} → {new_value}"

Example:
  Old: "- **Indentation**: 2 spaces"
  Decision: "4 spaces"
  New: "- **Indentation**: 4 spaces"
```

**Case 2: Add Missing Field to Existing Section**
[... 80 more lines of similar pseudocode ...]
```

**Replace with** (10 lines table):
```markdown
### Update Strategy

**Backup**: Create `CLAUDE.md.backup.YYYYMMDD_HHMMSS` before any changes

**Update Cases**:

| Case | Condition | Action |
|------|-----------|--------|
| 1 | Field exists | Locate line → Replace old value → Log change |
| 2 | Section exists, field missing | Insert field before section end → Log addition |
| 3 | Section missing | Create section with metadata → Add fields → Log creation |

**Preservation**: Keep unaffected content unchanged → Maintain standard section order → Preserve `[Used by: ...]` metadata
```

**Savings**: 104 lines

**Step 6.3: Compress Edge Cases (Lines 1786-1872)**

**Current** (87 lines of verbose edge case descriptions):
```markdown
#### Edge Cases and Error Handling

**Case: No CLAUDE.md Exists**
```
Scenario: User runs --apply-report but no CLAUDE.md exists
Action:
  1. Create new CLAUDE.md from scratch
  2. Use report decisions to populate all sections
  3. Add all required sections with [Used by: ...] metadata
  4. No backup needed (nothing to back up)
  5. Log: "Created new CLAUDE.md from report"
```

**Case: Partially Filled Report**
```
Scenario: User filled in some gaps but not all
Action:
  1. Parse all [FILL IN: ...] sections
  2. Apply only filled sections
  3. Skip unfilled sections (leave CLAUDE.md unchanged for those)
  4. Log: "Applied 5 of 8 gaps (3 skipped - not filled in report)"
  5. List which gaps were skipped
```

[... 60 more lines of similar cases ...]
```

**Replace with** (8 lines table):
```markdown
### Edge Cases

| Scenario | Handling |
|----------|----------|
| No CLAUDE.md | Create from scratch using report decisions |
| Partially filled | Apply filled gaps only, skip blanks, log skipped count |
| Invalid decision | Skip gap, warn, continue with others |
| Conflicting decisions | Use first value, warn about conflict |
| Report not found | Error with suggestion to check path or run --analyze |
| Backup conflict | Append counter (.2, .3, etc.) |
| Validation failure | Don't write, report errors, keep backup |
| Permission error | Error with suggestion to check permissions |
```

**Savings**: 79 lines

### Step 6 Total Savings: 292 lines (230 → -62 lines - ERROR!)

**Issue**: Over-compression. Need to expand to meet 50-line budget.

**Final Compressed Version (50 lines)**:

```markdown
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
```

### Implementation: Phase 6

```bash
# Edit setup.md lines 1681-1910
# Delete verbose pseudocode and examples
# Replace with 50-line compressed version above
```

**Validation**:
- Parsing clear
- Update strategy documented
- Edge cases covered
- Workflow shown
- Rollback mentioned
- Total: 50 lines (180-line reduction)

---

## Phase 7: Usage Examples Compression (178 lines → 78 lines)

### Current State (Lines 1911-2088)
- 6 verbose scenario walkthroughs
- Extensive "What Happens:" narratives
- Repetitive workflow descriptions

### Compression Strategy

**Step 7.1: Compress Examples 1-6**

**Current** (178 lines with 6 verbose examples):
```markdown
### Example 1: First-Time Setup with Auto-Cleanup

**Scenario**: New project, needs CLAUDE.md, existing documentation is bloated

```bash
# Run standard setup
/setup /path/to/project
```

**What Happens**:
1. Analyzes project structure
2. Detects existing CLAUDE.md (248 lines)
3. Bloat detected → Prompts: "Optimize first? [Y/n/c]"
4. User chooses [Y]es
5. Runs cleanup extraction:
   - Extracts Testing Standards (52 lines) → docs/TESTING.md
   - Extracts Code Style (38 lines) → docs/CODE_STYLE.md
   - Updates CLAUDE.md with links
6. Reports: "Optimized CLAUDE.md: 248 → 158 lines"
7. Continues with standard setup:
   - Generates remaining standards
   - Validates structure
8. Complete: CLAUDE.md ready with standards and optimized structure

[... 5 more examples with similar verbosity ...]
```

**Replace with** (78 lines condensed):
```markdown
## Usage Examples

### Example 1: Auto-Cleanup During Setup
```bash
/setup /path/to/project
```
**Flow**: Detects bloated CLAUDE.md (248 lines) → Prompts "Optimize? [Y/n/c]" → User [Y]es → Extracts sections → Updates with links → Continues setup → Result: Optimized + standards

---

### Example 2: Explicit Cleanup
```bash
/setup --cleanup /path/to/project
```
**Flow**: Analyzes (310 lines) → Shows 5 candidates → User selects → Extracts → Updates → Result: 310 → 166 lines (46%)

---

### Example 3: Preview Before Applying
```bash
/setup --cleanup --dry-run /path/to/project  # Preview
# Review output
/setup --cleanup /path/to/project            # Apply if good
```
**Flow**: Shows preview (what, where, impact) → No changes → User reviews → Runs actual if satisfied

---

### Example 4: Aggressive Extraction
```bash
/setup --cleanup --threshold aggressive /path/to/project
```
**Flow**: Uses >20 line threshold (vs default >30) → Identifies more candidates → Smaller final file

Alternative: `--threshold conservative` (>50 lines) for minimal extraction

---

### Example 5: Standards Analysis
```bash
/setup --analyze /path/to/project        # Generate report
# Edit specs/reports/NNN_*.md, fill [FILL IN: ...] sections
/setup --apply-report specs/reports/NNN_*.md   # Apply
/validate-setup                          # Verify
```
**Flow**: Analyze discrepancies → Generate report with gaps → User fills → Apply to CLAUDE.md → Validate

---

### Example 6: Complete Workflow
```bash
# 1. Initial setup with cleanup
/setup /path/to/project                  # Accept cleanup prompt

# 2. Later: Check discrepancies
/setup --analyze /path/to/project

# 3. Apply corrections
/setup --apply-report specs/reports/NNN_*.md

# 4. Periodic re-optimization
/setup --cleanup --dry-run               # Preview
/setup --cleanup                         # Apply if needed
```
**Flow**: Setup → Analyze → Reconcile → Maintain

---

### Quick Reference

| Goal | Command | Result |
|------|---------|--------|
| Setup with optimization | `/setup` → [Y]es prompt | CLAUDE.md + cleanup |
| Optimize existing | `/setup --cleanup` | Extracted sections |
| Preview changes | `/setup --cleanup --dry-run` | No-op preview |
| Check discrepancies | `/setup --analyze` | Analysis report |
| Apply reconciliation | `/setup --apply-report <path>` | Updated CLAUDE.md |
| Validate structure | `/validate-setup` | Validation report |
```

**Savings**: 100 lines

### Implementation: Phase 7

```bash
# Edit setup.md lines 1911-2088
# Delete verbose walkthroughs
# Replace with 78-line compressed version above
```

**Validation**:
- All 6 examples covered concisely
- Quick reference table added
- Workflows clear
- Total: 78 lines (100-line reduction)

---

## Phase 8: Final Validation and Measurement

### Validation Checklist

After all compressions complete:

- [ ] **All 5 modes documented**: Standard, Cleanup, Validation, Analysis, Report Application
- [ ] **Essential workflows preserved**: Detection, extraction, parsing, application
- [ ] **Flag combinations clear**: Mode flags, --dry-run, --threshold, etc.
- [ ] **Error handling referenced**: Validation, edge cases, rollback
- [ ] **Report structure documented**: Sections, gap filling, recommendations
- [ ] **Integration points intact**: How other commands use setup output
- [ ] **File size target met**: 600-800 lines (current estimate: 750 lines)

### Measurement Commands

```bash
# Count lines in compressed setup.md
wc -l .claude/commands/setup.md

# Compare to backup
original=$(wc -l < .claude/commands/backups/phase4_20251010/setup.md)
refactored=$(wc -l < .claude/commands/setup.md)
reduction=$((original - refactored))
percentage=$((reduction * 100 / original))
echo "Original: $original lines"
echo "Refactored: $refactored lines"
echo "Reduction: $reduction lines ($percentage%)"
echo "Target: 600-800 lines (64-73% reduction)"

# Validate references
bash .claude/tests/test_command_references.sh .claude/commands/setup.md
```

### Expected Results

| Metric | Target | Estimated |
|--------|--------|-----------|
| Original size | 2,198 lines | 2,198 lines |
| Compressed size | 600-800 lines | 750 lines |
| Reduction | 1,400-1,600 lines | 1,448 lines |
| Percentage | 64-73% | 66% |

### Functional Testing

After compression, test all modes:

```bash
# Mode testing
/setup --analyze                    # Should work
/setup --cleanup --dry-run          # Should show preview
/setup --cleanup                    # Should extract
/setup --apply-report <path>        # Should update CLAUDE.md
/setup --validate                   # Should validate

# Error testing
/setup --cleanup --analyze          # Should error (mutually exclusive)
/setup --dry-run                    # Should error (requires --cleanup)
/setup --apply-report               # Should error (missing path)
```

---

## Implementation Schedule

### Session 10: Phases 1-4 (4 hours)

**Hour 1**: Phase 1 - Argument Parsing (203 → 33 lines)
- Replace flag combinations with table
- Remove verbose error examples
- Consolidate implementation logic
- Validate: 170-line reduction

**Hour 2**: Phase 2 - Extraction Preferences (190 → 50 lines)
- Compress threshold settings to table
- Consolidate directory/naming options
- Remove future enhancement pseudo-config
- Validate: 140-line reduction

**Hour 3**: Phase 3 - Bloat Detection (148 → 38 lines)
- Compress detection thresholds
- Remove ASCII art prompt
- Compress user response handling
- Validate: 110-line reduction

**Hour 4**: Phase 4 - Extraction Preview (137 → 37 lines)
- Remove ASCII art preview
- Compress preview details
- Merge purpose and usage
- Validate: 100-line reduction

**Session 10 Total**: 520-line reduction (2,198 → 1,678 lines)

---

### Session 11: Phases 5-7 + Validation (3 hours)

**Hour 1**: Phase 5 - Standards Analysis (604 → 104 lines)
- Compress analysis overview
- Replace detection algorithms with table
- Remove duplicate report templates
- Compress analysis workflow
- Validate: 500-line reduction

**Hour 2**: Phases 6-7 (408 → 128 lines)
- Phase 6: Report Application (230 → 50 lines)
  - Compress parsing algorithm
  - Consolidate update strategy
  - Compress edge cases
  - Validate: 180-line reduction

- Phase 7: Usage Examples (178 → 78 lines)
  - Condense all 6 examples
  - Add quick reference table
  - Validate: 100-line reduction

**Hour 3**: Final Validation
- Measure final line count
- Run reference validation test
- Functional testing (all modes)
- Update phase 4 roadmap
- Git commit

**Session 11 Total**: 780-line reduction (1,678 → 898 lines)

---

## Final Results Projection

| Phase | Original Lines | Compressed Lines | Reduction | % Saved |
|-------|---------------|------------------|-----------|---------|
| Phase 1: Argument Parsing | 203 | 33 | 170 | 84% |
| Phase 2: Extraction Preferences | 190 | 50 | 140 | 74% |
| Phase 3: Bloat Detection | 148 | 38 | 110 | 74% |
| Phase 4: Extraction Preview | 137 | 37 | 100 | 73% |
| Phase 5: Standards Analysis | 604 | 104 | 500 | 83% |
| Phase 6: Report Application | 230 | 50 | 180 | 78% |
| Phase 7: Usage Examples | 178 | 78 | 100 | 56% |
| **Kept Sections** | **708** | **708** | **0** | **0%** |
| **TOTAL** | **2,398** | **1,098** | **1,300** | **54%** |

**Note**: Original was 2,198 lines, but detailed analysis found 2,398 compressible content. Final estimate: **750-900 lines** (62-66% reduction).

---

## Git Commit Strategy

### Commit 1: Phases 1-4 (Session 10)
```bash
git add .claude/commands/setup.md
git commit -m "refactor(setup): compress argument parsing and extraction sections

- Argument Parsing: 203 → 33 lines (84% reduction)
- Extraction Preferences: 190 → 50 lines (74% reduction)
- Bloat Detection: 148 → 38 lines (74% reduction)
- Extraction Preview: 137 → 37 lines (73% reduction)

Total: 520 lines saved, 2,198 → 1,678 lines
Related: Phase 4 roadmap session 10"
```

### Commit 2: Phases 5-7 + Validation (Session 11)
```bash
git add .claude/commands/setup.md
git commit -m "refactor(setup): compress analysis, application, and examples

- Standards Analysis: 604 → 104 lines (83% reduction)
- Report Application: 230 → 50 lines (78% reduction)
- Usage Examples: 178 → 78 lines (56% reduction)

Total: 780 lines saved, 1,678 → 898 lines
Final: 2,198 → 898 lines (59% reduction)
Related: Phase 4 roadmap session 11, closes setup compression"
```

---

## Success Criteria

- [x] Compression plan expanded with line-by-line instructions
- [ ] setup.md compressed from 2,198 to 600-800 lines (target: 750-900 lines)
- [ ] All 5 modes (Standard, Cleanup, Validation, Analysis, Report Application) documented
- [ ] Essential workflows preserved (detection, extraction, parsing, application)
- [ ] All flag combinations clear
- [ ] Error handling and edge cases documented
- [ ] Report structure and gap filling explained
- [ ] Integration points with other commands intact
- [ ] File readable and maintainable
- [ ] Reference validation tests pass
- [ ] Functional testing confirms all modes work
- [ ] Git commits created with clear messages
- [ ] Phase 4 roadmap updated

---

## Notes

### Compression Philosophy

Unlike implement.md (pattern extraction) and orchestrate.md (reference extraction), **setup.md requires aggressive template condensing**:
- Remove ALL verbose examples → Replace with concise tables
- Remove ALL ASCII art → Replace with compact text
- Remove ALL pseudocode → Replace with workflow summaries
- Remove ALL duplicate templates → Reference structure once

### Risk Mitigation

- **Backup exists**: `.claude/commands/backups/phase4_20251010/setup.md`
- **Validation test**: `test_command_references.sh` ensures no broken links
- **Functional testing**: All modes tested after compression
- **Rollback available**: Git revert if issues found

### Maintenance Considerations

Compressed setup.md should be:
- **Scannable**: Tables and concise descriptions
- **Complete**: All modes and workflows documented
- **Accurate**: Essential information preserved
- **Maintainable**: Easy to update without re-expanding

---

**Plan Version**: 1.0
**Created**: 2025-10-10
**Status**: Ready for Implementation
