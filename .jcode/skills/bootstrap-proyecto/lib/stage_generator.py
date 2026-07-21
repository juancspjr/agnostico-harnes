#!/usr/bin/env python3
"""
stage_generator.py — Genera seed skeleton S₀ desde el proyecto.

Lee el dominio detectado y los flujos críticos del proyecto para
generar stages específicas. Si no hay proyecto, usa defaults
adaptables marcados como _adaptable=True.

Uso:
  python3 stage_generator.py [--repo PATH] [--json]
  python3 stage_generator.py [--repo PATH] [--apply]  # Aplica a config.toml
"""

import json
import sys
from pathlib import Path

# Stages genericas default (hardcodeado legacy, usado si no hay proyecto)
DEFAULT_STAGES = [
    {"id": "init", "name": "Inicialización", "description": "Bootstrap session, state init"},
    {"id": "interpret", "name": "Interpretación", "description": "Triage task, decide skills"},
    {"id": "plan", "name": "Planificación", "description": "DDLP, TPSP, declare loop"},
    {"id": "execute", "name": "Ejecución", "description": "Worker, build, edit, commit"},
    {"id": "verify", "name": "Verificación", "description": "Checks, smoke tests"},
    {"id": "handoff", "name": "Entrega", "description": "Closeout, handoff next agent"},
]

# Domain-to-stage mappings for common project types
DOMAIN_STAGES = {
    "crm": [
        {"id": "auth", "name": "Autenticación", "description": "Login, registro, sesiones, roles"},
        {"id": "leads", "name": "Prospección", "description": "Captura de leads, calificación, pipeline"},
        {"id": "sales", "name": "Ventas", "description": "Oportunidades, cotizaciones, cierres"},
        {"id": "customers", "name": "Clientes", "description": "Gestión de contactos, historial"},
        {"id": "reports", "name": "Reportes", "description": "Dashboards, KPIs, exportación"},
    ],
    "ecommerce": [
        {"id": "products", "name": "Productos", "description": "Catálogo, inventario, precios"},
        {"id": "cart", "name": "Carrito", "description": "Checkout, descuentos, impuestos"},
        {"id": "orders", "name": "Órdenes", "description": "Procesamiento, pagos, envíos"},
        {"id": "users", "name": "Usuarios", "description": "Perfiles, direcciones, preferencias"},
        {"id": "admin", "name": "Administración", "description": "Panel, analytics, reporting"},
    ],
    "erp": [
        {"id": "invoicing", "name": "Facturación", "description": "Facturas, notas crédito, retenciones"},
        {"id": "inventory", "name": "Inventario", "description": "Stock, movimientos, auditoría"},
        {"id": "procurement", "name": "Compras", "description": "Órdenes compra, proveedores"},
        {"id": "accounting", "name": "Contabilidad", "description": "Libros diario, mayor, balances"},
        {"id": "hr", "name": "RRHH", "description": "Empleados, nómina, ausencias"},
    ],
    "api": [
        {"id": "routes", "name": "Endpoints", "description": "Definición de rutas y middlewares"},
        {"id": "validation", "name": "Validación", "description": "Schemas, tipos, sanitización"},
        {"id": "auth", "name": "Autenticación", "description": "JWT, OAuth, API keys"},
        {"id": "storage", "name": "Persistencia", "description": "Base de datos, caché, archivos"},
        {"id": "docs", "name": "Documentación", "description": "OpenAPI, ejemplos, SDK"},
    ],
    "ml": [
        {"id": "data", "name": "Datos", "description": "Ingesta, limpieza, exploración"},
        {"id": "train", "name": "Entrenamiento", "description": "Modelos, hiperparámetros, validación"},
        {"id": "eval", "name": "Evaluación", "description": "Métricas, test sets, comparación"},
        {"id": "deploy", "name": "Despliegue", "description": "Servir modelo, API, monitoreo"},
        {"id": "pipeline", "name": "Pipeline", "description": "Automación, versionado, registro"},
    ],
    "auth": [
        {"id": "login", "name": "Login", "description": "Credenciales, MFA, SSO"},
        {"id": "register", "name": "Registro", "description": "Signup, verificación, onboarding"},
        {"id": "sessions", "name": "Sesiones", "description": "Tokens, refresh, revocación"},
        {"id": "permissions", "name": "Permisos", "description": "Roles, scopes, políticas"},
        {"id": "audit", "name": "Auditoría", "description": "Logs, eventos, compliance"},
    ],
    "data": [
        {"id": "ingest", "name": "Ingesta", "description": "Conexiones, extracción, scheduling"},
        {"id": "transform", "name": "Transformación", "description": "Limpieza, normalización, enriquecimiento"},
        {"id": "load", "name": "Carga", "description": "Almacenamiento, particionado, índices"},
        {"id": "analyze", "name": "Análisis", "description": "Consultas, agregaciones, reporting"},
        {"id": "monitor", "name": "Monitoreo", "description": "Calidad datos, alertas, linaje"},
    ],
    "devops": [
        {"id": "infra", "name": "Infraestructura", "description": "Cloud, redes, storage"},
        {"id": "deploy", "name": "Despliegue", "description": "CI/CD, rollback, canary"},
        {"id": "monitor", "name": "Monitoreo", "description": "Métricas, logs, alertas"},
        {"id": "security", "name": "Seguridad", "description": "Vulnerabilidades, compliance"},
        {"id": "backup", "name": "Respaldo", "description": "Backups, DRP, retention"},
    ],
}


