-- Neovim STT (Speech-to-Text) Plugin
-- Uses Vosk for offline speech recognition
--
-- Requirements:
--   - parecord (pulseaudio-utils or pipewire-pulse)
--   - vosk Python package with vosk-model-small-en-us
--   - ~/.local/bin/vosk-transcribe.py (transcription helper)
--
-- Configuration (optional):
--   vim.g.stt_model_path = "~/.local/share/vosk/vosk-model-small-en-us"
--   vim.g.stt_record_timeout = 30  -- max seconds for recording
--   vim.g.stt_sample_rate = 16000  -- audio sample rate
--
-- Usage:
--   <leader>vr - Start recording
--   <leader>vs - Stop recording and transcribe
--   <leader>vt - Toggle recording (start if not recording, stop if recording)
--
-- Author: Claude Code Integration
-- License: MIT

local M = {}

-- State
local recording_job_id = nil
local recording_file = "/tmp/nvim-stt-recording.wav"
local is_recording = false

-- Configuration with defaults
local function get_config()
  return {
    model_path = vim.g.stt_model_path or vim.fn.expand("~/.local/share/vosk/vosk-model-small-en-us"),
    transcribe_script = vim.g.stt_transcribe_script or vim.fn.expand("~/.local/bin/vosk-transcribe.py"),
    record_timeout = vim.g.stt_record_timeout or 30,
    sample_rate = vim.g.stt_sample_rate or 16000,
    recording_file = vim.g.stt_recording_file or recording_file,
  }
end

-- Helper: show message
local function notify(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify("[STT] " .. msg, level)
end

-- Helper: check if command exists
local function command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Start recording audio
function M.start_recording()
  if is_recording then
    notify("Already recording! Press <leader>vs to stop.", vim.log.levels.WARN)
    return
  end

  local config = get_config()

  -- Check for parecord
  if not command_exists("parecord") then
    notify("parecord not found. Install pulseaudio-utils or pipewire-pulse.", vim.log.levels.ERROR)
    return
  end

  -- Clean up any existing recording file
  vim.fn.delete(config.recording_file)

  -- Start recording with parecord
  -- Uses mono channel at 16kHz for optimal Vosk performance
  local cmd = {
    "parecord",
    "--channels=1",
    "--rate=" .. config.sample_rate,
    "--file-format=wav",
    config.recording_file
  }

  recording_job_id = vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code, _)
      is_recording = false
      recording_job_id = nil

      if exit_code == 0 or exit_code == 143 then
        -- 143 = SIGTERM (normal stop), 0 = natural exit
        M.transcribe_and_insert()
      else
        notify("Recording failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        -- Only log non-empty stderr
        for _, line in ipairs(data) do
          if line ~= "" then
            notify("Recording stderr: " .. line, vim.log.levels.DEBUG)
          end
        end
      end
    end,
  })

  if recording_job_id > 0 then
    is_recording = true
    notify("Recording started... Press <leader>vs to stop", vim.log.levels.INFO)

    -- Set up auto-stop timeout
    vim.defer_fn(function()
      if is_recording then
        notify("Recording timeout reached, auto-stopping", vim.log.levels.WARN)
        M.stop_recording()
      end
    end, config.record_timeout * 1000)
  else
    notify("Failed to start recording", vim.log.levels.ERROR)
  end
end

-- Stop recording
function M.stop_recording()
  if not is_recording or not recording_job_id then
    notify("Not currently recording", vim.log.levels.WARN)
    return
  end

  -- Send SIGTERM to parecord to stop gracefully
  vim.fn.jobstop(recording_job_id)
  -- Note: on_exit callback will handle transcription
  notify("Stopping recording...", vim.log.levels.INFO)
end

-- Toggle recording state
function M.toggle_recording()
  if is_recording then
    M.stop_recording()
  else
    M.start_recording()
  end
end

