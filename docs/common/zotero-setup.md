# Zotero Integration Setup

This guide covers setting up Zotero for bibliography management with the Neovim configuration.

## Overview

Zotero integration provides:
- Citation management from within Neovim
- Automatic bibliography generation
- Citation key search with Telescope
- Automatic export to BibTeX format

## Prerequisites

- Zotero application installed
- LaTeX distribution installed (see [Prerequisites](prerequisites.md))
- Neovim configuration installed (see [Main Installation](../../nvim/docs/INSTALLATION.md))

## Installation

### Install Zotero

Download and install from [zotero.org](https://www.zotero.org/download/)

**Linux**:
```bash
# Download Zotero tarball from zotero.org
sudo mv ~/Downloads/Zotero_linux-x86_64 /opt/zotero
cd /opt/zotero
sudo ./set_launcher_icon
sudo ln -s /opt/zotero/zotero.desktop ~/.local/share/applications/zotero.desktop
```

**macOS**:
Download and install the DMG package

**Windows**:
Download and run the installer

### Install Better BibTeX Plugin

Better BibTeX provides enhanced BibTeX export and citation key management.

1. Download the latest release from [retorque.re/zotero-better-bibtex](https://retorque.re/zotero-better-bibtex/installation/)
2. In Zotero, go to Tools → Add-ons
3. Click the gear icon and select "Install Add-on From File"
4. Navigate to the downloaded .xpi file
5. Restart Zotero

## Configuration

### Configure Better BibTeX

1. In Zotero, go to Edit → Preferences → Better BibTeX
2. Set citation key format to `[auth][year]`
   - This generates keys like "Smith2023"
   - Consistent format for easy citation
3. Go to Edit → Preferences → Sync
   - Set up your Zotero account or create one
   - Enable synchronization across devices
4. Check 'On item change' at the bottom left
   - Automatically updates citation keys
5. Switch to the 'Automatic Export' tab
   - Check 'On Change'
   - Enables automatic BibTeX export

### Create Bibliography Directory

Create the directory where your bibliography will be stored:

```bash
mkdir -p ~/texmf/bibtex/bib
```

If you have custom bibliography styles:
```bash
cp -R ~/.config/latex/bst ~/texmf/bibtex
```

### Export Library

Configure automatic export to keep your bibliography updated:

1. In Zotero, right-click your library folder
   - Or right-click a specific collection to export only that collection
2. Select "Export Library" (or "Export Collection")
3. Choose "Better BibTeX" format
4. Check "Keep Updated"
   - This enables automatic export when you add/modify entries
5. Save as "Zotero.bib" to `~/texmf/bibtex/bib`

## Usage in Neovim

### Search Citations

With a LaTeX file open:

```vim
<leader>fc    " Search citations with Telescope
```

This opens a fuzzy finder with your Zotero library:
- Search by author, title, or year
- Preview citation details
- Press Enter to insert citation key

### Insert Citations

1. Use citation search (`<leader>fc`) to find reference
2. Press Enter to insert `\cite{AuthorYear}`
3. Or manually type `\cite{` and use completion

### Update Bibliography

Your bibliography updates automatically when you:
- Add new references to Zotero
- Modify existing references
- Change citation keys

If auto-export fails, manually export:
1. Right-click library in Zotero
2. Select "Export Library"
3. Choose existing export location
4. Overwrite when prompted

## Troubleshooting

### Citations Not Found

**Issue**: Telescope citation search shows no results

**Solutions**:
1. Verify export location:
   ```bash
   ls ~/texmf/bibtex/bib/Zotero.bib
   ```
2. Check file has content:
   ```bash
   head ~/texmf/bibtex/bib/Zotero.bib
   ```
3. Clear VimTeX cache:
   ```vim
   :VimtexClearCache kpsewhich
   ```

### Citation Keys Not Updating

**Issue**: Modified references show old citation keys

**Solutions**:
1. In Zotero, verify Better BibTeX settings:
   - Edit → Preferences → Better BibTeX
   - Check 'On item change' is enabled
2. Manually refresh:
   - Right-click reference
   - Better BibTeX → Refresh BibTeX key
3. Re-export library if auto-export failed

### Bibliography Not Found During Compilation

**Issue**: LaTeX compilation fails with "Bibliography not found"

**Solutions**:
1. Verify bibliography path in your .tex file:
   ```latex
   \addbibresource{~/texmf/bibtex/bib/Zotero.bib}
   ```
2. Use relative path if in same directory:
   ```latex
   \addbibresource{Zotero.bib}
   ```
3. Clear LaTeX build cache:
   ```vim
   :VimtexClean
   ```

## Advanced Configuration

### Multiple Collections

Export different collections for different projects:

1. Create collection in Zotero for each project
2. Export each collection to project directory:
   - `~/project1/references.bib`
   - `~/project2/references.bib`
3. Reference appropriate file in LaTeX document

### Custom Citation Styles

Better BibTeX supports custom citation key formats:

```
[auth:lower][year]           → smith2023
[auth:upper][shorttitle:lower][year] → SMITHIntroduction2023
[authEtAl:lower]_[year]      → smith_et_al_2023
```

Configure in Edit → Preferences → Better BibTeX → Citation keys

### Cloud Synchronization

Enable Zotero sync for access across devices:

1. Create account at [zotero.org](https://www.zotero.org/)
2. In Zotero: Edit → Preferences → Sync
3. Enter credentials and enable sync
4. Your library syncs automatically

## Navigation

- [Back to Installation Documentation Index](../README.md)
- [Prerequisites Reference](prerequisites.md)
- [Main Installation Guide](../../nvim/docs/INSTALLATION.md)
- [Advanced Setup Guide](../../nvim/docs/ADVANCED_SETUP.md)
