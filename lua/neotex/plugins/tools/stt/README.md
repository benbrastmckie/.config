# STT (Speech-to-Text) Plugin

Offline speech recognition for Neovim using Vosk.

## Features

- **Offline recognition**: No internet required, Vosk models run locally
- **Terminal mode support**: Works in Claude Code sidebar and other terminal buffers
- **Auto-transcription**: Records → stops → transcribes → inserts at cursor
- **Configurable timeout**: Default 30 seconds max recording length

## Quick Start

### Start/Stop Recording

```vim
<leader>vr     " Start recording
<leader>vs     " Stop and transcribe
<leader>vv     " Toggle recording

<C-\>          " Toggle (works in normal AND terminal modes)
```

### Health Check

```vim
:STTHealth
" or
<leader>vh
```

## Terminal Mode Support

The `<C-\>` keybinding includes a **terminal-mode mapping** required for Claude Code sidebar:

```lua
-- Terminal-mode mapping
vim.keymap.set('t', '<C-\\>', function()
  vim.cmd('stopinsert')  -- Exit terminal mode temporarily
  M.toggle_recording()
end, {
  noremap = true,
  silent = true,
  desc = 'STT: Toggle recording (terminal mode)'
})
```

### Why Terminal Mode?

Terminal buffers intercept keybindings before Neovim can process them. Without a terminal-mode mapping, `<C-\>` would be sent to the terminal application (Claude Code) instead of triggering STT.

**Behavior**:
1. Press `<C-\>` in Claude Code sidebar
2. Exits terminal mode (`stopinsert`)
3. Starts/stops recording
4. Returns to insert mode after transcription completes

## Dependencies

Install requirements:

```bash
# PulseAudio/PipeWire
sudo pacman -S pulseaudio-utils  # or pipewire-pulse

# Python and Vosk
pip install vosk

# Download Vosk model
mkdir -p ~/.local/share/vosk
cd ~/.local/share/vosk
wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
unzip vosk-model-small-en-us-0.15.zip
mv vosk-model-small-en-us-0.15 vosk-model-small-en-us

# Install transcription helper
# (should already exist in ~/.local/bin/vosk-transcribe.py)
```

## Configuration

Optional configuration (set in `init.lua` or via globals):

```lua
vim.g.stt_model_path = "~/.local/share/vosk/vosk-model-small-en-us"
vim.g.stt_transcribe_script = "~/.local/bin/vosk-transcribe.py"
vim.g.stt_record_timeout = 30  -- max seconds
vim.g.stt_sample_rate = 16000  -- Hz
```

## Usage Commands

```vim
:STTStart       " Start recording
:STTStop        " Stop and transcribe
:STTToggle      " Toggle recording
:STTHealth      " Check dependencies
```

## Keybindings Reference

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>vr` | Normal | Start recording |
| `<leader>vs` | Normal | Stop recording and transcribe |
| `<leader>vv` | Normal | Toggle recording |
| `<leader>vh` | Normal | Health check |
| `<C-\>` | Normal | Toggle recording (alternative) |
| `<C-\>` | Terminal | Toggle recording (works in Claude Code) |

## Troubleshooting

### No audio recording

**Check parecord**:
```bash
which parecord
parecord --list-devices
```

**Test recording manually**:
```bash
parecord --channels=1 --rate=16000 --file-format=wav /tmp/test.wav
# Speak for 5 seconds, then Ctrl-C
aplay /tmp/test.wav
```

### Transcription fails

**Check Python and Vosk**:
```bash
python3 -c "import vosk; print('Vosk OK')"
```

**Check model exists**:
```bash
ls -la ~/.local/share/vosk/vosk-model-small-en-us
```

**Test transcription script**:
```bash
python3 ~/.local/bin/vosk-transcribe.py /tmp/test.wav ~/.local/share/vosk/vosk-model-small-en-us
```

### Doesn't work in Claude Code sidebar

**Verify terminal-mode mapping**:
```vim
:verbose map <C-\>
```

Should show:
```
t  <C-\>       * <Lua function>
                 STT: Toggle recording (terminal mode)
n  <C-\>       * <Lua function>
                 STT: Toggle recording (Ctrl-\)
```

**Check buffer type**:
```vim
:echo &buftype
" Should show 'terminal' in Claude Code
```

### Empty transcriptions

- Speak clearly and close to microphone
- Reduce background noise
- Vosk small model has limited vocabulary (use medium/large for better results)
- Check recording file was created: `ls -lh /tmp/nvim-stt-recording.wav`

## Architecture

### Recording Flow

```
User presses <C-\> (terminal mode)
    │
    ▼
Exits terminal mode (stopinsert)
    │
    ▼
M.toggle_recording() called
    │
    ▼
jobstart(parecord) -> /tmp/nvim-stt-recording.wav
    │
    ▼
User speaks (up to 30s)
    │
    ▼
User presses <C-\> again
    │
    ▼
jobstop(parecord) sends SIGTERM
    │
    ▼
on_exit callback triggered
    │
    ▼
M.transcribe_and_insert()
    │
    ▼
jobstart(python3 vosk-transcribe.py)
    │
    ▼
on_exit: insert text at cursor
```

### State Management

```lua
local recording_job_id = nil    -- parecord job ID
local is_recording = false       -- recording state
local recording_file = "/tmp/nvim-stt-recording.wav"
```

## Integration with Claude Code

The STT plugin integrates with Claude Code sidebar via:

1. **Terminal-mode keybinding**: `<C-\>` works in terminal buffers
2. **SessionStart hook**: Claude signals Neovim when ready (see `.claude/docs/guides/neovim-integration.md`)
3. **TTS notifications**: Piper announces when Claude completes (see `.claude/hooks/tts-notify.sh`)

**Full integration docs**: See `.claude/docs/guides/neovim-integration.md` in your project root.

## Files

- `init.lua` - Main plugin implementation
- `README.md` - This file

## See Also

- [MAPPINGS.md](../../../../docs/MAPPINGS.md) - Full keybinding reference
- [Claude Code Integration](../../../ai/claude/README.md) - Claude Code plugin
- [Neovim Integration Guide](?path=.claude/docs/guides/neovim-integration.md) - Claude Code hooks
