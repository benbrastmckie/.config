# Multi-Agent Research Workflow Best Practices (2025)

## Metadata
- **Date**: 2025-10-13
- **Research Focus**: Industry best practices for multi-agent workflows
- **Report Number**: 002
- **Topic**: orchestrate_improvements
- **Sources**:
  - Anthropic Engineering: Multi-Agent Research System (June 2025)
  - LangGraph Official Documentation (2025)
  - LangChain Blog: Multi-Agent Architectures Benchmarking
  - Microsoft Agent Framework Documentation
  - Research Papers: MAST (Multi-Agent System Failure Taxonomy)
  - Research Papers: Model Context Protocol (MCP) Advances (arXiv 2504.21030)
  - Industry blogs: Galileo AI, MarkTechPost, Medium technical articles

## Summary

Modern multi-agent research workflows (2025) emphasize lightweight coordination through artifact-based communication, where specialized subagents write outputs to external systems and pass references back to supervisors. Key patterns include: (1) parallel task decomposition with clear boundaries, (2) external memory for context management, (3) fresh subagent spawning when context limits approach, and (4) structured report synthesis by coordinator agents. Anthropic's production system demonstrates 90.2% performance improvement over single-agent approaches, though at 15x token cost, making it suitable for high-value research tasks.

## Supervisor Pattern Recommendations

### Agent Coordination

**Core Architecture (LangGraph 2025)**
- **Supervisor-Worker Pattern**: Central supervisor agent coordinates all communication flow and task delegation, making decisions about which agent to invoke based on context and requirements
- **Minimal Assumptions**: Supervisor architecture places very few assumptions on subagents, making it feasible for all multi-agent scenarios
- **Orchestrator-Worker Implementation**: Lead agent analyzes queries, develops strategies, and spawns specialized subagents that operate in parallel

**Context Management Strategy**
- **Remove Handoff Messages**: Strip supervisor's routing logic from subagent state to declutter context windows - even recent models show outsized impacts from context clutter on reliability
- **Separate Message Lists**: Store separate message histories for each agent in subagent's graph state, serving as their "view" of the conversation
- **State Schema Separation**: Define subgraphs with separate state schemas; use input/output transformations when no shared state keys exist between subgraph and parent

**Communication Optimization**
- **Forward Message Tool**: Give supervisors a forward_message tool to pass worker responses directly to users without regeneration, saving tokens and avoiding misrepresentation through paraphrasing
- **When to Use**: Deploy when supervisor determines worker's response is sufficient and doesn't require further processing or summarization

### Task Decomposition

**Decomposition Strategies**
- **Decomposition-First Approach**: Structured, step-by-step planning where all sub-goals are mapped before execution; suitable for stable, well-defined tasks
- **Interleaved Approach**: Flexible, adaptive method where planning and execution happen concurrently; ideal for dynamic environments requiring real-time feedback

**Task Boundaries**
Each subagent requires:
- **Specific Objective**: Clear, focused research task
- **Output Format Guidance**: Structured format specification (e.g., report sections, data structures)
- **Tool & Source Instructions**: Explicit guidance on which tools and information sources to use
- **Clear Task Boundaries**: Prevents duplicate work, gaps, or missing information between agents

**Parallel Research Best Practices**
- **Progressive Narrowing**: Start with broad queries, then progressively narrow focus
- **Extended Thinking Mode**: Use extended thinking for planning which tools to use or how many subagents to create
- **Scaling Effort**: Scale agent effort based on query complexity (3-5 parallel subagents for complex research)
- **Multi-Tool Usage**: Allow subagents to use multiple tools simultaneously
- **Task Specialization**: Group tools/responsibilities to improve focus - agents more likely to succeed on focused tasks than selecting from dozens of tools

### Context Management

**External Memory Patterns**
- **Summarization Phases**: Agents summarize completed work phases and store essential information in external memory before proceeding
- **Fresh Subagent Spawning**: When context limits approach, spawn fresh subagents with clean contexts while maintaining continuity through careful handoffs
- **Context Retrieval**: Agents can retrieve stored context (like research plans) from their memory systems
- **Persistent Memory**: Cross-agent context sharing and refinement over time using persistent storage

