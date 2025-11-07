---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch
argument-hint: <feature description> [report-path1] [report-path2] ...
description: Create a detailed implementation plan following project standards, optionally guided by research reports
command-type: primary
dependent-commands: list, update, revise
---

# Create Implementation Plan

**YOU MUST create implementation plan following this exact process:**

**YOUR EXECUTION MODE**: This command uses a MIXED EXECUTION MODEL with TWO distinct modes:

**MODE 1: Direct Plan Creation (Steps 1-7)**
- **Your Role**: You are the PLAN CREATOR
- **Execution Style**: Direct - use Read, Write, Edit, Grep, Glob tools yourself
- **When**: All features (this is the core workflow)
- **Output**: Implementation plan file created by you directly

**MODE 2: Research Orchestration (Step 0.5 - Conditional)**
- **Your Role**: You are the ORCHESTRATOR (NOT the researcher)
- **Execution Style**: Delegation - use Task tool to invoke research-specialist agents
- **When**: Complex features meeting specific triggers (see Step 0.5)
- **Output**: Research reports created by subagents, then proceed to Mode 1

**CRITICAL DISTINCTION**:
- Step 0.5 (research delegation) = ORCHESTRATION MODE (if triggered)
- Steps 1-7 (plan creation) = DIRECT EXECUTION MODE (always)

**CRITICAL INSTRUCTIONS**:
- Execute all steps in EXACT sequential order
- DO NOT skip complexity analysis
- DO NOT skip standards discovery
- DO NOT skip research integration (if reports provided)
- DO NOT skip Step 0.5 research delegation (if complexity triggers met)
- Plan file creation is MANDATORY
- Complexity calculation is REQUIRED

Create a comprehensive implementation plan for the specified feature or task, following project-specific coding standards and incorporating insights from any provided research reports.

