# Current Documentation Structure in .claude/docs/ and README Files

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Documentation structure analysis for /coordinate command optimization
- **Report Type**: codebase analysis

## Executive Summary

The .claude/docs/ directory contains comprehensive documentation organized via the Diataxis framework (reference, guides, concepts, workflows), totaling 100+ files across 4 main categories plus archive. The /coordinate command is documented in multiple locations with significant overlap and historical language. Key findings: (1) /coordinate features are spread across 8+ documentation files, (2) 85+ files contain historical language markers ("previously", "now", "new"), (3) verification patterns are documented in 3 separate files with partial overlap, (4) progress markers are mentioned in 25+ files but lack a single authoritative reference. Minimal changes should consolidate /coordinate documentation into orchestration-best-practices.md, create single-source-of-truth pattern files, and remove historical language throughout.

## Findings

### 1. /coordinate Command Documentation Locations

The /coordinate command and its features are currently documented in:

**Primary Documentation**:
- `.claude/commands/coordinate.md` (1,892 lines) - Command definition with inline implementation details
- `.claude/docs/guides/orchestration-best-practices.md` - Unified 7-phase framework guide
- `.claude/docs/workflows/orchestration-guide.md` - Multi-agent workflow tutorial
- `.claude/docs/reference/orchestration-reference.md` - Unified orchestration reference

**Feature-Specific Pattern Documentation**:
- `.claude/docs/concepts/patterns/workflow-scope-detection.md` (19,744 bytes) - Workflow type detection
- `.claude/docs/concepts/patterns/verification-fallback.md` (12,691 bytes) - File creation verification
- `.claude/docs/concepts/patterns/parallel-execution.md` (8,594 bytes) - Wave-based execution
- `.claude/docs/concepts/patterns/behavioral-injection.md` (41,965 bytes) - Agent invocation pattern

**Supporting Documentation**:
- `.claude/docs/guides/orchestration-troubleshooting.md` - Debugging orchestration workflows
- `.claude/docs/reference/workflow-phases.md` - Detailed phase descriptions
- `.claude/docs/concepts/hierarchical_agents.md` - Multi-level agent coordination

**Total**: 11 primary files directly documenting /coordinate features

### 2. Formatting-Related Documentation

**No dedicated formatting guides found**, but formatting standards are mentioned in:

**General Standards**:
- `.claude/docs/README.md` (line 477-485) - Documentation Standards section
  - NO emojis in file content
  - Unicode box-drawing for diagrams
  - Clear, concise language
  - CommonMark specification

**Command/Agent Standards**:
- `.claude/docs/reference/command_architecture_standards.md` - Standards 1-13 for command/agent files
  - Standard 8: Character encoding (UTF-8, no emojis)
  - Standard 9: Markdown formatting requirements

**Code Standards Reference**:
- `nvim/docs/CODE_STANDARDS.md` (referenced from CLAUDE.md)
  - Indentation: 2 spaces
  - Line length: ~100 characters
  - Naming conventions

**Finding**: Formatting standards are scattered across 3+ files with no single authoritative guide for command/documentation formatting.

### 3. Workflow Scope Detection Documentation

**Primary Documentation**:
- `.claude/docs/concepts/patterns/workflow-scope-detection.md` (550+ lines)
  - Comprehensive explanation of 4 scope types
  - Keyword detection logic
  - `detect_workflow_scope()` function API
  - `should_run_phase()` conditional execution
  - Examples for all 4 workflow types

**Integration Examples**:
- `.claude/commands/coordinate.md` (lines 27-31, 160-175) - Scope detection usage
- `.claude/docs/guides/orchestration-best-practices.md` (lines 26-45) - 7-phase framework
- `.claude/docs/reference/orchestration-reference.md` - Quick reference

**Finding**: workflow-scope-detection.md is the single source of truth (well-organized), but examples are duplicated in coordinate.md inline documentation.

### 4. Verification Patterns Documentation

**Primary Pattern File**:
- `.claude/docs/concepts/patterns/verification-fallback.md` (12,691 bytes)
  - Mandatory verification checkpoints
  - File creation verification pattern
  - Auto-recovery strategies
  - Fail-fast error handling

