# Dropdown Menu Improvement Design Strategy

## Executive Summary

This report outlines an architectural strategy to improve the Claude Code dropdown menu by implementing intelligent command deduplication, scope-aware selection, and cache management. The goal is to show each command exactly once with the most appropriate description, eliminating redundant entries while maintaining backward compatibility.

## Design Goals

### Primary Goals
1. **Deduplication**: Each command appears exactly once in dropdown
2. **Clarity**: No confusing duplicate scope markers
3. **Correctness**: Deleted commands don't appear
4. **Consistency**: Same command shows same description across contexts

### Secondary Goals
1. **Performance**: Fast dropdown loading (<100ms)
2. **Maintainability**: Simple rules that scale
3. **Extensibility**: Easy to add new sources
4. **User-Friendly**: Works without user configuration

## Architecture Overview

### Core Concept: Command Registry with Deduplication

```
┌────────────────────────────────────────────────────────────────┐
│                      Command Discovery Phase                  │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Source 1: Built-in          Source 2: User Custom            │
│  Registry (50+ commands)      Commands (20 commands)           │
│  └─ /implement                └─ .claude/commands/*.md         │
│  └─ /research                 └─ /plan                         │
│  └─ /resume-implement         └─ /coordinate                   │
│  └─ etc.                       └─ etc.                          │
│                                                                │
│  Source 3: Project Config     Source 4: Hierarchy Config       │
│  CLAUDE.md References         nvim/CLAUDE.md References        │
│  └─ /implement (listed 20×)    └─ /implement                   │
│  └─ /plan                      └─ /research                    │
│  └─ /research                  └─ /test                        │
│  └─ etc.                        └─ etc.                         │
│                                                                │
└─────────────────────┬────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────┐
│                   Deduplication & Merging                      │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Priority-Based Selection:                                    │
│  1. User Custom (highest priority)                            │
│  2. Hierarchical Config (nvim overrides)                      │
│  3. Project Config (main CLAUDE.md)                           │
│  4. Built-in Registry (lowest priority)                       │
│                                                                │
│  Algorithm:                                                   │
│  For each unique command name:                                │
│    - Collect all sources                                      │
│    - Select highest-priority source                           │
│    - Extract description & metadata                           │
│    - Mark as deleted if not in current sources                │
│    - Resolve scope conflicts                                  │
│                                                                │
└─────────────────────┬────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────┐
│              Validation & Scope Resolution                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Scope Validation:                                            │
│  - Check if command actually exists in source                 │
│  - Mark stale entries (deleted but still in cache)            │
│  - Warn on conflicts (same command, different behavior)       │
│                                                                │
│  Description Consolidation:                                   │
│  - Use primary source description                             │
│  - Append scope notes if variants differ                      │
│  - Warn if descriptions conflict significantly                │
│                                                                │
└─────────────────────┬────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────┐
│            Unified Command Registry (Final)                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Command Registry:                                            │
│  {                                                            │
│    "implement": {                                             │
│      "name": "/implement",                                    │
│      "description": "Execute implementation plan...",         │
│      "source": "user_custom",                                 │
│      "source_file": ".claude/commands/implement.md",          │
│      "scope": null,                                           │
│      "alternate_sources": ["project_config", "builtin"],     │
│      "is_active": true                                        │
│    },                                                         │
│    "resume-implement": {                                      │
│      "name": "/resume-implement",                             │
│      "description": "Resume from incomplete plan...",         │
│      "source": "builtin",                                     │
│      "is_active": false,                                      │
│      "deleted_in": "plan_033",                                │
│      "reason": "Duplicate of /implement auto-resume"          │
│    }                                                          │
│  }                                                            │
│                                                                │
└─────────────────────┬────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────────────┐
│            Dropdown Menu Display (Deduped)                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Filter by prefix (/im → /implement, /optimize-claude)       │
│  For each active command:                                     │
│    - Show name                                                │
│    - Show description (primary source)                        │
│    - Show scope only if multiple variants exist               │
│    - Show source indicator if not .claude/commands/           │
│                                                                │
│  Result:                                                      │
│  /implement                                                   │
│    Execute implementation plan with automated testing,        │
│    adaptive replanning, and commits                           │
│                                                                │
│  /optimize-claude                                             │
│    CLAUDE.md Optimization Command                             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Key Design Components

### 1. Priority-Based Source Selection

**Principle**: When same command found in multiple sources, select based on source priority.

**Priority Hierarchy**:
```
1. User Custom Commands (.claude/commands/)     - HIGHEST PRIORITY
   - Commands that user explicitly defined
   - Can override all other sources
   
