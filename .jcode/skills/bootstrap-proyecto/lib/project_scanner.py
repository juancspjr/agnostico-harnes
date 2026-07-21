#!/usr/bin/env python3
"""
project_scanner.py — Detecta dominio, lenguaje y estado del proyecto.

Lee PDR.md, PROJECT.md, y escanea src/ para determinar:
- Dominio del proyecto (CRM, e-commerce, API, ML, etc.)
- Lenguaje principal (Python, Go, TypeScript, Rust, Java)
- Estado: vacío, en desarrollo, completo
- Flujos críticos (desde PDR.md §5)

Uso:
  python3 project_scanner.py [--repo PATH]
"""

import json
import os
import re
import sys
from pathlib import Path

LANGUAGE_SIGNATURES = {
    "python": {
        "extensions": {".py", ".pyx", ".ipynb"},
        "indicators": ["import ", "from ", "def ", "class ", "if __name__"],
    },
    "go": {
        "extensions": {".go"},
        "indicators": ["package ", "func ", "import (", "type struct"],
    },
    "typescript": {
        "extensions": {".ts", ".tsx"},
        "indicators": ["interface ", "type ", "import ", "export ", "const ", "function "],
    },
    "javascript": {
        "extensions": {".js", ".jsx", ".mjs"},
        "indicators": ["const ", "function ", "import ", "export ", "require("],
    },
    "rust": {
        "extensions": {".rs"},
        "indicators": ["fn ", "let mut ", "impl ", "struct ", "enum ", "pub "],
    },
    "java": {
        "extensions": {".java", ".kt", ".scala"},
        "indicators": ["public class", "private ", "import java.", "@Override"],
    },
    "csharp": {
        "extensions": {".cs"},
        "indicators": ["namespace ", "using System", "class ", "public void"],
    },
    "ruby": {
        "extensions": {".rb"},
        "indicators": ["def ", "class ", "require ", "gem ", "module "],
    },
}

DOMAIN_PATTERNS = {
    "crm": {
        "indicators": [
            "cliente", "lead", "customer", "contacto", "venta", "sale",
            "oportunidad", "opportunity", "pipeline", "account",
        ],
    },
    "ecommerce": {
        "indicators": [
            "producto", "product", "carrito", "cart", "orden", "order",
            "pago", "payment", "checkout", "inventario", "inventory",
        ],
    },
    "erp": {
        "indicators": [
            "factura", "invoice", "proveedor", "supplier", "compra", "purchase",
            "inventario", "inventory", "contabilidad", "accounting",
        ],
    },
    "api": {
        "indicators": [
            "endpoint", "route", "middleware", "rest", "graphql",
            "api", "http", "request", "response",
        ],
    },
    "ml": {
        "indicators": [
            "modelo", "model", "entrenar", "train", "predicción", "prediction",
            "dataset", "neural", "tensor", "sklearn", "pytorch",
        ],
    },
    "auth": {
        "indicators": [
            "login", "logout", "register", "password", "token", "sesión",
            "session", "oauth", "jwt", "autenticación", "authentication",
        ],
    },
    "data": {
        "indicators": [
            "etl", "pipeline", "data", "dato", "transformación", "transform",
            "batch", "streaming", "warehouse", "base de datos",
        ],
    },
    "devops": {
        "indicators": [
            "deploy", "ci/cd", "docker", "kubernetes", "terraform",
            "infra", "monitor", "observabilidad", "observability",
        ],
    },
}


def read_file_safe(path: Path) -> str:
    """Lee archivo sin lanzar excepción."""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except (FileNotFoundError, PermissionError, OSError):
        return ""


def detect_domain(pdr_path: Path, project_path: Path) -> list:
    """Detecta dominio del proyecto desde PDR.md, PROJECT.md y código."""
    content = read_file_safe(pdr_path).lower()
    content += "\n" + read_file_safe(project_path).lower()

    # También escanear src/ para keywords
    src_dir = pdr_path.parent / "src"
    if src_dir.exists():
        for f in src_dir.rglob("*"):
            if f.is_file():
                try:
                    content += "\n" + f.read_text(encoding="utf-8", errors="replace").lower()
                except Exception:
                    pass

    domains = []
    for domain, config in DOMAIN_PATTERNS.items():
        score = sum(1 for ind in config["indicators"] if ind in content)
        if score >= 2:
            domains.append((domain, score))

    domains.sort(key=lambda x: -x[1])
    return [d for d, s in domains]


