-- Custom Jupyter Notebook styling implementation
local M = {}

-- Create namespace for our highlights
local ns_id = vim.api.nvim_create_namespace("jupyter_notebook_styling")

-- Define the highlight groups
local function setup_highlights()
  -- Cell separator line
  vim.api.nvim_set_hl(0, "JupyterCellSeparator", { fg = "#6272a4", bold = true })
  -- Code cell background
  vim.api.nvim_set_hl(0, "JupyterCodeCell", { bg = "#1E1E2E" })
  -- Markdown cell background
  vim.api.nvim_set_hl(0, "JupyterMarkdownCell", { bg = "#2D2D3D" })
  -- Cell icons
  vim.api.nvim_set_hl(0, "JupyterCellIcon", { fg = "#89b4fa", bold = true })
  -- Active cell
  vim.api.nvim_set_hl(0, "JupyterActiveCell", { bg = "#363654" })
end

-- Define signs for cell types
local function setup_signs()
  vim.fn.sign_define("JupyterCodeSign", { text = "📊", texthl = "JupyterCellIcon" })
  vim.fn.sign_define("JupyterMarkdownSign", { text = "📝", texthl = "JupyterCellIcon" })
  vim.fn.sign_define("JupyterSeparatorSign", { text = "▶", texthl = "JupyterCellIcon" })
end

-- Apply styling to the current buffer
local function apply_styling(bufnr)
  -- Clear existing styling
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- Track cell state
  local in_code_cell = false
  local in_markdown_cell = true -- Start with markdown (jupyter default)
  local current_cell_start = 0
  
  -- Cell markers - detect both markdown and Python style markers
  local markers = {
    ["```"] = true,         -- markdown cells
    ["# %%"] = true,        -- python cells
    ["#%%"] = true          -- python cells variant
  }
  
  -- Process each line
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
      -- Add horizontal separator
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, i-1, 0, {
        virt_text = {{"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", "JupyterCellSeparator"}},
        virt_text_pos = "overlay",
        priority = 100,
      })
      
      -- Add sign marker for visual indicator in gutter
      vim.fn.sign_place(0, "JupyterSigns", "JupyterSeparatorSign", bufnr, { lnum = i })
      
      -- Determine if we're entering a code or markdown cell
      if line:match("^%s*```python") then
        in_code_cell = true
        in_markdown_cell = false
        
        -- Place code cell icon
        vim.fn.sign_place(0, "JupyterSigns", "JupyterCodeSign", bufnr, { lnum = i+1 })
      elseif line:match("^%s*```") and in_code_cell then
        in_code_cell = false
        in_markdown_cell = true
      elseif line:match("^%s*#%%") or line:match("^%s*# %%") then
        -- Python cell marker
        if in_markdown_cell then
          in_markdown_cell = false
          in_code_cell = true
          vim.fn.sign_place(0, "JupyterSigns", "JupyterCodeSign", bufnr, { lnum = i+1 })
        else
          -- Switching between code cells
          vim.fn.sign_place(0, "JupyterSigns", "JupyterCodeSign", bufnr, { lnum = i+1 })
        end
      end
      
      -- Add background color to previous cell
      if current_cell_start > 0 then
        local hl_group = in_code_cell and "JupyterMarkdownCell" or "JupyterCodeCell"
        
        -- Apply highlight to the entire cell region
        for j = current_cell_start, i-2 do
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, j, 0, {
            line_hl_group = hl_group,
            priority = 10, -- Lower priority than other extmarks
          })
        end
      end
      
      current_cell_start = i
    end
  end
  
  -- Handle the last cell if it exists
  if current_cell_start > 0 and current_cell_start <= #lines then
    local hl_group = in_code_cell and "JupyterCodeCell" or "JupyterMarkdownCell"
    
    for j = current_cell_start, #lines-1 do
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, j, 0, {
        line_hl_group = hl_group,
        priority = 10,
      })
    end
  end
end

-- Setup function to initialize the styling
function M.setup()
  -- Create autocommand group
  vim.api.nvim_create_augroup("JupyterNotebookStyling", { clear = true })
  
  -- Setup highlight groups and signs
  setup_highlights()
  setup_signs()
  
  -- Apply styling when entering jupyter notebook files
  vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost"}, {
    pattern = {"*.ipynb", "*.md"},
    group = "JupyterNotebookStyling",
    callback = function(args)
      -- Enable sign column for cell markers
      vim.opt_local.signcolumn = "yes:1"
      
      -- Apply the styling
      apply_styling(args.buf)
    end
  })
  
  -- Force apply styling to all open buffers
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname:match("%.ipynb$") or bufname:match("%.md$") then
      if vim.api.nvim_buf_is_loaded(buf) then
        apply_styling(buf)
      end
    end
  end
end

return M