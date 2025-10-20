---
command-type: primary
dependent-commands: list-summaries, validate-setup
description: Update all relevant documentation based on recent code changes
argument-hint: [change-description] [scope]
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Task, TodoWrite
---

# /document Command

**YOU MUST update documentation following exact process:**

**CRITICAL INSTRUCTIONS**:
- Execute all documentation steps in EXACT sequential order
- DO NOT skip cross-reference verification
- DO NOT skip README updates
- DO NOT skip CLAUDE.md compliance checks
- DO NOT skip documentation validation
- Fallback mechanisms ensure 100% documentation completeness

Updates all relevant documentation to accurately reflect the current codebase state, ensuring compliance with project documentation standards defined in CLAUDE.md.

## Usage

```
/document [change-description] [scope]
```

### Arguments

- `[scope-description]` (optional): Brief description of area to document
- `[scope]` (optional): Specific directory or module to focus on (defaults to entire codebase)

## Examples

### Auto-detect Scope
```
/document
```
Analyzes the codebase and updates all relevant documentation

### With Scope Description
```
/document "Kitty terminal support and command picker" nvim/lua/neotex
```

### Scoped Documentation
```
/document "Authentication system" nvim/lua/neotex/auth
```

## Process

### 1. **Scope Detection**
- Analyzes affected areas of the codebase
- Identifies files and their types
- Determines which documentation needs updating
- Reviews implementation summaries if available

**MANDATORY VERIFICATION - Scope and Paths Validated**:

```bash
# Verify scope is valid
if [ -z "$SCOPE" ]; then
  SCOPE="$PWD"
  echo "✓ Using current directory as scope: $SCOPE"
fi

# Verify scope path exists
if [ ! -d "$SCOPE" ]; then
  echo "❌ ERROR: Scope directory not found: $SCOPE"
  exit 1
fi

# Identify documentation files in scope
DOC_FILES=$(find "$SCOPE" -name "README.md" -o -name "*.md" | sort)
DOC_COUNT=$(echo "$DOC_FILES" | wc -l)

echo "✓ VERIFIED: Scope validated ($DOC_COUNT documentation files found)"
```

### 2. **Standards Verification**

**YOU MUST verify documentation standards. This is NOT optional.**

**STEP 1 (REQUIRED) - Load and Verify Documentation Standards**

**EXECUTE NOW - Read CLAUDE.md Documentation Standards**

**ABSOLUTE REQUIREMENT**: YOU MUST read and apply documentation standards from CLAUDE.md. This is NOT optional.

**WHY THIS MATTERS**: Documentation standards ensure consistency and compliance across all project documentation.

- Reads CLAUDE.md for project documentation standards
- Checks for specific requirements:
  - README.md requirements per directory
  - Code style documentation
  - ASCII diagram standards
  - Character encoding rules
  - API documentation format

**MANDATORY VERIFICATION - Verify Standards Loaded**

**Verification Steps**:
```bash
# Load documentation standards
STANDARDS_FILE=$(find_upward_claude_md "$PWD")

if [ -z "$STANDARDS_FILE" ] || [ ! -f "$STANDARDS_FILE" ]; then
  echo "⚠️  CLAUDE.md not found - Using default standards"
  # Fallback: Use sensible defaults
else
  # Extract documentation policy section
  DOC_POLICY=$(extract_section "$STANDARDS_FILE" "documentation_policy")
  echo "✓ Documentation standards loaded from: $STANDARDS_FILE"
fi
```

**Fallback Mechanism**:
- If CLAUDE.md not found → Use sensible language-specific defaults
- If documentation_policy section missing → Use core requirements (README.md, UTF-8, no emojis)

### 3. **Documentation Identification**
Automatically identifies and updates:
- **README.md files** in affected directories
- **API documentation** for modified functions/modules
- **Configuration documentation** for settings
- **Command documentation** for CLI functionality
- **Architecture docs** for system structure
- **CHANGELOG.md** if present

### 4. **Documentation Updates**

