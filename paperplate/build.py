#!/usr/bin/env python3
"""paperplate build: Markdown -> Pandoc -> Typst -> PDF (or DOCX).

Usage:
    python3 paperplate/build.py pdf            # build the PDF
    python3 paperplate/build.py docx           # build a Word version of the same source
    python3 paperplate/build.py typ            # only write build/document.typ (debugging)
    python3 paperplate/build.py versions       # print the toolchain versions
    python3 paperplate/build.py pdf --strict   # fail on any warning (use this in CI)

The build is a pure function of: your Markdown, bibliography, figures, the
paperplate/ directory, the pinned tool versions and the build timestamp. The
timestamp is SOURCE_DATE_EPOCH if set, else the date of the last git commit.
"""
from __future__ import annotations

import argparse
import copy
import datetime as dt
import glob
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

if sys.version_info < (3, 9):
    sys.exit(f"Paperplate needs Python 3.9 or newer; this is {sys.version.split()[0]}. "
             "See 'Install' in the README.")

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("The setup step is missing. Run the 'Install' commands from the README "
             "(on Mac/Linux: make setup), then try again.")

PKG = Path(__file__).resolve().parent            # .../paperplate
ROOT = PKG.parent                                # project root

# Versions this release of paperplate is tested with (also pinned in requirements.txt).
EXPECTED = {"pandoc": "3.9", "typst": "0.15.0"}

MONTHS = {
    "en": ["January", "February", "March", "April", "May", "June", "July",
           "August", "September", "October", "November", "December"],
    "de": ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
           "August", "September", "Oktober", "November", "Dezember"],
}

# Keys that steer the build and are not passed on as document metadata.
BUILD_KEYS = {"input", "output", "profile", "bibliography", "csl", "csl-dir",
              "pdf-standard", "font-paths", "source-dir", "docx-reference"}


class BuildError(Exception):
    pass


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
def find_pandoc() -> str:
    if os.environ.get("PANDOC"):
        return os.environ["PANDOC"]
    try:
        import pypandoc  # bundled binary, pinned in requirements.txt
        return pypandoc.get_pandoc_path()
    except Exception:
        pass
    found = shutil.which("pandoc")
    if found:
        return found
    raise BuildError("Pandoc not found. Run the 'Install' commands from the README (make setup).")


def tool_versions(pandoc: str) -> dict:
    out = subprocess.run([pandoc, "--version"], capture_output=True, text=True).stdout
    pandoc_version = out.split()[1] if out else "unknown"
    try:
        import typst
        typst_version = getattr(typst, "__version__", None)
        if typst_version is None:
            from importlib.metadata import version
            typst_version = version("typst")
    except ImportError:
        raise BuildError("typst is missing. Run the 'Install' commands from the README (make setup).")
    return {"pandoc": pandoc_version, "typst": typst_version}


def check_versions(versions: dict, strict: bool) -> None:
    for tool, wanted in EXPECTED.items():
        if versions[tool] != wanted:
            msg = f"{tool} {versions[tool]} found, but paperplate is tested with {wanted}"
            if strict:
                raise BuildError(msg)
            print(f"warning: {msg}", file=sys.stderr)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
