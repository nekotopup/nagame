#!/usr/bin/env bash
set -e

echo "→ Mengoptimalkan Cache Laravel..."
php artisan optimize

echo "→ Menjalankan Migrasi Database..."
php artisan migrate --force

echo "✓ Tugas optimasi selesai!"
