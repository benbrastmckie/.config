# MCP Tools Guide for Lean 4 Development

## Overview

This guide describes the MCP (Model Context Protocol) tools available for Lean 4 development in the ProofChecker system. MCP tools provide real-time proof verification, theorem search, and project exploration capabilities.

## Available MCP Servers

### 1. lean-lsp-mcp (Proof Verification)

**Purpose**: Real-time interaction with Lean Language Server

**Status**: [YELLOW] Partial (wrapper implemented, MCP integration pending)

**When to Use**:
- Validating proofs incrementally during implementation
- Getting current proof state at any position
- Diagnosing compilation errors in real-time
- Obtaining type information for expressions
- Getting hover documentation

**Key Functions**:
- `getProofState(file, line, col)` - Get current goals and hypotheses
- `checkProof(file, proof_text)` - Validate proof without writing file
- `getDiagnostics(file)` - Get errors, warnings, info messages
- `getHover(file, line, col)` - Get type and documentation info

**Example Usage**:
```typescript
import { createLSPClient } from './.claude/tool/mcp/index.js';

const lsp = createLSPClient();

// During proof implementation:
// 1. Write tactic line
const result = await lsp.getProofState('file.lean', { line: 45, column: 10 });

// 2. Check new proof state
if (result.success) {
  console.log('Goals:', result.data.goals);
  console.log('Hypotheses:', result.data.hypotheses);
}

// 3. Get diagnostics to check for errors
const diagnostics = await lsp.getDiagnostics('file.lean');

// 4. Proceed only if no errors
if (diagnostics.success) {
  const errors = diagnostics.data.filter(d => d.severity === 'error');
  if (errors.length === 0) {
    // Continue with next step
  }
}
```

**Benefits**:
- Catch errors immediately without full compilation
- See proof state after each tactic
- Get suggestions from LSP
- Faster iteration cycle

**Limitations** (Current):
- MCP protocol integration not yet complete
- Fallback to full compilation when unavailable
- Cache may become stale if file changes externally

### 2. LeanExplore (Structure Exploration)

**Purpose**: Explore Lean project structure and dependencies

**Status**: [RED] Planned (not yet implemented)

**When to Use**:
- Understanding Mathlib organization
- Finding related theorems in a namespace
- Analyzing theorem dependencies
- Discovering available type class instances
- Navigating module hierarchy

**Key Functions** (Planned):
- `exploreModule(name)` - List all contents of a module
- `exploreDependencies(theorem)` - Find what a theorem depends on
- `exploreUsages(theorem)` - Find where a theorem is used
- `exploreNamespace(ns)` - Navigate namespace hierarchy

**Example Usage** (Planned):
```typescript
// To understand a Mathlib area:
const explorer = createExploreClient();

// 1. Explore namespace
const contents = await explorer.exploreNamespace('Topology.MetricSpace');

// 2. Review definitions and theorems
console.log('Definitions:', contents.data.definitions);
console.log('Theorems:', contents.data.theorems);

// 3. Explore dependencies for key theorems
const deps = await explorer.exploreDependencies('dist_triangle');

// 4. Build mental model of the area
```

**Benefits** (When Implemented):
- Understand Mathlib structure quickly
- Find related theorems efficiently
- Analyze proof dependencies
- Discover available instances

### 3. Loogle (Type-based Search)

**Purpose**: Search theorems by type signature and patterns

**Status**: [RED] Planned (not yet implemented)

**When to Use**:
- Finding theorems with specific type signatures
- Searching for lemmas matching a pattern
- Goal-directed theorem discovery
- Finding theorems that could prove current goal

**Key Functions** (Planned):
- `searchByType(pattern)` - Find theorems matching type pattern
- `searchByPattern(pattern)` - Pattern-based search
- `searchUnify(goal)` - Find theorems that unify with goal

**Pattern Syntax** (Planned):
- `?a`, `?b` - Pattern variables
- `_` - Wildcard
- Exact type signatures

