# /optimize-claude Command Guide

> **Command File**: [.claude/commands/optimize-claude.md](../../commands/optimize-claude.md)

## Overview

The `/optimize-claude` command analyzes your CLAUDE.md file and .claude/docs/ directory structure to generate an optimization plan. It uses a multi-stage agent workflow to identify bloated sections, find integration opportunities, and create a detailed implementation plan.

## Usage

### Basic Usage

```bash
/optimize-claude  # Simple, no flags needed
```

### Advanced Usage

```bash
/optimize-claude [--threshold <aggressive|balanced|conservative>]
                 [--aggressive|--balanced|--conservative]
                 [--dry-run]
                 [--file <report-path>] ...
```

### Flags

- `--threshold <value>`: Set bloat detection threshold
  - `aggressive`: >50 lines (strict bloat detection)
  - `balanced`: >80 lines (default, recommended)
  - `conservative`: >120 lines (lenient, for complex domains)
- `--aggressive`: Shorthand for `--threshold aggressive`
- `--balanced`: Shorthand for `--threshold balanced`
- `--conservative`: Shorthand for `--threshold conservative`
- `--dry-run`: Preview workflow stages without execution
- `--file <path>`: Add additional report to research phase (can be used multiple times)

### Examples

```bash
# Use aggressive threshold for strict bloat detection
/optimize-claude --aggressive

# Preview workflow without execution
/optimize-claude --dry-run

# Include additional analysis reports
/optimize-claude --file .claude/specs/analysis_report.md

# Combine multiple flags
/optimize-claude --conservative --file report1.md --file report2.md
```

## Workflow

The command uses a three-stage agent workflow:

```
┌────────────────────────────────┐
│ /optimize-claude               │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Stage 1: Parallel Research     │
│ • claude-md-analyzer           │
│ • docs-structure-analyzer      │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Stage 2: Plan Generation       │
│ • cleanup-plan-architect       │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ Display Results                │
│ • Show plan location           │
│ • Show next steps              │
└────────────────────────────────┘
```

### Stage 1: Parallel Research

Two specialized agents run in parallel:

1. **claude-md-analyzer** (.claude/agents/claude-md-analyzer.md)
   - Analyzes CLAUDE.md structure using existing optimize-claude-md.sh library
   - Identifies bloated sections (>80 lines with balanced threshold)
   - Detects metadata gaps ([Used by: ...] tags)
   - Generates section analysis table with recommendations

2. **docs-structure-analyzer** (.claude/agents/docs-structure-analyzer.md)
   - Discovers .claude/docs/ directory layout
   - Identifies existing documentation categories
   - Finds integration points for CLAUDE.md extractions
   - Detects gaps (missing files) and overlaps (duplicate content)

### Stage 2: Plan Generation

One planning agent synthesizes research:

3. **cleanup-plan-architect** (.claude/agents/cleanup-plan-architect.md)
   - Reads both research reports
   - Matches bloated sections to appropriate .claude/docs/ locations
   - Generates /implement-compatible plan with:
     - Backup phase (Phase 1)
     - Extraction phases (one per bloated section)
     - Verification phase (final phase with rollback procedure)

### Stage 3: Results Display

The command displays:
- Location of both research reports
- Location of implementation plan
- Next steps command: `/implement [PLAN_PATH]`

No interactive prompts - user reviews plan manually before running /implement.

## What Gets Analyzed

### CLAUDE.md Structure

- **Section sizes**: Line counts per section
- **Bloat detection**: Sections >80 lines flagged (balanced threshold)
- **Metadata usage**: [Used by: ...] tag presence
- **Complexity scores**: Based on section content and cross-references

### .claude/docs/ Organization

- **Directory layout**: Tree structure of all categories
- **Existing files**: Complete file inventory with descriptions
- **Integration points**: Natural homes for CLAUDE.md extractions
- **Gap analysis**: Missing documentation files
- **Overlap detection**: Duplicate content between CLAUDE.md and docs/

## Output Artifacts

All artifacts saved in topic-based directory: `.claude/specs/optimize_claude_{TIMESTAMP}/`

### Research Reports

1. **CLAUDE.md analysis** (`reports/001_claude_md_analysis.md`)
   - Section analysis table
   - Extraction candidates with line ranges
   - Integration point suggestions
   - Metadata gap list

