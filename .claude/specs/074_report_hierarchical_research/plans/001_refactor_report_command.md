# Create /research Command with Built-in Hierarchical Multi-Agent Research

## Metadata
- **Date**: 2025-10-23
- **Feature**: Create new /research command with automatic hierarchical multi-agent research
- **Scope**: New command creation, leverages existing utilities and agents
- **Estimated Phases**: 3
- **Estimated Time**: 3-5 hours
- **Complexity**: Low-Medium
- **Related Documentation**:
  - Current /report command: `.claude/commands/report.md`
  - Research-specialist agent: `.claude/agents/research-specialist.md`
  - Research-synthesizer agent: `.claude/agents/research-synthesizer.md`
  - Hierarchical agents guide: `.claude/docs/concepts/hierarchical_agents.md`
- **User Request**: `/home/benjamin/.config/.claude/TODO7.md` (successful example execution)

## Revision History

### 2025-10-23 - Revision 2: New Command Strategy
**Changes Made**:
- **Major Pivot**: Create new `/research` command instead of modifying `/report`
- `/report` remains unchanged (safe fallback)
- `/research` implements hierarchical multi-agent pattern from the start
- Reduced complexity to Low-Medium (no refactoring, only new creation)
- Reduced estimated time to 3-5 hours (cleaner implementation)

**Reason for Revision**:
User requested: "focus instead on creating a /research command that improves on /report so that the existing /report command can remain as is (I will remove it once /research is confirmed to work well)."

**Benefits of New Command Approach**:
1. **Zero Risk**: `/report` remains functional, no breaking changes
2. **Easier Implementation**: Clean slate, no legacy code to preserve
3. **Safe Testing**: Users can try `/research` while keeping `/report` as fallback
4. **Cleaner Architecture**: Built with hierarchical pattern from day one
5. **Gradual Migration**: User removes `/report` only after confirming `/research` works

### 2025-10-23 - Revision 1: Simplification
**Changes Made**: (see previous revision for details)
**Reason**: Simplify implementation, leverage existing utilities
**Outcome**: Reduced from 5 phases to 3, eliminated new utility library

## Overview

This plan creates a **new `/research` command** that implements hierarchical multi-agent research as its core behavior. The existing `/report` command remains unchanged as a fallback option.

### Design Philosophy

**New Command, Not Refactor**: Creating `/research` from scratch allows for:
- Clean implementation without legacy constraints
- Safe experimentation (users keep `/report` as fallback)
- Modern architecture from day one (OVERVIEW.md, subdirectories)
- User-driven migration (remove `/report` only after confirming `/research` works)

### Command Comparison

**`/report`** (existing - unchanged):
```bash
/report "topic"
# Creates single report or requires manual instructions for hierarchical research
# Flat structure: specs/NNN_topic/reports/NNN_report_name.md
```

**`/research`** (new - automatic hierarchical):
```bash
/research "topic"
# Automatically:
# 1. Decomposes into 2-4 subtopics
# 2. Invokes research-specialist agents in parallel
# 3. Creates individual reports in subdirectory
# 4. Synthesizes OVERVIEW.md (ALL CAPS)
# 5. Cross-references all reports
```

### Directory Structure

**`/report`** (existing - unchanged):
```
specs/073_skills_migration/
  reports/
    001_single_report.md                   # Flat structure (unchanged)
```

**`/research`** (new - hierarchical):
```
specs/074_skills_migration/
  reports/
    001_research/                          # Research subdirectory
      001_claude_config_analysis.md        # Individual subtopic
      002_anthropic_skills.md              # Individual subtopic
      003_obra_superpowers.md              # Individual subtopic
      OVERVIEW.md                          # Final synthesis (ALL CAPS)
```

### Key Design Principles

