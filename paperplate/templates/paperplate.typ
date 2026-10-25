// paperplate.typ — page layout for all document profiles.
//
// `conf` is called from the generated document (see document.typ). Every option
// can be set in the YAML front matter of your Markdown file or in paperplate.yaml;
// profiles (paperplate/profiles/*.yaml) only provide different defaults.

// ---------------------------------------------------------------------------
// Localised strings (Typst already localises "Figure", "Table", "Contents").
// ---------------------------------------------------------------------------
#let strings = (
  en: (
    abstract: "Abstract",
    acknowledgements: "Acknowledgements",
    declaration: "Declaration of Authorship",
    lof: "List of Figures",
    lot: "List of Tables",
    keywords: "Keywords",
    author: "Author",
    supervisor: "Supervisor",
    supervisors: "Supervisors",
    student-id: "Student ID",
    word-count: "Word count",
    place-date: "Place, date",
    signature: "Signature",
    declaration-text: [I hereby declare that I wrote this work independently, that I did not use any sources or aids other than those indicated, and that all passages taken from other works, literally or in substance, are marked as such.],
  ),
  de: (
    abstract: "Zusammenfassung",
    acknowledgements: "Danksagung",
    declaration: "Eigenständigkeitserklärung",
    lof: "Abbildungsverzeichnis",
    lot: "Tabellenverzeichnis",
    keywords: "Schlüsselwörter",
    author: "Verfasser",
    supervisor: "Betreuer",
    supervisors: "Betreuer",
    student-id: "Matrikelnummer",
    word-count: "Wortanzahl",
    place-date: "Ort, Datum",
    signature: "Unterschrift",
    declaration-text: [Hiermit versichere ich, dass ich die vorliegende Arbeit selbstständig verfasst und keine anderen als die angegebenen Quellen und Hilfsmittel benutzt habe. Alle Stellen, die wörtlich oder sinngemäß aus anderen Werken entnommen sind, habe ich als solche kenntlich gemacht.],
  ),
)

#let group-thousands(value, sep) = {
  let s = str(int(value))
  let parts = ()
  let i = s.len()
  while i > 0 {
    let start = calc.max(0, i - 3)
    parts.push(s.slice(start, i))
    i = start
  }
  parts.rev().join(sep)
}

#let as-array(x) = if x == none { () } else if type(x) == array { x } else { (x,) }

