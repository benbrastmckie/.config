# Library Directory Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: .claude/lib/ directory systematic refactor
- **Scope**: Archive unused libraries, organize active libraries into subdirectories, update all references
- **Estimated Phases**: 5
- **Estimated Hours**: 18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 325.0
- **Research Reports**:
  - [Library Directory Refactor Analysis](../reports/001_lib_directory_refactor_analysis.md)

## Overview

The `.claude/lib/` directory has become bloated with 63 library files totaling ~872KB. Analysis reveals that 16 libraries (25%) have zero external references and should be archived, while 47 active libraries can be logically organized into 6 functional subdirectories. This refactor will improve discoverability, reduce clutter, and maintain comprehensive documentation through README files in each subdirectory.

**Key Goals:**
1. Archive 16 unused libraries to preserve them while cleaning the active workspace
2. Organize 47 active libraries into 6 logical subdirectories (core/, workflow/, plan/, artifact/, convert/, util/)
3. Update all source references throughout .claude/ (excluding specs/, archive/, backups/)
4. Create comprehensive README documentation in each subdirectory
5. Validate all functionality through testing

## Research Summary

Based on the Library Directory Refactor Analysis research report:

**Usage Distribution Finding**: Libraries fall into clear usage tiers - 7 high-usage core libraries (10+ references), 11 medium-usage workflow libraries (5-9 references), and the rest specialized or unused.

**Unused Library Finding**: 16 libraries have zero external references and are candidates for archival: agent-discovery.sh, agent-invocation.sh, agent-registry-utils.sh, agent-schema-validator.sh, analysis-pattern.sh, audit-imperative-language.sh, checkpoint-migration.sh, complexity-thresholds.sh, context-metrics.sh, debug-utils.sh, dependency-analysis.sh, deps-utils.sh, generate-readme.sh, git-utils.sh, json-utils.sh, monitor-model-usage.sh, source-libraries-snippet.sh, timestamp-utils.sh, validate_executable_doc_separation.sh (Note: convert-docx.sh, convert-markdown.sh, convert-pdf.sh have indirect usage through convert-core.sh).

**Documentation Issue Finding**: The current README.md references 12+ non-existent libraries that were previously archived but not updated in documentation.

**Subdirectory Organization Finding**: Libraries logically group into 6 functional domains: core (8), workflow (9), plan (7), artifact (5), convert (4), util (9).

**Recommended Approach**: Execute in phases with validation between each - preparation, archival, migration, documentation, then final validation. Update references in order of impact (tests first, then agents, then commands, then docs).

## Success Criteria

- [ ] All 16 unused libraries archived to .claude/archive/lib/cleanup-2025-11-19/
- [ ] Archive manifest README.md created documenting each archived library
- [ ] All 47 active libraries moved to appropriate subdirectories (core/, workflow/, plan/, artifact/, convert/, util/)
- [ ] All source statements in commands/ updated with new paths
- [ ] All source statements in agents/ updated with new paths
- [ ] All source statements in tests/ updated with new paths
- [ ] Main lib/README.md completely rewritten without non-existent library references
- [ ] Each subdirectory has comprehensive README.md with library descriptions and usage examples
- [ ] All test suites pass after refactor
- [ ] No broken source statements remain

## Technical Design

### Directory Structure After Refactor

```
.claude/lib/
  README.md                    # Main index with subdirectory overview
  core/                        # Essential infrastructure (8 libraries)
    README.md
    state-persistence.sh
    error-handling.sh
    unified-location-detection.sh
    detect-project-dir.sh
    base-utils.sh
    library-sourcing.sh
    library-version-check.sh
    unified-logger.sh
  workflow/                    # Workflow orchestration (9 libraries)
    README.md
    workflow-state-machine.sh
    workflow-initialization.sh
    workflow-init.sh
    workflow-scope-detection.sh
    workflow-detection.sh
    workflow-llm-classifier.sh
    checkpoint-utils.sh
    argument-capture.sh
    metadata-extraction.sh
  plan/                        # Plan management (7 libraries)
    README.md
    plan-core-bundle.sh
    topic-utils.sh
    topic-decomposition.sh
    checkbox-utils.sh
    complexity-utils.sh
    auto-analysis-utils.sh
    parse-template.sh
  artifact/                    # Artifact management (5 libraries)
    README.md
    artifact-creation.sh
    artifact-registry.sh
    overview-synthesis.sh
    substitute-variables.sh
    template-integration.sh
  convert/                     # Document conversion (4 libraries)
    README.md
    convert-core.sh
    convert-docx.sh
    convert-pdf.sh
    convert-markdown.sh
  util/                        # Miscellaneous utilities (9 libraries)
    README.md
    git-commit-utils.sh
    optimize-claude-md.sh
    progress-dashboard.sh
    detect-testing.sh
    generate-testing-protocols.sh
    backup-command-file.sh
    rollback-command-file.sh
    validate-agent-invocation-pattern.sh
    dependency-analyzer.sh
```

