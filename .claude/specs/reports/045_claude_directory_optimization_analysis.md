# .claude/ Directory Optimization Analysis

## Metadata
- **Report Number**: 045
- **Date**: 2025-10-13
- **Scope**: Comprehensive analysis of .claude/ directory bloat, redundancy, and optimization opportunities
- **Primary Directory**: /home/benjamin/.config/.claude/
- **Total Files Analyzed**: 353 files (7.6M total size)
- **Research Methods**: Directory structure analysis, code quality review, dependency mapping, context usage analysis
- **Priority**: Preserve all critical functionality while optimizing for context preservation and removing bloat

## Executive Summary

The `.claude/` directory contains a mature and comprehensive workflow automation system with 353 files across 11 subsystems, totaling 7.6M. Analysis reveals significant optimization opportunities:

- **Bloat Removal**: 442KB of backup files, deprecated commands, and scattered temporary files can be safely removed
- **Unused Systems**: Template system (40% complete, 0 integration) and TTS system (complete, 0 integration) are candidates for archival or removal
- **Context Optimization**: 35% reduction potential in large commands/agents (5,750+ lines) through consolidation and reference extraction
- **Code Quality**: 3 utilities >1500 lines can be refactored into modular components
- **Redundancy**: Duplicate patterns, fragmented documentation, and mixed naming conventions can be consolidated

**Critical Finding**: All high-value functionality (orchestration, adaptive planning, checkpoint resume, progressive structure, error recovery) must be preserved. Optimization focuses on removing cruft and improving maintainability without feature loss.

## 1. Bloat Identification Summary

### Quick Reference: Bloat Components

| Component | Size | Risk | Action | Savings |
|-----------|------|------|--------|---------|
| `commands/backups/phase4_20251010/` | 432KB | Low | Remove | 432KB |
| 10 scattered `.backup`/`.new` files | ~10KB | Low | Remove | 10KB |
| `specs/plans/004_docs_refactoring/` | 232KB | Low | Archive/Remove | 232KB |
| `/update` command (deprecated) | ~3KB | Low | Remove | 3KB |
| **Total Bloat** | **~677KB** | **Low** | **Remove All** | **677KB** |

### 1.1 Command Backup Directory

**Location**: `.claude/commands/backups/phase4_20251010/`
**Contents**: 20 backup commands from Phase 4 refactoring (October 10, 2025)
**Size**: 432KB
**Analysis**: Git history provides version control; backups are redundant
**Recommendation**: **Remove entire directory** - No functionality loss

### 1.2 Scattered Backup Files

**Plan Backups** (7 files in `.claude/specs/plans/`):
- `026_complete_nvim_refactor.md.backup`
- `027_system_optimization_refactor.md.backup`
- `028_complete_system_optimization.md.backup` (+ 2 revisions)
- `031_filetype_aware_surround_configuration.md.backup`
- `032_nvim_config_comprehensive_improvement.md.backup`

**Test Backups** (3 files in `.claude/tests/`):
- `test_smart_checkpoint_resume.sh.backup`
- `test_smart_checkpoint_resume.sh.new` (0 bytes - empty)

**Recommendation**: **Remove all 10 files** - Development artifacts, purpose fulfilled

### 1.3 Obsolete Validation Scripts

**Location**: `.claude/specs/plans/004_docs_refactoring/`
**Contents**: 3 validation scripts (`validate_emojis.sh`, `validate_orphans.sh`, `validate_links.sh`)
**Size**: 232KB
**Analysis**: One-time validation utilities for completed refactoring
**Recommendation**: **Remove** - Validation complete, one-time use

### 1.4 Deprecated `/update` Command

**Location**: `.claude/commands/update.md`
**Status**: Marked deprecated in CLAUDE.md, superseded by `/revise`
**Recommendation**: **Remove command file** - Replacement established

## 2. Unused Systems Analysis

### 2.1 Template System (40% Complete, 0 Integration)

**Components**:
- Commands: `plan-wizard.md` (719 lines), `plan-from-template.md` (569 lines)
- Utilities: `parse-template.sh` (157 lines), `substitute-variables.sh` (196 lines)
- Templates: 10 YAML files (~50KB)
- Tests: `test_template_system.sh`
- **Total**: ~1,750 lines of code

**Integration Status**: ❌ **0 references in active commands**

**Value Assessment**:
- Potential value: Could accelerate plan creation
- Current value: Zero (no usage)
- Completion: 40% (commands exist, no integration)

