# Bash Session Persistence Patterns Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: Bash Session Persistence Patterns
- **Report Type**: best practices
- **Overview Report**: [Bash Export Persistence Alternatives](OVERVIEW.md)
- **Related Reports**: [State Management Across Tool Invocations](002_state_management_across_tool_invocations.md), [Alternative Bash Tool Architectures](003_alternative_bash_tool_architectures.md), [Inter-Process Communication Lightweight Methods](004_inter_process_communication_lightweight_methods.md)

## Executive Summary

Industry best practices for bash session persistence include checkpoint-based state files (using `declare -p` serialization), terminal multiplexers (tmux/screen) for process persistence, and project-specific environment managers (direnv). Modern CLI tools favor JSON-based checkpoint files for complex state while `declare -p` serves simple variable persistence needs. The codebase implements sophisticated checkpoint patterns with schema versioning and atomic operations.

## Findings

### Pattern 1: State File Serialization with `declare -p`

**Industry Standard Pattern:**
The `declare -p` command provides robust state serialization for bash variables, preserving types and attributes across invocations.

**Basic Implementation:**
```bash
#!/usr/bin/env bash
statefile='/var/statefile'

# Load previous state
. "$statefile" 2>/dev/null || :

# Initialize with defaults
declare -i persistent_counter
: ${persistent_counter:=0}

# Update state
persistent_counter="$((persistent_counter + 1))"

# Persist to file
declare -p persistent_counter >"$statefile"
```

**Key Advantages:**
- Automatic escaping of special characters
- Preserves variable attributes (-i for integer, -x for export, -a for array)
- Works with arrays, associative arrays, and complex types
- Reusable output format suitable for sourcing
- Both bash and zsh support `typeset -p` (more portable)

**Critical Limitations:**
- **Function scoping**: If sourcing occurs within a function, all variables become local to that function scope
- **Security risk**: State files execute as shell code, requiring strict file permissions
- **Portability**: Output only guaranteed reusable in same bash version, same locale, same system
- **No function persistence**: `declare -p` only handles variables, not function definitions

**Best Practices from Stack Overflow (2024-2025):**
1. Initialize variables with defaults before sourcing state file
2. Use error suppression: `. "$statefile" 2>/dev/null || :`
3. For multiple variables: `declare -p var1 var2 var3 >"$statefile"`
4. Use `trap` on EXIT to automatically save state when script terminates
5. Secure state files with restrictive permissions (chmod 600)

**Reference:** Stack Overflow #63084354, #12334495

### Pattern 2: JSON-Based Checkpoint Files (Codebase Implementation)

**Location:** `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`

**Sophisticated Implementation:**
The codebase uses JSON checkpoint files with schema versioning for workflow state persistence:

```bash
# Schema version tracking (line 25)
readonly CHECKPOINT_SCHEMA_VERSION="1.3"

# Checkpoint storage location (line 28)
readonly CHECKPOINTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/checkpoints"

# save_checkpoint function (lines 58-138)
# - Uses jq for robust JSON construction
# - Captures plan file modification times for staleness detection
# - Tracks replanning history and debug iterations
# - Preserves context metadata for resumed workflows
```

**State Preserved (Lines 100-138):**
- Workflow identification (type, project name, description)
- Phase progress (current phase, completed phases, total phases)
- Testing status (tests_passing boolean)
- Error tracking (last_error, debug_report_path)
- Adaptive planning metadata (replanning_count, replan_history)
- Context preservation (pruning logs, artifact metadata cache)
- Template metadata (template_source, template_variables)

**Advantages Over `declare -p`:**
- Structured format enables programmatic querying (jq)
- Schema versioning supports migration between checkpoint formats
- Human-readable for debugging
- Safe to version control (no executable code)
- Cross-shell compatible
- Supports complex nested data structures

**Performance Characteristics:**
- Plan modification time tracking prevents stale checkpoint resumes (lines 85-88)
- Atomic writes using temp files (line 79)
- Graceful jq fallback to basic JSON construction (lines 140-150)

**Reference:** `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:25-150`

### Pattern 3: Terminal Multiplexers (tmux/screen)

**Process Persistence vs Variable Persistence:**
Terminal multiplexers like tmux and screen solve a different problem than variable persistence—they preserve the entire shell process, not just variables.

**tmux Environment Variable Challenges:**

**Key Difference from screen:**
- **screen**: Copies environment from launching shell for each new session
- **tmux**: Spawns a server on first session; subsequent sessions inherit environment from server, not shell

**Setting Variables in tmux:**

1. **New sessions**: `tmux new-session -s SESSION_NAME -e VAR=value`
2. **Windows**: Use `-e 'VARIABLE=value'` flag when creating windows
3. **Separate environments**: `tmux -L <arbitrary_name>` creates new server with calling shell's environment

