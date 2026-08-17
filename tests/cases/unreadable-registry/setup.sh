# Реестр существует, но не читается. Проверка условия обязательна: под Git Bash
# на Windows chmod 000 не действует, файл всё равно читается, и случай молча
# засчитался бы пройденным — ровно то ложное зелёное, против которого всё это.
mkdir -p .redfirst
printf 'Ключ | never | 30\n' > .redfirst/irreplaceable
chmod 000 .redfirst/irreplaceable 2>/dev/null
if cat .redfirst/irreplaceable >/dev/null 2>&1; then
    echo "chmod 000 не действует в этой среде — нечитаемый файл не создать"
    exit 77
fi
