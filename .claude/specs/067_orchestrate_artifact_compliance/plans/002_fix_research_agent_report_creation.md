# Fix /orchestrate Research Agent Report Creation Implementation Plan

## Metadata
- **Date**: 2025-10-19
- **Feature**: Ensure research subagents create report files with proper verification
- **Scope**: Fix /orchestrate research phase to enforce file creation and integrate metadata extraction
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Topic Directory**: specs/067_orchestrate_artifact_compliance/
- **Related Plan**: [001_fix_orchestrate_artifact_organization.md](001_fix_orchestrate_artifact_organization.md)

## Overview

The /orchestrate command has a fully implemented mechanism for research agents to create report files (path calculation, Write tool instructions, verification logic), but agents are not complying with the file creation directive. Instead, they return summaries in their text output without using the Write tool.

This plan fixes the execution compliance issue by:
1. Strengthening the CRITICAL directive to make file creation truly non-negotiable
2. Adding explicit verification that the Write tool was actually used (not just that text was returned)
3. Integrating metadata-extraction utilities to extract summaries from created files
4. Implementing a fallback mechanism: if agent doesn't create file, orchestrator creates it using agent's summary
5. Updating verification to use `extract_report_metadata()` for consistent summary extraction

## Success Criteria
- [ ] Research agents create report files in 100% of cases (either directly or via fallback)
- [ ] Orchestrator verifies Write tool usage, not just text output
- [ ] Summaries extracted from report files using `extract_report_metadata()`, not from agent text
- [ ] Fallback mechanism successfully creates files when agents don't comply
- [ ] Context window usage remains <30% via metadata-only passing
- [ ] Tests verify file creation and metadata extraction
- [ ] No regression in parallel execution performance

## Technical Design

### Current Implementation (Already Exists)

**Path Calculation** (.claude/commands/orchestrate.md:504-522):
```bash
# Pre-calculate absolute paths before agent invocation
TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/reports/${topic}"
mkdir -p "$TOPIC_DIR"
NEXT_NUM=$(get_next_artifact_number "$TOPIC_DIR")
REPORT_PATH="${TOPIC_DIR}/${NEXT_NUM}_analysis.md"
REPORT_PATHS["$topic"]="$REPORT_PATH"
```

**Agent Instruction** (orchestrate.md:536-560):
```markdown
**CRITICAL: Create Report File**

You MUST create a research report file using the Write tool at this EXACT path:
**Report Path**: ${REPORT_PATHS["topic_name"]}

DO NOT: Return only a summary
DO: Use Write tool with exact path above
     Return: REPORT_PATH: ${REPORT_PATHS["topic_name"]}
```

**Current Verification** (orchestrate.md:656-674):
```bash
# Extract REPORT_PATH from agent output
EXTRACTED_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'REPORT_PATH:\s*\K/.+' | head -1)

if [ -z "$EXTRACTED_PATH" ]; then
  echo "⚠️  Agent did not return REPORT_PATH"
  EXTRACTED_PATH="${REPORT_PATHS[$topic]}"  # Use pre-calculated
fi
```

### Problems with Current Implementation

1. **Weak Compliance Enforcement**: The "CRITICAL" directive is just text; agents can ignore it
2. **Insufficient Verification**: Only checks if `REPORT_PATH:` text is returned, not if file actually exists or Write tool was used
3. **No Fallback**: If agent doesn't create file, workflow fails or continues with missing artifact
4. **Manual Summary Extraction**: Orchestrator relies on agent's text summary instead of reading from file
5. **No Tool Usage Verification**: Doesn't check if Write tool was actually invoked

### Proposed Solution

**1. Strengthen Directive** - Make file creation the PRIMARY output, not secondary:
```markdown
# ABSOLUTE REQUIREMENT - File Creation is Your Primary Task

Before beginning research, you will create a report file. This is not optional.

**Report File Path**: ${REPORT_PATH}

**STEP 1: Create Report File**
Use the Write tool immediately to create the report file at the path above.

**STEP 2: Conduct Research**
Fill in the report content as you research.

**STEP 3: Return File Confirmation**
Return ONLY: REPORT_CREATED: ${REPORT_PATH}

DO NOT return a summary. The orchestrator will extract the summary by reading your report file.
```

