-- Typst ftplugin configuration
-- Keybindings use <leader>l (same as LaTeX) - filetype isolation prevents conflicts

-- Buffer-local variable to store pinned main file
vim.b.typst_main_file = vim.b.typst_main_file or nil

-- Auto-detect main file for multi-file projects
local function detect_main_file()
  if vim.b.typst_main_file then
    return vim.b.typst_main_file
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ":h")

  -- If current file is not in a subdirectory (no chapters/, includes/, etc.), use it
  local parent_dir_name = vim.fn.fnamemodify(current_dir, ":t")
  local common_subdirs = { "chapters", "sections", "parts", "includes", "content" }
  local is_in_subdir = vim.tbl_contains(common_subdirs, parent_dir_name)

  if not is_in_subdir then
    return current_file
  end

  -- We're in a subdirectory, search for main file
  local project_root = vim.fn.fnamemodify(current_dir, ":h") -- Go up one level

  -- Look for main file candidates in project root
  local main_candidates = {
    -- Common main file names
    project_root .. "/main.typ",
    project_root .. "/index.typ",
    project_root .. "/document.typ",
    -- Check for directory-named file (e.g., BimodalReference.typ in typst/ dir)
    project_root .. "/" .. vim.fn.fnamemodify(project_root, ":t") .. ".typ",
  }

  for _, candidate in ipairs(main_candidates) do
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
  end

  -- Fallback: Find any .typ file in project root (not recursively)
  local typ_files = vim.fn.glob(project_root .. "/*.typ", false, true)
  if #typ_files > 0 then
    -- Sort by name to get consistent behavior
    table.sort(typ_files)
    return typ_files[1]
  end

  -- Last resort: use current file
  return current_file
end

-- Pin current file as main file (for multi-file projects)
local function pin_main_file()
  local current_file = vim.api.nvim_buf_get_name(0)
  vim.b.typst_main_file = current_file

  -- Notify tinymist LSP about pinned main file
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "tinymist" })
  for _, client in ipairs(clients) do
    vim.lsp.buf.execute_command({
      command = "tinymist.pinMain",
      arguments = { current_file },
    })
  end

  vim.notify("Pinned " .. vim.fn.fnamemodify(current_file, ":t") .. " as main file", vim.log.levels.INFO)
end

-- Unpin main file
local function unpin_main_file()
  vim.b.typst_main_file = nil

  local clients = vim.lsp.get_clients({ bufnr = 0, name = "tinymist" })
  for _, client in ipairs(clients) do
    vim.lsp.buf.execute_command({
      command = "tinymist.pinMain",
      arguments = { vim.v.null },
    })
  end

  vim.notify("Unpinned main file", vim.log.levels.INFO)
end

-- Configure nvim-surround for Typst-specific surrounds
local ok_surround, surround = pcall(require, "nvim-surround")
if ok_surround then
  surround.buffer_setup({
    surrounds = {
      -- Bold: *text*
      ["b"] = {
        add = { "*", "*" },
        find = "%*[^*]+%*",
        delete = "^(%*)().-(%*)()$",
      },
      -- Italic: _text_
      ["i"] = {
        add = { "_", "_" },
        find = "_[^_]+_",
        delete = "^(_)().-(_)()$",
      },
      -- Inline math: $expr$
      ["$"] = {
        add = { "$", "$" },
        find = "%$[^$]+%$",
        delete = "^(%$)().-(%$)()$",
      },
      -- Inline code: `code`
      ["c"] = {
        add = { "`", "`" },
        find = "`[^`]+`",
        delete = "^(`)().--(`)()$",
      },
      -- Function/environment: #fn[content]
      ["e"] = {
        add = function()
          local fn = vim.fn.input("Function: ")
          return { { "#" .. fn .. "[" }, { "]" } }
        end,
        find = "#%w+%b[]",
        delete = "^(#%w+%[)().-(%])()$",
      },
      -- Raw block: ```lang content ```
      ["r"] = {
        add = function()
          local lang = vim.fn.input("Language (or empty): ")
          if lang ~= "" then
            return { { "```" .. lang .. "\n" }, { "\n```" } }
          else
            return { { "```\n" }, { "\n```" } }
          end
        end,
      },
      -- Display math: $ expr $ (with spaces)
      ["m"] = {
        add = { "$ ", " $" },
        find = "%$ .-%$",
        delete = "^(%$ )().-( %$)()$",
      },
    },
  })
end

