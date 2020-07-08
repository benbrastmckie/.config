# Cheat Sheet [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

The following sections present a list of key-bindings and features which have been included in the present configuration.
I will provide links to associated tutorial videos throughout, omitting mention of the standard Vim commands which have been preserved except to provide the following resources for learning Vim.
For configuration instructions, see the installation [(Video 1/3)](https://youtu.be/JVIcU9ePtVE).

## Learning Vim

NeoVim maintains the same modes, key-bindings, and conventions as Vim and Vi which go back as far as the late 70s.
With some some practice, these conventions provide an extremely powerful and efficient way to edit text documents, making up the core functionality which NeoVim has to offer.
Learning to use NeoVim is comparable to learning how to touch-type: it will take a concerted effort over a short period of time to get a good foundation from which mastery can slowly be cultivated over the years to come.
However, even with just the foundations, NeoVim offers a significant increase in efficiency, well worth the initial investment.
See the introduction [(Video 1/7)](https://youtu.be/pYNvDkB0iRk) for related discussion, as well as the following resources for learning to use NeoVim.

- [OpenVim](https://www.openvim.com/) Free interactive Vim tutorial.
- [VimAdventure](https://vim-adventures.com/) Free game to practice basic Vim commands.
- [Vim Tutor](https://www.youtube.com/watch?v=d8XtNXutVto) A guided tour through `vimtutor`.
- [Tutorial Series](https://www.youtube.com/watch?v=H3o4l4GVLW0&t=1s) Short tutorial video series.
- [Inspiration](https://www.youtube.com/watch?v=1UXHsCT18wE) Inspiration and Comedy.

I have not made any changes to the conventions which come standard with NeoVim, as there is no need to reinvent the wheel.
Rather, what follows is a minimal number of extensions to the functionality provided by NeoVim.

## Mappings

Which-Key is triggered by the space bar, and will bring up a range of key-bindings with associated names.
Accordingly, I will focus attention on the mappings included in `~/.config/nvim/keys/mappings.vim`, though I will mention some of the Which-Key bindings in discussing plugins in the following section.

### _Line Movements_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Drag lines**: after visually selecting one or more lines, the commands `Alt+j` and `Alt+k` will drag the selected lines up or down, indenting accordingly.
- **Better tabbing**: after visually selecting one or more lines, the `<` and `>` keys will adjust indents.
- **Display line movements**: in either normal or visual mode, `Shift+j` and `Shift+k` will vertically navigate displayed lines as opposed to numbered lines.

### _Windows, Buffers, and Panes_ [(Video 2/3)](https://youtu.be/Xvu1IKEpO0M)

- **Manage windows**: use `Ctrl+Space+c` to create a new window, and `Ctrl+Space+k` to kill the current window (make sure that all processes have been ended, for instance by closing NeoVim with `Space+q`).
- **Switch windows**: use `Ctrl+Space+n` and `Ctrl+Space+p` to cycle through open windows.
- **Switch buffers**: use `Tab` and `Shift+Tab` to cycle though the open buffers.
- **Navigate panes**: use `Ctrl+h/j/k/l` to switch focus between buffers.
- **Resize panes**: use `Alt+h/l` to horizontally resize the buffer in focus.

### _Commands_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Save and Quit**: use `Space+w` to save buffer, and `Space+q` to save and quite all buffers.
- **Comment**: in normal mode or visually mode, use `Ctrl+\ ` to toggle whether the lines in question are commented out.
- **Spelling**: use `Ctrl+s` to search alternatives to misspelled word.
- **Cut and Paste**: use `"dp` and `"dP` to paste previously deleted block below and above respectively.
- **Help**: use `Ctrl+m` to open Help for the word under the cursor.
- **Multiple Cursors**: use `Ctrl+n` to select the word under the cursor, where repeating `Ctrl+n` will select the next occurrences of that word, `Ctrl+x` will skip the current selected occurrence, and `Ctrl+p` will deselect the current occurrence and go back to the previous occurrence of that word.

## Plugins

In what follows, I will discuss a number of key plugins included in `~/.config/nvim/vim-plug/plugins.vim` which are of considerable use for writing LaTeX documents.

### _File Management_ [(Video 3/7)](https://youtu.be/v_zYV8G7gOs)

- **Local File Search**: use `Ctrl+p` to fuzzy search for files being tracked by Git in the current project folder, navigating with `Ctrl+j/k`, and opening files with `Enter`.
- **Global File Search**: use `Space+Shift+f` to fuzzy search through all files in the home folder, navigating with `Ctrl+j/k`, and opening files with `Enter`.
- **Explorer**: use `Space+e` to open the file explorer, navigating with `j/k`, adding directories with `Shift+a`, adding files `a`, and opening files with `Enter`.
- **Close Buffer**: use `Space+d` to close current buffer.

### _Projects and Templates_ [(Video 5/7)](https://youtu.be/z5HfVQQDrAg)

- **Projects**: use `Space+Shift+s,s` to create a new project, and `Space+Shift+s,d` to delete a new project.
  - To create a first project, enter the command `:SSave` instead, following the prompt to create a sessions folder.
- **Templates**: use `Space+t` to choose from a variety of templates in the `~/.config/nvim/templates` directory.
  - To add new templates, add the relevant file to `~/.config/nvim/templates`, customising `~/.config/nvim/keys/which-key.vim`.

### _Git Integration_ [(Video 3/7)](http://syoutu.be/v_zYV8G7gOs) [(Video 5/7)](https://youtu.be/z5HfVQQDrAg)

- **LazyGit**: use `Space+g,g` to open LazyGit, followed by `?` to see a range of different commands, using `h/j/k/l` to navigate as usual.
- **Fugitive**: use `Space+g` to bring up a range of git commands.

### _Autocomplete_ [(Video 2/7)](https://youtu.be/KGqrpnxoDxw)

- **Select Entry**: use `Ctrl+j` and `Ctrl+k` to cycle through the autocomplete menu.
- **Trigger Completion**: continue typing after selecting desired option.
- **Snippet Completion**: use `Enter` to select highlighted option, and `Tab` to reselect previous field.
- **Go to**: use `gd` to go to the definition of the word under the cursor (if any).
- **Spelling**: use `Ctrl+s` to search alternatives to misspelled word.
- **Hide**: use `Space+k` to hide autocomplete menu, and `Space+r` to restore.

### _Autopairs and Surround_ [(Video 4/7)](https://youtu.be/1fcc5YoCrvc)

- **Autopairs**: use open-quote/bracket to create pair, adding a space if padding is desired, followed by the closing quote/bracket.
- **Add Surround**: in visual select mode use `Shift+s`, or in normal mode use `Space+s,s`, followed by the desired Vim noun to specify the text-object in question, and then enter either:
  - `q/Q` for single/double LaTeX quotes, respectively.
  - Open bracket for brackets with padding, and close bracket for brackets without padding.
- **Change Surround**: in normal mode, use `Space+s` followed by:
  - `k` to remove the next outermost quotes/brackets relative to the position of the cursor.
  - `d` followed by the desired quotes/brackets to be deleted.
  - `c` followed by both the quote/brackets to change, and then the quotes/brackets which are to be inserted instead.

### _LaTeX Support_ [(Video 2/7)](https://youtu.be/KGqrpnxoDxw)

- **Build**: use `Space+b` to toggle auto-build.
- **Preview**: use `Space+p` to preview current line.
- **Index**: use `Ctrl+i` to open the index.
- **Count**: use `Ctrl+c` to count words.
- **Log**: use `Ctrl+l` to open LaTeX log in horizontal split, and `Space+d` to close.
- **Clean**: use `Space+a,k` to delete auxiliary LaTeX files.

### _Markdown_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Build**: use `Space+m,m` to toggle auto-build.
- **Preview**: use `Space+m,p` to preview document.
- **Kill**: use `Space+m,k` to close document.
- **Select**: use `Space+m,s` to cycle through selection options in a markdown bullet point list.

### _Pandoc_ [(Video 7/7)](https://www.youtube.com/watch?v=l0N5LJTe6-A)

- Use `Space+Shift+p` to select which file format into which you would like to convert the file open in current buffer.
- Alternatively, you can run `:Pandoc [Source file] [Output file]` in the command line to simulate terminal commands.

### _Misc Bindings_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Search**: use `Space+f` to fuzzy find within the current document.
- **Undo**: use `Space+u` to open the undo tree.
- **Zen Mode**: use `Space+z` to toggle zen mode (best used when the window is maximised).
- **Reload**: use `Space+Shift+r` to reload the configuration files.
