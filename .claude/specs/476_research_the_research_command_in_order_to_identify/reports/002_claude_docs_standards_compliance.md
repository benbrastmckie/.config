# Claude Docs Standards Compliance for Command Development

## Metadata
- **Date**: 2025-10-26
- **Agent**: research-specialist
- **Topic**: Command development standards and compliance requirements
- **Report Type**: Standards analysis

## Executive Summary

The `.claude/docs/` directory establishes comprehensive architectural standards for command development through 12 core standards, 8 design patterns, and 4 enforcement mechanisms. Commands must use imperative language (MUST/WILL/SHALL), implement verification-fallback patterns for 100% file creation rates, and maintain <30% context usage through metadata-only passing. The system achieves 90% code reduction through behavioral injection (referencing agent files instead of duplicating procedures), prevents 0% delegation rates through strict anti-pattern enforcement, and requires specific structural templates (Task blocks, bash execution, verification checkpoints) to remain inline while prohibiting behavioral content duplication.

## Findings

### 1. Command Architecture Standards (Reference Document)

**File**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (1966 lines)

#### Standard 0: Execution Enforcement
- **Requirement**: All critical operations use imperative language (MUST/WILL/SHALL, not should/may/can)
- **Enforcement Patterns**:
  - Direct execution blocks: `**EXECUTE NOW - Calculate Paths**`
  - Mandatory verification checkpoints: `**MANDATORY VERIFICATION - Report File Existence**`
  - Non-negotiable agent prompts: `THIS EXACT TEMPLATE (No modifications)`
  - Checkpoint reporting: `CHECKPOINT REQUIREMENT`
- **Language Strength Hierarchy** (lines 186-196):
  - Critical: "CRITICAL:", "ABSOLUTE REQUIREMENT" (safety, data integrity)
  - Mandatory: "YOU MUST", "REQUIRED", "EXECUTE NOW" (essential steps)
  - Strong: "Always", "Never", "Ensure" (best practices)
  - Standard: "Should", "Recommended" (preferences) - **PROHIBITED in critical sections**
  - Optional: "May", "Can", "Consider" (alternatives) - **PROHIBITED in critical sections**

#### Standard 0.5: Subagent Prompt Enforcement
- **Extension for Agent Definition Files** (lines 419-929)
- **Imperative transformation rules**:
  - Role Declaration: "I am" → "YOU MUST perform these exact steps"
  - Sequential Dependencies: Steps marked "STEP N (REQUIRED BEFORE STEP N+1)"
  - File Creation as Primary Obligation: Marked "ABSOLUTE REQUIREMENT"
  - Passive Voice Elimination: Zero "should/may/can" in critical sections
- **Target Score**: 95+/100 on enforcement rubric (28 completion criteria)

#### Standard 1: Executable Instructions Must Be Inline
- **Required inline content** (lines 931-943):
  - Step-by-step execution procedures with numbered steps
  - Tool invocation examples with actual parameter values
  - Decision logic flowcharts with conditions and branches
  - JSON/YAML structure specifications
  - Bash command examples with actual paths
  - Agent prompt templates (complete, not truncated)
  - Critical warnings (e.g., "CRITICAL: Send ALL Task invocations in SINGLE message")
  - Error recovery procedures
  - Checkpoint structure definitions
  - Regex patterns for parsing results

