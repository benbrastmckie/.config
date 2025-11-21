# Haiku LLM-Based Topic Naming Strategy - Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: LLM-based directory naming with Haiku model
- **Report Type**: Clean-break refactor design
- **Complexity**: 3

## Executive Summary

This report proposes a complete architectural refactor replacing the current rule-based topic naming system (sanitize_topic_name) with a Haiku LLM subagent that generates semantic directory names directly from user prompts. The refactor eliminates all stopword filtering, artifact stripping, and length truncation logic in favor of a simple two-tier system: Haiku-generated name (Tier 1) or fallback to `NNN_no_name/` (Tier 2) when LLM fails. This clean-break approach dramatically simplifies the codebase (removing ~200 lines of sanitization logic), provides superior semantic clarity through AI understanding, and makes LLM failures immediately visible through the `no_name` sentinel value.

## Findings

### Current Implementation Analysis

**Current Architecture** (/home/benjamin/.config/.claude/lib/plan/topic-utils.sh):

The existing implementation uses a complex rule-based system with multiple components:

1. **sanitize_topic_name()** (lines 183-257):
   - 8-step algorithm with path extraction, stopword filtering, artifact stripping
   - 71 stopwords (40 common English + 31 planning context terms)
   - Length limit enforcement (35 chars with word-boundary preservation)
   - Multiple sed/grep transformations

2. **strip_artifact_references()** (lines 142-163):
   - Removes artifact numbering patterns (001_, NNN_)
   - Filters artifact directory names (reports, plans, debug, etc.)
   - Strips file extensions (.md, .txt, .sh, etc.)
   - Removes common basenames (readme, claude, output, etc.)

3. **extract_significant_words()** (lines 30-77):
   - Tier 2 fallback for LLM classification failures
   - Extracts 4 significant words from description
   - 40-character length limit
   - Used by workflow-classifier integration

**Integration Points**:

All four directory-creating commands funnel through this infrastructure:

- `/plan`, `/research`, `/debug` → `initialize_workflow_paths()` → `sanitize_topic_name()`
- `/optimize-claude` → `perform_location_detection()` → `sanitize_topic_name()`

**Recent Enhancement (Spec 862)**:

Implementation just completed adding artifact stripping, extended stopwords, and reduced length limits. Summary shows 100% test coverage with 82 passing tests (60 unit + 22 integration).

### Problem Analysis

**Complexity Issues**:

1. **Rule Brittleness**: The current system requires continuous maintenance as new patterns emerge (e.g., "862_infrastructure_to_improve_the_names_that_will_be" shows the system still struggles with complex prompts)

2. **Context Loss**: Stopword filtering removes semantic context. Example from implementation summary: "carefully create plan to implement authentication" → "authentication" loses the intent to "create plan"

3. **Maintenance Burden**:
   - 71 stopwords require curation
   - Artifact patterns need updating as new artifact types emerge
   - Test suite requires 82 tests to cover edge cases
   - Documentation spans multiple files (directory-protocols.md, topic-utils.sh docstrings)

4. **No Feedback Loop**: When sanitization produces poor names, users have no insight into why or how to improve their prompts

### Haiku Agent Pattern Analysis

**Existing Haiku Agents** (.claude/agents/):

Research found 7 agents using Haiku 4.5 for deterministic tasks:

1. **plan-complexity-classifier.md** (lines 1-532):
   - Model: haiku (not haiku-4.5)
   - Task: Fast semantic classification (<5s)
   - Returns: Structured JSON with validation
   - Pattern: Completion signal + JSON payload
   - State persistence: Saves to workflow state for next bash block

2. **doc-converter.md**: Deterministic document format conversion
3. **complexity-estimator.md**: Fast complexity assessment
4. **implementer-coordinator.md**: Deterministic coordination logic
5. **spec-updater.md**: Deterministic file updates
6. **docs-structure-analyzer.md**: Fast structural analysis
7. **claude-md-analyzer.md**: Fast CLAUDE.md structure analysis

**Key Pattern** (from plan-complexity-classifier.md lines 4-6):
```yaml
model: haiku
model-justification: Classification is fast, deterministic task requiring <5s response time
fallback-model: sonnet-4.5
```

