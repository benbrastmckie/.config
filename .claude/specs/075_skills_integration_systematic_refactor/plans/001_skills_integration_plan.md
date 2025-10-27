# Skills Integration Systematic Refactor Plan

## Plan Metadata
- **Plan ID**: 001_skills_integration_plan
- **Topic**: 075_skills_integration_systematic_refactor
- **Created**: 2025-10-23
- **Status**: Active
- **Complexity**: 6.5/10
- **Estimated Duration**: 6-9 weeks

## Objective
Integrate Claude Code skills system into existing .claude/ configuration while maintaining compliance with .claude/docs/ standards and creating systematic documentation for the new skill implementation.

## Research Reports
- [Skills System Architecture](../reports/001_skills_system_architecture.md)
- [Claude Config Compliance](../reports/002_claude_config_compliance.md)
- [Documentation Standards](../reports/003_documentation_standards.md)
- [Integration Patterns](../reports/004_integration_patterns.md)

## Success Criteria
- Skills system integrated with existing .claude/ architecture
- Documentation standards applied to all skill files
- Context management patterns implemented for skills
- Skills registry system operational
- All 4 research reports integrated into implementation
- User can review progress at each stage before proceeding

## Risk Assessment
- **Low Risk**: Adopting pre-built skills from obra/superpowers (battle-tested, community-validated)
- **Medium Risk**: Creating custom meta-level enforcement skills (new pattern, requires testing)
- **Low Risk**: Documentation infrastructure (extends existing patterns)
- **Medium Risk**: Integration with current behavioral injection architecture (requires careful coordination)

## Complexity Assessment
**Overall Complexity**: 6.5/10

- Multi-phase refactor with 6 distinct stages
- Integration across multiple system layers (commands, agents, utilities, documentation)
- Balance between preservation (orchestration) and innovation (skills)
- Requires user review checkpoints at each stage
- **Efficiency Factors**: Extends agent-registry-utils.sh (90% code overlap), uses unified-location-detection.sh (85% token reduction, 36x speedup), leverages 9 documented architectural patterns

**Estimated Duration**: 6-9 weeks

**Phase Duration Breakdown**:
- Phase 0: 1 week (documentation foundation)
- Phase 1: 1 week (extend existing registry infrastructure)
- Phase 2: 1-2 weeks (obra/superpowers integration)
- Phase 3: 1 week (Anthropic document skills)
- Phase 4: 1-2 weeks (custom guidance skills, pre-commit hooks)
- Phase 5: 2-3 weeks (command integration and agent migration)
- Phase 6: 1 week (validation and optimization with existing documentation)

**Existing Infrastructure**:
- **agent-registry-utils.sh**: Registry patterns, frontmatter parsing, metadata extraction, caching
- **unified-location-detection.sh**: Location detection, directory creation, topic numbering (85% token reduction, 36x speedup)
- **artifact-creation.sh**: Lazy directory creation (`ensure_artifact_directory()`), artifact path calculation
- **Documented Patterns** (9 files): behavioral-injection, metadata-extraction, verification-fallback, checkpoint-recovery, context-management, forward-message, hierarchical-supervision, parallel-execution, README
- **Clean Infrastructure**: 266KB library consolidation, 25 scripts archived, /research command provides hierarchical multi-agent research

## Implementation Phases

### Phase 0: Planning and Documentation Foundation
**Status**: Pending
**Objective**: Create documentation infrastructure and skill definition standards
**Complexity**: 4/10
**Duration**: 1 week

#### Tasks
1. Create skill definition template in `.claude/templates/skill-definition-template.md`
   - Follow agent definition format with frontmatter
   - Include sections: Core Capabilities, Standards Compliance, Behavioral Guidelines, Expected Input/Output
   - Apply enforcement patterns (YOU MUST, EXECUTE NOW, MANDATORY VERIFICATION)
   - Ensure metadata extraction compatibility

2. Create skills README in `.claude/skills/README.md`
   - Document purpose of skills directory
   - Explain relationship to agents (specialized capabilities vs orchestration)
   - Link to command_architecture_standards.md
   - Provide tool access patterns documentation
   - Include invocation patterns (behavioral injection)
   - Add quality checklist for skills development