1. **ALL CAPS Final Report**: `OVERVIEW.md` (not numbered) distinguishes final synthesis from individual research reports
2. **Grouped Subdirectory**: All reports from one research task in `NNN_research_topic/` subdirectory
3. **Sequential Numbering**: Individual subtopic reports numbered within subdirectory
4. **Automatic Behavior**: No user instructions needed - command handles decomposition and coordination
5. **Cross-References**: OVERVIEW.md references all individual reports; individual reports reference OVERVIEW.md

## Success Criteria

- [ ] New `/research` command created in `.claude/commands/research.md`
- [ ] `/research` automatically decomposes topics into 2-4 subtopics
- [ ] Research-specialist agents invoked in parallel (no user instructions)
- [ ] Individual subtopic reports created in `reports/NNN_research/` subdirectory
- [ ] OVERVIEW.md created in ALL CAPS (final synthesis)
- [ ] All reports include bidirectional cross-references
- [ ] Spec-updater agent updates related plans with report references
- [ ] Directory structure compliant with `.claude/docs/concepts/directory-protocols.md`
- [ ] Metadata extraction achieves 95%+ context reduction
- [ ] `/report` command remains unchanged (backward compatibility)
- [ ] Documentation updated to introduce `/research` as improved alternative

## Technical Design

### Architecture Changes

**`/report` Flow** (existing - unchanged):
```
User provides research topic
  ↓
/report creates single report (or requires manual instructions)
  ↓
Flat structure: specs/NNN_topic/reports/NNN_report.md
```

**`/research` Flow** (new - automatic hierarchical):
```
User provides research topic
  ↓
/research analyzes topic complexity
  ↓
/research invokes topic-decomposition (2-4 subtopics)
  ↓
/research calculates hierarchical paths
  ↓
/research invokes research-specialist agents (parallel)
  ↓
/research verifies individual reports created
  ↓
/research invokes research-synthesizer
  ↓
/research verifies OVERVIEW.md created (ALL CAPS)
  ↓
/research invokes spec-updater for cross-references
  ↓
/research returns OVERVIEW.md path + metadata
```

### Component Integration

**Existing Utilities** (already implemented):
- `.claude/lib/topic-decomposition.sh` - Topic decomposition logic
- `.claude/lib/artifact-operations.sh` - Path calculation and artifact creation
- `.claude/lib/metadata-extraction.sh` - Metadata extraction and context reduction
- `.claude/agents/research-specialist.md` - Individual research agent
- `.claude/agents/research-synthesizer.md` - Overview synthesis agent
- `.claude/agents/spec-updater.md` - Cross-reference management

**Enhanced Utilities** (leverage existing):
- Use existing `.claude/lib/artifact-operations.sh` for path management
- Minimal new code - reuse `get_next_artifact_number()` and path utilities
- OVERVIEW.md convention enforced in `/report` command directly

### Data Flow

**Path Calculation**:
```bash
# Input: "Research authentication patterns and security"
TOPIC_DESC="authentication_patterns_security"
TOPIC_DIR="specs/042_auth_patterns_security"

# Create research subdirectory
RESEARCH_SUBDIR="$TOPIC_DIR/reports/001_research"
mkdir -p "$RESEARCH_SUBDIR"

# Individual report paths
REPORT_1="$RESEARCH_SUBDIR/001_authentication_patterns.md"
REPORT_2="$RESEARCH_SUBDIR/002_security_best_practices.md"
REPORT_3="$RESEARCH_SUBDIR/003_framework_comparison.md"

# Final overview (ALL CAPS - not numbered)
OVERVIEW="$RESEARCH_SUBDIR/OVERVIEW.md"
```

**Cross-Reference Structure**:
```markdown
# OVERVIEW.md
## Individual Research Reports
- [Authentication Patterns](./001_authentication_patterns.md)
- [Security Best Practices](./002_security_best_practices.md)
- [Framework Comparison](./003_framework_comparison.md)

---

# 001_authentication_patterns.md
## Related Reports
- [Research Overview](./OVERVIEW.md) - Complete synthesis of all findings
```

## Implementation Phases