**Agent Invocation Pattern** (from /plan command lines 274-296):
```
Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    [Context and requirements]

    Execute according to behavioral guidelines and return completion signal:
    [SIGNAL]: [result]
  "
}
```

### Architecture Comparison

**Current System** (Rule-Based):
```
User Prompt → sanitize_topic_name() → 8-step algorithm → Topic Name
                ↓
          [71 stopwords filter]
          [artifact stripping]
          [path extraction]
          [length truncation]
          [multiple sed/grep]
```

**Proposed System** (LLM-Based):
```
User Prompt → topic-naming-agent (Haiku) → Topic Name
              (5-15 word semantic analysis)
                ↓
              Success? → Use LLM name
                ↓
              Failure? → Fallback: NNN_no_name/
```

### Cost Analysis

**Haiku 4.5 Pricing**: $0.003 per 1K input tokens (from model-selection-guide.md lines 8-9)

**Estimated Token Usage per Invocation**:
- Agent prompt: ~800 tokens (behavioral guidelines)
- User description: ~100-200 tokens (typical feature description)
- Output: ~50 tokens (topic name + completion signal)
- **Total**: ~1,000 tokens per invocation

**Cost per Topic Creation**: $0.003 (1K tokens × $0.003/1K)

**Usage Pattern Analysis**:
Based on spec directory analysis (75 existing topics in production):
- Average topic creation rate: ~10-15 per week (active development)
- Monthly cost: $0.003 × 60 topics = **$0.18/month**
- Annual cost: **$2.16/year**

**Cost Comparison to Development Time**:
- Maintaining rule-based system: ~2 hours/month (updating stopwords, fixing edge cases, test maintenance)
- Developer time value: $50/hour (conservative)
- Monthly maintenance cost: $100/month = **$1,200/year**
- **Savings**: $1,197.84/year (99.8% reduction)

### Error Handling Analysis

**Current System Error Handling**:
- No explicit error handling for sanitization failures
- Falls back to basic sanitization (Tier 2) when extract_significant_words fails
- Produces generic names like "topic" when all extraction fails (line 72-73 in topic-utils.sh)
- No visibility into failure modes

**Proposed Error Handling** (Clean-Break):

**Tier 1**: Haiku LLM agent generates semantic name
- Input: Full user prompt + context
- Validation: Regex `^[a-z0-9_]{5,40}$`
- Output: Semantic snake_case name (e.g., "jwt_authentication_refactor")

**Tier 2**: Fallback to sentinel value on ANY failure
- LLM timeout? → `NNN_no_name/`
- LLM returns invalid format? → `NNN_no_name/`
- LLM service unavailable? → `NNN_no_name/`
- Validation fails? → `NNN_no_name/`

**Why `no_name` Sentinel**:
1. **Immediate Visibility**: User instantly sees LLM failed
2. **No Silent Degradation**: Unlike "topic" fallback, `no_name` is obviously wrong
3. **Debugging Signal**: Presence of `no_name` directories indicates LLM reliability issues
4. **Simple Detection**: `ls .claude/specs/*_no_name/` shows all failures
5. **Manual Intervention Trigger**: User can rename directory with meaningful context

### Integration with Error Logging

**Error Handling Pattern** (.claude/docs/concepts/patterns/error-handling.md):

Current system requires all commands to integrate centralized error logging (lines 1-100):

```bash
# Source error-handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || exit 1

# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/plan"  # or /research, /debug, /optimize-claude
WORKFLOW_ID="workflow_$(date +%s)"
USER_ARGS="$*"

# Log errors with standardized types
log_command_error "agent_error" "Haiku naming agent timeout" "$agent_output"
```

**Error Types for Naming Agent**:
- `agent_error`: Haiku agent invocation failure
- `timeout_error`: Agent timeout (>5s response)
- `validation_error`: Invalid format returned (regex mismatch)
- `execution_error`: Agent returned error signal

**Error Consumption Workflow**:
1. Query errors: `/errors --command /plan --type agent_error`
2. Analyze patterns: `/repair --type agent_error --complexity 2`
3. Fix issues: Address Haiku agent reliability or fallback to different model

### Clean-Break Refactor Requirements

**Writing Standards Compliance** (.claude/docs/concepts/writing-standards.md lines 21-45):

