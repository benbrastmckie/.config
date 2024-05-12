if status is-interactive
    # Commands to run in interactive sessions can go here
end

bind --erase \ct
# bind \ct true

# There's a catch 22 here. xodide is called but won't be found unless
# fish is aware of the paths set by brew:.
#    /opt/brew/bin/brew shellenv >> ~/.config/fish/config.fish # Ensures that brew paths are recognised inside fish

zoxide init fish --cmd cd | source

