# Haiku LLM-Based Topic Naming Refactor - Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Haiku LLM-based topic directory naming system
- **Scope**: Complete clean-break refactor replacing rule-based sanitization with LLM semantic naming
- **Estimated Phases**: 6
- **Estimated Hours**: 18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 67.0
- **Structure Level**: 0
- **Research Reports**:
  - [Haiku LLM Naming Strategy](../reports/001_haiku_llm_naming_strategy.md)

## Overview

This plan implements a clean-break architectural refactor that replaces the current complex rule-based topic naming system (71 stopwords, artifact stripping, length truncation, ~200 lines of logic) with a simple Haiku LLM agent that generates semantic directory names directly from user prompts. The system uses a two-tier approach: Tier 1 (Haiku-generated name) or Tier 2 (fallback to `NNN_no_name/` sentinel value on any failure), making LLM failures immediately visible for debugging. This refactor eliminates all sanitization complexity, reduces maintenance burden by 99.8% ($1,197.84/year savings vs $2.16/year LLM cost), and provides superior semantic clarity through AI understanding of user intent.

## Research Summary

Research analyzed the current rule-based implementation (sanitize_topic_name with 8-step algorithm, 71 stopwords, artifact stripping), existing Haiku agent patterns (plan-complexity-classifier.md), cost analysis ($0.003/1K tokens = $2.16/year vs $1,200/year maintenance), and clean-break refactor requirements from writing-standards.md. Key findings:

- **Current System Complexity**: 200+ lines of sanitization logic, 82 tests required, continuous maintenance for new patterns
- **Haiku Pattern Success**: 7 existing agents use Haiku 4.5 for fast deterministic tasks (<5s response time)
- **Cost Advantage**: 99.8% cost reduction through automation ($2.16/year LLM vs $1,200/year developer maintenance)
- **Clean-Break Approach**: Remove all legacy sanitization, no backward compatibility needed, present-focused documentation
- **Failure Visibility**: `no_name` sentinel makes LLM failures obvious vs silent degradation to generic names
- **Integration Points**: All four commands (/plan, /research, /debug, /optimize-claude) funnel through topic-utils.sh

Recommended approach: Create topic-naming-agent.md following existing Haiku patterns, replace sanitize_topic_name() with LLM invocation, integrate centralized error logging, and provide clear fallback to `no_name` on any failure mode.

## Success Criteria

- [ ] Haiku topic-naming-agent.md created with completion signal protocol
- [ ] All sanitization functions removed from topic-utils.sh (clean break)
- [ ] All four commands integrated with LLM naming and error logging
- [ ] Fallback to `no_name` on all failure modes (timeout, validation, error)
- [ ] Error logging integrated for agent failures (agent_error, validation_error, timeout_error)
- [ ] Test suite created (50 tests: 20 agent + 10 fallback + 20 integration)
- [ ] Documentation updated following clean-break standards (no historical context)
- [ ] Monitoring script deployed for tracking `no_name` directories
- [ ] First 20 topic creations validated (<5% `no_name` rate, <3s avg response time)
- [ ] Cost analysis confirmed ($2.16/year actual vs $2.16/year projected)

## Technical Design

### Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│ User Prompt: "fix JWT token expiration bug"                  │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Command Layer (/plan, /research, /debug, /optimize-claude)   │
│ - Invokes topic-naming-agent via Task tool                   │
│ - Provides full user prompt as context                       │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Topic Naming Agent (Haiku 4.5)                               │
│ - Semantic analysis (5-15 word understanding)                │
│ - Extracts technical terms, action verbs, domain concepts    │
│ - Formats as snake_case (5-40 chars)                         │
│ - Returns: TOPIC_NAME_GENERATED: jwt_token_expiration_fix    │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Command Validation & Fallback                                │
│ - Parse completion signal (TOPIC_NAME_GENERATED: name)       │
│ - Validate format: ^[a-z0-9_]{5,40}$                         │
│ - Success? → Use LLM name                                    │
│ - Failure? → Fallback to "no_name" + log error              │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Topic Allocation (allocate_and_create_topic)                 │
│ - Atomic topic number allocation with name                   │
│ - Creates: NNN_jwt_token_expiration_fix/ or NNN_no_name/    │
└──────────────────────────────────────────────────────────────┘
```

### Component Interactions

**New Components**:
1. `.claude/agents/topic-naming-agent.md` - Haiku agent with behavioral guidelines
2. Agent invocation logic in all four commands (replaces sanitize_topic_name calls)
3. Error logging integration in commands (centralized error log)
4. Validation regex enforcement (^[a-z0-9_]{5,40}$)
5. Monitoring script (.claude/scripts/check_no_name_directories.sh)

**Modified Components**:
1. `.claude/lib/plan/topic-utils.sh` - REMOVE sanitize_topic_name(), strip_artifact_references(), extract_significant_words()
2. `.claude/commands/plan.md` - Replace sanitize call with agent invocation
3. `.claude/commands/research.md` - Replace sanitize call with agent invocation
4. `.claude/commands/debug.md` - Replace sanitize call with agent invocation
5. `.claude/commands/optimize-claude.md` - Replace sanitize call with agent invocation

**Deleted Components** (Clean Break):
- sanitize_topic_name() function (lines 183-257 in topic-utils.sh)
- strip_artifact_references() function (lines 142-163 in topic-utils.sh)
- extract_significant_words() function (lines 30-77 in topic-utils.sh)
- All 82 existing tests for rule-based system

### Error Handling Strategy

**Agent Failure Modes**:
1. **Timeout** (>5s response) → log_command_error("timeout_error") → "no_name"
2. **API Error** (Haiku unavailable) → log_command_error("agent_error") → "no_name"
3. **Validation Failure** (invalid format) → log_command_error("validation_error") → "no_name"
4. **Error Signal** (agent returns TASK_ERROR) → log_command_error("agent_error") → "no_name"
5. **Empty Prompt** (user provides no description) → skip agent → "no_name"

**Error Logging Integration**:
```bash
# Commands source error-handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || exit 1

# Initialize error log
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="/plan"  # or /research, /debug, /optimize-claude
WORKFLOW_ID="workflow_$(date +%s)"

# Log naming failures
if [ "$TOPIC_NAME" = "no_name" ]; then
  log_command_error "agent_error" "Topic naming LLM failed" "prompt=$USER_DESCRIPTION"
fi
```

**Error Consumption Workflow**:
1. Query errors: `/errors --type agent_error --command /plan`
2. Analyze patterns: `/repair --type agent_error --complexity 2`
3. Manual intervention: Rename `NNN_no_name/` directories with monitoring script helper

### Data Flow

**Successful Path**:
```
User: "fix JWT token expiration bug"
  → Command invokes topic-naming-agent via Task tool
  → Agent analyzes: extracts "jwt", "token", "expiration", "fix"
  → Agent returns: TOPIC_NAME_GENERATED: jwt_token_expiration_fix
  → Command validates: matches ^[a-z0-9_]{5,40}$ ✓
  → allocate_and_create_topic("jwt_token_expiration_fix")
  → Creates: 867_jwt_token_expiration_fix/
```

**Failure Path**:
```
User: [complex prompt that confuses LLM]
  → Command invokes topic-naming-agent via Task tool
  → Agent timeout (>5s) or returns invalid format
  → Command logs: log_command_error("timeout_error", ...) or ("validation_error", ...)
  → Fallback: TOPIC_NAME="no_name"
  → allocate_and_create_topic("no_name")
  → Creates: 867_no_name/
  → User sees obvious failure, can investigate with /errors