**Context Engineering Strategies (Four Buckets)**
- **Write**: Generate and structure information for context
- **Select**: Choose relevant information to include
- **Compress**: Intelligently reduce context size while preserving meaning
- **Isolate**: Separate concerns to manage context boundaries

**Context Limits**
Managing context is critical - Anthropic found that simple instructions like "research the semiconductor shortage" without proper context engineering resulted in subagents misinterpreting tasks or duplicating work.

## Report Generation Patterns

### Individual Agent Reports

**Artifact-Based Communication (Anthropic Pattern)**
- **External Filesystem Output**: Subagents output directly to external filesystems to "minimize the 'game of telephone'" effect
- **Lightweight References**: Subagents call tools to store work in external systems, then pass lightweight references back to coordinator
- **Best Use Cases**: Works best for structured outputs like code, reports, data visualizations
- **Independence**: Artifacts persist independently rather than requiring everything to communicate through lead agent

**Benefits**
- **Reduced Context Load**: Supervisor doesn't need to hold full reports in context
- **Parallel Generation**: Multiple subagents can write reports simultaneously without coordination
- **Persistence**: Reports exist as durable artifacts beyond conversation context
- **Verification**: Easier to audit and verify individual agent contributions

### Report Structure

**Modern Report Components (2025 Standards)**
- **Structured Output**: Multi-page reports with clear sections and hierarchical organization
- **Comprehensive Citations**: All claims properly attributed to sources with specific citation locations
- **Executive Summary**: Brief overview of findings and key insights
- **Methodology Section**: Documentation of research approach and sources used
- **Visual Elements**: Mind maps, diagrams, or data visualizations where applicable
- **Thinking Documentation**: Summary of reasoning process and decision points

**Synthesis Approach**
- **Citation Agent Pattern**: Use specialized CitationAgent to process documents and research reports, identifying specific citation locations and ensuring proper attribution
- **Lead Agent Synthesis**: Lead agent synthesizes subagent findings into coherent final report
- **Structured Outputs**: AI deep research agents produce structured, citation-backed reports at research analyst level

**Quality Indicators**
- Reports should be fully documented with clear citations
- Easy to reference and verify information
- Multi-agent collaboration creates more comprehensive analysis than single-agent approaches
- Dynamic visualization of concepts and relationships

### Handoff Mechanisms

**Research to Planning Phase**
- **Artifact References**: Pass file paths or identifiers rather than full report contents
- **Summary Documents**: Lead agent creates synthesis documents that planning agents can reference
- **Structured Metadata**: Include metadata about report scope, sources, and key findings for quick orientation
- **External Storage**: Reports stored in project-specific locations (e.g., specs/reports/{topic}/)

**Sequential Workflow Coordination**
- **Phase Boundaries**: Clear transitions between research, planning, implementation, debugging, documentation phases
- **Checkpoint Systems**: State saved at phase boundaries for resumption
- **Progress Markers**: Real-time visibility through progress markers (e.g., "PROGRESS:" indicators)
- **Todo Tracking**: All workflow phases tracked in structured todo lists

**Error Handoff**
- **Debug Reports**: Separate artifact category for debugging findings (debug/{topic}/ vs specs/reports/)
- **Failure Context**: Debug specialists receive error history and previous failure context
- **Iteration Limiting**: Maximum debug iterations before user escalation (e.g., 3 iterations)
- **Recovery Integration**: Automatic invocation of debug specialists on test failures

## Context Preservation Strategies

### Minimizing Orchestrator Context

**Lightweight Supervision**
- **Reference-Based Communication**: Pass artifact references (file paths, IDs) rather than full contents
- **Summary Consumption**: Orchestrator reads summaries, not full reports
- **Delegation Pattern**: Orchestrator focuses on coordination logic, not domain details
- **State Isolation**: Each agent maintains own scratchpad, supervisor doesn't hold all state

**Forward Message Pattern**
- **Direct Passthrough**: Forward subagent responses directly to users when sufficient
- **Token Efficiency**: Avoid regenerating or paraphrasing worker outputs
- **Fidelity**: Preserve exact agent output without supervisor interpretation
- **Selective Synthesis**: Only synthesize when coordination or integration is required