#### README.md Updates
Following CLAUDE.md standards:
```markdown
# Directory Name

Brief description of directory purpose.

## Modules

### filename.lua
Description of what this module does and its key functions.

## Subdirectories

- [subdirectory-name/](subdirectory-name/README.md) - Brief description

## Navigation
- [← Parent Directory](../README.md)
```

#### Function Documentation
- Updates docstrings and annotations
- Maintains parameter descriptions
- Updates return value documentation
- Adds usage examples if missing

#### Configuration Documentation
- Updates available options
- Documents current settings
- Updates default values
- Documents option behaviors

**MANDATORY VERIFICATION - All Documentation Files Created/Updated**:

```bash
# Verify all required documentation files exist
REQUIRED_DOCS=()
MISSING_DOCS=()

# Check for README.md in each directory with code
for dir in $(find "$SCOPE" -type d); do
  # Skip hidden and non-code directories
  [[ "$dir" =~ /\. ]] && continue
  [[ "$dir" =~ /(node_modules|vendor|dist|build)/ ]] && continue

  # Check if directory has code files
  CODE_FILES=$(find "$dir" -maxdepth 1 -type f \( -name "*.lua" -o -name "*.md" -o -name "*.sh" \) 2>/dev/null)

  if [ -n "$CODE_FILES" ]; then
    README_PATH="$dir/README.md"
    REQUIRED_DOCS+=("$README_PATH")

    if [ ! -f "$README_PATH" ]; then
      MISSING_DOCS+=("$README_PATH")
      echo "⚠️  Missing README.md: $dir"
    fi
  fi
done

# Report results
if [ ${#MISSING_DOCS[@]} -eq 0 ]; then
  echo "✓ VERIFIED: All required documentation files exist (${#REQUIRED_DOCS[@]} files)"
else
  echo "⚠️  WARNING: ${#MISSING_DOCS[@]} missing README.md files (should be created)"
  for missing in "${MISSING_DOCS[@]}"; do
    echo "  - $missing"
  done
fi

# Verify updated files were actually modified
for doc_file in "${UPDATED_FILES[@]}"; do
  if [ ! -f "$doc_file" ]; then
    echo "❌ ERROR: Updated file not found: $doc_file"
    exit 1
  fi
done

echo "✓ VERIFIED: All updated documentation files exist"
```

### 5. **Compliance Checks**

**YOU MUST perform compliance checks. This is NOT optional.**

**STEP 2 (REQUIRED) - Verify Documentation Compliance**

**EXECUTE NOW - Check All Documentation Standards**

**ABSOLUTE REQUIREMENT**: YOU MUST verify all documentation meets standards. This is NOT optional.

**WHY THIS MATTERS**: Compliance checks prevent documentation drift and ensure maintainability.

#### Style Compliance
**MANDATORY CHECKS**:
- ✓ Indentation (as specified in CLAUDE.md)
- ✓ Line length limits
- ✓ Naming conventions
- ✓ Import organization

#### Content Requirements
**MANDATORY CHECKS**:
- ✓ All directories have README.md
- ✓ All public functions documented
- ✓ Configuration options explained
- ✓ System capabilities accurately described

#### Formatting Standards
**MANDATORY CHECKS**:
- ✓ UTF-8 encoding (no emojis in files)
- ✓ Box-drawing characters for diagrams
- ✓ Markdown formatting consistency
- ✓ Code example syntax highlighting

**MANDATORY VERIFICATION - Verify Compliance Standards Met**

**Verification Process**:
```bash
# Check each updated file for compliance
COMPLIANCE_ERRORS=0

for doc_file in $UPDATED_FILES; do
  # Check UTF-8 encoding
  if ! file "$doc_file" | grep -q "UTF-8"; then
    echo "❌ Encoding error: $doc_file (not UTF-8)"
    ((COMPLIANCE_ERRORS++))
  fi

  # Check for emojis in content
  if grep -P '[\x{1F300}-\x{1F9FF}]' "$doc_file" > /dev/null 2>&1; then
    echo "❌ Emoji found in: $doc_file"
    ((COMPLIANCE_ERRORS++))
  fi

  # Check for README.md in each directory
  if [ -d "$doc_file" ] && [ ! -f "$doc_file/README.md" ]; then
    echo "⚠️  Missing README.md in: $doc_file"
    ((COMPLIANCE_ERRORS++))
  fi
done

if [ $COMPLIANCE_ERRORS -eq 0 ]; then
  echo "✓ All compliance checks passed"
else
  echo "⚠️  Compliance errors found: $COMPLIANCE_ERRORS"
  echo "Manual review required"
fi
```

