# /optimize-claude Command Guide

> **Command File**: [.claude/commands/optimize-claude.md](../../commands/optimize-claude.md)

## Overview

The `/optimize-claude` command analyzes your CLAUDE.md file and .claude/docs/ directory structure to generate an optimization plan. It uses a multi-stage agent workflow to identify bloated sections, find integration opportunities, and create a detailed implementation plan.

## Usage

```bash
/optimize-claude  # Simple, no flags needed
```

No arguments or flags required - the command runs with sensible defaults.

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

### Balanced Threshold (Hardcoded)

The command uses a "balanced" threshold of 80 lines for bloat detection. This is a good default for most projects:

- **Bloated**: Sections >80 lines → Extract to .claude/docs/
- **Moderate**: Sections 50-80 lines → Consider extraction
- **Optimal**: Sections <50 lines → Keep inline

### Why 80 Lines?

- Fits ~2 screens of terminal output
- Leaves room for summaries (2-3 sentences + link)
- Balances context overhead vs reference jumping
- Matches optimize-claude-md.sh library default

### Future Customization

If you need different thresholds, you can:
1. Modify the agent directly (claude-md-analyzer.md)
2. Request a command enhancement to add `--threshold` flag
3. Run optimize-claude-md.sh library directly for custom analysis

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
   bash -n .claude/lib/optimize-claude-md.sh
   bash -n .claude/lib/unified-location-detection.sh
   ```

### Issue: Plan has no optimization recommendations

**Cause**: Your CLAUDE.md may already be well-optimized

**Solution**:
1. Check CLAUDE.md analysis report for bloated sections
2. If no sections >80 lines, your CLAUDE.md is already optimal
3. Consider using a more aggressive threshold (50 lines) if desired

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
