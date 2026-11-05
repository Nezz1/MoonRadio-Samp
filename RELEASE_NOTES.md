# 🎵 MoonRadio Aurora v4.0.0 — YouTube Music Plug & Play Edition

Rilis penuh **MoonRadio Aurora v4.0.0** untuk **GTA SA-MP (MoonLoader)**. Streaming lagu langsung dari **YouTube Music** di dalam game tanpa perlu menyimpan file MP3 lokal dan **tanpa perlu menginstal Python**.

---

### ✨ Apa Saja yang Baru di v4.0.0?
- **🔥 Integrasi Penuh `ytmusicapi` Terbaru**: Beranda (*Home Feed*) aktif dengan lagu *Trending*, *Rilisan Baru*, *Playlist Kurasi*, *Live Search Suggestions*, dan *Smart Radio Mix* yang menyesuaikan selera dari lagu yang baru kamu putar.
- **⚡ 5x–10x Lebih Cepat Saat Ganti Lagu**:
  - Ekstraksi *Fast-Path IPv4* (`-4`) yang bebas *timeout* IPv6.
  - *Low-Latency FFmpeg RAM Buffer* (inisiasi transcode dalam ~0.2 detik tanpa mengurangi kualitas 192kbps 44.1kHz Stereo).
  - Sinkronisasi *pre-buffer* `BASS` instan + *Smart Next-Track URL Prefetch* di latar belakang.
- **🖼️ Opsi Tampilan Cover Art & Vinyl Disc**: Bisa memilih **Cover Art Langsung** seperti aplikasi YouTube Music atau **Vinyl Disc Berputar** (`/rcover` atau klik kanan pada cover di Player Bar).
- **💻 Optimasi Khusus Laptop & Perbaikan Kursor**:
  - *Adaptive Zero-Idle Disk I/O* & pembatasan thread FFmpeg (`-threads 1` + *Below Normal Priority*) agar FPS GTA SA-MP tetap stabil saat menyetir.
  - Indikator *real-time* saat memuat lagu (spinner, animasi gelombang *seek bar*, dan waktu tunggu) vs status gagal putar.
  - Perbaikan penuh bug kursor berkedip (*cursor flickering*) saat membuka menu `/radio`.

---

### 📦 Pilih Paket Sesuai Windows Kamu

1. **`MoonRadio_v4.0.0_Win10_11.zip`** *(⭐ **Sangat Direkomendasikan** untuk Windows 10 / 11 64-bit — Cepat, Mulus & Stabil)*
2. **`MoonRadio_v4.0.0_Win7.zip`** *(Khusus Windows 7 SP1 32/64-bit — Legacy)*

> ⚠️ **Disclaimer Pengguna Windows 7:**
> Sangat disarankan menggunakan **Windows 10 atau Windows 11** untuk pengalaman terbaik. Versi **Windows 7** disediakan khusus sebagai dukungan *legacy*, namun **terkadang tidak stabil dan memiliki *delay* lebih lama saat memutar lagu** karena keterbatasan jaringan TLS/SSL bawaan Windows 7 serta dihentikannya dukungan resmi Python modern & `yt-dlp` terbaru di sistem operasi Windows 7.

---

### 🚀 Cara Pasang
1. Pastikan GTA SA-MP kamu sudah terpasang **MoonLoader** dan library **`mimgui`**.
2. Ekstrak file `.zip` yang kamu unduh, lalu salin folder **`moonloader`** ke dalam folder instalasi GTA San Andreas kamu.
3. Masuk ke dalam game dan ketik **`/radio`** atau **`/mr`** (atau tekan **`F9`**), atau langsung ketik **`/rplay [judul lagu]`**.
4. *(Saat pertama kali dipakai, tunggu ±10–25 detik hingga `MoonRadioBridge.exe` selesai mengunduh `yt-dlp.exe` otomatis).*
