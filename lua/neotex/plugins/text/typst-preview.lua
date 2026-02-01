-- Typst Preview Plugin Configuration
-- Live preview for Typst documents with cross-jump support
return {
  "chomosuke/typst-preview.nvim",
  version = "1.*",  -- Pin to 1.x for stability
  ft = "typst",
  config = function()
    require("typst-preview").setup({
      -- Use system-installed tinymist from NixOS, auto-download websocat
      dependencies_bin = {
        ["tinymist"] = "tinymist",
        ["websocat"] = nil, -- nil = auto-download, required for click-to-jump
      },
      -- Open preview in default browser
      open_cmd = nil, -- Uses xdg-open on Linux
      -- Invert colors for dark mode (optional)
      invert_colors = "never",
      -- Follow cursor in preview (forward sync: Neovim -> browser)
      follow_cursor = true,
      -- Debug mode (logs to ~/.local/share/nvim/typst-preview/log.txt)
      debug = false,
      -- Main file detection for multi-file projects
      get_main_file = function(current_file)
        -- Check for buffer-local pinned main file
        if vim.b.typst_main_file then
          return vim.b.typst_main_file
        end

        local current_dir = vim.fn.fnamemodify(current_file, ":h")

        -- If current file is not in a subdirectory, use it
        local parent_dir_name = vim.fn.fnamemodify(current_dir, ":t")
        local common_subdirs = { "chapters", "sections", "parts", "includes", "content" }
        local is_in_subdir = vim.tbl_contains(common_subdirs, parent_dir_name)

        if not is_in_subdir then
          return current_file
        end

        -- We're in a subdirectory, search for main file
        local project_root = vim.fn.fnamemodify(current_dir, ":h")

        -- Look for main file candidates in project root
        local main_candidates = {
          project_root .. "/main.typ",
          project_root .. "/index.typ",
          project_root .. "/document.typ",
          project_root .. "/" .. vim.fn.fnamemodify(project_root, ":t") .. ".typ",
        }

        for _, candidate in ipairs(main_candidates) do
          if vim.fn.filereadable(candidate) == 1 then
            return candidate
          end
        end

        -- Fallback: Find any .typ file in project root
        local typ_files = vim.fn.glob(project_root .. "/*.typ", false, true)
        if #typ_files > 0 then
          table.sort(typ_files)
          return typ_files[1]
        end

        return current_file
      end,
      -- Project root detection
      get_root = function(main_file)
        local root = os.getenv("TYPST_ROOT")
        if root then
          return root
        end
        local main_dir = vim.fn.fnamemodify(main_file, ":h")
        local found = vim.fs.find({ "typst.toml", ".git" }, { path = main_dir, upward = true })
        if #found > 0 then
          return vim.fn.fnamemodify(found[1], ":h")
        end
        return main_dir
      end,
    })
  end,
}
