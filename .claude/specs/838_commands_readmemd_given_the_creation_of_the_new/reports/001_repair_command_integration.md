# /repair Command Integration Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Update commands README.md for new /repair command
- **Report Type**: codebase analysis

## Executive Summary

The `/repair` command has been created as a new primary workflow command that performs error analysis and creates fix implementation plans. The commands README.md (773 lines, 10 commands documented) requires updates to include /repair in the command catalog, update the count from 10 to 11, and ensure consistency with existing command documentation patterns.

## Findings

### Current State Analysis

**Commands README.md Structure** (/home/benjamin/.config/.claude/commands/README.md):
- Line 5: Declares "Current Command Count: 10 active commands"
- Lines 103-361: "Available Commands" section with 10 commands documented
- Commands organized by type: Primary Commands, Workflow Commands, Utility Commands
- Each command entry follows consistent format: Purpose, Usage, Type, Example, Dependencies, Features, Documentation link

**New /repair Command Details** (/home/benjamin/.config/.claude/commands/repair.md):
- Lines 1-12: Frontmatter declares command-type: primary, dependent-agents: repair-analyst, plan-architect
- Line 4: Description: "Research error patterns and create implementation plan to fix them"
- Lines 15-21: Workflow type is "research-and-plan" with terminal state "plan"
- Usage: `/repair [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4]`

**Companion Guide Documentation** (/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md):
- Complete 504-line guide following established pattern
- Sections: Overview, Architecture, Usage Examples, Error Filtering, Advanced Topics, Troubleshooting, See Also
- Line 359-368: Documents relationship with /errors command
- Line 487-503: Related commands include /errors, /debug, /build, /plan

**Current Command Inventory** (from directory listing):
1. build.md (primary)
2. collapse.md (workflow)
3. convert-docs.md (primary)
4. debug.md (primary)
5. errors.md (utility - NOT documented in README.md)
6. expand.md (workflow)
7. optimize-claude.md (utility)
8. plan.md (primary)
9. repair.md (primary - NEW, not yet documented)
10. research.md (primary)
11. revise.md (workflow)
12. setup.md (utility)

**Discrepancy Identified**: The README.md shows 10 commands but /errors command exists and is undocumented. With /repair added, there are actually 12 command files, but only 10 are documented.

### Documentation Pattern Analysis

