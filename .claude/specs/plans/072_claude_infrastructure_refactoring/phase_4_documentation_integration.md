# Phase 4: Documentation Integration and Navigation Updates

## Metadata
- **Phase Number**: 4
- **Parent Plan**: 072_claude_infrastructure_refactoring.md
- **Objective**: Integrate hierarchical-agent-workflow.md and clean up archive references
- **Complexity**: Low
- **Status**: PENDING
- **Dependencies**: None
- **Estimated Tasks**: 6 detailed tasks

## Overview

This phase integrates recent documentation additions (hierarchical-agent-workflow.md) into the main navigation and cleans up lingering archive references. The documentation structure (Diataxis framework) is working well and should be preserved, requiring only targeted integration updates.

### Current State

**Documentation Structure** (41 markdown files):
- Well-organized Diataxis framework
- Reference (5), Guides (11), Concepts (4), Workflows (6), Archive (8)
- Main README comprehensive (619 lines)
- Recent consolidation completed (2025-10-17)

**Issues**:
- hierarchical-agent-workflow.md exists but not in main README navigation
- Archive has 8 files with some lingering references in active docs
- No archive/README.md explaining historical context

### Target State

- hierarchical-agent-workflow.md integrated into Workflows section
- Zero archive references in active documentation
- archive/README.md created with historical context
- All internal links validated and working
- Documentation structure maintains Diataxis integrity

## Stage 1: Navigation Update

### Objective
Add hierarchical-agent-workflow.md to main README workflows section.

### Tasks

#### Task 1.1: Update Main README Navigation
**File**: `.claude/docs/README.md`

Locate the Workflows section and add hierarchical-agent-workflow.md:

```markdown
## Workflows

Step-by-step guides for common development workflows in the .claude/ system.

### Core Workflows
- [Hierarchical Agent Workflow](workflows/hierarchical-agent-workflow.md) - Multi-level agent coordination for complex tasks with metadata-based context passing
- [Orchestration Guide](workflows/orchestration-guide.md) - Multi-agent workflow coordination from research to documentation
- [Adaptive Planning Guide](workflows/adaptive-planning-guide.md) - Intelligent plan revision during execution
- [Spec Updater Guide](workflows/spec_updater_guide.md) - Automated artifact management and lifecycle tracking
- [Checkpoint Template Guide](workflows/checkpoint_template_guide.md) - State management and recovery patterns
- [Development Workflow](workflows/development-workflow.md) - Standard research → plan → implement → test cycle

### See Also
- [Using Agents Guide](guides/using-agents.md) - Agent invocation and behavioral injection patterns
- [Hierarchical Agents Concept](concepts/hierarchical_agents.md) - Architecture and design patterns
```

**Testing**: Verify link resolves correctly

#### Task 1.2: Add Cross-References in Related Docs

**Update**: `.claude/docs/guides/using-agents.md`

Add reference to workflow:

```markdown
## Hierarchical Agent Workflows

For complete multi-level coordination workflows, see [Hierarchical Agent Workflow](../workflows/hierarchical-agent-workflow.md).

[Existing using-agents content...]
```

**Update**: `.claude/docs/concepts/hierarchical_agents.md`

Add reference to workflow:

```markdown
## Practical Application

For step-by-step workflow guidance on using hierarchical agents, see [Hierarchical Agent Workflow](../workflows/hierarchical-agent-workflow.md).

[Existing concepts content...]
```

**Testing**: Verify all cross-references resolve

---

## Stage 2: Archive Cleanup

### Objective
Remove archive references from active documentation and create archive/README.md.

### Tasks

#### Task 2.1: Audit Archive References
**Script**: Find all references to archive/ in active docs

```bash
#!/usr/bin/env bash
# Find archive references in active documentation

echo "Scanning for archive references in active documentation..."

# Search all markdown files except those in archive/
find .claude/docs -name "*.md" ! -path "*.claude/docs/archive/*" -type f | \
while IFS= read -r doc_file; do
  if grep -q "archive/" "$doc_file" 2>/dev/null; then
    echo ""
    echo "File: $doc_file"
    grep -n "archive/" "$doc_file"
  fi
done
```

**Expected findings**:
- Navigation links in subdirectory READMEs
- Cross-references in recently updated docs
- Historical notes mentioning archived content

