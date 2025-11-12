# Internal Link Conventions Guide

Standards for creating and maintaining internal links in markdown documentation.

## Link Format Standards

### Relative Paths (Required)

Always use relative paths from the current file location, not absolute paths.

**Good Examples**:
```markdown
<!-- From .claude/docs/guides/file.md to .claude/docs/concepts/pattern.md -->
[Pattern Name](../concepts/pattern.md)

<!-- From .claude/commands/command.md to .claude/docs/guides/guide.md -->
[Guide](../docs/guides/guide.md)

<!-- From .claude/specs/NNN_topic/plans/plan.md to .claude/docs/guides/guide.md -->
[Guide](../../../docs/guides/guide.md)
```

**Bad Examples**:
```markdown
<!-- Absolute filesystem path -->
[Guide](/home/benjamin/.config/.claude/docs/guides/guide.md)

<!-- Repository-relative without clear base -->
[Guide](.claude/docs/guides/guide.md)
```

### Section Anchors

Link to specific sections using `#anchor` syntax.

**Format**:
```markdown
[Standard 11](../reference/command_architecture_standards.md#standard-11)
[Phase 2](../plans/001_plan.md#phase-2-implementation)
```

**Anchor Generation Rules**:
- Lowercase all text
- Replace spaces with hyphens
- Remove special characters except hyphens
- Example: `## Phase 2: Implementation` → `#phase-2-implementation`

### Cross-Directory Links

Calculate the correct number of `../` to reach the target.

**Example**:
```
Current file:  .claude/specs/042_topic/plans/001_plan.md
Target file:   .claude/docs/guides/guide.md

Path calculation:
- Up 3 levels: ../../../ (gets to .claude/)
- Down to target: docs/guides/guide.md
- Final path: ../../../docs/guides/guide.md
```

## Special Cases

### Template Placeholders

Use placeholder patterns in templates and examples. These are intentionally "broken" and should not be fixed.

**Allowed Patterns**:
```markdown
[Plan](specs/NNN_topic_name/plans/001_plan.md)
[File]({relative_path}/file.md)
[Config]($CONFIG_DIR/config.md)
```

### Historical Documentation

Spec files, reports, and summaries document historical states. Broken links in these files may be intentional (documenting renamed/moved files).

**Policy**: Do not fix broken links in:
- `.claude/specs/**/reports/`
- `.claude/specs/**/summaries/`
- `.claude/specs/**/plans/` (except active plans)

### External Links

External URLs use absolute format:
```markdown
[Claude Code Docs](https://docs.claude.com/claude-code)
[GitHub Repo](https://github.com/user/repo)
```

## Validation

### Manual Validation

Before committing, verify links:
```bash
# Quick check for recently modified files
./.claude/scripts/validate-links-quick.sh 7

# Full validation
./.claude/scripts/validate-links.sh
```

### Automated Validation

- **Pre-commit hook**: Validates staged markdown files
- **CI/CD**: Runs on pull requests modifying markdown files
- **Manual**: Run validation scripts before major releases

## Common Issues and Fixes

### Issue: Link works in editor but not in validation

**Cause**: Case sensitivity (Linux filesystem vs case-insensitive editor)

**Fix**: Ensure exact case match
```markdown
<!-- Wrong (if file is README.md) -->
[Readme](readme.md)

<!-- Correct -->
[README](README.md)
```

### Issue: Link path has too many `../`

**Fix**: Recalculate relative path
```bash
# From: .claude/docs/guides/file.md
# To:   .claude/commands/command.md
# Correct: ../../commands/command.md (up 2 to .claude/, down 1 to commands/)
# Wrong: ../../../commands/command.md (goes outside .claude/)
```

### Issue: Link to moved file

**Fix**: Update link to new location
```markdown
<!-- Old location (archived) -->
[Guide](../docs/archive/guides/guide.md)

<!-- New location -->
[Guide](../docs/guides/guide.md)
```

## Tools

### Link Validation Script

Validate all active documentation:
```bash
./.claude/scripts/validate-links.sh
```

### Quick Validation

Check recently modified files:
```bash
./.claude/scripts/validate-links-quick.sh [days]
```

### Find Links in File

Extract all links from a file:
```bash
grep -oE '\]\([^)]+\)' file.md
```

## References

- [Markdown Specification](https://spec.commonmark.org/)
- [markdown-link-check Documentation](https://github.com/tcort/markdown-link-check)
- [Command Development Guide](command-development-guide.md)
