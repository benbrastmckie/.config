> /coordinate is running… "Research how exactly the workflow is identified 
in the coordinate command and how research topics are identified and passed
 to the research subagents (when relevant). I am specifically concerned how
 research file names are chosen, and how the prompts are constructed for 
those research subagents." 
  ⎿  Allowed 4 tools for this command

● I'll research how the /coordinate command identifies workflows and
  constructs research prompts for subagents.

● Let me examine the workflow identification and research topic
  handling in /coordinate:

● Read(.claude/lib/workflow-state-machine.sh)
  ⎿  Read 850 lines

● Read(.claude/lib/workflow-scope-detection.sh)
  ⎿  Read 293 lines

● Read(.claude/lib/workflow-llm-classifier.sh)
  ⎿  Read 438 lines

● Now let me examine how research file names are chosen and how prompts
   are constructed:

● Read(.claude/lib/workflow-initialization.sh)
  ⎿  Read 300 lines

● Read(.claude/agents/research-specialist.md)
  ⎿  Read 200 lines

● Read(.claude/lib/workflow-initialization.sh)
  ⎿  Read 200 lines

● Perfect! Now let me look at how the research file names are actually
  used and how the prompts are constructed in the coordinate command
  itself:

● Search(pattern: "RESEARCH_TOPIC_", path:
        ".claude/commands/coordinate.md", output_mode: "content")
  ⎿  Found 41 lines (ctrl+o to expand)

● Search(pattern: "Research Topic:", path:
        ".claude/commands/coordinate.md", output_mode: "content")
  ⎿  Found 67 lines (ctrl+o to expand)