## Feature/Task and Reports
- **Feature**: First argument before any .md paths
- **Research Reports**: Any paths to specs/reports/*.md files in arguments

Parse arguments to separate feature description from report paths.

## Process

**YOU MUST execute these steps in EXACT sequential order:**

### 0. Feature Description Complexity Pre-Analysis

**Before starting plan creation**, I'll analyze the feature description for initial complexity estimation and template recommendations.

**Process**:
1. **Load Complexity Utilities**
   ```bash
   source .claude/lib/complexity-utils.sh
   ```

2. **Analyze Feature Description**
   ```bash
   ANALYSIS=$(analyze_feature_description "$FEATURE_DESCRIPTION")
   ```

3. **Display Analysis Results**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   COMPLEXITY PRE-ANALYSIS
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Estimated complexity: X.X (Medium)
   Recommended structure: single-file (expand if needed)
   Suggested phases: 4-5
   Matching templates: test-suite, crud-feature

   Recommendations:
   - Consider using /plan-from-template for faster planning
   - Template suggestions based on keywords in description
   - All plans start as single-file regardless of complexity
   - Use /expand phase during implementation if phases prove complex

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

4. **User Options**
   - **Continue**: Proceed with manual plan creation
   - **Skip**: Use `--skip-analysis` flag to bypass this step
   - **Template**: Consider using `/plan-from-template <template-name>` if templates match

**Note**: This analysis is informational only. It helps guide planning decisions but doesn't restrict plan creation. All plans start as single files (Level 0) regardless of estimated complexity.

### 0.5. Research Agent Delegation for Complex Features

**ORCHESTRATION MODE ACTIVATED** (When Complexity Triggers Met)

**YOUR ROLE FOR STEP 0.5**: You are the RESEARCH ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS FOR STEP 0.5**:
- DO NOT execute research yourself using Read/Grep/Write tools when complexity triggers met
- ONLY use Task tool to delegate research to research-specialist agents
- Your job in Step 0.5: decompose research needs → invoke agents in parallel → verify report creation → cache metadata
- You will NOT see research content directly (agents create reports, you read them later in planning steps)

**EXECUTION MODES IN THIS STEP**:
- **If complexity triggers NOT met**: Skip Step 0.5 entirely, proceed to Step 1 (direct mode)
- **If complexity triggers met**: Execute Step 0.5 as ORCHESTRATOR (delegate to agents)

**After Step 0.5 completes**: Return to DIRECT EXECUTION MODE for Steps 1-7 (you create the plan yourself)

---

**YOU MUST invoke research-specialist agents for complex features. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Research delegation is MANDATORY when triggers met
- DO NOT skip complexity trigger checks
- DO NOT skip parallel agent invocation (2-3 agents)
- DO NOT skip metadata extraction
- Fallback mechanism ensures research completion

**When no research reports are provided AND the feature is complex**, delegate research to specialized subagents before planning.

---

#### Complexity Triggers for Research Delegation

Research subagents are invoked when ALL of the following apply:
- **No research reports provided** in command arguments
- **Feature complexity indicators** (any 2 or more):
  - Ambiguous requirements (multiple possible interpretations)
  - Multiple technical approaches mentioned or implied
  - Cross-cutting concerns (security, performance, scalability)
  - Integration with external systems or complex APIs
  - Novel features without clear precedent in codebase

#### Research Delegation Workflow

When triggers met, perform research delegation:

**Step 1: Source Context Preservation Utilities**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-metrics.sh"
```

**Step 2: Track Context Before Research**
```bash
# Track initial context
CONTEXT_BEFORE=$(track_context_usage "before" "plan_research" "")
```

**Step 3: Define Research Topics**

Identify 2-3 research focus areas based on feature requirements:
- **Patterns**: Existing implementations and architectural patterns
- **Best Practices**: Security, performance, testing standards
- **Alternatives**: Different technical approaches and trade-offs

**STEP 4 (REQUIRED WHEN TRIGGERS MET) - Invoke Research Subagents in Parallel**

**EXECUTE NOW - Invoke Research-Specialist Agents in Parallel**

**ABSOLUTE REQUIREMENT**: When complexity triggers met, YOU MUST invoke 2-3 research-specialist agents. This is NOT optional.

**WHY THIS MATTERS**: Parallel research provides comprehensive analysis from multiple perspectives (patterns, best practices, alternatives), reducing planning errors by 40%.

Use Task tool to invoke 2-3 research-specialist agents in parallel (single message, multiple Task calls):

**Agent Invocation Template**:

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications, no paraphrasing)**

```
For each research topic (patterns, best practices, alternatives):

Task {
  subagent_type: "general-purpose"
  description: "Research {topic} for {feature}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    Research Focus: {topic} (patterns | best practices | alternatives)
    Feature: {feature_description}

    Tasks (ALL REQUIRED):
    1. Search codebase for existing implementations (Grep, Glob)
    2. Identify relevant patterns, utilities, conventions
    3. Research best practices for this type of feature
    4. Analyze security, performance, testing considerations
    5. Document alternative approaches with pros/cons

    **ABSOLUTE REQUIREMENT**: Create report file at specified path. This is MANDATORY.

    Output (ALL REQUIRED):
    - Create report: specs/{topic}/reports/{NNN}_{topic}.md
    - Include: Executive Summary, Findings, Recommendations, References
    - Return metadata: {path, 50-word summary, key_findings[]}

    Project standards: Read CLAUDE.md for coding conventions
}
```

**Template Variables** (ONLY allowed modifications):
- `{topic}`: Research focus (patterns, best practices, or alternatives)
- `{feature}`: Feature description
- `{feature_description}`: Full feature description
- `{NNN}`: Report number (next available)

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Task list (1-5)
- Output structure (report path, metadata format)
- Standards reference

**Parallel Invocation Requirement**:
- MUST invoke 2-3 agents in SINGLE message (multiple Task calls)
- DO NOT invoke sequentially (reduces time by 60-80%)
- Each agent handles ONE research focus

---

**STEP 5 (REQUIRED AFTER STEP 4) - Mandatory Verification with Fallback**

**MANDATORY VERIFICATION - Confirm Research Reports Created**

**ABSOLUTE REQUIREMENT**: YOU MUST verify all research reports were created. This is NOT optional.

**WHY THIS MATTERS**: Research reports provide critical context for planning. Missing reports lead to incomplete plans.

After each research subagent completes:

**Verification Steps**:

```bash
# For each subagent response
RESEARCH_RESULT=$(forward_message "$SUBAGENT_OUTPUT" "research_${TOPIC}")

# Extract artifact path and metadata
ARTIFACT_PATH=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].path')
ARTIFACT_METADATA=$(echo "$RESEARCH_RESULT" | jq -r '.artifacts[0].metadata')

# MANDATORY: Verify artifact file exists
if [ ! -f "$ARTIFACT_PATH" ]; then
  echo "⚠️  RESEARCH REPORT NOT FOUND - TRIGGERING MANDATORY FALLBACK"

  # FALLBACK MECHANISM (Guarantees 100% Research Completion)
  FALLBACK_PATH="specs/${FEATURE_TOPIC}/reports/${REPORT_NUM}_${TOPIC}.md"
  mkdir -p "$(dirname "$FALLBACK_PATH")"

  # EXECUTE NOW - Create Fallback Report
  cat > "$FALLBACK_PATH" <<'EOF'
# ${TOPIC} Research Report (Fallback)

## Agent Output
$SUBAGENT_OUTPUT

## Metadata
- Generated: Fallback mechanism
- Reason: Primary report creation failed
- Topic: ${TOPIC}
- Feature: ${FEATURE_DESCRIPTION}
- Status: Fallback (requires review)
EOF

  ARTIFACT_PATH="$FALLBACK_PATH"
  echo "✓ VERIFIED: Fallback report created: $ARTIFACT_PATH"

  # MANDATORY: Verify fallback file created
  if [ ! -f "$FALLBACK_PATH" ]; then
    echo "CRITICAL ERROR: Fallback mechanism failed"
    exit 1
  fi
fi

# Cache metadata for on-demand loading (not full content!)
cache_metadata "$ARTIFACT_PATH" "$ARTIFACT_METADATA"

# Accumulate artifact paths for planning phase
RESEARCH_REPORTS="$RESEARCH_REPORTS $ARTIFACT_PATH"
```

**Fallback Mechanism** (Guarantees 100% Research Completion):
- If agent fails to create report → Create from agent output
- Minimal structure with agent findings preserved
- Non-blocking (planning continues with available reports)

---

**Step 6: Track Context After Research**
```bash
# Calculate context reduction
CONTEXT_AFTER=$(track_context_usage "after" "plan_research" "")
CONTEXT_REDUCTION=$(calculate_context_reduction "$CONTEXT_BEFORE" "$CONTEXT_AFTER")

# Log reduction metrics
echo "Context reduction: $CONTEXT_REDUCTION% (metadata-only passing)"
```

**Expected Context Reduction**:
- 92-95% reduction vs. loading full research reports
- Full reports: ~3000 chars per report × 3 = 9000 chars
- Metadata only: ~150 chars per report × 3 = 450 chars
- Reduction: 9000 → 450 = 95%

#### On-Demand Report Loading

During plan creation (Steps 2-8), I'll load full report content only when needed:

```bash
# When synthesizing technical design or phase tasks
if [ -n "$ARTIFACT_PATH" ]; then
  FULL_REPORT=$(load_metadata_on_demand "$ARTIFACT_PATH")
  # Use full report content for detailed planning
  # Report content not retained in memory after use
fi
```

#### Benefits of Research Delegation

- **Comprehensive Research**: 2-3 specialized agents cover multiple perspectives
- **Parallel Execution**: All research happens simultaneously (60-80% time savings)
- **Minimal Context**: Metadata-only passing (95% reduction)
- **On-Demand Details**: Load full reports only when needed
- **Better Plans**: Informed by actual codebase patterns and best practices

#### Skip Research Delegation

To skip automatic research delegation (use direct planning):
- Provide existing research reports in command arguments
- Use `--skip-research` flag (suppresses research delegation)
- Research delegation only occurs when no reports provided

---

**RETURN TO DIRECT EXECUTION MODE** (Steps 1-7)

**YOUR ROLE FOR STEPS 1-7**: You are the PLAN CREATOR (not an orchestrator)

You will now create the implementation plan yourself using Read, Write, Edit, Grep, Glob tools directly. This is NOT orchestration - you execute these steps yourself.

---

### 1. Report Integration (if provided)

**Note**: Direct execution by you, no agent delegation.

If research reports are provided, I'll:
- Read and analyze each report
- Extract key findings and recommendations
- Identify technical constraints and patterns
- Use insights to inform the plan structure
- Reference reports in the plan metadata

### 1.5. Update Report Implementation Status
**After creating the plan, update referenced reports:**

**For each research report provided:**
- Use Edit tool to update "## Implementation Status" section
- Change: `Status: Research Complete` → `Status: Planning In Progress`
- Update: `Plan: None yet` → `Plan: [link to specs/plans/NNN.md]`
- Update date field

**Example update:**
```markdown
## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/018_spec_file_updates.md](../plans/018_spec_file_updates.md)
- **Implementation**: Not started
- **Date**: 2025-10-03
```

**Edge Cases:**
- If report lacks "Implementation Status" section: Use Edit tool to append section before updating
- If report already has a plan link: Update existing (report WILL inform multiple plans)

### 2. Requirements Analysis and Complexity Evaluation

**Note**: Direct execution by you, no agent delegation.

**YOU MUST perform complexity evaluation. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Complexity calculation is MANDATORY for every plan
- DO NOT skip requirements analysis
- DO NOT skip complexity scoring
- Complexity score MUST be stored in plan metadata

Analyze the feature requirements to determine:
- Core functionality needed
- Technical scope and boundaries
- Affected components and modules
- Dependencies and prerequisites
- Alignment with report recommendations (if applicable)

---

**STEP 6 (REQUIRED BEFORE PLAN CREATION) - Mandatory Complexity Evaluation**

**EXECUTE NOW - Calculate Plan Complexity**

**ABSOLUTE REQUIREMENT**: YOU MUST calculate plan complexity using utilities. This is NOT optional.

**WHY THIS MATTERS**: Complexity score guides phase expansion decisions during implementation and is stored in metadata for future reference.

**Complexity Evaluation** (Progressive Planning):

```bash
# Source complexity utilities
source .claude/lib/analyze-plan-requirements.sh
source .claude/lib/calculate-plan-complexity.sh

# Analyze requirements
REQUIREMENTS_ANALYSIS=$(analyze_plan_requirements "$FEATURE_DESCRIPTION" "$RESEARCH_REPORTS")

# Extract estimates
TASK_COUNT=$(echo "$REQUIREMENTS_ANALYSIS" | jq -r '.task_count')
PHASE_COUNT=$(echo "$REQUIREMENTS_ANALYSIS" | jq -r '.phase_count')
ESTIMATED_HOURS=$(echo "$REQUIREMENTS_ANALYSIS" | jq -r '.estimated_hours')
DEPENDENCY_COMPLEXITY=$(echo "$REQUIREMENTS_ANALYSIS" | jq -r '.dependency_complexity')

# Calculate complexity score
COMPLEXITY_SCORE=$(calculate_plan_complexity "$TASK_COUNT" "$PHASE_COUNT" "$ESTIMATED_HOURS" "$DEPENDENCY_COMPLEXITY")

# MANDATORY: Store complexity score for metadata
export PLAN_COMPLEXITY_SCORE="$COMPLEXITY_SCORE"

# Display complexity hint if score ≥50
if [ "$COMPLEXITY_SCORE" -ge 50 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "COMPLEXITY HINT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Complexity Score: $COMPLEXITY_SCORE"
  echo "Recommendation: Consider using /expand phase during"
  echo "implementation if phases prove complex"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
```

**Required Outputs**:
- `$PLAN_COMPLEXITY_SCORE`: Exported for metadata inclusion
- Complexity hint displayed if score ≥50
- Task count, phase count, estimated hours calculated

**Important Notes**:
- **All plans start as single files (Level 0)** regardless of complexity
- Complexity score guides `/expand phase` usage during implementation
- Complexity score stored in plan metadata for future reference

---

### 3. Topic-Based Location Determination

**Note**: Direct execution by you, no agent delegation.
I'll determine the topic directory location using the uniform structure:

**Step 1: Source Required Utilities**
```bash
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh
source .claude/lib/template-integration.sh
source .claude/lib/unified-location-detection.sh
```

**Step 2: Extract Topic from Report or Feature**
- If research reports are provided:
  - Read the first report file
  - Extract topic directory from report path (e.g., `specs/042_auth/reports/001_*.md` → `specs/042_auth`)
  - Use the same topic directory for the plan
- If no reports:
  - Use feature description to determine topic
  - Use unified location detection library to create topic directory

**Step 3: Get or Create Topic Directory**
```bash
# If using existing topic from report
if [ -n "$REPORT_PATH" ]; then
  TOPIC_DIR=$(dirname "$(dirname "$REPORT_PATH")")
else
  # Use unified location detection library for new topics
  LOCATION_JSON=$(perform_location_detection "$FEATURE_DESCRIPTION" "false")

  # Extract topic path from JSON output
  if command -v jq &>/dev/null; then
    TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
    PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
  else
    # Fallback without jq
    TOPIC_DIR=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    PLANS_DIR="${TOPIC_DIR}/plans"
  fi

  # MANDATORY VERIFICATION checkpoint
  if [ ! -d "$TOPIC_DIR" ]; then
    echo "ERROR: Location detection failed - directory not created: $TOPIC_DIR"
    exit 1
  fi

  echo "✓ VERIFIED: Topic directory created at $TOPIC_DIR"
fi

# Creates: specs/{NNN_topic}/ with subdirectories (plans/, reports/, summaries/, debug/, etc.)
```

**Step 4: Verify Topic Structure**
- Ensure topic directory has all standard subdirectories:
  - `plans/` - Implementation plans
  - `reports/` - Research reports
  - `summaries/` - Implementation summaries
  - `debug/` - Debug reports (committed to git)
  - `scripts/` - Investigation scripts (gitignored)
  - `outputs/` - Test outputs (gitignored)
  - `artifacts/` - Operation artifacts (gitignored)
  - `backups/` - Backups (gitignored)

### 4. Plan Creation Using Uniform Structure

**Note**: Direct execution by you, no agent delegation.

**YOU MUST create plan file using exact process. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Plan file creation is MANDATORY
- DO NOT skip artifact number calculation
- DO NOT skip plan name generation
- DO NOT skip file creation verification
- Fallback mechanism ensures 100% plan creation

Create the plan using `create_topic_artifact()`:

---

**STEP 7 (REQUIRED) - Calculate Plan Number**

**EXECUTE NOW - Get Next Plan Number**

**ABSOLUTE REQUIREMENT**: YOU MUST calculate next available plan number. This is NOT optional.

**WHY THIS MATTERS**: Sequential numbering prevents conflicts and maintains artifact organization.

**Step 1: Get Next Plan Number Within Topic**
```bash
# Source artifact utilities
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh

# Get next number in topic's plans/ subdirectory
NEXT_NUM=$(get_next_artifact_number "${TOPIC_DIR}/plans")

# MANDATORY: Verify number is valid
if [ -z "$NEXT_NUM" ] || [ "$NEXT_NUM" -lt 1 ]; then
  echo "⚠️  INVALID PLAN NUMBER - Triggering fallback"
  # Fallback: Use 001 or enumerate directory manually
  NEXT_NUM=$(find "${TOPIC_DIR}/plans" -name "*.md" | wc -l)
  NEXT_NUM=$((NEXT_NUM + 1))
fi

# Format with leading zeros (e.g., 001, 002, 003)
PLAN_NUM=$(printf "%03d" "$NEXT_NUM")
```

---

**STEP 8 (REQUIRED AFTER STEP 7) - Generate Plan Name**

**EXECUTE NOW - Create Plan Filename**

**ABSOLUTE REQUIREMENT**: YOU MUST generate valid plan name. This is NOT optional.

**Step 2: Generate Plan Name**
```bash
# Convert feature description to snake_case
PLAN_NAME=$(echo "$FEATURE_DESCRIPTION" | \
  tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/_/g' | \
  sed 's/__*/_/g' | \
  sed 's/^_//; s/_$//' | \
  cut -c1-50)