-- Helper functions for Typst operations
local function typst_compile()
  local main_file = detect_main_file()
  local main_filename = vim.fn.fnamemodify(main_file, ":t")

  vim.notify("Compiling " .. main_filename .. "...", vim.log.levels.INFO)
  vim.fn.jobstart({ "typst", "compile", main_file }, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("Compilation successful", vim.log.levels.INFO)
      else
        vim.notify("Compilation failed (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

-- Watch job ID for stopping later
local typst_watch_job = nil

local function typst_watch()
  local main_file = detect_main_file()
  local main_filename = vim.fn.fnamemodify(main_file, ":t")

  -- Stop existing watch if running
  if typst_watch_job then
    vim.fn.jobstop(typst_watch_job)
  end

  vim.notify("Starting watch on " .. main_filename .. "...", vim.log.levels.INFO)
  typst_watch_job = vim.fn.jobstart({ "typst", "watch", main_file }, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        local msg = table.concat(data, "\n")
        if msg:match("compiled successfully") then
          vim.notify("Compiled successfully", vim.log.levels.INFO)
        end
      end
    end,
    on_exit = function(_, exit_code)
      typst_watch_job = nil
      if exit_code ~= 0 and exit_code ~= 143 then -- 143 is SIGTERM (normal stop)
        vim.notify("Watch stopped (exit code: " .. exit_code .. ")", vim.log.levels.WARN)
      else
        vim.notify("Watch stopped", vim.log.levels.INFO)
      end
    end,
  })
end

local function typst_watch_stop()
  if typst_watch_job then
    vim.fn.jobstop(typst_watch_job)
    typst_watch_job = nil
    vim.notify("Stopped watch", vim.log.levels.INFO)
  else
    vim.notify("No watch process running", vim.log.levels.WARN)
  end
end

local function typst_view_pdf()
  local main_file = detect_main_file()
  local pdf = vim.fn.fnamemodify(main_file, ":r") .. ".pdf"

  if vim.fn.filereadable(pdf) == 1 then
    vim.fn.jobstart({ "sioyek", pdf }, { detach = true })
  else
    local pdf_name = vim.fn.fnamemodify(pdf, ":t")
    vim.notify("PDF not found: " .. pdf_name .. ". Compile first with <leader>lc", vim.log.levels.WARN)
  end
end

local function typst_format()
  vim.lsp.buf.format({ async = true })
end

local function show_diagnostics()
  vim.diagnostic.open_float(nil, { focus = false, scope = "line" })
end

-- Register which-key bindings for Typst (uses <leader>l like LaTeX)
-- NOTE: Sync features (forward/backward) only work with web preview (<leader>ll/<leader>lp)
--       PDF viewer (<leader>lv) does not support sync (similar to LaTeX without SyncTeX)
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>l", group = "typst", icon = "󰬛", buffer = 0 },
    { "<leader>lc", typst_watch, desc = "compile (watch)", icon = "", buffer = 0 },
    { "<leader>le", show_diagnostics, desc = "errors", icon = "", buffer = 0 },
    { "<leader>lf", typst_format, desc = "format", icon = "", buffer = 0 },
    { "<leader>ll", "<cmd>TypstPreviewToggle<CR>", desc = "live preview (web)", icon = "", buffer = 0 },
    { "<leader>lp", "<cmd>TypstPreview<CR>", desc = "preview (web)", icon = "", buffer = 0 },
    { "<leader>lP", pin_main_file, desc = "pin main file", icon = "", buffer = 0 },
    { "<leader>lr", typst_compile, desc = "run (compile once)", icon = "", buffer = 0 },
    { "<leader>ls", "<cmd>TypstPreviewSyncCursor<CR>", desc = "sync cursor (web)", icon = "", buffer = 0 },
    { "<leader>lu", unpin_main_file, desc = "unpin main file", icon = "", buffer = 0 },
    { "<leader>lv", typst_view_pdf, desc = "view pdf (Sioyek)", icon = "", buffer = 0 },
    { "<leader>lw", typst_watch_stop, desc = "stop watch", icon = "󰅚", buffer = 0 },
    { "<leader>lx", "<cmd>TypstPreviewStop<CR>", desc = "stop preview", icon = "󰅚", buffer = 0 },
  })
end

-- Enable treesitter highlighting for Typst
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldlevel = 99

-- Set up formatting options
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Enable spell checking for prose
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

-- Disable winfixbuf for Typst files to allow typst-preview cross-jump
vim.opt_local.winfixbuf = false
