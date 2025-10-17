# /setup Command Enhancement and CLAUDE.md Optimization Implementation Plan

## Metadata
- **Date**: 2025-10-16
- **Plan Number**: 061
- **Feature**: Enhanced /setup command with adaptive testing detection, context optimization, and lean CLAUDE.md generation
- **Scope**: Improve existing /setup command and optimize current CLAUDE.md file (648→400 lines), enabling multi-repository usage
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/reports/050_setup_command_improvements.md

## Overview

This plan implements comprehensive improvements to the `/setup` command based on research report 050, focusing on three primary goals:

1. **Optimize Current CLAUDE.md** - Reduce from 648 to ~400 lines (38% reduction) via context optimization
2. **Enhance /setup Command** - Add adaptive testing detection, README scaffolding, incremental updates
3. **Enable Multi-Repository Usage** - Make /setup adaptable across diverse project types

The implementation follows a phased approach: first optimize the existing CLAUDE.md to demonstrate value, then enhance /setup with new capabilities so it can maintain lean configs across all repositories.

## Success Criteria

- [ ] Current CLAUDE.md reduced from 648 to ≤400 lines
- [ ] Directory Protocols (185 lines) and Development Philosophy (95 lines) extracted to reference files
- [ ] /setup command includes adaptive testing detection (score-based, 0-6 points)
- [ ] /setup --optimize mode analyzes and optimizes any CLAUDE.md
- [ ] /setup --generate-readmes creates systematic documentation coverage
- [ ] All new utilities have >80% test coverage
- [ ] Zero manual configuration required for common repository patterns

## Technical Design

### Architecture Overview

```
/setup Command (Enhanced)
├── Core Modes (Existing)
│   ├── Standard mode (improved: uses new utilities)
│   ├── Cleanup mode (--cleanup)
│   ├── Validation mode (--validate)
│   ├── Analysis mode (--analyze)
│   └── Report application (--apply-report)
├── New Modes
│   ├── Optimization mode (--optimize [--dry-run])
│   ├── README generation (--generate-readmes)
│   └── Section update (--update-section NAME)
└── Detection Utilities (New)
    ├── detect-testing.sh (score-based framework detection)
    ├── optimize-claude-md.sh (bloat analysis and extraction)
    ├── generate-readme.sh (template-based scaffolding)
    └── update-section.sh (incremental section regeneration)
```

### Key Design Decisions

1. **Immediate Value First**: Phase 1 optimizes existing CLAUDE.md to demonstrate benefits
2. **Utility-Based Architecture**: Executable bash scripts (not AI instructions) for core detection logic
3. **Backward Compatibility**: Existing /setup modes unchanged, new features additive
4. **Progressive Disclosure**: Inline essentials (commands, style guides), reference details (specs, philosophy)
5. **Score-Based Testing**: 6-point weighted system (CI=2, tests/coverage/runners=1 each) determines TDD emphasis

### Testing Detection Algorithm

