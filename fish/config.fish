set -U fish_greeting
# Disable welcome message
set -U fish_greeting

# OMF Path (auto-generated)
# Already handled by OMF

# Add Homebrew's bin directory to PATH (for all installed packages)
set -gx PATH /usr/local/bin $PATH

# Add NVM node bin to PATH
if test -d "$HOME/.nvm/versions/node"
    set -gx PATH $HOME/.nvm/versions/node/v22.19.0/bin $PATH
end

# Alias pip to pip3
alias pip='pip3'

# Add Python user bin to PATH for pip-installed tools
set -gx PATH $HOME/Library/Python/3.13/bin $PATH

# Fix ls to use /bin/ls directly
alias ls='/bin/ls'
