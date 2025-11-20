# Neovim Buffer Opening Integration for Claude Code Workflows - Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Automatic artifact buffer opening after workflow command completion
- **Scope**: Neovim integration for `/research`, `/plan`, `/build`, and other workflow commands
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 68.0
- **Research Reports**:
  - [Neovim Buffer Opening Integration Research](/home/benjamin/.config/.claude/specs/848_when_using_claude_code_neovim_greggh_plugin/reports/001_buffer_opening_integration.md)

## Overview

This plan implements automatic buffer opening in Neovim when Claude Code workflow commands (`/research`, `/plan`, `/build`, etc.) complete and generate artifacts. The solution uses Neovim's native file system event watching API (`vim.uv.new_fs_event()`) to monitor the `.claude/specs/` directory and automatically open newly created markdown artifacts in appropriate buffers.

The implementation integrates seamlessly with the existing `greggh/claude-code.nvim` plugin infrastructure and the extensive internal Claude Code integration system (9,626 lines across 20 files).

## Research Summary

Key findings from the research report:

1. **Existing Architecture**: The Neovim configuration has comprehensive Claude Code integration with established buffer opening patterns using `vim.cmd("edit " .. vim.fn.fnameescape(filepath))`

2. **Completion Signals**: All workflow commands return standardized completion signals (e.g., `REPORT_CREATED: /path/to/file.md`) that provide clear hooks for automation

3. **Directory Structure**: Topic-based organization in `specs/{NNN_topic}/` with artifact subdirectories (plans/, reports/, summaries/, debug/)

4. **Recommended Approach**: File system watcher using native `vim.uv.new_fs_event()` API for event-driven, zero-overhead monitoring with automatic buffer opening

5. **Integration Points**: Existing command picker, session manager, and worktree systems provide foundation for enhancement

## Success Criteria

- [ ] File system watcher monitors `.claude/specs/` directory for new artifacts
- [ ] Research reports auto-open in buffers after `/research` command completion
- [ ] Implementation plans auto-open in buffers after `/plan` command completion
- [ ] Summaries auto-open in buffers after `/build` command completion
- [ ] Terminal context detection works correctly (opens in split vs. current window)
- [ ] Debouncing prevents duplicate buffer opens for the same file
- [ ] Configuration allows users to enable/disable feature and customize behavior
- [ ] No performance degradation (< 100ms startup overhead, < 5% CPU during events)
- [ ] Feature works across worktrees and session boundaries
- [ ] Documentation explains configuration and troubleshooting

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Neovim (claude-code.nvim)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────┐      │
│  │  artifact-watcher.lua (NEW MODULE)               │      │
│  ├──────────────────────────────────────────────────┤      │
│  │                                                   │      │
│  │  ┌────────────────────────────────────┐          │      │
│  │  │  Specs Directory Watcher           │          │      │
│  │  │  (vim.uv.new_fs_event)             │          │      │
│  │  └────────────┬───────────────────────┘          │      │
│  │               │                                   │      │
│  │               ▼                                   │      │
│  │  ┌────────────────────────────────────┐          │      │
│  │  │  Topic Directory Watchers          │          │      │
│  │  │  (per specs/{NNN_topic}/)          │          │      │
│  │  └────────────┬───────────────────────┘          │      │
│  │               │                                   │      │
│  │               ▼                                   │      │
│  │  ┌────────────────────────────────────┐          │      │
│  │  │  Artifact Watchers                 │          │      │
│  │  │  • reports/ (enabled)              │          │      │
│  │  │  • plans/ (enabled)                │          │      │
│  │  │  • summaries/ (enabled)            │          │      │
│  │  │  • debug/ (disabled by default)    │          │      │
│  │  └────────────┬───────────────────────┘          │      │
│  │               │                                   │      │
│  │               ▼                                   │      │
│  │  ┌────────────────────────────────────┐          │      │
│  │  │  File Event Handler                │          │      │
│  │  │  • Debouncing (500ms)              │          │      │
│  │  │  • Path validation                 │          │      │
│  │  │  • Context detection               │          │      │
│  │  └────────────┬───────────────────────┘          │      │
│  │               │                                   │      │
│  │               ▼                                   │      │
│  │  ┌────────────────────────────────────┐          │      │
│  │  │  Buffer Opener                     │          │      │
│  │  │  • Terminal: vsplit                │          │      │
│  │  │  • Normal: edit                    │          │      │
│  │  │  • Notification                    │          │      │
│  │  └────────────────────────────────────┘          │      │
│  │                                                   │      │
│  └──────────────────────────────────────────────────┘      │
│                         ▲                                   │
│                         │                                   │
│  ┌──────────────────────┴───────────────────────────┐      │
│  │  claude/init.lua (INTEGRATION POINT)             │      │
│  │  • Watcher initialization                        │      │
│  │  • Configuration management                      │      │
│  └──────────────────────────────────────────────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                         ▲
                         │ Creates artifacts
                         │
