" Vim syntax file
" Language: PlainTasks
" Maintainer: David Elentok
" Filenames: *.TODO
"
if exists("b:current_syntax")
  finish
endif

" header overrides notes match
syn match ptNotes '\v^\s*(\-|\+|✓|✔|√|❍|❑|■|□|☐|▪|▫|–|—|≡|→|›|\[[[:space:]sx-]\]|＿|✘|(x\s+))@!\S.*$'
syn match ptHeader '\v^\s*\#?\s?\w+.{-}:\s{-}$(\@[^\s]+(\(.{-}\))?\s{-})*$\n?'

" completed or canceled override pending
" todo: match bullet separately to color it
syn match ptPending '\v^\s*(\-|❍|❑|■|□|☐|▪|▫|–|—|≡|→|›|\[\s\])((\s+([^\@\n]|([ \t])@<!\@)*)(([^\n]*)?(\@done|\@cancelled)[[:space:]\(])@!)' contains=ptTag
syn match ptCompleted '\v^\s*(\+|✓|✔|☑|√|\[x\])(\s+([^\@\n]|(\s)@<!\@|\@\s)*)[^\n]*'
syn match ptCompleted '\v^\s*(-)(\s+([^\@]|(\s)@<!\@|\@\s)*)(.*\@done(\s|\(|$)[^\n]*)'
syn match ptCancelled '\v^\s*(✘|x|\[-\])(\s+([^\@\n]|(\s)@<!\@|\@\s)*)(.*)'
syn match ptCancelled '\v^\s*(-)(\s+([^\@]|(\s)@<!\@|\@\s)*)(.*\@cancelled(\s|\(|$)[^\n]*)'

" todo: match other tags
" todo: match archive line
syn match ptTag '\v\s\@((high|today|critical|low|completed|done)[\([:space:]])@![[:alnum:]\.\(\)\-\!\? \:\+]+[ \t]*'
syn match ptSeparator '\v^\s*---.{3,5}---+$'

hi def link ptNotes Comment
hi def link ptHeader Identifier

hi def link ptPending Normal
hi def link ptCompleted Comment
hi def link ptCancelled Comment

hi def link ptTag Function
hi def link ptSeparator Comment
