#!/usr/bin/env python3
"""One-off draft PDF from markdown (plain layout, no LaTeX rendering)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

from fpdf import FPDF


def md_to_plain(md: str) -> str:
    md = re.sub(r"^\s*---\s*$", "", md, flags=re.MULTILINE)
    md = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", md)
    md = re.sub(r"\*\*([^*]+)\*\*", r"\1", md)
    md = re.sub(r"\*([^*]+)\*", r"\1", md)
    md = re.sub(r"^#+\s*", "", md, flags=re.MULTILINE)
    md = re.sub(r"^\s*[-*]\s+", "• ", md, flags=re.MULTILINE)
    md = re.sub(r"\$\$[^$]+\$\$", "[equation]", md)
    md = re.sub(r"\$[^$]+\$", "[eq]", md)
    md = re.sub(r"<[^>]+>", "", md)
    return md


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    src = root / "documentation" / "Article_Improved.md"
    out = root / "documentation" / "Article_Improved_draft.pdf"
    if len(sys.argv) >= 2:
        out = Path(sys.argv[1])

    text = md_to_plain(src.read_text(encoding="utf-8"))
    font = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.add_font("DejaVu", "", font)
    pdf.add_font("DejaVu", "B", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
    pdf.set_font("DejaVu", "", 10)

    for para in text.split("\n\n"):
        line = para.strip()
        if not line:
            continue
        if line.startswith("• "):
            pdf.set_font("DejaVu", "", 10)
        elif len(line) < 120 and not line.endswith("."):
            pdf.set_font("DejaVu", "B", 11)
        else:
            pdf.set_font("DejaVu", "", 10)
        pdf.multi_cell(0, 5, line)
        pdf.ln(2)

    pdf.output(str(out))
    print(out)


if __name__ == "__main__":
    main()
