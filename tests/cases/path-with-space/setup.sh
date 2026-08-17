# Блокер 3: список найденных файлов раскрывается без кавычек, поэтому путь с
# пробелом распадается на два несуществующих. Правда: Widget жив, два вызова.
mkdir -p "my src"
printf '{}\n' > package.json
printf 'export function Widget() { return 1 }\n' > "my src/a.js"
printf 'import { Widget } from "./a.js"\nWidget()\nWidget()\n' > "my src/b.js"
