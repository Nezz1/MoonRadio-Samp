#!/usr/bin/env python3
"""
MoonRadio YouTube Music Streaming Engine & Bridge Server (Tanpa File MP3 Lokal)
================================================================================
Menghubungkan mod MoonRadio (GTA SA-MP / MoonLoader) langsung ke YouTube Music
secara real-time tanpa mengunduh/menyimpan file MP3 lokal ke disk.

Alur Sistem:
  1. In-Game (Lua) <-> Python Bridge melalui Non-Blocking Atomic IPC
     (%TEMP%/moonradio_bridge) agar GTA SA-MP tidak pernah lag/freeze.
  2. Pencarian lagu, rekomendasi/mix, & lirik menggunakan `ytmusicapi` + LRCLIB.
  3. Ekstraksi stream URL menggunakan `yt-dlp` (tanpa download file).
  4. Transcoding on-the-fly di RAM menggunakan `ffmpeg` (CBR 192kbps MP3 buffer)
     yang disajikan melalui Local HTTP Stream (`http://127.0.0.1:48291/stream/...`)
     langsung ke engine BASS di GTA SA-MP sehingga:
     - Studio Audio FX (3-Band EQ, DX8 Reverb, Speed/Pitch 50-150%, Pan) 100% aktif
     - 3-Mode Spectrum Visualizer & Stereo Peak Meter 100% aktif
     - Seek Bar, A-B Loop, Drop Bookmark, Lirik Karaoke (.LRC), & Cover Art 100% aktif

Install (mode source / developer; pemain biasa cukup memakai MoonRadioBridge.exe):
    pip install ytmusicapi
    # yt-dlp.exe diunduh & di-update otomatis ke folder ./bin (lihat toolchain.py).
    # FFmpeg dicari di folder aplikasi, ./bin, lalu PATH:
    #   Windows       : winget install ffmpeg
    #   Ubuntu/Debian : sudo apt install ffmpeg
    #   macOS         : brew install ffmpeg

Jalankan sebelum / saat bermain GTA SA-MP:
    python music_player.py
    (Atau jalankan tanpa prompt CLI: python music_player.py --bridge)
"""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request

try:
    from ytmusicapi import YTMusic
except ImportError:
    YTMusic = None

import io
import toolchain
from toolchain import ambil_url_audio  # yt-dlp.exe eksternal + auto-update (lihat toolchain.py)

# Mode terbungkus (.exe tanpa konsol) atau redirect Windows: pastikan UTF-8 aman agar tidak pernah UnicodeEncodeError.
if getattr(sys, "frozen", False) or sys.stdout is None:
    try:
        _log_path = os.path.join(toolchain.APP_DIR, "moonradio_bridge.log")
        if os.path.isfile(_log_path) and os.path.getsize(_log_path) > 1_000_000:
            os.replace(_log_path, _log_path + ".old")
        _log_fh = open(_log_path, "a", encoding="utf-8", errors="replace", buffering=1)
        if sys.stdout is None or not getattr(sys.stdout, "isatty", lambda: False)():
            sys.stdout = _log_fh
            sys.stderr = _log_fh
    except OSError:
        pass

for _sname in ("stdout", "stderr"):
    _st = getattr(sys, _sname, None)
    if _st is not None:
        try:
            _st.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            try:
                if hasattr(_st, "buffer"):
                    setattr(sys, _sname, io.TextIOWrapper(_st.buffer, encoding="utf-8", errors="replace", line_buffering=True))
            except Exception:
                pass


# ==============================================================================
# KONFIGURASI BRIDGE & STREAMING RAM
# ==============================================================================
BRIDGE_PORT = int(os.environ.get("MOONRADIO_PORT", "48291"))
STREAM_BITRATE_KBPS = 192
BYTES_PER_SEC = (STREAM_BITRATE_KBPS * 1000) // 8  # 24.000 byte/detik (CBR 192kbps)
PREBUFFER_BYTES = 16384  # 16 KB (~0.68 detik audio) — sinkron dengan BASS_CONFIG_NET_PREBUF 15%
MAX_RAM_SESSIONS = 4     # Maksimal lagu di buffer RAM (hemat RAM laptop)
URL_CACHE_TTL = 2400     # Cache URL stream yt-dlp selama 40 menit


def get_bridge_dirs() -> list[str]:
    """Kembalikan direktori IPC utama (%TEMP%/moonradio_bridge) dan lokal bila ada."""
    dirs = []
    temp_root = os.environ.get("TEMP") or os.environ.get("TMP") or tempfile.gettempdir()
    primary = os.path.join(temp_root, "moonradio_bridge")
    dirs.append(primary)

    # Jika script dijalankan di dalam folder moonloader/radio, sinkronkan juga ke ./bridge
    script_dir = os.path.dirname(os.path.abspath(__file__))
    local_bridge = os.path.join(script_dir, "bridge")
    if os.path.normcase(local_bridge) != os.path.normcase(primary):
        if os.path.basename(script_dir).lower() == "radio" or os.path.isdir(local_bridge):
            dirs.append(local_bridge)

    for d in dirs:
        os.makedirs(d, exist_ok=True)
    return dirs


BRIDGE_DIRS = get_bridge_dirs()
PRIMARY_BRIDGE_DIR = BRIDGE_DIRS[0]


# ==============================================================================
# FUNGSI INTI PENCARI & PEMUTAR LAGU (KOMPATIBEL DENGAN VERSI CLI)
# ==============================================================================
def parse_duration_seconds(dur_str: str | int | float | None) -> int:
    """Konversi string durasi (mis. '3:45' atau '1:02:10') ke total detik."""
    if dur_str is None:
        return 0
    if isinstance(dur_str, (int, float)):
        return max(0, int(dur_str))
    s = str(dur_str).strip()
    if not s:
        return 0
    if s.isdigit():
        return int(s)
    parts = s.split(":")
    try:
        if len(parts) == 2:
            return int(parts[0]) * 60 + int(parts[1])
        if len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
    except ValueError:
        pass
    return 0


def format_duration_mmss(seconds: int | float) -> str:
    seconds = max(0, int(seconds or 0))
    return f"{seconds // 60}:{seconds % 60:02d}"


def clean_field(val: str | None, fallback: str = "") -> str:
    """Bersihkan karakter kontrol/tab/baris baru agar aman untuk protokol IPC Lua."""
    if not val:
        return fallback
    s = re.sub(r"[\r\n\t|]+", " ", str(val)).strip()
    return s if s else fallback


_YT_URL_RE = re.compile(r"(?:v=|youtu\.be/|/watch/)([A-Za-z0-9_-]{11})")


def extract_direct_video_id(query: str) -> str | None:
    q = (query or "").strip()
    m = _YT_URL_RE.search(q)
    if m:
        return m.group(1)
    if re.fullmatch(r"[A-Za-z0-9_-]{11}", q) and any(c.isdigit() for c in q):
        return q
    return None


