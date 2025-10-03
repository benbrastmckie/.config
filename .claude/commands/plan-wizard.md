# /plan-wizard - Interactive Plan Creation Wizard

**Description**: Interactive wizard that guides users through creating implementation plans with optional research integration

**Category**: Planning (project)

**Allowed Tools**: Read, Write, Grep, Glob, WebSearch, Task, TodoWrite

## Overview

The `/plan-wizard` command provides an interactive, guided experience for creating implementation plans. It walks users through a series of prompts to understand their feature requirements, suggests research topics, and generates a comprehensive implementation plan.

**Benefits**:
- Lower barrier to planning for new users
- Guided workflow with intelligent suggestions
- Automatic research topic identification
- Integration with existing plan generation system

**When to Use**:
- You're new to the planning system
- You want guidance on breaking down a feature
- You're unsure what research topics are needed
- You prefer interactive input over writing full descriptions

## Command Logic

### Step 1: Welcome and Feature Description

Display welcome message and prompt for feature description:

```
🧙 Plan Wizard - Interactive Plan Creation

This wizard will guide you through creating a comprehensive implementation plan.

Step 1: What would you like to implement?
Describe your feature or task in 1-2 sentences:
```

**User Input**: Feature description (1-2 sentences)

**Processing**:
- Store feature description as `$FEATURE_DESC`
- Extract keywords for scope analysis
- Prepare for component identification

### Step 2: Component Identification

Analyze the feature description and suggest affected components:

**Logic**:
1. Extract technology/domain keywords from feature description
2. Search project for common component patterns
3. Suggest likely affected components
4. Allow user to customize selection

```bash
# Identify common components in the project
COMMON_COMPONENTS=$(find . -type d -name "lua" -o -name "plugin" -o -name "config" -o -name "utils" -o -name "core" 2>/dev/null | head -10)

# Parse feature for component hints
SUGGESTED_COMPONENTS=""
if echo "$FEATURE_DESC" | grep -qi "auth"; then
  SUGGESTED_COMPONENTS="$SUGGESTED_COMPONENTS auth, security, user"
fi
if echo "$FEATURE_DESC" | grep -qi "ui\|interface\|display"; then
  SUGGESTED_COMPONENTS="$SUGGESTED_COMPONENTS ui, interface, display"
fi
if echo "$FEATURE_DESC" | grep -qi "test\|spec"; then
  SUGGESTED_COMPONENTS="$SUGGESTED_COMPONENTS tests, specs"
fi
if echo "$FEATURE_DESC" | grep -qi "doc\|readme"; then
  SUGGESTED_COMPONENTS="$SUGGESTED_COMPONENTS documentation"
fi
# Add project-specific component detection based on common directories
```

**Prompt**:
```
Step 2: Which components will this affect?

Suggested components (based on your description):
- [component 1]
- [component 2]
- [component 3]

Enter components (comma-separated), or press Enter to use suggestions:
```

**User Input**: Component list (optional, defaults to suggestions)

**Processing**:
- Parse comma-separated components
- Store as `$COMPONENTS` array
- Use for scope estimation

### Step 3: Complexity Assessment

Prompt user to assess complexity level:

```
Step 3: What's the main complexity level?

1. Simple    - Minor changes, single file, < 2 hours
2. Medium    - Multiple files, new functionality, 2-8 hours
3. Complex   - Architecture changes, multiple modules, 8-16 hours
4. Critical  - Major refactor, system-wide impact, > 16 hours

Select complexity (1-4):
```

**User Input**: Complexity level (1-4)

**Processing**:
- Map selection to complexity string
- Store as `$COMPLEXITY`
- Use for phase estimation and research decision

**Mapping**:
- 1 → "simple" (est. 1-2 phases, likely no research)
- 2 → "medium" (est. 2-4 phases, optional research)
- 3 → "complex" (est. 4-6 phases, research recommended)
- 4 → "critical" (est. 6+ phases, research required)

### Step 4: Research Decision

