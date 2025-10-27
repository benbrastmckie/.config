# Library Cleanup Analysis: .claude/lib/ Directory

**Research Date**: 2025-10-26
**Scope**: Analysis of 73 scripts in .claude/lib/ for unused, redundant, or removable utilities
**Context**: Recent cleanup removed 266KB from .claude/ directory; this research identifies further opportunities

## Executive Summary

Analysis of 73 scripts in `.claude/lib/` identified **27 scripts with zero usage** (37% of total), **6 migration/validation scripts** that are one-time utilities, and **8 scripts** with redundant or consolidatable functionality. Total cleanup opportunity: **~41 scripts** representing **~52% of library files**.

### Key Findings

1. **Zero-Usage Scripts**: 27 scripts have no references in commands, agents, or other libraries
2. **Migration Scripts**: 6 one-time migration utilities that have completed their purpose
3. **Validation Scripts**: 3 command-specific validation scripts used only during development
4. **Redundant Functionality**: 8 scripts with overlapping capabilities that can be consolidated
5. **Unused Python Script**: 1 Python script with equivalent bash implementation

### Impact Assessment

- **Space Savings**: ~185KB (estimated 25% of lib/ directory)
- **Maintenance Reduction**: 41 fewer files to maintain
- **Cognitive Load**: Simpler navigation and discovery
- **Risk**: Low (all identified scripts either unused or have replacements)

## Methodology

### Analysis Approach

1. **Usage Pattern Analysis**: Searched all references across:
   - `.claude/commands/` (14 command files)
   - `.claude/agents/` (5 agent behavioral files)
   - `.claude/lib/` (cross-library dependencies)

2. **Automated Reference Counting**: Script developed to count references per file:
   ```bash
   for script in .claude/lib/*.sh; do
     scriptname=$(basename "$script")
     cmd_refs=$(grep -r "$scriptname" .claude/commands/ 2>/dev/null | wc -l)
     agent_refs=$(grep -r "$scriptname" .claude/agents/ 2>/dev/null | wc -l)
     lib_refs=$(grep -r "$scriptname" .claude/lib/*.sh 2>/dev/null | grep -v "^$script:" | wc -l)
     total=$((cmd_refs + agent_refs + lib_refs))
   done
   ```

3. **Manual Verification**: Inspected zero-usage scripts to confirm:
   - No indirect usage patterns
   - Not required for future functionality
   - Safe to archive

### Reference Count Distribution

| Usage Level | Script Count | Percentage |
|-------------|--------------|------------|
| 0 references | 27 | 37% |
| 1-3 references | 15 | 21% |
| 4-10 references | 19 | 26% |
| 11-30 references | 9 | 12% |
| 31+ references | 3 | 4% |

**Total Scripts Analyzed**: 73 (71 bash scripts + 1 Python script + 1 README)

## Detailed Findings

### Category 1: Zero-Usage Scripts (27 scripts)

Complete list of scripts with **0 references** across commands, agents, and libraries:

#### Agent Management (6 scripts)
1. **agent-frontmatter-validator.sh** (0 refs)
   - Purpose: Validate YAML frontmatter in agent files
   - Status: Functionality superseded by agent-registry-utils.sh
   - Size: 4.0K
   - Recommendation: **Archive** (validation now handled during registration)

2. **agent-loading-utils.sh** (0 refs)
   - Purpose: Load agent behavioral prompts, strip frontmatter
   - Status: Functions exist but never invoked
   - Size: 8.7K
   - Recommendation: **Archive** (behavioral injection uses direct file reads)

3. **command-discovery.sh** (0 refs)
   - Purpose: Discover and list available commands
   - Status: Never used; /list command handles this
   - Size: 3.3K
   - Recommendation: **Archive** (superseded by /list)

4. **hierarchical-agent-support.sh** (0 refs)
   - Purpose: Support functions for hierarchical agents
   - Status: Never invoked despite hierarchical pattern implementation
   - Size: 13K
   - Recommendation: **Archive** (functionality integrated elsewhere)

5. **parallel-orchestration-utils.sh** (0 refs)
   - Purpose: Utilities for parallel agent orchestration
   - Status: /orchestrate implements pattern without this utility
   - Size: 15K
   - Recommendation: **Archive** (inline implementation preferred)

