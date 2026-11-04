MoonRadio — In-Game YouTube Music & Audio FX for GTA SA-MP

Read this document in English (below) or Bahasa Indonesia (scroll down to the second half).

🇬🇧 English

MoonRadio is a MoonLoader mod for GTA San Andreas Multiplayer (SA-MP) that lets you stream tracks directly from YouTube Music while you play. Instead of alt-tabbing out of the game to change songs, you get a clean glassmorphism HUD right inside SA-MP—complete with synced karaoke lyrics, a real-time spectrum visualizer, and studio-grade audio effects powered by BASS DSP.

What It Does

YouTube Music Streaming — Search for any track, browse trending charts, or let it queue up automatic radio recommendations based on the song or artist you're listening to.

Synced Karaoke Lyrics (.LRC) — Pulls time-synced lyrics from LRCLIB and YouTube Music so the lines scroll automatically in time with the music.

BASS DSP Audio Effects — Tweak how your music sounds in real time without leaving the game:

10-Band Equalizer with built-in presets (Flat, Bass Boost, Treble Boost, Vocal, Rock, Pop, Classical, EDM)

Reverb & Echo (Studio, Hall, Arena, Echo)

Dynamic Bass Boost & Compression

Distortion & Stereo Width Control

8D Surround Audio (smoothly pans the audio 360° around your head)

Custom Radio Filters (HT / Walkie-Talkie, Old FM Radio, Lo-Fi Filter — great for roleplay)

Real-Time Spectrum Visualizer — Stereo frequency analyzer with three modes (Classic Bars, Waveform Line, Circle Spectrum), drawn via mimgui drawlists so it won't tank your FPS.

Customizable Glassmorphism UI — Built on mimgui with a translucent modern layout. You can drag the windows around, resize them, and tweak the accent colors to match your HUD.

Lightweight Background Bridge (MoonRadioBridge.exe) — A small Python helper powered by yt-dlp and FFmpeg that extracts and transcodes audio streams on the fly with minimal RAM usage.

No Game Stutters — Searching, lyric fetching, and audio buffering all run asynchronously in background threads, so your game won't freeze or hitch when a new song loads.

System Requirements & Dependencies

Component

Minimum Requirement

Base Game

GTA San Andreas (PC)

Multiplayer Client

SA-MP 0.3.7 / SA-MP 0.3.DL / open.mp

Script Loader

MoonLoader v0.26 or v0.27

Lua Libraries

mimgui, samp.events, encoding, copas (optional, for async)

Operating System

Windows 10 / 11 (Recommended) or Windows 7 (Legacy build available)

Audio Engine

BASS Audio Library (bundled with GTA SA / MoonLoader) + bass_fx.dll (included)

Installation (For Players)

Download the latest release
Head over to the Releases page and grab the .zip archive that matches your operating system:

Windows 10 / 11: MoonRadio-vX.X.X-Win10-11.zip

Windows 7: MoonRadio-vX.X.X-Win7.zip

Extract to your GTA San Andreas folder
Unpack everything inside the .zip directly into your root GTA San Andreas directory (the same folder where gta_sa.exe is located).

Check your folder structure
Once extracted, your directory should look like this:

GTA San Andreas/
├── moonloader/
│   ├── MoonRadio.lua
│   ├── lib/
│   │   └── mimgui/ ...
│   └── radio/
│       ├── MoonRadioBridge.exe
│       └── bin/
│           └── ffmpeg.exe


Launch the game
Join any SA-MP server, open the chat, and type /mradio to bring up the player dashboard.

In-Game Commands (/mradio)

Command

What It Does

/mradio

Opens or closes the main MoonRadio dashboard.

/mradio help

Prints a quick list of available commands in the chatbox.

/mradio play [title / URL]

Plays a song right away from a search query or a direct YouTube link.

/mradio stop

Stops the current track immediately.

/mradio volume [0-100]

Sets the music volume (e.g., /mradio volume 80).

/mradio eq [preset]

Switches the equalizer preset on the fly (e.g., /mradio eq bass).

/mradio lyrics

