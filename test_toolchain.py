"""Tes cepat toolchain: unduh yt-dlp, ekstrak URL, cek update. Jalankan: python test_toolchain.py"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))
import toolchain

print("APP_DIR:", toolchain.APP_DIR)
print("ffmpeg :", toolchain.find_tool("ffmpeg"))
toolchain.ensure_ytdlp_async()
toolchain._ready.wait(180)
print("yt-dlp :", toolchain.status_line())
url, ua, dur, thumb = toolchain.ambil_url_audio("dQw4w9WgXcQ")
print("URL ok :", url[:80], "...")
print("UA     :", ua)
print("durasi :", dur, "| thumb:", bool(thumb))
print("update :", toolchain.update_ytdlp(), toolchain.status_line())
