# History Expansion Disable Methods Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: Bash History Expansion Disable Methods (invocation and configuration)
- **Report Type**: Best practices and technical investigation
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

Bash history expansion occurs during early parsing, before shell syntax analysis and quote interpretation. This timing makes inline `set +H` ineffective for the same command line. Reliable solutions require pre-invocation configuration: (1) invoking bash with specific environment/options, (2) using POSIX mode restrictions, or (3) relying on non-interactive shell defaults. For automation tools like Claude Code, the recommended approach is ensuring bash invocations use non-interactive mode (which disables history expansion by default) or explicitly setting `BASH_ENV` to a script containing `set +H`.

## Findings

### 1. Why Inline `set +H` Fails

**Core Issue**: History expansion is performed immediately after a complete line is read, **before** the shell breaks it into words or recognizes shell syntax elements like quotes, command substitution, or pipelines.

**Source**: GNU Bash Manual - History Interaction
- Reference: https://www.gnu.org/software/bash/manual/html_node/History-Interaction.html
- Quote: "History expansion is performed immediately after a complete line is read, before the shell breaks it into words."

**Parsing Order**:
1. Line read from input
2. **History expansion processed** (! patterns expanded)
3. Shell syntax parsing (quotes, commands, etc.)
4. Command execution (where `set +H` would take effect)

**Example Failure**:
```bash
set +H; echo "Price is $10!"
# Fails: History expansion processes "!" before set +H executes
# Error: bash: !": event not found
```

**Why Same-Line Doesn't Work**: The shell never gets a chance to disable history expansion because the entire line (including the `set +H` command) is processed for history expansion before any command execution begins.

**Source**: Unix StackExchange - History expansion inside single quotes
- Reference: https://unix.stackexchange.com/questions/390931/bash-history-expansion-inside-single-quotes-after-a-double-quote-inside-the-sam
- Evidence: Bug report response acknowledging "History expansion is explicitly line-oriented, and always has been. There's not a clean way to make it aware of the shell's current quoting state."

### 2. Bash Invocation Options

**Option 1: Non-Interactive Shell Default Behavior**

Non-interactive shells (scripts, `-c` commands) **disable history expansion by default**.

**Source**: GNU Bash Manual - History Interaction
- Default: "This option is on by default when the shell is interactive"
- Inverse: Non-interactive shells do NOT perform history expansion by default

**Verification Method**:
```bash
# Check if history expansion is enabled
case $- in
  (*H*) echo "enabled" ;;
  (*) echo "disabled" ;;
esac
```

**Critical for Automation**: Most automation tools (CI/CD, subprocess execution, containerized scripts) run bash non-interactively, avoiding history expansion issues automatically.

**Option 2: Explicit Bash Invocation with Set Options**

The `set` builtin options can be specified when invoking bash:

**Source**: GNU Bash Manual - The Set Builtin
- Reference: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
- Quote: "All of the single-character shell options documented in the description of the set builtin command, including -o, can be used as options when the shell is invoked."

**Syntax**:
```bash
bash +H script.sh          # Disable history expansion via +H
bash +o histexpand script.sh  # Same using long-form option name
```

**Important**: The `+` prefix disables options (confusingly opposite to `set` where `-H` enables and `+H` disables).

**Option 3: POSIX Mode**

Running bash in POSIX mode modifies history expansion behavior:

**Source**: GNU Bash Manual - Bash POSIX Mode
- Reference: https://www.gnu.org/software/bash/manual/html_node/Bash-POSIX-Mode.html

**Behavior Change**: "The '!' character does not introduce history expansion within a double-quoted string, even if the histexpand option is enabled."

**Invocation**:
```bash
bash --posix script.sh
```

**Limitation**: POSIX mode doesn't fully disable history expansion - it only restricts behavior inside double-quoted strings. History expansion is still active in other contexts.

**Not Recommended**: Partial protection, doesn't solve the fundamental issue for unquoted or single-quoted contexts.

### 3. Environment Variable Approaches

**Option 1: BASH_ENV Variable**

For non-interactive shells, `BASH_ENV` specifies a startup script to execute before running commands.

