" ragtag.vim - Ghetto XML/HTML mappings (formerly allml.vim)
" Author:       Tim Pope <http://tpo.pe/>
" Version:      2.0
" GetLatestVimScripts: 1896 1 :AutoInstall: ragtag.vim

if exists("g:loaded_ragtag") || &cp || v:version < 700
  finish
endif
let g:loaded_ragtag = 1

if !exists('g:html_indent_inctags')
  let g:html_indent_inctags = 'body,head,html,tbody,p,li,dt,dd'
endif
if !exists('g:html_indent_autotags')
  let g:html_indent_autotags = 'wbr'
endif
if !exists('g:html_indent_script1')
  let g:html_indent_script1 = 'inc'
endif
if !exists('g:html_indent_style1')
  let g:html_indent_style1 = 'inc'
endif

augroup ragtag
  autocmd!
  autocmd BufReadPost * if ! did_filetype() && getline(1)." ".getline(2).
        \ " ".getline(3) =~? '<\%(!DOCTYPE \)\=html\>' | setf html | endif
  autocmd FileType *html*,wml,jsp,gsp,mustache,smarty             call s:Init()
  autocmd FileType php,asp*,cf,mason,eruby,liquid,jst,eelixir     call s:Init()
  autocmd FileType xml,xslt,xsd,docbk                             call s:Init()
  autocmd FileType vue                                            call s:Init()
  autocmd FileType jinja,njk                                      call s:Init()
  autocmd FileType javascript.jsx,jsx,javascriptreact,handlebars  call s:Init()
  autocmd FileType typescript.tsx,tsx,typescriptreact             call s:Init()
  autocmd InsertLeave * call s:Leave()
  autocmd CursorHold * if exists("b:loaded_ragtag") | call s:Leave() | endif
augroup END

inoremap <silent> <Plug>ragtagHtmlComplete <C-R>=<SID>htmlEn()<CR><C-X><C-O><C-P><C-R>=<SID>htmlDis()<CR><C-N>

" Public interface, for if you have your own filetypes to activate on
function! RagtagInit()
  call s:Init()
endfunction

function! AllmlInit()
  call s:Init()
endfunction

function! s:isFiletype(ft)
  return index(split(&filetype, '\.'), a:ft) >= 0
endfunction

