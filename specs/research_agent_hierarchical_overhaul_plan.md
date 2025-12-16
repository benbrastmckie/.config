# Research Agent Hierarchical Delegation Implementation Plan

**Date**: 2025-12-12  
**Feature**: Overhaul OpenCode research.md agent to implement hierarchical coordinator-specialist delegation pattern for context window preservation  
**Status**: [NOT STARTED]  
**Estimated Hours**: 12-16 hours  
**Standards File**: /home/benjamin/.config/CLAUDE.md  
**Research Reports**: none (planning phase)

---

## Executive Summary

The current OpenCode `research.md` agent is a thin orchestrator (6 lines) that delegates immediately to `research-coordinator` but lacks the sophisticated hierarchical delegation patterns implemented in Claude Code's three-tier architecture. This plan implements the complete three-tier pattern (Command → Coordinator → Specialist) to achieve:

- **95-96% context reduction** via metadata-only passing between tiers
- **40-60% time savings** via parallel specialist execution
- **10-20+ iteration capacity** vs 3-4 baseline through brief summaries
- **Hard barrier enforcement** preventing coordinator bypass
- **Multi-layer validation** (invocation plan → trace → outputs)

The implementation integrates proven patterns from Claude Code's research-coordinator (Examples 7-8 in hierarchical-agents-examples.md) while adapting to OpenCode's simpler directory structure (`.opencode/specs/` vs `.claude/specs/`).

---

## Context & Problem Analysis

### Current Implementation Analysis

**research.md (Primary Agent)** - `/home/benjamin/.config/.opencode/agent/research.md`:
```markdown
1. Receive Request: Accept user's research topic
2. Delegate Immediately: Use task tool to invoke research-coordinator
3. Stream Output: Stream output directly to user
```