Based on complexity, suggest whether research is needed:

**Logic**:
```bash
if [ "$COMPLEXITY" = "simple" ]; then
  RESEARCH_SUGGESTION="not recommended"
  DEFAULT_RESEARCH="n"
elif [ "$COMPLEXITY" = "medium" ]; then
  RESEARCH_SUGGESTION="optional"
  DEFAULT_RESEARCH="n"
else
  RESEARCH_SUGGESTION="recommended"
  DEFAULT_RESEARCH="y"
fi
```

**Prompt**:
```
Step 4: Should I research first? ($RESEARCH_SUGGESTION)

Research will help identify:
- Existing patterns in the codebase
- Best practices and standards
- Alternative approaches
- Potential challenges

Conduct research before planning? (y/n) [$DEFAULT_RESEARCH]:
```

**User Input**: y/n (defaults based on complexity)

**Processing**:
- Store decision as `$DO_RESEARCH`
- If yes, proceed to Step 5
- If no, skip to Step 6

### Step 5: Research Topic Identification (Conditional)

If research requested, identify and confirm research topics:

**Logic**:
```bash
# Identify research topics based on feature description and components
RESEARCH_TOPICS=()

# Pattern detection for common research needs
if echo "$FEATURE_DESC" | grep -qi "auth\|security\|login"; then
  RESEARCH_TOPICS+=("Security best practices for authentication (2025)")
  RESEARCH_TOPICS+=("Existing authentication patterns in codebase")
fi

if echo "$FEATURE_DESC" | grep -qi "performance\|optimize\|speed"; then
  RESEARCH_TOPICS+=("Performance optimization techniques")
  RESEARCH_TOPICS+=("Benchmarking and profiling approaches")
fi

if echo "$FEATURE_DESC" | grep -qi "ui\|interface"; then
  RESEARCH_TOPICS+=("UI/UX best practices")
  RESEARCH_TOPICS+=("Existing interface patterns")
fi

# Generic topics for all features
RESEARCH_TOPICS+=("Existing implementations of similar features")
RESEARCH_TOPICS+=("Project coding standards and conventions")

# Limit to top 3-4 most relevant topics
RESEARCH_TOPICS=("${RESEARCH_TOPICS[@]:0:4}")
```

**Prompt**:
```
Step 5: Research Topics

Based on your feature, I suggest researching:
1. [topic 1]
2. [topic 2]
3. [topic 3]

Options:
- Press Enter to proceed with these topics
- Edit topics (comma-separated list)
- Type 'skip' to skip research

Your choice:
```

**User Input**:
- Enter (use suggestions)
- Custom topic list
- "skip" (cancel research)

**Processing**:
- If Enter: use suggested topics
- If custom: parse and use custom topics
- If skip: set `$DO_RESEARCH="n"`
- Store final topics as `$RESEARCH_TOPICS` array

### Step 6: Execute Research (Conditional)

If research confirmed, launch parallel research agents:

```markdown
Launching research agents...

[Agent 1/N] Researching: [topic 1]
[Agent 2/N] Researching: [topic 2]
[Agent 3/N] Researching: [topic 3]

This may take 30-60 seconds...
```

**Implementation**:
```bash
# Create research artifacts directory if needed
mkdir -p .claude/specs/artifacts

# Build research agent prompts
for i in "${!RESEARCH_TOPICS[@]}"; do
  TOPIC="${RESEARCH_TOPICS[$i]}"
  AGENT_PROMPT="Research Task: $TOPIC

Context: User wants to implement: $FEATURE_DESC
Components affected: ${COMPONENTS[@]}

Investigate $TOPIC to inform the planning phase.

Requirements:
- Search codebase for existing patterns
- Research best practices (use WebSearch for current standards)
- Identify potential challenges
- Summarize findings in max 150 words

Output format:
**Findings Summary**
- Key findings (3-5 bullet points)
- Recommended approach
- Potential challenges

Save findings to artifact for plan generation."

  # Invoke research-specialist agent
  # (In actual execution, use Task tool with subagent_type: research-specialist)
done

# Wait for all agents to complete
# Collect artifact references for plan generation
```

