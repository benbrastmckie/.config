# Safe Archival Strategy and Dependency Mapping

**[← Back to Overview](./OVERVIEW.md)**

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Safe Archival Strategy and Dependency Mapping
- **Report Type**: codebase analysis, policy design, dependency analysis
- **Part of**: [Research Overview: Agents and Library Scripts Archival Analysis](./OVERVIEW.md)

## Executive Summary

This report establishes a safe archival strategy for the .claude/ system following clean-break and fail-fast philosophy. Analysis of 62 library files, 13 commands, and 34 agents reveals complex dependency graphs requiring careful sequencing. The strategy prioritizes verification checkpoints over backward compatibility, uses dependency analysis to prevent breaking changes, and implements a five-tier priority system for archival decisions. Critical finding: 8 commands already successfully archived demonstrate the pattern - agents and libraries must remain active as they support both active and archived commands through shared infrastructure.

## Findings

### 1. Clean-Break Philosophy Applied to Archival

**Core Principle** (CLAUDE.md:99-128):
- Delete obsolete code immediately after migration
- No deprecation warnings, compatibility shims, or transition periods
- No archives beyond git history
- Configuration describes what it is, not what it was
- Missing files produce immediate, obvious bash errors

**Critical Distinction - Fallback Types** (CLAUDE.md:115-118):
- **Bootstrap fallbacks**: PROHIBITED (hide configuration errors)
- **Verification fallbacks**: REQUIRED (detect failures immediately)
- **Optimization fallbacks**: ACCEPTABLE (performance caches only)

**Archival Interpretation**:
When archiving commands, the clean-break philosophy means:
1. Move command file to archive directory immediately (no gradual deprecation)
2. Fail-fast: Any invocation of archived command produces clear error
3. No compatibility shims to redirect old command to new replacement
4. Git history serves as archive (no need for separate historical commentary)
5. Verification checkpoints detect missing dependencies immediately

### 2. Successful Archival Pattern Analysis

**Evidence from Spec 721** (000_comprehensive_summary.md:1-429):
Eight commands successfully archived on 2025-11-15:
- `/refactor` (13,316 bytes) - Code quality analysis
- `/analyze` (11,242 bytes) - Metrics and performance
- `/plan-from-template` (8,772 bytes) - Template-based planning
- `/plan-wizard` (7,856 bytes) - Interactive guided planning
- `/test` (3,664 bytes) - Targeted test execution
- `/test-all` (3,082 bytes) - Full regression testing
- `/list` (7,376 bytes) - Artifact discovery
- `/document` (4,796 bytes) - Documentation updates

**Archive Location**: `.claude/archive/commands/` (verified via ls:1-8)

**Key Finding**: Commands archived, but supporting infrastructure preserved:
- **Libraries intact**: All 62 library files remain in `.claude/lib/`
- **Agents intact**: test-specialist, code-reviewer agents remain active
- **Templates intact**: 10 YAML templates in `.claude/commands/templates/`
- **Utilities intact**: metadata-extraction.sh, parse-template.sh, detect-testing.sh

**Rationale**: Libraries and agents support BOTH active and archived commands through shared infrastructure. Archiving them would break active command dependencies.

### 3. Dependency Graph Analysis

**Library Dependency Patterns** (Grep output source patterns):

**Tier 1: Foundation Libraries** (sourced by 10+ files):
- `detect-project-dir.sh` - Sourced by 15+ libraries/commands
- `base-utils.sh` - Sourced by 12+ libraries
- `unified-logger.sh` - Sourced by 8+ libraries
- `timestamp-utils.sh` - Sourced by checkpoint-utils.sh, unified-logger.sh

**Tier 2: Core Orchestration** (sourced by 5+ files):
- `plan-core-bundle.sh` - Sourced by collapse.md:86, expand.md:84, auto-analysis-utils.sh:10
- `workflow-state-machine.sh` - Sourced by coordinate.md:104,251,596,886
- `checkpoint-utils.sh` - Sourced by implement.md, coordinate.md, workflow-state-machine.sh
- `error-handling.sh` - Sourced by coordinate.md:124,253,611,901

