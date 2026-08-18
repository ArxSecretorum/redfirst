# Заменитель компилятора: падает, если файл с классом, на который ссылается
# Main.kt, отсутствует. Настоящий gradle в наборе не нужен — проверяется не он,
# а поведение removable вокруг любой объявленной команды сборки.
for c in $(grep -oE '[A-Z][A-Za-z0-9_]*\(\)' Main.kt | tr -d '()'); do
    if [ ! -f "$c.kt" ]; then
        echo "error: unresolved reference: $c"
        exit 1
    fi
done
echo "BUILD OK"