**Output**: Store artifact references as `$RESEARCH_ARTIFACTS` array

### Step 7: Generate Implementation Plan

Invoke plan-architect agent with all collected context:

```markdown
Generating implementation plan...

Feature: $FEATURE_DESC
Components: ${COMPONENTS[@]}
Complexity: $COMPLEXITY
Research: [$RESEARCH_ARTIFACTS or "None"]
```

**Implementation**:
```bash
# Build comprehensive prompt for plan-architect
PLAN_PROMPT="# Plan Generation Task

## User Context (from Plan Wizard)

**Feature Description**: $FEATURE_DESC

**Affected Components**: ${COMPONENTS[@]}

**Complexity Level**: $COMPLEXITY

**Research Findings**:
$(if [ "$DO_RESEARCH" = "y" ]; then
  echo "[Research artifacts: ${RESEARCH_ARTIFACTS[@]}]"
  echo "Incorporate findings from research into the plan."
else
  echo "No research conducted - use existing knowledge and codebase analysis."
fi)

## Objective

Create a comprehensive implementation plan following project standards that:
- Addresses the user's feature description
- Covers all affected components
- Matches the specified complexity level
- Incorporates research findings (if available)
- Follows /home/benjamin/.config/CLAUDE.md standards

## Requirements

Use the /plan command to generate the plan:

\`\`\`bash
/plan \"$FEATURE_DESC\" $(if [ "$DO_RESEARCH" = "y" ]; then echo "${RESEARCH_ARTIFACTS[@]}"; fi)
\`\`\`

Ensure the plan includes:
- Appropriate number of phases for $COMPLEXITY complexity
- Tasks covering all components: ${COMPONENTS[@]}
- Testing strategy
- Documentation requirements

## Expected Output

- Plan file path: specs/plans/NNN_*.md
- Brief summary of phases and approach
"

# Invoke plan-architect agent with this prompt
# (Use Task tool with subagent_type: plan-architect)
```

**Agent Invocation**:
```markdown
Use Task tool:
- subagent_type: plan-architect
- description: "Create implementation plan from wizard input"
- prompt: $PLAN_PROMPT
```

### Step 8: Display Results

Extract plan path from agent output and display to user:

```
✅ Plan Created Successfully!

Plan: specs/plans/[NNN]_[feature_name].md
Phases: N
Complexity: $COMPLEXITY
Research: [Y/N, N artifacts if yes]

Next steps:
- Review the plan: cat specs/plans/[NNN]_[feature_name].md
- Implement the plan: /implement specs/plans/[NNN]_[feature_name].md
- Modify if needed: /update-plan specs/plans/[NNN]_[feature_name].md "changes..."

The wizard has completed. Happy implementing! 🚀
```

**Output Data**:
- Plan file path
- Number of phases
- Research artifact references (if any)
- Suggested next commands

## Error Handling

### Invalid Input

**Scenario**: User provides empty or invalid input

**Action**:
- Re-prompt with validation message
- Show example of valid input
- Allow up to 3 retries before using defaults

### Research Failures

**Scenario**: Research agents fail or timeout

**Action**:
- Report which research topics failed
- Offer to continue without those findings
- Ask user: "Continue with partial research? (y/n)"
- If yes: proceed with available research
- If no: skip all research and plan directly

### Plan Generation Failures

**Scenario**: plan-architect agent fails

**Action**:
- Report error details
- Suggest manual planning: `/plan "$FEATURE_DESC"`
- Preserve wizard context for debugging
- Log failure for analysis

### Interruption

**Scenario**: User cancels wizard (Ctrl+C)

**Action**:
- Graceful exit message
- Preserve any research artifacts created
- Suggest resuming: "Research saved. Run /plan with findings: /plan \"...\" [artifacts]"

## Examples

### Example 1: Simple Feature (No Research)