┌────────────────────────┴─────────────────────────────┐
│  Claude Code Workflow Commands                       │
│  • /research → specs/{NNN}/reports/NNN_*.md         │
│  • /plan → specs/{NNN}/plans/NNN_*.md               │
│  • /build → specs/{NNN}/summaries/NNN_*.md          │
│  • /debug → specs/{NNN}/debug/NNN_*.md              │
└──────────────────────────────────────────────────────┘
```

### Key Components

1. **Artifact Watcher Module** (`artifact-watcher.lua`):
   - Core module managing file system event watchers
   - Three-tier watching: specs directory → topic directories → artifact subdirectories
   - Event-driven architecture using `vim.uv.new_fs_event()`
   - Configurable debouncing (default 500ms) and artifact type filtering

2. **Integration Layer** (`claude/init.lua` modifications):
   - Initializes watcher on module setup
   - Passes configuration from user settings
   - Provides lifecycle management (start/stop watching)

3. **Configuration System**:
   - User-facing options in `claudecode.lua`
   - Sensible defaults (auto-open enabled for reports, plans, summaries)
   - Runtime toggles and customization

4. **Buffer Management**:
   - Context-aware opening (terminal vs. normal buffer)
   - Safe path handling with `vim.fn.fnameescape()`
   - Integration with existing notification system

### Performance Characteristics

- **Startup Overhead**: < 100ms (one-time watcher initialization)
- **Event Processing**: O(1) per file, < 5% CPU during artifact creation
- **Memory Footprint**: ~1-2KB per active watcher, ~300-400 watchers for 100 topics
- **Scaling**: Well within Linux inotify limits (8192 default, need ~4 per topic)

### Security Considerations

- All file paths validated before opening
- `vim.fn.fnameescape()` prevents injection attacks
- `vim.fn.filereadable()` checks prevent opening non-existent/inaccessible files
- Markdown files are non-executable (no code execution risk)

## Implementation Phases

### Phase 1: Core Artifact Watcher Module [NOT STARTED]
dependencies: []

**Objective**: Create the artifact-watcher module with file system event watching, debouncing, and buffer opening logic

**Complexity**: Medium

**Tasks**:
- [ ] Create `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/artifact-watcher.lua`
- [ ] Implement `find_specs_directory()` - Search upward from cwd for `.claude/specs` directory
- [ ] Implement `setup(config)` - Initialize watcher with user configuration
- [ ] Implement `start_watching(specs_dir)` - Create top-level specs directory watcher
- [ ] Implement `watch_topic_directory(topic_path)` - Watch individual topic directories for new artifact subdirectories
- [ ] Implement `watch_artifact_directory(artifact_dir, artifact_type)` - Watch specific artifact type directories (reports/, plans/, etc.)
- [ ] Implement `open_artifact(filepath, artifact_type)` - Open file in appropriate buffer/split with context detection
- [ ] Implement `stop_watching()` - Cleanup function to stop all active watchers
- [ ] Add debouncing logic using `recent_artifacts` table with timestamp tracking
- [ ] Add error handling with graceful degradation (log warnings, continue without watching)

**Testing**:
```bash
# Unit test
nvim --headless -c "lua require('neotex.plugins.ai.claude.util.artifact-watcher').find_specs_directory()" -c "qa!"