3. Document skills integration in `.claude/docs/guides/skills-integration-guide.md`
   - Explain hybrid architecture (skills for expertise, subagents for workflows)
   - Reference existing skills-vs-subagents decision guide (`.claude/docs/guides/skills-vs-subagents-decision.md`)
   - Extend with integration examples with commands
   - Document context management for skills
   - Reference all 4 research reports
   - Reference documented architectural patterns (`.claude/docs/concepts/patterns/README.md`)

4. Add skills section to CLAUDE.md template
   - Define skills section with markers (<!-- SECTION: skills_system -->)
   - Include [Used by: commands] metadata
   - Document enabled skills and their purposes
   - Link to skills-integration-guide.md

5. Extend pre-commit validation for skills
   - Add skill file validation (≥200 lines minimum)
   - Verify frontmatter completeness (allowed-tools, description)
   - Check required sections (Core Capabilities, Standards Compliance, etc.)
   - Scan for temporal markers (timeless writing policy)

#### Testing
- Validate template against command_architecture_standards.md
- Verify README navigation links work correctly
- Test pre-commit hook with sample skill file
- Run timeless writing validation on all new documentation

#### Success Criteria
- All documentation templates created and validated
- Pre-commit hook extends to skills directory
- Cross-references complete and tested
- **USER REVIEW CHECKPOINT**: Review documentation standards before proceeding

#### Artifacts Created
- `.claude/templates/skill-definition-template.md`
- `.claude/skills/README.md`
- `.claude/docs/guides/skills-integration-guide.md`
- `.git/hooks/pre-commit` (extended with skills validation)

---

### Phase 1: Skills Registry Infrastructure
**Status**: Pending
**Objective**: Build skill discovery, registration, and invocation infrastructure
**Complexity**: 5/10
**Duration**: 1 week

#### Dependencies
- Phase 0 must be complete
- User approval of documentation standards required

#### Existing Infrastructure
- **agent-registry-utils.sh** provides registry patterns with 90% code overlap (frontmatter parsing, metadata extraction, caching)
- **unified-location-detection.sh** provides directory creation utilities (85% token reduction, 36x speedup vs agent-based approach)
- **artifact-creation.sh** provides lazy directory creation pattern (`ensure_artifact_directory()`)

#### Tasks
1. Extend skills registry system in `.claude/lib/agent-registry-utils.sh` to support skills
   - Add `list_skills()` - List all available skills (reuse `list_agents()` pattern)
   - Add `validate_skill(skill_name)` - Verify skill exists and is valid (reuse `validate_agent()` pattern)
   - Add `get_skill_info(skill_name)` - Extract metadata from frontmatter (reuse `get_agent_info()` pattern)
   - Add `get_skill_capabilities(skill_name)` - Parse capabilities section (new function)
   - Add `find_skills_by_capability(pattern)` - Capability-based search (new function)
   - Add `load_skill_behavioral_prompt(skill_name)` - Reuse agent loading pattern
   - Extend existing caching for performance (project skills override global skills)
   - **Effort saved**: ~5KB code, 1 week development time by extending existing registry instead of creating parallel system

2. Create `.claude/skills/` directory structure using existing infrastructure
   - Use `ensure_artifact_directory()` pattern from artifact-creation.sh for lazy directory creation
   - Main directories: `converters/`, `analyzers/`, `enforcers/`, `integrations/`
   - Each skill in subdirectory: `skill-name/SKILL.md`
   - Support for optional files: `reference.md`, `scripts/`, `templates/`
   - Leverage unified-location-detection.sh for directory path resolution (85% token reduction benefit)

3. Extend metadata extraction utilities for skills
   - Implement `extract_skill_metadata()` in `.claude/lib/metadata-extraction.sh` (extends existing utility)
   - Extract title, description, capabilities, allowed-tools
   - Support 95-99% context reduction pattern (see `.claude/docs/concepts/patterns/metadata-extraction.md`)
   - Return metadata-only format compatible with existing patterns
   - Follow verification-fallback pattern (see `.claude/docs/concepts/patterns/verification-fallback.md`) for 100% file creation rate

4. Integrate skills with context management
   - Add skills pruning to `.claude/lib/context-pruning.sh`
   - Implement `prune_skill_output()` - Clear full outputs after metadata extraction
   - Add skills to layered context architecture documentation
   - Ensure <30% context usage target maintained