def detect_language(repo_root: Path) -> list:
    """Detecta lenguajes presentes en src/ por extensiones."""
    src_dir = repo_root / "src"
    if not src_dir.exists():
        return []

    extensions = set()
    for f in src_dir.rglob("*"):
        if f.is_file():
            extensions.add(f.suffix.lower())

    languages = []
    for lang, config in LANGUAGE_SIGNATURES.items():
        overlap = extensions & config["extensions"]
        if overlap:
            languages.append((lang, len(overlap)))

    languages.sort(key=lambda x: -x[1])
    return [l for l, s in languages]


def detect_project_state(repo_root: Path) -> dict:
    """Determina estado del proyecto: empty, developing, mature."""
    src_dir = repo_root / "src"

    if not src_dir.exists() or not any(src_dir.rglob("*")):
        return "empty"

    total_files = sum(1 for f in src_dir.rglob("*") if f.is_file())
    total_lines = sum(
        len(f.read_text(encoding="utf-8", errors="replace").splitlines())
        for f in src_dir.rglob("*") if f.is_file()
        if f.suffix in {".py", ".go", ".ts", ".js", ".rs", ".java", ".cs", ".rb"}
    )

    if total_files < 5 or total_lines < 200:
        return "developing"
    return "mature"


def extract_critical_flows(pdr_path: Path) -> list:
    """Extrae flujos críticos desde PDR.md §5 (o sección similar)."""
    content = read_file_safe(pdr_path)
    # Buscar sección §5 o "flujos críticos" o "critical flows"
    section = ""
    patterns = [
        r"§5.*?(?=§\d|$)", r"flujos? críticos?.*?(?=\n##|\Z)",
        r"critical flows?.*?(?=\n##|\Z)", r"## 5\..*?(?=\n##|\Z)",
    ]
    for p in patterns:
        m = re.search(p, content, re.IGNORECASE | re.DOTALL)
        if m:
            section = m.group(0)
            break

    if not section:
        return []

    # Extraer items con bullet points o numbered lists
    flows = re.findall(r"[-*]\s+(.+?)(?=\n[-*]|\n\d\.|\Z)", section)
    if not flows:
        flows = re.findall(r"\d\.\s+(.+?)(?=\n\d\.|\Z)", section)
    if not flows:
        # Last resort: split by newlines, take non-empty lines
        flows = [l.strip("- *") for l in section.split("\n")
                 if l.strip() and not l.strip().startswith("#")]

    return [f.strip() for f in flows if len(f.strip()) > 10][:10]


def scan(repo_root: str = ".") -> dict:
    """Escaner completo del proyecto."""
    root = Path(repo_root).resolve()
    pdr_path = root / "PDR.md"
    project_path = root / "PROJECT.md"

    result = {
        "project_name": root.name,
        "state": detect_project_state(root),
        "languages": detect_language(root),
        "domains": detect_domain(pdr_path, project_path),
        "critical_flows": extract_critical_flows(pdr_path),
        "has_pdr": pdr_path.exists(),
        "has_project_md": project_path.exists(),
        "src_file_count": sum(1 for f in (root / "src").rglob("*") if f.is_file())
        if (root / "src").exists() else 0,
    }

    return result


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Project Scanner — detecta dominio, lenguaje y estado")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = scan(args.repo)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"=== Project Scanner: {result['project_name']} ===")
        print(f"Estado: {result['state']}")
        print(f"Lenguajes: {result['languages'] or '(ninguno detectado)'}")
        print(f"Dominios: {result['domains'] or '(no detectado)'}")
        print(f"Flujos críticos: {len(result['critical_flows'])} encontrados")
        print(f"Archivos en src/: {result['src_file_count']}")
        print(f"PDR.md: {'✅' if result['has_pdr'] else '❌'}")
        print(f"PROJECT.md: {'✅' if result['has_project_md'] else '❌'}")

    return result


if __name__ == "__main__":
    main()