```

## Implementation Phases

### Phase 1: Topic Naming Agent Development [COMPLETE]
dependencies: []

**Objective**: Create Haiku-based topic naming agent with completion signal protocol and validation

**Complexity**: Medium

**Tasks**:
- [x] Create `.claude/agents/topic-naming-agent.md` with YAML frontmatter (file: .claude/agents/topic-naming-agent.md)
  - Model: haiku-4.5
  - Model justification: Fast deterministic naming (<3s), low cost ($0.003/1K tokens)
  - Fallback model: sonnet-4.5
  - Allowed tools: None (pure semantic analysis)
- [x] Implement 4-step behavioral guidelines following plan-complexity-classifier.md pattern (file: .claude/agents/topic-naming-agent.md)
  - STEP 1: Receive and verify user prompt (not empty)
  - STEP 2: Generate semantic topic name (5-15 word analysis, snake_case, 5-40 chars)
  - STEP 3: Validate format (^[a-z0-9_]{5,40}$, no consecutive underscores)
  - STEP 4: Return completion signal (TOPIC_NAME_GENERATED: name)
- [x] Add error handling section with structured error signals (file: .claude/agents/topic-naming-agent.md)
  - ERROR_CONTEXT JSON format
  - TASK_ERROR signal format
  - Validation error examples
- [x] Document example transformations table (8-10 examples) (file: .claude/agents/topic-naming-agent.md)
  - Complex prompts → semantic names
  - Edge cases (paths, artifacts, verbose descriptions)
  - Show reasoning for each transformation
- [x] Add completion criteria checklist (42 items following plan-architect pattern) (file: .claude/agents/topic-naming-agent.md)

**Testing**:
```bash
# Manual agent test via Claude Code
# Invoke agent with test prompts and verify completion signals
# Validate response time <3s
# Verify format validation works
```

**Expected Duration**: 4 hours

### Phase 2: Library Refactor (Clean Break) [COMPLETE]
dependencies: [1]

**Objective**: Remove all rule-based sanitization logic and prepare integration stubs

**Complexity**: Low

**Tasks**:
- [x] Delete `strip_artifact_references()` function entirely (file: .claude/lib/plan/topic-utils.sh, lines 142-163)
- [x] Delete `extract_significant_words()` function entirely (file: .claude/lib/plan/topic-utils.sh, lines 30-77)
- [x] Delete `sanitize_topic_name()` function entirely (file: .claude/lib/plan/topic-utils.sh, lines 183-257)
- [x] Update file header docstring to remove sanitization references (file: .claude/lib/plan/topic-utils.sh)
- [x] Add validation helper function `validate_topic_name_format()` (file: .claude/lib/plan/topic-utils.sh)
  - Input: topic name string
  - Validation: ^[a-z0-9_]{5,40}$ regex
  - Returns: 0 (valid) or 1 (invalid)
  - Used by commands after parsing agent response
- [x] Verify no other functions depend on deleted functions (search codebase)
- [x] Update topic-utils.sh line count (expect ~150 lines vs ~344 lines before, 55% reduction)

**Testing**:
```bash
# Verify library sources without errors
source .claude/lib/plan/topic-utils.sh

# Verify deleted functions no longer exist
type strip_artifact_references 2>&1 | grep -q "not found"
type extract_significant_words 2>&1 | grep -q "not found"
type sanitize_topic_name 2>&1 | grep -q "not found"

# Verify new validation function works
validate_topic_name_format "jwt_auth_refactor"  # should return 0
validate_topic_name_format "Invalid-Name!"      # should return 1
```

**Expected Duration**: 2 hours

### Phase 3: Command Integration - /plan and /research [COMPLETE]
dependencies: [2]

**Objective**: Integrate LLM naming with agent invocation and error logging for /plan and /research commands

**Complexity**: High

**Tasks**:
- [x] Update `/plan` command to invoke topic-naming-agent (file: .claude/commands/plan.md)
  - Source error-handling library at command start
  - Initialize error log (ensure_error_log_exists)
  - Set COMMAND_NAME="/plan", WORKFLOW_ID
  - Replace sanitize_topic_name call with Task tool invocation
  - Parse TOPIC_NAME_GENERATED signal from agent output
  - Validate format with validate_topic_name_format()
  - Log errors on failure (agent_error, validation_error, timeout_error)
  - Fall back to TOPIC_NAME="no_name" on any failure
  - Pass topic name to allocate_and_create_topic()
- [x] Update `/research` command to invoke topic-naming-agent (file: .claude/commands/research.md)
  - Same pattern as /plan
  - Ensure error logging uses COMMAND_NAME="/research"
- [x] Add timeout handling for agent invocation (5s max) in both commands
  - Log timeout_error if agent exceeds 5s
  - Fallback to "no_name"
- [x] Verify agent invocation uses Task tool (not SlashCommand) per behavioral-injection pattern
- [x] Test both commands with various prompt formats (3-5 test cases each)

**Testing**:
```bash
# Test /plan with good prompt
/plan "Implement JWT authentication with refresh tokens"
# Expect: Topic created with semantic name (e.g., 868_jwt_auth_refresh_tokens/)

# Test /plan with empty prompt (should fallback)
/plan ""
# Expect: 869_no_name/ created, error logged

# Test /research with complex prompt
/research "Analyze existing authentication patterns in codebase for OAuth migration"
# Expect: Topic created with semantic name (e.g., 870_auth_patterns_oauth_migration/)