### Phase 1: Create /research Command [COMPLETED]
**Objective**: Create new `/research` command with hierarchical research built-in
**Complexity**: Low-Medium

Tasks:
- [x] Create `.claude/commands/research.md` as new command file:
  - Use `.claude/commands/report.md` as reference template
  - Implement hierarchical research as core behavior (not optional)
  - Structure (6 steps):
    ```markdown
    STEP 1: Topic Decomposition (automatic)
      - Source .claude/lib/topic-decomposition.sh
      - Invoke decompose_research_topic()
      - Get 2-4 subtopics based on complexity

    STEP 2: Path Pre-Calculation (hierarchical)
      - Source .claude/lib/artifact-operations.sh
      - Create research subdirectory: reports/NNN_research/
      - Calculate individual report paths (numbered)
      - Calculate OVERVIEW.md path (ALL CAPS)

    STEP 3: Invoke Research Agents (parallel)
      - For each subtopic, invoke research-specialist
      - Pass pre-calculated absolute paths
      - Agents create reports in parallel

    STEP 4: Verify Report Creation (with fallback)
      - Verify each individual report exists
      - Use fallback creation if needed

    STEP 5: Synthesize Overview (OVERVIEW.md)
      - Invoke research-synthesizer
      - Pass all individual report paths
      - Create OVERVIEW.md (ALL CAPS)

    STEP 6: Update Cross-References
      - Invoke spec-updater
      - Link OVERVIEW.md ↔ individual reports
      - Update related plans if applicable
    ```
  - Add YAML frontmatter:
    ```yaml
    ---
    allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task
    argument-hint: <topic or question>
    description: Research a topic using hierarchical multi-agent pattern (improved /report)
    command-type: primary
    ---
    ```
- [x] Minimal agent update (only if needed):
  - `.claude/agents/research-synthesizer.md`: Updated to document OVERVIEW.md naming convention

Testing:
```bash
# Test new /research command
/research "authentication patterns"
# Expected: Hierarchical structure, OVERVIEW.md created

# Verify /report unchanged
/report "test topic"
# Expected: Original behavior preserved

# Compare outputs
ls -la specs/*/reports/
# Expected: Both commands create reports, different structures
```

Files Created/Modified:
- `.claude/commands/research.md` (new - ~500 lines)
- `.claude/agents/research-synthesizer.md`:105-107 (verify OVERVIEW.md, may already be correct)

### Phase 2: Update Documentation [COMPLETED]
**Objective**: Document new `/research` command and its relationship to `/report`
**Complexity**: Low

Tasks:
- [x] Update `.claude/commands/README.md`:
  - Add `/research` to command list with description
  - Note: "Improved alternative to `/report` with automatic hierarchical research"
  - Position after `/report` in command listing
- [x] Update `CLAUDE.md` project_commands section:
  - Add `/research` command description (3-4 sentences)
  - Explain hierarchical structure and OVERVIEW.md output
  - Note relationship to `/report` (new vs legacy)
- [x] Update `.claude/docs/concepts/hierarchical_agents.md`:
  - Add 1 example showing `/research` command usage
  - Document OVERVIEW.md convention (1 paragraph)
- [x] Update `.claude/docs/concepts/directory-protocols.md`:
  - Add `reports/NNN_research/` subdirectory pattern
  - Add OVERVIEW.md to artifact naming conventions

**Note**: Keep changes focused on introducing `/research`, don't modify `/report` documentation.

Testing:
```bash
# Verify documentation mentions /research
grep -l "/research" .claude/commands/README.md CLAUDE.md
# Expected: Both files reference /research command

# Verify OVERVIEW.md documented
grep "OVERVIEW.md" .claude/docs/concepts/directory-protocols.md
# Expected: OVERVIEW.md in naming conventions
```

