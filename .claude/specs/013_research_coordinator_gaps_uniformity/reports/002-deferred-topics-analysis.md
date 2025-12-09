# Deferred Topics Analysis - Research Coordinator Implementation

## Report Metadata
- **Date**: 2025-12-08
- **Topic**: Analysis of deferred topics from spec 009 for plan 013 revision
- **Research Type**: Gap analysis and requirements documentation
- **Source Plans**:
  - [009 Research Coordinator Agents Plan](../../009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md)
  - [013 Research Coordinator Gaps Plan](../plans/001-research-coordinator-gaps-uniformity-plan.md)

## Executive Summary

This report analyzes the deferred work items from spec 009 (Research Coordinator Agent Implementation) to identify gaps in plan 013 (Research Coordinator Gaps and Uniformity). The analysis reveals 4 major categories of deferred work that are not currently addressed in plan 013:

1. **Phase 4 Command Integration** (3 commands: /repair, /debug, /revise)
2. **Phase 6 Advanced Topic Detection** (3 features)
3. **Phase 7 Adaptive Research Depth** (3 features)
4. **Phase 8 Cross-Command Research Sharing** (3 features)

## Deferred Items from Spec 009

### Phase 4: Apply Pattern to Other Planning Commands [DEFERRED]

**Original Scope from spec 009:**
- Integrate research-coordinator into /create-plan command
- Integrate research-coordinator into /repair command
- Integrate research-coordinator into /debug command
- Integrate research-coordinator into /revise command
- Update command frontmatter for all modified commands
- Test each command integration independently

**Current Coverage in Plan 013:**
- /create-plan: Covered (Phase 1)
- /research: Covered (Phase 3)
- /lean-plan: Covered (Phase 4 investigation)
- /repair: NOT COVERED
- /debug: NOT COVERED
- /revise: NOT COVERED

**Gap Analysis - /repair Command:**
- Current state: Uses research-specialist directly (Block 1b-exec)
- Integration points:
  - Block 1a: Add topic decomposition for error analysis
  - Block 1b-exec: Replace research-specialist with research-coordinator
  - Block 1c: Update validation for multi-report scenarios
- Unique requirements:
  - Error filters (--since, --type, --command, --severity) must be passed to research-coordinator
  - Error log analysis may benefit from multiple research topics (e.g., "error patterns", "root causes", "affected workflows")

**Gap Analysis - /debug Command:**
- Current state: Uses research-specialist directly (Block 3, Research Delegation)
- Integration points:
  - Block 3: Add topic decomposition for root cause analysis
  - Research Delegation Task: Replace research-specialist with research-coordinator
  - Research Verification: Update validation for multi-report scenarios
- Unique requirements:
  - Debug context (ISSUE_DESCRIPTION) may decompose into multiple investigation topics
  - Plan-architect in debug mode creates debug strategy plans

**Gap Analysis - /revise Command:**
- Current state: Uses research-specialist directly (Block 4b)
- Integration points:
  - Block 4a: Add topic decomposition for revision context
  - Block 4b: Replace research-specialist with research-coordinator
  - Block 4c: Update validation for multi-report scenarios
- Unique requirements:
  - EXISTING_PLAN_PATH context must be available to research topics
  - REVISION_DETAILS drives topic decomposition
  - Research builds on existing plan structure

### Phase 6: Advanced Topic Detection [DEFERRED]

**Original Scope from spec 009:**
- LLM-based topic clustering (analyze prompt semantics)
- User-interactive topic refinement (prompt for confirmation)
- Topic dependency tracking (some topics depend on others)

**Current Coverage in Plan 013:**
- topic-detection-agent exists and is integrated (Phase 2)
- Haiku model used for cost optimization
- No advanced features implemented

**Gap Analysis - LLM-based Topic Clustering:**
- Current: Simple keyword extraction and conjunction detection
- Needed: Semantic analysis of prompt to identify conceptually distinct research areas
- Implementation approach:
  - Upgrade topic-detection-agent prompt to include semantic clustering instructions
  - Add output field for topic relationships (related, dependent, independent)
  - Consider using Sonnet 4.5 for complex clustering scenarios (complexity 4)

