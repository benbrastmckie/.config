# Documentation Historical Commentary Cleanup

## Metadata
- **Date**: 2025-10-16
- **Feature**: Audit and clean all project documentation to remove historical commentary
- **Scope**: `.claude/docs/`, `.claude/templates/`, `.claude/commands/`, and related documentation
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (Policy already exists in CLAUDE.md lines 276-283)

## Overview

The project already has a comprehensive policy against historical commentary in documentation (CLAUDE.md "Development Philosophy → Documentation Standards"). This plan focuses on:

1. Auditing all project documentation for policy violations
2. Removing any temporal markers, deprecation notes, and migration commentary
3. Rewriting violated sections to be present-focused and timeless
4. Establishing enforcement mechanisms for future documentation work

**Key Policy Requirements** (CLAUDE.md lines 276-283):
- No historical reporting of changes, updates, or migration paths
- Ban labels: "(New)", "(Old)", "(Original)", "(Current)", "(Updated)", version indicators
- Ban phrases: "previously", "now supports", "recently added", "in the latest version", "used to", "no longer"
- No migration guides or compatibility documentation for refactors
- Documentation should read as if current implementation always existed

## Success Criteria
- [ ] All documentation in `.claude/docs/` follows timeless writing policy
- [ ] All documentation in `.claude/templates/` follows timeless writing policy
- [ ] All documentation in `.claude/commands/` follows timeless writing policy
- [ ] No temporal markers or historical references in project docs
- [ ] Enforcement checklist created for `/document` command integration
- [ ] Technical accuracy preserved while removing historical commentary

## Technical Design

### Audit Strategy

**Pattern Detection**:
1. **Explicit Temporal Markers**: "(New)", "(Old)", "(Updated)", "(Current)", "(Deprecated)", "(Original)", "(Legacy)", "(Previous)"
2. **Temporal Phrases**: "previously", "now supports", "recently", "used to", "no longer", "in the latest", "updated to", "changed from"
3. **Migration Language**: "migration from", "migrated to", "backward compatibility", "breaking change", "deprecated in favor of"
4. **Version References**: "v1.0", "version 2", "as of", "since version"

**Scanning Approach**:
- Use `Grep` tool with regex patterns for each category
- Focus on `.claude/docs/`, `.claude/templates/`, `.claude/commands/`
- Generate violation report with file paths and line numbers
- Prioritize high-impact documentation files (README.md, guide files)

### Cleanup Strategy

**Rewriting Principles**:
1. **Remove temporal context**: Delete phrases that reference time or change
2. **Focus on current state**: Describe what exists now, not what changed
3. **Preserve technical accuracy**: Maintain all technical details and examples
4. **Natural flow**: Ensure documentation reads smoothly after edits
5. **No replacement markers**: Don't replace "(New)" with "(Current)" - remove entirely

**Example Transformations**:
- Before: "Feature X was recently added to support Y"
- After: "Feature X supports Y"

- Before: "This replaces the old method (deprecated)"
- After: "This method handles Z operations"

- Before: "Updated in v2.0 to use async"
- After: "Uses async operations"

## Implementation Phases

### Phase 1: Documentation Audit [COMPLETED]
**Objective**: Scan all documentation directories for historical commentary violations
**Dependencies**: []
**Risk**: Low
**Estimated Time**: 1-2 hours

Tasks:
- [x] Scan `.claude/docs/` for explicit temporal markers (New, Old, Updated, etc.)
- [x] Scan `.claude/docs/` for temporal phrases (previously, recently, now supports, etc.)
- [x] Scan `.claude/docs/` for migration language (deprecated, backward compatibility, etc.)
- [x] Scan `.claude/templates/` for all violation patterns
- [x] Scan `.claude/commands/` for all violation patterns (excluding legitimate technical terms)
- [x] Generate comprehensive violation report with file paths and line numbers
- [x] Categorize violations by severity (high-impact guides vs low-impact internal docs)

Testing:
```bash
# Verify audit completeness
grep -r "Audit Report" .claude/specs/plans/059_*/
```

Expected Outcomes:
- Complete list of files with violations
- Line numbers for each violation
- Categorization by violation type
- Priority order for cleanup

---

### Phase 2: High-Priority Cleanup [COMPLETED]
**Objective**: Remove violations from user-facing documentation and guides
**Dependencies**: [1]
**Risk**: Medium (must preserve technical accuracy)
**Estimated Time**: 2-3 hours

Tasks:
- [x] Clean `.claude/docs/README.md` (main entry point) - No violations found
- [x] Clean `.claude/templates/README.md` - No violations found
- [x] Clean `.claude/docs/orchestration-guide.md` (high-traffic guide) - 2 violations removed
- [x] Clean `.claude/docs/adaptive-planning-guide.md` (high-traffic guide) - No violations found
- [x] Clean `.claude/docs/command-reference.md` (user-facing reference) - No violations found
- [x] Clean `.claude/docs/agent-reference.md` (user-facing reference) - No violations found
- [x] Verify technical accuracy of rewritten sections
- [x] Ensure natural flow after edits

Testing:
```bash
# Verify no violations remain in cleaned files
grep -E "(recently|previously|now supports|deprecated|New\)|Old\)|Updated\))" \
  .claude/docs/README.md \
  .claude/docs/orchestration-guide.md \
  .claude/docs/adaptive-planning-guide.md \
  .claude/docs/command-reference.md \
  .claude/docs/agent-reference.md \
  .claude/templates/README.md
```

Expected Outcomes:
- All high-priority files follow timeless writing policy
- Technical accuracy preserved
- Documentation reads naturally without temporal references

---