# Verify error logging
/errors --type agent_error --limit 5
# Should show any naming failures
```

**Expected Duration**: 5 hours

### Phase 4: Command Integration - /debug and /optimize-claude [COMPLETE]
dependencies: [2]

**Objective**: Complete LLM naming integration for remaining commands

**Complexity**: High

**Tasks**:
- [x] Update `/debug` command to invoke topic-naming-agent (file: .claude/commands/debug.md)
  - Source error-handling library
  - Initialize error log
  - Set COMMAND_NAME="/debug"
  - Replace sanitize_topic_name call with agent invocation
  - Parse completion signal, validate, log errors
  - Fallback to "no_name"
- [x] Update `/optimize-claude` command to invoke topic-naming-agent (file: .claude/commands/optimize-claude.md)
  - Same pattern as other commands
  - Set COMMAND_NAME="/optimize-claude"
  - Handle location detection integration (perform_location_detection previously called sanitize)
- [x] Verify all four commands follow identical agent invocation pattern for consistency
- [x] Test edge cases: very long prompts (>200 words), special characters, file paths
- [x] Verify error logging captures all failure modes across all commands

**Testing**:
```bash
# Test /debug with error description
/debug "State machine transitions failing in build command after Phase 2 completion"
# Expect: Semantic name like 871_state_machine_transitions_fail/

# Test /optimize-claude with description
/optimize-claude "Improve command response time by reducing bash block count"
# Expect: Semantic name like 872_reduce_bash_block_count/

# Verify consistent error logging across all commands
/errors --since 1h --summary
# Should show naming errors grouped by command

# Test very long prompt (>200 words)
/plan "$(cat long_description.txt)"
# Expect: Agent extracts core concepts, creates semantic name or falls back to no_name
```

**Expected Duration**: 5 hours

### Phase 5: Testing and Monitoring Infrastructure [COMPLETE]
dependencies: [3, 4]

**Objective**: Create comprehensive test suite and monitoring tools for LLM naming system

**Complexity**: Medium

**Tasks**:
- [x] Create agent unit test suite `.claude/tests/test_topic_naming_agent.sh` (28 tests)
  - Test valid completion signal parsing
  - Test validation regex enforcement (valid/invalid formats)
  - Test various prompt formats (simple, complex, with paths, with artifacts)
  - Test error signal format (TASK_ERROR, ERROR_CONTEXT)
  - Verify all tests pass (28/28) ✓
- [x] Create fallback test suite `.claude/tests/test_topic_naming_fallback.sh` (35 tests)
  - Test no_name fallback on agent timeout
  - Test no_name fallback on validation failure
  - Test no_name fallback on empty prompt
  - Test no_name fallback on agent error signal
  - Verify error logging on each failure mode
  - Verify all tests pass (35/35) ✓
- [x] Create integration test suite `.claude/tests/test_topic_naming_integration.sh` (22 tests)
  - Test /plan command with LLM naming integration
  - Test /research command with LLM naming integration
  - Test /debug command with LLM naming integration
  - Test /optimize-claude command with LLM naming integration
  - Verify agent file structure and STEP workflow
  - Verify error logging integration
  - Verify all tests pass (22/22) ✓
- [x] Create monitoring script `.claude/scripts/check_no_name_directories.sh`
  - List all NNN_no_name/ directories (149 lines)
  - Suggest /errors command for investigation
  - Exit 0 if no failures, exit 1 if failures found
  - Supports -q (quiet) and -v (verbose) modes
- [x] Create manual rename helper `.claude/scripts/rename_no_name_directory.sh`
  - Input: no_name directory path, new semantic name (175 lines)
  - Validate inputs with validate_topic_name_format
  - Rename preserving topic number
  - Interactive confirmation before rename
  - Update any cross-references (if needed)
- [x] Run full test suite and verify 85/85 tests pass

**Testing**:
```bash
# Run all test suites
.claude/tests/test_topic_naming_agent.sh
# Expect: 20/20 passed

.claude/tests/test_topic_naming_fallback.sh
# Expect: 10/10 passed

.claude/tests/test_topic_naming_integration.sh
# Expect: 20/20 passed

# Test monitoring script
.claude/scripts/check_no_name_directories.sh
# Expect: List of no_name dirs or "No naming failures found"