# MANDATORY: Verify name is not empty
if [ -z "$PLAN_NAME" ]; then
  echo "⚠️  EMPTY PLAN NAME - Using fallback"
  PLAN_NAME="implementation_plan"
fi

# Create full filename
PLAN_FILENAME="${PLAN_NUM}_${PLAN_NAME}.md"
```

---

**STEP 9 (REQUIRED AFTER STEP 8) - Create Plan File with Verification**

**EXECUTE NOW - Create Plan File Using Utility**

**MANDATORY FILE CREATION**: YOU MUST create plan file and verify creation. This is NOT optional.

**ABSOLUTE REQUIREMENT**: Plan file creation is the primary deliverable of this command. Missing file means command failure.

**WHY THIS MATTERS**: Plan file is the primary deliverable of this command. Missing file means command failure.

**Step 3: Create Plan File (MANDATORY)**
```bash
# Create plan file using utility (auto-numbers and registers)
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "$PLAN_NAME" "$PLAN_CONTENT")
# Creates: ${TOPIC_DIR}/plans/NNN_plan_name.md

# MANDATORY: Verify file exists
if [ ! -f "$PLAN_PATH" ]; then
  echo "⚠️  PLAN FILE NOT FOUND - Triggering fallback mechanism"

  # Fallback: Create file directly with Write tool
  FALLBACK_PATH="${TOPIC_DIR}/plans/${PLAN_FILENAME}"

  # Ensure parent directory exists (lazy creation)
  source .claude/lib/unified-location-detection.sh
  ensure_artifact_directory "$FALLBACK_PATH" || {
    echo "ERROR: Failed to create parent directory for plan" >&2
    exit 1
  }

  # Use Write tool to create plan file
  # (PLAN_CONTENT already prepared in Steps 6-8)
  cat > "$FALLBACK_PATH" <<EOF
