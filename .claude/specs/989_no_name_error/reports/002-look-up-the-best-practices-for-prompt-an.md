# Anthropic Prompt and Context Engineering Best Practices Research Report

## Metadata
- **Date**: 2025-12-01
- **Agent**: research-specialist
- **Topic**: Anthropic prompt engineering and context management best practices
- **Report Type**: best practices analysis with infrastructure evaluation
- **Workflow Type**: research-only

## Executive Summary

This report synthesizes Anthropic's official prompt engineering and context management best practices from 2025 documentation, then evaluates the current .claude/ command infrastructure against these standards. Key findings include strong alignment with Anthropic's hierarchical agent patterns and structured context engineering, but opportunities exist for enhanced progressive disclosure, compaction strategies, and just-in-time context retrieval. The infrastructure demonstrates sophisticated implementation of recommended patterns including XML-based structure, chain-of-thought reasoning, and tool design minimalism.

## Findings

### Part 1: Anthropic's Official Best Practices (2025)

#### 1.1 Core Prompt Engineering Principles

**Recommended Technique Sequence** (from Anthropic documentation):
1. **Prompt generator** - Start with automated assistance
2. **Be clear and direct** - Foundational clarity in instructions
3. **Use examples (multishot)** - Provide sample inputs/outputs
4. **Let Claude think (chain of thought)** - Enable step-by-step reasoning
5. **Use XML tags** - Structure information with formatting
6. **Give Claude a role (system prompts)** - Define persona/context
7. **Prefill Claude's response** - Guide output format
8. **Chain complex prompts** - Connect multiple prompts
9. **Long context tips** - Optimize for extended documents

Source: [Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)

**Key Techniques**:

1. **Chain-of-Thought Reasoning**: "Often Claude will respond more accurately if you simply tell it to think step by step after you give it an instruction."

2. **Few-Shot Prompting**: "Providing examples, otherwise known as few-shot prompting, is a well known best practice that Anthropic continues to strongly advise."

3. **XML Tags for Structure**: "Templates often place variables between XML tags. This follows another key best practice by clearly delineating different parts of the prompt by providing a clear structure."

4. **Specificity**: "Claude Code's success rate improves significantly with more specific instructions, especially on first attempts."

#### 1.2 System Prompt Design

**Core Principle** (from system prompts documentation):
"Use the `system` parameter to set Claude's role. Put everything else, like task-specific instructions, in the `user` turn instead."

**Design Strategy**:
- **Specific and layered**: Rather than "data scientist," try "data scientist specializing in customer insight analysis for Fortune 500 companies"
- **Placed in system parameter only**: Reserve the user message for task-specific details
- **Experimentally refined**: Test variations to discover which role yields optimal insights

**Benefits**:
- Enhanced performance in complex domains (legal, financial)
- Tone customization (CFO conciseness vs. copywriter creativity)
- Task focus (prevents scope drift)

