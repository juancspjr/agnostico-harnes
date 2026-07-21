#!/usr/bin/env python3
# =============================================================================
# .jcode/lib/_config_parse.py — Parser TOML mínimo (sin dependencias externas)
# =============================================================================
# Soporta:
#   - Secciones [section] y [section.subsection]
#   - Scalars: key = "string" / key = number / key = bool
#   - Arrays: key = ["item1", "item2", ...] (multilínea OK)
# =============================================================================

import sys
import re


def parse_toml(content):
    """Retorna dict {section: {key: value_or_list}}"""
    result = {}
    current_section = None
    current_body_lines = []

    def flush_section():
        nonlocal current_section, current_body_lines
        if current_section is None:
            return
        body = "\n".join(current_body_lines)
        result[current_section] = parse_section_body(body)

    for line in content.split("\n"):
        # Section header
        m = re.match(r"^\s*\[([^\]]+)\]\s*$", line)
        if m:
            flush_section()
            current_section = m.group(1).strip()
            current_body_lines = []
            continue
        # Skip comments
        if line.strip().startswith("#"):
            continue
        if current_section is not None:
            current_body_lines.append(line)
    flush_section()
    return result


def parse_section_body(body):
    """Parsea el body de una sección → dict de key → value/list"""
    result = {}
    # Arrays: key = [...] multilínea
    array_pattern = re.compile(
        r'^(\w+)\s*=\s*\[(.*?)\]', re.MULTILINE | re.DOTALL
    )
    for m in array_pattern.finditer(body):
        key = m.group(1)
        items_raw = m.group(2)
        items = re.findall(r'"([^"]*)"', items_raw)
        result[key] = items
    # Scalars: key = "value" o key = number o key = bool (líneas simples)
    scalar_pattern = re.compile(r'^(\w+)\s*=\s*("[^"]*"|\d+(?:\.\d+)?|true|false)\s*(?:#.*)?$', re.MULTILINE)
    for m in scalar_pattern.finditer(body):
        key = m.group(1)
        if key in result:
            continue  # Ya parseado como array
        val = m.group(2).strip()
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        result[key] = val
    return result


def get_value(toml_data, key_path):
    """key_path = 'section.field' → retorna list (si array) o string (si scalar)
    Soporta secciones con puntos como 'workspace.code_extensions.extensions':
    el ÚLTIMO punto separa section de field.
    """
    if "." not in key_path:
        sys.exit(1)
    # Split on the LAST dot to handle dotted section names
    section, field = key_path.rsplit(".", 1)
    if section not in toml_data:
        sys.exit(1)
    sec_data = toml_data[section]
    if field not in sec_data:
        sys.exit(1)
    return sec_data[field]


def main():
    if len(sys.argv) < 3:
        print("Usage: _config_parse.py <config.toml> <section.field>", file=sys.stderr)
        sys.exit(1)

    config_file = sys.argv[1]
    key_path = sys.argv[2]

    try:
        with open(config_file, "r") as f:
            content = f.read()
    except Exception as e:
        print(f"Error leyendo {config_file}: {e}", file=sys.stderr)
        sys.exit(1)

    toml_data = parse_toml(content)
    try:
        value = get_value(toml_data, key_path)
    except SystemExit:
        sys.exit(1)

    if isinstance(value, list):
        for item in value:
            print(item)
    else:
        print(value)


if __name__ == "__main__":
    main()