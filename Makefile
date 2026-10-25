# Paperplate. Run `make help`.
PY      ?= python3
VENV    ?= .venv
BUILD   := $(PY) paperplate/build.py

.PHONY: help setup pdf docx typ strict figures test versions clean

help:
	@echo "make setup     create .venv and install the pinned toolchain"
	@echo "make pdf       build the PDF (output path: see paperplate.yaml)"
	@echo "make strict    like pdf, but fail on any warning or tool-version mismatch"
	@echo "make docx      build a Word version for reviewers"
	@echo "make typ       write build/document.typ only (debugging)"
	@echo "make figures   run src/figures/Makefile, if you have one (optional)"
	@echo "make test      build the test configurations and check the PDFs"
	@echo "make versions  print the toolchain versions"
	@echo "make clean     remove build/ and output/"

setup:
	$(PY) -m venv $(VENV)
	$(VENV)/bin/pip install -r requirements.txt
	@echo "Now use:  source $(VENV)/bin/activate"

pdf:
	$(BUILD) pdf

strict:
	$(BUILD) pdf --strict

docx:
	$(BUILD) docx

typ:
	$(BUILD) typ

versions:
	$(BUILD) versions

# Figures are never produced by the build. If you generate them from code, put the
# recipe in src/figures/Makefile and run it yourself; commit the resulting images.
figures:
	@if [ -f src/figures/Makefile ]; then $(MAKE) -C src/figures; \
	else echo "No src/figures/Makefile: figures are plain image files you commit."; fi

test:
	$(PY) tests/run.py

clean:
	rm -rf build output
