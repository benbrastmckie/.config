-- Debug compose buffer parsing

local M = {}

local logger = require('neotex.plugins.tools.himalaya.core.logger')
local draft_parser = require('neotex.plugins.tools.himalaya.core.draft_parser')

-- Hook into the parse_email_buffer function
function M.enable()
  -- Create an autocmd that monitors the compose buffer parsing
  vim.api.nvim_create_augroup('HimalayaComposeDebug', { clear = true })
  
  -- Monitor BufWritePost to see what's in the buffer
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = 'HimalayaComposeDebug',
    pattern = '*.eml',
    callback = function(args)
      local file = args.file
      if not file:match('himalaya/drafts/draft_') then
        return
      end
      
      -- Wait a bit for the sync to start
      vim.defer_fn(function()
        print("\n=== COMPOSE BUFFER DEBUG ===")
        print("After save, checking parse...")
        
        -- Read the file that was saved
        local content = vim.fn.readfile(file)
        print("\nFile content (" .. #content .. " lines):")
        for i, line in ipairs(content) do
          print(string.format("%d: %s", i, line))
        end
        
        -- Parse it with the draft parser
        print("\n=== PARSING WITH DRAFT PARSER ===")
        local parsed = draft_parser.parse_email(content)
        
        print("Parsed results:")
        print("  Subject:", parsed.subject or "(nil)")
        print("  From:", parsed.from or "(nil)")
        print("  To:", parsed.to or "(nil)")
        print("  Body:", parsed.body and string.format("'%s' (length: %d)", parsed.body:sub(1, 50), #parsed.body) or "(nil)")
        print("  Headers count:", vim.tbl_count(parsed.headers or {}))
        
        if parsed.body then
          print("\nFull parsed body:")
          for i, line in ipairs(vim.split(parsed.body, '\n')) do
            print(string.format("  %d: '%s'", i, line))
          end
        end
        
        -- Check if himalaya save was called
        print("\n=== CHECKING HIMALAYA SAVE ===")
        print("(If himalaya save was called, you should see the debug output above)")
      end, 1000)  -- Wait 1 second to allow sync to happen
    end
  })
  
  print("Compose buffer debugging enabled.")
end

function M.disable()
  vim.api.nvim_del_augroup_by_name('HimalayaComposeDebug')
  print("Compose buffer debugging disabled.")
end

-- Commands
vim.api.nvim_create_user_command('HimalayaComposeDebugOn', M.enable, {
  desc = 'Enable compose buffer debugging'
})

vim.api.nvim_create_user_command('HimalayaComposeDebugOff', M.disable, {
  desc = 'Disable compose buffer debugging'
})

return M