**Recommendation Options**:
1. **Remove** (Recommended) - No current usage, adaptive planning may be superior
2. **Archive** - Move to `.claude/archive/template-system/` for potential future completion
3. **Complete** (~10-15 hours) - Integrate with `/plan` command (questionable benefit)

**Decision**: **Defer to user** - Ask: "Do you want template-based planning, or is adaptive planning sufficient?"

### 2.2 TTS System (Complete Implementation, 0 Integration)

**Components**:
- Core: 3 files in `.claude/tts/` (`tts-config.sh`, `tts-messages.sh`, `README.md`)
- Hooks: 3 files in `.claude/hooks/` (`tts-dispatcher.sh`, `post-command-metrics.sh`, `post-subagent-metrics.sh`)
- **Total**: ~100KB, complete implementation

**Integration Status**: ❌ **0 references in command files**

**Analysis**: TTS hooks are "user-configured in settings" (per hook documentation). System may be activated outside `.claude/` directory.

**Recommendation**: **Investigate before removal**

**Questions for User**:
1. Do you use TTS (text-to-speech) notifications during workflows?
2. Have you configured TTS hooks in Claude Code settings?
3. If not used, should it be removed or archived?

**If NOT used**: Remove (~100KB savings) or archive
**If used**: Keep and document in CLAUDE.md

## 3. Redundancy Analysis

### 3.1 Agent Definition Fragmentation

**Finding**: doc-converter agent has 3 related files with unclear boundaries

**Files**:
- `doc-converter.md` (58KB, 1,871 lines) - Primary conversion agent
- `doc-converter-update.md` (2.3KB, 93 lines) - Update log (marker_pdf command change)
- `doc-converter-usage.md` (7.2KB, 283 lines) - Quick start guide

**Analysis**:
- `doc-converter.md`: Main agent definition (keep)
- `doc-converter-update.md`: **Historical update log** (not needed, violates "no historical documentation" principle)
- `doc-converter-usage.md`: Quick start guide (useful, but could be integrated into main agent)

**Recommendation**:
1. **Remove** `doc-converter-update.md` (2.3KB) - Historical artifact, information now in main agent
2. **Consolidate** `doc-converter-usage.md` into `doc-converter.md` or extract to shared examples
3. Net savings: 2.3KB minimum, up to 9.5KB if consolidated

### 3.2 Duplicate README Pattern

**Finding**: `lib/README.md` and `lib/UTILS_README.md` both exist

**Analysis Needed**: Verify if these are:
- Duplicate documentation (consolidate)
- Different purposes (one for utilities, one for library overview)

**Recommendation**: Read both files to determine redundancy, then consolidate or clarify distinction

### 3.3 Code Duplication Patterns

**Cross-Platform Timestamp Handling** (repeated in 3+ files):
```bash
# Appears in checkpoint-utils.sh:79, adaptive-planning-logger.sh:67, etc.
stat -c %Y "$file" 2>/dev/null || stat -f %m "$file"
```

**Recommendation**: Extract to `get_file_mtime()` utility in shared library

**Date Formatting Patterns** (repeated across files):
```bash
# Similar patterns in multiple utilities
date '+%Y-%m-%d %H:%M:%S'
date '+%s'
```

**Recommendation**: Create `format_timestamp()` and `get_unix_time()` utility functions

**Validation Patterns** (15+ instances):
```bash
[[ -z "$var" ]] && error "Parameter required"
```

**Recommendation**: Create `require_param()` validation function

## 4. Code Quality Issues

### 4.1 Overly Complex Files (>1500 lines)

| File | Lines | Functions | Recommendation |
|------|-------|-----------|----------------|
| `auto-analysis-utils.sh` | 1,755 | ~30 | Split into: agent invocation, phase analysis, stage analysis, artifact mgmt |
| `convert-docs.sh` | 1,502 | ~30 | Extract validation, conversion engines, parallel processing to modules |
| `parse-adaptive-plan.sh` | 1,298 | 33 | Group into logical modules: detection, expansion, collapse, metadata |

**Total Complexity**: 4,555 lines across 3 files
**Target**: Modularize into 9-12 focused files (300-500 lines each)
**Benefit**: Easier maintenance, better testability, reduced context per operation

### 4.2 Inefficient Patterns

**Multiple grep -c Calls** (complexity-utils.sh:86-110):
```bash
# Current: Multiple passes over same file
task_count=$(grep -c "^- \[ \]" "$file")
file_count=$(grep -c "^  - " "$file")
```

