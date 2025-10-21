-- Enhanced Jupyter styling for Markdown files (.md)
if vim.fn.expand("%:e") == "md" then
  -- Check if this is a Jupyter-converted markdown file
  local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
  local is_jupyter = false

  for _, line in ipairs(lines) do
    if line:match("^```python") then
      is_jupyter = true
      break
    end
  end

  if is_jupyter then
    -- Apply Jupyter notebook styling
    vim.opt_local.signcolumn = "yes:1"

    -- Ensure our styling module is loaded
    vim.defer_fn(function()
      local ok, styling = pcall(require, "neotex.plugins.tools.jupyter.styling")
      if ok and type(styling) == "table" and styling.setup then
        styling.setup()
      end
    end, 100)
  end
end

-- Apply custom markdown comment highlighting
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "ColorScheme"}, {
  buffer = 0,
  callback = function()
    -- Define muted color for comments (Gruvbox gray)
    local muted_color = "#928374"

    -- Ensure HTML comment highlights are set
    vim.api.nvim_set_hl(0, "htmlComment", { fg = muted_color, italic = true })
    vim.api.nvim_set_hl(0, "htmlCommentPart", { fg = muted_color, italic = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownHtmlComment", { fg = muted_color, italic = true })
  end
})

-- Markdown-specific nvim-surround configuration
-- These surrounds are only available in markdown files
require("nvim-surround").buffer_setup({
  surrounds = {
    -- Bold: **text** (double asterisk for strong emphasis)
    ["b"] = {
      add = { "**", "**" },
      find = "%*%*.-%*%*",
      delete = "^(%*%*)().-(%*%*)()$",
    },
    -- Italic: *text* (single asterisk for emphasis)
    ["i"] = {
      add = { "*", "*" },
      find = "%*.-%*",
      delete = "^(%*)().-(%)()$",
    },
    -- Inline code: `text` (backtick for code)
    ["`"] = {
      add = { "`", "`" },
      find = "`.-`",
      delete = "^(`)().-(`)()$",
    },
    -- Code block: ```language\ntext\n``` (fenced code block with language prompt)
    ["c"] = {
      add = function()
        local lang = vim.fn.input("Language: ")
        return { { "```" .. lang, "" }, { "", "```" } }
      end,
    },
    -- Link: [text](url) (markdown link with URL prompt)
    ["l"] = {
      add = function()
        local url = vim.fn.input("URL: ")
        return { { "[", "](" .. url .. ")" } }
      end,
    },
    -- Strikethrough: ~~text~~ (GFM strikethrough)
    ["~"] = {
      add = { "~~", "~~" },
      find = "~~.-~~",
      delete = "^(~~)().-(~~)()$",
    },
  },
})

-- Register Pandoc-specific which-key mappings for this buffer
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>p", group = "pandoc", icon = "󰈙", buffer = 0 },
    { "<leader>ph", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.html'<CR>", desc = "html", icon = "󰌝", buffer = 0 },
    { "<leader>pl", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.tex'<CR>", desc = "latex", icon = "󰐺", buffer = 0 },
    { "<leader>pm", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.md'<CR>", desc = "markdown", icon = "󱀈", buffer = 0 },
    { "<leader>pp", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.pdf' open=0<CR>", desc = "pdf", icon = "󰈙", buffer = 0 },
    { "<leader>pv", "<cmd>TermExec cmd='sioyek %:p:r.pdf &' open=0<CR>", desc = "view", icon = "󰛓", buffer = 0 },
    { "<leader>pw", "<cmd>TermExec cmd='pandoc %:p -o %:p:r.docx'<CR>", desc = "word", icon = "󰈭", buffer = 0 },
  })
end