### Reference Update Pattern

All source statements will be updated following this pattern:
```bash
# Old pattern
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# New pattern
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
```

### Risk Mitigation

1. **Atomic Commits**: Each phase committed separately to enable rollback
2. **Test Validation**: Run tests after each major change
3. **Backup**: Archive contains full copies of all moved libraries
4. **Order of Updates**: Tests first (easiest to verify), then agents, then commands

## Implementation Phases

### Phase 1: Preparation and Archive Structure [COMPLETE]
dependencies: []

**Objective**: Create archive directory, subdirectory structure, and document current state

**Complexity**: Low

**Tasks**:
- [x] Create archive directory: `.claude/archive/lib/cleanup-2025-11-19/`
- [x] Create lib subdirectories: `core/`, `workflow/`, `plan/`, `artifact/`, `convert/`, `util/`
- [x] Create archive manifest template: `.claude/archive/lib/cleanup-2025-11-19/README.md`
- [x] Document list of 16 libraries to archive with their original purposes
- [x] Create README template for subdirectories

**Testing**:
```bash
# Verify directories created
ls -la .claude/archive/lib/cleanup-2025-11-19/
ls -la .claude/lib/core/ .claude/lib/workflow/ .claude/lib/plan/ .claude/lib/artifact/ .claude/lib/convert/ .claude/lib/util/
```

**Expected Duration**: 1 hour

---

### Phase 2: Archive Unused Libraries [COMPLETE]
dependencies: [1]

**Objective**: Move 16 unused libraries to archive with documentation

**Complexity**: Medium

**Tasks**:
- [x] Move `agent-discovery.sh` to archive (file: .claude/lib/agent-discovery.sh)
- [x] Move `agent-invocation.sh` to archive (file: .claude/lib/agent-invocation.sh)
- [x] Move `agent-registry-utils.sh` to archive (file: .claude/lib/agent-registry-utils.sh)
- [x] Move `agent-schema-validator.sh` to archive (file: .claude/lib/agent-schema-validator.sh)
- [x] Move `analysis-pattern.sh` to archive (file: .claude/lib/analysis-pattern.sh)
- [x] Move `audit-imperative-language.sh` to archive (file: .claude/lib/audit-imperative-language.sh)
- [x] Move `checkpoint-migration.sh` to archive (file: .claude/lib/checkpoint-migration.sh)
- [x] Move `complexity-thresholds.sh` to archive (file: .claude/lib/complexity-thresholds.sh)
- [x] Move `context-metrics.sh` to archive (file: .claude/lib/context-metrics.sh)
- [x] Move `debug-utils.sh` to archive (file: .claude/lib/debug-utils.sh)
- [x] Move `dependency-analysis.sh` to archive (file: .claude/lib/dependency-analysis.sh)
- [x] Move `deps-utils.sh` to archive (file: .claude/lib/deps-utils.sh)
- [x] Move `generate-readme.sh` to archive (file: .claude/lib/generate-readme.sh)
- [x] Move `git-utils.sh` to archive (file: .claude/lib/git-utils.sh)
- [x] Move `json-utils.sh` to archive (file: .claude/lib/json-utils.sh)
- [x] Move `monitor-model-usage.sh` to archive (file: .claude/lib/monitor-model-usage.sh)
- [x] Move `source-libraries-snippet.sh` to archive (file: .claude/lib/source-libraries-snippet.sh)
- [x] Move `timestamp-utils.sh` to archive (file: .claude/lib/timestamp-utils.sh)
- [x] Move `validate_executable_doc_separation.sh` to archive (file: .claude/lib/validate_executable_doc_separation.sh)
- [x] Complete archive manifest README with purpose descriptions for each archived library

**Testing**:
```bash
# Verify all 16 libraries archived
ls -la .claude/archive/lib/cleanup-2025-11-19/*.sh | wc -l
# Should show: 19

# Verify archive manifest exists and is complete
wc -l .claude/archive/lib/cleanup-2025-11-19/README.md
```