def load_yaml(path: Path) -> dict:
    with open(path, encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    if not isinstance(data, dict):
        raise BuildError(f"{path} must contain a YAML mapping")
    return data


def load_config(config_path: Path) -> dict:
    project = load_yaml(config_path) if config_path.exists() else {}
    profile_name = project.get("profile", "thesis")
    profile_file = PKG / "profiles" / f"{profile_name}.yaml"
    if not profile_file.exists():
        available = ", ".join(sorted(p.stem for p in (PKG / "profiles").glob("*.yaml")))
        raise BuildError(f"unknown profile '{profile_name}' (available: {available})")
    merged = load_yaml(profile_file)
    merged.update(project)
    merged["profile"] = profile_name
    return merged


def resolve_inputs(config: dict) -> list[Path]:
    patterns = config.get("input", "src/input.md")
    if isinstance(patterns, str):
        patterns = [patterns]
    files: list[Path] = []
    for pattern in patterns:
        matches = sorted(glob.glob(str(ROOT / pattern)))
        if not matches:
            raise BuildError(f"no input files match '{pattern}'")
        files.extend(Path(m) for m in matches)
    return files


def resolve_csl(config: dict) -> Path | None:
    name = config.get("csl")
    if not name:
        return None
    candidate = ROOT / name
    if str(name).endswith(".csl") or "/" in str(name):
        if not candidate.exists():
            raise BuildError(f"CSL file not found: {name}")
        return candidate
    bundled = PKG / "csl" / f"{name}.csl"
    if bundled.exists():
        return bundled
    available = ", ".join(sorted(p.stem for p in (PKG / "csl").glob("*.csl")))
    raise BuildError(f"unknown citation style '{name}' (bundled: {available}; or give a path to a .csl file)")


def build_timestamp() -> dt.datetime:
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch:
        return dt.datetime.fromtimestamp(int(epoch), tz=dt.timezone.utc)
    try:
        out = subprocess.run(["git", "log", "-1", "--format=%ct"], cwd=ROOT,
                             capture_output=True, text=True, check=True).stdout.strip()
        if out:
            return dt.datetime.fromtimestamp(int(out), tz=dt.timezone.utc)
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    print("note: no git history found, so today's date and time are used. The text is the same "
          "on every build, but the PDF file differs slightly each time. (To get identical files, "
          "keep the project in git and commit, or set SOURCE_DATE_EPOCH.)", file=sys.stderr)
    return dt.datetime.now(tz=dt.timezone.utc).replace(microsecond=0)


def format_date(ts: dt.datetime, lang: str) -> str:
    code = str(lang).split("-")[0].lower()
    months = MONTHS.get(code)
    if months is None:
        return ts.date().isoformat()
    if code == "de":
        return f"{ts.day}. {months[ts.month - 1]} {ts.year}"
    return f"{ts.day} {months[ts.month - 1]} {ts.year}"


def typst_path(value: str) -> str:
    """Project-relative path -> root-absolute path understood by Typst."""
    p = str(value).replace("\\", "/")
    return p if p.startswith("/") else "/" + p


def document_metadata(config: dict, ts: dt.datetime) -> dict:
    meta = {k: copy.deepcopy(v) for k, v in config.items() if k not in BUILD_KEYS}
    meta["lang"] = meta.get("lang", "en")
    # `date: auto` is resolved by the Lua filter, so it also works in the front matter.
    meta["build-date"] = format_date(ts, meta["lang"])
    if meta.get("logo"):
        meta["logo"] = typst_path(meta["logo"])
    meta["source-dir"] = str(config.get("source-dir", "src")).strip("/")
    meta["paperplate-lib"] = typst_path(
        (PKG / "templates" / "paperplate.typ").relative_to(ROOT).as_posix())
    return meta


# ---------------------------------------------------------------------------
# Build steps
# ---------------------------------------------------------------------------
def run_pandoc(pandoc: str, config: dict, meta: dict, target: str, out_file: Path) -> str:
    build_dir = ROOT / "build"
    build_dir.mkdir(exist_ok=True)
    meta_file = build_dir / "metadata.json"
    meta_file.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

    cmd = [pandoc, *[str(p) for p in resolve_inputs(config)],
           "--from", "markdown", "--to", target, "--standalone", "--wrap=none",
           "--metadata-file", str(meta_file),
           "--lua-filter", str(PKG / "filters" / "paperplate.lua")]

    bibliographies = config.get("bibliography") or []
    if isinstance(bibliographies, str):
        bibliographies = [bibliographies]
    for bib in bibliographies:
        if not (ROOT / bib).exists():
            raise BuildError(f"bibliography file not found: {bib}")
    if bibliographies:
        # Must come after the Lua filter so cross-references are resolved first.
        cmd.append("--citeproc")
        for bib in bibliographies:
            cmd += ["--bibliography", str(ROOT / bib)]
        csl = resolve_csl(config)
        if csl:
            cmd += ["--csl", str(csl)]

    if target != "typst":
        # Typst resolves images itself (the filter makes the paths root-absolute);
        # every other writer needs to know where the Markdown's relative paths start.
        cmd += ["--resource-path", os.pathsep.join([str(ROOT), str(ROOT / meta["source-dir"])])]
    if target == "typst":
        cmd += ["--template", str(PKG / "templates" / "document.typ"),
                "-V", f"paperplate-lib={meta['paperplate-lib']}"]
    elif target == "docx" and config.get("docx-reference"):
        cmd += ["--reference-doc", str(ROOT / config["docx-reference"])]
    cmd += ["--output", str(out_file)]

    env = dict(os.environ, LC_ALL="C.UTF-8", TZ="UTC")
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, env=env)
    stderr_lines = []
    for line in result.stderr.strip().splitlines():
        if "rsvg-convert" in line:
            line = ("note: SVG figures were embedded as SVG; Word 2016 or newer shows them. "
                    "For older Word, use PNG figures or install rsvg-convert (librsvg).")
        stderr_lines.append(line)
    if stderr_lines:
        print("\n".join(stderr_lines), file=sys.stderr)
    if result.returncode != 0:
        raise BuildError("Pandoc failed")
    return result.stderr


