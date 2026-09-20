#!/usr/bin/env bash
# Script local — NE PAS committer (déjà dans .gitignore).
# Usage : ./run_dev.sh [device]
#   device = chrome   → lance sur Chrome (web)  [défaut]
#   device = android  → lance sur Android (émulateur ou device connecté)
#   device = ios      → lance sur iOS (si disponible)
#
# Exemples :
#   ./run_dev.sh
#   ./run_dev.sh android
#   ./run_dev.sh ios

set -euo pipefail

DEVICE="${1:-chrome}"

DART_DEFINES=(
  --dart-define=SUPABASE_URL=https://lmabxhlwgynujhfrjwqm.supabase.co
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_byrAlN288EeOpRzTmVVimQ_NUgLXWSB
  --dart-define=TRAINER_ACCESS_CODE=change_moi_2026
)

case "$DEVICE" in
  chrome)
    flutter run -d chrome --web-port=9090 "${DART_DEFINES[@]}"
    ;;
  android)
    flutter run -d android "${DART_DEFINES[@]}"
    ;;
  ios)
    flutter run -d ios "${DART_DEFINES[@]}"
    ;;
  *)
    echo "Usage: ./run_dev.sh [chrome|android|ios]"
    exit 1
    ;;
esac