**Tier 3: Specialized Workflows** (sourced by 2-4 files):
- `complexity-utils.sh` - Sourced by plan.md:30, implement.md:102
- `metadata-extraction.sh` - Sourced by research.md:54
- `artifact-creation.sh` - Sourced by research.md:52
- `agent-invocation.sh` - Sourced by auto-analysis-utils.sh:15

**Tier 4: Feature-Specific** (sourced by 1 file):
- `convert-core.sh` - Only sourced by convert-docs.md:242
- `topic-decomposition.sh` - Only sourced by research.md:51
- `template-integration.sh` - Only sourced by research.md:53

**Tier 5: Standalone Utilities** (not sourced, invoked directly):
- `optimize-claude-md.sh` - Standalone script for /optimize-claude
- `generate-readme.sh` - Standalone documentation generator
- `dependency-analyzer.sh` - Standalone dependency analysis tool

**Command Dependencies on Libraries** (research.md:51-55 example):
```bash
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh
source .claude/lib/metadata-extraction.sh
source .claude/lib/overview-synthesis.sh
```

**Critical Insight**: Archiving a Tier 1 library would break 10+ active commands immediately. Tier 2 would break 5+ commands. Only Tier 4-5 are safe archival candidates.

### 4. Agent Dependency Analysis

**Active Agents** (34 total in .claude/agents/):
- `research-specialist.md` - Used by /research, /coordinate research phase
- `plan-architect.md` - Used by /plan, /coordinate planning phase
- `code-writer.md` - Used by /implement, /coordinate implementation
- `test-specialist.md` - Used by /test-all (archived), but also /implement testing phase
- `code-reviewer.md` - Used by /refactor (archived), but also /implement code review
- `spec-updater.md` - Used by all workflow commands for artifact management

**Dependency Pattern**: Agents are shared resources across multiple commands
- Archiving an agent breaks ALL commands that invoke it
- Even archived commands' agents remain valuable (test-specialist used by /implement)
- Agents follow shared utility pattern, not command-specific pattern

**Agent Discovery Hierarchy** (CLAUDE.md configuration_portability section):
1. Built-in registry (~50 built-in)
2. Project-level: `.config/.claude/agents/` (34 agents - AUTHORITATIVE)
3. User-level: `~/.claude/agents/` (KEPT EMPTY per portability policy)

**Archival Implication**: Never archive agents unless ALL consuming commands archived AND no future commands will use agent capabilities.

### 5. Verification Checkpoint Integration

**Checkpoint Pattern** (verification-helpers.sh:34-99):
```bash
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  # Success: Single character output
  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"
    return 0
  else
    # Failure: Enhanced verbose diagnostic (38 lines)
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    # ... detailed diagnostics ...
  fi
}
```

**Usage in Commands** (coordinate.md pattern):
- Pre-calculate artifact paths before agent invocation
- Verify file creation immediately after agent execution
- Fail-fast if verification fails (exit 1, no silent fallbacks)
- Provide actionable diagnostics for troubleshooting

**Archival Integration**:
When archiving commands, verification checkpoints ensure:
1. Dependencies detected immediately (not silently ignored)
2. Missing libraries cause obvious bash errors (source failures)
3. Missing agents cause Task tool invocation failures
4. Clear error messages guide restoration if needed

### 6. Fail-Fast Detection Mechanisms

**Source Statement Failures** (bash behavior):
```bash
source .claude/lib/missing-file.sh  # Immediate error, script exits
# Error: .claude/lib/missing-file.sh: No such file or directory
```

**Agent Invocation Failures** (Task tool behavior):
```bash
Task {
  agent: "missing-agent"  # Immediate error, clear diagnostic
  # Error: Agent 'missing-agent' not found in registry
}
```

