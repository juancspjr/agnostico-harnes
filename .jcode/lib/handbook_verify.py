#!/usr/bin/env python3
# =============================================================================
# .jcode/lib/handbook_verify.py — BGPD Source Verification (paper Appendix B.1)
# =============================================================================
# Paso 4 del workflow BGPD:
#   Resuelve locators del handbook contra el filesystem real.
#   Retiene solo los sites que siguen siendo relevantes al request q.
# Paper ref: arXiv:2607.13285v1 §3.3.1, Appendix B.1
# =============================================================================

import argparse
import json
import sys
from pathlib import Path


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)


def compute_relevance(request: str, behavior: str) -> float:
    """Heurística de token overlap entre request y behavior."""
    if not request or not behavior:
        return 0.0
    req_tokens = set(request.lower().split())
    beh_tokens = set(behavior.lower().split())
    if not req_tokens:
        return 0.0
    overlap = req_tokens & beh_tokens
    return len(overlap) / len(req_tokens) if req_tokens else 0.0


def verify_site(repo_root: Path, entry: dict) -> dict:
    """Verifica un L3 entry contra el filesystem."""
    file_path = entry.get("file", "")
    line_range = entry.get("line_range", [0, 0])
    qualname = entry.get("qualname", "")

    # Check file exists
    abs_file = repo_root / file_path
    if not abs_file.exists():
        return {
            "qualname": qualname,
            "status": "skipped_missing",
            "reason": "file_not_found",
        }

    # Check anchor in source (simple heuristic: qualname as substring)
    try:
        source = abs_file.read_text(encoding="utf-8", errors="replace")
        # Extract function name from qualname
        fname = qualname.split(".")[-1]
        if fname not in source:
            return {
                "qualname": qualname,
                "status": "skipped_missing",
                "reason": "anchor_not_found",
            }
        # Check line range validity
        lines = source.split("\n")
        if line_range[0] > len(lines):
            return {
                "qualname": qualname,
                "status": "skipped_missing",
                "reason": "line_out_of_range",
            }
    except Exception as e:
        return {
            "qualname": qualname,
            "status": "skipped_error",
            "reason": str(e),
        }

    return {
        "qualname": qualname,
        "status": "verified",
        "file": file_path,
        "line_range": line_range,
    }


def verify_handbook(repo_root: str = ".", request: str = "", stages: list = None) -> dict:
    """Ejecuta BGPD verification completa."""
    root = Path(repo_root).resolve()
    handbook_dir = root / ".jcode" / "handbook"
    cache_b = load_json(handbook_dir / "cache_B.json")
    frozen = load_json(handbook_dir / "frozen_entries.json")
    frozen_qualnames = {f.get("qualname") for f in frozen}

    l3_entries = cache_b.get("l3_entries", {})
    if not l3_entries:
        return {
            "summary": {"verified_count": 0, "skipped_missing": 0, "skipped_frozen": 0, "skipped_irrelevant": 0},
            "verified": [],
            "skipped_missing": [],
            "skipped_frozen": [],
            "skipped_irrelevant": [],
        }

    # Filter by stages if provided
    if stages:
        l3_entries = {
            qn: e for qn, e in l3_entries.items()
            if any(s in e.get("relations", {}).get("stages", []) for s in stages)
        }

    verified = []
    skipped_missing = []
    skipped_frozen = []
    skipped_irrelevant = []

    for qn, entry in l3_entries.items():
        # Frozen check
        if qn in frozen_qualnames:
            skipped_frozen.append({"qualname": qn, "reason": "frozen_entry"})
            continue

        # Relevance check
        relevance = compute_relevance(request, entry.get("behavior", ""))
        if request and relevance < 0.10:
            skipped_irrelevant.append({"qualname": qn, "relevance": relevance})
            continue

        # Verify against filesystem
        result = verify_site(root, entry)
        if result["status"] == "verified":
            result["relevance"] = relevance
            verified.append(result)
        else:
            skipped_missing.append(result)

    return {
        "summary": {
            "verified_count": len(verified),
            "skipped_missing": len(skipped_missing),
            "skipped_frozen": len(skipped_frozen),
            "skipped_irrelevant": len(skipped_irrelevant),
        },
        "verified": verified,
        "skipped_missing": skipped_missing,
        "skipped_frozen": skipped_frozen,
        "skipped_irrelevant": skipped_irrelevant,
    }


def main():
    parser = argparse.ArgumentParser(description="Handbook BGPD Source Verification")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--request", default="",
                        help="Request string for relevance check (token overlap)")
    parser.add_argument("--stages", nargs="*", default=[],
                        help="Filter by stage IDs")
    parser.add_argument("--output", default="json",
                        choices=["json", "summary"])
    args = parser.parse_args()

    result = verify_handbook(args.repo, args.request, args.stages or None)

    if args.output == "json":
        print(json.dumps(result, indent=2))
    else:
        s = result["summary"]
        print(f"verified={s['verified_count']} missing={s['skipped_missing']} "
              f"frozen={s['skipped_frozen']} irrelevant={s['skipped_irrelevant']}")

    return 0


if __name__ == "__main__":
    sys.exit(main())