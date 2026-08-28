# counter утверждает ОТСУТСТВИЕ. Если поиск не смог пройти по всему дереву,
# отсутствие не подтверждено — и это единственная ветка, где ошибка поиска
# отделена от честного нуля. Условие проверяется, а не предполагается.
mkdir -p src closed
printf '{}\n' > package.json
printf 'export function Any(){}\n' > src/a.js
printf 'secret-value\n' > closed/hidden.js
chmod 000 closed 2>/dev/null
if ls closed >/dev/null 2>&1; then
    echo "chmod 000 has no effect on a directory - the search error cannot be reproduced"
    exit 77
fi
