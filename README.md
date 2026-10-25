# Paperplate

**Write your thesis, report or paper in a plain text file. Get a finished PDF.**

You type in a simple text format (Markdown). Paperplate turns it into a PDF with a title page,
table of contents, numbered figures and tables, citations, a reference list and
cross-references like "see Figure 2". You never fiddle with layout. Same input in, same PDF out.

```
your text + your sources + your images  ──▶  PDF   (and a Word file for reviewers)
```

No LaTeX, no R, no Docker. It does not run your code: you create your charts and images first,
and Paperplate just places them.

**Contents:** [Is this for me?](#is-this-for-me) · [Install](#install) · [Your first PDF](#your-first-pdf) ·
[Writing](#writing) · [Sources and citations](#sources-and-citations) · [Settings and recipes](#settings-and-recipes) ·
[Word version](#word-version-for-reviewers) · [Releases](#publishing-a-release) · [No install](#no-install-option-github-only) ·
[Troubleshooting](#troubleshooting) · [Glossary](#glossary) · [For tinkerers](#for-tinkerers)

---

## Is this for me?

**Good fit:** theses, reports, papers, memos. Anything text-heavy with references, figures
and tables, where you want clean consistent layout and a history of every change.

**Not a fit:** pixel-perfect designed brochures, documents that must be written collaboratively in
Word, or work where you must use a university's own LaTeX or Word template.

| Paperplate does | Paperplate does not |
|---|---|
| Title page, contents, lists of figures and tables | Run your code or create your charts |
| Citations and reference list in many styles (APA, IEEE, …) | Fetch sources by itself (you give it a `.bib` file, see below) |
| Numbered figures, tables, equations and links between them | Support your university's custom template out of the box |
| English and German wording, A4 or US Letter | Live preview while typing (you rebuild with one command) |
| Word file for reviewers, archival PDF/A | Track changes in Word (review in Word, then copy edits back into your text) |

---

## Install

You do this **once per computer**. It takes about 10 minutes. Pick your system.

You will use the **terminal**: a window where you type commands. Copy a block, paste it, press Enter.
Lines starting with `#` are comments; you can paste them too.

### Mac

1. Open **Terminal** (press `Cmd + Space`, type `Terminal`, press Enter).
2. Install Apple's developer tools (gives you `git`, `make` and Python). A pop-up appears; click *Install* and wait until it finishes:

```bash
xcode-select --install
```

3. Get the project, set it up and build the example PDF. Replace `YOUR-NAME/YOUR-REPO` with your repository (see [Get the project](#get-the-project) below):

```bash
cd ~/Documents
git clone https://github.com/YOUR-NAME/YOUR-REPO.git thesis
cd thesis
make setup
make pdf
open output/*.pdf
```

Next time you only need `cd ~/Documents/thesis` and then `make pdf`.

### Windows

1. Install **Python** and **Git**. Open **PowerShell** (Start menu, type `PowerShell`) and run:

```powershell
winget install Python.Python.3.12
winget install Git.Git
```

   Then **close PowerShell and open it again** so it finds the new programs.
   (No `winget`? Install Python from <https://www.python.org/downloads/> and tick *"Add python.exe to PATH"*, and Git from <https://git-scm.com/download/win>.)

2. Get the project, set it up and build the example PDF. Replace `YOUR-NAME/YOUR-REPO` (see [Get the project](#get-the-project)):

```powershell
cd $HOME\Documents
git clone https://github.com/YOUR-NAME/YOUR-REPO.git thesis
cd thesis
py -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python paperplate\build.py pdf
start output\example-thesis.pdf
```

Next time: open PowerShell, `cd $HOME\Documents\thesis`, then `.venv\Scripts\python paperplate\build.py pdf`.
Windows has no `make`, so on Windows always use these `.venv\Scripts\python paperplate\build.py …` commands.

> The commands were tested on Linux, with Python 3.9, 3.10, 3.11 and 3.13. The Mac and Windows
> commands are the same steps, but could not be tried on a real Mac or Windows machine. If a step
> fails, see [Troubleshooting](#troubleshooting).

### Linux

Debian / Ubuntu:

```bash
sudo apt update && sudo apt install -y git make python3 python3-venv
```

Fedora:

```bash
sudo dnf install -y git make python3
```

Then:

```bash
cd ~/Documents
git clone https://github.com/YOUR-NAME/YOUR-REPO.git thesis
cd thesis
make setup
make pdf
xdg-open output/*.pdf
```

### Get the project

Do this once for **each** document you write (each thesis gets its own copy):

1. Open the Paperplate page on GitHub: <https://github.com/PhilKohn/paperplate>
2. Click the green **Use this template** button, then **Create a new repository**.
3. Give it a name (for example `thesis-computer-science`), choose **Private** if you want, click **Create repository**.
4. On your new repository's page, click **Code** and copy the web address. That is the address to use after `git clone` above.

No GitHub account, or no git? On the Paperplate page click **Code → Download ZIP**, unzip it, and open a terminal in that folder instead of running `git clone`. It works the same, but you lose the change history.

### Which Python?

Python 3.9 or newer. Tested with 3.9, 3.10, 3.11 and 3.13. Check yours with `python3 --version` (Mac/Linux) or `py --version` (Windows).

---

## Your first PDF

After the install above you already built one. Open `output/example-thesis.pdf`. It is a small
thesis that explains itself, and it was made from the file `src/input.md`. Open that file in any
text editor (TextEdit, Notepad, VS Code …) next to the PDF to see how the text maps to the result.

Now make it yours:

1. Open `src/input.md`. At the very top, between the two `---` lines, change the title, your name, institution and so on.
2. Delete the example text below the second `---` and write your own.
3. Rebuild:

| | Command |
|---|---|
| Mac / Linux | `make pdf` |
| Windows | `.venv\Scripts\python paperplate\build.py pdf` |

4. Open the new PDF in the `output/` folder. Repeat.

The PDF's file name is set in `paperplate.yaml` (the line `output:`). Change it to something like
`output/my-thesis.pdf`.

---

## Writing

Everything is in `src/input.md`, in **Markdown**: plain text with a few simple marks.

```markdown
# A chapter heading
## A section heading
### A subsection heading

Normal text. *Italic*, **bold**, `code-style text`.

- A bullet
- Another bullet

1. A numbered step
2. Another step

> A quotation.

Text with a footnote.[^1]

[^1]: This is the footnote text.
```

Headings are numbered automatically (1, 1.1, 1.1.1). For an unnumbered heading (an appendix, say) write `# Appendix {.unnumbered}`.

### Figures, tables, equations and cross-references

Put image files (PNG, JPG or SVG) into `src/figures/`. Then:

```markdown
![The caption goes here.](figures/chart.png){#fig:chart width=70%}

| Name  | Value |
|:------|------:|
| Alpha |     1 |
| Beta  |     2 |

: The caption of the table. {#tbl:values}

$$ \bar{x} = \frac{1}{n} \sum_{i=1}^{n} x_i $$ {#eq:mean}
```

The part in curly braces `{#fig:chart}` is a **label**. Refer to it anywhere in the text, and Paperplate
writes "Figure 1", with the right number and a clickable link:

```markdown
As @fig:chart shows, ... see @tbl:values and @eq:mean.
```

Labels start with `fig:`, `tbl:`, `eq:` or `sec:` (for headings: `# Method {#sec:method}`, then `@sec:method`).
Image paths are written relative to the `src/` folder.

**Charts from code (R, Python, Excel …):** create them yourself, save as PNG or SVG, put them in `src/figures/`.
Paperplate never runs your code, so even a 3-hour analysis does not slow it down.

### Several files

Long thesis? One file per chapter. In `paperplate.yaml` set:

```yaml
input: src/chapters/*.md      # all matching files, in alphabetical order: 01-intro.md, 02-method.md, …
```

Put the title, author and abstract (the "front matter" between `---` lines) in the **first** file only.

---

## Sources and citations

You cite a source by its **key** (a short ID like `knuth1984`). The details of every source live in
one file, `src/bibliography.bib`.

```markdown
Reproducible research is important [@knuth1984].
With a page: [@sandve2013, p. 4]. Several: [@knuth1984; @wilkinson2016].
In the sentence: @wilkinson2016 argue that ...
```

Paperplate builds the reference list at the end by itself, and **only with the sources you actually cited**.

### Getting the `.bib` file from Zotero (recommended)

1. Install [Zotero](https://www.zotero.org) and its plugin [Better BibTeX](https://retorque.re/zotero-better-bibtex/).
2. Right-click your collection → **Export Collection…** → format **Better BibTeX** → tick **Keep updated** → save it as `src/bibliography.bib` inside your project.
3. Every source in Zotero now has a key, shown in Zotero (or look in the `.bib` file: the word after `@article{`). Use it after an `@` in your text.

No Zotero? You can write entries by hand in `src/bibliography.bib`:

```bibtex
@book{smith2020,
  author    = {Smith, Jane},
  title     = {A Book Title},
  publisher = {Example Press},
  year      = {2020}
}
```

### Citation style

In `paperplate.yaml`, the line `csl:` chooses the style:

`apa7` · `ieee` · `chicago-author-date` · `harvard` · `mla` · `nature` · `din-1505-2`

Need another one? Download any `.csl` file from <https://www.zotero.org/styles>, put it in `src/`,
and write `csl: src/that-file.csl`.

---

## Settings and recipes

There are three places for settings. Later ones win over earlier ones:

1. A **profile**: the starting point (`thesis`, `report` or `article`).
2. **`paperplate.yaml`**: settings for the whole project.
3. The **top of `src/input.md`**: the document's own details (title, author, abstract).

| Profile | Title page | Contents | Lists of figures/tables | Each chapter on a new page |
|---|---|---|---|---|
| `thesis` | yes | yes | yes | yes |
| `report` | yes | yes | no | no |
| `article` | no (title block only) | no | no | no |

### Copy-paste recipes

Add these lines to `paperplate.yaml` (remove the `#` at the start of a line to turn it on).

```yaml
profile: article            # thesis | report | article
csl: ieee                   # citation style (see list above)
lang: de                    # German wording: Inhaltsverzeichnis, Abbildung, Tabelle …
papersize: us-letter        # default is a4
declaration: true           # adds a declaration-of-authorship page
titlepage: false            # no title page
toc: false                  # no table of contents
lof: false                  # no list of figures
lot: false                  # no list of tables
draft: true                 # diagonal DRAFT watermark
two-sided: true             # mirrored margins for printing on both sides
fontsize: 12pt
linestretch: 1.5            # line spacing
mainfont: [New Computer Modern]    # body font (built in: Libertinus Serif, New Computer Modern)
headingfont: [DejaVu Sans Mono]    # heading font
pdf-standard: a-2b          # archival PDF/A, which many universities and libraries require
```

**Japanese, Chinese, Korean:** no CJK font is built in, so add one yourself (for example Noto Serif CJK from <https://fonts.google.com/noto>), put the font files in `src/fonts/`, and set `font-paths: [src/fonts]` and `mainfont: [Noto Serif CJK JP]`. Line breaking and mixed Japanese/English text work. Labels such as "Contents" stay English or German for these languages.

**Your own font:** put the `.ttf` or `.otf` file into a folder such as `src/fonts/`, then write
`font-paths: [src/fonts]` and `mainfont: [The Font Family Name]`. Only built-in fonts and the fonts in
those folders are used, never fonts installed on your computer. That is what makes the PDF look the
same on every computer.

**Title page content** (top of `src/input.md`, between the `---` lines):

```yaml
title: "My Thesis"
subtitle: "A subtitle"
author: "Your Name"
supervisor: ["Prof. Jane Doe", "Dr. John Roe"]
institution: "Example University"
faculty: "Faculty of Examples"
degree: "Master of Science"
student-id: "123456"
email: "you@example.org"
date: auto                  # auto = date of your last commit; or write "1 June 2027"
keywords: [one, two, three]
abstract: |
  Your abstract here.
acknowledgements: |
  Thanks to …
logo: src/figures/logo.png  # optional logo on the title page
```

Leave a line out and that element disappears from the title page.

---

## Word version for reviewers

Your supervisor wants Word? Build a `.docx` from the same text. Cross-references, citations and the reference list are included.

| | Command |
|---|---|
| Mac / Linux | `make docx` |
| Windows | `.venv\Scripts\python paperplate\build.py docx` |

The file lands in `output/`. The layout is simpler than the PDF. Send it for comments, then apply
the changes in `src/input.md` yourself and rebuild. Do not keep editing the Word file; the text
file is the master copy.

---

## Publishing a release

A **release** is a labelled, permanent snapshot of your work (for example "v1.0 submitted version").
GitHub builds the PDF and Word file for you and attaches them to it. You can do this from your browser:

1. Save your work to GitHub (see below, "Saving your work").
2. On your repository's page, click **Releases → Draft a new release**.
3. In *Choose a tag*, type a name such as `v1.0` and choose *Create new tag*. Give the release a title.
4. Click **Publish release**.
5. Wait about two minutes and reload the page. Under **Assets** you will find the PDF and the Word file.

You do **not** need a release to get a PDF. `make pdf` on your own computer is enough. A release is for the version you hand in.

### Saving your work

Do this regularly; it keeps the full history of every change and a backup on GitHub:

```bash
git add -A
git commit -m "Write chapter 2"
git push
```

(Same commands on Mac, Windows and Linux. Replace the text in quotes with a short note on what you did.)

---

## No-install option (GitHub only)

If you cannot or do not want to install anything: edit directly on GitHub.

1. Create your repository from the template (see [Get the project](#get-the-project)).
2. Open `src/input.md`, click the pencil icon, edit, click **Commit changes**.
3. Click the **Actions** tab. The latest run builds your PDF (about two minutes).
4. Open that run, scroll to **Artifacts**, download **document**. It is a ZIP file with the PDF and Word file inside.

Slower than building locally, but it needs nothing but a browser. Images and the `.bib` file can be uploaded through **Add file → Upload files**.

---

## Troubleshooting

Almost every problem is shown in the last lines the terminal printed. If you are stuck, copy those lines into a chat with Claude or an issue on GitHub.

| What you see | What to do |
|---|---|
| `make: command not found` (Mac) | Run `xcode-select --install`. |
| `make` does not exist (Windows) | Normal. Use the `.venv\Scripts\python paperplate\build.py pdf` commands. |
| `python3: command not found` or `'py' is not recognized` | Python is not installed, or the terminal was opened before installing it. Install it (see [Install](#install)), then close and reopen the terminal. |
| `The setup step is missing` | You skipped `make setup` (or the Windows `py -m venv …` lines). Run them once in the project folder. |
| `no input files match 'src/input.md'` | You are not in the project folder. Use `cd` to go into it (`cd ~/Documents/thesis`). Or the file was renamed: check `input:` in `paperplate.yaml`. |
| `these citation keys are not in your bibliography file: …` | The key in your text is misspelled or missing from `src/bibliography.bib`. Compare it letter by letter. |
| `Typst failed … file not found` | An image path is wrong. Paths are relative to `src/`: `figures/chart.png` means the file `src/figures/chart.png`. Capital letters count. |
| The PDF does not change | You edited another file than the one in `paperplate.yaml` (`input:`), or you did not rebuild, or your PDF viewer shows the old file. Close and reopen the PDF. |
| The date on the title page is old | `date: auto` uses the date of your last *commit*. Commit, or write the date yourself: `date: "1 June 2027"`. |
| `warning: pandoc … found, but paperplate is tested with …` | Your tool versions differ from the tested ones. Run the install commands again. |
| `note: no git history found …` | Harmless. It appears if you downloaded a ZIP instead of using git. |
| `raw LaTeX is not supported and was left out: …` | Your text contains LaTeX commands (for example `\textbf{…}`), which Paperplate does not run. Use Markdown instead (`**bold**`). Only `\verb|…|`, `\newpage` and `\today` are translated. |
| `unknown font family` | Only built-in fonts and fonts in `font-paths` work. See [Settings](#settings-and-recipes). |
| Windows: `running scripts is disabled` | You used `.venv\Scripts\Activate.ps1`. You do not need it; use `.venv\Scripts\python …` as shown. |

For a stricter check (turns every warning into an error, like the automatic build does), add `--strict` to the build command, or run `make strict` on Mac/Linux.

---

## Glossary

- **Terminal / PowerShell:** the window where you type commands.
- **Markdown:** a way to write formatted text in a plain text file (`#` for headings, `*` for italics).
- **Repository ("repo"):** a project folder whose history is tracked and backed up on GitHub.
- **Commit:** a saved snapshot of your files with a short note. **Push** uploads commits to GitHub.
- **Template:** a repository you copy to start your own.
- **Release:** a labelled snapshot on GitHub, with the PDF attached.
- **BibTeX / `.bib`:** a text file listing your sources. Zotero can create it for you.
- **Citation key:** the short ID of a source, such as `knuth1984`.
- **CSL:** a file that defines a citation style (APA, IEEE …).
- **Front matter:** the settings block between the two `---` lines at the top of your Markdown file.
- **Profile:** a bundle of default settings (`thesis`, `report`, `article`).

---

## For tinkerers

```
paperplate.yaml            project settings
src/                       your Markdown, .bib file and figures
paperplate/build.py        the build: Markdown → Pandoc → Typst → PDF
paperplate/filters/        Lua filter: cross-references, word count, image paths
paperplate/templates/      document.typ (Pandoc template) and paperplate.typ (the layout)
paperplate/profiles/       thesis | report | article defaults
paperplate/csl/            bundled citation styles
tests/                     end-to-end tests (make test)
```

- **Pinned tools:** Pandoc 3.9 and Typst 0.15.0, installed by `pip` from `requirements.txt`. No separate install of Pandoc is needed.
- **Deterministic:** the build timestamp is `SOURCE_DATE_EPOCH` if set, otherwise the last git commit date. Only built-in or project fonts are used. Rebuilding the same commit gives byte-identical PDFs; `make test` checks this, in four configurations plus the Word output.
- **Automatic builds:** `.github/workflows/build.yml` runs tests and a strict build on every push and pull request, uploads the result as an artifact, and attaches the PDF and Word file to every published release.
- **Other commands:** `make strict` (fail on any warning), `make typ` (write `build/document.typ` for debugging), `make versions`, `make test`, `make figures` (runs `src/figures/Makefile` if you have one), `make clean`.
- **The earlier LaTeX-based version** is preserved on the branch `archive/latex-pandoc-v0`.

## License

MIT, see [LICENSE](LICENSE). The bundled citation styles are CC BY-SA 3.0, see [THIRD_PARTY.md](THIRD_PARTY.md).