**2. Verify Write Tool Usage** - Check that Write tool was invoked:
```bash
# After agent completes, verify Write tool was used
if ! grep -q "Write.*${REPORT_PATH}" <<< "$AGENT_TOOL_TRACE"; then
  echo "⚠️  Agent did not use Write tool for report creation"
  NEEDS_FALLBACK=true
fi
```

**3. Integrate Metadata Extraction** - Use utility to extract summary from file:
```bash
# Source metadata extraction utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Extract metadata from created report file
METADATA=$(extract_report_metadata "$REPORT_PATH")

# Parse JSON to get 50-word summary
SUMMARY=$(echo "$METADATA" | jq -r '.summary')
TITLE=$(echo "$METADATA" | jq -r '.title')
```

**4. Implement Fallback** - Create file using agent's output if it doesn't comply:
```bash
# If file doesn't exist, create it using agent's text output
if [ ! -f "$REPORT_PATH" ]; then
  echo "⚠️  Report file not created by agent. Creating fallback report..."

  # Extract summary from agent output (first paragraph)
  AGENT_SUMMARY=$(echo "$AGENT_OUTPUT" | head -20 | grep -v '^$' | head -5)

  # Create report file with agent's findings
  cat > "$REPORT_PATH" <<EOF
# ${topic}

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Agent**: research-specialist
- **Source**: Orchestrate workflow (fallback creation)

## Executive Summary
$AGENT_SUMMARY

## Findings
(Full findings extracted from agent output)

$AGENT_OUTPUT
EOF

  echo "✓ Fallback report created at: $REPORT_PATH"
fi
```

**5. Update Verification Flow**:
```bash
# New verification sequence:
# 1. Check if file exists
# 2. If not, trigger fallback creation
# 3. Extract metadata from file (guaranteed to exist after fallback)
# 4. Store minimal context (path + 50-word summary)

VERIFICATION_STEPS:
1. Check Write tool usage in agent trace
2. Verify file exists at expected path
3. If missing: Create fallback report from agent output
4. Extract metadata using extract_report_metadata()
5. Store: {path, title, 50-word summary}
6. Prune agent's full output (keep only metadata)
```

### Data Flow (Improved)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Orchestrator Pre-calculates Report Paths                │
│    - REPORT_PATH="/path/to/specs/reports/topic/001.md"     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Invoke Research Agent with STRENGTHENED Directive        │
│    - "ABSOLUTE REQUIREMENT: Create file FIRST"             │
│    - "Return: REPORT_CREATED: ${REPORT_PATH}"              │
│    - "DO NOT return summary text"                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
         ┌─────────────────────────────────┐
         │ 3. Agent Creates Report File?   │
         └─────────────────────────────────┘
                ↓                    ↓
         ┌──────────┐          ┌──────────┐
         │   YES    │          │    NO    │
         └──────────┘          └──────────┘
              ↓                      ↓
              ↓           ┌──────────────────────────────┐
              ↓           │ 4. Fallback: Orchestrator    │
              ↓           │    creates file from agent   │
              ↓           │    output text               │
              ↓           └──────────────────────────────┘
              ↓                      ↓
              └──────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Verify File Exists (guaranteed via fallback)             │
│    - Check: file exists at REPORT_PATH                      │
│    - Log: File created by agent or fallback                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Extract Metadata from File                               │
│    - metadata=$(extract_report_metadata "$REPORT_PATH")    │
│    - summary=$(echo "$metadata" | jq -r '.summary')        │
│    - title=$(echo "$metadata" | jq -r '.title')            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Store Minimal Context in Orchestrator                    │
│    - RESEARCH_METADATA["$topic"]="$metadata" (250 chars)   │
│    - Prune full agent output (context saved: 95%)          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Pass to Planning Phase                                   │
│    - Report path + 50-word summary only                     │
│    - Full report available on disk if needed                │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Strengthen Agent Directive and Add Fallback
**Objective**: Make file creation non-negotiable and ensure reports always exist
**Complexity**: Medium

