--------------------------------------------------------------------------------
-- Claude Terminal State Management Module
--------------------------------------------------------------------------------
-- Event-driven terminal state tracking and command queueing for Claude Code.
-- Uses TermOpen/TextChanged autocommands instead of timer-based polling.
--
-- State Lifecycle:
--   CLOSED -> OPENING -> READY -> BUSY -> READY
--   (TermClose can transition to CLOSED from any state)
--
-- Pattern-based readiness detection:
--   1. ^>                     - Main prompt (highest reliability)
--   2. Welcome to Claude Code - Initial welcome complete
--   3. ────────               - Separator line
--   4. ? for shortcuts        - Help footer
--   5. Try.*────.*shortcuts   - Combined multi-line pattern
--------------------------------------------------------------------------------

local M = {}

-- Terminal state enum
M.State = {
  CLOSED = 0,
  OPENING = 1,
  READY = 2,
  BUSY = 3
}

-- Module state
local state = M.State.CLOSED
local pending_commands = {}

--------------------------------------------------------------------------------
-- Public API: State Getters
--------------------------------------------------------------------------------

--- Get current terminal state
--- @return number Current state (M.State.*)
function M.get_state()
  return state
end

--- Check if terminal is in READY state
--- @return boolean True if terminal is ready for commands
function M.is_ready()
  return state == M.State.READY
end

--------------------------------------------------------------------------------
-- Terminal Discovery
--------------------------------------------------------------------------------

--- Find Claude Code terminal buffer
--- @return number|nil Buffer handle if found, nil otherwise
function M.find_claude_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      local buftype = vim.bo[buf].buftype
      if buftype == "terminal" and (bufname:match("claude") or bufname:match("ClaudeCode")) then
        return buf
      end
    end
  end
  return nil
end

--------------------------------------------------------------------------------
-- Readiness Detection
--------------------------------------------------------------------------------

--- Check if terminal is ready by pattern matching buffer content
--- Uses multiple patterns in priority order for reliability
--- @param buf number Buffer handle
--- @return boolean True if terminal is ready for input
function M.is_terminal_ready(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  -- Get last 10 lines for pattern matching
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, -10, -1, false)
  if not ok or not lines then
    return false
  end

  -- Check individual patterns (priority order)
  for _, line in ipairs(lines) do
    if line:match("^>") or                           -- Main prompt
       line:match("Welcome to Claude Code!") or      -- Welcome complete
       line:match("────────") or                      -- Separator line
       line:match("? for shortcuts") then            -- Help footer
      return true
    end
  end

  -- Check combined multi-line pattern
  local text = table.concat(lines, "\n")
  return text:match("Try.*%s*────.*%s*%?.*shortcuts") ~= nil
end

--------------------------------------------------------------------------------
-- Command Queue Management
--------------------------------------------------------------------------------

--- Queue command to be sent when terminal is ready
--- Primary readiness signal: SessionStart hook -> on_claude_ready()
--- Fallback: TextChanged autocommand
--- @param command_text string Command text to send
--- @param opts table|nil Options table with optional fields:
---   - auto_focus: boolean - Focus terminal after sending
---   - notification: function - Callback to execute after successful send
---   - ensure_open: boolean - Open Claude Code if terminal doesn't exist
function M.queue_command(command_text, opts)
  opts = opts or {}

  -- Add to queue
  table.insert(pending_commands, {
    text = command_text,
    timestamp = os.time(),
    opts = opts
  })

  local claude_buf = M.find_claude_terminal()

  if not claude_buf then
    -- No terminal exists
    if opts.ensure_open then
      vim.cmd('ClaudeCode')  -- SessionStart hook will call on_claude_ready()
    end
    -- Queue will be flushed by hook or TextChanged fallback
    return
  end

  -- Terminal exists - ensure visible and flush immediately
  M.focus_terminal(claude_buf)
  M.flush_queue(claude_buf)
end