**Example Usage** (Planned):
```typescript
const loogle = createLoogleClient();

// To find commutativity theorems:
const results = await loogle.searchByPattern('?a * ?b = ?b * ?a');

// To find theorems about sqrt:
const sqrtTheorems = await loogle.searchByType(
  '∀ x : ℝ, x ≥ 0 → sqrt x * sqrt x = x'
);

// To find theorems for current goal:
const applicable = await loogle.searchUnify('a + b = b + a');
```

**Benefits** (When Implemented):
- Find exact theorems needed
- Discover lemmas by type
- Pattern-based discovery
- Goal-directed search

### 4. LeanSearch (Semantic Search)

**Purpose**: Natural language semantic search over Mathlib

**Status**: [RED] Planned (not yet implemented)

**When to Use**:
- Initial exploration of unfamiliar areas
- Finding theorems without knowing exact terminology
- Discovering related mathematical concepts
- Broad conceptual search

**Key Functions** (Planned):
- `searchSemantic(query)` - Natural language search
- `searchSimilar(theorem)` - Find similar theorems
- `searchConcept(concept)` - Search by mathematical concept

**Example Usage** (Planned):
```typescript
const search = createSearchClient();

// Natural language queries:
const results = await search.searchSemantic(
  'theorems about continuity of square root function'
);

const cauchy = await search.searchSemantic(
  'Cauchy sequences in metric spaces'
);

const compact = await search.searchConcept('compactness');
```

**Benefits** (When Implemented):
- Find theorems without exact terminology
- Discover related concepts
- Exploratory search
- Semantic understanding

## Search Strategy Decision Tree

```
START: Need to find a theorem

├─ Do you know the exact type signature?
│  YES → Use Loogle (type-based search)
│  NO → Continue
│
├─ Do you know the general pattern?
│  YES → Use Loogle (pattern search)
│  NO → Continue
│
├─ Do you know the mathematical concept?
│  YES → Use LeanSearch (semantic search)
│  NO → Continue
│
└─ Exploring a general area?
   YES → Use LeanExplore (namespace exploration)
   NO → Use LeanSearch (broad semantic search)
```

## Multi-Tool Search Strategy

For comprehensive searches, use multiple tools in sequence:

1. **Start Broad**: LeanSearch with natural language
2. **Refine**: LeanExplore to understand namespace structure
3. **Precise**: Loogle for exact type matches
4. **Verify**: lean-lsp to check if theorem applies

## Integration with Agents

### Researcher Agent
- Uses all search tools (Loogle, LeanSearch, LeanExplore)
- Merges results from multiple sources
- Ranks by relevance and confidence

### Implementer Agent
- Uses lean-lsp for incremental validation
- Validates each tactic before proceeding
- Gets proof state after each step

### Planner Agent
- Uses Loogle for type-guided planning
- Uses LeanExplore for dependency analysis
- Builds proof strategy from available theorems

### Reviser Agent
- Uses lean-lsp for error diagnosis
- Uses LeanSearch to find similar successful proofs
- Generates specific revision recommendations

## Agent Integration Guide

### How to Invoke MCP Tools from Agents

Agents invoke MCP tools using the Python client wrapper located at `.claude/tool/mcp/client.py`.

#### Import MCP Client

```python
from opencode.tool.mcp.client import check_mcp_server_configured, invoke_mcp_tool
```

#### Check Tool Availability

Before invoking MCP tools, check if the server is configured:

```python
# Check if lean-lsp server is available
mcp_available = check_mcp_server_configured("lean-lsp")

if mcp_available:
    # Use MCP tools
    pass
else:
    # Fall back to alternative approach
    pass
```

#### Invoke MCP Tools

Use `invoke_mcp_tool()` to call any MCP tool:

