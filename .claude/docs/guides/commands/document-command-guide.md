# /document Command - Complete Guide

**Executable**: `.claude/commands/document.md`

**Quick Start**: Run `/document [change-description] [scope]` - the command is self-executing.

---

## Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
3. [Documentation Process](#documentation-process)
4. [Standards Compliance](#standards-compliance)
5. [Documentation Priorities](#documentation-priorities)
6. [Best Practices](#best-practices)
7. [Agent Integration](#agent-integration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The `/document` command updates all relevant documentation to accurately reflect the current codebase state, ensuring compliance with project documentation standards defined in CLAUDE.md.

### When to Use

- After implementing new features or bug fixes
- When code structure or APIs have changed
- To ensure documentation remains synchronized with code
- To fix broken cross-references
- To add missing README.md files
- To enforce documentation standards across the project

### Key Features

- **Automatic detection**: Analyzes code changes to determine documentation needs
- **Standards-compliant**: Follows project-specific documentation requirements from CLAUDE.md
- **Non-destructive**: Preserves existing valid documentation
- **Comprehensive**: Updates all related documentation in one pass
- **Traceable**: Creates clear summary of all documentation changes
- **Idempotent**: Safe to run multiple times
- **Agent-Powered**: Delegates complex analysis to specialized agents

---

## Usage

### Syntax

```bash
/document [change-description] [scope]
```

### Arguments

- `[change-description]` (optional): Brief description of changes that need documentation
- `[scope]` (optional): Specific directory or module to focus on (defaults to current directory)

### Examples

#### Auto-detect Scope

```bash
/document
```

Analyzes the codebase and updates all relevant documentation in the current directory.

#### With Change Description

```bash
/document "Added authentication system with OAuth2 support"
```

Focuses documentation updates on authentication-related changes.

#### Scoped Documentation

```bash
/document "Kitty terminal support and command picker" nvim/lua/neotex
```

Updates documentation only within the specified directory scope.

#### Full Project Documentation Update

```bash
/document "Complete refactor of plugin architecture" .
```

Updates all documentation across the entire project.

---

## Documentation Process

### Phase 0: Initialize and Verify Scope

The command first validates the target scope:

1. **CLAUDE_PROJECT_DIR Detection**: Uses Standard 13 to detect project root
2. **Argument Parsing**: Extracts change description and scope from arguments
3. **Scope Validation**: Verifies the target directory exists
4. **File Discovery**: Identifies all documentation files (*.md) in scope
5. **Checkpoint**: Reports scope validation and file count

**Output Example**:
```
✓ VERIFIED: Scope validated (23 documentation files found)
Scope: /home/user/project/nvim/lua/neotex
Change Description: Added authentication system
```

### Phase 1: Load Documentation Standards

Loads project-specific documentation standards from CLAUDE.md:

1. **Find CLAUDE.md**: Searches project root for standards file
2. **Extract Policy**: Reads `documentation_policy` section if present
3. **Fallback**: Uses sensible defaults if CLAUDE.md not found
4. **Standards Summary**: Reports loaded standards

**Default Standards (Fallback)**:
- README.md required per directory
- UTF-8 encoding for all documentation
- No emojis in file content
- Unicode box-drawing for diagrams
- Cross-references must be valid
- Timeless writing (no temporal markers)

### Phase 2: Identify Documentation Updates Needed

Delegates to specialized agent for analysis:

**Agent Task**: Analyzes codebase to identify:
- Directories missing README.md files
- Outdated documentation based on recent code changes
- Missing API documentation for public functions
- Broken cross-references between documents
- Non-compliant documentation (emojis, wrong encoding, etc.)

**Agent Returns**: Structured list of updates needed with priorities.

### Phase 3: Update Documentation

Performs the actual documentation updates:

#### README.md Updates

Creates or updates README.md files following this structure:

```markdown
# Directory Name

Brief description of directory purpose.

## Modules

### filename.lua
Description of what this module does and its key functions.

### another-module.lua
Description of this module's purpose and key functionality.

## Subdirectories

- [subdirectory-name/](subdirectory-name/README.md) - Brief description

## Navigation
- [← Parent Directory](../README.md)
```

#### Function Documentation

Updates inline documentation:
- Docstrings and annotations
- Parameter descriptions
- Return value documentation
- Usage examples

#### Configuration Documentation

Updates configuration docs:
- Available options and their descriptions
- Current settings and defaults
- Option behaviors and side effects
- Configuration examples

#### Compliance Checks

After updates, validates:
- **UTF-8 Encoding**: All files must be UTF-8
- **No Emojis**: File content must not contain emoji characters
- **Standards**: Follows CLAUDE.md documentation policy

**Example Output**:
```
✓ All compliance checks passed
```

### Phase 4: Verify Cross-References

Validates all markdown links in updated documentation:

1. **Extract Links**: Finds all `[text](path)` style links
2. **Skip External**: Ignores http:// and https:// URLs
3. **Resolve Paths**: Converts relative paths to absolute
4. **Verify Existence**: Checks that target files/directories exist
5. **Report Broken Links**: Lists any invalid references for manual review

**Example Output**:
```
✓ All cross-references valid
```

or

```
⚠️  Broken links found: 2 (manual review needed)
❌ BROKEN LINK in README.md: ../old-module/api.md
❌ BROKEN LINK in docs/guide.md: ../removed-feature.md
```

### Phase 5: Report Completion

Provides comprehensive checkpoint report:

```
========================================
CHECKPOINT: Documentation Updates Complete
========================================
Scope: Added authentication system
Files Updated: 8
Compliance: 0 errors
Broken Links: 0 found
Standards: ✓ CLAUDE.md COMPLIANT
Status: DOCUMENTATION CURRENT
========================================
```

---

## Standards Compliance

### CLAUDE.md Requirements

The command automatically enforces these standards from CLAUDE.md:

#### Documentation Policy
- **Every subdirectory must have README.md**: Ensures navigability
- **Content Requirements**: Purpose, modules/files, navigation links
- **ASCII Diagrams**: Using Unicode box-drawing characters (not ASCII art)
- **No Emojis**: In file content (only runtime UI if applicable)
- **UTF-8 Encoding**: All documentation files
- **Timeless Writing**: No historical commentary, temporal markers, or version references

#### Timeless Writing Policy

Documentation must read as if the current implementation always existed:

**Avoid**:
- Temporal markers: "(New)", "(Old)", "(Updated)", "(Current)", "(Deprecated)"
- Temporal phrases: "previously", "recently", "now supports", "used to", "no longer"
- Migration language: "migration from", "backward compatibility", "breaking change"
- Version references: "v1.0", "since version", "as of version"

**Use Instead**:
- Present-tense descriptions of current functionality
- Focus on what the system does, not what changed
- Move historical context to CHANGELOG.md if needed
- Document current behavior without comparison to past

### Markdown Standards

- **Clear, concise language**: Avoid unnecessary verbosity
- **Code examples with syntax highlighting**: Use triple backticks with language
- **Consistent formatting**: Follow established patterns in project
- **Proper heading hierarchy**: h1 → h2 → h3 (no skipping levels)
- **Link validity**: All cross-references must resolve to existing files

---

## Documentation Priorities

### High Priority

These are updated first and must be complete:

1. **Public APIs**: External interfaces and their usage patterns
2. **Configuration Options**: Available settings and their effects
3. **Core Functionality**: Primary features and capabilities

### Medium Priority

Updated after high-priority items:

1. **Internal Architecture**: System structure and organization
2. **Code Comments**: Inline documentation and explanations
3. **Module Organization**: Component relationships and dependencies

### Low Priority

Updated if time permits:

1. **Performance Characteristics**: Current performance metrics and behavior
2. **Implementation Details**: Technical specifics and internals
3. **Test Documentation**: Test case descriptions and coverage

---

## Best Practices

### DO

- **Keep docs current**: Run `/document` after completing implementation
- **Review before committing**: Verify documentation accuracy
- **Include examples**: Add usage examples for features
- **Maintain consistency**: Follow established patterns
- **Document behavior**: Explain what the system does and how it works
- **Use present tense**: "The module handles..." not "The module will handle..."
- **Be specific**: Provide concrete details, not vague descriptions

### DON'T

- **Over-document**: Avoid redundant or obvious documentation
- **Break existing docs**: Preserve valid existing content
- **Add emojis**: Follow encoding standards (UTF-8, no emojis)
- **Create without purpose**: Every doc should add value
- **Ignore standards**: Always check CLAUDE.md before documenting
- **Use temporal markers**: No "(New)", "recently", "now supports", etc.
- **Document history**: Use CHANGELOG.md for historical changes

---

## Agent Integration

### Documentation Analysis Agent

The `/document` command delegates complex analysis to a specialized agent:

**Agent Purpose**:
- Analyze codebase for documentation needs
- Identify outdated or missing documentation
- Validate documentation compliance
- Ensure standards adherence

**Agent Capabilities**:
- **Standards Compliance**: Automatic adherence to CLAUDE.md policy
- **Cross-Referencing**: Proper linking between docs, specs, plans, reports
- **Completeness Checks**: Ensures all required documentation exists
- **Format Consistency**: Maintains uniform documentation style

**Delegation Benefits**:
- Consistent documentation format and style
- Automatic enforcement of project standards
- Comprehensive cross-reference validation
- Reduced manual effort for large-scale updates

### When Agent Delegation Occurs

The command invokes an agent in Phase 2 for:
- Large scope (>20 files)
- Complex change descriptions
- Cross-module documentation updates
- Initial documentation generation

For simple updates (single file, small scope), the command may execute directly.

---

## Troubleshooting

### Missing CLAUDE.md

**Symptom**: Warning "CLAUDE.md not found - Using default standards"

**Resolution**:
1. Create CLAUDE.md with `/setup` command
2. Verify CLAUDE.md exists in project root
3. Check for typos in filename (must be CLAUDE.md, not claude.md)

**Impact**: Command uses sensible defaults if CLAUDE.md missing

### Compliance Errors

**Symptom**: "Compliance errors found: N"

**Common Issues**:
- **Encoding errors**: File not UTF-8
  - Solution: Convert file to UTF-8 encoding
  - Command: `iconv -f ISO-8859-1 -t UTF-8 file.md > file.md.utf8 && mv file.md.utf8 file.md`
- **Emoji found**: Documentation contains emoji characters
  - Solution: Remove emojis from file content
  - Use Unicode box-drawing characters instead of emoji for diagrams

### Broken Links

**Symptom**: "Broken links found: N (manual review needed)"

**Resolution**:
1. Review reported broken links
2. Update links to correct paths
3. Remove links to deleted files
4. Consider creating referenced files if they should exist
5. Re-run `/document` to verify fixes

**Prevention**:
- Use relative paths for internal links
- Test links after major refactors
- Run `/document` regularly to catch drift early

### Documentation Conflicts

**Symptom**: Agent reports conflicts between existing and generated docs

**Resolution**:
1. Review conflicting sections manually
2. Preserve custom sections if still relevant
3. Merge changes carefully
4. Update custom content to match current code
5. Use git diff to see what changed

### No Updates Detected

**Symptom**: Command completes but reports 0 files updated

**Possible Causes**:
- Documentation already current
- Scope too narrow (missed relevant files)
- No code changes since last documentation update

**Resolution**:
1. Verify scope includes changed files
2. Check if documentation truly reflects current code
3. Expand scope if needed
4. Run with broader change description

### Agent Fails to Analyze

**Symptom**: Agent invocation fails or times out

**Resolution**:
1. Reduce scope to smaller directory
2. Provide more specific change description
3. Check for corrupted files in scope
4. Verify .claude/agents/ directory exists
5. Run `/validate-setup` to check configuration

---

## Integration with Other Commands

### Before Documenting

Run these commands before `/document`:

- **`/implement`**: Complete code implementation first
- **`/test`**: Verify functionality works as documented
- **`/list-summaries`**: Review implementation history for context

### After Documenting

Follow-up with these commands:

- **Review**: Manually review all updated documentation for accuracy
- **Commit**: Commit documentation with code changes using descriptive message
- **`/validate-setup`**: Verify CLAUDE.md compliance and cross-references

### Documentation Workflow Example

```bash
# 1. Implement feature
/implement specs/plans/auth-system.md

# 2. Test implementation
/test-all

# 3. Document changes
/document "OAuth2 authentication system" src/auth

# 4. Review updates
git diff

# 5. Commit together
git add .
git commit -m "feat(auth): implement OAuth2 authentication with documentation"

# 6. Validate compliance
/validate-setup
```

---

## Special Cases

### Feature Documentation

When documenting new features:

1. **Create comprehensive documentation**: Full description, not just API reference
2. **Add usage examples**: Show realistic use cases
3. **Update feature lists**: Add to project README or feature index
4. **Document capabilities and limitations**: Set clear expectations

### Architecture Documentation

When documenting architectural changes:

1. **Update architectural documentation**: System design docs, component diagrams
2. **Modify module descriptions**: Reflect new relationships and dependencies
3. **Update code examples**: Ensure examples match new architecture
4. **Document system organization**: Explain how components interact

### Troubleshooting Documentation

When adding diagnostic information:

1. **Update troubleshooting guides**: Add new common issues
2. **Document resolution approaches**: Provide step-by-step fixes
3. **Add diagnostic procedures**: Help users identify problems
4. **Document common issues and solutions**: Build knowledge base

---

## Error Handling

### Graceful Degradation

The command is designed to continue even with partial failures:

- **Missing CLAUDE.md**: Falls back to sensible defaults
- **Broken Links**: Reports but doesn't block completion
- **Compliance Errors**: Reports but allows manual review
- **Agent Failures**: Degrades to direct execution for simple cases

### Rollback Strategy

If documentation updates introduce errors:

1. **Use git to revert**:
   ```bash
   git checkout HEAD -- path/to/file.md
   ```

2. **Review what changed**:
   ```bash
   git diff HEAD~1 path/to/file.md
   ```

3. **Selective revert**:
   - Keep good changes
   - Fix problematic sections manually
   - Re-run `/document` with narrower scope

---

## Output Examples

### Successful Completion

```
✓ VERIFIED: Scope validated (15 documentation files found)
Scope: /home/user/project/src/auth
Change Description: OAuth2 authentication system

✓ Documentation standards loaded from: /home/user/project/CLAUDE.md

Analyzing scope for documentation updates...

Updating documentation files:
- src/auth/README.md (updated modules section)
- src/auth/oauth2/README.md (created)
- docs/api/authentication.md (updated API reference)
- CHANGELOG.md (added entry)

✓ All compliance checks passed

Verifying cross-references...
✓ All cross-references valid

========================================
CHECKPOINT: Documentation Updates Complete
========================================
Scope: OAuth2 authentication system
Files Updated: 4
Compliance: 0 errors
Broken Links: 0 found
Standards: ✓ CLAUDE.md COMPLIANT
Status: DOCUMENTATION CURRENT
========================================
```

### With Warnings

```
✓ VERIFIED: Scope validated (8 documentation files found)
Scope: /home/user/project/src/legacy
Change Description: Auto-detected

⚠️  CLAUDE.md not found - Using default standards

Analyzing scope for documentation updates...

Updating documentation files:
- src/legacy/README.md (updated)
- src/legacy/old-module/README.md (updated)

⚠️  Compliance errors found: 2
❌ Encoding error: src/legacy/old-file.md (not UTF-8)
❌ Emoji found in: src/legacy/README.md

Verifying cross-references...
⚠️  Broken links found: 1 (manual review needed)
❌ BROKEN LINK in src/legacy/README.md: ../removed/api.md

========================================
CHECKPOINT: Documentation Updates Complete
========================================
Scope: /home/user/project/src/legacy
Files Updated: 2
Compliance: 2 errors
Broken Links: 1 found
Standards: ⚠️  MANUAL REVIEW REQUIRED
Status: DOCUMENTATION NEEDS REVIEW
========================================
```

---

## Documentation Review Checklist

Before finalizing documentation updates, verify:

### Content Quality
- [ ] Documentation describes current state accurately
- [ ] Technical details are correct and complete
- [ ] Examples are functional and relevant
- [ ] Navigation links work correctly

### Standards Compliance
- [ ] No emojis in file content (UTF-8 compliance)
- [ ] Unicode box-drawing used for diagrams (not ASCII art)
- [ ] Markdown follows CommonMark specification
- [ ] Line length within limits (if specified in CLAUDE.md)

### Timeless Writing Policy
- [ ] No temporal markers: "(New)", "(Old)", "(Updated)", "(Current)", "(Deprecated)"
- [ ] No temporal phrases: "previously", "recently", "now supports", "used to", "no longer"
- [ ] No migration language: "migration from", "backward compatibility", "breaking change"
- [ ] No version references in descriptions: "v1.0", "since version", "as of version"
- [ ] Documentation reads as if current implementation always existed
- [ ] Historical context moved to CHANGELOG.md if needed

### Directory Structure
- [ ] Every subdirectory has README.md
- [ ] README includes: purpose, modules, navigation
- [ ] Cross-references are complete and accurate
- [ ] Parent/child links maintained

---

## Notes

- **Idempotent Operation**: Safe to run multiple times on the same scope
- **Non-Destructive**: Preserves valid existing documentation
- **Standards-Driven**: Follows CLAUDE.md documentation policy
- **Agent-Powered**: Delegates complex analysis for consistency
- **Fail-Safe**: Continues with warnings rather than blocking on non-critical issues