1. **Prioritize coherence over compatibility**: New system doesn't need to replicate old sanitization behavior
2. **No legacy burden**: Remove all sanitization logic entirely
3. **Migration is acceptable**: Existing directories keep their names, new directories use LLM
4. **System integration**: Commands continue working with new topic name source

**Code Standards** (.claude/docs/reference/standards/code-standards.md):

From research of existing agents and libraries:
- Follow agent behavioral guidelines format (YAML frontmatter + markdown sections)
- Use completion signals for parsing (e.g., `TOPIC_NAME_GENERATED: name`)
- Integrate error handling library for centralized logging
- Include validation regex and fallback logic
- Document model justification in frontmatter

**Testing Requirements**:

Clean-break means:
- No tests for old sanitization logic (removed entirely)
- New tests for:
  1. Agent invocation and completion signal parsing
  2. Validation regex enforcement
  3. Fallback to `no_name` on all failure modes
  4. Integration with all 4 commands
  5. Error logging integration

## Recommendations

### Recommendation 1: Implement Haiku Topic-Naming Agent

**Approach**: Create new agent at `.claude/agents/topic-naming-agent.md`

**Agent Specification**:

```yaml
---
allowed-tools: None
description: Fast semantic topic directory name generation from user prompts
model: haiku-4.5
model-justification: Directory naming is fast, deterministic task requiring <3s response time and low cost ($0.003/1K tokens)
fallback-model: sonnet-4.5
---
```

**Behavioral Guidelines** (following plan-complexity-classifier.md pattern):

**STEP 1**: Receive and verify user prompt
- Input: Full feature description/workflow prompt
- Checkpoint: Verify prompt is not empty

**STEP 2**: Generate semantic topic name
- Analyze prompt for core intent (5-15 word semantic understanding)
- Extract key technical terms, action verbs, and domain concepts
- Format as snake_case (lowercase, underscores only)
- Length: 5-40 characters (enforced by validation)
- Avoid generic terms: "plan", "feature", "implementation" alone

**STEP 3**: Validate output format
- Regex: `^[a-z0-9_]{5,40}$`
- No leading/trailing underscores
- No consecutive underscores
- Descriptive and meaningful (not generic)

**STEP 4**: Return completion signal
```
TOPIC_NAME_GENERATED: jwt_authentication_refactor
```

**Example Transformations**:

| User Prompt | Generated Name | Reasoning |
|-------------|----------------|-----------|
| "I just completed an implementation summarized in /home/.../001_implementation_summary.md and want you to research a different strategy" | `alternative_strategy_research` | Focuses on "different strategy" and "research" action |
| "fix the JWT token expiration bug causing login failures" | `jwt_token_expiration_fix` | Preserves technical term (JWT), problem (expiration), action (fix) |
| "Research authentication patterns to create implementation plan" | `auth_patterns_implementation` | Combines domain (auth patterns) with goal (implementation) |
| "carefully research the /home/benjamin/.config/.claude/ directory" | `claude_directory_analysis` | Extracts meaningful path component and action |

**Error Handling**:

Return structured error signal on failure:
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Generated name contains invalid characters",
  "details": {"generated": "auth-patterns!", "expected_format": "^[a-z0-9_]{5,40}$"}
}

