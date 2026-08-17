# Кириллица в имени каталога. Правда: Kirill жив.
mkdir -p "исходники"
printf '{}\n' > package.json
printf 'export function Kirill() { return 1 }\n' > "исходники/a.js"
printf 'Kirill()\n' > "исходники/b.js"
