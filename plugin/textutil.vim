" textutil.vim : Vim plugin for editing rtf,rtfd,doc,wordml files.
" Name Of File: textutil.vim
" Maintainer:   omi taku <advweb@jcom.home.ne.jp>
" URL:          http://members.jcom.home.ne.jp/advweb/
" Date:         2005/12/13
" Version:      0.1 (initial upload)
"
" Installation
" ------------
" 1. Copy the textutil.vim script to the $HOME/.vim/plugin directory.
"    Refer to ':help add-plugin', ':help add-global-plugin' and ':help runtimepath'
"    for more details about Vim plugins.
" 2. Restart Vim.
"
" Usage
" -----
" 1. When you open rtf, rtfd, doc or wordml file with Vim,
"    editing file format is automatically converted to plain text.
"    And when you write file, file format is automatically converted to
"    rtf, rtfd, doc or wordml file format.
"
" Configuration
" -------------
" 1. g:textutil_txt_encoding
"    When this script convert rtf, rtfd, doc or wordml file to plain text with textutil command,
"    use this encoding.
"    default value is 'utf-8'.
"    for example,
"        :let g:textutil_txt_encoding='Shift_JIS'
"
" Note
" ----
" 1. This script is based on 'textutil' command.
"    So this script will only run on MacOS 10.4 or later.
"

" if plugin is already loaded then, not load plugin.
if exists("loaded_textutil") || &cp || exists("#BufReadPre#*.rtf")
	finish
endif
let loaded_textutil = 1

" configuration
if !exists('g:textutil_txt_encoding')
	let g:textutil_txt_encoding = 'utf-8'
endif

" set autocmd
augroup textutil
	" Remove all textutil autocommands
	au!

	" rtf
	autocmd BufReadPre,FileReadPre		*.rtf    setlocal bin
	autocmd BufReadPost,FileReadPost	*.rtf    call s:read("textutil -convert txt -encoding " . g:textutil_txt_encoding)
	autocmd BufWritePost,FileWritePost	*.rtf    call s:write("textutil -convert rtf")

	" rtfd
	autocmd BufReadPre,FileReadPre		*.rtfd   setlocal bin
	autocmd BufReadPost,FileReadPost	*.rtfd   call s:read("textutil -convert txt -encoding " . g:textutil_txt_encoding)
	autocmd BufWritePost,FileWritePost	*.rtfd   call s:write("textutil -convert rtfd")

	" doc
	autocmd BufReadPre,FileReadPre		*.doc    setlocal bin
	autocmd BufReadPost,FileReadPost	*.doc    call s:read("textutil -convert txt -encoding " . g:textutil_txt_encoding)
	autocmd BufWritePost,FileWritePost	*.doc    call s:write("textutil -convert doc")

	" wordml
	autocmd BufReadPre,FileReadPre		*.wordml setlocal bin
	autocmd BufReadPost,FileReadPost	*.wordml call s:read("textutil -convert txt -encoding " . g:textutil_txt_encoding)
	autocmd BufWritePost,FileWritePost	*.wordml call s:write("textutil -convert wordml")
augroup END

" Function to check that executing "cmd [-f]" works.
" The result is cached in s:have_"cmd" for speed.
fun s:check(cmd)
	let name = substitute(a:cmd, '\(\S*\).*', '\1', '')
	if !exists("s:have_" . name)
		let e = executable(name)
		if e < 0
			let r = system(name);
			let e = (r !~ "not found" && r != "")
		endif
		exe "let s:have_" . name . "=" . e
	endif
	exe "return s:have_" . name
endfun

" after reading file, convert file format.
fun s:read(cmd)
	" don't do anything if the cmd is not supported
	if !s:check(a:cmd)
		return
	endif
	" make 'patchmode' empty, we don't want a copy of the written file
	let pm_save = &pm
	set pm=
	" remove 'a' and 'A' from 'cpo' to avoid the alternate file changes
	let cpo_save = &cpo
	set cpo-=a cpo-=A
	" set 'modifiable'
	let ma_save = &ma
	setlocal ma

	" when filtering the whole buffer, it will become empty
	let empty = line("'[") == 1 && line("']") == line("$")

	let tmp = tempname()
	let tmpe = tmp . "." . expand("<afile>:e")

	" write the just read lines to a temp file
	execute "silent '[,']w " . tmpe

	" convert tmpe to text file
	call system(a:cmd . " \"" . tmpe . "\" -output \"" . tmp . "\"")

	" delete the compressed lines; remember the line number
	let l = line("'[") - 1
	if exists(":lockmarks")
		lockmarks '[,']d _
	else
		'[,']d _
	endif

	" read in the uncompressed lines "'[-1r tmp"
	setlocal bin
	if exists(":lockmarks")
		execute "silent lockmarks " . l . "r " . tmp
	else
		execute "silent " . l . "r " . tmp
	endif

	" if buffer became empty, delete trailing blank line
	if empty
		silent $delete _
		1
	endif
	" delete the temp file and the used buffers
	call delete(tmp)
	call delete(tmpe)
	silent! exe "bwipe " . tmp
	silent! exe "bwipe " . tmpe
	let &pm = pm_save
	let &cpo = cpo_save
	let &l:ma = ma_save
	" When uncompressed the whole buffer, do autocommands
	if empty
		if &verbose >= 8
			execute "doau BufReadPost " . expand("%:r")
		else
			execute "silent! doau BufReadPost " . expand("%:r")
		endif
	endif
endfun

" after writing file, convert file format.
fun s:write(cmd)
	" don't do anything if the cmd is not supported
	if s:check(a:cmd)
		" Rename the file before compressing it.
		let nm = expand("<afile>")
		let nmt = tempname()
		if rename(nm, nmt) == 0
			call system(a:cmd . " \"" . nmt . "\"")
			call rename(nmt . "." . expand("<afile>:e"), nm)
		endif
	endif
endfun

" vim: set sw=4 :