**Source**: Unix StackExchange - BASH_ENV treatment
- Reference: https://unix.stackexchange.com/questions/590788/treatment-of-env-and-bash-env-in-bash-running-in-bash-and-sh-mode

**Mechanism**: If `BASH_ENV` is set when bash is invoked to execute a shell script, its value is expanded and used as the name of a startup file to read before executing the script.

**Usage Pattern**:
```bash
# Create startup script
echo "set +H" > /tmp/disable-history.sh

# Invoke bash with BASH_ENV
BASH_ENV=/tmp/disable-history.sh bash script.sh
```

**Advantages**:
- Executes before script parsing (solves timing issue)
- Works for non-interactive shells
- No script modification required

**Disadvantages**:
- Requires environment variable control
- Additional file dependency
- Not honored in privileged mode

**Option 2: SHELLOPTS Variable (Read-Only Limitation)**

`SHELLOPTS` is a colon-separated list of enabled shell options, including `histexpand`.

**Source**: Linux Bash Shell Scripting Tutorial
- Reference: https://bash.cyberciti.biz/guide/Setting_shell_options

**Critical Limitation**: SHELLOPTS is a **read-only** variable that cannot be set via export.

**Why It Fails**:
```bash
# This DOES NOT work
export SHELLOPTS=braceexpand:hashall  # Error: readonly variable

# SHELLOPTS is automatically populated based on current shell options
```

**Correct Understanding**: SHELLOPTS reflects current options but cannot be used to configure them. It's informational only.

### 4. Configuration File Approaches

**Option 1: .bashrc Modification**

For interactive shells, add `set +H` to shell startup files.

**Locations**:
- User-specific: `~/.bashrc`, `~/.bash_profile`
- System-wide: `/etc/profile.d/disable-history.sh`

**Example**:
```bash
# Add to ~/.bashrc
set +H  # Disable history expansion permanently
```

**Limitation**: Only affects interactive shells. Non-interactive shells don't source `.bashrc` by default.

**Option 2: .inputrc Configuration**

The `.inputrc` file configures readline library behavior, but does **not** control history expansion.

**Why It Doesn't Apply**: History expansion is a shell parser feature, not a readline input feature. `.inputrc` controls keybindings and completion, not parsing behavior.

**Conclusion**: .inputrc is NOT a solution for history expansion issues.

### 5. How Automation Tools Handle This

**CI/CD Systems (Jenkins, GitLab CI, GitHub Actions)**

**Pattern**: Execute commands via non-interactive bash invocations:
```bash
bash -c "command"
bash script.sh
```

**Result**: History expansion disabled by default (non-interactive shell).

**Source**: Stack Overflow - Why history command is default disabled for bash scripts
- Reference: https://stackoverflow.com/questions/45800345/why-history-command-is-default-disabled-for-bash-scripts
- Rationale: "For scripts, reading dotfiles for history would be pure startup-time overhead, with that content never used at runtime, making all shell scripts take longer to start up with no compensating benefit."

**Docker Exec**

**Pattern**: `docker exec container bash -c "command"`

**Behavior**: Creates non-interactive bash session by default (history expansion disabled).

**Exception**: `docker exec -it container bash` creates interactive session (history expansion enabled).

**Best Practice**: Avoid `-it` flags in automated scripts; use non-interactive exec.

**Python subprocess Module**

**Default Behavior**: `subprocess.run(["bash", "-c", "command"])` executes non-interactive bash.

**Source**: Python Documentation - subprocess module
- Reference: https://docs.python.org/3/library/subprocess.html

**Result**: History expansion automatically disabled.

**Alternative for Interactive Features**: Use `subprocess.run(["bash", "-i", "-c", "command"])` to force interactive mode (enables history expansion).

**Ansible Shell Module**

**Pattern**: Uses `/bin/sh` or specified shell executable.

**Best Practice**: Prefer `command` module over `shell` module to avoid shell expansion issues entirely.

**Source**: Ansible Documentation - command-instead-of-shell lint rule
- Reference: https://ansible.readthedocs.io/projects/lint/rules/command-instead-of-shell/
- Guidance: "Shell is considerably slower than command and should be avoided unless there is a special need for using shell features"

