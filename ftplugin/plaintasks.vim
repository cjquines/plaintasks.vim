"Vim filetype plugin
" Language: PlainTasks
" Maintainer: David Elentok
" ArchiveTasks() added by Nik van der Ploeg

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif

" used for past due messages
if exists("*nvim_create_namespace")
  let s:plaintasks_namespace = nvim_create_namespace("plaintasks")
endif

nnoremap <silent> <buffer> + :call NewTask()<cr>A
vnoremap <silent> <buffer> + :call NewTask()<cr>
noremap <silent> <buffer> = :call ToggleComplete()<cr>
noremap <silent> <buffer> <C-M> :call ToggleCancel()<cr>
nnoremap <silent> <buffer> - :call ArchiveTasks()<cr>
abbr -- <c-r>=Separator()<cr>

" when pressing enter within a task it creates another task
setlocal comments+=n:☐

function! s:synGroup(line, col)
  let l:s = synID(a:line, a:col, 1)
  return synIDattr(l:s, "name")
endfun

function! ToggleComplete()
  let line = getline('.')
  if line =~ "^ *✔"
    s/^\( *\)✔/\1☐/
    s/ *@done.*$//
  elseif line =~ "^ *☐"
    s/^\( *\)☐/\1✔/
    let date_format = get(g:, "plaintasks_date_format", "(%y-%m-%d %H:%M)")
    let text = " @done " . strftime(date_format)
    exec "normal A" . text
    normal _
  endif
endfunc

function! ToggleCancel()
  let line = getline('.')
  if line =~ "^ *✘"
    s/^\( *\)✘/\1☐/
    s/ *@cancelled.*$//
  elseif line =~ "^ *☐"
    s/^\( *\)☐/\1✘/
    let date_format = get(g:, "plaintasks_date_format", "(%y-%m-%d %H:%M)")
    let text = " @cancelled " . strftime(date_format)
    exec "normal A" . text
    normal _
  endif
endfunc

function! NewTask()
  let synName=s:synGroup(line('.'), col('.'))
  if synName == "ptPending"
    \ || synName == "ptCompleted"
    \ || synName == "ptCancelled"
    \ || synName == "ptTag"
    \ || synName == "ptHeader"
    \ || synName == "ptSeparator"
    execute "normal! A\<cr>☐ "
  else
    execute "normal! I☐ "
  end
endfunc

function! ArchiveTasks()
    let orig_line=line('.')
    let orig_col=col('.')
    let archive_start = search("^Archive:")
    if (archive_start == 0)
        call cursor(line('$'), 1)
        normal 2o
        normal iArchive:
        normal o＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
        let archive_start = line('$') - 1
    endif
    call cursor(1,1)

    let found=0
    let a_reg = @a
    if search("✔", "", archive_start) != 0
        call cursor(1,1)
        while search("✔", "", archive_start) > 0
            if (found == 0)
                normal "add
            else
                normal "Add
            endif
            let found = found + 1
            call cursor(1,1)
        endwhile

        call cursor(archive_start + 1,1)
        normal "ap
    endif

    "clean up
    let @a = a_reg
    call cursor(orig_line, orig_col)
endfunc

function! Separator()
    let line = getline('.')
    if line =~ "^-*$"
      return "--- ✄ -----------------------"
    else
      return "--"
    end
endfunc

function! s:setVirtualText(buffer_number, line_number, message, hl_group) abort
  call nvim_buf_set_virtual_text(
    \a:buffer_number,
    \s:plaintasks_namespace,
    \a:line_number,
    \[[a:message, a:hl_group]],
    \{},
    \)
endfunction

function! ClearHighlightPastDue()
  if !has("nvim")
    return
  endif
  if &buftype !=# '' ? 1 : 0
    return
  endif
  call nvim_buf_clear_namespace(bufnr(""), s:plaintasks_namespace, 0, -1)
endfunction

function! HighlightPastDue()
  if !has("nvim")
    return
  endif
  if &buftype !=# '' ? 1 : 0
    return
  endif
  call ClearHighlightPastDue()
  let text = getline(1, "$")
  let date_format = get(g:, "plaintasks_date_format", "(%y-%m-%d %H:%M)")
  for line_number in range(0, len(text) - 1)
    let line = text[line_number]
    let synName = s:synGroup(line_number + 1, 1)
    if synName == "ptCompleted" || synName == "ptCancelled"
      continue
    endif
    let matched = matchlist(line, '\v\@due(\([^@\n]*\))')
    if len(matched) > 0
      let deadline = strptime(date_format, matched[1])
      if deadline == 0
        continue
      endif
      let now = localtime()
      let overdue = deadline <= now ? v:true : v:false
      let diff = overdue ? now - deadline : deadline - now
      let mn = string(float2nr(fmod(diff, 3600) / 60))[:-1]
      let min = len(mn) < 2 ? "0" . mn : mn
      let hrs = string(float2nr(fmod(diff, 3600 * 24) / 3600))[:-1]
      let dys = string(float2nr(diff / (3600 * 24)))[:-1]
      let message =
        \(dys == 0 ? "" : (dys == 1 ? dys . " day, " : dys . " days, ")) .
        \(hrs . ":" . min) .
        \(overdue ? " overdue" : " remaining")
      call s:setVirtualText(
        \bufnr(""),
        \line_number,
        \message,
        \overdue ? "ptOverdue" : (dys == 0 ? "ptNextDay" : "ptDeadline"),
        \)
    endif
  endfor
endfunc

augroup plaintasks
  autocmd!
  autocmd BufEnter * call HighlightPastDue()
  autocmd InsertEnter * call ClearHighlightPastDue()
  autocmd TextYankPost * call ClearHighlightPastDue()
  autocmd FocusGained * call HighlightPastDue()
  autocmd InsertLeave * call HighlightPastDue()
augroup END
