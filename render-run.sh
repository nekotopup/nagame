#!/usr/bin/env bash
# ============================================================
# render-start.sh — Skrip peluncur kontainer asli untuk Render
# ============================================================
set -e

echo "→ Menyiapkan aplikasi Laravel untuk produksi..."

# 1. Jalankan optimasi cache Laravel
php artisan optimize

# 2. Jalankan migrasi database otomatis secara paksa
echo "→ Menjalankan migrasi database..."
php artisan migrate --force

# 3. Nyalakan PHP-FPM di latar belakang (Background)
echo "→ Memulai PHP-FPM..."
php-fpm -D

# 4. Nyalakan Nginx di latar depan (Foreground) agar kontainer tetap hidup
echo "→ Memulai Nginx di port $PORT..."
nginx -g "daemon off;"