2. Hierarchical Config (nvim/.claude/CLAUDE.md)
   - Directory-specific overrides
   - More specific than project-wide
   
3. Project Config (main CLAUDE.md)
   - Project-wide command references
   - Shared configuration
   
4. Built-in Registry (Claude Code)             - LOWEST PRIORITY
   - Default Claude Code commands
   - Available to all projects
```

**Example Decision Matrix**:
```
Command: /implement

Source                          File                              Exists?
────────────────────────────────────────────────────────────────────────
1. .claude/commands/            implement.md                      ✓ YES    ← USE THIS
2. nvim/.claude/CLAUDE.md       (references /implement)          ✓ YES
3. Main CLAUDE.md               (references /implement)          ✓ YES
4. Built-in registry            (native /implement)              ✓ YES

Decision: Use source 1 (.claude/commands/implement.md)
Reason: Highest priority source where command actively exists
Result: Show /implement once with description from implement.md
```

### 2. Scope Resolution Strategy

**Principle**: Only show scope markers when they represent functional differences.

**Rule Set**:
```
Rule 1: Single Implementation
  If command exists in only one source or all sources describe same behavior:
    └─ Show command without scope marker
    └─ Example: /implement (not /implement (user) and /implement (project))

Rule 2: Functional Variants
  If command has genuinely different implementations per scope:
    └─ Show both with scope labels
    └─ Example: /test (user) vs /test (project) with different test runners
    
Rule 3: Description-Only Differences
  If behavior is same but descriptions vary:
    └─ Consolidate descriptions
    └─ Choose most complete/accurate version
    └─ Example: Use "...with adaptive replanning" version (more informative)

Rule 4: Deprecated/Deleted Variants
  If scope variant is deleted/deprecated:
    └─ Remove from dropdown
    └─ Log as deprecated in documentation
    └─ Example: /resume-implement removed, /implement handles resume
```

**Decision Flow for /implement**:
```
/implement found in multiple sources:
  ✓ Is behavior identical? YES
    └─ Only one description variant?
      ✓ YES → Show /implement (single entry)
      ✗ NO  → Use best description (with adaptive replanning)
  ✗ NO → Show with scope markers (user/project)
```

### 3. Deleted Command Detection

**Principle**: Remove commands that no longer exist in current, active sources.

**Verification Process**:
```
For each command in registry:
  
  Step 1: Check User Custom (.claude/commands/)
    └─ File exists? → ACTIVE
    └─ File doesn't exist? → Continue to Step 2
  
  Step 2: Check Hierarchical Config (nvim/.claude/CLAUDE.md)
    └─ Referenced? → ACTIVE (directory override)
    └─ Not referenced? → Continue to Step 3
  
  Step 3: Check Project Config (main CLAUDE.md)
    └─ Referenced in Project-Specific Commands? → ACTIVE
    └─ Only in old specs/plans? → DEPRECATED (archived)
    └─ Not found? → Continue to Step 4
  
  Step 4: Check Built-in Registry
    └─ In built-in? → ACTIVE (but low priority)
    └─ Not in built-in? → DELETED (remove from dropdown)
  
  Final Decision:
    - ACTIVE: Include in dropdown
    - DEPRECATED: Hide from dropdown, document as deprecated
    - DELETED: Remove from dropdown, cleanup cache
```

**Example: /resume-implement**
```
Check .claude/commands/:     resume-implement.md → NOT FOUND
Check nvim/.claude/CLAUDE.md: No reference → NOT FOUND
Check main CLAUDE.md:        Only in old specs → ARCHIVED
Check built-in:             Exists in Claude Code registry → EXISTS