```python
result = invoke_mcp_tool(
    server="lean-lsp",           # MCP server name from .mcp.json
    tool="lean_diagnostic_messages",  # Tool name
    arguments={"file_path": "Logos/Core/Theorem.lean"},  # Tool arguments
    timeout=30                   # Timeout in seconds (default: 30)
)

# Check result
if result["success"]:
    # Tool invocation succeeded
    data = result["result"]
    # Process data
else:
    # Tool invocation failed
    error = result["error"]
    # Handle error
```

### Available Tools by Agent

#### lean-implementation-agent

**Primary Tools**:
- `lean_diagnostic_messages` - Check for compilation errors
- `lean_goal` - Get proof state at position
- `lean_run_code` - Test code snippet
- `lean_build` - Rebuild project

**Usage Pattern**:
1. Write Lean code
2. Call `lean_diagnostic_messages` to check for errors
3. If errors: Analyze and fix
4. Iterate until compilation succeeds

#### lean-research-agent

**Primary Tools**:
- `lean_loogle` - Type-based search (if not using local CLI)
- `lean_leansearch` - Natural language search
- `lean_local_search` - Local project search
- `lean_hover_info` - Get documentation

**Usage Pattern**:
1. Formulate search query
2. Call appropriate search tool
3. Parse and rank results
4. Return relevant theorems

### Tool Invocation Examples

#### Example 1: Check Compilation Errors

```python
from opencode.tool.mcp.client import invoke_mcp_tool

# Check diagnostics for a Lean file
result = invoke_mcp_tool(
    server="lean-lsp",
    tool="lean_diagnostic_messages",
    arguments={"file_path": "Logos/Core/Theorem.lean"}
)

if result["success"]:
    diagnostics = result["result"]
    
    # Filter by severity (1=error, 2=warning, 3=info)
    errors = [d for d in diagnostics if d.get("severity") == 1]
    warnings = [d for d in diagnostics if d.get("severity") == 2]
    
    if errors:
        print(f"Found {len(errors)} errors:")
        for error in errors:
            line = error["range"]["start"]["line"]
            message = error["message"]
            print(f"  Line {line}: {message}")
    else:
        print("No compilation errors")
else:
    print(f"Error: {result['error']}")
```

#### Example 2: Get Proof Goal

```python
# Get proof state at specific position
result = invoke_mcp_tool(
    server="lean-lsp",
    tool="lean_goal",
    arguments={
        "file_path": "Logos/Core/Theorem.lean",
        "line": 45,
        "column": 10
    }
)

if result["success"]:
    goal_state = result["result"]
    print(f"Goals: {goal_state.get('goals', [])}")
    print(f"Hypotheses: {goal_state.get('hypotheses', [])}")
else:
    print(f"Error: {result['error']}")
```

#### Example 3: Run Code Snippet

```python
# Test a code snippet without writing to file
result = invoke_mcp_tool(
    server="lean-lsp",
    tool="lean_run_code",
    arguments={
        "code": "theorem test : True := trivial"
    }
)

if result["success"]:
    output = result["result"]
    print(f"Code execution result: {output}")
else:
    print(f"Error: {result['error']}")
```

#### Example 4: Search with Loogle

```python
# Type-based search using lean_loogle
result = invoke_mcp_tool(
    server="lean-lsp",
    tool="lean_loogle",
    arguments={
        "query": "?a + ?b = ?b + ?a"
    }
)

if result["success"]:
    results = result["result"]
    print(f"Found {len(results)} theorems:")
    for theorem in results[:5]:  # Top 5 results
        print(f"  - {theorem['name']}: {theorem['type']}")
else:
    print(f"Error: {result['error']}")
```

#### Example 5: Natural Language Search

```python
# Semantic search using lean_leansearch
result = invoke_mcp_tool(
    server="lean-lsp",
    tool="lean_leansearch",
    arguments={
        "query": "theorems about continuity of functions"
    }
)

if result["success"]:
    results = result["result"]
    for theorem in results[:10]:  # Top 10 results
        print(f"  - {theorem['name']}")
        print(f"    {theorem['docstring']}")
else:
    print(f"Error: {result['error']}")
```

