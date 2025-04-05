require("nvim-surround").buffer_setup({
  surrounds = {
    -- ["e"] = {
    --   add = function()
    --     local env = require("nvim-surround.config").get_input ("Environment: ")
    --     return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
    --   end,
    -- },
    ["b"] = {
      add = { "**", "**" },
      find = "**.-**",
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "_", "_" },
      find = "_.-_",
      delete = "^(_)().-(_)()$",
    },
  },
})

-- prevents markdown from changing tabs to 4 spaces
-- vim.g.markdown_recommended_style = 0

-- MarkdownFoldLevel has been moved to lua/neotex/core/functions.lua
-- Use the global _G.MarkdownFoldLevel() function instead

-- Load the saved folding state for markdown
require("neotex.core.functions").LoadFoldingState()

-- Function to extract URLs from a line of text
function _G.ExtractUrlsFromLine(line)
  local urls = {}
  local url_patterns = {
    -- Markdown link format [text](url)
    "%[.-%]%((.-)%)",
    -- Plain URLs with various protocols
    "https?://[%w%.%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*]+",
    "www%.[%w%.%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*]+",
    "file://[%w%.%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*]+",
  }

  for _, pattern in ipairs(url_patterns) do
    for url_match in string.gmatch(line, pattern) do
      -- Process the URL based on the pattern
      local url = url_match

      -- Store the URL and its position
      local start_idx = string.find(line, url_match, 1, true)
      if start_idx then
        -- For markdown links, the pattern captures just the URL part
        if pattern == "%[.-%]%((.-)%)" then
          -- Safely escape the URL for pattern matching
          local escaped_url = url:gsub("([%%%-%+%_%:%&%=%?%/%(%)%#%$%@%!%~%*])", "%%%1")
          -- Find the actual text of the full markdown link for position calculation
          local full_link_start = line:find("%[.-%]%(" .. escaped_url .. "%)", 1)

          -- Only proceed if we found a valid start position
          if full_link_start then
            local full_link_end = full_link_start
            -- Find the closing parenthesis
            local depth = 0
            for i = full_link_start, #line do
              local char = line:sub(i, i)
              if char == "(" then
                depth = depth + 1
              elseif char == ")" then
                depth = depth - 1
                if depth == 0 then
                  full_link_end = i
                  break
                end
              end
            end

            -- Only proceed if we have valid positions
            local url_start = line:find("%(", full_link_start, true)
            if url_start and full_link_end and full_link_start then
              url_start = url_start + 1 -- Move past the opening parenthesis
              table.insert(urls, {
                url = url,
                start = full_link_start,
                finish = full_link_end,
                url_start = url_start,
                url_end = url_start + #url - 1
              })
            end
          end
        else
          -- For regular URLs, store their positions directly
          table.insert(urls, {
            url = url,
            start = start_idx,
            finish = start_idx + #url - 1
          })
        end
      end
    end
  end

  return urls
end

-- Function to open URL at a specific position or under cursor
function _G.OpenUrlAtPosition(line_num, col)
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  if not line then return false end

  -- Extract all URLs from the line
  local urls = ExtractUrlsFromLine(line)
  if #urls == 0 then return false end

  -- Find the URL at or closest to the position
  local selected_url = nil
  local min_distance = math.huge

  -- Only process URLs if we have valid column position
  if col and #urls > 0 then
    for _, url_info in ipairs(urls) do
      -- Ensure we have valid position information
      if url_info.start and url_info.finish then
        if col >= url_info.start and col <= url_info.finish then
          -- Position is directly on this URL
          selected_url = url_info.url
          break
        else
          -- Calculate distance to this URL
          local distance = math.min(math.abs(col - url_info.start), math.abs(col - url_info.finish))
          if distance < min_distance then
            min_distance = distance
            selected_url = url_info.url
          end
        end
      end
    end
  end

  if selected_url then
    -- Make sure URL has protocol prefix
    if not selected_url:match("^https?://") and not selected_url:match("^file://") then
      if selected_url:match("^www%.") then
        selected_url = "https://" .. selected_url
      else
        selected_url = "https://" .. selected_url
      end
    end

    -- Open the URL with the system browser
    local cmd = string.format("silent !xdg-open '%s' &", selected_url:gsub("'", "\\'"))
    vim.cmd(cmd)
    vim.notify("Opening URL: " .. selected_url, vim.log.levels.INFO)
    return true
  end
end

-- Function to open URL at mouse position
function _G.OpenUrlAtMouse()
  local mouse_pos = vim.fn.getmousepos()
  if not mouse_pos or not mouse_pos.line or not mouse_pos.column then
    vim.notify("Invalid mouse position", vim.log.levels.WARN)
    return false
  end

  local line_num = mouse_pos.line
  local col = mouse_pos.column - 1 -- Convert to 0-indexed

  if OpenUrlAtPosition(line_num, col) then
    return true
  else
    vim.notify("No URL found at mouse position", vim.log.levels.WARN)
    return false
  end
end

-- Function to open URL under cursor (backward compatibility)
function _G.OpenUrlUnderCursor()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor_pos[1]
  local col = cursor_pos[2]

  if OpenUrlAtPosition(line_num, col) then
    return true
  else
    vim.notify("No URL found under cursor", vim.log.levels.WARN)
    return false
  end
end

-- Add keybinding to open the URL under cursor with gx for familiar Vim behavior
vim.keymap.set("n", "gx", ":lua OpenUrlUnderCursor()<CR>",
  { buffer = true, silent = true, desc = "Open URL under cursor" })

-- Enable Ctrl+Click to open URLs
vim.keymap.set("n", "<C-LeftMouse>", function()
  -- We don't perform standard Ctrl+LeftMouse because we want to keep cursor position
  -- Instead, we directly get the mouse position and use it
  vim.schedule(function()
    OpenUrlAtMouse()
  end)
end, { buffer = true, silent = true, desc = "Open URL with Ctrl+Click" })

-- Handle mouse release to avoid issues
vim.keymap.set("n", "<C-LeftRelease>", "<Nop>", { buffer = true, silent = true })