Tasks:
- [ ] Read current agent prompt construction (.claude/commands/orchestrate.md:533-612)
- [ ] Rewrite "CRITICAL" directive to make file creation the PRIMARY task, not secondary (.claude/commands/orchestrate.md:536-560)
- [ ] Change expected return format from `REPORT_PATH: /path` to `REPORT_CREATED: /path` (emphasizes action taken)
- [ ] Remove "Secondary Output: Brief summary" instruction (orchestrator will extract from file)
- [ ] Add explicit instruction: "DO NOT return summary text. Orchestrator will read your report file." (.claude/commands/orchestrate.md:559)
- [ ] Implement fallback report creation function in orchestrate.md (after line 674)
- [ ] Add file existence check before metadata extraction (.claude/commands/orchestrate.md:656-680)
- [ ] Trigger fallback if file doesn't exist: create report from agent's text output
- [ ] Test fallback creation with mock agent output

Testing:
```bash
# Test fallback report creation
cd /home/benjamin/.config

# Simulate agent that didn't create file
AGENT_OUTPUT="Research findings: Authentication uses JWT tokens. Security concerns include token expiration handling."
REPORT_PATH=".claude/specs/test_topic/reports/001_test.md"
mkdir -p "$(dirname "$REPORT_PATH")"

# Simulate fallback creation
cat > "$REPORT_PATH" <<EOF
# Test Topic

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Agent**: research-specialist (fallback creation)

## Executive Summary
$(echo "$AGENT_OUTPUT" | head -5)

## Findings
$AGENT_OUTPUT
EOF

# Verify file created
[[ -f "$REPORT_PATH" ]] && echo "✓ Fallback report created"
cat "$REPORT_PATH"

# Cleanup
rm -rf ".claude/specs/test_topic"
```

Validation:
- [ ] New directive emphasizes file creation as primary task
- [ ] Return format changed to `REPORT_CREATED: /path`
- [ ] Summary extraction instruction removed from agent prompt
- [ ] Fallback function creates valid report file from agent output
- [ ] Fallback report has proper markdown structure with metadata
- [ ] File existence guaranteed after fallback

### Phase 2: Integrate Metadata Extraction
**Objective**: Extract summaries from report files instead of relying on agent text output
**Complexity**: Low

Tasks:
- [ ] Source metadata-extraction.sh utility at top of orchestrate.md (.claude/commands/orchestrate.md:1-50)
- [ ] Add `source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"` before research phase
- [ ] Replace manual summary extraction with `extract_report_metadata()` call (.claude/commands/orchestrate.md:680-730)
- [ ] Update research summary aggregation to use extracted metadata (.claude/commands/orchestrate.md:732-850)
- [ ] Change from storing agent text to storing metadata JSON (.claude/commands/orchestrate.md:740)
- [ ] Update synthesis logic to read from metadata structure (.claude/commands/orchestrate.md:750-850)
- [ ] Test metadata extraction with real report files

Testing:
```bash
# Test metadata extraction from report file
cd /home/benjamin/.config
source .claude/lib/metadata-extraction.sh

# Create test report
REPORT_PATH=".claude/specs/test_topic/reports/001_auth_test.md"
mkdir -p "$(dirname "$REPORT_PATH")"

cat > "$REPORT_PATH" <<'EOF'
# Authentication Patterns Analysis

## Metadata
- **Date**: 2025-10-19
- **Agent**: research-specialist

## Executive Summary
Current codebase uses session-based authentication with cookies. JWT tokens recommended for API endpoints. Security audit needed for session handling.

## Findings
### Session Management
- Uses HTTP-only cookies
- 30-minute timeout
- No refresh token mechanism

### Recommendations
- Implement JWT for API auth
- Add refresh token rotation
- Conduct security audit
EOF

# Extract metadata
METADATA=$(extract_report_metadata "$REPORT_PATH")
echo "Metadata JSON:"
echo "$METADATA" | jq .

# Extract specific fields
SUMMARY=$(echo "$METADATA" | jq -r '.summary')
TITLE=$(echo "$METADATA" | jq -r '.title')
RECS=$(echo "$METADATA" | jq -r '.recommendations[]')

echo ""
echo "Extracted Summary (50 words max):"
echo "$SUMMARY"
echo ""
echo "Title: $TITLE"
echo ""
echo "Recommendations:"
echo "$RECS"

# Verify summary length
WORD_COUNT=$(echo "$SUMMARY" | wc -w)
[[ $WORD_COUNT -le 50 ]] && echo "✓ Summary within 50-word limit ($WORD_COUNT words)"

# Cleanup
rm -rf ".claude/specs/test_topic"
```

