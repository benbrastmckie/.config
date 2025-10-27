# Performance Optimization Patterns for /research

## Overview

The `/research` command demonstrates strong adoption of performance optimization patterns but has untapped optimization potential through better pattern integration and prompt streamlining. Analysis reveals 566-line command file with 15 code blocks, 29 enforcement markers, and opportunities for 20-30% context reduction through metadata extraction pattern improvements and verification checkpoint consolidation.

## Research Findings

### 1. Pattern Adoption Analysis

**Currently Used Patterns**:
- **Metadata Extraction Pattern**: Partially adopted in research-synthesizer agent (Step 4, lines 179-219 of agent file)
- **Forward Message Pattern**: NOT explicitly used in /research command
- **Context Management Pattern**: NOT explicitly documented in command workflow
- **Unified Location Detection**: Fully adopted (lines 84-108 of research.md)

**Pattern Coverage**:
- research-specialist agent: 0/3 performance patterns mentioned in behavioral guidelines
- research-synthesizer agent: 1/3 patterns (metadata extraction in Step 4)
- /research command: 0/3 patterns referenced in workflow documentation

**Impact**: Missing pattern references mean agents may not be following optimal context reduction practices despite having capability.

### 2. Command File Bloat Analysis

**Prompt Template Size** (lines 173-336):
- Agent invocation template: 164 lines (29% of command file)
- Includes extensive inline documentation, examples, and checkpoint requirements
- Code blocks: 30 backtick delimiters (15 complete code blocks)
- Enforcement markers: 29 instances (EXECUTE NOW, MANDATORY, REQUIRED, CHECKPOINT)

**Redundancy Patterns**:
- Verification checkpoint instructions repeated 4 times (Steps 1, 2, 3, 4)
- Path validation logic duplicated in command and both agents
- Progress marker documentation repeated in agent (lines 201-236) and command (lines 212-235)

**Quick Win Opportunity**: Extract agent invocation templates to `.claude/templates/agent-invocations/` (estimated 40% prompt size reduction).

### 3. Verification Checkpoint Overhead

**Current Checkpoint Pattern** (research.md):
- Step 1: Path verification checkpoint (lines 159-171)
- Step 2: Path pre-calculation checkpoint (lines 148-171)
- Step 3: Parallel agent invocation (no explicit checkpoint)
- Step 4: Report creation verification (lines 239-276)
- Step 5: Cross-reference update (lines 346-427)

**Checkpoint Redundancy**:
- 3 separate verification checkpoints for file existence
- 2 checkpoints for path format validation (absolute vs relative)
- Each checkpoint includes bash code blocks with error handling (30-50 lines each)

**Optimization Potential**: Consolidate checkpoints using shared verification library function (estimated 80-100 line reduction).

### 4. File I/O Pattern Analysis

**Current File Operations** (per /research invocation):
- Location detection: 1 read (unified-location-detection.sh sources)
- Topic decomposition: 1 Task invocation (subtopic calculation)
- Path pre-calculation: N calculations (no file I/O, in-memory only)
- Agent invocations: 2-4 parallel research agents + 1 synthesizer (N+1 Write operations)
- Verification: N+1 file existence checks (1 per agent + overview)
- Cross-reference update: 1 Read (overview) + N Reads (subtopic reports) + N+1 Edits

**Total File Operations** (4 subtopics): ~18 file operations (4 Write, 6 Read, 5 Edit, 1 exists check per subtopic, 1 overview check)

**Optimization Opportunity**:
- Verification uses individual `[ -f "$path" ]` checks instead of batched verification
- Cross-reference update reads each report individually instead of metadata-only extraction
- Estimated 30% reduction via metadata extraction library integration

### 5. Agent Coordination Overhead

**Current Agent Pattern**:
- research-specialist agent: Full 671-line behavioral file loaded per invocation (4 invocations = 2,684 lines context)
- research-synthesizer agent: Full 259-line behavioral file loaded once
- Total agent context: ~3,000 lines per /research invocation

**Agent Behavioral File Bloat**:
- research-specialist: 28 completion criteria checklist (lines 322-411)
- Extensive error handling examples (lines 261-320)
- Report structure documentation (lines 415-474) - duplicates `.claude/templates/report-structure.md`

**Optimization Potential**: Agent behavioral files should reference shared templates instead of duplicating content (estimated 200-250 line reduction per agent).

### 6. Unused Performance Pattern Opportunities

**Metadata Extraction Pattern**:
- **Current State**: research-synthesizer returns 100-word summary (Step 4)
- **Optimization**: research-specialist agents could return metadata-only (not currently enforced)
- **Evidence**: Agent completion criteria (lines 356-360) require `REPORT_CREATED: [path]` format but don't prohibit additional content
- **Impact**: Agents may return summaries in addition to path, increasing context by 200-500 tokens per agent

