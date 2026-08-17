# Блокер 2: strip_strings сбрасывает состояние кавычек на каждой строке, поэтому
# строки внутри многострочного литерала считаются кодом. Правда: ghostly мёртв —
# объявление плюс два упоминания в docstring.
mkdir -p pkg
printf '[project]\nname = "probe"\n' > pyproject.toml
printf 'def ghostly():\n    return 1\n' > pkg/dead.py
cat > pkg/notes.py <<'PY'
"""
Historical note about ghostly and why it was removed.
The name ghostly appears here on purpose, inside a docstring.
"""
VALUE = 1
PY