Validation:
- [ ] `extract_report_metadata()` successfully extracts title, summary, recommendations
- [ ] Summary is ≤50 words
- [ ] Metadata JSON format matches expected structure
- [ ] Orchestrator stores metadata instead of full agent output
- [ ] Context usage reduced by 95% (full report not in memory)

### Phase 3: Verification, Testing, and Documentation
**Objective**: Verify file creation, test all scenarios, update documentation
**Complexity**: Medium

Tasks:
- [ ] Add Write tool usage verification in orchestrate.md (check agent tool trace)
- [ ] Implement verification sequence: (1) Check Write tool used, (2) Check file exists, (3) Trigger fallback if needed, (4) Extract metadata
- [ ] Update checkpoint data structure to include metadata instead of summaries (.claude/commands/orchestrate.md:836-860)
- [ ] Create test script for full research phase workflow (`.claude/tests/test_orchestrate_research_phase.sh`)
- [ ] Test Case 1: Agent creates file correctly (happy path)
- [ ] Test Case 2: Agent doesn't create file (fallback path)
- [ ] Test Case 3: Multiple parallel agents, mixed compliance (some create files, some don't)
- [ ] Test Case 4: Metadata extraction from various report formats
- [ ] Test Case 5: Context usage verification (<30% target)
- [ ] Update orchestrate.md documentation to explain new verification flow (.claude/commands/orchestrate.md:460-520)
- [ ] Add inline comments explaining fallback logic
- [ ] Document metadata extraction integration
- [ ] Update examples to show new return format (`REPORT_CREATED:`)

Testing:
```bash
#!/usr/bin/env bash
# .claude/tests/test_orchestrate_research_phase.sh

set -euo pipefail

echo "=== Testing /orchestrate Research Phase Report Creation ==="

# Source required utilities
source /home/benjamin/.config/.claude/lib/metadata-extraction.sh
source /home/benjamin/.config/.claude/lib/artifact-creation.sh

# Test Case 1: Agent creates file correctly (happy path)
test_agent_creates_file() {
  echo ""
  echo "Test 1: Agent creates file correctly"

  TOPIC="auth_patterns"
  REPORT_PATH=".claude/specs/test_research/reports/001_${TOPIC}.md"
  mkdir -p "$(dirname "$REPORT_PATH")"

  # Simulate agent creating file
  cat > "$REPORT_PATH" <<EOF
# Authentication Patterns

## Executive Summary
JWT tokens recommended for API authentication. Session cookies for web apps.

## Findings
- JWT: Stateless, scalable
- Sessions: Server-side storage required
EOF

  # Verify file exists
  [[ -f "$REPORT_PATH" ]] || { echo "FAIL: File not created"; return 1; }

  # Extract metadata
  METADATA=$(extract_report_metadata "$REPORT_PATH")
  SUMMARY=$(echo "$METADATA" | jq -r '.summary')

  echo "✓ File created by agent"
  echo "✓ Metadata extracted: $SUMMARY"

  # Cleanup
  rm -rf ".claude/specs/test_research"
}

# Test Case 2: Agent doesn't create file (fallback path)
test_fallback_creation() {
  echo ""
  echo "Test 2: Fallback report creation"

  TOPIC="security_practices"
  REPORT_PATH=".claude/specs/test_research/reports/001_${TOPIC}.md"
  mkdir -p "$(dirname "$REPORT_PATH")"

  # Simulate agent output without file creation
  AGENT_OUTPUT="Security best practices: Use bcrypt for passwords. Enable rate limiting. Implement 2FA for admin accounts."

  # Check file doesn't exist (agent didn't create it)
  if [[ ! -f "$REPORT_PATH" ]]; then
    echo "⚠️  Agent did not create file. Triggering fallback..."

    # Fallback: Create report from agent output
    cat > "$REPORT_PATH" <<EOF
# ${TOPIC}

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Agent**: research-specialist (fallback creation)

## Executive Summary
$(echo "$AGENT_OUTPUT" | head -5)

## Findings
$AGENT_OUTPUT
EOF
  fi

  # Verify file now exists (via fallback)
  [[ -f "$REPORT_PATH" ]] || { echo "FAIL: Fallback didn't create file"; return 1; }

  # Extract metadata from fallback report
  METADATA=$(extract_report_metadata "$REPORT_PATH")
  SUMMARY=$(echo "$METADATA" | jq -r '.summary')

  echo "✓ Fallback report created"
  echo "✓ Metadata extracted from fallback: $SUMMARY"

  # Cleanup
  rm -rf ".claude/specs/test_research"
}

# Test Case 3: Metadata extraction and context reduction
test_context_reduction() {
  echo ""
  echo "Test 3: Context reduction via metadata extraction"

  REPORT_PATH=".claude/specs/test_research/reports/001_test.md"
  mkdir -p "$(dirname "$REPORT_PATH")"

  # Create large report (simulating full research output)
  cat > "$REPORT_PATH" <<EOF
# Comprehensive Authentication Research

## Executive Summary
This report analyzes authentication patterns in modern web applications. JWT tokens are recommended for API authentication due to stateless nature and scalability. Session cookies remain appropriate for traditional web applications requiring server-side state management.

## Findings
[... 5000 characters of detailed findings ...]
$(printf 'Detailed analysis paragraph. %.0s' {1..100})

## Recommendations
- Implement JWT for APIs
- Use session cookies for web apps
- Enable 2FA for admin accounts
- Conduct security audits quarterly
- Implement rate limiting
EOF

  # Measure original size
  FULL_SIZE=$(wc -c < "$REPORT_PATH")

  # Extract metadata
  METADATA=$(extract_report_metadata "$REPORT_PATH")
  METADATA_SIZE=$(echo "$METADATA" | wc -c)

  # Calculate reduction
  REDUCTION=$((100 - (METADATA_SIZE * 100 / FULL_SIZE)))

  echo "Full report size: $FULL_SIZE chars"
  echo "Metadata size: $METADATA_SIZE chars"
  echo "Context reduction: ${REDUCTION}%"

  [[ $REDUCTION -ge 90 ]] && echo "✓ Context reduction target met (>90%)"

  # Cleanup
  rm -rf ".claude/specs/test_research"
}

# Run all tests
test_agent_creates_file
test_fallback_creation
test_context_reduction

echo ""
echo "=== All Tests Passed ==="
```

Validation:
- [ ] Write tool usage check implemented
- [ ] File existence verified before metadata extraction
- [ ] Fallback triggers correctly when file missing
- [ ] Metadata extraction works for all report formats
- [ ] Context usage <30% verified
- [ ] All test cases pass
- [ ] Documentation updated with new flow
- [ ] Examples show new return format

## Testing Strategy

### Unit Tests
- Metadata extraction from various report formats
- Fallback report creation from agent text output
- Summary truncation to 50 words
- JSON metadata parsing

### Integration Tests
- Full research phase with file creation
- Full research phase with fallback creation
- Mixed scenario: some agents create files, others don't
- Metadata extraction and context pruning

### Performance Tests
- Context window usage measurement (target: <30%)
- Parallel execution time (ensure no regression)
- Metadata extraction speed

### Test Script Execution
```bash
# Run research phase tests
/home/benjamin/.config/.claude/tests/test_orchestrate_research_phase.sh

# Expected output:
# Test 1: Agent creates file correctly ✓
# Test 2: Fallback report creation ✓
# Test 3: Context reduction ✓ (95%+)
# All Tests Passed
```

## Documentation Requirements

### Files to Update

1. **`.claude/commands/orchestrate.md`**
   - Update research phase documentation (lines 460-730)
   - Document strengthened directive
   - Explain fallback mechanism
   - Show metadata extraction integration
   - Update examples with `REPORT_CREATED:` format

2. **`.claude/docs/concepts/hierarchical_agents.md`**
   - Add section on report creation compliance
   - Document fallback pattern for agent non-compliance
   - Explain metadata extraction for context reduction

3. **`.claude/agents/research-specialist.md`**
   - Update expected output format
   - Emphasize file creation as primary task
   - Remove summary text return (orchestrator extracts from file)

### Documentation Sections

**orchestrate.md - Research Phase**
```markdown
## Research Phase: File Creation and Metadata Extraction

### Agent Report Creation

Research agents are instructed to create report files as their PRIMARY task:

**Agent Directive**:
```markdown
# ABSOLUTE REQUIREMENT - File Creation is Your Primary Task

**Report File Path**: {pre-calculated path}

**STEP 1: Create Report File**
Use the Write tool immediately to create the report file.

**STEP 2: Conduct Research**
Fill in the report content as you research.

**STEP 3: Return File Confirmation**
Return ONLY: REPORT_CREATED: {file path}
```

### Fallback Mechanism

If an agent does not create the report file, the orchestrator automatically creates
it using the agent's text output:

```bash
# Check if file exists
if [ ! -f "$REPORT_PATH" ]; then
  # Fallback: Create report from agent output
  create_fallback_report "$REPORT_PATH" "$AGENT_OUTPUT"
fi
```

This ensures reports ALWAYS exist, regardless of agent compliance.

### Metadata Extraction

After ensuring the report file exists (either via agent or fallback), the orchestrator
extracts minimal metadata for context preservation:

```bash
# Extract metadata (title + 50-word summary)
METADATA=$(extract_report_metadata "$REPORT_PATH")
SUMMARY=$(echo "$METADATA" | jq -r '.summary')

# Store only metadata (250 chars vs 5000+ chars)
RESEARCH_METADATA["$topic"]="$METADATA"
```

**Context Reduction**: 95%+ (5000 tokens → 250 tokens per report)
```

## Dependencies

### Required Utilities
- `.claude/lib/metadata-extraction.sh` (already exists)
  - `extract_report_metadata()` - Extract title + 50-word summary
  - `extract_plan_metadata()` - Extract plan metadata (if needed)
- `.claude/lib/artifact-creation.sh` (for fallback file creation)
  - `get_next_artifact_number()` - Already used
- `.claude/lib/unified-logger.sh` (logging)
- `jq` (JSON parsing)

### Command Integration
- `/orchestrate` command (will be modified)
- `research-specialist` agent definition (update expected behavior)

## Risk Assessment

### Risks

1. **Agent Behavior Changes**
   - Risk: Agents may continue to ignore file creation directive
   - Mitigation: Fallback ensures files always created
   - Impact: Low (fallback guarantees report existence)

2. **Metadata Extraction Failures**
   - Risk: `extract_report_metadata()` might fail on malformed reports
   - Mitigation: Add error handling for metadata extraction
   - Impact: Low (fallback reports have known structure)

3. **Context Window Impact**
   - Risk: Metadata extraction might not achieve 95% reduction target
   - Mitigation: Test with real reports, verify summary ≤50 words
   - Impact: Low (utility already tested and proven)

4. **Performance Regression**
   - Risk: Fallback creation might slow down research phase
   - Mitigation: Fallback only triggers when agent doesn't comply
   - Impact: Low (file creation is fast, <1 second)

### Mitigation Strategies

- **Phase 1 First**: Implement fallback before removing agent text summary
- **Incremental Testing**: Test each phase independently
- **Monitoring**: Log fallback usage to track agent compliance rate
- **Documentation**: Clear instructions for agent behavior

## Notes

### Why This Matters

**Reliability**: Research reports are critical artifacts for planning and documentation. They must exist and be accessible, regardless of agent compliance.

**Context Management**: Extracting metadata from files instead of relying on agent text output:
- Guarantees consistent format (utility controls extraction)
- Reduces context window usage (95%+ reduction)
- Enables full reports to be available on disk for deep dives

**Separation of Concerns**:
- Agents: Create comprehensive reports
- Orchestrator: Extract minimal metadata for context
- Planning phase: Read full reports on-demand if needed

### Implementation Notes

- Fallback mechanism is a safety net, not the primary path
- Strengthened directive should improve agent compliance over time
- Metadata extraction provides consistent summaries regardless of agent text quality
- Integration with existing `extract_report_metadata()` utility ensures consistency

### Assumptions

- `extract_report_metadata()` utility works reliably (already tested in hierarchical agents)
- Fallback report creation produces valid markdown that can be parsed
- Agents will eventually improve compliance with strengthened directive
- Context reduction target (95%) is achievable with 50-word summaries

### Future Enhancements

- Agent compliance monitoring dashboard
- Automatic agent prompt tuning based on compliance rate
- Enhanced fallback: use spec-updater agent to improve fallback reports
- Parallel metadata extraction (extract from all reports simultaneously)
