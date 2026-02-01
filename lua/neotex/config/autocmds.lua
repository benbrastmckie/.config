-- neotex.config.autocmds
-- Autocommand configuration

local M = {}

function M.setup()
  local api = vim.api

  -- Set special buffers as fixed and map 'q' to close
  api.nvim_create_autocmd(
    "FileType",
    {
      pattern = { "man", "help", "qf", "lspinfo", "infoview", "NvimTree" }, -- "startuptime",
      callback = function(ev)
        -- Set the window as fixed
        vim.wo.winfixbuf = true
        -- Map q to close
        vim.keymap.set("n", "q", ":close<CR>", { buffer = ev.buf, silent = true })
      end,
    }
  )

  
  -- Setup terminal keymaps and suppress native terminal message
  api.nvim_create_autocmd({ "TermOpen" }, {
    pattern = { "term://*" }, -- use term://*toggleterm#* for only ToggleTerm
    callback = function(ev)
      set_terminal_keymaps()
      
      -- Aggressive suppression of the native terminal message
      local bufname = vim.api.nvim_buf_get_name(ev.buf)
      
      -- Set buffer-local option to suppress messages
      vim.bo[ev.buf].modifiable = true
      
      -- Multiple approaches to clear the message
      vim.cmd([[silent! echo ""]])
      vim.cmd([[silent! redraw!]])
      
      -- For Claude Code, use additional suppression
      if bufname:match("claude%-code") or bufname:match("ClaudeCode") then
        -- Clear any messages immediately and after a short delay
        vim.defer_fn(function()
          vim.cmd([[silent! echo ""]])
          vim.cmd([[silent! redraw!]])
        end, 1)
        
        -- Also try clearing with messages command
        vim.defer_fn(function()
          vim.cmd([[silent! messages clear]])
        end, 10)
      end
      
      -- Final clear for all terminals
      vim.defer_fn(function()
        vim.cmd([[silent! echo ""]])
      end, 50)
    end,
  })

  -- Setup markdown keymaps
  api.nvim_create_autocmd({ "BufEnter", "BufReadPre", "BufNewFile" }, {
    pattern = { "*.md" },
    command = "lua set_markdown_keymaps()",
  })

  -- Handle file changes silently - suppress the "File changed on disk" messages
  api.nvim_create_autocmd("FileChangedShell", {
    pattern = "*",
    callback = function(args)
      local bufname = vim.api.nvim_buf_get_name(args.buf)
      
      -- Check if file still exists
      if vim.fn.filereadable(bufname) == 0 then
        -- File was deleted - mark as not modified and don't reload
        vim.bo[args.buf].modified = false
        -- Tell vim we handled it by setting to "ignore" 
        vim.v.fcs_choice = ""
      else
        -- File was modified - reload silently
        vim.v.fcs_choice = "reload"
      end
    end,
  })

  -- Auto-reload on focus and buffer entry (removed CursorHold events for performance)
  -- CursorHold/CursorHoldI removed: caused 5-10ms lag on every cursor pause
  -- FocusGained and BufEnter are sufficient for detecting external file changes
  api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    pattern = "*",
    callback = function()
      if vim.o.autoread and vim.fn.getcmdwintype() == '' then
        -- Silently check for file changes
        vim.cmd('silent! checktime')
      end
    end,
  })

  -- WezTerm OSC 7 integration for tab title updates
  -- Only runs when inside WezTerm (checked via WEZTERM_PANE env var)
  if vim.env.WEZTERM_PANE then
    -- Helper function to emit OSC 7 escape sequence with current working directory
    -- OSC 7 format: ESC ] 7 ; file://hostname/path ST
    -- WezTerm extracts the directory name from this for tab titles
    local function emit_osc7()
      local cwd = vim.fn.getcwd()
      local hostname = vim.fn.hostname()
      -- Use \027 (decimal) for ESC for Lua 5.1 compatibility
      -- \007 is BEL which serves as the string terminator (ST)
      local osc7 = string.format("\027]7;file://%s%s\007", hostname, cwd)
      io.write(osc7)
      io.flush()
    end

    -- Emit OSC 7 on directory changes (covers :cd, :lcd, :tcd, autochdir)
    api.nvim_create_autocmd("DirChanged", {
      pattern = "*",
      callback = emit_osc7,
      desc = "WezTerm: Update tab title on directory change",
    })

    -- Emit OSC 7 on Neovim startup to set initial tab title
    api.nvim_create_autocmd("VimEnter", {
      pattern = "*",
      callback = emit_osc7,
      desc = "WezTerm: Set initial tab title",
    })

    -- Emit OSC 7 when entering non-terminal buffers
    -- This restores the Neovim cwd display after terminal buffers (which emit their own OSC 7)
    api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        -- Only emit for non-terminal buffers to avoid conflicts with shell's OSC 7
        if vim.bo.buftype ~= "terminal" then
          emit_osc7()
        end
      end,
      desc = "WezTerm: Restore tab title when leaving terminal buffer",
    })

    -- Claude Code task number integration for WezTerm tab title
    -- Monitors Claude Code terminal buffers for /research N, /plan N, /implement N, /revise N commands
    -- and emits TASK_NUMBER user variable to WezTerm via OSC 1337
    --
    -- Related: Task 791 - Extends wezterm-task-number.sh hook to work from within Neovim
    --
    -- This works alongside the shell-level wezterm-task-number.sh hook:
    -- - Shell hook: Works for standalone Claude Code (uses CLAUDE_USER_PROMPT env var)
    -- - This monitor: Works for Claude Code inside Neovim (emits OSC directly to WezTerm)
    -- Both set the same TASK_NUMBER user variable, so they coexist without conflict.
    local wezterm = require('neotex.lib.wezterm')

    -- Buffer-local state for tracking Claude Code terminals
    -- Key: buffer number, Value: { last_task_number, debounce_timer }
    local claude_buffer_state = {}

    -- Function to parse task number from a line of text
    local function parse_task_number(line)
      if not line or line == '' then
        return nil
      end
      -- Use Lua pattern matching (slightly different from POSIX regex)
      -- Note: Removed ^ anchor to match anywhere in line (handles terminal prompts)
      local task_num = line:match('/?%s*[rR][eE][sS][eE][aA][rR][cC][hH]%s+(%d+)')
        or line:match('/?%s*[pP][lL][aA][nN]%s+(%d+)')
        or line:match('/?%s*[iI][mM][pP][lL][eE][mM][eE][nN][tT]%s+(%d+)')
        or line:match('/?%s*[rR][eE][vV][iI][sS][eE]%s+(%d+)')
      return task_num
    end

    -- Function to check if a buffer is a Claude Code terminal
    local function is_claude_terminal(bufnr)
      local bufname = api.nvim_buf_get_name(bufnr)
      -- Match pattern used by claude-code.nvim plugin (just "claude", not "claude-code")
      return bufname:match('claude') or bufname:match('ClaudeCode')
    end

    -- Function to update task number with debouncing
    local function update_task_number(bufnr, task_number)
      local state = claude_buffer_state[bufnr]
      if not state then
        return
      end

      -- Cancel any pending debounce timer
      if state.debounce_timer then
        vim.fn.timer_stop(state.debounce_timer)
        state.debounce_timer = nil
      end

      -- Debounce: wait 100ms before emitting to avoid rapid updates during typing
      state.debounce_timer = vim.fn.timer_start(100, function()
        state.debounce_timer = nil

        -- Only emit if task number actually changed
        if state.last_task_number ~= task_number then
          if task_number then
            wezterm.set_task_number(task_number)
          else
            wezterm.clear_task_number()
          end
          state.last_task_number = task_number
        end
      end)
    end

    -- Setup monitoring for a Claude Code terminal buffer
    local function setup_claude_monitor(bufnr)
      if claude_buffer_state[bufnr] then
        return -- Already monitoring
      end

      claude_buffer_state[bufnr] = {
        last_task_number = nil,
        debounce_timer = nil,
      }

      -- Attach to buffer to monitor changes
      api.nvim_buf_attach(bufnr, false, {
        on_lines = function(_, _, _, first_line, last_line, _, _, _, _)
          -- Only process if buffer is still valid
          if not api.nvim_buf_is_valid(bufnr) then
            return true -- Detach
          end

          -- Get the changed lines
          local lines = api.nvim_buf_get_lines(bufnr, first_line, last_line, false)

          -- Check each changed line for task patterns
          for _, line in ipairs(lines) do
            local task_num = parse_task_number(line)
            if task_num then
              update_task_number(bufnr, task_num)
              return -- Found a task number, stop processing
            end
          end
        end,
        on_detach = function()
          -- Cleanup buffer state on detach
          local state = claude_buffer_state[bufnr]
          if state and state.debounce_timer then
            vim.fn.timer_stop(state.debounce_timer)
          end
          claude_buffer_state[bufnr] = nil
        end,
      })
    end

    -- TermOpen autocmd to detect Claude Code terminals
    api.nvim_create_autocmd('TermOpen', {
      pattern = 'term://*',
      callback = function(ev)
        -- Defer to next tick to ensure buffer name is set
        vim.defer_fn(function()
          if is_claude_terminal(ev.buf) then
            setup_claude_monitor(ev.buf)
          end
        end, 10)
      end,
      desc = 'WezTerm: Setup task number monitoring for Claude Code terminals',
    })

    -- BufDelete/BufWipeout to cleanup state
    api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
      pattern = '*',
      callback = function(ev)
        local state = claude_buffer_state[ev.buf]
        if state then
          if state.debounce_timer then
            vim.fn.timer_stop(state.debounce_timer)
          end
          claude_buffer_state[ev.buf] = nil

          -- Clear task number when Claude terminal closes
          wezterm.clear_task_number()
        end
      end,
      desc = 'WezTerm: Cleanup Claude Code terminal state',
    })
  end

  return true
end

return M

