# Paperplate

Write in Markdown, get a PDF. Titlepage, table of contents, citations, figures, tables,
equations and cross-references included. Same input, same tools, **same bytes out**.

```
Markdown + .bib + images ──Pandoc (+ Lua filter, citeproc, CSL)──▶ Typst ──▶ PDF
                                       └────────────────────────────────▶ DOCX (for reviewers)
```

No LaTeX, no R, no Docker needed. Code is never run during the build: figures are image
files you create beforehand and commit.

## Quick start

```bash
make setup && source .venv/bin/activate   # installs the pinned toolchain (Python 3.10+)
make pdf                                  # -> output/example-thesis.pdf
```

Then edit `src/input.md` and `src/bibliography.bib`, and set the output name in
`paperplate.yaml`. Use this repository as a GitHub template for each new document.

## Writing

```markdown
# Introduction {#sec:intro}

As shown in @fig:chart and @tbl:profiles, see also @sec:method and @eq:mean.
Cite with keys from your .bib file [@knuth1984, p. 4; @wilkinson2016] or @sandve2013 says...

![Caption text.](figures/chart.png){#fig:chart width=70%}

| A | B |
|---|---|
| 1 | 2 |

: Table caption. {#tbl:profiles}

$$ \bar{x} = \frac{1}{n} \sum x_i $$ {#eq:mean}
```

Labels: `fig:`, `tbl:`, `eq:`, `sec:`. In the PDF, Typst does the numbering and, with
`lang: de`, the wording ("Abbildung 1"). Image paths are relative to `src/`.
`src/input.md` is a complete working example.

## Settings

Three layers, last one wins: **profile** → `paperplate.yaml` → **front matter** of your Markdown file.

| Profile | Title page | Contents | LoF / LoT | New page per chapter |
|---|---|---|---|---|
| `thesis` | yes | yes | yes | yes |
| `report` | yes | yes | no | no |
| `article` | no (title block) | no | no | no |

Build settings (`paperplate.yaml`): `profile`, `input` (file, list or glob such as
`src/chapters/*.md`), `bibliography`, `csl`, `output`, `pdf-standard`, `font-paths`,
`source-dir`, `docx-reference`.

Document content (front matter): `title`, `subtitle`, `author`, `supervisor`, `institution`,
`faculty`, `degree`, `student-id`, `email`, `date` (`auto` = build date), `keywords`,
`abstract`, `acknowledgements`, `lang` (`en`, `de`), `logo`.

Layout toggles: `titlepage`, `title-block`, `declaration`, `toc`, `toc-depth`, `lof`, `lot`,
`show-word-count`, `draft`, `two-sided`, `papersize`, `mainfont`, `monofont`, `fontsize`,
`linestretch`, `justify`, `paragraph-style` (`indent`|`block`), `heading-numbering`,
`chapter-pagebreak`, `running-header`.

**Citation styles:** `csl: apa7 | ieee | chicago-author-date | harvard | mla | nature | din-1505-2`,
or a path to any `.csl` file (see <https://www.zotero.org/styles>).

**Fonts:** only fonts embedded in Typst plus those in `paperplate/fonts/` or your `font-paths`
are used. System fonts are deliberately ignored; that is what makes the output identical on every machine.

**Archival PDF:** `pdf-standard: a-2b` (also `a-1b`, `a-3b`, `a-4`, `ua-1`, …).

## Bibliography with Zotero

1. Install [Better BibTeX](https://retorque.re/zotero-better-bibtex/).
2. Right-click your collection → *Export Collection…* → format *Better BibTeX*, tick **Keep updated**, save as `src/bibliography.bib`.
3. Cite with the key Better BibTeX shows (`@knuth1984`).

Only cited works appear in the reference list. CSL JSON/YAML files also work.

## Figures from code

The build never executes code. Generate images however you like and commit them. If you want a
single command for that, put the recipe in `src/figures/Makefile`; `make figures` runs it.

## DOCX for reviewers

`make docx` produces a Word file from the same source (same cross-reference numbers and
bibliography). Supply `docx-reference: src/reference.docx` to control its styles. SVG figures in
DOCX need `rsvg-convert` (`librsvg2-bin`); otherwise use PNG.

## Reproducibility

- Pinned versions: Pandoc 3.9 and Typst 0.15.0 (`requirements.txt`). `--strict` (used in CI) fails on a version mismatch or any warning.
- Timestamp: `SOURCE_DATE_EPOCH` if set, otherwise the last git commit date. `date: auto` and the PDF metadata use it, so rebuilding an unchanged commit gives identical bytes. Uncommitted edits keep the previous commit's date until you commit.
- `make test` builds four configurations (English thesis, IEEE article, German report, PDF/A + draft), checks the PDFs and verifies that two builds are byte-identical.

## GitHub Actions

`.github/workflows/build.yml` runs tests and a strict build on every push and pull request,
uploads the result as an artifact, and attaches the PDF and DOCX to every published release.

## Layout

```
paperplate.yaml            project settings
src/                       your Markdown, .bib, figures
paperplate/build.py        the build
paperplate/filters/        Lua filter: cross-references, word count, paths
paperplate/templates/      Typst layout (document.typ is the Pandoc template, paperplate.typ the design)
paperplate/profiles/       thesis | report | article defaults
paperplate/csl/            bundled citation styles
tests/                     end-to-end tests
```

The previous LaTeX-based version is preserved on the branch `archive/latex-pandoc-v0`.

## License

MIT, see [LICENSE](LICENSE). Bundled CSL styles are CC BY-SA 3.0, see [THIRD_PARTY.md](THIRD_PARTY.md).
