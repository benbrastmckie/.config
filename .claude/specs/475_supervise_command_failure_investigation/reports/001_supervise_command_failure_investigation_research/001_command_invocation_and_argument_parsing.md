# Command Invocation and Argument Parsing Research

**Research Date**: 2025-10-25
**Topic**: Investigation of /supervise command invocation and argument parsing mechanisms
**Scope**: Command structure, argument handling, TODO.md references, error handling

## Executive Summary

The /supervise command is a markdown file at `/home/benjamin/.config/.claude/commands/supervise.md` that follows an AI execution script pattern. It expects a single argument (`$1`) as the workflow description. The command does NOT return TODO.md files itself - TODO.md output likely indicates the command file wasn't properly executed and Claude returned a TODO.md file from elsewhere. Key findings include: (1) simplistic argument parsing with single mandatory parameter, (2) no TODO.md references in command code, (3) strict orchestrator-only design prohibiting direct file operations, and (4) comprehensive error handling with 18 exit points.

## Research Questions

1. How is the /supervise command structured and invoked?
2. What is the argument parsing logic in the command file?
3. When and why does the command return TODO.md references?
4. What are the expected argument formats?
5. What error handling might output TODO.md?

## Findings

### Finding 1: Command Structure and Execution Model

**File Location**: `/home/benjamin/.config/.claude/commands/supervise.md`

