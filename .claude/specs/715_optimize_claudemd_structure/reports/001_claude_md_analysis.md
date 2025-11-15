# CLAUDE.md Structure Analysis

## Metadata
- **Date**: 2025-11-14
- **Agent**: claude-md-analyzer
- **File Analyzed**: /home/benjamin/.config/CLAUDE.md
- **Threshold**: balanced (80 lines)
- **Report Type**: Structure Analysis and Bloat Detection

## Summary

- **Total Lines**: 1001
- **Total Sections**: 19 (analyzed sections)
- **Bloated Sections (>80 lines)**: 4
- **Moderate Sections (50-80 lines)**: 2
- **Sections Missing Metadata**: 3
- **Projected Savings**: ~437 lines (43.7% reduction)
- **Target Size After Extraction**: 564 lines

## Section Analysis

| Section | Lines | Status | Recommendation |
|---------|-------|--------|----------------|
| Project Standards and Guidelines | 25 | Optimal | Keep inline |
| Testing Protocols | 76 | Moderate | Consider extraction |
| Code Standards | 84 | **Bloated** | Extract to docs/ with summary |
| Directory Organization Standards | 231 | **Bloated** | Extract to docs/ with summary |
| Development Philosophy | 49 | Optimal | Keep inline |
| Adaptive Planning | 36 | Optimal | Keep inline |
| Adaptive Planning Configuration | 39 | Optimal | Keep inline |
| Development Workflow | 15 | Optimal | Keep inline |
| Hierarchical Agent Architecture | 93 | **Bloated** | Extract to docs/ with summary |
| State-Based Orchestration Architecture | 108 | **Bloated** | Extract to docs/ with summary |
| Project-Specific Commands | 61 | Moderate | Consider extraction |
| Quick Reference | 32 | Optimal | Keep inline |
| Documentation Policy | 25 | Optimal | Keep inline |
| Standards Discovery | 20 | Optimal | Keep inline |
| Notes | 6 | Optimal | Keep inline |

## Extraction Candidates

### 1. Code Standards (84 lines) → .claude/docs/reference/code-standards.md
- **Rationale**: Standards and reference documentation should live in reference/ directory
- **Integration**: Create new file (no existing code-standards.md found)
- **Content**: General principles, language-specific standards, command architecture, link conventions
- **CLAUDE.md Summary**: 5-10 line summary with link to full reference doc
- **Priority**: HIGH - 84 lines is significant bloat for inline reference material

### 2. Directory Organization Standards (231 lines) → .claude/docs/concepts/directory-organization.md
- **Rationale**: Architectural concept explaining directory structure principles
- **Integration**: Create new file (no existing directory-organization.md found in concepts/)
- **Content**: Directory structure, decision matrix, file placement rules, anti-patterns
- **CLAUDE.md Summary**: 8-12 line summary with decision tree link
- **Priority**: CRITICAL - 231 lines is the largest bloat contributor (23% of total file)

### 3. Hierarchical Agent Architecture (93 lines) → .claude/docs/concepts/hierarchical_agents.md
- **Rationale**: Merge with existing hierarchical_agents.md file
- **Integration**: File already exists - merge unique content, remove duplicates
- **Content**: Overview, key features, context reduction metrics, utilities, agent templates
- **CLAUDE.md Summary**: 6-8 line summary focusing on usage and key metrics
- **Priority**: HIGH - File already exists with overlapping content

### 4. State-Based Orchestration Architecture (108 lines) → .claude/docs/architecture/state-based-orchestration-overview.md
- **Rationale**: Link to existing comprehensive documentation
- **Integration**: File already exists with 2000+ lines of complete documentation
- **Content**: Overview, core components, performance achievements, resources
- **CLAUDE.md Summary**: 5-7 line summary with link to architecture overview
- **Priority**: HIGH - Redundant with existing comprehensive doc

### 5. Testing Protocols (76 lines) → .claude/docs/reference/testing-protocols.md
- **Rationale**: Test discovery and configuration belongs in reference documentation
- **Integration**: Create new file (no existing testing-protocols.md found)
- **Content**: Test discovery, Claude Code testing, Neovim testing, coverage requirements, isolation standards
- **CLAUDE.md Summary**: 4-6 line summary with link to test configuration reference
- **Priority**: MEDIUM - Just under bloat threshold but good extraction candidate

### 6. Project-Specific Commands (61 lines) → .claude/docs/reference/command-reference.md
- **Rationale**: Merge with existing command-reference.md
- **Integration**: File already exists - ensure all commands are documented there
- **Content**: Command listing with usage guides, orchestration comparison
- **CLAUDE.md Summary**: 3-5 line summary pointing to command reference catalog
- **Priority**: MEDIUM - Moderate size but already has natural documentation home

## Integration Points

### .claude/docs/concepts/
**Natural Home For**: Architectural patterns, system design concepts, workflow patterns

**Current Extraction Candidates**:
- Directory Organization Standards (231 lines) - NEW FILE NEEDED
- Hierarchical Agent Architecture (93 lines) - MERGE with existing hierarchical_agents.md

**Existing Files**:
- `hierarchical_agents.md` - Already exists, merge candidate
- `development-workflow.md` - Already exists
- `directory-protocols.md` - Already exists
- `bash-block-execution-model.md` - Already exists
- `writing-standards.md` - Already exists
- `patterns/` subdirectory with 13+ pattern files

**Gaps**:
- No `directory-organization.md` (should be created from 231-line section)

**Opportunity**: Extract directory organization architecture to standalone concept file

---

### .claude/docs/reference/
**Natural Home For**: Standards documentation, API references, command catalogs, configuration references