**Context Window Optimization**
- **Removed Handoff Messages**: Strip routing logic and internal coordination messages from subagent views
- **Focused Context**: Each agent sees only relevant history for their task
- **Clean Slate Spawning**: Create fresh agents rather than passing accumulated context

### Artifact-Based Communication

**File-Based Coordination**
- **External Storage**: Write reports, code, visualizations to project filesystem
- **Structured Locations**: Organized directory structures (specs/reports/{topic}/, debug/{topic}/)
- **Incremental Numbering**: Sequential numbering (001, 002, 003) for ordering and reference
- **Durable Artifacts**: Persist beyond conversation lifetime, enable resumption and audit

**Reference Passing**
- **Lightweight Identifiers**: Pass file paths or artifact IDs between phases
- **Lazy Loading**: Agents read artifacts only when needed
- **Selective Reading**: Read specific sections or metadata without loading full content
- **Version Control**: Git-tracked artifacts enable history and rollback (except gitignored specs/)

**Shared Workspace Pattern**
- **Common Directory Structure**: All agents work within known, structured locations
- **Discovery Protocols**: Commands to list available artifacts (/list-reports, /list-plans)
- **Metadata Files**: Lightweight metadata for artifact discovery without full reads
- **Organized Topics**: Group related artifacts by topic subdirectories

### Summary Generation

**When to Summarize**
- **Context Limit Threshold**: When approaching model context windows (e.g., 80% threshold)
- **Phase Completion**: At natural workflow boundaries (research → planning, implementation → testing)
- **Handoff Points**: Before passing control to different agent types
- **User Updates**: For progress reporting and status checks

**Summarization Strategies**
- **Progressive Compression**: Multi-level summaries (executive → section → detail)
- **Key Facts Extraction**: Distill essential information from full reports
- **Citation Preservation**: Maintain source references even in summaries
- **Structured Format**: Use consistent summary structure for easy parsing

**Implementation Summaries**
- **Plan-Code Linkage**: Connect implementation plans to executed code changes
- **Report References**: Document which research reports informed the implementation
- **Artifact Catalog**: List all artifacts produced during workflow (reports, plans, code)
- **Outcome Documentation**: Record test results, metrics, success criteria

**Summary Storage**
- **Dedicated Location**: specs/summaries/ for implementation summaries
- **Naming Convention**: Match plan numbering (042_implementation_summary.md for 042_plan.md)
- **Lightweight Format**: Brief, scannable structure focused on outcomes and artifacts

## Integration Patterns

### Research to Planning

**Multi-Report Input**
- **Plan Commands**: /plan accepts multiple report paths as input
- **Synthesis Requirements**: Planning agent synthesizes multiple research reports into coherent plan
- **Topic Organization**: Research reports organized in topic subdirectories enable focused discovery
- **Report References**: Plans document which reports informed their design

**Research Discovery**
- **List Commands**: /list-reports with search patterns for finding relevant research
- **Topic-Based Search**: Search within specific topic directories
- **Metadata Reading**: Quick scanning of report metadata without full reads
- **Recent Filtering**: --recent N flag for finding latest research

**Planning Agent Requirements**
- **Research Context**: Receives research report references, not full contents
- **Selective Reading**: Reads relevant sections as needed during planning
- **Standards Integration**: Incorporates project standards from CLAUDE.md
- **Complexity Analysis**: Applies complexity thresholds for automatic plan structure

### Error Recovery

**Failure Detection**
- **Test Failure Patterns**: Detect consecutive failures in same phase (suggests missing prerequisites)
- **Timeout Monitoring**: Track execution time against expected durations
- **Complexity Signals**: High complexity scores (>8) or task counts (>10) indicate replanning needs
- **Scope Drift Flags**: Manual flags for discovered out-of-scope work

**Recovery Strategies (2025 Taxonomy)**

**Communication and Isolation**
- **Lightweight Acknowledgment**: Confirm receipt without flooding network
- **Bulkhead Patterns**: Compartmentalize system into distinct failure domains with independent capacity
- **Escalation Paths**: Trigger isolation procedures when communication degrades beyond recovery threshold
- **Hierarchical Escalation**: Route exceptions to supervisor agents