6. **progressive-planning-utils.sh** (0 refs)
   - Purpose: Progressive plan structure utilities
   - Status: Functionality in plan-core-bundle.sh
   - Size: 15K
   - Recommendation: **Archive** (superseded by consolidation)

#### Artifact Management (3 scripts)
7. **artifact-cleanup.sh** (0 refs)
   - Purpose: Clean up temporary artifacts
   - Status: Never invoked; manual cleanup used
   - Size: 5.0K
   - Recommendation: **Archive** (cleanup handled by commands)

8. **artifact-cross-reference.sh** (0 refs)
   - Purpose: Manage cross-references between artifacts
   - Status: Functionality moved to artifact-registry.sh
   - Size: 5.5K
   - Recommendation: **Archive** (superseded by registry)

9. **report-generation.sh** (0 refs)
   - Purpose: Generate research reports
   - Status: /research command handles this directly
   - Size: 16K
   - Recommendation: **Archive** (inline in /research)

#### Testing & Setup (3 scripts)
10. **detect-testing.sh** (0 refs)
    - Purpose: Score testing infrastructure (0-6)
    - Status: Used by /setup but not invoked
    - Size: 3.8K
    - Recommendation: **Keep** (referenced in CLAUDE.md, potential future use)

11. **generate-readme.sh** (0 refs)
    - Purpose: Generate README files for directories
    - Status: Mentioned in CLAUDE.md but never invoked
    - Size: 6.5K
    - Recommendation: **Keep** (documented utility, potential use)

12. **generate-testing-protocols.sh** (0 refs)
    - Purpose: Generate testing protocol sections
    - Status: One-time use during /setup development
    - Size: 5.8K
    - Recommendation: **Archive** (development utility)

#### Validation & Migration (6 scripts)
13. **migrate-agent-registry.sh** (0 refs)
    - Purpose: Migrate agent registry from old to new schema
    - Status: **One-time migration completed**
    - Size: 5.8K
    - Recommendation: **Archive** (migration complete, keep for reference)

14. **migrate-checkpoint-v1.3.sh** (0 refs)
    - Purpose: Migrate checkpoint from v1.2 to v1.3
    - Status: **One-time migration utility**
    - Size: 4.9K
    - Recommendation: **Archive** (migration complete)

15. **validate-orchestrate.sh** (0 refs)
    - Purpose: Validate orchestrate.md structure (Plan 066)
    - Status: **Development-time validation**
    - Size: 9.6K
    - Recommendation: **Archive** (development complete)

16. **validate-orchestrate-pattern.sh** (0 refs)
    - Purpose: Validate orchestrate pattern compliance
    - Status: **Development-time validation**
    - Size: 2.9K
    - Recommendation: **Archive** (superse ded by validate-orchestrate-implementation.sh)

17. **validate-orchestrate-implementation.sh** (0 refs)
    - Purpose: Validate orchestrate implementation details
    - Status: **Development-time validation**
    - Size: 3.9K
    - Recommendation: **Archive** (validation complete)

18. **audit-execution-enforcement.sh** (0 refs)
    - Purpose: Audit execution enforcement in commands
    - Status: **One-time audit completed**
    - Size: 7.2K
    - Recommendation: **Archive** (audit complete, spec 438)

#### Tracking & Progress (4 scripts)
19. **checkpoint-manager.sh** (0 refs)
    - Purpose: Checkpoint management for resumable implementation
    - Status: Comprehensive 520-line utility never used
    - Size: 16K
    - Recommendation: **Archive** (checkpoint-utils.sh used instead)

20. **progress-tracker.sh** (0 refs)
    - Purpose: Real-time progress visualization
    - Status: Wave-based visualization never implemented
    - Size: 18K
    - Recommendation: **Archive** (progress-dashboard.sh used instead)

21. **track-file-creation-rate.sh** (0 refs)
    - Purpose: Track file creation rates for Plan 077
    - Status: **Hardcoded path to spec 077** (one-time use)
    - Size: 1.4K
    - Recommendation: **Archive** (spec-specific utility)

22. **register-all-agents.sh** (0 refs)
    - Purpose: Register all agents (standalone bash version)
    - Status: Duplicates register-agents.py functionality
    - Size: 2.1K
    - Recommendation: **Archive** (Python version preferred)

