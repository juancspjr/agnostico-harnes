#!/usr/bin/env python3
# =============================================================================
# .jcode/lib/handbook_builder.py — Phase I: Static Fact Extraction (paper §3.2)
# =============================================================================
# Extrae el program graph G a partir del código fuente usando ast de stdlib.
# Auto-detecta leaf mode: function si <=200 funciones, file en caso contrario.
# Paper ref: arXiv:2607.13285v1, Phase I
# =============================================================================

import ast
import hashlib
import json
import os
import sys
from pathlib import Path


# Built-in methods that should NOT be counted as call edges
BUILTIN_METHODS = {
    'split', 'join', 'rsplit', 'splitlines', 'strip', 'rstrip', 'lstrip',
    'upper', 'lower', 'title', 'capitalize', 'swapcase', 'replace',
    'startswith', 'endswith', 'find', 'rfind', 'index', 'rindex',
    'count', 'encode', 'decode', 'format', 'format_map',
    'isdigit', 'isalnum', 'isupper', 'islower', 'isspace', 'istitle',
    'isidentifier', 'isprintable', 'isnumeric', 'isdecimal', 'isascii',
    'expandtabs', 'ljust', 'rjust', 'center', 'zfill', 'partition',
    'rpartition', 'removeprefix', 'removesuffix', 'translate', 'maketrans',
    'append', 'extend', 'insert', 'remove', 'pop', 'clear', 'sort', 'reverse', 'copy',
    'keys', 'values', 'items', 'get', 'popitem',
    'update', 'setdefault',
    'add', 'discard', 'union', 'intersection', 'difference',
    'read', 'readline', 'readlines', 'write', 'writelines',
    'close', 'flush', 'seek', 'tell', 'truncate', 'fileno',
    'hex', 'fromhex',
    'print', 'len', 'range', 'enumerate', 'zip', 'map', 'filter',
    'sorted', 'reversed', 'sum', 'min', 'max', 'abs', 'round',
    'isinstance', 'issubclass', 'hasattr', 'getattr', 'setattr',
    'delattr', 'dir', 'vars', 'type', 'id', 'hash', 'repr',
    'str', 'int', 'float', 'bool', 'complex',
    'list', 'tuple', 'set', 'frozenset', 'dict', 'bytes', 'bytearray',
    'open', 'input', 'iter', 'next', 'all', 'any',
    'match', 'search', 'findall', 'finditer', 'sub', 'subn', 'escape', 'fullmatch',
    'load', 'loads', 'dump', 'dumps',
    'exists', 'isfile', 'isdir', 'join', 'split', 'splitext',
    'basename', 'dirname', 'abspath', 'relpath', 'normpath',
    'getcwd', 'chdir', 'listdir', 'mkdir', 'makedirs', 'remove',
    'rmdir', 'removedirs', 'rename', 'renames', 'walk', 'glob',
}


def _read_source_dirs(repo_root: Path) -> list:
    """Lee source_dirs de config.toml o autodetecta."""
    config_path = repo_root / ".jcode" / "config.toml"
    if config_path.exists():
        try:
            import tomllib
            with open(config_path, "rb") as f:
                config = tomllib.load(f)
            dirs = config.get("workspace", {}).get("source_dirs", [])
            if dirs:
                return [str(d) for d in dirs if isinstance(d, str)]
        except Exception:
            pass

    # Autodetect
    candidates = ["src", "lib", "app", "tests", ".jcode/lib",
                  "backend", "frontend", "scripts"]
    return [d for d in candidates if (repo_root / d).exists()]


def _read_source_dirs_from_config(repo_root: Path) -> list:
    """Lee [workspace] source_dirs desde config.toml."""
    config_path = repo_root / ".jcode" / "config.toml"
    if not config_path.exists():
        return []  # will autodetect
    try:
        import tomllib
        with open(config_path, "rb") as f:
            config = tomllib.load(f)
        return config.get("workspace", {}).get("source_dirs", [])
    except Exception:
        return []


