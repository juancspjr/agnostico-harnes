#!/usr/bin/env python3
"""
language_adapter.py — Framework multi-lenguaje con Python como referencia.

Permite registrar adaptadores para cualquier lenguaje. Cada adaptador
implementa la misma interfaz que PythonAdapter. Auto-detecta el lenguaje
del proyecto.

Framework extensible:
  1. Definir clase que herede de BaseAdapter
  2. Implementar extract(), parse_file(), _extract_from_tree()
  3. Registrar con LanguageAdapterRegistry.register("lang", MyAdapter)
  4. Listo

Uso:
  python3 language_adapter.py [--repo PATH] [--detect]
  python3 language_adapter.py [--repo PATH] [--generate-skeleton LANG]
"""

import ast
import importlib
import inspect
import json
import os
import sys
from abc import ABC, abstractmethod
from pathlib import Path


class BaseAdapter(ABC):
    """Interfaz que todos los adaptadores deben implementar.

    Referencia: PythonAdapter en handbook_builder.py
    """

    FILE_EXT = ".py"  # Extensión por defecto (cada adapter override)

    @abstractmethod
    def extract(self, repo_root: Path) -> dict:
        """Extrae el program graph G del repo."""
        ...

    @abstractmethod
    def parse_file(self, path: Path, rel_path: str) -> dict:
        """Parsea un archivo y retorna funciones, calls y state."""
        ...

    def validate_skeleton(self) -> bool:
        """Verifica que el adaptador implementa los métodos mínimos."""
        methods = ["extract", "parse_file"]
        for m in methods:
            if not hasattr(self, m) or not callable(getattr(self, m)):
                return False
        return True


class LanguageAdapterRegistry:
    """Registro central de adaptadores de lenguaje."""

    _adapters = {}

    @classmethod
    def register(cls, name: str, adapter_class):
        """Registra un adaptador para un lenguaje."""
        cls._adapters[name] = adapter_class

    @classmethod
    def get(cls, name: str):
        """Obtiene adaptador por nombre de lenguaje."""
        return cls._adapters.get(name)

    @classmethod
    def list(cls) -> list:
        """Lista lenguajes registrados."""
        return list(cls._adapters.keys())

    @classmethod
    def auto_detect(cls, repo_root) -> str:
        """Detecta el lenguaje del proyecto por extensiones."""
        if isinstance(repo_root, str):
            repo_root = Path(repo_root)
        # Buscar extensiones en src/ y raíz
        extensions = set()
        scan_dirs = [repo_root / "src", repo_root]
        for sd in scan_dirs:
            if sd.exists():
                for f in sd.rglob("*"):
                    if f.is_file() and not f.name.startswith("."):
                        extensions.add(f.suffix.lower())

        # Mapa extensión → lenguaje
        ext_map = {
            ".py": "python", ".pyx": "python", ".go": "go", ".ts": "typescript",
            ".tsx": "typescript", ".js": "javascript", ".jsx": "javascript",
            ".rs": "rust", ".java": "java", ".kt": "kotlin", ".cs": "csharp",
            ".rb": "ruby", ".swift": "swift",
        }

        lang_scores = {}
        for ext, lang in ext_map.items():
            if ext in extensions:
                lang_scores[lang] = lang_scores.get(lang, 0) + 1

        if not lang_scores:
            return "python"  # default

        return max(lang_scores, key=lang_scores.get)


# Registrar PythonAdapter como referencia
try:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent / "lib"))
    from handbook_builder import PythonAdapter
    LanguageAdapterRegistry.register("python", PythonAdapter)
except ImportError:
    print("[warn] PythonAdapter no disponible — solo registro básico", file=sys.stderr)