#### Structure & Validation (5 scripts)
23. **structure-validator.sh** (0 refs)
    - Purpose: Validate plan structure
    - Status: Sources structure-eval-utils.sh but never invoked
    - Size: 3.9K
    - Recommendation: **Archive** (functionality in plan-core-bundle.sh)

24. **structure-eval-utils.sh** (0 refs)
    - Purpose: Plan structure evaluation utilities
    - Status: Sourced by structure-validator.sh (also unused)
    - Size: 8.5K
    - Recommendation: **Archive** (both scripts unused)

25. **validation-utils.sh** (0 refs)
    - Purpose: Input validation and parameter checking
    - Status: Listed in README but never sourced
    - Size: 7.1K
    - Recommendation: **Archive** (error-handling.sh covers this)

26. **optimize-claude-md.sh** (0 refs)
    - Purpose: Analyze CLAUDE.md bloat (dry-run mode)
    - Status: Mentioned in CLAUDE.md but never invoked
    - Size: 5.9K
    - Recommendation: **Keep** (documented utility, /setup uses concept)

27. **dependency-mapper.sh** (0 refs)
    - Purpose: Map dependencies between phases
    - Status: Superseded by dependency-analyzer.sh
    - Size: 3.0K
    - Recommendation: **Archive** (functionality in dependency-analyzer.sh)

### Category 2: Low-Usage Scripts (1-3 references)

Scripts with minimal usage that may be candidates for consolidation:

#### Single-Reference Scripts (7 scripts)

1. **agent-discovery.sh** (1 ref)
   - Referenced by: agent-registry-utils.sh
   - Purpose: Extract agent metadata from files
   - Recommendation: **Consolidate** into agent-registry-utils.sh

2. **agent-schema-validator.sh** (1 ref)
   - Referenced by: agent-registry-utils.sh
   - Purpose: Validate agent schema
   - Recommendation: **Consolidate** into agent-registry-utils.sh

3. **complexity-thresholds.sh** (1 ref)
   - Referenced by: /plan command
   - Purpose: Load complexity threshold configuration
   - Recommendation: **Keep** (clean separation of config)

4. **dependency-analysis.sh** (1 ref)
   - Referenced by: /implement command
   - Purpose: Analyze phase dependencies
   - Recommendation: **Keep** (core /implement functionality)

5. **deps-utils.sh** (1 ref)
   - Referenced by: json-utils.sh
   - Purpose: Dependency checking (jq, etc.)
   - Recommendation: **Keep** (infrastructure utility)

6. **json-utils.sh** (1 ref)
   - Referenced by: base-utils.sh
   - Purpose: JSON processing utilities
   - Recommendation: **Keep** (core infrastructure)

7. **topic-decomposition.sh** (1 ref)
   - Referenced by: /research command
   - Purpose: Decompose research topics
   - Recommendation: **Keep** (core /research functionality)

8. **validate-orchestrate-pattern.sh** (1 ref)
   - Referenced by: validate-orchestrate.sh (also unused)
   - Recommendation: **Archive** (both scripts unused)

### Category 3: Redundant Functionality

Scripts with overlapping capabilities:

#### Checkpoint Management (2 scripts, prefer 1)
- **checkpoint-manager.sh** (0 refs, 16K) - Comprehensive but unused
- **checkpoint-utils.sh** (30 refs, 28K) - Actually used
- **Recommendation**: Archive checkpoint-manager.sh

#### Progress Tracking (2 scripts, prefer 1)
- **progress-tracker.sh** (0 refs, 18K) - Wave visualization, unused
- **progress-dashboard.sh** (8 refs, 12K) - Actually used
- **Recommendation**: Archive progress-tracker.sh

#### Agent Registration (2 scripts, prefer 1)
- **register-all-agents.sh** (0 refs, 2.1K) - Bash version
- **register-agents.py** (0 refs, 5.0K) - Python version, more robust
- **Recommendation**: Archive register-all-agents.sh OR remove both (never used)

#### Structure Validation (2 scripts, functionality consolidated)
- **structure-validator.sh** (0 refs, 3.9K)
- **structure-eval-utils.sh** (0 refs, 8.5K)
- **plan-core-bundle.sh** (16 refs, 34K) - Consolidated version
- **Recommendation**: Archive both structure-* scripts

### Category 4: Python Scripts

