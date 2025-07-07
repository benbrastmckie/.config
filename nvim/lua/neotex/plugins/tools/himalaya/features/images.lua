-- Image Display Support
-- Handles terminal image rendering for email attachments

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local api = require('neotex.plugins.tools.himalaya.core.api')
local attachments = require('neotex.plugins.tools.himalaya.features.attachments')

-- Supported image protocols
M.protocols = {
  -- Kitty graphics protocol
  kitty = {
    available = function()
      return os.getenv("TERM") == "xterm-kitty" or vim.env.KITTY_WINDOW_ID ~= nil
    end,
    display = function(path, opts)
      return M.display_kitty(path, opts)
    end
  },
  
  -- iTerm2 inline images
  iterm2 = {
    available = function()
      return os.getenv("TERM_PROGRAM") == "iTerm.app"
    end,
    display = function(path, opts)
      return M.display_iterm2(path, opts)
    end
  },
  
  -- Sixel graphics
  sixel = {
    available = function()
      return vim.fn.executable('img2sixel') == 1
    end,
    display = function(path, opts)
      return M.display_sixel(path, opts)
    end
  },
  
  -- Unicode blocks (fallback)
  blocks = {
    available = function()
      return vim.fn.executable('chafa') == 1 or vim.fn.executable('timg') == 1
    end,
    display = function(path, opts)
      return M.display_blocks(path, opts)
    end
  },
  
  -- ASCII art (last resort)
  ascii = {
    available = function()
      return vim.fn.executable('jp2a') == 1 or vim.fn.executable('ascii-image-converter') == 1
    end,
    display = function(path, opts)
      return M.display_ascii(path, opts)
    end
  }
}

-- Detect available protocol
function M.detect_protocol()
  local preferred = config.get('images.protocol')
  
  -- Check preferred protocol first
  if preferred and M.protocols[preferred] and M.protocols[preferred].available() then
    return preferred
  end
  
  -- Auto-detect
  for name, protocol in pairs(M.protocols) do
    if protocol.available() then
      logger.debug("Detected image protocol: " .. name)
      return name
    end
  end
  
  return nil
end

-- Display image from email attachment
function M.display_attachment(email_id, attachment_id, attachment_info)
  -- Check if attachment is an image
  if not M.is_image(attachment_info.content_type) then
    return api.error("Attachment is not an image", "NOT_AN_IMAGE")
  end
  
  -- Download attachment
  local download_result = attachments.download(email_id, attachment_id)
  
  if not download_result.success then
    return download_result
  end
  
  local image_path = download_result.data.path
  
  -- Display image
  return M.display(image_path, {
    max_width = config.get('images.max_width', 80),
    max_height = config.get('images.max_height', 40),
    preserve_aspect = true
  })
end

-- Display image file
function M.display(path, opts)
  opts = opts or {}
  
  -- Detect protocol
  local protocol = M.detect_protocol()
  
  if not protocol then
    return api.error("No image display protocol available", "NO_PROTOCOL")
  end
  
  -- Convert image if needed
  local display_path = path
  if opts.resize or opts.convert then
    display_path = M.prepare_image(path, opts)
  end
  
  -- Display using detected protocol
  local result = M.protocols[protocol].display(display_path, opts)
  
  -- Clean up temporary file
  if display_path ~= path then
    vim.fn.delete(display_path)
  end
  
  return result
end

-- Display using Kitty protocol
function M.display_kitty(path, opts)
  local cmd = 'kitty +kitten icat'
  
  if opts.max_width then
    cmd = cmd .. ' --place ' .. opts.max_width .. 'x' .. (opts.max_height or opts.max_width)
  end
  
  if opts.preserve_aspect then
    cmd = cmd .. ' --scale-up'
  end
  
  cmd = cmd .. ' ' .. vim.fn.shellescape(path)
  
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return api.error("Failed to display image with Kitty", "DISPLAY_FAILED")
  end
  
  return api.success({ protocol = 'kitty', displayed = true })
end

-- Display using iTerm2 protocol
function M.display_iterm2(path, opts)
  -- Read and encode image
  local file = io.open(path, 'rb')
  if not file then
    return api.error("Failed to read image file", "READ_FAILED")
  end
  
  local content = file:read('*a')
  file:close()
  
  local encoded = vim.base64.encode(content)
  
  -- Build escape sequence
  local sequence = string.format(
    '\027]1337;File=inline=1;width=%s;height=%s;preserveAspectRatio=1:%s\007',
    opts.max_width or 'auto',
    opts.max_height or 'auto',
    encoded
  )
  
  -- Output sequence
  io.write(sequence)
  io.flush()
  
  return api.success({ protocol = 'iterm2', displayed = true })
end

