if status is-interactive
    # Commands to run in interactive sessions can go here
end

bind --erase \ct
# removes the mapping <C-t> which is being used to close the terminal in NeoVim

if type -q zoxide
zoxide init fish --cmd cd | source
# removes the mapping <C-t> which is being used to close the terminal in NeoVim
end
