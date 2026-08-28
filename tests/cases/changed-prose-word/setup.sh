# Оговорка Д1: слово, живущее только в комментариях, переживает оба отсева.
#
# Отсеиваются имя, встречающееся один раз (упоминание, не вещь), и имя в трёх
# файлах и более (заведомо подключено). Английское слово из комментария часто
# не подходит ни под то, ни под другое: встречается дважды, в двух файлах — и
# попадает в список наравне с настоящим символом.
#
# На первом прогоне на живом коммите таких было больше половины: unverifiable,
# accumulates, anyone. Человек, ради которого команда написана, отличить их от
# имён не может — он потому и спрашивает.
if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed - no comparison base can be built"
    exit 77
fi
printf 'rootProject.name = "probe"\n' > settings.gradle.kts
printf '// zzzgoneword described this in prose\nclass Base {\n    fun zzzGoneCall() = 1\n}\n' > Base.kt
git init -q . >/dev/null 2>&1 || { echo "git init did not work"; exit 77; }
git -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -c user.email=t@t -c user.name=t commit -q -m base >/dev/null 2>&1 \
    || { echo "the base commit was not made"; exit 77; }

# Изменение. Появилось: настоящий символ в коде и слово, живущее только в прозе.
# Исчезло: настоящий символ и слово, жившее только в комментарии базы.
printf 'class Base {\n    fun b() = 1\n}\n' > Base.kt
printf '// zzzproseword explains what this class is for\nclass ZzzWidget {\n    fun go() = 1\n}\n' > A.kt
printf '// zzzproseword again, still only prose\nclass ZzzUser {\n    fun use() = ZzzWidget().go()\n}\n' > B.kt
