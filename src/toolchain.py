"""
Manajemen alat & ekstraktor hibrida MoonRadio:
1. Global IPv4 Resolver (mencegah timeout IPv6 di ISP Indonesia).
2. In-Memory `yt_dlp.YoutubeDL` (0 detik proses startup, koneksi HTTP Keep-Alive).
3. Eksternal `yt-dlp.exe` dengan Auto-Update mandiri (fallback jika YouTube mengubah algoritma).
4. Automatic SoundCloud Fallback (`scsearch1:`) jika video YouTube diblokir/dibatasi.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import socket
import subprocess
import sys
import threading
import time
import urllib.request

# Paksa resolusi IPv4 secara global agar koneksi ke YouTube / GoogleVideo tidak pernah
# menggantung (timeout 8-10 detik) akibat rute IPv6 yang mati di banyak ISP.
_orig_getaddrinfo = socket.getaddrinfo


def _ipv4_getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    try:
        return _orig_getaddrinfo(host, port, socket.AF_INET, type, proto, flags)
    except Exception:
        return _orig_getaddrinfo(host, port, family, type, proto, flags)


socket.getaddrinfo = _ipv4_getaddrinfo

try:
    import yt_dlp as _inmem_ytdlp
except Exception:
    _inmem_ytdlp = None

IS_WINDOWS = os.name == "nt"
FROZEN = bool(getattr(sys, "frozen", False))

if FROZEN:
    APP_DIR = os.path.dirname(os.path.abspath(sys.executable))
else:
    APP_DIR = os.path.dirname(os.path.abspath(__file__))

BIN_DIR = os.path.join(APP_DIR, "bin")
STAMP_FILE = os.path.join(BIN_DIR, "ytdlp_update_stamp.txt")

UPDATE_INTERVAL_SEC = 12 * 3600       # cek update terjadwal tiap 12 jam
FORCED_UPDATE_COOLDOWN_SEC = 20 * 60  # update paksa saat gagal maks 1x / 20 menit
EXTRACT_TIMEOUT_SEC = 35


def _is_legacy_windows() -> bool:
    """Windows 7 / Vista (versi NT < 6.2): yt-dlp resmi tidak lagi mendukungnya."""
    if os.environ.get("MOONRADIO_WIN7") == "1":
        return True
    if not IS_WINDOWS:
        return False
    try:
        v = sys.getwindowsversion()
        return (v.major, v.minor) < (6, 2)
    except Exception:
        return False


IS_LEGACY_WIN = _is_legacy_windows()

# Windows 7: pakai build komunitas yang rutin mengikuti rilis resmi yt-dlp.
_GH = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/"
if IS_LEGACY_WIN:
    _GH = "https://github.com/nicolaasjan/yt-dlp/releases/latest/download/"
    _ASSET = "yt-dlp_x86_win7.exe"  # 32-bit: jalan di Win7 32/64-bit
elif IS_WINDOWS:
    _ASSET = "yt-dlp.exe"
elif sys.platform == "darwin":
    _ASSET = "yt-dlp_macos"
else:
    _ASSET = "yt-dlp_linux"
YTDLP_LOCAL_NAME = "yt-dlp.exe" if IS_WINDOWS else "yt-dlp"

_status = {"msg": "", "ok": False}
_update_lock = threading.RLock()
_ydl_lock = threading.Lock()
_ydl_instance = None
_ready = threading.Event()
_last_forced = 0.0


def log(msg: str):
    print(f"[toolchain] {msg}", flush=True)


def _no_window() -> int:
    if not IS_WINDOWS:
        return 0
    return getattr(subprocess, "CREATE_NO_WINDOW", 0x08000000) | getattr(
        subprocess, "BELOW_NORMAL_PRIORITY_CLASS", 0x00004000
    )


# ------------------------------------------------------------------ FFmpeg
def find_tool(name: str) -> str | None:
    """Cari ffmpeg/ffplay: folder aplikasi, bin/, lalu PATH sistem."""
    exe = name + (".exe" if IS_WINDOWS else "")
    for d in (APP_DIR, BIN_DIR, os.path.join(APP_DIR, "ffmpeg"), os.path.join(APP_DIR, "ffmpeg", "bin")):
        p = os.path.join(d, exe)
        if os.path.isfile(p):
            return p
    return shutil.which(name)


# ------------------------------------------------------------------ yt-dlp
def ytdlp_path() -> str | None:
    p = os.path.join(BIN_DIR, YTDLP_LOCAL_NAME)
    if os.path.isfile(p) and os.path.getsize(p) > 1_000_000:
        return p
    return shutil.which("yt-dlp")


def _http_get(url: str, timeout: int = 30) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "MoonRadioBridge/4.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def _verify_sha256(url_base: str, asset: str, data: bytes) -> bool:
    """Cocokkan hash dengan SHA2-256SUMS resmi. Jika daftar hash tak terjangkau, lewati."""
    try:
        sums = _http_get(url_base + "SHA2-256SUMS", 20).decode("utf-8", "ignore")
    except Exception:
        return True
    for line in sums.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[1].lstrip("*") == asset:
            return parts[0].lower() == hashlib.sha256(data).hexdigest()
    return True


def download_ytdlp() -> bool:
    os.makedirs(BIN_DIR, exist_ok=True)
    log(f"Mengunduh {_ASSET} dari GitHub...")
    _status["msg"] = "Mengunduh yt-dlp..."
    try:
        data = _http_get(_GH + _ASSET, timeout=120)
        if len(data) < 1_000_000:
            raise RuntimeError("file unduhan terlalu kecil")
        if not _verify_sha256(_GH, _ASSET, data):
            raise RuntimeError("checksum SHA-256 tidak cocok")
        target = os.path.join(BIN_DIR, YTDLP_LOCAL_NAME)
        tmp = target + ".download"
        with open(tmp, "wb") as f:
            f.write(data)
        os.replace(tmp, target)
        if not IS_WINDOWS:
            os.chmod(target, 0o755)
        _write_stamp()
        log("yt-dlp berhasil diunduh.")
        return True
    except Exception as e:
        log(f"Gagal mengunduh yt-dlp: {e}")
        _status["msg"] = f"Gagal mengunduh yt-dlp: {e}"
        return False


def _write_stamp():
    try:
        with open(STAMP_FILE, "w") as f:
            f.write(str(int(time.time())))
    except OSError:
        pass


def _read_stamp() -> float:
    try:
        with open(STAMP_FILE) as f:
            return float(f.read().strip())
    except (OSError, ValueError):
        return 0.0


def ytdlp_version() -> str:
    if _inmem_ytdlp is not None:
        try:
            return f"{_inmem_ytdlp.version.__version__} (In-Memory + Auto-Update)"
        except Exception:
            pass
    p = ytdlp_path()
    if not p:
        return ""
    try:
        out = subprocess.run([p, "--version"], capture_output=True, text=True,
                             timeout=30, creationflags=_no_window())
        return out.stdout.strip()
    except Exception:
        return ""


def _update_legacy(path: str) -> bool:
    """Build Win7 tidak punya `-U` resmi: bandingkan hash lokal dengan SHA2-256SUMS rilis terbaru."""
    log("Memeriksa update yt-dlp (build Windows 7)...")
    try:
        sums = _http_get(_GH + "SHA2-256SUMS", 20).decode("utf-8", "ignore")
        remote = ""
        for line in sums.splitlines():
            parts = line.split()
            if len(parts) >= 2 and parts[1].lstrip("*") == _ASSET:
                remote = parts[0].lower()
        with open(path, "rb") as f:
            local = hashlib.sha256(f.read()).hexdigest()
        _write_stamp()
        if remote and remote != local:
            return download_ytdlp()
        log("yt-dlp sudah terbaru.")
        return True
    except Exception as e:
        log(f"Cek update gagal: {e}")
        return False


def update_ytdlp() -> bool:
    """Update yt-dlp ke rilis terbaru (self-update resmi `-U`). Aman dipanggil dari thread mana pun."""
    with _update_lock:
        p = os.path.join(BIN_DIR, YTDLP_LOCAL_NAME)
        if not os.path.isfile(p):
            return download_ytdlp()
        if IS_LEGACY_WIN:
            return _update_legacy(p)
        log("Memeriksa update yt-dlp eksternal...")
        try:
            r = subprocess.run([p, "-U"], capture_output=True, text=True, timeout=180,
                               creationflags=_no_window())
            _write_stamp()
            if r.returncode != 0:
                raise RuntimeError((r.stderr or r.stdout).strip()[:200])
            return True
        except Exception as e:
            log(f"Update yt-dlp gagal ({e}); mencoba unduh ulang binary.")
            return download_ytdlp()


def ensure_ytdlp_async():
    """Dipanggil saat bridge start: pastikan yt-dlp siap di RAM dan binary cadangan ter-update di background."""
    if _inmem_ytdlp is not None:
        _status["ok"] = True
        _ready.set()

    def worker():
        try:
            with _update_lock:
                if not ytdlp_path():
                    download_ytdlp()
                elif time.time() - _read_stamp() > UPDATE_INTERVAL_SEC:
                    update_ytdlp()
        finally:
            _status["ok"] = (_inmem_ytdlp is not None) or (ytdlp_path() is not None)
            _ready.set()
        while True:
            time.sleep(1800)
            if time.time() - _read_stamp() > UPDATE_INTERVAL_SEC:
                update_ytdlp()

    threading.Thread(target=worker, daemon=True, name="ytdlp-updater").start()


def force_update_if_allowed() -> bool:
    global _last_forced
    now = time.time()
    if now - _last_forced < FORCED_UPDATE_COOLDOWN_SEC:
        return False
    _last_forced = now
    return update_ytdlp()


# ------------------------------------------------------------ Ekstraksi Hibrida (In-Memory + Binary + SoundCloud)
def _get_inmem_ydl():
    global _ydl_instance
    if _inmem_ytdlp is None:
        return None
    if _ydl_instance is None:
        _ydl_instance = _inmem_ytdlp.YoutubeDL({
            "format": "bestaudio[protocol^=http][protocol!=http_dash_segments]/bestaudio/best",
            "noplaylist": True,
            "quiet": True,
            "no_warnings": True,
            "nocheckcertificate": True,
            "source_address": "0.0.0.0",
            "socket_timeout": 6,
            "extractor_args": {
                "youtube": {
                    "player_skip": ["hls", "dash", "configs", "initial_data"],
                }
            },
        })
    return _ydl_instance


def _pick_url_from_info(info: dict) -> tuple[str, str | None, int, str | None]:
    url = info.get("url")
    headers = info.get("http_headers") or {}
    if not url:
        fmts = info.get("requested_formats") or info.get("formats") or []
        audio = [
            f for f in fmts
            if f.get("url")
            and f.get("vcodec") in (None, "none")
            and str(f.get("protocol", "")).startswith("http")
            and "dash" not in str(f.get("protocol", ""))
        ]
        if not audio:
            audio = [f for f in fmts if f.get("url") and f.get("vcodec") in (None, "none")]
        pick = (audio or [f for f in fmts if f.get("url")] or [None])[-1]
        if not pick:
            raise RuntimeError("Tidak ada URL stream audio yang valid")
        url = pick["url"]
        headers = pick.get("http_headers") or headers
    return url, headers.get("User-Agent"), int(info.get("duration") or 0), info.get("thumbnail")


def _extract_via_inmem(target: str) -> tuple[str, str | None, int, str | None]:
    ydl = _get_inmem_ydl()
    if ydl is None:
        raise RuntimeError("In-memory yt_dlp tidak tersedia")
    with _ydl_lock:
        info = ydl.extract_info(target, download=False)
    if not info:
        raise RuntimeError("Ekstraksi in-memory kosong")
    if "entries" in info:
        entries = [e for e in (info.get("entries") or []) if e]
        if not entries:
            raise RuntimeError("Hasil pencarian fallback kosong")
        info = entries[0]
    return _pick_url_from_info(info)


def _extract_via_binary(target: str) -> tuple[str, str | None, int, str | None]:
    p = ytdlp_path()
    if not p:
        raise RuntimeError("yt-dlp.exe belum tersedia")
    # Penting: JANGAN lewati `webpage` karena lagu berlisensi resmi membutuhkan webpage untuk visitorData/signature
    fast_cmd = [
        p, "-4", "-f", "bestaudio[protocol^=http][protocol!=http_dash_segments]/bestaudio/best",
        "--no-playlist", "--no-warnings", "--no-progress", "--no-check-certificates",
        "--socket-timeout", "6",
        "--extractor-args", "youtube:player_skip=hls,dash,configs,initial_data",
        "--print", "%(url)s\t%(duration)s\t%(thumbnail)s\t%(http_headers.User-Agent)s",
        target,
    ]
    r = subprocess.run(
        fast_cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=EXTRACT_TIMEOUT_SEC,
        creationflags=_no_window(),
    )
    if r.returncode == 0 and r.stdout.strip():
        lines = [ln.strip() for ln in r.stdout.splitlines() if ln.strip()]
        if lines:
            parts = lines[-1].split("\t")
            url_out = parts[0].strip() if len(parts) > 0 else ""
            if url_out.startswith("http"):
                dur_str = parts[1].strip() if len(parts) > 1 else "0"
                thumb_out = parts[2].strip() if len(parts) > 2 else ""
                ua_out = parts[3].strip() if len(parts) > 3 else ""
                try:
                    dur_val = int(float(dur_str)) if dur_str and dur_str != "NA" else 0
                except ValueError:
                    dur_val = 0
                return (
                    url_out,
                    None if ua_out in ("", "NA") else ua_out,
                    dur_val,
                    None if thumb_out in ("", "NA") else thumb_out,
                )

    msg = (r.stderr or "yt-dlp gagal").strip().splitlines()
    raise RuntimeError(msg[-1][:160] if msg else "yt-dlp gagal")


def ambil_url_audio(video_id: str, title: str = "", artist: str = "") -> tuple[str, str | None, int, str | None]:
    """
    Mesin Ekstraksi Hibrida 3-Lapis:
      1. In-Memory `yt_dlp.YoutubeDL` (1.1 - 1.8 detik, tanpa buka .exe eksternal).
      2. Binary `yt-dlp.exe` Auto-Updated (untuk Windows 7 atau jika YouTube mengubah sistem).
      3. Automatic SoundCloud Fallback (`scsearch1:`) jika video YouTube kena blokir/pembatasan usia.
    """
    yt_url = f"https://www.youtube.com/watch?v={video_id}"
    last_err: Exception | None = None

    # Lapis 1: In-Memory yt_dlp (Instan tanpa overhead spawn .exe)
    if _inmem_ytdlp is not None:
        try:
            return _extract_via_inmem(yt_url)
        except Exception as e:
            last_err = e

    # Lapis 2: Binary eksternal yt-dlp.exe (dengan dukungan auto-update mandiri)
    _ready.wait(timeout=45)
    if ytdlp_path():
        try:
            return _extract_via_binary(yt_url)
        except Exception as e:
            last_err = e
            if force_update_if_allowed():
                try:
                    return _extract_via_binary(yt_url)
                except Exception as e2:
                    last_err = e2

    # Lapis 3: Fallback otomatis ke SoundCloud jika lagu memiliki judul/artis dan YouTube bermasalah
    search_q = f"{title} {artist}".strip()
    if search_q and search_q.lower() != video_id.lower():
        sc_target = f"scsearch1:{search_q}"
        log(f"YouTube gagal untuk {video_id}, beralih otomatis ke SoundCloud: '{search_q}'")
        if _inmem_ytdlp is not None:
            try:
                return _extract_via_inmem(sc_target)
            except Exception as e:
                last_err = e
        if ytdlp_path():
            try:
                return _extract_via_binary(sc_target)
            except Exception as e:
                last_err = e

    raise RuntimeError(str(last_err) if last_err else "Gagal mengambil stream audio")


def status_line() -> str:
    v = ytdlp_version()
    return f"yt-dlp {v}" if v else (_status["msg"] or "yt-dlp belum tersedia")


# ------------------------------------------------------------ Proses game
def game_running() -> bool:
    """True bila proses GTA SA / SA-MP terdeteksi (Windows). Non-Windows: selalu True."""
    if not IS_WINDOWS:
        return True
    try:
        out = subprocess.run(["tasklist", "/FO", "CSV", "/NH"], capture_output=True, text=True,
                             timeout=15, creationflags=_no_window()).stdout.lower()
    except Exception:
        return True
    return any(n in out for n in ("gta_sa.exe", "gta-sa.exe", "samp.exe", "gta_sa_dx9.exe"))