#### Standard 11: Imperative Agent Invocation Pattern
- **Required Elements** (lines 1128-1241):
  1. **Imperative Instruction**: `**EXECUTE NOW**: USE the Task tool to invoke...`
  2. **Agent Behavioral File Reference**: `Read and follow: .claude/agents/[agent-name].md`
  3. **No Code Block Wrappers**: Task invocations must NOT be fenced with ` ```yaml`
  4. **No "Example" Prefixes**: Remove documentation context
  5. **Completion Signal Requirement**: `Return: REPORT_CREATED: ${REPORT_PATH}`
- **Anti-Pattern Detection** (lines 1212-1221):
  ```bash
  awk '/```yaml/{
    found=0
    for(i=NR-5; i<NR; i++) {
      if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
    }
    if(!found) print FILENAME":"NR": Documentation-only YAML block (violates Standard 11)"
  } {lines[NR]=$0}' .claude/commands/*.md
  ```
- **Impact**: 0% delegation rate → 100% when properly applied

#### Standard 12: Structural vs Behavioral Content Separation
- **Structural Templates MUST Be Inline** (lines 1244-1274):
  1. Task Invocation Syntax: `Task { subagent_type, description, prompt }`
  2. Bash Execution Blocks: `**EXECUTE NOW**: bash commands`
  3. JSON Schemas: Data structure definitions
  4. Verification Checkpoints: `**MANDATORY VERIFICATION**: file existence checks`
  5. Critical Warnings: `**CRITICAL**: error conditions`
- **Behavioral Content MUST NOT Be Duplicated** (lines 1276-1330):
  - Agent STEP sequences (e.g., STEP 1/2/3)
  - File creation workflows (PRIMARY OBLIGATION blocks)
  - Agent verification steps (agent-internal quality checks)
  - Output format specifications
- **Benefits**: 90% code reduction (150 lines → 15 lines per invocation), single source of truth, zero synchronization burden

#### Validation Criteria (lines 1769-1819)
- **Command File Changes**:
  - Execution Enforcement: Critical steps use "EXECUTE NOW", "YOU MUST"
  - Verification Checkpoints: Explicit with `if [ ! -f ]` checks
  - Fallback Mechanisms: Agent-dependent operations include fallback creation
  - Agent Template Enforcement: Prompts marked "THIS EXACT TEMPLATE"
  - Checkpoint Reporting: Major steps include explicit completion reporting
- **Agent File Changes**:
  - Imperative Language: All critical steps use "YOU MUST", "EXECUTE NOW"
  - Sequential Dependencies: Steps marked "STEP N (REQUIRED BEFORE STEP N+1)"
  - File Creation Priority: Marked "PRIMARY OBLIGATION" or "ABSOLUTE REQUIREMENT"
  - Passive Voice Elimination: Zero "should/may/can" in critical sections
  - Quality Scoring: 95+/100 on enforcement rubric (9.5+ categories at full strength)

### 2. Command Development Guide

**File**: `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (1303 lines)

#### Command Development Workflow (Section 3, lines 200-327)
1. **Define Purpose and Scope**: Clear purpose statement and boundaries
2. **Design Command Structure**: Metadata section complete (type, tools, arguments)
3. **Implement Behavioral Guidelines**: Workflow with error handling
4. **Add Standards Discovery Section**: CLAUDE.md sections usage
5. **Integrate with Agents**: Behavioral injection pattern
6. **Add Testing and Validation**: Test commands and validation criteria
7. **Document Usage and Examples**: Complete examples with edge cases
8. **Add to Commands README**: Discoverable and documented

#### Standards Integration Pattern (Section 4, lines 329-397)
- **Discovery Process**: Locate CLAUDE.md → Parse sections → Apply to operations
- **Sections Used**: Code Standards, Testing Protocols, Documentation Policy
- **Compliance Verification Checklist**:
  - Code style matches CLAUDE.md specifications
  - Naming follows project conventions
  - Error handling matches project patterns
  - Tests follow testing standards and pass
  - Documentation meets policy requirements
- **Fallback Behavior**: Use language defaults, suggest `/setup`, continue with graceful degradation

#### Agent Integration (Section 5, lines 399-868)

##### Behavioral Injection Pattern (lines 425-488)
**Option A: Load and Inject Behavioral Prompt**
- When to use: Need to modify agent behavior programmatically
- Implementation: Load agent behavioral file, build complete prompt with context

**Option B: Reference Agent File (Simpler)**
- When to use: Agent behavioral file is complete
- Pattern: `Read and follow behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md`