**Expected Duration**: 2 hours

---

### Phase 3: Migrate Active Libraries to Subdirectories [COMPLETE]
dependencies: [2]

**Objective**: Move 47 active libraries to their functional subdirectories and update all references

**Complexity**: High

**Tasks**:
- [x] Move core libraries (8 files) to `.claude/lib/core/`:
  - state-persistence.sh, error-handling.sh, unified-location-detection.sh, detect-project-dir.sh, base-utils.sh, library-sourcing.sh, library-version-check.sh, unified-logger.sh
- [x] Move workflow libraries (9 files) to `.claude/lib/workflow/`:
  - workflow-state-machine.sh, workflow-initialization.sh, workflow-init.sh, workflow-scope-detection.sh, workflow-detection.sh, workflow-llm-classifier.sh, checkpoint-utils.sh, argument-capture.sh, metadata-extraction.sh
- [x] Move plan libraries (7 files) to `.claude/lib/plan/`:
  - plan-core-bundle.sh, topic-utils.sh, topic-decomposition.sh, checkbox-utils.sh, complexity-utils.sh, auto-analysis-utils.sh, parse-template.sh
- [x] Move artifact libraries (5 files) to `.claude/lib/artifact/`:
  - artifact-creation.sh, artifact-registry.sh, overview-synthesis.sh, substitute-variables.sh, template-integration.sh
- [x] Move convert libraries (4 files) to `.claude/lib/convert/`:
  - convert-core.sh, convert-docx.sh, convert-pdf.sh, convert-markdown.sh
- [x] Move util libraries (9 files) to `.claude/lib/util/`:
  - git-commit-utils.sh, optimize-claude-md.sh, progress-dashboard.sh, detect-testing.sh, generate-testing-protocols.sh, backup-command-file.sh, rollback-command-file.sh, validate-agent-invocation-pattern.sh, dependency-analyzer.sh
- [x] Update internal library dependencies:
  - workflow-scope-detection.sh line 27 (workflow-llm-classifier.sh)
  - workflow-detection.sh line 21 (workflow-scope-detection.sh)
- [x] Update source statements in `.claude/tests/` (20+ files) - update all lib/ paths to subdirectory paths
- [x] Update source statements in `.claude/agents/spec-updater.md` (lines 373, 385, 434, 483, 521, 601, 713)
- [x] Update source statements in `.claude/agents/docs-structure-analyzer.md` (line 78)
- [x] Update source statements in `.claude/agents/cleanup-plan-architect.md` (line 108)
- [x] Update source statements in `.claude/agents/plan-complexity-classifier.md` (line 494)
- [x] Update source statements in `.claude/agents/implementer-coordinator.md` (line 86)
- [x] Update source statements in `.claude/commands/build.md` (lines 77-81, 167, 310-311, 476-477, 625-627, 770-772)
- [x] Update source statements in `.claude/commands/debug.md` (lines 111-119, 209-210, 243-245, 356, 420-421, 505, 554-555, 620, 665-666)
- [x] Update source statements in `.claude/commands/plan.md` (lines 115-123, 260-261, 373-374)
- [x] Update source statements in `.claude/commands/research.md` (lines 114-122, 252-253)
- [x] Update source statements in `.claude/commands/revise.md` (lines 222-227, 289-290, 567-568)
- [x] Update source statements in `.claude/commands/collapse.md` (lines 111, 486-487)
- [x] Update source statements in `.claude/commands/expand.md` (lines 109, 618-619)
- [x] Update source statements in `.claude/commands/convert-docs.md` (line 242)
- [x] Update source statements in `.claude/commands/setup.md` (if any lib references)
- [x] Verify no remaining direct lib/ references (excluding subdirectories)

**Testing**:
```bash
# Verify library counts in each subdirectory
echo "Core: $(ls .claude/lib/core/*.sh 2>/dev/null | wc -l)"
echo "Workflow: $(ls .claude/lib/workflow/*.sh 2>/dev/null | wc -l)"
echo "Plan: $(ls .claude/lib/plan/*.sh 2>/dev/null | wc -l)"
echo "Artifact: $(ls .claude/lib/artifact/*.sh 2>/dev/null | wc -l)"
echo "Convert: $(ls .claude/lib/convert/*.sh 2>/dev/null | wc -l)"
echo "Util: $(ls .claude/lib/util/*.sh 2>/dev/null | wc -l)"

# Verify no old-style lib references remain (excluding archive, specs, backups)
grep -r 'source.*\.claude/lib/[^/]*\.sh' .claude/commands/ .claude/agents/ .claude/tests/ --include="*.md" --include="*.sh" | grep -v 'lib/core/' | grep -v 'lib/workflow/' | grep -v 'lib/plan/' | grep -v 'lib/artifact/' | grep -v 'lib/convert/' | grep -v 'lib/util/'

# Run test suite
bash .claude/tests/test_semantic_slug_commands.sh
```