Decision: DEPRECATED
  - Reason: User intentionally deleted, built-in version exists but is redundant
  - Action: Hide from dropdown in this project
  - Documentation: "Functionality merged into /implement auto-resume"
  - Rationale: /implement now auto-resumes, making /resume-implement unnecessary
```

### 4. Cache Management

**Principle**: Keep registry fresh and synchronized with filesystem.

**Cache Strategy**:
```
┌─────────────────────────────────────────────┐
│        Dropdown Registry Cache (.json)      │
├─────────────────────────────────────────────┤
│                                             │
│  Metadata:                                  │
│    - Created: 2025-11-15T10:30:00Z         │
│    - LastUpdated: 2025-11-15T12:45:00Z     │
│    - Version: 2.0                          │
│    - Hash: <content-hash>                  │
│                                             │
│  Invalidation Triggers:                    │
│    - File created in .claude/commands/     │
│    - File modified in .claude/commands/    │
│    - File deleted from .claude/commands/   │
│    - CLAUDE.md modified                    │
│    - nvim/.claude/CLAUDE.md modified       │
│    - Manual cache clear                    │
│    - Cache age > 24 hours                  │
│                                             │
│  Cleanup Actions:                          │
│    - Remove entries for deleted files      │
│    - Update descriptions from modified     │
│    - Recompute scope conflicts             │
│    - Recalculate priorities                │
│                                             │
└─────────────────────────────────────────────┘
```

## Detailed Deduplication Algorithm

### Algorithm Pseudocode

```
function buildCommandRegistry():
  registry = {}
  sourceStack = [builtinRegistry, projectConfig, hierarchyConfig, userCustom]
  
  // Phase 1: Collect all commands from all sources
  for each source in sourceStack:
    commands = parseSource(source)
    for each cmd in commands:
      if cmd.name not in registry:
        registry[cmd.name] = {
          name: cmd.name,
          sources: [],
          descriptions: []
        }
      registry[cmd.name].sources.append({
        source: source,
        description: cmd.description,
        file: cmd.file,
        exists: fileExists(cmd.file)
      })
  
  // Phase 2: Deduplicate and select primary source
  finalRegistry = {}
  for each cmd.name in registry.keys():
    
    // Filter out non-existent sources
    activeSources = [s for s in registry[cmd.name].sources if s.exists]
    
    if activeSources.isEmpty():
      // Command doesn't exist anywhere
      finalRegistry[cmd.name] = {
        status: DELETED,
        reason: "Not found in any active source"
      }
      continue
    
    // Select highest-priority active source
    primarySource = activeSources[0]  // First in priority order
    
    // Check for conflicts in descriptions
    uniqueDescriptions = uniqueSet([s.description for s in activeSources])
    
    if uniqueDescriptions.length > 1:
      // Descriptions conflict - log warning
      logWarning(`${cmd.name}: Multiple descriptions found`)
      // Use primary source description
      primaryDesc = primarySource.description
    else:
      primaryDesc = uniqueDescriptions[0]
    
    // Check for scope conflicts
    hasMultipleSources = activeSources.length > 1
    scopeMarker = null
    if hasMultipleSources && hasFunctionalDifferences(activeSources):
      scopeMarker = getPrimarySourceScope(primarySource)
    
    // Build final entry
    finalRegistry[cmd.name] = {
      name: cmd.name,
      description: primaryDesc,
      source: primarySource.source,
      sourceFile: primarySource.file,
      scope: scopeMarker,
      alternates: activeSources.slice(1),  // Other valid sources
      isActive: true,
      priority: calculatePriority(primarySource),
      lastVerified: now()
    }
  
  return finalRegistry

function filterForDropdown(registry, prefix):
  filtered = []
  for each cmd in registry.values():
    if cmd.name.startsWith(prefix) && cmd.isActive:
      filtered.append({
        name: cmd.name,
        description: cmd.description,
        scope: cmd.scope,  // May be null
        indicator: cmd.source  // Optional: show source if not custom
      })
  
  // Sort by primary/alternate sources
  filtered.sort(by: [isCustom DESC, priority DESC])
  return filtered