TASK_ERROR: validation_error - Generated name contains invalid characters
```

Commands will parse error signal and fall back to `no_name`.

### Recommendation 2: Refactor Topic Name Generation Function

**Target**: `.claude/lib/plan/topic-utils.sh`

**Changes**:

1. **Remove Functions** (clean break):
   - `strip_artifact_references()` (lines 142-163) - DELETE
   - `extract_significant_words()` (lines 30-77) - DELETE
   - `sanitize_topic_name()` (lines 183-257) - REPLACE

2. **Replace with `generate_topic_name_llm()`**:

```bash
# generate_topic_name_llm: Generate semantic topic name using Haiku LLM agent
#
# Arguments:
#   $1 - description: User's workflow description/prompt
#
# Returns:
#   Topic name on success (5-40 chars, snake_case)
#   "no_name" on ANY failure (timeout, validation, error)
#
# Exit codes:
#   0 - Always succeeds (returns "no_name" on agent failure)
#
# Integration:
#   - Invokes topic-naming-agent.md via subagent protocol
#   - Parses TOPIC_NAME_GENERATED signal
#   - Validates format: ^[a-z0-9_]{5,40}$
#   - Logs errors to centralized error log
#   - Falls back to "no_name" on any failure
#
# Example:
#   TOPIC_NAME=$(generate_topic_name_llm "$USER_PROMPT")
#   # Success: "jwt_authentication_refactor"
#   # Failure: "no_name"
#
generate_topic_name_llm() {
  local description="$1"

  # Validation: Description must not be empty
  if [ -z "$description" ]; then
    echo "no_name"
    return 0
  fi

  # Agent invocation pattern (inline - not via Task tool since this is library function)
  # Commands will call this function and handle agent invocation themselves
  # This function provides validation and parsing logic

  # For now, return "no_name" to indicate agent call needed
  # Commands will implement actual agent invocation
  echo "no_name"
  return 0
}
```

**Note**: The actual agent invocation must happen in commands (not library functions) because subagent protocol requires Task tool which is only available in command context. Library provides validation and fallback logic.

3. **Update Function References**:

All calls to `sanitize_topic_name()` should be updated to use new agent invocation pattern:

```bash
# OLD (rule-based):
TOPIC_NAME=$(sanitize_topic_name "$USER_DESCRIPTION")

# NEW (LLM-based):
# Invoke topic-naming-agent via Task tool (in command, not library)
# Parse TOPIC_NAME_GENERATED signal
# Validate format
# Fall back to "no_name" on failure
TOPIC_NAME="no_name"  # Default
# ... agent invocation and parsing ...
if [ "$TOPIC_NAME" = "no_name" ]; then
  echo "WARNING: LLM naming failed, using no_name directory" >&2
  log_command_error "agent_error" "Topic naming agent failed" "$agent_output"
fi
```

### Recommendation 3: Update All Four Commands

**Commands to Update**:

1. `/plan` (.claude/commands/plan.md)
2. `/research` (.claude/commands/research.md)
3. `/debug` (.claude/commands/debug.md)
4. `/optimize-claude` (.claude/commands/optimize-claude.md)

**Integration Pattern** (for each command):

**Before topic allocation** (replace sanitize_topic_name call):

```bash
# NEW: Invoke topic-naming-agent for semantic name generation
TOPIC_NAME="no_name"  # Default fallback

# Use Task tool to invoke agent
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    **User Prompt**: ${USER_DESCRIPTION}

    Generate a semantic topic directory name and return:
    TOPIC_NAME_GENERATED: [name]
  "
}

# Parse agent output (next bash block)
AGENT_OUTPUT="[captured from agent]"

# Extract topic name from completion signal
if echo "$AGENT_OUTPUT" | grep -q "TOPIC_NAME_GENERATED:"; then
  TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME_GENERATED:" | cut -d: -f2- | tr -d ' ')

  # Validate format
  if ! echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'; then
    echo "WARNING: LLM returned invalid topic name format, using no_name" >&2
    log_command_error "validation_error" "Invalid topic name format" "name=$TOPIC_NAME"
    TOPIC_NAME="no_name"
  fi
else
  # Agent failed or timed out
  echo "WARNING: LLM naming agent failed, using no_name" >&2
  log_command_error "agent_error" "Topic naming agent failed" "$AGENT_OUTPUT"
  TOPIC_NAME="no_name"
fi

# Continue with atomic topic allocation using LLM-generated name
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_NAME")
```

**Error Logging Integration**:

Each command must log naming failures:

```bash
# Source error-handling library at command start
source "$CLAUDE_PROJECT_DIR/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="[/plan|/research|/debug|/optimize-claude]"
WORKFLOW_ID="workflow_$(date +%s)"

# Log naming failures
if [ "$TOPIC_NAME" = "no_name" ]; then
  log_command_error "agent_error" "Topic naming LLM failed" "prompt=$USER_DESCRIPTION"
fi
```

### Recommendation 4: Create Monitoring and Debugging Tools

**Tool 1**: `.claude/scripts/check_no_name_directories.sh`

```bash
#!/usr/bin/env bash
# Check for LLM naming failures (no_name directories)

SPECS_DIR="${1:-.claude/specs}"

echo "Checking for LLM naming failures..."
NO_NAME_DIRS=$(ls -1d "$SPECS_DIR"/[0-9][0-9][0-9]_no_name 2>/dev/null || echo "")