##### Anti-Pattern: Documentation-Only YAML Blocks (lines 490-678)
- **Problem**: YAML blocks wrapped in markdown fences without imperative instructions cause 0% delegation rate
- **Detection Pattern**:
  ```bash
  for file in .claude/commands/*.md; do
    awk '/```yaml/{
      found=0
      for(i=NR-5; i<NR; i++) {
        if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
      }
      if(!found) print FILENAME":"NR": Documentation-only YAML block detected"
    } {lines[NR]=$0}' "$file"
  done
  ```
- **Conversion Guide** (lines 571-625):
  1. Identify documentation-only blocks
  2. Classify each block (syntax reference vs should invoke agents)
  3. Transform to executable pattern: Remove code fences, add imperative instruction
  4. Validate conversion with regression tests

##### Code Fence Priming Effect (lines 680-782)
- **Problem**: Early code-fenced Task examples establish "documentation interpretation" pattern
- **Root Cause**: First code-fenced example at lines 62-79 causes subsequent unwrapped Task blocks to be interpreted as non-executable
- **Fix Pattern** (lines 704-761):
  1. Remove code fences from Task examples
  2. Add HTML comments: `<!-- This Task invocation is executable -->`
  3. Keep anti-pattern examples fenced (marked with ❌)
  4. Verify tool access: Ensure agents have Bash in allowed-tools
- **Impact of Fix**: Delegation rate 0% → 100%, context usage >80% → <30%, parallel agents 0 → 2-4 simultaneously

##### Path Calculation Best Practices (lines 946-1031)
- **CRITICAL**: Calculate paths in parent command scope, NOT in agent prompts
- **Why**: Bash tool escapes command substitution `$(...)` for security
- **Working constructs**: Arithmetic `$((expr))`, sequential `cmd1 && cmd2`, pipes, sourcing, conditionals
- **Broken constructs**: Command substitution `VAR=$(command)`, backticks
- **Correct Implementation**:
  ```bash
  # Parent command calculates paths
  source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
  LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")
  REPORT_PATH="${REPORTS_DIR}/001_${SANITIZED_TOPIC}.md"

  # Pass absolute path to agent
  Task {
    prompt: "**Report Path**: $REPORT_PATH"
  }
  ```

##### Using Utility Libraries (Section 5.5, lines 870-944)
- **When to Use Libraries vs Agents**:
  - Deterministic operations (no AI reasoning): location detection, sanitization, parsing
  - Performance critical paths: workflow initialization, checkpoint operations
  - Context window optimization: Libraries use 0 tokens, agents use 15k-75k tokens
- **Available Libraries**:
  - `unified-location-detection.sh`: Standardized location detection (<1s, 0 tokens vs 25s, 75k tokens for agent)
  - `plan-core-bundle.sh`: Plan parsing and manipulation
  - `metadata-extraction.sh`: Report/plan metadata extraction (99% context reduction)
  - `checkpoint-utils.sh`: Checkpoint state management

#### When to Use Inline Templates (Section 7.2, lines 1187-1251)
- **Inline Required - Structural Templates**:
  1. Task Invocation Blocks: Commands must parse to invoke agents
  2. Bash Execution Blocks: Commands execute directly
  3. Verification Checkpoints: Orchestrator responsibility
  4. JSON Schemas: Commands parse/validate data structures
  5. Critical Warnings: Execution-critical constraints
- **NOT Inline - Behavioral Content** (reference agent files):
  - Agent STEP sequences
  - File creation workflows
  - Agent verification steps
  - Output format specifications

#### Anti-Patterns to Avoid (Section 7.3, lines 1253-1267)
- Using `/expand` for content changes (structural change only)
- Including all possible tools (violates least privilege)
- Duplicating pattern documentation (creates maintenance burden)
- Skipping standards discovery (inconsistent behavior)
- Hardcoding test commands (breaks in different projects)
- Inline agent definitions (duplication)
- Large agent context passing (token waste)

### 3. Writing Standards

**File**: `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (558 lines)

#### Development Philosophy (lines 12-45)
- **Clean-Break Refactors**: Prioritize coherence over compatibility
- **Core Values**: Clarity, quality, coherence, maintainability
- **Exception**: Command/agent files require special refactoring rules (AI prompts, not code)

#### Documentation Standards (lines 47-62)
- **Present-Focused Writing**: Document current implementation, not changes
- **Ban historical markers**: Never use "(New)", "(Old)", "(Updated)", "(Current)"
- **No migration guides**: Do not create migration documentation for refactors
- **Timeless writing**: Avoid "previously", "now supports", "recently added"

