# Himalaya Email Client Installation Guide

A comprehensive guide for setting up Himalaya email client with local storage and IMAP synchronization for both NixOS and non-NixOS users.

## Overview

This installation creates a hybrid email setup that combines:
- **Local email storage** (Maildir format) for offline access and speed
- **Automatic IMAP synchronization** (every 5 minutes) with servers
- **OAuth2 authentication** for secure access
- **Multi-account support** for personal and work emails

## Architecture

```
IMAP Server <--[mbsync]--> Local Maildir <--> Himalaya CLI <--> NeoVim Interface
     |                          |                                    |
  Gmail/Work              ~/Mail/Gmail                          User Actions
                          ~/Mail/Work
```

## Prerequisites

### For All Users
- Gmail account with 2FA enabled
- Google Cloud Console access for OAuth2 setup

### For NixOS Users
- NixOS with home-manager (recommended)
- Flakes enabled (optional but recommended)

### For Non-NixOS Users
- Linux/macOS system
- Package manager (apt, yum, brew, etc.)

---

## Part 1: OAuth2 Setup (All Users)

### 1. Create Google Cloud OAuth2 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select existing one
3. Enable the Gmail API:
   - Go to "APIs & Services" → "Library"
   - Search for "Gmail API" and enable it
4. Create OAuth2 credentials:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth 2.0 Client IDs"
   - Choose "Desktop application"
   - Note the **Client ID** and **Client Secret**

### 2. Configure OAuth Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. Choose "External" user type
3. Fill in application name (e.g., "Personal Email Client")
4. Add your email to "Test users" section
5. Add these scopes:
   - `https://mail.google.com/` (required)
   - `https://www.googleapis.com/auth/contacts` (optional)
   - `https://www.googleapis.com/auth/calendar` (optional)
   - `https://www.googleapis.com/auth/carddav` (optional)

---

## Part 2A: NixOS Installation

### 1. System Configuration

Add to your NixOS configuration:

```nix
# System packages
environment.systemPackages = with pkgs; [
  himalaya          # CLI email client
  isync            # For Gmail/IMAP sync (mbsync)
  msmtp            # For sending emails
  pass             # Password manager for OAuth2 tokens
  gnupg            # Required for pass
  libsecret        # For secret-tool command
  w3m              # Terminal web browser for HTML email viewing
  cyrus-sasl-xoauth2  # XOAUTH2 SASL plugin
];

# SASL path for XOAUTH2 support
environment.sessionVariables = {
  SASL_PATH = "${pkgs.cyrus-sasl-xoauth2}/lib/sasl2";
};

# Keyring setup
services.gnome.gnome-keyring.enable = true;
security.pam.services.lightdm.enableGnomeKeyring = true;  # Or your display manager

# GPG agent (optional)
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = true;
};
```

### 2. Home Manager Configuration

```nix
# Himalaya configuration
home.file.".config/himalaya/config.toml".text = ''
  display-name = "Your Name"
  downloads-dir = "~/Downloads"

  [accounts.personal]
  email = "your-email@gmail.com"
  display-name = "Your Name"
  default = true

  # Local Maildir backend
  [accounts.personal.backend]
  type = "maildir"
  root-dir = "~/Mail/Gmail"
  maildirpp = true

  # SMTP for sending
  [accounts.personal.message.send.backend]
  type = "smtp"
  host = "smtp.gmail.com"
  port = 465
  login = "your-email@gmail.com"

  [accounts.personal.message.send.backend.auth]
  type = "oauth2"
  client-id = "$GMAIL_CLIENT_ID"
  client-secret.keyring = "gmail-oauth2-client-secret"
  access-token.keyring = "gmail-oauth2-access-token"
  refresh-token.keyring = "gmail-oauth2-refresh-token"
  auth-url = "https://accounts.google.com/o/oauth2/v2/auth"
  token-url = "https://www.googleapis.com/oauth2/v3/token"
  pkce = true
  scope = "https://mail.google.com/"
'';

# mbsync configuration
home.file.".mbsyncrc".text = ''
  IMAPAccount gmail
  Host imap.gmail.com
  Port 993
  User your-email@gmail.com
  AuthMechs XOAUTH2
  PassCmd "secret-tool lookup service gmail user your-email@gmail.com"
  SSLType IMAPS

  IMAPStore gmail-remote
  Account gmail

  MaildirStore gmail-local
  Path ~/Mail/Gmail/
  Inbox ~/Mail/Gmail/INBOX
  SubFolders Verbatim

  Channel gmail
  Far :gmail-remote:
  Near :gmail-local:
  Patterns *
  Create Both
  SyncState *
  Expunge Both
'';

# Systemd service for automatic sync
systemd.user.services.mbsync = {
  Unit = {
    Description = "Mailbox synchronization service";
    After = [ "network-online.target" ];
  };
  Service = {
    Type = "oneshot";
    ExecStart = "${pkgs.isync}/bin/mbsync -a";
  };
  Install.WantedBy = [ "default.target" ];
};

# Timer for periodic sync (every 5 minutes)
systemd.user.timers.mbsync = {
  Unit.Description = "Mailbox synchronization timer";
  Timer = {
    OnBootSec = "2m";
    OnUnitActiveSec = "5m";
    Unit = "mbsync.service";
  };
  Install.WantedBy = [ "timers.target" ];
};

# Create mail directories
home.activation.createMailDirs = lib.mkAfter ''
  mkdir -p ~/Mail/Gmail ~/Mail/Work
'';

# Set environment variables
home.sessionVariables = {
  GMAIL_CLIENT_ID = "your-client-id-here";
  SASL_PATH = "${pkgs.cyrus-sasl-xoauth2}/lib/sasl2";
};
```

