if status is-interactive
    # Commands to run in interactive sessions can go here
end

bind --erase \ct
# bind \ct true
zoxide init fish --cmd cd | source