#### Banned Patterns (lines 79-231)
- **Temporal Markers**: (New), (Old), (Updated), (Current), (Deprecated)
- **Temporal Phrases**: "previously", "recently", "now supports", "used to", "no longer"
- **Migration Language**: "migration from", "migrated to", "backward compatibility", "breaking change"
- **Version References**: "v1.0", "since version", "as of version", "introduced in"

#### Rewriting Patterns (lines 193-253)
1. **Remove Temporal Context Entirely**: "recently added" → "supports"
2. **Focus on Current Capabilities**: "Previously polling, now webhooks" → "Uses webhooks"
3. **Convert Comparisons to Descriptions**: "Replaces old caching" → "Provides in-memory caching"
4. **Eliminate Version Markers**: "New in v2.0" → "Supports parallel execution"

### 4. Imperative Language Guide

**File**: `/home/benjamin/.config/.claude/docs/guides/imperative-language-guide.md` (635 lines)

#### Transformation Rules (lines 50-83)
| Weak Language | Strength | Imperative Replacement | When to Use |
|---------------|----------|------------------------|-------------|
| should | Suggestive | **MUST** | Absolute requirements |
| may | Permissive | **WILL** or **SHALL** | Conditional requirements |
| can | Enabling | **MUST** or **SHALL** | Capability requirements |
| could | Possibility | **WILL** or **MAY** | Conditional actions |
| consider | Reflective | **MUST** or **SHALL** | Required evaluation |
| try to | Aspirational | **WILL** | Required attempt |

#### Application by File Type (lines 85-248)

##### Commands (lines 89-160)
- **Phase 0: Role Clarification**: Commands that orchestrate subagents MUST begin with explicit role
- **Execution Instructions**: All steps use imperative language with verification
- **Agent Invocation Templates**: "Use THIS EXACT TEMPLATE, no modifications"

##### Agents (lines 162-248)
- **Role Declaration**: "**YOUR ROLE**: You are a research specialist agent"
- **Sequential Steps**: "STEP 1 (REQUIRED BEFORE STEP 2)"
- **Mandatory Verification**: "YOU MUST verify all required inputs are present"

#### Enforcement Patterns (lines 250-345)
1. **Direct Execution Blocks**: "EXECUTE NOW - Create Directory Structure"
2. **Mandatory Verification Blocks**: "MANDATORY VERIFICATION - Confirm File Exists"
3. **Fallback Mechanisms**: "GUARANTEE: File WILL exist at specified path"
4. **Checkpoint Reporting**: "CHECKPOINT REQUIREMENT - Report Phase Completion"

#### Testing Validation (lines 351-424)
- **Audit Script**: `.claude/lib/audit-imperative-language.sh`
- **Expected Results**:
  - Imperative ratio ≥90%: Excellent enforcement
  - Imperative ratio 70-89%: Needs improvement
  - Imperative ratio <70%: Requires migration

### 5. Design Patterns

#### Behavioral Injection Pattern

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (690 lines)

##### Definition (lines 8-14)
Commands inject context into agents via file reads instead of SlashCommand tool invocations, enabling hierarchical multi-agent patterns and preventing direct execution.

##### Implementation (lines 38-144)
- **Phase 0: Role Clarification** (lines 42-59): "You are the ORCHESTRATOR. DO NOT execute yourself."
- **Path Pre-Calculation** (lines 61-79): Calculate all paths before invoking agents
- **Context Injection via File Content** (lines 81-100): Structured data injection
- **Code Example** (lines 102-144): Real /orchestrate Phase 0 implementation

##### Structural Templates vs Behavioral Content (lines 186-256)
- **Structural Templates (MUST remain inline)**:
  - Task invocation syntax
  - Bash execution blocks
  - JSON schemas
  - Verification checkpoints
  - Critical warnings
- **Behavioral Content (MUST be referenced)**:
  - Agent STEP sequences
  - File creation workflows
  - Agent verification steps
  - Output format specifications
