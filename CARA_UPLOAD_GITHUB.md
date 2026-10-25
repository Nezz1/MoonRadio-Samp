# 🚀 Panduan Lengkap Upload MoonRadio ke GitHub (Langkah demi Langkah)

Semua file di dalam folder `MoonRadio_Package` ini **sudah disiapkan dan di-commit ke Git lokal (`branch main`)** lengkap dengan tampilan `README.md` profesional, screenshot in-game (`assets/preview.png`), `LICENSE`, dan `.gitignore`.

Berikut langkah mudah untuk mempublikasikannya ke akun GitHub kamu:

---

## Langkah 1: Buat Repository Baru di GitHub
1. Buka [https://github.com/new](https://github.com/new) dan login ke akun GitHub kamu.
2. Isi bagian berikut:
   - **Repository name**: `MoonRadio-Aurora` *(atau nama yang kamu suka, misal `moonradio-samp`)*
   - **Description**: `🎵 In-Game YouTube Music Streaming, Studio Audio FX, Synced Karaoke Lyrics & Glassmorphism HUD for GTA SA-MP (MoonLoader)`
   - **Visibility**: Pilih **Public** (agar semua orang bisa melihat dan memberi ⭐ Star).
   - **PENTING**: **Jangan centang** *Add a README file*, *Add .gitignore*, atau *Choose a license* (karena semuanya sudah kita buatkan secara lengkap di folder ini).
3. Klik tombol hijau **Create repository**.

---

## Langkah 2: Upload Kode ke GitHub
Setelah klik *Create repository*, GitHub akan menampilkan URL repo kamu (contoh: `https://github.com/USERNAME_KAMU/MoonRadio-Aurora.git`).

Buka **Command Prompt (CMD)** atau **PowerShell** di folder `C:\Users\Usuario\.gemini\antigravity\scratch\MoonRadio_Package`, lalu jalankan 2 baris perintah ini (ganti URL dengan URL repo GitHub kamu):

```bat
git remote add origin https://github.com/USERNAME_KAMU/MoonRadio-Aurora.git
git push -u origin main
```
*(Jika muncul jendela Login GitHub, silakan klik **Sign in with your browser**).*

Begitu selesai, coba refresh halaman GitHub kamu — halaman depan repo-mu akan langsung tampil keren lengkap dengan badge, diagram, screenshot in-game, dan tabel dokumentasi!

---

## Langkah 3: Buat "GitHub Releases" (Tempat Pemain Download `.zip` Full)
Agar pemain biasa bisa langsung men-download paket *Plug-and-Play* (yang berisi `MoonRadio_Aurora.lua` + `MoonRadioBridge.exe` + `ffmpeg.exe`):

1. **Pastikan `ffmpeg.exe` sudah kamu masukkan** ke dalam:
   - `dist\MoonRadio\moonloader\radio\bin\ffmpeg.exe` *(untuk paket Win 10/11)*
   - `dist\MoonRadio_Win7\moonloader\radio\bin\ffmpeg.exe` *(untuk paket Win 7)*
2. Klik dua kali file **`pack_releases.bat`**.
   Skrip ini akan otomatis membungkus kedua paket menjadi:
   - `releases\MoonRadio_v4.0.0_Win10_11.zip`
   - `releases\MoonRadio_v4.0.0_Win7.zip`
3. Buka halaman repository GitHub kamu di browser, lalu di bagian kanan klik **Releases** -> **Create a new release** (atau **Draft a new release**).
4. Isi form Release seperti ini:
   - **Choose a tag**: Ketik `v4.0.0` lalu klik **+ Create new tag: v4.0.0 on publish**.
   - **Release title**: `MoonRadio Aurora v4.0.0 — YouTube Music Plug & Play Edition`
   - **Describe this release**: Buka file [`RELEASE_NOTES.md`](RELEASE_NOTES.md), salin (*copy*) seluruh isinya, lalu tempel (*paste*) ke kotak deskripsi tersebut.
   - **Attach binaries (Kotak bagian bawah)**: Seret (*drag & drop*) kedua file `.zip` dari folder `releases\` (`MoonRadio_v4.0.0_Win10_11.zip` dan `MoonRadio_v4.0.0_Win7.zip`) ke kotak upload tersebut.
5. Klik tombol hijau **Publish release**! 🎉
