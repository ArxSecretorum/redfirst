# Исходник в CP1251: байты невалидны для UTF-8, а LC_ALL инструмент выставляет
# в C.UTF-8. Правда: Legacy жив.
mkdir -p src/main/kotlin
printf 'rootProject.name = "probe"\n' > settings.gradle.kts
printf 'object Legacy {\n    fun go() = 1\n}\n' > src/main/kotlin/Legacy.kt
printf '// \317\360\350\342\345\362 \357\356 CP1251\nval used = Legacy.go()\n' > src/main/kotlin/User.kt