**Recommendation**: Single awk pass to count multiple patterns

**Nested Command Substitutions** (checkpoint-utils.sh:49-148):
```bash
# Building JSON with nested $(...)
json=$(echo "{\"phase\": \"$(get_phase)\", \"status\": \"$(get_status)\"}")
```

**Recommendation**: Use jq or streaming JSON builder

### 4.3 Error Handling Improvements

**Generic Error Codes** (many functions):
```bash
return 1  # No context about what failed
```

**Recommendation**: Implement structured error returns (see error-utils.sh patterns):
- Error code + context
- Validation at function boundaries
- Specific error messages

## 5. Context Preservation Opportunities

### 5.1 Context-Heavy Components

| Component | Current Size | Target Size | Savings | Strategy |
|-----------|--------------|-------------|---------|----------|
| `orchestrate.md` | 5,628 lines | ~3,000 lines | 2,628 (46%) | Consolidate examples, extract templates |
| `implement.md` | 1,803 lines | ~1,000 lines | 803 (44%) | Consolidate dashboard examples, extract patterns |
| `doc-converter.md` | 1,871 lines | ~800 lines | 1,071 (57%) | Extract logging patterns, move standalone script |
| `auto-analysis-utils.sh` | 1,755 lines | ~900 lines | 855 (48%) | Consolidate boilerplate, extract helpers |
| `convert-docs.sh` | 1,502 lines | ~1,000 lines | 502 (33%) | Extract validation, use helper libraries |

**Total Estimated Savings**: ~5,850 lines (35% reduction)
**Method**: Extract to reference files, consolidate duplicate examples, modularize utilities
**Risk**: Low - No functionality loss, improved maintainability

### 5.2 Simplification Strategies

**Strategy 1: Extract Orchestration Templates**
- Move phase templates from `orchestrate.md` to `.claude/templates/orchestration-patterns.md`
- Reference in main command: "See orchestration-patterns.md for templates"
- Savings: ~1,000 lines

**Strategy 2: Create Shared Examples File**
- Extract common command patterns (dry-run, dashboard, checkpoint) to `.claude/docs/command-examples.md`
- Reference across multiple commands
- Savings: ~500 lines across all commands

**Strategy 3: Consolidate Logging Patterns**
- Extract verbose logging examples from `doc-converter.md` to reusable snippets
- Create `.claude/docs/logging-patterns.md`
- Savings: ~300 lines

**Strategy 4: Modularize Large Utilities**
- Split `auto-analysis-utils.sh` into focused modules
- Benefits: Reduced context per operation, better testability
- Savings: Not line count, but context usage per invocation

**Strategy 5: Reference External Docs**
- Link to Pandoc, marker-pdf docs instead of inline duplication
- Remove redundant tool usage examples
- Savings: ~200 lines across agents

## 6. High-Value Functionality Preservation

### 6.1 Critical Components (Must Preserve)

**Commands** (Breaking change if removed):
- `/orchestrate` - Primary workflow coordination, documented in CLAUDE.md
- `/implement` - Core execution engine with auto-resume and adaptive planning
- `/plan` - Standards-aware planning with complexity analysis
- `/revise` - Auto-mode used by /implement adaptive planning
- `/expand` & `/collapse` - Manual structure control
- `/test`, `/test-all` - Testing infrastructure
- `/report`, `/debug`, `/document` - Workflow support commands

**Utilities** (Used by 5+ commands):
- `checkpoint-utils.sh` (769 lines, 13 functions) - Smart auto-resume, used by /implement and /orchestrate
- `error-utils.sh` (809 lines, 20 functions) - 4-level error recovery, used by 5+ commands
- `complexity-utils.sh` (770 lines, 11 functions) - Hybrid complexity evaluation, enables adaptive planning
- `adaptive-planning-logger.sh` (370 lines, 13 functions) - Structured logging, audit trail for replanning
- `parse-adaptive-plan.sh` (1,298 lines, 33 functions) - Progressive structure parsing (Level 0/1/2)

**Test Infrastructure**:
- `run_all_tests.sh` - Test runner
- 34 active test files (90.6% passing)
- Coverage: parsing (100%), progressive (90%), state mgmt (85%), utilities (90.6%)

**Unique Features**:
- Adaptive Planning - Auto-revision during implementation (2-replan-per-phase limit)
- Progressive Structure - Three-level organization (file → phase-expanded → stage-expanded)
- Smart Checkpoint Resume - 90% auto-resume rate with safety checks
- Multi-Agent Orchestration - Parallel research, sequential planning, conditional debugging
- Hybrid Complexity Evaluation - Threshold + agent-based scoring