# Integration test - create test artifact and verify watcher detects it
mkdir -p /tmp/test_claude/.claude/specs/001_test/reports
nvim --headless -c "lua require('neotex.plugins.ai.claude.util.artifact-watcher').setup()" \
  -c "lua vim.loop.sleep(100)" \
  -c "lua io.open('/tmp/test_claude/.claude/specs/001_test/reports/001_test.md', 'w'):write('# Test'):close()" \
  -c "lua vim.loop.sleep(600)" \
  -c "qa!"
```

**Expected Duration**: 4 hours

---

### Phase 2: Integration with Claude Module System [NOT STARTED]
dependencies: [1]

**Objective**: Integrate artifact watcher with existing claude/init.lua system and establish configuration flow

**Complexity**: Low

**Tasks**:
- [ ] Modify `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua` to add artifact watcher initialization
- [ ] Add `M.setup()` configuration for watcher parameters (watch_artifacts, auto_open_artifacts, watch_artifact_types, debounce_ms, open_in_split)
- [ ] Add watcher cleanup in module teardown (if cleanup mechanism exists)
- [ ] Ensure watcher starts after session manager initialization
- [ ] Add error handling for watcher initialization failures (log warning, continue without feature)
- [ ] Test watcher lifecycle (startup, runtime, shutdown)

**Testing**:
```bash
# Test configuration propagation
nvim --headless -c "lua require('neotex.plugins.ai.claude').setup({ watch_artifacts = true, debounce_ms = 1000 })" \
  -c "lua print(vim.inspect(require('neotex.plugins.ai.claude').config))" \
  -c "qa!"

# Test initialization sequence
nvim -c "lua vim.defer_fn(function() print('Watcher active:', require('neotex.plugins.ai.claude.util.artifact-watcher')._active) end, 200)"
```

**Expected Duration**: 2 hours

---

### Phase 3: User Configuration and Plugin Integration [NOT STARTED]
dependencies: [2]

**Objective**: Add user-facing configuration in claudecode.lua with sensible defaults and documentation

**Complexity**: Low

**Tasks**:
- [ ] Modify `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua` to add artifact watcher configuration
- [ ] Add default configuration: `watch_artifacts = true`, `auto_open_artifacts = true`
- [ ] Add `watch_artifact_types` with defaults: reports=true, plans=true, summaries=true, debug=false
- [ ] Add `debounce_ms = 500` and `open_in_split = nil` (auto-detect)
- [ ] Ensure configuration is passed to `claude.setup()` in deferred function
- [ ] Add inline comments explaining each configuration option
- [ ] Test with various configuration combinations (all enabled, selective types, disabled)

**Testing**:
```bash
# Test default configuration
nvim --headless -c "lua require('neotex.plugins.ai.claudecode')" \
  -c "lua vim.defer_fn(function() print(vim.inspect(require('neotex.plugins.ai.claude').config)) end, 200)" \
  -c "qa!"

# Test custom configuration (edit claudecode.lua with watch_artifacts = false, verify no watcher active)
```

**Expected Duration**: 1.5 hours

---

### Phase 4: Real-World Testing and Refinement [NOT STARTED]
dependencies: [3]

**Objective**: Test with actual workflow commands and refine behavior based on real usage patterns

**Complexity**: Medium

**Tasks**:
- [ ] Test `/research "automatic buffer test"` - verify report auto-opens
- [ ] Test `/plan "buffer test feature"` - verify plan auto-opens (and research report if created)
- [ ] Test `/build` with existing plan - verify summary auto-opens
- [ ] Test multiple commands in rapid succession - verify debouncing prevents duplicates
- [ ] Test in terminal buffer context - verify vertical split behavior
- [ ] Test in normal buffer context - verify current window replacement behavior
- [ ] Test with `watch_artifacts = false` - verify no auto-opening
- [ ] Test with selective artifact types (e.g., only reports) - verify filtering works
- [ ] Test across worktree boundaries - verify watcher respects active worktree
- [ ] Monitor performance during heavy usage (10+ commands creating artifacts)
- [ ] Collect and address any edge cases or unexpected behaviors
- [ ] Refine debounce timing if needed based on actual command completion speeds

**Testing**:
```bash
# Real workflow test sequence
cd /home/benjamin/.config
nvim -c "ClaudeCode" # Open Claude Code terminal

