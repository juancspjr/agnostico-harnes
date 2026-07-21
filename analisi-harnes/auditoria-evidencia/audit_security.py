"""
audit_security.py — Tests de seguridad independientes del harness.
Ejecuta PoC de los hallazgos de FASE C del reporte de auditoría.

Uso:
  python3 analisi-harnes/auditoria-evidencia/audit_security.py
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path("/home/juan/proyectos/proyecto-01")


def test_C4_builder_corrupts_with_invalid_path():
    """C-4: handbook_builder.py --repo /invalid/path corrompe program_graph.json"""
    print("\n[C-4] Test: builder con path inválido")
    print("-" * 60)

    # Backup
    pg = REPO / ".jcode/handbook/program_graph.json"
    backup = Path("/tmp/pg_backup_test.json")
    backup.write_bytes(pg.read_bytes())
    n_before = len(json.loads(pg.read_text())["functions"])
    print(f"  Antes: {n_before} funciones")

    # Execute with invalid path
    result = subprocess.run(
        ["python3", str(REPO / ".jcode/lib/handbook_builder.py"),
         "--repo", "/nonexistent/totally/fake/path"],
        cwd=str(REPO), capture_output=True, text=True
    )

    n_after = len(json.loads(pg.read_text())["functions"])
    print(f"  Después: {n_after} funciones")
    print(f"  Exit code: {result.returncode}")

    if n_after == 0:
        print(f"  ❌ CRITICAL: builder corrompió program_graph.json con 0 funciones")
        verdict = "FAIL"
    else:
        verdict = "PASS"

    # Restore
    pg.write_bytes(backup.read_bytes())
    print(f"  (PG restaurado)")
    return verdict == "FAIL"


def test_H4_resync_without_rebuild():
    """H-4: resync sin rebuild previo retorna no_op aún con cambios"""
    print("\n[H-4] Test: resync sin Phase I no detecta cambios")
    print("-" * 60)

    cfg = REPO / ".jcode/lib/_config_parse.py"
    backup = Path("/tmp/_cfg_backup.py")
    backup.write_bytes(cfg.read_bytes())

    # Renombrar parse_toml
    content = cfg.read_text()
    new_content = content.replace("def parse_toml(", "def parse_toml_renamed(")
    cfg.write_text(new_content)

    try:
        result = subprocess.run(
            ["python3", str(REPO / ".jcode/lib/handbook_resync.py"), "--auto"],
            cwd=str(REPO), capture_output=True, text=True
        )
        print(f"  Output: {result.stdout.strip()[:150]}")
        if "no_op" in result.stdout:
            print(f"  ❌ HIGH: resync retornó no_op pese a cambio en código")
            verdict = "FAIL"
        else:
            verdict = "PASS"
    finally:
        cfg.write_bytes(backup.read_bytes())

    return verdict == "FAIL"


def test_C2_stub_mode_permanent():
    """C-2: Phase II usa siempre classify_function_stub, no LLM real"""
    print("\n[C-2] Test: Phase II no integra LLM real")
    print("-" * 60)

    phase2 = (REPO / ".jcode/lib/handbook_phase2.py").read_text()

    # Buscar indicadores de LLM integration
    has_llm_call = any(k in phase2.lower() for k in
                       ["openai.", "anthropic.", "litellm.", "z-ai", "z_ai",
                        "client.chat", "llm("])
    has_stub = "classify_function_stub" in phase2

    print(f"  Tiene classify_function_stub: {has_stub}")
    print(f"  Tiene llamada a LLM real: {has_llm_call}")

    if has_stub and not has_llm_call:
        print(f"  ❌ CRITICAL: solo modo stub implementado")
        return True
    return False


def test_H5_no_locking():
    """H-5: handbook_resync.py no usa locks"""
    print("\n[H-5] Test: race condition entre resyncs")
    print("-" * 60)

    resync = (REPO / ".jcode/lib/handbook_resync.py").read_text()

    has_lock = any(k in resync for k in ["fcntl", "flock", "threading.Lock", "Lock("])

    print(f"  Usa locks: {has_lock}")

    if not has_lock:
        print(f"  ❌ HIGH: race condition posible en save_json()")
        return True
    return False


def test_H1_empty_source_hash():
    """H-1: source_hash vacío en L3 entries"""
    print("\n[H-1] Test: source_hash vacío")
    print("-" * 60)

    cb = json.loads((REPO / ".jcode/handbook/cache_B.json").read_text())
    entries = cb["l3_entries"]
    empty = sum(1 for e in entries.values() if not e.get("source_hash"))

    print(f"  L3 entries con source_hash vacío: {empty}/{len(entries)}")

    if empty == len(entries) and len(entries) > 0:
        print(f"  ❌ HIGH: source_hash nunca se calcula")
        return True
    return False


def test_C1_circularity_broken():
    """C-1: handbook no escanea todos los scripts del harness"""
    print("\n[C-1] Test: circularidad handbook→código")
    print("-" * 60)

    pg = json.loads((REPO / ".jcode/handbook/program_graph.json").read_text())
    files = set(f["file"] for f in pg["functions"])

    expected = {
        ".jcode/lib/_config_parse.py",
        ".jcode/lib/handbook_builder.py",
        ".jcode/lib/handbook_phase2.py",
        ".jcode/lib/handbook_phase3.py",
        ".jcode/lib/handbook_resync.py",
        ".jcode/lib/handbook_verify.py",
    }
    missing = expected - files

    print(f"  Archivos del harness en PG: {len(expected & files)}/{len(expected)}")
    if missing:
        print(f"  ❌ Archivos NO escaneados: {missing}")
        print(f"  CRITICAL: circularidad rota")
        return True
    return False


def main():
    print(f"=== Tests de seguridad independientes ({REPO}) ===\n")
    results = []

    tests = [
        ("C-1", test_C1_circularity_broken),
        ("C-2", test_C2_stub_mode_permanent),
        ("C-4", test_C4_builder_corrupts_with_invalid_path),
        ("H-1", test_H1_empty_source_hash),
        ("H-4", test_H4_resync_without_rebuild),
        ("H-5", test_H5_no_locking),
    ]

    for label, fn in tests:
        try:
            failed = fn()
            results.append((label, "CRITICAL" if "C-" in label else "HIGH", failed))
        except Exception as e:
            print(f"  ⚠️  Test {label} errored: {e}")
            results.append((label, "?", False))

    print("\n" + "=" * 60)
    print("RESUMEN DE TESTS DE SEGURIDAD")
    print("=" * 60)
    n_crit = sum(1 for _, s, f in results if f and s == "CRITICAL")
    n_high = sum(1 for _, s, f in results if f and s == "HIGH")
    print(f"  CRITICAL fallan: {n_crit}")
    print(f"  HIGH fallan:     {n_high}")
    print(f"  Total hallazgos confirmados: {n_crit + n_high}")
    return 0 if (n_crit + n_high) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