### Error Handling Patterns

#### Pattern 1: Graceful Degradation

```python
from opencode.tool.mcp.client import check_mcp_server_configured, invoke_mcp_tool

# Check availability first
if check_mcp_server_configured("lean-lsp"):
    # Use MCP tool
    result = invoke_mcp_tool(
        server="lean-lsp",
        tool="lean_diagnostic_messages",
        arguments={"file_path": "file.lean"}
    )
    
    if result["success"]:
        # Process result
        pass
    else:
        # MCP tool failed - fall back
        print(f"MCP tool failed: {result['error']}")
        # Use alternative approach (e.g., lake build)
else:
    # MCP not available - fall back
    print("lean-lsp-mcp not available, using lake build")
    # Use alternative approach
```

#### Pattern 2: Retry on Timeout

```python
def invoke_with_retry(server, tool, arguments, max_retries=2):
    """Invoke MCP tool with retry on timeout."""
    for attempt in range(max_retries):
        result = invoke_mcp_tool(
            server=server,
            tool=tool,
            arguments=arguments,
            timeout=30
        )
        
        if result["success"]:
            return result
        
        # Check if timeout error
        if "timeout" in result["error"].lower():
            if attempt < max_retries - 1:
                print(f"Timeout, retrying ({attempt + 1}/{max_retries})...")
                continue
        
        # Non-timeout error or max retries reached
        return result
    
    return result
```

#### Pattern 3: Error Logging

```python
import json
from pathlib import Path

def log_mcp_error(error_message, error_code="MCP_ERROR"):
    """Log MCP tool error to errors.json."""
    errors_file = Path(".claude/errors.json")
    
    error_entry = {
        "type": "mcp_tool_error",
        "code": error_code,
        "message": error_message,
        "timestamp": datetime.now().isoformat()
    }
    
    # Append to errors.json
    if errors_file.exists():
        with open(errors_file, 'r') as f:
            errors = json.load(f)
    else:
        errors = []
    
    errors.append(error_entry)
    
    with open(errors_file, 'w') as f:
        json.dump(errors, f, indent=2)

# Usage
result = invoke_mcp_tool(...)
if not result["success"]:
    log_mcp_error(result["error"], "MCP_TOOL_UNAVAILABLE")
```

### Troubleshooting MCP Tool Invocation

#### Issue 1: Server Not Configured

**Error**: `MCP server 'lean-lsp' not configured or unavailable`

**Solutions**:
1. Check `.mcp.json` exists in project root
2. Verify `lean-lsp` server is configured in `.mcp.json`
3. Check `uvx` command is available: `which uvx`
4. Install lean-lsp-mcp: `uvx lean-lsp-mcp`

#### Issue 2: Tool Not Found

**Error**: `Tool 'lean_diagnostic_messages' not found`

**Solutions**:
1. Verify tool name is correct (check lean-lsp-mcp documentation)
2. Check lean-lsp-mcp version: `uvx lean-lsp-mcp --version`
3. Update lean-lsp-mcp: `uvx --reinstall lean-lsp-mcp`

#### Issue 3: Timeout

**Error**: `MCP tool invocation timed out`

**Solutions**:
1. Increase timeout: `invoke_mcp_tool(..., timeout=60)`
2. Check if Lean LSP server is responsive
3. Restart Lean LSP server
4. Check system resources (CPU, memory)

#### Issue 4: Invalid Arguments

**Error**: `Invalid arguments for tool`

**Solutions**:
1. Check tool documentation for required arguments
2. Verify argument types (string, int, dict, etc.)
3. Ensure file paths are absolute or relative to project root
4. Check argument names match tool specification

### Difference Between CLI Tools and MCP Tools

#### CLI Tools (e.g., Loogle CLI)