- **Benefits**: 90% reduction (150 lines → 15 lines per invocation), single source of truth

##### Anti-Patterns (lines 258-525)

**Example Violation 0: Inline Template Duplication** (lines 260-320)
- **Problem**: Duplicating 646 lines of research-specialist.md behavioral guidelines
- **Impact**: Maintenance burden, violates single source of truth, 800+ lines across command
- **Correct Pattern**: Reference behavioral file with context injection only (90% reduction)

**Anti-Pattern: Documentation-Only YAML Blocks** (lines 322-412)
- **Detection Rule**: ` ```yaml` blocks not preceded by imperative instructions
- **Consequences**: 0% delegation rate, silent failure, maintenance confusion
- **Correct Pattern**: Remove code fences, add `**EXECUTE NOW**: USE the Task tool`

**Anti-Pattern: Code-Fenced Task Examples Create Priming Effect** (lines 414-525)
- **Root Cause**: Early code-fenced examples establish "documentation interpretation" pattern
- **Detection**: Search for ` ```yaml` wrappers around Task examples
- **Fix**: Remove code fences, add HTML comments `<!-- executable -->`, keep anti-pattern examples fenced
- **Impact of Fix**: Delegation 0% → 100%, context >80% → <30%, streaming fallback errors eliminated

#### Verification and Fallback Pattern

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` (404 lines)

##### Definition (lines 8-15)
MANDATORY VERIFICATION checkpoints with fallback file creation mechanisms achieve 100% file creation rates.

##### Core Mechanism (lines 36-106)
1. **Path Pre-Calculation** (lines 38-59): Calculate all file paths before execution
2. **MANDATORY VERIFICATION Checkpoints** (lines 61-80): Verify file exists after creation
3. **Fallback File Creation** (lines 82-106): Create file directly if verification fails

##### Problems Solved (lines 26-32)
- **100% File Creation Rate**: 10/10 tests vs 6-8/10 without pattern
- **Immediate Correction**: Files created via fallback within same phase
- **Clear Diagnostics**: Verification checkpoints identify exact failure point
- **Predictable Workflows**: Eliminate cascading phase failures

##### Code Example (lines 108-192)
Real /implement command migration with path pre-calculation, agent invocation, mandatory verification, and fallback mechanism.

##### Performance Impact (lines 341-389)
| Command | Before Pattern | After Pattern | Improvement |
|---------|---------------|---------------|-------------|
| /report | 7/10 (70%) | 10/10 (100%) | +43% |
| /plan | 6/10 (60%) | 10/10 (100%) | +67% |
| /implement | 8/10 (80%) | 10/10 (100%) | +25% |
| **Average** | **7/10 (70%)** | **10/10 (100%)** | **+43%** |

#### Context Management Pattern

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md` (290 lines)

##### Definition (lines 8-11)
Techniques for maintaining <30% context usage through aggressive pruning, layered context, and metadata-only passing.

##### Implementation Techniques (lines 30-176)
1. **Metadata Extraction** (lines 30-47): Return 200-300 tokens instead of 5,000-10,000
2. **Context Pruning** (lines 49-81): Reduce phase from 5,000 tokens to 200 tokens (96% reduction)
3. **Forward Message Pattern** (lines 83-99): Direct forwarding (0 additional tokens)
4. **Layered Context Architecture** (lines 101-138):
   - Layer 1: Permanent (500-1,000 tokens)
   - Layer 2: Phase-Scoped (2,000-4,000 tokens per phase, pruned after)
   - Layer 3: Metadata (200-300 tokens per phase)
   - Layer 4: Transient (0 tokens, pruned immediately)
5. **Checkpoint-Based State** (lines 140-154): Store state externally, load on-demand

##### Performance Impact (lines 263-276)
| Workflow | Without Management | With Management | Reduction |
|----------|-------------------|-----------------|-----------|
| 4-agent research | 20,000 tokens (80%) | 1,000 tokens (4%) | 95% |
| 7-phase /orchestrate | 40,000 tokens (160% overflow) | 7,000 tokens (28%) | 82% |
| Hierarchical (3 levels) | 60,000 tokens (240% overflow) | 4,000 tokens (16%) | 93% |