**Expected Duration**: 8 hours

---

### Phase 4: Documentation Updates [COMPLETE]
dependencies: [3]

**Objective**: Create comprehensive README documentation for all subdirectories and update main lib/README.md

**Complexity**: Medium

**Tasks**:
- [x] Rewrite `.claude/lib/README.md` - complete overhaul removing non-existent library references
  - Add subdirectory overview section
  - Include sourcing examples for each subdirectory
  - Document the migration rationale
  - Add quick reference table
- [x] Create `.claude/lib/core/README.md` with:
  - Purpose: Essential infrastructure libraries
  - List of 8 libraries with function descriptions
  - Usage examples for state-persistence.sh, error-handling.sh
  - Dependencies on other subdirectories
- [x] Create `.claude/lib/workflow/README.md` with:
  - Purpose: Workflow orchestration libraries
  - List of 9 libraries with function descriptions
  - Usage examples for workflow-state-machine.sh, checkpoint-utils.sh
  - Dependencies on core/
- [x] Create `.claude/lib/plan/README.md` with:
  - Purpose: Plan management libraries
  - List of 7 libraries with function descriptions
  - Usage examples for plan-core-bundle.sh, checkbox-utils.sh
  - Dependencies on core/, artifact/
- [x] Create `.claude/lib/artifact/README.md` with:
  - Purpose: Artifact management libraries
  - List of 5 libraries with function descriptions
  - Usage examples for artifact-creation.sh, template-integration.sh
  - Dependencies on core/
- [x] Create `.claude/lib/convert/README.md` with:
  - Purpose: Document conversion libraries
  - List of 4 libraries with function descriptions
  - Usage examples for convert-core.sh
  - Internal dependency documentation (convert-core.sh sources the others)
- [x] Create `.claude/lib/util/README.md` with:
  - Purpose: Miscellaneous utilities
  - List of 9 libraries with function descriptions
  - Usage examples for git-commit-utils.sh, optimize-claude-md.sh
  - Note about potential future deprecation of low-usage libraries
- [x] Update `.claude/agents/README.md` to reference new lib subdirectory structure
- [x] Update any docs/ files that reference lib/ paths (scan .claude/docs/ for lib/ mentions)

**Testing**:
```bash
# Verify all README files exist
ls -la .claude/lib/README.md .claude/lib/*/README.md

# Check for broken internal links in READMEs
grep -h '\[.*\](.*\.sh)' .claude/lib/*/README.md | while read line; do
  file=$(echo "$line" | grep -o '([^)]*\.sh)' | tr -d '()')
  if [ -n "$file" ]; then
    echo "Checking: $file"
  fi
done

# Verify no references to non-existent libraries in main README
grep -E 'plan-parsing|conversion-logger|adaptive-planning-logger|plan-structure-utils|plan-metadata-utils|progressive-planning-utils|validation-utils|parallel-orchestration-utils|structure-eval-utils|analyze-metrics|hierarchical-agent-support|verification-helpers' .claude/lib/README.md
```

**Expected Duration**: 4 hours

---

### Phase 5: Final Validation and Cleanup [COMPLETE]
dependencies: [4]

**Objective**: Comprehensive validation of the refactor and cleanup of any remaining issues

**Complexity**: Medium

**Tasks**:
- [x] Run complete test suite to verify all source statements work
- [x] Execute key commands to verify functionality:
  - `/build` command with a test plan
  - `/debug` command with a test scenario
  - `/plan` command with a simple feature
  - `/research` command with a topic
  - `/convert-docs` command with test files
- [x] Verify agent functionality by invoking agents that use libraries
- [x] Scan for any remaining broken source statements
- [x] Check that all documentation links work
- [x] Remove any empty or redundant files
- [x] Verify .gitignore excludes archive/ appropriately
- [x] Create summary of changes for CHANGELOG
- [x] Commit all changes with detailed commit message

