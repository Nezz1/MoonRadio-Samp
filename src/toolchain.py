"""
Manajemen alat eksternal MoonRadio: lokasi FFmpeg, yt-dlp (unduh otomatis +
update otomatis), dan ekstraksi URL audio.

yt-dlp TIDAK dibundel di dalam MoonRadioBridge.exe. Dipakai binary resmi
`yt-dlp.exe` dari GitHub Releases yang diunduh otomatis ke folder `bin/` dan
diperbarui sendiri, sehingga pemain tidak perlu merilis ulang paket tiap kali
YouTube mengubah sistemnya.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request

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
EXTRACT_TIMEOUT_SEC = 45

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
    req = urllib.request.Request(url, headers={"User-Agent": "MoonRadioBridge/2.0"})
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
        before = ytdlp_version()
        log(f"Memeriksa update yt-dlp (versi sekarang: {before or '?'})...")
        try:
            r = subprocess.run([p, "-U"], capture_output=True, text=True, timeout=180,
                               creationflags=_no_window())
            _write_stamp()
            after = ytdlp_version()
            if r.returncode != 0 and not after:
                raise RuntimeError((r.stderr or r.stdout).strip()[:200])
            log(f"yt-dlp: {before or '?'} -> {after or '?'}")
            return True
        except Exception as e:
            log(f"Update yt-dlp gagal ({e}); mencoba unduh ulang binary.")
            return download_ytdlp()


def ensure_ytdlp_async():
    """Dipanggil saat bridge start: pastikan yt-dlp ada & mutakhir (background)."""
    def worker():
        try:
            with _update_lock:
                if not ytdlp_path():
                    download_ytdlp()
                elif time.time() - _read_stamp() > UPDATE_INTERVAL_SEC:
                    update_ytdlp()
        finally:
            _status["ok"] = ytdlp_path() is not None
            _ready.set()
        # Pengecekan berkala selama bridge hidup
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


# ------------------------------------------------------------ Ekstraksi URL
def _run_extract(video_id: str) -> dict:
    p = ytdlp_path()
    if not p:
        raise RuntimeError("yt-dlp belum tersedia (sedang diunduh / tidak ada internet)")
    target_url = f"https://www.youtube.com/watch?v={video_id}"

    # Fast-path: IPv4 langsung + lewati unduhan HTML webpage/initial_data + cetak 4 kolom saja
    fast_cmd = [
        p, "-4", "-f", "bestaudio/best",
        "--no-playlist", "--no-warnings", "--no-progress", "--no-check-certificates",
        "--socket-timeout", "6",
        "--extractor-args", "youtube:player_skip=webpage,configs,initial_data",
        "--print", "%(url)s\t%(duration)s\t%(thumbnail)s\t%(http_headers.User-Agent)s",
        target_url,
    ]
    r = subprocess.run(
        fast_cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=20,
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
                return {
                    "url": url_out,
                    "duration": dur_val,
                    "thumbnail": None if thumb_out in ("", "NA") else thumb_out,
                    "http_headers": {"User-Agent": ua_out} if ua_out and ua_out != "NA" else {},
                }

    # Fallback penuh bila video butuh ekstraksi webpage standar
    cmd = [
        p, "-4", "-f", "bestaudio/best", "--no-playlist", "--no-warnings", "--no-progress",
        "--no-check-certificates", "--socket-timeout", "8", "--dump-single-json",
        target_url,
    ]
    r2 = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace",
                        timeout=EXTRACT_TIMEOUT_SEC, creationflags=_no_window())
    if r2.returncode != 0 or not r2.stdout.strip():
        msg = (r2.stderr or r.stderr or "yt-dlp gagal").strip().splitlines()
        raise RuntimeError(msg[-1][:160] if msg else "yt-dlp gagal")
    return json.loads(r2.stdout)


def ambil_url_audio(video_id: str) -> tuple[str, str | None, int, str | None]:
    """Ekstrak URL streaming audio (tanpa mengunduh). Auto-update yt-dlp lalu coba lagi bila gagal."""
    _ready.wait(timeout=90)  # tunggu unduhan/update awal selesai
    with _update_lock:       # jangan ekstrak saat binary sedang diganti
        pass
    try:
        info = _run_extract(video_id)
    except Exception as first_err:
        if force_update_if_allowed():
            info = _run_extract(video_id)
        else:
            raise first_err

    url = info.get("url")
    headers = info.get("http_headers") or {}
    if not url:
        fmts = info.get("requested_formats") or info.get("formats") or []
        audio = [f for f in fmts if f.get("url") and f.get("vcodec") in (None, "none")]
        pick = (audio or [f for f in fmts if f.get("url")] or [None])[-1]
        if not pick:
            raise RuntimeError("yt-dlp tidak mengembalikan URL audio")
        url = pick["url"]
        headers = pick.get("http_headers") or headers
    return url, headers.get("User-Agent"), int(info.get("duration") or 0), info.get("thumbnail")


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