### 6. Heredoc Workaround

**Quoted Heredoc Delimiters** disable expansions (including history expansion):

```bash
cat <<'EOF'
This exclamation mark won't expand: !history
Price is $10!
EOF
```

**Mechanism**: Quoting the delimiter (single or double quotes) disables:
- Parameter expansion ($var)
- Command substitution $(cmd)
- History expansion (!)

**Source**: Linux Documentation - Here Documents
- Reference: https://tldp.org/LDP/abs/html/here-docs.html

**Use Case**: Passing complex strings with special characters through bash without expansion.

**Limitation**: Only applicable to heredoc contexts, not general command execution.

## Recommendations

### 1. For Claude Code / SlashCommand Tool (Primary Recommendation)

**Verify Non-Interactive Invocation**

**Action**: Confirm that the Bash tool in Claude Code invokes bash in non-interactive mode by default.

**Test**:
```bash
# Run this via Claude Code Bash tool to check interactivity
case $- in
  (*i*) echo "INTERACTIVE (history expansion enabled by default)" ;;
  (*) echo "NON-INTERACTIVE (history expansion disabled by default)" ;;
esac

# Also check history expansion specifically
case $- in
  (*H*) echo "histexpand ENABLED" ;;
  (*) echo "histexpand DISABLED" ;;
esac
```

**Expected Result**: NON-INTERACTIVE with histexpand DISABLED.

**If Interactive**: This would explain the history expansion errors. Solution: Modify Claude Code to invoke bash non-interactively.

**If Already Non-Interactive**: The errors may be caused by a different mechanism (e.g., explicit `-i` flag, forced interactive mode, or shell configuration files being sourced).

### 2. For /coordinate Command Script Generation (Immediate Fix)

**Use Quoted Heredoc Delimiters**

**Problem**: Coordinate command generates bash scripts containing exclamation marks in strings.

**Solution**: When generating bash commands via heredoc, always quote the delimiter:

**Before (Problematic)**:
```bash
cat <<EOF > script.sh
echo "Price is $10!"
EOF
```

**After (Fixed)**:
```bash
cat <<'EOF' > script.sh
echo "Price is $10!"
EOF
```

**Implementation**: Update coordinate.md Phase 0 and all script generation points to use `<<'EOF'` instead of `<<EOF`.

**Verification**:
- File: /home/benjamin/.config/.claude/commands/coordinate.md
- Search for: `<<EOF`, `<<SCRIPT`, `<<BASH`
- Replace with quoted versions: `<<'EOF'`, `<<'SCRIPT'`, `<<'BASH'`

### 3. For Robustness Across All Commands (Defense in Depth)

**Add Explicit History Expansion Disable**

Even if bash is non-interactive, add explicit protection as defense-in-depth:

**Method A: Per-Script Header**
```bash
#!/bin/bash
set +H  # Disable history expansion
# ... rest of script
```

**Method B: BASH_ENV for Generated Scripts**

Create a bash configuration file with safety settings:
```bash
# File: .claude/config/bash-safe.sh
set +H          # Disable history expansion
set -e          # Exit on error
set -u          # Error on undefined variables
set -o pipefail # Propagate pipe failures
```

Invoke generated scripts with:
```bash
BASH_ENV=.claude/config/bash-safe.sh bash script.sh
```

**Tradeoffs**:
- Method A: Simpler, but requires modifying script content
- Method B: Cleaner separation, but requires BASH_ENV control

### 4. For Diagnostic and Verification (Recommended Testing)

**Create Test Suite for History Expansion Handling**

**Purpose**: Verify that bash invocations correctly handle special characters.

**Test Cases**:
```bash
# Test 1: Exclamation marks in strings
echo "Price is $10!"

# Test 2: Multiple exclamation marks
echo "Error!!! Failed!"

# Test 3: Exclamation in different quote contexts
echo 'Single quotes: $10!'
echo "Double quotes: $10!"

# Test 4: Heredoc with exclamations
cat <<'EOF'
Multiple special chars: $10! $20! $30!
EOF

# Test 5: Complex command with pipes and exclamations
echo "Data!" | grep -v "Filter!"
```