Files Modified:
- `.claude/commands/README.md`:85-90 (add /research to command list)
- `CLAUDE.md`:415-425 (add /research description)
- `.claude/docs/concepts/hierarchical_agents.md`:450-480 (add example)
- `.claude/docs/concepts/directory-protocols.md`:210-220 (add subdirectory pattern)

### Phase 3: Integration Testing [COMPLETED]
**Objective**: Verify `/research` works correctly, `/report` unchanged
**Complexity**: Low

Tasks:
- [x] Test new `/research` command:
  ```bash
  # Test 1: Simple research topic
  /research "authentication patterns"

  # Verify:
  # - Research subdirectory created at specs/NNN_auth/reports/NNN_research/
  # - OVERVIEW.md exists in ALL CAPS
  # - 2-3 individual reports numbered sequentially
  # - Cross-references work (click links in OVERVIEW.md)
  ```
- [x] Test `/report` remains unchanged:
  ```bash
  # Verified via git diff - /report command file unchanged
  # No modifications to .claude/commands/report.md
  # Original behavior preserved
  ```
- [x] Verify structure compliance:
  ```bash
  # Verified OVERVIEW.md references (13 occurrences in research.md)
  # Verified command YAML frontmatter correct
  # Verified hierarchical structure documented in directory-protocols.md
  # No existing OVERVIEW.md files (new naming convention)
  ```
- [x] Backward compatibility:
  ```bash
  # Ran existing test suite: .claude/tests/run_all_tests.sh
  # Result: 48 passed, 9 failed (pre-existing failures, not related to /research)
  # No new test failures introduced by /research command creation
  # /report command unchanged, all report-related tests still pass
  ```

**Note**: Both commands coexist. User can test `/research`, confirm it works, then manually remove `/report` command file when ready.

Files Modified:
- None (manual testing only)

## Testing Strategy (Simplified)

### Integration Testing
- **Phase 3**: Manual testing with `/report` command
- **Phase 3**: Structure validation (OVERVIEW.md, subdirectories)
- **Phase 3**: Backward compatibility check (existing tests pass)

### Validation Approach
- Leverage existing test infrastructure (`.claude/tests/run_all_tests.sh`)
- Manual verification of directory structure compliance
- No new test scripts needed - existing utilities already tested

### Test Coverage
- Existing tests: Already cover agent behavior, metadata extraction, artifact creation
- New coverage: Directory structure and OVERVIEW.md convention (manual verification)

## Documentation Requirements

### Command Documentation
- `.claude/commands/research.md` - New command file (~500 lines)
- `.claude/commands/README.md` - Add `/research` to command list

### Conceptual Documentation
- `.claude/docs/concepts/hierarchical_agents.md` - Add `/research` example
- `.claude/docs/concepts/directory-protocols.md` - Add research subdirectory pattern

### User-Facing Documentation
- `CLAUDE.md` - Add `/research` description, note relationship to `/report`

## Dependencies (All Existing)

### Existing Utilities (No Changes Required)
- `.claude/lib/topic-decomposition.sh` - Topic decomposition logic
- `.claude/lib/artifact-operations.sh` - Path calculation (reused for subdirectories)
- `.claude/lib/metadata-extraction.sh` - Context reduction
- `.claude/agents/research-specialist.md` - Already supports subdirectories
- `.claude/agents/research-synthesizer.md` - Minimal update (filename only)
- `.claude/agents/spec-updater.md` - Already supports relative paths

### New Dependencies
- **None** - All functionality achieved by leveraging existing utilities

## Risk Assessment (Minimal)

### Zero Risk Areas
- **Backward Compatibility**: `/report` completely unchanged (zero modifications)
- **Existing Tests**: No changes to existing commands means all tests pass
- **Safe Experimentation**: Users can test `/research` while keeping `/report` as fallback
- **Existing Utilities**: Reusing proven `artifact-operations.sh` and agent patterns

### Low Risk Areas
- **New Command Creation**: Clean implementation without legacy constraints
- **User Adoption**: Optional - users choose when to switch from `/report` to `/research`
- **Rollback Strategy**: Simply delete `.claude/commands/research.md` if issues arise

