#!/usr/bin/env python3

# Re-evaluates Lua barrels (file table returns to make Lua have proper modules)

import os
import re
import sys

project_root = sys.argv[1]
src_path = os.path.join(project_root, "src")


def get_return_name(path: str):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    content = content.rstrip()

    # this is a submodule
    match = re.search(r"return\s+([A-Za-z_][A-Za-z0-9_.]*)\s*(?:--.*)?$", content)
    if match:
        return match.group(1)

    # this is a module barrel
    table_match = re.search(r"return\s*\{.*\}\s*(?:--.*)?$", content, re.DOTALL)
    if table_match:
        base = os.path.splitext(os.path.basename(path))[0]
        return base

    return None


def walk_module(submod_path: str, abs_submod_path: str):
    entries: dict[str, str] = {}

    root, _, files = next(os.walk(abs_submod_path))
    files = sorted(files)
    for file in files:
        if not file.endswith(".lua"):
            continue
        abs_mod_path = os.path.join(root, file)
        mod_req = os.path.join(submod_path, file[:-4]).replace("/", ".")
        mod_name = get_return_name(abs_mod_path)
        if not mod_name:
            continue
        entries[mod_name] = mod_req

    return entries


def gen_return_table(entries: dict[str, str]):
    lines = ["return {"]
    for mod_name, mod_req in entries.items():
        line = '    {0} = require("{1}"),'.format(mod_name, mod_req)
        lines.append(line)
    lines.append("}")
    return "\n".join(lines)


def gen_assignment_lines(entries: dict[str, str], varname: str):
    return [
        f'{varname}.{key} = require("{req_path}")' for key, req_path in entries.items()
    ]


def update_module_file(path: str, entries: dict[str, str]):
    if len(entries) < 1:
        return

    if not os.path.exists(path):
        dirpath = os.path.dirname(path)
        if dirpath:
            os.makedirs(dirpath, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            _ = f.write(gen_return_table(entries) + "\n")
        return

    with open(path, "r", encoding="utf-8") as f:
        content = f.read().rstrip()

    ident_match = re.search(r"return\s+([A-Za-z_][A-Za-z0-9_.]*)\s*(?:--.*)?$", content)

    if ident_match:
        varname = ident_match.group(1)
        lines = content.split("\n")
        return_line_idx = len(lines) - 1

        # Pattern for a single assignment line belonging to this varname
        assign_pattern = re.compile(
            r"^\s*" + re.escape(varname) + r'\.\w+\s*=\s*require\("[^"]+"\)\s*$'
        )

        # Scan upward from just above the return line, collecting contiguous matches
        block_start = return_line_idx
        i = return_line_idx - 1
        while i >= 0 and assign_pattern.match(lines[i]):
            block_start = i
            i -= 1

        existing_lines = lines[block_start:return_line_idx]
        desired_lines = gen_assignment_lines(entries, varname)

        # Compare stripped existing lines vs desired -- skip rewrite if identical
        if [l.strip() for l in existing_lines] == desired_lines:
            return  # already up to date, nothing to do

        # Rebuild: everything before the block + new block + return line onward
        before = lines[:block_start]
        after = lines[return_line_idx:]

        new_lines = before + desired_lines + after
        new_content = "\n".join(new_lines)

    else:
        table_match = re.search(r"return\s*\{.*\}\s*(?:--.*)?$", content, re.DOTALL)
        if table_match:
            new_content = content[: table_match.start()] + gen_return_table(entries)
        else:
            new_content = content + "\n\n" + gen_return_table(entries)

    new_content = new_content.rstrip() + "\n"

    with open(path, "w", encoding="utf-8") as f:
        _ = f.write(new_content)


def touch_module(submod_path: str):
    abs_submod_path = os.path.join(src_path, submod_path)
    update_module_file(
        abs_submod_path + ".lua", walk_module(submod_path, abs_submod_path)
    )


for root, dirs, files in os.walk(src_path, topdown=False):
    for dir in dirs:
        submod_path = os.path.relpath(os.path.join(root, dir), src_path)
        touch_module(submod_path)