**Testing**:
```bash
# Comprehensive validation
echo "=== Final Validation ==="

# 1. Check no old-style references remain
echo "Checking for old-style lib references..."
OLD_REFS=$(grep -r 'source.*\.claude/lib/[^/]*\.sh' .claude/commands/ .claude/agents/ .claude/tests/ --include="*.md" --include="*.sh" 2>/dev/null | grep -v 'lib/core/' | grep -v 'lib/workflow/' | grep -v 'lib/plan/' | grep -v 'lib/artifact/' | grep -v 'lib/convert/' | grep -v 'lib/util/' | wc -l)
echo "Old-style references: $OLD_REFS (should be 0)"

# 2. Check library counts
echo "Library counts:"
echo "  Core: $(ls .claude/lib/core/*.sh 2>/dev/null | wc -l) (expected: 8)"
echo "  Workflow: $(ls .claude/lib/workflow/*.sh 2>/dev/null | wc -l) (expected: 9)"
echo "  Plan: $(ls .claude/lib/plan/*.sh 2>/dev/null | wc -l) (expected: 7)"
echo "  Artifact: $(ls .claude/lib/artifact/*.sh 2>/dev/null | wc -l) (expected: 5)"
echo "  Convert: $(ls .claude/lib/convert/*.sh 2>/dev/null | wc -l) (expected: 4)"
echo "  Util: $(ls .claude/lib/util/*.sh 2>/dev/null | wc -l) (expected: 9)"
echo "  Archived: $(ls .claude/archive/lib/cleanup-2025-11-19/*.sh 2>/dev/null | wc -l) (expected: 19)"

# 3. Check README presence
echo "README files:"
for dir in core workflow plan artifact convert util; do
  if [ -f ".claude/lib/$dir/README.md" ]; then
    echo "  $dir/README.md: OK"
  else
    echo "  $dir/README.md: MISSING"
  fi
done

# 4. Source statement syntax check
echo "Checking source syntax..."
bash -n .claude/lib/*/*.sh 2>&1 | head -20

echo "=== Validation Complete ==="
```

**Expected Duration**: 3 hours

---

**Note on Expansion**: This plan has a complexity score of 325.0 which qualifies for Tier 3 structure. Consider using `/expand phase 3` if Phase 3 (migration) requires more detailed breakdown during implementation, as it contains the highest number of file modifications.

## Testing Strategy

**Overall Approach**:
- Test after each phase to catch issues early
- Use existing test suite as primary validation
- Manual command execution for integration testing
- Focus on high-impact commands (build, debug, plan)

**Test Commands**:
```bash
# Primary test suite
bash .claude/tests/test_semantic_slug_commands.sh

# Syntax validation for all libraries
for f in .claude/lib/*/*.sh; do bash -n "$f"; done

# Source statement validation
grep -r 'source.*lib/' .claude/commands/ .claude/agents/ | while read line; do
  # Verify each source path exists
  path=$(echo "$line" | grep -o '"[^"]*lib/[^"]*"' | tr -d '"')
  if [ -n "$path" ] && [ ! -f "$path" ]; then
    echo "Missing: $path"
  fi
done
```

## Documentation Requirements

**Files to Update**:
- `.claude/lib/README.md` - Complete rewrite required
- `.claude/lib/core/README.md` - New file
- `.claude/lib/workflow/README.md` - New file
- `.claude/lib/plan/README.md` - New file
- `.claude/lib/artifact/README.md` - New file
- `.claude/lib/convert/README.md` - New file
- `.claude/lib/util/README.md` - New file
- `.claude/agents/README.md` - Update lib references
- `.claude/archive/lib/cleanup-2025-11-19/README.md` - Archive manifest

**Documentation Standards**:
- Follow CommonMark specification
- No emojis in content
- Include code examples with syntax highlighting
- Use clear, concise language
- Cross-reference related libraries

## Dependencies

**Prerequisites**:
- No external tool dependencies
- All changes confined to .claude/ directory
- Git for version control

**Internal Dependencies**:
- Phase 1 must complete before Phase 2 (directories needed)
- Phase 2 must complete before Phase 3 (archive before migrate)
- Phase 3 must complete before Phase 4 (files in place before documenting)
- Phase 4 must complete before Phase 5 (docs done before final validation)

**Risk Factors**:
- High number of file modifications in Phase 3 (100+ edits)
- Internal library dependencies require careful update order
- Test suite must pass or functionality is broken