5. Create skill invocation wrapper utilities
   - Add `invoke_skill()` function in `.claude/lib/skills-invocation.sh`
   - Support behavioral injection pattern (see `.claude/docs/concepts/patterns/behavioral-injection.md`)
   - Follow imperative agent invocation pattern per Standard 11 (see `.claude/docs/reference/command_architecture_standards.md`)
   - Pre-calculate artifact paths before invocation
   - Verify skill outputs with mandatory verification checkpoints (verification-fallback pattern)
   - Implement fallback recovery mechanisms (checkpoint-recovery pattern: `.claude/docs/concepts/patterns/checkpoint-recovery.md`)

#### Testing
- Test skill discovery with sample skills across all capability directories
- Validate metadata extraction produces expected format
- Verify context pruning reduces token usage
- Test skill invocation wrapper with mock skill files
- Run performance benchmarks (caching, discovery time)

#### Success Criteria
- All registry functions operational
- Skills directory structure created with documentation
- Metadata extraction compatible with existing patterns
- Context management integration complete
- **USER REVIEW CHECKPOINT**: Review infrastructure before installing external skills

#### Artifacts Created
- `.claude/lib/agent-registry-utils.sh` (extended with skills support: list_skills(), validate_skill(), get_skill_info())
- `.claude/lib/skills-invocation.sh`
- `.claude/lib/metadata-extraction.sh` (extended with `extract_skill_metadata()`)
- `.claude/lib/context-pruning.sh` (extended with `prune_skill_output()`)
- `.claude/skills/README.md` (complete directory structure documentation)

---

### Phase 2: obra/superpowers Integration
**Status**: Pending
**Objective**: Install and configure obra/superpowers community skills (20+ battle-tested skills)
**Complexity**: 5/10
**Duration**: 1-2 weeks

#### Dependencies
- Phase 1 must be complete
- User approval of registry infrastructure required

#### Tasks
1. Install obra/superpowers plugin
   - Run `/plugin marketplace add obra/superpowers-marketplace`
   - Run `/plugin install superpowers@superpowers-marketplace`
   - Verify installation with `/plugin list`

2. Identify skills to enable
   - **Collaboration**: dispatching-parallel-agents, requesting-code-review, receiving-code-review, using-git-worktrees, finishing-a-development-branch, subagent-driven-development
   - **Testing**: test-driven-development, condition-based-waiting, testing-anti-patterns
   - **Debugging**: systematic-debugging, root-cause-tracing, verification-before-completion, defense-in-depth
   - **Meta**: writing-skills, sharing-skills, testing-skills-with-subagents, using-superpowers
   - **Skip**: brainstorming, writing-plans, executing-plans (conflict with /plan and /implement)

3. Update CLAUDE.md with enabled skills
   - Add <!-- SECTION: skills_system --> with enabled skills list
   - Document each skill's purpose and when it activates
   - Reference skills-integration-guide.md for details
   - Include [Used by: commands] metadata

4. Test skills in isolated workflows
   - **Document generation**: Test with sample markdown → PDF conversion
   - **Testing**: Verify test-driven-development activates during test writing
   - **Debugging**: Validate systematic-debugging provides 4-phase investigation
   - **Collaboration**: Test dispatching-parallel-agents with /orchestrate

5. Measure baseline performance
   - Capture token usage before skills (baseline)
   - Capture token usage with skills enabled
   - Measure workflow execution time (parallel vs sequential)
   - Validate <30% context usage maintained

#### Testing
- Test each skill category independently
- Verify no conflicts with existing commands/agents
- Validate skills activate in appropriate contexts
- Measure token reduction and performance gains
- Test git worktrees workflow (40-60% productivity gain expected)
- Test parallel agents coordination (50-70% time reduction expected)

#### Success Criteria
- All selected skills installed and verified
- CLAUDE.md updated with skills documentation
- Performance baselines captured
- No conflicts with existing architecture
- **USER REVIEW CHECKPOINT**: Review performance metrics and skill activation before custom skills

#### Artifacts Created
- `CLAUDE.md` (skills section with enabled skills list)
- Performance baseline metrics (`.claude/data/metrics/skills-baseline.json`)
- Skills activation test results

---

### Phase 3: Anthropic Document Skills Integration
**Status**: Pending
**Objective**: Install and configure Anthropic official document skills (docx, pdf, pptx, xlsx)
**Complexity**: 4/10
**Duration**: 1 week

#### Dependencies
- Phase 2 must be complete
- User approval of obra/superpowers integration required

