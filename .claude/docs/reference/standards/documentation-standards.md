# Documentation Standards

Comprehensive README.md structure requirements, directory classification, and template selection guide for the .claude/ system.

## README.md Requirements

### Directory Classification

All directories in .claude/ are classified into one of five categories, each with specific README requirements.

#### Active Development Directories

Directories containing source code, commands, agents, or active development artifacts.

**Examples**: `commands/`, `agents/`, `lib/`, `docs/`, `tests/`, `scripts/`, `hooks/`

**README Requirement**: REQUIRED at all levels
- Every directory and subdirectory must have README.md
- Purpose statement (what the directory contains)
- Module/file documentation (what each file does)
- Usage examples (how to use the contents)
- Navigation links (parent, children, related)

**Template**: Use [Template A](#template-a-top-level-directory) (Top-level) or [Template B](#template-b-subdirectory) (Subdirectory)

**Rationale**: Active code requires continuous documentation to support development, onboarding, and maintenance.

#### Utility Directories

Directories containing data, logs, checkpoints, registries, or backups.

**Examples**: `data/`, `backups/`, `data/registries/`

**README Requirement**: ROOT ONLY
- Root directory requires README.md explaining purpose, structure, lifecycle
- Subdirectories do NOT require individual READMEs unless they contain 5+ distinct categories
- Document data lifecycle, cleanup policies, and gitignore status

**Template**: Use [Template C](#template-c-utility-directory) (Utility Directory)

**Rationale**: Utility directories have stable structures; subdirectory READMEs would become maintenance overhead without adding value.

#### Temporary Directories

Directories containing ephemeral working files, state files, or transient artifacts.

**Examples**: `tmp/`, `tmp/baselines/`, `tmp/link-validation/`

**README Requirement**: NOT REQUIRED
- Root README.md not required (content is ephemeral and self-documenting)
- Subdirectories do NOT require READMEs
- If circumstances change and documentation becomes necessary, use Template C

**Template**: N/A (excluded from README requirements)

**Rationale**: Temporary content is transient; documentation would become stale immediately and provide no long-term value.

#### Archive Directories

Directories containing deprecated code, old implementations, or historical artifacts.

**Examples**: `archive/`, `archive/deprecated-agents/`, `archive/lib/cleanup-2025-11-19/`

**README Requirement**: MANIFESTS ONLY (no root README)
- Root directory does NOT require README.md (directory purpose is self-evident from name)
- Timestamped cleanup subdirectories require manifest README.md documenting WHAT was archived WHEN
- These manifest READMEs are historical records, not active documentation
- Manifests should include: date, reason for archival, original location, contents summary

**Template**: Custom manifest template for cleanup subdirectories

**Manifest Template**:
```markdown
# {Original Directory Name} Archive

Content archived from {original_path} on {YYYY-MM-DD}.

## Reason for Archival

{Why this content was moved to archive/ - e.g., "Superseded by new implementation", "Deprecated after Phase 7 refactor"}

## Contents

{List of files/directories archived with brief descriptions}

## Original Location

{Original path where this content resided}

## Related Changes

{Link to PR, commit, or plan that triggered this archival}
```

**Rationale**: Archive directories are intentionally frozen; extensive documentation would imply they're active. Manifests provide historical context without suggesting ongoing maintenance.

#### Topic Directories

Directories containing workflow artifacts organized by topic (specs/, plans/, reports/).

**Examples**: `specs/`, `specs/858_readmemd_files_throughout_claude_order_improve/`

**README Requirement**: ROOT ONLY
- Root directory requires comprehensive README.md explaining organization, file naming, usage patterns
- Individual topic subdirectories do NOT require READMEs (self-documenting via plans/, reports/, summaries/ structure)
- Document workflow (how plans/reports/summaries are created and used)

**Template**: Use [Template A](#template-a-top-level-directory) (Top-level) for root directory

**Rationale**: Topic-based structure is self-documenting through consistent subdirectory organization. READMEs in each topic would duplicate information without adding value.

#### Test Fixture Directories

Directories containing test input data, mock files, or fixture structures for testing.

**Examples**: `tests/fixtures/`, `tests/fixtures/plans/test_adaptive/`, `tests/features/data/`

**README Requirement**: ROOT ONLY
- Root directory requires README.md explaining fixture organization, naming conventions, and usage
- Fixture subdirectories do NOT require individual READMEs (follow consistent patterns documented in root)
- Document how to add new fixtures and maintain existing ones

**Template**: Use [Template A](#template-a-top-level-directory) (Top-level) for root directory

**Rationale**: Fixture subdirectories follow consistent patterns (sample input files, expected outputs, mock data). Individual READMEs would duplicate the same structural information without adding value.

### Directory Classification Decision Tree

Use this decision tree to determine the correct classification for any directory:

```
1. Does directory contain source code, commands, agents, or libraries?
   → YES: Active Development Directory (README required at all levels)
   → NO: Continue to 2

2. Does directory contain temporary/ephemeral working files?
   → YES: Temporary Directory (README not required)
   → NO: Continue to 3

3. Does directory contain deprecated/archived code?
   → YES: Archive Directory (timestamped manifests only, no root README)
   → NO: Continue to 4

4. Does directory contain topic-based workflow artifacts?
   → YES: Topic Directory (README required for root only)
   → NO: Continue to 5

5. Does directory contain data, logs, backups, or registries?
   → YES: Utility Directory (README required for root only)
   → NO: Review classification with documentation team
```

### Standard README Sections

All READMEs (regardless of directory type) must include these standard sections when applicable:

#### Purpose Section (Required)

First paragraph provides one-sentence directory purpose. Followed by detailed explanation under `## Purpose` heading.

**Example**:
```markdown
# Library Name

Brief one-sentence purpose statement.

## Purpose

Detailed explanation of what this library does, when to use it, and how it fits into the system architecture.
```

#### Module Documentation (Required for Active Development Directories)

Document each file/module with:
- **Purpose**: What it does
- **Key Functions/Sections**: Main exports or capabilities
- **Usage Example**: Code demonstrating typical usage
- **Dependencies**: Required libraries or prerequisites

**Example**:
```markdown
## Files in This Directory

### utility-name.sh
**Purpose**: Provides X functionality for Y use cases

**Key Functions**:
- `function_name()` - Description
- `another_function()` - Description

**Usage Example**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/category/utility-name.sh"
result=$(function_name "argument")
```

**Dependencies**: Requires base-utils.sh, error-handling.sh
```

#### Navigation Section (Required)

Link to parent directory and related directories. Use arrow notation for parent links.

**Example**:
```markdown
## Navigation

- [← Parent Directory](../README.md)
- [Related: agents/](../agents/README.md) - AI assistants
- [Subdirectory: shared/](shared/README.md) - Shared utilities
```

#### Usage Examples (Required Where Applicable)

Provide concrete code examples demonstrating how to use the module/library/command.

**Guidelines**:
- Use bash syntax highlighting
- Include complete, runnable examples
- Show common patterns, not edge cases
- Include expected output if helpful

### README Templates

#### Template A: Top-Level Directory

Use for main directories like agents/, commands/, lib/, scripts/, docs/.

```markdown
# {Directory Name}

{One-paragraph purpose statement}

**Current {Item} Count**: {N} {items}

## Purpose

{Detailed explanation of directory role}

## {Key Section Based on Type}

[e.g., "Available Agents", "Workflow", "Directory Structure"]

## Module Documentation

### {Module/File Name}
- **Purpose**: {Description}
- **Usage**: {Example or pattern}
- **Dependencies**: {If applicable}

## Navigation

- [← Parent Directory](../README.md)
- [{Subdirectory}]({subdir}/README.md) - {Description}
- [Related: {Other}]({path}/README.md)
```

#### Template B: Subdirectory

Use for subdirectories within active development directories.

```markdown
# {Subdirectory Name}

{One-paragraph purpose statement}

## Purpose

{Detailed explanation}

## Files in This Directory

### {filename}
**Purpose**: {Description}
**Key Functions/Sections**: {List}
**Usage Example**: {Code block if applicable}

## Navigation

- [← Parent Directory](../README.md)
- [Related: {Other}]({path})
```

#### Template C: Utility Directory

Use for utility directories like data/, backups/, registries/.

```markdown
# {Directory Name}

{One-paragraph purpose statement}

## Purpose

{Explanation of directory role and lifecycle}

## Contents

{Description of what files/subdirectories typically exist here}

## Maintenance

{Cleanup policies, retention, gitignore status}

## Navigation

- [← Parent Directory](../README.md)
```

### Validation

Run validation before committing:

```bash
.claude/scripts/validate-readmes.sh
```

The validation script checks:
- Active development directories have READMEs at all levels
- Utility directories have root README only
- Temporary directories have no READMEs (excluded)
- Archive directories have timestamped manifests only (no root README)
- Topic directories have root README only
- All READMEs follow template structure
- Navigation links are not broken
- File listings match actual directory contents

Run comprehensive validation with link checking:

```bash
.claude/scripts/validate-readmes.sh --comprehensive
```

## Documentation Format Standards

All documentation (READMEs, guides, references) must follow these format standards:

### Content Standards

#### Unicode Character Usage

**Allowed Unicode Characters**:
- Box-drawing (U+2500-U+257F): ├ │ └ ─ ┌ ┐ ┤ ┬ ┴ ┼
- Arrows (U+2190-U+21FF): ← → ↔ ↑ ↓
- Mathematical operators (U+2200-U+22FF): ≥ ≤ × ≠ ± ∞
- Bullets and punctuation (U+2000-U+206F): • – — … ‹ ›
- Geometric shapes (U+25A0-U+25FF): ▼ ▲ ■ □ ◆
- Miscellaneous symbols (U+2600-U+26FF): ⚠ ✓ ☐ ☑ ★

**Prohibited Characters**:
- Emoji characters (U+1F300-U+1F9FF): 😀 🎉 ✨ 📝 🚀 ❌

**Rationale**: Unicode symbols are standard technical notation used in diagrams, lists, and documentation. Emojis cause UTF-8 encoding issues across different terminals and editors.

**Unicode Box-Drawing**: Use Unicode box-drawing characters for diagrams:
- Corners: ┌ ┐ └ ┘
- Lines: ─ │
- Intersections: ├ ┤ ┬ ┴ ┼
- Example: See .claude/README.md for workflow diagrams

**CommonMark Compliance**: Follow CommonMark specification for markdown syntax.

**Timeless Writing**: Avoid temporal markers like "new", "recently", "updated". Write as if the documentation is current at any point in time.

**Code Examples**: Always include syntax highlighting for code blocks:
```bash
# Use language identifier
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/base-utils.sh"
```

### Link Conventions

**Relative Paths**: Use relative paths for internal documentation links:
- Correct: `[commands/](../commands/README.md)`
- Incorrect: `[commands/](/home/user/.config/.claude/commands/README.md)`

**Arrow Notation**: Use left arrow (←) for parent directory links:
- `[← Parent Directory](../README.md)`
- `[← .claude/ Directory](../README.md)`

**Descriptive Links**: Provide context in link text:
- Correct: `[Error Handling Guide](docs/guides/error-handling.md)`
- Incorrect: `[Click here](docs/guides/error-handling.md)`

### Section Ordering

Standard section order for READMEs:
1. Title (H1)
2. Brief purpose statement (paragraph)
3. Metadata (if applicable - counts, versions, etc.)
4. Purpose (H2)
5. Content sections (H2 - varies by type)
6. Navigation (H2 - always last)

## Documentation Updates

### When to Update READMEs

Update documentation when:
- Adding new files to a directory
- Removing or deprecating files
- Changing file purpose or functionality
- Modifying directory structure
- Adding or removing subdirectories
- Updating dependencies between modules

### Update Checklist

When updating a README:
- [ ] Update file/module listings
- [ ] Verify code examples still work
- [ ] Check navigation links are correct
- [ ] Update item counts (if present)
- [ ] Verify dependencies are current
- [ ] Run validation script
- [ ] Update parent README if directory structure changed

### Validation Workflow

```bash
# 1. Make README changes
vim .claude/lib/core/README.md

# 2. Validate structure and links
.claude/scripts/validate-readmes.sh --comprehensive

# 3. Fix any issues identified

# 4. Commit with descriptive message
git add .claude/lib/core/README.md
git commit -m "docs(lib): update core library documentation"
```

## Examples of Excellent READMEs

These READMEs demonstrate best practices:

**Top-Level Directory Examples**:
- `.claude/docs/README.md` - Comprehensive Diataxis organization with clear navigation
- `.claude/commands/README.md` - Workflow visualization and command mapping
- `.claude/agents/README.md` - Command-to-agent mapping with model selection
- `.claude/lib/README.md` - Subdirectory overview with decision matrix

**Subdirectory Examples**:
- `.claude/lib/core/README.md` - Complete function listings with usage examples
- `.claude/docs/concepts/README.md` - Document summaries with cross-links
- `.claude/agents/shared/README.md` - Shared protocol documentation

**Utility Directory Examples**:
- `.claude/data/README.md` - Lifecycle documentation with cleanup policies
- `.claude/backups/README.md` - Clear retention policy and maintenance procedures

## Related Standards

- [Code Standards](code-standards.md) - Coding conventions and style guide
- [Output Formatting Standards](output-formatting.md) - Command output and logging
- [Testing Protocols](testing-protocols.md) - Test structure and coverage
- [Error Handling Pattern](../../concepts/patterns/error-handling.md) - Error logging and recovery

## Navigation

- [← standards/ Directory](README.md)
- [← reference/ Directory](../README.md)
- [← docs/ Directory](../../README.md)