# Test rename helper
.claude/scripts/rename_no_name_directory.sh .claude/specs/999_no_name jwt_auth_fix
# Expect: Directory renamed to 999_jwt_auth_fix/
```

**Expected Duration**: 4 hours

### Phase 6: Documentation and Validation [COMPLETE]
dependencies: [5]

**Objective**: Update all documentation following clean-break standards and validate production deployment

**Complexity**: Low

**Tasks**:
- [x] Update `.claude/docs/concepts/directory-protocols.md` (clean-break rewrite)
  - REMOVE anti-patterns section (lines 86-119) - rule-based logic no longer exists
  - REMOVE automatic prevention section - obsolete with LLM approach
  - UPDATE topic naming section (lines 62-85) to describe LLM approach (present tense)
  - ADD "Fallback Behavior" section explaining no_name sentinel
  - NO historical context ("previously used rule-based system")
- [x] Update `.claude/lib/plan/topic-utils.sh` docstrings
  - Remove sanitization algorithm documentation
  - Document validation function (validate_topic_name_format)
  - Note: Agent invocation happens in commands, not library
- [x] Create new guide `.claude/docs/guides/development/topic-naming-with-llm.md`
  - Explain Haiku agent architecture (how it works now)
  - Document prompt engineering tips for better names
  - Show examples of good vs poor prompts
  - Explain no_name fallback and how to handle it
  - Cost analysis ($2.16/year, <$0.003 per topic)
  - NO migration guides or historical comparisons
- [x] Update CLAUDE.md directory_protocols section
  - Reference new LLM approach
  - Remove stopword/sanitization references
  - Link to topic-naming-with-llm.md guide
- [x] Validate first 20 topic creations in production
  - Track no_name failure rate (target: <5%)
  - Track LLM response time (target: <3s average)
  - Monitor actual cost vs projected ($2.16/year)
  - Collect any user feedback
- [x] Create validation report documenting metrics and any adjustments needed

**Testing**:
```bash
# Validate documentation has no temporal markers
grep -rE "(previously|recently|now supports|used to|no longer)" .claude/docs/concepts/directory-protocols.md
# Expect: No matches (or only legitimate technical usage)

grep -rE "(previously|recently|now supports|used to|no longer)" .claude/docs/guides/development/topic-naming-with-llm.md
# Expect: No matches

# Monitor first 20 topics
watch -n 300 '.claude/scripts/check_no_name_directories.sh'
# Track failure rate over 1 week