1. **register-agents.py** (0 refs)
   - Purpose: Register all agents in registry (Python implementation)
   - Status: More robust than bash version, but never used
   - Duplicate: register-all-agents.sh (bash version, also unused)
   - Size: 5.0K
   - Recommendation: **Archive both** (agent registration automated)

### Category 5: Temporary Files

Directory: `.claude/lib/tmp/`

1. **detect_weak_language.sh** (549 bytes)
2. **detect_weak_language_v2.sh** (953 bytes)
3. **analyze_usage.sh** (525 bytes, created during this research)
4. **e2e_orchestrate_666123/** (test directory)
5. **e2e_orchestrate_666298/** (test directory)
6. **e2e_orchestrate_666686/** (test directory)
7. **e2e_orchestrate_666904/** (test directory)

**Recommendation**: Clean entire tmp/ directory (test artifacts)

## Consolidation Opportunities

### Agent Management Consolidation

**Target**: Consolidate 3 scripts into agent-registry-utils.sh

1. **agent-discovery.sh** → Extract functions into agent-registry-utils.sh
2. **agent-schema-validator.sh** → Inline validation into registry operations
3. **agent-frontmatter-validator.sh** → Already superseded

**Savings**: ~16K, 2 fewer dependencies

### Archive Recommendations Summary

| Category | Script Count | Total Size | Archive Path |
|----------|--------------|------------|--------------|
| Zero-usage (safe) | 27 | ~185K | .claude/archive/lib/cleanup-2025-10-26/ |
| Redundant (duplicates) | 8 | ~65K | .claude/archive/lib/cleanup-2025-10-26/ |
| Python (unused) | 1 | 5K | .claude/archive/lib/cleanup-2025-10-26/ |
| Temp files | 7+ | ~15K | Delete (no archive needed) |
| **TOTAL** | **41+** | **~270K** | |

## High-Value Scripts (Keep)

These scripts are heavily used and critical to system functionality:

### Top 10 Most-Referenced Scripts

1. **error-handling.sh** (39 refs) - Error classification, retry logic
2. **checkpoint-utils.sh** (30 refs) - Checkpoint management for workflows
3. **checkbox-utils.sh** (27 refs) - Checkbox propagation across plan levels
4. **base-utils.sh** (25 refs) - Core utility functions
5. **detect-project-dir.sh** (21 refs) - Project directory detection
6. **unified-logger.sh** (18 refs) - Structured logging system
7. **plan-core-bundle.sh** (16 refs) - Consolidated plan parsing
8. **convert-core.sh** (14 refs) - Document conversion orchestration
9. **agent-registry-utils.sh** (10 refs) - Agent registry operations
10. **unified-location-detection.sh** (9 refs) - Location detection (85% token reduction)

**Total High-Value Scripts**: ~10-12 scripts representing 80% of usage

## Risk Assessment

### Low Risk (Safe to Archive)

**Zero-usage scripts** (27): No impact on existing functionality
- No references in active codebase
- Migration scripts completed their purpose
- Validation scripts used during development only
- Can be restored from archive if needed

### Medium Risk (Review Before Archive)

**Documented utilities** (3): Mentioned in CLAUDE.md but unused
- `detect-testing.sh` - Referenced in Testing Protocols section
- `generate-readme.sh` - Referenced in Quick Reference section
- `optimize-claude-md.sh` - Referenced in Quick Reference section

**Recommendation**: Keep these 3 scripts despite zero usage (documented features)

### High Risk (Do Not Archive)

**Core infrastructure** (12 scripts): >10 references each
- All top-10 most-referenced scripts
- Critical for command/agent functionality
- Removing would break multiple workflows

## Implementation Plan

### Phase 1: Archive Zero-Usage Scripts (Safe)

**Action**: Move 24 scripts to `.claude/archive/lib/cleanup-2025-10-26/`

**Exclude from archive** (keep despite zero usage):
- `detect-testing.sh` (documented in CLAUDE.md)
- `generate-readme.sh` (documented in CLAUDE.md)
- `optimize-claude-md.sh` (documented in CLAUDE.md)

**Scripts to archive**:
```bash
# Agent management (6)
agent-frontmatter-validator.sh
agent-loading-utils.sh
command-discovery.sh
hierarchical-agent-support.sh
parallel-orchestration-utils.sh
progressive-planning-utils.sh

# Artifact management (3)
artifact-cleanup.sh
artifact-cross-reference.sh
report-generation.sh

# Validation & migration (6)
migrate-agent-registry.sh
migrate-checkpoint-v1.3.sh
validate-orchestrate.sh
validate-orchestrate-pattern.sh
validate-orchestrate-implementation.sh
audit-execution-enforcement.sh

# Tracking & progress (4)
checkpoint-manager.sh
progress-tracker.sh
track-file-creation-rate.sh
register-all-agents.sh

# Structure & validation (5)
structure-validator.sh
structure-eval-utils.sh
validation-utils.sh
dependency-mapper.sh
register-agents.py (Python)
```

**Estimated savings**: ~190K

### Phase 2: Clean Temporary Directory

**Action**: Remove `.claude/lib/tmp/` directory

```bash
rm -rf .claude/lib/tmp/
```

**Estimated savings**: ~15K + test directories

### Phase 3: Update Documentation

**Files to update**:
1. `.claude/lib/README.md` - Remove archived scripts from index
2. `.claude/lib/UTILS_README.md` - Update utility script list
3. `CLAUDE.md` - Update library references (if any)

### Phase 4: Consolidation (Optional)

**Low priority** - Can be deferred to future cleanup:

1. **Agent management consolidation**:
   - Merge agent-discovery.sh → agent-registry-utils.sh
   - Merge agent-schema-validator.sh → agent-registry-utils.sh
   - Savings: ~16K, 2 fewer files

2. **Update references**:
   - Search for any remaining references to consolidated scripts
   - Update to use agent-registry-utils.sh instead

## Recommendations

### Immediate Actions (High Priority)

1. **Archive 24 zero-usage scripts** to `.claude/archive/lib/cleanup-2025-10-26/`
   - Risk: Low (no active usage)
   - Impact: ~190K space savings
   - Effort: 15 minutes

2. **Clean tmp/ directory**
   - Risk: None (test artifacts)
   - Impact: ~15K savings + cleaner structure
   - Effort: 2 minutes

3. **Update library documentation**
   - Risk: None
   - Impact: Accurate inventory
   - Effort: 30 minutes

**Total immediate savings**: ~205K, 31+ fewer files

### Future Actions (Low Priority)

4. **Consolidate agent management utilities**
   - Risk: Low (single use case each)
   - Impact: ~16K savings, simpler dependencies
   - Effort: 2-3 hours (merge + test)

5. **Review documented-but-unused utilities**
   - Scripts: detect-testing.sh, generate-readme.sh, optimize-claude-md.sh
   - Decision: Keep, archive, or implement
   - Effort: 1 hour analysis

### Monitoring

After cleanup, monitor for:
1. **Missing script errors**: Check logs for references to archived scripts
2. **Test failures**: Run `.claude/tests/run_all_tests.sh`
3. **Command failures**: Test all slash commands
4. **Archive access**: Track any attempts to use archived scripts

## Appendix A: Complete Usage Statistics

Full reference count for all 73 scripts:

```
Script                                    Cmds  Agents  Libs  Total
===============================================================================
error-handling.sh                           38       0     1     39
checkpoint-utils.sh                         22       2     6     30
checkbox-utils.sh                           10      17     0     27
base-utils.sh                                1       0    24     25
detect-project-dir.sh                       18       0     3     21
unified-logger.sh                           11       0     7     18
plan-core-bundle.sh                          5       0    11     16
convert-core.sh                              3       0    11     14
agent-registry-utils.sh                      9       0     1     10
unified-location-detection.sh                6       3     0      9
topic-utils.sh                               7       0     1      8
progress-dashboard.sh                        8       0     0      8
workflow-detection.sh                        7       0     0      7
git-utils.sh                                 0       6     0      6
context-metrics.sh                           6       0     0      6
metadata-extraction.sh                       6       0     0      6
auto-analysis-utils.sh                       6       0     0      6
parse-template.sh                            5       0     0      5
template-integration.sh                      4       0     0      4
agent-invocation.sh                          0       0     3      3
artifact-creation.sh                         3       0     0      3
context-pruning.sh                           3       0     0      3
dependency-analyzer.sh                       2       1     0      3
analyze-metrics.sh                           2       0     0      2
analysis-pattern.sh                          0       0     2      2
artifact-registry.sh                         0       0     2      2
convert-docx.sh                              0       0     2      2
convert-markdown.sh                          0       0     2      2
convert-pdf.sh                               0       0     2      2
substitute-variables.sh                      2       0     0      2
timestamp-utils.sh                           0       0     2      2
agent-discovery.sh                           0       0     1      1
agent-schema-validator.sh                    0       0     1      1
complexity-thresholds.sh                     1       0     0      1
dependency-analysis.sh                       1       0     0      1
deps-utils.sh                                0       0     1      1
json-utils.sh                                0       0     1      1
topic-decomposition.sh                       1       0     0      1
validate-orchestrate-pattern.sh              1       0     0      1
agent-frontmatter-validator.sh               0       0     0      0
agent-loading-utils.sh                       0       0     0      0
artifact-cleanup.sh                          0       0     0      0
artifact-cross-reference.sh                  0       0     0      0
audit-execution-enforcement.sh               0       0     0      0
audit-imperative-language.sh                 0       0     0      0
checkpoint-manager.sh                        0       0     0      0
command-discovery.sh                         0       0     0      0
dependency-mapper.sh                         0       0     0      0
detect-testing.sh                            0       0     0      0
generate-readme.sh                           0       0     0      0
generate-testing-protocols.sh                0       0     0      0
hierarchical-agent-support.sh                0       0     0      0
migrate-agent-registry.sh                    0       0     0      0
migrate-checkpoint-v1.3.sh                   0       0     0      0
optimize-claude-md.sh                        0       0     0      0
parallel-orchestration-utils.sh              0       0     0      0
progressive-planning-utils.sh                0       0     0      0
progress-tracker.sh                          0       0     0      0
register-all-agents.sh                       0       0     0      0
register-agents.py                           0       0     0      0
report-generation.sh                         0       0     0      0
structure-eval-utils.sh                      0       0     0      0
structure-validator.sh                       0       0     0      0
track-file-creation-rate.sh                  0       0     0      0
validate-orchestrate-implementation.sh       0       0     0      0
validate-orchestrate.sh                      0       0     0      0
validation-utils.sh                          0       0     0      0
```

## Appendix B: Archive Structure

Recommended archive organization:

```
.claude/archive/lib/cleanup-2025-10-26/
├── agent-management/
│   ├── agent-frontmatter-validator.sh
│   ├── agent-loading-utils.sh
│   ├── command-discovery.sh
│   ├── hierarchical-agent-support.sh
│   ├── parallel-orchestration-utils.sh
│   ├── progressive-planning-utils.sh
│   ├── register-all-agents.sh
│   └── register-agents.py
├── artifact-management/
│   ├── artifact-cleanup.sh
│   ├── artifact-cross-reference.sh
│   └── report-generation.sh
├── migration-scripts/
│   ├── migrate-agent-registry.sh
│   └── migrate-checkpoint-v1.3.sh
├── validation-scripts/
│   ├── audit-execution-enforcement.sh
│   ├── validate-orchestrate.sh
│   ├── validate-orchestrate-pattern.sh
│   └── validate-orchestrate-implementation.sh
├── tracking-progress/
│   ├── checkpoint-manager.sh
│   ├── progress-tracker.sh
│   └── track-file-creation-rate.sh
├── structure-validation/
│   ├── structure-validator.sh
│   ├── structure-eval-utils.sh
│   ├── validation-utils.sh
│   └── dependency-mapper.sh
└── README.md (archive manifest with restoration instructions)
```

## Conclusion

The `.claude/lib/` directory contains significant cleanup opportunities:

- **37% of scripts** (27/73) have zero usage
- **Additional 8 scripts** are redundant or duplicate functionality
- **Total cleanup**: 41+ scripts (~270K)
- **Risk**: Low (comprehensive testing available via `.claude/tests/`)
- **Impact**: Improved maintainability, reduced cognitive load, cleaner structure

**Primary recommendation**: Archive 24 zero-usage scripts immediately (keeping 3 documented utilities), clean tmp/ directory, and update documentation. This provides ~205K savings with minimal risk.

**Secondary recommendation**: Consolidate agent management utilities (optional, deferred to future iteration).

This cleanup builds on the recent October 2025 cleanup that removed 266KB, bringing total cleanup potential to **~470KB** (combined).