**Common Pitfalls:**
- Reattached sessions have environment from when tmux was originally launched (potentially weeks old)
- SSH-related variables (SSH_AUTH_SOCK) become stale unless using update-environment
- Default update-environment includes: DISPLAY, SSH_ASKPASS, SSH_AUTH_SOCK, SSH_AGENT_PID, SSH_CONNECTION, WINDOWID, XAUTHORITY

**Best Practice for Environment Isolation:**
Use separate tmux servers (`tmux -L project_name`) when projects require completely different environments.

**References:**
- tmux man page (man7.org)
- Stack Overflow #20701757
- GitHub tmux discussions #3997

### Pattern 4: Project-Specific Environment Management (direnv + nix-shell)

**Modern CLI Pattern (2025):**
direnv provides automatic environment activation when entering directories, eliminating manual sourcing.

**How direnv Works:**
1. Detects `.envrc` file in directory
2. Automatically loads environment variables when `cd`-ing into directory
3. Unloads variables when leaving directory
4. Watches for `.envrc` changes and auto-reloads

**Integration with Nix (nix-direnv):**
```bash
# .envrc file
use nix
```

**Key Benefits:**
- **Automatic activation**: No manual `source` commands required
- **Fast performance**: Only re-evaluates when shell.nix changes (cached otherwise)
- **Garbage collection protection**: Symlinks shell derivation in user's gcroots
- **Declarative**: Environment defined in version-controlled files

**Active Development:**
Multiple 2025 articles demonstrate continued adoption, including guides on flakes + direnv workflows.

**Reference:**
- direnv.net official documentation
- nix.dev/guides/recipes/direnv
- nix-community/nix-direnv GitHub

### Pattern 5: Shell-Specific Persistence (fish shell)

**Function Persistence:**
fish shell provides `funcsave` command to persist function definitions across sessions.

```fish
function hello
    echo "hello world"
end
funcsave hello
```

**How It Works:**
- Saves function to `~/.config/fish/functions/hello.fish`
- Automatically loaded for all future sessions
- Lazy-loading: Functions only loaded when first invoked (improves startup time)

**Limitation:**
Saved functions cannot serve as event handlers until explicitly run or sourced. For event handlers, add to configuration file instead.

**Reference:** fishshell.com/docs/current/cmds/funcsave.html

### Pattern 6: Codebase Library Sourcing Pattern

**Location:** `/home/benjamin/.config/.claude/lib/library-sourcing.sh`

**Consolidated Sourcing with Deduplication:**
```bash
# Lines 42-99: source_required_libraries function
# - Sources 7 core libraries in specific order
# - Deduplicates library list (O(n²) algorithm, acceptable for ~10 libraries)
# - Fail-fast error handling with detailed diagnostics
# - Tracks failed libraries and reports all failures
```

**Library Load Order (Lines 48-56):**
1. workflow-detection.sh - Workflow scope detection
2. error-handling.sh - Error utilities
3. checkpoint-utils.sh - Checkpoint save/restore
4. unified-logger.sh - Progress logging
5. unified-location-detection.sh - Project structure detection
6. metadata-extraction.sh - Report/plan metadata extraction
7. context-pruning.sh - Context management

**Deduplication Strategy (Lines 64-83):**
- Algorithm: O(n²) string matching, acceptable for n≈10 libraries
- Trade-off: Not idempotent across multiple calls (acceptable since commands run in isolated processes)
- Debug logging shows removed duplicates when DEBUG=1

**Reference:** `/home/benjamin/.config/.claude/lib/library-sourcing.sh:42-99`

### Pattern 7: Lazy Directory Creation (Codebase Pattern)

**Location:** `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`

**Performance Optimization:**
The codebase implements lazy directory creation to eliminate empty subdirectory proliferation:

```bash
# Lines 12-13: Performance impact
# - 80% reduction in mkdir calls during location detection
# - Eliminated 400-500 empty directories

# Pattern: ensure_artifact_directory function
# - Creates parent directory only when writing files
# - Reduces filesystem clutter
# - Improves performance by deferring I/O
```

**Atomic Topic Allocation (Lines 16-32):**
Eliminates race conditions in concurrent workflows:
- **OLD**: get_next_topic_number() → race condition → 40-60% collision rate
- **NEW**: allocate_and_create_topic() → atomic under exclusive file lock → 0% collision rate
- **Performance**: Lock hold time increased by ~2ms (10ms → 12ms), acceptable
- **Testing**: 1000 parallel allocations, 0% collision rate verified

**Reference:** `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:12-32`

### Pattern 8: Docker Container Environment Persistence

**Key Finding:**
Environment variables set via `docker exec -e VAR=value` are NOT persistent and only exist for command duration.

**For Persistent Changes:**
- Create new image with ENV directives
- Modify deployment configuration (docker-compose, Kubernetes)
- Write to container's .bashrc (only affects interactive shells, not running processes)

**Quoting Requirements:**
- **Double quotes**: Variable resolved in Docker host shell
- **Single quotes**: Variable resolved inside container
- **Example**: `docker exec container bash -c 'echo "$ENV_VAR"'`

**Reference:** Docker documentation, Stack Overflow #27812548

