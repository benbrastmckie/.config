# Multi-Instance Lean-LSP Optimization Guide

**Created**: 2026-01-28
**Purpose**: Reduce MCP AbortError -32001 timeouts when running multiple Claude Code sessions
**Audience**: Users running multiple concurrent Lean development sessions

---

## Overview

Running multiple concurrent Claude Code sessions with Lean-LSP MCP tools can cause AbortError -32001 timeouts due to resource contention. This guide documents prevention strategies and workflow optimizations.

### Root Cause

Multiple concurrent lean-lsp-mcp instances via STDIO transport create:
- Memory pressure from parallel `lake build` processes (can exceed 16GB)
- File locking contention on `.olean` files in shared `.lake/` cache
- CPU saturation from parallel compilation workers
- Diagnostic processing delays under concurrent load

**Reference Issues**:
- [lean-lsp-mcp #118](https://github.com/oOo0oOo/lean-lsp-mcp/issues/118) - Build concurrency exhausts memory
- [lean-lsp-mcp #115](https://github.com/oOo0oOo/lean-lsp-mcp/issues/115) - Diagnostic hang scenarios
- [Claude Code #6594](https://github.com/anthropics/claude-code/issues/6594) - Shared AbortController cascade

---

## Prevention Strategies

### 1. Pre-Build Project (Highest Impact)

**Run `lake build` before starting Claude sessions**:

```bash
cd /home/benjamin/Projects/ProofChecker
lake build
```

**Why this works**:
- Prevents concurrent `lake build` triggers when multiple agents start
- Eliminates timeout on first diagnostic call in each session
- Reduces memory pressure from parallel builds

**When to rebuild**:
- Morning startup or after pulling changes
- After making significant import changes
- After adding new dependencies

### 2. Configure Environment Variables

Add to `~/.claude.json` (user-scope MCP configuration):

```json
{
  "mcpServers": {
    "lean-lsp": {
      "command": "uvx",
      "args": ["lean-lsp-mcp"],
      "env": {
        "LEAN_LOG_LEVEL": "WARNING",
        "LEAN_PROJECT_PATH": "/home/benjamin/Projects/ProofChecker"
      }
    }
  }
}
```

**Benefits**:
- `LEAN_LOG_LEVEL: "WARNING"` reduces log I/O overhead
- Explicit `LEAN_PROJECT_PATH` prevents detection overhead across instances
- Consistent configuration across all sessions

### 3. Session Management Strategy

**Option A - Soft Throttling (Recommended)**:
- Keep all sessions open for different work
- When triggering Lean implementation agents, pause work in 3-4 other sessions
- Resume non-Lean work after agent completes
- Non-Lean work (general tasks, LaTeX, meta) unaffected

**Option B - Monitor and Respond**:
```bash
# Check active lean-lsp instances
ps aux | grep lean-lsp-mcp | wc -l

# If experiencing timeouts, temporarily reduce concurrent Lean operations
```

---

## Workflow Recommendations

### For Lean Implementation Tasks

1. **Before starting `/implement` on Lean task**:
   - Run `lake build` if project has been modified
   - Pause Lean work in other sessions
   - Allow 1-2 minutes for LSP to stabilize

2. **During Lean agent execution**:
   - Avoid starting new Lean tasks in other sessions
   - General/meta/LaTeX tasks in other sessions are fine

3. **After Lean agent completes**:
   - Resume Lean work in other sessions
   - Results are cached, subsequent operations faster

### For Research Tasks

Research agents using `lean_leansearch`, `lean_loogle`, etc. are less resource-intensive
than implementation agents. Multiple concurrent research tasks are generally safe.

---

## Monitoring

### Check Resource Usage

```bash
# Memory usage by lean processes
ps aux --sort=-%mem | grep -E '(lean|lake)' | head -10

# CPU usage
htop -p $(pgrep -d, -f 'lean|lake')

# Disk I/O on .lake directory
sudo iotop -p $(pgrep -d, -f 'lean|lake') 2>/dev/null || \
  iostat -x 1 | grep -A5 Device
```

### Identify Contention

If you see these symptoms, reduce concurrent sessions:
- lean-lsp calls consistently exceeding 30 seconds
- Memory usage spiking above 12GB
- Multiple `lake build` processes running simultaneously
- Diagnostic messages timing out repeatedly

---

## Expected Results

With optimization strategies applied:
- 60-80% reduction in timeout frequency
- Memory usage stays under 8GB (vs 16GB+ spikes)
- Diagnostic calls complete within 30s (vs 60s+ timeouts)
- Agents complete successfully without interruption

---

## Future Improvements

### Awaiting Upstream (lean-lsp-mcp #118)

The lean-lsp-mcp project is considering build queue functionality:
- Serialize concurrent builds instead of parallel execution
- Automatic coordination across instances
- Would eliminate need for manual pre-build

**Status**: Open issue, no implementation timeline yet.

### Potential SSE/HTTP Transport

Moving from STDIO to HTTP/SSE transport would allow:
- Single shared server process
- Built-in request queuing
- Connection pooling

**Status**: Would require lean-lsp-mcp changes, not currently planned.

---

## Related Documentation

- `.claude/context/core/patterns/mcp-tool-recovery.md` - Error recovery patterns
- `.claude/context/core/patterns/early-metadata-pattern.md` - Interruption handling
- `.claude/rules/error-handling.md` - Error types and recovery
- `.claude/CLAUDE.md` (MCP Server Configuration section) - MCP setup
