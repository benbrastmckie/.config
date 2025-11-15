# Command Enumeration and Source Analysis

## Overview

This report documents all sources from which Claude Code collects commands for dropdown menu display, including analysis of how deduplication should work.

## Source 1: Built-in Claude Code Registry

### Description
Claude Code contains ~50+ native commands integrated into the application. These are automatically available to all users.

### How It's Exposed
- Available through `/` prefix in any project
- Registered in Claude Code's internal command registry
- Scope marker: "(built-in)" or unmarked

### Current Commands in Registry (Suspected)
Based on dropdown appearance and CLAUDE.md references:
- /implement (built-in version)
- /research
- /plan
- /orchestrate
- /setup
- /test
- /revise
- /update (deprecated but may still be in registry)
- /resume-implement (likely from older Claude Code versions)
- /vim (Neovim toggle)
- Many others (~40+ total)

### Problems with This Source
1. No way for users to override duplicates
2. Cannot remove stale commands from built-in registry
3. /resume-implement persists despite being removed from project

## Source 2: .claude/commands/ Directory

### Description
User-defined custom commands stored as markdown files in `.claude/commands/` directory.

### Files in This Project
```
Total: 20 command files

analyze.md                     - Analyze system metrics
collapse.md                    - Collapse expanded phases
convert-docs.md                - Convert document formats
coordinate.md                  - Coordinate multi-agent workflows (2,371 lines)
debug.md                       - Investigate issues
document.md                    - Update documentation
expand.md                      - Expand phases to separate files
implement.md                   - Execute implementation plans
list.md                        - List implementation artifacts
orchestrate.md                 - Orchestrate subagents (5,438 lines)
plan.md                        - Create implementation plans
plan-from-template.md          - Generate plan from template
plan-wizard.md                 - Interactive plan wizard
refactor.md                    - Analyze code refactoring
research.md                    - Research topics
revise.md                      - Revise existing plans
setup.md                       - Setup/improve CLAUDE.md
supervise.md                   - Supervise agents
test.md                        - Run project tests
test-all.md                    - Run all tests
```

### Metadata Structure (YAML Frontmatter)
Each command file contains:
```yaml
---
description: [command description]
command-type: [primary|utility|support|workflow]
argument-hint: [optional arguments]
allowed-tools: [tools that can be used]
dependent-commands: [other commands this depends on]
---
```

### What's Missing: /resume-implement
- **NOT found** in .claude/commands/ directory
- **WAS deleted** in Plan 033 consolidation
- **Still appears** in dropdown menu
- Deletion confirmed completed but effect not visible in dropdown

### Enumeration Method
Claude Code scans `.claude/commands/` for `.md` files and:
1. Extracts YAML frontmatter
2. Parses description field
3. Adds scope marker based on context
4. Adds to available commands list

### Enumeration Issues
1. No duplicate detection within this source
2. Only reads description field (not command-type)
3. No scoping strategy visible
4. Files deleted but entries may persist in caches

## Source 3: CLAUDE.md Configuration Files

### Files in Project
```
/home/benjamin/.config/CLAUDE.md                 - Main config
/home/benjamin/.config/nvim/CLAUDE.md            - Neovim overrides
/home/benjamin/.config/nvim/.claude/CLAUDE.md    - Additional Neovim config
```

### How Commands are Referenced in CLAUDE.md

#### Type A: Inline Descriptions in Text Sections
Example from main CLAUDE.md:
```markdown
All commands located in `.claude/commands/`. Primary orchestration: 
`/coordinate` (production-ready, 2,371 lines). Core workflow commands: 
`/research`, `/plan`, `/implement`, `/test`, `/debug`, `/document`. 
Planning utilities: `/plan-wizard`, `/plan-from-template`. 
Setup: `/setup [--enhance-with-docs]`.
```

#### Type B: Usage Examples in Documentation
```markdown
### Common Tasks
- **Run Tests**: `:TestSuite` or `/test-all`
- **Implementation**: `/implement [plan-file]`
- **Planning**: `/plan <feature description>`
```

#### Type C: Section Metadata Tags
```markdown
[Used by: /implement, /plan, /orchestrate, /coordinate]
[Used by: /research, /plan, /implement, /list-plans, /list-reports, /list-summaries]
```

### Enumeration Strategy (Likely)
Claude Code parser may:
1. Search CLAUDE.md files for `/[a-z-]+` patterns
2. Extract surrounding text as description
3. Mark source as "(project)" scope
4. Add to commands list

### Enumeration Issues in This Project
1. **Duplicate Descriptions**: /implement referenced with 2 different descriptions:
   - "Execute implementation plan with automated testing and commits..."
   - "Execute implementation plan with automated testing, adaptive replanning, and commits..."

2. **Multiple References**: /implement appears in:
   - Project-Specific Commands section
   - Adaptive Planning section
   - Development Workflow section
   - Development Philosophy section (in links)
   - At least 20+ locations in file

3. **Scope Confusion**: Each reference potentially becomes separate entry

4. **Mix of Command and Topic References**:
   - Some `/implement` in code blocks (actual commands)
   - Some in lists (documentation links)
   - Parser may not distinguish

## Source 4: Nested CLAUDE.md Files (Hierarchy)

### Subdirectory Configurations
```
nvim/CLAUDE.md                - Neovim-specific standards
nvim/.claude/CLAUDE.md        - Additional Neovim Claude config
```

### Command Inheritance/Override
CLAUDE.md hierarchy allows:
- Child directories can override parent commands
- Commands scoped to specific directories
- Merging of parent + child configurations

