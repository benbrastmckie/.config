# MCP Server Setup Guide for NixOS

A guide to installing, configuring, and verifying [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers for [Claude Code](https://code.claude.com/) on NixOS. This guide covers the three MCP servers integrated into the Logos Laboratories project: Astro Docs, Context7, and Playwright.

**Last updated**: 2026-02-05
**NixOS version**: 24.11 (home-manager)
**Claude Code**: Latest (installed via `home.packages`)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Understanding MCP in Claude Code](#2-understanding-mcp-in-claude-code)
3. [Astro Docs MCP](#3-astro-docs-mcp)
4. [Context7 MCP](#4-context7-mcp)
5. [Playwright MCP (Deferred)](#5-playwright-mcp-deferred)
6. [Troubleshooting](#6-troubleshooting)
7. [Quick Reference](#7-quick-reference)

---

## 1. Prerequisites

### NixOS and Home-Manager

This guide assumes a NixOS system managed with [home-manager](https://nix-community.github.io/home-manager/) and a dotfiles repository at `~/.dotfiles/`. All software installation is declarative through Nix packages.

Your `~/.dotfiles/home.nix` should include:

```nix
home.packages = with pkgs; [
  claude-code   # Claude Code CLI
  nodejs        # Required for npx-based MCP servers
];
```

After modifying `home.nix`, rebuild with your update script (typically `~/.dotfiles/update.sh` or `home-manager switch`).

### Verify Node.js and npx

Node.js and npx are required for stdio-based MCP servers (Context7, Playwright). Verify they are available:

```bash
node --version    # Should output a version (e.g., v24.13.0)
npx --version     # Should output a version (e.g., 11.6.2)
which npx         # Should be a Nix profile path (e.g., /home/benjamin/.nix-profile/bin/npx)
```

### Configuration File Locations

| File | Scope | Purpose |
|------|-------|---------|
| `.mcp.json` (project root) | Project | MCP server definitions (version-controlled) |
| `.opencode/settings.json` (project) | Project | Permission auto-approval for MCP tools |
| `~/.claude.json` | User | Cross-project MCP servers (e.g., lean-lsp) |
| `~/.opencode/settings.json` | User | User-level permissions |

**NixOS note**: The user-level settings file (`~/.opencode/settings.json`) is symlinked by home-manager from `~/.dotfiles/config/claude-settings.json`. Any manual edits to `~/.opencode/settings.json` will be overwritten on the next `home-manager switch`. Always edit the source file at `~/.dotfiles/config/claude-settings.json` instead.

---

## 2. Understanding MCP in Claude Code

MCP (Model Context Protocol) lets Claude Code connect to external tool servers that provide specialized capabilities -- searching documentation, browsing web pages, querying databases, and more.

### Transport Types

| Type | How It Works | Example |
|------|-------------|---------|
| **HTTP** | Claude Code connects to a remote URL. No local software needed. | Astro Docs MCP |
| **stdio** | Claude Code spawns a local process and communicates via stdin/stdout. Requires a local command (e.g., `npx`). | Context7, Playwright |

### Configuration Scopes

MCP servers can be configured at three scopes. This project uses **project scope** for web-related servers:

| Scope | Config File | Version Controlled | Use Case |
|-------|------------|-------------------|----------|
| **Project** | `.mcp.json` | Yes | Team-shared servers (recommended) |
| **Local** | `~/.claude.json` (project path) | No | Personal/experimental servers |
| **User** | `~/.claude.json` (global) | No | Cross-project personal servers |

### Configuration Format

**HTTP server** (remote):
```json
{
  "mcpServers": {
    "server-name": {
      "type": "http",
      "url": "https://example.com/mcp"
    }
  }
}
```

**stdio server** (local process):
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name@latest"],
      "env": {
        "OPTIONAL_KEY": "value"
      }
    }
  }
}
```

### Adding Servers via CLI

Instead of editing `.mcp.json` manually, you can use the Claude Code CLI:

```bash
# Add an HTTP server
claude mcp add --transport http --scope project astro-docs https://mcp.docs.astro.build/mcp

# Add a stdio server
claude mcp add --transport stdio --scope project context7 -- npx -y @upstash/context7-mcp@latest

# Add a stdio server with environment variables
claude mcp add --transport stdio --scope project --env KEY=value server-name -- command args
```

### Managing Servers

```bash
claude mcp list                    # List all configured servers
claude mcp get <name>              # Get details for a specific server
claude mcp remove <name>           # Remove a server
claude mcp reset-project-choices   # Reset approval choices for project-scoped servers
```

Inside a Claude Code session, use `/mcp` to check server status and connectivity.

### Permission Auto-Approval

To avoid being prompted for permission every time an MCP tool is invoked, add wildcards to `.opencode/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__server-name__*",
      "Bash(npx *)"
    ]
  }
}
```

The `Bash(npx *)` entry is required for stdio servers that use `npx` as their command.

For more details, see the [Claude Code MCP documentation](https://code.claude.com/docs/en/mcp).

---

## 3. Astro Docs MCP

**Status**: Active
**Type**: HTTP (remote)
**Tools**: `search_astro_docs` (1 tool)
**Repository**: [withastro/docs-mcp](https://github.com/withastro/docs-mcp)

### Overview

Astro Docs MCP is a remote HTTP server hosted by the [Astro](https://astro.build/) team. It provides semantic search over the official Astro documentation, powered by [kapa.ai](https://www.kapa.ai/). Since it is a remote server, it requires zero local installation -- no binaries, no packages, no NixOS-specific configuration.

### Configuration

The server is already configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "astro-docs": {
      "type": "http",
      "url": "https://mcp.docs.astro.build/mcp"
    }
  }
}
```

Permission auto-approval is configured in `.opencode/settings.json`:

```json
"mcp__astro-docs__*"
```

### Verification

1. **Check server is listed**:
   ```bash
   claude mcp list
   ```
   You should see `astro-docs` with type `http`.

2. **Check server status in a session**:
   Inside a Claude Code session, type `/mcp`. The Astro Docs server should show as connected.

3. **Test the tool**:
   Ask Claude: "Search the Astro docs for content collections"

   Claude will invoke `mcp__astro-docs__search_astro_docs` and return relevant documentation results.

### NixOS Notes

- No NixOS-specific considerations. This server works identically on all platforms.
- The server is subject to upstream rate limits (not publicly documented).
- No authentication or API key required.

---

## 4. Context7 MCP

**Status**: Active
**Type**: stdio (local, via npx)
**Tools**: `resolve-library-id`, `query-docs` (2 tools)
**Repository**: [upstash/context7](https://github.com/upstash/context7)

### Overview

Context7 provides up-to-date documentation and code examples for any programming library. It uses a two-step workflow: first resolve a library name to a Context7 library ID, then query that library's documentation. The server runs locally via `npx`, requiring only Node.js.

### Prerequisites

Node.js must be installed via home-manager (see [Prerequisites](#1-prerequisites)). No additional NixOS packages are needed -- the `@upstash/context7-mcp` package is pure JavaScript and has no native binary dependencies.

### Configuration

The server is already configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

The `-y` flag auto-accepts npm package installation without prompting. On first invocation, npx downloads the package to `~/.npm/_npx/`. Subsequent runs use the cached version.

#### Optional: API Key for Higher Rate Limits

Context7 works without an API key, but you can register for a free key at the [Context7 dashboard](https://context7.com/dashboard) to get higher rate limits:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      }
    }
  }
}
```

Set the environment variable in `~/.dotfiles/home.nix`:

```nix
home.sessionVariables = {
  CONTEXT7_API_KEY = "your-api-key-here";
};
```

Then rebuild with `home-manager switch`.

### Verification

1. **Check server is listed**:
   ```bash
   claude mcp list
   ```
   You should see `context7` with type `stdio`.

2. **Check server status in a session**:
   Inside a Claude Code session, type `/mcp`. The Context7 server should show as connected.

3. **Test the two-step usage pattern**:

   **Step 1** -- Resolve a library ID:
   Ask Claude: "Use Context7 to find the library ID for Astro"

   Claude will invoke `mcp__context7__resolve-library-id` and return matching library IDs.

   **Step 2** -- Query documentation:
   Ask Claude: "Query Context7 for how to create content collections in Astro"

   Claude will invoke `mcp__context7__query-docs` with the resolved library ID.

### NixOS Notes

- npx works via the Nix-provided Node.js -- no special NixOS configuration needed.
- The package downloads to `~/.npm/_npx/`, which is a writable user directory.
- First invocation can be slow (5-10 seconds) due to the initial package download.
- No FHS or dynamic linking issues since the package is pure JavaScript.

---

## 5. Playwright MCP (Deferred)

**Status**: Deferred -- blocked by browser binary availability on NixOS
**Type**: stdio (local, via npx)
**Tools**: ~33 tools (browser automation, screenshots, form filling, etc.)
**Repository**: [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp)

### Overview

Playwright MCP provides browser automation capabilities: navigating web pages, taking screenshots, filling forms, clicking elements, and more. It requires a compatible browser binary (Chromium, Firefox, or WebKit) to be installed on the system.

### Why It Is Deferred on NixOS

NixOS does not follow the [Filesystem Hierarchy Standard (FHS)](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard). All libraries and binaries live in the Nix store (`/nix/store/...`) rather than at standard paths like `/usr/lib/`. This causes problems for Playwright because:

1. **`npx playwright install` fails**: Playwright downloads pre-built browser binaries that are dynamically linked against standard FHS paths (`/lib/x86_64-linux-gnu/`, etc.). These paths do not exist on NixOS, so the downloaded browsers crash immediately.

2. **System browsers are incompatible**: While browsers like Vivaldi or Brave may be installed system-wide, Playwright requires its own specific browser builds (chromium, firefox, webkit) with specific version-matched dependencies.

3. **The solution is Nix-packaged browsers**: NixOS provides `playwright-driver.browsers`, which contains Playwright-compatible browser binaries properly linked against Nix store paths.

### Solution Path: Home-Manager

When you are ready to enable Playwright MCP, add the following to `~/.dotfiles/home.nix`:

```nix
home.packages = with pkgs; [
  playwright-driver.browsers
];

home.sessionVariables = {
  PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
};
```

Then rebuild with your update script.

#### Environment Variables Explained

| Variable | Value | Purpose |
|----------|-------|---------|
| `PLAYWRIGHT_BROWSERS_PATH` | Nix store path to `playwright-driver.browsers` | Tells Playwright where to find browser binaries |
| `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS` | `true` | Bypasses host validation checks that fail on NixOS |
| `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD` | `1` | Prevents npm postinstall scripts from downloading incompatible binaries |

### Version Matching Requirement

**Critical**: The npm `@playwright/mcp` package version must be compatible with the `playwright-driver.browsers` version from nixpkgs. A version mismatch causes Playwright to look for browser revisions that do not exist in the Nix-provided browsers directory.

Check the nixpkgs version:

```bash
# Check which version of playwright-driver is available
nix eval nixpkgs#playwright-driver.version
```

As of February 2026, nixpkgs provides `playwright-driver` v1.57.0. Pin the npm package accordingly:

```json
{
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@1.57", "--headless"]
  }
}
```

If you use `@latest` instead of a pinned version, the npm package may expect newer browser builds than what nixpkgs provides, causing launch failures.

### MCP Configuration (When Ready)

Add to `.mcp.json` once browsers are installed:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"],
      "env": {
        "PLAYWRIGHT_BROWSERS_PATH": "${PLAYWRIGHT_BROWSERS_PATH}",
        "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS": "true"
      }
    }
  }
}
```

Note: `.mcp.json` supports `${VAR}` environment variable expansion, so `PLAYWRIGHT_BROWSERS_PATH` references the session variable set in `home.nix`.

Permission auto-approval is already configured in `.opencode/settings.json`:

```json
"mcp__playwright__*"
```

### Alternative: Nix Flake

A community Nix flake wraps Playwright MCP with NixOS-compatible browser handling. See [benjaminkitt/nix-playwright-mcp](https://github.com/benjaminkitt/nix-playwright-mcp):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "nix",
      "args": ["run", "github:benjaminkitt/nix-playwright-mcp"]
    }
  }
}
```

This bundles the browser binaries and environment variables into a single Nix derivation, avoiding version matching issues.

### Verification (When Browsers Available)

1. **Verify browser binaries exist**:
   ```bash
   ls $PLAYWRIGHT_BROWSERS_PATH/chromium-*/chrome-linux/chrome
   ```

2. **Test the MCP server manually**:
   ```bash
   npx -y @playwright/mcp@latest --headless
   ```
   It should start without errors and wait for stdin input. Press Ctrl+C to exit.

3. **Check in Claude Code**:
   ```bash
   claude mcp list
   ```
   Inside a session, use `/mcp` to verify connectivity.

4. **Test a tool**:
   Ask Claude: "Navigate to https://example.com and take a snapshot"

### Further Reading

- [NixOS Wiki: Playwright](https://wiki.nixos.org/wiki/Playwright) -- Official NixOS guide for Playwright setup
- [Configuring Claude Code Playwright MCP on NixOS](https://chili-it.de/posts/claude-code-playwright-nixos/) -- Community walkthrough for Claude Code integration
- [nix-playwright-mcp](https://github.com/benjaminkitt/nix-playwright-mcp) -- Community Nix flake for Playwright MCP

---

## 6. Troubleshooting

### npx: command not found

**Cause**: Node.js is not installed or not on `PATH`.

**Fix**: Ensure `nodejs` is in `home.packages` in `~/.dotfiles/home.nix`:

```nix
home.packages = with pkgs; [
  nodejs
];
```

Rebuild with `home-manager switch`, then verify:

```bash
which npx
npx --version
```

### Context7 is slow on first invocation

**Cause**: npx downloads the `@upstash/context7-mcp` package on first use (~5-10 seconds).

**Fix**: This is expected behavior. Subsequent invocations use the cached package at `~/.npm/_npx/` and start much faster. If the cache is cleared (e.g., by `npm cache clean`), the next invocation will re-download.

### MCP server not appearing in /mcp

**Cause**: `.mcp.json` may have a syntax error, or Claude Code has not re-read the configuration.

**Fix**:

1. Validate the JSON:
   ```bash
   jq . .mcp.json
   ```
   If jq reports an error, fix the JSON syntax.

2. Restart Claude Code -- it reads `.mcp.json` at startup.

3. Check the server list:
   ```bash
   claude mcp list
   ```

### MCP tool invocations are blocked by permissions

**Cause**: The MCP tool wildcard is missing from `.opencode/settings.json`.

**Fix**: Ensure the permission wildcards are present:

```json
{
  "permissions": {
    "allow": [
      "mcp__astro-docs__*",
      "mcp__context7__*",
      "mcp__playwright__*",
      "Bash(npx *)"
    ]
  }
}
```

### Playwright: browser launch fails on NixOS

**Cause**: Browser binaries are missing, or the `PLAYWRIGHT_BROWSERS_PATH` environment variable is not set, or the npm package version does not match the nixpkgs `playwright-driver.browsers` version.

**Fix**:

1. **Check if browsers are installed**:
   ```bash
   echo $PLAYWRIGHT_BROWSERS_PATH
   ls $PLAYWRIGHT_BROWSERS_PATH
   ```
   If the variable is empty or the directory does not exist, install `playwright-driver.browsers` via home-manager (see [Section 5](#5-playwright-mcp-deferred)).

2. **Check version alignment**:
   ```bash
   # Nixpkgs playwright-driver version
   nix eval nixpkgs#playwright-driver.version

   # npm @playwright/mcp version (check package.json or npm info)
   npm info @playwright/mcp version
   ```
   The major and minor versions should match. Pin the npm package version if they differ.

3. **Verify environment variables**:
   ```bash
   echo $PLAYWRIGHT_BROWSERS_PATH
   echo $PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS
   echo $PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD
   ```
   All three should be set. If not, check `home.sessionVariables` in `~/.dotfiles/home.nix`.

### Home-manager symlink overwrites manual edits

**Cause**: `~/.opencode/settings.json` is symlinked from `~/.dotfiles/config/claude-settings.json` by home-manager. Running `home-manager switch` overwrites any manual edits to the symlink target.

**Fix**: Always edit the source file at `~/.dotfiles/config/claude-settings.json`, then run `home-manager switch` to apply changes. Do not edit `~/.opencode/settings.json` directly.

Note: Project-level settings at `.opencode/settings.json` (inside the project directory) are NOT managed by home-manager and can be edited directly.

---

## 7. Quick Reference

| Server | Type | Status | Key Command | Config Key |
|--------|------|--------|-------------|------------|
| [Astro Docs](https://github.com/withastro/docs-mcp) | HTTP | Active | (none -- remote) | `astro-docs` |
| [Context7](https://github.com/upstash/context7) | stdio | Active | `npx -y @upstash/context7-mcp@latest` | `context7` |
| [Playwright](https://github.com/microsoft/playwright-mcp) | stdio | Deferred | `npx -y @playwright/mcp@latest --headless` | `playwright` |

### Key Files

| File | Purpose |
|------|---------|
| `.mcp.json` | Project-level MCP server definitions |
| `.opencode/settings.json` | Permission auto-approval wildcards |
| `~/.dotfiles/home.nix` | NixOS package installation (nodejs, playwright-driver.browsers) |
| `~/.dotfiles/config/claude-settings.json` | Source for user-level Claude settings (symlinked by home-manager) |

### Useful Commands

```bash
claude mcp list                    # List all MCP servers
claude mcp get <name>              # Get server details
claude mcp add ...                 # Add a new server
claude mcp remove <name>           # Remove a server
claude mcp reset-project-choices   # Reset approval choices
```

Inside a Claude Code session: `/mcp` to check server status.

### References

- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Astro Docs MCP (GitHub)](https://github.com/withastro/docs-mcp)
- [Context7 MCP (GitHub)](https://github.com/upstash/context7)
- [Context7 API Key Dashboard](https://context7.com/dashboard)
- [Playwright MCP (GitHub)](https://github.com/microsoft/playwright-mcp)
- [NixOS Wiki: Playwright](https://wiki.nixos.org/wiki/Playwright)
- [nix-playwright-mcp (GitHub)](https://github.com/benjaminkitt/nix-playwright-mcp)
- [Claude Code Playwright MCP on NixOS](https://chili-it.de/posts/claude-code-playwright-nixos/)