**File Verification Failures** (verification-helpers.sh:82-99):
- Expected vs Actual path comparison
- Directory diagnostic (exists, file count, recent files)
- Actionable fix commands provided
- No silent fallbacks or graceful degradation

**Archival Safety**: Fail-fast mechanisms ensure archived dependencies detected immediately, not discovered later in production workflows.

### 7. Precedent Analysis - Recent Archival Operations

**Spec 720 Pattern** (Clean-Break Removal):
- Phase 1: Audit and Backup (git commit for rollback)
- Phase 2: Complete Removal (rm -rf, no gradual deprecation)
- Phase 3: Validation (verify active commands still work)
- Phase 4: Documentation Update (describe current state, not history)

**Commits** (git log output):
- `0e344025` - Phase 4: Update Documentation
- `7f656046` - Phase 2: Complete Removal
- `ef7f93b0` - Phase 1: Audit and Backup
- `a545a17e` - Clean-Break Removal (commands)

**Pattern**: Immediate removal → verification → documentation (no transition period)

**Spec 718 Pattern** (Commands Directory Cleanup):
- Removed 8 commands to `.claude/archive/commands/`
- 48.1% directory reduction achieved
- All libraries preserved (supporting infrastructure)
- No backward compatibility shims created

**Key Learning**: Archive location (`.claude/archive/commands/`) serves as rollback mechanism through git, not as active alternative discovery path.

## Recommendations

### Recommendation 1: Five-Tier Archival Priority System

**Priority 1 (NEVER ARCHIVE)**: Foundation Infrastructure
- **Tier 1 Libraries**: detect-project-dir.sh, base-utils.sh, unified-logger.sh, timestamp-utils.sh
- **All Active Agents**: 34 agents in `.claude/agents/` (shared across commands)
- **Core Orchestration**: workflow-state-machine.sh, checkpoint-utils.sh, error-handling.sh
- **Rationale**: Breaking these breaks 10+ active commands immediately

**Priority 2 (ARCHIVE WITH EXTREME CAUTION)**: Core Workflow Libraries
- **Tier 2 Libraries**: plan-core-bundle.sh, state-persistence.sh, verification-helpers.sh
- **Prerequisite**: Verify NO active commands depend on these (grep all commands)
- **Verification**: Run full test suite after archival
- **Rationale**: 5+ command dependencies, high risk

**Priority 3 (SAFE TO ARCHIVE)**: Feature-Specific Libraries
- **Tier 4 Libraries**: convert-core.sh (only convert-docs.md), topic-decomposition.sh (only research.md)
- **Condition**: Archive command FIRST, then archive library
- **Verification**: Grep confirms single command dependency
- **Example**: Archive /convert-docs → verify no errors → archive convert-core.sh

**Priority 4 (SAFE TO ARCHIVE)**: Standalone Utilities
- **Tier 5 Libraries**: optimize-claude-md.sh, generate-readme.sh, dependency-analyzer.sh
- **Condition**: Not sourced by any command (invoked as standalone scripts)
- **Verification**: Grep output shows NO `source` statements
- **Low Risk**: No sourcing dependencies means no fail-fast errors

**Priority 5 (SAFE TO ARCHIVE)**: Command Files Only
- **Target**: Command markdown files in `.claude/commands/`
- **Preserve**: Supporting libraries, agents, templates
- **Pattern**: 8 commands archived successfully (Spec 721)
- **Verification**: Active commands remain functional

### Recommendation 2: Dependency Detection Workflow

**Step 1: Pre-Archival Dependency Audit**
```bash
# Identify all dependencies for target file
TARGET="lib/feature-specific.sh"
grep -r "source.*${TARGET}" .claude/commands/
grep -r "source.*${TARGET}" .claude/lib/

# Count consuming commands
CONSUMERS=$(grep -r "source.*${TARGET}" .claude/commands/ | wc -l)
echo "Consumers: $CONSUMERS"
```

