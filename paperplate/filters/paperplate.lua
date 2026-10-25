-- paperplate.lua
--
-- One Pandoc Lua filter for two jobs:
--
--   1. Cross-references for figures, tables, equations and sections.
--        Label:      ![Caption](img.png){#fig:name}
--                    : Caption {#tbl:name}          (after a table)
--                    $$ a = b $$ {#eq:name}
--                    # Heading {#sec:name}
--        Reference:  @fig:name   or   [@fig:name]   or   [@fig:a; @fig:b]
--
--      For Typst output the numbering is done by Typst itself (#ref), so
--      "Figure 3" is always consistent with the caption. For every other
--      output format (DOCX, HTML, ...) this filter computes the numbers.
--
--   2. Word count. If the metadata field `word-count` is "auto", it is replaced
--      by the number of words in the body (code blocks and the bibliography
--      are not counted).
--
-- Run this filter BEFORE --citeproc, otherwise citeproc complains that
-- "fig:name" is not a bibliography key.

local is_typst = FORMAT:match("typst") ~= nil

-- label prefix -> English supplement (used for non-Typst output only)
local KINDS = {
  fig = "Figure",
  tbl = "Table",
  eq  = "Equation",
  sec = "Section",
}

local source_dir = "src"   -- images in Markdown are relative to this project directory
local labels = {}      -- id -> { kind = "fig", number = "3", text = "..." }
local counters = { fig = 0, tbl = 0, eq = 0 }
local sec_counter = {}
local heading_numbering = false

local function kind_of(id)
  if not id then return nil end
  local prefix = id:match("^(%a+):")
  if prefix and KINDS[prefix] then return prefix end
  return nil
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Pass 1: collect labels and number them ------------------------------------

local function eq_label(para)
  -- Matches: Para[ Math(DisplayMath), Space, Str "{#eq:name}" ]
  local c = para.content
  if #c < 2 then return nil end
  local last = c[#c]
  if last.t ~= "Str" then return nil end
  local id = last.text:match("^{#(eq:[%w:_%-%.]+)}$")
  if not id then return nil end
  local math_el
  for i = 1, #c - 1 do
    if c[i].t == "Math" and c[i].mathtype == "DisplayMath" then
      if math_el then return nil end -- more than one equation: not our pattern
      math_el = c[i]
    elseif c[i].t ~= "Space" and c[i].t ~= "SoftBreak" then
      return nil -- other text in the paragraph: not a display equation
    end
  end
  if not math_el then return nil end
  return id, math_el
end

local function collect(doc)
  -- walk() reaches blocks nested in divs too, and visits siblings in order.
  doc:walk({
    Figure = function(block)
      if kind_of(block.identifier) == "fig" then
        counters.fig = counters.fig + 1
        labels[block.identifier] = { kind = "fig", number = tostring(counters.fig) }
      end
    end,
    Table = function(block)
      if kind_of(block.identifier) == "tbl" then
        counters.tbl = counters.tbl + 1
        labels[block.identifier] = { kind = "tbl", number = tostring(counters.tbl) }
      end
    end,
    Para = function(block)
      local id = eq_label(block)
      if id then
        counters.eq = counters.eq + 1
        labels[id] = { kind = "eq", number = tostring(counters.eq) }
      end
    end,
    Header = function(block)
      local level = block.level
      local number
      if not block.classes:includes("unnumbered") then
        sec_counter[level] = (sec_counter[level] or 0) + 1
        for l = level + 1, 6 do sec_counter[l] = 0 end
        local parts = {}
        for l = 1, level do parts[#parts + 1] = tostring(sec_counter[l] or 0) end
        number = table.concat(parts, ".")
      end
      if kind_of(block.identifier) == "sec" then
        labels[block.identifier] = {
          kind = "sec",
          number = number,
          text = pandoc.utils.stringify(block.content),
        }
      end
    end,
  })
end

-- Pass 2: rewrite references ---------------------------------------------------

local function ref_inlines(id)
  local info = labels[id]
  if is_typst then
    if info.kind == "sec" and not heading_numbering then
      -- #ref on an unnumbered heading is a Typst error; link to its title.
      return { pandoc.Link(info.text, "#" .. id) }
    end
    return { pandoc.RawInline("typst", "#ref(<" .. id .. ">)") }
  end
  local label = KINDS[info.kind] .. " " .. (info.number or "")
  if info.kind == "sec" and not info.number then label = info.text end
  return { pandoc.Link(trim(label), "#" .. id) }
end

local function Cite(cite)
  local all_ours = #cite.citations > 0
  local any_ours = false
  for _, c in ipairs(cite.citations) do
    if kind_of(c.id) then any_ours = true else all_ours = false end
  end
  if not any_ours then return nil end -- ordinary bibliography citation
  if not all_ours then
    io.stderr:write("[paperplate] cannot mix cross-references and citations in one bracket; split them\n")
    return nil
  end
  local out = {}
  for i, c in ipairs(cite.citations) do
    if not labels[c.id] then
      io.stderr:write("[paperplate] WARNING: reference to undefined label '" .. c.id .. "'\n")
      out[#out + 1] = pandoc.Strong(pandoc.Str(c.id .. "?"))
    else
      if i > 1 then out[#out + 1] = pandoc.Str(", ") end
      for _, inl in ipairs(ref_inlines(c.id)) do out[#out + 1] = inl end
    end
  end
  return out
end

-- Labels on blocks ---------------------------------------------------------------

local function prefix_caption(caption, text)
  -- Put "Figure 3: " in front of the first caption block (non-Typst only).
  local first = caption.long[1]
  if first and (first.t == "Plain" or first.t == "Para") then
    local prefix = { pandoc.Strong(pandoc.Str(text .. ".")), pandoc.Space() }
    first.content = pandoc.List(prefix):extend(first.content)
  end
  return caption
end

local function Figure(fig)
  local info = labels[fig.identifier]
  if info and not is_typst then
    fig.caption = prefix_caption(fig.caption, "Figure " .. info.number)
    return fig
  end
end

local function Table(tbl)
  local info = labels[tbl.identifier]
  if info and not is_typst then
    tbl.caption = prefix_caption(tbl.caption, "Table " .. info.number)
    return tbl
  end
end

local function Para(para)
  local id, math_el = eq_label(para)
  if not id then return nil end
  local info = labels[id]
  if is_typst then
    -- Let Pandoc convert the TeX math to Typst math, then attach the label.
    local doc = pandoc.Pandoc({ pandoc.Para({ math_el }) })
    local typst_math = trim(pandoc.write(doc, "typst"))
    return pandoc.RawBlock("typst", typst_math .. " <" .. id .. ">")
  end
  math_el.text = trim(math_el.text) .. " \\qquad (" .. info.number .. ")"
  return pandoc.Para({ math_el })
end

-- Images ---------------------------------------------------------------------------------

-- Typst resolves image paths relative to the generated .typ file, which lives in
-- build/. Rewrite relative paths to project-root paths so Markdown can simply say
-- ![caption](figures/chart.png) regardless of where the build files are written.
local function Image(img)
  if not is_typst then return nil end
  local src = img.src
  if src:match("^/") or src:match("^%a[%w+.-]*://") or src:match("^data:") then
    return nil
  end
  img.src = "/" .. source_dir .. "/" .. src:gsub("^%./", "")
  return img
end

-- Raw LaTeX --------------------------------------------------------------------------------
-- Pandoc silently drops raw LaTeX when the output is not LaTeX, which leaves holes in the
-- document (an empty pair of quotes where \verb|...| stood, say). Translate the few
-- commands people actually use, and warn about everything else so nothing vanishes unseen.

local keeps_tex = FORMAT:match("latex") or FORMAT:match("beamer")
local build_date = nil   -- set in Pandoc(); used for \today

local function is_tex(fmt) return fmt == "tex" or fmt == "latex" end

local function page_break()
  if is_typst then return pandoc.RawBlock("typst", "#pagebreak()") end
  if FORMAT:match("docx") then
    return pandoc.RawBlock("openxml", '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
  end
  return nil
end

local function warn_raw(text)
  io.stderr:write("[WARNING] paperplate: raw LaTeX is not supported and was left out: "
    .. trim(text):gsub("\n", " ") .. "\n")
end

local function RawInline(el)
  if keeps_tex or not is_tex(el.format) then return nil end
  local delim, body = el.text:match("^\\verb%*?(%p)(.-)%1$")
  if body then return pandoc.Code(body) end
  local name = trim(el.text):match("^\\(%a+)$")
  if name == "today" and build_date then return pandoc.Str(build_date) end
  if (name == "newpage" or name == "pagebreak" or name == "clearpage") and is_typst then
    return pandoc.RawInline("typst", "#pagebreak()")
  end
  warn_raw(el.text)
  return {}
end

local function RawBlock(el)
  if keeps_tex or not is_tex(el.format) then return nil end
  local name = trim(el.text):match("^\\(%a+)$")
  if name == "newpage" or name == "pagebreak" or name == "clearpage" then
    local pb = page_break()
    if pb then return pb end
  end
  warn_raw(el.text)
  return {}
end

-- Word count -------------------------------------------------------------------------

local function count_words(blocks)
  local n = 0
  local walker = {
    Div = function(div)
      if div.identifier == "refs" then return {}, false end
    end,
    CodeBlock = function() return {} end,
    Code = function() return {} end,
    Str = function(s)
      if s.text:match("%w") then n = n + 1 end
    end,
  }
  pandoc.Pandoc(blocks):walk(walker)
  return n
end

-- Entry point ----------------------------------------------------------------------------

function Pandoc(doc)
  local meta = doc.meta
  heading_numbering = meta["heading-numbering"] ~= nil
      and pandoc.utils.stringify(meta["heading-numbering"]) ~= "false"
      and pandoc.utils.stringify(meta["heading-numbering"]) ~= ""

  if meta["source-dir"] ~= nil then
    source_dir = pandoc.utils.stringify(meta["source-dir"])
  end

  if meta["build-date"] ~= nil then build_date = pandoc.utils.stringify(meta["build-date"]) end

  collect(doc)

  local filtered = doc:walk({
    RawInline = RawInline,
    RawBlock = RawBlock,
    Image = Image,
    Cite = Cite,
    Figure = Figure,
    Table = Table,
    Para = Para,
  })

  -- `date: auto` in the front matter or config becomes the (reproducible) build date.
  local date = filtered.meta["date"]
  if date ~= nil and pandoc.utils.stringify(date) == "auto" and filtered.meta["build-date"] ~= nil then
    filtered.meta["date"] = filtered.meta["build-date"]
  end

  local wc = filtered.meta["word-count"]
  if wc ~= nil and pandoc.utils.stringify(wc) == "auto" then
    filtered.meta["word-count"] = pandoc.MetaString(tostring(count_words(filtered.blocks)))
  end
  return filtered
end