#### Tasks
1. Install Anthropic document skills plugin
   - Run `/plugin install document-skills@anthropic-agent-skills`
   - Verify installation with `/plugin list`
   - List available skills with skills registry

2. Test document conversion skills
   - Test docx: Markdown → Word document conversion
   - Test pdf: Markdown → PDF with formatting preservation
   - Test pptx: Outline → PowerPoint presentation
   - Test xlsx: CSV/data → Excel spreadsheet with formulas

3. Update /convert-docs command integration
   - Replace custom doc-converter agent references with skills
   - Update command to rely on automatic skill activation
   - Add skills availability check at command start
   - Document expected token savings (98% reduction baseline)

4. Test deterministic vs token generation
   - Validate binary format handling quality (DOCX structure, PDF layout)
   - Compare output quality: skills vs previous token generation
   - Verify formula evaluation in xlsx skill
   - Test edge cases (complex formatting, large files)

5. Update documentation
   - Add document skills to CLAUDE.md skills section
   - Update /convert-docs command documentation
   - Reference Anthropic skills documentation
   - Document when skills activate vs manual conversion

#### Testing
- Test all 4 document skills independently
- Validate format preservation and quality
- Test integration with /convert-docs command
- Measure token usage reduction (before/after)
- Verify binary output correctness

#### Success Criteria
- All 4 document skills operational
- /convert-docs command updated and tested
- Documentation complete
- Token reduction validated (≥90% expected)
- **USER REVIEW CHECKPOINT**: Review document conversion quality before custom skills

#### Artifacts Created
- `.claude/commands/convert-docs.md` (integrated with Anthropic document skills)
- `CLAUDE.md` (document skills section)
- Document conversion test results

---

### Phase 4: Custom Meta-Level Enforcement Skills
**Status**: Pending
**Objective**: Create project-specific skills that provide guidance and enforce testable standards from CLAUDE.md
**Complexity**: 6/10
**Duration**: 1-2 weeks

#### Dependencies
- Phase 3 must be complete
- User approval of document skills integration required

#### Rationale: Skills vs Libraries for Enforcement
Skills excel at providing guidance and making context-aware decisions, not enforcing deterministic rules. Deterministic enforcement (indentation, line length, timeless writing) belongs in unified libraries and pre-commit hooks. Skills should focus on subjective judgment (code quality, test completeness, debugging strategies).

#### Tasks
1. Create code-standards-guidance skill
   - Location: `.claude/skills/enforcers/code-standards-guidance/SKILL.md`
   - Read CLAUDE.md ## Code Standards section
   - Detect file type from extension
   - Extract language-specific standards
   - Provide guidance on code organization, naming conventions, error handling patterns
   - Focus on subjective quality (not deterministic rules like indentation)
   - Use allowed-tools: Read, Edit (restrict Write for safety)
   - Note: Deterministic checks (indentation, line length) handled by pre-commit hooks

2. Create testing-protocols-guidance skill
   - Location: `.claude/skills/enforcers/testing-protocols-guidance/SKILL.md`
   - Read CLAUDE.md ## Testing Protocols section
   - Provide guidance on test coverage strategies
   - Suggest test patterns for edge cases
   - Recommend integration vs unit test approaches
   - Use allowed-tools: Read, Bash (for test execution)
   - Note: Coverage thresholds enforced by test runners, skill provides strategic guidance

3. Reference systematic-debugging skill from obra/superpowers (no custom skill needed)
   - obra/superpowers provides systematic-debugging and root-cause-tracing skills
   - These provide 4-phase investigation methodology
   - No need to create custom debugging skill, leverage community-validated patterns

4. Update CLAUDE.md sections with links
   - Add file path references in ## Code Standards
   - Add file path references in ## Testing Protocols
   - Document where standards are defined (links to detailed files)
   - Note: ## Documentation Policy enforcement handled by pre-commit hooks (no skill needed)

5. Test automatic activation
   - Edit .lua file → code-standards-guidance activates
   - Run /test-all → testing-protocols-guidance activates
   - Invoke /debug → systematic-debugging skill (obra/superpowers) activates
   - Verify standards read from CLAUDE.md correctly

6. Measure token reduction
   - Baseline: Commands load standards sections directly (~6000 tokens)
   - With skills: Skills dormant (90 tokens), activate on demand (6000 tokens first time, cached)
   - Expected savings: 96% reduction baseline, standards cached across phases