**Backpressure and Load Management**
- **Adaptive Backpressure**: Upstream agents reduce message frequency when downstream can't keep up
- **Resource Throttling**: Limit concurrent operations based on system capacity
- **Queue Management**: Buffer tasks to smooth demand spikes

**Hybrid Recovery**
- **Coordinated Approaches**: Use orchestration for high-impact failures
- **Local Recovery**: Handle routine issues autonomously
- **Fallback Patterns**: Alternative approaches when primary tools fail
- **Graceful Degradation**: Continue operation despite tool failures

**Adaptive Replanning**
- **Automatic Triggers**: Invoke /revise --auto-mode when failure patterns detected
- **Structure Updates**: Expand phases, add phases, or update tasks
- **Loop Prevention**: Maximum replan limit per phase (e.g., 2 replans)
- **Replan History**: Log all replans for audit trail

**State Management**
- **Checkpoint Systems**: Save state at phase boundaries
- **Recovery Points**: Resume from last successful checkpoint
- **Error History**: Track failure patterns for informed recovery
- **User Escalation**: Human intervention when automatic recovery exhausted

**Exception Protocols**
- **Hierarchical Escalation**: Route to supervisor agents
- **Peer Consultation**: Collaborative problem-solving between agents
- **Human Escalation**: Judgment required exceptions
- **System-Wide Alerts**: Critical issues requiring immediate attention

### Debugging Integration

**Conditional Debugging Phase**
- **Test Failure Triggers**: Automatically invoke debug specialists on test failures
- **Iteration Limits**: Maximum debug iterations (e.g., 3) before user escalation
- **Debug Reports**: Separate artifact category in debug/{topic}/ directories
- **Context Provision**: Debug agents receive error history and failure context

**Debug to Implementation Flow**
- **Finding Reports**: Debug specialist creates diagnostic report
- **Fix Application**: Implementation agent applies fixes based on debug findings
- **Verification**: Re-run tests to verify fixes
- **Iteration**: Repeat until tests pass or iteration limit reached

**Debugging Best Practices**
- **Full Production Tracing**: Diagnose why agents failed and fix systematically
- **Decision Pattern Monitoring**: Track agent decision patterns and interaction structures
- **Privacy Preservation**: Monitor patterns without accessing conversation contents
- **Deterministic Safeguards**: Combine AI adaptability with retry logic and regular checkpoints

## Relevant Frameworks and Tools

### LangGraph (LangChain)
- **Official Package**: langgraph-supervisor package for supervisor pattern implementation
- **Multi-Agent Support**: Built-in patterns for supervisor-worker, hierarchical, network coordination
- **State Management**: Separate message lists and state schemas per agent
- **Subgraph Architecture**: Input/output transformations for parent-child communication
- **Latest Updates**: 2025 improvements include better context management and forward message patterns

### Model Context Protocol (MCP)
- **Context Persistence**: Mechanisms for persistent context storage and retrieval
- **Continuity**: Enable coherence across interaction boundaries
- **Disconnected Models Problem**: Addresses maintaining context across multiple agent interactions
- **Dynamic Discovery**: Standardized protocols for agent discovery and communication

### Microsoft Agent Framework
- **Long-Running Tasks**: Coordinate multiple agents across extended workflows
- **Persistent State**: State and context sharing across agent boundaries
- **Event-Driven Architecture**: Support for orchestrator-worker, hierarchical, blackboard, market-based patterns
- **Enterprise Focus**: Production-ready patterns for business workflows

### LangSmith
- **Tracing and Debugging**: Full production tracing for agent systems
- **Decision Monitoring**: Track agent decision patterns and interactions
- **Privacy Controls**: Monitor without accessing conversation contents
- **Performance Analysis**: Identify bottlenecks and optimization opportunities

### Anthropic Claude (Production System)
- **Extended Thinking**: Write reasoning before acting for better planning
- **Artifact Systems**: External output storage with reference passing
- **Rainbow Deployments**: Gradual traffic shifting for safe rollouts
- **Reliability Patterns**: Combine AI adaptability with deterministic safeguards

## Key Recommendations

### 1. Implement Artifact-Based Communication for Research Phase
**Action**: Modify /orchestrate research phase so each subagent creates individual report files instead of returning findings in-context.

