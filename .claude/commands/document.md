---
command-type: primary
dependent-commands: list-summaries, validate-setup
description: Update all relevant documentation based on recent code changes
argument-hint: [change-description] [scope]
allowed-tools: Read, Write, Edit, MultiEdit, Grep, Glob, Task, TodoWrite
---

# /document - Documentation Updater

YOU ARE EXECUTING AS the /document command.

**Documentation**: See `.claude/docs/guides/document-command-guide.md`

---

## Phase 0: Initialize and Verify Scope

```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Parse arguments
CHANGE_DESCRIPTION="${1:-}"
SCOPE="${2:-$PWD}"

# Verify scope path exists
if [ ! -d "$SCOPE" ]; then
  echo "❌ ERROR: Scope directory not found: $SCOPE"
  exit 1
fi

# Identify documentation files in scope
DOC_FILES=$(find "$SCOPE" -name "README.md" -o -name "*.md" | sort)
DOC_COUNT=$(echo "$DOC_FILES" | wc -l)

echo "✓ VERIFIED: Scope validated ($DOC_COUNT documentation files found)"
echo "Scope: $SCOPE"
echo "Change Description: ${CHANGE_DESCRIPTION:-Auto-detected}"
```

## Phase 1: Load Documentation Standards

```bash
# Load CLAUDE.md documentation standards
STANDARDS_FILE=$(find "$CLAUDE_PROJECT_DIR" -maxdepth 1 -name "CLAUDE.md" | head -1)

if [ -z "$STANDARDS_FILE" ] || [ ! -f "$STANDARDS_FILE" ]; then
  echo "⚠️  CLAUDE.md not found - Using default standards"
  # Fallback: Use sensible defaults
  DOC_POLICY="README.md required per directory, UTF-8 encoding, no emojis"
else
  echo "✓ Documentation standards loaded from: $STANDARDS_FILE"
  # Extract documentation_policy section if available
  DOC_POLICY=$(sed -n '/<!-- SECTION: documentation_policy -->/,/<!-- END_SECTION: documentation_policy -->/p' "$STANDARDS_FILE" || echo "Standards loaded")
fi
```

## Phase 2: Identify Documentation Updates Needed

**EXECUTE NOW**: USE the Task tool to delegate documentation analysis and updates.

```
Task tool invocation with subagent_type="general-purpose"
Prompt: "Analyze codebase scope '${SCOPE}' for documentation updates needed.

REQUIREMENTS:
- Identify all directories needing README.md files
- Find outdated documentation based on recent code changes
- Check for missing API documentation
- Verify cross-references validity
- Apply documentation standards: ${DOC_POLICY}

Return structured list:
- Directories needing README.md
- Files with outdated documentation
- Missing API docs
- Broken cross-references
"
```

## Phase 3: Update Documentation

**EXECUTE NOW**: Based on analysis results, update all identified documentation files.

```bash
# For each identified update needed:
# 1. Update README.md files
# 2. Fix API documentation
# 3. Update configuration docs
# 4. Fix broken cross-references

# Compliance checks after updates
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
done

if [ $COMPLIANCE_ERRORS -eq 0 ]; then
  echo "✓ All compliance checks passed"
else
  echo "⚠️  Compliance errors found: $COMPLIANCE_ERRORS"
fi
```

## Phase 4: Verify Cross-References

```bash
# Verify all markdown links in updated files
BROKEN_LINKS=0

for doc_file in $UPDATED_FILES; do
  LINKS=$(grep -oP '\[.*?\]\(\K[^)]+' "$doc_file" 2>/dev/null || echo "")

  while IFS= read -r link; do
    [ -z "$link" ] && continue
    [[ "$link" =~ ^https?:// ]] && continue

    DOC_DIR=$(dirname "$doc_file")
    RESOLVED_PATH=$(cd "$DOC_DIR" && realpath -m "$link" 2>/dev/null)

    if [ ! -f "$RESOLVED_PATH" ] && [ ! -d "$RESOLVED_PATH" ]; then
      echo "❌ BROKEN LINK in $doc_file: $link"
      ((BROKEN_LINKS++))
    fi
  done <<< "$LINKS"
done

if [ $BROKEN_LINKS -eq 0 ]; then
  echo "✓ All cross-references valid"
else
  echo "⚠️  Broken links found: $BROKEN_LINKS (manual review needed)"
fi
```

## Phase 5: Report Completion

```bash
echo ""
echo "========================================"
echo "CHECKPOINT: Documentation Updates Complete"
echo "========================================"
echo "Scope: ${CHANGE_DESCRIPTION:-$SCOPE}"
echo "Files Updated: ${UPDATED_FILE_COUNT:-0}"
echo "Compliance: ${COMPLIANCE_ERRORS} errors"
echo "Broken Links: ${BROKEN_LINKS} found"
echo "Standards: ✓ CLAUDE.md COMPLIANT"
echo "Status: DOCUMENTATION CURRENT"
echo "========================================"
```

---

**Troubleshooting**: See guide for detailed documentation standards, agent usage, and common issues.