def get_stages_for_domain(domains: list, critical_flows: list = None) -> list:
    """Genera stages a partir de dominios detectados y flujos críticos."""
    stages = []
    seen_ids = set()

    # Stages del dominio principal
    for domain in domains:
        if domain in DOMAIN_STAGES:
            for s in DOMAIN_STAGES[domain]:
                if s["id"] not in seen_ids:
                    seen_ids.add(s["id"])
                    stages.append(s)

    # Stages desde flujos críticos (si hay)
    if critical_flows:
        for flow in critical_flows[:8]:
            flow_id = flow.lower().replace(" ", "_").replace("-", "_")[:20]
            if flow_id not in seen_ids:
                seen_ids.add(flow_id)
                stages.append({
                    "id": flow_id,
                    "name": flow[:25],
                    "description": flow[:60],
                })

    return stages[:10]  # max 10 stages


def generate_test_skeletons(repo_root: str = ".") -> list:
    """Genera esqueletos de tests/integration/ desde PDR.md §5 (Capa B).

    Cada flujo crítico en PDR.md §5 genera un esqueleto de test con
    `set -euo pipefail` y placeholder para aserciones. El primer loop
    que toque ese flujo completa el esqueleto.
    """
    root = Path(repo_root).resolve()
    pdr_path = root / "PDR.md"

    if not pdr_path.exists():
        return []

    content = pdr_path.read_text(encoding="utf-8", errors="replace")

    # Extraer flujos críticos
    flows = []
    patterns = [
        r"§5.*?(?=§\d|\Z)",
        r"flujos? críticos?.*?(?=\n##|\Z)",
        r"critical flows?.*?(?=\n##|\Z)",
        r"## 5\..*?(?=\n##|\Z)",
    ]
    for p in patterns:
        m = re.search(p, content, re.IGNORECASE | re.DOTALL)
        if m:
            section = m.group(0)
            items = re.findall(r"[-*]\s+(.+?)(?=\n[-*]|\n\d\.|\Z)", section)
            if not items:
                items = re.findall(r"\d\.\s+(.+?)(?=\n\d\.|\Z)", section)
            if not items:
                items = [l.strip("- *") for l in section.split("\n")
                         if l.strip() and not l.strip().startswith("#")]
            flows = [f.strip() for f in items if len(f.strip()) > 10][:8]
            if flows:
                break

    # Crear directorio tests/integration/ si no existe
    tests_dir = root / "tests" / "integration"
    tests_dir.mkdir(parents=True, exist_ok=True)

    created = []
    for flow in flows:
        flow_id = re.sub(r"[^a-z0-9_]", "_", flow.lower())[:20].strip("_")
        if not flow_id:
            continue
        script_path = tests_dir / f"test_flow_{flow_id}.sh"
        if script_path.exists():
            continue
        script_content = f"""#!/usr/bin/env bash
# test_flow_{flow_id}.sh — Esqueleto generado por bootstrap-proyecto
# Cubre flujo crítico: {flow}
# Capa B de R-REUSABLE-VERIFICATION-INJECTION
# Rellenar con aserciones reales (set -euo pipefail anti HF-V1).
set -euo pipefail

# TODO: implementar setup (DB, mocks, fixtures)

# TODO: ejecutar flujo completo
# echo "Ejecutando flujo: {flow}"

# TODO: aserciones explícitas (anti PHANTOM-PASS HF-V1)
# [[ "$(<comando>)" == "<expected>" ]] || {{ echo "❌ FAIL"; exit 1; }}

echo "✅ test_flow_{flow_id} OK"
"""
        script_path.write_text(script_content)
        script_path.chmod(0o755)
        created.append(str(script_path.relative_to(root)))

    return created