#### Task 2.2: Remove Archive References
**Action**: Update each file with archive references

**Pattern to replace**:
```markdown
# Old (with archive reference)
- [Old Guide](../archive/old-guide.md) - Deprecated, see [New Guide](new-guide.md)

# New (archive reference removed)
- [New Guide](new-guide.md) - Current approach for [topic]
```

**Files likely needing updates**:
- `.claude/docs/guides/README.md`
- `.claude/docs/reference/README.md`
- `.claude/docs/concepts/README.md`
- `.claude/docs/workflows/README.md`

**Testing**: Re-run audit script and verify zero archive references found

#### Task 2.3: Create Archive README
**File**: `.claude/docs/archive/README.md`

```markdown
# Documentation Archive

This directory contains historical documentation that has been consolidated, superseded, or deprecated. Files are preserved for historical reference but are no longer actively maintained.

## Purpose

The archive serves to:
- **Preserve history**: Track evolution of .claude/ system design
- **Reference consolidations**: Show which docs were merged and why
- **Document deprecations**: Explain why approaches were superseded
- **Support archaeology**: Enable understanding of past decisions

## Archived Documentation

### Consolidation (2025-10-17)

The following files were consolidated into focused, comprehensive documents:

#### Agent Documentation Consolidation
- `old-agent-guide.md` → Merged into `../guides/using-agents.md`
- `agent-patterns.md` → Merged into `../concepts/hierarchical_agents.md`
- `agent-workflow-old.md` → Superseded by `../workflows/hierarchical-agent-workflow.md`

Rationale: Scattered agent documentation created duplication and inconsistency. Consolidation into three focused documents (guide, concept, workflow) follows Diataxis framework and eliminates redundancy.

#### Command Documentation Consolidation
- `command-tips.md` → Merged into `../guides/creating-commands.md`
- `command-examples.md` → Examples integrated into command guides
- `slash-command-overview.md` → Merged into `../reference/command-reference.md`

Rationale: Command documentation was fragmented across multiple files. Consolidation into reference (API) and guides (tutorials) improves discoverability.

#### Workflow Documentation Consolidation
- `workflow-patterns-old.md` → Merged into `../workflows/development-workflow.md`
- `checkpoint-guide-old.md` → Merged into `../workflows/checkpoint_template_guide.md`

Rationale: Workflow docs updated to reflect current best practices and adaptive planning capabilities.

### Deprecated Approaches (Historical Interest)

#### Early Agent Coordination (Pre-Hierarchical)
- `flat-agent-coordination.md` - Early single-level agent approach
- Superseded by: Hierarchical agent architecture with metadata-based context passing
- Deprecated: 2025-10
- Reason: Flat coordination led to context overflow (>80% usage). Hierarchical approach achieves <30% usage via metadata-only passing.

#### Manual Registry Management (Pre-Discovery)
- `manual-agent-registration.md` - Early agent registry without auto-discovery
- Superseded by: `../lib/agent-discovery.sh` automated discovery
- Deprecated: 2025-10
- Reason: Manual registration led to drift (2/19 agents registered). Auto-discovery ensures 100% coverage.

## Accessing Archived Docs

### Navigation

Archived documentation is **not linked** from active docs to avoid confusion. Access via:

```bash
# Direct file path
cat .claude/docs/archive/old-guide.md

# Search archive
grep -r "search term" .claude/docs/archive/
```

### Usage Guidelines

**Do NOT**:
- Reference archived docs in active documentation
- Use archived approaches in new code
- Recommend archived patterns to users

**Do**:
- Reference archive for historical context (e.g., "this supersedes X approach from archive")
- Consult archive to understand rationale for current design
- Preserve archive when cleaning up documentation

## Maintenance

### Adding to Archive

When deprecating documentation:

1. **Document rationale**: Why is this being archived?
2. **Link to replacement**: What supersedes this doc?
3. **Update this README**: Add entry explaining consolidation/deprecation
4. **Remove active references**: Ensure no active docs link to archived content
5. **Preserve file**: Move to archive/ (don't delete)

### Archive Retention

- **Permanent retention**: All archived docs preserved indefinitely
- **No expiration**: Historical value never diminishes
- **Read-only**: Archived docs not updated (preserve historical accuracy)

## See Also

- [Documentation Standards](../reference/documentation-standards.md)
- [Writing Standards](../concepts/writing-standards.md)
- [Main Documentation Index](../README.md)

---

*This archive was created during the 2025-10-17 documentation consolidation. For current documentation, see [Main Index](../README.md).*
```