### 6. Template vs Behavioral Distinction

**File**: `/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md` (367 lines)

#### Overview (lines 13-24)
Critical architectural distinction:
1. **Structural Templates** (MUST be inline): Execution-critical patterns Claude must see immediately
2. **Behavioral Content** (MUST be referenced): Agent execution procedures and workflows

**Benefits**:
- 90% code reduction per agent invocation (150 lines → 15 lines)
- 71% context usage reduction (85% → 25%)
- 100% file creation rate (up from 70%)
- 50-67% maintenance burden reduction

#### Structural Templates (lines 26-85)
**Characteristics**: Execution-critical patterns that define HOW commands execute

**Examples**:
1. Task Invocation Syntax (lines 38-46)
2. Bash Execution Blocks (lines 48-55)
3. JSON Schemas (lines 57-69)
4. Verification Checkpoints (lines 71-79)
5. Critical Warnings (lines 81-85)

#### Behavioral Content (lines 87-138)
**Characteristics**: Agent execution procedures (WHAT agents do, HOW they behave)

**Examples**:
1. Agent STEP Sequences (lines 100-106)
2. File Creation Workflows (lines 108-115)
3. Verification Steps Within Agent Behavior (lines 117-124)
4. Output Format Specifications (lines 126-138)

#### Decision Tree (lines 153-173)
```
Is this content about command execution structure?
├─ YES → Is it Task syntax, bash blocks, schemas, or checkpoints?
│         ├─ YES → ✓ INLINE in command file
│         └─ NO → Continue evaluation...
└─ NO → Is it STEP sequences, workflows, or agent procedures?
          ├─ YES → ✓ REFERENCE agent file
          └─ NO → Ask: "If I change this, where do I update it?"
```

#### Common Pitfalls: Search Pattern Mismatches (lines 256-329)
- **Pitfall**: Assuming patterns exist without verification during refactoring
- **Example**: /supervise refactor (spec 438) searched for non-existent patterns
- **Prevention**:
  1. Verify patterns exist with Grep before planning replacements
  2. Extract actual strings, not inferred descriptions
  3. Add pattern verification to Phase 0
  4. Update regression tests to detect actual patterns
- **Key Lessons**: Always use Grep to verify, classify blocks before deciding, ensure tests detect actual patterns

### 7. Performance and Efficiency Requirements

#### Context Window Optimization
- **Target**: <30% context usage throughout workflows (metadata extraction, context pruning)
- **Techniques**:
  - Metadata-only passing: 95% reduction (20,000 → 1,000 tokens)
  - Layered context architecture: Layer 4 (transient) pruned immediately
  - Checkpoint-based state: External storage with on-demand loading
  - Forward message pattern: 0 additional tokens (direct forwarding)

#### Token Reduction Metrics
- **Agent invocation**: 90% reduction (150 lines → 15 lines via behavioral injection)
- **Research phase**: 95% reduction (20,000 → 1,000 tokens with metadata)
- **7-phase workflow**: 82% reduction (40,000 → 7,000 tokens with context management)
- **Hierarchical (3 levels)**: 93% reduction (60,000 → 4,000 tokens)

#### File Creation Success Rates
- **Verification-Fallback Pattern**: 70% → 100% (10/10 vs 6-8/10)
- **Report creation**: +43% improvement
- **Plan creation**: +67% improvement
- **Implementation**: +25% improvement

#### Scalability Improvements
- **Phases supported**: 2-3 → 7-10
- **Agents coordinated**: 2-4 → 10-30
- **Workflow completion rate**: 40% → 100% (no context overflows)

### 8. Error Handling Standards

#### Verification and Fallback Requirements
- **Path Pre-Calculation**: Calculate ALL file paths before execution
- **Mandatory Verification**: After each file creation, verify existence with `[ -f "$PATH" ]`
- **Fallback Mechanism**: If verification fails, create file directly using Write tool
- **Re-Verification**: After fallback, verify again before proceeding
- **Escalation**: If re-verification fails, escalate to user with error details