**Current Extraction Candidates**:
- Code Standards (84 lines) - NEW FILE NEEDED
- Testing Protocols (76 lines) - NEW FILE NEEDED
- Project-Specific Commands (61 lines) - MERGE with existing command-reference.md

**Existing Files**:
- `command-reference.md` - Already exists, merge candidate
- `agent-reference.md` - Already exists
- `library-api.md` - Already exists
- `command_architecture_standards.md` - Already exists
- `test-isolation-standards.md` - Already exists

**Gaps**:
- No `code-standards.md` (should be created from 84-line section)
- No `testing-protocols.md` (should be created from 76-line section)

**Opportunity**: Extract standards documentation to reference directory for discoverability

---

### .claude/docs/architecture/
**Natural Home For**: Architecture overviews, system design documentation, technical deep-dives

**Current Extraction Candidates**:
- State-Based Orchestration Architecture (108 lines) - REPLACE with link to existing file

**Existing Files**:
- `state-based-orchestration-overview.md` - 2000+ lines comprehensive doc
- `coordinate-state-management.md` - Already exists
- `hierarchical-supervisor-coordination.md` - Already exists
- `workflow-state-machine.md` - Already exists

**Gaps**: None - architecture directory is well-populated

**Opportunity**: Replace inline section with brief summary + link to existing comprehensive doc

---

### .claude/docs/guides/
**Natural Home For**: Task-focused how-to guides, command usage guides, workflow tutorials

**Current Status**: No extraction candidates from CLAUDE.md (guides are already well-separated)

**Existing Files**:
- 30+ command guides (*-command-guide.md)
- Development guides (command-development-guide.md, agent-development-guide.md)
- Model selection guide, workflow guides

**Opportunity**: No immediate action needed - guides are already properly externalized

## Metadata Gaps

Sections missing `[Used by: ...]` metadata tags:

1. **development_workflow** (line 634)
   - Location: Lines 633-647 (Development Workflow section)
   - Impact: Commands won't know when to reference this section
   - Recommendation: Add `[Used by: /implement, /plan, /orchestrate, /coordinate]`

2. **quick_reference** (line 915)
   - Location: Lines 914-945 (Quick Reference section)
   - Impact: No discoverability metadata for quick reference lookup
   - Recommendation: Add `[Used by: all commands]` or consider if metadata is needed

3. **project_commands** (line 853)
   - Location: Lines 852-912 (Project-Specific Commands section)
   - Impact: Commands won't know when to reference command catalog
   - Recommendation: Add `[Used by: /help, all orchestration commands]`

**Analysis**: 3 out of 19 analyzed sections (15.8%) are missing metadata tags. This reduces discoverability for command-based section lookup.

**Impact**: MEDIUM - Missing metadata reduces automated section discovery but doesn't prevent manual navigation

**Recommendation**: Add metadata tags during extraction refactoring to maintain consistency with other sections

---

## Cross-Reference Duplication Analysis

### Duplicated Content Detected

1. **Hierarchical Agent Architecture** (CLAUDE.md lines 649-741) vs `.claude/docs/concepts/hierarchical_agents.md`
   - **Overlap**: ~60% content duplication
   - **CLAUDE.md unique**: Integration points, command integration examples
   - **Doc file unique**: Complete pattern documentation, case studies, troubleshooting
   - **Action**: Merge unique content from CLAUDE.md into doc file, replace CLAUDE.md section with summary

2. **State-Based Orchestration Architecture** (CLAUDE.md lines 743-850) vs `.claude/docs/architecture/state-based-orchestration-overview.md`
   - **Overlap**: ~90% content duplication (CLAUDE.md is abbreviated version)
   - **Doc file**: 2000+ lines comprehensive documentation
   - **Action**: Replace CLAUDE.md section with 5-7 line summary + link

3. **Command Architecture Standards** (referenced in Code Standards section) vs `.claude/docs/reference/command_architecture_standards.md`
   - **Overlap**: References exist but content is properly separated
   - **Action**: No duplication issue - proper linking pattern

### No Duplication Issues

- **Directory Organization Standards**: No existing file (new file needed)
- **Code Standards**: No existing file (new file needed)
- **Testing Protocols**: References test-isolation-standards.md but no content duplication

---

## Extraction Priority Recommendation

Based on bloat severity, duplication, and ease of extraction:

### Phase 1 (CRITICAL - Immediate Action)
1. **Directory Organization Standards** (231 lines → new file)
   - Largest bloat contributor
   - No existing file to merge with
   - Clear extraction target
   - Expected savings: 220+ lines after summary

### Phase 2 (HIGH - Next Priority)
2. **State-Based Orchestration Architecture** (108 lines → link to existing)
   - ~90% redundant with existing comprehensive doc
   - Simple extraction: replace with summary + link
   - Expected savings: 100+ lines

3. **Hierarchical Agent Architecture** (93 lines → merge with existing)
   - ~60% overlap with existing doc
   - Requires content merge analysis
   - Expected savings: 80+ lines

4. **Code Standards** (84 lines → new file)
   - Standards belong in reference/
   - Clean extraction candidate
   - Expected savings: 75+ lines

### Phase 3 (MEDIUM - Optional Optimization)
5. **Testing Protocols** (76 lines → new file)
   - Just under bloat threshold
   - Clean extraction candidate
   - Expected savings: 70+ lines

6. **Project-Specific Commands** (61 lines → merge with command-reference.md)
   - Merge with existing command catalog
   - Expected savings: 55+ lines

**Total Potential Savings**: ~600 lines (60% reduction from 1001 to ~400 lines)
**Conservative Estimate**: ~437 lines (43.7% reduction as per library analysis)
