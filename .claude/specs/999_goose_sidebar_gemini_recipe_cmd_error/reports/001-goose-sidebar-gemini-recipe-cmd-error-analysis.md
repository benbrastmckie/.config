# Goose Sidebar Gemini Recipe Command Error - Root Cause Analysis

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Root cause analysis for Goose sidebar recipe commands not recognized by Gemini
- **Report Type**: debug-focused codebase analysis

## Executive Summary

The root cause is architectural: goose.nvim's recipe picker executes recipes using `/recipe:<name>` syntax that is NOT a Goose CLI command. The picker sends this as user text via `goose run --text "/recipe:<name>"`, which the CLI forwards to the LLM as a literal user prompt. Gemini (and other providers) receive `/recipe:create-plan` as conversational text, not as a recipe invocation command, causing the "I'm not familiar with..." response. Recipe execution requires `goose run --recipe <path>` CLI syntax, not slash command syntax within a session.

## Findings

### Finding 1: Recipe Picker Uses Invalid Slash Command Syntax
- **Description**: The recipe picker in goose.nvim attempts to execute recipes using `/recipe:<name>` syntax sent as text to `goose.core.run()`, which translates to `goose run --text "/recipe:<name>"`. This syntax is NOT a valid Goose CLI recipe invocation method.
- **Location**:
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua:60-71`
  - `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/core.lua:57-97`
  - `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/job.lua:11-29`
- **Evidence**:
  ```lua
  -- execution.lua lines 60-62
  -- Build /recipe:<name> command - Goose will prompt for parameters conversationally
  local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
  local prompt = string.format('/recipe:%s', recipe_name)

  -- core.lua line 63
  job.execute(prompt, {...})

  -- job.lua lines 11-14
  function M.build_args(prompt)
    if not prompt then return nil end
    local message = context.format_message(prompt)
    local args = { "run", "--text", message }
  ```
  The picker creates a string like `/recipe:create-plan` and passes it to `goose.core.run()`, which builds CLI arguments as `goose run --text "/recipe:create-plan"`. This sends the slash command as literal user text to the LLM.
- **Impact**: CRITICAL - Recipe execution fails because the LLM receives `/recipe:<name>` as a conversational prompt, not as a command to execute a recipe file. This is the direct cause of the "I'm not familiar with..." error.

### Finding 2: Gemini-CLI Provider Filters Extension Information from System Prompts
- **Description**: The gemini-cli provider in Goose automatically filters out extension information from system prompts because CLI providers (gemini-cli, claude-code) have their own tool ecosystems. Recipe definitions and slash command documentation are NOT passed to the Gemini API.
- **Location**: Block Goose documentation - [CLI Providers Guide](https://block.github.io/goose/docs/guides/cli-providers/)
- **Evidence**: From web research: "The CLI providers automatically filter out goose's extension information from system prompts since these CLI tools have their own tool ecosystems. This prevents conflicts and ensures clean interaction with the underlying CLI tools. The Gemini CLI provider converts messages to simple text prompts with role prefixes (Human:/Assistant:) rather than using a structured JSON format."
- **Impact**: HIGH - Even if `/recipe:` were a valid in-session slash command (which it's not for `goose run --text`), the gemini-cli provider wouldn't receive recipe context or slash command documentation in the system prompt. The LLM has no knowledge of what `/recipe:` means.

### Finding 3: Recipe Execution Requires CLI --recipe Flag, Not In-Session Slash Commands
- **Description**: Goose CLI recipe execution requires the `--recipe` flag with a file path (`goose run --recipe <path>`), not an in-session slash command. The `/recipe` slash command exists ONLY within interactive sessions (`goose session` or `goose run --interactive`) to save the current conversation as a recipe file, not to execute existing recipes.
- **Location**:
  - Goose CLI documentation: `goose run --help` output
  - Recipe YAML files: `/home/benjamin/.config/.goose/recipes/*.yaml`
- **Evidence**:
  ```bash
  # Goose CLI help shows recipe execution syntax
  $ goose run --help
  --recipe <RECIPE_NAME or FULL_PATH_TO_RECIPE_FILE>
          Recipe name to get recipe file or the full path of the recipe file
          that defines a custom agent configuration.

  # The /recipe slash command saves conversations, doesn't execute recipes
  /recipe [filepath] - Generate a recipe from the current conversation and
                       save it to the specified filepath (must end with .yaml).
  ```
  The picker should be executing `goose run --recipe /path/to/create-plan.yaml` instead of `goose run --text "/recipe:create-plan"`.
- **Impact**: CRITICAL - Fundamental architecture mismatch. The picker assumes `/recipe:<name>` is a valid command syntax when it's actually only valid as a session slash command for saving conversations. Recipe execution must use the `--recipe` CLI flag.

### Finding 4: Neovim Picker Documentation Contains Incorrect Execution Model
- **Description**: The goose.nvim picker documentation and implementation assume that `/recipe:<name>` is a valid command that Goose will recognize and execute, when in reality this syntax is not supported by the Goose CLI for recipe execution.
- **Location**:
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md:5,27,46,162,264,291,300`
  - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md:238,529,698`
- **Evidence**:
  ```markdown
  # From picker/README.md line 5
  The Goose Recipe Picker is a comprehensive Telescope-based interface for
  managing and executing Goose recipes. It provides recipe discovery, rich
  previews, and native sidebar execution using `goose.core.run()` with
  `/recipe:<name>` commands.

  # From picker/README.md line 291
  -- Build /recipe:<name> command
  local prompt = string.format('/recipe:%s', recipe_name)
  ```
  Multiple documentation files state that recipes execute via `/recipe:<name>` command in the sidebar, but this is an incorrect execution model.
- **Impact**: MEDIUM - Documentation perpetuates the incorrect implementation. Developers and users expect this syntax to work based on documented behavior.

## Recommendations

1. **Replace Slash Command Syntax with CLI --recipe Flag Invocation**: Modify `execution.lua:run_recipe_in_sidebar()` to construct a proper `goose run --recipe <path>` command instead of sending `/recipe:<name>` as text. This requires either:
   - **Option A (Recommended)**: Build the CLI command directly: `goose run --recipe /path/to/recipe.yaml --params key=value` and execute it in a terminal split or background job, then display output in the sidebar
   - **Option B**: Create a temporary wrapper recipe that includes the target recipe as a sub-recipe and execute that wrapper
   - **Option C**: Investigate if goose.nvim can be enhanced to support `--recipe` flag in `job.lua:build_args()`

2. **Update All Documentation to Reflect Correct Recipe Execution Model**: Remove all references to `/recipe:<name>` syntax for recipe execution in:
   - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md`
   - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md`
   - `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` (comments)
   Update documentation to clarify that `/recipe` is only for saving conversations, not executing recipes, and that recipe execution requires the `--recipe` CLI flag.

3. **Implement Proper CLI Integration for Recipe Execution**: Enhance `goose.nvim` to support recipe execution by:
   - Adding a `--recipe` parameter option to `job.lua:build_args()` function
   - Modifying `execution.lua` to use the enhanced job builder with recipe path
   - Handling recipe parameter prompts either pre-execution (Neovim input prompts) or by allowing the CLI's native parameter prompting to work in the sidebar
   - Testing with both Gemini and Claude providers to ensure cross-provider compatibility

## References

### Codebase Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` (lines 1-131) - goose.nvim plugin configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` (lines 1-184) - Recipe execution module
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` (lines 1-966) - Plugin documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md` - Picker documentation
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/core.lua` (lines 1-169) - Core plugin functionality
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/job.lua` (lines 1-80) - CLI job execution
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/api.lua` (lines 1-398) - API functions
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/context.lua` (lines 1-189) - Context formatting
- `/home/benjamin/.config/.goose/recipes/create-plan.yaml` (lines 1-308) - Example recipe file
- `/home/benjamin/.config/.goose/recipes/research.yaml` (lines 1-112) - Example recipe file
- `/home/benjamin/.config/goose/config.yaml` (lines 1-4) - Goose CLI configuration
- `/home/benjamin/.config/.goosehints` - Goose project standards

### External Documentation
- [CLI Providers | goose](https://block.github.io/goose/docs/guides/cli-providers/) - CLI provider context handling
- [CLI Commands | goose](https://block.github.io/goose/docs/guides/goose-cli-commands/) - Complete CLI command reference
- [Recipe Reference Guide | goose](https://block.github.io/goose/docs/guides/recipes/recipe-reference/) - Recipe structure and syntax
- [Sub-Recipes For Specialized Tasks | goose](https://block.github.io/goose/docs/guides/recipes/sub-recipes/) - Sub-recipe patterns
- [A Recipe for Success: Cooking Up Repeatable Agentic Workflows | goose](https://block.github.io/goose/blog/2025/05/06/recipe-for-success/) - Recipe philosophy and usage
- [azorng/goose.nvim GitHub Repository](https://github.com/azorng/goose.nvim) - Plugin source code
- [API Reference | azorng/goose.nvim | DeepWiki](https://deepwiki.com/azorng/goose.nvim/4-api-reference) - Plugin API documentation
- [Practical Gemini CLI: Instruction Following — System Prompts and Context | Medium](https://medium.com/google-cloud/practical-gemini-cli-instruction-following-system-prompts-and-context-d3c26bed51b6) - Gemini CLI context handling

### Terminal Command Outputs
- `goose --help` - Main command help
- `goose run --help` - Recipe execution parameters
- `goose session --help` - Session management commands
