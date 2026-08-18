# Заменитель компилятора: падает, если файл с классом, на который ссылается
# любой файл дерева, отсутствует.
#
# Граница слова обязательна: без неё `orphanTest()` давало ссылку на `Test`.
#
# После ошибки печатается подвал — как это делает gradle. Из-за него последние
# строки вывода бесполезны: у настоящей сборки там «Run with --stacktrace»,
# а причина стоит выше. Случай removable-shows-error держит это.
fail=0
for c in $(cat *.kt 2>/dev/null | grep -oE '(^|[^A-Za-z0-9_])[A-Z][A-Za-z0-9_]*\(\)' \
           | sed 's/^[^A-Za-z0-9_]*//' | tr -d '()' | sort -u); do
    if [ ! -f "$c.kt" ]; then
        echo "error: unresolved reference: $c"
        fail=1
    fi
done
if [ "$fail" = 1 ]; then
    echo "* Try:"
    echo "> Run with --stacktrace option to get the stack trace."
    echo "> Run with --info or --debug option to get more log output."
    echo "> Run with --scan to get full insights."
    echo "> Get more help at https://help.gradle.org."
    echo ""
    echo "BUILD FAILED in 3s"
    echo "434 actionable tasks: 2 executed, 432 up-to-date"
    exit 1
fi
echo "BUILD OK"
