# Current Path Resolution Analysis

## Research Metadata
- **Topic**: Current Path Resolution Implementation in /research Command
- **Status**: Complete
- **Created**: 2025-10-23
- **Agent**: research-specialist

## Executive Summary
The /research command currently uses a multi-step bash-heavy path resolution process requiring 6+ bash invocations and 3+ file system traversals. Topic directory discovery uses find with process substitution and while loops in template-integration.sh (lines 211-228, 242-250). The get_next_artifact_number function in artifact-creation.sh (lines 134-157) requires a full directory scan with glob expansion and basename operations per file. This approach consumes significant tokens and introduces latency during orchestration workflows.

## Findings

### Finding 1: Multi-Step Path Calculation with Heavy Bash Dependencies

**Location**: /home/benjamin/.config/.claude/commands/research.md:77-130

The STEP 2 path pre-calculation process requires the following bash operations:

1. **Topic Extraction** (research.md:84): `extract_topic_from_question "$RESEARCH_TOPIC"`
   - Calls sed with regex stop-word removal
   - Applies tr for case conversion and character filtering
   - Uses awk for keyword extraction (up to 3 words)
   - Result: 4 subprocess invocations

2. **Topic Directory Lookup** (research.md:87): `find_matching_topic "$TOPIC_DESC"`
   - Calls find with maxdepth 1 to scan specs directory (template-integration.sh:228)
   - Uses while IFS read loop with process substitution to iterate directories
   - Each iteration: basename, sed, tr, string comparison operations
   - Result: 1 find + N directory operations (where N = existing topic count)

3. **Topic Directory Creation** (research.md:93): `get_or_create_topic_dir "$TOPIC_DESC" ".claude/specs"`
   - Repeats steps 1-2 internally (template-integration.sh:260-290)
   - Calls get_next_topic_number which requires another find operation (line 242-250)
   - Creates directory structure with mkdir -p
   - Result: Additional find + directory scan

4. **Report Subdirectory Numbering** (research.md:111): `get_next_artifact_number "${TOPIC_DIR}/reports"`
   - Scans directory with glob pattern [0-9][0-9][0-9]_*.md (artifact-creation.sh:145)
   - Iterates with for loop, calls basename and grep for each file
   - Performs arithmetic comparison to find max
   - Result: 1 glob expansion + N file operations

5. **Per-Subtopic Path Calculation** (research.md:116-128): Loop over SUBTOPICS array
   - Calls get_next_artifact_number for each subtopic report
   - Each call repeats glob expansion and file iteration
   - Result: M * (1 glob + N file ops) where M = subtopic count (2-4)

**Total Bash Operations for 3 Subtopics**:
- 6+ bash command invocations
- 3+ find/glob directory scans
- 15-20+ subprocess calls for text processing (sed, awk, tr, basename, grep)

**Token Impact**: Each bash command shown to orchestrator + command output = 200-500 tokens per operation. Estimated 2000-3000 tokens for complete path resolution.

### Finding 2: Redundant Directory Traversals in Topic Management

**Location**: /home/benjamin/.config/.claude/lib/template-integration.sh:189-290

The topic management functions exhibit significant redundancy:

**find_matching_topic** (lines 189-231):
- Uses `find "$base_specs_dir" -maxdepth 1 -type d -name "[0-9]*_*"` (line 228)
- Processes each directory with while loop and process substitution
- Performs string normalization and fuzzy matching
- Returns single best match or empty string

**get_next_topic_number** (lines 233-254):
- Uses identical find command: `find "$base_specs_dir" -maxdepth 1 -type d -name "[0-9]*_*"` (line 250)
- Processes each directory to extract numeric prefix
- Returns max number + 1

**get_or_create_topic_dir** (lines 256-290):
- Calls extract_topic_from_question (text processing overhead)
- Calls find_matching_topic (first directory scan)
- If no match: calls get_next_topic_number (second directory scan)
- Creates directory with 8 subdirectories

**Redundancy Analysis**:
- Two sequential find operations scan same directory structure
- No caching or memoization of find results
- Each scan processes all topic directories (currently 77+ in .claude/specs/)
- Process substitution `< <(find ...)` creates subshells for each scan

**Performance**: For .claude/specs/ with 77 topics:
- First scan (find_matching_topic): 77 directory operations
- Second scan (get_next_topic_number): 77 directory operations
- Total: 154 filesystem operations before path is determined

### Finding 3: Token-Heavy Bash Output in Orchestration Context

**Location**: /home/benjamin/.config/.claude/commands/research.md:106-129

The path pre-calculation step is executed inline within the /research command markdown file, meaning:

**Visibility to Orchestrator**:
- All bash commands are shown in full (lines 107-129)
- Includes heredoc syntax, array declarations, for loops
- Shows intermediate variables (RESEARCH_SUBDIR, NEXT_NUM, REPORT_PATH)
- Displays echo statements for verification

