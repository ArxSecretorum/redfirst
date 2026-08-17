#!/bin/sh
# Числа в документах против фактов.
#
# Найдено 2026-08-17 при разборе долгов: `docs/DEBTS.md` объявлял «890 строк
# POSIX sh» при фактических 1088 — и был неверен уже в день, когда его писали.
# Там же в трёх местах стояли три разных числа проверок: 240 в шапке, 242 в Д7,
# 250 в таблице. README объявлял «121 случай — 250 проверок».
#
# Причина ровно та же, что у примеров вывода в Д2, и она же — премисса всего
# инструмента: УТВЕРЖДЕНИЕ, КОТОРОЕ МАШИНА НЕ МОЖЕТ УРОНИТЬ, НИКТО НЕ
# ПОДДЕРЖИВАЕТ. Пока число нельзя было сделать красным, оно и дрейфовало.
#
# Механизм тот же, что у якорей вывода: значение обязано существовать в двух
# местах сразу — в факте, посчитанном машиной, и в тексте документа.
#
#     <!-- redfirst-count: checks=286 breaks=6 -->
#     <текст, в котором обязаны встретиться оба числа>
#
# Число в якоре сверяется с фактом ТОЧНО, и только потом ищется в тексте.
# Первая редакция искала факт прямо в тексте — и первый же прогон показал, чего
# это стоит: «4 модульных» разошлось с фактом, а проверка прошла, потому что
# цифра 5 нашлась в соседнем «6,5 с». Совпадение цифры в блоке, полном чисел,
# — слишком дешёвое утверждение, чтобы на нём что-то держать.
#
# Якорь действует на следующий за ним блок: до пустой строки, а если сразу за
# якорём стоит ограда markdown — до её закрытия. Так под якорь попадает и
# таблица, и пример команды.
#
# Числа считает `tests/run --count` теми же правилами, что и прогон. Второй
# счётчик был бы вторым источником правды, и сверять пришлось бы уже его.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RUN="$HERE/../run"
ROOT="$HERE/../.."

fails=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }

[ -f "$RUN" ] || { bad "не найден $RUN"; exit 1; }
FACTS=$(sh "$RUN" --count 2>/dev/null) || { bad 'tests/run --count не отработал'; exit 1; }
[ -n "$FACTS" ] || { bad 'tests/run --count ничего не напечатал'; exit 1; }

# Ограда markdown — через переменную: прямая запись обратных кавычек внутри
# одинарных валила dash. Та же причина, что в readme.sh.
FENCE='`''`''`'

fact() { printf '%s\n' "$FACTS" | sed -n "s/^$1=//p"; }

# Число может стоять в тексте словом: «шесть точек слома», «at six points».
# Заставлять документ писать цифрами значило бы чинить текст под проверку,
# а не проверку под текст.
words_for() {
    case $1 in
        1)  printf 'one один одна одну' ;;
        2)  printf 'two два две' ;;
        3)  printf 'three три' ;;
        4)  printf 'four четыре' ;;
        5)  printf 'five пять' ;;
        6)  printf 'six шесть шести' ;;
        7)  printf 'seven семь' ;;
        8)  printf 'eight восемь' ;;
        9)  printf 'nine девять' ;;
        10) printf 'ten десять' ;;
        11) printf 'eleven одиннадцать' ;;
        12) printf 'twelve двенадцать' ;;
        *)  printf '' ;;
    esac
}

# Цифры — с границей по не-цифре, иначе 4 нашлась бы внутри 284.
in_text() {
    _val=$1; _txt=$2
    if printf '%s' "$_txt" | grep -qE "(^|[^0-9])$_val([^0-9]|$)"; then return 0; fi
    for _w in $(words_for "$_val"); do
        if printf '%s' "$_txt" | grep -qiF -- "$_w"; then return 0; fi
    done
    return 1
}

verify() {
    _doc=$1; _pairs=$2; _txt=$3
    _name=${_doc##*/}
    for _p in $_pairs; do
        _k=${_p%%=*}; _want=${_p#*=}
        if [ "$_k" = "$_p" ]; then
            bad "$_name: якорь «$_p» без числа — пишется как ключ=значение"
            continue
        fi
        _v=$(fact "$_k")
        if [ -z "$_v" ]; then
            bad "$_name: якорь ссылается на «$_k», которого нет среди фактов"
            continue
        fi
        if [ "$_want" != "$_v" ]; then
            bad "$_name: заявлено $_k=$_want, фактически $_v"
            continue
        fi
        if in_text "$_v" "$_txt"; then
            ok "$_name: $_k=$_v — и в якоре, и в тексте"
        else
            bad "$_name: $_k=$_v верно в якоре, но в самом тексте этого числа нет: $(printf '%s' "$_txt" | tr '\n' ' ' | cut -c1-70)"
        fi
    done
}

anchors=0
check_doc() {
    _d=$1
    [ -f "$_d" ] || { bad "нет документа $_d"; return; }
    _pairs=""; _coll=0; _fenced=0; _first=0; _buf=""
    while IFS= read -r _l || [ -n "$_l" ]; do
        case $_l in
            '<!-- redfirst-count: '*' -->')
                _pairs=${_l#<!-- redfirst-count: }; _pairs=${_pairs% -->}
                anchors=$((anchors + 1))
                _coll=1; _fenced=0; _first=1; _buf=""
                continue ;;
        esac
        [ "$_coll" = 1 ] || continue
        if [ "$_first" = 1 ]; then
            _first=0
            case $_l in
                "$FENCE"*) _fenced=1; continue ;;
            esac
        fi
        if [ "$_fenced" = 1 ]; then
            if [ "$_l" = "$FENCE" ]; then
                verify "$_d" "$_pairs" "$_buf"; _coll=0; continue
            fi
        else
            case $_l in
                '') verify "$_d" "$_pairs" "$_buf"; _coll=0; continue ;;
            esac
        fi
        _buf="$_buf
$_l"
    done < "$_d"
    [ "$_coll" = 0 ] || verify "$_d" "$_pairs" "$_buf"
}

check_doc "$ROOT/README.md"
check_doc "$ROOT/docs/DEBTS.md"

# Без этой проверки документ, из которого удалили все якоря, прошёл бы как
# безупречный — ровно та дыра, которую в Д2 закрывал счёт блоков.
if [ "$anchors" -lt 4 ]; then
    bad "якорей на числа всего $anchors — было четыре, кто-то их убрал"
else
    ok "якорей на числа: $anchors"
fi

[ "$fails" = 0 ] || { printf 'numbers: провалов %s\n' "$fails"; exit 1; }
exit 0