### 3. Apply Configuration

```bash
# Rebuild NixOS
sudo nixos-rebuild switch

# Or with home-manager
home-manager switch --flake ~/.dotfiles/
```

---

## Part 2B: Non-NixOS Installation

### 1. Install Required Packages

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install himalaya isync msmtp pass gnupg libsecret-tools w3m
```

#### Arch Linux:
```bash
sudo pacman -S himalaya isync msmtp pass gnupg libsecret w3m
yay -S cyrus-sasl-xoauth2  # From AUR
```

#### macOS (Homebrew):
```bash
brew install himalaya isync msmtp pass gnupg libsecret w3m
```

### 2. Install XOAUTH2 SASL Plugin

#### From Source (if not available in package manager):
```bash
# Clone and build cyrus-sasl-xoauth2
git clone https://github.com/moriyoshi/cyrus-sasl-xoauth2.git
cd cyrus-sasl-xoauth2
./autogen.sh
./configure
make
sudo make install

# Set SASL path
export SASL_PATH="/usr/local/lib/sasl2"
echo 'export SASL_PATH="/usr/local/lib/sasl2"' >> ~/.bashrc
```

### 3. Create Configuration Files

#### Himalaya config (`~/.config/himalaya/config.toml`):
```toml
display-name = "Your Name"
downloads-dir = "~/Downloads"

[accounts.personal]
email = "your-email@gmail.com"
display-name = "Your Name"
default = true

[accounts.personal.backend]
type = "maildir"
root-dir = "~/Mail/Gmail"
maildirpp = true

[accounts.personal.message.send.backend]
type = "smtp"
host = "smtp.gmail.com"
port = 465
login = "your-email@gmail.com"

[accounts.personal.message.send.backend.auth]
type = "oauth2"
client-id = "your-client-id"
client-secret.keyring = "gmail-oauth2-client-secret"
access-token.keyring = "gmail-oauth2-access-token"
refresh-token.keyring = "gmail-oauth2-refresh-token"
auth-url = "https://accounts.google.com/o/oauth2/v2/auth"
token-url = "https://www.googleapis.com/oauth2/v3/token"
pkce = true
scope = "https://mail.google.com/"
```

#### mbsync config (`~/.mbsyncrc`):
```
IMAPAccount gmail
Host imap.gmail.com
Port 993
User your-email@gmail.com
AuthMechs XOAUTH2
PassCmd "secret-tool lookup service gmail user your-email@gmail.com"
SSLType IMAPS

IMAPStore gmail-remote
Account gmail

MaildirStore gmail-local
Path ~/Mail/Gmail/
Inbox ~/Mail/Gmail/INBOX
SubFolders Verbatim

Channel gmail
Far :gmail-remote:
Near :gmail-local:
Patterns *
Create Both
SyncState *
Expunge Both
```

### 4. Set Up Automatic Sync (systemd)

Create systemd service (`~/.config/systemd/user/mbsync.service`):
```ini
[Unit]
Description=Mailbox synchronization service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/mbsync -a

[Install]
WantedBy=default.target
```

Create systemd timer (`~/.config/systemd/user/mbsync.timer`):
```ini
[Unit]
Description=Mailbox synchronization timer

[Timer]
OnBootSec=2m
OnUnitActiveSec=5m
Unit=mbsync.service

[Install]
WantedBy=timers.target
```

Enable the timer:
```bash
systemctl --user enable mbsync.timer
systemctl --user start mbsync.timer
```

---

## Part 3: Configuration and Testing

### 1. Configure Himalaya Account

```bash
# Run interactive configuration
himalaya account configure personal
```

**Configuration options:**
- Backend: **Maildir**
- Enable Maildir++: **Yes**
- Backend for sending: **SMTP**
- SMTP host: **smtp.gmail.com** (accept default)
- SMTP encryption: **SSL/TLS**
- Enable OAuth 2.0: **Yes**
- OAuth method: **XOAUTH2**
- Client ID: Enter your Google Cloud client ID
- Client Secret: Enter your Google Cloud client secret
- Redirect scheme: **http**
- Redirect host: **localhost**
- Port: **49152** (accept default)
- Authorization URL: **https://accounts.google.com/o/oauth2/auth**
- Token URL: **https://www.googleapis.com/oauth2/v3/token**
- Scopes: Select **https://mail.google.com/** (and others if desired)
- Enable PKCE: **Yes**

### 2. Set Up mbsync Authentication

```bash
# Extract access token from Himalaya's keyring
ACCESS_TOKEN=$(secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token)

