-- Custom Jupyter Notebook styling implementation with theme integration
local M = {}

-- Create namespaces for our highlights
local ns_id = vim.api.nvim_create_namespace("jupyter_notebook_styling")
local active_cell_ns = vim.api.nvim_create_namespace("jupyter_active_cell")

-- Helper function to adjust color brightness
local function adjust_color(hex, amount)
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return hex end

  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
  r = math.min(255, math.max(0, r + amount))
  g = math.min(255, math.max(0, g + amount))
  b = math.min(255, math.max(0, b + amount))

  return string.format("#%02x%02x%02x", r, g, b)
end

-- Define the highlight groups based on current colorscheme
local function setup_highlights()
  -- Get colors from current theme
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local comment = vim.api.nvim_get_hl(0, { name = "Comment" })
  local func = vim.api.nvim_get_hl(0, { name = "Function" })

  -- Convert RGB values to hex if they exist, or use fallbacks
  local function to_hex(rgb)
    if not rgb then return nil end
    return string.format("#%06x", rgb)
  end

  local normal_bg = to_hex(normal.bg) or "#282828"
  local normal_fg = to_hex(normal.fg) or "#ebdbb2"
  local comment_fg = to_hex(comment.fg) or "#928374"
  local function_fg = to_hex(func.fg) or "#8ec07c"

  -- Cell separator line (use comment color)
  vim.api.nvim_set_hl(0, "JupyterCellSeparator", { fg = comment_fg, bold = true })

  -- Code cell background (slightly different from normal bg)
  vim.api.nvim_set_hl(0, "JupyterCodeCell", { bg = adjust_color(normal_bg, 10) })

  -- Markdown cell background (slightly lighter than code cells)
  vim.api.nvim_set_hl(0, "JupyterMarkdownCell", { bg = adjust_color(normal_bg, 20) })

  -- Cell icons (use function color)
  vim.api.nvim_set_hl(0, "JupyterCellIcon", { fg = function_fg, bold = true })

  -- Active cell (brighter than inactive cells)
  vim.api.nvim_set_hl(0, "JupyterActiveCell", { bg = adjust_color(normal_bg, 30) })
end

-- Define sign for code cell start
local function setup_signs()
  -- Modern sign definition (Neovim 0.9+)
  local signs = { 
    {
      name = "JupyterSeparatorSign",
      text = "▶",
      texthl = "JupyterCellIcon"
    }
  }
  
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.texthl })
  end
end

-- Try to use NotebookNavigator for cell detection if available
local function get_cells_from_nn(bufnr)
  local ok, nn = pcall(require, "notebook-navigator")
  if not ok then
    return nil
  end

  -- Check if get_cells function exists in NotebookNavigator
  if type(nn.get_cells) ~= "function" then
    return nil
  end

  -- Try to get cells from NotebookNavigator
  local ok2, cells = pcall(nn.get_cells, bufnr)
  if not ok2 or type(cells) ~= "table" then
    return nil
  end

  return cells
end

-- Fallback cell detection logic
local function detect_cells_manually(bufnr)
  local cells = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Cell markers - detect both markdown and Python style markers
  local markers = {
    ["```"] = true,  -- markdown cells
    ["# %%"] = true, -- python cells
    ["#%%"] = true   -- python cells variant
  }

  -- Track cell state
  local in_code_cell = false
  local in_markdown_cell = true -- Start with markdown (jupyter default)
  local current_cell_start = 0

  -- Process each line to find cell boundaries
  for i, line in ipairs(lines) do
    local is_marker = false

    -- Check if line matches any cell marker
    for marker, _ in pairs(markers) do
      if line:match("^%s*" .. marker) then
        is_marker = true
        break
      end
    end

    -- If this is a cell marker
    if is_marker then
      -- If we have a previous cell, add it to our list
      if current_cell_start > 0 then
        table.insert(cells, {
          start_line = current_cell_start,
          end_line = i - 2,
          cell_type = in_code_cell and "code" or "markdown",
          marker_line = i - 1
        })
      end

      -- Determine cell type for the new cell
      if line:match("^%s*```python") then
        in_code_cell = true
        in_markdown_cell = false
      elseif line:match("^%s*```") and in_code_cell then
        in_code_cell = false
        in_markdown_cell = true
      elseif line:match("^%s*#%%") or line:match("^%s*# %%") then
        if in_markdown_cell then
          in_markdown_cell = false
          in_code_cell = true
        end
      end

      current_cell_start = i
    end
  end

  -- Add the last cell if exists
  if current_cell_start > 0 and current_cell_start <= #lines then
    table.insert(cells, {
      start_line = current_cell_start,
      end_line = #lines - 1,
      cell_type = in_code_cell and "code" or "markdown"
    })
  end

  return cells