-- Transcribe recording and insert at cursor
function M.transcribe_and_insert()
  local config = get_config()

  -- Check if recording file exists
  if vim.fn.filereadable(config.recording_file) ~= 1 then
    notify("Recording file not found: " .. config.recording_file, vim.log.levels.ERROR)
    return
  end

  -- Check for transcription script
  if vim.fn.filereadable(config.transcribe_script) ~= 1 then
    notify("Transcription script not found: " .. config.transcribe_script, vim.log.levels.ERROR)
    return
  end

  -- Check for Python
  if not command_exists("python3") then
    notify("python3 not found", vim.log.levels.ERROR)
    return
  end

  notify("Transcribing...", vim.log.levels.INFO)

  -- Save current position for insertion
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_buf = vim.api.nvim_get_current_buf()

  -- Run transcription asynchronously
  local cmd = {
    "python3",
    config.transcribe_script,
    config.recording_file,
    config.model_path,
  }

  local output_lines = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output_lines, line)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        for _, line in ipairs(data) do
          if line ~= "" then
            notify("Transcription error: " .. line, vim.log.levels.ERROR)
          end
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        notify("Transcription failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        return
      end

      local text = table.concat(output_lines, " ")

      if text == "" then
        notify("No speech detected", vim.log.levels.WARN)
        return
      end

      -- Insert text at the saved cursor position
      vim.schedule(function()
        -- Make sure we're still in the same buffer
        if vim.api.nvim_get_current_buf() == current_buf then
          -- Insert after cursor position
          vim.api.nvim_win_set_cursor(0, cursor_pos)
          vim.api.nvim_put({text}, 'c', true, true)
          notify("Inserted: " .. string.sub(text, 1, 50) .. (string.len(text) > 50 and "..." or ""), vim.log.levels.INFO)
        else
          -- Different buffer, use unnamed register
          vim.fn.setreg('"', text)
          notify("Text saved to register: " .. string.sub(text, 1, 50) .. (string.len(text) > 50 and "..." or ""), vim.log.levels.INFO)
        end
      end)

      -- Clean up recording file
      vim.fn.delete(config.recording_file)
    end,
  })
end

-- Check dependencies and report status
function M.health()
  local config = get_config()
  local issues = {}

  -- Check parecord
  if not command_exists("parecord") then
    table.insert(issues, "parecord not found - install pulseaudio-utils or pipewire-pulse")
  end

  -- Check python3
  if not command_exists("python3") then
    table.insert(issues, "python3 not found")
  end

  -- Check transcription script
  if vim.fn.filereadable(config.transcribe_script) ~= 1 then
    table.insert(issues, "Transcription script not found at " .. config.transcribe_script)
  end

  -- Check model directory
  if vim.fn.isdirectory(config.model_path) ~= 1 then
    table.insert(issues, "Vosk model not found at " .. config.model_path)
  end

  if #issues == 0 then
    notify("All dependencies satisfied!", vim.log.levels.INFO)
    return true
  else
    for _, issue in ipairs(issues) do
      notify("Issue: " .. issue, vim.log.levels.ERROR)
    end
    return false
  end
end

-- Setup keymappings
function M.setup(opts)
  opts = opts or {}

  -- Apply user configuration
  if opts.model_path then
    vim.g.stt_model_path = opts.model_path
  end
  if opts.transcribe_script then
    vim.g.stt_transcribe_script = opts.transcribe_script
  end
  if opts.record_timeout then
    vim.g.stt_record_timeout = opts.record_timeout
  end
  if opts.sample_rate then
    vim.g.stt_sample_rate = opts.sample_rate
  end

  -- Note: Keymaps are now configured in which-key.lua for centralized management
  -- The plugin itself no longer sets keymaps to avoid duplicates
  if opts.keymaps ~= false then
    -- Only set keymaps if explicitly requested via opts.keymaps = true
    -- This allows manual setup for users who don't use which-key
    if opts.keymaps == true then
      local keymap_opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>vr', M.start_recording, vim.tbl_extend("force", keymap_opts, { desc = "STT: Start recording" }))
      vim.keymap.set('n', '<leader>vs', M.stop_recording, vim.tbl_extend("force", keymap_opts, { desc = "STT: Stop recording" }))
      vim.keymap.set('n', '<leader>vt', M.toggle_recording, vim.tbl_extend("force", keymap_opts, { desc = "STT: Toggle recording" }))
      vim.keymap.set('n', '<leader>vh', M.health, vim.tbl_extend("force", keymap_opts, { desc = "STT: Health check" }))
    end
  end

  -- Create user commands
  vim.api.nvim_create_user_command('STTStart', M.start_recording, { desc = 'Start STT recording' })
  vim.api.nvim_create_user_command('STTStop', M.stop_recording, { desc = 'Stop STT recording' })
  vim.api.nvim_create_user_command('STTToggle', M.toggle_recording, { desc = 'Toggle STT recording' })
  vim.api.nvim_create_user_command('STTHealth', M.health, { desc = 'Check STT dependencies' })

end

return M