2. **Docs structure analysis** (`reports/002_docs_structure_analysis.md`)
   - Directory tree
   - Category analysis (concepts/, guides/, reference/, etc.)
   - Integration points per category
   - Gap analysis (missing files)
   - Overlap detection (duplicates)

### Implementation Plan

**Optimization plan** (`plans/001_optimization_plan.md`)
- Metadata (research reports referenced)
- Overview (extraction strategy)
- Phase 1: Backup and preparation
- Phase 2-N: Section extractions (one per bloated section)
- Phase N+1: Verification and rollback
- Success criteria
- Rollback procedure

Plan format compatible with `/implement` command (phases with checkbox tasks).

## Example Output

```
=== /optimize-claude: CLAUDE.md Optimization Workflow ===

Research Stage: Analyzing CLAUDE.md and documentation...
  → Topic: .claude/specs/optimize_claude_1234567890
  → Analyzing CLAUDE.md structure (balanced threshold: 80 lines)
  → Analyzing .claude/docs/ organization

✓ CLAUDE.md analysis: .claude/specs/optimize_claude_1234567890/reports/001_claude_md_analysis.md
✓ Docs structure analysis: .claude/specs/optimize_claude_1234567890/reports/002_docs_structure_analysis.md

Planning Stage: Generating optimization plan...

✓ Implementation plan: .claude/specs/optimize_claude_1234567890/plans/001_optimization_plan.md

=== Optimization Plan Generated ===

Research Reports:
  • CLAUDE.md analysis: .claude/specs/optimize_claude_1234567890/reports/001_claude_md_analysis.md
  • Docs structure analysis: .claude/specs/optimize_claude_1234567890/reports/002_docs_structure_analysis.md

Implementation Plan:
  • .claude/specs/optimize_claude_1234567890/plans/001_optimization_plan.md

Next Steps:
  Review the plan and run: /implement .claude/specs/optimize_claude_1234567890/plans/001_optimization_plan.md
```

## Implementation Workflow

After `/optimize-claude` completes:

1. **Review the plan**
   ```bash
   cat .claude/specs/optimize_claude_*/plans/001_optimization_plan.md
   ```

2. **Review research reports** (optional, for detailed analysis)
   ```bash
   cat .claude/specs/optimize_claude_*/reports/001_claude_md_analysis.md
   cat .claude/specs/optimize_claude_*/reports/002_docs_structure_analysis.md
   ```

3. **Run implementation**
   ```bash
   /implement .claude/specs/optimize_claude_*/plans/001_optimization_plan.md
   ```

