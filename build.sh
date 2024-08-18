#!/bin/sh

docker run --rm \
       --volume "$(pwd):/data" \
       --user $(id -u):$(id -g) \
       pandoc/core --filter pandoc-crossref --filter pandoc-citeproc \
       -M cref=true \
       --bibliography src/bibtex.bib --biblatex \
       --top-level-division=chapter \
       README.md -o output/output.pdf
