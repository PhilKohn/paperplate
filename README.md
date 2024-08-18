# About

This repository will serve as a basis for automatically compiling academic writing done in markdown format. 

# Structure

```
.
├── output
    ├── output.pdf
    ├── output.tex
├── src
    ├── bibtex.bib
    ├── input.md
    └── template
        ├── template.tex
    ├── assets
        ├── plot.jpg
└── build.sh
```

## Summary of the Folder Structure

- docker/: Contains the Docker setup, including the Dockerfile and a script to build or run the Docker image.
- output/: Stores the final output files, such as PDFs and LaTeX documents generated from the source files.
- src/: Contains the source files, including the main markdown file, a bibliography file, a LaTeX template, and any assets like images.
- Root-level build.sh: A script likely designed to automate the process of generating the final documents, possibly by invoking Docker commands or running other scripts.

This structure is typical for projects that involve document generation workflows, where Docker is used to ensure a consistent environment, and scripts are employed to automate the process.