**Scoring System** (0-6 points):
- CI/CD configs (.github/workflows/*.yml, .gitlab-ci.yml): +2 points
- Test directories (tests/, __tests__/, spec/): +1 point
- Test files (>10 files matching *test*, *spec*): +1 point
- Coverage tools (.coveragerc, jest.config.js, coverage.xml): +1 point
- Test runners (run_tests.sh, Makefile with test:): +1 point

**Generation Thresholds**:
- **High (≥4 points)**: Full protocols + TDD guidance + CI integration docs
- **Medium (2-3 points)**: Brief protocols + expansion suggestions
- **Low (0-1 points)**: Minimal placeholder or omit section

### Context Optimization Strategy

**Extraction Criteria** (line count thresholds):
- **Bloated (>80 lines)**: Extract to docs/ with 10-15 line inline summary
- **Moderate (50-80 lines)**: Consider extraction based on content type
- **Optimal (<50 lines)**: Keep inline

**Target Distribution** (for 400-line CLAUDE.md):
- Project Overview: 20-25 lines
- Code Standards: 40-45 lines (essential)
- Testing Protocols: 30-35 lines (frequently referenced)
- Documentation Policy: 30-35 lines (core requirements)
- Directory Protocols: 15-20 lines (summary + link)
- Development Philosophy: 10-15 lines (principles + link)
- Development Workflow: 20-25 lines (phases + link)
- Project Commands: 25-30 lines (1-line descriptions)
- Quick Reference: 25-30 lines
- Standards Discovery: 15-20 lines
- Notes: 15-20 lines

## Implementation Phases

### Phase 1: Optimize Current CLAUDE.md (High Priority) [COMPLETED]

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 4-6 hours

**Objective**: Demonstrate context optimization value by reducing current CLAUDE.md from 648 to ~400 lines, extracting bloated sections to reference files.

**Tasks**:
- [x] Create `.claude/docs/directory-protocols.md` (extract 185-line section)
  - Full Directory Protocols content from CLAUDE.md lines ~180-365
  - Topic-based structure, artifact types, lifecycle, plan levels, dependencies
  - Examples and detailed usage patterns
- [x] Create `.claude/docs/development-philosophy.md` (extract 95-line section)
  - Clean-break refactors philosophy
  - Timeless documentation standards
  - Development rationale and principles
- [x] Update `.claude/docs/development-workflow.md` (expand existing)
  - Planning and implementation workflows
  - Spec updater integration
  - Git workflow details
- [x] Condense Project Commands section in CLAUDE.md (85→30 lines)
  - Keep: Command name + 1-line description
  - Remove: Detailed usage, all examples, verbose explanations
  - Link to: `.claude/commands/README.md` for details
- [x] Update CLAUDE.md with inline summaries and reference links
  - Directory Protocols: 185→15 lines (summary + link to docs/directory-protocols.md)
  - Development Philosophy: 95→10 lines (principles + link to docs/development-philosophy.md)
  - Development Workflow: 75→15 lines (phase names + link to docs/development-workflow.md)
  - Project Commands: 85→20 lines (command list + link to commands/README.md)
- [x] Add section markers for future incremental updates
  - Format: `<!-- SECTION: name -->` ... `<!-- END_SECTION: name -->`
  - Sections: directory_protocols, testing_protocols, code_standards, development_philosophy, adaptive_planning, adaptive_planning_config, development_workflow, project_commands, quick_reference, documentation_policy, standards_discovery (11 sections)
- [x] Validate all reference links work correctly
  - Check docs/directory-protocols.md accessible
  - Check docs/development-philosophy.md accessible
  - Check docs/development-workflow.md accessible
  - Verify relative paths correct from CLAUDE.md location

**Testing**:
```bash
# Verify line count reduction
wc -l /home/benjamin/.config/CLAUDE.md
# Target: ≤400 lines (currently 648)

# Validate reference files exist
test -f /home/benjamin/.config/.claude/docs/directory-protocols.md
test -f /home/benjamin/.config/.claude/docs/development-philosophy.md
test -f /home/benjamin/.config/.claude/docs/development-workflow.md

# Check for broken links (manual review)
grep -E '\[.*\]\(.*\.md\)' /home/benjamin/.config/CLAUDE.md
```

**Validation**:
- CLAUDE.md is ≤410 lines (allows 10-line buffer from 400 target)
- All extracted sections exist in docs/
- Section markers present for 10 major sections
- No broken reference links
- Content reads naturally with inline summaries

**Files Modified**:
- `/home/benjamin/.config/CLAUDE.md` (648→~400 lines)
- `/home/benjamin/.config/.claude/docs/directory-protocols.md` (new, ~170 lines)
- `/home/benjamin/.config/.claude/docs/development-philosophy.md` (new, ~85 lines)
- `/home/benjamin/.config/.claude/docs/development-workflow.md` (expand existing)

---

### Phase 2: Create Testing Detection Utility (High Priority)

**Dependencies**: []
**Risk**: Medium
**Estimated Time**: 6-8 hours

**Objective**: Implement score-based testing framework detection utility that analyzes repositories and generates appropriate testing protocol content.

**Tasks**:
- [ ] Create `.claude/lib/detect-testing.sh` utility
  - Function: `detect_testing_score()` returns score (0-6) and frameworks list
  - Check CI/CD configs (+2): .github/workflows/*.yml, .gitlab-ci.yml, .circleci/config.yml
  - Check test directories (+1): tests/, test/, __tests__/, spec/
  - Check test file count (+1 if >10): find *test*, *spec* files
  - Check coverage tools (+1): .coveragerc, pytest.ini, jest.config.js, .nyc_output/
  - Check test runners (+1): run_tests.sh, run_tests.py, Makefile with test:
  - Framework detection: pytest, jest, vitest, mocha, plenary, busted, cargo-test, go-test
  - Output format: `SCORE:4\nFRAMEWORKS:pytest jest`
- [ ] Create `.claude/lib/generate-testing-protocols.sh` utility
  - Function: `generate_testing_protocols(score, frameworks)` returns markdown content
  - High confidence (≥4): Full protocols with framework-specific commands, TDD guidance, CI integration
  - Medium confidence (2-3): Brief protocols with suggestions to expand
  - Low confidence (0-1): Minimal placeholder or omit
  - Template-based generation using detected frameworks
  - Include [Used by: /test, /test-all, /implement] metadata
- [ ] Add framework-specific templates in `.claude/templates/testing/`
  - `pytest.template.md` - Python pytest patterns
  - `jest.template.md` - JavaScript/TypeScript jest patterns
  - `vitest.template.md` - Vitest patterns
  - `plenary.template.md` - Neovim/Lua plenary patterns
  - `cargo.template.md` - Rust cargo test patterns
  - `go.template.md` - Go testing patterns
  - `generic.template.md` - Language-agnostic fallback
- [ ] Add error handling and edge cases
  - Handle directories with no tests gracefully
  - Handle mixed languages (multiple frameworks)
  - Handle ambiguous test patterns
  - Log detection details for debugging
- [ ] Source utility in error-handling.sh for availability
  - Add to `.claude/lib/error-handling.sh` sourcing section
  - Ensure functions available to /setup command

**Testing**:
```bash
# Unit test: Score calculation
.claude/tests/test_detect_testing.sh

# Test cases:
# 1. Python project (pytest, CI, coverage) → score 4-5, framework: pytest
# 2. JavaScript project (jest files, no CI) → score 2-3, framework: jest
# 3. Documentation project (no tests) → score 0-1, frameworks: none
# 4. This repo (.claude/tests/, no CI) → score 2-3, frameworks: bash-tests
# 5. Mixed project (pytest + jest) → score 4-5, frameworks: pytest jest

cd /home/benjamin/.config
source .claude/lib/detect-testing.sh
detect_testing_score .
# Expected: SCORE:3 or SCORE:4 (has test dir, test files, test runner)
# FRAMEWORKS:bash-tests plenary
```

**Validation**:
- `detect_testing_score()` returns correct score for test cases
- Framework detection accurate for common patterns
- generate_testing_protocols() produces valid markdown
- High/medium/low confidence outputs match examples in report
- Error handling prevents script failures

**Files Created**:
- `/home/benjamin/.config/.claude/lib/detect-testing.sh` (new, ~150 lines)
- `/home/benjamin/.config/.claude/lib/generate-testing-protocols.sh` (new, ~200 lines)
- `/home/benjamin/.config/.claude/templates/testing/*.template.md` (7 templates)
- `/home/benjamin/.config/.claude/tests/test_detect_testing.sh` (new, ~100 lines)

---

### Phase 3: Create Context Optimization Utility (High Priority)

**Dependencies**: []
**Risk**: Medium
**Estimated Time**: 8-10 hours

**Objective**: Implement automated context optimization analyzer that identifies CLAUDE.md bloat and performs extractions with summary generation.

**Tasks**:
- [ ] Create `.claude/lib/optimize-claude-md.sh` utility
  - Function: `analyze_bloat(claude_md_path)` generates optimization report
  - Parse CLAUDE.md sections (detect `## Section` headers)
  - Count lines per section (from section header to next header or EOF)
  - Classify: optimal (<50), moderate (50-80), bloated (>80)
  - Generate markdown report with recommendations table
  - Calculate savings: current lines → target lines, % reduction
- [ ] Implement section extraction logic
  - Function: `extract_section(section_name, source_file, target_file)`
  - Extract full section content to target file
  - Generate 10-20% inline summary (key concepts, 2-3 bullet points)
  - Add reference link: `See [Section Name](path/to/file.md) for details.`
  - Preserve section markers for incremental updates
- [ ] Add dry-run mode support
  - Flag: `--dry-run` shows report without applying changes
  - Display: sections to extract, target files, projected savings
  - User confirmation prompt if not dry-run
- [ ] Add threshold profiles
  - `--aggressive`: Extract sections >50 lines
  - `--balanced`: Extract sections >80 lines (default)
  - `--conservative`: Extract sections >120 lines
  - Configurable thresholds for different project needs
- [ ] Implement cross-reference update logic
  - Update links in CLAUDE.md to extracted files
  - Ensure relative paths correct
  - Validate all links after extraction
- [ ] Add rollback capability
  - Backup CLAUDE.md before optimization
  - Store in `.claude/backups/CLAUDE.md.YYYYMMDD-HHMMSS`
  - Function: `rollback_optimization()` restores from backup

**Testing**:
```bash
# Unit test: Section analysis
.claude/tests/test_optimize_claude_md.sh

# Test cases:
# 1. Bloated CLAUDE.md (648 lines) → recommend extracting 3-4 sections
# 2. Lean CLAUDE.md (300 lines) → recommend no changes or minor extractions
# 3. Custom threshold (--aggressive) → extract more sections
# 4. Dry-run mode → show report, no file modifications

# Integration test: Optimize test CLAUDE.md
cp /home/benjamin/.config/CLAUDE.md /tmp/test_CLAUDE.md
source .claude/lib/optimize-claude-md.sh
analyze_bloat /tmp/test_CLAUDE.md
# Expected: Report showing Directory Protocols (185 lines), Dev Philosophy (95 lines) as bloated

# Test extraction
extract_section "Directory Protocols" /tmp/test_CLAUDE.md /tmp/docs/directory-protocols.md
# Verify: /tmp/docs/directory-protocols.md created with ~170 lines
# Verify: /tmp/test_CLAUDE.md has ~20 line summary + link
```

**Validation**:
- `analyze_bloat()` correctly identifies bloated sections
- Section extraction preserves content integrity
- Inline summaries are coherent and informative (not truncated)
- Reference links use correct relative paths
- Dry-run mode shows accurate preview
- Backup created before modifications
- Rollback restores original file

**Files Created**:
- `/home/benjamin/.config/.claude/lib/optimize-claude-md.sh` (new, ~300 lines)
- `/home/benjamin/.config/.claude/tests/test_optimize_claude_md.sh` (new, ~120 lines)

---

### Phase 4: Create README Scaffolding Utility (High Priority)

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 6-8 hours

**Objective**: Implement automated README.md generator with template-based scaffolding, navigation link generation, and systematic documentation coverage.

**Tasks**:
- [ ] Create `.claude/lib/generate-readme.sh` utility
  - Function: `generate_readme(directory)` creates README.md from template
  - Detect parent directory and parent README
  - List files in directory (exclude hidden, README itself)
  - List subdirectories (exclude hidden, node_modules, dist, build, target, __pycache__)
  - Generate navigation links (parent, subdirectories)
  - Insert [FILL IN:] placeholders for manual content
  - Preserve existing READMEs (no overwrite unless --force)
- [ ] Create README template in `.claude/templates/README.template.md`
  - Sections: Purpose, Contents, Modules, Usage (conditional), Navigation
  - Auto-generated: Directory name, file list, subdirectory list, parent link, subdirectory links
  - Manual: Purpose descriptions, usage examples, related documentation
  - Clean, minimal format following documentation standards
- [ ] Implement directory scanning logic
  - Function: `find_directories_without_readme(root_dir)` returns list
  - Recursive scan from root directory
  - Exclude: .git, node_modules, dist, build, target, __pycache__, .pytest_cache
  - Identify directories with ≥2 significant files OR ≥1 subdirectory
  - Report coverage: N READMEs exist, M directories total, X% coverage
- [ ] Add coverage metrics and reporting
  - Count total directories eligible for README
  - Count directories with existing README
  - Calculate coverage percentage
  - Report: "Generated N READMEs, coverage: X/Y (Z%)"
  - List generated files for review
- [ ] Implement --force flag behavior
  - Default: Preserve existing READMEs
  - --force: Overwrite existing READMEs (use with caution)
  - Prompt for confirmation if --force used
  - Backup overwritten READMEs to `.claude/backups/readmes/`

**Testing**:
```bash
# Unit test: README generation
.claude/tests/test_generate_readme.sh

# Test cases:
# 1. Empty directory → README with minimal content
# 2. Directory with files → README lists files
# 3. Directory with subdirectories → README links to subdirs
# 4. Directory with existing README → no overwrite (unless --force)
# 5. Nested directory → correct parent link

# Integration test: Generate READMEs for test directory tree
mkdir -p /tmp/test_repo/{src,docs,tests}
touch /tmp/test_repo/src/main.py
touch /tmp/test_repo/docs/guide.md
touch /tmp/test_repo/tests/test_main.py

source .claude/lib/generate-readme.sh
find_directories_without_readme /tmp/test_repo
# Expected: src/, docs/, tests/, root (4 directories)

generate_readme /tmp/test_repo/src
# Verify: /tmp/test_repo/src/README.md created
# Verify: Contains main.py in Contents
# Verify: Parent link to ../README.md
# Verify: [FILL IN:] placeholders present
```

**Validation**:
- `generate_readme()` creates valid markdown files
- Navigation links are correct (parent, subdirectories)
- [FILL IN:] placeholders clearly marked
- File and subdirectory lists accurate
- Existing READMEs not overwritten without --force
- Coverage metrics calculation correct
- Template follows documentation standards

**Files Created**:
- `/home/benjamin/.config/.claude/lib/generate-readme.sh` (new, ~250 lines)
- `/home/benjamin/.config/.claude/templates/README.template.md` (new, ~40 lines)
- `/home/benjamin/.config/.claude/tests/test_generate_readme.sh` (new, ~150 lines)

---

### Phase 5: Integrate Utilities with /setup Command (Critical)

**Dependencies**: [2, 3, 4]
**Risk**: Medium
**Estimated Time**: 8-12 hours

**Objective**: Integrate new utilities into /setup command, adding --optimize, --generate-readmes, and --update-section modes while preserving existing functionality.

**Tasks**:
- [ ] Read current /setup command implementation
  - File: `/home/benjamin/.config/.claude/commands/setup.md`
  - Understand existing modes and structure
  - Identify integration points for new utilities
- [ ] Add --optimize mode to /setup command
  - Flag: `/setup --optimize [--dry-run] [--aggressive|--balanced|--conservative]`
  - Integration: Source `.claude/lib/optimize-claude-md.sh`
  - Workflow: analyze_bloat() → display report → [if not dry-run] perform extractions → report results
  - Update command documentation with usage examples
- [ ] Add --generate-readmes mode to /setup command
  - Flag: `/setup --generate-readmes [--force]`
  - Integration: Source `.claude/lib/generate-readme.sh`
  - Workflow: find_directories_without_readme() → generate for each → report coverage
  - Update command documentation with usage examples
- [ ] Add --update-section mode to /setup command
  - Flag: `/setup --update-section SECTION_NAME`
  - Integration: Source `.claude/lib/update-section.sh` (to be created)
  - Workflow: Detect section characteristics → generate new content → replace between markers
  - Supported sections: testing_protocols, code_standards, documentation_policy
  - Update command documentation with usage examples
- [ ] Update standard mode to use adaptive testing detection
  - When generating CLAUDE.md, call `detect_testing_score()`
  - Generate testing protocols using `generate_testing_protocols(score, frameworks)`
  - Replace hardcoded testing section with adaptive content
  - Maintain backward compatibility (existing CLAUDE.md files unchanged)
- [ ] Add utilities to error-handling.sh sourcing
  - Ensure all new utilities available to /setup
  - Add to utility library index
  - Document dependencies
- [ ] Update /setup command documentation
  - Add new modes to usage section
  - Provide examples for each mode
  - Document testing detection behavior
  - Link to `.claude/docs/setup-command-guide.md` (Phase 6)
- [ ] Test all /setup modes end-to-end
  - Standard mode: Generate new CLAUDE.md with adaptive testing
  - --optimize: Optimize existing CLAUDE.md
  - --generate-readmes: Create README coverage
  - --cleanup: Ensure existing mode still works
  - --validate: Ensure existing mode still works

**Testing**:
```bash
# Integration test: /setup modes
.claude/tests/test_setup_integration.sh

# Test standard mode with adaptive testing
cd /tmp/test_python_repo  # Repo with pytest setup
/setup
# Verify: CLAUDE.md has testing protocols with pytest commands
# Verify: Score-based generation (should be high confidence)

# Test optimize mode
cd /home/benjamin/.config
/setup --optimize --dry-run
# Verify: Report shows bloated sections
# Verify: No file modifications (dry-run)

/setup --optimize --balanced
# Verify: Extractions performed
# Verify: CLAUDE.md reduced in size
# Verify: Reference files created

# Test generate-readmes mode
cd /tmp/test_repo
/setup --generate-readmes
# Verify: READMEs created for directories without them
# Verify: Coverage report accurate

# Test update-section mode
cd /home/benjamin/.config
/setup --update-section testing_protocols
# Verify: Testing section regenerated
# Verify: Other sections unchanged
```

**Validation**:
- All new /setup modes functional
- Existing modes unchanged and working
- Adaptive testing detection integrated in standard mode
- Error handling robust (missing utilities, invalid sections)
- Help text updated with new modes
- Backward compatible with existing workflows

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/setup.md` (add new modes, integrate utilities)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (source new utilities)

**Files Created**:
- `/home/benjamin/.config/.claude/lib/update-section.sh` (new, ~150 lines)
- `/home/benjamin/.config/.claude/tests/test_setup_integration.sh` (new, ~200 lines)

---

### Phase 6: Documentation and Testing (Final)

**Dependencies**: [1, 2, 3, 4, 5]
**Risk**: Low
**Estimated Time**: 4-6 hours

**Objective**: Complete implementation with comprehensive documentation, usage guide, and full test suite validation.

**Tasks**:
- [ ] Create /setup usage guide in `.claude/docs/setup-command-guide.md`
  - Overview of all modes (8 total: standard, cleanup, validate, analyze, apply-report, optimize, generate-readmes, update-section)
  - Usage examples for different repository types (Neovim config, web app, CLI tool, docs project)
  - Testing detection heuristics explanation (scoring system, thresholds, frameworks)
  - Context optimization strategies (when to use --aggressive vs --balanced)
  - Incremental update workflows (when to use --update-section)
  - Troubleshooting common issues
  - Best practices for maintaining lean CLAUDE.md files
- [ ] Update CLAUDE.md Quick Reference section
  - Add new /setup modes with 1-line descriptions
  - Link to setup-command-guide.md for details
  - Keep concise (target: 25-30 lines total for commands section)
- [ ] Run complete test suite
  - Execute `.claude/tests/run_all_tests.sh`
  - Verify all new tests pass (test_detect_testing.sh, test_optimize_claude_md.sh, test_generate_readme.sh, test_setup_integration.sh)
  - Verify existing tests unaffected
  - Check coverage: target >80% for new utilities
- [ ] Create examples in `.claude/examples/setup/`
  - Example 1: Optimizing bloated CLAUDE.md (before/after)
  - Example 2: Generating CLAUDE.md for Python project (pytest detected)
  - Example 3: Generating CLAUDE.md for web app (no tests, minimal protocols)
  - Example 4: Using --generate-readmes for documentation coverage
  - Include sample outputs and expected results
- [ ] Update `.claude/commands/README.md`
  - Add /setup enhancements to command list
  - Link to setup-command-guide.md
  - Highlight adaptive testing and context optimization features
- [ ] Validate end-to-end workflows
  - Scenario 1: New user runs /setup in empty repo → gets appropriate CLAUDE.md
  - Scenario 2: User runs /setup --optimize → CLAUDE.md becomes lean
  - Scenario 3: User runs /setup --generate-readmes → systematic docs coverage
  - Scenario 4: User adds CI/CD → runs /setup --update-section testing_protocols → protocols upgraded
- [ ] Document Phase 1 optimizations in implementation summary
  - Record: CLAUDE.md reduced from 648→X lines (actual reduction)
  - List: Sections extracted and reference files created
  - Note: Context efficiency improvements (token reduction estimate)

**Testing**:
```bash
# Run complete test suite
cd /home/benjamin/.config
.claude/tests/run_all_tests.sh

# Expected: All tests pass
# Expected: New tests included in suite
# Expected: Coverage report >80% for new utilities

# Manual validation: Usage guide completeness
cat .claude/docs/setup-command-guide.md
# Verify: All modes documented
# Verify: Examples clear and comprehensive
# Verify: Troubleshooting section helpful

# Manual validation: CLAUDE.md Quick Reference
grep -A 30 "## Quick Reference" /home/benjamin/.config/CLAUDE.md
# Verify: New /setup modes listed
# Verify: Link to setup-command-guide.md present
# Verify: Section concise (≤30 lines)
```

**Validation**:
- Setup command guide is comprehensive and clear
- All examples runnable and produce expected outputs
- Test suite passes with >80% coverage
- Quick Reference updated and concise
- End-to-end workflows validated
- Documentation complete and accurate

**Files Created**:
- `/home/benjamin/.config/.claude/docs/setup-command-guide.md` (new, ~400 lines)
- `/home/benjamin/.config/.claude/examples/setup/example_*.md` (4 examples)

**Files Modified**:
- `/home/benjamin/.config/CLAUDE.md` (Quick Reference section)
- `/home/benjamin/.config/.claude/commands/README.md` (add /setup enhancements)
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh` (include new tests)

## Testing Strategy

### Unit Tests

**File**: `.claude/tests/test_detect_testing.sh`
- Test score calculation for various repository types
- Verify framework detection (pytest, jest, plenary, cargo-test, go-test)
- Edge cases: no tests, partial tests, comprehensive tests, mixed frameworks
- Expected: 15-20 test cases, all passing

**File**: `.claude/tests/test_optimize_claude_md.sh`
- Test section analysis and classification (optimal, moderate, bloated)
- Verify extraction logic preserves content
- Test summary generation quality (10-20% of original, coherent)
- Validate cross-reference updates
- Test dry-run mode accuracy
- Expected: 12-15 test cases, all passing

**File**: `.claude/tests/test_generate_readme.sh`
- Test template generation for various directory types
- Verify navigation link generation (parent, subdirectories)
- Test file/subdirectory listing accuracy
- Ensure no overwrite of existing READMEs (unless --force)
- Test coverage metrics calculation
- Expected: 10-12 test cases, all passing

### Integration Tests

**File**: `.claude/tests/test_setup_integration.sh`
- Test /setup standard mode with adaptive testing (high/medium/low confidence scenarios)
- Test /setup --optimize (dry-run and full execution)
- Test /setup --generate-readmes (empty repo, partial coverage)
- Test /setup --update-section (testing_protocols, code_standards)
- Verify backward compatibility (existing modes unchanged)
- Expected: 8-10 test cases, all passing

### End-to-End Scenarios

**Scenario 1**: Optimize Current CLAUDE.md
```bash
cd /home/benjamin/.config
cp CLAUDE.md CLAUDE.md.backup
/setup --optimize --balanced
# Verify: CLAUDE.md ≤400 lines
# Verify: docs/directory-protocols.md exists (~170 lines)
# Verify: docs/development-philosophy.md exists (~85 lines)
# Verify: All reference links work
```

**Scenario 2**: Generate CLAUDE.md for Python Project
```bash
cd /tmp/test_python_project  # Has pytest, CI, coverage
/setup
# Verify: CLAUDE.md created
# Verify: Testing protocols have pytest commands
# Verify: High confidence TDD guidance present
# Verify: CI integration documented
```

**Scenario 3**: Generate CLAUDE.md for Documentation Project
```bash
cd /tmp/test_docs_project  # No tests, only markdown files
/setup
# Verify: CLAUDE.md created
# Verify: Testing protocols minimal or omitted
# Verify: Documentation standards emphasized
# Verify: No inappropriate TDD enforcement
```

**Scenario 4**: Systematic README Coverage
```bash
cd /tmp/test_monorepo
/setup --generate-readmes
# Verify: READMEs generated for all directories
# Verify: Navigation links correct
# Verify: Coverage report accurate (e.g., 45/50 = 90%)
# Verify: [FILL IN:] placeholders present
```

### Test Coverage Target

- **Unit Tests**: >80% coverage of new utilities
- **Integration Tests**: All /setup modes tested end-to-end
- **Edge Cases**: Documented and tested (empty repos, broken links, missing files)
- **Regression**: Existing functionality unchanged (validated via existing tests)

## Risk Mitigation

### Risk 1: CLAUDE.md Optimization Breaks References

**Likelihood**: Medium
**Impact**: High (broken links disrupt workflow)

**Mitigation**:
- Validate all reference links after extraction (automated check)
- Use relative paths consistently
- Test with manual review before committing
- Backup original CLAUDE.md before optimization
- Implement rollback capability if issues discovered

### Risk 2: Testing Detection False Positives/Negatives

**Likelihood**: Medium
**Impact**: Medium (inappropriate TDD enforcement or omission)

**Mitigation**:
- Use weighted scoring system (not binary)
- Multiple indicators reduce false positives (need ≥4 points for high confidence)
- Framework detection uses multiple signals (imports, configs, file patterns)
- Provide user override mechanism (manual CLAUDE.md edit)
- Log detection details for debugging

### Risk 3: README Generation Overwrites Custom Content

**Likelihood**: Low
**Impact**: High (data loss)

**Mitigation**:
- Default behavior: Preserve existing READMEs
- --force flag required for overwrite (with confirmation prompt)
- Backup overwritten READMEs before replacement
- Clear messaging about --force implications
- [FILL IN:] placeholders distinguish auto vs manual content

### Risk 4: /setup Integration Breaks Existing Modes

**Likelihood**: Low
**Impact**: High (disrupts current workflow)

**Mitigation**:
- New modes are additive (no changes to existing mode logic)
- Comprehensive integration testing
- Test existing modes after integration
- Backward compatibility validation
- Git history preserves working version if issues arise

## Dependencies

### External Dependencies
- Bash 4.0+ (for associative arrays in utilities)
- Standard Unix tools: find, grep, awk, sed, wc
- Git (for project detection and version control)

### Internal Dependencies
- `.claude/lib/error-handling.sh` (existing, for utility sourcing)
- `.claude/lib/detect-project-dir.sh` (existing, for project root detection)
- `.claude/tests/run_all_tests.sh` (existing, for test execution)

### Optional Dependencies
- CI/CD system (.github/workflows/, .gitlab-ci.yml) for high-confidence testing detection
- Test frameworks (pytest, jest, plenary, etc.) for framework-specific protocol generation

## Documentation Requirements

### User-Facing Documentation
- [x] `/setup` command documentation updated with new modes (.claude/commands/setup.md)
- [ ] Setup command guide created (.claude/docs/setup-command-guide.md)
- [ ] Quick Reference updated in CLAUDE.md
- [ ] Examples provided (.claude/examples/setup/)
- [ ] Troubleshooting section in guide

### Developer Documentation
- [ ] Utility function documentation (inline comments)
- [ ] Testing detection algorithm documented
- [ ] Context optimization strategy documented
- [ ] Integration points documented

### Updated Files
- [ ] CLAUDE.md (optimized, new Quick Reference)
- [ ] .claude/commands/README.md (add /setup enhancements)
- [ ] .claude/docs/directory-protocols.md (extracted content)
- [ ] .claude/docs/development-philosophy.md (extracted content)
- [ ] .claude/docs/development-workflow.md (expanded)

## Notes

### Implementation Order Rationale

**Phase 1 First**: Optimize current CLAUDE.md immediately demonstrates value and validates extraction approach before building /setup enhancements. Provides concrete example for Phase 3 development.

**Phases 2-4 Parallel**: Utilities are independent and can be developed concurrently. Testing detection, context optimization, and README generation have no interdependencies.

**Phase 5 Requires 2-4**: Integration phase needs completed utilities to integrate with /setup command.

**Phase 6 Requires All**: Documentation and final testing validates complete implementation.

### Future Enhancements

**Not in this plan, but recommended for future**:
1. **Hierarchical Config Support**: Subdirectory .claude.md files (Report Recommendation 4)
2. **Incremental Section Updates**: Full --update-section implementation for all sections (Report Recommendation 5)
3. **Web-Based CLAUDE.md Editor**: GUI for non-technical users
4. **CI/CD Integration**: Automated CLAUDE.md validation in pipelines
5. **Multi-Repository Sync**: Sync common standards across repositories

### Success Metrics

**Immediate (Phase 1)**:
- Current CLAUDE.md: 648→≤400 lines (≥38% reduction)
- Context efficiency: ~2,600→~1,600 tokens (≥38% reduction)

**Post-Implementation (Phase 6)**:
- /setup works across 5+ different repository types without manual configuration
- Testing detection accuracy: >85% correct classification
- README generation coverage: >95% of eligible directories
- Test coverage: >80% for new utilities
- Zero manual threshold selection for common patterns

### Maintenance Considerations

**Ongoing maintenance requirements**:
1. **Framework Detection**: Update detect-testing.sh when new test frameworks emerge
2. **Template Updates**: Refresh testing templates as frameworks evolve
3. **Optimization Thresholds**: Adjust line count thresholds based on usage patterns
4. **README Template**: Evolve template based on documentation standards changes
5. **Test Suite**: Add tests for new edge cases as discovered

**Estimated maintenance**: 2-4 hours per quarter for updates

---

**Plan Status**: Ready for implementation
**Next Steps**: Execute Phase 1 to optimize current CLAUDE.md, validate approach, then proceed with utility development
**Spec Updater**: ☑ Plan created in topic-based structure, references research report, ready for /implement