Toggles the floating karaoke lyrics window.

/mradio viz

Toggles the audio spectrum visualizer window.

/mradio pos

Resets all UI windows back to their default screen coordinates if one gets stuck off-screen.

Windows 10 / 11 vs. Windows 7 Notes

Feature / Component

Windows 10 / 11 Package

Windows 7 Package

Python Runtime

Python 3.11 Embedded (Warm In-Memory Extraction)

Python 3.8 Standalone (Win7 Compatible)

Stream Startup Time

Under 2 seconds

Around 2–4 seconds

yt-dlp Auto-Update

Yes (checks for the latest release automatically)

Yes (checks for the latest release automatically)

Recommended FFmpeg

FFmpeg 7.x / 8.x Release Essentials

FFmpeg 7.0.2 / Windows 7 compatible builds

Why is Windows 10/11 recommended?
On Windows 10 and 11, MoonRadioBridge.exe keeps the extractor warm in RAM, so it doesn't have to spawn a separate external process every time you play a track. Because Windows 7 no longer receives modern TLS/SSL certificate updates and can't run Python 3.11+, the Win7 build has to use an external workaround—which works, but takes a couple of extra seconds to start playing.

Building from Source (For Developers & Modders)

If you want to tweak the code or compile MoonRadioBridge.exe yourself, here is how the repository is laid out:

MoonRadio_Package/
├── assets/
│   └── preview.png                   # In-game UI screenshot
├── packaging/
│   └── ytmusicapi_win7_compat.py     # Python 3.8 compatibility shim for newer ytmusicapi versions
├── src/
│   ├── MoonRadio_Aurora.lua          # Main MoonLoader script (mimgui UI + BASS Audio DSP)
│   ├── music_player.py               # YouTube Music bridge server, HTTP RAM streamer & LRC engine
│   └── toolchain.py                  # yt-dlp auto-updater, fast IPv4 extractor & FFmpeg locator
├── build.bat                         # Build script for Windows 10/11 (outputs to dist/MoonRadio)
├── build_win7.bat                    # Build script for Windows 7 (outputs to dist/MoonRadio_Win7)
├── pack_releases.bat                 # Packages compiled builds into ready-to-upload .zip archives
├── requirements-build.txt            # Standard build dependencies
└── requirements-build-win7.txt       # Windows 7 specific build dependencies


Build Steps

Build the Windows 10/11 package:

build.bat


The compiled files will be placed in dist\MoonRadio\.

Build the Windows 7 package (requires 32-bit Python 3.8):

build_win7.bat


The compiled files will be placed in dist\MoonRadio_Win7\.

Bundle ffmpeg.exe and create release archives:

Copy ffmpeg.exe into both dist\MoonRadio\moonloader\radio\bin\ and dist\MoonRadio_Win7\moonloader\radio\bin\.

Run pack_releases.bat to generate the final .zip files inside the releases\ folder.

🇮🇩 Bahasa Indonesia

MoonRadio adalah mod MoonLoader untuk GTA San Andreas Multiplayer (SA-MP) buat kamu yang suka dengerin lagu dari YouTube Music sambil main tanpa perlu bolak-balik Alt+Tab. Mod ini hadir dengan tampilan glassmorphism yang rapi di dalam game, lengkap dengan lirik karaoke yang jalan otomatis, spectrum visualizer, sampai pengaturan efek audio berbasis BASS DSP.

Fitur yang Tersedia

Streaming Langsung dari YouTube Music — Cari lagu apa saja, cek daftar lagu yang lagi tren, atau nyalakan rekomendasi radio otomatis berdasarkan lagu dan artis yang lagi kamu putar.

Lirik Karaoke Sinkron (.LRC) — Mengambil lirik ber-timestamp dari LRCLIB dan YouTube Music, jadi teks liriknya jalan sendiri mengikuti ketukan lagu.

Efek Audio Kelas Studio (BASS DSP) — Atur karakter suara langsung dari dalam game sesuai selera:

Equalizer 10-Band dengan pilihan preset siap pakai (Flat, Bass Boost, Treble Boost, Vocal, Rock, Pop, Classical, EDM)