def generate_adapter_skeleton(language: str) -> str:
    """Genera un esqueleto de adaptador para un lenguaje."""
    templates = {
        "go": '''
class GoAdapter(BaseAdapter):
    """Adapter para Go."""

    FILE_EXT = ".go"

    def extract(self, repo_root: Path) -> dict:
        """Extrae program graph G de código Go."""
        # TODO: implementar con AST parser Go o regex
        # Referencia: PythonAdapter en handbook_builder.py
        raise NotImplementedError("GoAdapter pending implementation")

    def parse_file(self, path: Path, rel_path: str) -> dict:
        raise NotImplementedError("GoAdapter.parse_file pending")
''',
        "typescript": '''
class TypeScriptAdapter(BaseAdapter):
    """Adapter para TypeScript."""

    FILE_EXT = ".ts"

    def extract(self, repo_root: Path) -> dict:
        """Extrae program graph G de código TypeScript."""
        # TODO: usar TypeScript compiler API o regex
        # Referencia: PythonAdapter en handbook_builder.py
        raise NotImplementedError("TypeScriptAdapter pending implementation")

    def parse_file(self, path: Path, rel_path: str) -> dict:
        raise NotImplementedError("TypeScriptAdapter.parse_file pending")
''',
        "rust": '''
class RustAdapter(BaseAdapter):
    """Adapter para Rust."""

    FILE_EXT = ".rs"

    def extract(self, repo_root: Path) -> dict:
        """Extrae program graph G de código Rust."""
        # TODO: usar syn crate o tree-sitter
        # Referencia: PythonAdapter en handbook_builder.py
        raise NotImplementedError("RustAdapter pending implementation")

    def parse_file(self, path: Path, rel_path: str) -> dict:
        raise NotImplementedError("RustAdapter.parse_file pending")
''',
        "java": '''
class JavaAdapter(BaseAdapter):
    """Adapter para Java."""

    FILE_EXT = ".java"

    def extract(self, repo_root: Path) -> dict:
        """Extrae program graph G de código Java."""
        # TODO: usar javaparser o regex
        # Referencia: PythonAdapter en handbook_builder.py
        raise NotImplementedError("JavaAdapter pending implementation")

    def parse_file(self, path: Path, rel_path: str) -> dict:
        raise NotImplementedError("JavaAdapter.parse_file pending")
''',
        "javascript": '''
class JavaScriptAdapter(BaseAdapter):
    """Adapter para JavaScript."""

    FILE_EXT = ".js"

    def extract(self, repo_root: Path) -> dict:
        """Extrae program graph G de código JavaScript."""
        # TODO: usar acorn/esprima o tree-sitter
        # Referencia: PythonAdapter en handbook_builder.py
        raise NotImplementedError("JavaScriptAdapter pending implementation")

    def parse_file(self, path: Path, rel_path: str) -> dict:
        raise NotImplementedError("JavaScriptAdapter.parse_file pending")
''',
    }

    if language in templates:
        header = f'''"""
{language.capitalize()}Adapter — Adaptador para {language}.

Generado automáticamente por language_adapter.py.
Sigue la misma interfaz que PythonAdapter en handbook_builder.py.
Implementar métodos extract() y parse_file() para completar.
"""

from pathlib import Path
from language_adapter import BaseAdapter


'''
        return header + templates[language]
    return None


def detect(repo_root: str = ".") -> dict:
    """Detecta lenguajes y adaptadores disponibles."""
    root = Path(repo_root).resolve()
    detected_lang = LanguageAdapterRegistry.auto_detect(root)
    available = LanguageAdapterRegistry.list()

    return {
        "detected_language": detected_lang,
        "available_adapters": available,
        "has_adapter": detected_lang in available,
        "python_reference_available": "python" in available,
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Language Adapter — multi-lenguaje framework")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--detect", action="store_true", help="Detect language")
    parser.add_argument("--generate-skeleton", metavar="LANG",
                        help="Generate adapter skeleton (go, typescript, rust, java, javascript)")
    parser.add_argument("--list", action="store_true", help="List registered adapters")
    args = parser.parse_args()

    if args.list:
        print(f"Registered adapters: {LanguageAdapterRegistry.list()}")
        return

    if args.generate_skeleton:
        skeleton = generate_adapter_skeleton(args.generate_skeleton)
        if skeleton:
            print(skeleton)
        else:
            print(f"[error] No template for '{args.generate_skeleton}'. "
                  f"Available: go, typescript, rust, java, javascript")
        return

    if args.detect:
        result = detect(args.repo)
        print(f"=== Language Adapter: {result['detected_language']} ===")
        print(f"Available adapters: {result['available_adapters']}")
        print(f"Has adapter: {'✅' if result['has_adapter'] else '❌ (generar con --generate-skeleton)'}")
        print(f"Python reference: {'✅' if result['python_reference_available'] else '❌'}")
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