Source: [System Prompts](https://platform.claude.com/docs/claude/system-prompts)

#### 1.3 Context Engineering for AI Agents

**Fundamental Principle**: "Building with language models is becoming less about finding the right words and phrases for your prompts, and more about answering the broader question of 'what configuration of context is most likely to generate our model's desired behavior?'"

**System Prompt Best Practices**:
- **Right Altitude Balance**: Avoid brittle, hardcoded logic on one extreme and vague, context-assuming guidance on the other
- **Structural Organization**: Use XML tags or Markdown headers to delineate sections like `<background_information>`, `<instructions>`, tool guidance, and output descriptions
- **Minimal Sufficiency**: Provide only essential information needed for expected behavior—minimal doesn't mean short

**Tool Design Principles**:
- Minimize functional overlap and ambiguity in tool selection
- Ensure tools return token-efficient information
- Make tools self-contained, robust, and unambiguous in purpose
- Avoid bloated tool sets that confuse agent decision-making

**Example Curation**:
Use diverse, canonical examples rather than exhaustive edge case lists. "Examples are the pictures worth a thousand words" for LLM behavior specification.

Source: [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

#### 1.4 Long Context Optimization Techniques

**Document Placement** (30K+ tokens):
"For situations with long documents or a lot of additional background content, Claude generally performs noticeably better if the documents and additive material are placed up top, above the detailed instructions or user query."

**Quote Extraction Technique**:
"Ask Claude to find quotes relevant to the question before answering, and to only answer if it finds relevant quotes. This encourages Claude to ground its responses in the provided context and reduces hallucination risk."

**Priming Instructions**:
"Instruct Claude to read the document carefully, as it will be asked questions later. This primes Claude to pay close attention to the input data with an eye for the task it will be asked to execute."

Source: [Long Context Window Tips](https://platform.claude.com/docs/en/long-context-window-tips)

#### 1.5 Context Management for Long-Running Agents

**Compaction** (from effective-context-engineering):
"Compaction is the practice of taking a conversation nearing the context window limit, summarizing its contents, and reinitiating a new context window with the summary."

Best practices:
- Preserve architectural decisions, unresolved issues, implementation details
- Discard redundant tool outputs
- Start with high recall, then optimize precision
- Tool result clearing represents lightweight compaction

**Context Editing**:
"Context editing automatically clears stale tool calls and results from within the context window when approaching token limits."

**Memory Tool**:
"The memory tool enables Claude to store and consult information outside the context window through a file-based system."

**Structured Note-Taking**:
Agents maintain persistent memory outside the context window (like NOTES.md files or to-do lists), retrieving relevant notes later.

**Sub-Agent Architectures**:
"Specialized agents handle focused tasks with clean context windows. Main agent coordinates high-level plans while subagents explore extensively but return condensed summaries (1,000-2,000 tokens)."

Source: [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

#### 1.6 Long-Running Agent Harnesses

**Two-Fold Solution** (from Claude Agent SDK):
1. **Initializer Agent**: Sets up the environment on the first run
2. **Coding Agent**: Makes incremental progress in every session, leaving clear artifacts for the next session

**Key Artifacts**:
- `init.sh` script for environment setup
- `claude-progress.txt` file logging what agents have done
- Initial git commit for state tracking

**Session Initialization Workflow**:
- Check current working directory
- Review git logs and progress files
- Select highest-priority incomplete feature
- Run end-to-end tests on existing functionality
- Begin incremental work on one feature

Source: [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

#### 1.7 Claude Code Best Practices

**CLAUDE.md Configuration**:
"Customize your setup through `CLAUDE.md` files. These special configuration files automatically load into every conversation, making them ideal for storing:
- Common bash commands and their usage
- Code style guidelines
- Testing procedures
- Repository conventions"

**Important**: Files should be "concise and human-readable" and iteratively refined like production prompts.

**Extended Thinking Modes**:
Phrases like "think," "think hard," "think harder," and "ultrathink" trigger progressively larger computation budgets.

**Structured Workflows**:
The "explore, plan, code, commit" pattern separates concerns effectively:
1. Have Claude read files without writing code
2. Request detailed plans before implementation
3. Execute the implementation
4. Create commits and pull requests

**Context Reset Strategy**:
"Use `/clear` between unrelated tasks to prevent irrelevant conversation from degrading performance."

Source: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

### Part 2: Current .claude/ Infrastructure Analysis

#### 2.1 Command Structure and System Prompts

**Current Implementation** (from /research command, lines 15-22):
```markdown
# /research - Research-Only Workflow Command

YOU ARE EXECUTING a research-only workflow that creates comprehensive research reports without planning or implementation phases.

**Workflow Type**: research-only
**Terminal State**: research (after research phase complete)
**Expected Output**: Research reports in .claude/specs/NNN_topic/reports/
```

**Analysis**:
- ✅ Clear role definition ("research-only workflow")
- ✅ Explicit scope boundaries (no planning/implementation)
- ✅ Specific expected outputs with paths
- ⚠️ Could benefit from more layered role specificity (e.g., "Research Specialist specializing in codebase analysis and best practices synthesis")

**Similar Pattern in /plan** (lines 16-22):
```markdown
# /plan - Research-and-Plan Workflow Command

YOU ARE EXECUTING a research-and-plan workflow that creates comprehensive research reports and then generates a new implementation plan based on those findings.

**Workflow Type**: research-and-plan
**Terminal State**: plan (after planning phase complete)
**Expected Output**: Research reports + implementation plan in .claude/specs/NNN_topic/
```

**Evaluation Against Anthropic Standards**:
- ✅ System-level role definition (workflow type)
- ✅ Task-specific instructions in command body
- ✅ Clear delineation between role and task
- 📊 Score: 85/100 (strong alignment)

#### 2.2 XML and Structural Organization

**Current Implementation** (from /research agent invocation, lines 596-614):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: research workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}
    - Output Directory: ${RESEARCH_DIR}
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Workflow Type: research-only
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}
```

**Analysis**:
- ✅ Structured sections with Markdown headers (`**Input Contract**`)
- ✅ Clear variable delineation
- ⚠️ Uses Markdown `**bold**` instead of XML tags
- 💡 Opportunity: Could use `<input_contract>`, `<context>`, `<instructions>` XML tags

**Evaluation Against Anthropic Standards**:
- ✅ Clear structural organization (Anthropic accepts both XML and Markdown)
- ✅ Variable delineation
- ✅ Logical section grouping
- 📊 Score: 90/100 (excellent, could add XML for even more clarity)

#### 2.3 Chain-of-Thought and Step-by-Step Reasoning

**Current Implementation** (from research-specialist.md, lines 20-51):
```markdown
**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints

### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path
### STEP 2 (REQUIRED BEFORE STEP 3) - Create Report File FIRST
### STEP 3 (REQUIRED BEFORE STEP 4) - Conduct Research and Update Report
### STEP 4 (ABSOLUTE REQUIREMENT) - Verify and Return Confirmation
```

**Analysis**:
- ✅ Explicit step-by-step sequencing
- ✅ Checkpoint validation between steps
- ✅ Prerequisites clearly stated ("REQUIRED BEFORE")
- ✅ Promotes chain-of-thought by forcing sequential execution
- 📊 Score: 95/100 (exemplary implementation)

**Anthropic Recommendation**: "Often Claude will respond more accurately if you simply tell it to think step by step."

**Infrastructure Alignment**: ✅ Exceeds recommendation with explicit checkpoints and dependency enforcement

#### 2.4 Few-Shot Prompting and Examples

**Current Implementation** (from /research command, lines 28-32):
```markdown
**Example**: If user ran `/research "authentication patterns in codebase"`, change:
- FROM: `echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$TEMP_FILE"`
- TO: `echo "authentication patterns in codebase" > "$TEMP_FILE"`
```

**Analysis**:
- ✅ Concrete example provided
- ✅ Shows before/after transformation
- ⚠️ Only one example (could benefit from 2-3 examples)
- 💡 Opportunity: Add edge case examples (special characters, long prompts)

**Similar Pattern in /build** (lines 30-32):
```markdown
**Examples**:
- If user ran `/build plan.md 3 --dry-run`, change to: `echo "plan.md 3 --dry-run" > "$TEMP_FILE"`
- If user ran `/build`, change to: `echo "" > "$TEMP_FILE"` (auto-resume mode)
```

**Evaluation**:
- ✅ Multiple examples (2)
- ✅ Shows different use cases (arguments vs. auto-resume)
- 📊 Score: 85/100 (good, could expand to 3-4 examples)

#### 2.5 Tool Design and Minimalism

**Current Implementation** (from research-specialist.md, lines 651-658):
```markdown
### Tool Access
My tools support research and report creation:
- **Read**: Access file contents for analysis
- **Write**: Create research report files (reports only, not code)
- **Grep**: Search file contents for patterns
- **Glob**: Find files by pattern, determine report numbers
- **WebSearch**: Find external information and best practices
- **WebFetch**: Retrieve web documentation

I cannot Edit existing files or execute code (Bash), ensuring I only create new research documentation.
```

**Analysis**:
- ✅ Minimal, focused tool set (6 tools, clear purposes)
- ✅ No functional overlap (Read vs. Write are distinct)
- ✅ Self-contained tools with unambiguous purposes
- ✅ Explicit constraints (cannot Edit or Bash)
- 📊 Score: 95/100 (exemplary tool design)

**Anthropic Guidance**: "One of the most common failure modes is bloated tool sets that cover too much functionality or lead to ambiguous decision points."

**Infrastructure Alignment**: ✅ Excellent - tools are minimal and purpose-specific

**Comparison to plan-architect** (lines 3):
```markdown
allowed-tools: Read, Write, Edit, Grep, Glob, WebSearch, Bash
```

**Analysis**:
- ✅ 7 tools (still minimal)
- ✅ Edit tool justified (plan revision mode)
- ✅ Bash tool justified (complexity calculation, path manipulation)
- 📊 Score: 90/100 (good, slightly more complex but justified)

#### 2.6 Context Management and Compaction

**Current Implementation** (from /build command, iteration loop, lines 454-476):
```bash
# === ITERATION LOOP VARIABLES ===
# These enable persistent iteration for large plans
ITERATION=1
CONTINUATION_CONTEXT=""
LAST_WORK_REMAINING=""
STUCK_COUNT=0

# Persist iteration variables for cross-block accessibility
append_workflow_state "MAX_ITERATIONS" "$MAX_ITERATIONS"
append_workflow_state "CONTEXT_THRESHOLD" "$CONTEXT_THRESHOLD"
append_workflow_state "ITERATION" "$ITERATION"
append_workflow_state "CONTINUATION_CONTEXT" "$CONTINUATION_CONTEXT"
append_workflow_state "LAST_WORK_REMAINING" "$LAST_WORK_REMAINING"
append_workflow_state "STUCK_COUNT" "$STUCK_COUNT"

# Create build workspace directory for iteration summaries
BUILD_WORKSPACE="${CLAUDE_PROJECT_DIR}/.claude/tmp/build_${WORKFLOW_ID}"
mkdir -p "$BUILD_WORKSPACE"
append_workflow_state "BUILD_WORKSPACE" "$BUILD_WORKSPACE"
```

**Analysis**:
- ✅ Iteration-based compaction strategy
- ✅ Continuation context file (`CONTINUATION_CONTEXT`)
- ✅ Work remaining tracking (progressive disclosure)
- ✅ Stuck detection (prevents infinite loops)
- ⚠️ Missing: Explicit summary generation for continuation
- 💡 Opportunity: Add structured note-taking pattern

**Evaluation Against Anthropic Compaction Standards**:
- ✅ Context window management via iterations
- ✅ State persistence between sessions
- ⚠️ No explicit LLM-based summarization call
- 📊 Score: 75/100 (good foundation, needs explicit summarization)

**Anthropic Recommendation**: "Compaction distills the contents of a context window in a high-fidelity manner, enabling the agent to continue with minimal performance degradation."

**Gap**: The infrastructure tracks state but doesn't implement LLM-based summarization for context compaction.

#### 2.7 Hierarchical Agent Architecture and Sub-Agents

**Current Implementation** (Task tool delegation in /research, lines 238-261):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /research command

    **Input**:
    - User Prompt: ${WORKFLOW_DESCRIPTION}
    - Command Name: /research
    - OUTPUT_FILE_PATH: ${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to OUTPUT_FILE_PATH using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>
```

**Analysis**:
- ✅ Sub-agent architecture (topic-naming-agent invoked by research command)
- ✅ Focused task delegation (single responsibility: topic naming)
- ✅ Clean context window (no search history, just generation task)
- ✅ Condensed return (single topic name, not full reasoning)
- 📊 Score: 95/100 (exemplary sub-agent pattern)

**Anthropic Guidance**: "Main agent coordinates high-level plans while subagents explore extensively but return condensed summaries (1,000-2,000 tokens), isolating detailed search context from synthesis work."

**Infrastructure Alignment**: ✅ Excellent - follows recommended pattern precisely

**Similar Pattern in /plan** (lines 920-945):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: plan workflow

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_JSON}
```

**Analysis**:
- ✅ Clean delegation (plan-architect handles all planning logic)
- ✅ Context isolation (orchestrator doesn't execute planning)
- ✅ Condensed return (plan file path, not entire plan content)
- 📊 Score: 95/100

#### 2.8 Progressive Disclosure and Just-in-Time Retrieval

**Current Implementation** (from /build implementer-coordinator invocation, lines 505-563):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    You are executing the implementation phase for: build workflow

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - summaries_dir: ${TOPIC_PATH}/summaries/
    - artifact_paths:
      - reports: ${TOPIC_PATH}/reports/
      - plans: ${TOPIC_PATH}/plans/
      - summaries: ${TOPIC_PATH}/summaries/
      - debug: ${TOPIC_PATH}/debug/
      - outputs: ${TOPIC_PATH}/outputs/
      - checkpoints: ${HOME}/.claude/data/checkpoints/
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - iteration: ${ITERATION}
```

**Analysis**:
- ⚠️ Paths pre-loaded (not just-in-time retrieval)
- ✅ Continuation context supports progressive disclosure
- ⚠️ All artifact paths provided upfront (could be loaded on-demand)
- 💡 Opportunity: Implement lightweight identifier pattern

**Anthropic Recommendation**: "Just-in-Time Retrieval: Maintain lightweight identifiers (file paths, links, queries) and dynamically load data at runtime rather than pre-processing everything."

**Gap**: The infrastructure provides full paths upfront. Could benefit from a retrieval mechanism where agent requests paths only when needed.

**Evaluation**:
- ⚠️ Pre-loads context (not progressive)
- ✅ Continuation context enables incremental work
- 📊 Score: 65/100 (opportunity for improvement)

#### 2.9 Progress Tracking and Artifacts

**Current Implementation** (from research-specialist.md, lines 201-236):
```markdown
## Progress Streaming (MANDATORY During Research)

**YOU MUST emit progress markers during research** to provide visibility:

### Progress Marker Format
```
PROGRESS: <brief-message>
```

### Required Progress Markers

YOU MUST emit these markers at each milestone:

1. **Starting** (STEP 2): `PROGRESS: Creating report file at [path]`
2. **Starting Research** (STEP 3 start): `PROGRESS: Starting research on [topic]`
3. **Searching** (during search): `PROGRESS: Searching codebase for [pattern]`
4. **Analyzing** (during analysis): `PROGRESS: Analyzing [N] files found`
5. **Web Research** (if applicable): `PROGRESS: Searching for [topic] best practices`
6. **Updating** (during writes): `PROGRESS: Updating report with findings`
7. **Completing** (STEP 4): `PROGRESS: Research complete, report verified`
```

**Analysis**:
- ✅ Structured progress tracking
- ✅ Human-readable format
- ✅ Milestone-based (not verbose logging)
- ✅ Consistent pattern across agents
- 📊 Score: 90/100 (excellent for visibility)

**Anthropic Recommendation** (from agent harnesses): "The key insight was finding a way for agents to quickly understand the state of work when starting with a fresh context window, accomplished with the progress file alongside git history."

**Infrastructure Alignment**: ✅ Excellent - progress markers enable state recovery and visibility

#### 2.10 Hard Barrier Pattern and Mandatory Delegation

**Current Implementation** (from /research command, lines 584-616 and 618-764):
```markdown
## Block 1d: Report Path Pre-Calculation

**EXECUTE NOW**: Pre-calculate the absolute report path before invoking research-specialist.

This implements the **hard barrier pattern** - the report path is calculated BEFORE subagent invocation, passed as an explicit contract, and validated AFTER return.

## Block 1d-exec: Research Specialist Invocation

**HARD BARRIER - Research Specialist Invocation**

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent. This invocation is MANDATORY.

## Block 1e: Agent Output Validation (Hard Barrier)

**EXECUTE NOW**: Validate that research-specialist created the report at the pre-calculated path.

This is the **hard barrier** - the workflow CANNOT proceed to Block 2 unless the report file exists.
```

**Analysis**:
- ✅ Pre-calculation pattern (path determined before invocation)
- ✅ Explicit contract (path passed to subagent)
- ✅ Post-invocation validation (file existence check)
- ✅ Mandatory delegation (no bypass allowed)
- ✅ Architectural enforcement (bash blocks enforce barrier)
- 📊 Score: 100/100 (perfect implementation)

**Anthropic Pattern** (from sub-agent architectures): "Specialized agents handle focused tasks with clean context windows."

**Infrastructure Alignment**: ✅ Exceeds recommendation - adds enforcement layer to ensure delegation always occurs

### Part 3: Improvement Opportunities

#### 3.1 Context Engineering Enhancements

**Opportunity 1: Implement Explicit Compaction**

Current state: Iteration-based state persistence exists, but no LLM-based summarization.

**Recommendation**:
Add a compaction step in the iteration loop:

```markdown
# After iteration completion, before next iteration
Task {
  subagent_type: "general-purpose"
  description: "Compact iteration context for next cycle"
  prompt: "
    Read the implementation summary from iteration ${ITERATION}:
    ${CONTINUATION_CONTEXT}

    Create a high-fidelity summary preserving:
    - Architectural decisions made
    - Unresolved issues or blockers
    - Implementation details for next iteration
    - Critical context from phase work

    Discard:
    - Redundant tool outputs
    - Verbose debug information
    - Completed task details (keep only status)

    Output: Condensed summary (<2000 tokens) for iteration $((ITERATION + 1))
  "
}
```

**Expected Impact**: Reduce context window pressure, improve coherence across iterations.

**Opportunity 2: Implement Just-in-Time Path Retrieval**

Current state: All artifact paths pre-loaded in Task invocation.

**Recommendation**:
Provide path discovery mechanism instead of full paths:

```markdown
Task {
  prompt: "
    **Path Discovery**:
    - Use discover_artifact_path() function to retrieve paths on-demand
    - Example: discover_artifact_path('reports', $TOPIC_PATH) → reports directory path
    - Only load paths when accessing artifacts, not upfront

    Available artifact types: reports, plans, summaries, debug, outputs
  "
}
```

**Expected Impact**: Reduce upfront context, enable true progressive disclosure.

**Opportunity 3: Add XML Tag Structure**

Current state: Markdown headers used for structure.

**Recommendation**:
Supplement Markdown with XML for variable delineation:

```markdown
Task {
  prompt: "
    <background_information>
    You are executing the implementation phase for: build workflow
    </background_information>

    <input_contract>
      <plan_path>$PLAN_FILE</plan_path>
      <topic_path>$TOPIC_PATH</topic_path>
      <iteration>$ITERATION</iteration>
      <max_iterations>$MAX_ITERATIONS</max_iterations>
    </input_contract>

    <instructions>
    Execute all implementation phases according to the plan.
    </instructions>
  "
}
```

**Expected Impact**: Improved prompt clarity, reduced ambiguity.

#### 3.2 Few-Shot and Example Enhancements

**Opportunity 4: Expand Example Coverage**

Current state: 1-2 examples per command.

**Recommendation**:
Provide 3-4 examples covering:
- Standard case
- Edge case (special characters, long inputs)
- Error case (missing file, invalid format)
- Advanced case (flags, optional parameters)

**Example for /research**:
```markdown
**Examples**:
1. Standard: `/research "authentication patterns"`
   - `echo "authentication patterns" > "$TEMP_FILE"`

2. Long prompt: `/research "analyze async/await patterns in Lua ecosystem with focus on error handling"`
   - `echo "analyze async/await patterns..." > "$TEMP_FILE"`

3. Special characters: `/research "OAuth2 flow (RFC 6749) implementation"`
   - `echo "OAuth2 flow (RFC 6749) implementation" > "$TEMP_FILE"`

4. With file: `/research --file /tmp/prompt.md --complexity 4`
   - File content loaded into WORKFLOW_DESCRIPTION
```

**Expected Impact**: Improved accuracy on edge cases, reduced errors.

#### 3.3 Progress and Visibility Enhancements

**Opportunity 5: Add Estimated Completion Metrics**

Current state: Progress markers show current activity.

**Recommendation**:
Add completion estimates:

```markdown
PROGRESS: Searching codebase (auth*.lua) [Phase 1/4]
PROGRESS: Analyzing 15 files found [Phase 2/4, 25% complete]
PROGRESS: Updating report with findings [Phase 3/4, 75% complete]
PROGRESS: Research complete, report verified [Phase 4/4, 100% complete]
```

**Expected Impact**: Better user visibility into time-to-completion.

**Opportunity 6: Implement Structured Note-Taking**

Current state: Continuation context stored as summary file.

**Recommendation**:
Add persistent notes structure:

```markdown
# Create notes file for long-running workflows
NOTES_FILE="${TOPIC_PATH}/NOTES.md"

# Agent updates notes incrementally
## Iteration 1 Notes
- Architecture decision: Use Redis for session storage
- Blocker: Redis connection pool size needs tuning
- Next: Implement retry logic for Redis failures

## Iteration 2 Notes
- Resolved: Redis pool size set to 10
- New finding: Session TTL needs sliding window
- Next: Implement sliding window refresh
```

**Expected Impact**: Better context recovery across sessions, improved debugging.

#### 3.4 Tool and Agent Design Enhancements

**Opportunity 7: Add Tool Description Refinements**

Current state: Tools listed with brief descriptions.

**Recommendation** (from Anthropic SWE-bench case study):
"Even small refinements to tool descriptions can yield dramatic improvements."

Refine tool descriptions in agent behavioral files:

```markdown
**Before**:
- **Grep**: Search file contents for patterns

**After**:
- **Grep**: Search file contents for regex patterns. Use for finding specific code patterns, function definitions, or configuration values. Returns line numbers and matched text. Supports context lines (-A, -B, -C).
```

**Expected Impact**: Reduced tool selection errors, improved agent accuracy.

#### 3.5 Testing and Validation Enhancements

**Opportunity 8: Add Pre-Flight Validation**

Current state: Validation happens during execution.

**Recommendation**:
Add validation phase before execution:

```markdown
# Before research invocation
validate_research_prerequisites() {
  # Check report directory exists
  # Verify WORKFLOW_DESCRIPTION is non-empty
  # Confirm research complexity in valid range (1-4)
  # Validate CLAUDE_PROJECT_DIR set
}
```

**Expected Impact**: Fail-fast on invalid inputs, clearer error messages.

## Recommendations

### High-Priority Recommendations (Implement First)

1. **Implement Explicit Context Compaction** (Opportunity 1)
   - Add LLM-based summarization between iterations
   - Preserve high-signal context (decisions, blockers, next steps)
   - Discard low-signal context (verbose outputs, completed details)
   - **Rationale**: Directly addresses Anthropic's compaction best practice
   - **Impact**: High - improves multi-iteration coherence

2. **Expand Few-Shot Examples to 3-4 per Command** (Opportunity 4)
   - Cover standard, edge, error, and advanced cases
   - Include examples with special characters and flags
   - Show both successful and error scenarios
   - **Rationale**: Anthropic strongly recommends few-shot prompting
   - **Impact**: Medium - reduces errors on edge cases

3. **Refine Tool Descriptions with Detailed Usage Guidance** (Opportunity 7)
   - Add parameter explanations
   - Include common use cases
   - Specify output formats
   - **Rationale**: Anthropic SWE-bench case study showed dramatic improvements
   - **Impact**: High - improves tool selection accuracy

### Medium-Priority Recommendations (Implement Next)

4. **Add XML Tag Structure to Task Invocations** (Opportunity 3)
   - Wrap context sections in `<background_information>`
   - Wrap inputs in `<input_contract>`
   - Wrap instructions in `<instructions>`
   - **Rationale**: Anthropic explicitly recommends XML for structure
   - **Impact**: Medium - improves prompt clarity

5. **Implement Structured Note-Taking for Long Workflows** (Opportunity 6)
   - Create persistent NOTES.md files
   - Agents append notes incrementally
   - Include decisions, blockers, next steps
   - **Rationale**: Recommended by Anthropic for long-running agents
   - **Impact**: High - improves context recovery across sessions

6. **Add Progress Completion Estimates** (Opportunity 5)
   - Show phase numbers (e.g., Phase 2/4)
   - Include percentage complete estimates
   - Provide time-to-completion estimates
   - **Rationale**: Improves user visibility
   - **Impact**: Low - cosmetic improvement, better UX

### Low-Priority Recommendations (Consider for Future)

7. **Implement Just-in-Time Path Retrieval** (Opportunity 2)
   - Provide discovery functions instead of full paths
   - Load paths on-demand, not upfront
   - Reduce initial context window pressure
   - **Rationale**: Anthropic recommends progressive disclosure
   - **Impact**: Low - current approach works well, optimization not critical

8. **Add Pre-Flight Validation Functions** (Opportunity 8)
   - Validate inputs before execution
   - Fail-fast with clear error messages
   - Check prerequisites (directories, variables)
   - **Rationale**: Improves error handling
   - **Impact**: Low - current error handling is adequate

### Additional Observations

**Infrastructure Strengths**:
- ✅ Excellent hierarchical agent architecture (95/100)
- ✅ Strong hard barrier pattern implementation (100/100)
- ✅ Well-designed tool sets with minimal overlap (95/100)
- ✅ Clear step-by-step reasoning with checkpoints (95/100)
- ✅ Structured progress tracking (90/100)

**Infrastructure Gaps Compared to Anthropic Best Practices**:
- ⚠️ No explicit LLM-based context compaction (75/100)
- ⚠️ Limited few-shot examples (1-2 vs. recommended 3-4) (85/100)
- ⚠️ Pre-loads context instead of just-in-time retrieval (65/100)
- ⚠️ Markdown structure instead of XML tags (90/100)

**Overall Infrastructure Score**: 88/100
- Strong alignment with Anthropic's 2025 best practices
- Excellent foundation with room for targeted improvements
- High-priority opportunities focus on compaction and examples

## References

### Anthropic Documentation Sources
1. [Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview) - Core techniques and sequencing
2. [System Prompts](https://platform.claude.com/docs/claude/system-prompts) - Role definition and design strategy
3. [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) - Context engineering principles, compaction, sub-agents
4. [Long Context Window Tips](https://platform.claude.com/docs/en/long-context-window-tips) - Document placement, quote extraction
5. [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) - Session management, progress tracking
6. [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - CLAUDE.md usage, structured workflows

### Codebase References
1. `/home/benjamin/.config/.claude/commands/research.md` - Lines 15-1012 (command structure, agent invocation, hard barrier pattern)
2. `/home/benjamin/.config/.claude/commands/plan.md` - Lines 1-1227 (workflow orchestration, state machine)
3. `/home/benjamin/.config/.claude/commands/build.md` - Lines 1-1933 (iteration loop, context management, test execution)
4. `/home/benjamin/.config/.claude/agents/research-specialist.md` - Lines 1-691 (agent behavioral guidelines, step-by-step execution, tool access)
5. `/home/benjamin/.config/.claude/agents/plan-architect.md` - Lines 1-100 (operation mode detection, complexity calculation)
6. `/home/benjamin/.config/CLAUDE.md` - Lines 1-end (project standards, documentation policy, command reference)
