# Контроль к предыдущему: апостроф в имени файла. Правда: Marker жив.
mkdir -p pkg
printf '{}\n' > package.json
printf 'export function Marker() { return 1 }\n' > "pkg/don't.js"
printf "import { Marker } from './x'\nMarker()\n" > pkg/use.js
