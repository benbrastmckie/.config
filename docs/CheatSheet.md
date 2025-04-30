# Cheat Sheet

> This is outdated...

The following sections present a list of key-bindings and features which have been included in the present configuration.
Although I take my target audience to be academics looking to write papers in LaTeX and take notes in Markdown, I will not attempt to provide [resources for learning LaTeX](https://www.youtube.com/watch?v=VhmkLrOjLsw) or [Markdown](https://www.youtube.com/watch?v=hpAJMSS8pvs&t=574s).
Similarly, if you are looking for the bindings which come default in Vim, then you might check this [resource](https://vim.rtorr.com) out.
I will provide links to associated tutorial videos throughout, omitting mention of the standard Vim commands which have mostly been preserved.
For configuration instructions, see the installation instructions in the [README.md](https://github.com/benbrastmckie/.config/blob/master/README.md) as well as the [(Install Part 1)](https://youtu.be/JVIcU9ePtVE) video on YouTube.
If you are looking for information specifically about using Git, you can find a number of resources in the [LearningGit.md](https://github.com/benbrastmckie/.config/blob/master/LearningGit.md) file that I've included.
I will also provide links to further resources for learning Vim below.

## Table of Contents

1. [Learning Vim](#Learning-Vim)
2. [Mappings](#Mappings)
3. [Plugins](#Plugins)

# [Learning Vim](https://www.youtube.com/watch?v=oyEPY6xFhs0&t=2s)

NeoVim maintains the same modes, key-bindings, and conventions as Vim and Vi which go back as far as the late 70s.
With some some practice, these conventions provide an extremely powerful and efficient way to edit text documents, making up the core functionality which NeoVim has to offer.
Learning to use NeoVim is comparable to learning how to touch-type: it will take a concerted effort over a short period of time to get a good foundation from which mastery can slowly be cultivated over the years to come.
However, even with just the foundations, NeoVim offers a significant increase in efficiency, well worth the initial investment.
See the introduction [(Demo Part 1)](https://youtu.be/pYNvDkB0iRk) for related discussion, as well as the following resources for learning to use NeoVim.

- [Detailed Guide](https://danielmiessler.com/study/vim/) Nice overview.
- [OpenVim](https://www.openvim.com/) Free interactive Vim tutorial.
- [VimAdventure](https://vim-adventures.com/) Free game to practice basic Vim commands.
- [Vim Tutor](https://www.youtube.com/watch?v=d8XtNXutVto) A guided tour through `vimtutor`.
- [Tutorial Series](https://www.youtube.com/watch?v=H3o4l4GVLW0&t=1s) Short tutorial video series.
- [Orienting Remarks](http://www.viemu.com/a-why-vi-vim.html) Learning Vim is like learning to touch-type.
- [Another List](https://blog.joren.ga/tools/vim-learning-steps) Another list of resources for learning Vim.
- [Pure Zeal](https://thevaluable.dev/vim-adept/) A sermon on the virtues of Vim!

I have not made any changes to the conventions which come standard with NeoVim, as there is no need to reinvent the wheel.
Rather, what follows is a minimal number of extensions to the functionality provided by NeoVim.

# Mappings

Which-Key is triggered by the space bar, and will bring up a range of key-bindings with associated names.
Accordingly, I will focus attention on the mappings included in `~/.config/nvim/keys/mappings.vim`, though I will mention some of the Which-Key bindings in discussing plugins in the following section.

## _Line Movements_ 

- **Drag Lines**: the commands `alt+j` and `alt+k` will drag the selected lines up or down in visual, normal, or insert mode, where indenting is adjusted automatically.
- **Better Indenting**: the `<` and `>` keys will adjust indents in both normal and visual mode.
- **Display Line Movements**: in either normal or visual mode, `shift+j` and `shift+k` will vertically navigate displayed lines as opposed to numbered lines, whereas `shift+h` and `shift+l` will move to the beginning or end of the displayed line, respectively.

## _Windows, Buffers, and Panes_ 

- **Manage Windows**: use `<ctrl+space>c` to create a new window, and `<ctrl+space>k` to kill the current window (make sure that all processes have been ended, for instance by closing NeoVim with `<space>q`).
- **Switch Windows**: use `<ctrl+space>n` and `<ctrl+space>p` to cycle through open windows.
- **Switch Buffers**: use `<bs>` and `<shift+tab>` to cycle though the open buffers.
- **Navigate Panes**: use `<ctrl>h/j/k/l` to switch focus between buffers.
- **Resize Panes**: use `<alt>h/l` to horizontally resize the buffer in focus.

## _Commands_ [(Basic Features)](https://www.youtube.com/watch?v=_Ct2S65kpjQ)

- **Save and Quit**: use `<space>w` to save buffer, and `<space>q` to save and quite all buffers.
- **Copy**: use `Y` to yank to end of line.
- **Previous Word**: use `E` to go to the end of the previous word.
- **Comment**: in normal mode or visual mode, use `ctrl+\ ` to toggle whether the lines in question are commented out.
- **Help**: use `shift+m` to open Help for the word under the cursor, and `q` to close.
- **Terminal**: use `ctrl+t` to toggle the terminal window in NeoVim.
- **Bib Export**: use `<space>ab` to generate local bibliography from all citations present in the document.
- **Bib Annotate**: use `<space>aa` to generate a markdown file with annotations from the pdf associated with the citation under the cursor.

## _Zathura (Linux)_ [(Basic Features)](https://www.youtube.com/watch?v=_Ct2S65kpjQ)

- **Index**: use `<space>` to toggle the index.
- **Zoom**: use `shift+k` and `shift+j` to zoom in and out, respectively.
- **Print**: use `p` to print.
- **Normal Mode**: use `w` to remove colouration.
- **Sync**: use `ctrl+[right click]` on a line in the pdf once it has been generated by Vimtex in order to highlight the corresponding line in NeoVim. For syncing in the other direction, use `<space>v` to highlight active line in the pdf.
  - NOTE: Zathura will have to have been started by the NeoVim instances you are currently using for syncing to work. To reset sync, close Zathura and regenerate the pdf via `<space>b` or `<space>v` if building is complete or already turned on.

<!-- ## _GitHub Cli_ [(Git Part 4)](https://www.youtube.com/watch?v=KM_Mwp7R_rk&t=198s) -->
<!---->
<!-- - Use `<space>gc` to create new GitHub issue. -->
<!-- - Use `<space>gl` to list all open issues. -->
<!-- - Use `<space>gr` to view GitHub Cli references. -->
<!-- - Use `<space>gv` to view the repo in a browser. -->

# Plugins

In what follows, I will discuss a number of key plugins included in `~/.config/nvim/vim-plug/plugins.vim` which are of considerable use for writing LaTeX documents.

## _File Management_

- **Local File Search**: use `ctrl+p` to search for files being tracked by Git in the current project folder, navigating with `ctrl+j/k`, and opening files with `Enter`.
- **Fuzzy File Search**: use `<space>ff` to fuzzy search through all files in the project folder, navigating with `ctrl+j/k`, and opening files with `Enter`.
- **Explorer**: use `<space>e` to open the file explorer, navigating with `j/k`, opening and closing directories with `h/l` adding directories with `shift+a`, adding files with `a`, opening files with `Enter`, or looking up commands with `?`.
- **Close Buffer**: use `<space>d` to close current buffer.
- **LazyGit**: use `<space>gg` to open LazyGit, followed by `?` to see a range of different commands, using `h/j/k/l` to navigate.
- **Branch**: use `<space>fb` to search through git branches.
- **CWD**: use `<space>au` to change the project directory to the directory which contains the current file.
- **Hunks**: use `<space>gj` and `<space>gk` to navigate between changes since last commit.
- **Blame**: use `<space>gl` to see author responsible for previous change of the line under the cursor.

## _Projects and Templates_

- **Projects**: use `<space>ms` to create a new project, `<space>ml` to switch to a different project, and `<space>md` to delete a project.
- **Templates**: use `<space>t` to choose from a variety of templates in the `~/.config/nvim/templates` directory.
  - To add new templates, add the relevant file to `~/.config/nvim/templates`, customising `~/.config/nvim/keys/which-key.vim`.

## _Autocomplete_

- **Select Entry**: use `ctrl+j` and `ctrl+k` to cycle through the autocomplete menu.
- **Trigger Completion**: continue typing after selecting desired option, or hit `Enter`.
- **Snippet Completion**: use `Enter` to select highlighted option, and `tab` to move through fields.
- **Go To**: use `gd` to go to the definition of the word under the cursor (if any).
- **Spelling**: use `ctrl+s` to search alternatives to misspelled word.

## _Autopairs and Surround_

- **Autopairs**: use open-quote/bracket to create pair, adding a space if padding is desired, followed by the closing quote/bracket.
- **Add Surround**: in visual select mode use `shift+s`, or in normal mode use `<space>ss`, followed by the desired text object, and then either:
  - `q/Q` for single/double LaTeX quotes, respectively.
  - `i` for italics, `b` for bold, `t` for typescript, `s` for small-caps, `$` to create an in-line math environment, open (left) bracket/parentheses/brace for padding, and close (right) bracket/parentheses/brace for no padding.
- **Change Surround**: in normal mode, use `<space>s` followed by:
  - `c` followed by the trigger for what you want to change (e.g., `}`), and then the trigger for what you want to change to (e.g., `[`).
  - `d` followed by the trigger for what you want to delete (e.g., `i` if the cursor is anywhere in `\textit{example}`, and similarly for other triggers).

## _LaTeX Support_ [(Basic Features)](https://www.youtube.com/watch?v=_Ct2S65kpjQ)

- **Build**: use `<space>b` to toggle auto-build.
- **View**: use `<space>v` to preview current line.
- **Index**: use `<space>i` to open the index.
- **Count**: use `<space>ac` to count words.
- **Report Errors**: use `<space>ar` to open LaTeX log in horizontal split, and `<space>d` to close.
- **Clean**: use `<space>ak` to delete auxiliary LaTeX files.
- **Glossary**: use `<space>ag` to edit the default glossary template.
- **BibExport**: use `<space>ab` to generate a local bib file from citations in the document.
- **Snippets**: use `<space>as` to edit the snippets file.
- **Vimtex**: use `<space>av` to lookup bib entry under the cursor, giving you the option of viewing or editing the bib data, opening the file, etc.
- **Citation**: use `<space>fc` to search through the bib file included at the end of your LaTeX document.
- **Pandoc**: use `<space>p` to select which file format into which you would like to convert the file open in current buffer.

<!-- ## _Markdown_ [(Install Part 3)](https://youtu.be/TMA7nu9KCEQ)[(Demo Part 6)](https://www.youtube.com/watch?v=K9u7NrCSn1c&t=380s) -->
<!---->
<!-- - **Fold**: use `<space>mf` to toggle folding for current, and `<space>mF` to toggle all folding. -->
<!-- - **Preview**: use `<space>mp` to preview document. -->
<!-- - **Kill**: use `<space>mk` to close document. -->
<!-- - **Select**: use `<space>ms` to cycle through selection options in a markdown bullet point list. -->

## _Misc Bindings_ 

- **Undo**: use `<space>u` to open the undo tree, `<C-j/k>` to navigate, `<C-u>` to restore selected, `<C-a>` to yank additions, and `<C-d>` to yank deletions.
- **Centre**: use `alt-m` to centre screen on the cursor.
- **Highlight**: use `Enter` to kill the result of search highlights.
- **Htop**: use `<space>ah` to open the `htop` system monitor.
- **Illuminate**: use `<space>ai` to toggle the illumination of all words matching the word under the cursor.
- **LSP**: use `<space>al` to toggle the autocomplete menu.
- **Symbols**: use `<space>ap` to generate the symbol for the math under the cursor.
- **Buffers**: use `<space>fb` to switch between open buffers.
- **Keymaps**: use `<space>fk` to search through keymaps.
- **Registers**: use `<space>fr` to search through registers.
- **Themes**: use `<space>ft` to switch between themes.
- **Yanks**: use `<space>fy` to paste from past yanks.
- **List**: use `<space>l` to choose between commands useful for editing lists in markdown documents.




