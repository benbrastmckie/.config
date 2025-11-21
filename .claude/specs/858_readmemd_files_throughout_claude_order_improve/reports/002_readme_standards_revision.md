# README.md Documentation Standards Revision Research

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Plan revision insights for README.md file documentation standards
- **Report Type**: codebase analysis and documentation standards research
- **Workflow Type**: research-and-revise
- **Complexity**: 2

## Executive Summary

The user requests clarification on README.md documentation standards for three specific directory types (archive/, specs/, tmp/) and integration of these standards into the .claude/docs/ ecosystem. Current documentation standards in CLAUDE.md:192-212 mandate README.md files for "every subdirectory" but lack explicit exceptions for utility/temporary directories. The existing plan correctly identifies the need to document archive/, specs/, and tmp/ characteristics, but can be refined with clearer directory classification and targeted documentation placement within the .claude/docs/reference/standards/ structure.

## Findings

### 1. Current README.md Standard Location and Content

**Primary Standard**: CLAUDE.md lines 188-212 (documentation_policy section)

Current requirement (line 193):
```markdown
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs
```

**Location**: /home/benjamin/.config/CLAUDE.md:192-197

**Analysis**: This is an absolute requirement ("must have") with no exceptions documented for utility directories like archive/, specs/, or tmp/.

### 2. Current Directory Categorization in Documentation

**Source**: /home/benjamin/.config/.claude/docs/concepts/directory-organization.md:1-100