#### Testing
- Test each guidance skill independently
- Validate standards discovery across project types
- Verify guidance quality (subjective vs deterministic)
- Test skill portability (same skill, different project with different standards)
- Measure token usage before/after
- Verify pre-commit hooks handle deterministic enforcement

#### Success Criteria
- 2 custom guidance skills created and tested (code, testing)
- obra/superpowers debugging skills integrated
- CLAUDE.md updated with file path references
- Automatic activation verified
- Token reduction validated (≥90% expected)
- Skills portable across projects
- Deterministic enforcement delegated to pre-commit hooks
- **USER REVIEW CHECKPOINT**: Review guidance behavior before command integration

#### Artifacts Created
- `.claude/skills/enforcers/code-standards-guidance/SKILL.md`
- `.claude/skills/enforcers/testing-protocols-guidance/SKILL.md`
- `CLAUDE.md` (file path references in Code Standards and Testing Protocols sections)
- Note: Documentation standards enforcement delegated to pre-commit hooks

---

### Phase 5: Command Integration and Agent Migration
**Status**: Pending
**Objective**: Update commands to leverage skills, migrate simple agents to skills where appropriate
**Complexity**: 7/10
**Duration**: 2-3 weeks

#### Dependencies
- Phase 4 must be complete
- User approval of custom enforcement skills required

#### Tasks
1. Update /implement command integration
   - Add skills availability notation in behavioral prompts
   - Document which skills auto-activate during implementation
   - Remove redundant standards injection (handled by enforcement skills)
   - Test adaptive planning with skills active
   - Verify checkpoint recovery compatible with skills

2. Update /orchestrate command integration
   - Add skills coordination for parallel workflows
   - Reference dispatching-parallel-agents skill
   - Update multi-agent workflow documentation
   - Test hierarchical supervision with skills
   - Verify context management (<30% usage maintained)

3. Update /test-all command integration
   - Reference test-driven-development skill
   - Reference testing-protocols-enforcement skill
   - Remove inline testing methodology (handled by skills)
   - Verify coverage thresholds enforced by skill

4. Update /debug command integration
   - Reference systematic-debugging skill
   - Reference root-cause-tracing skill
   - Update debug workflow to leverage skills
   - Test parallel hypothesis investigation

5. Migrate simple agents to skills (where appropriate)
   - **doc-converter**: Replace with Anthropic document skills (already done in Phase 3)
   - **github-specialist**: Evaluate for migration to github-operations skill
   - **metrics-specialist**: Evaluate for migration to performance-metrics skill
   - **Preserve**: Keep orchestration agents (spec-updater, plan-architect, implementation-executor, plan-structure-manager)
   - **plan-structure-manager**: Created 2025-10-26, handles Phase/Stage expansion operations (integrates with /expand and /collapse commands)
   - **Potential skills opportunity**: "when to expand phases" decision-making skill during /plan creation (provides complexity threshold guidance, complements plan-structure-manager execution)

6. Update agent behavioral prompts
   - Add "Skills Available (auto-activate)" section
   - List expected skills for each workflow type
   - Remove redundant standards injection
   - Verify behavioral injection pattern maintained

#### Testing
- Test each command with skills integration
- Verify skills activate automatically in appropriate contexts
- Test agent migration paths (document conversion quality)
- Validate context usage remains <30%
- Measure end-to-end workflow performance
- Test checkpoint recovery with skills active

#### Success Criteria
- All commands updated and tested
- Agent migration complete where appropriate
- Behavioral prompts optimized
- Context usage target maintained (<30%)
- **USER REVIEW CHECKPOINT**: Review command integration before validation phase

#### Artifacts Created
- `.claude/commands/implement.md` (integrated with skills availability notation)
- `.claude/commands/orchestrate.md` (integrated with skills coordination)
- `.claude/commands/test-all.md` (integrated with testing-protocols-guidance skill)
- `.claude/commands/debug.md` (integrated with systematic-debugging skill)
- Agent behavioral prompts (extended with "Skills Available" sections)
- Migration documentation for converted agents

---

### Phase 6: Validation, Optimization, and Documentation
**Status**: Pending
**Objective**: Validate complete integration, optimize activation, document patterns, capture metrics
**Complexity**: 5/10
**Duration**: 1 week

#### Dependencies
- Phase 5 must be complete
- User approval of command integration required