```

### Example Execution: /im Prefix

**Input**: User types "/im" in dropdown

**Execution**:
```
Step 1: Collect from all sources
  - Built-in: /implement, /implement-advanced (if exists)
  - User custom: /implement
  - Project config: /implement (referenced 20 times)
  - Hierarchy config: /implement (nvim override)

Step 2: Deduplicate
  - Command: "implement"
  - Sources: [builtin, user_custom, project, hierarchy]
  - Active: All exist
  - Primary: user_custom (highest priority)
  - Descriptions: 2 variants found
  - Select: "Execute implementation plan... with adaptive replanning"

Step 3: Scope resolution
  - Multiple sources? YES
  - Functional differences? NO (all do same thing)
  - Scope marker? NO (not needed, functionally identical)

Step 4: Build entry
  Entry: {
    name: "/implement",
    description: "Execute implementation plan... with adaptive replanning",
    source: "user_custom",
    sourceFile: ".claude/commands/implement.md",
    scope: null,
    isActive: true
  }

Step 5: Filter for "/im" prefix
  Match: YES (starts with /im)
  Display: /implement
           Execute implementation plan with automated testing,
           adaptive replanning, and commits

Step 6: Check for /resume-implement
  - Name: "resume-implement"
  - Sources: [builtin] (user custom deleted)
  - Active: YES (in builtin)
  - But: Marked as deprecated in project docs
  - Decision: Show but with deprecation notice, or hide?
  - Best practice: Hide (user explicitly deleted)
  - Override rule: User deletion > builtin registry
  - Final: Hidden from dropdown
```

**Output**: Single /implement entry shown

## Implementation Phases

### Phase 1: Analysis & Validation (1-2 days)
- Audit current command enumeration
- Map all sources and their command lists
- Identify all duplicates and conflicts
- Document scope marker semantics
- Create test cases for deduplication

### Phase 2: Core Deduplication (3-5 days)
- Implement priority-based selection
- Build command registry structure
- Add scope resolution logic
- Implement deleted command detection
- Add validation tests

### Phase 3: Cache Management (2-3 days)
- Design cache structure
- Implement cache invalidation
- Add file watching for changes
- Create cache cleanup routines
- Add cache performance tests

### Phase 4: Integration & Testing (3-5 days)
- Integrate with Claude Code dropdown
- Test all source combinations
- Verify backward compatibility
- Performance testing
- User acceptance testing

### Phase 5: Documentation & Rollout (1-2 days)
- Document deduplication strategy
- Create user migration guide
- Add troubleshooting section
- Plan rollout strategy
- Monitor for issues

## Success Criteria

### Functional Requirements
- [ ] Each command appears exactly once in dropdown
- [ ] No "(user)" or "(project)" duplicates
- [ ] Deleted commands don't appear
- [ ] Descriptions are consistent and accurate
- [ ] Auto-resume functionality works without /resume-implement

### Performance Requirements
- [ ] Dropdown loads in <100ms
- [ ] Registry build in <50ms
- [ ] Cache hit rate >95%
- [ ] Memory usage <5MB

### User Experience
- [ ] Users see clean dropdown (no duplicates)
- [ ] Commands are discoverable by prefix
- [ ] Descriptions accurately reflect behavior
- [ ] No breaking changes to existing workflows

## Rollout Strategy

### Pre-rollout
1. Deploy with feature flag (disabled)
2. Run beta testing with select users
3. Collect feedback and iterate
4. Validate all test cases pass

### Rollout Phase 1
- Enable for new projects (opt-in)
- Monitor for issues
- Gather user feedback
- Document known limitations

### Rollout Phase 2
- Enable for existing projects (with notice)
- Provide migration guide
- Support old behavior with flag if needed
- Monitor adoption

### Post-rollout
- Monitor for edge cases
- Iterate on feedback
- Plan next improvements
- Document lessons learned

## Conclusion

This design strategy provides a comprehensive approach to fixing the dropdown menu duplication issue by:
1. Implementing clear priority-based source selection
2. Providing scope-aware command resolution
3. Detecting and removing deleted commands
4. Managing cache freshness and invalidation

The strategy is scalable, maintains backward compatibility, and provides a foundation for future command system improvements.