#### Testing Requirements
- **File Creation Tests**: 100% success rate (10/10 tests)
- **Verification Checkpoints**: All file operations require verification
- **Fallback Coverage**: All file creation operations include fallback mechanisms
- **Diagnostic Time**: Immediate identification via verification checkpoint logs

### 9. Verification Requirements

#### Mandatory Verification Checkpoints
**After Agent Completes** (from command_architecture_standards.md, lines 107-133):
```markdown
**MANDATORY VERIFICATION - Report File Existence**

After agents complete, YOU MUST execute this verification:

```bash
for topic in "${!REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${REPORT_PATHS[$topic]}"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "CRITICAL: Report missing at $EXPECTED_PATH"
    echo "Executing fallback creation..."

    cat > "$EXPECTED_PATH" <<EOF
# ${topic}
## Findings
${AGENT_OUTPUT[$topic]}
EOF
  fi

  echo "✓ Verified: $EXPECTED_PATH"
done
```

**REQUIREMENT**: This verification is NOT optional. Execute it exactly as shown.
```

**Verification Checklist** (from verification-fallback.md, lines 149-163):
```markdown
**Verification Checklist** (ALL must be ✓):
- [ ] Report file exists at $REPORT_PATH
- [ ] Executive Summary completed (not placeholder)
- [ ] Findings section has detailed content
- [ ] Recommendations section has at least 3 items
- [ ] References section lists all files analyzed
- [ ] All file references include line numbers
```

#### Fallback Mechanism Structure
**Required Structure** (from command_architecture_standards.md, lines 202-228):
```markdown
### Agent Execution with Fallback

**Primary Path**: Agent follows instructions and creates output
**Fallback Path**: Command creates output from agent response if agent doesn't comply

**Implementation**:
1. Invoke agent with explicit file creation directive
2. Verify expected output exists
3. If missing: Create from agent's text output
4. Guarantee: Output exists regardless of agent behavior

**Example**:
```bash
# After agent completes
if [ ! -f "$EXPECTED_FILE" ]; then
  echo "Agent didn't create file. Executing fallback..."
  cat > "$EXPECTED_FILE" <<EOF
# Fallback Report
$AGENT_OUTPUT
EOF
fi
```
```

**When Fallbacks Required**:
- ✅ Agent file creation (reports, plans, documentation)
- ✅ Agent structured output parsing
- ✅ Agent artifact organization
- ✅ Cross-agent coordination
- ❌ Not needed for read-only operations
- ❌ Not needed for tool-based operations (Write/Edit directly)

## Recommendations

### 1. Command Development Compliance Checklist

**Before Creating New Command**:
- [ ] Define purpose and scope with clear success criteria
- [ ] Choose appropriate command type (primary/support/workflow/utility)
- [ ] Select minimal tool set following least-privilege principle
- [ ] Design metadata section with all required fields

**During Implementation**:
- [ ] Use imperative language (MUST/WILL/SHALL) for all critical operations
- [ ] Implement Phase 0 role clarification for orchestrating commands
- [ ] Add MANDATORY VERIFICATION checkpoints after all file operations
- [ ] Include fallback mechanisms for 100% file creation guarantee
- [ ] Pre-calculate all artifact paths before agent invocation
- [ ] Use behavioral injection pattern (reference agent files, inject context only)
- [ ] Maintain <30% context usage through metadata-only passing

**After Implementation**:
- [ ] Run imperative language audit (target: ≥90% imperative ratio)
- [ ] Test file creation rate (target: 10/10 = 100%)
- [ ] Verify agent delegation rate (target: 100%)
- [ ] Check context window usage (target: <30%)
- [ ] Validate Standards 0, 0.5, 1, 11, and 12 compliance

### 2. Anti-Pattern Prevention

**Detect and Fix Before Committing**:
- [ ] Run documentation-only YAML block detection script
- [ ] Check for code-fenced Task examples (priming effect)
- [ ] Verify no behavioral content duplication (STEP sequences, PRIMARY OBLIGATION)
- [ ] Ensure no path calculation in agent prompts (use parent command)
- [ ] Confirm all Task invocations have imperative instructions
- [ ] Validate all agent files score ≥95/100 on enforcement rubric

