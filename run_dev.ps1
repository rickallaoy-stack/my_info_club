# Script local — NE PAS committer (ajouté au .gitignore).
# Usage : .\run_dev.ps1 [-Device chrome|android|ios]
#
# Exemples :
#   .\run_dev.ps1              # Chrome (web)
#   .\run_dev.ps1 -Device android   # Android (émulateur ou device connecté)
#   .\run_dev.ps1 -Device ios       # iOS (si available)

param(
    [ValidateSet('chrome', 'android', 'ios')]
    [string]$Device = 'chrome'
)

$dartDefines = @(
    '--dart-define=SUPABASE_URL=https://lmabxhlwgynujhfrjwqm.supabase.co'
    '--dart-define=SUPABASE_ANON_KEY=sb_publishable_byrAlN288EeOpRzTmVVimQ_NUgLXWSB'
)

switch ($Device) {
    'chrome' {
        flutter run -d chrome --web-port=9090 @dartDefines
    }
    'android' {
        flutter run -d android @dartDefines
    }
    'ios' {
        flutter run -d ios @dartDefines
    }
}