# In terminal, run:
# /research "test automatic buffer opening behavior"
# (verify report opens in vsplit)

# /plan "implement test feature based on research"
# (verify plan opens, possibly report too)

# /build <plan-file>
# (verify summary opens after build completes)

# Check for performance issues
# :messages (check for warnings/errors)
```

**Expected Duration**: 3 hours

---

### Phase 5: Documentation and User Guidance [NOT STARTED]
dependencies: [4]

**Objective**: Create comprehensive documentation for users and developers with configuration examples and troubleshooting

**Complexity**: Low

**Tasks**:
- [ ] Add "Automatic Artifact Opening" section to `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`
- [ ] Document configuration options with examples (watch_artifacts, auto_open_artifacts, watch_artifact_types, debounce_ms, open_in_split)
- [ ] Document behavior in different contexts (terminal vs. normal buffer, split behavior)
- [ ] Add troubleshooting section with common issues:
  - Artifacts not opening automatically
  - Too many files opening
  - Performance issues
- [ ] Add code examples for custom configuration
- [ ] Document how to check configuration at runtime (`:lua print(vim.inspect(require('neotex.plugins.ai.claude').config))`)
- [ ] Add developer notes to `artifact-watcher.lua` explaining architecture, performance characteristics, and extension points
- [ ] Document how to disable feature if needed
- [ ] Add examples of conditional opening rules (future enhancement reference)

**Testing**:
```bash
# Verify documentation is accurate by following troubleshooting steps
# Test each configuration example in documentation
# Ensure all code snippets are syntactically correct
```

**Expected Duration**: 1.5 hours

---

## Testing Strategy

### Unit Testing

**Test File**: `/home/benjamin/.config/nvim/tests/neotex/plugins/ai/claude/util/artifact-watcher_spec.lua`

Key test cases:
- `find_specs_directory()` returns correct path
- Watcher initialization succeeds with valid specs directory
- Watcher handles missing specs directory gracefully
- Debouncing prevents duplicate opens for same file within threshold
- File validation prevents opening non-existent/unreadable files
- Configuration merging works correctly

### Integration Testing

**Manual Test Protocol**:
1. Basic functionality: `/research` → report auto-opens
2. Multiple artifacts: `/plan` → both research and plan auto-open
3. Terminal context: Artifacts open in vsplit when in terminal buffer
4. Disabled feature: No auto-opening when `watch_artifacts = false`
5. Concurrent commands: Multiple rapid commands handled correctly
6. Artifact type filtering: Only configured types auto-open

### Performance Testing

**Benchmarks**:
- Startup time with 0, 10, 50, 100 topic directories (target: < 100ms overhead)
- CPU usage during rapid artifact creation (target: < 5% spike)
- Memory stability over 8-hour session (target: no leaks)
- Watcher count with 100 topics (target: ~300-400, well under OS limits)

### Regression Testing

Ensure existing functionality unaffected:
- Command picker still works for manual artifact opening
- Session management continues to function
- Worktree integration not disrupted
- Visual selection and other features remain operational

## Documentation Requirements

### User Documentation

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`

Required sections:
- Feature overview and benefits
- Configuration reference with all options
- Behavior description (terminal vs. normal buffer)
- Troubleshooting guide with solutions
- Examples for common use cases

### Developer Documentation