# Store token for mbsync
secret-tool store --label="Gmail OAuth2 for mbsync" service gmail user your-email@gmail.com
# When prompted, enter the ACCESS_TOKEN
```

### 3. Create Mail Directory Structure

```bash
mkdir -p ~/Mail/Gmail/INBOX/{cur,new,tmp}
mkdir -p ~/Mail/Gmail/[Gmail].Sent\ Mail/{cur,new,tmp}
mkdir -p ~/Mail/Gmail/[Gmail].Drafts/{cur,new,tmp}
mkdir -p ~/Mail/Gmail/[Gmail].Trash/{cur,new,tmp}
```

### 4. Initial Sync

```bash
# For NixOS users, ensure SASL_PATH is set
export SASL_PATH="/nix/store/$(ls /nix/store/ | grep cyrus-sasl-xoauth2)/lib/sasl2"

# For non-NixOS users
export SASL_PATH="/usr/local/lib/sasl2"  # or wherever you installed it

# Perform initial sync (may take several minutes)
mbsync -a

# Check sync progress
ls -la ~/Mail/Gmail/INBOX/cur/
```

### 5. Test Himalaya

```bash
# List accounts
himalaya account list

# List emails
himalaya envelope list

# Read an email
himalaya message read 1

# Compose new email
himalaya message write
```

---

## Part 4: Troubleshooting

### Common Issues

#### 1. "Access blocked: hasn't completed Google verification"
**Solution:** Add your email as a test user in Google Cloud Console OAuth consent screen.

#### 2. "SASL mechanism XOAUTH2 not available"
**Solution:** 
- Ensure `cyrus-sasl-xoauth2` is installed
- Set `SASL_PATH` environment variable correctly
- For NixOS: Add to configuration and rebuild

#### 3. "cannot list maildir entries"
**Solution:**
- Create maildir structure: `mkdir -p ~/Mail/Gmail/INBOX/{cur,new,tmp}`
- Run initial sync: `mbsync -a`

#### 4. "No such file or directory" for mbsync
**Solution:**
- Ensure `.mbsyncrc` exists with correct configuration
- Check OAuth2 token is stored: `secret-tool lookup service gmail user your-email@gmail.com`

#### 5. Token authentication fails
**Solution:**
- Tokens may have expired - reconfigure Himalaya: `himalaya account configure personal`
- Extract new token and update mbsync storage

### Verification Commands

```bash
# Check if XOAUTH2 is available
mbsync --version

# Verify tokens are stored
secret-tool lookup service himalaya-cli username gmail-smtp-oauth2-access-token
secret-tool lookup service gmail user your-email@gmail.com

# Check maildir structure
find ~/Mail/Gmail -type d | head -10

# Monitor sync service
systemctl --user status mbsync.timer
journalctl --user -u mbsync.service -f
```

---

## Part 5: Usage

### Daily Workflow

```bash
# Check emails
himalaya envelope list

# Read email
himalaya message read <ID>

# Reply to email
himalaya message reply <ID>

# Compose new email
himalaya message write

# Manual sync
mbsync -a

# Check different folders
himalaya folder list
himalaya envelope list --folder "INBOX"
```

### Directory Structure

```
~/Mail/Gmail/
├── INBOX/
│   ├── cur/     # Read emails
│   ├── new/     # Unread emails
│   └── tmp/     # Temporary files
├── [Gmail].Sent Mail/
├── [Gmail].Drafts/
└── [Gmail].Trash/
```

### Automatic Sync

- Emails sync automatically every 5 minutes
- Check sync status: `systemctl --user status mbsync.timer`
- Manual sync: `mbsync -a`

---

## Multi-Account Setup

To add work email or additional accounts:

1. **Add to Himalaya config:**
```toml
[accounts.work]
email = "work@company.com"
display-name = "Work Account"

[accounts.work.backend]
type = "maildir"
root-dir = "~/Mail/Work"
maildirpp = true

# ... similar SMTP configuration
```

2. **Add to mbsync config:**
```
IMAPAccount work
Host mail.company.com
Port 993
User work@company.com
# ... similar configuration
```

3. **Configure and test:**
```bash
himalaya account configure work
mkdir -p ~/Mail/Work
mbsync work
```

---

## Security Considerations

- OAuth2 tokens are stored in system keyring
- Never commit configuration files with credentials to version control
- Consider using `.gitignore` for sensitive configs
- Regularly rotate OAuth2 credentials
- Use app-specific passwords as fallback if OAuth2 fails

---

## Integration with NeoVim

This installation provides the foundation for NeoVim email integration. Once installed, the Himalaya plugin provides a complete email management system within NeoVim.

For usage instructions and plugin documentation, see [README.md](README.md).

## Navigation
- [← Plugin Documentation](README.md)
- [← Tools Directory](../README.md)