### 6.2 Preservation Requirements by Priority

**Must Preserve** (Breaking change if removed):
- Core commands: /orchestrate, /implement, /plan, /revise, /expand, /collapse
- Core utilities: checkpoint-utils.sh, error-utils.sh, complexity-utils.sh, parse-adaptive-plan.sh
- Test infrastructure: run_all_tests.sh, 34 test files
- Adaptive planning integration
- Progressive structure system

**Should Preserve** (Significant value, alternatives exist):
- /expand, /collapse (manual control, auto-expansion works)
- adaptive-planning-logger.sh (audit trail, helpful but not blocking)
- progress-dashboard.sh (visual feedback, text markers fallback)
- artifact-utils.sh (tracking, 878 lines, 20 functions)

**Nice to Have** (Limited usage, some value):
- /analyze (metrics analysis, 351 lines)
- /convert-docs (document conversion, 1502 lines)
- /plan-from-template (template planning, 569 lines)
- workflow-metrics.sh (performance tracking, 215 lines)

## 7. Optimization Recommendations

### 7.1 Immediate Actions (Low Risk, High Impact)

**Priority 1: Remove Bloat** (677KB savings, 1-2 hours)
1. Remove `.claude/commands/backups/phase4_20251010/` directory (432KB)
2. Remove 10 scattered `.backup`/`.new` files (~10KB)
3. Remove `.claude/specs/plans/004_docs_refactoring/` validation scripts (232KB)
4. Remove `/update` command (deprecated, 3KB)

**Priority 2: Investigate Unused Systems** (Defer to user)
1. **Template System**: Ask user if needed, remove/archive if not (~1,750 lines)
2. **TTS System**: Ask user if configured, remove/archive if not (~100KB)

**Priority 3: Clean Documentation Artifacts** (2.3KB savings, 30 minutes)
1. Remove `doc-converter-update.md` (historical artifact, 2.3KB)
2. Consider consolidating `doc-converter-usage.md` into main agent

### 7.2 Context Preservation Simplifications (35% reduction, 8-10 hours)

**Phase 1: Extract Reference Files** (3-4 hours)
1. Create `.claude/templates/orchestration-patterns.md` with phase templates (~1,000 lines extracted from orchestrate.md)
2. Create `.claude/docs/command-examples.md` with common patterns (~500 lines extracted from multiple commands)
3. Create `.claude/docs/logging-patterns.md` with logging examples (~300 lines extracted from agents)
4. Update commands/agents to reference these files instead of inline duplication

**Phase 2: Consolidate Examples** (2-3 hours)
1. orchestrate.md: Remove 6 redundant dry-run examples, keep 1 reference (save ~600 lines)
2. implement.md: Consolidate 3+ dashboard examples into 1 (save ~300 lines)
3. doc-converter.md: Remove standalone script template to separate reference (save ~280 lines)

**Phase 3: Simplify Agents** (2-3 hours)
1. doc-converter.md: Consolidate logging patterns section (lines 661-983, save ~300 lines)
2. doc-converter.md: Consolidate 5 orchestration phases (near-identical structure, save ~400 lines)
3. doc-converter.md: Consolidate tool detection examples (4 similar examples → 1, save ~100 lines)

**Total Context Savings**: ~5,850 lines (35% reduction in analyzed components)

### 7.3 Code Quality Refactoring (20-30 hours)

**Phase 1: Extract Shared Utilities** (5-6 hours)
1. Create `timestamp-utils.sh` with platform-independent timestamp functions
2. Create `validation-utils.sh` with `require_param()` and common validators
3. Update 15+ files to use shared utilities instead of duplication

**Phase 2: Modularize Complex Files** (10-12 hours)
1. Split `auto-analysis-utils.sh` (1,755 lines) into:
   - `agent-invocation.sh` (~400 lines)
   - `phase-analysis.sh` (~400 lines)
   - `stage-analysis.sh` (~400 lines)
   - `artifact-management.sh` (~400 lines)

2. Split `convert-docs.sh` (1,502 lines) into:
   - `conversion-core.sh` (~500 lines)
   - `conversion-validation.sh` (~400 lines)
   - `conversion-parallel.sh` (~400 lines)

3. Split `parse-adaptive-plan.sh` (1,298 lines) into:
   - `plan-detection.sh` (~400 lines)
   - `plan-expansion.sh` (~400 lines)
   - `plan-collapse.sh` (~300 lines)
   - `plan-metadata.sh` (~200 lines)

