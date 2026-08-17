# Имя есть в двух файлах, но в обоих — только внутри строк. В коде его нет
# нигде. Правда: мёртв, и это отдельный четвёртый исход.
mkdir -p src/main/kotlin
printf 'rootProject.name = "probe"\n' > settings.gradle.kts
printf 'object Notes {\n    val a = "LegacyExport is gone"\n}\n' > src/main/kotlin/Notes.kt
printf 'object More {\n    val b = "see LegacyExport in the changelog"\n}\n' > src/main/kotlin/More.kt
