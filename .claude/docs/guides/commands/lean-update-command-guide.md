# /lean-update Command Guide

## Overview

The `/lean-update` command automates maintenance documentation updates for Lean theorem proving projects. It scans source trees for sorry placeholders, calculates module completion percentages, validates cross-references, and synchronizes a six-document ecosystem used for project maintenance.

**Target Projects**: Lean 4 projects with structured maintenance documentation

**Time Savings**: Reduces manual maintenance from 30-60 minutes to ~5 minutes per update cycle

## Modes and Options

### Scan Mode (Default)

Updates all maintenance documents based on current project state.

```bash
/lean-update
```

**Behavior**:
- Scans Lean source for sorry placeholders
- Counts sorries by module
- Updates SORRY_REGISTRY.md, IMPLEMENTATION_STATUS.md, and other docs
- Validates cross-references between documents
- Creates git snapshot before updates

### Verify Mode

Checks cross-reference integrity without modifying files.

```bash
/lean-update --verify
```

**Behavior**:
- Analyzes maintenance documents
- Validates bidirectional links
- Checks for broken file references
- Reports validation errors
- **No files are modified**

### Build Mode

Includes `lake build` and `lake test` verification.

```bash
/lean-update --with-build
```

**Behavior**:
- Performs standard scan mode updates
- Runs `lake build` (timeout: 5 minutes)
- Runs `lake test` (timeout: 5 minutes)
- Reports build/test status in summary

### Dry-Run Mode

Previews changes without applying updates.

```bash
/lean-update --dry-run
```

**Behavior**:
- Analyzes project and generates update recommendations
- Shows what would be updated
- **No files are modified**
- **No git snapshot created**

### Combined Modes

Flags can be combined:

```bash
# Preview with build verification
/lean-update --with-build --dry-run

# Verify cross-references and run build
/lean-update --verify --with-build
```

## Lean Project Detection

The command automatically detects Lean projects by searching upward from the current directory for:

1. `lakefile.toml` (Lean 4 build configuration)
2. `lean-toolchain` (Lean version pinning)

**Detection Behavior**:
- Searches parent directories until project root found
- Sets `PROJECT_ROOT` to directory containing lakefile.toml or lean-toolchain
- Fails if neither file found

**Example Project Structure**:
```
ProofChecker/
├── lakefile.toml          # Detected as Lean project
├── lean-toolchain
├── Logos/Core/            # Source code
│   ├── Syntax/
│   ├── ProofSystem/
│   └── Metalogic/
└── Documentation/
    └── ProjectInfo/       # Maintenance docs
```

## Maintenance Document Discovery

The command discovers maintenance documents using these heuristics:

### Required Documents

Must exist or command fails:
- `TODO.md` (project root)
- `CLAUDE.md` (project root)

### Optional Documents

Discovered if they exist:
- `SORRY_REGISTRY.md`
- `IMPLEMENTATION_STATUS.md`
- `KNOWN_LIMITATIONS.md`
- `MAINTENANCE.md`

### Discovery Locations

Searches in order:
1. `Documentation/ProjectInfo/` (ProofChecker structure)
2. `docs/` (common alternative)
3. Project root (fallback)

**Note**: If optional documents don't exist, the command continues but only updates available files.

## Sorry Detection Methodology

### Module-Based Scanning

The command uses grep to count sorry placeholders:

```bash
# Count sorries in each module
grep -rn "sorry" Logos/Core/Syntax/ | wc -l
grep -rn "sorry" Logos/Core/Metalogic/ | wc -l
```

### Module Detection

Automatically detects module structure:

1. **Modular Projects**: If subdirectories found under source directory, each is treated as a module
2. **Flat Projects**: If no subdirectories, counts all sorries together

### Completion Percentage Calculation

```
completion_percent = ((total_theorems - sorry_count) / total_theorems) * 100
```

**Example**:
- Module has 30 theorems/functions
- 12 have sorry placeholders
- Completion: (30 - 12) / 30 = 60%

### Verification