### Phase 3: Comprehensive Cleanup
**Objective**: Remove violations from all remaining documentation
**Dependencies**: [2]
**Risk**: Low
**Estimated Time**: 2-3 hours

Tasks:
- [ ] Clean remaining `.claude/docs/*.md` files
- [ ] Clean `.claude/templates/*.md` files (excluding orchestration-patterns.md agent prompts)
- [ ] Clean `.claude/commands/*.md` files (carefully preserve command instructions)
- [ ] Verify no regressions in high-priority files
- [ ] Run final audit scan to confirm zero violations
- [ ] Document any edge cases where temporal language is technically necessary

Testing:
```bash
# Run comprehensive audit again
cd /home/benjamin/.config
grep -r -E "(recently|previously|now supports|used to|no longer|New\)|Old\)|Updated\)|Current\)|Deprecated\))" \
  .claude/docs/ \
  .claude/templates/ \
  .claude/commands/ \
  --exclude-dir=.git | grep -v "^Binary"

# Should return zero results or only legitimate technical usage
```

Expected Outcomes:
- Zero policy violations across all documentation
- All files follow present-focused writing principles
- Command instructions remain functional and clear

---

### Phase 4: Enforcement Integration
**Objective**: Establish enforcement mechanisms for future documentation work
**Dependencies**: [3]
**Risk**: Low
**Estimated Time**: 1-2 hours

Tasks:
- [ ] Create documentation review checklist for `/document` command
- [ ] Add policy reference to `/document` command prompt
- [ ] Create grep-based validation script for pre-commit checks (optional)
- [ ] Document cleanup patterns and examples for future reference
- [ ] Update CLAUDE.md documentation policy section if needed (likely not needed)
- [ ] Generate implementation summary linking to cleaned files

Testing:
```bash
# Verify checklist is integrated
grep -A 5 "Documentation Standards" .claude/commands/document.md

# Run validation script
.claude/scripts/validate_docs_timeless.sh  # If created
```

Expected Outcomes:
- `/document` command references policy
- Review checklist available for manual checks
- Optional automation for validation
- Clear examples for future documentation work

---

## Testing Strategy

### Phase-Specific Testing
Each phase includes specific grep commands to verify violations are removed.

### Comprehensive Validation
After Phase 3, run comprehensive audit:
```bash
# Pattern 1: Explicit temporal markers
grep -r -E "\(New\)|\(Old\)|\(Updated\)|\(Current\)|\(Deprecated\)|\(Original\)|\(Legacy\)|\(Previous\)" \
  .claude/docs/ .claude/templates/ .claude/commands/

# Pattern 2: Temporal phrases
grep -r -E "\b(previously|recently|now supports|used to|no longer|in the latest|updated to|changed from)\b" \
  .claude/docs/ .claude/templates/ .claude/commands/

# Pattern 3: Migration language
grep -r -E "\b(migration from|migrated to|backward compatibility|breaking change|deprecated in favor)\b" \
  .claude/docs/ .claude/templates/ .claude/commands/

# Pattern 4: Version references
grep -r -E "\bv[0-9]+\.[0-9]+|version [0-9]+|as of version|since version\b" \
  .claude/docs/ .claude/templates/ .claude/commands/
```

### False Positive Handling
Some technical terms may match patterns but are legitimate:
- "deprecated" in code examples or API references (keep)
- "version" in tool version requirements (keep)
- "migration" in data migration context (case-by-case)

Flag these during audit and preserve if technically necessary.

## Documentation Requirements

### Files to Update
- All `.claude/docs/*.md` files (20 files identified)
- All `.claude/templates/*.md` files (3 files identified)
- Relevant `.claude/commands/*.md` files (as violations are found)

### Update Approach
- Read → Edit → Test pattern for each file
- Preserve all technical content and examples
- Maintain markdown formatting and structure
- Update cross-references if sections are rewritten

## Dependencies

### External Dependencies
None - all work is internal documentation cleanup.

### Tool Dependencies
- `Grep` tool for pattern matching
- `Read` tool for file analysis
- `Edit` tool for precise edits
- `Bash` tool for validation scripts

## Risk Assessment

### Medium Risks
- **Technical Accuracy Loss**: Removing context might obscure important technical details
  - Mitigation: Careful review of each edit, preserve all technical facts

- **Command Instruction Breakage**: Over-aggressive cleanup might alter command behavior
  - Mitigation: Test commands after cleanup, preserve instructional clarity

### Low Risks
- **False Positives**: Grep patterns might flag legitimate technical usage
  - Mitigation: Manual review of audit results, preserve technical terms

## Notes

### Policy Already Exists
CLAUDE.md already contains comprehensive policy (lines 276-283). No policy update needed.

### Scope Boundaries
This plan focuses on `.claude/` directory documentation. Neovim-specific documentation (`nvim/`) is out of scope unless violations are discovered.

### Preservation Priorities
1. Technical accuracy (highest priority)
2. Command functionality
3. Instructional clarity
4. Natural documentation flow

### Spec Updater Checklist
- [x] Plan created in topic-based structure: `.claude/specs/plans/059_documentation_historical_commentary_cleanup.md`
- [ ] Standard subdirectories will be created if audit artifacts are generated
- [ ] Cross-references will be updated if cleanup spans multiple artifacts
- [ ] Implementation summary will be created after Phase 4 completion
- [ ] Gitignore compliance: This plan is gitignored, any debug artifacts will be committed

## Estimated Complexity

**Overall Complexity**: Medium
- **Audit Phase**: Low complexity (pattern matching)
- **Cleanup Phases**: Medium complexity (requires careful rewriting)
- **Enforcement Phase**: Low complexity (checklist creation)

**Time Estimate**: 6-10 hours total across 4 phases
