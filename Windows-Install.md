# Windows Installation Guide

This guide provides detailed instructions for installing the NeoTex Neovim configuration on Windows, using either Windows Subsystem for Linux (WSL) or native Windows installation.

## Option 1: WSL2 Installation (Recommended)

Using Windows Subsystem for Linux provides the most compatible environment for this Neovim configuration.

### Install WSL2

1. Open PowerShell as Administrator and run:

```powershell
wsl --install
```

2. Restart your computer
3. Set up Ubuntu when prompted (username and password)

### Follow Debian/Ubuntu Instructions

Once WSL2 is set up, follow the [Debian Installation Guide](./Debian-Install.md) with these Windows-specific additions:

#### Windows Terminal Setup

For a better terminal experience:

1. Install [Windows Terminal](https://apps.microsoft.com/detail/windows-terminal/9N0DX20HK701) from the Microsoft Store
2. Open Windows Terminal Settings (Ctrl+,)
3. Set Ubuntu as your default profile
4. Install a Nerd Font:
   - Download [RobotoMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/RobotoMono.zip)
   - Extract and install all fonts (right-click > Install)
   - In Windows Terminal settings, change the font to "RobotoMono Nerd Font"

#### GUI Applications Support

For Zotero and PDF viewers:

1. Enable WSL GUI app support:

```powershell
# In PowerShell (Admin)
wsl --update
```

2. Install an X server (optional but recommended for better performance):
   - Download and install [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
   - Run XLaunch with these settings:
     - Multiple windows
     - Display number: 0
     - Start no client
     - Check "Disable access control"
   - Add to your WSL ~/.bashrc or ~/.zshrc:

```bash
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1
```

### File System Considerations

When working with files in WSL:

- Store all your files within the WSL file system, not on Windows drives
- Access WSL files from Windows using: `\\wsl$\Ubuntu\home\yourusername\`
- Access Windows files from WSL at `/mnt/c/` (slower performance)

## Option 2: Native Windows Installation

### Install Neovim

1. Install [Chocolatey](https://chocolatey.org/install) package manager
2. Open PowerShell as Administrator and run:

```powershell
choco install neovim -y
```

### Install Dependencies

```powershell
# Core tools
choco install git -y
choco install lazygit -y
choco install python3 -y
choco install nodejs -y
choco install fzf -y
choco install ripgrep -y
choco install pandoc -y
choco install stylua -y
choco install wget -y

# Install Python support for Neovim
pip install pynvim

# Install Node.js modules
npm install -g neovim
```

### Install Nerd Font

1. Download [RobotoMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/RobotoMono.zip)
2. Extract and install all fonts (right-click > Install)

### Create Neovim Config Directory

```powershell
# Create config directory
mkdir "$env:LOCALAPPDATA\nvim"
```

### Clone the Configuration

```powershell
# Go to Neovim config directory
cd "$env:LOCALAPPDATA\nvim"

# Initialize git repo
git init
git remote add origin https://github.com/benbrastmckie/.config.git
git pull origin master
```

### LaTeX Installation

1. Install MiKTeX:

```powershell
choco install miktex -y
```

2. Open MiKTeX Console and set it to install missing packages automatically

### PDF Viewer Setup

Install SumatraPDF:

```powershell
choco install sumatrapdf -y
```

Configure SumatraPDF for inverse search:
1. Open SumatraPDF > Settings > Options
2. Set inverse search command to:
   - `cmd /c start /min nvim.exe --headless -c "VimtexInverseSearch %l '%f'"`

Update VimTeX configuration:

```powershell
nvim "$env:LOCALAPPDATA\nvim\lua\neotex\plugins\vimtex.lua"
```

Replace occurrences of 'okular' and 'zathura' with 'sumatrapdf'.

### Zotero Integration

1. Download and install [Zotero](https://www.zotero.org/download/)
2. Install Better BibTeX:
   - Download from [here](https://retorque.re/zotero-better-bibtex/installation/)
   - In Zotero, go to Tools > Add-ons
   - Click the gear icon and select "Install Add-on From File"
   - Navigate to the downloaded .xpi file

3. Configure Better BibTeX:
   - In Zotero, go to Edit > Preferences > Better BibTeX
   - Set citation key format to `auth.fold + year`
   - Go to Edit > Preferences > Sync and set up your account
   - Check 'On item change' at the bottom left
   - Switch to the 'Automatic Export' tab and check 'On Change'

4. Create Bibliography Directory:

```powershell
mkdir -p "$env:USERPROFILE\texmf\bibtex\bib"
```

5. Export Library:
   - Right-click your library folder
   - Select "Export Library"
   - Choose "Better BibTeX" format and check "Keep Updated"
   - Save as "Zotero.bib" to the bibtex directory above

6. Update Telescope configuration:

```powershell
nvim "$env:LOCALAPPDATA\nvim\lua\neotex\plugins\telescope.lua"
```

Update the path to match your Windows path structure.

## Terminal Recommendations

### Windows Terminal (Recommended)

Install from the Microsoft Store and configure:
1. Set default profile to PowerShell or WSL
2. Set font to RobotoMono Nerd Font
3. Enable acrylic transparency if desired
4. Configure colors to match your theme

### Alternative: Alacritty

```powershell
choco install alacritty -y
```

Create configuration:

```powershell
mkdir "$env:APPDATA\alacritty"
# Edit configuration to set font and other preferences
nvim "$env:APPDATA\alacritty\alacritty.yml"
```

## Git Configuration

### Set Username and Email

```powershell
git config --global user.name "YOUR-USERNAME"
git config --global user.email "YOUR-EMAIL"
```

### Add SSH Key to GitHub

Generate an SSH key:

```powershell
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Start the SSH agent:

```powershell
# Start the ssh-agent
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
ssh-add ~\.ssh\id_rsa
```

Add the key to your GitHub account:
1. Copy the key:
   ```powershell
   Get-Content ~\.ssh\id_rsa.pub | clip
   ```
2. Go to GitHub > Profile > Settings > SSH and GPG Keys
3. Click "New SSH Key"
4. Paste your key and save

### Add Personal Access Token

1. Create a token at GitHub.com > Settings > Developer settings > Personal Access Tokens
2. Set no expiration date
3. Select "repo" scope
4. Copy the token and save it temporarily
5. Configure Git to remember credentials:

```powershell
git config --global credential.helper store
```

## Windows Key Remapping (Optional)

For better ergonomics, use PowerToys to remap keys:

1. Install [PowerToys](https://github.com/microsoft/PowerToys/releases/)
2. Open PowerToys > Keyboard Manager
3. Add key remappings:
   - Caps Lock → Escape
   - Any other preferred remappings

## Verification

Test your setup by:

1. Opening Neovim
2. Creating a new LaTeX file with `<space>tp`
3. Building with `<space>b` to ensure PDF generation works
4. Using `<space>fc` to verify citation search works
5. Running `:checkhealth` to confirm all systems are operational

## Troubleshooting

### Common Issues

1. **Path issues**: Ensure all installed programs are in your PATH
2. **Font rendering problems**: Verify nerd font installation and terminal configuration
3. **PDF viewer integration**: Check SumatraPDF configuration for inverse search
4. **Missing icons**: Confirm terminal is using Nerd Font
5. **LaTeX compilation fails**: Check MiKTeX installation and ensure packages are installed

### Windows-Specific Fixes

1. **Performance issues**: Try adding these to your init.lua:
   ```lua
   vim.opt.shellslash = true  -- Use forward slashes in file paths
   vim.opt.shell = "pwsh.exe" -- Use PowerShell for better performance
   ```

2. **File path problems**: Use forward slashes (/) or escaped backslashes (\\\\) in all file paths

3. **WSL file access is slow**: Store all working files within the WSL file system

For further assistance, open an issue on the GitHub repository.