**Testing**: Verify archive/README.md provides clear historical context

---

## Stage 3: Cross-Reference Validation

### Objective
Validate all internal links resolve correctly across documentation.

### Tasks

#### Task 3.1: Create Link Validation Script
**File**: `.claude/lib/validate-doc-links.sh`

```bash
#!/usr/bin/env bash
# Validate all internal documentation links

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"

validate_markdown_links() {
  local docs_dir=".claude/docs"
  local errors=0

  echo "Validating markdown links in $docs_dir..."

  # Find all markdown files
  while IFS= read -r md_file; do
    local file_dir
    file_dir=$(dirname "$md_file")

    # Extract markdown links [text](path)
    while IFS= read -r link; do
      # Skip external links (http://, https://)
      if [[ "$link" =~ ^https?:// ]]; then
        continue
      fi

      # Skip anchor links (#section)
      if [[ "$link" =~ ^\# ]]; then
        continue
      fi

      # Resolve relative path
      local resolved_path
      if [[ "$link" =~ ^/ ]]; then
        # Absolute path from repo root
        resolved_path=".${link}"
      else
        # Relative path from current file
        resolved_path="$file_dir/$link"
      fi

      # Normalize path (resolve ..)
      resolved_path=$(realpath -m "$resolved_path" 2>/dev/null || echo "$resolved_path")

      # Check if file exists
      if [[ ! -f "$resolved_path" ]] && [[ ! -d "$resolved_path" ]]; then
        error "Broken link in $(basename "$md_file"): $link"
        echo "  Resolved to: $resolved_path (not found)"
        ((errors++))
      fi
    done < <(grep -oP '\[([^\]]+)\]\(\K[^)]+' "$md_file" 2>/dev/null || true)
  done < <(find "$docs_dir" -name "*.md" -type f)

  if [[ $errors -eq 0 ]]; then
    echo "✓ All documentation links valid"
    return 0
  else
    error "Found $errors broken links"
    return 1
  fi
}

# Validate anchor links (section references)
validate_anchor_links() {
  echo "Validating anchor links..."

  local docs_dir=".claude/docs"
  local errors=0

  while IFS= read -r md_file; do
    # Extract anchor links (#section)
    while IFS= read -r anchor; do
      # Remove leading #
      anchor="${anchor#\#}"

      # Convert to heading format (lowercase, hyphens for spaces)
      local heading_pattern
      heading_pattern=$(echo "$anchor" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

      # Check if heading exists in file
      if ! grep -qi "^## .*${heading_pattern}" "$md_file" && \
         ! grep -qi "^### .*${heading_pattern}" "$md_file"; then
        error "Broken anchor in $(basename "$md_file"): #$anchor"
        ((errors++))
      fi
    done < <(grep -oP '\[([^\]]+)\]\((\K#[^)]+)' "$md_file" 2>/dev/null || true)
  done < <(find "$docs_dir" -name "*.md" -type f)

  if [[ $errors -eq 0 ]]; then
    echo "✓ All anchor links valid"
    return 0
  else
    error "Found $errors broken anchor links"
    return 1
  fi
}

# Run all validations
main() {
  local failed=0

  validate_markdown_links || ((failed++))
  validate_anchor_links || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo ""
    echo "All link validations passed ✓"
    return 0
  else
    echo ""
    error "$failed validation(s) failed"
    return 1
  fi
}

main "$@"
```

**Testing**: Run validator on entire docs/ directory

#### Task 3.2: Fix Broken Links
**Action**: Address all broken links found by validator

Common issues:
- Relative paths incorrect after file moves
- Missing .md extensions
- Anchor links to renamed sections

**Fix pattern**:
```bash
# Run validator
.claude/lib/validate-doc-links.sh

# For each broken link:
# 1. Verify target file location
# 2. Update link with correct relative path
# 3. Re-run validator to confirm fix
```

---

