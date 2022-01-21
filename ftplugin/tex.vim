" Use Vimtex context menu with PdfAnnots 
" nnoremap <c-a> <cmd>call PdfAnnots()<cr>
function PdfAnnots() abort
  try
    let infile = vimtex#context#get().handler.get_actions().entry.file
  catch /E121/
    echo "No file found"
    return
  endtry

  let cwd = getcwd()
  try
    call chdir(b:vimtex.root)

    if !isdirectory('Annotations')
      call mkdir('Annotations')
    endif

    let outfile = "Annotations/" . fnamemodify(infile, ':t:r') . '.md'
    call system(printf('pdfannots -o "%s" "%s"', outfile, infile))

    execute 'split' fnameescape(outfile)
  finally
    call chdir(cwd)
  endtry
endfunction

" Define what get's paired
let g:AutoPairs = {
      \ "`":"'",
      \ "(":")",
      \ "[":"]",
      \ "{":"}",
      \ "$":"$",
      \ "( ": " )",
      \ "[ ": " ]",
      \ "{ ": " }",
      \ "$ ": " $",
      \ }