if [ -z "$NO_NAME_DIRS" ]; then
  echo "✓ No naming failures found"
  exit 0
else
  echo "⚠ Found LLM naming failures:"
  echo "$NO_NAME_DIRS"
  echo ""
  echo "To investigate:"
  echo "  /errors --type agent_error --command /plan"
  exit 1
fi
```

**Tool 2**: Enhanced error querying

Users can debug naming failures with existing `/errors` command:

```bash
# View all naming agent failures
/errors --type agent_error --limit 20

# View recent naming failures for specific command
/errors --command /plan --type agent_error --since 1d

# Analyze patterns and create fix plan
/repair --type agent_error --complexity 2
```

**Tool 3**: Manual directory renaming helper

```bash
#!/usr/bin/env bash
# Rename no_name directory to meaningful name

NO_NAME_DIR="$1"
NEW_NAME="$2"

if [ ! -d "$NO_NAME_DIR" ]; then
  echo "ERROR: Directory not found: $NO_NAME_DIR"
  exit 1
fi

# Extract topic number
TOPIC_NUM=$(basename "$NO_NAME_DIR" | cut -d_ -f1)

# Construct new path
NEW_DIR="${NO_NAME_DIR%/*}/${TOPIC_NUM}_${NEW_NAME}"

# Rename
mv "$NO_NAME_DIR" "$NEW_DIR"
echo "✓ Renamed: $NO_NAME_DIR -> $NEW_DIR"
```

### Recommendation 5: Simplified Testing Strategy

**Test Suite Structure** (clean break - no old tests retained):

1. **Agent Unit Tests** (`.claude/tests/test_topic_naming_agent.sh`):
   - Test agent returns valid completion signal
   - Test validation regex enforcement
   - Test various prompt formats
   - Test error signal format
   - Target: 20 tests

2. **Fallback Tests** (`.claude/tests/test_topic_naming_fallback.sh`):
   - Test no_name fallback on agent timeout
   - Test no_name fallback on validation failure
   - Test no_name fallback on empty prompt
   - Test no_name fallback on agent error
   - Target: 10 tests

3. **Integration Tests** (`.claude/tests/test_topic_naming_integration.sh`):
   - Test /plan command with LLM naming
   - Test /research command with LLM naming
   - Test /debug command with LLM naming
   - Test /optimize-claude command with LLM naming
   - Verify error logging on failures
   - Target: 20 tests

**Total Tests**: 50 tests (vs 82 in rule-based system)

**Test Reduction Rationale**:
- No need for stopword filtering tests (removed)
- No need for artifact stripping tests (removed)
- No need for length truncation tests (removed)
- No need for path extraction tests (removed)
- Focus on: agent invocation, validation, fallback, integration

### Recommendation 6: Documentation Updates

**Files to Update** (clean-break - remove historical context):

1. **directory-protocols.md**:
   - Remove anti-patterns section (lines 86-119) - no longer applicable
   - Remove automatic prevention section (lines 110-119) - rule-based logic removed
   - Update topic naming section (lines 62-85) to describe LLM approach
   - Add "Fallback Behavior" section explaining `no_name` sentinel

2. **topic-utils.sh docstrings**:
   - Update function documentation to reflect LLM approach
   - Remove sanitization algorithm documentation
   - Add agent invocation pattern documentation

3. **Create new guide**: `.claude/docs/guides/development/topic-naming-with-llm.md`
   - Explain Haiku agent architecture
   - Document prompt engineering tips for better names
   - Show examples of good vs poor prompts
   - Explain no_name fallback and how to handle it
   - Cost analysis and justification

4. **Update CLAUDE.md**:
   - Update directory_protocols section to reference new LLM approach
   - Remove references to stopword lists and sanitization rules

**Documentation Philosophy** (writing-standards.md compliance):

- No historical context ("previously used rule-based system")
- Present-focused: "Topic names are generated by Haiku LLM agent"
- No migration guides: Just document current LLM approach
- Clean narrative: Write as if this was always the implementation

### Recommendation 7: Phased Rollout Plan

**Phase 1**: Agent Development (4-6 hours)
- Create topic-naming-agent.md with behavioral guidelines
- Implement validation and completion signal format
- Create agent unit tests (20 tests)
- Verify agent responds in <3s

**Phase 2**: Library Refactor (2-3 hours)
- Remove sanitize_topic_name() and supporting functions
- Update topic-utils.sh with agent integration stubs
- Create fallback tests (10 tests)

**Phase 3**: Command Integration (6-8 hours)
- Update /plan command with agent invocation
- Update /research command with agent invocation
- Update /debug command with agent invocation
- Update /optimize-claude command with agent invocation
- Add error logging to all commands
- Create integration tests (20 tests)

**Phase 4**: Tools and Monitoring (2-3 hours)
- Create check_no_name_directories.sh script
- Create manual rename helper script
- Enhance error logging queries

**Phase 5**: Documentation (3-4 hours)
- Update directory-protocols.md
- Update topic-utils.sh docstrings
- Create topic-naming-with-llm.md guide
- Update CLAUDE.md

**Phase 6**: Validation (1 week monitoring)
- Deploy to production
- Monitor first 20 topic creations
- Track no_name failure rate (target: <5%)
- Track LLM response time (target: <3s average)
- Collect user feedback
- Adjust agent prompt if needed

**Total Estimated Time**: 17-24 hours (vs 16-20 hours for rule-based enhancements)

**Rollback Plan**:

If LLM approach fails (>20% no_name rate or >5s average latency):

```bash
# Revert to previous sanitize_topic_name implementation
git revert [commit-hash]