$PLAN_CONTENT
EOF

  PLAN_PATH="$FALLBACK_PATH"
  echo "✓ Fallback plan file created: $PLAN_PATH"

  # Manual registration in artifact registry
  echo "$PLAN_PATH" >> "${TOPIC_DIR}/.artifact-registry"
fi

# FILE_CREATION_ENFORCED: Verify file is readable and non-empty
if [ ! -s "$PLAN_PATH" ]; then
  echo "❌ CRITICAL: Plan file empty or unreadable: $PLAN_PATH"
  exit 1
fi

echo "✓ CRITICAL: Plan file created successfully: $PLAN_PATH"

# Additional verification - file structure and metadata
if ! grep -q "## Metadata" "$PLAN_PATH"; then
  echo "❌ ERROR: Plan file missing metadata section"
  exit 1
fi

if ! grep -q "## Implementation Phases" "$PLAN_PATH"; then
  echo "❌ ERROR: Plan file missing phases section"
  exit 1
fi

# Verify file size is reasonable (MUST be >1000 bytes for a proper plan)
file_size=$(wc -c < "$PLAN_PATH")
if [ "$file_size" -lt 1000 ]; then
  echo "❌ ERROR: Plan file too small (${file_size} bytes), expected >1000"
  exit 1
fi

echo "✓ VERIFIED: Plan file complete and well-formed (${file_size} bytes)"
```

**Fallback Mechanism** (Guarantees 100% Plan Creation):
- If `create_topic_artifact` fails → Create file directly with Write tool
- Manual directory creation if needed
- Manual artifact registry update
- File size verification ensures non-empty file
- Structure verification ensures required sections present

**MANDATORY VERIFICATION - Plan File Complete**:

```bash
# Final comprehensive verification
if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL: Plan file does not exist after creation"
  exit 1