**Primary Commands Section** (Lines 105-208):
- Format: Title (#### /command), Purpose, Usage, Type, Example, Dependencies, Features, Documentation link
- Current primary commands: /build, /debug, /plan, /research, /convert-docs
- /repair should be added here (primary command type)

**Workflow Commands Section** (Lines 210-288):
- Commands: /expand, /collapse, /revise
- Less detailed format (no "Dependencies" subsection)

**Utility Commands Section** (Lines 290-361):
- Commands: /setup, /convert-docs (duplicate?), /optimize-claude
- Note: /convert-docs appears in both Primary and Utility sections (lines 318-341)

**Dependencies Documentation Pattern**:
```markdown
**Dependencies**:
- **Agents**: agent1, agent2
- **Libraries**: lib1, lib2
```

**Features Documentation Pattern**:
```markdown
**Features**:
- Feature description 1
- Feature description 2
- Feature description 3
```

### Integration Points

**Relationship with /errors Command**:
- /repair uses error logs at .claude/data/logs/errors.jsonl (same source as /errors)
- /repair creates analysis and plans; /errors provides query utility
- repair-command-guide.md lines 359-380 documents workflow: /errors → /repair → /build
- Both commands should be cross-referenced in README.md

**Agent Dependencies**:
- repair-analyst agent (/home/benjamin/.config/.claude/agents/repair-analyst.md)
- plan-architect agent (shared with /plan, /debug, /revise)
- Follows behavioral injection pattern (agent frontmatter lines 1-7)

**Library Dependencies**:
- workflow-state-machine.sh (>=2.0.0) - from repair.md line 10
- state-persistence.sh (>=1.5.0) - from repair.md line 11
- Additional libraries sourced: error-handling.sh, unified-location-detection.sh, workflow-initialization.sh (lines 119-131)

## Recommendations

### 1. Add /repair to Primary Commands Section (Priority: High, Effort: Low)

**Location**: After /debug command (after line 156), before /plan command

**Content Structure**:
```markdown
---

#### /repair
**Purpose**: Error analysis and repair planning workflow - Analyze error logs, identify patterns, create fix plans

**Usage**: `/repair [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4]`

**Type**: primary

**Example**:
```bash
/repair --type state_error --complexity 3
```

**Dependencies**:
- **Agents**: repair-analyst, plan-architect
- **Libraries**: workflow-state-machine.sh, state-persistence.sh, library-version-check.sh, error-handling.sh

**Features**:
- Error pattern analysis from logs
- Root cause identification
- Fix implementation plan generation
- Filterable by time, type, command, severity

**Documentation**: [Repair Command Guide](../docs/guides/commands/repair-command-guide.md)
```

**Rationale**: Primary commands section is the appropriate location for a research-and-plan workflow command. Positioning after /debug and before /plan maintains workflow sequence (debug → repair → plan).

### 2. Add /errors to Utility Commands Section (Priority: High, Effort: Low)

**Location**: Before /setup command (before line 292)

**Content Structure**:
```markdown
#### /errors
**Purpose**: Query and display error logs - Filter errors by command, time, type, workflow ID

**Usage**: `/errors [--command CMD] [--since TIME] [--type TYPE] [--limit N] [--summary]`

**Type**: utility

**Example**:
```bash
/errors --command /build --since 2025-11-19
```

**Dependencies**:
- **Libraries**: error-handling.sh

**Features**:
- Error log querying and filtering
- Summary statistics
- Raw JSONL output mode
- Time-range filtering

**Documentation**: [Errors Command Guide](../docs/guides/commands/errors-command-guide.md)

---
```

**Rationale**: /errors is a query utility (read-only) that complements /repair. It should be documented before utility commands like /setup that perform configuration changes.

### 3. Update Command Count (Priority: High, Effort: Minimal)

**Location**: Line 5

**Change**:
```markdown
- **Current Command Count**: 10 active commands
+ **Current Command Count**: 12 active commands
```

**Rationale**: Includes /repair and /errors, bringing total to 12 documented commands.

### 4. Add Cross-References Between /repair and /errors (Priority: Medium, Effort: Low)

**Location 1**: /repair Features section

Add cross-reference bullet:
```markdown
- Integration with /errors command for log queries
```

**Location 2**: /errors Features section (if added per recommendation #2)

Add cross-reference bullet:
```markdown
- Integrates with /repair for error analysis and fix planning
```

**Rationale**: These commands work together in a workflow sequence. Cross-references help users discover the complete error handling toolkit.

### 5. Verify /convert-docs Duplication (Priority: Medium, Effort: Low)

**Issue**: /convert-docs appears in both Primary Commands (lines 318-341) and the listing suggests it may be misclassified.

**Action**: Review command-type in convert-docs.md frontmatter and ensure it appears only in the correct section (likely Primary Commands, not Utility Commands).

**Rationale**: Duplicate entries cause confusion and maintenance burden. Each command should appear exactly once in the appropriate type section.

## References

### Files Analyzed
- /home/benjamin/.config/.claude/commands/README.md (773 lines) - Main documentation file requiring updates
- /home/benjamin/.config/.claude/commands/repair.md (403 lines) - New command definition with frontmatter and workflow
- /home/benjamin/.config/.claude/commands/errors.md (exists but not reviewed in detail) - Companion utility command
- /home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md (504 lines) - Complete usage guide
- /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md (306 lines) - Errors command guide
- /home/benjamin/.config/.claude/agents/repair-analyst.md (lines 1-50 reviewed) - Agent definition with behavioral guidelines

### Key Line References
- README.md:5 - Command count declaration
- README.md:105-208 - Primary Commands section
- README.md:210-288 - Workflow Commands section
- README.md:290-361 - Utility Commands section
- repair.md:1-12 - Frontmatter with command metadata
- repair.md:15-21 - Workflow type and terminal state
- repair-command-guide.md:359-380 - /errors integration workflow
- repair-command-guide.md:487-503 - Related commands section

### Command Files Inventory
Total: 12 command definition files (.md) in /home/benjamin/.config/.claude/commands/
- Documented in README.md: 10 commands
- Undocumented: 2 commands (/errors, /repair)
