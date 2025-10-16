# Improve Research Phase

## Problem

I just ran the `/orchestrate` command and got the following:

```consol
> /orchestrate is running… review .claude/ in full in order 
to identify bloat or redundant commands/agents/scripts that 
can be removed as well as any other inefficiencies or 
potential improvements to be made in order to provide a 
clean, clear, and efficient workflow, creating detailed 
reports and an implementation plan to revise any 
shortcomings without substantial lose of high value 
functionality 
  ⎿  Allowed 7 tools for this command

● I'll orchestrate a comprehensive review of the
  .claude/ directory to identify bloat, redundancy, and
  optimization opportunities, then create detailed
  reports and an implementation plan.

● Phase 1: Research Phase (Parallel Execution)

  I'll launch 4 specialized research agents in parallel
  to comprehensively analyze the .claude/ directory:

  1. Directory Structure & Inventory Analysis
  2. Redundancy & Unused Component Detection
  3. Code Quality & Efficiency Analysis
  4. High-Value Functionality Documentation

● Task(Analyze .claude/ directory structure)
  ⎿  Done (26 tool uses · 47.9k tokens · 1m 44s)       

● Task(Identify redundant/unused components)
  ⎿  Done (48 tool uses · 61.5k tokens · 1m 56s)       

● Task(Analyze code quality issues)
  ⎿  Done (20 tool uses · 100.8k tokens · 1m 15s)      

● Task(Document high-value functionality)
  ⎿  Done (18 tool uses · 79.7k tokens · 1m 32s)       

> I also want to identify any commands/agents/etc that 
can be simplified to avoid better preserve the context 

> I don't want to give up any critical functionality 

● Perfect! I'll incorporate those requirements into the
  research. Let me complete the research phase and
  update the todo list.

● Excellent! I understand your priorities:
  1. Preserve critical functionality - no loss of
  high-value features
  2. Simplify for context preservation - identify
  commands/agents/scripts that can be streamlined to
  reduce context usage
  3. Remove bloat - eliminate redundancy and unused
  components

  Let me add one more focused research task to analyze
  context preservation opportunities:

● Task(Analyze context preservation opportunities)
  ⎿  Done (16 tool uses · 124.3k tokens · 1m 5s)                      

● Phase 2: Planning Phase

  Perfect! All research is complete. Now I'll synthesize the findings
  into comprehensive reports and an implementation plan using the
  /report and /plan commands.

... (various tasks take place) ...

● Now let me create a comprehensive but more concise report to preserve context. I'll generate the complete report in a single, well-structured Write operation:
```

CURRENT EXECUTION: After conducting research with separate research agents, claude code created a single report by calling the `/report` command.

DESIRED EXECUTION: I want each research subagent to create a report in `{project}/specs/reports/{NNN_topic}/NNN_report_name.md`. I then want references to these reports to be passed to the planning agent along with the instruction to read the reports and create a plan fitting the specific aims provided by the user and any other relevant context.

## Research

1. Review the current implementation and what would be required to implement the alternative DESIRED EXECUTION given above
2. Conduct research online to review best practices for gathering research, creating reports, and using those reports to create detailed implementation plans
3. Compare a range of relevant alternative implementations, providing analyses of their advantages and costs