**Gap Analysis - User-Interactive Topic Refinement:**
- Current: Fully automated topic detection with no user confirmation
- Needed: Optional confirmation step before research execution
- Implementation approach:
  - Add --confirm flag to commands
  - When enabled, display detected topics and prompt for adjustment
  - Allow users to add, remove, or rename topics
  - Skip confirmation for complexity 1-2 (simple prompts)

**Gap Analysis - Topic Dependency Tracking:**
- Current: Topics treated as independent (parallel execution)
- Needed: Track dependencies between topics for ordered execution
- Implementation approach:
  - Extend topic-detection-agent output to include dependencies
  - Format: `{"topics": [...], "dependencies": {"topic2": ["topic1"]}}`
  - research-coordinator respects dependencies (sequential when dependent)
  - Enables research quality improvements (build on prior findings)

### Phase 7: Adaptive Research Depth [DEFERRED]

**Original Scope from spec 009:**
- Complexity-based research allocation (simple prompts = 1 topic, complex = 5 topics)
- Dynamic research-specialist selection (different specialists for different domains)
- Iterative research (coordinator requests follow-up research based on initial findings)

**Current Coverage in Plan 013:**
- RESEARCH_COMPLEXITY influences topic count (Phase 1 heuristics)
- Single research-specialist type used for all topics
- No iterative research capability

**Gap Analysis - Complexity-Based Research Allocation:**
- Current: Heuristic mapping (complexity 1-2 = 1 topic, 3 = 2-3 topics, 4 = 4-5 topics)
- Needed: More nuanced allocation based on prompt analysis
- Implementation approach:
  - Factor in prompt length, domain complexity, ambiguity markers
  - Allow complexity override via --topics N flag
  - Document complexity → topic count mapping in standards

**Gap Analysis - Dynamic Research-Specialist Selection:**
- Current: All research uses generic research-specialist
- Needed: Domain-specific specialists for specialized research
- Implementation approach:
  - Define specialist types: generic, lean-specific, security-focused, performance-focused
  - topic-detection-agent outputs recommended specialist type per topic
  - research-coordinator routes to appropriate specialist
  - Fallback to generic if specialized specialist unavailable

**Gap Analysis - Iterative Research:**
- Current: Single-pass research (coordinator invokes specialists once)
- Needed: Follow-up research based on initial findings
- Implementation approach:
  - research-coordinator analyzes initial results
  - If gaps identified, generates follow-up research topics
  - Maximum 2 iterations to prevent infinite loops
  - Log iteration count and rationale

### Phase 8: Cross-Command Research Sharing [DEFERRED]

**Original Scope from spec 009:**
- Research cache for common topics (reuse Mathlib theorem research across plans)
- Research index for topic discovery (search existing reports before creating new)
- Research versioning (track when research becomes stale, trigger refresh)

**Current Coverage in Plan 013:**
- None - each command creates new research from scratch
- No caching, indexing, or versioning

**Gap Analysis - Research Cache:**
- Current: Every research request creates new reports
- Needed: Cache recent research by topic signature
- Implementation approach:
  - Cache key: normalized topic description hash
  - Cache storage: `.claude/data/research_cache/`
  - Cache TTL: 7 days default, configurable
  - Cache hit behavior: Return cached report path, skip research-specialist invocation
  - Cache miss behavior: Create new research, add to cache

**Gap Analysis - Research Index:**
- Current: No discovery mechanism for existing research
- Needed: Searchable index of all research reports
- Implementation approach:
  - Index storage: `.claude/data/research_index.json`
  - Index fields: topic, path, date, key_findings_summary
  - Index update: research-specialist adds entry on report creation
  - Query API: `search_research_index(query)` returns matching reports
  - Integration: research-coordinator checks index before creating new research