# Verify cost analysis
/errors --type agent_error --since 1week | wc -l
# Calculate: (total topics - errors) * $0.003 ≈ $2.16/year projected
```

**Expected Duration**: 3 hours

**Note**: Clean-break documentation means writing as if LLM approach always existed. No "migration from rule-based system" sections, no "improved over previous version" language. Present-focused descriptions only.

## Testing Strategy

### Test Structure

**Total Tests**: 50 tests (vs 82 in rule-based system, 39% reduction)

**Test Categories**:
1. **Agent Unit Tests** (20 tests): Completion signal parsing, validation regex, prompt formats, error signals
2. **Fallback Tests** (10 tests): All failure modes lead to "no_name" + error logging
3. **Integration Tests** (20 tests): All four commands with LLM naming, error logging, directory creation

**Test Reduction Rationale**:
- No stopword filtering tests (feature removed)
- No artifact stripping tests (feature removed)
- No length truncation tests (feature removed)
- No path extraction tests (feature removed)
- Focus: Agent invocation, validation, fallback, integration

### Testing Approach

**Unit Testing**: Test agent behavioral guidelines in isolation
- Mock agent responses with completion signals
- Verify validation regex catches invalid formats
- Test error signal parsing
- Confirm <3s response time requirement

**Fallback Testing**: Verify graceful degradation
- Simulate agent timeout → "no_name" + timeout_error logged
- Simulate invalid format → "no_name" + validation_error logged
- Simulate empty prompt → "no_name" (skip agent)
- Simulate agent error signal → "no_name" + agent_error logged

**Integration Testing**: End-to-end command workflows
- Real agent invocation (not mocked)
- Verify topic directories created correctly
- Confirm error logging integration works
- Test all four commands (/plan, /research, /debug, /optimize-claude)

### Success Metrics

**Test Coverage**: 100% of critical paths
- Agent invocation and parsing: 100%
- Validation logic: 100%
- Fallback mechanisms: 100%
- Error logging: 100%
- Command integration: 100%

**Performance Targets**:
- Agent response time: <3s average (95th percentile <5s)
- Validation overhead: <10ms
- Total naming overhead: <3.5s vs 23ms before (acceptable for human workflows)

**Quality Targets**:
- Test pass rate: 100% (50/50 tests)
- No_name failure rate: <5% in production
- Error logging completeness: 100% of failures captured

## Documentation Requirements

### Files to Update

**Modified** (clean-break rewrite):
1. `.claude/docs/concepts/directory-protocols.md` - Remove rule-based sections, add LLM approach
2. `.claude/lib/plan/topic-utils.sh` - Update docstrings for validation function
3. `CLAUDE.md` - Update directory_protocols section reference

**Created** (new present-focused documentation):
1. `.claude/docs/guides/development/topic-naming-with-llm.md` - Complete LLM naming guide
2. `.claude/agents/topic-naming-agent.md` - Agent behavioral guidelines
3. `.claude/scripts/check_no_name_directories.sh` - Monitoring script
4. `.claude/scripts/rename_no_name_directory.sh` - Rename helper
5. `.claude/tests/test_topic_naming_agent.sh` - Agent unit tests
6. `.claude/tests/test_topic_naming_fallback.sh` - Fallback tests
7. `.claude/tests/test_topic_naming_integration.sh` - Integration tests

**Deleted** (clean break):
1. `.claude/tests/test_topic_name_sanitization.sh` - Old 60 unit tests for rule-based system
2. `.claude/tests/test_directory_naming_integration.sh` - Old 22 integration tests
3. `.claude/scripts/monitor_topic_naming.sh` - Old monitoring (replaced)

### Documentation Standards Compliance

**Writing Standards** (from writing-standards.md):
- Present-focused: Describe LLM approach as current implementation
- No historical markers: No "(New)", "(Updated)", "previously", "now supports"
- Clean narrative: Write as if LLM approach always existed
- No migration guides: Just document how LLM naming works today
- Timeless language: Avoid temporal phrases and version references

**Example Transformations**:

❌ Wrong: "The system was migrated from rule-based sanitization to LLM naming in 2025"
✓ Correct: "The system uses Haiku LLM agent for semantic topic name generation"

❌ Wrong: "Previously, we used stopword filtering. Now we use AI understanding."
✓ Correct: "Topic names are generated through AI semantic analysis of user prompts"

❌ Wrong: "This approach replaces the old sanitization method"
✓ Correct: "Uses Haiku agent to extract core concepts and generate descriptive directory names"

## Dependencies

### External Dependencies
- Claude Haiku 4.5 API availability (critical)
- Existing error-handling library (`.claude/lib/core/error-handling.sh`)
- Existing topic allocation logic (`allocate_and_create_topic`)
- Task tool for agent invocation (available in commands)

### Internal Dependencies
- Phase 1 must complete before Phase 2 (agent must exist before library refactor)
- Phases 3 and 4 depend on Phase 2 (commands need library ready)
- Phase 5 depends on Phases 3 and 4 (tests need integrated commands)
- Phase 6 depends on Phase 5 (docs need validated implementation)

### Rollback Plan

If LLM approach fails (>20% no_name rate or >5s average latency):

**Immediate Rollback**:
```bash
# Revert all changes
cd /home/benjamin/.config
git revert [commit-hash-range]

