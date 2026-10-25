# Third-party material

| Component | Where | License |
|---|---|---|
| Citation Style Language styles (apa7, ieee, chicago-author-date, harvard, mla, nature, din-1505-2) | `paperplate/csl/` | CC BY-SA 3.0, from <https://github.com/citation-style-language/styles>. Each file names its authors and license in its `<info>` block. |
| Typst (via `typst-py`) and its embedded fonts (Libertinus Serif, New Computer Modern, DejaVu Sans Mono) | installed with `pip` | Apache-2.0 (Typst); SIL OFL 1.1 (fonts) |
| Pandoc (via `pypandoc_binary`) | installed with `pip` | GPL-2.0-or-later. It is run as a separate program and not redistributed by this repository. |

The CSL files are the only third-party files committed here. They keep their own license
(CC BY-SA 3.0); the MIT license of this repository does not apply to them. Documents you
build with them are not affected.
