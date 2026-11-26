#!/usr/bin/env bash
OUT="bar-context.txt"
: > "$OUT"

full() {
  echo "=================== $1 ===================" >> "$OUT"
  if [ -f "$1" ]; then cat "$1" >> "$OUT"; else echo "!! FICHIER INTROUVABLE" >> "$OUT"; fi
  echo >> "$OUT"
}

props() {
  echo "=================== $1 (propriétés / signaux / fonctions) ===================" >> "$OUT"
  if [ -f "$1" ]; then
    grep -nE '^\s*(default |readonly |required )*property |^\s*signal |^\s*function |^\s*id:' "$1" >> "$OUT"
  else echo "!! FICHIER INTROUVABLE" >> "$OUT"; fi
  echo >> "$OUT"
}

# Fichiers complets (petits)
full components/action/BarButton.qml
full components/tooltip/ConnectivityTooltip.qml
full components/tooltip/BatteryTooltip.qml
full components/info/PopupTooltip.qml
full panels/controls/MoreMenu.qml
full shell.qml

# Fichiers volumineux : uniquement l'interface publique
props panels/controls/ControlCenter/Controller.qml
props panels/services/WeatherService.qml

# Usages à connaître avant de déplacer / renommer
echo "=================== Usages de barRoot / hostBar ===================" >> "$OUT"
grep -rn "hostBar\|barRoot" --include=*.qml . | grep -v "panels/shell/Bar.qml" >> "$OUT"
echo >> "$OUT"

echo "=================== Usages de Calandar ===================" >> "$OUT"
grep -rn "Calandar" --include=*.qml --include=*.jsonc --include=*.sh --include=*.md . >> "$OUT"
echo >> "$OUT"

echo "=================== Usages de Bar { (instanciation) ===================" >> "$OUT"
grep -rnE '\bBar\s*\{' --include=*.qml . >> "$OUT"
echo >> "$OUT"

echo "=================== Imports de la Bar actuelle ===================" >> "$OUT"
grep -rn "panels/shell\|\"../shell\"\|/shell\"" --include=*.qml . >> "$OUT"

echo "OK -> $OUT ($(wc -l < "$OUT") lignes, $(wc -c < "$OUT") octets)"
