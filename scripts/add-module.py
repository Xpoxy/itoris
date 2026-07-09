#!/usr/bin/env python3
import re
import sys


def main():
    if len(sys.argv) < 5:
        sys.exit(1)

    path = sys.argv[2]
    template_file = sys.argv[3]
    module_name = sys.argv[4]
    base_class = sys.argv[5] if len(sys.argv) > 5 else ""

    with open(template_file, "r") as f:
        template = f.read()

    def replace(match):
        index = int(match.group(1))
        return sys.argv[index] if index < len(sys.argv) else ""

    content = (
        re.sub(r"%(\d+)", replace, template)
        .replace("%M", module_name)
        .replace("%B", base_class)
    )

    with open(path, "w") as f:
        _ = f.write(content)


main()