def cari_lagu(ytm: YTMusic, query: str, limit: int = 20, prefer_videos: bool = False) -> list[dict]:
    """Cari lagu/video di YouTube Music (sigma67/ytmusicapi), mendukung URL langsung."""
    direct_vid = extract_direct_video_id(query)
    if direct_vid:
        try:
            wp = ytm.get_watch_playlist(videoId=direct_vid, limit=max(5, limit))
            tracks = wp.get("tracks") or []
            if tracks:
                return tracks
        except Exception:
            pass

    primary_filter = "videos" if prefer_videos else "songs"
    secondary_filter = "songs" if prefer_videos else "videos"
    hasil: list[dict] = []
    try:
        hasil = ytm.search(query, filter=primary_filter, limit=limit) or []
    except Exception:
        hasil = []
    if len(hasil) < min(5, limit):
        try:
            extra = ytm.search(query, filter=secondary_filter, limit=limit) or []
            seen = {x.get("videoId") for x in hasil if isinstance(x, dict) and x.get("videoId")}
            for it in extra:
                if isinstance(it, dict) and it.get("videoId") and it.get("videoId") not in seen:
                    seen.add(it["videoId"])
                    hasil.append(it)
        except Exception:
            pass
    return hasil



# ambil_url_audio() kini diimpor dari toolchain.py (yt-dlp.exe eksternal dengan auto-update).


def putar(url: str, user_agent: str | None = None):
    """Putar URL audio langsung dengan ffplay (untuk mode CLI mandiri)."""
    ffplay_bin = toolchain.find_tool("ffplay")
    if not ffplay_bin:
        print("❌ ffplay tidak ditemukan. Pastikan FFmpeg sudah terpasang di PATH.")
        return
    cmd = [ffplay_bin, "-nodisp", "-autoexit", "-loglevel", "quiet"]
    if user_agent:
        cmd += ["-user_agent", user_agent]
    cmd.append(url)

    proses = subprocess.Popen(cmd)
    try:
        proses.wait()
    except KeyboardInterrupt:
        proses.terminate()
        print("\n⏹  Dihentikan.")


def format_hasil(i: int, lagu: dict) -> str:
    artis = ", ".join(a["name"] for a in lagu.get("artists", []) if a.get("name")) or "Unknown"
    durasi = lagu.get("duration") or format_duration_mmss(lagu.get("duration_seconds") or 0) or "?"
    return f"  {i}. {lagu.get('title', 'Unknown')} - {artis} [{durasi}]"


# ==============================================================================
# IN-MEMORY AUDIO TRANSCODER & BUFFER SESSION (ZERO LOCAL MP3 FILES)
# ==============================================================================
class StreamSession:
    """
    Menyimpan stream audio MP3 hasil transcode on-the-fly di RAM (`bytearray`).
    Mendukung pembacaan progresif oleh BASS melalui HTTP lokal maupun slicing
    byte instan ketika pengguna menggeser Seek Bar / A-B Loop.
    """

    def __init__(
        self,
        session_id: str,
        video_id: str,
        audio_url: str,
        user_agent: str | None,
        start_sec: float = 0.0,
        ffmpeg_bin: str | None = None,
    ):
        self.session_id = session_id
        self.video_id = video_id
        self.audio_url = audio_url
        self.user_agent = user_agent
        self.start_sec = max(0.0, float(start_sec or 0.0))
        self.ffmpeg_bin = ffmpeg_bin or toolchain.find_tool("ffmpeg")

        self.data = bytearray()
        self.cond = threading.Condition()
        self.ready_event = threading.Event()
        self.eof = False
        self.aborted = False
        self.error: str | None = None
        self.created_at = time.time()
        self.last_access = time.time()
        self.proc: subprocess.Popen | None = None
        self._thread = threading.Thread(target=self._worker, daemon=True)

    def start(self):
        self._thread.start()

    def stop(self):
        self.aborted = True
        with self.cond:
            self.cond.notify_all()
        self.ready_event.set()
        proc = self.proc
        if proc and proc.poll() is None:
            try:
                proc.terminate()
            except Exception:
                pass

    def _worker(self):
        try:
            if self.ffmpeg_bin:
                cmd = [
                    self.ffmpeg_bin,
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-reconnect",
                    "1",
                    "-reconnect_streamed",
                    "1",
                    "-reconnect_delay_max",
                    "5",
                ]
                if self.user_agent:
                    cmd += ["-user_agent", self.user_agent]
                if self.start_sec > 0.15:
                    cmd += ["-ss", f"{self.start_sec:.2f}"]
                cmd += [
                    "-probesize",
                    "32768",
                    "-analyzeduration",
                    "0",
                    "-fflags",
                    "+nobuffer+discardcorrupt",
                    "-i",
                    self.audio_url,
                    "-vn",
                    "-threads",
                    "1",
                    "-acodec",
                    "libmp3lame",
                    "-b:a",
                    f"{STREAM_BITRATE_KBPS}k",
                    "-ar",
                    "44100",
                    "-ac",
                    "2",
                    "-write_xing",
                    "0",
                    "-id3v2_version",
                    "0",
                    "-f",
                    "mp3",
                    "pipe:1",
                ]

                creationflags = 0
                if os.name == "nt":
                    creationflags = getattr(subprocess, "CREATE_NO_WINDOW", 0x08000000) | getattr(
                        subprocess, "BELOW_NORMAL_PRIORITY_CLASS", 0x00004000
                    )

                self.proc = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    bufsize=16384,
                    creationflags=creationflags,
                )
                assert self.proc.stdout is not None
                while not self.aborted:
                    chunk = self.proc.stdout.read(8192)
                    if not chunk:
                        break
                    with self.cond:
                        self.data.extend(chunk)
                        if len(self.data) >= PREBUFFER_BYTES:
                            self.ready_event.set()
                        self.cond.notify_all()
            else:
                # Fallback jika ffmpeg belum ada: stream langsung via urllib
                headers = {}
                if self.user_agent:
                    headers["User-Agent"] = self.user_agent
                req = urllib.request.Request(self.audio_url, headers=headers)
                with urllib.request.urlopen(req, timeout=12) as resp:
                    while not self.aborted:
                        chunk = resp.read(16384)
                        if not chunk:
                            break
                        with self.cond:
                            self.data.extend(chunk)
                            if len(self.data) >= PREBUFFER_BYTES:
                                self.ready_event.set()
                            self.cond.notify_all()

            if len(self.data) == 0 and not self.aborted:
                err_out = ""
                if self.proc and self.proc.stderr:
                    try:
                        err_out = self.proc.stderr.read().decode("utf-8", errors="ignore").strip()
                    except Exception:
                        pass
                self.error = err_out[:120] if err_out else "Stream audio kosong dari YouTube"
        except Exception as e:
            if not self.aborted:
                self.error = str(e)
        finally:
            with self.cond:
                self.eof = True
                self.cond.notify_all()
            self.ready_event.set()

    def find_mp3_frame_offset(self, target_sec: float) -> int:
        """Cari batas frame MP3 terdekat untuk slicing instan di RAM."""
        rel_sec = max(0.0, target_sec - self.start_sec)
        approx_byte = int(rel_sec * BYTES_PER_SEC)
        with self.cond:
            n = len(self.data)
            if approx_byte <= 0 or n == 0:
                return 0
            if approx_byte >= n:
                return -1
            # Cari MP3 frame sync header (11 bit 1: 0xFF dan (b2 & 0xE0) == 0xE0)
            limit = min(n - 4, approx_byte + 2048)
            for idx in range(approx_byte, limit):
                if self.data[idx] == 0xFF and (self.data[idx + 1] & 0xE0) == 0xE0:
                    return idx
            return approx_byte


