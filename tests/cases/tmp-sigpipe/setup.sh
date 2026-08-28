# Инструмент создаёт временный каталог первой же строкой и удаляет его ловушкой
# на EXIT INT TERM. SIGPIPE в этот список не входит — а он приходит всякий раз,
# когда вывод обрывают: `redfirst counter … | head -1`, `… | grep -q`.
#
# Найдено 2026-08-17 на целевой машине: восемь пустых каталогов /tmp/redfirst.*,
# ровно по два на каждый из четырёх ночных прогонов. Ровно та же болезнь, что
# уже была у набора и была у него вылечена, — только теперь у самого продукта,
# и на чужой машине, которую он засоряет молча.
#
# Условие случая — среда, где обрыв канала действительно убивает писателя.
# Проверяется, а не угадывается по имени платформы: писатель печатает строку,
# ждёт, пока читатель уйдёт, печатает вторую и отмечает, что дошёл до конца.
# Дошёл — значит SIGPIPE здесь не работает и проверять нечего.
rm -f reached_end
sh -c 'echo one; sleep 1; echo two; : > reached_end' 2>/dev/null | head -n 1 >/dev/null
sleep 1
if [ -f reached_end ]; then
    echo "a broken pipe does not kill the writer here - SIGPIPE cannot be reproduced"
    rm -f reached_end
    exit 77
fi
printf 'rootProject.name = "probe"\n' > settings.gradle.kts
printf 'class Live {\n    fun run() = 1\n}\n' > Live.kt