**Command Metadata** (Lines 1-3):
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
---
```

**Key Discovery**: The /supervise command is NOT a traditional bash script. It's a markdown file containing AI execution instructions. This is critical because:

1. **AI Execution Script Pattern**: Commands in `.claude/commands/*.md` are AI prompts, not executable shell scripts
2. **Tool Restrictions**: Only 4 tools allowed (Task, TodoWrite, Bash, Read) - notably excludes Write, Edit, Grep, Glob
3. **Orchestrator Role**: The command is designed as a pure orchestrator that delegates work to agents via the Task tool

**Architectural Pattern** (Lines 7-29):
- Phase 0: Pre-calculate paths, create topic directory structure
- Phase 1-N: Invoke agents with pre-calculated paths, verify, extract metadata
- Completion: Report success + artifact locations

**Critical Prohibition** (Lines 19-24):
```markdown
**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure
```

This prohibition is significant: if the /supervise command is trying to execute tasks directly (rather than delegating to agents), it violates its own design and may fail silently.

### Finding 2: Argument Parsing Logic

**Primary Argument Parsing** (Lines 451-457):
```bash
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /supervise \"<workflow description>\""
  exit 1
fi
```

**Analysis**:
1. **Single Required Parameter**: Command expects exactly one argument (`$1`)
2. **No Validation**: Beyond checking if empty, there's no format validation
3. **No Parsing Logic**: The description is used as-is, not parsed into components
4. **Error Message Format**: Uses standard error + usage pattern

**Expected Format** (Line 455):
```
Usage: /supervise "<workflow description>"
```

**Invocation Examples Found** (Lines 1854-1901):
- Research-only: `/supervise "research API authentication patterns"`
- Research-and-plan: `/supervise "research the authentication module to create a refactor plan"`
- Full-implementation: `/supervise "implement OAuth2 authentication for the API"`
- Debug-only: `/supervise "fix the token refresh bug in auth.js"`

**Workflow Scope Detection** (Lines 480-506):
The command uses keyword-based detection to determine which phases to execute:
```bash
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

case "$WORKFLOW_SCOPE" in
  research-only)      PHASES_TO_EXECUTE="0,1" ;;
  research-and-plan)  PHASES_TO_EXECUTE="0,1,2" ;;
  full-implementation) PHASES_TO_EXECUTE="0,1,2,3,4" ;;
  debug-only)         PHASES_TO_EXECUTE="0,1,5" ;;
esac
```

This keyword detection happens via `detect_workflow_scope()` function from `workflow-detection.sh` library (sourced at lines 221-227).

### Finding 3: TODO.md References - NONE FOUND

**Critical Finding**: The /supervise command file contains ZERO references to "TODO.md"

**Search Results**:
- Pattern search for `TODO\.md` in `/home/benjamin/.config/.claude/commands/`: NO MATCHES
- Pattern search for `TODO` in supervise.md: NO MATCHES
- Full text search in all .claude files: 48 files contain "TODO" but supervise.md is NOT among them

**Interpretation**: If the /supervise command is returning TODO.md content, it's NOT coming from the command file itself. Possible causes:

1. **Command Not Executing**: The .md file isn't being processed as an AI execution script
2. **System-Level Fallback**: Claude Code may have a fallback that returns TODO.md when command fails to load
3. **Different File Returned**: The system may be returning a different TODO.md file from the filesystem
4. **Workspace Context Issue**: Claude may be reading a TODO.md from the project directory instead of executing the command

**Evidence from Git History**:
Recent commits show TODO.md files were deleted:
```
git status:
D .claude/TODO.md
D .claude/TODO2.md
D .claude/TODO3.md
```

These files were removed but may still exist in working directory or be referenced by stale processes.

### Finding 4: Expected Argument Format

**Format**: Single string argument containing natural language workflow description

**Characteristics**:
1. **Quoted String**: Must be quoted if contains spaces: `/supervise "description here"`
2. **Natural Language**: Not structured format - just plain English description
3. **Keyword-Driven**: Contains keywords that trigger workflow scope detection
4. **No Parameters**: No flags, options, or additional parameters supported

**Keyword Categories** (from workflow-detection.sh integration):

| Workflow Type | Keywords | Example |
|---------------|----------|---------|
| research-only | "research" WITHOUT "plan"/"implement" | "research API patterns" |
| research-and-plan | "research...plan", "analyze...planning" | "research auth to create plan" |
| full-implementation | "implement", "build", "add feature" | "implement OAuth2" |
| debug-only | "fix", "debug", "troubleshoot" | "fix token refresh bug" |

**Validation**: None beyond non-empty check - any non-empty string is accepted

### Finding 5: Error Handling and Exit Points

**18 Exit Points Found** (Lines 226-1818):

The command has extensive error handling with fail-fast behavior. Every exit point follows this pattern:

```bash
if [ error condition ]; then
  echo "ERROR: descriptive message"
  exit 1
fi
```

**Exit Categories**:

1. **Library Loading Failures** (Lines 226-275): 7 exit points for missing library files
   - workflow-detection.sh
   - error-handling.sh
   - checkpoint-utils.sh
   - unified-logger.sh
   - unified-location-detection.sh
   - metadata-extraction.sh
   - context-pruning.sh

2. **Input Validation** (Line 456): Missing workflow description

3. **Location Detection Failures** (Lines 524, 531, 544, 573): Cannot determine project root or topic metadata

4. **Directory Creation Failures** (Lines 610): Topic directory creation failed

5. **Verification Failures** (Lines 877, 1098, 1111, 1268, 1565, 1817): Agent output files missing after verification

**None of these error paths produce TODO.md output** - they all output clear error messages and exit with code 1.

## Detailed Analysis

### Command Execution Flow

```
┌─────────────────────────────────────────┐
│ 1. Parse Arguments ($1 = description)  │
│    Line 451: WORKFLOW_DESCRIPTION="$1" │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Source 7 Library Files               │
│    Lines 221-275: Load utilities        │
│    EXIT if any library missing          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 3. Detect Workflow Scope                │
│    Line 480: detect_workflow_scope()    │
│    Determines phases to execute         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 4. Phase 0: Location Detection          │
│    Lines 509-658: Calculate paths       │
│    EXIT if location cannot be determined│
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 5. Phase 1-6: Agent Delegation          │
│    Each phase: Task tool invocations    │
│    Verification checkpoints after each  │
│    EXIT on verification failure         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 6. Workflow Completion Summary          │
│    Display artifacts created            │
│    Clean up checkpoints                 │
└─────────────────────────────────────────┘
```

### TODO.md Output Scenarios

Given that supervise.md contains NO TODO.md references, if TODO.md is being returned, the failure must occur BEFORE or OUTSIDE command execution:

**Scenario 1: Command File Not Loaded**
- SlashCommand tool fails to load supervise.md
- System fallback returns TODO.md from workspace
- Root cause: File path resolution issue or permission problem

**Scenario 2: Command File Malformed**
- Markdown frontmatter parsing fails
- Claude doesn't recognize file as command
- Falls back to returning file content from current directory
- Root cause: YAML syntax error or encoding issue

**Scenario 3: Wrong File Returned**
- SlashCommand tool receives wrong path
- Loads TODO.md instead of supervise.md
- Root cause: Path calculation bug in command dispatch system

**Scenario 4: Workspace TODO.md in Context**
- supervise.md executes correctly
- But Claude's response includes TODO.md from workspace context
- Root cause: File open in editor or git status includes deleted TODO.md

**Scenario 5: Agent Creates TODO.md**
- Command delegates to research-specialist agent
- Agent fails to receive proper path
- Agent creates TODO.md as fallback
- Root cause: Path interpolation failure in Task tool prompt

## Code References

### Key File Locations

1. **Command File**: `/home/benjamin/.config/.claude/commands/supervise.md` (1956 lines)
2. **Agent Behavioral Files**:
   - `/home/benjamin/.config/.claude/agents/research-specialist.md`
   - `/home/benjamin/.config/.claude/agents/plan-architect.md`
   - `/home/benjamin/.config/.claude/agents/code-writer.md`
   - `/home/benjamin/.config/.claude/agents/test-specialist.md`
   - `/home/benjamin/.config/.claude/agents/debug-analyst.md`
   - `/home/benjamin/.config/.claude/agents/doc-writer.md`
3. **Library Files**:
   - `/home/benjamin/.config/.claude/lib/workflow-detection.sh`
   - `/home/benjamin/.config/.claude/lib/error-handling.sh`
   - `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`

### Critical Code Sections

**Argument Parsing** (supervise.md:451-457):
```bash
WORKFLOW_DESCRIPTION="$1"
if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  echo "Usage: /supervise \"<workflow description>\""
  exit 1
fi
```

**Library Loading** (supervise.md:217-275):
All 7 libraries are sourced with fail-fast error handling.

**Agent Invocation Pattern** (supervise.md:739-757):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]} (absolute path, pre-calculated by orchestrator)
    ...
  "
}
```

**Path Pre-Calculation** (supervise.md:625-658):
All artifact paths calculated BEFORE agent invocations to ensure consistency.

## Conclusions and Recommendations

### Conclusions

1. **No TODO.md in Command**: The /supervise command does not reference, create, or return TODO.md files
2. **Simplistic Argument Parsing**: Only validates non-empty, no format checking
3. **Orchestrator-Only Design**: Command delegates ALL file operations to agents
4. **Fail-Fast Error Handling**: 18 exit points with clear error messages
5. **External Failure Mode**: TODO.md output indicates system-level failure, not command-level failure

### Recommendations

#### Immediate Investigation Priorities

1. **Verify Command Invocation**:
   - Check if SlashCommand tool is properly loading supervise.md
   - Verify file path resolution in command dispatch
   - Test with minimal invocation: `/supervise "test"`

2. **Check Workspace State**:
   - Verify no TODO.md files in current directory
   - Check git status for deleted TODO.md files still in working tree
   - Search for TODO.md in .claude/ directory

3. **Agent Path Interpolation**:
   - Verify bash variable substitution works in Task tool prompts
   - Check if `${REPORT_PATHS[i]}` is properly expanded
   - Test if research-specialist agent receives absolute paths

4. **Library Dependencies**:
   - Verify all 7 library files exist and are readable
   - Check for syntax errors in library shell scripts
   - Test workflow-detection.sh scope detection function

#### Debugging Strategy

**Phase 1: Reproduce Issue**
```bash
# Test minimal invocation
/supervise "test minimal workflow"

# Expected: Either error message or workflow execution
# If TODO.md returned: Confirms system-level failure
```

**Phase 2: Check File System State**
```bash
# Find all TODO.md files
find /home/benjamin/.config -name "TODO.md" -o -name "TODO*.md"

# Check git status
cd /home/benjamin/.config
git status | grep TODO
```

**Phase 3: Verify Library Loading**
```bash
# Test library sourcing
cd /home/benjamin/.config/.claude
source lib/workflow-detection.sh
source lib/error-handling.sh
source lib/unified-location-detection.sh

# Run scope detection
detect_workflow_scope "test workflow"
```

**Phase 4: Test Agent Delegation**
```bash
# Minimal agent invocation test
# (Would need to be done through Claude interface)
Task {
  subagent_type: "general-purpose"
  description: "Test path interpolation"
  prompt: "
    Report Path: /tmp/test_report.md
    Create file at path above with: echo 'test' > /tmp/test_report.md
    Return: FILE_CREATED: /tmp/test_report.md
  "
}
```

### Root Cause Hypotheses (Ranked by Likelihood)

1. **HIGH**: Command file not being executed, TODO.md in workspace returned instead
2. **MEDIUM**: Agent path interpolation failing, agent creates TODO.md as fallback
3. **LOW**: Library loading failure causing early exit (but should show error, not TODO.md)
4. **VERY LOW**: Malformed markdown frontmatter preventing command recognition