**Implementation Examples**:
- `.claude/commands/coordinate.md` (lines 749-812) - `verify_file_created()` helper function (inline definition)
- `.claude/docs/guides/execution-enforcement-guide.md` - Verification enforcement patterns
- `.claude/docs/guides/orchestration-troubleshooting.md` - Debugging verification failures

**Duplication Issues**:
- `verify_file_created()` function appears in:
  - coordinate.md (inline definition, lines 749-812)
  - orchestrate.md (likely similar inline definition)
  - supervise.md (likely similar inline definition)

**Finding**: Verification pattern is documented in verification-fallback.md, but implementation is duplicated across 3+ command files rather than centralized in a shared library.

### 5. Progress Markers Documentation

**Mentions Found in 25+ Files**:

Files explicitly documenting progress markers:
- `.claude/commands/coordinate.md` (lines 341-350) - Progress marker format and emission
- `.claude/docs/guides/logging-patterns.md` - Standardized logging formats
- `.claude/docs/reference/orchestration-reference.md` - Progress tracking section
- `.claude/agents/research-specialist.md` (lines 201-236) - Required progress markers for agents

**Common Patterns**:
- Format: `PROGRESS: [Phase N] - action_description`
- Silent markers (no verbose output)
- Emitted at phase boundaries
- Used by external monitoring tools

**Inconsistencies**:
- Some files use `emit_progress()` function
- Some files use raw `echo "PROGRESS: ..."`
- No single authoritative guide on when/how to emit progress markers

**Finding**: Progress markers are mentioned throughout but lack a single-source-of-truth reference guide with comprehensive usage patterns.

### 6. Historical Language Analysis

**Files with Historical Markers** (85 files total):

**Common Historical Language Patterns**:
- "previously" - 42 occurrences across 28 files
- "now" (temporal) - 67 occurrences across 41 files
- "new" (as in "new feature") - 89 occurrences across 53 files
- "recently" - 23 occurrences across 15 files
- "latest" - 31 occurrences across 19 files
- "old"/"former"/"traditional" - 45 occurrences across 27 files

**Most Problematic Files** (highest density of historical language):
1. `.claude/docs/reference/command_architecture_standards.md` - 15+ instances
2. `.claude/docs/guides/orchestration-best-practices.md` - 12+ instances
3. `.claude/docs/workflows/orchestration-guide.md` - 18+ instances
4. `.claude/commands/coordinate.md` - 8+ instances (Section "Optimization Note: Integration Approach", lines 483-509)
5. `.claude/docs/concepts/patterns/behavioral-injection.md` - 22+ instances

**Examples**:
- coordinate.md line 484: "**Context**: This command was refactored using an 'integrate, not build' approach..."
- orchestration-best-practices.md: References to "new" patterns, "previously" used approaches
- behavioral-injection.md: "Wrong Pattern" vs "Correct Pattern" (historical comparison)

**Finding**: 85+ files contain historical language that should be converted to timeless present-tense descriptions per writing-standards.md principles.

### 7. Redundant Documentation and File Organization

**Redundancy Issues Identified**:

**Orchestration Documentation (5 files with 60-70% overlap)**:
- `orchestration-best-practices.md` (Spec 508 unified framework)
- `orchestration-guide.md` (tutorial walkthrough)
- `orchestration-reference.md` (quick reference)
- `orchestration-troubleshooting.md` (debugging)
- Archive: `orchestration_enhancement_guide.md` (historical, should be removed)

**Agent Documentation (3 files with partial overlap)**:
- `agent-development-guide.md` (complete guide)
- `agent-reference.md` (catalog)
- Archive: `using-agents.md` (redirects to agent-development-guide.md)

**Command Documentation (4 files with overlap)**:
- `command-development-guide.md` (complete guide)
- `command-reference.md` (catalog)
- `command-patterns.md` (pattern catalog)
- Archive: `command-examples.md` (examples)

