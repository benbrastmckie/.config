# Archive Documentation-Only Agents Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Archive Unused Agents
- **Scope**: Archive 8 documentation-only agents and clean up all references across the codebase
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Unused Agent Analysis Report](/home/benjamin/.config/.claude/specs/800_claude_agents_readmemd_to_help_identify_these/reports/001_unused_agent_analysis.md)
- **Structure Level**: 0
- **Complexity Score**: 62.5

## Overview

This plan implements the archival of 8 agents that exist only in documentation but are never actually invoked by any command. The research identified these agents through comprehensive codebase analysis:

1. github-specialist
2. metrics-specialist
3. implementation-researcher
4. research-synthesizer
5. implementation-sub-supervisor
6. testing-sub-supervisor
7. plan-structure-manager
8. revision-specialist

The goal is to reduce maintenance burden by moving unused agent definitions to an archive directory and cleaning up all 94 documentation references to maintain quality documentation.

## Research Summary

Key findings from the unused agent analysis report:

- **Active agents**: 16 agents are actively invoked via Task tool in command files
- **Documentation-only agents**: 8 agents have definition files but are never invoked by any command
- **Documentation impact**: 94 files contain references to unused agents
- **High-priority files**: agents/README.md, agent-reference.md, hierarchical-agents.md, and several guides require updates
- **Test files**: 2 test files may become obsolete and should be archived

Recommended approach: Create archive directory, move agent files, update documentation systematically by priority, and archive related test files.

## Success Criteria
- [ ] All 8 unused agent definition files moved to archive directory
- [ ] agents/README.md updated with correct agent count (17 instead of 25)
- [ ] All documentation files cleaned of archived agent references
- [ ] Test files for archived agents moved to archive
- [ ] agent-registry.json updated (if exists)
- [ ] No broken links or references remain in documentation
- [ ] Documentation maintains coherent structure after cleanup

## Technical Design

### Archive Structure
```
.claude/
├── archive/
│   └── deprecated-agents/
│       ├── github-specialist.md
│       ├── metrics-specialist.md
│       ├── implementation-researcher.md
│       ├── research-synthesizer.md
│       ├── implementation-sub-supervisor.md
│       ├── testing-sub-supervisor.md
│       ├── plan-structure-manager.md
│       ├── revision-specialist.md
│       ├── README.md (archive manifest)
│       └── tests/
│           ├── test_hierarchical_supervisors.sh
│           └── test_revision_specialist.sh
└── agents/
    └── README.md (updated with 17 agents)
```

### Documentation Update Strategy
1. **Priority-based cleanup**: Start with high-impact files (README.md, references)
2. **Section removal**: Remove entire sections for archived agents rather than leaving stubs
3. **Count updates**: Correct agent counts throughout documentation
4. **Link cleanup**: Remove or update navigation links to archived agents

## Implementation Phases

### Phase 1: Create Archive Infrastructure [COMPLETE]
dependencies: []

**Objective**: Set up archive directory structure and move agent definition files
**Complexity**: Low

Tasks:
- [x] Create archive directory structure: `.claude/archive/deprecated-agents/` (file: /home/benjamin/.config/.claude/archive/deprecated-agents/)
- [x] Create tests subdirectory: `.claude/archive/deprecated-agents/tests/` (file: /home/benjamin/.config/.claude/archive/deprecated-agents/tests/)
- [x] Move github-specialist.md to archive (file: /home/benjamin/.config/.claude/agents/github-specialist.md)
- [x] Move metrics-specialist.md to archive (file: /home/benjamin/.config/.claude/agents/metrics-specialist.md)
- [x] Move implementation-researcher.md to archive (file: /home/benjamin/.config/.claude/agents/implementation-researcher.md)
- [x] Move research-synthesizer.md to archive (file: /home/benjamin/.config/.claude/agents/research-synthesizer.md)
- [x] Move implementation-sub-supervisor.md to archive (file: /home/benjamin/.config/.claude/agents/implementation-sub-supervisor.md)
- [x] Move testing-sub-supervisor.md to archive (file: /home/benjamin/.config/.claude/agents/testing-sub-supervisor.md)
- [x] Move plan-structure-manager.md to archive (file: /home/benjamin/.config/.claude/agents/plan-structure-manager.md)
- [x] Move revision-specialist.md to archive (file: /home/benjamin/.config/.claude/agents/revision-specialist.md)
- [x] Create archive README.md documenting why agents were archived and when