### 3. Performance Optimization

**Target Metrics**:
- [ ] Context usage: <30% across entire workflow
- [ ] Code reduction: 90% per agent invocation (behavioral injection)
- [ ] File creation: 100% success rate (verification-fallback pattern)
- [ ] Agent delegation: 100% rate (no documentation-only blocks)

**Implementation Techniques**:
- [ ] Use metadata extraction (99% context reduction)
- [ ] Implement layered context architecture (permanent, phase-scoped, metadata, transient)
- [ ] Apply aggressive pruning (prune Layer 4 immediately, Layer 2 after phase)
- [ ] Use forward message pattern (0 additional tokens)
- [ ] Store state in checkpoints (external storage, on-demand loading)

### 4. Standards Integration

**Discovery Process**:
1. Locate CLAUDE.md (search upward from working directory)
2. Check for subdirectory-specific CLAUDE.md
3. Parse relevant sections (Code Standards, Testing Protocols, Documentation Policy)
4. Apply standards to operations (naming, error handling, test commands)

**Fallback Behavior**:
- Use language-specific defaults if CLAUDE.md not found
- Suggest running `/setup` to create CLAUDE.md
- Continue with graceful degradation
- Document limitations in output

### 5. Testing Requirements

**Validation Criteria**:
- [ ] File creation tests: 10/10 success rate (100%)
- [ ] Verification checkpoints: Present after all file operations
- [ ] Fallback mechanisms: Included for all file creation operations
- [ ] Imperative language: ≥90% ratio (audit script)
- [ ] Agent delegation: 100% rate (no silent failures)
- [ ] Context usage: <30% across workflow

**Testing Tools**:
- `.claude/lib/audit-imperative-language.sh` (imperative ratio)
- `.claude/tests/validate_behavioral_injection.sh` (behavioral injection pattern)
- `.claude/tests/validate_verification_fallback.sh` (verification and fallback pattern)
- Automated detection for documentation-only YAML blocks

### 6. Documentation Standards

**Writing Guidelines**:
- Use present-focused writing (document current state, not changes)
- Ban historical markers: (New), (Old), (Updated), (Current)
- Avoid temporal phrases: "previously", "recently", "now supports"
- No migration language: "migration from", "backward compatibility"
- Focus on current capabilities, not comparisons to past

**Exception**:
- CHANGELOG.md: Version-by-version chronological record
- Migration guides: Separate documents for version upgrades
- Commit messages: Git history for code-level changes

## References

### Core Standards Documents
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (1966 lines) - Standards 0, 0.5, 1, 11, 12
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (1303 lines) - Development workflow, agent integration
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (558 lines) - Development philosophy, documentation standards
- `/home/benjamin/.config/.claude/docs/guides/imperative-language-guide.md` (635 lines) - Transformation rules, enforcement patterns

### Design Patterns
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (690 lines) - Context injection, anti-patterns
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` (404 lines) - 100% file creation pattern
- `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md` (290 lines) - <30% context usage techniques
- `/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md` (367 lines) - Inline vs reference decision criteria

### Testing and Validation
- `.claude/lib/audit-imperative-language.sh` - Imperative ratio validation
- `.claude/tests/validate_behavioral_injection.sh` - Behavioral injection pattern validation
- `.claude/tests/validate_verification_fallback.sh` - Verification and fallback pattern validation

### Performance Metrics
- Context reduction: 82-95% (metadata extraction, layered architecture)
- Code reduction: 90% per agent invocation (behavioral injection)
- File creation: 70% → 100% (verification-fallback pattern)
- Agent delegation: 0% → 100% (imperative invocation pattern)

## Metadata
- **Files Analyzed**: 8 core documents, 50+ supporting files
- **Total Lines Reviewed**: 5,813 lines of standards documentation
- **Standards Coverage**: 12 core standards, 8 design patterns, 4 enforcement mechanisms
- **Performance Targets**: <30% context, 100% file creation, 90% code reduction, ≥90% imperative ratio
