local Job = require('plenary.job')

local log = require('el._log')
local modes = require('el.data').modes
local mode_highlights = require('el.data').mode_highlights
local sections = require('el.sections')

local extensions = {}

local git_changed = vim.regex([[\(\d\+\)\( file changed\)\@=]])
local git_insertions = vim.regex([[\(\d\+\)\( insertions\)\@=]])
local git_deletions = vim.regex([[\(\d\+\)\( deletions\)\@=]])

local parse_shortstat_output = function(s)
  local result = {}

  local changed = {git_changed:match_str(s)}
  if not vim.tbl_isempty(changed) then
    table.insert(result, string.format('+%s', string.sub(s, changed[1] + 1, changed[2])))
  end

  local insert = {git_insertions:match_str(s)}
  if not vim.tbl_isempty(insert) then
    table.insert(result, string.format('~%s', string.sub(s, insert[1] + 1, insert[2])))
  end

  local delete = {git_deletions:match_str(s)}
  if not vim.tbl_isempty(delete) then
    table.insert(result, string.format('-%s', string.sub(s, delete[1] + 1, delete[2])))
  end

  if vim.tbl_isempty(result) then
    return nil
  end

  return string.format("[%s]", table.concat(result, ", "))
end

extensions.git_changes = function(_, buffer)
  if vim.api.nvim_buf_get_option(buffer.bufnr, 'bufhidden') ~= ""
      or vim.api.nvim_buf_get_option(buffer.bufnr, 'buftype') == 'nofile' then
    return
  end

  if vim.fn.filereadable(buffer.name) ~= 1 then
    return
  end

  local j = Job:new({
    command = "git",
    args = {"diff", "--shortstat", buffer.name},
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  })

  local ok, result = pcall(function()
    return parse_shortstat_output(vim.trim(j:start():wait()._raw_output))
  end)

  if ok then
    return result
  end

  return ''
end

extensions.mode = function(_, _)
  local mode = vim.fn.mode()

  local higroup = mode_highlights[mode]
  local display_name = modes[mode][1]

  return sections.highlight(
    higroup,
    string.format('[%s]', display_name)
  )
end

-- adding it as a function just for better clarity
-- on whats going on
local file_extension = function(filename)
  return filename:match('%.(%w+)$')
end

extensions.file_icon = function(_, bufnr)
  local icons = {
    default_symbol = '',
    ai = '',
    apache = '',
    awk = '',
    bash = '',
    bat = '',
    bazel = '',
    bib = '',
    c = '',
    cc = '',
    clisp = '',
    clj = '',
    cljc = '',
    clojure = '',
    cmake = '',
    cobol = '',
    coffee = ' ',
    config = '',
    coq = '',
    cp = '',
    cpp = '',
    crystal = '',
    csh = '',
    csharp = '',
    css = '',
    cuda = '',
    cxx = '',
    cython = '',
    d = '',
    dart = '',
    db = '',
    diff = '',
    dockerfile = '',
    dump = '',
    edn = '',
    ejs = '',
    elisp = '',
    elixir = '',
    elm = '',
    erl = '',
    fish = '',
    fs = '',
    fsi = '',
    fsscript = '',
    fsx = '',
    go = '',
    graphviz = '',
    h = '',
    hbs = '',
    hh = '',
    hpp = '',
    hrl = '',
    hs = '',
    htm = '',
    html = '',
    hxx = '',
    ico = '',
    idris = '',
    ini = '',
    j = '',
    jasmine = '',
    java = '',
    jl = '',
    javascript = '',
    json = '',
    jsx = '',
    julia = '⛬',
    jupyter = '',
    kotlin = '',
    ksh = '',
    labview = '',
    less = '',
    lhs = '',
    lisp = 'λ',
    llvm = '',
    lsp = 'λ',
    lua = '',
    m = '',
    markdown = '',
    mathematica = '',
    matlab = '',
    max = '',
    md = '',
    meson = '',
    ml = '',
    mli = '',
    mustache = '',
    nginx = '',
    nim = '',
    nix = '',
    nvcc = '',
    nvidia = '',
    octave = '',
    opencl = '',
    org = '',
    patch = '',
    perl6 = '',
    php = '',
    pl = '',
    postgresql = '',
    pp = '',
    prolog = '',
    ps = '',
    ps1 = '',
    psb = '',
    psd = '',
    py = '',
    pyc = '',
    pyd = '',
    pyo = '',
    python = '',
    rb = '',
    react = '',
    reason = '',
    rkt = '',
    rlib = '',
    rmd = '',
    rs = '',
    rss = '',
    ruby = '',
    rust = '',
    sass = '',
    scala = '',
    scheme = 'λ',
    scm = 'λ',
    scrbl = '',
    scss = '',
    sh = '',
    slim = '',
    sln = '',
    sql = '',
    styl = '',
    suo = '',
    svg = '',
    swift = '',
    t = '',
    tex = '',
    toml = '',
    ts = '',
    tsx = '',
    twig = '',
    txt = 'e',
    typescript = '',
    vim = '',
    vue = '﵂',
    xul = '',
    yaml = '',
    yml = '',
    zsh = '',
  }
  local ficon = icons[bufnr.filetype]
  if ficon == nil then
    local extension = file_extension(bufnr.name)
    return icons[extension] or icons.default_symbol
  end
  return ficon
end

return extensions
