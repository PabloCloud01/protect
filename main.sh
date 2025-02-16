#!/bin/bash

# Path ke file yang akan dimodifikasi
FILE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php"
BACKUP_PATH="${FILE_PATH}.backup"

# Tampilkan menu pilihan
echo "Pilih opsi:"
echo "1. Lindungi User ID dari penghapusan"
echo "2. Reset (Kembalikan file dari backup)"
read -p "Masukkan pilihan (1/2): " choice

# Jika memilih opsi 1 (Lindungi User ID)
if [[ "$choice" == "1" ]]; then
    # Cek apakah backup sudah ada, jika belum buat backup terlebih dahulu
    if [[ ! -f "$BACKUP_PATH" ]]; then
        cp "$FILE_PATH" "$BACKUP_PATH"
        echo "Backup file berhasil disimpan di $BACKUP_PATH"
    else
        echo "Backup sudah tersedia, tidak perlu backup ulang."
    fi

    # Minta input User ID yang ingin dilindungi
    read -p "Masukkan User ID yang ingin dilindungi: " protected_id

    # Cek apakah proteksi sudah ada sebelumnya
    if grep -q "Dilarang Menghapus Admin Utama Panel" "$FILE_PATH"; then
        echo "Proteksi sudah ada sebelumnya!"
        exit 0
    fi

    # Sisipkan proteksi sebelum pemanggilan deletionService->handle($user);
    sed -i "/if (\$request->user()->id === \$user->id) {/a \\
        if (\$user->id == $protected_id) { \\
            throw new DisplayException('Dilarang Menghapus Admin Utama Panel (Protected By PabloDev)'); \\
        }" "$FILE_PATH"

    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    apt-get install nodejs -y
    npm i -g yarn
    cd /var/www/pterodactyl/ && yarn 
    cd /var/www/pterodactyl/ && yarn build:production --progress
    php artisan view:clear
    php artisan route:clear
    echo "Proteksi berhasil ditambahkan! User ID yang dilindungi: $protected_id"

# Jika memilih opsi 2 (Reset dari backup)
elif [[ "$choice" == "2" ]]; then
    # Cek apakah file backup tersedia
    if [[ -f "$BACKUP_PATH" ]]; then
        cp "$BACKUP_PATH" "$FILE_PATH"
        echo "Reset berhasil! File dikembalikan ke versi sebelum proteksi."
    else
        echo "Error: Backup file tidak ditemukan! Tidak bisa mereset."
        exit 1
    fi
else
    echo "Pilihan tidak valid!"
    exit 1
fi