Sorry counts are verified against SORRY_REGISTRY.md:
- Warns if counts differ by more than 3
- Allows small variance for detection differences
- Uses actual grep count as canonical source

## Six-Document Ecosystem

### Document Relationships

```
                    ┌─────────────────┐
                    │   TODO.md       │
                    │  (Active Work)  │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌──────────────┐  ┌─────────────┐  ┌──────────────┐
    │ IMPL STATUS  │  │   SORRY      │  │   KNOWN      │
    │ (Module %)   │◄─┤  REGISTRY    │─►│ LIMITATIONS  │
    │              │  │ (Tech Debt)  │  │ (Gaps)       │
    └──────────────┘  └─────────────┘  └──────────────┘
            │                │                │
            └────────────────┼────────────────┘
                             │
                    ┌────────▼────────┐
                    │  MAINTENANCE.md │
                    │   (Workflow)    │
                    └─────────────────┘
```

### TODO.md (Active Work)

**Purpose**: Track active tasks, priorities, and project status

**Updated Sections**:
- Task status (compare with git log)
- Priority classifications
- Cross-references to other docs

**Preserved Sections**:
- `## Backlog` (manually prioritized tasks)
- `## Saved` (intentionally demoted tasks)

### SORRY_REGISTRY.md (Technical Debt)

**Purpose**: Track sorry placeholders in Lean source code

**Updated Sections**:
- Active placeholders (module-by-module)
- Sorry counts per module
- File paths and line numbers

**Preserved Sections**:
- `## Resolved Placeholders` (historical record)

**Format**:
```markdown
## Active Placeholders

### Metalogic (15 sorries)

- **Logos/Core/Metalogic/Completeness.lean:45** - `completeness_proof` - Placeholder for completeness theorem proof
- **Logos/Core/Metalogic/Soundness.lean:120** - `soundness_auxiliary_lemma` - Helper lemma needed
```

### IMPLEMENTATION_STATUS.md (Module Progress)

**Purpose**: High-level module completion tracking

**Updated Sections**:
- Module completion percentages
- "What Works" vs "What's Partial" categorization
- Sorry verification commands

**Preserved Sections**:
- Lines with `<!-- MANUAL -->` comment (manual annotations)

**Example**:
```markdown
## Module Status

- **Syntax**: 100% complete (0 sorries)
- **ProofSystem**: 100% complete (0 sorries)
- **Metalogic**: 60% complete (15 sorries) <!-- MANUAL: Needs completeness theorem -->
```

### KNOWN_LIMITATIONS.md (User-Facing Gaps)

**Purpose**: Document known limitations and gaps requiring user awareness

**Updated Sections**:
- Gaps linked to sorry placeholders
- Cross-references to SORRY_REGISTRY.md

**Preserved Sections**:
- Workaround details marked with `<!-- MANUAL -->`

### MAINTENANCE.md (Workflow Documentation)

**Purpose**: Document maintenance workflow and procedures

**Updated Sections**:
- Related documentation links
- Document synchronization requirements

**Preserved Sections**:
- Custom procedures marked with `<!-- CUSTOM -->`

**Rarely Updated**: Only when workflow procedures change

### CLAUDE.md (Project Configuration)

**Purpose**: Central project configuration for AI assistants

**Updated Sections**:
- Documentation index
- Quick reference links

**Preserved Sections**:
- Project-specific standards marked with `<!-- CUSTOM -->`

## Multi-File Update Workflow

### Update Sequence

1. **Git Snapshot**: Create recovery point before any modifications
2. **Analysis**: Generate update recommendations via lean-maintenance-analyzer
3. **Verification**: Validate analysis report structure and content
4. **Preservation**: Extract manually-curated sections before updates
5. **Updates**: Apply changes atomically per file
6. **Verification**: Confirm preservation sections unchanged
7. **Cross-References**: Validate bidirectional links

### Atomic Updates

Each file is updated atomically:

```bash
# Create temporary file with updates
temp_file=$(mktemp)
apply_updates "$original_file" > "$temp_file"

# Verify preservation sections
verify_preservation "$original_file" "$temp_file"

# Atomic replacement
mv "$temp_file" "$original_file"
```

### Rollback on Failure

If any update fails:
- Atomic updates prevent partial corruption
- Git snapshot enables full recovery
- Error logged to error tracking system

## Preservation Policies

### Why Preservation Matters

Maintenance documents contain both:
- **Auto-generated content**: Sorry counts, module completion, cross-references
- **Manual curation**: Strategic decisions, custom priorities, workarounds

Preservation ensures manual work isn't overwritten.

### Preservation Mechanisms

| Document | Preserved Sections | Detection Method |
|----------|-------------------|------------------|
| TODO.md | Backlog, Saved | Section headings (`## Backlog`, `## Saved`) |
| SORRY_REGISTRY.md | Resolved Placeholders | Section heading (`## Resolved Placeholders`) |
| IMPLEMENTATION_STATUS.md | Manual annotations | Inline comment (`<!-- MANUAL -->`) |
| KNOWN_LIMITATIONS.md | Workaround details | Inline comment (`<!-- MANUAL -->`) |
| MAINTENANCE.md | Custom procedures | Inline comment (`<!-- CUSTOM -->`) |
| CLAUDE.md | Project standards | Inline comment (`<!-- CUSTOM -->`) |

### Example: TODO.md Preservation

**Before Update**:
```markdown
## Backlog

- [ ] Implement advanced proof automation tactics (low priority, saved for v2.0)
- [ ] Add GUI for proof visualization (nice-to-have)

## Saved

- [ ] Refactor parser (postponed - current parser works)
```

**After Update**:
- Active tasks section regenerated from project scan
- Backlog section **unchanged** (preserved verbatim)
- Saved section **unchanged** (preserved verbatim)

### Preservation Verification

After each file update:

```bash
# Extract preserved section from original
ORIGINAL_SECTION=$(sed -n '/^## Backlog/,/^## /p' "$ORIGINAL_FILE")

# Extract same section from updated file
NEW_SECTION=$(sed -n '/^## Backlog/,/^## /p' "$UPDATED_FILE")

# Verify unchanged
if [ "$ORIGINAL_SECTION" != "$NEW_SECTION" ]; then
  echo "ERROR: Preserved section modified"
  rollback_update
fi
```

## Cross-Reference Validation

### Bidirectional Link Verification

The command validates that cross-references are bidirectional:

**Rule**: If document A references document B, then B should reference A

**Example**:
```markdown
# TODO.md
See [SORRY_REGISTRY.md](Documentation/ProjectInfo/SORRY_REGISTRY.md) for technical debt.

# SORRY_REGISTRY.md
Related tasks in [TODO.md](../../TODO.md).
```

### Validation Checks

1. **TODO.md ↔ SORRY_REGISTRY.md**: Active tasks reference technical debt
2. **SORRY_REGISTRY.md ↔ IMPLEMENTATION_STATUS.md**: Sorry counts align with module status
3. **SORRY_REGISTRY.md ↔ KNOWN_LIMITATIONS.md**: Gaps linked to sorries
4. **MAINTENANCE.md**: References all other maintenance docs

### Broken Reference Detection

Checks for:
- Links to non-existent files
- Links to deleted sections
- Malformed relative paths

**Example Warning**:
```
⚠️  Warning: Broken reference in CLAUDE.md: Documentation/Old/Removed.md
```

### Section Structure Validation

Verifies each document maintains required sections:

- TODO.md: Overview, High Priority, Medium Priority, Low Priority, Backlog, Saved
- SORRY_REGISTRY.md: Active Placeholders, Resolved Placeholders
- IMPLEMENTATION_STATUS.md: Module Status, What Works, What's Partial

## Build Verification

### When to Use --with-build

Use build verification when:
- After major source changes
- Before creating a release
- Validating maintenance doc accuracy
- Investigating discrepancies between docs and source

**Trade-off**: Adds 2-10 minutes to command execution time

### Build Process

