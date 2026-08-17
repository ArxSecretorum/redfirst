#!/bin/sh
# Обещания прозы против кода.
#
# Д2 сделал проверяемыми примеры вывода, а числа стали сверяться после того, как
# в DEBTS нашлось «890 строк» при 1088. Осталась проза — и за сутки 2026-08-17
# она дала пять расхождений подряд:
#
#   * «установщик предлагает кандидатов и задаёт два вопроса» — `read` в нём ноль;
#   * «полным набор бывает только на Linux» — на Linux он тоже неполон;
#   * «stdout показывается при коде 0» — показывается МОДЕЛИ, не человеку;
#   * «README.en.md ждёт решения» — файл удалён тремя коммитами раньше;
#   * «everything executable is one file» — исполняемых файлов три.
#
# Последнее стояло в разделе про безопасность, то есть ровно там, где человек
# решает, пускать ли к себе session-хук. Хуже места для неточности нет.
#
# Механизм тот же, что у якорей вывода и у чисел, и разница только в том, чем
# кончается проверка: у обещания есть ИМЯ, а у имени — проверяльщик.
#
#     <!-- redfirst-claim: no-network -->
#     - no network, no dependencies, no self-update;
#
# Связь двусторонняя: имя без проверяльщика — провал (обещание, которое никто не
# держит), проверяльщик без имени в документах — тоже (проверка, которая ничего
# не сторожит). Без второй половины достаточно было бы удалить строку из README,
# и проверка молча замолчала бы вместе с ней.
set -u

LC_ALL=C; export LC_ALL

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT="$HERE/../.."

KNOWN='installer-asks-nothing no-network one-file-runs-itself
installer-keeps-your-settings registry-holds-no-paths'

fails=0
seen=''
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }

# Каждый проверяльщик печатает, ЧТО он посчитал, а не только вердикт: число без
# того, что за ним стоит, — это ровно то, против чего написан весь инструмент.
verify() {
    case $1 in
        installer-asks-nothing)
            _n=$(grep -cE '(^|[;&|[:space:]])read([[:space:]]|$)' "$ROOT/install.sh" || true)
            [ "$_n" = 0 ] && { ok "installer-asks-nothing: обращений к read в install.sh $_n"; return 0; }
            bad "installer-asks-nothing: в install.sh $_n обращений к read — он спрашивает"; return 1 ;;
        no-network)
            _n=$(cat "$ROOT/bin/redfirst" "$ROOT/install.sh" \
                 | grep -cE 'curl|wget|netcat|[^[:alnum:]]nc[[:space:]]|https?://|ftp://' || true)
            [ "$_n" = 0 ] && { ok "no-network: сетевых обращений в двух скриптах $_n"; return 0; }
            bad "no-network: нашлось $_n мест, похожих на сеть"; return 1 ;;
        one-file-runs-itself)
            _n=$(ls -1 "$ROOT/bin" 2>/dev/null | grep -c . || true)
            if [ "$_n" != 1 ]; then
                bad "one-file-runs-itself: в bin/ файлов $_n, а обещан один"; return 1
            fi
            if grep -q '^HOOK_CMD=.*\$BIN' "$ROOT/install.sh"; then
                ok "one-file-runs-itself: в bin/ один файл, и хук зовёт именно его"; return 0
            fi
            bad "one-file-runs-itself: команда хука ссылается не на bin/redfirst"; return 1 ;;
        installer-keeps-your-settings)
            # Обещание держит случай набора, а не отдельная проверка: он гоняет
            # установщик на чужом settings.json и смотрит получившийся файл.
            if grep -q '^install-keeps-foreign' "$ROOT/tests/cases/install.cases"; then
                ok "installer-keeps-your-settings: держится случаем install-keeps-foreign"; return 0
            fi
            bad "installer-keeps-your-settings: случая install-keeps-foreign больше нет"; return 1 ;;
        registry-holds-no-paths)
            _n=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$ROOT/templates/irreplaceable" \
                 | grep -c '[/\\]' || true)
            [ "$_n" = 0 ] && { ok "registry-holds-no-paths: строк с путями в шаблоне $_n"; return 0; }
            bad "registry-holds-no-paths: в шаблоне $_n строк с путями"; return 1 ;;
        *)
            bad "$1: обещание с таким именем никто не проверяет"; return 1 ;;
    esac
}

scan_doc() {
    [ -f "$1" ] || return 0
    while IFS= read -r _l || [ -n "$_l" ]; do
        case $_l in
            '<!-- redfirst-claim: '*' -->')
                _c=${_l#<!-- redfirst-claim: }; _c=${_c% -->}
                seen="$seen $_c"
                verify "$_c" || true ;;
        esac
    done < "$1"
}

scan_doc "$ROOT/README.md"
scan_doc "$ROOT/docs/DEBTS.md"

# Вторая половина связи: проверяльщик, чьего имени нет ни в одном документе,
# ничего не сторожит. Удалить строку из README было бы достаточно, чтобы
# проверка замолчала вместе с ней и никто этого не заметил.
for k in $KNOWN; do
    case " $seen " in
        *" $k "*) ;;
        *) bad "$k: проверяльщик есть, а обещания в документах нет — он ничего не сторожит" ;;
    esac
done

[ "$fails" = 0 ] || { printf 'claims: провалов %s\n' "$fails"; exit 1; }
exit 0