## Recommendations

### Recommendation 1: Use JSON Checkpoints for Complex Workflow State

**When to Use:**
- Multi-phase workflows requiring resume capability
- State includes nested data structures, arrays, metadata
- Need for schema versioning and migration
- Programmatic querying of state (using jq)

**Implementation Pattern:**
Follow the codebase's checkpoint-utils.sh pattern:
1. Define schema version constant for migration tracking
2. Use jq for robust JSON construction with fallback
3. Track file modification times for staleness detection
4. Implement atomic writes with temp files
5. Store checkpoints in standardized location (.claude/data/checkpoints/)

**Advantages:**
- Human-readable for debugging
- Safe to version control
- Cross-shell compatible
- Supports complex nested structures
- Enables programmatic querying

**Reference Implementation:** `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`

### Recommendation 2: Use `declare -p` for Simple Variable Persistence

**When to Use:**
- Single-script state persistence (cron jobs, counters)
- Simple variable types (strings, integers, arrays)
- No need for cross-shell compatibility
- State file will not be version controlled

**Implementation Pattern:**
```bash
statefile='/var/lib/script-state'

# Load state (gracefully handle missing file)
. "$statefile" 2>/dev/null || :

# Initialize with defaults
declare -i counter
: ${counter:=0}

# Update state
counter=$((counter + 1))

# Auto-save on exit
trap 'declare -p counter >"$statefile"' EXIT

# Secure permissions
chmod 600 "$statefile"
```

**Security Requirements:**
- Set restrictive permissions (chmod 600) since state file executes as shell code
- Validate file ownership before sourcing
- Consider using JSON if state file is user-accessible

### Recommendation 3: Adopt direnv for Project-Specific Environments

**When to Use:**
- Multiple projects with different environment requirements
- Need automatic environment activation when entering project directories
- Want declarative, version-controlled environment definitions
- Integration with Nix or other package managers

**Implementation:**
1. Install direnv and hook into shell (.bashrc, .zshrc)
2. Create `.envrc` in project root with environment variables
3. Use `direnv allow` to authorize file
4. Combine with nix-direnv for caching and garbage collection protection

**Benefits:**
- Zero manual activation overhead
- Fast performance through caching
- Works across shell types
- Integrates with development environments

### Recommendation 4: Combine Patterns Based on Persistence Scope

**Hierarchy of Persistence Needs:**

1. **Process persistence**: Use tmux/screen for long-running processes
2. **Project environment**: Use direnv for project-specific variables
3. **Workflow state**: Use JSON checkpoints (checkpoint-utils.sh pattern)
4. **Script state**: Use `declare -p` for simple cron/script persistence
5. **Function definitions**: Use shell-specific mechanisms (fish funcsave) or source from .bashrc

**Anti-Pattern:**
Do not attempt to use `declare -p` for complex workflow state—use JSON checkpoints instead. The codebase demonstrates why: structured checkpoints enable schema migration, staleness detection, and programmatic querying.

**Cross-Cutting Concerns:**
- Atomic operations: Use file locks for concurrent access (unified-location-detection.sh example)
- Staleness detection: Track file modification times (checkpoint-utils.sh lines 85-88)
- Lazy creation: Defer I/O until needed (unified-location-detection.sh)

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:25-150` - JSON checkpoint implementation with schema versioning
2. `/home/benjamin/.config/.claude/lib/library-sourcing.sh:42-99` - Consolidated library sourcing with deduplication
3. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:12-32` - Lazy directory creation and atomic topic allocation
4. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:1-100` - Workflow path initialization pattern

### External Sources

1. Stack Overflow #63084354 - "How to store state between two consecutive runs of a bash script" (declare -p examples)
2. Stack Overflow #12334495 - "bash—Better way to store variable between runs?"
3. lgfang.github.io/computer/2015/11/30/bash-serialize-variables - "Serialize BASH Environment Variables"
4. tmux man page (man7.org/linux/man-pages/man1/tmux.1.html)
5. Stack Overflow #20701757 - "TMUX setting environment variables for sessions"
6. GitHub tmux discussions #3997 - "Session environment variables"
7. direnv.net - Official direnv documentation
8. nix.dev/guides/recipes/direnv - "Automatic environment activation with direnv"
9. github.com/nix-community/nix-direnv - "A fast, persistent use_nix/use_flake implementation"
10. fishshell.com/docs/current/cmds/funcsave.html - "funcsave - save function definition"
11. Docker documentation (docs.docker.com/reference/cli/docker/container/exec/)
12. Stack Overflow #27812548 - "How to set an environment variable in a running docker container"

### Key Concepts

- **State Serialization**: Converting bash variables to storable format
- **Checkpoint Recovery**: Resuming workflows from saved state
- **Atomic Operations**: Preventing race conditions in concurrent access
- **Lazy Creation**: Deferring resource allocation until needed
- **Schema Versioning**: Supporting checkpoint format migration
- **Environment Isolation**: Per-project or per-session variable scoping