function! s:Init()
  let b:loaded_ragtag = 1
  if s:subtype() == "xml"
    imap <script> <buffer> <C-X>! <?xml version="1.0" encoding="<C-R>=toupper(<SID>charset())<CR>"?>
  elseif s:subtype() == "xhtml"
    imap <script> <buffer> <C-X>! <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  else
    imap <script> <buffer> <C-X>! <!DOCTYPE html>
  endif

  if empty(&l:define)
    let &l:define = '\<id=["'']\='
    let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe') . '|setl def='
  endif

  imap <silent> <buffer> <C-X># <C-R>=<SID>charsetTag()<CR>
  inoremap <silent> <buffer> <SID>HtmlComplete <C-R>=<SID>htmlEn()<CR><C-X><C-O><C-P><C-R>=<SID>htmlDis()<CR><C-N>
  imap     <buffer> <C-X>H <SID>HtmlComplete
  inoremap <silent> <buffer> <C-X>$ <C-R>=<SID>javascriptIncludeTag()<CR>
  inoremap <silent> <buffer> <C-X>@ <C-R>=<SID>stylesheetTag()<CR>
  inoremap <silent> <buffer> <C-X><Space> <Esc>ciW<Lt><C-R>"<C-R>=<SID>tagextras()<CR>></<C-R>"><Esc>F<i
  inoremap <silent> <buffer> <C-X><CR> <Esc>ciW<Lt><C-R>"<C-R>=<SID>tagextras()<CR>><CR></<C-R>"><Esc>O
  if exists("&omnifunc")
    inoremap <silent> <buffer> <C-X>/ <Lt>/<C-R>=<SID>htmlEn()<CR><C-X><C-O><C-R>=<SID>htmlDis()<CR><C-R>=<SID>reindent()<CR>
    if exists(":XMLns")
      XMLns xhtml10s
    endif
  else
    inoremap <silent> <buffer> <C-X>/ <Lt>/><Left>
  endif
  let b:surround_{char2nr("p")} = "<p>\n\t\r\n</p>"
  let b:surround_{char2nr("d")} = "<div\1div: \r^[^ ]\r &\1>\n\t\r\n</div>"
  imap <buffer> <C-X><C-_> <C-X>/
  imap <buffer> <SID>ragtagOopen    <C-X><Lt><Space>
  imap <buffer> <SID>ragtagOclose   <Space><C-X>><Left><Left>
  if s:isFiletype('php')
    inoremap <buffer> <C-X><Lt> <?php
    inoremap <buffer> <C-X>>    ?>
    inoremap <buffer> <SID>ragtagOopen    <?php<Space>echo<Space>
    let b:surround_45 = "<?php \r ?>"
    let b:surround_61 = "<?= \r ?>"
  elseif s:isFiletype('htmltt') || s:isFiletype('tt2html')
    inoremap <buffer> <C-X><Lt> [%
    inoremap <buffer> <C-X>>    %]
    let b:surround_45  = "[% \r %]"
    let b:surround_61  = "[% \r %]"
    if !exists("b:surround_101")
      let b:surround_101 = "[% \r %]\n[% END %]"
    endif
  elseif s:isFiletype('mustache')
    inoremap <buffer> <SID>ragtagOopen    {{<Space>
    inoremap <buffer> <SID>ragtagOclose   <Space>}}<Left><Left>
    inoremap <buffer> <C-X><Lt> {{
    inoremap <buffer> <C-X>>    }}
    let b:surround_45 = "{{ \r }}"
    let b:surround_61 = "{{ \r }}"
  elseif s:isFiletype('django') || s:isFiletype('htmldjango') || s:isFiletype('liquid') || s:isFiletype('htmljinja') || s:isFiletype('jinja')
    inoremap <buffer> <SID>ragtagOopen    {{<Space>
    inoremap <buffer> <SID>ragtagOclose   <Space>}}<Left><Left>
    inoremap <buffer> <C-X><Lt> {%
    inoremap <buffer> <C-X>>    %}
    let b:surround_45 = "{% \r %}"
    let b:surround_61 = "{{ \r }}"
  elseif s:isFiletype('mason')
    inoremap <buffer> <SID>ragtagOopen    <&<Space>
    inoremap <buffer> <SID>ragtagOclose   <Space>&><Left><Left>
    inoremap <buffer> <C-X><Lt> <%
    inoremap <buffer> <C-X>>    %>
    let b:surround_45 = "<% \r %>"
    let b:surround_61 = "<& \r &>"
  elseif s:isFiletype('cf')
    inoremap <buffer> <SID>ragtagOopen    <cfoutput>
    inoremap <buffer> <SID>ragtagOclose   </cfoutput><Left><C-Left><Left>
    inoremap <buffer> <C-X><Lt> <cf
    inoremap <buffer> <C-X>>    >
    let b:surround_45 = "<cf\r>"
    let b:surround_61 = "<cfoutput>\r</cfoutput>"
  elseif s:isFiletype('smarty')
    inoremap <buffer> <SID>ragtagOopen    {
    inoremap <buffer> <SID>ragtagOclose   }
    inoremap <buffer> <C-X><Lt> {
    inoremap <buffer> <C-X>>    }
    let b:surround_45 = "{\r}"
    let b:surround_61 = "{\r}"
  elseif s:isFiletype('handlebars')
    inoremap <buffer> <SID>ragtagOopen    {{
    inoremap <buffer> <SID>ragtagOclose   }}
    inoremap <buffer> <C-X><Lt> {{
    inoremap <buffer> <C-X>>    }}
    let b:surround_45 = "{{\r}}"
    let b:surround_61 = "{{\r}}"
  elseif &filetype ==# 'html'
    inoremap <buffer> <SID>ragtagOopen    <!--#echo var=
    inoremap <buffer> <C-X><Lt> <!--#
    inoremap <buffer> <C-X>>    -->
    let b:surround_45 = "<!--#\r -->"
    let b:surround_61 = "<!--#echo var=\r -->"
  else
    inoremap <buffer> <SID>ragtagOopen    <%=<Space>
    inoremap <buffer> <C-X><Lt> <%
    inoremap <buffer> <C-X>>    %>
    let b:surround_45 = "<% \r %>"
    let b:surround_61 = "<%= \r %>"
  endif
  imap <script> <buffer> <C-X>= <SID>ragtagOopen<SID>ragtagOclose<Left>
  imap <script> <buffer> <C-X>+ <C-V><NL><Esc>I<SID>ragtagOopen<Esc>A<SID>ragtagOclose<Esc>F<NL>s
  " <%\n\n%>
  if s:isFiletype('cf')
    inoremap <buffer> <C-X>] <cfscript><CR></cfscript><Esc>O
  elseif s:isFiletype('mason')
    inoremap <buffer> <C-X>] <%perl><CR></%perl><Esc>O
  elseif &filetype ==# 'html' || &filetype ==# 'xml' || &filetype ==# 'xhtml'
    imap     <buffer> <C-X>] <script<C-R>=<SID>javascriptType()<CR>><CR></script><Esc>O
  else
    imap     <buffer> <C-X>] <C-X><Lt><CR><C-X>><Esc>O
  endif
  " <% %>
  if s:isFiletype('eruby') || s:isFiletype('jst')
    inoremap  <buffer> <C-X>- <%<Space><Space>%><Esc>2hi
    inoremap  <buffer> <C-X>_ <C-V><NL><Esc>I<%<Space><Esc>A<Space>%><Esc>F<NL>s
  elseif s:isFiletype('cf')
    inoremap  <buffer> <C-X>- <cf><Left>
    inoremap  <buffer> <C-X>_ <cfset ><Left>
  elseif s:isFiletype('smarty')
    imap <buffer> <C-X>- <C-X><Lt><C-X>><Esc>i
    imap <buffer> <C-X>_ <C-V><NL><Esc>I<C-X><Lt><Esc>A<C-X>><Esc>F<NL>s
  else
    imap <buffer> <C-X>- <C-X><Lt><Space><Space><C-X>><Esc>2hi
    imap <buffer> <C-X>_ <C-V><NL><Esc>I<C-X><Lt><Space><Esc>A<Space><C-X>><Esc>F<NL>s
  endif
  " Comments
  if s:isFiletype('aspperl') || s:isFiletype('aspvbs')
    imap <buffer> <C-X>' <C-X><Lt>'<Space><Space><C-X>><Esc>2hi
    imap <buffer> <C-X>" <C-V><NL><Esc>I<C-X><Lt>'<Space><Esc>A<Space><C-X>><Esc>F<NL>s
    let b:surround_35 = maparg("<C-X><Lt>","i")."' \r ".maparg("<C-X>>","i")
  elseif s:isFiletype('jsp') || s:isFiletype('gsp')
    inoremap <buffer> <C-X>'     <Lt>%--<Space><Space>--%><Esc>4hi
    inoremap <buffer> <C-X>"     <C-V><NL><Esc>I<%--<Space><Esc>A<Space>--%><Esc>F<NL>s
    let b:surround_35 = "<%-- \r --%>"
  elseif s:isFiletype('cf')
    inoremap <buffer> <C-X>'     <Lt>!---<Space><Space>---><Esc>4hi
    inoremap <buffer> <C-X>"     <C-V><NL><Esc>I<!---<Space><Esc>A<Space>---><Esc>F<NL>s
    setlocal commentstring=<!---%s--->
    let b:surround_35 = "<!--- \r --->"
  elseif &filetype ==# 'html' || &filetype ==# 'xml' || &filetype ==# 'xhtml'
    inoremap <buffer> <C-X>'     <Lt>!--<Space><Space>--><Esc>3hi
    inoremap <buffer> <C-X>"     <C-V><NL><Esc>I<!--<Space><Esc>A<Space>--><Esc>F<NL>s
    let b:surround_35 = "<!-- \r -->"
  elseif s:isFiletype('django') || s:isFiletype('htmldjango') || s:isFiletype('htmljinja')
    inoremap <buffer> <C-X>'     {#<Space><Space>#}<Esc>2hi
    inoremap <buffer> <C-X>"     <C-V><NL><Esc>I<C-X>{#<Space><Esc>A<Space>#}<Esc>F<NL>s
    let b:surround_35 = "{# \r #}"
  elseif s:isFiletype('liquid')
    inoremap <buffer> <C-X>'     {%<Space>comment<Space>%}{%<Space>endcomment<Space>%}<Esc>15hi
    inoremap <buffer> <C-X>"     <C-V><NL><Esc>I<C-X>{%<Space>comment<Space>%}<Esc>A{%<Space>endcomment<Space>%}<Esc>F<NL>s
    let b:surround_35 = "{% comment %}\r{% endcomment %}"
  elseif s:isFiletype('smarty')
    inoremap <buffer> <C-X>'     {*<Space><Space>*}<Esc>2hi
    inoremap <buffer> <C-X>"     <C-V><NL><Esc>I<C-X>{*<Space><Esc>A<Space>*}<Esc>F<NL>s
    let b:surround_35 = "{* \r *}"
  elseif s:isFiletype('handlebars')
    imap <script> <buffer> <C-X>= <SID>ragtagOopen<SID>ragtagOclose<Left><Left>
    inoremap  <buffer> <C-X>_ <Esc>ciW{{#<C-R>"}}<CR>{{/<C-R>"}}<Esc>khi
    inoremap  <buffer> <C-X>' {{!}}<Esc>hi
    inoremap  <buffer> <C-X>" <C-V><NL><Esc>I{{!<Esc>A}}<Esc>F<NL>s
  else
    imap <buffer> <C-X>' <C-X><Lt>#<Space><Space><C-X>><Esc>2hi
    imap <buffer> <C-X>" <C-V><NL><Esc>I<C-X><Lt>#<Space><Esc>A<Space><C-X>><Esc>F<NL>s
    let b:surround_35 = maparg("<C-X><Lt>","i")."# \r ".maparg("<C-X>>","i")
  endif
  imap <buffer> <C-X>%           <Plug>ragtagUrlEncode
  imap <buffer> <C-X>&           <Plug>ragtagXmlEncode
  imap <buffer> <C-V>%           <Plug>ragtagUrlV
  imap <buffer> <C-V>&           <Plug>ragtagXmlV
  if !exists("b:did_indent")
    if s:subtype() == "xml"
      runtime! indent/xml.vim
    else
      runtime! indent/html.vim
    endif
  endif
  if exists("g:html_indent_tags") && g:html_indent_tags !~ '\\|p\>'
    let g:html_indent_tags = g:html_indent_tags.'\|p\|li\|dt\|dd'
    let g:html_indent_tags = g:html_indent_tags.'\|article\|aside\|audio\|bdi\|canvas\|command\|datalist\|details\|figcaption\|figure\|footer\|header\|hgroup\|mark\|meter\|nav\|output\|progress\|rp\|rt\|ruby\|section\|summary\|time\|video'
  endif
  set indentkeys+=!^F
  let b:surround_indent = 1
  silent doautocmd User Ragtag
  silent doautocmd User ragtag
endfunction

function! s:Leave()
  call s:disableescape()
endfunction

function! s:length(str)
  return strlen(substitute(a:str,'.','.','g'))
endfunction

function! s:repeat(str,cnt)
  let cnt = a:cnt
  let str = ""
  while cnt > 0
    let str = str . a:str
    let cnt = cnt - 1
  endwhile
  return str
endfunction

function! s:reindent()
  if (len(&indentexpr) || &cindent)
    return "\<C-F>"
  endif
  return ""
endfun

function! s:stylesheetType()
  if s:subtype() == 'html5'
    return ''
  else
    return ' type="text/css"'
  endif
endfunction

function! s:stylesheetTag()
  if !exists("b:ragtag_stylesheet_link_tag")
    if exists("b:allml_stylesheet_link_tag")
      let b:ragtag_stylesheet_link_tag = b:allml_stylesheet_link_tag
    else
      let b:ragtag_stylesheet_link_tag = '<link rel="stylesheet"'.s:stylesheetType()." href=\"/stylesheets/\r.css\" />"
    endif
  endif
  return s:insertTag(b:ragtag_stylesheet_link_tag)
endfunction

function! s:javascriptType()
  if s:subtype() == 'html5'
    return ''
  else
    return ' type="text/javascript"'
  endif
endfunction

function! s:javascriptIncludeTag()
  if !exists("b:ragtag_javascript_include_tag")
    if exists("b:allml_javascript_include_tag")
      let b:ragtag_javascript_include_tag = b:allml_javascript_include_tag
    else
      let b:ragtag_javascript_include_tag = '<script'.s:javascriptType()." src=\"/javascripts/\r.js\"></script>"
    endif
  endif
  return s:insertTag(b:ragtag_javascript_include_tag)
endfunction

function! s:insertTag(tag)
  let tag = a:tag
  if s:subtype() == "html"
    let tag = substitute(a:tag,'\s*/>','>','g')
  endif
  let before = matchstr(tag,'^.\{-\}\ze\r')
  let after  = matchstr(tag,'\r\zs\%(.*\r\)\@!.\{-\}$')
  " middle isn't currently used
  let middle = matchstr(tag,'\r\zs.\{-\}\ze\r')
  return before.after.s:repeat("\<Left>",s:length(after))
endfunction

function! s:htmlEn()
  let b:ragtag_omni = &l:omnifunc
  let b:ragtag_isk = &l:isk
  let b:ragtag_completeopt = &l:completeopt
  " : is for namespaced xml attributes
  setlocal omnifunc=htmlcomplete#CompleteTags isk+=: completeopt=
  return ""
endfunction

function! s:htmlDis()
  if exists("b:ragtag_omni")
    let &l:omnifunc = b:ragtag_omni
    unlet b:ragtag_omni
  endif
  if exists("b:ragtag_isk")
    let &l:isk = b:ragtag_isk
    unlet b:ragtag_isk
  endif
  if exists("b:ragtag_completeopt")
    let &l:completeopt = b:ragtag_completeopt
    unlet b:ragtag_completeopt
  endif
  return ""
endfunction

function! s:subtype()
  let top = getline(1)."\n".getline(2)
  if (top =~ '<?xml\>' && &ft !~? 'html') || &ft =~? '^\%(xml\|xsd\|xslt\|docbk\)$'
    return "xml"
  elseif top =~? '\<xhtml\>'
    return 'xhtml'
  elseif top =~? '<!DOCTYPE html>'
    return 'html5'
  elseif top =~? '[^<]\<html\>'
    return "html"
  elseif s:isFiletype('xhtml')
    return "xhtml"
  elseif exists("b:loaded_ragtag")
    return "html5"
  else
    return ""
  endif
endfunction

function! s:closetagback()
  if s:subtype() == "html"
    return ">\<Left>"
  else
    return " />\<Left>\<Left>\<Left>"
  endif
endfunction

function! s:closetag()
  if s:subtype() == "html"
    return ">"
  else
    return " />"
  endif
endfunction

function! s:charset()
  let enc = &fileencoding
  if enc == ""
    let enc = &encoding
  endif
  if enc == "latin1"
    return "ISO-8859-1"
  elseif enc == ""
    return "US-ASCII"
  else
    return enc
  endif
endfunction

function! s:charsetTag()
  if s:subtype() == 'html5'
    return '<meta charset="'.s:charset().'"'.s:closetag()
  else
    return '<meta http-equiv="Content-Type" content="text/html; charset='.s:charset().'"'.s:closetag()
  endif
endfunction

function! s:tagextras()
  if s:subtype() == "xml"
    return ""
  elseif @" == 'html' && s:subtype() == 'xhtml'
    let lang = "en"
    if exists("$LANG") && $LANG =~ '^..'
      let lang = strpart($LANG,0,2)
    endif
    return ' xmlns="http://www.w3.org/1999/xhtml" lang="'.lang.'" xml:lang="'.lang.'"'
  elseif @" == 'style'
    return s:stylesheetType()
  elseif @" == 'script'
    return s:javascriptType()
  elseif @" == 'table'
    return ' cellspacing="0"'
  else
    return ""
  endif
endfunction

inoremap <silent> <SID>urlspace <C-R>=<SID>getinput()=~?'\%([?&]\<Bar>&amp;\)[%a-z0-9._~+-]*=[%a-z0-9._~+-]*$'?'+':'%20'<CR>

function! s:urltab(htmlesc)
  let line = s:getinput()
  let g:line = line
  if line =~ '[^ <>"'."'".']\@<!\w\+$'
    return ":"
  elseif line =~ '[^ <>"'."'".']\@<!\w\+:/\=/\=[%a-z0-9._~+-]*$'
    return "/"
  elseif line =~? '\%([?&]\|&amp;\)[%a-z0-9._~+-]*$'
    return "="
  elseif line =~? '\%([?&]\|&amp;\)[%a-z0-9._~+-]*=[%a-z0-9._~+-]*$'
    if a:htmlesc || synIDattr(synID(line('.'),col('.')-1,1),"name") =~ 'mlString$'
      return "&amp;"
    else
      return "&"
    endif
  elseif line =~ '/$\|\.\w\+$'
    return "?"
  else
    return "/"
  endif
endfunction

function! s:toggleurlescape()
  let htmllayer = 0
  if exists("b:ragtag_escape_mode")
    if b:ragtag_escape_mode == "url"
      call s:disableescape()
      return ""
    elseif b:ragtag_escape_mode == "xml"
      let htmllayer = 1
    endif
    call s:disableescape()
  endif
  let b:ragtag_escape_mode = "url"
  imap     <buffer> <BS> <Plug>ragtagBSUrl
  inoremap <buffer> <CR> %0A
  imap <script> <buffer> <Space> <SID>urlspace
  inoremap <buffer> <Tab> &
  inoremap <buffer> <Bar> %7C
  if htmllayer
    inoremap <silent> <buffer> <Tab> <C-R>=<SID>urltab(1)<CR>
  else
    inoremap <silent> <buffer> <Tab> <C-R>=<SID>urltab(0)<CR>
  endif
  let i = 33
  while i < 127
    " RFC3986: reserved = :/?#[]@ !$&'()*+,;=
    if nr2char(i) =~# '[|=A-Za-z0-9_.~-]'
    else
      call s:urlmap(nr2char(i))
    endif
    let i = i + 1
  endwhile
  return ""
endfunction

function! s:urlencode(char)
  let i = 0
  let repl = ""
  while i < strlen(a:char)
    let repl  = repl . printf("%%%02X",char2nr(strpart(a:char,i,1)))
    let i = i + 1
  endwhile
  return repl
endfunction

function! s:urlmap(char)
  let repl = s:urlencode(a:char)
  exe "inoremap <buffer> ".a:char." ".repl
endfunction

function! s:urlv()
  return s:urlencode(nr2char(getchar()))
endfunction

function! s:togglexmlescape()
  if exists("b:ragtag_escape_mode")
    if b:ragtag_escape_mode == "xml"
      call s:disableescape()
      return ""
    endif
    call s:disableescape()
  endif
  let b:ragtag_escape_mode = "xml"
  imap <buffer> <BS> <Plug>ragtagBSXml
  inoremap <buffer> <Lt> &lt;
  inoremap <buffer> >    &gt;
  inoremap <buffer> &    &amp;
  inoremap <buffer> "    &quot;
  return ""
endfunction

function! s:disableescape()
  if exists("b:ragtag_escape_mode")
    if b:ragtag_escape_mode == "xml"
      silent! iunmap <buffer> <BS>
      silent! iunmap <buffer> <Lt>
      silent! iunmap <buffer> >
      silent! iunmap <buffer> &
      silent! iunmap <buffer> "
    elseif b:ragtag_escape_mode == "url"
      silent! iunmap <buffer> <BS>
      silent! iunmap <buffer> <Tab>
      silent! iunmap <buffer> <CR>
      silent! iunmap <buffer> <Space>
      silent! iunmap <buffer> <Bar>
      let i = 33
      while i < 127
        if nr2char(i) =~# '[|A-Za-z0-9_.~-]'
        else
          exe "silent! iunmap <buffer> ".nr2char(i)
        endif
        let i = i + 1
      endwhile
    endif
    unlet b:ragtag_escape_mode
  endif
endfunction

function! s:getinput()
  return strpart(getline('.'),0,col('.')-1)
endfunction

function! s:bspattern(pattern)
  let start = s:getinput()
  let match = matchstr(start,'\%('.a:pattern.'\)$')
  if match == ""
    return "\<BS>"
  else
    return s:repeat("\<BS>",strlen(match))
  endif
endfunction

inoremap <silent> <Plug>ragtagBSUrl     <C-R>=<SID>bspattern('%\x\x\=\<Bar>&amp;')<CR>
inoremap <silent> <Plug>ragtagBSXml     <C-R>=<SID>bspattern('&#\=\w*;\<Bar><[^><]*>\=')<CR>
inoremap <silent>  <SID>ragtagUrlEncode <C-R>=<SID>toggleurlescape()<CR>
inoremap <silent>  <SID>ragtagXmlEncode <C-R>=<SID>togglexmlescape()<CR>
inoremap <silent> <Plug>ragtagUrlEncode <C-R>=<SID>toggleurlescape()<CR>
inoremap <silent> <Plug>ragtagXmlEncode <C-R>=<SID>togglexmlescape()<CR>
inoremap <silent> <Plug>ragtagUrlV      <C-R>=<SID>urlv()<CR>
inoremap <silent> <Plug>ragtagXmlV      <C-R>="&#".getchar().";"<CR>

if exists("g:ragtag_global_maps")
  imap     <C-X>H      <Plug>ragtagHtmlComplete
  imap     <C-X>/    </<Plug>ragtagHtmlComplete
  imap     <C-X>%      <Plug>ragtagUrlEncode
  imap     <C-X>&      <Plug>ragtagXmlEncode
  imap     <C-V>%      <Plug>ragtagUrlV
  imap     <C-V>&      <Plug>ragtagXmlV
endif