**Step 2: Archive Decision Matrix**
- 0 consumers → Priority 4 (SAFE)
- 1 consumer → Priority 3 (SAFE if command archived)
- 2-4 consumers → Priority 2 (CAUTION)
- 5+ consumers → Priority 1 (NEVER)

**Step 3: Sequenced Archival**
1. Archive consuming commands first
2. Verify all tests pass
3. Archive library second
4. Verify fail-fast detection works (attempt to invoke archived command)
5. Commit with clear message

**Step 4: Verification Checkpoints**
```bash
# After archival, test fail-fast behavior
source .claude/lib/archived-file.sh 2>&1
# Expected: "No such file or directory" error

# Verify active commands still work
/coordinate "test workflow"
# Expected: Success (no sourcing errors)
```

### Recommendation 3: Archive Structure and Organization

**Directory Structure**:
```
.claude/archive/
├── commands/          # Archived slash commands (8 files)
├── agents/            # Archived agents (ONLY if NO consumers)
├── lib/               # Archived libraries (ONLY Tier 4-5)
└── templates/         # Archived templates (feature-specific)
```

**Gitignore Policy**:
- `.claude/archive/` should be COMMITTED (rollback capability)
- Follows clean-break philosophy (git history as archive)
- No need for separate archive documentation (use git log)

**Naming Convention**:
- Keep original filename in archive
- No timestamp suffixes (git handles versioning)
- Example: `.claude/archive/commands/refactor.md` (not `refactor-archived-20251115.md`)

### Recommendation 4: Fail-Fast Verification After Archival

**Test Suite Requirements**:
1. **Active Command Test**: Verify all 13 active commands execute without source errors
2. **Archived Command Test**: Verify archived commands fail-fast with clear errors
3. **Library Dependency Test**: Source all active libraries to detect missing dependencies
4. **Agent Invocation Test**: Invoke all active agents through Task tool

**Verification Script Pattern**:
```bash
#!/usr/bin/env bash
# test_archival_safety.sh

set -euo pipefail

echo "Testing active commands..."
for cmd in plan implement coordinate research debug; do
  if ! /$cmd --help &>/dev/null; then
    echo "ERROR: /$cmd failed (possible missing library)"
    exit 1
  fi
done

echo "Testing archived commands fail-fast..."
if /archived-command 2>&1 | grep -q "No such file"; then
  echo "✓ Archived command fails as expected"
else
  echo "ERROR: Archived command should fail"
  exit 1
fi

echo "✓ All archival safety checks passed"
```

### Recommendation 5: Phased Archival Approach

**Phase 1: Command-Only Archival** (Low Risk)
- Target: Command markdown files only
- Preserve: All libraries, agents, templates
- Example: 8 commands already successfully archived
- Verification: Run test suite, confirm active commands work

**Phase 2: Feature-Specific Library Archival** (Medium Risk)
- Target: Tier 4 libraries (1 consumer each)
- Prerequisite: Consuming command already archived
- Example: Archive convert-core.sh AFTER convert-docs.md archived
- Verification: Grep confirms no remaining consumers

**Phase 3: Standalone Utility Archival** (Low Risk)
- Target: Tier 5 libraries (0 consumers)
- No dependencies to break
- Example: optimize-claude-md.sh (standalone script)
- Verification: Grep confirms no `source` statements

**Phase 4: Agent Archival** (HIGH Risk - Avoid Unless Necessary)
- Target: Agents with 0 consuming commands
- Prerequisite: Extensive verification (ALL commands tested)
- Caution: Agents are shared resources, archival rarely safe
- Recommendation: Avoid agent archival in most cases

**Phase 5: Core Library Archival** (EXTREME Risk - Not Recommended)
- Target: Tier 1-2 libraries
- Prerequisite: Major architectural refactor
- Risk: Breaking 5-15 active commands
- Recommendation: Only if replacing with better abstraction

### Recommendation 6: Rollback and Recovery Strategy