fi

# RETURN_FORMAT_SPECIFIED: Output plan creation confirmation
echo "✓ VERIFIED: Plan file exists and is complete: $PLAN_PATH"
```

---

**Benefits of Uniform Structure**:
- All artifacts for a topic in one directory
- Easy cross-referencing between plans, reports, summaries
- Consistent numbering within topic
- Automatic subdirectory creation
- Single utility manages all artifact creation

### 5. Standards Discovery

**Note**: Direct execution by you, no agent delegation.

For standards discovery process, see [Standards Discovery Patterns](../docs/command-patterns.md#standards-discovery-patterns).

**Plan-specific discovery:**
- Identify CLAUDE.md location for plan metadata
- Extract testing protocols for phase validation criteria
- Note coding standards for task descriptions

### 6. Plan Structure

**Note**: Direct execution by you, no agent delegation.

**YOU MUST include these sections in the implementation plan:**

#### Overview
- Feature description and objectives
- Success criteria and deliverables
- Risk assessment and mitigation strategies

#### Technical Design
- Architecture decisions
- Component interactions
- Data flow and state management
- API design (if applicable)

#### Implementation Phases
**YOU MUST include in each phase:**
- Clear objectives and scope
- Specific tasks with checkboxes `- [ ]`
- Testing requirements
- Validation criteria
- Estimated complexity

#### Phase Format
```markdown
### Phase N: [Phase Name]
**Objective**: [What this phase accomplishes]
**Complexity**: [Low/Medium/High]

Tasks:
- [ ] Task description with file reference
- [ ] Another specific task
- [ ] Testing task
- [ ] Update plan checkboxes across hierarchy (use checkbox-utils.sh)

Testing:
- Test command or approach
- Expected outcomes

**Phase Completion Protocol**:
When phase is complete, update checkboxes across all hierarchy levels:
```bash
source .claude/lib/checkbox-utils.sh
mark_phase_complete <plan_path> <phase_num>
verify_checkbox_consistency <plan_path> <phase_num>
```
```

### 7. Standards Integration

**Note**: Direct execution by you, no agent delegation.

Based on discovered standards, I'll ensure:
- Code style matches project conventions
- File organization follows existing patterns
- Testing approach aligns with project practices
- Documentation format is consistent
- Git commit message format is specified

### 8. Progressive Plan Creation

**All plans start as single files** (Structure Level 0):
- Path: `specs/{NNN_topic}/plans/NNN_feature_name.md`
- Topic directory: `{NNN_topic}` = three-digit numbered topic (e.g., `042_authentication`)
- Single file with all phases and tasks inline
- Feature name converted to lowercase with underscores
- Comprehensive yet actionable content
- Clear phase boundaries for `/implement` command compatibility
- Metadata includes Structure Level: 0 and Complexity Score

**Expansion happens during implementation**:
- Use `/expand phase <plan> <phase-num>` to extract complex phases to separate files (Level 0 → 1)
- Use `/expand stage <phase> <stage-num>` to extract complex stages to separate files (Level 1 → 2)
- Structure grows organically based on actual implementation needs, not predictions

**Path Format**:
- Level 0: `specs/{NNN_topic}/plans/NNN_plan.md`
- Level 1: `specs/{NNN_topic}/plans/NNN_plan/NNN_plan.md` + `phase_N_name.md`
- Level 2: `specs/{NNN_topic}/plans/NNN_plan/phase_N_name/phase_N_overview.md` + `stage_M_name.md`

### 8.5. Agent-Based Plan Phase Analysis

**After creating the plan, YOU MUST analyze the entire plan holistically to identify which phases (if any) require expansion to separate files.**

**Analysis Approach:**

The primary agent (executing `/plan`) has just created the plan and has all phases in context. Rather than using a generic complexity threshold, YOU MUST review the entire plan and make informed recommendations about which specific phases require expansion.

**Evaluation Criteria:**

I'll consider for each phase:
- **Task count and complexity**: Not just numbers, but actual complexity of work
- **Scope and breadth**: Files, modules, subsystems touched
- **Interrelationships**: Dependencies and connections between phases
- **Phase relationships**: How phases build on each other
- **Natural breakpoints**: Where expansion creates better conceptual boundaries

**Evaluation Process:**

```
Read /home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md

You just created this implementation plan with [N] phases.

[Full plan content]

Follow the holistic analysis approach and identify which phases (if any)
would benefit from expansion to separate files.