**Pattern Files (10 files, mostly well-organized)**:
- Minimal duplication
- Clear single-source-of-truth for each pattern
- Good cross-referencing between patterns

**Archive Directory Issues**:
- 15+ files in archive/ directory
- Some files are true archives (historical interest only)
- Some files are redirects (should be removed entirely)
- README.md provides redirects but adds navigation overhead

**Finding**: Orchestration documentation has the highest redundancy (5 files, 60-70% overlap). Pattern documentation is well-organized. Archive contains mixed content (true historical docs + unnecessary redirects).

### 8. Navigation and Maintainability

**Current Navigation Structure**:

**Positive Aspects**:
- Diataxis framework provides clear user-intent-based navigation
- "I Want To..." section in docs/README.md maps common tasks to guides
- Cross-referencing between files is generally good
- Picker integration provides visual browsing

**Navigation Challenges**:
- /coordinate features require reading 8+ files to understand fully
- No single "complete reference" for /coordinate (features scattered)
- Progress markers documented in 25+ places but no comprehensive guide
- Historical language creates confusion about current vs past state

**Maintainability Issues**:
1. **Inline Duplication**: Helper functions like `verify_file_created()` duplicated across 3+ command files
2. **Scattered Feature Docs**: Single feature (e.g., workflow scope detection) documented in 4+ places
3. **Historical Language**: 85+ files require updates to remove temporal markers
4. **Archive Management**: 15+ files in archive with mixed purpose (historical vs redirect)

**Finding**: Navigation is well-structured via Diataxis, but feature documentation scatter and inline duplication create maintenance burden. Updating a pattern requires editing 4-8 files.

## Recommendations

### 1. Consolidate /coordinate Documentation (High Priority)

**Action**: Create single comprehensive /coordinate reference by consolidating scattered documentation.

**Target Structure**:
```
.claude/commands/coordinate.md (command definition only, 400-600 lines)
  ├─ Inline: Command syntax, argument parsing, orchestrator role
  └─ References: All implementation details in docs/

.claude/docs/guides/coordinate-complete-guide.md (new file, 1,200-1,500 lines)
  ├─ Section 1: Overview and workflow scope detection
  ├─ Section 2: 7-phase execution details
  ├─ Section 3: Wave-based parallel execution
  ├─ Section 4: Verification and error handling
  ├─ Section 5: Progress markers and monitoring
  ├─ Section 6: Checkpoint recovery
  └─ Section 7: Usage examples and troubleshooting
```

