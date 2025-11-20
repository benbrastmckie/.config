# Broken Links Troubleshooting Guide

Solutions for common broken link issues.

## Quick Diagnostics

### Check Single File
```bash
npx markdown-link-check path/to/file.md \
  --config .claude/scripts/markdown-link-check.json
```

### Check Recent Changes
```bash
./.claude/scripts/validate-links-quick.sh 7  # Last 7 days
```

### Full Repository Scan
```bash
./.claude/scripts/validate-links.sh
```

## Common Issues

### 1. File Not Found

**Symptom**: `✗ path/to/file.md → Status: 404`

**Causes**:
- File was moved or deleted
- Incorrect relative path
- Case sensitivity issue

**Solutions**:
```bash
# Find where file actually is
find . -name "filename.md"

# Check if file was moved (git history)
git log --follow --all -- "**/filename.md"
```

### 2. Absolute Path

**Symptom**: Link contains `/home/user/.config/`

**Solution**: Convert to relative
```bash
# From .claude/docs/file.md linking to CLAUDE.md
# Wrong: /home/benjamin/.config/CLAUDE.md
# Right: ../../CLAUDE.md
```

### 3. Renamed File

**Symptom**: Link points to old filename

**Solution**: Update to new name
```bash
# Find references to old name
grep -r "old-filename.md" --include="*.md" .claude/

# Replace with new name
sed -i 's|old-filename\.md|new-filename.md|g' file.md
```

### 4. Validation Fails on Template

**Symptom**: Error on `[Plan](specs/NNN_topic/plans/001_plan.md)`

**Solution**: This is expected - template placeholders should fail validation

These patterns are ignored in active docs validation:
- `{variable}`
- `NNN_`
- `$VAR`
- `.*` (regex)

## Advanced Diagnostics

### Find All Broken Links
```bash
# Scan and save results
./.claude/scripts/validate-links.sh

# View detailed results
cat .claude/tmp/link-validation/validation_*.log
```

### Extract All Links from File
```bash
# List all markdown links
grep -oE '\[([^\]]+)\]\(([^)]+)\)' file.md

# Extract just paths
grep -oE '\]\([^)]+\)' file.md | sed 's/](\(.*\))/\1/'
```

## Fixing Strategies

### Strategy 1: Search and Replace
```bash
# Find all references to broken link target
grep -r "old-path" --include="*.md" .claude/

# Use sed for bulk replacement
sed -i 's|old-path|new-path|g' file.md
```

### Strategy 2: Manual Fix (Individual Files)
1. Open file in editor
2. Find broken link line number from validation output
3. Verify target file location
4. Update relative path
5. Test: `npx markdown-link-check file.md`

## Prevention

### Pre-Commit Validation
Pre-commit hook validates staged markdown files automatically.

### Regular Validation
```bash
# Add to weekly maintenance
./.claude/scripts/validate-links.sh
```

### Documentation Standards
- Follow link conventions from code-standards.md
- Review relative path calculation before committing
- Test links locally before pushing

## References

- [Code Standards - Link Conventions](../reference/standards/code-standards.md#link-conventions)
- [markdown-link-check](https://github.com/tcort/markdown-link-check)