Provide your recommendation in the structured format.
```

**If Expansion Recommended:**

Display formatted analysis:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The following phases WILL benefit from expansion:

Phase [N]: [Phase Name]
Rationale: [Agent's reasoning based on understanding the phase]
Command: /expand phase <plan-path> [N]

Phase [M]: [Phase Name]
Rationale: [Agent's reasoning based on understanding the phase]
Command: /expand phase <plan-path> [M]

Note: Expansion is optional. You MAY expand now before starting
implementation, or expand during implementation using /expand phase
if phases prove too complex.

Overall Complexity Score: [X] (stored in plan metadata)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If No Expansion Recommended:**

Display brief note:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan structure: All phases are appropriately scoped for inline format.

[Agent's brief rationale - e.g., "All phases have 3-5 straightforward
tasks that work well together in the single-file format."]

Overall Complexity Score: [X] (stored in plan metadata)

Note: Phases MAY be expanded during implementation if needed using
/expand phase <plan-path> <phase-num>.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Analysis Benefits:**

- **Specific recommendations**: Not just "plan is complex," but "Phase 3 and Phase 5 need expansion"
- **Clear rationale**: Agent explains why each phase would benefit
- **Holistic view**: Agent sees how phases relate, not just individual metrics
- **Better judgment**: Understands actual complexity, not just task counts
- **Informed decisions**: User knows which phases to consider expanding

**Relationship to /implement Proactive Check:**

- **At plan creation**: Agent reviews entire plan holistically for structural recommendations
- **At implementation**: Agent re-evaluates specific phase before starting work
- **Different contexts**: Full plan view vs focused phase view
- **User flexibility**: Can expand at plan time, implementation time, or not at all

### 8.6. Present Recommendations

The agent-based analysis from Step 8.5 is presented immediately after plan creation, before final output. This helps users make informed decisions about plan structure before beginning implementation.

**Presentation Timing:**
- After plan file is written
- Before final "Plan created successfully" message
- Gives user opportunity to expand phases immediately if desired

**User Options After Analysis:**
1. **Expand now**: Use recommended `/expand phase` commands before starting implementation
2. **Expand during implementation**: Wait and expand if phases prove complex
3. **Keep inline**: Continue with Level 0 structure throughout implementation
4. **Selective expansion**: Expand some recommended phases but not others

This analysis replaces the generic complexity hint (≥50 threshold) with specific, informed recommendations based on actual plan content.

### 9. Spec-Updater Agent Invocation

**YOU MUST invoke spec-updater agent after plan creation. This is NOT optional.**

**CRITICAL INSTRUCTIONS**:
- Spec-updater invocation is MANDATORY after plan file creation
- DO NOT skip topic structure verification
- DO NOT skip cross-reference initialization
- Fallback mechanism ensures topic structure is valid

After the plan file is created and written, invoke the spec-updater agent to verify topic structure and initialize cross-references.

This step ensures the topic directory structure is properly initialized and ready for implementation.

---

**STEP 10 (REQUIRED AFTER STEP 9) - Invoke Spec-Updater Agent**

**EXECUTE NOW - Verify Topic Structure via Spec-Updater**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke spec-updater agent to verify topic structure. This is NOT optional.

**WHY THIS MATTERS**: Topic structure verification ensures all subdirectories exist and gitignore compliance is correct, preventing file organization errors during implementation.

#### Step 10.1: Invoke Spec-Updater Agent

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

```
Task {
  subagent_type: "general-purpose"
  description: "Initialize topic structure for new plan"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Context:
    - Plan created at: {plan_path}
    - Topic directory: {topic_dir}
    - Operation: plan_creation

    Tasks:
    1. Verify topic subdirectories exist:
       - reports/
       - plans/
       - summaries/
       - debug/
       - scripts/
       - outputs/
       - artifacts/
       - backups/

    2. Create any missing subdirectories

    3. Create .gitkeep in debug/ subdirectory (ensures directory tracked in git)

    4. Validate gitignore compliance:
       - Debug reports MUST NOT be gitignored
       - All other subdirectories MUST be gitignored

    5. Initialize plan metadata cross-reference section if missing

    Return:
    - Verification status (subdirectories_ok: true/false, gitignore_ok: true/false)
    - List of subdirectories created (if any)
    - Any warnings or issues encountered
    - Confirmation message for user
}
```

**Template Variables** (ONLY allowed modifications):
- `{plan_path}`: Absolute plan file path (from STEP 9)
- `{topic_dir}`: Topic directory path (from STEP 3)

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Task list (1-5)
- Return format requirements

---

**STEP 11 (REQUIRED AFTER STEP 10) - Mandatory Verification with Fallback**

**MANDATORY VERIFICATION - Confirm Topic Structure Valid**

**ABSOLUTE REQUIREMENT**: YOU MUST verify topic structure is valid. This is NOT optional.

#### Step 11.1: Handle Spec-Updater Response

**Verification Steps**:

```bash
# Parse agent response for verification status
VERIFICATION_STATUS=$(echo "$AGENT_OUTPUT" | jq -r '.subdirectories_ok')
GITIGNORE_STATUS=$(echo "$AGENT_OUTPUT" | jq -r '.gitignore_ok')

# MANDATORY: Verify topic structure
if [ "$VERIFICATION_STATUS" != "true" ] || [ "$GITIGNORE_STATUS" != "true" ]; then
  echo "⚠️  TOPIC STRUCTURE INCOMPLETE - Triggering fallback mechanism"

  # Fallback: Create subdirectories manually
  for subdir in reports plans summaries debug scripts outputs artifacts backups; do
    mkdir -p "${TOPIC_DIR}/${subdir}"
  done

  # Create .gitkeep in debug/
  touch "${TOPIC_DIR}/debug/.gitkeep"

  # Verify .gitignore compliance
  if [ -f ".gitignore" ]; then
    # Ensure gitignored subdirectories are listed
    for subdir in scripts outputs artifacts backups; do
      if ! grep -q "specs/.*/${subdir}/" .gitignore 2>/dev/null; then
        echo "specs/**/${subdir}/" >> .gitignore
      fi
    done
  fi

  echo "✓ Fallback: Topic structure created manually"
fi