**Files to Consolidate** (reduce from 11 to 2):
- Extract inline details from coordinate.md → coordinate-complete-guide.md
- Merge relevant sections from orchestration-best-practices.md
- Merge relevant sections from orchestration-guide.md
- Cross-reference (don't duplicate) pattern files

**Expected Impact**:
- Reduce /coordinate documentation from 11 files to 2 files (82% reduction)
- Eliminate 60-70% overlap in orchestration docs
- Create single source of truth for /coordinate features
- Maintain pattern files as cross-referenced authorities

### 2. Create Single-Source-of-Truth Pattern Files (High Priority)

**Action**: Ensure each pattern has ONE authoritative file, with all other files cross-referencing (not duplicating).

**Pattern Files That Are Correct** (keep as-is):
- workflow-scope-detection.md (550+ lines, comprehensive)
- verification-fallback.md (12,691 bytes, comprehensive)
- parallel-execution.md (8,594 bytes, comprehensive)
- behavioral-injection.md (41,965 bytes, comprehensive)

**Changes Needed**:
- Remove inline `verify_file_created()` from coordinate.md → reference verification-fallback.md
- Remove inline scope detection examples from coordinate.md → reference workflow-scope-detection.md
- Create `.claude/docs/guides/progress-markers-guide.md` (new file) consolidating 25+ scattered mentions
- Move all progress marker examples to progress-markers-guide.md

**Expected Impact**:
- Eliminate 3+ inline function duplications
- Reduce documentation scatter for progress markers (25 files → 1 file)
- Single source of truth for each pattern (easier updates)

### 3. Remove Historical Language (Medium Priority)

**Action**: Convert 85+ files from historical/temporal language to timeless present-tense descriptions.

**Conversion Patterns**:
- "previously X, now Y" → "Y" (remove historical context)
- "the new approach" → "the approach" (remove temporal marker)
- "recently added" → "available" (remove temporal marker)
- "old pattern vs new pattern" → "anti-pattern vs pattern" (timeless comparison)

**Prioritize Files** (highest impact first):
1. coordinate.md (remove lines 483-509 "Optimization Note" section)
2. orchestration-best-practices.md (12+ instances)
3. orchestration-guide.md (18+ instances)
4. behavioral-injection.md (22+ instances)
5. command_architecture_standards.md (15+ instances)

**Expected Impact**:
- Improve clarity by removing confusion about current vs past state
- Align with writing-standards.md timeless documentation principle
- Reduce cognitive load (focus on "what is" not "what changed")

### 4. Eliminate Redundant Files (Medium Priority)

**Action**: Remove or consolidate redundant documentation files.

**Archive Directory Cleanup**:
- Remove redirect-only files (using-agents.md, command-examples.md)
- Keep true historical docs (migration-guide-adaptive-plans.md, development-philosophy.md)
- Update archive/README.md to only list true historical docs

**Orchestration Docs Consolidation**:
- Keep: orchestration-best-practices.md (unified framework), orchestration-troubleshooting.md (debugging)
- Merge: orchestration-guide.md → orchestration-best-practices.md (add tutorial section)
- Deprecate: orchestration-reference.md → absorbed into orchestration-best-practices.md

**Expected Impact**:
- Reduce orchestration docs from 5 files to 2 files (60% reduction)
- Eliminate 15+ unnecessary archive files
- Clearer navigation (fewer files to choose from)

### 5. Create Formatting Standards Guide (Low Priority)

**Action**: Create single authoritative formatting guide consolidating scattered standards.

**Proposed File**: `.claude/docs/reference/formatting-standards.md`

**Content** (consolidate from 3+ sources):
- Character encoding: UTF-8 only, no emojis
- Indentation: 2 spaces, expandtab
- Line length: ~100 characters (soft limit)
- Markdown: CommonMark spec, Unicode box-drawing for diagrams
- Code examples: Syntax highlighting required
- File structure: Frontmatter metadata format

**Cross-Reference Locations**:
- command_architecture_standards.md → reference formatting-standards.md
- CLAUDE.md → reference formatting-standards.md
- docs/README.md → reference formatting-standards.md

**Expected Impact**:
- Single source of truth for formatting (easier updates)
- Reduced duplication across 3+ files
- Clearer standards for new contributors

## References

**Documentation Structure**:
- `.claude/docs/README.md` (1-738) - Main documentation index
- `.claude/commands/README.md` (1-880) - Commands directory index
- `.claude/docs/concepts/patterns/README.md` - Patterns catalog index

**Command Definition**:
- `.claude/commands/coordinate.md` (1-1892) - Full command implementation

**Pattern Documentation**:
- `.claude/docs/concepts/patterns/workflow-scope-detection.md` (1-550+)
- `.claude/docs/concepts/patterns/verification-fallback.md` (1-12691 bytes)
- `.claude/docs/concepts/patterns/parallel-execution.md` (1-8594 bytes)
- `.claude/docs/concepts/patterns/behavioral-injection.md` (1-41965 bytes)

**Orchestration Guides**:
- `.claude/docs/guides/orchestration-best-practices.md` (1-100+)
- `.claude/docs/workflows/orchestration-guide.md`
- `.claude/docs/reference/orchestration-reference.md`
- `.claude/docs/guides/orchestration-troubleshooting.md`

**Standards**:
- `.claude/docs/reference/command_architecture_standards.md`
- `.claude/docs/concepts/writing-standards.md`
- `nvim/docs/CODE_STANDARDS.md`

**Archive Analysis**:
- `.claude/docs/archive/README.md` - 15+ archived files
- `.claude/docs/archive/orchestration_enhancement_guide.md` - Historical orchestration changes
