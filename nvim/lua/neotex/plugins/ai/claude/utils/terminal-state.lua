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

  vim.notify(
    string.format("[DEBUG] queue_command: Added '%s' to queue (total: %d)", command_text, #pending_commands),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  local claude_buf = M.find_claude_terminal()

  if not claude_buf then
    -- No terminal exists
    vim.notify(
      "[DEBUG] queue_command: No terminal exists",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
    if opts.ensure_open then
      vim.notify(
        "[DEBUG] queue_command: Opening ClaudeCode",
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )
      vim.cmd('ClaudeCode')  -- SessionStart hook will call on_claude_ready()
    end
    -- Queue will be flushed by hook or TextChanged fallback
    return
  end

  -- Terminal exists - check window state BEFORE focusing
  local wins = vim.fn.win_findbuf(claude_buf)
  local needs_reopen = (#wins == 0)

  vim.notify(
    string.format("[DEBUG] queue_command: Terminal exists (buf=%d, wins=%d, needs_reopen=%s)",
      claude_buf, #wins, needs_reopen),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  -- Focus terminal (might trigger async window open)
  M.focus_terminal(claude_buf)

  -- Smart delay based on pre-check state
  if needs_reopen then
    -- Window was closed, needs time to reopen and settle
    vim.notify(
      "[DEBUG] queue_command: Scheduling flush in 150ms (window needs reopen)",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
    vim.defer_fn(function()
      vim.notify(
        "[DEBUG] queue_command: Executing deferred flush (150ms elapsed)",
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )
      M.flush_queue(claude_buf)
    end, 150)  -- Increased from 100ms for reliability
  else
    -- Window already visible, flush after current event loop completes
    -- This ensures mode changes from focus_terminal() complete
    vim.notify(
      "[DEBUG] queue_command: Scheduling flush via vim.schedule (window visible)",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
    vim.schedule(function()
      vim.notify(
        "[DEBUG] queue_command: Executing scheduled flush",
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )
      M.flush_queue(claude_buf)
    end)
  end
end

--- Send all queued commands to terminal
--- Only sends commands that are fresh (< 30 seconds old)
--- @param claude_buf number Terminal buffer handle
function M.flush_queue(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    vim.notify(
      "[DEBUG] flush_queue: Buffer invalid",
      vim.log.levels.WARN,
      { title = "Claude Debug" }
    )
    return
  end

  vim.notify(
    string.format("[DEBUG] flush_queue: Starting flush, queue size=%d", #pending_commands),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  local current_mode = vim.api.nvim_get_mode().mode
  vim.notify(
    string.format("[DEBUG] flush_queue: Current mode before flushing: %s", current_mode),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  while #pending_commands > 0 do
    local cmd = table.remove(pending_commands, 1)

    vim.notify(
      string.format("[DEBUG] flush_queue: Processing command '%s'", cmd.text),
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )

    -- Check if command is still fresh (< 30 seconds old)
    if os.time() - cmd.timestamp < 30 then
      local success, err = M.send_to_terminal(claude_buf, cmd.text, cmd.opts)

      vim.notify(
        string.format("[DEBUG] flush_queue: send_to_terminal result: success=%s, err=%s", success, err or "nil"),
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )

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

  local mode_after_flush = vim.api.nvim_get_mode().mode
  vim.notify(
    string.format("[DEBUG] flush_queue: Flush complete, mode=%s, queue size=%d",
      mode_after_flush, #pending_commands),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )
end

--- Called by SessionStart hook when Claude is ready
--- This is the primary readiness detection mechanism
--- Hook script: ~/.config/nvim/scripts/claude-ready-signal.sh
--- @see ~/.claude/settings.json for hook configuration
function M.on_claude_ready()
  vim.notify(
    string.format("[DEBUG] on_claude_ready: Called, queue size=%d", #pending_commands),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  state = M.State.READY

  local claude_buf = M.find_claude_terminal()
  vim.notify(
    string.format("[DEBUG] on_claude_ready: claude_buf=%s, queue size=%d",
      claude_buf or "nil", #pending_commands),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  if claude_buf and #pending_commands > 0 then
    vim.notify(
      "[DEBUG] on_claude_ready: Calling focus_terminal and flush_queue",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
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

  vim.notify(
    string.format("[DEBUG] send_to_terminal: Sending '%s', auto_focus=%s",
      command_text, opts.auto_focus or false),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  -- Get terminal job ID
  local ok, job_id = pcall(vim.api.nvim_buf_get_var, claude_buf, 'terminal_job_id')
  if not ok or not job_id then
    vim.notify(
      "[DEBUG] send_to_terminal: Failed to get job_id",
      vim.log.levels.ERROR,
      { title = "Claude Debug" }
    )
    return false, "no_job_id"
  end

  vim.notify(
    string.format("[DEBUG] send_to_terminal: Got job_id=%s, sending via chansend", job_id),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  -- Send command via chansend (without newline unless in text)
  vim.fn.chansend(job_id, command_text)

  vim.notify(
    "[DEBUG] send_to_terminal: chansend complete",
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  -- Optionally focus terminal and enter insert mode
  if opts.auto_focus then
    vim.notify(
      "[DEBUG] send_to_terminal: auto_focus=true, calling focus_terminal",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
    M.focus_terminal(claude_buf)
  end

  return true, nil
end

--- Focus Claude terminal window and optionally enter insert mode
--- If window is closed but buffer exists, reopens the window
--- @param claude_buf number Terminal buffer handle
function M.focus_terminal(claude_buf)
  if not vim.api.nvim_buf_is_valid(claude_buf) then
    vim.notify(
      "[DEBUG] focus_terminal: Buffer invalid",
      vim.log.levels.WARN,
      { title = "Claude Debug" }
    )
    return
  end

  local wins = vim.fn.win_findbuf(claude_buf)
  local current_mode = vim.api.nvim_get_mode().mode

  vim.notify(
    string.format("[DEBUG] focus_terminal: buf=%d, wins=%d, mode=%s, state=%s",
      claude_buf, #wins, current_mode, state),
    vim.log.levels.INFO,
    { title = "Claude Debug" }
  )

  if #wins > 0 then
    -- Window exists, focus it
    vim.notify(
      string.format("[DEBUG] focus_terminal: Focusing window %d", wins[1]),
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
    vim.api.nvim_set_current_win(wins[1])

    -- Enter insert mode if currently in normal mode
    local mode_after_focus = vim.api.nvim_get_mode().mode
    vim.notify(
      string.format("[DEBUG] focus_terminal: Mode after focus: %s", mode_after_focus),
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )

    if mode_after_focus == 'n' then
      vim.notify(
        "[DEBUG] focus_terminal: Entering insert mode",
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )
      vim.cmd('startinsert!')

      local mode_after_insert = vim.api.nvim_get_mode().mode
      vim.notify(
        string.format("[DEBUG] focus_terminal: Mode after startinsert: %s", mode_after_insert),
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )
    end
  elseif state ~= M.State.OPENING then
    -- Window doesn't exist but buffer does - reopen Claude Code sidebar
    vim.notify(
      "[DEBUG] focus_terminal: No window, calling ClaudeCode to toggle",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
    vim.cmd('ClaudeCode')

    -- Wait for window to appear, then focus
    vim.defer_fn(function()
      local new_wins = vim.fn.win_findbuf(claude_buf)
      vim.notify(
        string.format("[DEBUG] focus_terminal: After 50ms, new_wins=%d", #new_wins),
        vim.log.levels.INFO,
        { title = "Claude Debug" }
      )

      if #new_wins > 0 then
        vim.api.nvim_set_current_win(new_wins[1])
        local deferred_mode = vim.api.nvim_get_mode().mode

        vim.notify(
          string.format("[DEBUG] focus_terminal: Deferred focus, mode=%s", deferred_mode),
          vim.log.levels.INFO,
          { title = "Claude Debug" }
        )

        if deferred_mode == 'n' then
          vim.notify(
            "[DEBUG] focus_terminal: Deferred entering insert mode",
            vim.log.levels.INFO,
            { title = "Claude Debug" }
          )
          vim.cmd('startinsert!')
        end
      end
    end, 50)
  else
    vim.notify(
      "[DEBUG] focus_terminal: State is OPENING, waiting for window creation",
      vim.log.levels.INFO,
      { title = "Claude Debug" }
    )
  end
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
