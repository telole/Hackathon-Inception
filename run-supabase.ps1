$ErrorActionPreference = 'Stop'
$pkFlutter = 'C:/Users/PERSONAL/.shorebird/bin/cache/flutter/9a881029f89fafe9004e6d387eb75b46cc2aa155/bin/flutter.bat'
if (!(Test-Path -LiteralPath $pkFlutter)) { throw 'SDK Flutter kompatibel tidak ditemukan. Sesuaikan variabel pkFlutter.' }
Push-Location $PSScriptRoot
try {
  if (!(Test-Path -LiteralPath 'env.json')) { throw 'Konfigurasi Supabase env.json belum tersedia.' }
  & $pkFlutter run -t lib/main.dart --dart-define-from-file=env.json @args
} finally { Pop-Location }