# Or temporarily disable LLM and use basic fallback
# Edit commands to use: TOPIC_NAME=$(echo "$DESC" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
```

## References

### Code Files Analyzed

- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (lines 1-344)
  - Current sanitize_topic_name implementation (lines 183-257)
  - strip_artifact_references function (lines 142-163)
  - extract_significant_words function (lines 30-77)

- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh` (lines 1-450)
  - allocate_and_create_topic atomic allocation (lines 230-307)
  - Topic number sequencing and rollover logic (lines 180-228)
  - ensure_artifact_directory lazy creation (lines 396-424)

- `/home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh` (lines 1-100)
  - initialize_workflow_paths integration (sources topic-utils.sh)
  - extract_topic_from_plan_path for /revise command (lines 78-100)

- `/home/benjamin/.config/.claude/agents/plan-complexity-classifier.md` (lines 1-532)
  - Haiku agent pattern example
  - Completion signal format (line 197)
  - Validation checklist (lines 155-185)
  - State persistence pattern (lines 476-532)

- `/home/benjamin/.config/.claude/commands/plan.md` (lines 265-324)
  - Agent invocation pattern (lines 274-296)
  - Task tool usage for subagents

### Documentation Analyzed

- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (lines 1-150)
  - Topic-based organization overview (lines 17-35)
  - Topic naming anti-patterns (lines 86-119)
  - Atomic topic allocation requirements (lines 120-150)

- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (lines 1-100)
  - Centralized error logging pattern
  - Error type taxonomy (lines 49-69)
  - JSONL schema (lines 71-95)
  - Command integration requirements (lines 96-100)

- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-80)
  - Clean-break refactor philosophy (lines 21-45)
  - No legacy burden principle (line 27)
  - Present-focused documentation (lines 47-57)

- `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md` (lines 8-9, 16-18)
  - Haiku pricing: $0.003/1K tokens
  - Haiku use cases: deterministic tasks

### Implementation Summary

- `/home/benjamin/.config/.claude/specs/862_infrastructure_to_improve_the_names_that_will_be/summaries/001_implementation_summary.md` (lines 1-314)
  - Recent rule-based enhancement completion
  - 82 tests passing (60 unit + 22 integration)
  - Performance: 23ms total allocation time
  - Four commands integrated: /plan, /research, /debug, /optimize-claude

### Related Specifications

- Spec 862: Infrastructure to improve directory names (just completed)
  - Enhanced sanitize_topic_name with artifact stripping
  - Added 31 planning context stopwords
  - Reduced length limit to 35 characters

- Spec 777: Semantic slug generation with LLM fallback
  - Introduced workflow-classifier integration
  - Three-tier fallback: LLM → extract_significant_words → sanitize

This research analyzed 12 files across agents, commands, libraries, and documentation to design a comprehensive clean-break refactor replacing rule-based topic naming with Haiku LLM semantic generation.