```
User: /plan-wizard

Wizard: What would you like to implement?
User: Add a dark mode toggle to the settings

Wizard: Which components will this affect?
Suggested: ui, settings, config
User: [Enter]

Wizard: What's the main complexity level?
User: 1

Wizard: Should I research first? (not recommended)
User: n

Wizard: Generating implementation plan...

✅ Plan Created!
Plan: specs/plans/045_dark_mode_toggle.md
Phases: 2
Complexity: simple
Research: No

Next: /implement specs/plans/045_dark_mode_toggle.md
```

### Example 2: Complex Feature (With Research)

```
User: /plan-wizard

Wizard: What would you like to implement?
User: Implement OAuth2 authentication with Google and GitHub providers

Wizard: Which components will this affect?
Suggested: auth, security, user, api
User: auth, security, user, api, config [Enter]

Wizard: What's the main complexity level?
User: 3

Wizard: Should I research first? (recommended)
User: y

Wizard: Research Topics:
1. Security best practices for OAuth2 (2025)
2. Existing authentication patterns in codebase
3. OAuth2 provider integration approaches
4. Project coding standards and conventions

Options: [Enter]/edit/skip
User: [Enter]

Wizard: Launching research agents...
[Agent 1/4] Researching: Security best practices for OAuth2 (2025)
[Agent 2/4] Researching: Existing authentication patterns in codebase
[Agent 3/4] Researching: OAuth2 provider integration approaches
[Agent 4/4] Researching: Project coding standards and conventions

Research complete. Generating implementation plan...

✅ Plan Created!
Plan: specs/plans/046_oauth2_authentication.md
Phases: 5
Complexity: complex
Research: Yes (4 artifacts)

Next: /implement specs/plans/046_oauth2_authentication.md
```

### Example 3: User Customization

```
User: /plan-wizard

Wizard: What would you like to implement?
User: Refactor the plugin loading system for better performance

Wizard: Which components will this affect?
Suggested: plugin, core, performance
User: plugin, core, lazy-loading, startup [Enter]

Wizard: What's the main complexity level?
User: 3

Wizard: Should I research first? (recommended)
User: y

Wizard: Research Topics:
1. Performance optimization techniques
2. Existing implementations of similar features
3. Project coding standards and conventions

Options: [Enter]/edit/skip
User: Plugin lazy-loading patterns, Neovim startup optimization, Performance profiling approaches [Enter]

Wizard: Launching research agents...
[Agent 1/3] Researching: Plugin lazy-loading patterns
[Agent 2/3] Researching: Neovim startup optimization
[Agent 3/3] Researching: Performance profiling approaches

Research complete. Generating implementation plan...

✅ Plan Created!
Plan: specs/plans/047_plugin_loading_refactor.md
Phases: 6
Complexity: complex
Research: Yes (3 artifacts)
```

## Integration with Existing Commands

### With /plan Command

The wizard internally uses `/plan` for final plan generation:

```bash
/plan "$FEATURE_DESC" $(echo "${RESEARCH_ARTIFACTS[@]}")
```

All `/plan` features work:
- Automatic numbering
- Plan template following
- Cross-referencing research
- Standards compliance

### With /report Command

Research topics identified by wizard can launch `/report`:

```bash
# Wizard internally invokes research-specialist agents
# These create research artifacts similar to /report outputs
# But stored in .claude/specs/artifacts/ not specs/reports/
```

### With /implement Command

Plans created by wizard are directly compatible:

```bash
/implement specs/plans/[NNN]_[feature_name].md
```

No difference from manually created plans.

### With /orchestrate Command

For complex features, wizard can suggest orchestrate:

```
Note: This is a complex feature. Consider using /orchestrate for automated
research + planning + implementation:

/orchestrate "$FEATURE_DESC"
```

## Success Criteria