end

-- Apply styling to the current buffer
local function apply_styling(bufnr)
  -- Clear existing styling
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Only apply to ipynb files
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if not bufname:match("%.ipynb$") then
    return
  end

  -- Get cells - try NotebookNavigator first, then fallback to manual detection
  local cells = get_cells_from_nn(bufnr) or detect_cells_manually(bufnr)

  -- Process each cell
  for _, cell in ipairs(cells) do
    -- Only show separator sign at the top of code cells
    if cell.cell_type == "code" and cell.marker_line then
      -- Place sign marker using lower level API to avoid deprecated function
      local ns = vim.api.nvim_create_namespace("JupyterSigns")
      vim.api.nvim_buf_set_extmark(bufnr, ns, cell.start_line, 0, {
        sign_text = "▶",
        sign_hl_group = "JupyterCellIcon",
        priority = 10,
      })
    end

    -- Apply background color only to code cells
    if cell.cell_type == "code" then
      for line_num = cell.start_line, cell.end_line do
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, 0, {
          line_hl_group = "JupyterCodeCell",
          priority = 10, -- Lower priority than other extmarks
        })
      end
    end
  end
end

-- Highlight the cell under cursor
local function highlight_active_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  -- Only apply to ipynb files
  if not bufname:match("%.ipynb$") then
    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1

  -- Clear previous active cell highlight
  vim.api.nvim_buf_clear_namespace(bufnr, active_cell_ns, 0, -1)

  -- Get cells - try NotebookNavigator first, then fallback to manual detection
  local cells = get_cells_from_nn(bufnr) or detect_cells_manually(bufnr)

  -- Find which cell contains the cursor
  for _, cell in ipairs(cells) do
    if cursor_line >= cell.start_line and cursor_line <= cell.end_line then
      -- Highlight active cell only if it's a code cell
      if cell.cell_type == "code" then
        for line_num = cell.start_line, cell.end_line do
          vim.api.nvim_buf_set_extmark(bufnr, active_cell_ns, line_num, 0, {
            line_hl_group = "JupyterActiveCell",
            priority = 15, -- Higher than regular cell highlighting
          })
        end
      end
      break
    end
  end
end

-- Setup function to initialize the styling
function M.setup()
  -- Create autocommand group
  local group = vim.api.nvim_create_augroup("JupyterNotebookStyling", { clear = true })

  -- Setup highlight groups and signs
  setup_highlights()
  setup_signs()

  -- Apply styling only when entering or writing jupyter notebook files
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    pattern = "*.ipynb",
    group = group,
    callback = function(args)
      -- Enable sign column for cell markers
      vim.opt_local.signcolumn = "yes:1"

      -- Apply the styling
      apply_styling(args.buf)
    end
  })

  -- Highlight active cell when cursor moves
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    pattern = "*.ipynb",
    group = group,
    callback = function()
      highlight_active_cell()
    end
  })

  -- Force apply styling to all open ipynb buffers
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname:match("%.ipynb$") then
      if vim.api.nvim_buf_is_loaded(buf) then
        apply_styling(buf)
      end
    end
  end

  -- Set up an autocmd to refresh highlights when colorscheme changes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      -- Re-setup all highlights with the new colorscheme
      setup_highlights()

      -- Reapply to all open buffers
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname:match("%.ipynb$") and vim.api.nvim_buf_is_loaded(buf) then
          apply_styling(buf)
        end
      end
    end,
  })
end

return M