**Example Output Verbosity** (lines 114, 126-127):
```bash
echo "Creating subtopic reports in: $RESEARCH_SUBDIR"
echo "  Subtopic: $subtopic"
echo "  Path: $REPORT_PATH"
```

For 3 subtopics, this produces:
- 1 directory creation message
- 3 subtopic name messages
- 3 path display messages
- Total: 7 echo outputs + command invocations

**Token Analysis**:
- Bash command block: ~800 tokens (lines 107-129)
- Output for 3 subtopics: ~400 tokens
- Verification logic: ~200 tokens
- Total per /research invocation: ~1400 tokens

**Compounding Effect**:
When /research is invoked by /orchestrate:
- Orchestrator sees full bash implementation details
- Orchestrator tracks all intermediate outputs
- No abstraction barrier between implementation and caller
- Context accumulation across multiple research agents (2-4 typical)

**Current Orchestration Pattern** (/orchestrate → /research):
1. Orchestrator invokes /research via SlashCommand
2. /research command markdown fully expands (including bash blocks)
3. Path resolution bash commands execute with full visibility
4. Orchestrator receives all outputs
5. Process repeats for planning, implementation phases

Result: 1400 tokens * 4 phases = 5600+ tokens for path resolution alone across typical workflow.

### Finding 4: Lack of Path Resolution Abstraction

**Location**: Comparison across commands (research.md, report.md, plan.md, debug.md, orchestrate.md)

**Grep Analysis**: The pattern `get_or_create_topic_dir|get_next_artifact_number` appears in 5 command files:
- /report.md: lines 84, 87, 93, 111, 118 (5 invocations)
- /debug.md: lines 388, 401 (2 invocations)
- /orchestrate.md: line 704 (1 invocation)
- /research.md: lines 84, 87, 93, 111, 118 (5 invocations - identical to report)
- /plan.md: lines 475, 483, 529 (3 invocations)

**Observation**: Each command reimplements path resolution inline using bash utilities. No centralized path resolution service or agent exists.

**Implications**:
1. **Code Duplication**: research.md and report.md have identical path calculation blocks (lines 77-136 vs 77-136)
2. **Maintenance Burden**: Changes to path structure require updates in 5+ files
3. **Inconsistent Patterns**: Some commands use template-integration.sh, others use artifact-operations.sh
4. **No Optimization Opportunity**: Each command starts from scratch (no shared state/cache)

**Alternative Architecture Not Present**:
- Dedicated path-resolver agent with minimal tool access (Bash only, no Read/Grep/Write)
- Centralized path calculation service in shared utilities
- Cached path mappings to avoid repeated directory scans
- Abstract path API that hides implementation details from orchestrators

## Detailed Analysis

### Current Architecture: Inline Bash Resolution

The current implementation follows this pattern:

```
/research Command
  ├─ Step 1: Topic decomposition (Task tool → subagent)
  ├─ Step 2: Path pre-calculation (inline bash)
  │    ├─ extract_topic_from_question() [4 subprocesses]
  │    ├─ find_matching_topic() [1 find + N dir ops]
  │    ├─ get_or_create_topic_dir() [2 finds + N+M dir ops]
  │    ├─ get_next_artifact_number() [1 glob + P file ops]
  │    └─ Per-subtopic loop [M * (1 glob + P file ops)]
  ├─ Step 3: Invoke research agents (Task tool → subagents)
  └─ Step 4: Synthesis
```

**Bottleneck**: Step 2 blocks agent invocation and consumes significant tokens visible to orchestrator.

### Performance Characteristics

**Time Complexity**:
- O(N) for find_matching_topic (N = topic count)
- O(N) for get_next_topic_number (N = topic count)
- O(P) for get_next_artifact_number (P = files in directory)
- O(M * P) for per-subtopic numbering (M = subtopics, P = files per subdir)

With current codebase (77 topics, ~3 subtopics typical):
- Topic lookup: 77 operations
- Topic numbering: 77 operations
- Report numbering: ~5 operations (reports subdirectory)
- Subtopic numbering: 3 * 5 = 15 operations
- **Total**: ~174 filesystem operations per /research invocation

**Space Complexity**:
- Bash arrays for subtopics (M elements)
- Associative array for subtopic paths (M key-value pairs)
- Process substitution buffers for find output (N lines)
- **Total**: O(N + M) space in shell memory

### Token Consumption Breakdown

Based on research.md lines 77-136:

| Component | Lines | Estimated Tokens |
|-----------|-------|------------------|
| Bash command block | 77-129 | 800 |
| Function calls (5 utils) | 84, 87, 93, 111, 118 | 300 |
| Loop structure | 116-128 | 200 |
| Echo outputs (7 messages) | 114, 126-127 | 400 |
| Verification logic | 131-136 | 200 |
| **Total per invocation** | | **1900 tokens** |