def _auto_detect_source_dirs(repo_root: Path) -> list:
    """Si no hay source_dirs configurados, detectar automáticamente."""
    candidates = ["src", "lib", "app", "tests", ".jcode/lib",
                  "backend", "frontend", "scripts"]
    return [d for d in candidates if (repo_root / d).exists()]


def _validate_repo_root(repo_root: Path):
    """C-4: validar repo_root ANTES de cualquier operación."""
    if not repo_root.exists():
        raise FileNotFoundError(
            f"repo_root no existe: {repo_root}. "
            f"Verificar --repo path."
        )
    if not repo_root.is_dir():
        raise NotADirectoryError(
            f"repo_root no es directorio: {repo_root}"
        )
    if not os.access(repo_root, os.R_OK):
        raise PermissionError(
            f"Sin permisos de lectura en: {repo_root}"
        )


class PythonAdapter:
    """Adapter Python para extraer el program graph G."""

    def extract(self, repo_root: Path) -> dict:
        """Extrae el program graph G del repo con scan dinámico."""
        # C-4: validar repo_root ANTES de cualquier operación
        _validate_repo_root(repo_root)

        functions = []
        call_edges = []
        state_accesses = []
        files_scanned = 0
        unresolved_calls_log = []

        # C-1: scan_dirs dinámico (desde config.toml o autodetect)
        configured_dirs = _read_source_dirs(repo_root)
        scan_dirs = configured_dirs[:]

        # C-1: SIEMPRE incluir .jcode/lib (circularidad del harness)
        if ".jcode/lib" not in scan_dirs:
            scan_dirs.append(".jcode/lib")

        # Filtrar solo directorios que existen
        scan_dirs = [d for d in scan_dirs if (repo_root / d).exists()]

        if not scan_dirs:
            print("[warn] No source directories found. Autodetecting...", file=sys.stderr)
            scan_dirs = _auto_detect_source_dirs(repo_root)

        for scan_dir in scan_dirs:
            for py_file in (repo_root / scan_dir).rglob("*.py"):
                # Skip __pycache__
                if "__pycache__" in str(py_file):
                    continue
                files_scanned += 1
                try:
                    source = py_file.read_text(encoding="utf-8", errors="replace")
                    tree = ast.parse(source, filename=str(py_file))
                except (SyntaxError, UnicodeDecodeError) as e:
                    unresolved_calls_log.append({
                        "file": str(py_file.relative_to(repo_root)),
                        "error": f"parse_error: {type(e).__name__}: {str(e)[:100]}",
                    })
                    continue

                rel_path = str(py_file.relative_to(repo_root))
                self._extract_from_tree(
                    tree, rel_path, source,
                    functions, call_edges, state_accesses, unresolved_calls_log
                )

        # C-4: nunca retornar PG vacío (quien llama no debe escribirlo)
        if not functions and files_scanned > 0:
            raise RuntimeError(
                "Functions found but none extracted. "
                "Check AST extraction logic."
            )
        if not functions:
            raise RuntimeError(
                f"No functions found in {scan_dirs}. "
                f"Verificar --repo path y source_dirs en config.toml. "
                f"Files scanned: {files_scanned}. "
                f"NO se escribió program_graph.json."
            )

        # Auto-detect leaf mode
        leaf_mode = "function" if len(functions) <= 200 else "file"

        graph = {
            "schema_version": 1,
            "language": "python",
            "leaf_mode": leaf_mode,
            "files_scanned": files_scanned,
            "functions": functions,
            "boundaries": [],
            "call_edges": call_edges,
            "state_accesses": state_accesses,
            "unresolved_calls_log": unresolved_calls_log,
        }
        return graph

    def _extract_from_tree(self, tree, rel_path, source, functions, call_edges,
                          state_accesses, unresolved_calls_log):
        """Extrae funciones, calls y state access del AST tree."""
        # Mapear nombres a qualnames
        scope_stack = []
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                scope_stack.append(node.name)
                for item in node.body:
                    if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        self._record_function(
                            item, rel_path, source,
                            functions, call_edges, state_accesses,
                            unresolved_calls_log, qualname_prefix=".".join(scope_stack),
                        )
                scope_stack.pop()

        # Funciones top-level
        for node in tree.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                self._record_function(
                    node, rel_path, source,
                    functions, call_edges, state_accesses,
                    unresolved_calls_log, qualname_prefix="",
                )

    def _record_function(self, func_node, rel_path, source, functions,
                         call_edges, state_accesses, unresolved_calls_log,
                         qualname_prefix=""):
        """Registra una función con sus calls y state accesses."""
        func_name = func_node.name
        qualname = f"{qualname_prefix}.{func_name}" if qualname_prefix else func_name

        # Signature
        try:
            signature = ast.unparse(func_node.args) if hasattr(ast, 'unparse') else f"({func_node.args})"
        except Exception:
            signature = "(...)"
        return_annotation = ""
        if func_node.returns:
            try:
                return_annotation = f" -> {ast.unparse(func_node.returns)}" if hasattr(ast, 'unparse') else ""
            except Exception:
                pass
        full_signature = f"({signature}){return_annotation}"

        # Body hash
        try:
            body_src = ast.get_source_segment(source, func_node) or ""
            body_hash = "sha256:" + hashlib.sha256(body_src.encode()).hexdigest()[:16]
        except Exception:
            body_hash = "sha256:unknown"

        functions.append({
            "qualname": qualname,
            "file": rel_path,
            "line_range": [func_node.lineno, func_node.end_lineno or func_node.lineno],
            "signature": full_signature,
            "body_hash": body_hash,
        })

        # Extract calls dentro de esta función
        for node in ast.walk(func_node):
            if isinstance(node, ast.Call):
                callee_name = self._get_call_name(node.func)
                if not callee_name:
                    continue
                # H-2: filtrar métodos built-in y funciones builtins
                if callee_name in BUILTIN_METHODS:
                    continue
                call_edges.append({
                        "caller": qualname,
                        "callee": callee_name,
                        "line": node.lineno,
                        "resolved": False,  # Marcamos como no resuelto; Phase III puede resolver
                    })

            # State accesses: self.x = ... (write) vs ... = self.x (read)
            if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name) and node.value.id == "self":
                access_type = "unknown"
                # Buscar si es parte de un Assign target
                parent_is_assign = self._is_assign_target(node)
                access_type = "write" if parent_is_assign else "read"
                state_accesses.append({
                    "function": qualname,
                    "attribute": f"self.{node.attr}",
                    "access": access_type,
                    "line": node.lineno,
                })

    def _get_call_name(self, func_node):
        """Extrae el nombre de la función llamada."""
        if isinstance(func_node, ast.Name):
            return func_node.id
        elif isinstance(func_node, ast.Attribute):
            return func_node.attr
        return None

    def _is_assign_target(self, attr_node):
        """Heurística: si un Attribute es target de Assign → write."""
        # ast no provee parent directo, usamos heurística simple
        # Si está en la posición 0 de Assign.targets, es write
        return True  # Simplificado para Phase I


def build_program_graph(repo_root: str) -> dict:
    """Construye el program graph G para el repo dado."""
    root = Path(repo_root).resolve()
    adapter = PythonAdapter()
    return adapter.extract(root)


def save_program_graph(graph: dict, output_path: str):
    """Guarda el program graph a JSON."""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(graph, f, indent=2)
    print(f"[ok] program graph saved to {output_path}")
    print(f"     {len(graph['functions'])} functions, "
          f"{len(graph['call_edges'])} call edges, "
          f"{len(graph['state_accesses'])} state accesses, "
          f"leaf_mode={graph['leaf_mode']}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Handbook Phase I: Static Fact Extraction")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--output", default=".jcode/handbook/program_graph.json",
                        help="Output JSON path")
    args = parser.parse_args()

    try:
        graph = build_program_graph(args.repo)
        save_program_graph(graph, args.output)
    except (FileNotFoundError, NotADirectoryError, PermissionError, RuntimeError) as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()