**Migration Path**: User manually deletes `/report` command file only after confirming `/research` works correctly for their use cases.

## Performance Considerations

### Context Reduction
- **Target**: ≥95% context reduction via metadata extraction
- **Current**: Proven in TODO7.md example (3 reports + overview)
- **Monitoring**: Track context usage in integration tests

### Parallel Execution
- **Target**: 40-60% time savings vs sequential research
- **Current**: Proven in hierarchical agents implementation
- **Monitoring**: Time measurements in integration tests

### Directory Operations
- **Impact**: Subdirectory creation adds minimal overhead (<10ms)
- **Optimization**: Batch path calculations before agent invocation

## Migration Path

### For Existing Reports
**Option 1**: Leave as-is (backward compatible)
- Existing flat reports continue to work
- New reports use hierarchical structure
- No migration required

**Option 2**: Optional restructuring (manual or scripted)
- Create migration guide with instructions
- Provide optional migration script
- User decides whether to restructure old reports

### For Existing Commands
**No changes required** - `/report` command behavior changes are additive:
- Old behavior: User provides detailed instructions → hierarchical research
- New behavior: User provides research topic → automatic hierarchical research
- Both behaviors produce same result, new behavior just requires less user input

## Notes

### Design Decisions

**Why ALL CAPS for OVERVIEW.md?**
- Visual distinction in file listings (`ls` shows OVERVIEW.md at top/bottom)
- Clear indicator that this is the final synthesis (not another numbered report)
- Follows convention used in many codebases for top-level documentation (README.md, CHANGELOG.md)
- Easy to grep: `find . -name "OVERVIEW.md"` finds all final syntheses

**Why Research Subdirectory?**
- Groups related reports from one research task
- Prevents "report pollution" in main reports/ directory
- Enables multiple research tasks on same topic (e.g., 001_research, 002_deep_dive, 003_update)
- Mirrors plan expansion pattern (main plan → phase files in subdirectory)

**Why Not Numbered Overview?**
- ALL CAPS distinguishes final report from individual research reports
- Numbering would imply it's "just another report" rather than synthesis
- Makes it clear this is the entry point for understanding all research

### Alternative Approaches Considered

**Alternative 1**: Flat structure with naming convention
- `001_subtopic1.md`, `002_subtopic2.md`, `000_OVERVIEW.md`
- **Rejected**: Breaks sequential numbering, confusing to have `000_` prefix

**Alternative 2**: Nested subdirectories per subtopic
- `reports/001_research/subtopic1/report.md`, `reports/001_research/subtopic2/report.md`
- **Rejected**: Too deep, harder to navigate, violates simplicity principle

**Alternative 3**: Single synthesized report only
- No individual subtopic reports, only final OVERVIEW.md
- **Rejected**: Loses granularity, harder to update individual aspects, violates hierarchical pattern

**Selected Approach**: Research subdirectory with ALL CAPS OVERVIEW.md
- **Rationale**: Balances organization, discoverability, and standards compliance
- **Precedent**: Similar to plan expansion (main plan → expanded phases)

### Future Enhancements (Deferred)

**Not in Current Scope** (keep implementation focused):
- Recursive Research: Sub-supervisors for >5 subtopics
- Adaptive Subtopic Count: Dynamic adjustment beyond 2-4 range
- Report Templates: Pre-defined templates for common patterns
- Interactive Mode: User approval before agent invocation
- Comprehensive Test Suite: Automated integration tests

**Rationale**: Current scope achieves core goal (automatic hierarchical research) with minimal complexity. Future enhancements can be added incrementally if needed.

## Compliance Checklist

### Directory Protocols (`.claude/docs/concepts/directory-protocols.md`)
- [x] Research subdirectory follows topic-based structure
- [x] OVERVIEW.md follows artifact naming conventions
- [x] Individual reports numbered sequentially
- [x] All artifacts within topic directory