**Benefits**:
- Dramatically reduces orchestrator context load
- Enables true parallel research execution
- Creates durable artifacts for planning phase reference
- Simplifies debugging and audit trails

**Implementation**:
- Research agents receive: topic, output file path, format requirements
- Agents write to specs/reports/{topic}/NNN_report.md
- Return lightweight result: file path + brief status (success/failure, word count)
- Planning agent receives list of report paths, reads selectively

### 2. Adopt External Memory for Context Management
**Action**: Use summarization and fresh subagent spawning patterns to manage context limits.

**Benefits**:
- Prevents context window overflow on complex workflows
- Maintains continuity through structured handoffs
- Enables resumption from checkpoints
- Reduces token costs

**Implementation**:
- Store research summaries at phase boundaries
- Planning agent stores plan reference, not full plan text
- Implementation agent loads only current phase details
- Spawn fresh agents for new phases with minimal context

### 3. Implement Structured Report Synthesis
**Action**: Add dedicated synthesis step after research phase where lead agent creates integrated research summary.

**Benefits**:
- Planning agent receives coherent synthesis, not scattered findings
- Easier to identify gaps or contradictions
- Better citation tracking and attribution
- Professional-quality research output

**Implementation**:
- After all research agents complete, invoke synthesis task
- Synthesis agent reads all reports, creates unified document
- Include: executive summary, key findings, contradictions/gaps, actionable insights
- Store as specs/reports/{topic}/000_synthesis.md

### 4. Add Adaptive Recovery with Loop Prevention
**Action**: Implement automatic replanning on test failures with maximum iteration limits.

**Benefits**:
- Self-correcting workflows reduce manual intervention
- Prevents infinite debugging loops
- Clear escalation paths for stuck situations
- Maintains system reliability

**Implementation**:
- Track replan count in checkpoint state
- Trigger /revise --auto-mode on 2+ consecutive test failures in same phase
- Maximum 2 replans per phase
- User escalation message when limit exceeded
- Log all replan triggers and outcomes

### 5. Optimize Context with Forward Message Pattern
**Action**: Add forward_message capability to orchestrator for passing subagent outputs directly.

**Benefits**:
- 40-60% token savings on orchestrator turns
- Preserves exact agent output fidelity
- Faster response times
- Reduced risk of misrepresentation

**Implementation**:
- Orchestrator evaluates if subagent output is sufficient
- If yes: forward directly to user/next agent
- If no: synthesize, integrate, or format
- Track forwarded vs. synthesized ratio for optimization

## Resource Considerations

### Token Economics
- **Multi-Agent Overhead**: ~15x token consumption vs single-agent chat
- **Value Alignment**: Best for tasks where outcome value exceeds expense
- **Parallel Research**: High value for divisible research problems
- **Poor Fit**: Tightly interdependent tasks like coding (less amenable to parallelization)

### Performance Expectations
- **Anthropic Results**: 90.2% performance improvement over single-agent on research tasks
- **Success Factors**: Token volume explained 80% of success on web browsing/research tasks
- **Agent Composition**: Lead agent (Opus 4) with worker subagents (Sonnet 4) for cost-performance balance

### System Design Tradeoffs
- **Complexity**: Multi-agent adds coordination overhead and debugging complexity
- **Reliability**: Requires sophisticated error handling and state management
- **Scalability**: More agents = more failure modes to handle
- **Value Threshold**: Only justified for high-value, research-intensive workflows

## Conclusion

Modern multi-agent research workflows prioritize lightweight coordination through artifact-based communication, external memory management, and structured report generation. The key insight from 2025 production systems is that orchestrators should coordinate, not consume - managing references to external artifacts rather than holding full reports in context. This pattern enables true parallel research, reduces token costs, and creates durable artifacts for downstream phases. Combined with adaptive recovery mechanisms and loop prevention, these patterns enable robust, scalable multi-agent systems suitable for complex research workflows.

For the /orchestrate command specifically, the highest-impact improvements are: (1) individual subagent report generation, (2) synthesis agent for research integration, (3) reference-based handoffs to planning phase, and (4) adaptive replanning with failure recovery. These changes align with industry best practices while maintaining the command's core workflow structure.