#### Tasks
1. Collect comprehensive metrics
   - Token usage: Before skills baseline vs after skills
   - Context utilization: Verify <30% maintained (target <23%)
   - Workflow execution time: Sequential vs parallel with skills
   - Skills activation frequency and accuracy
   - Context window consumption across full workflows

2. Optimize skill activation
   - Tune skill descriptions for better relevance matching
   - Add anti-patterns where skills should NOT activate
   - Test edge cases and adjust descriptions
   - Validate activation accuracy (precision/recall)

3. Update .claude/docs/ with skills architecture
   - Extend `.claude/docs/concepts/patterns/README.md` with skills integration section (not standalone skills-architecture.md)
   - Document hybrid architecture (skills + subagents) integration with existing patterns
   - Include integration patterns and examples
   - Reference existing skills-vs-subagents decision guide (`.claude/docs/guides/skills-vs-subagents-decision.md`)
   - Reference all 4 research reports
   - Cross-reference existing architectural patterns (behavioral-injection, metadata-extraction, verification-fallback, etc.)

4. Create skills migration guide
   - Document when to create new skills
   - Provide migration checklist (agent → skill)
   - Include template usage instructions
   - Add troubleshooting section

5. Update command and agent reference documentation
   - Add skills references to `.claude/docs/reference/command-reference.md`
   - Update `.claude/docs/reference/agent-reference.md` with migrated agents
   - Document skills integration in `.claude/docs/guides/command-development-guide.md`
   - Update `.claude/docs/guides/agent-development-guide.md` with skills decision tree

6. Run complete validation suite
   - Pre-commit validation on all skills
   - Timeless writing validation on documentation
   - Skills registry validation
   - Command integration tests
   - End-to-end workflow tests

7. Capture final performance comparison
   - Token reduction: Total savings per workflow type
   - Context usage: Final percentage vs target
   - Workflow efficiency: Time savings for parallelizable tasks
   - Standards compliance: Automatic enforcement vs manual

#### Testing
- Run complete test suite across all workflows
- Validate metrics accuracy and reproducibility
- Test documentation navigation and completeness
- Verify all cross-references valid
- Test skills activation across diverse scenarios

#### Success Criteria
- Metrics validated and documented
- Skill activation optimized
- Complete documentation architecture in place
- Migration guide operational
- Validation suite passes completely
- Performance targets achieved:
  - Token reduction: ≥33,000 per workflow (42% additional reduction)
  - Context usage: ≤23% (vs baseline <30%)
  - Workflow efficiency: 40-70% improvement for parallelizable tasks
  - Standards compliance: Automatic enforcement without degradation
- **FINAL USER REVIEW CHECKPOINT**: Review complete integration and approve for production

#### Artifacts Created
- `.claude/docs/concepts/patterns/README.md` (extended with skills integration section)
- `.claude/docs/guides/skills-migration-guide.md`
- `.claude/docs/reference/command-reference.md` (extended with skills references)
- `.claude/docs/reference/agent-reference.md` (extended with migrated agents)
- Performance metrics report (`.claude/data/metrics/skills-integration-final.json`)
- Validation test results

---

## Implementation Notes

### Preservation Strategy
- **PRESERVE**: Orchestration layer (commands, behavioral injection, hierarchical agents)
- **PRESERVE**: Progressive plan structures (L0 → L1 → L2 expansion)
- **PRESERVE**: Adaptive planning (complexity-based replanning)
- **PRESERVE**: Checkpoint recovery (resumable workflows)
- **ADOPT**: Skills for standards enforcement, methodologies, quality gates
- **ADOPT**: obra/superpowers collaboration patterns
- **REPLACE**: Custom doc-converter with Anthropic document skills

### Rollback Mechanisms
- Each phase has user review checkpoint
- Git tags at each phase completion for rollback points
- Performance baselines captured for comparison
- Validation suite ensures no regressions
- Incremental migration allows partial rollback

### Context Management Strategy
- Skills dormant: 30-50 tokens per skill
- Skills activated: 500-2000 tokens typical
- Metadata-only returns after execution: 95-99% reduction
- Context pruning after skill completion
- Target maintained: <30% context usage (stretch goal: <23%)

### Risk Mitigation
- Start with low-risk ecosystem skills (obra/superpowers, Anthropic)
- Test in isolated workflows before full integration
- Measure performance at each phase
- User review checkpoints prevent runaway changes
- Preserve orchestration layer (no migration of critical paths)