def compile_pdf(config: dict, typ_file: Path, out_file: Path, ts: dt.datetime, strict: bool) -> list[str]:
    import typst

    font_paths = [str(PKG / "fonts")]
    for extra in config.get("font-paths", []) or []:
        font_paths.append(str(ROOT / extra))
    standards = config.get("pdf-standard") or []
    if isinstance(standards, str):
        standards = [standards]

    out_file.parent.mkdir(parents=True, exist_ok=True)
    try:
        _, warnings = typst.compile_with_warnings(
            str(typ_file),
            output=str(out_file),
            root=str(ROOT),
            font_paths=[p for p in font_paths if Path(p).exists()],
            ignore_system_fonts=True,   # only embedded + bundled fonts: same result everywhere
            pdf_standards=standards,
            timestamp=ts,
        )
    except typst.TypstError as err:
        raise BuildError(f"Typst failed:\n{err}")
    messages = [str(w) if not hasattr(w, "message") else w.message for w in warnings]
    for m in messages:
        print(f"typst warning: {m}", file=sys.stderr)
    if messages and strict:
        raise BuildError("warnings treated as errors (--strict)")
    return messages


# ---------------------------------------------------------------------------
def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="paperplate build")
    parser.add_argument("command", choices=["pdf", "docx", "typ", "versions"])
    parser.add_argument("--config", default=str(ROOT / "paperplate.yaml"))
    parser.add_argument("--strict", action="store_true",
                        help="fail on tool-version mismatch and on any warning")
    args = parser.parse_args(argv)

    try:
        pandoc = find_pandoc()
        versions = tool_versions(pandoc)
        if args.command == "versions":
            print(json.dumps(versions, indent=2))
            return 0
        check_versions(versions, args.strict)

        config = load_config(Path(args.config))
        ts = build_timestamp()
        meta = document_metadata(config, ts)
        stem = Path(config.get("output", "output/paper.pdf")).stem
        out_dir = ROOT / Path(config.get("output", "output/paper.pdf")).parent

        if args.command == "docx":
            out_file = out_dir / f"{stem}.docx"
            out_dir.mkdir(parents=True, exist_ok=True)
            run_pandoc(pandoc, config, meta, "docx", out_file)
            print(f"wrote {out_file.relative_to(ROOT)}")
            return 0

        typ_file = ROOT / "build" / "document.typ"
        stderr = run_pandoc(pandoc, config, meta, "typst", typ_file)
        missing = sorted(set(re.findall(r"Citeproc: citation (\S+) not found", stderr or "")))
        if missing:
            raise BuildError(
                "these citation keys are not in your bibliography file: " + ", ".join(missing)
                + "\nCheck the spelling against the keys in your .bib file (capital letters count).")
        if args.strict and stderr and "WARNING" in stderr:
            raise BuildError("Pandoc warnings treated as errors (--strict)")
        if args.command == "typ":
            print(f"wrote {typ_file.relative_to(ROOT)}")
            return 0

        out_file = out_dir / f"{stem}.pdf"
        compile_pdf(config, typ_file, out_file, ts, args.strict)
        print(f"wrote {out_file.relative_to(ROOT)}  "
              f"(pandoc {versions['pandoc']}, typst {versions['typst']}, "
              f"timestamp {ts.isoformat()})")
        return 0
    except BuildError as err:
        print(f"error: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
