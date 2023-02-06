local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require "telescope.actions"

-- local job_opts = {
--   entry_maker = function(entry)
--     local _, _, filename, lnum, col, text = string.find(entry, "([^:]+):(%d+):(.*)")
--     local table = {
--       ordinal = text,
--       display = filename .. ":" .. text
--     }
--     return table
--   end
-- }
--
-- local opts = {
--   finder = finders.new_oneshot_job(rg, job_opts),
--   sorter = sorters.get_generic_fuzzy_sorter(),
-- }

telescope.setup {
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "smart" },
    mappings = {
      i = {
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,

        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,

        ["<C-c>"] = actions.close,

        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,

        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,

        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,

        ["<PageUp>"] = actions.results_scrolling_up,
        ["<PageDown>"] = actions.results_scrolling_down,

        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-l>"] = actions.complete_tag,
        ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
      },

      n = {
        ["<esc>"] = actions.close,
        ["<CR>"] = actions.select_default,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,

        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

        ["j"] = actions.move_selection_next,
        ["k"] = actions.move_selection_previous,
        ["H"] = actions.move_to_top,
        ["M"] = actions.move_to_middle,
        ["L"] = actions.move_to_bottom,

        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,
        ["gg"] = actions.move_to_top,
        ["G"] = actions.move_to_bottom,

        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,

        ["<PageUp>"] = actions.results_scrolling_up,
        ["<PageDown>"] = actions.results_scrolling_down,

        ["?"] = actions.which_key,
      },
    },
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  load_extensions = { "yank_history" },
  extensions = {
    bibtex = {
      depth = 1,
      -- Depth for the *.bib file
      custom_formats = {},
      -- Custom format for citation label
      format = '',
      -- Format to use for citation label.
      -- Try to match the filetype by default, or use 'plain'
      global_files = {'/home/benjamin/texmf/bibtex/bib/Zotero.bib'},
      -- Path to global bibliographies (placed outside of the project)
      search_keys = { 'author', 'year', 'title' },
      -- Define the search keys to use in the picker
      citation_format = '{{author}} ({{year}}), {{title}}.',
      -- Template for the formatted citation
      citation_trim_firstname = true,
      -- Only use initials for the authors first name
      citation_max_auth = 2,
      -- Max number of authors to write in the formatted citation
      -- following authors will be replaced by "et al."
      context = false,
      -- Context awareness disabled by default
      context_fallback = true,
      -- Fallback to global/directory .bib files if context not found
      -- This setting has no effect if context = false
      wrap = false,
      -- Wrapping in the preview window is disabled by default
    },
    -- Your extension configuration goes here:
    -- extension_name = {
    --   extension_config_key = value,
    -- }
    -- please take a look at the readme of the extension you want to configure
  },
}