**Gap Analysis - Research Versioning:**
- Current: Research reports are static files with no versioning
- Needed: Track freshness and trigger refresh when stale
- Implementation approach:
  - Add `research_date` field to index
  - Define staleness threshold (14 days default)
  - On cache hit, check freshness
  - If stale, trigger refresh (new research, update cache and index)
  - Optional: track dependencies (invalidate derived research when source changes)

## Integration Requirements Summary

### Command Integration Priority

| Command | Complexity | Priority | Dependencies |
|---------|------------|----------|--------------|
| /repair | High | Medium | Uses research-specialist directly |
| /debug | High | Medium | Uses research-specialist directly |
| /revise | Medium | Medium | Uses research-specialist directly |

### Feature Priority

| Feature | Complexity | Priority | Value |
|---------|------------|----------|-------|
| /repair integration | High | 1 | Enables error analysis multi-topic |
| /debug integration | High | 2 | Enables root cause multi-topic |
| /revise integration | Medium | 3 | Enables revision context multi-topic |
| Research cache | Medium | 4 | Reduces redundant research |
| Research index | Low | 5 | Enables topic discovery |
| Topic clustering | Medium | 6 | Improves topic quality |
| Interactive refinement | Low | 7 | Improves user control |
| Topic dependencies | Medium | 8 | Enables ordered research |
| Dynamic specialists | High | 9 | Requires new agent definitions |
| Iterative research | High | 10 | Complex coordination |
| Research versioning | Medium | 11 | Requires cache first |

## Recommendations for Plan 013 Revision

### Critical Additions (Must Add)

1. **Phase 10: Integrate research-coordinator into /repair**
   - Add topic decomposition for error analysis
   - Replace research-specialist invocation with research-coordinator
   - Update multi-report validation

2. **Phase 11: Integrate research-coordinator into /debug**
   - Add topic decomposition for root cause analysis
   - Replace research-specialist invocation with research-coordinator
   - Update multi-report validation

3. **Phase 12: Integrate research-coordinator into /revise**
   - Add topic decomposition for revision context
   - Replace research-specialist invocation with research-coordinator
   - Update multi-report validation

### Important Additions (Should Add)

4. **Phase 13: Implement Research Cache**
   - Create cache storage infrastructure
   - Add cache check logic to research-coordinator
   - Add cache write logic to research-specialist

5. **Phase 14: Implement Research Index**
   - Create index storage and schema
   - Add index update logic
   - Add search/query capability

### Future Additions (Could Add - Lower Priority)

6. **Phase 15: Advanced Topic Detection** (bundled)
   - LLM-based semantic clustering
   - User-interactive refinement (--confirm flag)
   - Topic dependency tracking

7. **Phase 16: Adaptive Research Depth** (bundled)
   - Enhanced complexity mapping
   - Dynamic specialist selection framework
   - Iterative research capability

8. **Phase 17: Research Versioning**
   - Staleness tracking
   - Automatic refresh triggers

## Estimated Additional Hours

| Phase | Description | Hours |
|-------|-------------|-------|
| Phase 10 | /repair integration | 6-8 |
| Phase 11 | /debug integration | 6-8 |
| Phase 12 | /revise integration | 5-7 |
| Phase 13 | Research cache | 8-10 |
| Phase 14 | Research index | 6-8 |
| Phase 15 | Advanced topic detection | 12-15 |
| Phase 16 | Adaptive research depth | 15-20 |
| Phase 17 | Research versioning | 5-7 |
| **Total** | | **63-83 hours** |

## Conclusion

Plan 013 currently addresses 4 commands (/create-plan, /research, /lean-plan, verification) but leaves 3 commands unintegrated (/repair, /debug, /revise) and all advanced features deferred. To fully implement the research-coordinator vision from spec 009, plan 013 should be expanded to include:

1. Immediate: Phases 10-12 (remaining command integration) - 17-23 hours
2. Medium-term: Phases 13-14 (caching and indexing) - 14-18 hours
3. Long-term: Phases 15-17 (advanced features) - 32-42 hours

This expansion will ensure complete coverage of the original spec 009 vision while maintaining the uniformity standards established in plan 013.
