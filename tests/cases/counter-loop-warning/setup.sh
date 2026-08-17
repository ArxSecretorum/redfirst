# grep предупреждает в stderr, но выходит кодом не больше единицы: поиск
# формально удался, а часть дерева не прочитана. Отсутствие не подтверждено.
# Ветка отделена от «ОШИБКА ПОИСКА» именно этим — там статус больше единицы.
#
# Замерено 2026-08-17 на Raspberry Pi OS, GNU grep 3.11:
#   нечитаемый каталог -> статус 2 (ловит ветка выше)
#   петля симлинков    -> статус 0, stderr «recursive directory loop»
mkdir -p src sub
printf '{}\n' > package.json
printf 'export function Any(){}\n' > src/a.js
ln -s .. sub/loop 2>/dev/null
if [ ! -L sub/loop ]; then
    echo "символические ссылки здесь не создаются — петлю не построить"
    exit 77
fi
if ! grep -RnE zzzProbeTerm . 2>&1 >/dev/null | grep -q "recursive directory loop"; then
    echo "grep не предупреждает о петле — ветку не воспроизвести"
    exit 77
fi