### 6. **Cross-Reference Updates**

**YOU MUST verify and fix cross-references. This is NOT optional.**

**STEP 3 (REQUIRED) - Verify All Cross-References**

**EXECUTE NOW - Check and Fix Document Links**

**ABSOLUTE REQUIREMENT**: YOU MUST verify all cross-references are valid. This is NOT optional.

**WHY THIS MATTERS**: Broken links reduce documentation usability and indicate documentation drift.

**MANDATORY OPERATIONS**:
- ✓ Updates links between documents
- ✓ Fixes broken references
- ✓ Updates navigation sections
- ✓ Maintains document hierarchy

**MANDATORY VERIFICATION - Verify All Cross-References Valid**

**Verification Process**:
```bash
# Extract and verify all markdown links
BROKEN_LINKS=0

for doc_file in $UPDATED_FILES; do
  # Extract all markdown links
  LINKS=$(grep -oP '\[.*?\]\(\K[^)]+' "$doc_file" 2>/dev/null || echo "")

  while IFS= read -r link; do
    [ -z "$link" ] && continue

    # Skip external URLs
    [[ "$link" =~ ^https?:// ]] && continue

    # Resolve relative path
    DOC_DIR=$(dirname "$doc_file")
    RESOLVED_PATH=$(cd "$DOC_DIR" && realpath -m "$link" 2>/dev/null)

    # Check if file exists
    if [ ! -f "$RESOLVED_PATH" ] && [ ! -d "$RESOLVED_PATH" ]; then
      echo "❌ BROKEN LINK in $doc_file: $link → $RESOLVED_PATH"
      ((BROKEN_LINKS++))
    fi
  done <<< "$LINKS"
done

if [ $BROKEN_LINKS -eq 0 ]; then
  echo "✓ All cross-references valid"
else
  echo "⚠️  Broken links found: $BROKEN_LINKS"
  echo "Manual review required"
fi
```

**Fallback Mechanism**:
- If link verification fails → Log broken links but continue
- Document broken links in update summary
- Non-blocking (documentation updates complete)

## Documentation Priorities

### High Priority
1. **Public APIs** - External interfaces and their usage
2. **Configuration Options** - Available settings and their effects
3. **Core Functionality** - Primary features and capabilities

### Medium Priority
1. **Internal Architecture** - System structure and organization
2. **Code Comments** - Inline documentation and explanations
3. **Module Organization** - Component relationships

### Low Priority
1. **Performance Characteristics** - Current performance metrics and behavior
2. **Implementation Details** - Technical specifics and internals
3. **Test Documentation** - Test case descriptions and coverage

## Output

### Updated Files
The command will update:
- All affected README.md files
- Module documentation headers
- Configuration documentation
- API reference documents
- Architecture diagrams (if needed)

### Report Generation
Creates a summary of documentation updates:
```
Documentation Update Summary
============================
Files Updated: 12
- nvim/lua/neotex/ai-claude/README.md (added new modules)
- nvim/lua/neotex/ai-claude/commands/README.md (updated features)
- CLAUDE.md (added new standards)

Compliance Checks: ✓ All passed
New Documentation: 3 files created
Broken Links Fixed: 2
```

## Standards Compliance

### CLAUDE.md Requirements
Automatically enforces:
- **Documentation Policy**: Every subdirectory must have README.md
- **Content Requirements**: Purpose, modules, navigation
- **ASCII Diagrams**: Using Unicode box-drawing characters
- **No Emojis**: In file content (only runtime UI)
- **UTF-8 Encoding**: All documentation files
- **Timeless Writing**: No historical commentary, temporal markers, or version references (see CLAUDE.md "Development Philosophy → Documentation Standards")