```bash
# Run lake build (timeout: 5 minutes)
lake build

# Run lake test (timeout: 5 minutes)
lake test
```

### Build Status Reporting

Build/test results included in summary:

```
Build Verification:
  • Build: passed
  • Tests: passed (48/48 tests)
```

### Failure Handling

If build fails:
- **Documentation updates still applied** (build failure doesn't block docs)
- Build failure reported in summary
- Logged to error tracking system
- User can investigate source issues separately

## Error Recovery

### Git Snapshot Recovery

Every scan mode run creates a git snapshot before updates:

```bash
# View changes since snapshot
git diff <snapshot-hash>

# Restore specific file
git restore --source=<snapshot-hash> -- Documentation/ProjectInfo/SORRY_REGISTRY.md

# Restore entire Documentation directory
git restore --source=<snapshot-hash> -- Documentation/
```

**Snapshot Commit Message**:
```
Snapshot before /lean-update (lean_update_1234567890)
```

### Manual Recovery

If git snapshot unavailable:
1. Locate backup files (if created): `.backup` extension
2. Compare with git log to find last known good state
3. Manually revert changes

### Prevention

Best practices to minimize recovery needs:
- Use `--dry-run` first to preview changes
- Review git diff after updates
- Keep Backlog and Saved sections current before running command
- Run `--verify` periodically to catch issues early

## Troubleshooting

### "Not a Lean project" Error

**Symptom**:
```
Error: Not a Lean project. No lakefile.toml or lean-toolchain found.
```

**Solution**:
- Ensure you're in a Lean project directory
- Check for `lakefile.toml` or `lean-toolchain` in project root
- If subproject, navigate to project root first

### "Documentation directory not found" Error

**Symptom**:
```
Error: Cannot locate documentation directory.
```

**Solution**:
- Create `Documentation/ProjectInfo/` directory
- Or create `docs/` directory
- Or place maintenance docs in project root

### "TODO.md not found" Error

**Symptom**:
```
Error: TODO.md not found at /path/to/project/TODO.md
```

**Solution**:
- Create TODO.md in project root
- Use `/todo` command to generate initial TODO.md structure

### Sorry Count Mismatch Warning

**Symptom**:
```
⚠️  Warning: Sorry count mismatch for module 'Metalogic'
    Scan count: 15, Agent count: 12
```

**Cause**: Agent may use different detection heuristics

**Solution**:
- If variance small (±3), generally safe to ignore
- If variance large, investigate:
  - Check for commented-out sorries
  - Check for sorries in strings or documentation
  - Manually verify with `grep -rn "sorry" Logos/Core/Metalogic/`

### Cross-Reference Validation Warnings

**Symptom**:
```
⚠️  Found 2 validation warnings
⚠️  Warning: SORRY_REGISTRY.md does not reference TODO.md
```

**Solution**:
- Add missing cross-references manually
- Ensure bidirectional links between documents
- Use `--verify` mode to check before applying updates

### Build Timeout

**Symptom**:
```
✗ Build failed (timeout after 300 seconds)
```

**Solution**:
- Build timeout set to 5 minutes
- If project requires longer build:
  - Build separately: `lake build`
  - Skip build verification (omit `--with-build`)
- Investigate build performance issues

## Examples

### Basic Usage

```bash
# Navigate to Lean project
cd ~/Projects/ProofChecker

# Run standard update
/lean-update
```

**Output**:
```
⚙️  /lean-update Command - Mode: scan

🔍 Detecting Lean project...
   ✓ Lean project detected: /home/user/Projects/ProofChecker

🔍 Discovering maintenance documents...
   ✓ Documentation directory: /home/user/Projects/ProofChecker/Documentation/ProjectInfo
   ✓ Found: SORRY_REGISTRY.md
   ✓ Found: IMPLEMENTATION_STATUS.md
   ✓ Found: KNOWN_LIMITATIONS.md
   ✓ Found: MAINTENANCE.md

🔍 Scanning for sorry placeholders...
   ✓ Found Lean source directories: /home/user/Projects/ProofChecker/Logos/Core
   ✓ Module 'Syntax': 0 sorry placeholders
   ✓ Module 'ProofSystem': 0 sorry placeholders
   ✓ Module 'Metalogic': 15 sorry placeholders
   ✓ Module 'Theorems': 8 sorry placeholders

...

═══════════════════════════════════════════════════════════════
   /lean-update Command Summary
═══════════════════════════════════════════════════════════════

📊 Summary
───────────────────────────────────────────────────────────────
Mode: Full documentation update
Files updated: 3

Sorry Placeholder Summary:
  • Syntax: 0 sorry placeholders
  • ProofSystem: 0 sorry placeholders
  • Metalogic: 15 sorry placeholders
  • Theorems: 8 sorry placeholders

✓ Cross-reference validation: All checks passed
```

### Dry-Run Preview

```bash
# Preview changes before applying
/lean-update --dry-run
```

**Use Case**: Before committing updates, preview to ensure preservation sections won't be affected

### Verify-Only Mode

```bash
# Check cross-references without updates
/lean-update --verify
```

**Use Case**: Periodic health check of documentation ecosystem

### Full Verification

```bash
# Complete verification including build/test
/lean-update --with-build
```

**Use Case**: Pre-release validation of project state

### Recovery After Bad Update

```bash
# Run update
/lean-update

# Oh no, something looks wrong!
# View what changed
git diff abc123def  # Use snapshot hash from summary

# Restore previous state
git restore --source=abc123def -- Documentation/

# Or restore specific file
git restore --source=abc123def -- Documentation/ProjectInfo/SORRY_REGISTRY.md
```

## Integration with Other Commands

### With /todo Command

`/todo` maintains `.claude/TODO.md` (project infrastructure)
`/lean-update` maintains project-level `TODO.md` (Lean project tasks)

**Different Scopes**: Commands operate on different TODO.md files

### With /implement Command

After implementation phase:

```bash
# Complete implementation
/implement my-plan.md

# Update maintenance docs
cd ~/Projects/ProofChecker
/lean-update
```

### With Git Workflow

```bash
# Before starting work
/lean-update --verify

# Make changes to Lean source
...

# After completing work
/lean-update
git add Documentation/
git commit -m "Update maintenance docs after [feature]"
```

## Performance Characteristics

**Typical Execution Time**:
- Small project (<1000 lines): 5-10 seconds
- Medium project (<10,000 lines): 10-30 seconds
- Large project (>10,000 lines): 30-60 seconds

**With --with-build**:
- Add 2-10 minutes depending on project size

**Bottlenecks**:
- Sorry scanning (grep on large codebases)
- Build verification (if enabled)
- Git log queries (if many commits)

## Best Practices

### When to Run /lean-update

**Recommended Frequency**:
- After completing a module or major feature
- Before creating a release or milestone
- After resolving multiple sorry placeholders
- Weekly for active development projects

**Avoid**:
- During active development (too frequent)
- Immediately after modifying Backlog/Saved sections

### Maintaining Preservation Sections

**Best Practice**:
1. Manually curate Backlog and Saved sections thoughtfully
2. Use `<!-- MANUAL -->` comments for annotations you want preserved
3. Run `--dry-run` before applying to verify preservation

**Example**:
```markdown
## Module Status

- **Metalogic**: 60% complete (15 sorries) <!-- MANUAL: Blocked on theorem prover performance -->
```

### Cross-Reference Maintenance

**Best Practice**:
- When creating new maintenance docs, add cross-references to existing docs
- Use relative paths for portability
- Validate with `--verify` before committing

### Git Workflow Integration

**Recommended Pattern**:
```bash
# Start of work session
/lean-update --verify  # Check current state

# Do work
...

# End of work session
/lean-update           # Update docs
git add Documentation/
git commit -m "Update maintenance docs after [work]"
```

## Command Reference Quick Link

See [Command Reference](.claude/docs/reference/standards/command-reference.md) for complete command catalog.