# Display verification status to user
if [ "$VERIFICATION_STATUS" = "true" ] && [ "$GITIGNORE_STATUS" = "true" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Topic structure verified:"
  echo "✓ All subdirectories present"
  echo "✓ Gitignore compliance validated"
  echo "✓ Debug directory ready for issue tracking"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# If warnings/issues present, display them
WARNINGS=$(echo "$AGENT_OUTPUT" | jq -r '.warnings[]' 2>/dev/null)
if [ -n "$WARNINGS" ]; then
  echo "⚠️  Warnings from spec-updater:"
  echo "$WARNINGS"
fi
```

**Fallback Mechanism** (Guarantees 100% Topic Structure):
- If agent fails → Create subdirectories manually
- If subdirectories missing → Create them with mkdir -p
- If .gitkeep missing → Create it with touch
- If gitignore incomplete → Update it manually

---

### 10. Post-Creation Automatic Complexity Evaluation

**IMPORTANT**: After spec-updater verification completes, perform automatic complexity-based evaluation to determine if any phases WILL be auto-expanded.

This step runs **after** spec-updater invocation (Step 9), providing automated structure optimization.

#### Step 10.1: Source Complexity Utilities

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Check if complexity utilities exist
if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh" ]; then
  echo "Note: Complexity utilities not found, skipping automatic evaluation"
  # Continue to output (section 11)
  exit 0
fi

source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"
```

#### Step 10.2: Read Configurable Thresholds from CLAUDE.md

Use the `read_threshold` function to read expansion thresholds with fallbacks:

```bash
# Helper function: read_threshold
# Reads threshold value from CLAUDE.md with fallback to default
read_threshold() {
  local threshold_name="$1"
  local default_value="$2"

  # Find CLAUDE.md (search upward from project directory)
  local claude_md=""
  local search_dir="$(pwd)"

  while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/CLAUDE.md" ]; then
      claude_md="$search_dir/CLAUDE.md"
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  # Check CLAUDE_PROJECT_DIR as fallback
  if [ -z "$claude_md" ] && [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
    claude_md="$CLAUDE_PROJECT_DIR/CLAUDE.md"
  fi

  # No CLAUDE.md found, use default
  if [ -z "$claude_md" ]; then
    echo "$default_value"
    return
  fi

  # Extract threshold value from pattern: - **Threshold Name**: value
  local threshold_value=$(grep -E "^\s*-\s+\*\*$threshold_name\*\*:" "$claude_md" | \
                          grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

  # Validate threshold is numeric
  if ! [[ "$threshold_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$default_value"
    return
  fi

  echo "$threshold_value"
}

# Read thresholds
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10")
```

#### Step 10.3: Evaluate Each Phase for Auto-Expansion

Parse the plan file and evaluate each phase:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AUTOMATIC COMPLEXITY EVALUATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Using thresholds:"
echo "  Expansion: $EXPANSION_THRESHOLD (complexity score)"
echo "  Task Count: $TASK_COUNT_THRESHOLD (tasks per phase)"
echo ""

# Parse total phases from plan
total_phases=$(grep -c "^### Phase [0-9]" "$plan_file" || echo "0")

if [ "$total_phases" -eq 0 ]; then
  echo "No phases found, skipping evaluation"
  echo ""
else
  echo "Evaluating $total_phases phases..."
  echo ""

  # Track expansions
  expanded_count=0
  expanded_phases=""

  # Evaluate each phase
  for phase_num in $(seq 1 "$total_phases"); do
    # Extract phase content (from "### Phase N:" to next "### Phase" or "## ")
    phase_content=$(sed -n "/^### Phase $phase_num:/,/^### Phase\|^## /p" "$plan_file" | sed '$d')
    phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
                 sed 's/^### Phase [0-9]*: //' | sed 's/ *\[.*\]$//' | sed 's/ *\*\*Objective\*\*.*//')
    task_list=$(echo "$phase_content" | grep "^- \[ \]")

    # Calculate complexity
    complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list" 2>/dev/null || echo "0")
    task_count=$(echo "$task_list" | grep -c "^- \[ \]" || echo "0")

    # Decide if expansion needed
    needs_expansion=false
    expansion_reason=""

    # Use bc for float comparison if available
    if command -v bc &>/dev/null; then
      if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )); then
        needs_expansion=true
        expansion_reason="complexity $complexity_score > threshold $EXPANSION_THRESHOLD"
      fi
    else
      # Fallback to integer comparison
      complexity_int=${complexity_score%.*}
      threshold_int=${EXPANSION_THRESHOLD%.*}
      if [ "$complexity_int" -gt "$threshold_int" ]; then
        needs_expansion=true
        expansion_reason="complexity $complexity_score > threshold $EXPANSION_THRESHOLD"
      fi
    fi

    if [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
      needs_expansion=true
      if [ -n "$expansion_reason" ]; then
        expansion_reason="$expansion_reason AND $task_count tasks > $TASK_COUNT_THRESHOLD"
      else
        expansion_reason="$task_count tasks > threshold $TASK_COUNT_THRESHOLD"
      fi
    fi

    # Auto-expand if threshold exceeded
    if [ "$needs_expansion" = "true" ]; then
      echo "Phase $phase_num: $phase_name"
      echo "  Complexity: $complexity_score | Tasks: $task_count"
      echo "  Reason: $expansion_reason"
      echo "  Action: Auto-expanding..."
      echo ""

      # Invoke /expand phase command
      "$CLAUDE_PROJECT_DIR/.claude/commands/expand" phase "$plan_file" "$phase_num"

      # Track expansion
      expanded_count=$((expanded_count + 1))
      expanded_phases="$expanded_phases $phase_num"

      # Update plan file path after first expansion (L0 → L1 transition)
      plan_base=$(basename "$plan_file" .md)
      if [[ -d "${plan_file%/*}/$plan_base" ]]; then
        plan_file="${plan_file%/*}/$plan_base/$plan_base.md"
      fi

      echo ""
    else
      echo "Phase $phase_num: $phase_name (complexity $complexity_score, $task_count tasks) - OK"
    fi
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "EVALUATION COMPLETE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$expanded_count" -gt 0 ]; then
    echo "Auto-expanded $expanded_count phase(s):$expanded_phases"
    echo "Plan structure: Level 1 (phase-expanded)"
  else
    echo "Plan structure: Level 0 (all phases inline)"
  fi

  echo ""