**Phase 3: Improve Efficiency** (5-7 hours)
1. Replace multiple `grep -c` calls with single awk passes
2. Use jq for all JSON manipulation
3. Implement structured error returns across all utilities
4. Add validation at function boundaries

**Total Investment**: 20-25 hours
**Benefit**: Easier maintenance, better testability, reduced context, improved performance

### 7.4 Structural Improvements (4-6 hours)

**Cleanup Naming Inconsistencies** (1-2 hours)
1. Standardize on hyphens for all filenames (commands, agents, libraries)
2. Rename inconsistent files:
   - `collapse_specialist.md` → `collapse-specialist.md`
   - `complexity_estimator.md` → `complexity-estimator.md`
   - Mixed test files → standardize on `test-*` pattern

**Consolidate Duplicate READMEs** (1 hour)
1. Review `lib/README.md` and `lib/UTILS_README.md`
2. Consolidate if redundant, clarify if different purposes
3. Ensure single source of truth for library documentation

**Clean Test Fixtures** (1-2 hours)
1. Consolidate test plans in `specs/plans/test_*` and `specs/plans/test_adaptive/`
2. Consider moving to `.claude/tests/fixtures/` for better organization
3. Remove obsolete test checkpoint directories

**Clarify Checkpoint Directories** (1 hour)
1. Verify purpose of `.claude/checkpoints/` vs `.claude/data/checkpoints/`
2. Consolidate if redundant
3. Document distinction if both needed

## 8. Risk Assessment

### 8.1 Risk Matrix

| Action | Functionality Risk | Context Savings | Effort | Priority |
|--------|-------------------|-----------------|--------|----------|
| Remove bloat (677KB) | **Low** | Medium | 1-2h | **High** |
| Remove unused systems | **Low** (after user confirm) | High | 1h | **High** |
| Context simplification | **Very Low** | High (35%) | 8-10h | **High** |
| Code refactoring | **Low** | Low (indirect) | 20-30h | Medium |
| Structural improvements | **Very Low** | Low | 4-6h | Medium |

### 8.2 Safety Measures

**Before Any Removal**:
1. ✓ Git commit current state (create checkpoint)
2. ✓ Run full test suite: `.claude/tests/run_all_tests.sh`
3. ✓ Verify 90%+ tests passing
4. ✓ User confirmation for any high-value components

**After Each Phase**:
1. ✓ Run test suite again
2. ✓ Verify no regressions
3. ✓ Test key workflows: /orchestrate, /implement, /plan
4. ✓ Git commit with descriptive message

**Rollback Plan**:
- Git history provides full rollback capability
- Checkpoint each phase separately for granular rollback
- If tests fail, rollback immediately

## 9. Implementation Roadmap

### Phase 1: Bloat Removal (1-2 hours, Low Risk)

**Immediate Removals** (no user input needed):
1. Remove `.claude/commands/backups/phase4_20251010/` (432KB)
2. Remove 10 scattered `.backup`/`.new` files (10KB)
3. Remove `.claude/specs/plans/004_docs_refactoring/` (232KB)
4. Remove `/update` command (3KB)
5. Remove `doc-converter-update.md` (2.3KB)
6. Update CLAUDE.md to remove `/update` from command list

**Expected Results**:
- 679KB removed
- Cleaner directory structure
- No functionality loss

### Phase 2: User Decision Points (30 minutes discussion)

**Questions for User**:
1. **Template System** (1,750 lines):
   - Do you want template-based planning?
   - Is adaptive planning sufficient?
   - Action: Remove, Archive, or Complete?

2. **TTS System** (100KB):
   - Do you use TTS notifications?
   - Is it configured in your settings?
   - Action: Remove, Archive, or Document?

3. **Context Optimization** (5,850 lines potential):
   - Priority: High, Medium, or Low?
   - Acceptable effort: 8-10 hours for 35% reduction?

4. **Code Refactoring** (20-30 hours):
   - Priority: High, Medium, or Low?
   - Value: Better maintainability vs time investment?

### Phase 3: Context Preservation (8-10 hours, Low Risk)

**If user approves**:
1. Extract reference files (3-4 hours)
2. Consolidate examples (2-3 hours)
3. Simplify agents (2-3 hours)
4. Test after each step

**Expected Results**:
- 35% context reduction in large components
- No functionality loss
- Improved maintainability