// ---------------------------------------------------------------------------
// The template
// ---------------------------------------------------------------------------
#let conf(
  // --- content ---
  title: none,
  subtitle: none,
  authors: (),
  supervisors: (),
  institution: none,
  faculty: none,
  degree: none,
  student-id: none,
  email: none,
  logo: none,
  titlepage-note: none,
  date: none,
  word-count: none,
  show-word-count: false,
  keywords: (),
  abstract: none,
  abstract-title: none,
  acknowledgements: none,
  declaration-text: none,
  // --- structure toggles ---
  titlepage: true,
  title-block: false, // compact title block on the first page (article style)
  declaration: false,
  toc: true,
  toc-depth: 3,
  lof: false,
  lot: false,
  // --- language and layout ---
  lang: "en",
  region: none,
  paper: "a4",
  margin: auto,
  two-sided: false,
  font: ("Libertinus Serif",),
  heading-font: none,
  mono-font: ("DejaVu Sans Mono",),
  math-font: (),
  fontsize: 11pt,
  linestretch: 1.0,
  justify: true,
  paragraph-style: "block", // "block" (space between) or "indent" (first-line indent)
  heading-numbering: "1.1",
  heading-numbering-depth: 3,
  chapter-pagebreak: true,
  running-header: true,
  link-color: none,
  draft: false,
  draft-label: "DRAFT",
  doc,
) = {
  let t = strings.at(lang, default: strings.en)
  let authors = as-array(authors)
  let supervisors = as-array(supervisors)

  let page-margin = if margin != auto {
    margin
  } else if two-sided {
    (inside: 3cm, outside: 2.5cm, top: 2.5cm, bottom: 2.5cm)
  } else {
    (x: 2.8cm, y: 2.5cm)
  }

  let heading-text-font = if heading-font != none { heading-font } else { font }

  // PDF metadata -----------------------------------------------------------
  set document(
    title: if title != none { title } else { auto },
    author: authors.map(a => if type(a) == str { a } else { a.text }),
  )

  // Text and paragraphs ----------------------------------------------------
  set text(
    font: font,
    size: fontsize,
    lang: lang,
    region: region,
  )
  set par(
    justify: justify,
    leading: 0.65em * linestretch,
    spacing: if paragraph-style == "indent" { 0.65em * linestretch } else { 1.2em * linestretch },
    first-line-indent: if paragraph-style == "indent" { (amount: 1.5em, all: false) } else { 0pt },
  )
  show raw: set text(font: mono-font, size: 0.9em)
  show math.equation: set text(font: if math-font != () { math-font } else { ("New Computer Modern Math",) })
  if link-color != none {
    show link: set text(fill: link-color)
  }

  // Headings ---------------------------------------------------------------
  let numbering-fn = if heading-numbering == none or heading-numbering == false {
    none
  } else {
    (..n) => if n.pos().len() <= heading-numbering-depth { numbering(heading-numbering, ..n) }
  }
  set heading(numbering: numbering-fn)
  show heading: set text(font: heading-text-font, weight: "bold", hyphenate: false)
  show heading.where(level: 1): it => {
    if chapter-pagebreak { pagebreak(weak: true, to: if two-sided { "odd" } else { none }) }
    v(2.5cm * (if chapter-pagebreak { 1 } else { 0 }) / 3 + 0.5em)
    text(size: 1.7em, it)
    v(1em)
  }
  show heading.where(level: 2): it => { v(1.2em, weak: true); text(size: 1.3em, it); v(0.6em, weak: true) }
  show heading.where(level: 3): it => { v(1em, weak: true); text(size: 1.12em, it); v(0.5em, weak: true) }
  show heading.where(level: 4): it => { v(0.8em, weak: true); text(style: "italic", it); v(0.4em, weak: true) }

  // Figures, tables, equations, quotes, notes ---------------------------------
  set figure(gap: 0.9em)
  show figure.caption: set text(size: 0.9em)
  show figure.caption: it => block(width: 100%)[
    #strong[#it.supplement #context it.counter.display(it.numbering)#it.separator]
    #it.body
  ]
  show figure: set block(above: 1.6em, below: 1.6em)
  set table(stroke: none, inset: (x: 6pt, y: 4pt))
  show table: it => block(stroke: (top: 0.8pt, bottom: 0.8pt), inset: (y: 2pt), it)
  show table.cell.where(y: 0): strong
  set math.equation(numbering: "(1)")
  // Only equations that carry a label (via {#eq:name}) are numbered.
  show math.equation.where(block: true): it => {
    if it.has("label") { it } else { math.equation(block: true, numbering: none, it.body) }
  }
  show quote.where(block: true): it => block(
    inset: (left: 1.2em, y: 0.2em),
    stroke: (left: 2pt + luma(70%)),
    it.body,
  )
  set footnote.entry(gap: 0.5em)
  // Bibliography generated by Pandoc (citeproc) sits in a block labelled <refs>.
  show <refs>: set par(hanging-indent: 1.5em, justify: false, spacing: 0.9em)

  // Page: unnumbered title page, roman numerals for front matter ---------------
  let background = if draft {
    place(center + horizon, rotate(-35deg, text(size: 6em, weight: "bold", fill: luma(88%), draft-label)))
  } else { none }

  let inline-front = title-block and not titlepage

  // Running header (chapter title) used in the main matter.
  let main-header = if running-header {
    context {
      let page-no = here().page()
      let chapters = query(heading.where(level: 1, outlined: true))
      let opens-chapter = chapters.any(h => h.location().page() == page-no)
      let before = chapters.filter(h => h.location().page() <= page-no)
      if opens-chapter or before.len() == 0 { none } else {
        let ch = before.last()
        let number = if ch.numbering != none {
          [#numbering(ch.numbering, ..counter(heading).at(ch.location()))#h(1em)]
        } else { none }
        text(size: 0.85em, style: "italic", [#number#ch.body])
        v(-0.5em)
        line(length: 100%, stroke: 0.4pt)
      }
    }
  } else { none }

  set page(
    paper: paper,
    margin: page-margin,
    numbering: if inline-front { "1" } else { none },
    header: if inline-front { main-header } else { none },
    background: background,
  )

  // --- Title page ---
  if titlepage {
    let info(label, body) = [
      #text(size: 0.8em, fill: luma(40%), label) \
      #body
    ]
    let people = authors.map(a => a)
    page(margin: (x: 3cm, y: 2.5cm))[
      #set par(justify: false, first-line-indent: 0pt)
      #align(center)[
        #if logo != none { image(logo, height: 3.2cm) }
        #v(0.6em)
        #if institution != none { text(size: 1.25em, weight: "bold", smallcaps(institution)) }
        #if faculty != none { linebreak(); text(size: 1.05em, faculty) }
      ]
      #v(1fr)
      #align(center)[
        #line(length: 100%, stroke: 0.6pt)
        #v(0.8em)
        #text(size: 2.2em, weight: "bold", font: heading-text-font, title)
        #if subtitle != none { v(0.5em); text(size: 1.3em, style: "italic", subtitle) }
        #v(0.8em)
        #line(length: 100%, stroke: 0.6pt)
      ]
      #v(1fr)
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 1em,
        align(left)[
          #if people.len() > 0 { info(t.author, people.join(linebreak())) }
          #if student-id != none or email != none {
            v(0.4em)
            text(size: 0.85em, [#if student-id != none [#t.student-id: #student-id \ ] #if email != none [#email]])
          }
        ],
        align(right)[
          #if supervisors.len() > 0 {
            info(if supervisors.len() > 1 { t.supervisors } else { t.supervisor }, supervisors.join(linebreak()))
          }
        ],
      )
      #v(1fr)
      #align(center)[
        #if show-word-count and word-count != none {
          text(size: 0.85em)[#t.word-count: #group-thousands(word-count, if lang == "de" { "." } else { "," })]
          parbreak()
        }
        #if titlepage-note != none { titlepage-note; parbreak() }
        #if degree != none { degree; parbreak() }
        #if date != none { date }
      ]
    ]
    counter(page).update(1)
  }

  // --- Title block (article style, no separate title page) ---
  if inline-front {
    align(center)[
      #text(size: 1.8em, weight: "bold", font: heading-text-font, title)
      #if subtitle != none { v(0.3em); text(size: 1.2em, style: "italic", subtitle) }
      #v(0.8em)
      #authors.join([, ])
      #if institution != none { linebreak(); text(size: 0.9em, institution) }
      #if date != none { linebreak(); text(size: 0.9em, date) }
    ]
    v(1em)
    if abstract != none {
      block(width: 100%, inset: (x: 1.5em))[
        #text(weight: "bold", if abstract-title != none { abstract-title } else { t.abstract })
        #parbreak()
        #abstract
        #let kw = as-array(keywords)
        #if kw.len() > 0 [#parbreak() *#t.keywords:* #kw.join(", ")]
      ]
      v(1em)
    }
  }

  // --- Front matter (roman numerals) ---
  show: body => if inline-front { body } else {
    set page(numbering: "i")
    body
  }
  let front-title(body) = heading(level: 1, numbering: none, outlined: false, body)

  if declaration {
    pagebreak(weak: true)
    front-title(t.declaration)
    if declaration-text != none { declaration-text } else { t.declaration-text }
    v(3cm)
    grid(
      columns: (1fr, 1fr), column-gutter: 2cm,
      [#line(length: 100%, stroke: 0.5pt) #text(size: 0.85em, t.place-date)],
      [#line(length: 100%, stroke: 0.5pt) #text(size: 0.85em, t.signature)],
    )
  }
  if abstract != none and not inline-front {
    pagebreak(weak: true)
    front-title(if abstract-title != none { abstract-title } else { t.abstract })
    abstract
    let kw = as-array(keywords)
    if kw.len() > 0 { v(1em); [*#t.keywords:* #kw.join(", ")] }
  }
  if acknowledgements != none {
    if inline-front {
      // Article style: a compact note under the abstract, not a page of its own.
      block(width: 100%, inset: (x: 1.5em))[
        #text(weight: "bold", t.acknowledgements)
        #parbreak()
        #acknowledgements
      ]
      v(1em)
    } else {
      pagebreak(weak: true)
      front-title(t.acknowledgements)
      acknowledgements
    }
  }
  if toc {
    pagebreak(weak: true)
    outline(title: auto, depth: toc-depth)
  }
  if lof {
    pagebreak(weak: true)
    outline(title: t.lof, target: figure.where(kind: image))
  }
  if lot {
    pagebreak(weak: true)
    outline(title: t.lot, target: figure.where(kind: table))
  }

  // --- Main matter (arabic numerals) ---
  // A `set page` rule placed after content forces a page break, so an article-style
  // document (title block on the first page) must not emit one here: it already has
  // the arabic numbering and the running header from the start.
  show: body => if inline-front { body } else {
    set page(numbering: "1", header: main-header)
    body
  }
  if not inline-front {
    pagebreak(weak: true)
    counter(page).update(1)
  }

  doc
}
