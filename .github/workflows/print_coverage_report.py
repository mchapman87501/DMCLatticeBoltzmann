#!/usr/bin/env python3
from pathlib import Path
import json
import os

content = json.loads(Path("test_coverage.json").read_text())
data = content["data"]
file_entries = data[0]["files"]


def ansi_color(fg_color, bg_color):
    return f"\033[38;5;{fg_color};48;5;{bg_color}m"


def ansi_normal():
    return "\033[0m"


caution_thresh = 90
low_cov_thresh = 80

ansi_red = ansi_color(0, 9)
ansi_yellow = ansi_color(0, 11)
ansi_green = ansi_color(0, 10)


def pct_color(pct):
    if pct <= low_cov_thresh:
        return ansi_red
    if pct <= caution_thresh:
        return ansi_yellow
    return ansi_green


reset_color = ansi_normal()

print(f"""{"Filename":61.61s} Cov'd  Total  Pct""")
for entry in file_entries:
    filename = entry["filename"]
    rel_pathname = Path(filename).relative_to(Path.cwd())
    relname = os.fspath(rel_pathname)
    line_summary = entry["summary"]["lines"]
    covered = line_summary["covered"]
    total = line_summary["count"]
    percent = line_summary["percent"]
    color = pct_color(percent)

    print(
        f"""{color}{relname[-61:]:61.61s} {line_summary["covered"]:5d}  {line_summary["count"]:5d}  {line_summary["percent"]:3.0f}%{reset_color}"""
    )