**Location**: Inline in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/artifact-watcher.lua`

Required content:
- Module architecture and design rationale
- API documentation for public functions
- Performance characteristics and scaling behavior
- Extension points for future enhancements
- Implementation notes and gotchas

### Code Standards Compliance

Per CLAUDE.md standards:
- 2-space indentation (Lua standard)
- Use `pcall` for safe requires and function calls
- Snake_case for function names
- Clear, descriptive variable names
- Comments describe WHAT code does, not WHY (design rationale in separate docs)
- No emojis in code or file content

## Dependencies

### Neovim Version Requirements
- Neovim 0.9+ (for stable `vim.uv` API)
- Graceful degradation for older versions (check API availability)

### External Dependencies
- None (uses native `vim.uv.new_fs_event()`)
- Existing integration: `neotex.util.notifications` for user feedback

### System Dependencies
- Linux: inotify support (standard in modern kernels)
- macOS: FSEvents support (standard)
- Windows: ReadDirectoryChangesW (standard)

### Integration Points
- `claude/init.lua` - Module initialization
- `claudecode.lua` - User configuration
- `neotex.util.notifications` - User notifications
- Existing command picker - Complementary manual artifact browsing

## Risk Management

### Technical Risks

**Risk**: File system watcher doesn't detect files created by external processes
**Mitigation**: Use native `vim.uv.new_fs_event()` which monitors OS-level file system events, not Neovim-internal buffer writes
**Likelihood**: Low

**Risk**: Too many watchers consume system resources
**Mitigation**: ~4 watchers per topic, well under Linux inotify limit of 8192. Implement watcher cleanup for deleted topics.
**Likelihood**: Low

**Risk**: Race condition between file creation and watcher establishment
**Mitigation**: Watchers created immediately on Neovim startup. Existing directories scanned and watched. Debouncing handles near-simultaneous events.
**Likelihood**: Medium → Low (mitigated)

**Risk**: Performance degradation with many topics
**Mitigation**: Event-driven architecture has O(1) processing per file. Benchmark with 100 topics to validate performance targets.
**Likelihood**: Low

### User Experience Risks

**Risk**: Users find auto-opening intrusive
**Mitigation**: Provide clear disable mechanism (`watch_artifacts = false`). Selective artifact type filtering. Document in README.
**Likelihood**: Low

**Risk**: Unexpected behavior in edge cases
**Mitigation**: Comprehensive testing phase (Phase 4) with real workflow commands. User documentation includes troubleshooting.
**Likelihood**: Medium → Low (testing phase addresses this)

### Rollback Plan

If critical issues arise post-deployment:
1. Set `watch_artifacts = false` by default in `claudecode.lua`
2. Keep module in codebase for opt-in usage
3. Investigate and fix issues
4. Re-enable in future release after validation

## Future Enhancements

Beyond initial implementation (not in scope for this plan):

1. **Smart Window Management**: Remember user preferences for split direction per artifact type
2. **Artifact History**: Track recently auto-opened artifacts with Telescope picker integration
3. **Conditional Opening Rules**: User-defined functions to control when to auto-open
4. **Session Integration**: Link opened artifacts to Claude Code sessions for context tracking
5. **Multi-Editor Support**: Extend mechanism to VSCode, Emacs, etc. with shared protocol

## Notes

- This implementation leverages Neovim's native file system event API for zero external dependencies
- The approach is non-invasive to workflow commands (no modifications needed)
- Architecture supports future extensions without major refactoring
- Performance characteristics are excellent for typical usage (< 1000 topics)
- Feature enhances user experience while remaining fully optional and configurable

---

**Implementation Complexity Analysis**:
```
Score = Base(10 - new feature)
        + Tasks/2 (50 tasks / 2 = 25)
        + Files*3 (3 files * 3 = 9)
        + Integrations*5 (6 integration points * 5 = 30)
        - Simplicity bonus (-6 for using native APIs)
      = 10 + 25 + 9 + 30 - 6
      = 68.0
```

Complexity tier: **Tier 2** (50-200), but starting with **Level 0** (single file plan) per progressive planning protocol. Expansion to phase files can be done via `/expand` if needed during implementation.

**Note**: All phases include `[NOT STARTED]` markers as required for `/build` command compatibility and progress tracking.