Efek Reverb & Echo (Studio, Hall, Arena, Echo)

Dynamic Bass Boost & Compression

Distortion & Pengaturan Lebar Stereo (Stereo Width)

Efek Audio 8D Surround (suara musik berputar 360° mengelilingi kepala secara halus)

Filter Radio Khusus (Radio HT / Walkie-Talkie, Radio FM Tua, Filter Lo-Fi — cocok buat suasana roleplay)

Real-Time Spectrum Visualizer — Visualisasi frekuensi audio stereo dengan tiga pilihan gaya (Classic Bars, Waveform Line, Circle Spectrum). Digambar langsung lewat mimgui drawlist supaya tetap enteng dan nggak bikin FPS drop.

Tampilan Glassmorphism Modern — UI transparan berbasis mimgui yang responsif. Posisi jendelanya bisa kamu geser-geser, ukurannya bisa diatur ulang, dan warnanya bisa disesuaikan dengan selera.

Server Streaming Lokal yang Ringan (MoonRadioBridge.exe) — Program jembatan berbasis Python (yt-dlp dan FFmpeg) yang mengekstrak serta melakukan transcoding audio secara real-time tanpa makan banyak RAM.

Bebas Freeze atau Patah-Patah — Proses cari lagu, unduh lirik, dan buffering audio semuanya jalan di background thread, jadi game GTA SA kamu nggak bakal macet waktu ganti lagu.

Kebutuhan Sistem & Dependensi

Komponen

Spesifikasi / Kebutuhan Minimal

Game

GTA San Andreas (PC)

Klien Multiplayer

SA-MP 0.3.7 / SA-MP 0.3.DL / open.mp

Plugin Scripting

MoonLoader v0.26 atau v0.27

Library Lua

mimgui, samp.events, encoding, copas (opsional untuk async)

Sistem Operasi

Windows 10 / 11 (Disarankan) atau Windows 7 (Tersedia paket khusus)

Audio Engine

BASS Audio Library (Bawaan GTA SA / MoonLoader) + bass_fx.dll (Sudah termasuk)

Cara Pasang (Buat Pemain)

Unduh file rilis terbaru
Buka halaman Releases di GitHub, lalu pilih paket .zip yang sesuai dengan Windows yang kamu pakai:

Windows 10 / 11: Unduh MoonRadio-vX.X.X-Win10-11.zip

Windows 7: Unduh MoonRadio-vX.X.X-Win7.zip

Ekstrak ke folder GTA San Andreas
Ekstrak seluruh isi file .zip tadi langsung ke folder utama GTA San Andreas kamu (sejajar dengan file gta_sa.exe).

Pastikan susunan foldernya sudah benar
Kalau sudah diekstrak dengan benar, susunan foldernya akan terlihat seperti ini:

GTA San Andreas/
├── moonloader/
│   ├── MoonRadio.lua
│   ├── lib/
│   │   └── mimgui/ ...
│   └── radio/
│       ├── MoonRadioBridge.exe
│       └── bin/
│           └── ffmpeg.exe


Buka game dan mainkan
Masuk ke server SA-MP mana pun, buka kolom chat, lalu ketik /mradio untuk membuka menu utama MoonRadio.

Daftar Perintah di Dalam Game (/mradio)

Perintah

Kegunaan

/mradio

Membuka atau menutup menu utama MoonRadio.

/mradio help

Menampilkan daftar perintah singkat di kolom chat.

/mradio play [judul / URL]

Langsung memutar lagu dari kata kunci pencarian atau link YouTube.

/mradio stop

Menghentikan lagu yang sedang diputar.

/mradio volume [0-100]

Mengatur keras-pelannya volume musik (contoh: /mradio volume 80).

/mradio eq [preset]

Mengganti preset Equalizer secara cepat (contoh: /mradio eq bass).

/mradio lyrics

Menampilkan atau menyembunyikan jendela lirik karaoke melayang.

/mradio viz

Menampilkan atau menyembunyikan jendela spectrum visualizer.

/mradio pos

