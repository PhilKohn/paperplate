# Pandoc Thesis Template for Academic Writing

This repository provides a template for compiling academic theses or papers using Pandoc. The primary function is to automate the conversion of Markdown files into professionally formatted PDFs using GitHub Actions.

## Features

- **Markdown to PDF Conversion:** Easily convert your thesis written in Markdown to a PDF.
- **GitHub Actions Automation:** Automatically compile your thesis into a PDF upon pushing changes to the repository.
- **Customizable Templates:** Modify the LaTeX template to suit your formatting needs.

## Repository Structure

- `src/`: Contains the source files including `input.md` (main content), `bibtex.bib` (bibliography), and LaTeX templates.
- `.github/workflows/`: Contains the GitHub Actions workflow file that automates the PDF generation.

## Usage

1. **Edit Markdown Content:**
   - Modify the `src/input.md` file with your thesis content.
   - Update `src/assets/bibtex.bib` for your references.

2. **Automatic PDF Generation:**
   - Push your changes to the repository.
   - The GitHub Actions workflow will automatically compile the Markdown into a PDF using Pandoc.

3. **Download the PDF:**
   - After the workflow completes, download the generated `output.pdf` from the GitHub Actions artifacts.
  
### Markdown Structure Guidelines

To ensure your Markdown file is correctly processed into a professional PDF, follow these guidelines:

1. **YAML Front Matter**:
   - Begin with a YAML block containing metadata like `title`, `author`, `date`, `abstract`, and `acknowledgements`.
   - Use Pandoc-specific settings like `toc` (table of contents), `lof` (list of figures), `lot` (list of tables), and `documentclass` to control the document structure.

2. **Sections and Headings**:
   - Use `#` for top-level sections (e.g., `# Introduction`), `##` for subsections, and so on.
   - Pandoc automatically generates a table of contents, so no need to manually create one.
   - You can reference sections using pandoc-secnos by lableing a section with `{#sec:label}` and then calling that lable inline unsing `@sec:lable`

3. **Figures and Tables**:
   - Embed figures using `![Caption](path/to/image){width=40% #fig:label}`.
   - Reference figures with `@fig:label` in the text.
   - Tables and equations can be similarly referenced using `#tbl:label` and `#eq:label`.

4. **Citations and References**:
   - Use citation keys like `[@authorYear]` to cite sources, with support for multiple and complex citations.
   - Include a bibliography file (e.g., `bibtex.bib`) and set the citation style in the YAML front matter.

5. **Footnotes**:
   - Define footnotes inline with `[^label]`, with definitions at the bottom of the document or section.

6. **Mathematical Equations**:
   - Inline equations are enclosed in `$`, and display equations are enclosed in `$$`.

7. **Bibliography**
   - Bibliography at the end of the paper will be genereated from the `bibtex.bib` file generated from Zotero's Better BibTex extention by including html tag `<div id="refs"></div>`

This structure ensures your Markdown file is compatible with Pandoc’s processing pipeline, resulting in a well-formatted PDF output. For clarification check out `src/template/reference.md`

## Requirements

- No local dependencies are required. The entire process is handled through GitHub Actions.
- Nonetheless, you need some software to write markdown in (ex.: Obsidian, Ulysses, VSCode etc.). Even basic text editors will do the trick.
- I recommend using Zotero and its Better BibTex add on to generete the `.bib` file in `src/assets`
- Also, you should have git installed on your machine and an GitHub account. You can also use the GitHub Desktop app if you don't want to use the terminal. This way you can clone this template to your repository and make push commits to trigger the workflow which will generate the pdf file. 

## Planed Development

- Write a `build.sh` file that will enable users to run everything locally.
- Build a `Dockerfile` on `pandoc/latex:ubuntu-latest` to avoid installing python and all TexLive dependencys within the GitHub Actions process.
- Build more templates.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contributions

Contributions are welcome! Please open an issue or submit a pull request.