4. **Verify optimization** (automatic in plan's final phase)
   - `/setup --validate` checks CLAUDE.md structure
   - `.claude/scripts/validate-links-quick.sh` checks links
   - Tests verify command discovery still works

## Thresholds and Configuration

### Threshold Profiles

The command supports three threshold profiles for bloat detection:

#### Aggressive (50 lines)

```bash
/optimize-claude --aggressive
```

- **Bloated**: Sections >50 lines → Extract to .claude/docs/
- **Moderate**: Sections 30-50 lines → Consider extraction
- **Optimal**: Sections <30 lines → Keep inline

**Use when**:
- CLAUDE.md is very large (>500 lines)
- You want maximum extraction for minimal inline content
- Documentation is complex and needs extensive detail

#### Balanced (80 lines, default)

```bash
/optimize-claude --balanced  # or just /optimize-claude
```

- **Bloated**: Sections >80 lines → Extract to .claude/docs/
- **Moderate**: Sections 50-80 lines → Consider extraction
- **Optimal**: Sections <50 lines → Keep inline

**Use when**:
- CLAUDE.md is moderate size (200-500 lines)
- You want good balance between inline and extracted content
- This is the recommended default for most projects

#### Conservative (120 lines)

```bash
/optimize-claude --conservative
```

- **Bloated**: Sections >120 lines → Extract to .claude/docs/
- **Moderate**: Sections 80-120 lines → Consider extraction
- **Optimal**: Sections <80 lines → Keep inline

**Use when**:
- CLAUDE.md is relatively small (<300 lines)
- Sections have complex interdependencies
- You prefer more content inline for discoverability

### Why These Thresholds?

- Fits ~2 screens of terminal output
- Leaves room for summaries (2-3 sentences + link)
- Balances context overhead vs reference jumping
- Matches optimize-claude-md.sh library default

### Dry-Run Mode

Preview the workflow without executing agents:

```bash
/optimize-claude --dry-run
```

**Output includes**:
- Workflow stages (Research, Analysis, Planning)
- Agents that will be invoked
- Current threshold configuration
- Additional reports (if any)
- Artifact paths that will be created
- Estimated execution time (3-5 minutes)

**Use dry-run when**:
- Verifying threshold settings before execution
- Checking which agents will be invoked
- Previewing artifact paths
- Understanding workflow stages

### Additional Reports

Include extra analysis reports for enhanced context:

```bash
/optimize-claude --file .claude/specs/analysis_report.md
/optimize-claude --file report1.md --file report2.md --file report3.md
```

**How it works**:
- Reports are validated (must exist) during setup
- Report paths are passed to docs-structure-analyzer agent
- Agent incorporates findings into research analysis
- Useful for iterative optimization with prior analysis

**Example use cases**:
- Including previous optimization reports for delta analysis
- Adding custom analysis from manual review
- Incorporating external documentation audits
- Building on prior /research command outputs

## Troubleshooting

### Issue: Command fails with "CLAUDE.md not found"

**Cause**: Running from incorrect directory or CLAUDE.md doesn't exist

**Solution**:
```bash
# Run from project root
cd /path/to/project
/optimize-claude

# Or ensure CLAUDE.md exists
test -f CLAUDE.md && echo "Found" || echo "Missing"
```

### Issue: Agents fail to create reports

**Cause**: Agent execution error or permission issues

**Solution**:
1. Check agent logs in command output for error details
2. Verify .claude/agents/ files exist:
   ```bash
   ls -l .claude/agents/claude-md-analyzer.md
   ls -l .claude/agents/docs-structure-analyzer.md
   ls -l .claude/agents/cleanup-plan-architect.md
   ```
3. Verify libraries are sourced correctly:
   ```bash
   bash -n .claude/lib/util/optimize-claude-md.sh
   bash -n .claude/lib/core/unified-location-detection.sh
   ```

### Issue: Plan has no optimization recommendations

**Cause**: Your CLAUDE.md may already be well-optimized for current threshold

**Solution**:
1. Check CLAUDE.md analysis report for bloated sections
2. If no sections exceed threshold, try a more aggressive setting:
   ```bash
   /optimize-claude --aggressive  # 50-line threshold
   ```
3. If still no recommendations, your CLAUDE.md is already optimal

### Issue: Verification fails after implementation

**Cause**: Broken links, missing summaries, or incomplete extractions

**Solution**:
1. Use rollback procedure from plan:
   ```bash
   BACKUP_FILE=".claude/backups/CLAUDE.md.YYYYMMDD-HHMMSS"
   cp "$BACKUP_FILE" CLAUDE.md
   ```
2. Review extraction phase that failed
3. Re-run that phase manually with corrections

### Issue: Agent timeout during execution

**Cause**: Large CLAUDE.md or complex .claude/docs/ structure

**Solution**:
1. Check if agents are still running:
   ```bash
   ps aux | grep claude
   ```
2. Increase timeout if available in future versions
3. Break into smaller operations (analyze CLAUDE.md separately from docs)

### Issue: Reports are created but contain no content

**Cause**: Agents completed but analysis found no issues

**Solution**:
1. Check report files directly:
   ```bash
   cat .claude/specs/[topic]/reports/*.md
   ```
2. If truly empty, CLAUDE.md may be optimal
3. Verify .claude/docs/ directory exists and has content to analyze

### Issue: False positive bloat detection

**Cause**: Threshold too aggressive for your use case

**Solution**:
1. Use conservative threshold for lenient bloat detection:
   ```bash
   /optimize-claude --conservative  # 120-line threshold
   ```
2. Review bloat criteria in analysis report
3. Some projects benefit from larger inline CLAUDE.md sections

### Issue: claude-md-analyzer agent fails with parse error

**Cause**: CLAUDE.md has malformed sections or invalid metadata

**Solution**:
1. Validate CLAUDE.md structure first:
   ```bash
   /setup --validate
   ```
2. Check for unmatched brackets or malformed `[Used by: ...]` metadata
3. Fix structural issues before re-running optimization

### Issue: docs-structure-analyzer finds no documentation

**Cause**: No .claude/docs/ directory or documentation not in standard format

**Solution**:
1. Check if docs exist:
   ```bash
   find .claude/docs -name "*.md" -type f
   ```
2. Create basic documentation structure if missing
3. Ensure READMEs follow expected format (see setup-command-guide.md)

### Issue: cleanup-plan-architect fails to generate plan

**Cause**: Analysis reports missing or incomplete

**Solution**:
1. Verify all prior agents completed successfully
2. Check for completion markers in command output
3. Re-run from beginning if any agent failed:
   ```bash
   /optimize-claude
   ```

### Issue: bloat-analyzer detects everything as bloated

**Cause**: Very low threshold or genuinely bloated documentation

**Solution**:
1. Review analysis report line counts
2. If sections are >150 lines, bloat detection is likely correct
3. Prioritize highest-impact extractions first

### Issue: accuracy-analyzer has low confidence scores

**Cause**: Inconsistent documentation or limited sample size

**Solution**:
1. Review accuracy report for specific inconsistencies
2. Fix flagged issues manually
3. Re-run analysis after improvements:
   ```bash
   /optimize-claude
   ```

### Issue: Path allocation fails with "topic directory error"

**Cause**: unified-location-detection.sh cannot allocate topic path

**Solution**:
1. Check .claude/specs/ directory exists:
   ```bash
   mkdir -p .claude/specs
   ```
2. Verify permissions:
   ```bash
   chmod u+w .claude/specs
   ```
3. Re-run command

### Issue: Generated plan format incompatible with /implement

**Cause**: Plan structure doesn't match expected format

**Solution**:
1. Check plan has proper phase markers (### Phase N:)
2. Verify plan metadata includes all required fields
3. Report issue if plan generation has bugs

### Issue: Concurrent execution conflicts

**Cause**: Multiple /optimize-claude runs or other commands modifying same files

**Solution**:
1. Wait for first execution to complete
2. Check for lock files:
   ```bash
   ls .claude/.locks/
   ```
3. Remove stale locks if process crashed (be careful!)

### Issue: .claude/docs/ not detected despite existing

**Cause**: Directory permissions or non-standard structure

**Solution**:
1. Verify directory is readable:
   ```bash
   ls -ld .claude/docs/
   test -r .claude/docs/ && echo "Readable" || echo "Not readable"
   ```
2. Check for README.md in docs root:
   ```bash
   ls .claude/docs/README.md
   ```
3. Fix permissions if needed:
   ```bash
   chmod -R u+r .claude/docs/
   ```

### Issue: Invalid threshold value error

**Cause**: Provided threshold value is not one of the valid options

**Solution**:
```bash
# Valid threshold values are: aggressive, balanced, conservative
/optimize-claude --threshold balanced  # Correct
/optimize-claude --aggressive          # Correct (shorthand)

# Invalid examples:
/optimize-claude --threshold strict    # ERROR: invalid value
/optimize-claude --threshold 80        # ERROR: must use name, not number
```

### Issue: Additional report file not found

**Cause**: File path provided to `--file` flag doesn't exist or is incorrect

**Solution**:
1. Verify file exists before passing to command:
   ```bash
   test -f path/to/report.md && echo "Found" || echo "Not found"
   ```
2. Use absolute paths for clarity:
   ```bash
   /optimize-claude --file /absolute/path/to/report.md
   ```
3. Check for typos in file path

### Issue: Dry-run shows unexpected configuration

**Cause**: Flags not parsed correctly or unexpected defaults

**Solution**:
1. Use dry-run to preview before execution:
   ```bash
   /optimize-claude --aggressive --dry-run
   ```
2. Verify threshold value in dry-run output
3. Check additional reports are listed (if provided)
4. Adjust flags if configuration doesn't match expectations

### Issue: Multiple file flags not recognized

**Cause**: Incorrect flag syntax or shell quoting issues

**Solution**:
```bash
# Correct: Repeat --file for each report
/optimize-claude --file report1.md --file report2.md

# Incorrect: Only one file path per --file flag
/optimize-claude --file report1.md report2.md  # ERROR: report2.md treated as unknown arg
```

## Integration with Other Commands

### Workflow Integration

`/optimize-claude` fits into the broader workflow:

1. **Setup** → `/setup` creates initial CLAUDE.md
2. **Growth** → Add sections as project evolves
3. **Optimization** → `/optimize-claude` detects bloat ← YOU ARE HERE
4. **Refactoring** → `/implement` executes optimization plan
5. **Validation** → `/setup --validate` verifies structure

### Related Commands

- `/setup --validate` - Validate CLAUDE.md structure (no modifications)
- `/implement [plan]` - Execute optimization plan phase-by-phase
- `/plan [feature]` - Create implementation plans (may reference optimized docs)
- `/document [scope]` - Update documentation (may trigger future optimization)

## Architecture and Design

### Agent-Based Design

Why use agents instead of direct execution?

1. **Separation of concerns**: Analysis logic separated from command orchestration
2. **Reusability**: Agents can be invoked by other commands
3. **Testability**: Agents can be tested independently
4. **Context reduction**: Agents return metadata summaries, not full analysis
5. **Library integration**: Agents source existing libraries (no reimplementation)

### Library Integration

The command leverages existing infrastructure:

**optimize-claude-md.sh**:
- `set_threshold_profile("balanced")` - Set analysis threshold
- `analyze_bloat("CLAUDE.md")` - Parse sections and detect bloat
- No duplicate awk logic (agents call library functions)

**unified-location-detection.sh**:
- `perform_location_detection("optimize CLAUDE.md structure")` - Allocate topic path
- `ensure_artifact_directory("path")` - Lazy directory creation
- Follows directory protocols (topic-based structure)

### Fail-Fast Error Handling

Verification checkpoints catch failures immediately:

1. **After research** (Phase 3): Verify both reports created
2. **After planning** (Phase 5): Verify plan created
3. **During implementation** (in generated plan): Verify each extraction
4. **After implementation** (final phase): Verify links, metadata, tests

If any checkpoint fails, command exits with diagnostic message.

## Performance Characteristics

### Execution Time

- **Research stage**: 10-20 seconds (parallel agents, depends on CLAUDE.md size and docs/ complexity)
- **Planning stage**: 5-10 seconds (single agent, synthesizes research)
- **Total**: ~15-30 seconds

### Context Reduction

- **Agent outputs**: Metadata summaries only (99% reduction)
- **Research reports**: Structured markdown (~2-5 KB each)
- **Implementation plan**: /implement-compatible (~5-15 KB)

### Storage

All artifacts stored in topic-based directory:
```
.claude/specs/optimize_claude_{TIMESTAMP}/
├── reports/
│   ├── 001_claude_md_analysis.md (~2-5 KB)
│   └── 002_docs_structure_analysis.md (~2-5 KB)
└── plans/
    └── 001_optimization_plan.md (~5-15 KB)
```

Total: ~10-25 KB per optimization run.

## Best Practices

### When to Run

Run `/optimize-claude` when:
- CLAUDE.md exceeds 800-1000 lines
- Sections become unwieldy (>100 lines)
- Command discovery slows down
- New documentation added to .claude/docs/
- After major feature additions

### Review Before Implementation

Always review the plan before running `/implement`:
1. Check extraction candidates (are they appropriate?)
2. Verify integration points (correct .claude/docs/ locations?)
3. Review rollback procedure (can you restore if needed?)
4. Verify testing steps (adequate validation?)

### Incremental Optimization

For large CLAUDE.md files (>1500 lines):
1. Run `/optimize-claude` to get full plan
2. Extract highest-impact sections first (largest, most bloated)
3. Run `/setup --validate` after each extraction
4. Continue with remaining extractions incrementally

### Backup Strategy

The plan always includes a backup phase:
- Backup created: `.claude/backups/CLAUDE.md.YYYYMMDD-HHMMSS`
- Keep backups for 30 days (manual cleanup)
- Test rollback procedure before major extractions

## See Also

- [/setup Command Guide](setup-command-guide.md) - CLAUDE.md creation and validation
- [/implement Command Guide](implement-command-guide.md) - Plan execution
- [Agent Reference](../reference/standards/agent-reference.md) - All specialized agents
- [Directory Protocols](../concepts/directory-protocols.md) - Topic-based artifact organization
- [Executable/Documentation Separation Pattern](../concepts/patterns/executable-documentation-separation.md) - Why agents are lean
