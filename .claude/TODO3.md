# Remove Auto Expansion

- plan /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/080_orchestrate_enhancement.md implemented a refactor of /orchestrate which, after a plan is created, runs the complexity evaluator agent and then expands the phases of the plan if warranted
- I want to simplify /orchestrate to always create a single plan file with explicit instructions that each phase is to have a complexity estimate but without calling the complexity evaluator agent (the planning agent should handle this)
- after a plan is created, if it calls for expansion, I want an option to be presented to the user to expand the plan using the expander agent
- The complexity evaluator agent is still useful and so can be kept, but should not be integrated into the /orchestrate command
- instead, I want the expander agent and the /expand command to both begin by calling the complexity evaluator agent on the relevant plan, expanding the plan if warranted, where the expanded plan files that are created are then evaluated after they are created in order to further expand those files if warranted
- I want to overhaul the phases in /orchestrate to provide a clean and adaptive architecture for research (creating reports with reference links and brief summaries), planning (creating a single plan with complexity estimates and returning a link and brief summary), implementation (updating ALL spec files in the plan hierarchy as progress is made or the context window is running low), testing, debugging loop, and documentation
- the /orchestrate command (as with all commands and agents) should fully comply with the standards set in .claude/docs/
