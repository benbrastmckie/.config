" Syntax highlighting for email composition
" Matches email headers and special elements

" Headers
syn match mailHeader "^From:.*$" contains=mailEmail
syn match mailHeader "^To:.*$" contains=mailEmail
syn match mailHeader "^Cc:.*$" contains=mailEmail
syn match mailHeader "^Bcc:.*$" contains=mailEmail
syn match mailHeader "^Subject:.*$"
syn match mailHeader "^Date:.*$"
syn match mailHeader "^Reply-To:.*$" contains=mailEmail
syn match mailHeader "^In-Reply-To:.*$"
syn match mailHeader "^References:.*$"

" Email addresses
syn match mailEmail "<[^>]\+@[^>]\+>" contained
syn match mailEmail "\<[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,}\>" contained

" Quoted text (for replies)
syn region mailQuoted start="^>" end="$" contains=mailQuotedNested
syn region mailQuotedNested start="^>>" end="$" contained contains=mailQuotedNested

" Signature
syn match mailSignature "^-- $" nextgroup=mailSignatureBlock
syn region mailSignatureBlock start="^-- $" end="\%$" contains=mailSignature

" URLs
syn match mailURL "https\?://[^ )\]>\"\t]\+"
syn match mailURL "www\.[^ )\]>\"\t]\+"

" Highlighting
hi def link mailHeader Keyword
hi def link mailEmail Underlined
hi def link mailQuoted Comment
hi def link mailQuotedNested Type
hi def link mailSignature PreProc
hi def link mailSignatureBlock Comment
hi def link mailURL Underlined