The system currently documents directory types:
- **scripts/** - Standalone operational tools (line 22-47)
- **lib/** - Sourced function libraries (line 51-78)
- **commands/** - Slash command definitions (line 81-100)
- **agents/** - AI assistant definitions
- **docs/** - Documentation
- **tests/** - Test suites

**Gap**: No explicit categorization for utility/temporary directories (archive/, specs/, tmp/, backups/, data/)

### 3. Archive Directory Current State

**Location**: /home/benjamin/.config/.claude/archive/

**Structure**: Contains 5 READMEs across subdirectories:
- archive/coordinate/README.md
- archive/deprecated-agents/README.md
- archive/legacy-workflow-commands/README.md
- archive/lib/cleanup-2025-11-19/README.md
- archive/tests/cleanup-2025-11-20/README.md

**Finding**: Archive subdirectories DO have READMEs documenting what was archived and when. These are timestamped cleanup documentation, not active development documentation.

**Root README**: /home/benjamin/.config/.claude/archive/README.md does NOT exist (verified via Read tool error)

### 4. Specs Directory Current State

**Location**: /home/benjamin/.config/.claude/specs/

**Structure**: Topic-based organization (e.g., 858_readmemd_files_throughout_claude_order_improve/)
- Each topic contains: plans/, reports/, summaries/, backups/ subdirectories
- Root README: /home/benjamin/.config/.claude/specs/README.md EXISTS (169 lines)

**Content Analysis** (specs/README.md:1-169):
- Line 1-4: Purpose statement
- Line 8-14: Directory structure overview
- Line 16-106: Subdirectory documentation (artifacts/, plans/, reports/, standards/, summaries/)
- Line 108-146: File naming and usage patterns
- Line 161-169: Standards compliance note

**Finding**: specs/README.md is comprehensive and follows CLAUDE.md standards. Individual topic directories (e.g., 858_/) do NOT have READMEs - these are ephemeral working directories.

### 5. Tmp Directory Current State

**Location**: /home/benjamin/.config/.claude/tmp/

**Structure** (verified via ls):
- backups/ and baselines/ subdirectories
- Temporary files: build_state_id.txt, plan_state_id.txt, invocation_*.txt, research_*.json
- link-validation/ subdirectory

**Root README**: Does NOT exist

**Characteristics**:
- Contains gitignored temporary/transient files
- State files for active workflows
- Validation baselines
- Working directory for commands

**Finding**: tmp/ is a true utility directory with ephemeral content - README would become stale quickly as contents change based on active workflows.

### 6. Documentation Standards Ecosystem Structure

**Location**: /home/benjamin/.config/.claude/docs/reference/standards/

**Existing Standards Documents** (verified via ls):
1. adaptive-planning.md (1,519 bytes)
2. agent-reference.md (13,664 bytes)
3. claude-md-schema.md (9,099 bytes)
4. code-standards.md (10,672 bytes)
5. command-authoring.md (18,509 bytes)
6. command-reference.md (18,827 bytes)
7. output-formatting.md (18,527 bytes)
8. plan-progress.md (5,661 bytes)
9. testing-protocols.md (11,994 bytes)
10. test-isolation.md (19,365 bytes)
11. README.md (1,061 bytes)

**Gap**: No "documentation-standards.md" or "readme-standards.md" file exists

**Finding**: The natural location for README.md creation standards would be:
- `/home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md`

This would contain:
- README.md structure requirements
- Directory classification (active vs. utility vs. archived)
- Exception policies for temporary/utility directories
- Template selection guide
- Validation requirements

### 7. Related Documentation Standards

**Source**: /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:1-558

Lines 47-76 define "Documentation Standards" and "Timeless Writing Principles":
- Present-focused writing (line 49)
- No historical reporting (line 52)
- Clean narrative (line 54)
- Ban historical markers (line 55)

**Relevance**: These principles apply to README.md content - should describe current state, not historical evolution.

**Source**: /home/benjamin/.config/.claude/docs/guides/commands/document-command-guide.md:1-80

Lines 24-33 list /document command use cases:
- "To add missing README.md files" (line 32)
- "To enforce documentation standards across the project" (line 33)

**Finding**: The /document command is responsible for README.md enforcement - it needs clear standards about when READMEs are required vs. optional.

### 8. Existing Plan Phase 1 Task 1.2 Template Analysis

**Source**: Existing plan lines 174-253

The plan proposes three templates:
- **Template A**: Top-level Directory (agents/, commands/, lib/)
- **Template B**: Subdirectory (lib/core/, docs/guides/)
- **Template C**: Utility/Support Directory (tmp/, backups/, data/)

**Finding**: Template C (lines 230-250) is designed for utility directories with sections:
- Purpose (role and lifecycle explanation)
- Contents (typical files/subdirectories)
- Maintenance (cleanup policies, retention, gitignore status)
- Navigation

**Analysis**: This template is appropriate for directories that DO need READMEs but contain transient content. The question is whether tmp/ needs even this minimal documentation.

### 9. Current CLAUDE.md README Requirement Language

**Exact Text** (CLAUDE.md:193):
```
Every subdirectory must have a README.md containing:
```

**Issue**: "Every subdirectory" is absolute - no exceptions documented

**User's Request**: Explicitly state that archive/, specs/, and tmp/ do NOT need READMEs at certain levels

**Conflict**: User wants FEWER READMEs, but current standard mandates MORE READMEs

**Resolution Path**: Refine standard to classify directories:
- **Active Development Directories**: Require READMEs (commands/, agents/, lib/, docs/, tests/, scripts/)
- **Utility Directories**: Require root README only (data/, backups/)
- **Temporary Directories**: Optional README (tmp/)
- **Archive Directories**: Require root README, subdirectory READMEs as timestamped manifests (archive/)
- **Topic Directories**: Require root README, individual topic instances do NOT need READMEs (specs/)

### 10. Integration Point in Documentation Ecosystem

**Best Location**: Create new standard document

**Proposed Path**: /home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md

**Reasoning**:
1. Aligns with existing standards structure (11 standards files already exist)
2. Natural location for README.md requirements (currently scattered in CLAUDE.md)
3. Separates README standards from general documentation policy
4. Provides detailed guidance beyond CLAUDE.md summary
5. Can include templates, examples, decision trees

**CLAUDE.md Integration**: Update documentation_policy section (lines 188-212) to reference the new standard:

```markdown
### README Requirements
See [Documentation Standards](.claude/docs/reference/standards/documentation-standards.md) for complete README.md structure requirements, directory classification, and template selection.

**Quick Summary**:
- **Active directories**: Require README.md for navigation and module documentation
- **Utility directories**: Require root README.md documenting purpose and lifecycle
- **Temporary directories**: README.md optional (tmp/)
- **Archive directories**: Root README.md plus timestamped manifests for cleanup subdirectories
```

This creates a two-tier system:
- **CLAUDE.md**: Quick reference summary with link to full standard
- **documentation-standards.md**: Complete requirements, templates, decision trees, validation

### 11. Directory-Specific Recommendations from Analysis

#### archive/
- **Recommendation**: Create root /home/benjamin/.config/.claude/archive/README.md
- **Content**: Purpose (deprecated code storage), organization (by date, by type), recovery process
- **Subdirectory READMEs**: Keep existing timestamped manifests (e.g., cleanup-2025-11-19/README.md) - these document WHAT was archived WHEN

#### specs/
- **Recommendation**: Keep existing /home/benjamin/.config/.claude/specs/README.md (already comprehensive)
- **Topic subdirectories**: Do NOT create READMEs for individual topic directories (e.g., 858_/)
- **Reasoning**: Topic directories are working areas with plans/, reports/, summaries/ - these subdirectories are self-documenting via their content

#### tmp/
- **Recommendation**: Create minimal /home/benjamin/.config/.claude/tmp/README.md
- **Content**: Purpose (temporary working files), lifecycle (ephemeral, gitignored), cleanup policy
- **Subdirectory READMEs**: NOT needed (backups/, baselines/, link-validation/ are transient)
- **Alternative**: Mark tmp/ as exception in documentation-standards.md - "Temporary working directory, README.md optional"

## Recommendations

### Recommendation 1: Create documentation-standards.md Standard Document

**Action**: Create /home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md

**Content Structure**:
```markdown
# Documentation Standards

## README.md Requirements

### Directory Classification

#### Active Development Directories
Directories containing source code, commands, agents, or active development artifacts.

**Examples**: commands/, agents/, lib/, docs/, tests/, scripts/, hooks/

**README Requirement**: REQUIRED
- Every directory and subdirectory must have README.md
- Purpose statement (what the directory contains)
- Module/file documentation (what each file does)
- Usage examples (how to use the contents)
- Navigation links (parent, children, related)

**Template**: Use Template A (Top-level) or Template B (Subdirectory)

#### Utility Directories
Directories containing data, logs, checkpoints, registries, or backups.

**Examples**: data/, backups/, .claude/data/registries/

**README Requirement**: ROOT ONLY
- Root directory requires README.md explaining purpose, structure, lifecycle
- Subdirectories do NOT require individual READMEs unless they contain 5+ distinct categories

**Template**: Use Template C (Utility Directory)

#### Temporary Directories
Directories containing ephemeral working files, state files, or transient artifacts.

**Examples**: tmp/, tmp/baselines/, tmp/link-validation/

**README Requirement**: OPTIONAL
- Root README.md optional but recommended for clarity
- Subdirectories do NOT require READMEs
- If created, should document cleanup policy and lifecycle

**Template**: Use Template C (Utility Directory) with minimal content

#### Archive Directories
Directories containing deprecated code, old implementations, or historical artifacts.

**Examples**: archive/, archive/deprecated-agents/, archive/lib/cleanup-2025-11-19/

**README Requirement**: ROOT + TIMESTAMPED MANIFESTS
- Root directory requires README.md explaining deprecation policy, organization, recovery process
- Timestamped cleanup subdirectories require manifest README.md documenting WHAT was archived WHEN
- These manifest READMEs are historical records, not active documentation

**Template**: Use Template C (Utility Directory) for root, custom manifest template for cleanup subdirectories

#### Topic Directories
Directories containing workflow artifacts organized by topic (specs/, plans/, reports/).

**Examples**: specs/, specs/858_readmemd_files_throughout_claude_order_improve/

**README Requirement**: ROOT ONLY
- Root directory requires comprehensive README.md explaining organization, file naming, usage patterns
- Individual topic subdirectories do NOT require READMEs (self-documenting via plans/, reports/, summaries/ structure)

**Template**: Use Template A (Top-level) for root directory

### Directory Classification Decision Tree

1. Does directory contain source code, commands, agents, or libraries?
   → YES: Active Development Directory (README required for all)
   → NO: Continue to 2

2. Does directory contain temporary/ephemeral working files?
   → YES: Temporary Directory (README optional)
   → NO: Continue to 3

3. Does directory contain deprecated/archived code?
   → YES: Archive Directory (README required for root + timestamped manifests)
   → NO: Continue to 4

4. Does directory contain topic-based workflow artifacts?
   → YES: Topic Directory (README required for root only)
   → NO: Continue to 5

5. Does directory contain data, logs, backups, or registries?
   → YES: Utility Directory (README required for root only)
   → NO: Review classification with documentation team

### README Templates

[Include the three templates from existing plan Task 1.2]

### Validation

Run validation before committing:
```bash
.claude/scripts/validate-readmes.sh
```

The validation script should check:
- Active development directories have READMEs at all levels
- Utility directories have root README only
- Archive directories have root README and timestamped manifests
- Topic directories have root README only
- All READMEs follow template structure
```

**Integration**: Add to docs/reference/standards/README.md inventory list

### Recommendation 2: Update CLAUDE.md Documentation Policy Section

**Action**: Edit /home/benjamin/.config/CLAUDE.md lines 192-197

**Current Text**:
```markdown
### README Requirements
Every subdirectory must have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs
```

**Revised Text**:
```markdown
### README Requirements

See [Documentation Standards](.claude/docs/reference/standards/documentation-standards.md) for complete README.md structure requirements, directory classification, and template selection guide.

**Directory Classification Quick Reference**:
- **Active Development** (commands/, agents/, lib/, docs/, tests/, scripts/): README.md required at all levels
- **Utility** (data/, backups/): Root README.md only, documents purpose and lifecycle
- **Temporary** (tmp/): README.md optional, cleanup policy if created
- **Archive** (archive/): Root README.md plus timestamped manifests for cleanup subdirectories
- **Topic-Based** (specs/): Root README.md only, individual topics self-documenting

**Standard README Sections**:
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module (active directories only)
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs
```

### Recommendation 3: Update Existing Plan Task 5.4 Documentation Policy Enhancement

**Action**: Revise existing plan lines 698-723 (Phase 5, Task 5.4)

**Current Approach**: Adds subsections directly to CLAUDE.md

**Revised Approach**:
1. Create documentation-standards.md (Recommendation 1)
2. Update CLAUDE.md to reference documentation-standards.md (Recommendation 2)
3. Remove direct subsection additions to CLAUDE.md (keeps CLAUDE.md concise)

**Rationale**:
- CLAUDE.md is a quick reference index, not comprehensive documentation
- Detailed standards belong in .claude/docs/reference/standards/
- Follows existing pattern (testing-protocols.md, code-standards.md, output-formatting.md all referenced from CLAUDE.md)

### Recommendation 4: Clarify archive/, specs/, tmp/ README Requirements in Plan

**Action**: Add explicit guidance to existing plan Phase 2, Task 2.1

**Current Text** (lines 286-304): Lists backups/README.md and data/registries/README.md as priorities

**Add Clarification**:
```markdown
**archive/README.md** (PRIORITY: MEDIUM):
- Purpose: Deprecated code and historical artifact storage
- Organization: By date (cleanup-YYYY-MM-DD/) and by type (deprecated-agents/, legacy-workflow-commands/)
- Recovery: Process for restoring archived code if needed
- Manifests: Timestamped subdirectories maintain their own manifest READMEs documenting what was archived when
- Navigation: Link to main .claude/ directories
- Template: Template C (Utility Directory)

**specs/README.md** (ALREADY EXISTS):
- Status: Comprehensive, follows standards (verified lines 1-169)
- Action: No changes needed
- Individual topic directories (e.g., 858_/): Do NOT create READMEs - topics are self-documenting

**tmp/README.md** (PRIORITY: LOW, OPTIONAL):
- Purpose: Temporary working files and state preservation
- Lifecycle: Ephemeral, gitignored, cleaned periodically
- Contents: State files (build_state_id.txt, plan_state_id.txt), validation baselines, working directories
- Cleanup: Manual cleanup, no retention policy
- Navigation: Link to parent .claude/
- Template: Template C (Utility Directory) with minimal sections
- Alternative: Mark as exception in documentation-standards.md - README optional for tmp/
```

### Recommendation 5: Add Documentation Standards to Reference Inventory

**Action**: Edit /home/benjamin/.config/.claude/docs/reference/standards/README.md

**Current Content** (lines 1-26): Lists 10 standards documents

**Addition** (line 11, insert in alphabetical order):
```markdown
| documentation-standards.md | README.md structure requirements and directory classification |
```

This ensures the new standard is discoverable via the standards directory index.

## References

### Primary Sources Analyzed

1. /home/benjamin/.config/CLAUDE.md:188-212 - Current documentation policy section
2. /home/benjamin/.config/CLAUDE.md:192-197 - README requirements (absolute "must have" mandate)
3. /home/benjamin/.config/.claude/docs/concepts/directory-organization.md:1-100 - Directory categorization
4. /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:1-558 - Timeless writing principles
5. /home/benjamin/.config/.claude/docs/guides/commands/document-command-guide.md:1-80 - /document command scope
6. /home/benjamin/.config/.claude/docs/reference/standards/README.md:1-26 - Standards directory inventory
7. /home/benjamin/.config/.claude/specs/README.md:1-169 - Existing comprehensive specs documentation
8. /home/benjamin/.config/.claude/specs/858_readmemd_files_throughout_claude_order_improve/plans/001_readmemd_files_throughout_claude_order_i_plan.md:174-253 - Template C (Utility Directory)
9. /home/benjamin/.config/.claude/specs/858_readmemd_files_throughout_claude_order_improve/plans/001_readmemd_files_throughout_claude_order_i_plan.md:686-723 - Phase 5 Task 5.4 documentation policy updates

### Directory Structure Verified

10. /home/benjamin/.config/.claude/archive/ - Contains 5 timestamped manifest READMEs in subdirectories, no root README
11. /home/benjamin/.config/.claude/specs/ - Contains comprehensive root README, individual topics lack READMEs
12. /home/benjamin/.config/.claude/tmp/ - Contains transient files, no README
13. /home/benjamin/.config/.claude/docs/reference/standards/ - Contains 11 standards files, no documentation-standards.md

### Related Documentation

14. /home/benjamin/.config/.claude/docs/guides/patterns/README.md:1-59 - Pattern guides structure
15. /home/benjamin/.config/.claude/docs/guides/README.md - Guides index (location context)
