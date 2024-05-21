if status is-interactive
    # Commands to run in interactive sessions can go here
end

# removes the mapping <C-t> which is being used to close the terminal in NeoVim
bind --erase \ct
# bind \ct true

# There's a catch 22 here. xodide is called but won't be found unless
# fish is aware of the paths set by brew:.
#    /opt/brew/bin/brew shellenv >> ~/.config/fish/config.fish # Ensures that brew paths are recognised inside fish

# runs zoxide if installed
if type -q zoxide
zoxide init fish --cmd cd | source
end

# runs neofetch if installed
if type -q neofetch
neofetch
end