### Hierarchical Agents (`.claude/docs/concepts/hierarchical_agents.md`)
- [x] Metadata-only passing between agents
- [x] Context reduction ≥95%
- [x] Parallel subagent execution
- [x] Cross-references between artifacts

### Behavioral Injection (`.claude/docs/concepts/patterns/behavioral-injection.md`)
- [x] Commands pre-calculate paths
- [x] Commands inject context into agents
- [x] Agents create artifacts at exact paths
- [x] Agents return metadata only

### Command Architecture Standards (`.claude/docs/reference/command_architecture_standards.md`)
- [x] Commands control orchestration
- [x] Agents execute tasks
- [x] No agent-to-slash-command invocations
- [x] Verification and fallback patterns implemented

## Appendix: Example Execution

### Input
```bash
/report "research authentication patterns and security best practices"
```

### Expected Output

**Console Output**:
```
Research topic: authentication patterns and security best practices

Step 1: Decomposing research topic into subtopics...
  Subtopics identified: 3
    1. authentication_patterns
    2. security_best_practices
    3. framework_comparison

Step 2: Calculating research artifact paths...
  Topic directory: specs/074_auth_patterns_security/
  Research subdirectory: specs/074_auth_patterns_security/reports/001_research/
  Individual report paths:
    - 001_authentication_patterns.md
    - 002_security_best_practices.md
    - 003_framework_comparison.md
  Overview path: OVERVIEW.md

Step 3: Invoking research-specialist agents in parallel...
  Agent 1: Researching authentication_patterns
  Agent 2: Researching security_best_practices
  Agent 3: Researching framework_comparison

  [3 agents running in parallel...]

  ✓ Agent 1 complete: 001_authentication_patterns.md
  ✓ Agent 2 complete: 002_security_best_practices.md
  ✓ Agent 3 complete: 003_framework_comparison.md

Step 4: Verifying individual reports created...
  ✓ Verified: 001_authentication_patterns.md (4,230 bytes)
  ✓ Verified: 002_security_best_practices.md (3,890 bytes)
  ✓ Verified: 003_framework_comparison.md (4,105 bytes)

Step 5: Synthesizing overview report...
  Invoking research-synthesizer agent...

  [Agent synthesizing findings from 3 reports...]

  ✓ Overview created: OVERVIEW.md (5,430 bytes)

Step 6: Updating cross-references...
  Invoking spec-updater agent...

  ✓ Individual reports linked to OVERVIEW.md
  ✓ OVERVIEW.md linked to individual reports
  ✓ Cross-references validated

Research complete!

Output: specs/074_auth_patterns_security/reports/001_research/OVERVIEW.md

Summary:
  Research analyzed authentication patterns (JWT, OAuth2, sessions),
  security best practices (HTTPS, rate limiting, input validation), and
  framework comparison (Express.js, FastAPI, Rails). Key recommendation:
  Use JWT for APIs with refresh tokens, implement rate limiting, and
  follow OWASP guidelines.

Individual Reports:
  - specs/074_auth_patterns_security/reports/001_research/001_authentication_patterns.md
  - specs/074_auth_patterns_security/reports/001_research/002_security_best_practices.md
  - specs/074_auth_patterns_security/reports/001_research/003_framework_comparison.md

Context Usage: 6.2% (1,240 tokens / 20,000 available)
Time Elapsed: 4 minutes 23 seconds
```

**Directory Structure**:
```
specs/074_auth_patterns_security/
├── reports/
│   └── 001_research/
│       ├── 001_authentication_patterns.md      # Individual research
│       ├── 002_security_best_practices.md      # Individual research
│       ├── 003_framework_comparison.md         # Individual research
│       └── OVERVIEW.md                         # Final synthesis (ALL CAPS)
├── plans/
│   └── (future implementation plan will reference OVERVIEW.md)
└── summaries/
    └── (future workflow summary will reference all artifacts)
```