Testing:
```bash
# Verify all agent files moved successfully
ls -la /home/benjamin/.config/.claude/archive/deprecated-agents/
test -f /home/benjamin/.config/.claude/archive/deprecated-agents/github-specialist.md && echo "PASS: github-specialist archived"
test ! -f /home/benjamin/.config/.claude/agents/github-specialist.md && echo "PASS: github-specialist removed from agents/"
```

**Expected Duration**: 1 hour

### Phase 2: Update agents/README.md [COMPLETE]
dependencies: [1]

**Objective**: Clean up the primary agents documentation file by removing all references to archived agents
**Complexity**: Medium

Tasks:
- [x] Update agent count from 25 to 17 in header (file: /home/benjamin/.config/.claude/agents/README.md, line 5)
- [x] Remove github-specialist section (lines 197-220)
- [x] Remove metrics-specialist section (lines 222-244)
- [x] Remove research-synthesizer section (lines 592-614)
- [x] Remove revision-specialist section (lines 616-637)
- [x] Remove plan-structure-manager section (lines 663-684)
- [x] Remove implementation-researcher section (lines 686-706)
- [x] Remove implementation-sub-supervisor section (lines 709-730)
- [x] Remove testing-sub-supervisor section (lines 733-751)
- [x] Update Command-to-Agent Mapping section to remove archived agents from /coordinate (lines 74-83)
- [x] Update Model Selection Patterns - remove archived agents from haiku, sonnet, opus lists (lines 102-139)
- [x] Update Navigation section to remove links to archived agents (lines 1059-1098)
- [x] Update Sub-Supervisor Agents section or remove entirely (lines 1090-1093)
- [x] Update Tool Access Patterns examples if they reference archived agents

Testing:
```bash
# Verify agent count is correct
grep -c "^### .*\.md$" /home/benjamin/.config/.claude/agents/README.md
# Should return approximately 17 agent sections

# Verify no references to archived agents remain
grep -c "github-specialist\|metrics-specialist\|implementation-researcher\|research-synthesizer\|implementation-sub-supervisor\|testing-sub-supervisor\|plan-structure-manager\|revision-specialist" /home/benjamin/.config/.claude/agents/README.md
# Should return 0
```

**Expected Duration**: 2 hours

### Phase 3: Update Core Documentation Files [COMPLETE]
dependencies: [2]

**Objective**: Clean up high-priority documentation files that reference archived agents
**Complexity**: Medium

Tasks:
- [x] Update /home/benjamin/.config/.claude/docs/reference/agent-reference.md - remove entries and tool matrix rows
- [x] Update /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md - remove implementation-researcher examples and update diagrams
- [x] Update /home/benjamin/.config/.claude/docs/guides/hierarchical-supervisor-guide.md - archive or simplify sub-supervisor documentation
- [x] Update /home/benjamin/.config/.claude/docs/reference/workflow-phases.md - remove github-specialist sections (lines 1200-1401)
- [x] Update /home/benjamin/.config/.claude/docs/quick-reference/agent-selection-flowchart.md - remove flowchart entries
- [x] Update /home/benjamin/.config/.claude/docs/guides/agent-development-guide.md - update agent catalog
- [x] Update /home/benjamin/.config/.claude/docs/guides/model-selection-guide.md - remove model assignments for archived agents

Testing:
```bash
# Verify no references to archived agents in core docs
for file in \
  /home/benjamin/.config/.claude/docs/reference/agent-reference.md \
  /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md \
  /home/benjamin/.config/.claude/docs/guides/hierarchical-supervisor-guide.md \
  /home/benjamin/.config/.claude/docs/reference/workflow-phases.md; do
  count=$(grep -c "github-specialist\|metrics-specialist\|implementation-researcher\|research-synthesizer\|implementation-sub-supervisor\|testing-sub-supervisor\|plan-structure-manager\|revision-specialist" "$file" 2>/dev/null || echo 0)
  echo "$file: $count references"
done
```

**Expected Duration**: 2.5 hours

### Phase 4: Archive Test Files and Update Registry [COMPLETE]
dependencies: [1]

**Objective**: Move obsolete test files to archive and update agent registry
**Complexity**: Low

Tasks:
- [x] Move test_hierarchical_supervisors.sh to archive/deprecated-agents/tests/ (file: /home/benjamin/.config/.claude/tests/test_hierarchical_supervisors.sh)
- [x] Move test_revision_specialist.sh to archive/deprecated-agents/tests/ (file: /home/benjamin/.config/.claude/tests/test_revision_specialist.sh)
- [x] Check if agent-registry.json exists and update if present (file: /home/benjamin/.config/.claude/agents/agent-registry.json)
- [x] Remove entries for 8 archived agents from registry if it exists