fi
```

#### Step 10.4: Update Plan Path for Final Output

After auto-expansion (if any), ensure the final plan path points to the correct location:

```bash
# Final plan path (might have changed from L0 → L1)
FINAL_PLAN_PATH="$plan_file"
```

**Benefits of Automatic Evaluation:**

- **Proactive Structure**: Plans are optimally structured before `/implement` begins
- **No Workflow Interruption**: Eliminates mid-implementation pauses for expansion
- **Configurable**: Project-specific thresholds in CLAUDE.md
- **Fallback Defaults**: Works without configuration (8.0 expansion, 10 task count)
- **Complementary**: Works alongside agent-based holistic analysis (Step 8.5)

**Relationship to Spec-Updater and Agent-Based Analysis:**

- **Step 8.5-8.6**: Holistic review with rationale-based recommendations
- **Step 9**: Spec-updater verifies topic structure and initializes cross-references
- **Step 10**: Automatic threshold-based evaluation with auto-expansion
- **Together**: Proper structure + informed recommendations + automatic optimization

## Output Format

### Single File Format (Structure Level 0)
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Topic Directory**: [specs/{NNN_topic}/ or .claude/specs/{NNN_topic}/]
- **Plan Number**: [NNN] (within topic)
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Structure Level**: 0
- **Complexity Score**: [N.N]
- **Estimated Phases**: [Number]
- **Estimated Tasks**: [Number]
- **Estimated Hours**: [Number]
- **Standards File**: [Path to CLAUDE.md if found]
- **Research Reports**: [List of report paths used, if any]

## Overview
[Feature description and goals]

## Success Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Technical Design
[Architecture and design decisions]

## Implementation Phases

### Phase 1: [Foundation/Setup]
**Objective**: [What this phase accomplishes]
**Dependencies**: []
**Complexity**: [Low/Medium/High]
**Risk**: [Low/Medium/High]
**Estimated Time**: [X-Y hours]

Tasks:
- [ ] Specific task with file reference
- [ ] Another task

Testing:
```bash
# Test command
```

### Phase 2: [Core Implementation]
**Dependencies**: [1]
[Continue with subsequent phases...]

## Phase Dependencies

Phase dependencies enable wave-based parallel execution during implementation. Phases with no dependencies (or satisfied dependencies) WILL execute in parallel, substantially reducing implementation time.

**Dependency Syntax**:
- `Dependencies: []` - No dependencies (independent phase, WILL run in wave 1)
- `Dependencies: [1]` - Depends on phase 1 completing first
- `Dependencies: [1, 2]` - Depends on phases 1 and 2 both completing first
- `Dependencies: [2, 3, 5]` - Depends on multiple non-consecutive phases

**Rules**:
- Dependencies are phase numbers (integers)
- A phase MUST only depend on earlier phases (no forward dependencies)
- Circular dependencies are invalid and will be detected
- Self-dependencies are invalid
- If no Dependencies field specified, defaults to `[]` (independent)

**Wave Calculation**:
The `/orchestrate` command uses topological sorting (Kahn's algorithm) to calculate execution waves:
- **Wave 1**: All phases with no dependencies execute in parallel
- **Wave 2**: All phases that only depend on Wave 1 phases execute in parallel
- **Wave N**: Continues until all phases scheduled

**Example**:
```markdown
### Phase 1: Database Setup
**Dependencies**: []

### Phase 2: API Layer
**Dependencies**: [1]

### Phase 3: Frontend Components
**Dependencies**: [1]

### Phase 4: Integration Tests
**Dependencies**: [2, 3]
```

**Execution Waves**:
- Wave 1: Phase 1
- Wave 2: Phases 2, 3 (parallel)
- Wave 3: Phase 4

**Performance Impact**:
- Example above: 40-50% time savings compared to sequential execution
- Wave-based execution typically achieves 30-60% time savings depending on dependency structure

For detailed dependency documentation, see `.claude/docs/phase_dependencies.md`

## Testing Strategy
[Overall testing approach]

## Documentation Requirements
[What documentation needs updating]

## Dependencies
[External dependencies or prerequisites]

## Related Artifacts
[If plan created from /orchestrate workflow with research artifacts:]
- [Existing Patterns](../artifacts/{project_name}/existing_patterns.md)
- [Best Practices](../artifacts/{project_name}/best_practices.md)
- [Alternative Approaches](../artifacts/{project_name}/alternatives.md)

[Otherwise: "No artifacts - direct implementation plan"]

## Notes
[Additional considerations or decisions]
```

## Agent Usage

For agent invocation patterns, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns).

**Plan-specific agents:**

| Agent | Purpose | When Used |
|-------|---------|-----------|
| research-specialist | Analyze codebase and research best practices | Complex features requiring analysis |
| plan-architect | Generate structured implementation plans | All planning workflows |

**Two-Stage Process:**
1. **Research** (optional): Parallel research-specialist agents for different topics
2. **Planning**: Single plan-architect agent creates Level 0 plan

**Key Behaviors:**
- Always creates single-file Level 0 plans
- Includes complexity score in metadata (informational)
- Adds expansion hints if complexity ≥50
- Follows project standards from CLAUDE.md
- Uses /implement-compatible checkbox format

---

## Checkpoint Reporting

**YOU MUST report plan creation checkpoint. This is NOT optional.**

**CHECKPOINT REQUIREMENT - Report Plan Creation Complete**

**ABSOLUTE REQUIREMENT**: After spec-updater verification and plan file creation, YOU MUST report this checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Checkpoint reporting provides confirmation that plan was created successfully with all metadata and cross-references.

**Report Format**:

```
CHECKPOINT: Plan Creation Complete
- Plan: ${PLAN_PATH}
- Topic: ${TOPIC_DIR}
- Complexity: ${PLAN_COMPLEXITY_SCORE}
- Phases: ${PHASE_COUNT}
- Estimated Hours: ${ESTIMATED_HOURS}
- Research Reports: ${REPORT_COUNT}
- Topic Structure: ✓ VERIFIED
- Status: READY FOR IMPLEMENTATION
```

**Required Information**:
- Plan file path (absolute path from STEP 9)
- Topic directory (from STEP 3)
- Complexity score (from STEP 6)
- Phase count (from STEP 6)
- Estimated hours (from STEP 6)
- Number of research reports used (if any)
- Topic structure verification status (from STEP 11)
- Ready for implementation confirmation

---

Let me analyze your feature requirements and create a comprehensive implementation plan.