When invoked via /orchestrate (4 research phases typical):
- **Total path resolution tokens**: 1900 * 4 = **7600 tokens**

Context window allocation (~200k tokens):
- Path resolution: 7600 tokens (3.8%)
- Actual research: ~150k tokens (75%)
- Orchestration overhead: ~42k tokens (21%)

**Optimization Potential**: Reducing path resolution to 500 tokens per invocation would save 5600 tokens (2.8% of context window).

## Recommendations

### Recommendation 1: Create Dedicated Path Resolver Agent

**Rationale**: Separate path calculation concerns from research orchestration logic.

**Implementation**:
- Create `.claude/agents/path-resolver.md` with restricted tool access (Bash only)
- Agent accepts: topic description, base directory, artifact type
- Agent returns: structured JSON with absolute paths
- Invoke via Task tool from /research command

**Benefits**:
- Reduced token visibility (orchestrator sees only Task invocation + JSON result)
- Centralized optimization (improve path-resolver without touching all commands)
- Consistent path patterns across commands
- Easier testing and validation

**Estimated Token Reduction**: 1900 → 400 tokens per invocation (79% reduction)

### Recommendation 2: Implement Bash Utility Consolidation

**Rationale**: Reduce subprocess overhead by combining operations.

**Implementation**:
- Create `resolve_research_paths()` function in new file `.claude/lib/path-resolution.sh`
- Single function that:
  1. Accepts topic description + subtopics array
  2. Performs all directory operations in one pass
  3. Returns structured output (JSON or space-delimited)
- Cache directory listings to avoid repeated finds

**Example Signature**:
```bash
resolve_research_paths() {
  local topic_desc="$1"
  shift
  local subtopics=("$@")

  # Single find operation
  local topics_cache=$(find "$base_specs_dir" -maxdepth 1 -type d -name "[0-9]*_*" 2>/dev/null)

  # Process once, return all paths
  echo "$topic_dir $research_subdir ${subtopic_paths[@]}"
}
```

**Benefits**:
- 6+ bash invocations → 1 consolidated function call
- 3+ directory scans → 1 cached scan
- Reduced process substitution overhead
- Improved performance for large topic counts (77+)

**Estimated Performance Gain**: 174 filesystem operations → ~80 operations (54% reduction)

### Recommendation 3: Adopt Lazy Path Resolution

**Rationale**: Defer path calculation until report file creation, reducing upfront orchestration overhead.

**Implementation**:
- Remove STEP 2 (path pre-calculation) from /research command
- Pass topic description and subtopic names to research-specialist agents
- Agents calculate their own report paths using lightweight utilities
- Trade: Agent complexity increases slightly, orchestrator complexity decreases significantly

**Benefits**:
- Orchestrator no longer sees bash path resolution details
- Research agents execute path calculation in parallel (implicit)
- Simpler /research command structure
- Better separation of concerns (each agent manages own filesystem location)

**Trade-offs**:
- Research-specialist must have Bash tool access (currently has it)
- Requires updating research-specialist.md with path resolution logic
- Less centralized control over directory structure

**Estimated Token Reduction**: 1900 → 150 tokens per /research invocation (92% reduction at orchestrator level)

### Recommendation 4: Introduce Path Resolution Caching

**Rationale**: Eliminate redundant directory scans within single workflow execution.

**Implementation**:
- Create `.claude/data/cache/path-resolution-cache.json`
- Structure: `{"topics": {"077": "/path/to/077_topic"}, "report_numbers": {"077_reports": 5}}`
- Cache populated on first access, invalidated on directory creation
- TTL: workflow session (cleared on /orchestrate completion)

**Benefits**:
- Second and subsequent path resolutions become O(1) lookups
- Reduces filesystem I/O for complex workflows (orchestrate with 5+ phases)
- Cache can be shared across commands in same session
- No behavior change (transparent optimization)

**Estimated Performance Gain**:
- First invocation: 174 operations (unchanged)
- Subsequent invocations: 5 operations (97% reduction)
- Average across 4-phase workflow: ~70 operations per invocation (60% reduction)

## References
- /home/benjamin/.config/.claude/commands/research.md:77-136 (STEP 2 path pre-calculation)
- /home/benjamin/.config/.claude/lib/template-integration.sh:189-290 (topic management functions)
- /home/benjamin/.config/.claude/lib/artifact-creation.sh:134-157 (get_next_artifact_number)
- /home/benjamin/.config/.claude/commands/report.md:84-118 (identical path resolution pattern)
- /home/benjamin/.config/.claude/commands/plan.md:475-529 (plan path calculation)
- /home/benjamin/.config/.claude/commands/debug.md:388-401 (debug topic creation)
- /home/benjamin/.config/.claude/commands/orchestrate.md:704 (workflow topic creation)
