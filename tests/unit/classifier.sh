#!/bin/sh
# Классификатор — один проход слева направо с переносом состояния между
# строками. Самая сложная часть инструмента и до 2026-08-17 самая непроверяемая:
# программа была зашита строкой внутри cmd_wired, и каждое утверждение стоило
# полного запуска — полторы секунды и провал, приходящий косвенно, вердиктом
# вместо корзины.
#
# Здесь она вызывается напрямую. Проверяется ровно одно: в какую корзину падает
# строка — code (настоящее использование), text (строка или комментарий),
# imp (импорт, использованием не считается).
set -u
. "$TOOL"

fails=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }

BOX=$(mktemp -d "${TMPDIR:-/tmp}/rf-cls.XXXXXX") || exit 1
# `cleanup` — уборка подключённого инструмента. Своя ловушка ставится ПОСЛЕ
# `. "$TOOL"` и затирает его собственную; пока инструмент заводил временный
# каталог и в библиотечном режиме, это оставляло по каталогу на каждый прогон.
# Корень вылечен там же, в инструменте, но цепочка здесь остаётся: скрипт,
# перехватывающий EXIT после подключения чужого кода, обязан позвать и его.
trap 'rm -rf "$BOX"; cleanup' EXIT INT TERM

# Содержимое приходит на stdin, корзины уходят строкой "code=N text=N".
run_cls() {
    _f="$BOX/$1"
    cat > "$_f"
    RF_SYM=$(bound "$(esc_ere "$2")") RF_IMP="$import_re" RF_NOSTRIP=0 \
    RF_DQ='"' RF_SQ=$(printf '\47') RF_BT='`' \
    awk "$CLASSIFIER" "$_f" | cut -f1 | sort | uniq -c | awk '{printf "%s=%s ", $2, $1}'
}

is() {   # $1 описание, $2 файл, $3 символ, $4 ожидаемое; содержимое на stdin
    got=$(run_cls "$2" "$3")
    got=${got% }
    if [ "$got" = "$4" ]; then ok "$1"; else bad "$1: [$got], ожидалось [$4]"; fi
}

# ── строки ───────────────────────────────────────────────────────────────────

is 'экранированная кавычка не закрывает строку' U.kt Zed 'text=1' <<'EOF'
val s = "text \" Zed still inside the string"
EOF

is 'строка и код в одной строке' U.kt Zed 'code=1' <<'EOF'
val a = "not here"; val b = Zed()
EOF

is 'тройная кавычка открыта и закрыта на одной строке' U.kt Zed 'text=1' <<'EOF'
val s = """Zed"""
EOF

is 'raw-строка Kotlin на несколько строк' U.kt Zed 'text=1' <<'EOF'
val s = """
    Zed was removed
"""
EOF

is 'обратный апостроф спанит строки' u.js Zed 'text=1' <<'EOF'
const s = `line one
Zed inside template
`
EOF

is 'python: тройная одинарная кавычка' u.py Zed 'text=1' <<'EOF'
'''
Zed removed
'''
V = 1
EOF

is 'python: тройная двойная кавычка' u.py Zed 'text=1' <<'EOF'
"""
Zed removed
"""
V = 1
EOF

# Одиночная кавычка НЕ переносится на следующую строку: апостроф в прозе
# открывал строку, которая никогда не закрывалась, и гасил остаток файла.
is 'непарный апостроф в комментарии не гасит следующую строку' U.kt Zed 'code=1 text=1' <<'EOF'
// don't call Zed from here any more
val x = Zed()
EOF

# ── интерполяция ─────────────────────────────────────────────────────────────

is 'простая интерполяция — это код' U.kt Zed 'code=1' <<'EOF'
val s = "key=${store.Zed()}"
EOF

is 'вложенная интерполяция' U.kt Zed 'code=1' <<'EOF'
val s = "${map["${Zed.go()}"]}"
EOF

is 'интерполяция в многострочном шаблоне JS' u.js Zed 'code=1' <<'EOF'
const s = `line
${Zed()}
`
EOF

is 'незавершённая интерполяция не подвешивает разбор' U.kt Zed 'code=1' <<'EOF'
val s = "${Zed
EOF

# ── комментарии ──────────────────────────────────────────────────────────────

is 'блочный комментарий на несколько строк' U.kt Zed 'text=1' <<'EOF'
/*
 Zed is gone
*/
val v = 1
EOF

is 'код после закрытого блочного комментария в той же строке' U.kt Zed 'code=1' <<'EOF'
/* note */ val x = Zed()
EOF

is 'хвостовой комментарий не съедает код перед собой' U.kt Zed 'code=1' <<'EOF'
val x = Zed()  // about Zed
EOF

is 'решётка в .py — комментарий' u.py Zed 'text=1' <<'EOF'
# Zed removed
V = 1
EOF

is 'решётка внутри строки .py — не комментарий' u.py Zed 'code=1' <<'EOF'
URL = "http://example/#anchor"
V = Zed()
EOF

is 'двойной дефис — комментарий в .sql' u.sql Zed 'text=1' <<'EOF'
-- Zed removed
SELECT 1;
EOF

is 'решётка в .kt комментарием НЕ является' U.kt Zed 'code=1' <<'EOF'
val h = 1 # Zed()
EOF

# ── heredoc ──────────────────────────────────────────────────────────────────

is 'heredoc: тело не код' u.sh Zed 'text=1' <<'EOF'
usage() {
cat <<TXT
Zed is no longer available
TXT
}
EOF

is 'heredoc с дефисом и отступом терминатора' u.sh Zed 'text=1' <<'EOF'
f() {
	cat <<-TXT
	Zed is gone
	TXT
}
EOF

is 'heredoc в кавычках' u.sh Zed 'text=1' <<'EOF'
f() {
cat <<'TXT'
Zed is gone
TXT
}
EOF

is 'после терминатора heredoc снова код' u.sh Zed 'code=1 text=1' <<'EOF'
cat <<TXT
Zed mentioned
TXT
Zed
EOF

is 'сдвиг << в не-shell не открывает heredoc' U.kt Zed 'code=1' <<'EOF'
val mask = 1 << 4
val x = Zed()
EOF

# ── импорты ──────────────────────────────────────────────────────────────────

is 'импорт не считается использованием' u.js Zed 'imp=1' <<'EOF'
import { Zed } from './x'
EOF

is 'импорт и настоящий вызов различаются' u.js Zed 'code=1 imp=1' <<'EOF'
import { Zed } from './x'
Zed()
EOF

[ "$fails" = 0 ] || { printf 'classifier: провалов %s\n' "$fails"; exit 1; }
exit 0