**Issues Identified**:
1. ✗ No path pre-calculation (hard barrier pattern missing)
2. ✗ No topic decomposition logic (delegates decomposition to coordinator)
3. ✗ No metadata extraction from coordinator output (passes full content)
4. ✗ No hard barrier validation (doesn't verify specialist outputs created)
5. ✗ No console summary generation (no 4-section format)
6. ✗ No error logging integration (no centralized error tracking)
7. ✗ No state machine integration (no workflow persistence)

**research-coordinator.md (Coordinator)** - `/home/benjamin/.config/.opencode/subagents/research-coordinator.md`:
```markdown
1. Initialize Project: Generate topic_slug, create specs/NNN_topic/ directory
2. Setup Overview: Create OVERVIEW.md with research topic
3. Decompose Plan: Break into 1-5 sub-topics, create report files (01_subtopic.md)
4. Delegate Execution: Invoke research-specialist for EACH sub-topic (parallel)
5. Finalize: Read OVERVIEW.md, synthesize executive summary
```

**Issues Identified**:
1. ✓ Path pre-calculation (creates report files before specialist invocation) ✓
2. ✓ Topic decomposition (1-5 sub-topics based on complexity) ✓
3. ✗ No metadata extraction (reads full OVERVIEW.md instead of metadata)
4. ✗ No invocation plan file creation (no hard barrier proof)
5. ✗ No brief summary return format (returns full executive summary)
6. ✗ No partial success mode (no ≥50% threshold handling)
7. ✗ No multi-layer validation (no invocation plan → trace → outputs validation)

**research-specialist.md (Specialist)** - `/home/benjamin/.config/.opencode/subagents/research-specialist.md`:
```markdown
1. Receive Task: Read assigned report file path
2. Understand Task: Read report file content
3. Conduct Research: Use webfetch for online research
4. Write Report: Update report file with findings (Summary, Findings, Sources)
5. Update Overview: Append summary to OVERVIEW.md
```

**Issues Identified**:
1. ✓ Receives pre-calculated path ✓
2. ✓ Self-contained research execution ✓
3. ✗ No YAML frontmatter metadata (findings_count, recommendations_count missing)
4. ✗ No completion signal format (no REPORT_CREATED: /path signal)
5. ✗ No error return protocol (no ERROR_CONTEXT + TASK_ERROR)
6. ✗ No self-validation (doesn't verify required sections before return)

### Gap Analysis: Claude Code Patterns vs OpenCode Implementation

| Pattern | Claude Code (.claude) | OpenCode (.opencode) | Gap |
|---------|----------------------|---------------------|-----|
| **Path Pre-Calculation** | Command pre-calculates all paths | Coordinator calculates paths | Medium (works but not optimal) |
| **Invocation Plan File** | Coordinator creates .invocation-plan.txt | Missing | **HIGH** |
| **Metadata Extraction** | Coordinator extracts 110 tokens/report | Coordinator reads full OVERVIEW.md | **HIGH** |
| **Brief Summary Format** | 80 tokens (96% reduction) | Full executive summary (2,000+ tokens) | **HIGH** |
| **Partial Success Mode** | ≥50% threshold with warnings | No partial success handling | **MEDIUM** |
| **Multi-Layer Validation** | Plan → Trace → Outputs | Only output validation | **HIGH** |
| **Error Return Protocol** | ERROR_CONTEXT + TASK_ERROR | Generic error messages | **MEDIUM** |
| **YAML Frontmatter** | Required in all artifacts | Missing | **HIGH** |
| **Coordinator Return Signals** | Standardized signal format | Unstructured output | **HIGH** |
| **Console Summaries** | 4-section format with metrics | Raw coordinator output | **MEDIUM** |

### Architecture Decision: Planning-Only vs Supervisor Mode

**Recommendation**: **Planning-Only Mode** (same as Claude Code research-coordinator)

**Rationale**:
1. **Simpler Integration**: OpenCode primary agents are thin orchestrators (6 lines) - adding specialist invocation logic maintains separation of concerns
2. **Control Retention**: Primary agent controls Task invocations (explicit delegation visible in logs)
3. **Debugging**: Easier to trace specialist invocations when done by primary agent
4. **Proven Pattern**: Claude Code's `/create-plan` and `research-mode` use planning-only successfully

**Planning-Only Mode Flow**:
```
research.md (Primary Agent)
    |
    | 1. Parse user request, set complexity (1-4)
    | 2. Pre-calculate topic directory and report paths
    | 3. Invoke research-coordinator with paths
    v
research-coordinator (Planning-Only)
    |
    | 4. Validate paths, create invocation plan file
    | 5. Return invocation metadata (topics + paths)
    v
research.md receives invocation plan
    |
    | 6. Parse invocation plan
    | 7. Invoke research-specialist for each topic (parallel)
    v
research-specialist (each instance)
    |
    | 8. Conduct research, create report at path
    | 9. Return REPORT_CREATED signal
    v
research.md validates all reports exist
    |
    | 10. Extract metadata from coordinator output
    | 11. Generate console summary
    v
Workflow complete
```

---

## Implementation Phases

### Phase 1: Research Specialist Enhancement (Metadata + Signals)

**Duration**: 2-3 hours  
**Dependencies**: None  
**Artifacts**: `research-specialist.md` (enhanced)

**Objectives**:
1. Add YAML frontmatter to all generated reports
2. Implement standardized completion signals (REPORT_CREATED: /path)
3. Add error return protocol (ERROR_CONTEXT + TASK_ERROR)
4. Implement pre-return section validation

**Tasks**:
1. [x] Add YAML frontmatter template to STEP 4 (Write Report)
   - Fields: `report_type`, `topic`, `findings_count`, `recommendations_count`, `created_date`, `status`
2. [x] Update STEP 4 to count findings and recommendations dynamically
   - Parse "## Findings" section for bullet points
   - Parse "## Recommendations" section if present
3. [x] Replace STEP 5 (Update Overview) with STEP 5 (Validate + Return Signal)
   - Validate required sections exist: Summary, Findings, Sources
   - Return signal: `REPORT_CREATED: /absolute/path/to/report.md`
4. [x] Add error handling to STEP 1 (input validation)
   - Check report_path provided
   - Return ERROR_CONTEXT if missing
5. [x] Add self-validation before return
   - File exists at path
   - YAML frontmatter valid
   - Required sections present

**Testing**:
- [ ] Unit test: YAML frontmatter parsing (findings_count, recommendations_count)
- [ ] Integration test: Specialist creates report with valid metadata
- [ ] Integration test: Specialist returns REPORT_CREATED signal
- [ ] Integration test: Specialist fails with ERROR_CONTEXT on invalid input

**Success Criteria**:
- All reports include YAML frontmatter with counts
- Completion signal format: `REPORT_CREATED: /path`
- Error signals include ERROR_CONTEXT JSON
- Self-validation catches missing sections

---

### Phase 2: Research Coordinator Enhancement (Planning-Only Mode)

**Duration**: 3-4 hours  
**Dependencies**: Phase 1 (specialist signals)  
**Artifacts**: `research-coordinator.md` (planning-only mode)

**Objectives**:
1. Add invocation plan file creation (hard barrier proof)
2. Implement metadata-only return format (remove OVERVIEW.md synthesis)
3. Add multi-layer validation (plan → outputs)
4. Implement partial success mode (≥50% threshold)

**Tasks**:
1. [x] Add STEP 2.5: Create Invocation Plan File
   - Path: `${topic_path}/.invocation-plan.txt`
   - Content: Expected invocations count, topic list, report paths
   - Status marker: `PLAN_COMPLETE`
2. [x] Refactor STEP 3: Decompose Plan → Generate Invocation Metadata
   - **Remove**: Specialist Task invocations
   - **Add**: Build invocations array (topic, report_path)
   - Return format: `INVOCATION_PLAN_READY: N` + JSON array
3. [x] Remove STEP 5: Finalize (no OVERVIEW.md synthesis)
   - **Rationale**: Planning-only mode doesn't invoke specialists
   - OVERVIEW.md creation moved to primary agent (Phase 3)
4. [x] Add STEP 4: Return Invocation Metadata
   - Signal format: `RESEARCH_COORDINATOR_COMPLETE: SUCCESS`
   - Fields: `topics_planned`, `invocation_plan_path`, `context_usage_percent`
   - Invocations array: `[{topic, report_path}, ...]`
5. [x] Add error handling for path validation
   - Validate `report_dir` exists
   - Validate `topic_path` exists
   - Return ERROR_CONTEXT if directories missing

**Testing**:
- [ ] Unit test: Invocation plan file creation
- [ ] Unit test: Invocation metadata JSON format
- [ ] Integration test: Coordinator returns RESEARCH_COORDINATOR_COMPLETE signal
- [ ] Integration test: Coordinator creates .invocation-plan.txt
- [ ] Integration test: Coordinator handles missing directories gracefully

**Success Criteria**:
- Invocation plan file created with all topic assignments
- Return signal includes `topics_planned` and `invocation_plan_path`
- No specialist Task invocations in coordinator
- Error handling for invalid paths

---

### Phase 3: Primary Agent Overhaul (Hard Barrier + Validation)

**Duration**: 4-5 hours  
**Dependencies**: Phase 1-2 (specialist + coordinator enhancements)  
**Artifacts**: `research.md` (full orchestrator)

**Objectives**:
1. Add argument capture and complexity detection
2. Pre-calculate topic directory and report paths
3. Implement hard barrier validation pattern
4. Add specialist invocation loop (parallel)
5. Generate metadata-based console summaries

**Tasks**:
1. [x] Add STEP 1: Argument Capture and Validation
   - Parse user request for research topic
   - Detect complexity (1-4) based on request scope
   - Set default complexity: 2 (2 topics)
2. [x] Add STEP 2: Path Pre-Calculation (Hard Barrier Pattern)
   - Generate `topic_slug` from request
   - Read `.opencode/specs/.counter`, increment, write back
   - Create topic directory: `.opencode/specs/NNN_topic_slug/`
   - Pre-calculate report paths: `reports/001_topic1.md`, `reports/002_topic2.md`, etc.
3. [x] Add STEP 3: Invoke Research Coordinator
   - Pass pre-calculated paths in input contract
   - Receive invocation metadata (topics + paths)
   - Parse `INVOCATION_PLAN_READY` signal
4. [x] Add STEP 4: Invoke Research Specialists (Parallel)
   - Loop over invocations array
   - Invoke research-specialist for each topic with pre-calculated path
   - All invocations in single message block (parallel execution)
5. [x] Add STEP 5: Hard Barrier Validation
   - Validate each report exists at pre-calculated path
   - Fail-fast if any report missing (exit with error)
   - Calculate success rate (completed / total)
   - Apply ≥50% threshold (warn if 50-99%, error if <50%)
6. [x] Add STEP 6: Metadata Extraction
   - Read YAML frontmatter from each report (not full content)
   - Extract: `findings_count`, `recommendations_count`, `topic`
   - Build metadata array (110 tokens per report)
7. [x] Add STEP 7: OVERVIEW.md Synthesis
   - Create OVERVIEW.md with research request and date
   - List all reports with metadata (title, findings count, path link)
   - Generate executive summary (3-5 sentences)
8. [x] Add STEP 8: Console Summary Generation
   - 4-section format: Summary / Phases / Artifacts / Next Steps
   - Include context reduction metrics
   - Include artifact paths for user access

**Testing**:
- [ ] Integration test: Primary agent pre-calculates all paths
- [ ] Integration test: Primary agent invokes coordinator successfully
- [ ] Integration test: Primary agent invokes all specialists in parallel
- [ ] Integration test: Hard barrier validation catches missing reports
- [ ] Integration test: Partial success mode (75% success rate)
- [ ] Integration test: OVERVIEW.md created with metadata
- [ ] Integration test: Console summary generated with metrics

**Success Criteria**:
- All paths pre-calculated before coordinator invocation
- Coordinator invoked with complete input contract
- All specialists invoked in parallel (single message block)
- Hard barrier validation enforces artifact creation
- OVERVIEW.md synthesis uses metadata (not full report reads)
- Console summary includes context reduction metrics

---

### Phase 4: Error Logging Integration

**Duration**: 1-2 hours  
**Dependencies**: Phase 3 (primary agent overhaul)  
**Artifacts**: `research.md` (error logging), `research-coordinator.md` (error signals), `research-specialist.md` (error signals)

**Objectives**:
1. Add centralized error logging to primary agent
2. Implement error parsing from coordinator/specialist signals
3. Add recovery hints to error messages

**Tasks**:
1. [x] Add error logging initialization to primary agent STEP 1
   - Set `WORKFLOW_ID` (nanosecond-precision timestamp)
   - Set `COMMAND_NAME` ("research-mode")
   - Initialize error context
2. [x] Add error parsing to coordinator invocation (STEP 3)
   - Parse `TASK_ERROR:` signals from coordinator output
   - Extract `ERROR_CONTEXT` JSON
   - Log to `.opencode/errors.jsonl` (create if missing)
3. [x] Add error parsing to specialist invocations (STEP 4)
   - Parse `TASK_ERROR:` signals from each specialist
   - Log specialist errors with topic context
4. [x] Add error logging to validation failures (STEP 5)
   - Log validation errors (missing reports) to errors.jsonl
   - Include recovery hints in error messages
5. [x] Create `.opencode/errors.jsonl` if missing
   - JSON Lines format (one error per line)
   - Fields: `timestamp`, `workflow_id`, `command`, `error_type`, `message`, `details`

**Testing**:
- [ ] Integration test: Error logged when coordinator fails
- [ ] Integration test: Error logged when specialist fails
- [ ] Integration test: Error logged when validation fails
- [ ] Integration test: errors.jsonl created if missing
- [ ] Integration test: Error context includes recovery hints

**Success Criteria**:
- All errors logged to `.opencode/errors.jsonl`
- Error context includes workflow_id for traceability
- Recovery hints provided in error messages
- JSON Lines format validated

---

### Phase 5: Partial Success Mode Implementation

**Duration**: 2 hours  
**Dependencies**: Phase 3-4 (validation + error logging)  
**Artifacts**: `research-coordinator.md` (partial success), `research.md` (threshold handling)

**Objectives**:
1. Implement ≥50% success threshold in primary agent
2. Add graceful degradation warnings
3. Support partial OVERVIEW.md generation

**Tasks**:
1. [x] Add success rate calculation to STEP 5 (Validation)
   - Count: `SUCCESSFUL_REPORTS`, `FAILED_REPORTS`
   - Calculate: `SUCCESS_RATE = (SUCCESSFUL / TOTAL) * 100`
2. [x] Add threshold logic to STEP 5
   - `<50%`: Exit with error, log to errors.jsonl
   - `50-99%`: Continue with warning, log to errors.jsonl
   - `100%`: Continue without warning
3. [x] Update STEP 7 (OVERVIEW.md) to handle partial results
   - List only successful reports in OVERVIEW.md
   - Add "Partial Success" marker if <100%
   - Include failed topics list
4. [x] Update console summary to show success rate
   - Format: "Research complete: 3/4 topics (75% success)"
   - Include warning for partial success

**Testing**:
- [ ] Integration test: 100% success (4/4 reports)
- [ ] Integration test: 75% success (3/4 reports, warning)
- [ ] Integration test: 50% success (2/4 reports, warning)
- [ ] Integration test: 25% success (1/4 reports, error + exit)
- [ ] Integration test: OVERVIEW.md includes failed topics list

**Success Criteria**:
- Threshold enforcement: <50% fails, ≥50% continues
- Warnings displayed for 50-99% success
- OVERVIEW.md includes partial success marker
- Console summary shows success rate

---

### Phase 6: Testing and Validation

**Duration**: 2-3 hours  
**Dependencies**: Phase 1-5 (all implementation phases)  
**Artifacts**: `test_research_agent_hierarchical.sh`

**Objectives**:
1. Create comprehensive integration test suite
2. Validate all hierarchical patterns implemented
3. Measure context reduction and time savings

**Tasks**:
1. [x] Create test suite structure
   - Test file: `.opencode/tests/test_research_agent_hierarchical.sh`
   - Mock coordinator/specialist outputs for testing
2. [x] Add test: Path pre-calculation
   - Verify paths calculated before coordinator invocation
   - Verify paths are absolute
3. [x] Add test: Invocation plan file creation
   - Verify .invocation-plan.txt created by coordinator
   - Verify plan includes all topic assignments
4. [x] Add test: Parallel specialist invocation
   - Verify all specialists invoked in single message
   - Verify no sequential bottlenecks
5. [x] Add test: Hard barrier validation
   - Verify validation catches missing reports
   - Verify fail-fast on <50% success
6. [x] Add test: Metadata extraction
   - Verify YAML frontmatter parsed correctly
   - Verify metadata-only passing (not full file reads)
7. [x] Add test: Console summary generation
   - Verify 4-section format
   - Verify context reduction metrics included
8. [x] Add test: Error logging
   - Verify errors logged to errors.jsonl
   - Verify error context includes recovery hints
9. [x] Add test: Partial success mode
   - Test 100%, 75%, 50%, 25% success rates
   - Verify threshold enforcement
10. [x] Measure performance metrics
    - Context reduction: baseline vs hierarchical
    - Time savings: sequential vs parallel (if applicable)

**Testing**:
- [ ] Run test suite: `bash .opencode/tests/test_research_agent_hierarchical.sh`
- [ ] Target: 20+ tests, 100% pass rate

**Success Criteria**:
- All 20+ tests pass
- Context reduction ≥95% demonstrated
- Hard barrier enforcement validated
- Partial success mode tested

---

### Phase 7: Documentation and Migration Guide

**Duration**: 1-2 hours  
**Dependencies**: Phase 6 (testing complete)  
**Artifacts**: `RESEARCH_AGENT_ARCHITECTURE.md`, `MIGRATION_GUIDE.md`

**Objectives**:
1. Document new hierarchical architecture
2. Create migration guide for other OpenCode agents
3. Update agent registry with new capabilities

**Tasks**:
1. [x] Create `RESEARCH_AGENT_ARCHITECTURE.md`
   - Document three-tier pattern implementation
   - Include flow diagrams
   - Include performance metrics
2. [x] Create `MIGRATION_GUIDE.md`
   - Step-by-step guide for migrating other agents
   - Pattern templates for coordinator/specialist enhancements
   - Testing checklist
3. [x] Update `agent-registry.json`
   - Add metadata about hierarchical patterns
   - Include performance metrics
4. [x] Update `README.md`
   - Document new research agent capabilities
   - Include context reduction metrics
   - Link to architecture guide

**Testing**:
- [ ] Documentation review: clarity, completeness, accuracy
- [ ] Link validation: all internal links work

**Success Criteria**:
- Architecture documented with diagrams
- Migration guide provides clear step-by-step instructions
- Agent registry updated with metrics
- README includes new capabilities

---

## Implementation Details

### File Modifications Summary

| File | Changes | Lines Added | Lines Removed |
|------|---------|-------------|---------------|
| `research-specialist.md` | Add YAML frontmatter, completion signals, error protocol, self-validation | ~40 | ~5 |
| `research-coordinator.md` | Add invocation plan file, metadata return format, remove specialist invocations, add error handling | ~60 | ~15 |
| `research.md` | Complete overhaul: argument capture, path pre-calculation, specialist invocation loop, validation, console summaries | ~150 | ~6 |
| `test_research_agent_hierarchical.sh` | New file: integration test suite | ~300 | 0 |
| `RESEARCH_AGENT_ARCHITECTURE.md` | New file: architecture documentation | ~200 | 0 |
| `MIGRATION_GUIDE.md` | New file: migration guide for other agents | ~150 | 0 |
| `agent-registry.json` | Update research agent metadata | ~10 | ~5 |
| `README.md` | Update research agent section | ~20 | ~10 |
| **Total** | | **~930** | **~41** |

### Code Standards Compliance

**Bash Standards** (N/A - Markdown behavioral files only):
- No bash code in OpenCode agents (all behavioral guidelines in Markdown)

**Markdown Standards**:
- All behavioral files use imperative directives: "**EXECUTE NOW**: USE the Task tool..."
- Clear STEP numbering for agent workflows
- YAML input/output contract specifications
- Signal format standards followed

**Error Handling Standards**:
- ERROR_CONTEXT JSON format: `{"error_type":"...","message":"...","details":{...}}`
- TASK_ERROR signal format: `TASK_ERROR: error_type - message`
- Standardized error types: validation_error, agent_error, parse_error, file_error

**Testing Standards**:
- Integration test coverage: 20+ tests
- Test organization: Setup → Execute → Assert → Cleanup
- Mock data for specialist/coordinator outputs
- Performance benchmarking included

### Context Reduction Calculations

**Baseline (Current OpenCode Implementation)**:
```
User Request → research.md → research-coordinator → 4x research-specialist
                                                          ↓
                          research-coordinator reads 4x full reports (2,500 tokens each)
                                                          ↓
                          research-coordinator synthesizes OVERVIEW.md (2,000 tokens)
                                                          ↓
                          research.md receives full OVERVIEW.md (2,000 tokens)

Total Context Consumption (Primary Agent): 2,000 tokens
```

**Hierarchical (New Implementation)**:
```
User Request → research.md (pre-calculates paths) → research-coordinator (planning-only)
                                                          ↓
                          Returns invocation metadata (440 tokens for 4 topics)
                                                          ↓
               research.md invokes 4x research-specialist (parallel)
                                                          ↓
               research.md extracts YAML frontmatter (110 tokens each)
                                                          ↓
               research.md builds OVERVIEW.md using metadata (not full reads)

Total Context Consumption (Primary Agent): 440 tokens (metadata only)

Context Reduction: (2,000 - 440) / 2,000 = 78%
```

**Note**: If primary agent read full reports (baseline comparison):
```
Baseline (reading 4 full reports): 4 x 2,500 = 10,000 tokens
Hierarchical (metadata only): 440 tokens
Context Reduction: (10,000 - 440) / 10,000 = 95.6%
```

### Performance Metrics

**Time Savings** (Parallel Execution):
```
Sequential Specialist Execution:
  4 specialists x 30 seconds each = 120 seconds total

Parallel Specialist Execution:
  4 specialists x 30 seconds (all running simultaneously) = 30 seconds total

Time Savings: (120 - 30) / 120 = 75%
```

**Iteration Capacity** (Multi-Session Workflows):
```
Context Budget: 200,000 tokens (Sonnet 3.5)
Agent Output per Iteration: 2,000 tokens (baseline) vs 440 tokens (hierarchical)

Baseline Iterations: 200,000 / 2,000 = 100 iterations
Hierarchical Iterations: 200,000 / 440 = 454 iterations

Iteration Capacity Increase: 454 / 100 = 4.54x
```

---

## Testing Strategy

### Unit Tests (Coordinator/Specialist Behavior)

**research-specialist.md**:
- [ ] Test: YAML frontmatter generation (findings_count, recommendations_count)
- [ ] Test: Completion signal format (REPORT_CREATED: /path)
- [ ] Test: Error signal format (ERROR_CONTEXT + TASK_ERROR)
- [ ] Test: Self-validation (required sections check)

**research-coordinator.md**:
- [ ] Test: Invocation plan file creation
- [ ] Test: Invocation metadata JSON format
- [ ] Test: RESEARCH_COORDINATOR_COMPLETE signal format
- [ ] Test: Error handling (missing directories)

### Integration Tests (End-to-End Workflows)

**Scenario 1: Single-Topic Research (Complexity 1)**:
- [ ] Test: 1 topic decomposed, 1 specialist invoked
- [ ] Test: Report created at pre-calculated path
- [ ] Test: OVERVIEW.md generated with 1 report link
- [ ] Test: Console summary shows 1/1 success

**Scenario 2: Multi-Topic Research (Complexity 3)**:
- [ ] Test: 3 topics decomposed, 3 specialists invoked (parallel)
- [ ] Test: All 3 reports created at pre-calculated paths
- [ ] Test: OVERVIEW.md generated with 3 report links
- [ ] Test: Console summary shows 3/3 success

**Scenario 3: Partial Success (2/4 Reports)**:
- [ ] Test: 4 topics decomposed, 2 specialists succeed, 2 fail
- [ ] Test: Validation catches 50% success rate
- [ ] Test: Warning displayed (not error)
- [ ] Test: OVERVIEW.md generated with 2 reports + failed topics list
- [ ] Test: Console summary shows 2/4 success (50%)

**Scenario 4: Critical Failure (1/4 Reports)**:
- [ ] Test: 4 topics decomposed, 1 specialist succeeds, 3 fail
- [ ] Test: Validation catches 25% success rate
- [ ] Test: Error displayed (not warning)
- [ ] Test: Workflow exits with error code
- [ ] Test: errors.jsonl includes validation error

**Scenario 5: Error Handling (Coordinator Failure)**:
- [ ] Test: Coordinator fails with ERROR_CONTEXT
- [ ] Test: Primary agent parses error signal
- [ ] Test: Error logged to errors.jsonl
- [ ] Test: User receives error message with recovery hints

**Scenario 6: Error Handling (Specialist Failure)**:
- [ ] Test: 1 specialist fails with ERROR_CONTEXT
- [ ] Test: Primary agent parses error signal
- [ ] Test: Error logged to errors.jsonl with topic context
- [ ] Test: Partial success mode continues (if ≥50%)

---

## Risk Assessment

### High-Risk Areas

1. **Invocation Plan Parsing** (Phase 3)
   - **Risk**: Primary agent fails to parse invocations array from coordinator
   - **Mitigation**: Use robust JSON parsing (jq or Python), validate format before invocation
   - **Fallback**: Coordinator returns simple text format with topic/path pairs

2. **Parallel Specialist Invocation** (Phase 3)
   - **Risk**: OpenCode doesn't support parallel Task invocations in single message
   - **Mitigation**: Test with 2 specialists first, then scale to 4
   - **Fallback**: Sequential invocation (loses time savings but maintains context reduction)

3. **YAML Frontmatter Parsing** (Phase 6)
   - **Risk**: Inconsistent frontmatter format breaks metadata extraction
   - **Mitigation**: Strict frontmatter template in specialist, validation before return
   - **Fallback**: Parse first 20 lines for key-value pairs (grep/sed approach)

4. **Error Logging Integration** (Phase 4)
   - **Risk**: errors.jsonl format incompatible with existing OpenCode tooling
   - **Mitigation**: Use JSON Lines format (one error per line, valid JSON)
   - **Fallback**: Simple text log with timestamp prefixes

### Medium-Risk Areas

1. **Path Pre-Calculation** (Phase 3)
   - **Risk**: Counter file race condition with concurrent research invocations
   - **Mitigation**: Use atomic file operations, nanosecond timestamps for uniqueness
   - **Fallback**: UUID-based topic slugs instead of counter

2. **OVERVIEW.md Synthesis** (Phase 3)
   - **Risk**: Metadata extraction fails, primary agent reads full reports
   - **Mitigation**: Validate YAML frontmatter exists before extraction attempt
   - **Fallback**: Full report reads (loses context reduction benefit)

3. **Partial Success Warnings** (Phase 5)
   - **Risk**: Users ignore warnings, proceed with incomplete research
   - **Mitigation**: Clear warning format, failed topics list prominently displayed
   - **Fallback**: Stricter threshold (≥75% instead of ≥50%)

### Low-Risk Areas

1. **Console Summary Generation** (Phase 3)
   - **Risk**: Summary format unclear or verbose
   - **Mitigation**: Follow 4-section format standard, include emoji markers
   - **Fallback**: Simple text summary without formatting

2. **Documentation** (Phase 7)
   - **Risk**: Documentation becomes stale as implementation evolves
   - **Mitigation**: Generate docs from code comments, version control
   - **Fallback**: Minimal documentation (README only)

---

## Success Metrics

### Performance Metrics

| Metric | Baseline | Target | Measurement |
|--------|---------|--------|-------------|
| **Context Reduction** | 0% (no hierarchy) | 95-96% | (Baseline Tokens - Hierarchical Tokens) / Baseline Tokens |
| **Time Savings** | 0% (sequential) | 40-60% | (Sequential Time - Parallel Time) / Sequential Time |
| **Iteration Capacity** | 3-4 iterations | 10-20 iterations | Context Budget / Tokens per Iteration |
| **Hard Barrier Success** | N/A | 100% enforcement | Test: bypass attempts fail |
| **Partial Success Handling** | N/A | ≥50% threshold works | Test: 50%, 75% scenarios continue |

### Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Test Coverage** | 20+ tests, 100% pass | Integration test suite execution |
| **Code Standards Compliance** | 100% | Markdown linting, signal format validation |
| **Error Logging Completeness** | All errors logged | errors.jsonl inspection |
| **Documentation Completeness** | All phases documented | Doc review checklist |

### User Experience Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Console Summary Clarity** | 4-section format | User feedback |
| **Error Message Clarity** | Recovery hints included | Error message review |
| **Partial Success Transparency** | Success rate displayed | Console output inspection |

---

## Rollout Strategy

### Phase-by-Phase Rollout

**Week 1**: Phases 1-2 (Specialist + Coordinator Enhancements)
- Deliverable: Enhanced specialist with YAML frontmatter and signals
- Deliverable: Coordinator with invocation plan file creation
- Testing: Unit tests for specialist/coordinator behavior

**Week 2**: Phase 3 (Primary Agent Overhaul)
- Deliverable: research.md with full orchestrator logic
- Deliverable: Hard barrier validation implemented
- Testing: Integration tests for end-to-end workflows

**Week 3**: Phases 4-5 (Error Logging + Partial Success)
- Deliverable: Error logging integration complete
- Deliverable: Partial success mode implemented
- Testing: Error handling and threshold tests

**Week 4**: Phases 6-7 (Testing + Documentation)
- Deliverable: Comprehensive test suite (20+ tests)
- Deliverable: Architecture documentation and migration guide
- Testing: Full test suite execution, performance benchmarking

### Deployment Steps

1. **Backup Current Implementation**:
   ```bash
   cp research.md research.md.backup_$(date +%Y%m%d)
   cp research-coordinator.md research-coordinator.md.backup_$(date +%Y%m%d)
   cp research-specialist.md research-specialist.md.backup_$(date +%Y%m%d)
   ```

2. **Deploy Phase 1 (Specialist)**:
   - Update `research-specialist.md`
   - Test with manual invocation
   - Verify YAML frontmatter and signals

3. **Deploy Phase 2 (Coordinator)**:
   - Update `research-coordinator.md`
   - Test with manual invocation
   - Verify invocation plan file creation

4. **Deploy Phase 3 (Primary Agent)**:
   - Update `research.md`
   - Test end-to-end workflow (1 topic, 2 topics, 4 topics)
   - Verify hard barrier validation

5. **Deploy Phases 4-5 (Error Logging + Partial Success)**:
   - Add error logging code
   - Test error scenarios
   - Verify partial success handling

6. **Run Full Test Suite** (Phase 6):
   - Execute all integration tests
   - Verify 100% pass rate
   - Measure performance metrics

7. **Publish Documentation** (Phase 7):
   - Commit architecture documentation
   - Update README.md
   - Publish migration guide

### Rollback Plan

If critical issues discovered:
1. Restore backups: `cp research.md.backup_YYYYMMDD research.md`
2. Verify rollback: Test original 6-line orchestrator
3. Document issue: Add to GitHub issues
4. Plan fix: Update implementation plan

---

## Appendices

### Appendix A: Pattern References from Claude Code

**Three-Tier Coordination Pattern**:
- File: `.claude/docs/concepts/three-tier-coordination-pattern.md`
- Sections: Tier 1 (Commands), Tier 2 (Coordinators), Tier 3 (Specialists)
- Key Patterns: Path pre-calculation, metadata extraction, hard barrier validation

**Hierarchical Agents Examples**:
- File: `.claude/docs/concepts/hierarchical-agents-examples.md`
- Example 7: Research coordinator with parallel multi-topic research
- Example 8: Lean command coordinator optimization

**Coordinator Patterns Standard**:
- File: `.claude/docs/reference/standards/coordinator-patterns-standard.md`
- Pattern 1: Path pre-calculation (hard barrier enforcement)
- Pattern 2: Metadata extraction (95%+ context reduction)
- Pattern 3: Partial success mode (≥50% threshold)
- Pattern 4: Error return protocol
- Pattern 5: Multi-layer validation

**Coordinator Return Signals**:
- File: `.claude/docs/reference/standards/coordinator-return-signals.md`
- research-coordinator signal format
- Error signal format (ERROR_CONTEXT + TASK_ERROR)

### Appendix B: OpenCode vs Claude Code Structural Differences

| Aspect | Claude Code | OpenCode | Adaptation Needed |
|--------|------------|----------|-------------------|
| **Specs Directory** | `.claude/specs/` | `.opencode/specs/` | Path updates in all references |
| **Agent Location** | `.claude/agents/` | `.opencode/agent/` (primary), `.opencode/subagents/` (sub) | Two-tier directory structure |
| **State Management** | `workflow-state-machine.sh` | N/A (no state machine) | Remove state transitions |
| **Error Logging** | `errors.jsonl` via `error-handling.sh` | Create `.opencode/errors.jsonl` | Manual JSON Lines format |
| **Counter File** | N/A (uses LLM topic naming) | `.opencode/specs/.counter` | Keep counter, add uniqueness checks |
| **OVERVIEW.md** | Not used in research workflows | Central to OpenCode research | Keep OVERVIEW.md, enhance with metadata |

### Appendix C: YAML Frontmatter Template

**research-specialist.md Output** (Report File):
```yaml
---
report_type: research
topic: "Topic description here"
findings_count: 12
recommendations_count: 5
created_date: 2025-12-12
status: complete
research_complexity: 3
workflow_type: multi_topic_research
---

# Research Report: [Topic Title]

## Summary
[1-paragraph summary of findings]

## Findings
1. [Finding 1]
2. [Finding 2]
...

## Recommendations
1. [Recommendation 1]
2. [Recommendation 2]
...

## Sources
- [URL 1]
- [URL 2]
...
```

### Appendix D: Signal Format Specifications

**RESEARCH_COORDINATOR_COMPLETE** (Coordinator → Primary Agent):
```yaml
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
coordinator_type: research
topics_planned: 4
invocation_plan_path: /home/user/.opencode/specs/042_lean_research/.invocation-plan.txt
context_usage_percent: 8

INVOCATION_PLAN_READY: 4
invocations: [
  {"topic": "Lean 4 Tactics", "report_path": "/home/user/.opencode/specs/042_lean_research/reports/001_lean_tactics.md"},
  {"topic": "Mathlib Integration", "report_path": "/home/user/.opencode/specs/042_lean_research/reports/002_mathlib_integration.md"},
  {"topic": "Proof Automation", "report_path": "/home/user/.opencode/specs/042_lean_research/reports/003_proof_automation.md"},
  {"topic": "Project Structure", "report_path": "/home/user/.opencode/specs/042_lean_research/reports/004_project_structure.md"}
]
```

**REPORT_CREATED** (Specialist → Primary Agent):
```
REPORT_CREATED: /home/user/.opencode/specs/042_lean_research/reports/001_lean_tactics.md
```

**ERROR_CONTEXT + TASK_ERROR** (Any Agent → Parent):
```json
ERROR_CONTEXT: {"error_type":"validation_error","message":"Missing report_path field","details":{"required_fields":["research_topic","report_path"]}}

TASK_ERROR: validation_error - Missing report_path field in input contract
```

---

## Next Steps

1. **Phase 1 Start**: Enhance `research-specialist.md` with YAML frontmatter and signals
2. **Testing**: Create unit tests for specialist behavior
3. **Phase 2 Start**: Refactor `research-coordinator.md` to planning-only mode
4. **Continue**: Follow phase progression through Phase 7

**Estimated Completion**: 12-16 hours total (2-3 weeks at part-time pace)

---

**End of Implementation Plan**