**Git-Based Rollback** (Clean-Break Philosophy):
```bash
# If archival breaks workflow, immediate rollback
git log --oneline | grep "archive"  # Find archival commit
git revert <commit-hash>            # Revert archival

# Alternative: Restore specific file
git checkout HEAD~1 .claude/lib/archived-file.sh
```

**No Separate Backup Files** (CLAUDE.md:122-126):
- No backup files with `.backup` suffix
- No migration tracking spreadsheets
- Git history serves as complete rollback mechanism
- Aligns with clean-break philosophy

**Verification After Restore**:
1. Source restored library to confirm no errors
2. Run full test suite
3. Verify active commands execute successfully
4. Commit restoration with clear message

### Recommendation 7: Documentation Standards for Archival

**What to Document** (Present-Focused):
- Current state of .claude/ directory structure
- Active commands and their purposes
- Archive location and contents

**What NOT to Document** (Avoid Historical Commentary):
- No "previously X was Y" statements
- No archival history timelines
- No migration tracking tables
- Use git log for historical context

**Example Documentation Pattern**:
```markdown
## Commands

Active commands (13 total):
- /coordinate - Multi-agent workflow orchestration
- /implement - Plan execution with testing
- /plan - Implementation plan creation
... (list continues)

Archived commands available in .claude/archive/commands/ for reference.
```

**Avoid**:
```markdown
## Commands

The following commands were archived on 2025-11-15 as part of cleanup:
- /refactor (previously used for code quality analysis)
- /analyze (previously used for metrics)
... (historical commentary - violates clean-break philosophy)
```

## References

### Core Documentation
- `/home/benjamin/.config/CLAUDE.md` - Clean-break philosophy (lines 99-128), configuration portability
- `/home/benjamin/.config/.claude/specs/721_archive_commands_in_order_to_provide_a_detailed/reports/000_comprehensive_summary.md` - Archival precedent analysis (8 commands)
- `/home/benjamin/.config/.claude/specs/720_dropdown_menumd_and_i_also_get_commands_that_i/plans/001_dropdown_menumd_and_i_also_get_commands_that_i_plan.md` - Clean-break removal pattern (lines 1-99)

### Library Files Analyzed
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:1-49` - State machine dependencies, source patterns
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh:1-51` - Bundle composition, base-utils sourcing
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:1-99` - Checkpoint schema, save/restore functions
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh:1-99` - Fail-fast verification patterns

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/research.md:51-55` - Library sourcing pattern (5 libraries)
- `/home/benjamin/.config/.claude/commands/coordinate.md:104,251,596,886` - workflow-state-machine.sh sourcing
- `/home/benjamin/.config/.claude/commands/plan.md:30,62` - complexity-utils.sh, extract-standards.sh sourcing
- `/home/benjamin/.config/.claude/commands/implement.md:22,55,102,139` - Multi-library sourcing pattern

### Archived Commands Reference
- `/home/benjamin/.config/.claude/archive/commands/refactor.md` - 13,316 bytes
- `/home/benjamin/.config/.claude/archive/commands/analyze.md` - 11,242 bytes
- `/home/benjamin/.config/.claude/archive/commands/test.md` - 3,664 bytes
- `/home/benjamin/.config/.claude/archive/commands/test-all.md` - 3,082 bytes
- (4 additional archived commands listed in comprehensive summary)

### Git History
- Commit `0e344025` - feat(720): complete Phase 4 - Update Documentation
- Commit `7f656046` - feat(720): complete Phase 2 - Complete Removal
- Commit `ef7f93b0` - feat(720): complete Phase 1 - Audit and Backup
- Commit `a545a17e` - feat(718): complete Phase 2 - Clean-Break Removal

### Dependency Analysis
- Grep output: 100+ source statements across 62 library files
- Tier 1 libraries: 15+ consumers each (detect-project-dir.sh, base-utils.sh)
- Tier 2 libraries: 5-10 consumers each (plan-core-bundle.sh, workflow-state-machine.sh)
- Tier 4-5 libraries: 0-1 consumers (safe archival candidates)
