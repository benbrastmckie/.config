# Agents README.md Update Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Update agents/README.md with comprehensive agent usage documentation
- **Scope**: Add command mappings, dependencies, and usage patterns for all agents
- **Estimated Phases**: 3
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 14.0
- **Research Reports**:
  - [Agents Directory Research](../reports/001_agents_directory_research.md)

## Overview

Update the `.claude/agents/README.md` file to provide comprehensive documentation about which commands use each agent, what dependencies each agent has (library files, external tools, subagent invocations), and which agents are unused or serve as hierarchical subagents. This update will improve discoverability and aid in debugging workflow issues.

## Research Summary

Key findings from the agents directory research:
- **25 agents exist** in the agents directory (excluding README.md)
- **22 agents are actively used** in commands
- **3 agents have no direct command references** but serve as hierarchical subagents (implementation-researcher, implementation-sub-supervisor, testing-sub-supervisor)
- **Library dependencies** are concentrated in unified-location-detection.sh (7 agents) and state-persistence.sh (4 agents)
- **Current README.md has outdated entries** (code-reviewer, code-writer, doc-writer, test-specialist) that don't exist as files
- **Model usage** follows clear patterns: haiku for classification, sonnet for reasoning, opus for architecture

Recommended approach: Complete rewrite of the "Available Agents" section with accurate agent list, command mappings, and dependency information.

## Success Criteria
- [ ] All 25 actual agents documented in README.md
- [ ] Each agent entry includes commands that use it
- [ ] Each agent entry includes library and external dependencies
- [ ] Hierarchical agents clearly identified with parent agents noted
- [ ] Outdated agent entries (code-reviewer, code-writer, doc-writer, test-specialist) removed
- [ ] Model selection rationale section added
- [ ] Navigation links updated to reflect actual agents

## Technical Design

### Architecture Overview
The README.md update involves restructuring the "Available Agents" section to include:
1. Command-to-agent mapping table (quick reference)
2. Individual agent entries with consistent format including:
   - Purpose
   - Commands using the agent
   - Dependencies (libraries, external tools, subagents)
   - Allowed tools
   - Model and justification
3. Model selection rationale summary
4. Updated navigation links

### Data Structure per Agent Entry
```markdown
### agent-name.md
**Purpose**: Brief description
**Model**: model-name (justification)

**Used By Commands**:
- /command1
- /command2

**Dependencies**:
- Libraries: lib/dependency.sh
- External: tool-name
- Subagents: invoked-agent.md

**Allowed Tools**: Tool1, Tool2, Tool3

**Typical Use Cases**:
- Use case 1
- Use case 2
```

## Implementation Phases

### Phase 1: Remove Outdated Entries and Add Command Mapping Table [COMPLETE]
dependencies: []

**Objective**: Clean up outdated agent entries and add a quick reference command-to-agent mapping table

**Complexity**: Low

Tasks:
- [x] Remove code-reviewer.md entry from Available Agents section (file: /home/benjamin/.config/.claude/agents/README.md, lines 130-147)
- [x] Remove code-writer.md entry from Available Agents section (file: /home/benjamin/.config/.claude/agents/README.md, lines 149-166)
- [x] Remove doc-writer.md entry from Available Agents section (file: /home/benjamin/.config/.claude/agents/README.md, lines 212-229)
- [x] Remove test-specialist.md entry from Available Agents section (file: /home/benjamin/.config/.claude/agents/README.md, lines 311-329)
- [x] Add "Command-to-Agent Mapping" table section after "Available Agents" heading with all 10 commands and their agents
- [x] Add "Model Selection Patterns" summary section explaining haiku/sonnet/opus usage patterns

Testing:
```bash
# Verify outdated entries removed
! grep -q "code-reviewer.md" /home/benjamin/.config/.claude/agents/README.md || echo "ERROR: code-reviewer still present"
! grep -q "code-writer.md" /home/benjamin/.config/.claude/agents/README.md || echo "ERROR: code-writer still present"
! grep -q "doc-writer.md" /home/benjamin/.config/.claude/agents/README.md || echo "ERROR: doc-writer still present"
! grep -q "test-specialist.md" /home/benjamin/.config/.claude/agents/README.md || echo "ERROR: test-specialist still present"

# Verify new sections added
grep -q "Command-to-Agent Mapping" /home/benjamin/.config/.claude/agents/README.md && echo "OK: Command mapping table present"
grep -q "Model Selection Patterns" /home/benjamin/.config/.claude/agents/README.md && echo "OK: Model patterns present"
```

**Expected Duration**: 1.5 hours

---

### Phase 2: Update Existing Agent Entries with Full Information [COMPLETE]
dependencies: [1]

**Objective**: Update each existing agent entry with command usage, dependencies, and model information

**Complexity**: Medium

