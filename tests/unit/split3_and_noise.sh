#!/bin/sh
# split3 — разбор строки реестра без единого форка (замена cut+trim, которые
# стоили девяти процессов на строку и сорока семи секунд на двухстах активах).
# is_noise — что считать тестом и сборочным мусором.
set -u
. "$TOOL"

fails=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }

split_is() {
    split3 "$1"
    if [ "$_f1" = "$2" ] && [ "$_f2" = "$3" ] && [ "$_f3" = "$4" ]; then
        ok "split3 «$1»"
    else
        bad "split3 «$1»: [$_f1][$_f2][$_f3], ожидалось [$2][$3][$4]"
    fi
}

split_is 'A|B|C'                     A B C
split_is ' A | B | C '               A B C
split_is 'Ключ подписи | never | 90' 'Ключ подписи' never 90
split_is 'A|B|C|D|E'                 A B C          # лишние поля отбрасываются
split_is 'A|B'                       A B ''
split_is 'A'                         A '' ''
split_is ''                          '' '' ''
split_is '|B|C'                      '' B C         # ведущий разделитель: имя пустое
split_is 'A||C'                      A '' C
split_is '  Ключ #1  | never | 90'   'Ключ #1' never 90

# Табы обрезаются наравне с пробелами: реестр правят в разных редакторах.
split_is "$(printf 'A\t|\tB\t|\tC')" A B C

noise_yes() { if is_noise "$1"; then ok "шум: $1"; else bad "$1 обязан быть шумом"; fi; }
noise_no()  { if is_noise "$1"; then bad "$1 НЕ шум, а отброшен"; else ok "боевой: $1"; fi; }

noise_yes ./src/test/kotlin/A.kt
noise_yes ./src/androidTest/kotlin/A.kt
noise_yes ./src/jvmTest/kotlin/A.kt
noise_yes ./app/FooTest.kt
noise_yes ./app/FooTests.kt
noise_yes ./app/foo_test.go
noise_yes ./app/foo.spec.ts
noise_yes ./pkg/test_thing.py
noise_yes ./pkg/conftest.py
noise_yes ./build/generated/A.kt
noise_yes ./node_modules/x/index.js
noise_yes ./target/debug/a.rs
noise_yes ./bin/Debug/app.cs
noise_yes ./app/PaymentIT.java

# Ложные срабатывания, стоившие боевых файлов.
noise_no ./app/AUDIT.java
noise_no ./app/COMMIT.java
noise_no ./app/EXIT.java
noise_no ./app/SPLIT.java
noise_no ./src/bin/cli.rs          # Cargo: src/bin — поставляемые бинари
noise_no ./bin/cli.js              # node: bin/cli.js — точка входа пакета
noise_no ./src/main/kotlin/A.kt
noise_no ./pkg/latest.py

[ "$fails" = 0 ] || { printf 'split3/is_noise: провалов %s\n' "$fails"; exit 1; }
exit 0
