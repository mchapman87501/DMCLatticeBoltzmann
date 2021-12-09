#!/usr/bin/env python3
from pathlib import Path
import json
import os


def ansi_color(fg_color, bg_color):
    return f"\033[38;5;{fg_color};48;5;{bg_color}m"


def ansi_normal():
    return "\033[0m"


caution_thresh = 90
low_cov_thresh = 80

ansi_red = ansi_color(0, 9)
ansi_yellow = ansi_color(0, 11)
ansi_green = ansi_color(0, 10)
reset_color = ansi_normal()


def pct_color(pct):
    if pct <= low_cov_thresh:
        return ansi_red
    if pct <= caution_thresh:
        return ansi_yellow
    return ansi_green


def get_all_file_entries():
    content = json.loads(Path("test_coverage.json").read_text())
    data = content["data"]
    return data[0]["files"]


def get_source_file_entries():
    # Get files from Sources only.
    for entry in get_all_file_entries():
        filename = entry["filename"]
        rel_pathname = Path(filename).relative_to(Path.cwd())
        top_dir = rel_pathname.parts[0]
        # TODO handle case-insensitive filesystems
        if top_dir == "Sources":
            yield entry


def print_coverage(file_entries):
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
            f"""{color}{relname[-61:]:61.61s} {covered:5d}  {total:5d}  {percent:3.0f}%{reset_color}"""
        )


def main():
    file_entries = get_source_file_entries()
    print_coverage(file_entries)


if __name__ == "__main__":
    main()