### Phase 4: Code Quality (20-30 hours, Medium Effort)

**If user prioritizes quality**:
1. Extract shared utilities (5-6 hours)
2. Modularize complex files (10-12 hours)
3. Improve efficiency (5-7 hours)
4. Comprehensive testing after each module

**Expected Results**:
- Easier maintenance
- Better testability
- Reduced context per operation
- Improved performance

### Phase 5: Structural Improvements (4-6 hours, Low Risk)

**Low priority, high polish**:
1. Naming consistency (1-2 hours)
2. README consolidation (1 hour)
3. Test fixture cleanup (1-2 hours)
4. Checkpoint directory clarification (1 hour)

**Expected Results**:
- Consistent naming conventions
- Clearer organization
- Better documentation

## 10. Success Metrics

### Quantitative Metrics

**Bloat Removal**:
- ✓ 679KB removed (target: 677KB minimum)
- ✓ 0 backup files remaining
- ✓ 0 deprecated commands

**Context Optimization**:
- ✓ 35% reduction in large components (target: 5,850 lines)
- ✓ 3 reference files created
- ✓ Duplicate examples consolidated

**Code Quality**:
- ✓ 3 files >1500 lines → 9-12 files <500 lines each
- ✓ 5+ shared utilities extracted
- ✓ Code duplication reduced by 50%

**Testing**:
- ✓ Test pass rate maintained at 90%+
- ✓ No regressions in key workflows
- ✓ All critical features functional

### Qualitative Metrics

**Maintainability**:
- ✓ Files easier to understand (<500 lines each)
- ✓ Clear separation of concerns
- ✓ Reduced code duplication

**Context Preservation**:
- ✓ Commands load faster (less to read)
- ✓ Agent invocations use less context
- ✓ Reference files reduce inline documentation

**User Experience**:
- ✓ No feature loss
- ✓ All workflows functional
- ✓ Cleaner directory structure

## 11. Conclusion

The `.claude/` directory is a mature, well-designed workflow automation system with **353 files across 11 subsystems**. Analysis reveals **significant optimization opportunities** while preserving all critical functionality:

### Key Findings

1. **Bloat**: 679KB can be removed immediately (backups, deprecated commands, temp files)
2. **Unused Systems**: Template and TTS systems (1,850+ lines) need user decision
3. **Context**: 35% reduction possible (5,850 lines) through consolidation
4. **Quality**: 3 large files (4,555 lines) benefit from modularization
5. **Critical Features**: All high-value functionality must be preserved

### Recommended Approach

**Immediate** (1-2 hours):
- Remove 679KB bloat (low risk, high impact)

**Short-term** (8-10 hours):
- Context optimization (35% reduction, low risk)
- User decisions on template/TTS systems

**Long-term** (20-30 hours):
- Code quality refactoring (better maintainability)
- Structural improvements (polish)

### Success Criteria

✓ **No functionality loss**
✓ **35% context reduction in large components**
✓ **679KB bloat removed**
✓ **90%+ test pass rate maintained**
✓ **Improved maintainability**

### Next Steps

1. **User Input**: Get decisions on template/TTS systems and optimization priorities
2. **Create Plan**: Generate implementation plan based on user priorities
3. **Execute**: Phase-by-phase implementation with testing after each phase
4. **Validate**: Comprehensive testing and user validation

The optimization can be completed in **9-12 hours of active work** for full context optimization, or **1-2 hours** for bloat removal only, depending on user priorities.

## References

### Key Files Analyzed

**Commands**: `.claude/commands/orchestrate.md`, `implement.md`, `plan.md`, `revise.md`, etc.
**Agents**: `.claude/agents/doc-converter.md`, `research-specialist.md`, etc.
**Libraries**: `.claude/lib/auto-analysis-utils.sh`, `checkpoint-utils.sh`, `error-utils.sh`, etc.
**Tests**: `.claude/tests/run_all_tests.sh`, `test_*.sh` (40 files)
**Documentation**: `CLAUDE.md`, `.claude/docs/`, etc.

### Related Reports

- Report 037: Document Conversion Analysis
- Report 042: Orchestrate Subagent Invocation Diagnosis
- Report 043: Orchestrate/Implement Improvement Opportunities
- Report 044: Plan 043 Revision Recommendations

### Cross-References

- CLAUDE.md documentation standards (Development Philosophy → Documentation Standards)
- Adaptive Planning configuration (CLAUDE.md → Adaptive Planning section)
- Test infrastructure (CLAUDE.md → Testing Protocols section)