-- Display using Sixel
function M.display_sixel(path, opts)
  local cmd = 'img2sixel'
  
  if opts.max_width then
    cmd = cmd .. ' -w ' .. opts.max_width
  end
  
  if opts.max_height then
    cmd = cmd .. ' -h ' .. opts.max_height
  end
  
  cmd = cmd .. ' ' .. vim.fn.shellescape(path)
  
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return api.error("Failed to display image with Sixel", "DISPLAY_FAILED")
  end
  
  -- Output sixel data
  io.write(result)
  io.flush()
  
  return api.success({ protocol = 'sixel', displayed = true })
end

-- Display using Unicode blocks
function M.display_blocks(path, opts)
  local cmd
  
  if vim.fn.executable('chafa') == 1 then
    cmd = 'chafa'
    
    if opts.max_width and opts.max_height then
      cmd = cmd .. ' -s ' .. opts.max_width .. 'x' .. opts.max_height
    end
    
    cmd = cmd .. ' --colors 256'
  elseif vim.fn.executable('timg') == 1 then
    cmd = 'timg'
    
    if opts.max_width then
      cmd = cmd .. ' -W' .. opts.max_width
    end
    
    if opts.max_height then
      cmd = cmd .. ' -H' .. opts.max_height
    end
  else
    return api.error("No block display tool found", "NO_TOOL")
  end
  
  cmd = cmd .. ' ' .. vim.fn.shellescape(path)
  
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return api.error("Failed to display image with blocks", "DISPLAY_FAILED")
  end
  
  -- Create buffer for image
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(result, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Show in floating window
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    width = width,
    height = #lines,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(buf, 'Image: ' .. vim.fn.fnamemodify(path, ':t'))
  
  -- Close on any key
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
  
  return api.success({ protocol = 'blocks', displayed = true, buffer = buf, window = win })
end

-- Display using ASCII art
function M.display_ascii(path, opts)
  local cmd
  
  if vim.fn.executable('ascii-image-converter') == 1 then
    cmd = 'ascii-image-converter'
    
    if opts.max_width then
      cmd = cmd .. ' -W ' .. opts.max_width
    end
    
    if opts.max_height then
      cmd = cmd .. ' -H ' .. opts.max_height
    end
    
    cmd = cmd .. ' -c'  -- Color output
  elseif vim.fn.executable('jp2a') == 1 then
    cmd = 'jp2a'
    
    if opts.max_width then
      cmd = cmd .. ' --width=' .. opts.max_width
    end
    
    if opts.max_height then
      cmd = cmd .. ' --height=' .. opts.max_height
    end
    
    cmd = cmd .. ' --colors'
  else
    return api.error("No ASCII art tool found", "NO_TOOL")
  end
  
  cmd = cmd .. ' ' .. vim.fn.shellescape(path)
  
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return api.error("Failed to display image as ASCII", "DISPLAY_FAILED")
  end
  
  -- Show in buffer (similar to blocks)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(result, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    width = width,
    height = #lines,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'rounded'
  })
  
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  
  return api.success({ protocol = 'ascii', displayed = true, buffer = buf, window = win })
end

-- Helper functions

-- Check if content type is an image
function M.is_image(content_type)
  return content_type and content_type:match('^image/')
end

-- Prepare image for display (resize, convert format)
function M.prepare_image(path, opts)
  if vim.fn.executable('convert') == 0 then
    -- ImageMagick not available
    return path
  end
  
  local temp_path = vim.fn.tempname() .. '.png'
  local cmd = 'convert ' .. vim.fn.shellescape(path)
  
  -- Resize if needed
  if opts.max_width or opts.max_height then
    local size = (opts.max_width or '') .. 'x' .. (opts.max_height or '')
    cmd = cmd .. ' -resize ' .. size
    
    if opts.preserve_aspect then
      cmd = cmd .. '>'  -- Only shrink larger images
    end
  end
  
  -- Convert to PNG for better compatibility
  cmd = cmd .. ' ' .. vim.fn.shellescape(temp_path)
  
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    logger.warn("Failed to prepare image: " .. result)
    return path
  end
  
  return temp_path
end

-- Get image information
function M.get_image_info(path)
  if vim.fn.executable('identify') == 0 then
    return nil
  end
  
  local cmd = 'identify -format "%wx%h %b %m" ' .. vim.fn.shellescape(path)
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return nil
  end
  
  local width, height, size, format = result:match("(%d+)x(%d+) ([%d.]+%w+) (%w+)")
  
  return {
    width = tonumber(width),
    height = tonumber(height),
    size = size,
    format = format
  }
end

-- Clear terminal graphics
function M.clear_graphics()
  local protocol = M.detect_protocol()
  
  if protocol == 'kitty' then
    -- Clear Kitty graphics
    io.write('\027_Ga=d\027\\')
  elseif protocol == 'iterm2' then
    -- Clear iTerm2 images
    io.write('\027]1337;ClearScrollback\007')
  end
  
  io.flush()
end

return M