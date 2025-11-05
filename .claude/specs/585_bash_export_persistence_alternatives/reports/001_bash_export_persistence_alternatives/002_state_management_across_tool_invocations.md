# State Management Across Tool Invocations Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: State Management Across Tool Invocations
- **Report Type**: best practices
- **Overview Report**: [Bash Export Persistence Alternatives](OVERVIEW.md)
- **Related Reports**: [Bash Session Persistence Patterns](001_bash_session_persistence_patterns.md), [Alternative Bash Tool Architectures](003_alternative_bash_tool_architectures.md), [Inter-Process Communication Lightweight Methods](004_inter_process_communication_lightweight_methods.md)

## Executive Summary

CLI tools and frameworks use diverse state management approaches ranging from file-based persistence (kubeconfig, Docker contexts) to hierarchical configuration systems (Git's local/global/system) and in-memory session contexts (Click, Cobra). Modern best practices favor XDG Base Directory compliance for configuration files, file locking for concurrent access, and hierarchical precedence (flags > env vars > config files > defaults). Key architectural patterns include per-session isolation (tmux, AWS sessions) versus per-invocation statelessness, with successful tools providing explicit state switching mechanisms rather than relying on shell environment variables.

## Findings

### 1. File-Based State Persistence Patterns

#### kubectl Context Management
- **Storage**: State persisted in kubeconfig file (typically `~/.kube/config`)
- **Structure**: Contexts encapsulate cluster URL, user credentials, and default namespace
- **Persistence Mechanism**: `kubectl config use-context` writes to kubeconfig file
- **Concurrency Issue**: Changes in one terminal affect all terminals since they share the same kubeconfig file
- **Alternative Tools**: kubectx provides streamlined context switching
- **Source**: kubernetes.io/docs/reference/kubectl/quick-reference/ (2025)

#### Docker Context Switching
- **Storage**: Context data stored separately per context
- **Switching Methods**:
  1. `docker context use <name>` - persists across invocations
  2. `DOCKER_CONTEXT` environment variable - overrides file-based context
  3. `--context` flag - per-invocation override
- **Portability**: `docker context export` enables context sharing across hosts
- **Isolation**: Each context contains all daemon management information
- **Source**: docs.docker.com/engine/manage-resources/contexts/

#### Terraform Workspace State Isolation
- **Storage**: Separate state files per workspace in same working directory
- **Isolation Level**: Complete state separation per workspace
- **Session Behavior**: Only one workspace active at a time per directory
- **Limitations**: Same backend used for all workspaces, not suitable for different credentials/access controls
- **Concurrency**: State locking prevents concurrent modifications
- **Best Practice**: Separate state files for different environments, not just workspaces
- **Source**: developer.hashicorp.com/terraform/language/state/workspaces

### 2. Hierarchical Configuration Systems

#### Git Config File Hierarchy
- **Three-Level System**:
  1. **System** (`/etc/gitconfig`) - all users, all repos, requires admin privileges
  2. **Global** (`~/.gitconfig`) - user-specific, all repos for that user
  3. **Local** (`.git/config`) - repository-specific
- **Precedence**: Local > Global > System (most specific wins)
- **Per-Invocation Override**: `git -c key=value` flag overrides all file-based config
- **Design Philosophy**: Each level can override previous level for progressive customization
- **Source**: git-scm.com/docs/git-config

#### AWS CLI Configuration Hierarchy
- **Persistence Mechanisms**:
  1. Configuration files (`~/.aws/config`, `~/.aws/credentials`)
  2. Named profiles for different credential sets
  3. SSO session configuration for reusable authentication
- **Precedence Order** (highest to lowest):
  1. Environment variables (`AWS_ACCESS_KEY_ID`, etc.)
  2. Command-line options
  3. Profile settings in config files
- **Session Management**: Profile selection persists via `AWS_PROFILE` environment variable for shell session duration
- **Caching**: SSO tokens cached, but process credentials NOT cached
- **Source**: docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

### 3. XDG Base Directory Specification (Modern Best Practice)

#### Standard Directory Structure
- **XDG_CONFIG_HOME**: `$HOME/.config/` - user-specific configuration files
- **XDG_CACHE_HOME**: `$HOME/.cache/` - non-essential cached data
- **XDG_STATE_HOME**: `$HOME/.local/state/` - state data persisting between restarts
- **XDG_DATA_HOME**: `$HOME/.local/share/` - user-specific data files
- **XDG_RUNTIME_DIR**: Runtime files (mode 0700, local filesystem, periodic cleanup)

#### Implementation Best Practices
- **Structure**: `$XDG_CONFIG_HOME/<application>/config.yml`
- **Fallback Logic**: Check environment variable → use if set → else use default
- **Migration Strategy**: Check legacy files first, then migrate to XDG-compliant paths
- **Cross-Platform**: XDG acceptable for CLI-only tools even on non-Linux platforms
- **Benefits**: Cleaner home directory, easier backup rules, portable settings
- **Source**: specifications.freedesktop.org/basedir/latest/

### 4. File Locking for Concurrent Access

#### Locking Mechanisms (Unix/Linux)
- **fcntl**: Most common mechanism for advisory file locks
- **flock(2)**: BSD-style file locking
- **lockf(3)**: POSIX locking interface
- **Lock Types**:
  - **Shared locks**: Multiple processes can hold simultaneously (read access)
  - **Exclusive locks**: Only one process can hold (write access)
- **Advisory vs Mandatory**: Unix defaults to advisory locks (cooperative), uncooperative processes can ignore

#### Terraform State Locking Example
- **Purpose**: Prevents state file corruption from concurrent modifications
- **Mechanism**: Backend-specific locking (DynamoDB for S3, etc.)
- **Behavior**: Only one operation can modify state at a time
- **Failure Mode**: Operations block waiting for lock release
- **Force Unlock**: Available but dangerous - only for stale locks
- **Source**: spacelift.io/blog/terraform-force-unlock

#### Distributed Locking Patterns
- **Coordinator Selection**: Hash-based algorithm distributes coordination across cluster nodes
- **Design Goal**: Coordinator typically on different node than initiator
- **Application**: Prevents bottlenecks in distributed systems
- **Source**: infohub.delltechnologies.com (OneFS file locking)

### 5. Session-Based State Management

#### tmux Session Persistence
- **Session Lifecycle**: Sessions persist whether attached or not
- **Detach/Reattach**: `Ctrl+b, d` to detach, `tmux attach` to reattach
- **Environment Variables**: Copied only when server starts (first session creation)
- **Update Mechanism**: `update-environment` option copies specific vars on attach
- **Default Updated Vars**: `DISPLAY`, `SSH_ASKPASS`, `SSH_AUTH_SOCK`, `SSH_AGENT_PID`, `SSH_CONNECTION`, `WINDOWID`, `XAUTHORITY`
- **Reboot Persistence**: Sessions lost on reboot (memory-based) unless using plugins like tmux-resurrect
- **Source**: github.com/tmux/tmux (discussions #3997)

#### AWS CLI Session State
- **SSO Sessions**: Grouped configuration for acquiring SSO access tokens
- **Reusability**: Single SSO session configuration shared across multiple profiles
- **Token Caching**: SSO tokens cached automatically
- **Duration**: Configurable session duration
- **Profile Override**: `AWS_PROFILE` environment variable for session-scoped profile selection
- **Source**: docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

#### Amazon Bedrock AgentCore Sessions (Modern Pattern)
- **Duration**: Ephemeral sessions up to 8 hours
- **Isolation**: Dedicated VM per session with isolated compute, memory, and filesystem
- **Persistence**: Data in memory or disk persists only for session duration
- **Cleanup**: Automatic resource cleanup when session terminates
- **vs Serverless**: Sessions maintain state across multiple invocations, unlike stateless functions
- **Use Case**: Multi-step workflows building upon previous interactions
- **Source**: docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-sessions.html

### 6. CLI Framework State Management Patterns

#### Click (Python) Context Objects
- **Context System**: Hierarchical context objects created per command invocation
- **ctx.obj Attribute**: Application-defined state object passed to child commands
- **Inheritance**: Child commands automatically inherit parent's `ctx.obj`
- **Context Linking**: Contexts form linked list to parent contexts
- **Meta Dictionary**: Application-wide state storage across entire context chain
- **Access Pattern**: `@click.pass_context` decorator provides context to command functions
- **Multiple Objects**: Use dictionary for `ctx.obj` when managing multiple state types
- **Source**: click.palletsprojects.com/en/stable/complex/

#### Cobra (Go) Persistent Flags
- **Persistent Flags**: Available to command and all subcommands
- **Local Flags**: Only available to specific command
- **Access Pattern**: Use `cmd.Flags()` (not `cmd.PersistentFlags()`) to access all applicable flags
- **Configuration Hierarchy** (highest to lowest):
  1. Command-line flags
  2. Environment variables
  3. Configuration files
  4. Default values
- **Viper Integration**: Seamless config management with environment variable binding
- **12-Factor Pattern**: Environment variable binding enables 12-factor app compliance
- **Source**: cobra.dev, pkg.go.dev/github.com/spf13/cobra

### 7. Per-Invocation vs Per-Session Isolation

#### Per-Invocation (Stateless) Pattern
- **Characteristics**: Each invocation independent, no shared state
- **Configuration Sources**: Flags, environment variables, config files read per invocation
- **Examples**: Most traditional Unix tools (ls, grep, find)
- **Benefits**: Simple, predictable, no concurrency issues
- **Drawbacks**: Must re-specify context each invocation or rely on config files

#### Per-Session (Stateful) Pattern
- **Characteristics**: State maintained across multiple invocations
- **Examples**: tmux sessions, AWS SSO sessions, AgentCore sessions
- **Benefits**: Context preservation, multi-step workflows, no re-authentication
- **Drawbacks**: Session management complexity, potential staleness
- **Hybrid Approach**: File-based state (kubectl context) acts as persistent session state

### 8. State Sharing vs State Isolation Trade-offs

#### State Sharing (kubectl pattern)
- **Advantages**: Single source of truth, simple configuration
- **Disadvantages**: Multi-terminal race conditions, accidental context switches affect all terminals
- **Workaround**: Per-terminal environment variable override (`KUBECONFIG`)
- **Source**: sierrana.co.uk/posts/2024/2024-10-09/ (kubectl global state workaround)

#### State Isolation (Terraform workspace pattern)
- **Advantages**: Safe concurrent operations on different environments
- **Disadvantages**: More complex setup, potential for forgetting to switch workspace
- **Safety Mechanism**: State locking prevents concurrent modifications to same workspace
- **Visibility**: Explicit workspace selection required (`terraform workspace select`)

## Recommendations

### 1. Use File-Based State Persistence with Explicit Switching

**Pattern**: Emulate kubectl/docker context model for persistent state across invocations.

**Implementation**:
- Store state in XDG-compliant configuration file (`$XDG_CONFIG_HOME/tool/context.json`)
- Provide explicit commands to switch state: `tool context use <name>`
- Display current context in command output or via `tool context current`
- Support environment variable override for per-terminal isolation

**Benefits**:
- State survives shell exit (unlike bash `export`)
- Cross-terminal consistency by default
- Per-terminal override available when needed
- Familiar pattern to users of kubectl/docker

**Example Structure**:
```json
{
  "current_context": "development",
  "contexts": {
    "development": {
      "workspace": "/home/user/project-dev",
      "branch": "feature/new-feature"
    },
    "production": {
      "workspace": "/home/user/project-prod",
      "branch": "main"
    }
  }
}
```

### 2. Implement Configuration Hierarchy with Clear Precedence

**Pattern**: Follow Git/AWS CLI model of hierarchical configuration with explicit precedence.

**Precedence Order** (highest to lowest):
1. Command-line flags (`--workspace=/path`)
2. Environment variables (`TOOL_WORKSPACE=/path`)
3. Context-specific config (current context settings)
4. Global config file (`$XDG_CONFIG_HOME/tool/config.yml`)
5. Default values

**Benefits**:
- Predictable override behavior
- Per-invocation flexibility without affecting persistent state
- Environment variable integration for CI/CD
- Standard pattern familiar to developers

**Implementation Notes**:
- Document precedence clearly in help text
- Provide debug flag showing which source was used: `tool config show --source`

### 3. Add File Locking for Concurrent Access Safety

**Pattern**: Implement advisory file locking for configuration file modifications.

**Implementation**:
- Use `flock(2)` or `fcntl` for exclusive lock during writes
- Use shared locks for reads
- Timeout mechanism for stale locks (warn user after 5 seconds)
- Auto-retry with exponential backoff for brief conflicts

**Critical Operations Requiring Locks**:
- Context switching (`tool context use`)
- Configuration updates (`tool config set`)
- State modifications that other processes might read

**Benefits**:
- Prevents race conditions from concurrent CLI invocations
- Safe for parallel CI/CD pipelines
- Corruption prevention for critical state

**Reference Implementation**:
- Terraform state locking (DynamoDB backend)
- Git index locking (`.git/index.lock`)

### 4. Support Both Global and Per-Directory State (Git Model)

**Pattern**: Combine system-wide user preferences with project-specific overrides.

**File Locations**:
- **Global**: `$XDG_CONFIG_HOME/tool/config.yml` - user preferences, default context
- **Local**: `.tool/config.yml` in project directory - project-specific overrides
- **Precedence**: Local > Global (like Git)

**Use Cases**:
- Global: Default editor, user credentials, color preferences
- Local: Project-specific workspace paths, branch strategies, team conventions

**Benefits**:
- Natural separation of user vs project settings
- Teams can commit `.tool/config.yml` for shared project configuration
- Users can have personal overrides without affecting team config

**Implementation**:
- Search upward from current directory for `.tool/config.yml`
- Merge with global config (local overrides global)
- Provide `tool config --show-origin` to debug config sources

### 5. Provide State Visibility and Debugging Tools

**Pattern**: Make state transparent and debuggable for users.

**Recommended Commands**:
```bash
# Show current context and its settings
tool context current --verbose

# List all available contexts
tool context list

# Show effective configuration (after precedence resolution)
tool config show --effective

# Show configuration sources used
tool config show --source

# Validate configuration file syntax
tool config validate
```

**Benefits**:
- Users understand what state they're in
- Debugging configuration issues becomes straightforward
- Prevents accidental operations in wrong context
- Reduces support burden

**UX Enhancement**:
- Color-code current context in `tool context list`
- Show context in command prompt integration (like git branch)
- Warn when operating in unexpected context

### 6. Consider Session-Based State for Long-Running Operations

**Pattern**: For workflows requiring authentication or expensive setup, use session model.

**When to Use Sessions**:
- OAuth token refresh cycles
- Database connection pooling
- Expensive initialization (loading large datasets)
- Multi-step interactive workflows

**Implementation Options**:
1. **Daemon Process**: Background daemon maintains state (like docker daemon)
2. **Token Cache**: Store authentication tokens with expiration (like AWS SSO)
3. **State Files with TTL**: File-based state with timestamp validation

**Example (Token Cache)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1...",
  "expires_at": "2025-11-04T16:30:00Z",
  "refresh_token": "eyJ0eXAiOiJKV1..."
}
```

**Benefits**:
- Avoid re-authentication on every invocation
- Better user experience for authenticated tools
- Reduced API rate limiting issues

**Security Considerations**:
- Use platform keychain for sensitive tokens (macOS Keychain, Linux Secret Service)
- File permissions 0600 for token cache files
- Clear session data on explicit logout

### 7. Avoid Bash Export-Style Environment Variables for Persistent State

**Anti-Pattern**: Relying on `export VAR=value` for cross-invocation state.

**Problems**:
- Lost on shell exit
- Not available to other terminals
- Difficult to debug (invisible in `ps` output)
- No validation or error checking
- Concurrent shells have inconsistent state

**When Environment Variables ARE Appropriate**:
- CI/CD pipeline configuration (ephemeral, process-scoped)
- Per-invocation overrides (`TOOL_VERBOSE=1 tool command`)
- Standard variables (`HOME`, `USER`, `PATH`)
- Integration with other tools expecting env vars

**Better Alternatives**:
- Configuration files for persistent state
- Explicit context switching commands
- Session management with file-based state

### 8. Implement XDG Base Directory Compliance for Modern CLI Tools

**Pattern**: Follow XDG specification for clean, organized configuration.

**Directory Usage**:
```
$XDG_CONFIG_HOME/tool/          # Configuration files
  ├── config.yml                # Global configuration
  ├── contexts.json             # Context definitions
  └── plugins/                  # Plugin configuration

$XDG_STATE_HOME/tool/           # State data
  ├── current-context           # Current context name
  ├── history.log               # Command history
  └── session-tokens.json       # Authentication tokens

$XDG_CACHE_HOME/tool/           # Cache data
  ├── downloads/                # Downloaded artifacts
  └── index-cache.json          # API response cache

$XDG_RUNTIME_DIR/tool/          # Runtime files
  └── daemon.sock               # Unix domain socket
```

**Implementation**:
```bash
# Bash example
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tool"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tool"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tool"
```

**Benefits**:
- Clean home directory (no dot-file pollution)
- Standard locations for backups
- OS-specific cleanup policies
- Platform consistency

### 9. Provide Migration Path from Legacy State Storage

**Pattern**: Support gradual migration from old to new state management.

**Migration Strategy**:
1. **Detect Legacy State**: Check for old-style config on first run
2. **Auto-Migrate**: Offer to migrate with user confirmation
3. **Maintain Compatibility**: Support both formats during transition period
4. **Clear Deprecation**: Warn users about legacy format removal timeline
5. **Document Migration**: Provide clear migration guide

**Example Migration Prompt**:
```
⚠️  Legacy configuration detected at ~/.toolrc

Would you like to migrate to XDG-compliant configuration?
  New location: ~/.config/tool/config.yml

This will:
  - Copy settings to new location
  - Preserve legacy file (not deleted)
  - Use new location for future operations

Migrate now? [Y/n]
```

**Benefits**:
- Smooth user experience
- Reduced breaking changes
- Clear communication of improvements
- Maintains user trust

### 10. Document State Management Model Clearly

**Pattern**: Make state management behavior explicit in documentation.

**Required Documentation**:
1. **Conceptual Overview**: Explain contexts, configuration hierarchy, persistence model
2. **File Locations**: List all configuration files and their purposes
3. **Precedence Rules**: Explicit precedence order with examples
4. **Common Workflows**: Task-based guides (switching contexts, debugging config)
5. **Troubleshooting**: Common state-related issues and solutions

**Example Documentation Structure**:
```markdown
# State Management

## Overview
[tool] uses file-based contexts for persistent state across invocations...

## Configuration Files
- Global: ~/.config/tool/config.yml
- Local: .tool/config.yml (project-specific)
- Contexts: ~/.config/tool/contexts.json

## Precedence Order
1. Command flags (--flag)
2. Environment variables (TOOL_VAR)
3. Local config (.tool/config.yml)
4. Current context settings
5. Global config (~/.config/tool/config.yml)
6. Defaults

## Common Tasks
### Switching Contexts
...
```

**Benefits**:
- Users understand mental model
- Reduces configuration errors
- Enables self-service troubleshooting
- Improves onboarding experience

## References

### Web Sources
- Kubernetes Kubectl Documentation: https://kubernetes.io/docs/reference/kubectl/quick-reference/ (2025)
- Docker Context Management: https://docs.docker.com/engine/manage-resources/contexts/
- Terraform Workspaces: https://developer.hashicorp.com/terraform/language/state/workspaces
- Terraform State Locking: https://spacelift.io/blog/terraform-force-unlock
- Git Config Documentation: https://git-scm.com/docs/git-config
- AWS CLI Configuration: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
- XDG Base Directory Specification: https://specifications.freedesktop.org/basedir/latest/
- XDG Implementation Guide: https://xdgbasedirectoryspecification.com/
- File Locking Fundamentals: https://www.baeldung.com/linux/file-locking
- tmux Environment Variables: https://github.com/orgs/tmux/discussions/3997
- tmux-resurrect Plugin: https://github.com/tmux-plugins/tmux-resurrect
- Amazon Bedrock AgentCore Sessions: https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-sessions.html
- Click Context Management: https://click.palletsprojects.com/en/stable/complex/
- Cobra Persistent Flags: https://cobra.dev/
- Cobra Package Documentation: https://pkg.go.dev/github.com/spf13/cobra
- Session State Management Patterns: https://fastercapital.com/content/Persistence-Strategies--State-Management
- Kubectl Global State Workaround: https://sierrana.co.uk/posts/2024/2024-10-09/

### Local Codebase Files
The following files in `/home/benjamin/.config/.claude` contain state management and export-related code (76 files identified via grep pattern matching for export/state/persistence/context keywords):

- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint state management utilities
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Location detection and path resolution
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` - Workflow state initialization
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Logging with state persistence
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Metadata extraction and state
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh` - Artifact state management
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context state pruning utilities
- `/home/benjamin/.config/.claude/tests/test_state_management.sh` - State management tests

Note: These files demonstrate the .claude system's own state management approaches which could provide implementation insights for alternative patterns to bash export persistence.