Tasks:
- [x] Update debug-specialist.md entry with: Used by /debug; Model: opus-4.1 (file: /home/benjamin/.config/.claude/agents/README.md, lines 168-188)
- [x] Update doc-converter.md entry with: Used by /convert-docs; Dependencies: markitdown, pandoc, pymupdf4llm; Model: haiku-4.5 (lines 190-210)
- [x] Update github-specialist.md entry with: Dependencies: gh CLI; Model: sonnet-4.5 (lines 231-248)
- [x] Update metrics-specialist.md entry with: Model: haiku-4.5 (lines 251-267)
- [x] Update plan-architect.md entry with: Used by /plan, /revise, /coordinate, /debug; Model: opus-4.1 (lines 270-287)
- [x] Update research-specialist.md entry with: Used by /plan, /research, /revise, /coordinate, /debug; Dependencies: lib/unified-location-detection.sh; Model: sonnet-4.5 (lines 289-310)
- [x] Update complexity-estimator.md entry with: Used by /expand, /collapse; Model: haiku-4.5 (lines 331-348)
- [x] Add missing agents: workflow-classifier, debug-analyst, implementer-coordinator, spec-updater, claude-md-analyzer, docs-structure-analyzer, docs-bloat-analyzer, docs-accuracy-analyzer, cleanup-plan-architect, research-sub-supervisor, research-synthesizer, revision-specialist, plan-complexity-classifier, implementation-executor, plan-structure-manager, implementation-researcher, implementation-sub-supervisor, testing-sub-supervisor

Testing:
```bash
# Count agent entries (should be 25)
AGENT_COUNT=$(grep -c "^### .*\.md$" /home/benjamin/.config/.claude/agents/README.md)
[ "$AGENT_COUNT" -ge 25 ] && echo "OK: $AGENT_COUNT agent entries" || echo "ERROR: Only $AGENT_COUNT agents"

# Verify key agents present
grep -q "workflow-classifier.md" /home/benjamin/.config/.claude/agents/README.md && echo "OK: workflow-classifier present"
grep -q "implementer-coordinator.md" /home/benjamin/.config/.claude/agents/README.md && echo "OK: implementer-coordinator present"
grep -q "spec-updater.md" /home/benjamin/.config/.claude/agents/README.md && echo "OK: spec-updater present"
```

**Expected Duration**: 2 hours

---

### Phase 3: Update Navigation Links and Final Cleanup [COMPLETE]
dependencies: [2]

**Objective**: Update navigation links to reflect actual agents and perform final cleanup

**Complexity**: Low

Tasks:
- [x] Update "Agent Definitions" navigation section with all 25 actual agents (file: /home/benjamin/.config/.claude/agents/README.md, lines 635-647)
- [x] Update agent count in header from "19 specialized agents" to "25 specialized agents" (line 4)
- [x] Remove "Recent Changes" section or update it with this update (lines 6-75)
- [x] Update "Integration with Commands" section to reflect accurate agent invocations (lines 481-502)
- [x] Verify all agent file links are correct relative paths
- [x] Add documentation of hierarchical relationships for sub-supervisor agents

Testing:
```bash
# Verify agent count updated
grep -q "25 specialized agents" /home/benjamin/.config/.claude/agents/README.md && echo "OK: Agent count updated"

# Verify navigation links count
NAV_COUNT=$(grep -c "^\- \[.*\.md\]" /home/benjamin/.config/.claude/agents/README.md)
echo "Navigation links: $NAV_COUNT"

# Verify file structure
ls -la /home/benjamin/.config/.claude/agents/*.md | wc -l
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Verification Approach
1. **Content Verification**: Grep for required sections and entries
2. **Link Validation**: Check all agent file links resolve to existing files
3. **Consistency Check**: Verify agent count matches actual files in directory
4. **Format Validation**: Ensure markdown syntax is valid

### Test Commands
```bash
# Full validation script
cd /home/benjamin/.config/.claude/agents

# Count actual agent files
ACTUAL=$(ls -1 *.md | grep -v README | wc -l)
echo "Actual agent files: $ACTUAL"

# Count documented agents
DOCUMENTED=$(grep -c "^### .*\.md$" README.md)
echo "Documented agents: $DOCUMENTED"

# Compare counts
[ "$ACTUAL" -eq "$DOCUMENTED" ] && echo "PASS: Counts match" || echo "FAIL: Counts differ"

# Verify no broken links
for agent in $(grep -o "^\- \[.*\.md\]" README.md | sed 's/.*\[\(.*\.md\)\].*/\1/'); do
  [ -f "$agent" ] || echo "BROKEN: $agent"
done
```

## Documentation Requirements

### Primary Deliverable
- `/home/benjamin/.config/.claude/agents/README.md` - Complete rewrite of Available Agents section

### No Additional Documentation
This plan updates an existing README.md file. No new documentation files needed.

## Dependencies

### Prerequisites
- Research report completed with agent analysis
- Access to all agent files in agents directory
- Access to command files to verify usage patterns

### External Dependencies
None - all work is internal documentation updates

### Integration Points
- Navigation links must match actual agent files
- Command references must match actual command invocations in command files
