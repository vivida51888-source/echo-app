#!/usr/bin/env python3
"""Remove `const` from widgets whose arguments reference EchoColors day/onSurface colors."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
WIDGETS = (
    "TextStyle",
    "Text",
    "Icon",
    "Padding",
    "InputDecoration",
    "Center",
    "Expanded",
)
ECHO = r"EchoColors\.(?:day|onSurface)"


def strip_const_blocks(content: str) -> str:
    for widget in WIDGETS:
        pattern = rf"const ({widget}\s*\("
        pos = 0
        while True:
            m = re.search(pattern, content[pos:])
            if not m:
                break
            start = pos + m.start()
            paren = pos + m.end() - 1
            depth = 0
            i = paren
            while i < len(content):
                if content[i] == "(":
                    depth += 1
                elif content[i] == ")":
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
                i += 1
            else:
                break
            block = content[start:end]
            if re.search(ECHO, block):
                content = content[:start] + block[6:] + content[end:]
                pos = start
            else:
                pos = end
    return content


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        updated = strip_const_blocks(text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            changed += 1
            print(path.relative_to(ROOT.parent))
    print(f"Updated {changed} files")


if __name__ == "__main__":
    main()