**Implementation**: Add to `.claude/tests/test_bash_history_expansion.sh`

**Expected Result**: All tests pass without "event not found" errors.

### 5. For Documentation and Standards (Long-term)

**Update CLAUDE.md with Bash Invocation Standards**

**Addition to Code Standards Section**:

```markdown
### Bash Script Generation Standards

**History Expansion Safety**:
- ALWAYS use quoted heredoc delimiters: `<<'EOF'` not `<<EOF`
- Verify bash invocations are non-interactive (history expansion disabled by default)
- For generated scripts, include `set +H` in shebang block as defense-in-depth
- Test all script generation with strings containing `!` characters

**Rationale**: History expansion occurs during parsing, before execution. Quoted heredocs and non-interactive shells prevent expansion issues.
```

**File**: /home/benjamin/.config/CLAUDE.md
**Section**: code_standards

### 6. Immediate Action Items (Priority Order)

**Priority 1 - Diagnostic** (Do First):
1. Run interactivity check via Claude Code Bash tool (Recommendation 1)
2. Determine if bash is interactive or non-interactive
3. Document findings in diagnostic report

**Priority 2 - Quick Fix** (If errors persist):
1. Update coordinate.md to use quoted heredoc delimiters (Recommendation 2)
2. Search for all `<<EOF` patterns in .claude/commands/
3. Replace with `<<'EOF'` where script content contains special characters

**Priority 3 - Robust Solution** (If bash is interactive):
1. Modify Claude Code Bash tool invocation to force non-interactive mode
2. OR implement BASH_ENV approach (Recommendation 3, Method B)
3. Add test suite (Recommendation 4)

**Priority 4 - Long-term** (After fix verified):
1. Update CLAUDE.md standards (Recommendation 5)
2. Audit all commands for heredoc patterns
3. Establish lint rule for unquoted heredocs

## References

### Official Documentation
- GNU Bash Manual - History Interaction: https://www.gnu.org/software/bash/manual/html_node/History-Interaction.html
- GNU Bash Manual - The Set Builtin: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
- GNU Bash Manual - Bash POSIX Mode: https://www.gnu.org/software/bash/manual/html_node/Bash-POSIX-Mode.html
- Python Documentation - subprocess module: https://docs.python.org/3/library/subprocess.html
- Linux Documentation - Here Documents: https://tldp.org/LDP/abs/html/here-docs.html

### Stack Exchange and Community Resources
- Unix StackExchange - Is history expansion disabled in scripts?: https://unix.stackexchange.com/questions/384861/is-history-expansion-disabled-in-scripts
- Unix StackExchange - History expansion inside single quotes: https://unix.stackexchange.com/questions/390931/bash-history-expansion-inside-single-quotes-after-a-double-quote-inside-the-sam
- Unix StackExchange - BASH_ENV treatment: https://unix.stackexchange.com/questions/590788/treatment-of-env-and-bash-env-in-bash-running-in-bash-and-sh-mode
- Stack Overflow - Why history command is default disabled for bash scripts: https://stackoverflow.com/questions/45800345/why-history-command-is-default-disabled-for-bash-scripts
- Stack Overflow - How to escape history expansion exclamation mark: https://stackoverflow.com/questions/22125658/how-can-i-escape-history-expansion-exclamation-mark-inside-a-double-quoted-str

### Tool-Specific Resources
- Ansible Documentation - command-instead-of-shell lint rule: https://ansible.readthedocs.io/projects/lint/rules/command-instead-of-shell/
- Linux Bash Shell Scripting Tutorial - Setting shell options: https://bash.cyberciti.biz/guide/Setting_shell_options
- Linux Bash Shell Scripting Tutorial - Histexpand: https://bash.cyberciti.biz/guide/Histexpand

### Project Files
- /home/benjamin/.config/.claude/commands/coordinate.md - Primary command requiring heredoc fixes
- /home/benjamin/.config/.claude/commands/supervise.md - Secondary command with bash invocations
- /home/benjamin/.config/CLAUDE.md - Project standards documentation (target for updates)