### Enumeration Issues
1. Commands may be collected from parent and child separately
2. Same command from different levels appears as different entries
3. No merge/deduplication across hierarchy levels
4. Scope markers may come from file location instead of metadata

## Analysis: Where Duplicates Come From

### /implement Duplication Pattern

The /implement command appears 4 times in dropdown for `/im`:

```
1. (user) - "Execute implementation plan with automated testing and commits"
2. (project) - "Execute implementation plan with automated testing, adaptive replanning..."
3. (user) - "Execute implementation plan with automated testing and commits"
4. (project) - "Execute implementation plan with automated testing, adaptive replanning..."
```

### Root Cause Analysis

Likely sequence:
1. **Built-in Registry** provides /implement (possibly marked as "user")
   → "Execute implementation plan with automated testing and commits"

2. **CLAUDE.md Main File** references /implement in Project-Specific Commands
   → Parsed as "(project)" with same description

3. **nvim/CLAUDE.md** references /implement
   → Parsed as "(project)" again from subdirectory

4. **Built-in Registry** provides /implement again (cache issue)
   → Results in duplicate

### /resume-implement Duplication Pattern

Why it appears despite being deleted:

1. **Built-in Registry** contains /resume-implement
   - Older Claude Code version included this command
   - Not removed when user deleted project version
   - Users' projects inherit built-in version

2. **Historical References** in CLAUDE.md
   - References may still exist in specs/ directories
   - Old plans reference /resume-implement
   - Parser may scan archived specs

3. **Cache Not Cleaned**
   - Deletion of .claude/commands/resume-implement.md not reflected
   - Cache or registry still includes deleted entry
   - No cleanup mechanism on file deletion

## Deduplication Strategy

### Current State
- No deduplication visible in dropdown
- Duplicates appear in order of source scanning
- Both "user" and "project" scopes shown

### Recommended Deduplication Rules

#### Rule 1: Primary Command Selection
**Strategy**: When same command found in multiple sources, select by priority:
1. User-defined override (.claude/commands/)
2. Hierarchical override (nvim/.claude/CLAUDE.md)
3. Project default (main CLAUDE.md)
4. Built-in (Claude Code registry)

**Example**:
```
/implement found in:
  - Built-in registry (priority 4)
  - Main CLAUDE.md (priority 3)
  - .claude/commands/implement.md (priority 1) ← USE THIS
  
Result: Show /implement once with definition from .claude/commands/
```

#### Rule 2: Scope Resolution
**Strategy**: Only show scope marker if variants actually differ:
- If all sources describe same command → no scope shown
- If variants differ functionally → show as separate commands
- If variants differ only in description → merge and show once

**Example**:
```
/implement from built-in vs .claude/commands have same behavior
  - Show once: /implement
  - Don't show: /implement (user) and /implement (project)

If /implement-with-pr (project-only variant) existed
  - Show: /implement (standard)
  - Show: /implement-with-pr (project variant)
```

#### Rule 3: Deleted Command Cleanup
**Strategy**: Remove commands that no longer exist in any active source:
1. Check .claude/commands/ (current source)
2. Check active CLAUDE.md files (not archived specs)
3. If not found, exclude from dropdown
4. Add validation to catch stale entries

**Example**:
```
/resume-implement is deleted from .claude/commands/
  - Not found in current .claude/commands/
  - Check CLAUDE.md: only in old specs (archived)
  - Check built-in: may still be in registry
  - Decision: Remove from dropdown, note in docs that it's deprecated
```

#### Rule 4: Description Conflict Resolution
**Strategy**: When same command has different descriptions, use primary source:
- Use description from highest-priority source
- If descriptions conflict, log warning
- Consolidate descriptions if both valid (e.g., "...with optional adaptive replanning")

**Example**:
```
/implement descriptions differ:
  - Built-in: "Execute implementation plan with automated testing..."
  - Project: "Execute implementation plan with automated testing, adaptive replanning..."
  
Resolution: Use project version (higher priority)
Result: "Execute implementation plan with automated testing, adaptive replanning..."
```

## Implementation Recommendations

### Immediate Actions
1. **Clear Cache**: Remove any dropdown cache files
2. **Audit CLAUDE.md**: Remove duplicate /implement descriptions
3. **Verify Deletion**: Confirm /resume-implement.md is actually deleted
4. **Check Built-in**: Determine what's in built-in registry

### Short-term Improvements
1. **Deduplication Logic**
   - Implement command uniqueness validation
   - Add scope resolution with priority rules
   - Create command registry with versions

2. **Cache Management**
   - Add cache invalidation on file changes
   - Track file modification times
   - Clear stale entries on startup

3. **Documentation**
   - Document command enumeration strategy
   - Specify scope marker semantics
   - Create command consolidation guidelines

### Long-term Architecture
1. **Centralized Registry**
   - Single source of truth for commands
   - Versioning and conflict resolution
   - Automatic deduplication

2. **Validation Framework**
   - Prevent duplicate command definitions
   - Validate scope markers
   - Test dropdown consistency

3. **Monitoring**
   - Alert on duplicate commands
   - Track cache freshness
   - Monitor scope conflicts

## Conclusion

The dropdown duplication issue stems from:
1. Multiple command enumeration sources without deduplication
2. Scope markers treated as distinguishing features instead of metadata
3. Stale cache entries from deleted commands
4. Lack of centralized command registry with conflict resolution

Fixing this requires implementing deduplication logic with clear priority rules and scope resolution strategy, plus a cache management system to prevent stale entries.

