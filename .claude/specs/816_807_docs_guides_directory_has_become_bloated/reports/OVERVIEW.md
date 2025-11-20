# Broken References Research - Executive Overview

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Cross-reference audit for guides directory refactor
- **Report Type**: executive summary

## Executive Summary

The guides directory refactor (spec 807) successfully reorganized `.claude/docs/guides/` from 77 files at root level to a hierarchical structure with 5 subdirectories. However, this created **~150 broken cross-references** across ~50 files in the codebase. The highest-impact file is `docs/README.md` with 45+ broken references. This research provides a complete inventory and actionable fix plan.

## Key Findings

### Total Impact
- **150+ broken references** identified across the codebase
- **~50 files** require updates
- **~20 high-priority files** need immediate attention
- **44 files moved** to new subdirectory locations
- **8 files archived** (with suggested replacements)

### Most Affected Files

| File | Broken References | Priority |
|------|-------------------|----------|
| `/home/benjamin/.config/.claude/docs/README.md` | 45+ | CRITICAL |
| `/home/benjamin/.config/.claude/docs/reference/code-standards.md` | 7 | HIGH |
| `/home/benjamin/.config/.claude/docs/reference/command-reference.md` | 6 | HIGH |
| `/home/benjamin/.config/.claude/docs/reference/README.md` | 12 | HIGH |
| `/home/benjamin/.config/.claude/docs/reference/library-api.md` | 5 | HIGH |
| `/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md` | 3 | MEDIUM |
| `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` | 3 | MEDIUM |

### Most Frequently Broken Paths

| Old Path | New Path | Reference Count |
|----------|----------|-----------------|
| `guides/agent-development-guide.md` | `guides/development/agent-development/agent-development-fundamentals.md` | 30+ |
| `guides/command-development-guide.md` | `guides/development/command-development/command-development-fundamentals.md` | 25+ |
| `guides/command-patterns.md` | `guides/patterns/command-patterns/command-patterns-overview.md` | 9 |
| `guides/standards-integration.md` | `guides/patterns/standards-integration.md` | 9 |
| `guides/performance-optimization.md` | `guides/patterns/performance-optimization.md` | 6 |

### Categories of Broken References

1. **External references** (from docs/reference/, docs/workflows/, etc.) - 100+ references
2. **Internal guide cross-references** (within guides/) - 30+ references
3. **Agent/command file references** - 5 references
4. **Architecture file references** - 3 references
5. **Historical/archived references** (specs, backups) - Lower priority

## Recommendations

### Immediate Actions (Phase 1)
1. Fix `docs/README.md` first - highest impact, most visibility
2. Fix all `docs/reference/*.md` files - critical developer documentation
3. Fix internal guide cross-references - ensures guide navigation works

### Secondary Actions (Phase 2)
4. Fix `docs/workflows/*.md` and `docs/concepts/*.md`
5. Fix agent and command template README files
6. Update CHANGELOG historical references

### Deferred Actions (Phase 3)
7. Archive and spec file references are historical - fix only if needed
8. Backup files should never be modified

### Implementation Strategy

**Recommended Approach**: Use the sed replacement commands provided in `002_reference_fix_mapping.md`. Execute in 6 phases:
1. Development guides (agent/command-development-guide)
2. Pattern guides (error, performance, logging, etc.)
3. Orchestration guides
4. Command guides (build, test, document)
5. Template files
6. Archived file replacements

**Estimated Effort**: 30-60 minutes for automated replacement + 30 minutes for manual verification

## Detailed Reports

- **[001_broken_references_inventory.md](001_broken_references_inventory.md)** - Complete list of all broken references organized by source file, with line numbers and specific broken patterns

- **[002_reference_fix_mapping.md](002_reference_fix_mapping.md)** - Mapping of old paths to new paths, grouped by destination subdirectory, with files referencing each path and ready-to-use sed replacement commands

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missed references | Low | Medium | Run markdown link checker after fixes |
| Incorrect path in sed | Low | High | Test on single file first |
| Breaking spec historical records | Low | Low | Skip specs directory in replacements |
| Partial replacement | Medium | Medium | Execute phases separately, commit after each |

## Success Criteria

- [ ] All links in docs/README.md resolve correctly
- [ ] All links in docs/reference/*.md resolve correctly
- [ ] All internal guide cross-references work
- [ ] Markdown link checker reports zero broken links in active documentation
- [ ] Build/test documentation remains accessible

## References

Files analyzed:
- `/home/benjamin/.config/.claude/docs/README.md` - Main documentation index
- `/home/benjamin/.config/.claude/docs/reference/*.md` - 16 reference documents
- `/home/benjamin/.config/.claude/docs/workflows/*.md` - 7 workflow guides
- `/home/benjamin/.config/.claude/docs/concepts/*.md` - 3 concept documents
- `/home/benjamin/.config/.claude/docs/guides/**/*.md` - 67 guide files
- `/home/benjamin/.config/.claude/agents/*.md` - Agent definitions
- `/home/benjamin/.config/.claude/commands/templates/*.md` - Command templates
- `/home/benjamin/.config/.claude/CHANGELOG.md` - Project changelog
- `/home/benjamin/.config/.claude/specs/807_*/summaries/001_guides_refactor_summary.md` - Original refactor summary