**Forward Message Pattern**:
- **Current State**: /research command does not explicitly forward subagent metadata
- **Optimization**: Spec-updater invocation (Step 6, lines 346-427) could forward agent metadata instead of re-reading reports
- **Evidence**: Lines 369-371 list subtopic paths but don't extract metadata for forwarding
- **Impact**: Spec-updater reads N+1 full reports (5-10KB each) instead of receiving metadata (200-300 bytes each)

**Context Pruning**:
- **Current State**: No explicit pruning instructions after agent completion
- **Optimization**: After Step 4 verification, command could prune agent response content (retain only paths)
- **Evidence**: No reference to `prune_subagent_output()` from context-pruning.sh library
- **Impact**: Full agent responses retained in context throughout Steps 5-6 (unnecessary 1,000-2,000 tokens)

### 7. Performance Bottleneck Ranking

**High Impact, Low Effort** (Quick Wins):
1. **Extract Agent Invocation Templates**: 40% prompt reduction, ~2 hours effort
   - Move lines 173-336 to `.claude/templates/agent-invocations/research-specialist-invocation.md`
   - Reference template via `$(cat .claude/templates/...)`
   - Line references: research.md:173-336, research.md:300-336

2. **Enforce Metadata-Only Returns**: 20% context reduction, ~1 hour effort
   - Add anti-pattern warning to research-specialist agent (after line 198)
   - Reference metadata extraction pattern explicitly
   - Line references: research-specialist.md:183-198

3. **Consolidate Verification Checkpoints**: 15% prompt reduction, ~3 hours effort
   - Extract verification logic to `.claude/lib/research-verification.sh`
   - Replace 4 checkpoint blocks with single function calls
   - Line references: research.md:159-171, 239-276

**Medium Impact, Medium Effort**:
4. **Integrate Metadata Extraction Library**: 30% file I/O reduction, ~4 hours effort
   - Use `extract_report_metadata()` from metadata-extraction.sh in Step 6
   - Forward metadata to spec-updater instead of file paths
   - Line references: research.md:369-371, metadata-extraction.sh:76-101

5. **Add Context Pruning**: 10-15% context reduction, ~2 hours effort
   - Import context-pruning.sh library
   - Call `prune_subagent_output()` after Step 4 verification
   - Line references: research.md:276 (insert after), context-pruning.sh:73-82

**Low Impact, High Effort** (Future Work):
6. **Agent Behavioral File Refactoring**: 8-10% agent context reduction, ~8 hours effort
   - Extract shared documentation to templates
   - Reference templates instead of duplicating content
   - Line references: research-specialist.md:415-474, templates/report-structure.md

### 8. Comparative Performance Analysis

**Current Performance** (estimated):
- Command prompt size: 566 lines (research.md)
- Agent behavioral context: ~3,000 lines (4 research-specialist + 1 synthesizer)
- Total context per invocation: ~3,566 lines (~35,000 tokens)
- File I/O operations: 18 per invocation (4 subtopics)
- Verification overhead: 4 checkpoints × 30 lines = 120 lines

**Optimized Performance** (with all quick wins):
- Command prompt size: ~340 lines (40% reduction via template extraction)
- Agent behavioral context: ~2,400 lines (20% reduction via metadata enforcement)
- Total context per invocation: ~2,740 lines (~23% reduction = ~27,000 tokens)
- File I/O operations: 13 per invocation (30% reduction via metadata extraction)
- Verification overhead: 4 function calls × 1 line = 4 lines (97% reduction)

**Expected Improvements**:
- Context usage reduction: 23% (8,000 tokens saved)
- Prompt bloat reduction: 40% (226 lines saved in command file)
- Verification overhead reduction: 97% (116 lines saved)
- File I/O reduction: 30% (5 fewer file operations)
- Time savings: 10-15% (primarily from reduced agent context loading)

## Recommendations

### 1. Immediate Quick Wins (Priority 1)

**Recommendation 1.1: Extract Agent Invocation Templates**
- **Impact**: 40% command prompt reduction (226 lines saved)
- **Effort**: 2 hours
- **Implementation**:
  ```bash
  # Create template directory
  mkdir -p .claude/templates/agent-invocations

  # Extract research-specialist invocation template
  # Move research.md:173-227 to .claude/templates/agent-invocations/research-specialist.md

  # Update research.md to reference template:
  AGENT_PROMPT=$(cat .claude/templates/agent-invocations/research-specialist.md)
  Task { prompt: "$AGENT_PROMPT" }
  ```
- **Line References**: research.md:173-336

**Recommendation 1.2: Enforce Metadata-Only Return Pattern**
- **Impact**: 20% agent context reduction (600 tokens saved per agent)
- **Effort**: 1 hour
- **Implementation**:
  ```markdown
  # Add to research-specialist.md after line 198:

  **ANTI-PATTERN WARNING**:
  DO NOT return summary text or findings in your response.
  The orchestrator will read your report file directly.

  See: [Metadata Extraction Pattern](.claude/docs/concepts/patterns/metadata-extraction.md)

  Example CORRECT return:
  REPORT_CREATED: /path/to/report.md

  Example INCORRECT return (DO NOT DO THIS):
  REPORT_CREATED: /path/to/report.md
  Summary: This report covers...
  Key Findings: ...
  ```