- [ ] Wizard completes successfully for simple features (no research)
- [ ] Wizard completes successfully for complex features (with research)
- [ ] User can customize components and research topics
- [ ] Research agents launch in parallel when requested
- [ ] Plan generation integrates research findings
- [ ] Generated plans are equivalent quality to manual `/plan`
- [ ] Error handling covers all failure scenarios
- [ ] Interruption preserves partial work
- [ ] Documentation clear for new users

## Testing

### Test Case 1: Simple Feature Flow

```bash
# Simulate wizard with simple feature
# Expected: No research, 2-phase plan, quick completion
Feature: "Add line numbers to editor"
Components: [default suggestions]
Complexity: 1 (simple)
Research: n
Expected Output: Plan with 1-2 phases, no research artifacts
```

### Test Case 2: Complex Feature with Research

```bash
# Simulate wizard with complex feature
# Expected: Research conducted, multi-phase plan
Feature: "Implement real-time collaboration with WebRTC"
Components: collaboration, network, ui, state
Complexity: 3 (complex)
Research: y
Topics: [default suggestions]
Expected Output: Plan with 5-7 phases, 3-4 research artifacts
```

### Test Case 3: User Customization

```bash
# Simulate wizard with custom inputs
# Expected: Custom topics researched, custom components in plan
Feature: "Add plugin marketplace"
Components: [user enters: plugin, marketplace, api, ui, download]
Complexity: 4 (critical)
Research: y
Topics: [user enters: "Plugin marketplace architectures, Security for user-submitted code, Plugin versioning systems"]
Expected Output: Plan addressing custom components, custom research topics
```

### Test Case 4: Research Failure Recovery

```bash
# Simulate research agent failure
# Expected: Graceful degradation, partial research used
Feature: "Implement telemetry"
Complexity: 2 (medium)
Research: y
[Simulate: 1 of 3 research agents fails]
Expected Output: Prompt "Continue with partial research?", if yes → plan with 2/3 research artifacts
```

### Test Case 5: Interruption Handling

```bash
# Simulate user interruption (Ctrl+C)
# Expected: Graceful exit, research preserved
Feature: "Add code linting"
Complexity: 2
Research: y
[Simulate: Ctrl+C during research]
Expected Output: "Research saved. Resume with: /plan \"...\" [artifacts]"
```

## Notes

### Design Decisions

**Why 4 Prompts?**
- Balances guidance with efficiency
- Captures essential planning parameters
- Avoids overwhelming new users
- Allows customization at key points

**Why Suggest Components?**
- Helps users think through scope
- Leverages codebase structure
- Allows expert users to customize
- Prevents scope creep

**Why Complexity Assessment?**
- Determines research necessity
- Estimates phase count
- Sets user expectations
- Guides agent selection (if delegation used)

**Why Optional Research?**
- Respects user's time for simple tasks
- Recommends research for complex tasks
- Allows expert override
- Integrates seamlessly with plan generation

### Future Enhancements

- **Template Integration**: "Start from template? (crud/api/refactor)"
- **Previous Plan Learning**: "Similar to previous plan 023?"
- **Automatic Component Detection**: Parse codebase structure
- **Visual Plan Preview**: Show phase outline before confirming
- **Voice Input**: Accept voice descriptions (if supported)
- **Collaborative Wizard**: Multiple users contribute to planning

### Limitations

- **No Plan Modification**: Wizard creates new plans only (use /update-plan for changes)
- **Linear Flow**: Cannot jump between steps (must complete in order)
- **No Template Selection**: Uses default plan template (future: template wizard)
- **Text Input Only**: No GUI or visual planning tools

## Implementation Notes

This command should be implemented as a markdown file following the command pattern established in `.claude/commands/`. It uses:

- **Allowed Tools**: Read, Write, Grep, Glob, WebSearch, Task, TodoWrite
- **Agent Invocations**: research-specialist (parallel), plan-architect (single)
- **Artifacts**: Stores research in .claude/specs/artifacts/ (not specs/reports/)
- **Output**: Standard plan in specs/plans/NNN_*.md

The wizard is stateless - each run is independent. If interrupted, user must restart, but any completed research artifacts are preserved and can be manually referenced.