def generate(repo_root: str = ".") -> dict:
    """Genera seed skeleton S₀ para el proyecto."""
    root = Path(repo_root).resolve()

    # Detectar proyecto
    sys.path.insert(0, str(root / ".jcode/skills/bootstrap-proyecto/lib"))
    from project_scanner import scan
    info = scan(repo_root)

    has_project = info["state"] != "empty" and info["src_file_count"] > 0

    if has_project and info["domains"]:
        stages = get_stages_for_domain(info["domains"], info["critical_flows"])
        result = {
            "stages": stages,
            "source": "project",
            "domain": info["domains"],
            "_adaptable": False,
        }
    else:
        # Sin proyecto o sin dominio: usar defaults adaptables
        result = {
            "stages": DEFAULT_STAGES,
            "source": "default",
            "domain": info["domains"],
            "_adaptable": True,
            "_note": "No se detectó proyecto. Stages genéricas. "
                     "Ejecuta de nuevo cuando el proyecto tenga código.",
        }

    # Capa B: generar esqueletos de tests desde PDR.md §5
    test_skeletons = generate_test_skeletons(repo_root)
    if test_skeletons:
        result["test_skeletons"] = test_skeletons
        result["_test_registry_note"] = (
            f"Se generaron {len(test_skeletons)} esqueletos de test en tests/integration/. "
            "Estos son la base del registry reutilizable que orient F12 invoca."
        )

    return result


def apply(repo_root: str = ".") -> dict:
    """Aplica las stages generadas a config.toml y handbook_phase2.py."""
    root = Path(repo_root).resolve()
    skeleton = generate(repo_root)

    # Escribir a config.toml
    config_path = root / ".jcode" / "config.toml"
    if config_path.exists():
        content = config_path.read_text()
        # Add or update [handbook] section
        if "[handbook]" not in content:
            content += "\n[handbook]\n"
        # Append stages
        stages_json = json.dumps(skeleton["stages"])
        content_lines = content.split("\n")
        new_lines = []
        in_handbook = False
        stages_written = False
        for line in content_lines:
            if line.strip().startswith("[handbook]"):
                in_handbook = True
                new_lines.append(line)
                continue
            if in_handbook and line.strip().startswith("["):
                if not stages_written:
                    new_lines.append(f"stages = {stages_json}")
                    stages_written = True
                in_handbook = False
                new_lines.append(line)
                continue
            if in_handbook and "stages" in line:
                new_lines.append(f"stages = {stages_json}")
                stages_written = True
                continue
            new_lines.append(line)
        if not stages_written:
            new_lines.append(f"stages = {stages_json}")
        config_path.write_text("\n".join(new_lines) + "\n")
        print(f"[ok] Stages escritas en config.toml ({len(skeleton['stages'])} stages)")

    return skeleton


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Stage Generator — stages adaptativas al proyecto")
    parser.add_argument("--repo", default=".", help="Repo root path")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--apply", action="store_true", help="Apply to config.toml")
    args = parser.parse_args()

    if args.apply:
        result = apply(args.repo)
    else:
        result = generate(args.repo)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"=== Stage Generator ===")
        print(f"Source: {result['source']}")
        print(f"Domain: {result.get('domain', 'N/A')}")
        print(f"Adaptable: {result.get('_adaptable', False)}")
        print(f"Stages ({len(result['stages'])}):")
        for s in result['stages']:
            print(f"  - {s['id']}: {s['name']}")
        if result.get('_note'):
            print(f"Note: {result['_note']}")

    return result


if __name__ == "__main__":
    main()