Testing:
```bash
# Verify test files moved
test -f /home/benjamin/.config/.claude/archive/deprecated-agents/tests/test_hierarchical_supervisors.sh && echo "PASS: test file archived"
test ! -f /home/benjamin/.config/.claude/tests/test_hierarchical_supervisors.sh && echo "PASS: test file removed from tests/"

# Verify registry updated (if exists)
if [ -f /home/benjamin/.config/.claude/agents/agent-registry.json ]; then
  grep -c "github-specialist\|metrics-specialist" /home/benjamin/.config/.claude/agents/agent-registry.json
fi
```

**Expected Duration**: 1 hour

### Phase 5: Final Validation and Cleanup [COMPLETE]
dependencies: [2, 3, 4]

**Objective**: Perform comprehensive validation to ensure no broken references remain
**Complexity**: Low

Tasks:
- [x] Run comprehensive grep search for all archived agent names across codebase
- [x] Verify no broken links in documentation (check for dead references)
- [x] Validate agents/README.md navigation section has no broken links
- [x] Ensure archived files in archive/deprecated-agents/ are accessible if needed for reference
- [x] Update any remaining stray references found during validation
- [x] Verify documentation structure remains coherent after cleanup

Testing:
```bash
# Comprehensive validation - search all .md files for archived agent references
find /home/benjamin/.config/.claude -name "*.md" -not -path "*archive*" -exec grep -l "github-specialist\|metrics-specialist\|implementation-researcher\|research-synthesizer\|implementation-sub-supervisor\|testing-sub-supervisor\|plan-structure-manager\|revision-specialist" {} \; 2>/dev/null
# Should return empty (no matches outside archive)

# Verify archive manifest exists
test -f /home/benjamin/.config/.claude/archive/deprecated-agents/README.md && echo "PASS: Archive manifest exists"

# Count total agent files remaining in agents/
ls -1 /home/benjamin/.config/.claude/agents/*.md 2>/dev/null | grep -v README | wc -l
# Should return approximately 17
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Verification Approach
1. **File existence checks**: Verify moved files exist in archive and not in original location
2. **Reference counts**: Use grep to count remaining references to archived agents
3. **Structure validation**: Ensure documentation sections are coherent after removal
4. **Link validation**: Check navigation links point to valid targets

### Quality Gates
- No references to archived agents in active documentation (outside archive/)
- Agent count in README matches actual agent files
- All moved files accessible in archive for historical reference
- No orphaned sections or broken navigation

### Rollback Plan
If issues arise:
1. Agent files can be moved back from archive/deprecated-agents/
2. Git history preserves all original documentation content
3. Research report provides complete list of changes for manual reversal

## Documentation Requirements

### Files to Update
Primary updates covered in implementation phases:
- agents/README.md (Phase 2)
- Core documentation files (Phase 3)
- Agent registry if exists (Phase 4)

### Archive Documentation
Create archive manifest in Phase 1 that includes:
- List of archived agents
- Reason for archival (never invoked by commands)
- Date of archival
- Reference to research report

### No New Documentation Required
This is a cleanup/archival task, not a feature addition. Focus is on removing outdated references rather than creating new documentation.

## Dependencies

### External Dependencies
None - all work is within the .claude/ directory structure.

### Internal Dependencies
- Phase 2 must complete before Phase 5 (README is primary reference)
- Phase 3 must complete before Phase 5 (docs must be clean for validation)
- Phase 4 can run in parallel with Phase 2 and 3 (depends only on Phase 1)

### Prerequisites
- Research report already completed and provides comprehensive analysis
- Git repository available for tracking changes and potential rollback

## Risk Mitigation

### Risk: Breaking references in external projects
**Mitigation**: This appears to be a self-contained project. Search confirms all references are within .claude/ directory.

### Risk: Losing important agent functionality
**Mitigation**: Research confirms these agents are never invoked - they exist only in documentation. Moving to archive preserves them for reference.

### Risk: Incomplete cleanup leaving stale references
**Mitigation**: Phase 5 provides comprehensive validation with find/grep to catch any missed references.

## Notes

- The research report identified plan-complexity-classifier as potentially unused (claimed by /plan but no Task invocation found). This plan does NOT include it in the archival list as it requires further verification.
- Files already in archive directories are excluded from cleanup scope as they don't need updating.
- Total of 94 files with references identified - many are in archive already and don't need changes.
