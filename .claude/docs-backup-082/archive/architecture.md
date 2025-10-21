# Claude Code Architecture

## Directory Modularization Architecture (Phase 7)

### Command → Shared Documentation References

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          COMMANDS (Primary Interface)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  orchestrate.md (850 lines) ──────┐                                         │
│    [Core: workflow coordination]  │                                         │
│                                   │                                         │
│                                   ├──────► workflow-phases.md (1,903 lines) │
│                                   │         [5 phase procedures]            │
│                                   │                                         │
│                                   ├──────► setup-modes.md (406 lines)       │
│                                   │         [5 command modes]               │
│                                   │                                         │
│                                   ├──────► bloat-detection.md (266 lines)   │
│                                   │         [Detection algorithms]          │
│                                   │                                         │
│                                   └──────► extraction-strategies.md (348)   │
│                                            [Extraction preferences]         │
│                                                                              │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                              │
│  implement.md (498 lines) ────────┐                                         │
│    [Core: phase execution]        │                                         │
│                                   │                                         │
│                                   ├──────► phase-execution.md (383 lines)   │
│                                   │         [Checkpoint, test, commit]      │
│                                   │                                         │
│                                   ├──────► implementation-workflow.md (152) │
│                                   │         [Implementation patterns]       │
│                                   │                                         │
│                                   └──────► revise-auto-mode.md (434 lines)  │
│                                            [Auto-mode specification]        │
│                                                                              │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                              │
│  setup.md (375 lines, 58.8% reduction)                                      │
│  revise.md (406 lines, 53.8% reduction)                                     │
│    ├──────► standards-analysis.md (247 lines)                               │
│    │         [Standards analysis procedures]                                │
│    └──────► revision-types.md (109 lines)                                   │
│              [5 revision types]                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ commands reference shared files
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     SHARED DOCUMENTATION (Reusable Content)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  commands/shared/                                                            │
│  ├── workflow-phases.md (1,903 lines) ....... orchestrate                   │
│  ├── phase-execution.md (383 lines) ......... implement                     │
│  ├── implementation-workflow.md (152 lines) . implement                     │
│  ├── setup-modes.md (406 lines) ............. setup                         │
│  ├── bloat-detection.md (266 lines) ......... setup, orchestrate            │
│  ├── extraction-strategies.md (348 lines) ... setup, orchestrate            │
│  ├── standards-analysis.md (247 lines) ...... setup                         │
│  ├── revise-auto-mode.md (434 lines) ........ revise, implement             │
│  └── revision-types.md (109 lines) .......... revise                        │
│                                                                              │
│  Total: 9 files, 4,248 lines of reusable documentation                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Utility Consolidation Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMMANDS (Utility Consumers)                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  implement.md ────────┐                                                     │
│  expand.md ───────────┤                                                     │
│  collapse.md ─────────┼────► source plan-core-bundle.sh                     │
│  revise.md ───────────┤       [4 commands use this]                         │
│  shared/*.md ─────────┘       [Consolidates 3 planning utilities]           │
│                                                                              │
│  implement.md ────────┐                                                     │
│  expand.md ───────────┼────► source unified-logger.sh                       │
│  orchestrate.md ──────┘       [3 commands use this]                         │
│                                [Consolidates 2 loggers]                     │
│                                                                              │
│  All utilities ───────────► source base-utils.sh                            │
│                              [Common: error(), warn(), info(), debug()]     │
│                              [Eliminates 4 duplicate error() functions]     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ commands source utilities
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CONSOLIDATED UTILITIES (Shared Functions)                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  lib/plan-core-bundle.sh (1,159 lines)                                      │
│    ┌─────────────────────────────────────────────────────────────┐         │
│    │ Consolidates:                                                │         │
│    │   • parse-plan-core.sh (plan parsing functions)              │         │
│    │   • plan-structure-utils.sh (structure utilities)            │         │
│    │   • plan-metadata-utils.sh (metadata operations)             │         │
│    │                                                               │         │
│    │ Benefits: 3 source statements → 1 import                     │         │
│    │                                                               │         │
│    │ Functions:                                                    │         │
│    │   • Plan Parsing (12 functions)                              │         │
│    │   • Structure Operations (8 functions)                       │         │
│    │   • Metadata Extraction (10 functions)                       │         │
│    └─────────────────────────────────────────────────────────────┘         │
│                                                                              │
│  lib/unified-logger.sh (717 lines)                                          │
│    ┌─────────────────────────────────────────────────────────────┐         │
│    │ Consolidates:                                                │         │
│    │   • adaptive-planning-logger.sh (adaptive planning logs)     │         │
│    │   • conversion-logger.sh (document conversion logs)          │         │
│    │                                                               │         │
│    │ Benefits: 2 source statements → 1 import                     │         │
│    │          Consistent logging interface                        │         │
│    │                                                               │         │
│    │ Functions:                                                    │         │
│    │   • Log Management (6 functions)                             │         │
│    │   • Query Operations (8 functions)                           │         │
│    │   • Rotation & Cleanup (4 functions)                         │         │
│    └─────────────────────────────────────────────────────────────┘         │
│                                                                              │
│  lib/base-utils.sh (~100 lines)                                             │
│    ┌─────────────────────────────────────────────────────────────┐         │
│    │ Provides:                                                     │         │
│    │   • error() - Error messaging and exit                        │         │
│    │   • warn() - Warning messages                                 │         │
│    │   • info() - Info messages                                    │         │
│    │   • debug() - Debug messages                                  │         │
│    │   • require_command() - Command existence checks              │         │
│    │   • require_file() - File existence checks                    │         │
│    │   • require_dir() - Directory existence checks                │         │
│    │                                                               │         │
│    │ Benefits: Eliminates 4 duplicate error() implementations      │         │
│    │          Zero dependencies (breaks circular deps)             │         │
│    └─────────────────────────────────────────────────────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Phase 7 Impact Summary

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| orchestrate.md | 2,720 lines | 850 lines | 68.8% (1,870 lines) |
| implement.md | 987 lines | 498 lines | 49.5% (489 lines) |
| setup.md | 911 lines | 375 lines | 58.8% (536 lines) |
| revise.md | 878 lines | 406 lines | 53.8% (472 lines) |
| **Total Command Reduction** | **5,496 lines** | **2,129 lines** | **61.3% (3,367 lines saved)** |

**New Files Created**:
- commands/shared/: 9 files (~4,248 lines reusable documentation)
- lib/: 3 consolidated utilities (plan-core-bundle.sh, unified-logger.sh, base-utils.sh)

**Commands Updated**: 7 commands now use consolidated utilities

## Benefits

### Reduced Duplication
- Documentation patterns: 9 shared files referenced by multiple commands (was duplicated)
- Planning utilities: 3 utilities → 1 consolidated bundle
- Loggers: 2 loggers → 1 unified logger
- Base functions: 1 base-utils.sh → eliminates 4 duplicate error() functions

### Improved Maintainability
- Update shared documentation once, all commands benefit
- Consolidate bug fixes in single utility file
- Consistent patterns across all commands
- Single source of truth for each concept

### Better Navigation
- Command files show concise summaries (50-100 words) + deep-dive links
- Shared files provide complete documentation (100-1,900 lines)
- lib/README.md provides function inventory with cross-references
- Clear separation: core logic (commands) vs detailed procedures (shared)

### Enhanced Documentation
- Reusable content: Concepts documented once, linked everywhere
- Structured organization: Shared files grouped by purpose
- Consistent formatting: All shared files follow same structure
- Easier updates: Change shared file once, all references updated

### Simplified Development
- Fewer source statements: 3 → 1 for planning, 2 → 1 for logging
- Zero circular dependencies: base-utils.sh has no dependencies
- Backward compatibility: Wrapper files ensure smooth transition
- Consistent interfaces: All utilities use same error handling patterns

## Reference-Based Composition Pattern

### How It Works

Commands reference shared documentation via markdown links:

```markdown
## Error Handling Strategy

The `/orchestrate` command implements multi-level error recovery:

**Error Types**: Transient (3 retries), Tool Access (2 retries), Critical (escalation)
**Debugging Limits**: Max 3 iterations before user escalation
**Recovery Patterns**: Exponential backoff, checkpoint rollback, reduced toolset

**See detailed procedures**: [Error Recovery Patterns](shared/error-recovery.md)
```

### Benefits of Reference Pattern

1. **Content Reuse**: Write once, reference everywhere
2. **Automatic Updates**: Claude reads linked files on-demand
3. **Reduced Context**: Command files stay focused and concise
4. **Better Organization**: Related content grouped in shared files
5. **No Preprocessing**: Native markdown links, no build step required

### Example Reference Flow

```
User invokes: /orchestrate "Add authentication"
  ↓
Claude reads: commands/orchestrate.md (850 lines)
  ↓
Claude sees reference: [Workflow Phases](shared/workflow-phases.md)
  ↓
Claude reads: commands/shared/workflow-phases.md (1,903 lines)
  ↓
Claude executes: Complete workflow with full phase documentation
```

## Utility Consolidation Pattern

### How It Works

Commands source consolidated utilities instead of multiple files:

**Before (3 source statements)**:
```bash
source "$CLAUDE_DIR/lib/parse-plan-core.sh"
source "$CLAUDE_DIR/lib/plan-structure-utils.sh"
source "$CLAUDE_DIR/lib/plan-metadata-utils.sh"
```

**After (1 source statement)**:
```bash
source "$CLAUDE_DIR/lib/plan-core-bundle.sh"
```

### Benefits of Consolidation

1. **Simplified Imports**: Fewer source statements
2. **Consistent Interfaces**: All functions use same patterns
3. **No Circular Dependencies**: base-utils.sh breaks dependency cycles
4. **Backward Compatible**: Wrapper files maintain old names
5. **Easier Testing**: Fewer files to test, clearer boundaries

### Consolidation Strategy

**Priority 1**: Bundle always-sourced-together utilities
- Example: 3 planning utilities → plan-core-bundle.sh

**Priority 2**: Unify similar-purpose utilities
- Example: 2 loggers → unified-logger.sh

**Priority 3**: Extract common functions
- Example: 4 duplicate error() → base-utils.sh

## Progressive Plan Structure

Phase 7 modularization works alongside progressive plan structure (L0/L1/L2):

```
Level 0 (Single File)
  specs/plans/001_feature.md
  ↓ /expand phase (when complexity grows)

Level 1 (Phase Expansion)
  specs/plans/001_feature/
    001_feature.md (main plan)
    phase_3_complex.md (expanded phase)
  ↓ /expand stage (when phases have stages)

Level 2 (Stage Expansion)
  specs/plans/001_feature/
    001_feature.md (main plan)
    phase_3_complex/
      phase_3_overview.md
      stage_2_implementation.md (expanded stage)
```

Both patterns (command modularization + plan structure) use the same principle:
**Start simple, expand on-demand when complexity requires it.**

## Future Enhancements

### Potential Improvements

1. **More Shared Documentation**: Extract common patterns from remaining commands
2. **lib/ Subdirectories**: Organize 30+ utilities into core/, adaptive/, conversion/, agents/
3. **Automated Link Validation**: CI/CD integration to verify all references
4. **Documentation Generation**: Auto-generate cross-reference index
5. **Utility Bundling**: Continue consolidating related utilities

### Maintenance Guidelines

1. **Keep Commands Focused**: Extract to shared/ when >50 lines of reusable content
2. **Bundle Related Utilities**: If 3+ commands always source same utils, bundle them
3. **Document References**: Always include 50-100 word summary before reference links
4. **Test Links**: Run `tests/test_command_references.sh` after changes
5. **Update Architecture**: Keep this diagram current as system evolves

## Related Documentation

- [.claude/README.md](../README.md) - Main configuration directory documentation
- [commands/README.md](../commands/README.md) - Complete command documentation
- [commands/shared/README.md](../commands/shared/README.md) - Shared documentation index
- [lib/README.md](../lib/README.md) - Utility function inventory

## Navigation

- [← Back to .claude/](../README.md)
- [Commands](../commands/README.md)
- [Utilities](../lib/README.md)
- [Tests](../tests/README.md)