--- Send all queued commands to terminal
--- Only sends commands that are fresh (< 30 seconds old)
--- @param claude_buf number Terminal buffer handle
function M.flush_queue(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    return
  end

  while #pending_commands > 0 do
    local cmd = table.remove(pending_commands, 1)

    -- Check if command is still fresh (< 30 seconds old)
    if os.time() - cmd.timestamp < 30 then
      local success, err = M.send_to_terminal(claude_buf, cmd.text, cmd.opts)

      -- Execute notification callback if provided
      if success and cmd.opts.notification then
        cmd.opts.notification()
      end
    else
      -- Stale command, notify user
      vim.notify(
        "Dropped stale command (>30s old)",
        vim.log.levels.WARN,
        { title = "Claude Terminal" }
      )
    end
  end
end

--- Called by SessionStart hook when Claude is ready
--- This is the primary readiness detection mechanism
--- Hook script: ~/.config/nvim/scripts/claude-ready-signal.sh
--- @see ~/.claude/settings.json for hook configuration
function M.on_claude_ready()
  state = M.State.READY

  local claude_buf = M.find_claude_terminal()
  if claude_buf and #pending_commands > 0 then
    M.focus_terminal(claude_buf)
    M.flush_queue(claude_buf)
  end
end

--------------------------------------------------------------------------------
-- Terminal Communication
--------------------------------------------------------------------------------

--- Send command to terminal via chansend
--- Safe wrapper around chansend with error handling
--- @param claude_buf number Terminal buffer handle
--- @param command_text string Command text to send
--- @param opts table|nil Options table with optional fields:
---   - auto_focus: boolean - Focus terminal after sending
--- @return boolean success True if command was sent successfully
--- @return string|nil error Error message if failed
function M.send_to_terminal(claude_buf, command_text, opts)
  opts = opts or {}

  -- Get terminal job ID
  local ok, job_id = pcall(vim.api.nvim_buf_get_var, claude_buf, 'terminal_job_id')
  if not ok or not job_id then
    return false, "no_job_id"
  end

  -- Send command via chansend (without newline unless in text)
  vim.fn.chansend(job_id, command_text)

  -- Optionally focus terminal and enter insert mode
  if opts.auto_focus then
    M.focus_terminal(claude_buf)
  end

  return true, nil
end

--- Focus Claude terminal window and optionally enter insert mode
--- If window is closed but buffer exists, reopens the window
--- @param claude_buf number Terminal buffer handle
function M.focus_terminal(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    return
  end

  local wins = vim.fn.win_findbuf(claude_buf)
  if #wins > 0 then
    -- Window exists, focus it
    vim.api.nvim_set_current_win(wins[1])
    -- Enter insert mode if currently in normal mode
    if vim.api.nvim_get_mode().mode == 'n' then
      vim.cmd('startinsert!')
    end
  elseif state ~= M.State.OPENING then
    -- Window doesn't exist but buffer does - reopen Claude Code sidebar
    -- Only do this if we're not currently in the middle of opening
    vim.cmd('ClaudeCode')

    -- Wait for window to appear, then focus
    vim.defer_fn(function()
      local new_wins = vim.fn.win_findbuf(claude_buf)
      if #new_wins > 0 then
        vim.api.nvim_set_current_win(new_wins[1])
        if vim.api.nvim_get_mode().mode == 'n' then
          vim.cmd('startinsert!')
        end
      end
    end, 50)
  end
  -- If state == OPENING and no window, just wait - it's being created
end

--------------------------------------------------------------------------------
-- Autocommand Setup (Event-Driven, No Timers)
--------------------------------------------------------------------------------

--- Setup terminal monitoring with autocommands
--- Call once during plugin initialization
--- Creates TermOpen/TermClose autocommands for state management
function M.setup()
  -- Monitor terminal open
  vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*claude*",
    callback = function(args)
      state = M.State.OPENING

      -- TextChanged autocommand as FALLBACK ONLY
      -- Primary readiness signal is SessionStart hook -> on_claude_ready()
      local ready_check_group = vim.api.nvim_create_augroup(
        "ClaudeReadyCheck_" .. args.buf,
        { clear = true }
      )

      vim.api.nvim_create_autocmd("TextChanged", {
        group = ready_check_group,
        buffer = args.buf,
        callback = function()
          if M.is_terminal_ready(args.buf) then
            state = M.State.READY
            M.focus_terminal(args.buf)
            M.flush_queue(args.buf)
            vim.api.nvim_del_augroup_by_id(ready_check_group)
          end
        end
      })

      -- NOTE: SessionStart hook will call on_claude_ready() when ready
      -- TextChanged only fires if hook is not configured or fails
    end
  })

  -- Monitor terminal close
  vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*claude*",
    callback = function()
      state = M.State.CLOSED

      -- Clear any pending commands
      pending_commands = {}
    end
  })
end

return M
