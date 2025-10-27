# Skills Integration Systematic Refactor Plan

## Plan Metadata
- **Plan ID**: 001_skills_integration_plan
- **Topic**: 075_skills_integration_systematic_refactor
- **Created**: 2025-10-23
- **Status**: Active
- **Complexity**: TBD
- **Estimated Duration**: TBD

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
**Overall Complexity**: 7.5/10

- Multi-phase refactor with 6 distinct stages
- Integration across multiple system layers (commands, agents, utilities, documentation)
- Balance between preservation (orchestration) and innovation (skills)
- Requires user review checkpoints at each stage

**Estimated Duration**: 8-12 weeks (with user review time)

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
   - Provide skills vs subagents decision matrix
   - Include integration examples with commands
   - Document context management for skills
   - Reference all 4 research reports

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
- Updated `.git/hooks/pre-commit`

---

### Phase 1: Skills Registry Infrastructure
**Status**: Pending
**Objective**: Build skill discovery, registration, and invocation infrastructure
**Complexity**: 6/10
**Duration**: 2 weeks

#### Dependencies
- Phase 0 must be complete
- User approval of documentation standards required

#### Tasks
1. Create skills registry system in `.claude/lib/skills-registry.sh`
   - Implement `list_skills()` - List all available skills
   - Implement `validate_skill(skill_name)` - Verify skill exists and is valid
   - Implement `get_skill_info(skill_name)` - Extract metadata from frontmatter
   - Implement `get_skill_capabilities(skill_name)` - Parse capabilities section
   - Implement `find_skills_by_capability(pattern)` - Capability-based search
   - Implement `load_skill_behavioral_prompt(skill_name)` - Similar to agent loading
   - Add caching for performance (project skills override global skills)

2. Create `.claude/skills/` directory structure
   - Main directories: `converters/`, `analyzers/`, `enforcers/`, `integrations/`
   - Each skill in subdirectory: `skill-name/SKILL.md`
   - Support for optional files: `reference.md`, `scripts/`, `templates/`

3. Create metadata extraction utilities for skills
   - Implement `extract_skill_metadata()` in `.claude/lib/metadata-extraction.sh`
   - Extract title, description, capabilities, allowed-tools
   - Support 95-99% context reduction pattern
   - Return metadata-only format compatible with existing patterns

4. Integrate skills with context management
   - Add skills pruning to `.claude/lib/context-pruning.sh`
   - Implement `prune_skill_output()` - Clear full outputs after metadata extraction
   - Add skills to layered context architecture documentation
   - Ensure <30% context usage target maintained

5. Create skill invocation wrapper utilities
   - Add `invoke_skill()` function in `.claude/lib/skills-invocation.sh`
   - Support behavioral injection pattern (read from SKILL.md)
   - Pre-calculate artifact paths before invocation
   - Verify skill outputs with mandatory verification checkpoints
   - Implement fallback recovery mechanisms

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
- `.claude/lib/skills-registry.sh`
- `.claude/lib/skills-invocation.sh`
- Updated `.claude/lib/metadata-extraction.sh`
- Updated `.claude/lib/context-pruning.sh`
- `.claude/skills/README.md` (updated with structure)

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
- Updated `CLAUDE.md` (skills section)
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
- Updated `.claude/commands/convert-docs.md`
- Updated `CLAUDE.md` (document skills)
- Document conversion test results

---

### Phase 4: Custom Meta-Level Enforcement Skills
**Status**: Pending
**Objective**: Create project-specific skills that read and enforce standards from CLAUDE.md
**Complexity**: 8/10
**Duration**: 2-3 weeks

#### Dependencies
- Phase 3 must be complete
- User approval of document skills integration required

#### Tasks
1. Create code-standards-enforcement skill
   - Location: `.claude/skills/enforcers/code-standards-enforcement/SKILL.md`
   - Read CLAUDE.md ## Code Standards section
   - Detect file type from extension
   - Extract language-specific standards
   - Apply enforcement during code editing
   - Use allowed-tools: Read, Edit (restrict Write for safety)

2. Create documentation-standards-enforcement skill
   - Location: `.claude/skills/enforcers/documentation-standards-enforcement/SKILL.md`
   - Read CLAUDE.md ## Documentation Policy section
   - Enforce README requirements
   - Apply timeless writing principles
   - Validate CommonMark compliance
   - Check for temporal markers
   - Use allowed-tools: Read, Edit

3. Create testing-protocols-enforcement skill
   - Location: `.claude/skills/enforcers/testing-protocols-enforcement/SKILL.md`
   - Read CLAUDE.md ## Testing Protocols section
   - Enforce coverage thresholds (≥80% modified, ≥60% baseline)
   - Validate test discovery patterns
   - Ensure regression tests for bug fixes
   - Use allowed-tools: Read, Bash (for test execution)

4. Update CLAUDE.md sections with links
   - Add file path references in ## Code Standards
   - Add file path references in ## Documentation Policy
   - Add file path references in ## Testing Protocols
   - Document where standards are defined (links to detailed files)

5. Test automatic activation
   - Edit .lua file → code-standards-enforcement activates
   - Create README.md → documentation-standards-enforcement activates
   - Run /test-all → testing-protocols-enforcement activates
   - Verify standards read from CLAUDE.md correctly

6. Measure token reduction
   - Baseline: Commands load standards sections directly (~6000 tokens)
   - With skills: Skills dormant (90 tokens), activate on demand (6000 tokens first time, cached)
   - Expected savings: 96% reduction baseline, standards cached across phases

#### Testing
- Test each enforcement skill independently
- Validate standards discovery across project types
- Verify enforcement applied correctly
- Test skill portability (same skill, different project with different standards)
- Measure token usage before/after

#### Success Criteria
- All 3 enforcement skills created and tested
- CLAUDE.md updated with file path references
- Automatic activation verified
- Token reduction validated (≥90% expected)
- Skills portable across projects
- **USER REVIEW CHECKPOINT**: Review enforcement behavior before command integration

#### Artifacts Created
- `.claude/skills/enforcers/code-standards-enforcement/SKILL.md`
- `.claude/skills/enforcers/documentation-standards-enforcement/SKILL.md`
- `.claude/skills/enforcers/testing-protocols-enforcement/SKILL.md`
- Updated `CLAUDE.md` (file path references)

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
   - **Preserve**: Keep orchestration agents (spec-updater, plan-architect, implementation-executor)

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
- Updated command files (implement.md, orchestrate.md, test-all.md, debug.md)
- Updated agent behavioral prompts
- Migration documentation for converted agents

---

### Phase 6: Validation, Optimization, and Documentation
**Status**: Pending
**Objective**: Validate complete integration, optimize activation, document patterns, capture metrics
**Complexity**: 6/10
**Duration**: 2 weeks

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
   - Create `.claude/docs/concepts/skills-architecture.md`
   - Document hybrid architecture (skills + subagents)
   - Include integration patterns and examples
   - Add decision matrix (when to use skills vs subagents)
   - Reference all 4 research reports

4. Create skills migration guide
   - Document when to create new skills
   - Provide migration checklist (agent → skill)
   - Include template usage instructions
   - Add troubleshooting section

5. Update command and agent reference documentation
   - Add skills references to command-reference.md
   - Update agent-reference.md with migrated agents
   - Document skills integration in command-development-guide.md
   - Update agent-development-guide.md with skills decision tree

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
- `.claude/docs/concepts/skills-architecture.md`
- `.claude/docs/guides/skills-migration-guide.md`
- Updated `.claude/docs/reference/command-reference.md`
- Updated `.claude/docs/reference/agent-reference.md`
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