**Approach**: Direct subprocess management

```python
import subprocess

# Start Loogle CLI process
process = subprocess.Popen(
    ["/path/to/loogle", "--json", "--interactive"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE
)

# Send query
process.stdin.write("?a + ?b = ?b + ?a\n")
process.stdin.flush()

# Read response
response = process.stdout.readline()
result = json.loads(response)
```

**Characteristics**:
- Direct process control
- Custom communication protocol
- Manual lifecycle management
- Hardcoded binary paths

#### MCP Tools (e.g., lean-lsp-mcp)

**Approach**: MCP protocol via client wrapper

```python
from opencode.tool.mcp.client import invoke_mcp_tool

# Invoke MCP tool
result = invoke_mcp_tool(
    server="lean-lsp",
    tool="lean_loogle",
    arguments={"query": "?a + ?b = ?b + ?a"}
)
```

**Characteristics**:
- Standardized MCP protocol
- Configuration via .mcp.json
- Automatic lifecycle management
- Multiple transport options (stdio, HTTP, SSE)

**When to Use Each**:
- **CLI Tools**: When tool has no MCP server, need direct control, or custom protocol
- **MCP Tools**: When tool has MCP server, want standardized interface, or need multiple transports

## Best Practices

1. **Always validate with LSP** before writing files
2. **Use type search first** when you know the signature
3. **Combine search tools** for comprehensive results
4. **Explore namespaces** to understand structure
5. **Check dependencies** before using complex theorems
6. **Verify incrementally** during proof construction

## Error Handling

If MCP tool unavailable:
- **lean-lsp** → Fall back to full compilation
- **Loogle** → Fall back to grep-based search
- **LeanSearch** → Fall back to keyword search
- **LeanExplore** → Fall back to manual file reading

## Performance Considerations

- **LSP queries**: Fast (< 100ms), use liberally
- **Loogle searches**: Moderate (< 1s), cache results
- **LeanSearch**: Slower (1-3s), use for initial exploration
- **LeanExplore**: Fast (< 500ms), good for navigation

## Implementation Status

### Phase 1: Foundation (Current)
- [PASS] Type definitions created
- [PASS] Error handling framework created
- [PASS] LSP client wrapper created (basic)
- [PASS] MCP tools guide created
- ⏳ MCP protocol integration (pending)

### Phase 2: Additional Clients (Planned)
- ⬜ LeanExplore client
- ⬜ Loogle client
- ⬜ LeanSearch client

### Phase 3: Integration (Planned)
- ⬜ Connect LSP to actual lean-lsp-mcp server
- ⬜ Implement MCP protocol communication
- ⬜ Add comprehensive error handling
- ⬜ Add performance monitoring

## Troubleshooting

### LSP Client Not Working

**Problem**: LSP operations return "not available" errors

**Solutions**:
1. Check if lean-lsp-mcp is installed: `uvx lean-lsp-mcp`
2. Verify `.mcp.json` configuration
3. Check MCP server logs
4. Fall back to full compilation

### Slow Response Times

**Problem**: MCP operations are slow

**Solutions**:
1. Enable caching: `useCache: true`
2. Increase cache TTL: `cacheTTL: 120000`
3. Check network/server load
4. Clear expired cache entries

### Stale Cache

**Problem**: Cache returns outdated results

**Solutions**:
1. Reduce cache TTL
2. Clear cache manually: `lsp.clearCache()`
3. Disable cache for critical operations

## References

- [MCP Integration Plan](../../specs/mcp-integration-plan.md)
- [MCP Integration Checklist](../../specs/mcp-integration-checklist.md)
- [MCP Tools README](../../tool/mcp/README.md)
- [TypeScript Type Definitions](../../tool/mcp/types.ts)

## Version

**Version**: 0.1.0  
**Last Updated**: 2025-12-15  
**Status**: Phase 1 - Foundation Complete