# Verify revert
git diff HEAD~6 .claude/lib/plan/topic-utils.sh
# Should show old sanitize_topic_name restored
```

**Alternative Fallback**:
```bash
# Temporarily use simple fallback in commands
TOPIC_NAME=$(echo "$DESC" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]//g' | cut -c1-40)
```

**Success Criteria for Rollback Decision**:
- No_name rate >20% after 20 topics
- Average response time >5s
- API availability <95%
- Haiku API cost exceeds $10/month (unexpected)

## Cost Analysis

### LLM Costs (Projected)

**Per Topic Creation**:
- Agent prompt: ~800 tokens (behavioral guidelines)
- User description: ~100-200 tokens (feature description)
- Output: ~50 tokens (topic name + signal)
- Total: ~1,000 tokens per invocation
- Cost: $0.003 (1K tokens × $0.003/1K)

**Monthly Usage** (active development):
- Topic creation rate: ~10-15 per week
- Monthly topics: ~60
- Monthly cost: 60 × $0.003 = **$0.18/month**

**Annual Costs**:
- Annual topics: ~720
- Annual cost: 720 × $0.003 = **$2.16/year**

### Development Cost Savings

**Rule-Based System Maintenance**:
- Stopword curation: ~1 hour/month
- Artifact pattern updates: ~0.5 hours/month
- Test maintenance: ~0.5 hours/month
- Documentation updates: ~0.5 hours/month
- Bug fixes and edge cases: ~1 hour/month
- **Total**: ~3.5 hours/month × $50/hour = **$175/month** = **$2,100/year**

**LLM System Maintenance**:
- Agent prompt tuning: ~1 hour/quarter = ~0.25 hours/month
- Monitoring no_name failures: ~0.25 hours/month
- **Total**: ~0.5 hours/month × $50/hour = **$25/month** = **$300/year**

**Net Savings**: $2,100 - $300 - $2.16 = **$1,797.84/year** (85.7% reduction)

### ROI Analysis

**Implementation Cost**: 18 hours × $50/hour = $900
**Annual Savings**: $1,797.84/year
**Payback Period**: 900 ÷ 1,797.84 = **0.5 years (6 months)**

After 6 months, every dollar spent on LLM naming saves $5.50 in maintenance costs (850% ROI).

## Risk Assessment

### Technical Risks

**Risk 1: Haiku API Availability**
- **Probability**: Low (Claude API uptime >99.5%)
- **Impact**: Medium (fallback to "no_name" works, but user experience degrades)
- **Mitigation**: Fallback sentinel makes failures visible, error logging enables monitoring

**Risk 2: LLM Naming Quality**
- **Probability**: Medium (semantic understanding may vary)
- **Impact**: Low (poor names visible as "no_name" or confusing semantic names)
- **Mitigation**: First 20 topics validation, prompt engineering in agent guidelines

**Risk 3: Response Time Degradation**
- **Probability**: Low (Haiku optimized for <5s responses)
- **Impact**: Medium (slower topic creation vs 23ms rule-based)
- **Mitigation**: 5s timeout enforced, fallback to "no_name", monitoring script

**Risk 4: Cost Overruns**
- **Probability**: Very Low (fixed cost per topic, predictable usage)
- **Impact**: Very Low ($2.16/year even at 720 topics)
- **Mitigation**: Monthly cost monitoring, usage alerts at $5/month threshold

### Implementation Risks

**Risk 5: Command Integration Complexity**
- **Probability**: Medium (four commands need identical pattern)
- **Impact**: Medium (inconsistent behavior across commands)
- **Mitigation**: Test all four commands in Phase 3-4, integration test suite

**Risk 6: Error Logging Gaps**
- **Probability**: Low (pattern already exists in other commands)
- **Impact**: Low (reduces visibility into failures)
- **Mitigation**: Explicit error logging tasks in Phases 3-4, fallback tests verify logging

**Risk 7: Documentation Drift**
- **Probability**: Low (clean-break removes historical context)
- **Impact**: Low (confusion about "old" vs "new" approach)
- **Mitigation**: Validation checks for temporal markers, present-focused writing enforced

## Validation Plan

### Week 1: Initial Deployment

**Metrics to Track**:
- First 5 topic creations (all commands)
- No_name failure rate (expect: 0-5%)
- Agent response time (expect: <3s average)
- Error log entries (expect: minimal)

**Success Criteria**:
- At least 3/5 topics have semantic names (60% success)
- No response times >5s
- No API errors
- Error logging captures any failures

### Week 2-3: Extended Validation

**Metrics to Track**:
- Total topics: 20 (across all commands)
- No_name rate: <5% (1/20 acceptable)
- Average response time: <3s
- Cost: ~$0.06 (20 × $0.003)

**Success Criteria**:
- No_name rate ≤5%
- 95th percentile response time <5s
- Actual cost matches projected
- No user complaints about naming quality

### Week 4: Production Acceptance

**Decision Point**: Continue with LLM naming or rollback to rule-based?

**Continue if**:
- No_name rate <5%
- Response time acceptable (<3s avg)
- Cost on track ($2.16/year projected)
- User satisfaction neutral or positive

**Rollback if**:
- No_name rate >20%
- Response time >5s average
- API availability issues (<95%)
- User dissatisfaction with semantic names

**Document Results**:
- Validation report with metrics
- Lessons learned
- Agent prompt tuning recommendations (if needed)
- Cost analysis (actual vs projected)