# ==============================================================================
# ENGINE UTAMA BRIDGE MOONRADIO
# ==============================================================================
class MoonRadioBridge:
    def __init__(self):
        self.ytm = YTMusic() if YTMusic else None
        self.ffmpeg_bin = toolchain.find_tool("ffmpeg")
        self.stream_executor = ThreadPoolExecutor(max_workers=2)
        self.executor = ThreadPoolExecutor(max_workers=3)
        self.art_executor = ThreadPoolExecutor(max_workers=2)
        self.lock = threading.Lock()

        # Cache URL & metadata lagu di memori
        self.url_cache: dict[str, dict] = {}
        self.sessions: dict[str, StreamSession] = {}
        self.video_base_session: dict[str, str] = {}  # videoId -> session_id (start_sec == 0)
        self.recent_played: list[dict] = []           # Riwayat lagu yang diputar sesi ini (untuk rekomendasi pintar)
        self.prefetched_vid: str = ""
        self.home_cache_ts: float = 0.0
        self._cmd_mtimes: dict[str, float] = {}

        # Tracking sequence IPC
        self.last_cmd_seq = {
            "search": "",
            "stream": "",
            "meta": "",
            "home": "",
            "suggest": "",
            "prefetch": "",
        }

    # ---------- Helper Atomic File Write ----------
    def write_ipc_file(self, filename: str, content: str):
        for bdir in BRIDGE_DIRS:
            try:
                target = os.path.join(bdir, filename)
                tmp = os.path.join(bdir, f".{filename}.tmp.{threading.get_ident()}")
                with open(tmp, "w", encoding="utf-8", newline="\n") as f:
                    f.write(content)
                os.replace(tmp, target)
            except Exception:
                pass

    def write_binary_file(self, filename: str, data: bytes):
        for bdir in BRIDGE_DIRS:
            try:
                target = os.path.join(bdir, filename)
                tmp = os.path.join(bdir, f".{filename}.tmp.{threading.get_ident()}")
                with open(tmp, "wb") as f:
                    f.write(data)
                os.replace(tmp, target)
            except Exception:
                pass

    def read_ipc_cmd(self, filename: str) -> str | None:
        last_seen_mt = self._cmd_mtimes.get(filename, -1.0)
        newest_mtime = last_seen_mt
        newest_text = None
        for bdir in BRIDGE_DIRS:
            path = os.path.join(bdir, filename)
            try:
                mt = os.path.getmtime(path)
                if mt > newest_mtime:
                    with open(path, "r", encoding="utf-8", errors="replace") as f:
                        txt = f.read().strip()
                    if txt:
                        newest_mtime = mt
                        newest_text = txt
            except OSError:
                pass
            except Exception:
                pass
        if newest_text is not None:
            self._cmd_mtimes[filename] = newest_mtime
        return newest_text

    # ---------- Parsing Hasil YouTube Music ----------
    def normalize_track(self, item: dict) -> dict | None:
        vid = item.get("videoId")
        if not vid:
            return None
        title = clean_field(item.get("title"), "Unknown Title")
        artists_list = item.get("artists") or []
        if isinstance(artists_list, list):
            artist = ", ".join(
                clean_field(a.get("name")) for a in artists_list if isinstance(a, dict) and a.get("name")
            )
        else:
            artist = ""
        if not artist:
            artist = clean_field(item.get("author"), "YouTube Music")

        album_obj = item.get("album")
        if isinstance(album_obj, dict):
            album = clean_field(album_obj.get("name"), "YouTube Music")
        elif isinstance(album_obj, str) and album_obj.strip():
            album = clean_field(album_obj, "YouTube Music")
        else:
            album = "YouTube Music"

        dur_sec = int(item.get("duration_seconds") or 0)
        dur_str = clean_field(item.get("duration") or item.get("length"), "")
        if dur_sec <= 0 and dur_str:
            dur_sec = parse_duration_seconds(dur_str)
        if not dur_str and dur_sec > 0:
            dur_str = format_duration_mmss(dur_sec)

        thumbs = item.get("thumbnails") or item.get("thumbnail") or []
        thumb_url = None
        if isinstance(thumbs, list) and thumbs:
            thumb_url = thumbs[-1].get("url")
        elif isinstance(thumbs, dict):
            t_list = thumbs.get("thumbnails") or []
            if t_list:
                thumb_url = t_list[-1].get("url")

        if thumb_url:
            with self.lock:
                entry = self.url_cache.setdefault(vid, {})
                entry["thumb"] = thumb_url
                if dur_sec > 0:
                    entry["dur"] = dur_sec

        return {
            "videoId": vid,
            "title": title,
            "artist": artist,
            "album": album,
            "durSec": dur_sec,
            "durStr": dur_str or "0:00",
        }

    # ---------- Resolusi URL Stream Audio ----------
    def resolve_stream_info(self, video_id: str) -> dict:
        now = time.time()
        with self.lock:
            cached = self.url_cache.get(video_id)
            if cached and cached.get("url") and (now - cached.get("ts", 0) < URL_CACHE_TTL):
                return cached

        url, ua, dur, thumb = ambil_url_audio(video_id)
        with self.lock:
            entry = self.url_cache.setdefault(video_id, {})
            entry.update({
                "url": url,
                "ua": ua,
                "dur": dur or entry.get("dur", 0),
                "thumb": entry.get("thumb") or thumb,
                "ts": now,
            })
            return dict(entry)

    # ---------- Manajemen Sesi Stream RAM ----------
    def _evict_old_sessions_locked(self):
        if len(self.sessions) <= MAX_RAM_SESSIONS:
            return
        ordered = sorted(self.sessions.values(), key=lambda s: s.last_access)
        while len(self.sessions) > MAX_RAM_SESSIONS and ordered:
            old = ordered.pop(0)
            self.sessions.pop(old.session_id, None)
            if self.video_base_session.get(old.video_id) == old.session_id:
                self.video_base_session.pop(old.video_id, None)
            old.stop()

    def get_session(self, session_id: str) -> StreamSession | None:
        with self.lock:
            s = self.sessions.get(session_id)
            if s:
                s.last_access = time.time()
            return s

    # ---------- Helper Playlist, Home Feed & Prefetch (sigma67/ytmusicapi) ----------
    def fetch_playlist_tracks(self, playlist_id: str, limit: int = 30) -> list[dict]:
        """Ambil daftar lagu dari playlistId / audioPlaylistId / browseId YouTube Music."""
        if not self.ytm or not playlist_id:
            return []
        pid = playlist_id.strip()
        raw_tracks: list[dict] = []

        # 1) Album browseId (MPREb_...)
        if pid.startswith("MPREb_"):
            try:
                alb = self.ytm.get_album(pid)
                alb_name = clean_field(alb.get("title"), "YouTube Music")
                alb_thumbs = alb.get("thumbnails") or []
                for it in alb.get("tracks") or []:
                    if isinstance(it, dict):
                        it.setdefault("album", alb_name)
                        if alb_thumbs and not it.get("thumbnails"):
                            it["thumbnails"] = alb_thumbs
                        raw_tracks.append(it)
            except Exception:
                pass

        # 2) Watch playlist (mendukung RDCLAK..., OLAK..., RDAMVM..., PL...)
        if not raw_tracks:
            try:
                wp_id = pid[2:] if pid.startswith("VL") else pid
                wp = self.ytm.get_watch_playlist(playlistId=wp_id, limit=limit)
                raw_tracks = wp.get("tracks") or []
            except Exception:
                raw_tracks = []

        # 3) Fallback ke get_playlist standar
        if not raw_tracks:
            try:
                pl_id = pid[2:] if pid.startswith("VL") else pid
                pl = self.ytm.get_playlist(pl_id, limit=limit)
                raw_tracks = pl.get("tracks") or []
            except Exception:
                raw_tracks = []

        out: list[dict] = []
        seen: set[str] = set()
        for item in raw_tracks:
            tr = self.normalize_track(item)
            if tr and tr["videoId"] not in seen:
                seen.add(tr["videoId"])
                out.append(tr)
                if len(out) >= limit:
                    break
        return out

    def prefetch_arts_batch(self, video_ids: list[str]):
        """Unduh cover art untuk daftar videoId/artKey di background agar UI langsung bergambar."""
        for vid in video_ids[:24]:
            if vid:
                self.art_executor.submit(self._ensure_cover_art, vid)

    def handle_home(self, seq: str, seed_info: str = ""):
        """
        Ambil beranda asli YouTube Music (`ytm.get_home()` + `ytm.get_explore()` + radio pintar
        berdasarkan lagu yang baru diputar) lalu tulis ke `resp_home.txt` dan `resp_search.txt`.
        """
        try:
            if not self.ytm:
                self.write_ipc_file("resp_home.txt", f"ERR|{seq}|ytmusicapi belum siap\n")
                return

            shelves_tracks: list[tuple[str, dict]] = []
            playlists_out: list[dict] = []
            all_tracks: list[dict] = []
            seen_vids: set[str] = set()
            seen_pls: set[str] = set()
            art_queue: list[str] = []

            def add_track(shelf_title: str, item: dict):
                tr = self.normalize_track(item)
                if not tr:
                    return
                vid = tr["videoId"]
                shelves_tracks.append((clean_field(shelf_title, "Pilihan Cepat"), tr))
                if vid not in seen_vids:
                    seen_vids.add(vid)
                    all_tracks.append(tr)
                    art_queue.append(vid)

            def add_playlist(shelf_title: str, pid: str, title: str, sub: str, thumbs: list):
                pid = clean_field(pid)
                if not pid or pid in seen_pls:
                    return
                seen_pls.add(pid)
                safe_id = "pl_" + re.sub(r"[^A-Za-z0-9_-]", "", pid)[:28]
                thumb_url = None
                if isinstance(thumbs, list) and thumbs:
                    thumb_url = thumbs[-1].get("url")
                if thumb_url:
                    with self.lock:
                        self.url_cache.setdefault(safe_id, {})["thumb"] = thumb_url
                    art_queue.append(safe_id)
                playlists_out.append({
                    "playlistId": pid,
                    "title": clean_field(title, "YouTube Music Mix"),
                    "sub": clean_field(sub, shelf_title),
                    "shelf": clean_field(shelf_title, "Playlist YT Music"),
                    "artKey": safe_id,
                })

            # 1) Jika pemain punya lagu yang baru diputar, buat rak "Radio Pintar Untukmu"
            seed_vid = clean_field(seed_info.split(";;")[0] if seed_info else "")
            if not seed_vid and self.recent_played:
                seed_vid = self.recent_played[-1].get("videoId", "")
            if seed_vid:
                try:
                    wp = self.ytm.get_watch_playlist(videoId=seed_vid, radio=True, limit=12)
                    for it in (wp.get("tracks") or [])[:10]:
                        if it.get("videoId") != seed_vid:
                            add_track("Untukmu (Radio Pintar)", it)
                except Exception:
                    pass

            # 2) Rak Beranda Asli YouTube Music (ytm.get_home)
            try:
                home_shelves = self.ytm.get_home(limit=6) or []
                for shelf in home_shelves:
                    stitle = clean_field(shelf.get("title"), "Beranda YT Music")
                    for item in shelf.get("contents") or []:
                        if not isinstance(item, dict):
                            continue
                        if item.get("videoId"):
                            add_track(stitle, item)
                        else:
                            pid = item.get("playlistId") or item.get("audioPlaylistId") or item.get("browseId")
                            if pid and (str(pid).startswith(("RD", "PL", "OL", "VL", "MPREb_"))):
                                desc = item.get("description") or ""
                                if not desc and isinstance(item.get("artists"), list):
                                    desc = ", ".join(
                                        a.get("name", "") for a in item["artists"] if isinstance(a, dict) and a.get("name")
                                    )
                                add_playlist(stitle, str(pid), item.get("title") or "Mix", desc or stitle, item.get("thumbnails") or [])
            except Exception as e:
                print(f"⚠️ [Home API Notice] get_home: {e}")

            # 3) Rak Explore & Trending YouTube Music (ytm.get_explore)
            try:
                exp = self.ytm.get_explore() or {}
                trending_items = (exp.get("trending") or {}).get("items") or []
                for it in trending_items[:12]:
                    if isinstance(it, dict) and it.get("videoId"):
                        add_track("Trending di YouTube Music", it)
                for alb in (exp.get("new_releases") or [])[:8]:
                    if isinstance(alb, dict):
                        apid = alb.get("audioPlaylistId") or alb.get("browseId")
                        if apid:
                            artists_str = ", ".join(
                                a.get("name", "") for a in (alb.get("artists") or []) if isinstance(a, dict) and a.get("name")
                            )
                            add_playlist("Rilisan Album Baru", str(apid), alb.get("title") or "Album", artists_str or "Album Baru", alb.get("thumbnails") or [])
            except Exception:
                pass

            # 4) Fallback pencarian bila koneksi/region mengembalikan beranda tipis
            if len(all_tracks) < 10:
                for q in ("Lagu Indonesia Populer Hits", "Top Global Hits", "Lagu Galau Sad Indonesia"):
                    try:
                        for it in cari_lagu(self.ytm, q, limit=8):
                            add_track("Populer Pilihan", it)
                    except Exception:
                        pass

            lines = [f"OK|{seq}|{len(shelves_tracks)}|{len(playlists_out)}|{int(time.time())}"]
            for shelf_name, t in shelves_tracks:
                lines.append(
                    f"TR\t{shelf_name}\t{t['videoId']}\t{t['title']}\t{t['artist']}\t{t['album']}\t{t['durSec']}\t{t['durStr']}"
                )
            for pl in playlists_out[:24]:
                lines.append(
                    f"PL\t{pl['playlistId']}\t{pl['title']}\t{pl['sub']}\t{pl['shelf']}\t{pl['artKey']}"
                )
            self.write_ipc_file("resp_home.txt", "\n".join(lines) + "\n")

            # Sinkronkan juga ke katalog utama bila baru booting
            if all_tracks:
                s_lines = [f"OK|{seq}|discover|{len(all_tracks)}|Beranda YouTube Music"]
                for t in all_tracks:
                    s_lines.append(
                        f"{t['videoId']}\t{t['title']}\t{t['artist']}\t{t['album']}\t{t['durSec']}\t{t['durStr']}"
                    )
                self.write_ipc_file("resp_search.txt", "\n".join(s_lines) + "\n")

            self.prefetch_arts_batch(art_queue)
            print(f"🏠 [YT Music Home] {len(all_tracks)} lagu & {len(playlists_out)} playlist kurasi dimuat")
        except Exception as e:
            err_msg = clean_field(str(e), "Gagal memuat Beranda YouTube Music")
            self.write_ipc_file("resp_home.txt", f"ERR|{seq}|{err_msg}\n")
            print(f"❌ [Home Error] {e}")

    def handle_suggest(self, seq: str, query: str):
        """Ambil saran pencarian real-time dari `ytm.get_search_suggestions`."""
        q = (query or "").strip()
        if not self.ytm or len(q) < 2:
            return
        try:
            suggs = self.ytm.get_search_suggestions(q) or []
            cleaned: list[str] = []
            for s in suggs:
                val = s.get("text") if isinstance(s, dict) else str(s)
                c = clean_field(val)
                if c and c.lower() != q.lower() and c not in cleaned:
                    cleaned.append(c)
                if len(cleaned) >= 6:
                    break
            lines = [f"OK|{seq}|{clean_field(q)}"] + cleaned
            self.write_ipc_file("resp_suggest.txt", "\n".join(lines) + "\n")
        except Exception:
            pass

    def handle_prefetch(self, seq: str, video_id: str, title: str, artist: str):
        """Pre-resolve URL stream, cover art, dan lirik lagu berikutnya di antrean agar pindah lagu instan."""
        vid = (video_id or "").strip()
        if not vid:
            return
        self.prefetched_vid = vid
        try:
            self._ensure_cover_art(vid)
            self._ensure_lyrics(vid, title or vid, artist or "YouTube Music")
            self.resolve_stream_info(vid)
            print(f"⚡ [Prefetch Ready] {title} ({vid})")
        except Exception:
            pass

    # ---------- Handler Pencarian & Rekomendasi ----------
    def handle_search(self, seq: str, mode: str, limit_str: str, query: str):
        try:
            if not self.ytm:
                self.write_ipc_file("resp_search.txt", f"ERR|{seq}|{mode}|Library ytmusicapi belum terpasang")
                return

            limit = max(5, min(50, int(limit_str or "20")))
            tracks: list[dict] = []
            seen_ids: set[str] = set()
            label_out = query

            if mode == "discover":
                self.handle_home(seq, query)
                return
            elif mode == "playlist":
                # Query berisi "playlistId;;Judul Playlist"
                parts = query.split(";;", 1)
                pid = parts[0].strip()
                label_out = parts[1].strip() if len(parts) > 1 and parts[1].strip() else "Playlist YouTube Music"
                tracks = self.fetch_playlist_tracks(pid, limit=limit)
            elif mode in ("automix", "automix_append"):
                # Query berisi videoId;;kata kunci lagu untuk radio se-vibe (ytm.get_watch_playlist radio=True)
                parts = query.split(";;")
                seed_vid = parts[0].strip() if parts else ""
                seed_q = parts[1].strip() if len(parts) > 1 else query
                label_out = seed_q or seed_vid
                if seed_vid:
                    try:
                        wp = self.ytm.get_watch_playlist(videoId=seed_vid, radio=True, limit=limit)
                        for item in wp.get("tracks", []):
                            tr = self.normalize_track(item)
                            if tr and tr["videoId"] not in seen_ids:
                                seen_ids.add(tr["videoId"])
                                tracks.append(tr)
                    except Exception:
                        pass
                if len(tracks) < 6 and seed_q:
                    res = cari_lagu(self.ytm, seed_q, limit=limit)
                    for item in res:
                        tr = self.normalize_track(item)
                        if tr and tr["videoId"] not in seen_ids:
                            seen_ids.add(tr["videoId"])
                            tracks.append(tr)
            else:
                prefer_vid = mode == "videos"
                res = cari_lagu(self.ytm, query, limit=limit, prefer_videos=prefer_vid)
                for item in res:
                    tr = self.normalize_track(item)
                    if tr and tr["videoId"] not in seen_ids:
                        seen_ids.add(tr["videoId"])
                        tracks.append(tr)

            lines = [f"OK|{seq}|{mode}|{len(tracks)}|{clean_field(label_out)}"]
            for t in tracks:
                lines.append(
                    f"{t['videoId']}\t{t['title']}\t{t['artist']}\t{t['album']}\t{t['durSec']}\t{t['durStr']}"
                )
            self.write_ipc_file("resp_search.txt", "\n".join(lines) + "\n")
            self.prefetch_arts_batch([t["videoId"] for t in tracks[:16]])
            print(f"🔎 [Search:{mode}] '{label_out}' -> {len(tracks)} lagu ditemukan")
        except Exception as e:
            err_msg = clean_field(str(e), "Gagal mencari di YouTube Music")
            self.write_ipc_file("resp_search.txt", f"ERR|{seq}|{mode}|{err_msg}\n")
            print(f"❌ [Search Error] {e}")

    # ---------- Handler Persiapan Stream & Seek ----------
    def handle_stream(self, seq: str, video_id: str, start_str: str, title: str, artist: str):
        try:
            start_sec = max(0.0, float(start_str or "0"))
        except ValueError:
            start_sec = 0.0

        try:
            # Catat lagu yang diputar untuk rekomendasi pintar Beranda
            with self.lock:
                if not self.recent_played or self.recent_played[-1].get("videoId") != video_id:
                    self.recent_played.append({"videoId": video_id, "title": title, "artist": artist})
                    if len(self.recent_played) > 25:
                        self.recent_played.pop(0)
                # Hentikan proses transcode lagu lama yang masih mengunduh agar hemat bandwidth
                for s in list(self.sessions.values()):
                    if s.video_id not in (video_id, self.prefetched_vid) and not s.eof and not s.aborted:
                        s.stop()

            # 1. Jalankan pengambilan cover art & lirik di background secara paralel
            self.executor.submit(self.fetch_metadata_assets, seq, video_id, title, artist)

            # 2. Cek apakah lagu ini sudah punya base session (start=0) di RAM yang mencakup posisi seek
            with self.lock:
                base_sid = self.video_base_session.get(video_id)
                base_sess = self.sessions.get(base_sid) if base_sid else None

            if base_sess and not base_sess.aborted and not base_sess.error:
                req_byte = int(start_sec * BYTES_PER_SEC) + PREBUFFER_BYTES
                with base_sess.cond:
                    buffered_ok = (len(base_sess.data) >= req_byte) or (
                        base_sess.eof and len(base_sess.data) > int(start_sec * BYTES_PER_SEC)
                    )
                if buffered_ok:
                    base_sess.last_access = time.time()
                    dur = self.url_cache.get(video_id, {}).get("dur", 0)
                    stream_url = (
                        f"http://127.0.0.1:{BRIDGE_PORT}/stream/{base_sess.session_id}.mp3"
                        f"?start={start_sec:.2f}&seq={seq}"
                    )
                    self.write_ipc_file(
                        "resp_stream.txt",
                        f"READY|{seq}|{video_id}|{stream_url}|{dur}|{start_sec:.2f}\n",
                    )
                    print(f"⚡ [RAM Instant Seek/Play] {title} ({start_sec:.1f}s)")
                    return

            # 3. Beri status progres bertahap ke UI Lua agar pemain tahu proses yang sedang berjalan
            with self.lock:
                has_cached_url = bool(
                    self.url_cache.get(video_id, {}).get("url")
                    and (time.time() - self.url_cache.get(video_id, {}).get("ts", 0) < URL_CACHE_TTL)
                )
            if not has_cached_url:
                self.write_ipc_file(
                    "resp_stream.txt",
                    f"PROGRESS|{seq}|{video_id}|[1/2] Mengambil link audio dari YouTube Music...\n",
                )

            info = self.resolve_stream_info(video_id)
            audio_url = info["url"]
            ua = info.get("ua")
            dur = int(info.get("dur") or 0)

            self.write_ipc_file(
                "resp_stream.txt",
                f"PROGRESS|{seq}|{video_id}|[2/2] Menyiapkan buffer audio (FFmpeg)...\n",
            )

            session_id = f"{video_id}_{int(start_sec * 10)}_{int(time.time() * 1000) % 100000}"
            sess = StreamSession(
                session_id=session_id,
                video_id=video_id,
                audio_url=audio_url,
                user_agent=ua,
                start_sec=start_sec,
                ffmpeg_bin=self.ffmpeg_bin,
            )

            with self.lock:
                self._evict_old_sessions_locked()
                self.sessions[session_id] = sess
                if start_sec < 0.25:
                    self.video_base_session[video_id] = session_id

            sess.start()
            # Tunggu sampai prebuffer 32KB siap di RAM (biasanya ~0.2 detik) agar BASS tidak nge-freeze
            sess.ready_event.wait(timeout=12.0)

            if sess.error and len(sess.data) == 0:
                raise RuntimeError(sess.error)

            stream_url = f"http://127.0.0.1:{BRIDGE_PORT}/stream/{session_id}.mp3?seq={seq}"
            self.write_ipc_file(
                "resp_stream.txt",
                f"READY|{seq}|{video_id}|{stream_url}|{dur}|{start_sec:.2f}\n",
            )
            print(f"▶  [Streaming Ready] {title} - {artist} [{format_duration_mmss(dur)}]")
        except Exception as e:
            err_msg = clean_field(str(e), "Gagal menyiapkan stream YouTube Music")
            self.write_ipc_file("resp_stream.txt", f"ERR|{seq}|{video_id}|{err_msg}\n")
            print(f"❌ [Stream Error] {video_id}: {e}")

    # ---------- Handler Lirik (.LRC) & Cover Art ----------
    def fetch_metadata_assets(self, seq: str, video_id: str, title: str, artist: str):
        has_art = self._ensure_cover_art(video_id)
        has_lrc, lyr_src = self._ensure_lyrics(video_id, title, artist)
        self.write_ipc_file(
            "resp_meta.txt",
            f"META|{seq}|{video_id}|{1 if has_art else 0}|{1 if has_lrc else 0}|{clean_field(lyr_src, 'YouTube Music')}\n",
        )

    def _ensure_cover_art(self, video_id: str) -> bool:
        art_name = f"art_{video_id}.jpg"
        primary_path = os.path.join(PRIMARY_BRIDGE_DIR, art_name)
        if os.path.isfile(primary_path) and os.path.getsize(primary_path) > 256:
            return True

        thumb_url = None
        with self.lock:
            thumb_url = self.url_cache.get(video_id, {}).get("thumb")

        if not thumb_url:
            if video_id.startswith("pl_"):
                return False
            thumb_url = f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"

        try:
            req = urllib.request.Request(
                thumb_url,
                headers={"User-Agent": "Mozilla/5.0"},
            )
            with urllib.request.urlopen(req, timeout=6) as resp:
                img_bytes = resp.read()
            if img_bytes and len(img_bytes) > 256:
                self.write_binary_file(art_name, img_bytes)
                return True
        except Exception:
            pass
        return False

    def _ensure_lyrics(self, video_id: str, title: str, artist: str) -> tuple[bool, str]:
        lrc_name = f"lyr_{video_id}.lrc"
        primary_path = os.path.join(PRIMARY_BRIDGE_DIR, lrc_name)
        if os.path.isfile(primary_path) and os.path.getsize(primary_path) > 16:
            return True, "Cached Lyrics"

        # 1. Coba Lirik Tersinkronisasi Resmi YouTube Music via sigma67/ytmusicapi (timestamps=True)
        plain_fallback: tuple[str, str] | None = None
        if self.ytm:
            try:
                wp = self.ytm.get_watch_playlist(videoId=video_id)
                lyrics_browse_id = wp.get("lyrics")
                if lyrics_browse_id:
                    lyr_obj = None
                    try:
                        lyr_obj = self.ytm.get_lyrics(lyrics_browse_id, timestamps=True)
                    except TypeError:
                        lyr_obj = self.ytm.get_lyrics(lyrics_browse_id)
                    except Exception:
                        try:
                            lyr_obj = self.ytm.get_lyrics(lyrics_browse_id)
                        except Exception:
                            lyr_obj = None
                    if lyr_obj and lyr_obj.get("lyrics"):
                        raw_lyrics = lyr_obj["lyrics"]
                        if isinstance(raw_lyrics, list):
                            lines = []
                            for ln in raw_lyrics:
                                if hasattr(ln, "start_time") and hasattr(ln, "text"):
                                    ms = int(getattr(ln, "start_time", 0) or 0)
                                    mm, ss, cs = (ms // 1000) // 60, (ms // 1000) % 60, (ms % 1000) // 10
                                    lines.append(f"[{mm:02d}:{ss:02d}.{cs:02d}]{getattr(ln, 'text', '')}")
                                elif isinstance(ln, dict):
                                    ms = int(ln.get("start_time") or 0)
                                    mm, ss, cs = (ms // 1000) // 60, (ms // 1000) % 60, (ms % 1000) // 10
                                    lines.append(f"[{mm:02d}:{ss:02d}.{cs:02d}]{ln.get('text', '')}")
                                else:
                                    lines.append(str(ln))
                            text_out = "\n".join(lines).strip()
                            if text_out:
                                self.write_ipc_file(lrc_name, text_out + "\n")
                                return True, "YouTube Music Synced"
                        elif isinstance(raw_lyrics, str) and raw_lyrics.strip():
                            plain_fallback = (raw_lyrics.strip(), "YouTube Music Lyrics")
            except Exception:
                pass

        # 2. Cari Synced LRC dari LRCLIB API (Gratis, mendukung timestamp [mm:ss.xx])
        clean_t = re.sub(
            r"[\(\[][^)\]]*(official|video|audio|lyric|lirik|mv|hd|4k|visualizer)[^)\]]*[\)\]]",
            "",
            title,
            flags=re.I,
        ).strip() or title
        clean_a = re.sub(r"\s*[-,&].*$", "", artist or "").strip()

        try:
            q = urllib.parse.quote(f"{clean_t} {clean_a}".strip())
            url = f"https://lrclib.net/api/search?q={q}"
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "MoonRadio-GTASAMP/4.0 (https://music.youtube.com)"},
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                items = json.loads(resp.read().decode("utf-8", errors="ignore"))
            if isinstance(items, list) and items:
                for it in items:
                    synced = it.get("syncedLyrics")
                    if synced and "[" in synced:
                        self.write_ipc_file(lrc_name, synced.strip() + "\n")
                        return True, "LRCLIB Synced LRC"
                if not plain_fallback:
                    for it in items:
                        plain = it.get("plainLyrics")
                        if plain and len(plain.strip()) > 20:
                            plain_fallback = (plain.strip(), "LRCLIB Plain Lyrics")
                            break
        except Exception:
            pass

        if plain_fallback:
            self.write_ipc_file(lrc_name, plain_fallback[0] + "\n")
            return True, plain_fallback[1]

        return False, "No Lyrics"

    # ---------- Loop Polling IPC Non-Blocking ----------
    def poll_loop(self):
        last_ping = 0.0
        while True:
            now = time.time()
            if now - last_ping >= 3.0:
                last_ping = now
                ff_flag = 1 if self.ffmpeg_bin else 0
                self.write_ipc_file("ping.txt", f"ONLINE|{int(now)}|{BRIDGE_PORT}|{ff_flag}\n")

            # 1. Prioritas Utama: Cek perintah stream/play/seek (cmd_stream.txt) via dedicated stream_executor
            raw_stream = self.read_ipc_cmd("cmd_stream.txt")
            if raw_stream:
                parts = raw_stream.split("|", 4)
                if len(parts) >= 3:
                    seq = parts[0]
                    video_id = parts[1]
                    start_str = parts[2]
                    title = parts[3] if len(parts) > 3 else video_id
                    artist = parts[4] if len(parts) > 4 else "YouTube Music"
                    if seq and seq != self.last_cmd_seq["stream"]:
                        self.last_cmd_seq["stream"] = seq
                        self.stream_executor.submit(self.handle_stream, seq, video_id, start_str, title, artist)

            # 2. Cek perintah pencarian / playlist / automix (cmd_search.txt)
            raw_search = self.read_ipc_cmd("cmd_search.txt")
            if raw_search:
                parts = raw_search.split("|", 3)
                if len(parts) >= 4:
                    seq, mode, limit_str, query = parts[0], parts[1], parts[2], parts[3]
                    if seq and seq != self.last_cmd_seq["search"]:
                        self.last_cmd_seq["search"] = seq
                        self.executor.submit(self.handle_search, seq, mode, limit_str, query)

            # 3. Cek perintah Beranda YouTube Music (cmd_home.txt)
            raw_home = self.read_ipc_cmd("cmd_home.txt")
            if raw_home:
                parts = raw_home.split("|", 1)
                seq = parts[0]
                seed_info = parts[1] if len(parts) > 1 else ""
                if seq and seq != self.last_cmd_seq["home"]:
                    self.last_cmd_seq["home"] = seq
                    self.executor.submit(self.handle_home, seq, seed_info)

            # 4. Cek perintah saran pencarian langsung (cmd_suggest.txt)
            raw_sugg = self.read_ipc_cmd("cmd_suggest.txt")
            if raw_sugg:
                parts = raw_sugg.split("|", 1)
                if len(parts) >= 2:
                    seq, q = parts[0], parts[1]
                    if seq and seq != self.last_cmd_seq["suggest"]:
                        self.last_cmd_seq["suggest"] = seq
                        self.executor.submit(self.handle_suggest, seq, q)

            # 5. Cek perintah pre-buffer lagu berikutnya (cmd_prefetch.txt)
            raw_pref = self.read_ipc_cmd("cmd_prefetch.txt")
            if raw_pref:
                parts = raw_pref.split("|", 3)
                if len(parts) >= 2:
                    seq = parts[0]
                    vid = parts[1]
                    title = parts[2] if len(parts) > 2 else vid
                    artist = parts[3] if len(parts) > 3 else "YouTube Music"
                    if seq and seq != self.last_cmd_seq["prefetch"]:
                        self.last_cmd_seq["prefetch"] = seq
                        self.executor.submit(self.handle_prefetch, seq, vid, title, artist)

            # 6. Cek perintah metadata/lirik/cover manual (cmd_meta.txt)
            raw_meta = self.read_ipc_cmd("cmd_meta.txt")
            if raw_meta:
                parts = raw_meta.split("|", 4)
                if len(parts) >= 4:
                    seq, video_id, title, artist = parts[0], parts[1], parts[2], parts[3]
                    if seq and seq != self.last_cmd_seq["meta"]:
                        self.last_cmd_seq["meta"] = seq
                        self.executor.submit(self.fetch_metadata_assets, seq, video_id, title, artist)

            time.sleep(0.05)


# ==============================================================================
# SERVER HTTP LOKAL UNTUK STREAMING KE BASS (127.0.0.1:48291)
# ==============================================================================
BRIDGE_INSTANCE: MoonRadioBridge | None = None


class LocalAudioStreamHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        # Jangan penuhi terminal dengan log HTTP per-request
        pass

    def do_HEAD(self):
        self._serve_stream(head_only=True)

    def do_GET(self):
        self._serve_stream(head_only=False)

    def _serve_stream(self, head_only: bool = False):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/health":
            body = b"OK"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if not head_only:
                self.wfile.write(body)
            return

        m = re.match(r"^/stream/([^/.]+)\.mp3$", parsed.path)
        if not m or BRIDGE_INSTANCE is None:
            self.send_error(404, "Stream session not found")
            return

        session_id = m.group(1)
        sess = BRIDGE_INSTANCE.get_session(session_id)
        if sess is None:
            self.send_error(404, "Session expired")
            return

        qs = urllib.parse.parse_qs(parsed.query)
        start_param = qs.get("start", [None])[0]
        byte_pos = 0
        if start_param is not None:
            try:
                target_sec = float(start_param)
                offset = sess.find_mp3_frame_offset(target_sec)
                if offset >= 0:
                    byte_pos = offset
            except ValueError:
                byte_pos = 0

        self.send_response(200)
        self.send_header("Content-Type", "audio/mpeg")
        self.send_header("Cache-Control", "no-cache, no-store")
        self.send_header("Connection", "close")
        self.send_header("icy-name", "MoonRadio YouTube Music Stream")
        self.end_headers()

        if head_only:
            return

        try:
            self.connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except Exception:
            pass

        try:
            while not sess.aborted:
                with sess.cond:
                    while byte_pos >= len(sess.data) and not sess.eof and not sess.aborted:
                        sess.cond.wait(timeout=0.4)
                    if sess.aborted:
                        break
                    if byte_pos < len(sess.data):
                        end_pos = min(len(sess.data), byte_pos + 32768)
                        chunk = bytes(sess.data[byte_pos:end_pos])
                    else:
                        chunk = b""
                if chunk:
                    self.wfile.write(chunk)
                    self.wfile.flush()
                    byte_pos += len(chunk)
                elif sess.eof:
                    break
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass


def start_bridge_background() -> MoonRadioBridge:
    global BRIDGE_INSTANCE
    if BRIDGE_INSTANCE is not None:
        return BRIDGE_INSTANCE

    if YTMusic is None:
        sys.exit("❌ Modul belum lengkap. Jalankan: pip install ytmusicapi")

    try:
        server = ThreadingHTTPServer(("127.0.0.1", BRIDGE_PORT), LocalAudioStreamHandler)
    except OSError:
        print(f"ℹ️  Bridge sudah berjalan di port {BRIDGE_PORT}. Instance ini ditutup.")
        sys.exit(0)

    toolchain.ensure_ytdlp_async()  # unduh / update yt-dlp di background

    bridge = MoonRadioBridge()
    BRIDGE_INSTANCE = bridge

    http_thread = threading.Thread(target=server.serve_forever, daemon=True)
    http_thread.start()

    ipc_thread = threading.Thread(target=bridge.poll_loop, daemon=True)
    ipc_thread.start()

    # Pre-warm katalog lagu populer di background agar saat buka /radio langsung ada rekomendasi
    bridge.executor.submit(bridge.handle_search, "init_boot", "discover", "25", "")
    return bridge


# ==============================================================================
# ENTRY POINT (MENDUKUNG MODE BRIDGE GTA SA-MP + INTERAKTIF CLI)
# ==============================================================================
def main():
    bridge_only = (
        "--bridge" in sys.argv or "--daemon" in sys.argv or getattr(sys, "frozen", False)
    )
    bridge = start_bridge_background()

    if "--autoexit" in sys.argv:
        def _watch_game():
            # Tutup otomatis setelah game berhenti (2 cek berturut-turut, jeda 30 dtk).
            time.sleep(120)
            misses = 0
            while True:
                misses = 0 if toolchain.game_running() else misses + 1
                if misses >= 2:
                    print("🛑 GTA SA-MP tidak terdeteksi lagi, bridge ditutup.")
                    os._exit(0)
                time.sleep(30)

        threading.Thread(target=_watch_game, daemon=True).start()

    print("=" * 68)
    print("🎵 MoonRadio YouTube Music Bridge & Streaming Server AKTIF!")
    print(f"   • Local Audio Stream : http://127.0.0.1:{BRIDGE_PORT}/stream/...")
    print(f"   • Bridge IPC Folder  : {PRIMARY_BRIDGE_DIR}")
    print(f"   • FFmpeg Transcoder  : {'Tersedia (' + bridge.ffmpeg_bin + ')' if bridge.ffmpeg_bin else 'Tidak ditemukan (Fallback Raw Stream)'}")
    print(f"   • yt-dlp             : {toolchain.status_line()} (auto-update aktif)")
    print("   • Cara Pakai di Game : Buka /radio atau ketik /rplay <judul lagu>")
    print("=" * 68)

    if bridge_only or not sys.stdin or not sys.stdin.isatty():
        print("🔄 Berjalan di mode Bridge Background. Tekan Ctrl+C untuk berhenti.")
        while True:
            time.sleep(1.0)
        return

    print("\n💡 Kamu bisa langsung mencari & memutar lagu dari dalam GTA SA-MP,")
    print("   atau ketik judul lagu di bawah untuk mengetes dari terminal (ketik 'q' untuk keluar):\n")

    ytm = bridge.ytm
    while True:
        query = input("Judul lagu (CLI / biarkan kosong untuk standby game): ").strip()
        if query.lower() in ("q", "quit", "exit"):
            break
        if not query:
            continue

        try:
            hasil = cari_lagu(ytm, query, limit=5)
        except Exception as e:
            print(f"❌ Gagal mencari: {e}\n")
            continue

        if not hasil:
            print("Lagu tidak ditemukan.\n")
            continue

        for i, lagu in enumerate(hasil, 1):
            print(format_hasil(i, lagu))

        pilih = input("Pilih nomor [1]: ").strip() or "1"
        if not pilih.isdigit() or not 1 <= int(pilih) <= len(hasil):
            print("Pilihan tidak valid.\n")
            continue

        lagu = hasil[int(pilih) - 1]
        print(f"\n▶  Memutar di CLI: {lagu['title']} ...")

        try:
            url, ua, _, _ = ambil_url_audio(lagu["videoId"])
        except Exception as e:
            print(f"❌ Gagal mengambil URL audio: {e}\n")
            continue

        putar(url, ua)
        print()


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print("\nSampai jumpa! 👋")