Mengembalikan posisi jendela UI ke tengah layar kalau tidak sengaja tergeser keluar batas layar.

Catatan untuk Pengguna Windows 10 / 11 vs. Windows 7

Fitur / Komponen

Paket Windows 10 / 11

Paket Windows 7

Python Runtime Engine

Python 3.11 Embedded (Fast In-Memory Extraction)

Python 3.8 Standalone (Kompatibel dengan Win7)

Kecepatan Mulai Putar Lagu

Cepat (kurang dari 2 detik)

Normal (sekitar 2–4 detik)

Auto-Update yt-dlp

Ya (otomatis mengecek versi terbaru)

Ya (otomatis mengecek versi terbaru)

Rekomendasi FFmpeg

FFmpeg 7.x / 8.x Release Essentials

FFmpeg 7.0.2 / Build yang mendukung Windows 7

Kenapa lebih disarankan pakai Windows 10 atau 11?
Di Windows 10/11, MoonRadioBridge.exe bisa mengekstrak audio langsung di dalam RAM (Warm In-Memory Extractor) tanpa perlu memanggil program eksternal berulang kali setiap ganti lagu. Sementara di Windows 7, sistem operasinya sudah tidak lagi mendapat pembaruan sertifikat keamanan TLS/SSL terbaru dan tidak mendukung Python 3.11 ke atas. Akibatnya, proses ekstraksi audio di Windows 7 harus lewat jalur workaround eksternal yang bikin waktu tunggu sebelum lagu berputar jadi sedikit lebih lama.

Panduan Build dari Source (Buat Developer & Modder)

Kalau kamu ingin mengutak-atik kodenya dan melakukan build ulang MoonRadioBridge.exe sendiri, berikut susunan file di dalam repositori ini:

MoonRadio_Package/
├── assets/
│   └── preview.png                   # Screenshot tampilan mod di dalam game
├── packaging/
│   └── ytmusicapi_win7_compat.py     # Penyesuaian kompatibilitas Python 3.8 untuk ytmusicapi terbaru
├── src/
│   ├── MoonRadio_Aurora.lua          # Script utama MoonLoader (UI mimgui + BASS Audio DSP)
│   ├── music_player.py               # Server jembatan YouTube Music, HTTP RAM streamer & mesin LRC
│   └── toolchain.py                  # Auto-updater yt-dlp, ekstraktor IPv4 cepat & pencari FFmpeg
├── build.bat                         # Skrip build untuk paket Windows 10/11 (hasil di dist/MoonRadio)
├── build_win7.bat                    # Skrip build untuk paket Windows 7 (hasil di dist/MoonRadio_Win7)
├── pack_releases.bat                 # Skrip pembungkus file .zip siap unggah ke GitHub Releases
├── requirements-build.txt            # Daftar dependensi build standar
└── requirements-build-win7.txt       # Daftar dependensi build khusus Windows 7


Langkah-Langkah Build

Build paket Windows 10/11:

build.bat


File hasil build akan masuk ke folder dist\MoonRadio\.

Build paket Windows 7 (wajib menggunakan Python 3.8 32-bit):

build_win7.bat


File hasil build akan masuk ke folder dist\MoonRadio_Win7\.

Tambahkan ffmpeg.exe dan bungkus jadi .zip rilis:

Masukkan ffmpeg.exe ke dalam folder dist\MoonRadio\moonloader\radio\bin\ dan dist\MoonRadio_Win7\moonloader\radio\bin\.

Jalankan pack_releases.bat untuk membuat file .zip siap rilis di dalam folder releases\.

Credits & Acknowledgements / Kredit

Mod Author: Nezxa

sigma67/ytmusicapi — Unofficial YouTube Music API client used for search, home charts, radio recommendations, and timestamped lyrics.

yt-dlp & nicolaasjan/yt-dlp — Audio stream extraction with built-in auto-update support.

LRCLIB — Community-driven database for synced .LRC lyrics.

FFmpeg & Un4seen BASS — Real-time audio transcoding and in-game DSP effect processing.

License / Lisensi

Distributed under the MIT License. See the LICENSE file for full details.
