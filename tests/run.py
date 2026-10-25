#!/usr/bin/env python3
"""End-to-end tests: build several configurations and check the PDFs.

    python3 tests/run.py

Every configuration in tests/configs/ is built with --strict (any warning fails).
The default configuration is built twice and the two PDFs must be byte-identical.
"""
from __future__ import annotations

import hashlib
import os
import subprocess
import sys
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "paperplate" / "build.py"
FIXED_EPOCH = "1761393600"  # 2025-10-25T12:00:00Z; the tests must not depend on the clock

failures: list[str] = []


def build(config: str, command: str = "pdf") -> subprocess.CompletedProcess:
    env = dict(os.environ, SOURCE_DATE_EPOCH=FIXED_EPOCH)
    return subprocess.run(
        [sys.executable, str(BUILD), command, "--strict", "--config", str(ROOT / "tests" / "configs" / config)],
        cwd=ROOT, env=env, capture_output=True, text=True,
    )


def pdf_text(path: Path) -> str:
    text = "\n".join((page.extract_text() or "") for page in PdfReader(str(path)).pages)
    return text.replace("\u00a0", " ")  # Typst uses no-break spaces ("Figure 1")


def check(name: str, condition: bool, detail: str = "") -> None:
    status = "ok  " if condition else "FAIL"
    print(f"  {status} {name}")
    if not condition:
        failures.append(f"{name} {detail}".strip())


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def case(config: str, out: str, must_contain: list[str], must_not_contain: list[str] = (),
         min_pages: int = 1, raw_contains: list[bytes] = ()) -> Path:
    print(f"\n[{config}]")
    result = build(config)
    check("build succeeds with --strict", result.returncode == 0, result.stderr.strip()[-600:])
    pdf = ROOT / out
    if result.returncode != 0 or not pdf.exists():
        return pdf
    text = pdf_text(pdf)
    check(f"at least {min_pages} pages", len(PdfReader(str(pdf)).pages) >= min_pages)
    for needle in must_contain:
        check(f"contains {needle!r}", needle in text)
    for needle in must_not_contain:
        check(f"does not contain {needle!r}", needle not in text)
    data = pdf.read_bytes()
    for needle in raw_contains:
        check(f"PDF bytes contain {needle!r}", needle in data)
    return pdf


def main() -> int:
    # --- default thesis in English, APA ---------------------------------------------
    first = case(
        "default.yaml", "build/test/default.pdf",
        must_contain=["Paperplate Example Thesis", "Contents", "List of Figures", "List of Tables",
                      "Figure 1", "Table 1", "Equation 1", "Knuth, D. E. (1984)",
                      "Sandve, G. K.", "References", "Word count: 4"],
        must_not_contain=["fig:", "tbl:", "eq:", "sec:"],
        min_pages=8,
    )

    # --- determinism: same inputs, same bytes ----------------------------------------
    print("\n[determinism]")
    if first.exists():
        digest_a = sha256(first)
        first.unlink()
        result = build("default.yaml")
        check("second build succeeds", result.returncode == 0, result.stderr.strip()[-400:])
        check("two builds are byte-identical", first.exists() and sha256(first) == digest_a)

    # --- article profile with a numeric citation style ----------------------------------
    case(
        "article-ieee.yaml", "build/test/article-ieee.pdf",
        must_contain=["Paperplate Example Thesis", "Abstract", "[1]", "Figure 1", "Equation 1"],
        must_not_contain=["List of Tables", "List of Figures"],
    )

    # --- German report with declaration of authorship -----------------------------------
    case(
        "report-de.yaml", "build/test/report-de.pdf",
        must_contain=["Beispielarbeit auf Deutsch", "Inhaltsverzeichnis", "Abbildungsverzeichnis",
                      "Tabellenverzeichnis", "Eigenständigkeitserklärung", "Abbildung 1",
                      "Tabelle 1", "Zusammenfassung", "Umlauten: Übung, Größe, Straße"],
    )

    # --- archival PDF/A, draft watermark, two-sided margins --------------------------------
    case(
        "pdfa-draft.yaml", "build/test/pdfa-draft.pdf",
        must_contain=["DRAFT", "Paperplate Example Thesis"],
        raw_contains=[b"pdfaid:part"],
    )

    # --- e-mail on the title page is the only '@' ------------------------------------------
    print("\n[title page]")
    default_pdf = ROOT / "build/test/default.pdf"
    if default_pdf.exists():
        check("exactly one '@' (the e-mail address)", pdf_text(default_pdf).count("@") == 1)

    # --- DOCX output keeps references, citations and images ---------------------------------
    print("\n[docx]")
    result = build("default.yaml", "docx")
    check("docx build succeeds", result.returncode == 0, result.stderr.strip()[-400:])
    docx = ROOT / "build/test/default.docx"
    if docx.exists():
        import re
        import zipfile
        with zipfile.ZipFile(docx) as z:
            xml = z.read("word/document.xml").decode("utf-8")
            media = [n for n in z.namelist() if n.startswith("word/media/")]
        text = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", xml))
        for needle in ("Figure 1", "Table 1", "Knuth, D. E. (1984)"):
            check(f"docx contains {needle!r}", needle in text)
        check("docx has no raw labels", not any(x in text for x in ("fig:", "tbl:", "eq:", "sec:")))
        check("docx embeds the figures", len(media) >= 1)

    print()
    if failures:
        print(f"{len(failures)} check(s) failed:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