- **Line References**: research-specialist.md:183-198, metadata-extraction.md:42-69

**Recommendation 1.3: Consolidate Verification Checkpoints**
- **Impact**: 97% verification overhead reduction (116 lines saved)
- **Effort**: 3 hours
- **Implementation**:
  ```bash
  # Create .claude/lib/research-verification.sh
  verify_research_paths() {
    local -n paths_ref=$1
    for subtopic in "${!paths_ref[@]}"; do
      [ -f "${paths_ref[$subtopic]}" ] || return 1
    done
    return 0
  }

  # Replace 4 checkpoint blocks with:
  source .claude/lib/research-verification.sh
  verify_research_paths SUBTOPIC_REPORT_PATHS || exit 1
  ```
- **Line References**: research.md:159-171, 239-276

### 2. Medium-Term Optimizations (Priority 2)

**Recommendation 2.1: Integrate Metadata Extraction Library**
- **Impact**: 30% file I/O reduction (5 fewer file operations)
- **Effort**: 4 hours
- **Implementation**:
  ```bash
  # In Step 6 (cross-reference update), replace file path passing with metadata:
  source .claude/lib/metadata-extraction.sh

  for path in "${SUBTOPIC_PATHS_ARRAY[@]}"; do
    METADATA=$(extract_report_metadata "$path")
    echo "    - Metadata: $METADATA"
  done

  # Pass metadata to spec-updater instead of paths
  ```
- **Line References**: research.md:369-371, metadata-extraction.sh:76-101

**Recommendation 2.2: Add Context Pruning After Verification**
- **Impact**: 10-15% context reduction (1,500 tokens saved)
- **Effort**: 2 hours
- **Implementation**:
  ```bash
  # After Step 4 verification (line 276), add:
  source .claude/lib/context-pruning.sh

  # Prune full agent responses, retain only paths
  for subtopic in "${!VERIFIED_PATHS[@]}"; do
    prune_subagent_output "agent_${subtopic}" "${VERIFIED_PATHS[$subtopic]}"
  done
  ```
- **Line References**: research.md:276, context-pruning.sh:73-82

### 3. Long-Term Improvements (Priority 3)

**Recommendation 3.1: Refactor Agent Behavioral Files**
- **Impact**: 8-10% agent context reduction (200-250 lines per agent)
- **Effort**: 8 hours
- **Implementation**: Extract duplicated documentation sections to shared templates
- **Line References**: research-specialist.md:415-474, templates/report-structure.md

**Recommendation 3.2: Add Performance Monitoring**
- **Impact**: Baseline for future optimization
- **Effort**: 6 hours
- **Implementation**: Create `.claude/tests/benchmark_research.sh` similar to benchmark_orchestrate.sh
- **Line References**: tests/benchmark_orchestrate.sh:1-412

### 4. Trade-Off Analysis

**Quick Win Trade-offs**:
- Template extraction (1.1): Adds indirection (1 file read) but saves 226 lines context
- Metadata enforcement (1.2): Requires agent behavior change but saves 600 tokens per agent
- Checkpoint consolidation (1.3): Reduces inline visibility but improves maintainability

**All trade-offs favor optimization** - benefits significantly outweigh costs.

## References

### Primary Analysis Files
- `/home/benjamin/.config/.claude/commands/research.md` (566 lines)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (671 lines)
- `/home/benjamin/.config/.claude/agents/research-synthesizer.md` (259 lines)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (526 lines)
- `/home/benjamin/.config/.claude/lib/topic-decomposition.sh` (86 lines)

### Performance Pattern Documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md` (393 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/forward-message.md` (331 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md` (290 lines)

### Supporting Libraries
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` (referenced in metadata-extraction.md:76-101)
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` (referenced in context-management.md:73-82)
- `/home/benjamin/.config/.claude/tests/benchmark_orchestrate.sh` (412 lines)

### Key Line References

**Command File Bloat**:
- research.md:173-336 - Agent invocation template (164 lines, 40% optimization potential)
- research.md:159-171 - Path verification checkpoint 1 (consolidation opportunity)
- research.md:239-276 - Report verification checkpoint (consolidation opportunity)

**Pattern Integration Opportunities**:
- research-specialist.md:183-198 - Return format specification (add metadata-only enforcement)
- research.md:369-371 - Subtopic path passing to spec-updater (use metadata instead)
- research.md:276 - Post-verification location (insert context pruning)

**Agent Behavioral File Optimization**:
- research-specialist.md:322-411 - 28 completion criteria (extract to checklist template)
- research-specialist.md:415-474 - Report structure documentation (reference shared template)