### Markdown Standards
- Clear, concise language
- Code examples with syntax highlighting
- Consistent formatting
- Proper heading hierarchy
- Link validity

## Best Practices

### DO
- **Keep docs current**: Ensure documentation reflects actual codebase state
- **Review before committing**: Verify documentation accuracy
- **Include examples**: Add usage examples for features
- **Maintain consistency**: Follow established patterns
- **Document behavior**: Explain what the system does and how it works

### DON'T
- **Over-document**: Avoid redundant documentation
- **Break existing docs**: Preserve valid existing content
- **Add emojis**: Follow encoding standards
- **Create without purpose**: Every doc should add value
- **Ignore standards**: Always check CLAUDE.md

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

## Integration with Other Commands

### Before Documenting
- Use `/implement` to complete code changes
- Use `/test` to verify functionality
- Use `/list-summaries` to review implementation history

### After Documenting
- Review all updated documentation
- Commit documentation with code changes
- Use `/validate-setup` to verify compliance

## Special Cases

### Feature Documentation
- Creates comprehensive documentation
- Adds usage examples
- Updates feature lists
- Documents capabilities and limitations

### Architecture Documentation
- Updates architectural documentation
- Modifies module descriptions
- Updates code examples
- Documents system organization

### Troubleshooting Documentation
- Updates troubleshooting guides
- Documents resolution approaches
- Adds diagnostic procedures
- Documents common issues and solutions

## Error Handling

### Missing CLAUDE.md
- Falls back to sensible defaults
- Creates basic documentation structure
- Suggests creating CLAUDE.md

### Conflicts
- Preserves custom sections
- Merges changes carefully
- Reports conflicts for manual review

### Invalid Documentation
- Reports formatting issues
- Suggests corrections
- Maintains backup of originals

## Checkpoint Reporting

**YOU MUST report documentation update checkpoint. This is NOT optional.**

**CHECKPOINT REQUIREMENT - Report Documentation Updates Complete**

**ABSOLUTE REQUIREMENT**: After all documentation updates complete, YOU MUST report this checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Checkpoint reporting confirms successful documentation updates with compliance verified and cross-references validated.

**Report Format**:

```
CHECKPOINT: Documentation Updates Complete
- Scope: ${SCOPE_DESCRIPTION}
- Files Updated: ${UPDATED_FILE_COUNT}
- Compliance Checks: ${COMPLIANCE_STATUS}
- Cross-References: ${CROSSREF_STATUS}
- Broken Links Fixed: ${BROKEN_LINKS_FIXED}
- New Documentation: ${NEW_DOC_COUNT}
- Standards: ✓ CLAUDE.md COMPLIANT
- Status: DOCUMENTATION CURRENT
```

**Required Information**:
- Scope description (from user input or auto-detected)
- Number of files updated
- Compliance check status (passed/warnings)
- Cross-reference verification status (all valid/broken links found)
- Number of broken links fixed
- Number of new documentation files created
- Standards compliance confirmation
- Documentation current status

---

## Agent Usage

For agent invocation patterns, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns). For documentation standards and artifact references, see [Artifact Referencing Patterns](../docs/command-patterns.md#artifact-referencing-patterns).

**Document-specific agent:**

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| doc-writer | Maintain documentation consistency | Standards compliance, cross-referencing, completeness checks |

**Delegation Benefits:**
- Consistent documentation format and style
- Automatic adherence to CLAUDE.md policy
- Proper linking between docs, specs, plans, reports
- Ensures all required documentation exists

**Standards Enforced:**
- README.md in every subdirectory
- Unicode box-drawing for diagrams
- No emojis (UTF-8 compliance)
- CommonMark specification
- Proper cross-references and navigation

## Notes

- **Automatic detection**: Analyzes code changes to determine documentation needs
- **Standards-compliant**: Follows project-specific documentation requirements
- **Non-destructive**: Preserves existing valid documentation
- **Comprehensive**: Updates all related documentation in one pass
- **Traceable**: Creates clear summary of all documentation changes
- **Idempotent**: Safe to run multiple times
- **Agent-Powered**: `doc-writer` ensures consistent, high-quality documentation