## Stage 4: Optional Optimization

### Objective
Review main README for potential section extractions (if needed).

### Tasks

#### Task 4.1: Analyze Main README Size
**File**: `.claude/docs/README.md`

```bash
# Check README size
wc -l .claude/docs/README.md
# Current: 619 lines

# Identify large sections
grep "^## " .claude/docs/README.md | nl
```

**Evaluation criteria**:
- Sections >100 lines: Consider extraction
- Self-contained topics: Good extraction candidates
- Frequently referenced: Keep in main README

**Decision**: Main README at 619 lines is manageable. Extraction only if specific sections become significantly larger (>150 lines).

#### Task 4.2: Extract if Needed (Conditional)

**If extraction needed**:

1. Identify section to extract (e.g., "Hierarchical Agent Architecture Overview")
2. Create new file in appropriate Diataxis category
3. Replace section with summary + link
4. Update cross-references
5. Validate all links

**Example**:
```markdown
# Before (in main README)
## Hierarchical Agent Architecture Overview
[150+ lines of detailed content]

# After (in main README)
## Hierarchical Agent Architecture

The .claude/ system uses hierarchical agent coordination to minimize context usage (<30%) through metadata-based passing and recursive supervision.

For complete architecture details, see:
- [Hierarchical Agents Concept](concepts/hierarchical_agents.md)
- [Hierarchical Agent Workflow](workflows/hierarchical-agent-workflow.md)
- [Using Agents Guide](guides/using-agents.md)
```

**Testing**: Verify extracted content maintains context and all links work

---

## Success Criteria Validation

- [ ] hierarchical-agent-workflow.md integrated into main README
- [ ] Cross-references added in using-agents.md and hierarchical_agents.md
- [ ] Zero archive references in active documentation
- [ ] archive/README.md created with comprehensive historical context
- [ ] All internal links validated (validate-doc-links.sh passes)
- [ ] Broken links fixed
- [ ] Main README size assessed (extraction if needed)
- [ ] Documentation structure maintains Diataxis integrity

## Testing Strategy

### Link Validation
```bash
# Validate all links
.claude/lib/validate-doc-links.sh

# Test hierarchical-agent-workflow.md navigation
# 1. Open .claude/docs/README.md
# 2. Click link to hierarchical-agent-workflow.md
# 3. Verify file opens correctly

# Test cross-references
# 1. Open using-agents.md
# 2. Click link to hierarchical-agent-workflow.md
# 3. Verify navigation works
```

### Archive Reference Check
```bash
# Verify no archive references in active docs
find .claude/docs -name "*.md" ! -path "*.claude/docs/archive/*" -type f | \
  xargs grep -l "archive/" || echo "No archive references found ✓"
```

### Navigation Integrity
```bash
# Test documentation structure
.claude/lib/structure-validator.sh

# Verify Diataxis categories
ls .claude/docs/
# Should show: reference/, guides/, concepts/, workflows/, archive/
```

## Performance Metrics

**Before**:
- hierarchical-agent-workflow.md: Not in navigation
- Archive references: 3-5 in active docs
- archive/README.md: Does not exist
- Broken links: Unknown

**After**:
- hierarchical-agent-workflow.md: Integrated with cross-references
- Archive references: 0 in active docs
- archive/README.md: Comprehensive historical context
- Broken links: 0 (validated)

## Documentation Updates

### Files Updated

- [ ] `.claude/docs/README.md` - Add hierarchical-agent-workflow.md to Workflows
- [ ] `.claude/docs/guides/using-agents.md` - Add cross-reference to workflow
- [ ] `.claude/docs/concepts/hierarchical_agents.md` - Add cross-reference to workflow
- [ ] `.claude/docs/archive/README.md` - Create historical context documentation
- [ ] `.claude/lib/README.md` - Add validate-doc-links.sh
- [ ] `CLAUDE.md` - Update documentation section if needed

### Files With Archive References Removed

- [ ] `.claude/docs/guides/README.md`
- [ ] `.claude/docs/reference/README.md`
- [ ] `.claude/docs/concepts/README.md`
- [ ] `.claude/docs/workflows/README.md`
- [ ] [Additional files found during audit]

## Next Phase

Phase 5: Discovery and Validation Infrastructure