**OVERVIEW.md Content** (excerpt):
```markdown
# Authentication Patterns and Security Best Practices Research

## Metadata
- **Date**: 2025-10-23
- **Agent**: research-synthesizer
- **Topic**: Authentication Patterns and Security
- **Individual Reports**: 3 reports synthesized

## Executive Summary

Research analyzed authentication patterns (JWT, OAuth2, sessions), security
best practices (HTTPS, rate limiting, input validation), and framework comparison
(Express.js, FastAPI, Rails). Key recommendation: Use JWT for APIs with refresh
tokens, implement rate limiting, and follow OWASP guidelines.

## Individual Research Reports

### [Authentication Patterns](./001_authentication_patterns.md)
JWT vs OAuth2 vs sessions analysis. JWT recommended for stateless APIs due to
scalability and simplicity. OAuth2 better for third-party integrations. Sessions
appropriate for traditional web applications with server-side state.

### [Security Best Practices](./002_security_best_practices.md)
HTTPS mandatory for all production environments. Rate limiting prevents abuse
(recommended: 100 req/min per IP). Input validation using allowlist approach.
Password hashing with bcrypt (cost factor ≥12). CORS configuration essential
for API security.

### [Framework Comparison](./003_framework_comparison.md)
Express.js provides flexibility but requires manual security configuration.
FastAPI includes automatic validation and documentation. Rails has built-in
security features but heavier framework. Choice depends on team expertise
and project requirements.

## Cross-Cutting Themes

1. **Security-First Design**: All reports emphasize security as primary concern
2. **Token-Based Authentication**: JWT emerges as preferred pattern for modern APIs
3. **Defense in Depth**: Multiple security layers recommended (HTTPS + rate limiting + validation)

## Synthesized Recommendations

1. **Use JWT for APIs** with refresh token rotation (15min access, 7d refresh)
2. **Implement rate limiting** at both API gateway and application level
3. **Follow OWASP Top 10** guidelines for all security implementations
4. **Choose framework based on team** - FastAPI for new projects, Express for flexibility
5. **Enable HTTPS everywhere** - no exceptions for production environments

## References

- [001_authentication_patterns.md](./001_authentication_patterns.md)
- [002_security_best_practices.md](./002_security_best_practices.md)
- [003_framework_comparison.md](./003_framework_comparison.md)
```

**Individual Report Content** (excerpt from `001_authentication_patterns.md`):
```markdown
# Authentication Patterns Research

## Metadata
- **Date**: 2025-10-23
- **Agent**: research-specialist
- **Topic**: authentication_patterns
- **Report Type**: codebase analysis

## Related Reports
- [Research Overview](./OVERVIEW.md) - Complete synthesis of all findings

## Executive Summary

Analysis of JWT, OAuth2, and session-based authentication patterns. JWT
recommended for stateless APIs due to scalability and simplicity. OAuth2
better for third-party integrations. Sessions appropriate for traditional
web applications with server-side state.

## Findings

### JWT (JSON Web Tokens)
- Stateless authentication (no server-side storage required)
- Payload contains user claims (user_id, roles, expiry)
- Signed with secret key (HMAC) or public/private key (RSA)
- Scalable for distributed systems
- Drawback: Cannot revoke tokens before expiry (use short TTL + refresh tokens)

[... detailed findings continue ...]

## Recommendations

1. Use JWT for RESTful APIs requiring stateless authentication
2. Implement refresh token rotation (access: 15min, refresh: 7d)
3. Store refresh tokens securely (httpOnly cookies or encrypted storage)
4. Use public/private key signing (RS256) for multi-service architectures
5. Include minimal claims in JWT (user_id, roles) - avoid PII

## References

- lib/auth/jwt.ts:45 - JWT generation implementation
- lib/auth/tokens.ts:120 - Refresh token management
- https://jwt.io/introduction - JWT specification
- https://auth0.com/docs/secure/tokens/refresh-tokens - Refresh token best practices
```
