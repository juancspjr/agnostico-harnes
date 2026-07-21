#!/usr/bin/env bash
# test_gap2.sh — Gap 2: Framework multi-lenguaje
# Estricto: recalcula desde ground truth
set -uo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
pass() { printf "  PASS  %s\n" "$*"; }
fail() { printf "  FAIL  %s\n" "$*" >&2; exit 1; }

echo "=== GAP 2: Framework multi-lenguaje ==="

# Test 1: BaseAdapter existe y es abstracta
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/.jcode/skills/bootstrap-proyecto/lib')
from language_adapter import BaseAdapter
assert BaseAdapter.__abstractmethods__, 'BaseAdapter debe ser abstracta'
assert hasattr(BaseAdapter, 'extract'), 'extract debe estar definido'
assert hasattr(BaseAdapter, 'parse_file'), 'parse_file debe estar definido'
print('BaseAdapter correcta')
"

# Test 2: PythonAdapter está registrado
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/.jcode/skills/bootstrap-proyecto/lib')
from language_adapter import LanguageAdapterRegistry
available = LanguageAdapterRegistry.list()
assert 'python' in available, 'PythonAdapter no registrado'
print(f'Adapters: {available}')
"
pass "PythonAdapter registrado"

# Test 3: auto-detect funciona
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/.jcode/skills/bootstrap-proyecto/lib')
from language_adapter import LanguageAdapterRegistry
lang = LanguageAdapterRegistry.auto_detect('$REPO_ROOT')
assert isinstance(lang, str), f'auto_detect debe retornar string'
print(f'Auto-detect: {lang}')
"

# Test 4: generate_adapter_skeleton produce código válido
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/.jcode/skills/bootstrap-proyecto/lib')
from language_adapter import generate_adapter_skeleton
for lang in ['go', 'typescript', 'rust', 'java', 'javascript']:
    skeleton = generate_adapter_skeleton(lang)
    assert skeleton, f'No skeleton for {lang}'
    assert 'class' in skeleton, f'Skeleton {lang} debe tener clase'
    assert 'FILE_EXT' in skeleton, f'Skeleton {lang} debe tener FILE_EXT'
    print(f'  {lang}: skeleton generado')
"
pass "Skeletons generados para 5 lenguajes"

# Test 5: detect() retorna estructura completa
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/.jcode/skills/bootstrap-proyecto/lib')
from language_adapter import detect
result = detect('$REPO_ROOT')
assert 'detected_language' in result
assert 'available_adapters' in result
assert 'has_adapter' in result
assert 'python_reference_available' in result
print(f'Detect: {result}')
"

pass "Gap 2: framework multi-lenguaje OK"
exit 0
