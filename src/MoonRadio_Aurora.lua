script_name('MoonRadio')
script_author('Nezxa')
script_version('4.0.0-YTM')
script_description('MoonRadio Zenith v4.0 YouTube Music Edition: Direct YT Music Streaming, Studio Audio FX, Visualizer, LRC & HUD')

--[[
  MoonRadio ZENITH v3.5 (Glassmorphism & Free Control Edition)
  Untuk MoonLoader (GTA SA-MP) | Butuh: MoonLoader, SAMPFUNCS, mimgui (lib/mimgui)

  Arsitektur Visual & UI/UX (mengikuti pedoman antislop-ui):
  - [R-01 / R-29] Palet Terkendali: 2-3 warna permukaan netral (matte/frosted) + 1 warna aksen pilihan.
    Menghapus gradien biru-ungu generik dan warna-warni berlebihan pada badge/header.
  - [R-10] Glassmorphism Terukur (Dose Cap): Efek kaca (translucent acrylic + top specular catchlight
    + inner hairline) diterapkan secara terarah pada layer fokal (Window Backdrop, Floating Transport Dock,
    Hero/Stage Deck, Compact Deck, dan In-Game HUD), sedangkan kartu daftar & pengaturan menggunakan
    permukaan matte bersih agar hierarki visual tetap tajam.
  - [R-11] Skala Border Radius Deliberate:
    Window/HUD = 16px | Kartu/Panel = 12px | Kontrol/Tombol/Input = 8px | Tag/Badge = 6px | CTA Utama = Pill.
  - [R-12 / R-13] Elevasi & Glow Fokal: Bayangan (shadow) dan pendaran (glow) hanya pada elemen fokal aktif.
  - [R-06 / R-09 / R-31] Tipografi & Dekorasi Bersih: Tanpa garis samping warna-warni dekoratif tanpa arti,
    tanpa badge eyebrow duplikat di atas judul, dan indikator titik status hanya menyala saat pemutaran aktif.

  Fitur Kontrol Bebas (Free Control Suite):
  1. Jendela Utama Bebas Geser & Ubah Ukuran (Free Drag & Corner Resize Grip + Klik Kanan Grip untuk Reset).
  2. Mode Compact Glass Deck (/rcompact atau tombol Compact di Top Bar): Tampilan melayang ringkas dengan
     kontrol penuh (Vinyl, Lirik, Seek Bar, Transport, Volume, Quick FX).
  3. Transparansi Kaca Bebas (Glass Frost Opacity 55% - 98%) & 2 Slot Memori Custom FX (Custom A & Custom B).
  4. Mini Player HUD Interaktif: Saat kursor aktif, arahkan mouse ke Mini HUD untuk klik Play/Pause, Next,
     Prev, Favorit, geser Seek Bar, atau putar Scroll Wheel untuk mengatur Volume.
  5. Editor Tata Letak HUD Bebas (/rminipos): Geser posisi & atur ukuran Mini Player HUD sekaligus
     Floating Karaoke Overlay secara bebas di layar dengan garis bantu magnetik (center snap guides).
  6. Kontrol Antrean Bebas (Queue Reorder): Geser urutan lagu (Naik/Turun), Hapus item, atau Bersihkan antrean.
  7. Scroll Wheel Fine-Tuning: Putar roda mouse di atas slider mana pun (Volume, Seek, EQ, Speed, Reverb, Pan)
     untuk pengaturan presisi tanpa perlu tahan klik, dan klik kanan slider untuk reset ke nilai tengah.
  8. 9 Slot Hotkey Bebas (Menu, Compact, Play/Pause, Next, Prev, Vol+, Vol-, Favorit, Karaoke).

  Command SAMP:
    /radio          - Buka/tutup jendela MoonRadio
    /rplay [judul]  - Cari & langsung putar lagu dari YouTube Music (tanpa buka menu!)
    /ryt [judul]    - Alias cepat untuk /rplay [judul lagu]
    /rcari [judul]  - Cari lagu di YouTube Music & tampilkan daftar hasilnya
    /rcompact       - Toggle Mode Compact Glass Deck
    /rnext /rprev   - Lagu berikutnya / sebelumnya
    /rpause         - Play / Pause
    /rvol [0-100]   - Atur volume cepat
    /rglass [55-98] - Atur tingkat keburaman kaca (Glass Opacity)
    /rmix           - Campur & acak semua playlist
    /rall           - Acak semua koleksi lagu
    /rfav           - Favoritkan / batal favorit lagu yang sedang diputar
    /rsleep [menit] - Pasang sleep timer otomatis (fade-out halus)
    /rmini          - Nyalakan / matikan Mini Player HUD
    /rminipos       - Buka Editor Tata Letak HUD Bebas (Mini HUD & Karaoke)
    /rministyle     - Ganti gaya visual Mini Player (Island / GlassDeck / Vinyl / Minimal)
    /rlyrics        - Buka tab Lirik
    /rkaraoke       - Toggle Floating Desktop Karaoke Lyrics di layar game
    /rfx [0-7]      - Ganti preset Studio Audio FX (Normal/BassBoost/Vocal/Nightcore/Slowed/LoFi/Hall)
    /rspeed [50-150]- Atur kecepatan & pitch lagu (50% - 150%)
    /rsmart         - Toggle Smart Shuffle Pintar (Anti-Tabrakan Genre/Mood)
    /rautomix       - Toggle Auto Smart Mix saat pilih lagu tanpa playlist
]]

require 'lib.moonloader'
local imgui  = require 'mimgui'
local ffi    = require 'ffi'
local bit    = require 'bit'
local lfs    = require 'lfs'
local inicfg = require 'inicfg'

-- ======================================================================
-- CONFIG & STATE DEFAULTS (WITH FREE CONTROL & GLASSMORPHISM SETTINGS)
-- ======================================================================
local cfg = inicfg.load({
  main = {
    volume = 0.72, shuffle = false, repeatMode = 1, -- 0 off, 1 semua, 2 satu lagu
    accent = 1, surface = 1, toast = true, toastPos = 2, autoResume = false,
    key = 121, lastList = 'lib', lastKey = '',
    -- Window Geometry & Glassmorphism (Free Control)
    winW = 1080, winH = 680, winX = -1, winY = -1,
    compact = false, compactX = -1, compactY = -1,
    glassAlpha = 88, -- 55 .. 98 (%)
    -- Mini player
    mini = true, miniStyle = 1, miniPos = 1, miniX = 0, miniY = 0,
    miniFX = -1, miniFY = -1, miniScale = 2, miniOpacity = 86,
    miniLyrics = true, miniHidePause = true, miniInteractive = true,
    -- Karaoke overlay & Free Position/Scale
    karaoke = false, karaokePos = 1, -- 1 bawah, 2 atas
    karaokeFX = -1, karaokeFY = -1, karaokeScale = 2,
    -- Workspace UI
    visStyle = 1,   -- 1 Spectrum Pillars, 2 Acoustic Wave, 3 Vinyl Pulse
    playerArtStyle = 1, -- 1 Cover Art Langsung (YT Music), 2 Vinyl Disc Berputar, 3 Cover Bawah + Vinyl Stage
    drawer = true,  -- panel inspektor kanan (Queue / Lirik cepat / Studio FX)
    drawerTab = 1,  -- 1 Antrean, 2 Lirik Cepat, 3 Quick FX
    -- Audio FX & Smart Features
    fxPreset = 1,   -- 1 Flat, 2 Bass Boost, 3 Vocal Crystal, 4 Nightcore, 5 Slowed+Reverb, 6 Lo-Fi Radio, 7 Concert Hall, 8 Custom
    eqBass = 0, eqMid = 0, eqTreble = 0, -- -12 .. +12 dB
    speed = 100,    -- 50 .. 150 (%)
    reverb = 0,     -- 0 .. 100 (%)
    pan = 0,        -- -100 .. +100
    -- 2 User Custom FX Memory Slots
    c1Bass = 6, c1Mid = 2, c1Treble = 4, c1Speed = 100, c1Reverb = 15, c1Pan = 0,
    c2Bass = 4, c2Mid = -1, c2Treble = -2, c2Speed = 88, c2Reverb = 45, c2Pan = 0,
    smoothFade = true,
    carDuck = false, carBoost = 20,
    -- Smart Shuffle & Auto Mix
    smartShuffle = true,
    smartAvoidClash = true,
    autoMix = true,
    autoMixLooseOnly = false,
    autoMixCount = 30,
    showVibeBadge = true,
    lyricAutoScroll = true,
    -- Expanded Free Hotkeys (9 Slots)
    keyNext = 176, keyPrev = 177, keyPause = 179,
    keyFav = 0, keyKaraoke = 0, keyCompact = 0,
    keyVolUp = 0, keyVolDn = 0
  }
}, 'moonradio.ini')

local DEFAULTS = {
  winW = 1080, winH = 680, winX = -1, winY = -1,
  compact = false, compactX = -1, compactY = -1, glassAlpha = 88,
  mini = true, miniStyle = 1, miniPos = 1, miniX = 0, miniY = 0,
  miniFX = -1, miniFY = -1, miniScale = 2, miniOpacity = 86,
  miniLyrics = true, miniHidePause = true, miniInteractive = true,
  surface = 1, toastPos = 2,
  karaoke = false, karaokePos = 1, karaokeFX = -1, karaokeFY = -1, karaokeScale = 2,
  visStyle = 1, playerArtStyle = 1, drawer = true, drawerTab = 1,
  fxPreset = 1, eqBass = 0, eqMid = 0, eqTreble = 0,
  speed = 100, reverb = 0, pan = 0,
  c1Bass = 6, c1Mid = 2, c1Treble = 4, c1Speed = 100, c1Reverb = 15, c1Pan = 0,
  c2Bass = 4, c2Mid = -1, c2Treble = -2, c2Speed = 88, c2Reverb = 45, c2Pan = 0,
  smoothFade = true, carDuck = false, carBoost = 20,
  smartShuffle = true, smartAvoidClash = true,
  autoMix = true, autoMixLooseOnly = false, autoMixCount = 30,
  showVibeBadge = true, lyricAutoScroll = true,
  keyNext = 176, keyPrev = 177, keyPause = 179,
  keyFav = 0, keyKaraoke = 0, keyCompact = 0, keyVolUp = 0, keyVolDn = 0
}
for k, v in pairs(DEFAULTS) do
  if cfg.main[k] == nil then cfg.main[k] = v end
end

local XT = {
  sleepAt = 0, sleepI = 1, sleepOpts = { 0, 15, 30, 45, 60, 90, 120 },
  sesSongs = 0, sesStart = os.clock(),
  vkn = {
    [8] = 'Backspace', [9] = 'Tab', [13] = 'Enter', [19] = 'Pause', [20] = 'CapsLock', [32] = 'Space',
    [33] = 'PgUp', [34] = 'PgDn', [35] = 'End', [36] = 'Home', [37] = 'Kiri', [38] = 'Atas', [39] = 'Kanan', [40] = 'Bawah',
    [45] = 'Insert', [46] = 'Delete', [176] = 'Media Next', [177] = 'Media Prev', [178] = 'Media Stop', [179] = 'Media Play',
    [186] = ';', [187] = '=', [188] = ',', [189] = '-', [190] = '.', [191] = '/', [192] = '`', [219] = '[', [220] = '\\',
    [221] = ']', [222] = "'"
  }
}

local MINI = {
  POS = { 'Tengah Atas', 'Kanan Atas', 'Kiri Atas', 'Kiri Bawah', 'Kanan Bawah', 'Tengah Bawah' },
  STYLES = { 'Dynamic Island', 'Glass Deck', 'Vinyl Turntable', 'Minimal Ribbon' },
  SCALES = { 0.85, 1.0, 1.20, 1.42 }, SNAMES = { 'Kecil', 'Normal', 'Besar', 'Jumbo' },
  KSCALES = { 0.85, 1.0, 1.22 }, KSNAMES = { 'Kecil', 'Normal', 'Besar' },
  W = 320, H = 70, PAD = 14, MARGIN = 16,
  IDLE_HIDE = 6,
  t = 0, want = false, edit = false, lastStart = -1, flash = -10, t0 = 0, sp = 0, lastPlay = 0, hoverT = 0
}

local cfgDirty = false
local function saveCfg() pcall(inicfg.save, cfg, 'moonradio.ini'); cfgDirty = false end
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end

local ROOT    = getWorkingDirectory() .. '\\radio'
local TEMPDIR = os.getenv('TEMP') or os.getenv('TMP') or ROOT
local BRIDGE  = TEMPDIR .. '\\moonradio_bridge'
local PLUG    = ROOT .. '\\plugins'
local STFILE  = ROOT .. '\\stations.txt'
local PLFILE  = ROOT .. '\\playlists.txt'
local BMFILE  = ROOT .. '\\bookmarks.txt'
local VBFILE  = ROOT .. '\\vibes.txt'
local CATFILE = ROOT .. '\\yt_catalog.txt'

local function ensureDirs()
  pcall(lfs.mkdir, ROOT)
  pcall(lfs.mkdir, BRIDGE)
  pcall(lfs.mkdir, PLUG)
end
ensureDirs()
math.randomseed(os.time())

-- ======================================================================
-- BASS AUDIO ENGINE + DX8 STUDIO FX
-- ======================================================================
ffi.cdef[[
uint32_t __stdcall BASS_StreamCreateFile(int mem, const void* file, uint64_t offset, uint64_t length, uint32_t flags);
uint32_t __stdcall BASS_StreamCreateURL(const char* url, uint32_t offset, uint32_t flags, void* proc, void* user);
int      __stdcall BASS_StreamFree(uint32_t handle);
int      __stdcall BASS_ChannelPlay(uint32_t handle, int restart);
int      __stdcall BASS_ChannelPause(uint32_t handle);
int      __stdcall BASS_ChannelStop(uint32_t handle);
uint32_t __stdcall BASS_ChannelIsActive(uint32_t handle);
uint64_t __stdcall BASS_ChannelGetLength(uint32_t handle, uint32_t mode);
uint64_t __stdcall BASS_ChannelGetPosition(uint32_t handle, uint32_t mode);
int      __stdcall BASS_ChannelSetPosition(uint32_t handle, uint64_t pos, uint32_t mode);
double   __stdcall BASS_ChannelBytes2Seconds(uint32_t handle, uint64_t pos);
uint64_t __stdcall BASS_ChannelSeconds2Bytes(uint32_t handle, double pos);
int      __stdcall BASS_ChannelSetAttribute(uint32_t handle, uint32_t attrib, float value);
int      __stdcall BASS_ChannelGetAttribute(uint32_t handle, uint32_t attrib, float* value);
uint32_t __stdcall BASS_ChannelGetData(uint32_t handle, void* buffer, uint32_t length);
uint32_t __stdcall BASS_ChannelGetLevel(uint32_t handle);
const char* __stdcall BASS_ChannelGetTags(uint32_t handle, uint32_t tags);
int      __stdcall BASS_ErrorGetCode(void);
int      __stdcall BASS_SetConfig(uint32_t option, uint32_t value);
uint32_t __stdcall BASS_PluginLoad(const char* file, uint32_t flags);
uint32_t __stdcall BASS_ChannelSetFX(uint32_t handle, uint32_t type, int priority);
int      __stdcall BASS_ChannelRemoveFX(uint32_t handle, uint32_t fx);
int      __stdcall BASS_FXSetParameters(uint32_t handle, const void* params);
void*    __stdcall ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);

typedef struct {
  float fCenter;
  float fBandwidth;
  float fGain;
} BASS_DX8_PARAMEQ;

typedef struct {
  float fInGain;
  float fReverbMix;
  float fReverbTime;
  float fHighFreqRTRatio;
} BASS_DX8_REVERB;
]]

local okBass, BASS = pcall(ffi.load, 'bass')
if not okBass then okBass, BASS = pcall(ffi.load, getGameDirectory() .. '\\bass.dll') end
assert(okBass, 'MoonRadio: bass.dll tidak ditemukan')

pcall(function()
  BASS.BASS_SetConfig(11, 8000) -- NET_TIMEOUT
  BASS.BASS_SetConfig(12, 3000) -- NET_BUFFER (3000 ms)
  BASS.BASS_SetConfig(15, 15)   -- NET_PREBUF (15% = ~10.8 KB, langsung terpenuhi instan dari prebuffer RAM 16 KB)
  BASS.BASS_SetConfig(21, 1)    -- NET_PLAYLIST (.pls / .m3u)
end)

local ERRTXT = {
  [1] = 'Memori tidak cukup', [2] = 'Gagal membuka file / link', [6] = 'Format tidak didukung (butuh plugin?)',
  [8] = 'BASS belum siap', [32] = 'Tidak ada koneksi internet', [37] = 'Fitur tidak tersedia',
  [40] = 'Koneksi timeout', [41] = 'Format file tidak dikenali', [44] = 'Codec tidak tersedia'
}
local LEN_ERR = 0xFFFFFFFFFFFFFFFFULL

local plugins = {}
local function loadPlugins()
  plugins = {}
  pcall(function()
    for f in lfs.dir(PLUG) do
      if f:lower():match('%.dll$') then
        local h = BASS.BASS_PluginLoad(PLUG .. '\\' .. f, 0)
        if h ~= 0 then plugins[#plugins + 1] = f end
      end
    end
  end)
end

local shell32Lib = nil
local function openFolder(path)
  pcall(function()
    if not shell32Lib then shell32Lib = ffi.load('shell32') end
    shell32Lib.ShellExecuteA(nil, 'open', path, nil, nil, 1)
  end)
end

-- ======================================================================
-- NOTIFICATION & TOAST ENGINE
-- ======================================================================
local TOASTS = { list = {} }
local FL = { text = '', untilT = 0, err = false, sub = '' }

local function pushToast(title, sub, kind, dur)
  dur = dur or 2.8
  local now = os.clock()
  for _, item in ipairs(TOASTS.list) do
    if item.kind == kind and kind ~= 'track' then
      item.title = title
      item.sub = sub or ''
      item.untilT = now + dur
      return
    end
  end
  TOASTS.list[#TOASTS.list + 1] = {
    title = title, sub = sub or '', kind = kind or 'info',
    startT = now, untilT = now + dur
  }
  if #TOASTS.list > 4 then table.remove(TOASTS.list, 1) end
end

local function flash(msg, isErr, sub)
  FL.text = msg
  FL.sub = sub or ''
  FL.untilT = os.clock() + 2.5
  FL.err = isErr and true or false
  pushToast(msg, sub or (isErr and 'Periksa kembali aksi kamu' or 'MoonRadio Studio'), isErr and 'err' or 'info', 2.5)
end

-- ======================================================================
-- TEXT / ID3 / LRC / BOOKMARKS UTILS (OPTIMIZED SINGLE-BUFFER READER)
-- ======================================================================
local function trim(s) return (s:gsub('^%s+', ''):gsub('[%s%z]+$', '')) end

XT.sanitizeGlyphs = function(s)
  if not s or s == '' then return '' end
  s = s:gsub('\239\187\191', '')
       :gsub('\226\128[\139-\143]', '')
       :gsub('\239\184[\142\143]', '')
  s = s:gsub('\226\128[\146-\149]', '-')
       :gsub('\226\136\146', '-')
       :gsub('\226\128[\152-\155]', "'")
       :gsub('\226\128[\156-\159]', '"')
       :gsub('\194\171', '"'):gsub('\194\187', '"')
       :gsub('\226\128\166', '...')
       :gsub('\226\128\162', '-'):gsub('\194\183', '-')
       :gsub('\195\151', 'x')
  s = s:gsub('\226[\152-\159][\128-\191]', '')
       :gsub('[\225-\239][\128-\191][\128-\191]', '')
       :gsub('[\240-\244][\128-\191][\128-\191][\128-\191]', '')
  return s
end

XT.isUtf8 = function(s)
  local i, n = 1, #s
  while i <= n do
    local c = s:byte(i)
    local len = c < 0x80 and 1 or (c >= 0xC2 and c < 0xE0) and 2 or (c >= 0xE0 and c < 0xF0) and 3 or (c >= 0xF0 and c < 0xF5) and 4 or 0
    if len == 0 or i + len - 1 > n then return false end
    for k = 1, len - 1 do
      local cc = s:byte(i + k)
      if cc < 0x80 or cc > 0xBF then return false end
    end
    i = i + len
  end
  return true
end

XT.latin1ToUtf8 = function(s)
  return (s:gsub('[\128-\255]', function(c)
    local b = c:byte()
    return string.char(0xC0 + math.floor(b / 64), 0x80 + b % 64)
  end))
end

local function fixText(s)
  if not s or s == '' then return '' end
  if not XT.isUtf8(s) then s = XT.latin1ToUtf8(s) end
  return trim(XT.sanitizeGlyphs(s))
end

XT.utf8char = function(cp)
  if cp < 0x80 then return string.char(cp)
  elseif cp < 0x800 then return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
  elseif cp < 0x10000 then return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
  else return string.char(0xF0 + math.floor(cp / 262144), 0x80 + math.floor(cp / 4096) % 64, 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64) end
end

XT.utf16ToUtf8 = function(s, be)
  local out, i = {}, 1
  if s:sub(1, 2) == '\255\254' then be = false; i = 3
  elseif s:sub(1, 2) == '\254\255' then be = true; i = 3 end
  while i + 1 <= #s do
    local b1, b2 = s:byte(i, i + 1)
    local cp = be and (b1 * 256 + b2) or (b2 * 256 + b1)
    i = i + 2
    if cp >= 0xD800 and cp < 0xDC00 and i + 1 <= #s then
      local c1, c2 = s:byte(i, i + 1)
      local lo = be and (c1 * 256 + c2) or (c2 * 256 + c1)
      i = i + 2
      cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
    end
    if cp == 0 then break end
    out[#out + 1] = XT.utf8char(cp)
  end
  return XT.sanitizeGlyphs(table.concat(out))
end

XT.decodeText = function(d, unsync)
  if not d or #d < 2 then return nil end
  if unsync then d = d:gsub('\255%z', '\255') end
  local enc, body, s = d:byte(1), d:sub(2), nil
  if enc == 0 then s = fixText(body:match('^[^%z]*'))
  elseif enc == 1 then s = XT.utf16ToUtf8(body, false)
  elseif enc == 2 then s = XT.utf16ToUtf8(body, true)
  else s = fixText(body:match('^[^%z]*')) end
  s = trim(s or '')
  if s == '' then return nil end
  return s
end

-- ---------- Lyrics & Cover Art Loader (YouTube Music & LRCLIB Bridge Cache) ----------
local S
local lyricOffset = 0.0
local lyrCache = { at = -1, pos = -1, off = 0, src = nil, idx = nil, cur = nil, nxt = nil, prog = 0 }

XT.invalidateLyricCache = function()
  lyrCache.at = -1
  lyrCache.src = nil
end

XT.lyricLines = function(text)
  local out = {}
  text = fixText(text or '')
  for line in text:gmatch('[^\r\n]+') do
    line = trim(line)
    if line ~= '' then out[#out + 1] = { text = line } end
  end
  return out
end

XT.parseLrc = function(raw)
  local out = {}
  raw = (raw or ''):gsub('^\239\187\191', '')
  for line in raw:gmatch('[^\r\n]+') do
    local stamps = {}
    for tag in line:gmatch('%[[%d:%.]+%]') do
      local mm, ss, frac = tag:match('%[(%d+):(%d+)%.(%d+)%]')
      if not mm then mm, ss = tag:match('%[(%d+):(%d+)%]') end
      if mm and ss then
        local f = tonumber(frac or '0') or 0
        local scale = frac and (#frac == 1 and 10 or #frac == 2 and 100 or 1000) or 1
        stamps[#stamps + 1] = tonumber(mm) * 60 + tonumber(ss) + f / scale
      end
    end
    local text = fixText(line:gsub('%[[%d:%.]+%]', ''))
    if text ~= '' then
      for _, stamp in ipairs(stamps) do out[#out + 1] = { time = stamp, text = text } end
    end
  end
  table.sort(out, function(a, b) return a.time < b.time end)
  return out
end

local function readFile(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local d = f:read('*a'); f:close()
  return d
end

local function extractVideoId(trackOrPath)
  if type(trackOrPath) == 'table' then
    if trackOrPath.videoId and trackOrPath.videoId ~= '' then return trackOrPath.videoId end
    trackOrPath = trackOrPath.path
  end
  if type(trackOrPath) ~= 'string' then return nil end
  return trackOrPath:match('^yt:(.+)$') or trackOrPath
end

XT.loadTrackLyrics = function(track)
  local vid = extractVideoId(track)
  if not vid or vid == '' then return nil end
  local lrcFile = BRIDGE .. '\\lyr_' .. vid .. '.lrc'
  if doesFileExist(lrcFile) then
    local raw = readFile(lrcFile)
    if raw and #raw > 8 then
      local lines = XT.parseLrc(raw)
      if #lines > 0 then
        if type(track) == 'table' then track.hasLrc = true end
        return { lines = lines, timed = true, source = (track and track.lyrSource) or 'YouTube Music / LRCLIB Synced' }
      end
      local plain = XT.lyricLines(raw)
      if #plain > 0 then
        if type(track) == 'table' then track.hasLrc = true end
        return { lines = plain, timed = false, source = (track and track.lyrSource) or 'YouTube Music Lyrics' }
      end
    end
  end
  return nil
end

XT.refreshLyricCache = function()
  if not S or not S.lyrics or not S.lyrics.lines or #S.lyrics.lines == 0 then
    lyrCache.src = nil; lyrCache.idx = nil; lyrCache.cur = nil; lyrCache.nxt = nil; lyrCache.prog = 0
    return
  end
  local now = os.clock()
  local pos = S.pos or 0
  if lyrCache.src == S.lyrics and lyrCache.off == lyricOffset and math.abs(now - lyrCache.at) < 0.04 and math.abs(pos - lyrCache.pos) < 0.04 then
    return
  end
  lyrCache.at = now
  lyrCache.pos = pos
  lyrCache.off = lyricOffset
  lyrCache.src = S.lyrics
  local lines = S.lyrics.lines
  if not S.lyrics.timed then
    local dur = math.max(30, S.dur or 180)
    local frac = clamp(pos / dur, 0, 0.999)
    local estIdx = clamp(math.floor(frac * #lines) + 1, 1, #lines)
    lyrCache.idx = estIdx
    lyrCache.cur = lines[estIdx] and lines[estIdx].text or nil
    lyrCache.nxt = lines[estIdx + 1] and lines[estIdx + 1].text or nil
    local lineSpan = dur / math.max(1, #lines)
    lyrCache.prog = clamp((pos - (estIdx - 1) * lineSpan) / math.max(0.5, lineSpan), 0, 1)
    return
  end
  local adjPos = pos - lyricOffset
  local active = 1
  for i = 1, #lines do
    if (lines[i].time or 0) <= adjPos then active = i else break end
  end
  lyrCache.idx = active
  lyrCache.cur = lines[active] and lines[active].text or nil
  lyrCache.nxt = lines[active + 1] and lines[active + 1].text or nil
  local t0 = lines[active] and lines[active].time or 0
  local t1 = (lines[active + 1] and lines[active + 1].time) or math.max(t0 + 4, S.dur or (t0 + 4))
  lyrCache.prog = (t1 > t0) and clamp((adjPos - t0) / (t1 - t0), 0, 1) or 1
end

local function currentLyricIndex()
  XT.refreshLyricCache()
  return lyrCache.idx
end

local function currentLyricText()
  XT.refreshLyricCache()
  return lyrCache.cur, lyrCache.nxt
end

local function currentLyricProgress()
  XT.refreshLyricCache()
  return lyrCache.prog
end

XT.readArtBytes = function(trackOrPath)
  local vid = extractVideoId(trackOrPath)
  if not vid or vid == '' then return nil end
  local artFile = BRIDGE .. '\\art_' .. vid .. '.jpg'
  if doesFileExist(artFile) then
    local d = readFile(artFile)
    if d and #d > 256 then return d end
  end
  return nil
end

XT.readStringList = function(p)
  local t, off = {}, 0
  while true do
    local s = ffi.string(p + off)
    if #s == 0 then break end
    t[#t + 1] = s
    off = off + #s + 1
  end
  return t
end

-- ======================================================================
-- YOUTUBE MUSIC STREAMING LIBRARY, CATALOG & BRIDGE STATE (NO LOCAL MP3)
-- ======================================================================
local lib, libVersion = {}, 0
local libByPath = {}
local stations, stVersion = {}, 0
local bookmarks = {}
local recentTracks = {}
local tmpList = {}
local FP = { list = {}, ckey = '', call = {} }

local YT = {
  seq = math.floor((os.time() % 100000) * 10),
  online = false,
  hasFfmpeg = true,
  port = 48291,
  lastPingCheck = 0,
  lastPoll = 0,
  lastSearchSeq = '',
  lastStreamSeq = '',
  lastMetaSeq = '',
  lastHomeSeq = '',
  lastSuggSeq = '',
  searching = false,
  homeLoading = false,
  searchQuery = '',
  searchMode = 'search',
  searchFilterVideos = false,
  searchResults = {},
  showSearchOnly = false,
  homeShelves = {},
  homePlaylists = {},
  suggestions = {},
  suggQuery = '',
  autoSearchAt = 0,
  pendingQuery = '',
  autoSuggAt = 0,
  pendingSugg = '',
  artReqAt = {},
  prefetchedVid = '',
  autoAppending = false,
  bootTried = false
}

local function relPath(p)
  if not p then return '' end
  return p
end
local function absPath(p)
  if not p or p == '' then return '' end
  if p:match('^yt:') then return p end
  return 'yt:' .. p
end
local function cleanName(s)
  s = XT.sanitizeGlyphs((s or ''):gsub('%c', ' '))
  return trim(s)
end

local function loadBookmarks()
  bookmarks = {}
  local f = io.open(BMFILE, 'r')
  if not f then return end
  for line in f:lines() do
    local k, v = line:match('^(.-)%s*|%s*([%d%.]+)%s*$')
    if k and v then bookmarks[k] = tonumber(v) end
  end
  f:close()
end

local function saveBookmarks()
  local w = io.open(BMFILE, 'w')
  if not w then return end
  for k, v in pairs(bookmarks) do
    w:write(k .. ' | ' .. string.format('%.2f', v) .. '\n')
  end
  w:close()
end

local function getBookmark(t)
  if not t or not t.path then return nil end
  return bookmarks[relPath(t.path)]
end

local function toggleBookmark(t, pos)
  if not t or not t.path then return end
  local k = relPath(t.path)
  if bookmarks[k] and math.abs(bookmarks[k] - pos) < 3 then
    bookmarks[k] = nil
    saveBookmarks()
    flash('Drop Bookmark dihapus', false, t.title)
  else
    bookmarks[k] = pos
    saveBookmarks()
    local mm = math.floor(pos / 60)
    local ss = math.floor(pos % 60)
    flash(string.format('Drop disimpan di %d:%02d', mm, ss), false, t.title)
  end
end

local vibeOverrides = {}
local vibeVersion = 0

local function loadVibeOverrides()
  vibeOverrides = {}
  local f = io.open(VBFILE, 'r')
  if not f then return end
  for line in f:lines() do
    local k, v = line:match('^(.-)%s*|%s*(%w+)%s*$')
    if k and v then vibeOverrides[k] = v:lower() end
  end
  f:close()
  vibeVersion = vibeVersion + 1
end

local function saveVibeOverrides()
  local w = io.open(VBFILE, 'w')
  if not w then return end
  for k, v in pairs(vibeOverrides) do
    if v and v ~= '' and v ~= 'auto' then
      w:write(k .. ' | ' .. v .. '\n')
    end
  end
  w:close()
end

local function updateKey(t)
  t.key = ((t.title or '') .. ' ' .. (t.artist or '') .. ' ' .. (t.album or '') .. ' ' .. (t.genre or '') .. ' ' .. (t.videoId or '') .. ' ' .. (t.group or '')):lower()
  t._smart = nil
end

local function saveCatalog()
  local w = io.open(CATFILE, 'w')
  if not w then return end
  w:write('# MoonRadio YouTube Music Metadata Catalog (Tanpa File MP3 Lokal)\n')
  local maxSave = math.min(#lib, 500)
  for i = 1, maxSave do
    local t = lib[i]
    if t and t.videoId then
      local ti = (t.title or ''):gsub('[\t\r\n]+', ' ')
      local ar = (t.artist or ''):gsub('[\t\r\n]+', ' ')
      local al = (t.album or 'YouTube Music'):gsub('[\t\r\n]+', ' ')
      local du = math.floor(tonumber(t.dur) or 0)
      local ds = (t.durStr or ''):gsub('[\t\r\n]+', ' ')
      w:write(string.format('%s\t%s\t%s\t%s\t%d\t%s\n', t.videoId, ti, ar, al, du, ds))
    end
  end
  w:close()
end

local function upsertYtTrack(videoId, title, artist, album, durSec, durStr, noSave)
  videoId = trim(tostring(videoId or ''))
  if videoId == '' then return nil end
  videoId = videoId:gsub('^yt:', '')
  local path = 'yt:' .. videoId
  local t = libByPath[path]
  local dSec = tonumber(durSec) or 0
  local hasLrc = doesFileExist(BRIDGE .. '\\lyr_' .. videoId .. '.lrc')
  if not t then
    t = {
      path = path,
      videoId = videoId,
      yt = true,
      file = videoId,
      title = fixText(title ~= '' and title or videoId),
      artist = fixText(artist ~= '' and artist or 'YouTube Music'),
      album = fixText(album and album ~= '' and album or 'YouTube Music'),
      year = '',
      genre = 'YouTube Music',
      ext = 'YTM',
      dur = dSec,
      durStr = (durStr and durStr ~= '') and durStr or (dSec > 0 and string.format('%d:%02d', math.floor(dSec / 60), dSec % 60) or ''),
      tagged = true,
      mtime = os.time(),
      hasLrc = hasLrc
    }
    lib[#lib + 1] = t
    libByPath[path] = t
    libVersion = libVersion + 1
  else
    if title and title ~= '' and (t.title == t.videoId or t.title:find('^YouTube Track')) then t.title = fixText(title) end
    if artist and artist ~= '' and (t.artist == 'YouTube Music' or t.artist == 'Unknown Artist') then t.artist = fixText(artist) end
    if album and album ~= '' and t.album == 'YouTube Music' then t.album = fixText(album) end
    if dSec > 0 then t.dur = dSec end
    if durStr and durStr ~= '' then t.durStr = durStr end
    if hasLrc then t.hasLrc = true end
  end
  updateKey(t)
  if not noSave then saveCatalog() end
  return t
end

local function loadCatalog()
  local f = io.open(CATFILE, 'r')
  if not f then return end
  for raw in f:lines() do
    local line = raw:gsub('\r$', '')
    if line ~= '' and not line:match('^%s*#') then
      local vid, ti, ar, al, du, ds = line:match('^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t?(.*)$')
      if vid then
        upsertYtTrack(vid, ti, ar, al, tonumber(du) or 0, ds, true)
      end
    end
  end
  f:close()
  libVersion = libVersion + 1
end

local function loadStations()
  stations = {}
  local f = io.open(STFILE, 'r')
  if not f then
    local w = io.open(STFILE, 'w')
    if w then
      w:write('# Format:  Nama | URL   (satu per baris)\n')
      w:write('Radio Paradise Main | http://stream.radioparadise.com/mp3-128\n')
      w:write('SomaFM Groove Salad | http://ice1.somafm.com/groovesalad-128-mp3\n')
      w:write('SomaFM DEF CON Radio | http://ice1.somafm.com/defcon-128-mp3\n')
      w:write('SomaFM Synthwave / Underground | http://ice1.somafm.com/u80s-128-mp3\n')
      w:write('Nightride FM Synthwave | https://stream.nightride.fm/nightride.m4a\n')
      w:close()
    end
    f = io.open(STFILE, 'r')
  end
  if f then
    for line in f:lines() do
      if not line:match('^%s*#') then
        local name, url = line:match('^%s*(.-)%s*|%s*(%S+)%s*$')
        if url then stations[#stations + 1] = { name = fixText(name ~= '' and name or url), url = url } end
      end
    end
    f:close()
  end
  stVersion = stVersion + 1
end

local function saveStations()
  local w = io.open(STFILE, 'w')
  if not w then return end
  w:write('# Format:  Nama | URL   (satu per baris)\n')
  for _, s in ipairs(stations) do w:write(s.name .. ' | ' .. s.url .. '\n') end
  w:close()
  stVersion = stVersion + 1
end

-- ======================================================================
-- PLAYLISTS & SMART QUEUE
-- ======================================================================
local queue = {}
local playlists, plVersion = {}, 0

local function isTrackList(n) return n == 'lib' or n == 'queue' end

FP.all = function()
  local key = plVersion .. '/' .. #FP.list .. '/' .. #playlists
  if FP.ckey ~= key then
    local l = {}
    for _, pl in ipairs(FP.list) do l[#l + 1] = pl end
    for _, pl in ipairs(playlists) do l[#l + 1] = pl end
    FP.ckey, FP.call = key, l
  end
  return FP.call
end

local function getList(name)
  if name == 'lib' then return lib elseif name == 'stations' then return stations elseif name == 'queue' then return queue end
  return tmpList
end

local function libFind(path)
  if not path or path == '' then return nil end
  local norm = absPath(path)
  local t = libByPath[norm] or libByPath[path]
  if not t then
    local vid = extractVideoId(norm)
    if vid and vid ~= '' then
      t = upsertYtTrack(vid, 'YouTube Track (' .. vid .. ')', 'YouTube Music', 'YouTube Music', 0, '', true)
    end
  end
  return t
end

local function savePlaylists()
  local w = io.open(PLFILE, 'w')
  if not w then flash('Gagal menyimpan playlists.txt', true); return end
  w:write('# MoonRadio playlists. Format: [Nama] lalu satu path lagu per baris\n')
  for _, pl in ipairs(playlists) do
    w:write('[' .. pl.name .. ']\n')
    for _, p in ipairs(pl.tracks) do w:write(relPath(p) .. '\n') end
    w:write('\n')
  end
  w:close()
end

local function loadPlaylists()
  playlists = {}
  local f = io.open(PLFILE, 'r')
  if f then
    local cur
    for raw in f:lines() do
      local line = raw:gsub('\r$', '')
      local name = line:match('^%[(.+)%]$')
      if name then
        cur = { name = fixText(name), tracks = {} }
        playlists[#playlists + 1] = cur
      elseif cur and line ~= '' and not line:match('^#') then
        cur.tracks[#cur.tracks + 1] = absPath(line)
      end
    end
    f:close()
  end
  plVersion = plVersion + 1
end

local function findPl(name)
  local l = name:lower()
  for i, p in ipairs(playlists) do if p.name:lower() == l then return p, i end end
  return nil
end

local function createPlaylist(name)
  name = cleanName(name)
  if name == '' then return nil, false end
  local p = findPl(name)
  if p then return p, false end
  p = { name = name, tracks = {} }
  playlists[#playlists + 1] = p
  plVersion = plVersion + 1
  savePlaylists()
  return p, true
end

local function renamePlaylist(pl, name)
  name = cleanName(name)
  if name == '' then return false, 'empty' end
  local other = findPl(name)
  if other and other ~= pl then return false, 'exists' end
  pl.name = name
  plVersion = plVersion + 1
  savePlaylists()
  return true
end

local function deletePlaylist(pl)
  for i, p in ipairs(playlists) do
    if p == pl then table.remove(playlists, i); break end
  end
  plVersion = plVersion + 1
  savePlaylists()
end

local function plHas(pl, path)
  if pl._sk ~= plVersion or not pl._set then
    local st = {}
    for _, p in ipairs(pl.tracks) do st[p] = true end
    pl._set, pl._sk = st, plVersion
  end
  return pl._set[path] == true
end

local function addToPlaylist(pl, track, noSave)
  if not track or not track.path or plHas(pl, track.path) then return false end
  pl.tracks[#pl.tracks + 1] = track.path
  plVersion = plVersion + 1
  pl._set[track.path] = true; pl._sk = plVersion
  if not noSave then savePlaylists() end
  return true
end

local function removeFromPlaylist(pl, path)
  for i, p in ipairs(pl.tracks) do
    if p == path then table.remove(pl.tracks, i); break end
  end
  plVersion = plVersion + 1
  savePlaylists()
end

local FAVNAME = 'Favorit'
local function isFav(t)
  if not t or not t.path then return false end
  local p = findPl(FAVNAME)
  return p ~= nil and plHas(p, t.path)
end

local function toggleFav(t)
  if not t or not t.path then return false end
  local p = findPl(FAVNAME) or createPlaylist(FAVNAME)
  if not p then return false end
  if plHas(p, t.path) then
    removeFromPlaylist(p, t.path)
    flash('Dihapus dari Favorit', false, t.title)
    return false
  end
  addToPlaylist(p, t)
  flash('Ditambahkan ke Favorit', false, t.title)
  return true
end

local function plTracks(pl)
  local key = plVersion .. '/' .. libVersion
  if pl._ck ~= key then
    local out = {}
    for _, p in ipairs(pl.tracks) do
      local t = libFind(p)
      if t then out[#out + 1] = t end
    end
    pl._res, pl._ck = out, key
  end
  return pl._res
end

local function mixOf(pls)
  local out, seen = {}, {}
  for _, pl in ipairs(pls) do
    for _, t in ipairs(plTracks(pl)) do
      if not seen[t] then seen[t] = true; out[#out + 1] = t end
    end
  end
  return out
end

local function shuffleInPlace(a)
  for i = #a, 2, -1 do
    local j = math.random(i)
    a[i], a[j] = a[j], a[i]
  end
  return a
end

local function seededShuffle(a, seed)
  local s = seed % 2147483647
  if s <= 0 then s = s + 2147483646 end
  for i = #a, 2, -1 do
    s = (s * 48271) % 2147483647
    local j = (s % i) + 1
    a[i], a[j] = a[j], a[i]
  end
  return a
end

-- ======================================================================
-- SMART VIBE SHUFFLE & AUTO MIX ENGINE (ANTI GENRE-CLASH)
-- ======================================================================
local SMART = {
  VIBES = {
    { id = 'sad',     name = 'Sad & Galau',     short = 'Sad/Galau', tint = 6 },
    { id = 'pop',     name = 'Pop & Santai',    short = 'Pop/Santai', tint = 1 },
    { id = 'dangdut', name = 'Dangdut & Koplo', short = 'Dangdut',   tint = 4 },
    { id = 'dj',      name = 'DJ & Remix',      short = 'DJ/Remix',  tint = 3 },
    { id = 'rock',    name = 'Rock & Alt',      short = 'Rock/Alt',  tint = 9 },
    { id = 'hiphop',  name = 'Hip-Hop & R&B',   short = 'Hip-Hop',   tint = 2 },
    { id = 'general', name = 'Mix & Umum',      short = 'Umum',      tint = 5 }
  },
  VIBE_MAP = {},
  -- Matriks kompatibilitas antar mood/genre:
  -- Nilai positif = se-vibe / nyambung halus; Nilai sangat negatif = tabrakan genre (mis. Sad <-> Dangdut/DJ)
  VIBE_MATRIX = {
    sad     = { sad = 62, pop = 18, general = 14, rock = -18, hiphop = -55, dj = -120, dangdut = -130 },
    pop     = { pop = 54, sad = 18, general = 20, hiphop = 18, rock = 14,   dj = -18,  dangdut = -38  },
    dangdut = { dangdut = 66, dj = 16, general = -42, pop = -38, hiphop = -75, rock = -95, sad = -130 },
    dj      = { dj = 64, dangdut = 16, hiphop = 18, general = -38, pop = -18, rock = -65, sad = -120 },
    rock    = { rock = 60, pop = 14, general = 12, sad = -16, hiphop = -20, dj = -65,  dangdut = -95  },
    hiphop  = { hiphop = 60, pop = 18, dj = 16, general = 12, rock = -20,   sad = -55, dangdut = -75  },
    general = { general = 38, pop = 20, sad = 16, rock = 12, hiphop = 12,   dj = -38,  dangdut = -42  }
  },
  STOPWORDS = {
    ['the'] = true, ['and'] = true, ['for'] = true, ['with'] = true, ['from'] = true,
    ['feat'] = true, ['ft'] = true, ['prod'] = true, ['official'] = true, ['music'] = true,
    ['video'] = true, ['audio'] = true, ['lyric'] = true, ['lyrics'] = true, ['version'] = true,
    ['lirik'] = true, ['lagu'] = true, ['full'] = true, ['album'] = true, ['track'] = true,
    ['unknown'] = true, ['artist'] = true, ['mp3'] = true, ['flac'] = true, ['wav'] = true,
    ['ogg'] = true, ['m4a'] = true, ['yang'] = true, ['dan'] = true, ['di'] = true, ['ke'] = true
  },
  KW_SUB = {
    dangdut = {
      'dangdut', 'koplo', 'campursari', 'jandhut', 'jaipong', 'tarling', 'pantura', 'banyuwangi',
      'kendang', 'gendang', 'adella', 'palapa', 'pallapa', 'monata', 'ageng music', 'anezka',
      'denny caknan', 'caknan', 'happy asmara', 'ndarboy', 'guyon waton', 'aftershine',
      'gilga sahid', 'gilga', 'gildcoustic', 'niken salindry', 'difarina', 'yenny inka',
      'via vallen', 'nella kharisma', 'vita alvia', 'sasya arkhisna', 'lala widy', 'shinta arsinta',
      'masdddho', 'ndx a.k.a', 'ndx aka', 'pendhoza', 'kembang wangi', 'rungkad', 'satru',
      'klebus', 'nglarani', 'dumes', 'wirang', 'kisinan', 'lamunan', 'sigar', 'anak lanang',
      'sanes', 'dadi siji', 'kalih welasku', 'widodari', 'kartonyono', 'los dol', 'pingal',
      'mendung tanpo udan', 'ojo dibandingke', 'bojo loro', 'pamer bojo', 'cidro', 'alololo',
      'lintang asmoro', 'taman jurug', 'pelanggaran', 'cundamani', 'cerito mustahil', 'ketintang',
      'rasah bali', 'santri pekok', 'titeni lan enteni', 'sekecak'
    },
    dj = {
      'jedag jedug', 'jedag', 'jedug', 'mengkane', 'full bass', 'slow bass', 'bass boost',
      'breakbeat', 'funkot', 'phonk', 'drift phonk', 'hardstyle', 'thailand style', 'thai style',
      'plat kt', 'club mix', 'bootleg', 'nightcore', 'sped up', 'alan walker', 'marshmello',
      'martin garrix', 'calvin harris', 'david guetta', 'tiesto', 'avicii', 'skrillex',
      'kordhell', 'dvrst', 'interworld', 'hensonn', 'whisnu santika', 'weird genius', 'dipha barus'
    },
    sad = {
      'galau', 'sedih', 'mellow', 'ballad', 'acoustic', 'akustik', 'unplugged', 'piano',
      'stripped', 'slowed', 'reverb', 'lofi', 'lo-fi', 'hujan', 'senja', 'sepi', 'rindu',
      'kangen', 'kenangan', 'patah hati', 'perpisahan', 'air mata', 'menangis', 'kecewa',
      'trauma', 'komang', 'rumah ke rumah', 'secukupnya', 'evaluasi', 'membasuh', 'sorai',
      'bertaut', 'runtuh', 'hati-hati di jalan', 'hati hati di jalan', 'monokrom', 'interaksi',
      'pesan terakhir', 'sisa rasa', 'melawan restu', 'tak segampang itu', 'jiwa yang bersedih',
      'bunga hati', 'tertawan hati', 'tak dianggap', 'nadin amizah', 'hindia', 'tulus',
      'mahalini', 'lyodra', 'tiara andini', 'ziva magnolya', 'anggis devaki', 'sal priadi',
      'pamungkas', 'fiersa besari', 'feby putri', 'febby putri', 'daun jatuh', 'payung teduh',
      'fourtwnty', 'juicy luicy', 'bernadya', 'idgitaf', 'kunto aji', 'ardhito', 'raisa',
      'isyana', 'glenn fredly', 'rossa', 'afgan', 'judika', 'virgoun', 'last child',
      'for revenge', 'serana', "d'masiv", 'dmasiv', 'peterpan', 'noah', 'armada',
      'kerispatih', 'samsons', 'ada band', 'cassandra', 'geisha', 'yovie', 'andmesh',
      'budi doremi', 'fabio asher', 'raim laode', 'stevan pasaribu', 'ghea indrawari',
      'bruno major', 'rex orange', 'keshi', 'joji', 'laufey', 'billie eilish',
      'olivia rodrigo', 'adele', 'sam smith', 'lewis capaldi', 'ed sheeran', 'coldplay',
      'kodaline', 'the script', 'passenger', 'james arthur', 'shawn mendes', 'conan gray',
      'cigarettes after sex', 'wave to earth', 'mitski', 'lana del rey', 'clairo',
      'beabadoobee', 'novo amor', 'bon iver', 'hozier', 'lord huron', 'daniel caesar',
      'frank ocean', 'giveon', 'mac demarco', 'untungnya bumi masih berputar', 'satu bulan',
      'kata mereka ini berlebihan', 'apa mungkin', 'lampu kuning', 'tampar', 'lantas'
    },
    rock = {
      'metalcore', 'deathcore', 'pop punk', 'alternative', 'grunge', 'hardcore', 'indie rock',
      'linkin park', 'bring me the horizon', 'bmth', 'avenged sevenfold', 'avenged', 'a7x',
      'green day', 'my chemical romance', 'blink-182', 'blink 182', 'sum 41', 'simple plan',
      'neck deep', 'paramore', 'fall out boy', 'panic! at the disco', 'twenty one pilots',
      'nirvana', 'foo fighters', 'red hot chili', 'arctic monkeys', 'the strokes', 'the 1975',
      'imagine dragons', 'one ok rock', 'slipknot', 'metallica', 'system of a down', 'korn',
      'limp bizkit', "guns n' roses", 'guns n roses', 'bon jovi', 'ac/dc', 'aerosmith',
      'scorpions', 'evanescence', 'three days grace', 'skillet', 'breaking benjamin',
      'dewa 19', 'dewa19', 'slank', 'jamrud', 'boomerang', 'pas band', 'netral', 'ntrl',
      'superman is dead', 'killing me inside', 'pee wee gaskins', 'stand here alone',
      'perunggu', 'reality club', 'the jansen', 'morfem', 'barasuara', 'st12', 'setia band',
      'kangen band', 'republika', 'letto', 'nidji', 'j-rocks'
    },
    hiphop = {
      'hip-hop', 'hip hop', 'hiphop', 'boom bap', 'freestyle', 'cypher', 'eminem', 'kendrick lamar',
      'travis scott', 'kanye', 'jay-z', '21 savage', 'metro boomin', 'playboi carti', 'asap rocky',
      'post malone', 'juice wrld', 'xxxtentacion', 'pop smoke', 'central cee', 'nicki minaj',
      'cardi b', 'doja cat', 'tupac', '2pac', 'notorious', 'snoop dogg', '50 cent', 'ice cube',
      'j. cole', 'tyler, the creator', 'childish gambino', 'rich brian', 'warren hue', 'ramengvrl',
      'basboi', 'tuan tigabelas', 'saykoji', 'iwa k', 'bondan', 'fade2black'
    },
    pop = {
      'synthpop', 'city pop', 'k-pop', 'kpop', 'j-pop', 'jpop', 'anime', 'opening', 'ending',
      'bruno mars', 'the weeknd', 'dua lipa', 'taylor swift', 'ariana grande', 'justin bieber',
      'katy perry', 'lady gaga', 'rihanna', 'beyonce', 'shakira', 'charlie puth', 'maroon 5',
      'one direction', 'harry styles', 'sabrina carpenter', 'chappell roan', 'benson boone',
      'newjeans', 'blackpink', 'twice', 'aespa', 'le sserafim', 'seventeen', 'stray kids',
      'red velvet', 'itzy', 'treasure', 'babymonster', 'illit', 'jungkook', 'yoasobi',
      'kenshi yonezu', 'fujii kaze', 'aimyon', 'radwimps', 'official hige', 'mrs. green apple',
      'creepy nuts', 'imase', 'vaundy', 'hivi', 'maliq', 'kahitna', 'diskoria', 'potret',
      'chrisye', 'sheila on 7', 'project pop', 'jkt48', 'marion jola', 'rizky febian',
      'vidi aldiano', 'agnez mo', 'bunga citra lestari'
    }
  },
  KW_WORD = {
    dangdut = { 'koplo', 'dangdut', 'gendang', 'kendang', 'jawa', 'ambyar' },
    dj      = { 'dj', 'remix', 'jj', 'edm', 'electro', 'techno', 'trance', 'dubstep', 'house', 'mashup', 'fyp', 'kane', 'club' },
    sad     = { 'sad', 'chill', 'slow', 'luka', 'usai', 'pergi', 'hilang', 'pamit', 'cincin', 'taruh', 'sial', 'ungu', 'hal', 'niki', 'cas' },
    rock    = { 'rock', 'metal', 'punk', 'emo', 'band', 'muse', 'oasis', 'queen', 'kotak', 'padi', 'wali', 'feast', 'mcr', 'sid' },
    hiphop  = { 'rap', 'trap', 'drill', 'rnb', 'r&b', 'drake', 'future', 'nas' },
    pop     = { 'pop', 'dance', 'disco', 'funk', 'upbeat', 'happy', 'ceria', 'ost', 'bts', 'exo', 'nct', 'ive', 'ado', 'ran', 'bcl' }
  },
  ctxVer = '',
  artistVibe = {},
  groupVibe = {},
  looseSet = {}
}

for _, v in ipairs(SMART.VIBES) do SMART.VIBE_MAP[v.id] = v end

SMART.rawScanText = function(hay, padded)
  local sc = { sad = 0, pop = 0, dangdut = 0, dj = 0, rock = 0, hiphop = 0 }
  for vibe, list in pairs(SMART.KW_SUB) do
    local w = (vibe == 'dangdut' or vibe == 'dj') and 4 or 3
    for i = 1, #list do
      if hay:find(list[i], 1, true) then sc[vibe] = sc[vibe] + w end
    end
  end
  for vibe, list in pairs(SMART.KW_WORD) do
    local w = (vibe == 'dangdut' or vibe == 'dj') and 4 or 2
    for i = 1, #list do
      if padded:find(' ' .. list[i] .. ' ', 1, true) then sc[vibe] = sc[vibe] + w end
    end
  end
  -- Jika judul/file secara eksplisit merupakan versi Koplo atau DJ Remix dari lagu sad/pop,
  -- prioritaskan identitas Koplo/DJ agar tidak nyasar ke antrean Sad/Galau
  if sc.dangdut >= 4 and sc.sad > 0 then sc.dangdut = sc.dangdut + 5 end
  if sc.dj >= 4 and sc.sad > 0 then sc.dj = sc.dj + 5 end
  local bestVibe, bestScore = nil, 0
  local order = { 'dangdut', 'dj', 'sad', 'rock', 'hiphop', 'pop' }
  for i = 1, #order do
    local k = order[i]
    if sc[k] > bestScore then bestScore = sc[k]; bestVibe = k end
  end
  return bestVibe, bestScore, sc
end

SMART.rebuildContext = function()
  local key = libVersion .. '/' .. plVersion .. '/' .. vibeVersion
  if SMART.ctxVer == key then return end
  SMART.ctxVer = key
  SMART.artistVibe = {}
  SMART.groupVibe = {}
  SMART.looseSet = {}

  local inManualPl = {}
  local trackPlNames = {}
  for _, pl in ipairs(playlists) do
    local pLow = (pl.name or ''):lower()
    for _, pth in ipairs(pl.tracks) do
      inManualPl[pth] = true
      trackPlNames[pth] = (trackPlNames[pth] and (trackPlNames[pth] .. ' ' .. pLow)) or pLow
    end
  end
  SMART.trackPlNames = trackPlNames

  local artCounts = {}
  local grpCounts = {}

  for _, t in ipairs(lib) do
    if not t.group and not inManualPl[t.path] then
      SMART.looseSet[t.path] = true
    end
    local ov = t.path and vibeOverrides[relPath(t.path)]
    local hay = ((t.title or '') .. ' ' .. (t.artist or '') .. ' ' .. (t.album or '') .. ' '
      .. (t.genre or '') .. ' ' .. (t.group or '') .. ' ' .. (t.file or '') .. ' '
      .. (trackPlNames[t.path] or '')):lower()
    local padded = ' ' .. hay:gsub('[%p%c]+', ' ') .. ' '
    local bv, bsc, sc = SMART.rawScanText(hay, padded)
    if ov and SMART.VIBE_MAP[ov] then
      bv = ov; bsc = 20; sc[ov] = 20
    end
    t._rawVibe, t._rawScore, t._rawSc, t._padded = bv, bsc, sc, padded

    if bv and bsc > 0 then
      local ak = (t.artist and t.artist ~= 'Unknown Artist') and t.artist:lower() or nil
      if ak then
        artCounts[ak] = artCounts[ak] or {}
        artCounts[ak][bv] = (artCounts[ak][bv] or 0) + bsc
      end
      local gk = t.group and t.group:lower() or nil
      if gk then
        grpCounts[gk] = grpCounts[gk] or {}
        grpCounts[gk][bv] = (grpCounts[gk][bv] or 0) + bsc
      end
    end
  end

  for ak, tbl in pairs(artCounts) do
    local bestV, bestC = nil, 0
    for v, c in pairs(tbl) do if c > bestC then bestC = c; bestV = v end end
    if bestV then SMART.artistVibe[ak] = bestV end
  end
  for gk, tbl in pairs(grpCounts) do
    local bestV, bestC = nil, 0
    for v, c in pairs(tbl) do if c > bestC then bestC = c; bestV = v end end
    if bestV then SMART.groupVibe[gk] = bestV end
  end
end

SMART.getProfile = function(t)
  if not t or t.url then
    return { vibe = 'general', info = SMART.VIBE_MAP.general, scores = {}, tokens = {}, pls = {} }
  end
  SMART.rebuildContext()
  local ver = SMART.ctxVer
  if t._smart and t._smart.ver == ver then return t._smart end

  local ak = (t.artist and t.artist ~= 'Unknown Artist') and t.artist:lower() or nil
  local gk = t.group and t.group:lower() or nil
  local genreLow = (t.genre and t.genre ~= '') and t.genre:lower() or nil

  local vibe = t._rawVibe
  local sc = {}
  for k, v in pairs(t._rawSc or {}) do sc[k] = v end

  -- Wariskan vibe dari artis atau folder jika judul lagu tidak memuat kata kunci eksplisit
  if not vibe then
    if ak and SMART.artistVibe[ak] then
      vibe = SMART.artistVibe[ak]
      sc[vibe] = (sc[vibe] or 0) + 3
    elseif gk and SMART.groupVibe[gk] then
      vibe = SMART.groupVibe[gk]
      sc[vibe] = (sc[vibe] or 0) + 2
    else
      vibe = 'general'
    end
  end

  local tokens = {}
  local padded = t._padded or (' ' .. (t.key or ''):gsub('[%p%c]+', ' ') .. ' ')
  for w in padded:gmatch('%w+') do
    if #w >= 3 and not SMART.STOPWORDS[w] and not tonumber(w) then
      tokens[w] = true
    end
  end

  local pls = {}
  for i, pl in ipairs(playlists) do
    if plHas(pl, t.path) then pls[i] = true end
  end

  local prof = {
    ver = ver,
    vibe = vibe,
    info = SMART.VIBE_MAP[vibe] or SMART.VIBE_MAP.general,
    scores = sc,
    tokens = tokens,
    artistKey = ak,
    groupKey = gk,
    genreKey = genreLow,
    pls = pls
  }
  t._smart = prof
  return prof
end

SMART.vibeLabel = function(t)
  local p = SMART.getProfile(t)
  return p.info and p.info.short or 'Umum'
end

SMART.vibeInfo = function(t)
  local p = SMART.getProfile(t)
  return p.info or SMART.VIBE_MAP.general
end

SMART.isLooseTrack = function(t)
  if not t or not t.path then return false end
  SMART.rebuildContext()
  return SMART.looseSet[t.path] == true
end

SMART.setTrackVibe = function(t, vibeId)
  if not t or not t.path then return end
  local k = relPath(t.path)
  if not vibeId or vibeId == 'auto' then
    vibeOverrides[k] = nil
    vibeVersion = vibeVersion + 1
    t._smart = nil
    saveVibeOverrides()
    local info = SMART.vibeInfo(t)
    flash('Vibe direset ke Otomatis: ' .. info.name, false, t.title)
  else
    vibeOverrides[k] = vibeId
    vibeVersion = vibeVersion + 1
    t._smart = nil
    saveVibeOverrides()
    local info = SMART.VIBE_MAP[vibeId] or SMART.VIBE_MAP.general
    flash('Vibe lagu dikunci ke: ' .. info.name, false, t.title)
  end
end

-- Hitung skor kecocokan transisi dari lagu `cur` ke kandidat `cand`
SMART.scoreTransition = function(cur, cand, prevArtistKey)
  if not cur or not cand then return 0 end
  if cur == cand then return -999 end
  local p1 = SMART.getProfile(cur)
  local p2 = SMART.getProfile(cand)

  local row = SMART.VIBE_MATRIX[p1.vibe] or SMART.VIBE_MATRIX.general
  local score = (row and row[p2.vibe]) or 0

  -- Jika proteksi ketat anti-lompat genre aktif, perkuat penalti untuk genre yang bertolak belakang
  if cfg.main.smartAvoidClash and score <= -35 then
    score = score * 1.8
  end

  -- Bonus kesamaan sub-vibe sekunder
  for k, v1 in pairs(p1.scores) do
    local v2 = p2.scores[k] or 0
    if v1 > 0 and v2 > 0 then
      score = score + math.min(22, (v1 + v2) * 2.5)
    end
  end

  -- Kesamaan Folder / Playlist asal
  if p1.groupKey and p1.groupKey == p2.groupKey then
    score = score + 28
  end
  for plIdx, _ in pairs(p1.pls) do
    if p2.pls[plIdx] then
      score = score + 26
      break
    end
  end

  -- Kesamaan Genre ID3
  if p1.genreKey and p1.genreKey == p2.genreKey then
    score = score + 22
  end

  -- Kesamaan Artis (dengan anti-clumping ringan bila lagu sebelumnya sudah artis yang sama)
  if p1.artistKey and p1.artistKey == p2.artistKey then
    if prevArtistKey and prevArtistKey == p2.artistKey then
      score = score + 8
    else
      score = score + 26
    end
  end

  -- Kemiripan kata kunci judul / kolaborator / seri
  local tokMatches = 0
  for w, _ in pairs(p1.tokens) do
    if p2.tokens[w] then
      tokMatches = tokMatches + 1
      if tokMatches >= 4 then break end
    end
  end
  score = score + tokMatches * 6

  return score
end

-- ======================================================================
-- PLAYER & STUDIO AUDIO FX ENGINE (OPTIMIZED ZERO-ALLOC FFI)
-- ======================================================================
local FX_PRESETS = {
  { name = 'Normal (Flat)',   tag = '0 dB | 100% Speed',   bass = 0,  mid = 0,  treble = 0,  speed = 100, reverb = 0,  desc = 'Suara asli jernih tanpa pewarnaan' },
  { name = 'Bass Boost',      tag = '+9 dB Bass | +3 High', bass = 9,  mid = -1, treble = 3,  speed = 100, reverb = 8,  desc = 'Dentuman sub-bass tebal & treble renyah' },
  { name = 'Vocal Crystal',   tag = '+5 Mid | +6 Treble',   bass = -2, mid = 5,  treble = 6,  speed = 100, reverb = 10, desc = 'Vokal penyanyi maju & detail akustik' },
  { name = 'Nightcore Rush',  tag = '118% Speed | +4 Bass', bass = 4,  mid = 0,  treble = 4,  speed = 118, reverb = 5,  desc = 'Tempo cepat +18% & nada tinggi energik' },
  { name = 'Slowed + Reverb', tag = '84% Speed | 58% Rev',  bass = 5,  mid = -2, treble = -2, speed = 84,  reverb = 58, desc = 'Vibe malam sinematik, tempo lambat & gema luas' },
  { name = 'Lo-Fi Radio',     tag = '96% Speed | Warm EQ',  bass = 3,  mid = 4,  treble = -9, speed = 96,  reverb = 22, desc = 'Hangat bergaya kaset analog & vinil retro' },
  { name = 'Concert Hall',    tag = '72% Hall | +4 Bass',   bass = 4,  mid = 1,  treble = 4,  speed = 100, reverb = 72, desc = 'Simulasi akustik panggung konser megah' },
  { name = 'Custom Studio',   tag = 'Racikan Manual',       bass = 0,  mid = 0,  treble = 0,  speed = 100, reverb = 0,  desc = 'Racikan manual EQ, Speed, Reverb & Pan milikmu' }
}

local eqParamBuf  = ffi.new('BASS_DX8_PARAMEQ')
local revParamBuf = ffi.new('BASS_DX8_REVERB')
local freqReadBuf = ffi.new('float[1]', 44100)
local EQ_CENTERS  = { 85.0, 1000.0, 10000.0 }

S = {
  handle = 0, listName = 'lib', index = 0, cur = nil,
  playing = false, live = false, dur = 0, pos = 0, posOffset = 0, state = 0,
  loading = false, loadStatus = '', loadAt = 0, reqSeq = '', playStarted = 0,
  err = nil, history = {}, liveTitle = nil, icyName = nil, nextMeta = 0, lyrics = nil,
  seeking = false, seekFrac = 0, muted = false, errChain = 0, errAt = 0,
  toastStart = 0, toastUntil = 0,
  -- Studio FX state
  baseFreq = 44100, fxEq = { 0, 0, 0 }, fxRev = 0,
  fadeGain = 1.0, carMult = 1.0, lastCarCheck = 0, inCarCached = false,
  lastAppliedVol = -1, lastPosPoll = 0,
  -- A-B Loop
  loopA = nil, loopB = nil,
  -- Peak levels & visualizer timing
  peakL = 0, peakR = 0, bassPulse = 0, lastFftAt = 0, lastBarFrame = 0
}

S.pick = function(list, n, cur)
  local b = S.bag
  if not b or b.list ~= list or b.n ~= n or b.ver ~= libVersion then
    b = { list = list, n = n, ver = libVersion, pos = 0, order = {} }
    S.bag = b
  end
  if b.pos >= #b.order then
    local o = {}
    for i = 1, n do if i ~= cur then o[#o + 1] = i end end
    shuffleInPlace(o)
    b.order, b.pos = o, 0
  end
  b.pos = b.pos + 1
  return b.order[b.pos]
end

-- Smart Shuffle Picker: memilih lagu berikutnya yang paling se-vibe tanpa mengulang lagu
SMART.pickNext = function(list, n, curIdx)
  if n <= 1 then return 1 end
  local curTrack = list[curIdx] or S.cur
  if not curTrack or curTrack.url or not cfg.main.smartShuffle then
    return S.pick(list, n, curIdx)
  end

  local sb = S.smartBag
  if not sb or sb.list ~= list or sb.n ~= n or sb.ver ~= libVersion then
    sb = { list = list, n = n, ver = libVersion, played = {}, count = 0, lastArtist = nil }
    S.smartBag = sb
  end
  if curIdx and curIdx > 0 and not sb.played[curIdx] then
    sb.played[curIdx] = true
    sb.count = sb.count + 1
  end
  if sb.count >= n then
    sb.played = {}
    sb.count = 0
    if curIdx and curIdx > 0 then sb.played[curIdx] = true; sb.count = 1 end
  end

  local cands = {}
  local minAccept = cfg.main.smartAvoidClash and -15 or -60

  local function collectCands(ignorePlayed, minScore)
    local out = {}
    for i = 1, n do
      if i ~= curIdx and (ignorePlayed or not sb.played[i]) then
        local sc = SMART.scoreTransition(curTrack, list[i], sb.lastArtist)
        if sc >= minScore then
          out[#out + 1] = { idx = i, score = sc + math.random() * 14 }
        end
      end
    end
    return out
  end

  -- 1. Cari lagu yang belum diputar dan tidak tabrakan mood
  cands = collectCands(false, minAccept)
  -- 2. Jika semua lagu se-vibe sudah habis diputar dan sisa antrean hanya lagu beda genre (mis. Dangdut saat lagi Sad),
  --    reset memori khusus lagu se-vibe agar tidak terpaksa loncat ke Dangdut!
  if #cands == 0 and cfg.main.smartAvoidClash then
    cands = collectCands(true, 10)
    if #cands > 0 then
      sb.played = {}
      sb.count = 0
      if curIdx and curIdx > 0 then sb.played[curIdx] = true; sb.count = 1 end
    end
  end
  -- 3. Fallback bila seluruh list memang satu jenis atau koleksi sangat kecil
  if #cands == 0 then
    cands = collectCands(false, -9999)
  end
  if #cands == 0 then
    return S.pick(list, n, curIdx)
  end

  table.sort(cands, function(a, b) return a.score > b.score end)
  local bestScore = cands[1].score
  local topPool = {}
  local maxPool = math.min(#cands, math.max(4, math.min(10, math.ceil(#cands * 0.35))))
  for i = 1, maxPool do
    if cands[i].score >= bestScore - 28 then
      topPool[#topPool + 1] = cands[i]
    end
  end

  local chosen = topPool[math.random(#topPool)] or cands[1]
  sb.played[chosen.idx] = true
  sb.count = sb.count + 1
  local chosenTrack = list[chosen.idx]
  sb.lastArtist = chosenTrack and chosenTrack._smart and chosenTrack._smart.artistKey or nil
  return chosen.idx
end

-- Urutkan array lagu secara acak namun mengalir halus antar mood (Smart Vibe Flow)
SMART.shuffleList = function(a, startTrack)
  shuffleInPlace(a)
  if not cfg.main.smartShuffle or #a <= 2 then return a end

  if startTrack then
    for i = 1, #a do
      if a[i] == startTrack then
        a[1], a[i] = a[i], a[1]
        break
      end
    end
  end

  local prevArtist = nil
  for i = 1, #a - 1 do
    local cur = a[i]
    local bestJ = i + 1
    local bestSc = -99999
    local limit = math.min(#a, i + 36)
    for j = i + 1, limit do
      local sc = SMART.scoreTransition(cur, a[j], prevArtist) + math.random() * 10
      if sc > bestSc then
        bestSc = sc
        bestJ = j
      end
    end
    if bestJ ~= i + 1 then
      a[i + 1], a[bestJ] = a[bestJ], a[i + 1]
    end
    local p = SMART.getProfile(a[i])
    prevArtist = p.artistKey
  end
  return a
end

-- Buat antrean Smart Mix yang sesuai dengan lagu `seedTrack`
SMART.buildMix = function(seedTrack, maxCount)
  if not seedTrack then return {}, SMART.VIBE_MAP.general end
  local seedProf = SMART.getProfile(seedTrack)
  local scored = {}
  local fallback = {}

  for _, t in ipairs(lib) do
    if t ~= seedTrack then
      local sc = SMART.scoreTransition(seedTrack, t, nil)
      local jitter = math.random() * 12
      if sc >= 0 then
        scored[#scored + 1] = { track = t, score = sc + jitter }
      elseif not cfg.main.smartAvoidClash or sc > -35 then
        fallback[#fallback + 1] = { track = t, score = sc + jitter }
      end
    end
  end

  table.sort(scored, function(a, b) return a.score > b.score end)
  if #scored < 8 and #fallback > 0 then
    table.sort(fallback, function(a, b) return a.score > b.score end)
    for i = 1, math.min(#fallback, 15 - #scored) do
      scored[#scored + 1] = fallback[i]
    end
  end

  local limit = (maxCount and maxCount > 0) and maxCount or #scored + 1
  local pool = {}
  for i = 1, math.min(#scored, math.max(limit - 1, 1)) do
    pool[#pool + 1] = scored[i].track
  end

  local out = { seedTrack }
  for i = 1, #pool do out[#out + 1] = pool[i] end
  if #out > 2 then
    SMART.shuffleList(out, seedTrack)
  end
  return out, seedProf.info
end


local nextTrack
local function curList() return getList(S.listName) end

local function effectiveVolume()
  if S.muted then return 0 end
  local v = cfg.main.volume * (S.fadeGain or 1) * (S.carMult or 1)
  if XT.sleepAt > 0 then
    local rem = XT.sleepAt - os.clock()
    if rem > 0 and rem < 15 then v = v * (rem / 15) end
  end
  return clamp(v, 0, 1)
end

local function applyVolume(force)
  if S.handle ~= 0 then
    local ev = effectiveVolume()
    if force or math.abs(ev - (S.lastAppliedVol or -1)) > 0.002 then
      S.lastAppliedVol = ev
      pcall(function() BASS.BASS_ChannelSetAttribute(S.handle, 2, ev) end)
    end
  end
end

local function setVolume(v)
  cfg.main.volume = clamp(v, 0, 1)
  S.muted = false
  cfgDirty = true
  applyVolume(true)
end

local function applyAudioFX()
  local h = S.handle
  if h == 0 then return end
  pcall(function()
    local spd = clamp(cfg.main.speed or 100, 50, 150) / 100.0
    if not S.live then
      BASS.BASS_ChannelSetAttribute(h, 1, (S.baseFreq > 0 and S.baseFreq or 44100) * spd)
    end
    local pan = clamp(cfg.main.pan or 0, -100, 100) / 100.0
    BASS.BASS_ChannelSetAttribute(h, 3, pan)
  end)

  pcall(function()
    local g1 = clamp(cfg.main.eqBass or 0, -12, 12)
    local g2 = clamp(cfg.main.eqMid or 0, -12, 12)
    local g3 = clamp(cfg.main.eqTreble or 0, -12, 12)
    local gains = { g1, g2, g3 }
    for i = 1, 3 do
      if S.fxEq[i] == 0 or S.fxEq[i] == nil then
        S.fxEq[i] = BASS.BASS_ChannelSetFX(h, 7, 0)
      end
      if S.fxEq[i] ~= 0 then
        eqParamBuf.fCenter = EQ_CENTERS[i]
        eqParamBuf.fBandwidth = 18.0
        eqParamBuf.fGain = gains[i]
        BASS.BASS_FXSetParameters(S.fxEq[i], eqParamBuf)
      end
    end

    local revPct = clamp(cfg.main.reverb or 0, 0, 100)
    if revPct > 1 then
      if S.fxRev == 0 or S.fxRev == nil then
        S.fxRev = BASS.BASS_ChannelSetFX(h, 8, 0)
      end
      if S.fxRev ~= 0 then
        revParamBuf.fInGain = 0.0
        revParamBuf.fReverbMix = -42.0 * (1.0 - (revPct / 100.0) ^ 0.65)
        revParamBuf.fReverbTime = 900.0 + (revPct / 100.0) * 1600.0
        revParamBuf.fHighFreqRTRatio = 0.35
        BASS.BASS_FXSetParameters(S.fxRev, revParamBuf)
      end
    elseif S.fxRev and S.fxRev ~= 0 then
      BASS.BASS_ChannelRemoveFX(h, S.fxRev)
      S.fxRev = 0
    end
  end)
end

local function selectFxPreset(idx, silent)
  local p = FX_PRESETS[idx]
  if not p then return end
  cfg.main.fxPreset = idx
  if idx ~= 8 then
    cfg.main.eqBass   = p.bass
    cfg.main.eqMid    = p.mid
    cfg.main.eqTreble = p.treble
    cfg.main.speed    = p.speed
    cfg.main.reverb   = p.reverb
  end
  cfgDirty = true
  applyAudioFX()
  if not silent then
    flash('Audio FX: ' .. p.name, false, p.desc)
  end
end

local function saveCustomFxSlot(slot)
  if slot == 1 then
    cfg.main.c1Bass, cfg.main.c1Mid, cfg.main.c1Treble = cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble
    cfg.main.c1Speed, cfg.main.c1Reverb, cfg.main.c1Pan = cfg.main.speed, cfg.main.reverb, cfg.main.pan
  else
    cfg.main.c2Bass, cfg.main.c2Mid, cfg.main.c2Treble = cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble
    cfg.main.c2Speed, cfg.main.c2Reverb, cfg.main.c2Pan = cfg.main.speed, cfg.main.reverb, cfg.main.pan
  end
  cfgDirty = true
  flash('Disimpan ke Slot Custom ' .. (slot == 1 and 'A' or 'B'), false,
    string.format('EQ %+d/%+d/%+ddB | Speed %d%% | Rev %d%%', cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble, cfg.main.speed, cfg.main.reverb))
end

local function loadCustomFxSlot(slot)
  if slot == 1 then
    cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble = cfg.main.c1Bass or 0, cfg.main.c1Mid or 0, cfg.main.c1Treble or 0
    cfg.main.speed, cfg.main.reverb, cfg.main.pan = cfg.main.c1Speed or 100, cfg.main.c1Reverb or 0, cfg.main.c1Pan or 0
  else
    cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble = cfg.main.c2Bass or 0, cfg.main.c2Mid or 0, cfg.main.c2Treble or 0
    cfg.main.speed, cfg.main.reverb, cfg.main.pan = cfg.main.c2Speed or 100, cfg.main.c2Reverb or 0, cfg.main.c2Pan or 0
  end
  cfg.main.fxPreset = 8
  cfgDirty = true
  applyAudioFX()
  flash('Memuat Slot Custom ' .. (slot == 1 and 'A' or 'B'), false,
    string.format('EQ %+d/%+d/%+ddB | Speed %d%% | Rev %d%%', cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble, cfg.main.speed, cfg.main.reverb))
end

local function freeHandle()
  if S.handle ~= 0 then
    pcall(function()
      BASS.BASS_ChannelStop(S.handle)
      BASS.BASS_StreamFree(S.handle)
    end)
    S.handle = 0
    S.fxEq[1], S.fxEq[2], S.fxEq[3] = 0, 0, 0
    S.fxRev = 0
    S.lastAppliedVol = -1
  end
end

local function pushRecent(t)
  if not t or t.url then return end
  for i = #recentTracks, 1, -1 do
    if recentTracks[i] == t then table.remove(recentTracks, i) end
  end
  table.insert(recentTracks, 1, t)
  if #recentTracks > 18 then table.remove(recentTracks) end
end

-- ======================================================================
-- YOUTUBE MUSIC NON-BLOCKING IPC BRIDGE FUNCTIONS
-- ======================================================================
YT.nextSeq = function(prefix)
  YT.seq = YT.seq + 1
  return (prefix or 'q') .. '_' .. tostring(YT.seq) .. '_' .. tostring(math.floor(os.clock() * 1000))
end

YT.writeCmd = function(filename, line)
  ensureDirs()
  local tmp = BRIDGE .. '\\.' .. filename .. '.tmp'
  local dst = BRIDGE .. '\\' .. filename
  local w = io.open(tmp, 'w')
  if w then
    w:write(line .. '\n')
    w:close()
    os.remove(dst)
    os.rename(tmp, dst)
  else
    local w2 = io.open(dst, 'w')
    if w2 then w2:write(line .. '\n'); w2:close() end
  end
end

YT.checkBridge = function()
  local now = os.clock()
  local interval = YT.online and 3.5 or 1.2
  if now - YT.lastPingCheck < interval then return YT.online end
  YT.lastPingCheck = now
  local pfile = BRIDGE .. '\\ping.txt'
  local a = lfs.attributes(pfile)
  if a and a.modification and math.abs(os.time() - a.modification) <= 12 then
    local f = io.open(pfile, 'r')
    if f then
      local line = f:read('*l') or ''
      f:close()
      local ts, port, ff = line:match('^ONLINE|(%d+)|(%d+)|(%d+)')
      if port then
        YT.online = true
        YT.port = tonumber(port) or 48291
        YT.hasFfmpeg = (ff == '1')
        return true
      end
    end
  end
  YT.online = false
  return false
end

YT.lastLaunchAt = 0
YT.tryLaunchPythonBridge = function(silent)
  pcall(function()
    -- Hindari spawn berulang saat bridge masih booting / mengunduh yt-dlp pertama kali
    if os.clock() - (YT.lastLaunchAt or 0) < 15 then return end
    if not shell32Lib then shell32Lib = ffi.load('shell32') end

    -- 1) Mode plug-and-play: MoonRadioBridge.exe (tanpa Python)
    local exeCandidates = {
      ROOT .. '\\MoonRadioBridge.exe',
      getWorkingDirectory() .. '\\radio\\MoonRadioBridge.exe',
      getGameDirectory() .. '\\moonloader\\radio\\MoonRadioBridge.exe'
    }
    for _, exePath in ipairs(exeCandidates) do
      if doesFileExist(exePath) then
        local dir = exePath:match('^(.*)[\\/][^\\/]+$') or ROOT
        YT.lastLaunchAt = os.clock()
        shell32Lib.ShellExecuteA(nil, 'open', exePath, '--bridge --autoexit', dir, 0)
        if not silent then
          flash('Menjalankan MoonRadio Bridge...', false, 'Pertama kali: yt-dlp diunduh otomatis')
        end
        return
      end
    end

    -- 2) Fallback developer: music_player.py via Python terpasang
    local candidates = {
      ROOT .. '\\music_player.py',
      getWorkingDirectory() .. '\\music_player.py',
      getGameDirectory() .. '\\music_player.py'
    }
    for _, scriptPath in ipairs(candidates) do
      if doesFileExist(scriptPath) then
        local dir = scriptPath:match('^(.*)[\\/][^\\/]+$') or ROOT
        YT.lastLaunchAt = os.clock()
        shell32Lib.ShellExecuteA(nil, 'open', 'python', '"' .. scriptPath .. '" --bridge --autoexit', dir, 0)
        if not silent then
          flash('Menjalankan Python YouTube Music Bridge...', false, scriptPath)
        end
        return
      end
    end
    if not silent then
      flash('MoonRadioBridge.exe tidak ditemukan di moonloader\\radio\\', true, 'Bridge belum terdeteksi')
    end
  end)
end

YT.requestSearch = function(query, mode, limit)
  query = trim(tostring(query or ''))
  mode = mode or (YT.searchFilterVideos and 'videos' or 'search')
  limit = limit or 20
  if mode ~= 'discover' and query == '' then
    flash('Ketik judul lagu atau nama penyanyi terlebih dahulu', true)
    return
  end
  if not YT.checkBridge() then
    YT.tryLaunchPythonBridge(true)
  end
  local seq = YT.nextSeq('srch')
  if mode ~= 'automix_append' then
    YT.searching = true
    YT.searchQuery = query
    YT.searchMode = mode
  else
    YT.autoAppending = true
  end
  local cleanQ = query:gsub('[|\r\n]+', ' ')
  YT.writeCmd('cmd_search.txt', string.format('%s|%s|%d|%s', seq, mode, limit, cleanQ))
  if mode == 'search' or mode == 'videos' then
    flash('Mencari di YouTube Music: "' .. query .. '"...', false, mode == 'videos' and 'Mode: Video / Remix / Cover' or 'Streaming tanpa unduh MP3')
  elseif mode == 'playfirst' then
    flash('Mencari & Memutar dari YouTube Music...', false, query)
  elseif mode == 'playlist' then
    local plTitle = query:match(';;(.+)$') or 'Playlist YouTube Music'
    flash('Memuat Playlist YouTube Music...', false, plTitle)
  end
end

YT.requestHome = function(seedTrack, silent)
  if not YT.checkBridge() then
    YT.tryLaunchPythonBridge(true)
  end
  local seq = YT.nextSeq('home')
  YT.homeLoading = true
  local seedVid = seedTrack and extractVideoId(seedTrack) or ''
  if seedVid == '' and #recentTracks > 0 then
    seedVid = extractVideoId(recentTracks[1]) or ''
  end
  YT.writeCmd('cmd_home.txt', string.format('%s|%s', seq, seedVid))
  if not silent then
    flash('Menyegarkan Beranda & Rekomendasi YouTube Music...', false, 'Live via sigma67/ytmusicapi')
  end
end

YT.requestSuggest = function(query)
  query = trim(tostring(query or ''))
  if #query < 2 then
    YT.suggestions = {}
    return
  end
  local seq = YT.nextSeq('sugg')
  local cleanQ = query:gsub('[|\r\n]+', ' ')
  YT.suggUntil = os.clock() + 4.0
  YT.writeCmd('cmd_suggest.txt', string.format('%s|%s', seq, cleanQ))
end

YT.requestPrefetch = function(t)
  if not t or t.url then return end
  local vid = extractVideoId(t)
  if not vid or vid == '' or vid == YT.prefetchedVid then return end
  YT.prefetchedVid = vid
  local seq = YT.nextSeq('pref')
  local cleanT = (t.title or vid):gsub('[|\r\n]+', ' ')
  local cleanA = (t.artist or 'YouTube Music'):gsub('[|\r\n]+', ' ')
  YT.writeCmd('cmd_prefetch.txt', string.format('%s|%s|%s|%s', seq, vid, cleanT, cleanA))
end

YT.requestArtIfMissing = function(t)
  if not t then return end
  local vid = extractVideoId(t)
  if not vid or vid == '' or vid:match('^pl_') then return end
  local now = os.clock()
  if YT.artReqAt[vid] and (now - YT.artReqAt[vid]) < 60.0 then return end
  YT.artReqAt[vid] = now
  YT.requestMeta(t)
end

YT.requestStream = function(t, startSec)
  if not t then return false end
  local vid = extractVideoId(t)
  if not vid or vid == '' then return false end
  if not YT.checkBridge() then
    YT.tryLaunchPythonBridge(true)
  end
  startSec = math.max(0, tonumber(startSec) or 0)
  local seq = YT.nextSeq('strm')
  S.reqSeq = seq
  S.loading = true
  S.loadAt = os.clock()
  S.loadStatus = (startSec > 0.5)
    and string.format('Melompat ke %d:%02d...', math.floor(startSec / 60), math.floor(startSec % 60))
    or '[1/2] Mengambil link audio dari YouTube Music...'
  YT.metaUntil = os.clock() + 14.0
  local cleanT = (t.title or vid):gsub('[|\r\n]+', ' ')
  local cleanA = (t.artist or 'YouTube Music'):gsub('[|\r\n]+', ' ')
  YT.writeCmd('cmd_stream.txt', string.format('%s|%s|%.2f|%s|%s', seq, vid, startSec, cleanT, cleanA))
  return true
end

YT.requestMeta = function(t)
  if not t then return end
  local vid = extractVideoId(t)
  if not vid or vid == '' then return end
  local seq = YT.nextSeq('meta')
  YT.metaUntil = os.clock() + 14.0
  local cleanT = (t.title or vid):gsub('[|\r\n]+', ' ')
  local cleanA = (t.artist or 'YouTube Music'):gsub('[|\r\n]+', ' ')
  YT.writeCmd('cmd_meta.txt', string.format('%s|%s|%s|%s', seq, vid, cleanT, cleanA))
end

local function startBassUrlStream(streamUrl, durSec, startSec)
  freeHandle()
  local h = BASS.BASS_StreamCreateURL(streamUrl, 0, 0x100000, nil, nil)
  if h == 0 then
    S.loading = false
    S.playing = false
    S.err = ERRTXT[BASS.BASS_ErrorGetCode()] or ('Error BASS #' .. BASS.BASS_ErrorGetCode())
    S.errAt = os.clock()
    flash('Gagal membuka stream audio: ' .. S.err, true)
    return false
  end

  S.handle = h
  S.loading = false
  S.err = nil
  S.baseFreq = 44100
  pcall(function()
    freqReadBuf[0] = 44100
    if BASS.BASS_ChannelGetAttribute(h, 1, freqReadBuf) ~= 0 and freqReadBuf[0] > 1000 then
      S.baseFreq = freqReadBuf[0]
    end
  end)

  S.posOffset = tonumber(startSec) or 0
  S.pos = S.posOffset
  if durSec and tonumber(durSec) and tonumber(durSec) > 0 then
    S.dur = tonumber(durSec)
    if S.cur then
      S.cur.dur = S.dur
      S.cur.durStr = string.format('%d:%02d', math.floor(S.dur / 60), math.floor(S.dur % 60))
    end
  elseif S.cur and S.cur.dur and S.cur.dur > 0 then
    S.dur = S.cur.dur
  end
  S.live = false

  S.fadeGain = cfg.main.smoothFade and 0.12 or 1.0
  applyVolume(true)
  applyAudioFX()

  BASS.BASS_ChannelPlay(h, 0)
  S.playing = true
  S.playStarted = os.clock()
  if S.posOffset < 0.5 then
    XT.sesSongs = XT.sesSongs + 1
    S.toastStart = os.clock(); S.toastUntil = S.toastStart + 5.0
  end

  if S.cur and not S.cur.url then
    local lyr = XT.loadTrackLyrics(S.cur)
    if lyr then S.lyrics = lyr; XT.invalidateLyricCache() end
  end
  return true
end

local function playIndex(listName, idx)
  local list = getList(listName)
  local t = list[idx]
  if not t then return false end
  freeHandle()
  S.listName, S.index, S.cur = listName, idx, t
  S.err, S.liveTitle, S.icyName, S.pos, S.posOffset, S.dur, S.live, S.seeking = nil, nil, nil, 0, 0, t.dur or 0, false, false
  S.lyrics = nil
  S.loopA, S.loopB = nil, nil
  S.prefetchedNext = false
  lyricOffset = 0.0
  XT.invalidateLyricCache()

  -- Jika Stasiun Radio Internet (Tab 5 Radio)
  if t.url then
    S.loading = false
    local h = BASS.BASS_StreamCreateURL(t.url, 0, 0x100000, nil, nil)
    if h == 0 then
      S.err = ERRTXT[BASS.BASS_ErrorGetCode()] or ('Error BASS #' .. BASS.BASS_ErrorGetCode())
      S.playing = false
      S.errAt = os.clock()
      return false
    end
    S.handle = h
    S.baseFreq = 44100
    S.fadeGain = cfg.main.smoothFade and 0.08 or 1.0
    applyVolume(true)
    applyAudioFX()
    S.live = true
    BASS.BASS_ChannelPlay(h, 0)
    S.playing = true
    S.nextMeta = 0
    XT.sesSongs = XT.sesSongs + 1
    S.toastStart = os.clock(); S.toastUntil = S.toastStart + 5.0
    cfg.main.lastList = listName
    cfg.main.lastKey = t.url; cfgDirty = true
    return true
  end

  -- Lagu Streaming YouTube Music (Non-Blocking via Python Bridge)
  S.lyrics = XT.loadTrackLyrics(t)
  XT.invalidateLyricCache()
  pushRecent(t)
  YT.requestStream(t, 0)

  S.toastStart = os.clock(); S.toastUntil = S.toastStart + 5.0
  cfg.main.lastList = (listName == 'queue') and 'lib' or listName
  cfg.main.lastKey = t.path; cfgDirty = true
  return true
end

local function playUrl(name, url)
  url = trim(url)
  if url == '' then return end
  if name == '' then name = url end
  tmpList = { { name = fixText(name), url = url } }
  S.history = {}
  playIndex('tmp', 1)
end

local function playQueue(list, label, startIdx)
  if #list == 0 then flash('Tidak ada lagu untuk diputar', true); return end
  queue = list
  S.queueName = label
  S.history = {}; S.errChain = 0; S.skipOnErr = true; S.smartBag = nil
  local idx = startIdx
  if not idx then idx = (cfg.main.shuffle and #list > 1) and math.random(#list) or 1 end
  playIndex('queue', idx)
end

local function ensureCustomQueue()
  if S.listName ~= 'queue' then
    local base = {}
    if S.cur and not S.cur.url then base[1] = S.cur end
    queue = base
    S.listName = 'queue'
    S.index = #queue
    S.queueName = 'Antrean Kustom'
  end
end

local function enqueueTrack(t, playNextFlag)
  if not t then return end
  ensureCustomQueue()
  local insPos = playNextFlag and math.min(#queue + 1, math.max(1, S.index + 1)) or (#queue + 1)
  table.insert(queue, insPos, t)
  flash(playNextFlag and 'Diputar setelah lagu ini' or 'Ditambahkan ke Antrean', false, t.title)
  if not S.cur or S.handle == 0 then
    playIndex('queue', 1)
  end
end

-- Free Queue Control: Move track up/down or remove from queue
local function moveQueueItem(idx, dir)
  if S.listName ~= 'queue' then
    local src = curList()
    local copy = {}
    for i = 1, math.min(#src, 80) do copy[i] = src[i] end
    queue = copy
    S.listName = 'queue'
    S.queueName = 'Antrean Kustom'
  end
  local target = idx + dir
  if target < 1 or target > #queue then return end
  queue[idx], queue[target] = queue[target], queue[idx]
  if S.index == idx then S.index = target
  elseif S.index == target then S.index = idx end
end

local function removeQueueItem(idx)
  if S.listName ~= 'queue' then return end
  local tr = queue[idx]
  if not tr then return end
  table.remove(queue, idx)
  if #queue == 0 then
    freeHandle(); S.playing = false; S.cur = nil; S.index = 0
  elseif idx < S.index then
    S.index = S.index - 1
  elseif idx == S.index then
    playIndex('queue', math.min(idx, #queue))
  end
end

SMART.playAutoMix = function(seedTrack, customPrefix)
  if not seedTrack then return false end
  local mix, vInfo = SMART.buildMix(seedTrack, cfg.main.autoMixCount or 30)
  if #mix < 6 and seedTrack.videoId then
    YT.requestSearch(seedTrack.videoId .. ';;' .. (seedTrack.title or '') .. ' ' .. (seedTrack.artist or ''), 'automix', cfg.main.autoMixCount or 25)
  end
  if #mix <= 1 then
    for idx, lt in ipairs(lib) do
      if lt == seedTrack then
        S.history = {}; S.errChain = 0; S.skipOnErr = true
        return playIndex('lib', idx)
      end
    end
  end
  queue = mix
  local prefix = customPrefix or ('Smart Mix [' .. (vInfo and vInfo.short or 'Vibe') .. ']')
  S.queueName = prefix .. ': ' .. seedTrack.title
  S.history = {}; S.errChain = 0; S.skipOnErr = true; S.smartBag = nil
  local ok = playIndex('queue', 1)
  if ok then
    flash('Auto Mix: ' .. (vInfo and vInfo.name or 'Se-Vibe') .. ' (' .. #mix .. ' lagu)', false, 'Disesuaikan dengan: ' .. seedTrack.title)
  end
  return ok
end

local function playMix(pls, shuffled, label, startTrack)
  local list = mixOf(pls)
  if #list == 0 then flash('Playlist itu belum ada lagunya', true); return end
  if shuffled then SMART.shuffleList(list, startTrack) end
  if not label then label = (#pls == 1) and pls[1].name or ('Mix ' .. #pls .. ' playlist') end
  local idx
  if startTrack then
    for i, t in ipairs(list) do if t == startTrack then idx = i; break end end
  end
  if shuffled and not idx then idx = 1 end
  S.smartBag = nil
  playQueue(list, label, idx)
end

local function pushHistory()
  if S.index > 0 then
    S.history[#S.history + 1] = { S.listName, S.index }
    if #S.history > 60 then table.remove(S.history, 1) end
  end
end

nextTrack = function(auto)
  local list = curList()
  local n = #list
  if n == 0 then return end
  if auto and cfg.main.repeatMode == 2 and isTrackList(S.listName) then return playIndex(S.listName, S.index) end
  local idx
  if cfg.main.shuffle and n > 1 then
    if cfg.main.smartShuffle and isTrackList(S.listName) then
      idx = SMART.pickNext(list, n, S.index)
    else
      idx = S.pick(list, n, S.index)
    end
  else
    idx = S.index + 1
    if idx > n then
      if auto and cfg.main.repeatMode == 0 then
        if cfg.main.autoMix and S.cur and S.cur.videoId then
          SMART.playAutoMix(S.cur)
          return
        end
        S.playing = false
        return
      end
      idx = 1
    end
  end
  pushHistory()
  playIndex(S.listName, idx)
end

local function prevTrack()
  if S.handle ~= 0 and not S.live and S.pos > 3 then
    BASS.BASS_ChannelSetPosition(S.handle, BASS.BASS_ChannelSeconds2Bytes(S.handle, 0), 0)
    S.pos = 0
    XT.invalidateLyricCache()
    return
  end
  local h = table.remove(S.history)
  if h then
    S.listName = h[1]
    playIndex(h[1], h[2])
    return
  end
  local list = curList()
  if #list == 0 then return end
  local idx = S.index - 1
  if idx < 1 then idx = #list end
  playIndex(S.listName, idx)
end

local function togglePlay()
  if S.loading then
    S.loading = false
    S.reqSeq = ''
    flash('Pemutaran dibatalkan')
    return
  end
  if S.handle == 0 then
    if S.cur and S.index > 0 then playIndex(S.listName, S.index)
    elseif #lib > 0 then playIndex('lib', 1)
    elseif #stations > 0 then playIndex('stations', 1) end
    return
  end
  if S.live then
    if S.playing then freeHandle(); S.playing = false else playIndex(S.listName, S.index) end
    return
  end
  local st = BASS.BASS_ChannelIsActive(S.handle)
  if st == 1 or st == 2 then
    BASS.BASS_ChannelPause(S.handle); S.playing = false
  elseif st == 3 or st == 4 then
    if cfg.main.smoothFade then S.fadeGain = 0.15 end
    BASS.BASS_ChannelPlay(S.handle, 0); S.playing = true
  else
    playIndex(S.listName, S.index)
  end
end

local function seekToSec(targetSec)
  if not S.cur or S.live or S.dur <= 0 then return end
  targetSec = clamp(targetSec, 0, math.max(0, S.dur - 0.5))
  S.pos = targetSec
  S.posOffset = targetSec
  XT.invalidateLyricCache()
  if S.cur.yt then
    YT.requestStream(S.cur, targetSec)
  elseif S.handle ~= 0 then
    BASS.BASS_ChannelSetPosition(S.handle, BASS.BASS_ChannelSeconds2Bytes(S.handle, targetSec), 0)
  end
end

local function seekTo(frac)
  if not S.cur or S.live or S.dur <= 0 then return end
  frac = clamp(frac, 0, 1)
  seekToSec(frac * S.dur)
end

local function seekRel(deltaSec)
  if not S.cur or S.live or S.dur <= 0 then return end
  local np = clamp((S.pos or 0) + deltaSec, 0, math.max(0, S.dur - 0.5))
  seekToSec(np)
end

local function pollLiveMeta()
  local h = S.handle
  local p = BASS.BASS_ChannelGetTags(h, 5)
  if p ~= nil then
    local s = ffi.string(p)
    local title = s:match("StreamTitle='(.-)';") or s:match("StreamTitle='(.*)'")
    if title and #title > 0 then
      local cleaned = fixText(title)
      if cleaned ~= '' and cleaned ~= S.liveTitle then
        S.liveTitle = cleaned
        S.toastStart = os.clock(); S.toastUntil = S.toastStart + 5.0
      end
    end
  end
  if not S.icyName then
    local p2 = BASS.BASS_ChannelGetTags(h, 4)
    if p2 ~= nil then
      for _, line in ipairs(XT.readStringList(p2)) do
        local n = line:match('^icy%-name:%s*(.+)')
        if n then S.icyName = fixText(n) end
      end
    end
  end
end

local ART_REF
YT.poll = function()
  local now = os.clock()
  local pollInterval = S.loading and 0.05 or 0.14
  if now - YT.lastPoll < pollInterval then return end
  YT.lastPoll = now
  YT.checkBridge()

  -- Auto-search & live suggestion debounce saat pengguna mengetik di kotak pencarian
  if YT.autoSuggAt > 0 and now >= YT.autoSuggAt and YT.pendingSugg ~= '' then
    local sq = YT.pendingSugg
    YT.autoSuggAt = 0
    YT.pendingSugg = ''
    YT.requestSuggest(sq)
  end
  if YT.autoSearchAt > 0 and now >= YT.autoSearchAt and YT.pendingQuery ~= '' then
    local q = YT.pendingQuery
    YT.autoSearchAt = 0
    YT.pendingQuery = ''
    YT.requestSearch(q, YT.searchFilterVideos and 'videos' or 'search', 20)
  end

  -- 1. Poll respons stream audio HANYA saat sedang loading lagu (hemat Disk I/O laptop)
  if S.loading then
    S.toastUntil = math.max(S.toastUntil or 0, now + 2.0)
    local fStream = io.open(BRIDGE .. '\\resp_stream.txt', 'r')
    if fStream then
      local line = fStream:read('*l') or ''
      fStream:close()
      local status, seq, vid, p4, p5, p6 = line:match('^(%u+)|([^|]+)|([^|]+)|([^|]*)|?([^|]*)|?(.*)$')
      if status and seq and seq == S.reqSeq then
        if status == 'PROGRESS' then
          S.loadStatus = (p4 ~= '' and p4) or 'Menyiapkan audio YouTube Music...'
        elseif status == 'READY' and seq ~= YT.lastStreamSeq then
          YT.lastStreamSeq = seq
          startBassUrlStream(p4, tonumber(p5) or 0, tonumber(p6) or 0)
        elseif status == 'ERR' and seq ~= YT.lastStreamSeq then
          YT.lastStreamSeq = seq
          S.loading = false
          S.playing = false
          S.err = (p4 ~= '' and p4) or 'Gagal memutar stream YouTube Music'
          S.errAt = now
          flash('Gagal memutar: ' .. S.err, true)
        end
      end
    end

    -- Timeout pengaman bila koneksi gagal atau Bridge belum aktif
    if S.loading and (now - S.loadAt) > 18.0 then
      S.loading = false
      S.playing = false
      S.err = YT.online and 'Waktu tunggu stream habis (Timeout)' or 'Bridge belum aktif (MoonRadioBridge.exe)'
      S.errAt = now
      flash(S.err, true)
    end
  end

  -- 2. Poll respons pencarian / playlist / automix HANYA saat sedang mencari
  if YT.searching or YT.autoAppending then
    local fSearch = io.open(BRIDGE .. '\\resp_search.txt', 'r')
    if fSearch then
      local firstLine = fSearch:read('*l') or ''
      local st, seq, mode, cntStr, q = firstLine:match('^(%u+)|([^|]+)|([^|]+)|([^|]+)|?(.*)$')
      if st and seq and seq ~= YT.lastSearchSeq then
        YT.lastSearchSeq = seq
        YT.searching = false
        YT.autoAppending = false
        if st == 'OK' then
          local results = {}
          for raw in fSearch:lines() do
            local line = raw:gsub('\r$', '')
            local vid, ti, ar, al, du, ds = line:match('^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t?(.*)$')
            if vid then
              local tr = upsertYtTrack(vid, ti, ar, al, tonumber(du) or 0, ds, true)
              if tr then results[#results + 1] = tr end
            end
          end
          saveCatalog()
          libVersion = libVersion + 1
          if mode == 'search' or mode == 'videos' then
            YT.searchResults = results
            YT.showSearchOnly = (#results > 0)
            flash(string.format('Ditemukan %d %s di YouTube Music', #results, mode == 'videos' and 'video/remix' or 'lagu'), false, q)
          elseif mode == 'playfirst' then
            YT.searchResults = results
            if #results > 0 then
              if cfg.main.autoMix and #results > 1 then
                playQueue(results, 'YT Music: ' .. (q ~= '' and q or results[1].title), 1)
              else
                for idx, lt in ipairs(lib) do
                  if lt == results[1] then playIndex('lib', idx); break end
                end
              end
              flash('Memutar dari YouTube Music: ' .. results[1].title, false, results[1].artist)
            else
              flash('Lagu tidak ditemukan di YouTube Music: ' .. q, true)
            end
          elseif mode == 'playlist' then
            if #results > 0 then
              playQueue(results, (q ~= '' and q or 'Playlist YouTube Music'), 1)
              flash('Memutar Playlist: ' .. (q ~= '' and q or results[1].title), false, #results .. ' lagu dari YouTube Music')
            else
              flash('Playlist kosong atau gagal dimuat', true)
            end
          elseif mode == 'automix' and #results > 0 then
            local seed = S.cur or results[1]
            local mix = { seed }
            for _, r in ipairs(results) do
              if r ~= seed then mix[#mix + 1] = r end
            end
            playQueue(mix, 'YouTube Smart Mix: ' .. seed.title, 1)
          elseif mode == 'automix_append' and #results > 0 then
            ensureCustomQueue()
            local inQ = {}
            for _, qt in ipairs(queue) do if qt.path then inQ[qt.path] = true end end
            local added = 0
            for _, r in ipairs(results) do
              if r.path and not inQ[r.path] then
                inQ[r.path] = true
                queue[#queue + 1] = r
                added = added + 1
              end
            end
            if added > 0 then
              flash('AutoPlay YT Music: +' .. added .. ' lagu se-vibe ditambahkan ke Antrean', false, S.cur and S.cur.title or '')
            end
          end
        elseif st == 'ERR' then
          flash('Pencarian gagal: ' .. (cntStr or 'Error'), true)
        end
      end
      fSearch:close()
    end
  end

  -- 3. Poll respons Beranda YouTube Music HANYA saat sedang memuat Beranda
  if YT.homeLoading then
    local fHome = io.open(BRIDGE .. '\\resp_home.txt', 'r')
    if fHome then
      local firstLine = fHome:read('*l') or ''
      local st, seq = firstLine:match('^(%u+)|([^|]+)|')
      if st and seq and seq ~= YT.lastHomeSeq then
        YT.lastHomeSeq = seq
        YT.homeLoading = false
        if st == 'OK' then
          local shelfMap = {}
          local shelfOrder = {}
          local pls = {}
          for raw in fHome:lines() do
            local line = raw:gsub('\r$', '')
            local kind, rest = line:match('^(%u%u)\t(.+)$')
            if kind == 'TR' and rest then
              local shf, vid, ti, ar, al, du, ds = rest:match('^([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t?(.*)$')
              if shf and vid then
                local tr = upsertYtTrack(vid, ti, ar, al, tonumber(du) or 0, ds, true)
                if tr then
                  if not shelfMap[shf] then
                    shelfMap[shf] = { name = shf, tracks = {} }
                    shelfOrder[#shelfOrder + 1] = shelfMap[shf]
                  end
                  local list = shelfMap[shf].tracks
                  if #list < 12 then list[#list + 1] = tr end
                end
              end
            elseif kind == 'PL' and rest then
              local pid, ptitle, psub, pshelf, partKey = rest:match('^([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t?(.*)$')
              if pid and ptitle then
                local aKey = (partKey and partKey ~= '') and partKey or ('pl_' .. pid:gsub('[^%w_%-]', ''):sub(1, 24))
                pls[#pls + 1] = {
                  playlistId = pid,
                  title = fixText(ptitle),
                  sub = fixText(psub ~= '' and psub or pshelf),
                  shelf = fixText(pshelf),
                  art = { path = 'yt:' .. aKey, videoId = aKey }
                }
              end
            end
          end
          YT.homeShelves = shelfOrder
          YT.homePlaylists = pls
          saveCatalog()
          libVersion = libVersion + 1
        end
      end
      fHome:close()
    end
  end

  -- 4. Poll saran pencarian langsung HANYA saat menunggu saran
  if (YT.suggUntil or 0) > now then
    local fSugg = io.open(BRIDGE .. '\\resp_suggest.txt', 'r')
    if fSugg then
      local firstLine = fSugg:read('*l') or ''
      local st, seq, sq = firstLine:match('^(%u+)|([^|]+)|?(.*)$')
      if st == 'OK' and seq and seq ~= YT.lastSuggSeq then
        YT.lastSuggSeq = seq
        YT.suggUntil = 0
        YT.suggQuery = sq or ''
        local suggs = {}
        for raw in fSugg:lines() do
          local s = trim(raw:gsub('\r$', ''))
          if s ~= '' then suggs[#suggs + 1] = fixText(s) end
        end
        YT.suggestions = suggs
      end
      fSugg:close()
    end
  end

  -- 5. Poll respons metadata cover art & lirik HANYA dalam rentang aktif setelah request
  if (YT.metaUntil or 0) > now and now - (YT.lastMetaPoll or 0) >= 0.35 then
    YT.lastMetaPoll = now
    local fMeta = io.open(BRIDGE .. '\\resp_meta.txt', 'r')
    if fMeta then
      local line = fMeta:read('*l') or ''
      fMeta:close()
      local tag, seq, vid, hasArt, hasLrc, lyrSrc = line:match('^(%u+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|?(.*)$')
      if tag == 'META' and seq and seq ~= YT.lastMetaSeq then
        YT.lastMetaSeq = seq
        local path = 'yt:' .. vid
        local tr = libByPath[path]
        if tr then
          if hasLrc == '1' then
            tr.hasLrc = true
            tr.lyrSource = (lyrSrc and lyrSrc ~= '') and lyrSrc or 'YouTube Music Synced'
          end
          if hasArt == '1' and ART_REF and ART_REF.c then
            ART_REF.c[path] = nil
          end
        end
        if S.cur and S.cur.videoId == vid and hasLrc == '1' then
          S.lyrics = XT.loadTrackLyrics(S.cur)
          XT.invalidateLyricCache()
        end
      end
    end
  end
end

local lastPlayerTick = os.clock()
local function updatePlayer()
  local now = os.clock()
  local dt = clamp(now - lastPlayerTick, 0.001, 0.25)
  lastPlayerTick = now

  YT.poll()

  if cfg.main.carDuck then
    if now - (S.lastCarCheck or 0) >= 0.25 then
      S.lastCarCheck = now
      local inCar = false
      pcall(function()
        if PLAYER_PED and doesCharExist(PLAYER_PED) then
          inCar = isCharInAnyCar(PLAYER_PED)
        end
      end)
      S.inCarCached = inCar
    end
    local targetCar = S.inCarCached and (1.0 + (cfg.main.carBoost or 20) / 100.0) or 0.72
    S.carMult = S.carMult + (targetCar - S.carMult) * clamp(dt * 3.5, 0, 1)
  else
    S.carMult = 1.0
  end

  if S.playing and S.fadeGain < 1.0 then
    S.fadeGain = math.min(1.0, S.fadeGain + dt * 1.8)
    applyVolume(false)
  elseif cfg.main.carDuck then
    applyVolume(false)
  end

  local h = S.handle
  if h == 0 then
    if not S.loading and S.err and S.playing == false and isTrackList(S.listName) and S.errChain >= 0 and S.errChain < math.min(#curList(), 8)
       and now - S.errAt > 1.5 and cfg.main.repeatMode ~= 2 and S.skipOnErr then
      S.errChain = S.errChain + 1
      nextTrack(true)
    end
    return
  end

  if now - (S.lastPosPoll or 0) < 0.045 then return end
  S.lastPosPoll = now

  local st = BASS.BASS_ChannelIsActive(h)
  S.state = st
  if st ~= 0 and not S.seeking and not S.loading then
    local pb = BASS.BASS_ChannelGetPosition(h, 0)
    if pb ~= LEN_ERR then
      local el = tonumber(BASS.BASS_ChannelBytes2Seconds(h, pb)) or 0
      S.pos = (S.posOffset or 0) + el
      if S.dur > 0 and S.pos > S.dur then S.dur = S.pos end
    end
    if not S.live and S.loopA and S.loopB and S.loopB > S.loopA + 0.5 and S.pos >= S.loopB then
      seekToSec(S.loopA)
    end
    -- Pre-resolve URL lagu berikutnya secara ringan (tanpa FFmpeg) setelah lagu saat ini stabil berjalan >= 10 detik
    if not S.live and not S.prefetchedNext and S.pos >= 10.0 and not YT.searching then
      S.prefetchedNext = true
      local lst = curList()
      if isTrackList(S.listName) and #lst > 1 and (S.index or 0) >= 1 then
        local nxtIdx = (S.index % #lst) + 1
        if lst[nxtIdx] and lst[nxtIdx] ~= S.cur then
          YT.requestPrefetch(lst[nxtIdx])
        end
      end
    end
    -- Endless AutoPlay (YouTube Music Radio): tambah lagu otomatis saat antrean hampir habis
    if not S.live and S.cur and S.cur.videoId and cfg.main.autoMix and not YT.autoAppending and not YT.searching then
      local lst = curList()
      if isTrackList(S.listName) and (S.index or 0) >= #lst and S.dur > 25 and (S.dur - S.pos) < 20 then
        YT.autoAppending = true
        YT.requestSearch(S.cur.videoId .. ';;' .. (S.cur.title or ''), 'automix_append', 15)
      end
    end
  end
  if st == 0 and S.playing and not S.loading then
    if S.live then
      S.playing = false; S.err = 'Koneksi stream terputus'
    else
      S.errChain = 0
      nextTrack(true)
    end
    return
  end
  if S.live and now >= S.nextMeta then
    S.nextMeta = now + 3
    pcall(pollLiveMeta)
  end
end

local function nowInfo()
  local c = S.cur
  if not c then return 'Belum ada lagu aktif', 'Ketik judul lagu di kotak pencarian atas atau gunakan /rplay [judul]', '' end
  if c.url then
    local title, artist = c.name, 'Live Stream Radio'
    if S.liveTitle then
      local a, b = S.liveTitle:match('^(.-)%s+%-%s+(.+)$')
      if a then artist, title = a, b else title = S.liveTitle; artist = c.name end
    end
    return title, artist, S.icyName or c.name
  end
  local al = c.album or 'YouTube Music'
  if S.loading then
    local el = math.max(0, os.clock() - (S.loadAt or os.clock()))
    local stTxt = (S.loadStatus and S.loadStatus ~= '') and S.loadStatus or '[1/2] Mengambil link audio dari YouTube Music...'
    return c.title, string.format('Memuat (%.1fs)  ·  %s', el, stTxt), al
  end
  if not S.playing and S.err and S.err ~= '' then
    return c.title, 'Gagal Diputar: ' .. S.err .. '  (Klik Play untuk coba lagi)', al
  end
  if c.durStr and c.durStr ~= '' then al = al .. '  ·  ' .. c.durStr end
  return c.title, c.artist, al
end

-- ======================================================================
-- YOUTUBE MUSIC DISCOVERY & CATALOG INITIALIZER
-- ======================================================================
local scan = { pos = 0, total = 0, done = 0, running = false }
local didResume = false

local function resumeLast()
  if didResume then return end
  didResume = true
  if not cfg.main.autoResume or cfg.main.lastKey == '' then return end
  if cfg.main.lastList == 'lib' then
    for i, t in ipairs(lib) do if t.path == cfg.main.lastKey then playIndex('lib', i); return end end
  else
    for i, s in ipairs(stations) do if s.url == cfg.main.lastKey then playIndex('stations', i); return end end
  end
end

local function startScan()
  ensureDirs()
  loadCatalog()
  if not YT.checkBridge() and not YT.bootTried then
    YT.bootTried = true
    YT.tryLaunchPythonBridge(true)
  end
  local seedTrack = (#recentTracks > 0 and recentTracks[1]) or (#lib > 0 and lib[1]) or nil
  YT.requestHome(seedTrack, true)
  if #lib == 0 then
    YT.requestSearch('', 'discover', 25)
  end
  resumeLast()
end

local function stepScan()
  scan.running = false
end

-- ======================================================================
-- ZENITH v3.5 GLASSMORPHISM DESIGN SYSTEM & VISUAL PRIMITIVES
-- ======================================================================
local window = imgui.new.bool(false)
local ui = {
  tab = 1, -- 1 Explore, 2 Stage, 3 Library, 4 Playlists, 5 Radio, 6 Lyrics, 7 Studio FX, 8 Settings
  search = imgui.new.char[128](),
  searchStr = '',
  stName = imgui.new.char[64](),
  stUrl = imgui.new.char[512](),
  plName = imgui.new.char[64](),
  popName = imgui.new.char[64](),
  plView = nil, plSel = {}, delConfirm = nil, addTrack = nil,
  libSort = 1,
  libFilterFav = false, libFilterLrc = false, libFilterVibe = 0,
  lyricAutoScroll = cfg.main.lyricAutoScroll ~= false, lyricManualUntil = 0,
  vinylAngle = 0.0, barsIdle = false,
  -- Free Window Drag & Resize State
  draggingWin = false, resizingWin = false,
  dragOffX = 0, dragOffY = 0
}
local fonts = {}
local GA = 1
local HUD_OPACITY = 1

-- [R-11] Deliberate Border Radius Scale (replaces uniform pill-everything)
local UI_R = {
  WIN  = 16, -- Main window & floating HUD shell
  CARD = 12, -- Containers & functional modules
  CTRL = 8,  -- Buttons, inputs, segmented tabs
  TAG  = 6   -- Compact metadata badges
}

-- [R-29] 5 Refined Glass Surface Themes (2-3 neutral surface tiers + 1 deliberate accent)
local SURFACES = {
  {
    name   = 'Obsidian Frosted',
    bg     = { 0.035, 0.040, 0.054 },
    side   = { 0.052, 0.060, 0.080 },
    panel  = { 0.072, 0.084, 0.112 },
    panel2 = { 0.110, 0.128, 0.168 },
    text   = { 0.960, 0.972, 0.992 },
    sub    = { 0.570, 0.625, 0.715 }
  },
  {
    name   = 'Graphite Studio',
    bg     = { 0.045, 0.047, 0.052 },
    side   = { 0.066, 0.069, 0.078 },
    panel  = { 0.090, 0.095, 0.108 },
    panel2 = { 0.135, 0.142, 0.160 },
    text   = { 0.965, 0.968, 0.975 },
    sub    = { 0.600, 0.620, 0.665 }
  },
  {
    name   = 'Nordic Slate',
    bg     = { 0.028, 0.044, 0.058 },
    side   = { 0.042, 0.064, 0.084 },
    panel  = { 0.062, 0.090, 0.118 },
    panel2 = { 0.098, 0.138, 0.176 },
    text   = { 0.945, 0.978, 0.995 },
    sub    = { 0.555, 0.665, 0.745 }
  },
  {
    name   = 'Espresso Acoustic',
    bg     = { 0.052, 0.038, 0.036 },
    side   = { 0.076, 0.056, 0.054 },
    panel  = { 0.106, 0.078, 0.075 },
    panel2 = { 0.156, 0.116, 0.112 },
    text   = { 0.985, 0.962, 0.952 },
    sub    = { 0.695, 0.610, 0.590 }
  },
  {
    name   = 'Pure AMOLED',
    bg     = { 0.010, 0.012, 0.016 },
    side   = { 0.026, 0.030, 0.038 },
    panel  = { 0.048, 0.054, 0.068 },
    panel2 = { 0.088, 0.098, 0.122 },
    text   = { 0.975, 0.980, 0.990 },
    sub    = { 0.545, 0.575, 0.635 }
  }
}

local C = {
  bg     = { 0.035, 0.040, 0.054 },
  side   = { 0.052, 0.060, 0.080 },
  panel  = { 0.072, 0.084, 0.112 },
  panel2 = { 0.110, 0.128, 0.168 },
  text   = { 0.960, 0.972, 0.992 },
  sub    = { 0.570, 0.625, 0.715 },
  red    = { 0.980, 0.360, 0.420 },
  green  = { 0.220, 0.880, 0.620 },
  gold   = { 0.980, 0.780, 0.300 },
  white  = { 1.000, 1.000, 1.000 }
}

local function syncSurface()
  local sf = SURFACES[clamp(cfg.main.surface or 1, 1, #SURFACES)] or SURFACES[1]
  C.bg, C.side, C.panel, C.panel2, C.text, C.sub = sf.bg, sf.side, sf.panel, sf.panel2, sf.text, sf.sub
end
syncSurface()

local accents = {
  { 0.22, 0.82, 0.98 }, -- 1 Ice Cyan
  { 0.38, 0.62, 1.00 }, -- 2 Cobalt Blue
  { 0.24, 0.88, 0.66 }, -- 3 Emerald Mint
  { 0.98, 0.68, 0.26 }, -- 4 Warm Amber
  { 0.96, 0.40, 0.58 }, -- 5 Rose Quartz
  { 0.66, 0.52, 1.00 }, -- 6 Soft Iris
  { 0.96, 0.84, 0.34 }, -- 7 Solar Gold
  { 0.88, 0.93, 1.00 }, -- 8 Pure Frost
  { 0.98, 0.34, 0.38 }, -- 9 Crimson Coral
  { 0.64, 0.94, 0.32 }  -- 10 Lime Studio
}
local accentNames = {
  'Ice Cyan', 'Cobalt Blue', 'Emerald Mint', 'Warm Amber', 'Rose Quartz',
  'Soft Iris', 'Solar Gold', 'Pure Frost', 'Crimson Coral', 'Lime Studio'
}

local function V2(x, y) return imgui.ImVec2(x, y) end
local function V4(c, a) return imgui.ImVec4(c[1], c[2], c[3], a or 1) end

local function U32RGB(r, g, b, a)
  local al = (a or 1) * GA * HUD_OPACITY
  if al < 0 then al = 0 elseif al > 1 then al = 1 end
  if r < 0 then r = 0 elseif r > 1 then r = 1 end
  if g < 0 then g = 0 elseif g > 1 then g = 1 end
  if b < 0 then b = 0 elseif b > 1 then b = 1 end
  return math.floor(al * 255 + 0.5) * 16777216 + math.floor(b * 255 + 0.5) * 65536
       + math.floor(g * 255 + 0.5) * 256 + math.floor(r * 255 + 0.5)
end

local function U32(c, a)
  return U32RGB(c[1], c[2], c[3], a)
end

local function accent() return accents[cfg.main.accent] or accents[1] end
local function glassOpacity() return clamp((cfg.main.glassAlpha or 88) / 100.0, 0.55, 0.98) end

local function pushFont(name)
  if fonts[name] then imgui.PushFont(fonts[name]); return true end
  return false
end
local function popFont(b) if b then imgui.PopFont() end end
local function T(dl, x, y, col, s) dl:AddText(V2(x, y), col, s) end

local function fmtTime(t)
  t = math.max(0, math.floor(t or 0))
  return string.format('%d:%02d', math.floor(t / 60), t % 60)
end

-- Two-Generation Ellipsize Cache + Fast Length Check (Zero Frame-Spike Optimization)
local ellCache, ellCacheOld, ellCount = {}, {}, 0
local function ellipsize(s, maxw, tag)
  s = tostring(s or '')
  if maxw <= 12 or s == '' then return '' end
  if #s * 10.5 <= maxw then return s end
  local key = (tag or '') .. '|' .. math.floor(maxw * 0.25) .. '|' .. s
  local c = ellCache[key] or ellCacheOld[key]
  if c then return c end
  local out = s
  if imgui.CalcTextSize(s).x > maxw then
    local ew = imgui.CalcTextSize('...').x
    local cut = s
    while #cut > 0 and imgui.CalcTextSize(cut).x + ew > maxw do
      local ns = cut:gsub('[%z\1-\127\194-\244][\128-\191]*$', '')
      if ns == cut then ns = cut:sub(1, -2) end
      cut = ns
    end
    out = cut .. '...'
  end
  ellCount = ellCount + 1
  if ellCount > 900 then
    ellCacheOld = ellCache
    ellCache = {}
    ellCount = 0
  end
  ellCache[key] = out
  return out
end

-- ---------- Layered Glassmorphism & Matte Surface Primitives ([R-10], [R-11], [R-12]) ----------

-- 1. Primary Window / Backdrop Glass Shell (Frosted Acrylic + Top Specular Catchlight)
ui.drawGlassShell = function(dl, x0, y0, x1, y1, r, alpha)
  r = r or UI_R.WIN
  local al = alpha or glassOpacity()
  -- Soft ambient drop shadow ([R-12] elevation on main floating window)
  dl:AddRectFilled(V2(x0 - 3, y0 - 2 + 4), V2(x1 + 3, y1 + 5), U32RGB(0, 0, 0, 0.26 * al), r + 3, 15)
  -- Frosted dark acrylic base
  dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(C.bg, al), r, 15)
  -- Subtle diagonal refractive sheen
  dl:AddRectFilledMultiColor(V2(x0, y0), V2(x1, y1),
    U32(C.white, 0.035), U32(C.white, 0.010), U32(C.white, 0.004), U32(C.white, 0.018))
  -- Crisp 1px top specular catchlight
  dl:AddLine(V2(x0 + r, y0 + 1), V2(x1 - r, y0 + 1), U32(C.white, 0.16), 1.0)
  -- Neutral frosted rim border
  dl:AddRect(V2(x0, y0), V2(x1, y1), U32(C.white, 0.085), r, 15, 1.0)
end

-- 2. Focal Glass Surface ([R-10] Dose Cap: Transport Dock, Stage/Hero Deck, and Floating HUDs only)
ui.drawGlassFocal = function(dl, x0, y0, x1, y1, r, ac, alpha, elev)
  r = r or UI_R.CARD
  ac = ac or accent()
  local al = alpha or math.min(0.96, glassOpacity() + 0.05)
  if elev then
    dl:AddRectFilled(V2(x0 - 2, y0 + 3), V2(x1 + 2, y1 + 4), U32RGB(0, 0, 0, 0.22 * al), r + 2, 15)
  end
  dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(C.side, al), r, 15)
  dl:AddRectFilledMultiColor(V2(x0, y0), V2(x1, y1),
    U32(ac, 0.065), U32(C.white, 0.018), U32(C.bg, 0.08), U32(ac, 0.025))
  dl:AddLine(V2(x0 + r * 0.8, y0 + 1), V2(x1 - r * 0.8, y0 + 1), U32(C.white, 0.15), 1.0)
  dl:AddRect(V2(x0, y0), V2(x1, y1), U32(C.white, 0.09), r, 15, 1.0)
end

-- 3. Clean Matte Surface Card ([R-10] Solid/Matte hierarchy for lists, settings, and secondary modules)
ui.drawMatteCard = function(dl, x0, y0, x1, y1, r, hov, sel, ac)
  r = r or UI_R.CARD
  ac = ac or accent()
  if sel then
    dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(ac, 0.13), r, 15)
    dl:AddRect(V2(x0, y0), V2(x1, y1), U32(ac, 0.42), r, 15, 1.0)
    -- [R-31] Left edge bar ONLY marks active/selected state
    dl:AddRectFilled(V2(x0, y0 + 7), V2(x0 + 3, y1 - 7), U32(ac), 1.5, 15)
  elseif hov then
    dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(C.panel2, 0.78), r, 15)
    dl:AddRect(V2(x0, y0), V2(x1, y1), U32(C.white, 0.10), r, 15, 1.0)
  else
    dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(C.panel, 0.72), r, 15)
    dl:AddRect(V2(x0, y0), V2(x1, y1), U32(C.white, 0.055), r, 15, 1.0)
  end
end

-- ---------- Album Art Texture Cache ----------
local ART = { c = {}, n = 0, loads = 0, tick = 0 }
ART_REF = ART

ART.evict = function()
  local old = {}
  for path, e in pairs(ART.c) do
    if e.used < ART.tick - 2 then old[#old + 1] = path end
  end
  table.sort(old, function(a, b) return ART.c[a].used < ART.c[b].used end)
  local drop = math.min(#old, 32)
  for i = 1, drop do ART.c[old[i]] = nil; ART.n = ART.n - 1 end
  if drop > 0 then collectgarbage('step', 100) end
end

local function getArtTexture(track)
  if not track or not track.path then return nil end
  local now = os.clock()
  local e = ART.c[track.path]
  if e then
    if e.tex then e.used = ART.tick; return e.tex end
    if now < (e.retryAt or 0) then return nil end
  end
  if ART.loads >= 2 then return nil end
  ART.loads = ART.loads + 1
  local tex = nil
  pcall(function()
    local bytes = XT.readArtBytes(track)
    if bytes then
      local buf = ffi.new('uint8_t[?]', #bytes)
      ffi.copy(buf, bytes, #bytes)
      tex = imgui.CreateTextureFromFileInMemory(ffi.cast('void*', buf), #bytes)
    elseif track.videoId and not tostring(track.videoId):match('^pl_') then
      YT.requestArtIfMissing(track)
    end
  end)
  if not ART.c[track.path] then ART.n = ART.n + 1 end
  ART.c[track.path] = { tex = tex or false, used = ART.tick, retryAt = now + 1.5 }
  if ART.n > 80 then ART.evict() end
  return tex
end

-- ---------- Custom Vector Primitives & Vinyl Disc ----------
ui.drawNote = function(dl, cx, cy, s, col)
  local r = s * 0.14
  local x1, x2 = cx - s * 0.2, cx + s * 0.2
  local yh, ytop = cy + s * 0.24, cy - s * 0.3
  dl:AddCircleFilled(V2(x1, yh), r, col, 14)
  dl:AddCircleFilled(V2(x2, yh), r, col, 14)
  local th = math.max(1.5, s * 0.07)
  dl:AddLine(V2(x1 + r - 0.5, yh), V2(x1 + r - 0.5, ytop), col, th)
  dl:AddLine(V2(x2 + r - 0.5, yh), V2(x2 + r - 0.5, ytop - s * 0.05), col, th)
  dl:AddQuadFilled(V2(x1 + r, ytop), V2(x2 + r, ytop - s * 0.05), V2(x2 + r, ytop + s * 0.09), V2(x1 + r, ytop + s * 0.14), col)
end

-- [R-01] Clean Monochrome/Single-Accent Placeholder Art (No generic rainbow/blue-purple multi-color slop)
ui.drawArt = function(dl, x, y, s, rounding, tex, tint)
  local a, b = V2(x, y), V2(x + s, y + s)
  if tex then
    local ok = pcall(function() dl:AddImageRounded(tex, a, b, V2(0, 0), V2(1, 1), U32(C.white), rounding, 15) end)
    if not ok then pcall(function() dl:AddImage(tex, a, b) end) end
  else
    local ac = tint and accents[tint] or accent()
    dl:AddRectFilled(a, b, U32(C.panel2, 0.92), rounding, 15)
    dl:AddRectFilledMultiColor(a, b,
      U32(ac, 0.18), U32(C.white, 0.03), U32(C.side, 0.40), U32(ac, 0.08))
    dl:AddRect(a, b, U32(C.white, 0.08), rounding, 15, 1)
    dl:AddCircle(V2(x + s / 2, y + s / 2), s * 0.32, U32(ac, 0.22), 24, 1.2)
    ui.drawNote(dl, x + s / 2, y + s / 2, s * 0.44, U32(C.text, 0.85))
  end
end

ui.drawVinylDisc = function(dl, cx, cy, r, tex, angle, ac)
  ac = ac or accent()
  dl:AddCircleFilled(V2(cx, cy), r, U32RGB(0.04, 0.045, 0.06, 0.98), 36)
  dl:AddCircle(V2(cx, cy), r, U32(C.white, 0.16), 36, 1.4)
  for i = 1, 3 do
    local gr = r * (0.50 + i * 0.13)
    dl:AddCircle(V2(cx, cy), gr, U32(C.text, 0.05 + (i % 2) * 0.025), 32, 1)
  end
  local ca, sa = math.cos(angle), math.sin(angle)
  local sx1, sy1 = cx + ca * (r * 0.82), cy + sa * (r * 0.82)
  local sx2, sy2 = cx - ca * (r * 0.82), cy - sa * (r * 0.82)
  dl:AddLine(V2(cx, cy), V2(sx1, sy1), U32(C.white, 0.12), 2.0)
  dl:AddLine(V2(cx, cy), V2(sx2, sy2), U32(C.white, 0.12), 2.0)
  local ir = r * 0.42
  if tex then
    ui.drawArt(dl, cx - ir, cy - ir, ir * 2, ir, tex)
  else
    dl:AddCircleFilled(V2(cx, cy), ir, U32(ac, 0.82), 24)
  end
  dl:AddCircle(V2(cx, cy), ir, U32(C.white, 0.22), 24, 1.0)
  dl:AddCircleFilled(V2(cx, cy), math.max(3, r * 0.08), U32(C.bg, 0.98), 14)
end

local PLAYER_ART_STYLES = {
  'Cover Art (YT Music)',
  'Vinyl Disc Berputar',
  'Cover Bawah + Vinyl Stage'
}

-- Indikator visual loading berputar (Spinner) saat menyiapkan stream / mencari lagu
ui.drawSpinner = function(dl, cx, cy, r, col, thick)
  thick = thick or 2.2
  local t = os.clock() * 5.2
  local segs = 12
  local arc = math.pi * 1.35
  local px, py
  for i = 0, segs do
    local a = t + (i / segs) * arc
    local x = cx + math.cos(a) * r
    local y = cy + math.sin(a) * r
    if px then
      dl:AddLine(V2(px, py), V2(x, y), col, thick)
    end
    px, py = x, y
  end
end

-- Indikator bar berjalan (Indeterminate Progress Bar) saat delay koneksi stream YouTube
ui.drawLoadingBar = function(dl, x0, y0, x1, y1, ac)
  local w = x1 - x0
  if w <= 4 then return end
  local h = y1 - y0
  dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(C.panel2, 0.85), h / 2, 15)
  local phase = (os.clock() * 0.85) % 1.0
  local barW = math.max(28, w * 0.28)
  local bx0 = x0 + (w + barW) * phase - barW
  local bx1 = bx0 + barW
  local cx0 = clamp(bx0, x0, x1)
  local cx1 = clamp(bx1, x0, x1)
  if cx1 > cx0 + 2 then
    dl:AddRectFilled(V2(cx0, y0), V2(cx1, y1), U32(ac, 0.92), h / 2, 15)
  end
end

-- Menggambar Cover Art langsung (gaya YouTube Music) atau Vinyl Disc sesuai konfigurasi playerArtStyle
ui.drawPlayerArt = function(dl, cx, cy, r, tex, angle, ac, isBottomBar)
  ac = ac or accent()
  local st = clamp(math.floor(cfg.main.playerArtStyle or 1), 1, 3)
  local useVinyl = (st == 2) or (st == 3 and not isBottomBar)
  if useVinyl then
    ui.drawVinylDisc(dl, cx, cy, r, tex, angle, ac)
  else
    local x, y, s = cx - r, cy - r, r * 2
    local rad = (s >= 72) and UI_R.CARD or UI_R.CTRL
    ui.drawArt(dl, x, y, s, rad, tex)
    dl:AddRect(V2(x, y), V2(x + s, y + s), U32(S.playing and ac or C.white, S.playing and 0.38 or 0.12), rad, 15, 1.0)
  end
  if S.loading then
    local x, y, s = cx - r, cy - r, r * 2
    local rad = useVinyl and r or ((s >= 72) and UI_R.CARD or UI_R.CTRL)
    dl:AddRectFilled(V2(x, y), V2(x + s, y + s), U32RGB(0, 0, 0, 0.62), rad, 15)
    ui.drawSpinner(dl, cx, cy, math.max(8, r * 0.48), U32(ac, 0.96), math.max(2.0, r * 0.09))
  end
end

ui.drawIcon = function(dl, kind, cx, cy, s, col)
  if kind == 'play' then
    dl:AddTriangleFilled(V2(cx - s * 0.32, cy - s * 0.5), V2(cx - s * 0.32, cy + s * 0.5), V2(cx + s * 0.55, cy), col)
  elseif kind == 'pause' then
    local w, hh = s * 0.26, s * 0.95
    dl:AddRectFilled(V2(cx - s * 0.42, cy - hh / 2), V2(cx - s * 0.42 + w, cy + hh / 2), col, 2, 15)
    dl:AddRectFilled(V2(cx + s * 0.16, cy - hh / 2), V2(cx + s * 0.16 + w, cy + hh / 2), col, 2, 15)
  elseif kind == 'next' then
    dl:AddTriangleFilled(V2(cx - s * 0.55, cy - s * 0.45), V2(cx - s * 0.55, cy + s * 0.45), V2(cx + s * 0.3, cy), col)
    dl:AddRectFilled(V2(cx + s * 0.38, cy - s * 0.45), V2(cx + s * 0.56, cy + s * 0.45), col, 1, 15)
  elseif kind == 'prev' then
    dl:AddTriangleFilled(V2(cx + s * 0.55, cy - s * 0.45), V2(cx + s * 0.55, cy + s * 0.45), V2(cx - s * 0.3, cy), col)
    dl:AddRectFilled(V2(cx - s * 0.56, cy - s * 0.45), V2(cx - s * 0.38, cy + s * 0.45), col, 1, 15)
  elseif kind == 'shuffle' then
    local x0, x1, x2, x3 = cx - s * 0.6, cx - s * 0.15, cx + s * 0.25, cx + s * 0.5
    local yt, yb = cy - s * 0.32, cy + s * 0.32
    dl:AddLine(V2(x0, yt), V2(x1, yt), col, 2); dl:AddLine(V2(x1, yt), V2(x2, yb), col, 2); dl:AddLine(V2(x2, yb), V2(x3, yb), col, 2)
    dl:AddLine(V2(x0, yb), V2(x1, yb), col, 2); dl:AddLine(V2(x1, yb), V2(x2, yt), col, 2); dl:AddLine(V2(x2, yt), V2(x3, yt), col, 2)
    dl:AddTriangleFilled(V2(x3, yt - 4), V2(x3, yt + 4), V2(x3 + 6, yt), col)
    dl:AddTriangleFilled(V2(x3, yb - 4), V2(x3, yb + 4), V2(x3 + 6, yb), col)
  elseif kind == 'repeat' or kind == 'repeat1' then
    dl:AddRect(V2(cx - s * 0.6, cy - s * 0.34), V2(cx + s * 0.6, cy + s * 0.34), col, 4, 15, 2)
    dl:AddTriangleFilled(V2(cx + s * 0.18, cy - s * 0.34 - 5), V2(cx + s * 0.18, cy - s * 0.34 + 5), V2(cx + s * 0.18 + 7, cy - s * 0.34), col)
    if kind == 'repeat1' then dl:AddText(V2(cx - 3.5, cy - 8), col, '1') end
  elseif kind == 'vol' or kind == 'mute' then
    dl:AddRectFilled(V2(cx - s * 0.7, cy - s * 0.2), V2(cx - s * 0.35, cy + s * 0.2), col, 1, 15)
    dl:AddQuadFilled(V2(cx - s * 0.35, cy - s * 0.2), V2(cx + s * 0.05, cy - s * 0.55), V2(cx + s * 0.05, cy + s * 0.55), V2(cx - s * 0.35, cy + s * 0.2), col)
    if kind == 'vol' then
      dl:AddLine(V2(cx + s * 0.3, cy - s * 0.25), V2(cx + s * 0.42, cy), col, 2)
      dl:AddLine(V2(cx + s * 0.42, cy), V2(cx + s * 0.3, cy + s * 0.25), col, 2)
      dl:AddLine(V2(cx + s * 0.5, cy - s * 0.5), V2(cx + s * 0.68, cy), col, 2)
      dl:AddLine(V2(cx + s * 0.68, cy), V2(cx + s * 0.5, cy + s * 0.5), col, 2)
    else
      dl:AddLine(V2(cx + s * 0.3, cy - s * 0.25), V2(cx + s * 0.7, cy + s * 0.25), col, 2)
      dl:AddLine(V2(cx + s * 0.3, cy + s * 0.25), V2(cx + s * 0.7, cy - s * 0.25), col, 2)
    end
  elseif kind == 'close' then
    dl:AddLine(V2(cx - s * 0.4, cy - s * 0.4), V2(cx + s * 0.4, cy + s * 0.4), col, 2)
    dl:AddLine(V2(cx - s * 0.4, cy + s * 0.4), V2(cx + s * 0.4, cy - s * 0.4), col, 2)
  elseif kind == 'compact' then
    dl:AddRect(V2(cx - s * 0.58, cy - s * 0.44), V2(cx + s * 0.58, cy + s * 0.44), col, 2.5, 15, 1.8)
    dl:AddRectFilled(V2(cx - s * 0.58, cy + s * 0.08), V2(cx + s * 0.58, cy + s * 0.44), col, 1.5, 15)
  elseif kind == 'expand' then
    dl:AddRect(V2(cx - s * 0.58, cy - s * 0.46), V2(cx + s * 0.58, cy + s * 0.46), col, 2.5, 15, 1.8)
    dl:AddLine(V2(cx - s * 0.26, cy), V2(cx + s * 0.26, cy), col, 1.8)
    dl:AddLine(V2(cx, cy - s * 0.26), V2(cx, cy + s * 0.26), col, 1.8)
  elseif kind == 'up' then
    dl:AddTriangleFilled(V2(cx, cy - s * 0.42), V2(cx - s * 0.48, cy + s * 0.32), V2(cx + s * 0.48, cy + s * 0.32), col)
  elseif kind == 'down' then
    dl:AddTriangleFilled(V2(cx, cy + s * 0.42), V2(cx - s * 0.48, cy - s * 0.32), V2(cx + s * 0.48, cy - s * 0.32), col)
  elseif kind == 'home' then
    dl:AddTriangleFilled(V2(cx - s * 0.75, cy - s * 0.05), V2(cx + s * 0.75, cy - s * 0.05), V2(cx, cy - s * 0.7), col)
    dl:AddRectFilled(V2(cx - s * 0.5, cy - s * 0.05), V2(cx + s * 0.5, cy + s * 0.65), col, 1, 15)
  elseif kind == 'plist' then
    for i = -1, 1 do dl:AddLine(V2(cx - s * 0.6, cy + i * s * 0.34), V2(cx + s * 0.15, cy + i * s * 0.34), col, 2) end
    dl:AddTriangleFilled(V2(cx + s * 0.3, cy - s * 0.3), V2(cx + s * 0.3, cy + s * 0.3), V2(cx + s * 0.75, cy), col)
  elseif kind == 'heart' then
    local r = s * 0.36
    dl:AddCircleFilled(V2(cx - r * 0.95, cy - r * 0.55), r, col, 14)
    dl:AddCircleFilled(V2(cx + r * 0.95, cy - r * 0.55), r, col, 14)
    dl:AddTriangleFilled(V2(cx - r * 1.82, cy - r * 0.28), V2(cx + r * 1.82, cy - r * 0.28), V2(cx, cy + s * 0.78), col)
  elseif kind == 'plus' then
    dl:AddLine(V2(cx - s * 0.45, cy), V2(cx + s * 0.45, cy), col, 2)
    dl:AddLine(V2(cx, cy - s * 0.45), V2(cx, cy + s * 0.45), col, 2)
  elseif kind == 'queue' then
    dl:AddLine(V2(cx - s * 0.55, cy - s * 0.36), V2(cx + s * 0.55, cy - s * 0.36), col, 2)
    dl:AddLine(V2(cx - s * 0.55, cy), V2(cx + s * 0.2, cy), col, 2)
    dl:AddLine(V2(cx - s * 0.55, cy + s * 0.36), V2(cx + s * 0.2, cy + s * 0.36), col, 2)
    dl:AddTriangleFilled(V2(cx + s * 0.32, cy - s * 0.05), V2(cx + s * 0.32, cy + s * 0.45), V2(cx + s * 0.68, cy + s * 0.2), col)
  elseif kind == 'star' then
    dl:AddQuadFilled(V2(cx, cy - s * 0.65), V2(cx + s * 0.65, cy), V2(cx, cy + s * 0.65), V2(cx - s * 0.65, cy), col)
  elseif kind == 'fx' then
    for i = -1, 1 do
      local x = cx + i * s * 0.42
      dl:AddLine(V2(x, cy - s * 0.55), V2(x, cy + s * 0.55), col, 2)
      local ky = cy + (i == 0 and -s * 0.22 or s * 0.2)
      dl:AddCircleFilled(V2(x, ky), s * 0.2, col, 10)
    end
  elseif kind == 'mic' then
    dl:AddRectFilled(V2(cx - s * 0.26, cy - s * 0.62), V2(cx + s * 0.26, cy + s * 0.12), col, s * 0.25, 15)
    dl:AddLine(V2(cx - s * 0.45, cy + s * 0.18), V2(cx + s * 0.45, cy + s * 0.18), col, 2)
    dl:AddLine(V2(cx, cy + s * 0.18), V2(cx, cy + s * 0.58), col, 2)
    dl:AddLine(V2(cx - s * 0.3, cy + s * 0.58), V2(cx + s * 0.3, cy + s * 0.58), col, 2)
  elseif kind == 'note' then
    ui.drawNote(dl, cx, cy, s * 1.65, col)
  elseif kind == 'bolt' then
    dl:AddTriangleFilled(V2(cx + s * 0.15, cy - s * 0.72), V2(cx - s * 0.52, cy + s * 0.08), V2(cx + s * 0.06, cy + s * 0.08), col)
    dl:AddTriangleFilled(V2(cx - s * 0.06, cy - s * 0.08), V2(cx + s * 0.52, cy - s * 0.08), V2(cx - s * 0.15, cy + s * 0.72), col)
  elseif kind == 'moon' then
    dl:AddCircleFilled(V2(cx, cy), s * 0.55, col, 16)
    dl:AddCircleFilled(V2(cx + s * 0.24, cy - s * 0.14), s * 0.42, U32(C.panel2), 14)
  elseif kind == 'dice' then
    dl:AddRect(V2(cx - s * 0.55, cy - s * 0.55), V2(cx + s * 0.55, cy + s * 0.55), col, 3, 15, 1.8)
    dl:AddCircleFilled(V2(cx - s * 0.24, cy - s * 0.24), s * 0.11, col, 8)
    dl:AddCircleFilled(V2(cx, cy), s * 0.11, col, 8)
    dl:AddCircleFilled(V2(cx + s * 0.24, cy + s * 0.24), s * 0.11, col, 8)
  elseif kind == 'nav1' then
    dl:AddCircle(V2(cx, cy), s * 0.5, col, 20, 2)
    dl:AddTriangleFilled(V2(cx - s * 0.13, cy - s * 0.22), V2(cx - s * 0.13, cy + s * 0.22), V2(cx + s * 0.25, cy), col)
  elseif kind == 'nav2' then
    for i = -1, 1 do dl:AddLine(V2(cx - s * 0.5, cy + i * s * 0.34), V2(cx + s * 0.5, cy + i * s * 0.34), col, 2) end
  elseif kind == 'nav3' then
    for i = -1, 1 do
      local hh = s * (0.45 + (i + 1) * 0.25)
      dl:AddRectFilled(V2(cx + i * s * 0.34 - 2, cy + s * 0.5 - hh), V2(cx + i * s * 0.34 + 2, cy + s * 0.5), col, 2, 15)
    end
  elseif kind == 'nav4' then
    dl:AddLine(V2(cx - s * 0.5, cy - s * 0.25), V2(cx + s * 0.5, cy - s * 0.25), col, 2)
    dl:AddLine(V2(cx - s * 0.5, cy + s * 0.25), V2(cx + s * 0.5, cy + s * 0.25), col, 2)
    dl:AddCircleFilled(V2(cx - s * 0.18, cy - s * 0.25), s * 0.17, col, 14)
    dl:AddCircleFilled(V2(cx + s * 0.2, cy + s * 0.25), s * 0.17, col, 14)
  end
end

ui.iconBtn = function(id, cx, cy, r, kind, on, size)
  imgui.SetCursorPos(V2(cx - r, cy - r))
  imgui.InvisibleButton(id, V2(r * 2, r * 2))
  local hov = imgui.IsItemHovered()
  local clicked = imgui.IsItemClicked()
  local a = imgui.GetItemRectMin()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  if hov or on then
    dl:AddRectFilled(V2(a.x, a.y), V2(a.x + r * 2, a.y + r * 2),
      U32(on and ac or C.panel2, on and 0.16 or 0.72), UI_R.CTRL, 15)
    if on then
      dl:AddRect(V2(a.x, a.y), V2(a.x + r * 2, a.y + r * 2), U32(ac, 0.38), UI_R.CTRL, 15, 1)
    end
  end
  local col = on and U32(ac) or (hov and U32(C.text) or U32(C.sub))
  ui.drawIcon(dl, kind, a.x + r, a.y + r, size or r, col)
  return clicked
end

-- [R-11] Deliberate Control Button: Uses crisp UI_R.CTRL (8px) radius instead of uniform pills
ui.pill = function(id, label, x, y, w, h, primary, badgeCol, icon)
  imgui.SetCursorPos(V2(x, y))
  imgui.InvisibleButton(id, V2(w, h))
  local hov, act = imgui.IsItemHovered(), imgui.IsItemActive()
  local clicked = imgui.IsItemClicked()
  local a, b = imgui.GetItemRectMin(), imgui.GetItemRectMax()
  local dl = imgui.GetWindowDrawList()
  local ac = badgeCol or accent()
  local rad = UI_R.CTRL
  local bg, fg
  if primary then
    bg = U32(ac, act and 0.82 or (hov and 0.98 or 0.90))
    fg = U32(C.bg)
    dl:AddRectFilled(a, b, bg, rad, 15)
    dl:AddLine(V2(a.x + rad, a.y + 1), V2(b.x - rad, a.y + 1), U32(C.white, 0.25), 1)
  else
    bg = U32(C.panel2, act and 0.85 or (hov and 0.95 or 0.68))
    fg = U32(hov and C.white or C.text)
    dl:AddRectFilled(a, b, bg, rad, 15)
    dl:AddRect(a, b, U32(C.white, hov and 0.16 or 0.07), rad, 15, 1)
  end
  local sz = imgui.CalcTextSize(label)
  if icon then
    local totalW = sz.x + 18
    local sx = a.x + (w - totalW) / 2
    ui.drawIcon(dl, icon, sx + 6, a.y + h / 2, 7.5, fg)
    T(dl, sx + 18, a.y + (h - sz.y) / 2, fg, label)
  else
    T(dl, a.x + (w - sz.x) / 2, a.y + (h - sz.y) / 2, fg, label)
  end
  return clicked
end

ui.toggle = function(id, x, y, on)
  imgui.SetCursorPos(V2(x, y))
  imgui.InvisibleButton(id, V2(44, 22))
  local clicked = imgui.IsItemClicked()
  local hov = imgui.IsItemHovered()
  local a = imgui.GetItemRectMin()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  dl:AddRectFilled(a, V2(a.x + 44, a.y + 22), on and U32(ac, 0.92) or U32(C.panel2, 0.88), 11, 15)
  dl:AddRect(a, V2(a.x + 44, a.y + 22), U32(C.white, hov and 0.28 or 0.08), 11, 15, 1)
  dl:AddCircleFilled(V2(a.x + (on and 33 or 11), a.y + 11), 8, U32(on and C.bg or C.sub), 16)
  return clicked
end

-- Slider with Free Control: Mouse-Wheel Fine Tuning + Right-Click Reset + Center Mark
ui.slider = function(id, x, y, w, frac, disabled, previewDur, centerMark, wheelStep)
  local h = 18
  imgui.SetCursorPos(V2(x, y))
  imgui.InvisibleButton(id, V2(w, h))
  local hov, act = imgui.IsItemHovered(), imgui.IsItemActive()
  local released = imgui.IsItemDeactivated()
  local io = imgui.GetIO()
  local rclick = hov and imgui.IsMouseClicked(1) and not disabled
  local p = imgui.GetItemRectMin()
  local dl = imgui.GetWindowDrawList()
  local cy = p.y + h / 2
  local ac = accent()
  local th = (hov or act) and not disabled and 6 or 4
  dl:AddRectFilled(V2(p.x, cy - th / 2), V2(p.x + w, cy + th / 2), U32(C.panel2, 0.92), th / 2, 15)

  if centerMark then
    local mx = p.x + w * 0.5
    dl:AddRectFilled(V2(mx - 1, cy - 6), V2(mx + 1, cy + 6), U32(C.sub, 0.55), 1, 15)
  end

  local nf, changed = frac, false
  local mouseFrac = clamp((io.MousePos.x - p.x) / math.max(1, w), 0, 1)
  if act and not disabled then
    nf = mouseFrac; changed = true
  elseif rclick and centerMark then
    nf = 0.5; changed = true
  elseif hov and not disabled and math.abs(io.MouseWheel or 0) > 0.01 then
    local step = wheelStep or (previewDur and (5.0 / math.max(10, previewDur)) or 0.03)
    nf = clamp(frac + (io.MouseWheel > 0 and step or -step), 0, 1)
    changed = true
    released = true
  end

  if previewDur and previewDur > 0 and (S.loopA or S.loopB) then
    local la = clamp((S.loopA or 0) / previewDur, 0, 1)
    local lb = clamp((S.loopB or previewDur) / previewDur, 0, 1)
    local lx0, lx1 = p.x + w * la, p.x + w * lb
    dl:AddRectFilled(V2(lx0, cy - 6), V2(lx1, cy + 6), U32(C.gold, 0.24), 3, 15)
    dl:AddRectFilled(V2(lx0 - 1, cy - 8), V2(lx0 + 2, cy + 8), U32(C.gold, 0.95), 1, 15)
    if S.loopB then
      dl:AddRectFilled(V2(lx1 - 2, cy - 8), V2(lx1 + 1, cy + 8), U32(C.gold, 0.95), 1, 15)
    end
  end

  if previewDur and previewDur > 0 and S.cur then
    local bm = getBookmark(S.cur)
    if bm and bm > 0 and bm <= previewDur then
      local bx = p.x + w * clamp(bm / previewDur, 0, 1)
      ui.drawIcon(dl, 'star', bx, cy, 7, U32(C.gold, 0.95))
    end
  end

  local curF = changed and nf or frac
  local fw = w * curF
  if centerMark then
    local x0 = p.x + w * 0.5
    local x1 = p.x + fw
    if math.abs(x1 - x0) > 1 then
      local leftX, rightX = math.min(x0, x1), math.max(x0, x1)
      dl:AddRectFilled(V2(leftX, cy - th / 2), V2(rightX, cy + th / 2), U32((hov or act) and not disabled and ac or C.text), th / 2, 15)
    end
  elseif fw > 0.5 then
    dl:AddRectFilled(V2(p.x, cy - th / 2), V2(p.x + fw, cy + th / 2), U32((hov or act) and not disabled and ac or C.text), th / 2, 15)
  end

  if (hov or act) and not disabled then
    dl:AddCircleFilled(V2(p.x + fw, cy), 7.5, U32(ac, 0.28), 14)
    dl:AddCircleFilled(V2(p.x + fw, cy), 5.0, U32(C.white), 14)
    if previewDur and previewDur > 0 then
      local hTime = fmtTime(mouseFrac * previewDur)
      local fs = pushFont('small')
      local tsz = imgui.CalcTextSize(hTime)
      local tx = clamp(io.MousePos.x - tsz.x / 2 - 7, p.x, p.x + w - tsz.x - 14)
      local ty = p.y - 24
      dl:AddRectFilled(V2(tx, ty), V2(tx + tsz.x + 14, ty + 20), U32(C.side, 0.96), UI_R.TAG, 15)
      dl:AddRect(V2(tx, ty), V2(tx + tsz.x + 14, ty + 20), U32(C.white, 0.14), UI_R.TAG, 15, 1)
      T(dl, tx + 7, ty + 2, U32(C.white), hTime)
      popFont(fs)
    end
  end
  return changed, nf, released and not disabled
end

ui.drawEq = function(dl, cx, cy, col)
  local t = os.clock()
  for i = 0, 2 do
    local hh = 5 + (math.sin(t * 7 + i * 1.7) + 1) * 5
    dl:AddRectFilled(V2(cx - 8 + i * 6, cy + 8 - hh), V2(cx - 8 + i * 6 + 3, cy + 8), col, 1, 15)
  end
end

-- [R-11 / R-29] Clean technical tag chip (6px radius, calm border)
ui.chip = function(dl, x, y, label, col)
  local sz = imgui.CalcTextSize(label)
  dl:AddRectFilled(V2(x, y), V2(x + sz.x + 16, y + 22), U32(C.panel2, 0.72), UI_R.TAG, 15)
  dl:AddRect(V2(x, y), V2(x + sz.x + 16, y + 22), U32(col or C.white, 0.24), UI_R.TAG, 15, 1)
  T(dl, x + 8, y + 2, U32(col or C.text), label)
  return x + sz.x + 22
end

-- ---------- 3-Mode Visualizer + Peak Meter (With Idle Sleep Optimization) ----------
local NB = 48
local fft = ffi.new('float[256]')
local bars, targets, peaks = {}, {}, {}
for i = 1, NB do bars[i] = 0; targets[i] = 0; peaks[i] = 0 end

ui.updateBars = function(dt, needFft)
  local now = os.clock()
  if now - (S.lastBarFrame or 0) < 0.012 then return end
  S.lastBarFrame = now
  dt = clamp(dt or 0.016, 0.001, 0.1)

  if S.handle ~= 0 and S.playing and S.state == 1 then
    local stArt = cfg.main.playerArtStyle or 1
    if stArt ~= 1 or cfg.main.visStyle == 3 or not window[0] then
      ui.vinylAngle = (ui.vinylAngle + dt * 1.8 * (clamp(cfg.main.speed or 100, 50, 150) / 100.0)) % (math.pi * 2)
    end
    if not needFft then return end
    ui.barsIdle = false
    if now - (S.lastFftAt or 0) >= 0.036 then
      S.lastFftAt = now
      local n = BASS.BASS_ChannelGetData(S.handle, fft, 0x80000000)
      local got = (n ~= 0xFFFFFFFF)
      local lv = BASS.BASS_ChannelGetLevel(S.handle)
      if lv ~= 0xFFFFFFFF then
        local l = bit.band(lv, 0xFFFF) / 32768.0
        local r = bit.rshift(lv, 16) / 32768.0
        if l > S.peakL then S.peakL = l end
        if r > S.peakR then S.peakR = r end
      end
      for i = 1, NB do
        if got then
          local b0 = math.floor(1 + ((i - 1) / NB) ^ 2 * 150)
          local b1 = math.max(b0, math.floor(1 + (i / NB) ^ 2 * 150) - 1)
          local m = 0
          for b = b0, b1 do if fft[b] > m then m = fft[b] end end
          targets[i] = clamp(math.sqrt(m) * (1.6 + i / NB), 0, 1)
        else
          targets[i] = 0
        end
      end
    end
    S.peakL = math.max(0, S.peakL - dt * 1.8)
    S.peakR = math.max(0, S.peakR - dt * 1.8)
  else
    if ui.barsIdle or not needFft then return end
    S.peakL = math.max(0, S.peakL - dt * 2.5)
    S.peakR = math.max(0, S.peakR - dt * 2.5)
    for i = 1, NB do targets[i] = 0 end
  end

  local bassSum, maxVal = 0, S.peakL + S.peakR
  for i = 1, NB do
    local tg = targets[i]
    if tg > bars[i] then
      bars[i] = bars[i] + (tg - bars[i]) * clamp(dt * 18, 0, 1)
    else
      bars[i] = math.max(tg, bars[i] - dt * 1.65)
    end
    if bars[i] >= peaks[i] then
      peaks[i] = bars[i]
    else
      peaks[i] = math.max(0, peaks[i] - dt * 0.55)
    end
    if peaks[i] > maxVal then maxVal = peaks[i] end
    if i <= 8 then bassSum = bassSum + bars[i] end
  end
  S.bassPulse = bassSum / 8
  if not S.playing and maxVal < 0.002 then
    ui.barsIdle = true
    S.bassPulse = 0
  end
end

-- [R-01 / R-29] Single-Accent Spectrum Visualizer (Clean & Monochromatic with White Peak Caps)
ui.drawVisualizerBox = function(dl, x, y, w, h, mode)
  local ac = accent()
  mode = mode or cfg.main.visStyle or 1
  local peakCol = U32(C.white, 0.78)
  if mode == 1 then
    local gap = 3
    local bw = math.max(2, (w - gap * (NB - 1)) / NB)
    for i = 1, NB do
      local v = bars[i]
      local pk = peaks[i]
      local bh = math.max(3, v * (h - 8))
      local x0 = x + (i - 1) * (bw + gap)
      dl:AddRectFilled(V2(x0, y + h - bh), V2(x0 + bw, y + h), U32(ac, 0.28 + 0.68 * v), bw / 2, 15)
      if pk > 0.06 then
        local py = y + h - math.max(5, pk * (h - 8)) - 4
        dl:AddRectFilled(V2(x0, py), V2(x0 + bw, py + 2.0), peakCol, 1, 15)
      end
    end
  elseif mode == 2 then
    local step = w / (NB - 1)
    local midY = y + h * 0.55
    local t = os.clock()
    local lineCol1 = U32(ac, 0.92)
    local lineCol2 = U32(C.white, 0.24)
    for i = 1, NB - 1 do
      local x0 = x + (i - 1) * step
      local x1 = x + i * step
      local v0 = bars[i] * math.sin(t * 4 + i * 0.45)
      local v1 = bars[i + 1] * math.sin(t * 4 + (i + 1) * 0.45)
      local y0 = midY - v0 * (h * 0.44)
      local y1 = midY - v1 * (h * 0.44)
      local y0b = midY + bars[i] * math.cos(t * 3 + i * 0.35) * (h * 0.30)
      local y1b = midY + bars[i + 1] * math.cos(t * 3 + (i + 1) * 0.35) * (h * 0.30)
      dl:AddLine(V2(x0, y0b), V2(x1, y1b), lineCol2, 1.8)
      dl:AddLine(V2(x0, y0), V2(x1, y1), lineCol1, 2.5)
    end
  else
    local gap = 3
    local bw = math.max(2, (w - gap * (NB - 1)) / NB)
    local cy = y + h / 2
    for i = 1, NB do
      local v = bars[i]
      local hh = math.max(2, v * (h * 0.46))
      local x0 = x + (i - 1) * (bw + gap)
      dl:AddRectFilled(V2(x0, cy - hh), V2(x0 + bw, cy + hh), U32(ac, 0.32 + 0.64 * v), bw / 2, 15)
    end
  end
end

-- ---------- Smart Filtered & Sorted Track List ----------
local ROW = 54
local viewCache = {
  q = nil, libVer = -1, libCount = -1, sort = -1,
  fav = false, lrc = false, vibe = 0, vibeVer = -1, plVer = -1, ytOnly = false, view = {}
}

ui.getLibView = function()
  local q = ui.searchStr or ''
  local wantVibe = (ui.libFilterVibe and ui.libFilterVibe > 0 and SMART.VIBES[ui.libFilterVibe]) and SMART.VIBES[ui.libFilterVibe].id or nil
  local ytOnly = YT.showSearchOnly and (#YT.searchResults > 0)
  if viewCache.q ~= q or viewCache.libVer ~= libVersion or viewCache.libCount ~= #lib
     or viewCache.sort ~= ui.libSort or viewCache.fav ~= ui.libFilterFav
     or viewCache.lrc ~= ui.libFilterLrc or viewCache.vibe ~= (ui.libFilterVibe or 0)
     or viewCache.vibeVer ~= vibeVersion or viewCache.plVer ~= plVersion
     or viewCache.ytOnly ~= ytOnly then
    local v = {}
    if ytOnly then
      local idxMap = {}
      for i, t in ipairs(lib) do idxMap[t] = i end
      for _, tr in ipairs(YT.searchResults) do
        local i = idxMap[tr]
        if i then
          local pass = true
          if ui.libFilterFav and not isFav(tr) then pass = false end
          if pass and ui.libFilterLrc and not tr.hasLrc then pass = false end
          if pass and wantVibe and SMART.getProfile(tr).vibe ~= wantVibe then pass = false end
          if pass then v[#v + 1] = i end
        end
      end
    else
      for i, t in ipairs(lib) do
        local pass = (q == '' or t.key:find(q, 1, true) ~= nil)
        if pass and ui.libFilterFav and not isFav(t) then pass = false end
        if pass and ui.libFilterLrc and not t.hasLrc then pass = false end
        if pass and wantVibe and SMART.getProfile(t).vibe ~= wantVibe then pass = false end
        if pass then v[#v + 1] = i end
      end
    end
    if ui.libSort == 2 then
      table.sort(v, function(a, b) return lib[a].title:lower() < lib[b].title:lower() end)
    elseif ui.libSort == 3 then
      table.sort(v, function(a, b) return lib[a].artist:lower() < lib[b].artist:lower() end)
    elseif ui.libSort == 4 then
      table.sort(v, function(a, b) return (lib[a].mtime or 0) > (lib[b].mtime or 0) end)
    end
    viewCache.q, viewCache.libVer, viewCache.libCount = q, libVersion, #lib
    viewCache.sort, viewCache.fav, viewCache.lrc = ui.libSort, ui.libFilterFav, ui.libFilterLrc
    viewCache.vibe, viewCache.vibeVer = (ui.libFilterVibe or 0), vibeVersion
    viewCache.plVer, viewCache.ytOnly, viewCache.view = plVersion, ytOnly, v
  end
  return viewCache.view
end

local stView = { ver = -1, view = {} }
ui.getStView = function()
  if stView.ver ~= stVersion or #stView.view ~= #stations then
    local v = {}
    for i = 1, #stations do v[i] = i end
    stView.ver, stView.view = stVersion, v
  end
  return stView.view
end

ui.drawList = function(listName, list, view, w, h, opts)
  opts = opts or {}
  local sideBtn = opts.del or opts.add
  local favCol = (listName ~= 'stations')
  local qBtn = (listName ~= 'stations')
  local nbtn = (sideBtn and 1 or 0) + (favCol and 1 or 0) + (qBtn and 1 or 0)
  local rsv = (nbtn > 0) and (nbtn * 36 + 8) or 0

  imgui.BeginChild('##list_' .. listName, V2(w, h), false, bit.bor(imgui.WindowFlags.NoBackground))
  local dl = imgui.GetWindowDrawList()
  local n = #view
  local scroll = imgui.GetScrollY()
  local first = math.max(1, math.floor(scroll / ROW) + 1)
  local last = math.min(n, first + math.ceil(h / ROW) + 1)
  local ac = accent()
  local rw = w - 12

  for vi = first, last do
    local idx = view[vi]
    local t = list[idx]
    if t then
      imgui.SetCursorPos(V2(0, (vi - 1) * ROW))
      imgui.InvisibleButton('##row' .. listName .. vi, V2(rw - rsv, ROW - 4))
      local hov = imgui.IsItemHovered()
      local clicked = imgui.IsItemClicked()
      local p0 = imgui.GetItemRectMin()
      local p1 = V2(p0.x + rw, p0.y + ROW - 4)
      local isCur
      if opts.isCur then isCur = opts.isCur(t) else isCur = (S.listName == listName and S.index == idx) end

      if isCur then
        ui.drawMatteCard(dl, p0.x, p0.y, p1.x, p1.y, UI_R.CTRL, false, true, ac)
      elseif hov then
        dl:AddRectFilled(p0, p1, U32(C.panel2, 0.65), UI_R.CTRL, 15)
      elseif vi % 2 == 0 then
        dl:AddRectFilled(p0, p1, U32(C.panel, 0.24), UI_R.CTRL, 15)
      end

      local midY = p0.y + (ROW - 4) / 2
      if isCur and S.loading then
        ui.drawSpinner(dl, p0.x + 26, midY, 8.5, U32(C.gold), 2.0)
      elseif isCur and S.playing then
        ui.drawEq(dl, p0.x + 26, midY, U32(ac))
      elseif hov then
        ui.drawIcon(dl, 'play', p0.x + 26, midY, 9, U32(ac))
      else
        local ns = tostring(vi)
        local nsz = imgui.CalcTextSize(ns)
        T(dl, p0.x + 26 - nsz.x / 2, midY - nsz.y / 2, U32(isCur and ac or C.sub), ns)
      end

      local tx = p0.x + 50
      local albumX = (w > 540) and (p0.x + rw * 0.62) or nil
      local maxw = (albumX and (albumX - tx - 14) or (rw - 50 - 14 - rsv))
      local title, sub, album
      if t.url then
        title, sub = t.name, t.url
      else
        title, sub, album = t.title, t.artist, t.group and ('[' .. t.group .. ']  ' .. t.album) or t.album
      end

      T(dl, tx, p0.y + 6, U32(isCur and ac or C.text), ellipsize(title, maxw, 'r'))
      local fs = pushFont('small')
      if isCur and S.loading then
        local el = math.max(0, os.clock() - (S.loadAt or os.clock()))
        local ltxt = string.format('Memuat audio (%.1fs)  ·  %s', el, S.loadStatus ~= '' and S.loadStatus or 'Menghubungkan ke YouTube Music...')
        T(dl, tx, p0.y + 27, U32(C.gold), ellipsize(ltxt, maxw, 'sload'))
      elseif isCur and not S.playing and S.err and S.err ~= '' then
        T(dl, tx, p0.y + 27, U32(C.red), ellipsize('Gagal: ' .. S.err .. ' (Klik untuk coba lagi)', maxw, 'serr'))
      else
        local badges = ''
        if not t.url then
          if t.durStr and t.durStr ~= '' then
            badges = badges .. '  ·  [' .. t.durStr .. ']'
          end
          if cfg.main.showVibeBadge then
            badges = badges .. '  ·  ' .. SMART.vibeLabel(t)
          end
          if t.hasLrc then badges = badges .. '  ·  LRC' end
          if getBookmark(t) then badges = badges .. '  ·  Drop' end
        end
        T(dl, tx, p0.y + 27, U32(C.sub), ellipsize(sub .. badges, maxw, 's'))
      end
      if albumX and album then
        T(dl, albumX, midY - 8, U32(C.sub), ellipsize(album, p1.x - albumX - 12 - rsv, 's'))
      end
      popFont(fs)

      if clicked then
        if opts.onPlay then
          opts.onPlay(idx, t)
        elseif listName == 'lib' and cfg.main.autoMix and #lib > 1 and (not cfg.main.autoMixLooseOnly or SMART.isLooseTrack(t)) then
          SMART.playAutoMix(t)
        else
          S.history = {}; S.errChain = 0; S.skipOnErr = (listName == 'lib')
          playIndex(listName, idx)
        end
      end

      local btnRight = rw - 34
      if sideBtn then
        imgui.SetCursorPos(V2(btnRight, (vi - 1) * ROW + 9))
        imgui.InvisibleButton('##side' .. listName .. vi, V2(30, 32))
        local dh = imgui.IsItemHovered()
        if imgui.IsItemClicked() then
          if opts.del then
            opts.del(idx, t)
            imgui.EndChild()
            return
          else
            ui.addTrack = t
            imgui.OpenPopup('##addpl')
          end
        end
        if hov or dh then
          if opts.del then ui.drawIcon(dl, 'close', p0.x + btnRight + 15, midY, 10.5, U32(dh and C.red or C.sub))
          else ui.drawIcon(dl, 'plus', p0.x + btnRight + 15, midY, 10.5, U32(dh and ac or C.sub)) end
        end
        btnRight = btnRight - 36
      end

      if favCol and t.path and not t.url then
        imgui.SetCursorPos(V2(btnRight, (vi - 1) * ROW + 9))
        imgui.InvisibleButton('##fav' .. listName .. vi, V2(30, 32))
        local fh = imgui.IsItemHovered()
        local fav = isFav(t)
        if imgui.IsItemClicked() then fav = toggleFav(t) end
        if fav or hov or fh then
          local col = fav and U32(ac) or (fh and U32(C.text) or U32(C.sub, 0.8))
          ui.drawIcon(dl, 'heart', p0.x + btnRight + 15, midY, 9.5, col)
        end
        btnRight = btnRight - 36
      end

      if qBtn and t.path and not t.url then
        imgui.SetCursorPos(V2(btnRight, (vi - 1) * ROW + 9))
        imgui.InvisibleButton('##qnext' .. listName .. vi, V2(30, 32))
        local qh = imgui.IsItemHovered()
        if imgui.IsItemClicked() then enqueueTrack(t, true) end
        if hov or qh then
          ui.drawIcon(dl, 'queue', p0.x + btnRight + 15, midY, 10, U32(qh and ac or C.sub, 0.9))
        end
      end
    end
  end

  imgui.SetCursorPos(V2(0, n * ROW))
  imgui.Dummy(V2(1, 1))

  if opts.add then
    imgui.PushStyleColor(imgui.Col.PopupBg, V4(C.panel))
    imgui.PushStyleColor(imgui.Col.Header, V4(ac, 0.22))
    imgui.PushStyleColor(imgui.Col.HeaderHovered, V4(ac, 0.38))
    imgui.PushStyleColor(imgui.Col.HeaderActive, V4(ac, 0.55))
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, V2(12, 12))
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, V2(8, 6))
    if imgui.BeginPopup('##addpl') then
      local tr = ui.addTrack
      imgui.Dummy(V2(260, 1))
      imgui.TextColored(V4(ac), tr and ellipsize(tr.title, 250, 'pt') or 'Aksi Lagu')
      imgui.Separator()
      if tr and imgui.Selectable('Buat Antrean Smart Mix dari Lagu Ini', false) then
        SMART.playAutoMix(tr)
        imgui.CloseCurrentPopup()
      end
      if tr and imgui.Selectable('Putar Setelah Lagu Ini (Play Next)', false) then
        enqueueTrack(tr, true)
        imgui.CloseCurrentPopup()
      end
      if tr and imgui.Selectable('Tambahkan ke Akhir Antrean', false) then
        enqueueTrack(tr, false)
        imgui.CloseCurrentPopup()
      end
      if tr and tr.path then
        imgui.Separator()
        local curOv = vibeOverrides[relPath(tr.path)]
        local detVibe = SMART.vibeInfo(tr).name
        imgui.TextColored(V4(C.sub), 'Kategori Mood / Vibe (' .. detVibe .. '):')
        if imgui.BeginMenu('Atur Vibe Lagu (Smart Shuffle)...') then
          if imgui.MenuItem('Deteksi Otomatis' .. (not curOv and '  [Aktif]' or '')) then
            SMART.setTrackVibe(tr, 'auto')
            imgui.CloseCurrentPopup()
          end
          imgui.Separator()
          for _, vb in ipairs(SMART.VIBES) do
            if imgui.MenuItem(vb.name .. (curOv == vb.id and '  [Terkunci]' or '')) then
              SMART.setTrackVibe(tr, vb.id)
              imgui.CloseCurrentPopup()
            end
          end
          imgui.EndMenu()
        end
      end
      imgui.Separator()
      imgui.TextColored(V4(C.sub), 'Simpan ke Playlist Manual:')
      for i, pl in ipairs(playlists) do
        local has = tr and plHas(pl, tr.path)
        local label = pl.name .. '  (' .. #pl.tracks .. ')' .. (has and '  [Ada]' or '') .. '##pp' .. i
        if imgui.Selectable(label, false) then
          if tr then
            if has then flash('Sudah ada di "' .. pl.name .. '"', true)
            else addToPlaylist(pl, tr); flash('Ditambahkan ke "' .. pl.name .. '"', false, tr.title) end
          end
          imgui.CloseCurrentPopup()
        end
      end
      if #playlists > 0 then imgui.Separator() end
      if imgui.InputTextWithHint('##popnew', '+ Buat playlist baru & Enter', ui.popName, ffi.sizeof(ui.popName), imgui.InputTextFlags.EnterReturnsTrue) then
        local nm = cleanName(ffi.string(ui.popName))
        if nm ~= '' and tr then
          local pl = createPlaylist(nm)
          if pl then
            addToPlaylist(pl, tr)
            flash('Ditambahkan ke "' .. pl.name .. '"', false, tr.title)
          end
          ffi.fill(ui.popName, ffi.sizeof(ui.popName))
          imgui.CloseCurrentPopup()
        end
      end
      imgui.EndPopup()
    end
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(4)
  end

  imgui.EndChild()
end

-- ======================================================================
-- ZENITH v3.5 WORKSPACE TABS (CLEAN TYPOGRAPHY & LAYERED GLASS)
-- ======================================================================
-- [R-01 / R-09 / R-31] Clean Header: No decorative left color bar, no redundant capsule pill
ui.header = function(title, sub, rightMeta, rightOffset)
  local p = imgui.GetWindowPos()
  local w = imgui.GetWindowWidth()
  local dl = imgui.GetWindowDrawList()
  local roff = rightOffset or 0
  local fs = pushFont('small')
  local metaW = 0
  if rightMeta and rightMeta ~= '' and (w - roff) >= 520 then
    local rsz = imgui.CalcTextSize(rightMeta)
    metaW = rsz.x + 24
    local rx1 = p.x + w - 20 - roff
    dl:AddRectFilled(V2(rx1 - rsz.x - 14, p.y + 18), V2(rx1, p.y + 40), U32(C.panel2, 0.75), UI_R.TAG, 15)
    dl:AddRect(V2(rx1 - rsz.x - 14, p.y + 18), V2(rx1, p.y + 40), U32(C.white, 0.08), UI_R.TAG, 15, 1)
    T(dl, rx1 - rsz.x - 7, p.y + 21, U32(C.sub, 0.92), rightMeta)
  end
  local maxTextW = math.max(160, w - 44 - roff - metaW)
  T(dl, p.x + 22, p.y + 44, U32(C.sub), ellipsize(sub, maxTextW, 'hsub'))
  popFont(fs)
  local fb = pushFont('title')
  T(dl, p.x + 22, p.y + 10, U32(C.text), ellipsize(title, maxTextW, 'htit'))
  popFont(fb)
  dl:AddLine(V2(p.x + 22, p.y + 68), V2(p.x + w - 22, p.y + 68), U32(C.white, 0.07), 1.0)
end

ui.emptyState = function(w, h, line1, line2, withBtn)
  local p = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  dl:AddCircleFilled(V2(p.x + w / 2, p.y + h / 2 - 24), 44, U32(C.panel2, 0.65), 32)
  dl:AddCircle(V2(p.x + w / 2, p.y + h / 2 - 24), 44, U32(C.white, 0.10), 32, 1.0)
  ui.drawNote(dl, p.x + w / 2, p.y + h / 2 - 24, 48, U32(ac, 0.85))
  local s1 = imgui.CalcTextSize(line1)
  T(dl, p.x + (w - s1.x) / 2, p.y + h / 2 + 34, U32(C.text), line1)
  local fs = pushFont('small')
  local s2 = imgui.CalcTextSize(line2)
  T(dl, p.x + (w - s2.x) / 2, p.y + h / 2 + 58, U32(C.sub), line2)
  popFont(fs)
  if withBtn then
    if ui.pill('##openf1', 'Muat Lagu Populer YT', w / 2 - 96, h / 2 + 90, 192, 36, true) then
      YT.requestSearch('', 'discover', 25)
    end
  end
end

ui.styledInput = function(id, hint, buf, x, y, w)
  local ac = accent()
  imgui.PushStyleColor(imgui.Col.FrameBg, V4(C.panel2, 0.78))
  imgui.PushStyleColor(imgui.Col.FrameBgHovered, V4(C.panel2, 0.96))
  imgui.PushStyleColor(imgui.Col.FrameBgActive, V4(C.panel2, 1.0))
  imgui.PushStyleColor(imgui.Col.Border, V4(C.white, 0.10))
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, UI_R.CTRL)
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1)
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, V2(12, 8))
  imgui.SetCursorPos(V2(x, y))
  imgui.SetNextItemWidth(w)
  local changed = imgui.InputTextWithHint(id, hint, buf, ffi.sizeof(buf))
  imgui.PopStyleVar(3)
  imgui.PopStyleColor(4)
  return changed
end

-- ---------- TAB 2: STAGE (FOCAL GLASS DECK + VINYL + SIGNAL TELEMETRY + VISUALIZER) ----------
ui.drawStage = function(w, h)
  local p = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  ui.updateBars(imgui.GetIO().DeltaTime, true)

  -- [R-10] Focal Glass Deck for Stage
  ui.drawGlassFocal(dl, p.x + 16, p.y + 12, p.x + w - 16, p.y + h - 12, UI_R.CARD, ac, nil, false)

  local A = math.min(220, math.max(150, h - 168))
  local ax, ay = 34, 28
  local tex = getArtTexture(S.cur)
  local pulse = (S.bassPulse or 0) * 10

  -- [R-13] Restrained focal halo behind active cover/vinyl only when playing
  if S.playing then
    dl:AddCircleFilled(V2(p.x + ax + A / 2, p.y + ay + A / 2), A * 0.52 + pulse, U32(ac, 0.06 + (S.bassPulse or 0) * 0.08), 36)
  end

  local artSt = cfg.main.playerArtStyle or 1
  if cfg.main.visStyle == 3 or artSt == 2 or artSt == 3 then
    ui.drawVinylDisc(dl, p.x + ax + A / 2, p.y + ay + A / 2, A * 0.48, tex, ui.vinylAngle, ac)
  else
    ui.drawArt(dl, p.x + ax, p.y + ay, A, UI_R.CARD, tex)
    dl:AddRect(V2(p.x + ax, p.y + ay), V2(p.x + ax + A, p.y + ay + A), U32(C.white, 0.12), UI_R.CARD, 15, 1.0)
  end
  if S.loading then
    dl:AddRectFilled(V2(p.x + ax, p.y + ay), V2(p.x + ax + A, p.y + ay + A), U32RGB(0, 0, 0, 0.58), UI_R.CARD, 15)
    ui.drawSpinner(dl, p.x + ax + A / 2, p.y + ay + A / 2, 22, U32(ac, 0.96), 3.0)
  end
  imgui.SetCursorPos(V2(ax, ay))
  imgui.InvisibleButton('##stage_art_btn', V2(A, A))
  if imgui.IsItemHovered() and imgui.IsMouseClicked(1) then
    cfg.main.playerArtStyle = ((cfg.main.playerArtStyle or 1) % #PLAYER_ART_STYLES) + 1
    cfgDirty = true
    flash('Gaya Gambar Player: ' .. PLAYER_ART_STYLES[cfg.main.playerArtStyle])
  end

  -- Stereo Peak Meter
  local mx = p.x + ax + A + 12
  local mh = A
  dl:AddRectFilled(V2(mx, p.y + ay), V2(mx + 4, p.y + ay + mh), U32(C.panel2, 0.8), 2, 15)
  dl:AddRectFilled(V2(mx + 6, p.y + ay), V2(mx + 10, p.y + ay + mh), U32(C.panel2, 0.8), 2, 15)
  local hL = clamp(S.peakL or 0, 0, 1) * mh
  local hR = clamp(S.peakR or 0, 0, 1) * mh
  if hL > 2 then dl:AddRectFilled(V2(mx, p.y + ay + mh - hL), V2(mx + 4, p.y + ay + mh), U32(ac, 0.9), 2, 15) end
  if hR > 2 then dl:AddRectFilled(V2(mx + 6, p.y + ay + mh - hR), V2(mx + 10, p.y + ay + mh), U32(ac, 0.72), 2, 15) end

  -- Signal Telemetry Card (Matte Card below Art)
  local telY = p.y + ay + A + 14
  local telH = (p.y + h - 24) - telY
  if telH >= 56 then
    local telW = A + 10
    ui.drawMatteCard(dl, p.x + ax, telY, p.x + ax + telW, telY + telH, UI_R.CTRL, false, false, ac)
    local fst = pushFont('small')
    local fxpNow = FX_PRESETS[cfg.main.fxPreset or 1] or FX_PRESETS[1]
    local khz = string.format('%.1f kHz', (S.baseFreq or 44100) / 1000)
    T(dl, p.x + ax + 12, telY + 7, U32(C.sub), 'Signal Telemetry')
    T(dl, p.x + ax + 12, telY + 26, U32(C.text), ellipsize('FX: ' .. fxpNow.name, telW - 24, 'tl1'))
    if telH >= 72 then
      local spdTxt = string.format('%s  ·  Speed %d%%', khz, cfg.main.speed or 100)
      T(dl, p.x + ax + 12, telY + 46, U32(C.sub), ellipsize(spdTxt, telW - 24, 'tl2'))
    end
    if telH >= 92 then
      local eqTxt = string.format('EQ %+d / %+d / %+d dB', cfg.main.eqBass or 0, cfg.main.eqMid or 0, cfg.main.eqTreble or 0)
      T(dl, p.x + ax + 12, telY + 66, U32(C.sub), ellipsize(eqTxt, telW - 24, 'tl3'))
    end
    popFont(fst)
  end

  local rx = ax + A + 34
  local rw = w - rx - 32
  local title, artist, album = nowInfo()

  local fs = pushFont('small')
  if S.loading then
    ui.drawSpinner(dl, p.x + rx + 6, p.y + ay + 8, 5.5, U32(C.gold), 1.8)
    T(dl, p.x + rx + 18, p.y + ay, U32(C.gold), 'Menyiapkan Stream YouTube Music...')
  elseif S.live or S.playing then
    local stCol = S.live and C.red or ac
    dl:AddCircleFilled(V2(p.x + rx + 5, p.y + ay + 8), 4.0, U32(stCol), 12)
    T(dl, p.x + rx + 15, p.y + ay, U32(stCol), S.live and 'Live Broadcast' or 'Sedang Diputar')
  elseif S.err and S.err ~= '' then
    dl:AddCircleFilled(V2(p.x + rx + 5, p.y + ay + 8), 4.0, U32(C.red), 12)
    T(dl, p.x + rx + 15, p.y + ay, U32(C.red), 'Pemutaran Gagal')
  else
    T(dl, p.x + rx, p.y + ay, U32(C.sub), 'Dijeda / Siap Diputar')
  end
  popFont(fs)

  local fb = pushFont('title')
  T(dl, p.x + rx, p.y + ay + 20, U32(C.text), ellipsize(title, rw, 'nt'))
  popFont(fb)
  local fb2 = pushFont('bold')
  local artCol = S.loading and C.gold or ((not S.playing and S.err) and C.red or C.sub)
  T(dl, p.x + rx, p.y + ay + 56, U32(artCol), ellipsize(artist, rw, 'na'))
  popFont(fb2)

  local fs2 = pushFont('small')
  T(dl, p.x + rx, p.y + ay + 80, U32(C.sub), ellipsize(album, rw, 'nb'))

  -- Clean Technical Tags ([R-11] 6px tag chips, guarded against right overflow)
  local cx = p.x + rx
  local cy = p.y + ay + 106
  local maxChipX = p.x + w - 28
  local function safeChip(label, col)
    if not label or label == '' then return end
    local sz = imgui.CalcTextSize(label)
    if cx + sz.x + 18 <= maxChipX then
      cx = ui.chip(dl, cx, cy, label, col)
    end
  end
  if S.cur then
    safeChip(S.cur.url and (S.live and 'RADIO' or 'STREAM') or (S.cur.ext or 'YT MUSIC'), ac)
    if not S.cur.url and cfg.main.showVibeBadge then
      local vInfo = SMART.vibeInfo(S.cur)
      safeChip('Vibe: ' .. vInfo.short, C.text)
    end
    local ln = (S.listName == 'lib') and 'Katalog' or (S.listName == 'stations') and 'Radio'
      or (S.listName == 'queue') and (S.queueName or 'Antrean') or 'Langsung'
    local lst = curList()
    if S.index > 0 and #lst > 1 then ln = ln .. ' ' .. S.index .. '/' .. #lst end
    safeChip(ellipsize(ln, 180, 'stq'), C.sub)
  end
  local fxp = FX_PRESETS[cfg.main.fxPreset or 1]
  if fxp and (cfg.main.fxPreset or 1) > 1 then
    safeChip('FX: ' .. fxp.name, ac)
  end
  if (cfg.main.speed or 100) ~= 100 then
    safeChip(string.format('%.2fx', (cfg.main.speed or 100) / 100), C.gold)
  end

  -- Action Controls Row
  local actY = ay + 138
  local loopLabel = (not S.loopA) and 'Loop A-B: Off'
    or (not S.loopB and ('A: ' .. fmtTime(S.loopA) .. ' -> Set B') or ('A-B: ' .. fmtTime(S.loopA) .. '-' .. fmtTime(S.loopB)))
  if ui.pill('##st_ab', loopLabel, rx, actY, 134, 30, S.loopA ~= nil, C.gold) then
    if not S.cur or S.live then
      flash('Pilih lagu YouTube Music terlebih dahulu untuk A-B Loop', true)
    elseif not S.loopA then
      S.loopA = S.pos or 0
      flash('Titik Loop A dikunci di ' .. fmtTime(S.loopA), false, 'Klik lagi untuk mengunci titik B')
    elseif not S.loopB then
      if (S.pos or 0) > S.loopA + 0.8 then
        S.loopB = S.pos
        flash('A-B Loop aktif: ' .. fmtTime(S.loopA) .. ' - ' .. fmtTime(S.loopB), false, S.cur.title)
      else
        S.loopA = nil
        flash('A-B Loop dibatalkan', false)
      end
    else
      S.loopA, S.loopB = nil, nil
      flash('A-B Loop dimatikan', false)
    end
  end

  local bm = S.cur and getBookmark(S.cur)
  local bmTxt = bm and ('Drop ' .. fmtTime(bm)) or 'Simpan Drop'
  if ui.pill('##st_bm', bmTxt, rx + 142, actY, 122, 30, bm ~= nil, C.gold, 'star') then
    if S.cur and not S.live then
      if bm and imgui.GetIO().KeyShift then
        toggleBookmark(S.cur, bm)
      elseif bm and math.abs((S.pos or 0) - bm) > 3 then
        seekTo(bm / math.max(1, S.dur))
        flash('Melompat ke Drop ' .. fmtTime(bm), false, S.cur.title)
      else
        toggleBookmark(S.cur, S.pos or 0)
      end
    end
  end

  local visNames = { 'Vis: Pillars', 'Vis: Wave', 'Vis: Vinyl' }
  if rx + 374 <= w - 20 then
    if ui.pill('##st_vis', visNames[cfg.main.visStyle or 1] or 'Vis', rx + 272, actY, 102, 30, false) then
      cfg.main.visStyle = ((cfg.main.visStyle or 1) % 3) + 1
      cfgDirty = true
    end
  end

  if rx + 504 <= w - 20 then
    if ui.pill('##st_kar', cfg.main.karaoke and 'Karaoke: ON' or 'Karaoke: OFF', rx + 382, actY, 122, 30, cfg.main.karaoke, nil, 'mic') then
      cfg.main.karaoke = not cfg.main.karaoke; cfgDirty = true
      flash('Floating Karaoke HUD: ' .. (cfg.main.karaoke and 'AKTIF' or 'MATI'))
    end
  end

  -- Live Lyric Banner inside Stage ([R-01] Matte card without decorative left stripe)
  local curLyr, nextLyr = currentLyricText()
  local lyY = p.y + ay + 176
  ui.drawMatteCard(dl, p.x + rx, lyY, p.x + rx + rw, lyY + 46, UI_R.CTRL, false, curLyr ~= nil, ac)
  ui.drawNote(dl, p.x + rx + 18, lyY + 16, 13, U32(curLyr and ac or C.sub))
  T(dl, p.x + rx + 30, lyY + 6, U32(curLyr and ac or C.sub),
    ellipsize(curLyr or 'Belum ada lirik aktif — klik di sini untuk membuka tab Lirik', rw - 42, 'stlyr1'))
  T(dl, p.x + rx + 30, lyY + 25, U32(C.sub, 0.78),
    ellipsize(nextLyr or (S.lyrics and S.lyrics.source or 'Lirik tersinkronisasi otomatis dari YouTube Music & LRCLIB'), rw - 42, 'stlyr2'))
  popFont(fs2)

  imgui.SetCursorPos(V2(rx, ay + 176))
  if imgui.InvisibleButton('##st_ly_jump', V2(rw, 46)) then
    ui.tab = 6
  end

  local vh = math.max(52, h - (ay + 234) - 24)
  local vy = p.y + h - vh - 24
  ui.drawVisualizerBox(dl, p.x + rx, vy, rw, vh, cfg.main.visStyle or 1)
end

-- ---------- TAB 6: INTERACTIVE LYRICS + CLICK-TO-SEEK + SYNC OFFSET ----------
ui.drawLyrics = function(w, h)
  local sub = (S.lyrics and S.lyrics.source) or 'Lirik tersinkronisasi otomatis dari YouTube Music & LRCLIB'
  local badge = S.lyrics and (S.lyrics.timed and 'Synced LRC' or 'Plain Text') or nil
  ui.header('Lirik & Karaoke', sub, badge, 326)

  local topY = 18
  if ui.pill('##ly_kar', cfg.main.karaoke and 'Karaoke Layar: ON' or 'Karaoke Layar: OFF', w - 184, topY, 164, 32, cfg.main.karaoke, nil, 'mic') then
    cfg.main.karaoke = not cfg.main.karaoke; cfgDirty = true
    flash('Floating Karaoke HUD: ' .. (cfg.main.karaoke and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##ly_auto', cfg.main.lyricAutoScroll and 'Auto-Scroll: ON' or 'Auto-Scroll: OFF', w - 326, topY, 134, 32, cfg.main.lyricAutoScroll) then
    cfg.main.lyricAutoScroll = not cfg.main.lyricAutoScroll
    ui.lyricAutoScroll = cfg.main.lyricAutoScroll
    cfgDirty = true
    ui.lyricManualUntil = 0
  end

  local areaY = 78
  local areaH = math.max(120, h - areaY - 12)
  imgui.SetCursorPos(V2(18, areaY))
  imgui.BeginChild('##lyricsCard', V2(w - 36, areaH), false,
    bit.bor(imgui.WindowFlags.NoBackground, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse))
  local p = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  ui.drawMatteCard(dl, p.x, p.y, p.x + w - 36, p.y + areaH, UI_R.CARD, false, false, ac)

  local title, artist = nowInfo()
  ui.drawArt(dl, p.x + 16, p.y + 12, 44, UI_R.CTRL, getArtTexture(S.cur))
  local fb = pushFont('bold')
  T(dl, p.x + 72, p.y + 12, U32(C.text), ellipsize(title, w - 380, 'lytitle'))
  popFont(fb)
  local fs = pushFont('small')
  T(dl, p.x + 72, p.y + 35, U32(C.sub), ellipsize(artist .. '  ·  Klik baris lirik untuk melompat ke waktu tersebut', w - 380, 'lyartist'))

  if S.lyrics and S.lyrics.timed then
    local ox = w - 36 - 230
    if ui.pill('##ly_m', '-0.25s', ox, 16, 62, 28, false) then
      lyricOffset = lyricOffset - 0.25
      XT.invalidateLyricCache()
    end
    local offTxt = string.format('Offset: %+.2fs', lyricOffset)
    T(dl, p.x + ox + 70, p.y + 21, U32(lyricOffset ~= 0 and C.gold or C.sub), offTxt)
    if ui.pill('##ly_p', '+0.25s', ox + 158, 16, 62, 28, false) then
      lyricOffset = lyricOffset + 0.25
      XT.invalidateLyricCache()
    end
  end
  popFont(fs)

  if not S.cur then
    ui.emptyState(w - 36, areaH, 'Belum Ada Lagu Diputar', 'Pilih lagu dari Library untuk menampilkan lirik tersinkronisasi', false)
  elseif not S.lyrics or not S.lyrics.lines or #S.lyrics.lines == 0 then
    ui.emptyState(w - 36, areaH, 'Lirik Sedang Dicari / Belum Tersedia',
      'Klik tombol di bawah untuk mengambil lirik sinkronisasi (.LRC) dari YouTube Music & LRCLIB', false)
    if S.cur and S.cur.path and ui.pill('##lyricsFetch', 'Cari Lirik Otomatis (YT/LRC)', (w - 36) / 2 - 110, areaH / 2 + 86, 220, 36, true) then
      YT.requestMeta(S.cur)
      flash('Mencari lirik sinkronisasi untuk: ' .. S.cur.title, false, S.cur.artist)
    end
  else
    local active = currentLyricIndex()
    local prog = currentLyricProgress()
    imgui.SetCursorPos(V2(14, 66))
    local listW = math.max(120, w - 64)
    local listH = math.max(60, areaH - 76)
    imgui.BeginChild('##lyricLines', V2(listW, listH), false, imgui.WindowFlags.NoBackground)
    local ldl = imgui.GetWindowDrawList()
    local ROW_L = 38
    local io = imgui.GetIO()
    local now = os.clock()

    if imgui.IsWindowHovered() and math.abs(io.MouseWheel or 0) > 0.01 then
      ui.lyricManualUntil = now + 3.5
    end

    if cfg.main.lyricAutoScroll and S.lyrics.timed and active and now >= (ui.lyricManualUntil or 0) then
      local targetScroll = math.max(0, (active - 1) * ROW_L - listH * 0.38)
      local curScroll = imgui.GetScrollY()
      imgui.SetScrollY(curScroll + (targetScroll - curScroll) * clamp(io.DeltaTime * 7, 0, 1))
    end

    local lines = S.lyrics.lines
    local n = #lines
    local scroll = imgui.GetScrollY()
    local first = math.max(1, math.floor(scroll / ROW_L) + 1)
    local last = math.min(n, first + math.ceil(listH / ROW_L) + 2)

    for i = first, last do
      local ln = lines[i]
      if ln then
        local ry = (i - 1) * ROW_L
        imgui.SetCursorPos(V2(4, ry))
        imgui.InvisibleButton('##lnbtn' .. i, V2(listW - 18, ROW_L - 4))
        local hov = imgui.IsItemHovered()
        local clicked = imgui.IsItemClicked()
        local p0 = imgui.GetItemRectMin()
        local p1 = V2(p0.x + listW - 18, p0.y + ROW_L - 4)
        local isAct = S.lyrics.timed and (i == active)

        if isAct then
          ldl:AddRectFilled(p0, p1, U32(ac, 0.14), UI_R.CTRL, 15)
          ldl:AddRectFilled(V2(p0.x, p0.y + ROW_L - 6), V2(p0.x + (listW - 18) * prog, p0.y + ROW_L - 4), U32(ac, 0.85), 1.5, 15)
        elseif hov then
          ldl:AddRectFilled(p0, p1, U32(C.panel2, 0.55), UI_R.CTRL, 15)
        end

        if clicked and ln.time and S.dur > 0 then
          seekTo(clamp((ln.time + lyricOffset) / S.dur, 0, 1))
        end

        local fsTime = pushFont('small')
        if ln.time then
          T(ldl, p0.x + 12, p0.y + 9, U32(isAct and ac or C.sub, isAct and 0.95 or 0.6), fmtTime(ln.time))
        end
        popFont(fsTime)

        local tx = ln.time and (p0.x + 62) or (p0.x + 16)
        local fLine = isAct and pushFont('bold') or false
        local dist = active and math.abs(i - active) or 0
        local alpha = isAct and 1.0 or (S.lyrics.timed and clamp(0.85 - dist * 0.12, 0.32, 0.82) or 0.92)
        T(ldl, tx, p0.y + (isAct and 7 or 8), U32(isAct and ac or (hov and C.white or C.text), alpha),
          ellipsize(ln.text, listW - 92, 'll' .. (isAct and 'b' or 'r')))
        popFont(fLine)
      end
    end
    imgui.SetCursorPos(V2(0, n * ROW_L + 16))
    imgui.Dummy(V2(1, 1))
    imgui.EndChild()
  end
  imgui.EndChild()
end

-- ---------- TAB 7: STUDIO AUDIO FX & FREE CUSTOM MEMORY SLOTS ----------
ui.drawStudioFX = function(w, h)
  local fxp = FX_PRESETS[cfg.main.fxPreset or 1] or FX_PRESETS[1]
  ui.header('Studio Audio FX & Kontrol Suara Bebas', 'Equalizer 3-Band DX8, Speed/Pitch, Reverb, Pan & 2 Slot Memori Custom (Scroll = Fine-Tune)', fxp.name, 148)

  if ui.pill('##fx_reset', 'Reset Normal', w - 156, 18, 136, 32, false) then
    cfg.main.pan = 0
    selectFxPreset(1)
  end

  local bodyW = w - 28
  local bodyH = math.max(120, h - 80)
  imgui.SetCursorPos(V2(14, 74))
  imgui.BeginChild('##fxbody', V2(bodyW, bodyH), false, imgui.WindowFlags.NoBackground)
  local dl = imgui.GetWindowDrawList()
  local p = imgui.GetWindowPos()
  local sy = imgui.GetScrollY()
  local oy = p.y - sy
  local ac = accent()
  local cw = bodyW - 14

  local fs = pushFont('small')
  T(dl, p.x + 6, oy + 2, U32(C.sub), 'Preset Karakter Suara  (Putar Scroll Mouse pada slider untuk presisi ±1, Klik Kanan untuk reset)')
  popFont(fs)

  local gap = 8
  local pw = math.floor((cw - 6 - gap * 3) / 4)
  local ph = 46
  for i, pr in ipairs(FX_PRESETS) do
    local col = (i - 1) % 4
    local row = math.floor((i - 1) / 4)
    local x = 6 + col * (pw + gap)
    local y = 22 + row * (ph + gap)
    imgui.SetCursorPos(V2(x, y))
    imgui.InvisibleButton('##fxp' .. i, V2(pw, ph))
    local hov = imgui.IsItemHovered()
    local sel = (cfg.main.fxPreset == i)
    local a = imgui.GetItemRectMin()
    local b = V2(a.x + pw, a.y + ph)
    ui.drawMatteCard(dl, a.x, a.y, b.x, b.y, UI_R.CTRL, hov, sel, ac)
    local fb = pushFont('bold')
    T(dl, a.x + 12, a.y + 5, U32(sel and ac or C.text), ellipsize(pr.name, pw - 20, 'fxn'))
    popFont(fb)
    local fs2 = pushFont('small')
    T(dl, a.x + 12, a.y + 25, U32(C.sub, sel and 0.95 or 0.80), ellipsize(pr.tag or pr.desc, pw - 20, 'fxd'))
    popFont(fs2)
    if imgui.IsItemClicked() then selectFxPreset(i) end
  end

  local boxY = 128
  local halfW = math.floor((cw - 6 - 10) / 2)
  local boxH = 212

  -- Left Rack: 3-Band Parametric EQ
  local lx = 6
  ui.drawMatteCard(dl, p.x + lx, oy + boxY, p.x + lx + halfW, oy + boxY + boxH, UI_R.CARD, false, false, ac)
  local fb = pushFont('bold')
  T(dl, p.x + lx + 16, oy + boxY + 10, U32(C.text), ellipsize('Parametric Equalizer (3-Band)', halfW - 104, 'eqh'))
  popFont(fb)
  local fsBtn = pushFont('small')
  if ui.pill('##fx_eq_flat', 'Flat 0dB', lx + halfW - 82, boxY + 8, 70, 24, false) then
    cfg.main.eqBass, cfg.main.eqMid, cfg.main.eqTreble = 0, 0, 0
    cfg.main.fxPreset = 8; cfgDirty = true; applyAudioFX()
  end
  popFont(fsBtn)
  dl:AddLine(V2(p.x + lx + 14, oy + boxY + 38), V2(p.x + lx + halfW - 14, oy + boxY + 38), U32(C.white, 0.06), 1)

  local bands = {
    { key = 'eqBass',   label = 'Sub & Bass (85 Hz)',    y = boxY + 48 },
    { key = 'eqMid',    label = 'Vocal & Mid (1 kHz)',   y = boxY + 104 },
    { key = 'eqTreble', label = 'Air & Treble (10 kHz)', y = boxY + 160 }
  }
  local slW = halfW - 32
  local fsb = pushFont('small')
  for idx, bd in ipairs(bands) do
    local val = clamp(cfg.main[bd.key] or 0, -12, 12)
    local vtxt = string.format('%+d dB', math.floor(val + 0.5))
    local vsz = imgui.CalcTextSize(vtxt)
    T(dl, p.x + lx + 16, oy + bd.y, U32(C.sub), ellipsize(bd.label, slW - vsz.x - 10, 'eqb' .. idx))
    T(dl, p.x + lx + 16 + slW - vsz.x, oy + bd.y, U32(val ~= 0 and ac or C.sub), vtxt)
    local ch, nf = ui.slider('##eqs' .. idx, lx + 16, bd.y + 20, slW, (val + 12) / 24, false, nil, true, 1 / 24)
    if ch then
      local nv = math.floor((nf * 24 - 12) + 0.5)
      if math.abs(nv) <= 0 then nv = 0 end
      cfg.main[bd.key] = nv
      cfg.main.fxPreset = 8
      cfgDirty = true
      applyAudioFX()
    end
  end
  popFont(fsb)

  -- Right Rack: Speed/Pitch, Reverb, Stereo Pan
  local rx = lx + halfW + 10
  ui.drawMatteCard(dl, p.x + rx, oy + boxY, p.x + rx + halfW, oy + boxY + boxH, UI_R.CARD, false, false, ac)
  local fb2 = pushFont('bold')
  T(dl, p.x + rx + 16, oy + boxY + 10, U32(C.text), ellipsize('Time, Space & Stereo', halfW - 110, 'sth'))
  popFont(fb2)
  local fsBtn2 = pushFont('small')
  if ui.pill('##fx_st_rst', 'Reset Stage', rx + halfW - 92, boxY + 8, 80, 24, false) then
    cfg.main.speed, cfg.main.reverb, cfg.main.pan = 100, 0, 0
    cfg.main.fxPreset = 8; cfgDirty = true; applyAudioFX()
  end
  popFont(fsBtn2)
  dl:AddLine(V2(p.x + rx + 14, oy + boxY + 38), V2(p.x + rx + halfW - 14, oy + boxY + 38), U32(C.white, 0.06), 1)

  local fs3 = pushFont('small')
  local spd = clamp(cfg.main.speed or 100, 50, 150)
  local spdTxt = string.format('%d%%', spd)
  local spsz = imgui.CalcTextSize(spdTxt)
  T(dl, p.x + rx + 16, oy + boxY + 48, U32(C.sub), ellipsize('Kecepatan & Pitch (50%-150%)', slW - spsz.x - 10, 'fxs1'))
  T(dl, p.x + rx + 16 + slW - spsz.x, oy + boxY + 48, U32(spd ~= 100 and C.gold or C.sub), spdTxt)
  local chS, nfS = ui.slider('##fx_spd', rx + 16, boxY + 68, slW, (spd - 50) / 100, S.live, nil, true, 0.01)
  if chS then
    local nspd = math.floor(50 + nfS * 100 + 0.5)
    if math.abs(nspd - 100) <= 1 then nspd = 100 end
    cfg.main.speed = nspd
    cfg.main.fxPreset = 8; cfgDirty = true; applyAudioFX()
  end

  local rev = clamp(cfg.main.reverb or 0, 0, 100)
  local revTxt = string.format('%d%%', rev)
  local rvsz = imgui.CalcTextSize(revTxt)
  T(dl, p.x + rx + 16, oy + boxY + 104, U32(C.sub), ellipsize('Gema Ruangan (DX8 Reverb Mix)', slW - rvsz.x - 10, 'fxs2'))
  T(dl, p.x + rx + 16 + slW - rvsz.x, oy + boxY + 104, U32(rev > 0 and ac or C.sub), revTxt)
  local chR, nfR = ui.slider('##fx_rev', rx + 16, boxY + 124, slW, rev / 100, false, nil, false, 0.02)
  if chR then
    cfg.main.reverb = math.floor(nfR * 100 + 0.5)
    cfg.main.fxPreset = 8; cfgDirty = true; applyAudioFX()
  end

  local pan = clamp(cfg.main.pan or 0, -100, 100)
  local panTxt = (pan == 0) and 'Center' or (pan < 0 and ('L ' .. (-pan) .. '%') or ('R ' .. pan .. '%'))
  local pnsz = imgui.CalcTextSize(panTxt)
  T(dl, p.x + rx + 16, oy + boxY + 160, U32(C.sub), ellipsize('Stereo Panning (Kiri / Kanan)', slW - pnsz.x - 10, 'fxs3'))
  T(dl, p.x + rx + 16 + slW - pnsz.x, oy + boxY + 160, U32(pan ~= 0 and ac or C.sub), panTxt)
  local chP, nfP = ui.slider('##fx_pan', rx + 16, boxY + 180, slW, (pan + 100) / 200, false, nil, true, 0.025)
  if chP then
    cfg.main.pan = math.floor(nfP * 200 - 100 + 0.5)
    if math.abs(cfg.main.pan) <= 3 then cfg.main.pan = 0 end
    cfgDirty = true; applyAudioFX()
  end
  popFont(fs3)

  -- Row 3: Free Custom FX Memory Slots (Slot Custom A & B)
  local memY = boxY + boxH + 10
  local memH = 54
  ui.drawMatteCard(dl, p.x + lx, oy + memY, p.x + lx + halfW, oy + memY + memH, UI_R.CARD, false, false, ac)
  T(dl, p.x + lx + 16, oy + memY + 7, U32(C.text), 'Memori Custom A')
  local fsm = pushFont('small')
  T(dl, p.x + lx + 16, oy + memY + 29, U32(C.sub),
    string.format('EQ %+d/%+d/%+d · %d%% · Rev %d%%', cfg.main.c1Bass or 0, cfg.main.c1Mid or 0, cfg.main.c1Treble or 0, cfg.main.c1Speed or 100, cfg.main.c1Reverb or 0))
  if ui.pill('##c1_load', 'Muat A', lx + halfW - 146, memY + 13, 64, 28, true) then loadCustomFxSlot(1) end
  if ui.pill('##c1_save', 'Simpan', lx + halfW - 76, memY + 13, 64, 28, false) then saveCustomFxSlot(1) end

  ui.drawMatteCard(dl, p.x + rx, oy + memY, p.x + rx + halfW, oy + memY + memH, UI_R.CARD, false, false, ac)
  popFont(fsm)
  T(dl, p.x + rx + 16, oy + memY + 7, U32(C.text), 'Memori Custom B')
  local fsm2 = pushFont('small')
  T(dl, p.x + rx + 16, oy + memY + 29, U32(C.sub),
    string.format('EQ %+d/%+d/%+d · %d%% · Rev %d%%', cfg.main.c2Bass or 0, cfg.main.c2Mid or 0, cfg.main.c2Treble or 0, cfg.main.c2Speed or 100, cfg.main.c2Reverb or 0))
  if ui.pill('##c2_load', 'Muat B', rx + halfW - 146, memY + 13, 64, 28, true) then loadCustomFxSlot(2) end
  if ui.pill('##c2_save', 'Simpan', rx + halfW - 76, memY + 13, 64, 28, false) then saveCustomFxSlot(2) end
  popFont(fsm2)

  -- Row 4: In-Car Stereo Boost & Smooth Fade
  local botY = memY + memH + 10
  local botH = 54
  ui.drawMatteCard(dl, p.x + lx, oy + botY, p.x + lx + halfW, oy + botY + botH, UI_R.CARD, false, false, ac)
  T(dl, p.x + lx + 16, oy + botY + 7, U32(C.text), ellipsize('In-Car Stereo Boost', halfW - 140, 'ic1'))
  local fs4 = pushFont('small')
  T(dl, p.x + lx + 16, oy + botY + 29, U32(C.sub), ellipsize('Naikkan volume saat di kendaraan GTA', halfW - 140, 'ic2'))
  if ui.pill('##fx_cboost', '+' .. tostring(cfg.main.carBoost or 20) .. '%', lx + halfW - 118, botY + 14, 54, 26, false) then
    local bOpts = { 10, 20, 30, 40 }
    local curB = cfg.main.carBoost or 20
    local nxtB = 20
    for idx, v in ipairs(bOpts) do
      if v == curB then nxtB = bOpts[(idx % #bOpts) + 1]; break end
    end
    cfg.main.carBoost = nxtB; cfgDirty = true
  end
  popFont(fs4)
  if ui.toggle('##tg_car', lx + halfW - 56, botY + 16, cfg.main.carDuck) then
    cfg.main.carDuck = not cfg.main.carDuck; cfgDirty = true
    flash('In-Car Stereo Mode: ' .. (cfg.main.carDuck and 'AKTIF' or 'MATI'))
  end

  ui.drawMatteCard(dl, p.x + rx, oy + botY, p.x + rx + halfW, oy + botY + botH, UI_R.CARD, false, false, ac)
  T(dl, p.x + rx + 16, oy + botY + 7, U32(C.text), ellipsize('Smooth Fade Transition', halfW - 80, 'sf1'))
  local fs5 = pushFont('small')
  T(dl, p.x + rx + 16, oy + botY + 29, U32(C.sub), ellipsize('Transisi volume halus saat putar & jeda', halfW - 80, 'sf2'))
  popFont(fs5)
  if ui.toggle('##tg_sfade', rx + halfW - 56, botY + 16, cfg.main.smoothFade) then
    cfg.main.smoothFade = not cfg.main.smoothFade; cfgDirty = true
    flash('Smooth Fade: ' .. (cfg.main.smoothFade and 'AKTIF' or 'MATI'))
  end

  imgui.SetCursorPos(V2(0, botY + botH + 10))
  imgui.Dummy(V2(1, 1))
  imgui.EndChild()
end

-- ======================================================================
-- ZENITH v3.5 WORKSPACE TABS (LIBRARY, RADIO, SETTINGS, EXPLORE, PLAYLISTS)
-- ======================================================================
ui.drawLibrary = function(w, h)
  local view = ui.getLibView()
  local bridgeBadge = YT.online and ('Bridge ONLINE · ' .. #lib .. ' Lagu') or 'Bridge Standby'
  local sub
  if YT.searching then
    sub = 'Sedang mencari "' .. (YT.searchQuery or '') .. '" di YouTube Music...'
  elseif S.loading then
    local el = math.max(0, os.clock() - (S.loadAt or os.clock()))
    sub = string.format('Memuat audio (%.1fs) · %s', el, S.loadStatus ~= '' and S.loadStatus or 'Menghubungkan ke YouTube Music...')
  elseif YT.showSearchOnly and #YT.searchResults > 0 then
    sub = string.format('Menampilkan %d hasil pencarian YouTube Music untuk "%s"  ·  Klik lagu untuk langsung memutar', #view, YT.searchQuery or '')
  else
    sub = #view .. ' ditampilkan dari ' .. #lib .. ' lagu di katalog  ·  Ketik judul lagu di bawah untuk mencari di YouTube Music'
  end
  ui.header('Pencarian & Katalog YouTube Music', sub, bridgeBadge)

  -- Baris 1: Kotak Pencarian Langsung YouTube Music + Tombol Cari YT & Populer YT
  local sy = 76
  local btnAreaW = 204
  local inputW = math.max(180, w - 44 - btnAreaW)
  local searchMode = YT.searchFilterVideos and 'videos' or 'search'
  if ui.styledInput('##yt_lib_search', 'Ketik judul lagu, penyanyi, atau tempel link YouTube Music...', ui.search, 22, sy, inputW) then
    ui.searchStr = ffi.string(ui.search):lower()
    local rawQ = trim(ffi.string(ui.search))
    if #rawQ >= 2 then
      YT.pendingQuery = rawQ
      YT.autoSearchAt = os.clock() + 0.65
      YT.pendingSugg = rawQ
      YT.autoSuggAt = os.clock() + 0.25
    else
      YT.autoSearchAt = 0
      YT.pendingQuery = ''
      YT.autoSuggAt = 0
      YT.pendingSugg = ''
      YT.suggestions = {}
      YT.showSearchOnly = false
    end
  end
  if imgui.IsItemFocused() and wasKeyPressed(13) then
    YT.autoSearchAt = 0
    YT.pendingQuery = ''
    YT.requestSearch(ffi.string(ui.search), searchMode, 20)
  end

  local bx = 22 + inputW + 8
  if ui.pill('##yt_btn_search', YT.searching and 'Mencari...' or 'Cari di YT', bx, sy, 96, 36, true) then
    YT.autoSearchAt = 0
    YT.pendingQuery = ''
    YT.requestSearch(ffi.string(ui.search), searchMode, 20)
  end
  if ui.pill('##yt_btn_disc', 'Populer YT', bx + 102, sy, 94, 36, false) then
    YT.showSearchOnly = false
    YT.requestSearch('', 'discover', 25)
  end

  -- Baris 2: Filter & Urutan Koleksi (Responsif, anti-tabrakan saat Drawer Kanan terbuka)
  local fy = 120
  local sq = trim(ffi.string(ui.search))
  local hasSaveBtn = (sq ~= '' and #view > 0 and w >= 720)
  local maxRight = hasSaveBtn and (w - 168) or (w - 22)
  local fx = 22

  local sorts = { 'Urut: Relevansi', 'Judul A-Z', 'Artis A-Z', 'Terbaru' }
  if ui.pill('##lib_sort', sorts[ui.libSort] or sorts[1], fx, fy, 112, 28, ui.libSort > 1) then
    ui.libSort = (ui.libSort % #sorts) + 1
  end
  fx = fx + 118

  if fx + 82 <= maxRight then
    if ui.pill('##lib_fav', 'Favorit', fx, fy, 82, 28, ui.libFilterFav, nil, 'heart') then
      ui.libFilterFav = not ui.libFilterFav
    end
    fx = fx + 88
  end

  if fx + 86 <= maxRight then
    if ui.pill('##lib_lrc', 'Ada LRC', fx, fy, 86, 28, ui.libFilterLrc, nil, 'mic') then
      ui.libFilterLrc = not ui.libFilterLrc
    end
    fx = fx + 92
  end

  local vf = ui.libFilterVibe or 0
  local vfLabel = (vf == 0) and 'Vibe: Semua' or ('Vibe: ' .. SMART.VIBES[vf].short)
  if fx + 112 <= maxRight then
    if ui.pill('##lib_vibe', vfLabel, fx, fy, 112, 28, vf > 0) then
      ui.libFilterVibe = (vf + 1) % (#SMART.VIBES + 1)
    end
    fx = fx + 118
  end

  if fx + 116 <= maxRight then
    if ui.pill('##lib_yttype', YT.searchFilterVideos and 'Tipe: Video/Remix' or 'Tipe: Lagu YT', fx, fy, 116, 28, YT.searchFilterVideos) then
      YT.searchFilterVideos = not YT.searchFilterVideos
      if sq ~= '' then
        YT.requestSearch(sq, YT.searchFilterVideos and 'videos' or 'search', 20)
      else
        flash('Filter Pencarian YT: ' .. (YT.searchFilterVideos and 'Video / Live / Remix' or 'Lagu Resmi (Songs)'))
      end
    end
    fx = fx + 122
  end

  if #YT.searchResults > 0 and fx + 118 <= maxRight then
    if ui.pill('##lib_ytmode', YT.showSearchOnly and ('Hasil Cari (' .. #YT.searchResults .. ')') or 'Semua Katalog', fx, fy, 118, 28, YT.showSearchOnly) then
      YT.showSearchOnly = not YT.showSearchOnly
    end
  end

  if hasSaveBtn then
    if ui.pill('##savepl', '+ Simpan Playlist', w - 160, fy, 138, 28, false) then
      local pl = createPlaylist(sq)
      if pl then
        local added = 0
        for _, idx in ipairs(view) do
          if addToPlaylist(pl, lib[idx], true) then added = added + 1 end
        end
        savePlaylists()
        flash('Playlist "' .. pl.name .. '" dibuat (' .. added .. ' lagu)')
      end
    end
  end

  -- Baris 2.5 (Opsional): Saran Pencarian Pintar (YouTube Music Live Autocomplete Chips)
  local listTop = 156
  if sq ~= '' and #YT.suggestions > 0 then
    local sxChip = 22
    local syChip = 153
    local p = imgui.GetWindowPos()
    local dl = imgui.GetWindowDrawList()
    local fsSugg = pushFont('small')
    T(dl, p.x + sxChip, p.y + syChip + 4, U32(C.sub), 'Saran:')
    sxChip = sxChip + 48
    for i = 1, math.min(6, #YT.suggestions) do
      local sTxt = YT.suggestions[i]
      local cw = math.min(176, math.max(64, imgui.CalcTextSize(sTxt).x + 22))
      if sxChip + cw > w - 24 then break end
      if ui.pill('##sugg_' .. i, ellipsize(sTxt, cw - 14, 'sg' .. i), sxChip, syChip, cw, 24, false) then
        ffi.fill(ui.search, ffi.sizeof(ui.search))
        ffi.copy(ui.search, sTxt, math.min(#sTxt, ffi.sizeof(ui.search) - 1))
        ui.searchStr = sTxt:lower()
        YT.autoSearchAt = 0
        YT.pendingQuery = ''
        YT.requestSearch(sTxt, YT.searchFilterVideos and 'videos' or 'search', 20)
      end
      sxChip = sxChip + cw + 6
    end
    popFont(fsSugg)
    listTop = 184
  end

  if #lib == 0 and not YT.searching then
    ui.emptyState(w, h, 'Belum Ada Lagu di Katalog Streaming',
      'Ketik judul lagu di kotak atas lalu klik "Cari di YT", atau klik tombol di bawah', true)
  elseif #view == 0 then
    ui.emptyState(w, h, YT.searching and 'Sedang Mencari di YouTube Music...' or 'Tidak Ada Lagu yang Cocok',
      'Tekan Enter atau klik tombol "Cari di YT" untuk mencari lagu baru di YouTube Music', false)
  else
    imgui.SetCursorPos(V2(14, listTop))
    ui.drawList('lib', lib, view, w - 28, math.max(80, h - listTop - 10), { add = true })
  end
end

ui.drawStations = function(w, h)
  ui.header('Live Radio & Stream', #stations .. ' stasiun radio internet & stream URL tersimpan', #stations .. ' Stations')
  ui.styledInput('##stname', 'Nama Stasiun', ui.stName, 22, 80, 160)
  ui.styledInput('##sturl', 'Tempel URL Stream Radio / MP3 (http://...)', ui.stUrl, 190, 80, w - 190 - 22 - 186)
  local url = trim(ffi.string(ui.stUrl))
  if ui.pill('##stplay', 'Putar', w - 22 - 176, 80, 84, 36, true) and url ~= '' then
    S.skipOnErr = false
    playUrl(trim(ffi.string(ui.stName)), url)
  end
  if ui.pill('##stsave', 'Simpan', w - 22 - 84, 80, 84, 36, false) and url ~= '' then
    local nm = fixText(ffi.string(ui.stName))
    stations[#stations + 1] = { name = (nm ~= '' and nm or url), url = url }
    saveStations()
    flash('Stasiun "' .. (nm ~= '' and nm or url) .. '" disimpan')
    ffi.fill(ui.stUrl, ffi.sizeof(ui.stUrl)); ffi.fill(ui.stName, ffi.sizeof(ui.stName))
  end
  if #stations == 0 then
    ui.emptyState(w, h + 110, 'Belum Ada Stasiun Radio', 'Tempel link stream radio di atas lalu klik Simpan', false)
  else
    imgui.SetCursorPos(V2(14, 128))
    ui.drawList('stations', stations, ui.getStView(), w - 28, h - 140, {
      del = function(idx, st)
        table.remove(stations, idx)
        if S.listName == 'stations' then
          if S.index == idx then S.index = 0 elseif S.index > idx then S.index = S.index - 1 end
        end
        saveStations()
        flash('Stasiun dihapus', false, st and st.name or '')
      end
    })
  end
end

ui.settingRow = function(y, w, title, desc, rightReserved)
  local p = imgui.GetWindowPos()
  local sy = imgui.GetScrollY()
  local dl = imgui.GetWindowDrawList()
  local maxTextW = math.max(160, w - 64 - (rightReserved or 200))
  ui.drawMatteCard(dl, p.x + 20, p.y + y - sy, p.x + w - 20, p.y + y - sy + 54, UI_R.CTRL, false, false)
  T(dl, p.x + 34, p.y + y - sy + 7, U32(C.text), ellipsize(title, maxTextW, 'srt'))
  local fs = pushFont('small')
  T(dl, p.x + 34, p.y + y - sy + 29, U32(C.sub), ellipsize(desc, maxTextW, 'srd'))
  popFont(fs)
end

ui.vkName = function(k)
  if not k or k <= 0 then return 'Kosong' end
  if XT.vkn[k] then return XT.vkn[k] end
  if k >= 112 and k <= 123 then return 'F' .. (k - 111) end
  if k >= 96 and k <= 105 then return 'Num' .. (k - 96) end
  if (k >= 48 and k <= 57) or (k >= 65 and k <= 90) then return string.char(k) end
  return 'Key' .. k
end

ui.bindPill = function(id, label, key, x, y, bw)
  bw = bw or 132
  local active = (ui.bind == key)
  local txt = active and 'Tekan tombol...' or (label .. ': ' .. ui.vkName(cfg.main[key]))
  if ui.pill(id, txt, x, y, bw, 34, active) then
    if active then ui.bind = nil else ui.bind = key end
  end
end

-- [R-01 / R-06] Clean Section Header without decorative colored left stripe or screaming all-caps
ui.settingSection = function(y, w, title)
  local p = imgui.GetWindowPos()
  local sy = imgui.GetScrollY()
  local dl = imgui.GetWindowDrawList()
  local fb = pushFont('bold')
  T(dl, p.x + 22, p.y + y - sy + 4, U32(C.text), title)
  popFont(fb)
  return y + 28
end

ui.drawSettings = function(w, h)
  ui.header('Settings & Kontrol Bebas', 'Kustomisasi Jendela Bebas, Glassmorphism, HUD Interaktif, Smart Shuffle, Audio & Hotkey')
  imgui.SetCursorPos(V2(0, 74))
  imgui.BeginChild('##setscroll', V2(w, h - 76), false, imgui.WindowFlags.NoBackground)
  local y = 6
  local rx = w - 20 - 16

  -- ====================================================================
  -- BAGIAN 0: KONTROL BEBAS JENDELA, GLASSMORPHISM & INTERAKSI HUD
  -- ====================================================================
  y = ui.settingSection(y, w, 'Kontrol Bebas Jendela & Glassmorphism')

  -- Ukuran Jendela & Preset Dimensi Bebas
  local curWinLabel = string.format('%dx%d', cfg.main.winW or 1080, cfg.main.winH or 680)
  ui.settingRow(y, w, 'Dimensi Jendela Utama (' .. curWinLabel .. ') & Mode Compact',
    'Tarik sudut kanan-bawah jendela untuk ubah ukuran bebas, atau pilih preset di kanan', 340)
  if ui.pill('##win_comp', cfg.main.compact and 'Mode: Compact' or 'Mode: Penuh', rx - 116, y + 10, 116, 34, cfg.main.compact) then
    cfg.main.compact = not cfg.main.compact; cfgDirty = true
  end
  if ui.pill('##win_preset', 'Preset Ukuran', rx - 116 - 8 - 112, y + 10, 112, 34, false) then
    local presets = { { 900, 560, 'Ringkas' }, { 1080, 680, 'Standar' }, { 1240, 740, 'Ultrawide' } }
    local curW = cfg.main.winW or 1080
    local pick = presets[2]
    for i, pr in ipairs(presets) do
      if math.abs(curW - pr[1]) < 40 then pick = presets[(i % #presets) + 1]; break end
    end
    cfg.main.winW, cfg.main.winH = pick[1], pick[2]
    cfg.main.winX, cfg.main.winY = -1, -1
    cfgDirty = true
    flash('Ukuran Jendela: ' .. pick[3] .. ' (' .. pick[1] .. 'x' .. pick[2] .. ')')
  end
  if ui.pill('##win_center', 'Tengah', rx - 116 - 8 - 112 - 8 - 76, y + 10, 76, 34, false) then
    cfg.main.winX, cfg.main.winY = -1, -1
    cfg.main.compactX, cfg.main.compactY = -1, -1
    cfgDirty = true
    flash('Posisi jendela direset ke tengah layar')
  end
  y = y + 60

  -- Transparansi Kaca Utama (Glassmorphism Frost Opacity)
  ui.settingRow(y, w, 'Tingkat Keburaman Kaca Utama (Glass Frost Opacity)',
    'Atur ketembusan pandang latar kaca jendela utama & Compact Deck (55% - 98%)', 265)
  local glx, gly, glw = rx - 246, y + 19, 168
  local gch, gnf = ui.slider('##glassalpha', glx, gly, glw, ((cfg.main.glassAlpha or 88) - 55) / 43, false, nil, false, 0.04)
  if gch then cfg.main.glassAlpha = math.floor(55 + gnf * 43 + 0.5); cfgDirty = true end
  local fsgl = pushFont('small')
  T(imgui.GetWindowDrawList(), imgui.GetWindowPos().x + rx - 64, imgui.GetWindowPos().y + y + 19 - imgui.GetScrollY(), U32(C.text), tostring(cfg.main.glassAlpha or 88) .. '%')
  popFont(fsgl)
  y = y + 60

  -- Mini HUD Kontrol Interaktif Langsung
  ui.settingRow(y, w, 'Kontrol Interaktif Langsung pada Mini Player HUD',
    'Saat kursor aktif (mis. tekan T/Tab), arahkan mouse ke Mini HUD untuk klik Play/Next/Seek & Scroll Volume', 90)
  if ui.toggle('##tg_mini_int', rx - 44, y + 16, cfg.main.miniInteractive) then
    cfg.main.miniInteractive = not cfg.main.miniInteractive
    cfgDirty = true
    flash('Mini HUD Interaktif: ' .. (cfg.main.miniInteractive and 'AKTIF' or 'MATI'))
  end
  y = y + 60

  -- Gaya Gambar Player Bawah & Studio (Cover Art Langsung vs Piringan Hitam / Vinyl)
  local artStyleIdx = clamp(math.floor(cfg.main.playerArtStyle or 1), 1, #PLAYER_ART_STYLES)
  ui.settingRow(y, w, 'Gaya Gambar Player Bawah & Beranda (Cover Art / Vinyl)',
    'Pilih tampilan gambar sampul lagu ala YouTube Music langsung atau piringan hitam (bisa klik kanan cover di bawah)', 210)
  if ui.pill('##btn_player_art', PLAYER_ART_STYLES[artStyleIdx], rx - 196, y + 10, 196, 34, artStyleIdx == 1) then
    cfg.main.playerArtStyle = (artStyleIdx % #PLAYER_ART_STYLES) + 1
    cfgDirty = true
    flash('Gaya Gambar Player: ' .. PLAYER_ART_STYLES[cfg.main.playerArtStyle])
  end
  y = y + 66

  -- ====================================================================
  -- BAGIAN 1: SMART SHUFFLE & AUTO MIX PINTAR
  -- ====================================================================
  y = ui.settingSection(y, w, 'Smart Shuffle & Auto Mix Pintar')

  ui.settingRow(y, w, 'Smart Shuffle Pintar (Anti-Tabrakan Genre & Mood)',
    'Cegah perpindahan drastis seperti lagu Sad/Galau tiba-tiba lompat ke Dangdut/DJ', 210)
  if ui.toggle('##tg_smartshuf', rx - 44, y + 16, cfg.main.smartShuffle) then
    cfg.main.smartShuffle = not cfg.main.smartShuffle
    S.smartBag = nil
    cfgDirty = true
    flash('Smart Shuffle Pintar: ' .. (cfg.main.smartShuffle and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##btn_testsmart', 'Acak Pintar', rx - 44 - 10 - 114, y + 10, 114, 34, false) then
    if #lib > 0 then
      local c = {}
      for i, t in ipairs(lib) do c[i] = t end
      cfg.main.smartShuffle = true
      cfg.main.shuffle = true
      cfgDirty = true
      SMART.shuffleList(c, S.cur)
      playQueue(c, 'Smart Shuffle Semua', 1)
      flash('Antrean Smart Shuffle dimulai (' .. #c .. ' lagu)')
    else
      flash('Library masih kosong', true)
    end
  end
  y = y + 60

  ui.settingRow(y, w, 'Proteksi Ketat Anti-Lompat Genre (Strict Mood Guard)',
    'Blokir penuh lagu yang bertolak belakang (Sad <-> Dangdut / Jedag-Jedug / Metal)', 90)
  if ui.toggle('##tg_smartclash', rx - 44, y + 16, cfg.main.smartAvoidClash) then
    cfg.main.smartAvoidClash = not cfg.main.smartAvoidClash
    S.smartBag = nil
    cfgDirty = true
    flash('Strict Mood Guard: ' .. (cfg.main.smartAvoidClash and 'AKTIF' or 'MATI'))
  end
  y = y + 60

  local mixCnt = cfg.main.autoMixCount or 30
  local mixCntLabel = (mixCnt <= 0) and 'Isi: Semua' or ('Isi: ' .. mixCnt .. ' Lagu')
  ui.settingRow(y, w, 'Auto Mix & Radio Pintar Saat Pilih Lagu',
    'Otomatis lanjutkan pemutaran dengan lagu se-vibe dari YouTube Music saat antrean habis', 210)
  if ui.toggle('##tg_automix', rx - 44, y + 16, cfg.main.autoMix) then
    cfg.main.autoMix = not cfg.main.autoMix
    cfgDirty = true
    flash('Auto Smart Mix: ' .. (cfg.main.autoMix and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##btn_amixcnt', mixCntLabel, rx - 44 - 10 - 118, y + 10, 118, 34, false) then
    local opts = { 15, 25, 30, 50, 0 }
    local nxt = 30
    for i, v in ipairs(opts) do
      if v == mixCnt then nxt = opts[(i % #opts) + 1]; break end
    end
    cfg.main.autoMixCount = nxt
    cfgDirty = true
    flash('Ukuran Auto Mix: ' .. (nxt == 0 and 'Semua Lagu Se-Vibe' or (nxt .. ' Lagu')))
  end
  y = y + 60

  ui.settingRow(y, w, 'Tampilkan Label Vibe / Genre di Daftar Lagu',
    'Tampilkan indikator mood otomatis (Sad/Galau, Dangdut, DJ/Remix, Pop) di Katalog & Player', 90)
  if ui.toggle('##tg_vibebadge', rx - 44, y + 16, cfg.main.showVibeBadge) then
    cfg.main.showVibeBadge = not cfg.main.showVibeBadge
    cfgDirty = true
    flash('Badge Vibe Lagu: ' .. (cfg.main.showVibeBadge and 'TAMPIL' or 'SEMBUNYI'))
  end
  y = y + 66

  -- ====================================================================
  -- BAGIAN 2: KONTROL PEMUTAR & AUDIO OTOMATIS
  -- ====================================================================
  y = ui.settingSection(y, w, 'Kontrol Pemutar & Audio Otomatis')

  ui.settingRow(y, w, 'Mode Shuffle (Acak Pemutaran Lagu)',
    'Acak lagu berikutnya secara otomatis (menggunakan Smart Shuffle bila diaktifkan)', 90)
  if ui.toggle('##tg_shuf_set', rx - 44, y + 16, cfg.main.shuffle) then
    cfg.main.shuffle = not cfg.main.shuffle
    cfgDirty = true
    flash('Mode Shuffle: ' .. (cfg.main.shuffle and 'ON' or 'OFF'))
  end
  y = y + 60

  local repMode = cfg.main.repeatMode or 0
  local repNames = { [0] = 'Mati (Off)', [1] = 'Semua Lagu', [2] = '1 Lagu Saja' }
  ui.settingRow(y, w, 'Repeat / Ulangi Lagu Otomatis',
    'Ulangi pemutaran saat antrean habis (Mode saat ini: ' .. (repNames[repMode] or 'Semua') .. ')', 210)
  if ui.toggle('##tg_rep_set', rx - 44, y + 16, repMode > 0) then
    cfg.main.repeatMode = (repMode > 0) and 0 or 1
    cfgDirty = true
    flash('Repeat Lagu: ' .. repNames[cfg.main.repeatMode])
  end
  if ui.pill('##btn_rep_mode', 'Mode: ' .. (repMode == 2 and '1 Lagu' or 'Semua'), rx - 44 - 10 - 118, y + 10, 118, 34, repMode == 2) then
    cfg.main.repeatMode = (repMode == 1) and 2 or 1
    cfgDirty = true
    flash('Repeat Mode: ' .. repNames[cfg.main.repeatMode])
  end
  y = y + 60

  ui.settingRow(y, w, 'Smooth Fade Transition (Transisi Volume Halus)',
    'Nyalakan efek fade-in volume lembut saat mulai memutar atau melanjutkan lagu', 90)
  if ui.toggle('##tg_fade_set', rx - 44, y + 16, cfg.main.smoothFade) then
    cfg.main.smoothFade = not cfg.main.smoothFade
    cfgDirty = true
    flash('Smooth Fade: ' .. (cfg.main.smoothFade and 'AKTIF' or 'MATI'))
  end
  y = y + 60

  ui.settingRow(y, w, 'In-Car Stereo Boost (Auto Volume Kendaraan)',
    'Otomatis naikkan volume musik saat karakter berada di dalam kendaraan GTA', 180)
  if ui.toggle('##tg_car_set', rx - 44, y + 16, cfg.main.carDuck) then
    cfg.main.carDuck = not cfg.main.carDuck
    cfgDirty = true
    flash('In-Car Stereo Boost: ' .. (cfg.main.carDuck and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##btn_car_pct', 'Boost +' .. tostring(cfg.main.carBoost or 20) .. '%', rx - 44 - 10 - 104, y + 10, 104, 34, false) then
    local bOpts = { 10, 20, 30, 40 }
    local curB = cfg.main.carBoost or 20
    local nxtB = 20
    for idx, v in ipairs(bOpts) do
      if v == curB then nxtB = bOpts[(idx % #bOpts) + 1]; break end
    end
    cfg.main.carBoost = nxtB
    cfgDirty = true
    flash('In-Car Boost diatur ke +' .. nxtB .. '%')
  end
  y = y + 60

  ui.settingRow(y, w, 'Auto-Resume Lagu Terakhir Saat Login',
    'Putar kembali lagu atau stasiun radio terakhir secara otomatis saat masuk ke dalam game', 90)
  if ui.toggle('##tg_resume_set', rx - 44, y + 16, cfg.main.autoResume) then
    cfg.main.autoResume = not cfg.main.autoResume
    cfgDirty = true
    flash('Auto-Resume: ' .. (cfg.main.autoResume and 'AKTIF' or 'MATI'))
  end
  y = y + 66

  -- ====================================================================
  -- BAGIAN 3: MINI PLAYER HUD, KARAOKE BEBAS & NOTIFIKASI
  -- ====================================================================
  y = ui.settingSection(y, w, 'HUD Layar, Karaoke Bebas & Notifikasi')

  local custom = (cfg.main.miniFX or -1) >= 0 and (cfg.main.miniFY or -1) >= 0
  local sname = MINI.SNAMES[cfg.main.miniScale] or MINI.SNAMES[2]
  local stName = MINI.STYLES[cfg.main.miniStyle or 1] or MINI.STYLES[1]
  ui.settingRow(y, w, 'Mini Player HUD: ' .. stName,
    'Posisi: ' .. (custom and 'Bebas (Custom)' or (MINI.POS[cfg.main.miniPos] or MINI.POS[1])) .. '  ·  Ukuran: ' .. sname, 360)
  if ui.toggle('##tg_mini', rx - 44, y + 16, cfg.main.mini) then
    cfg.main.mini = not cfg.main.mini
    cfgDirty = true
    flash('Mini Player HUD: ' .. (cfg.main.mini and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##ministyle', 'Gaya HUD', rx - 44 - 8 - 92, y + 10, 92, 34, false) then
    cfg.main.miniStyle = ((cfg.main.miniStyle or 1) % #MINI.STYLES) + 1
    cfgDirty = true
    flash('Gaya Mini Player: ' .. MINI.STYLES[cfg.main.miniStyle])
  end
  if ui.pill('##miniscale', 'Ukuran', rx - 44 - 8 - 92 - 8 - 72, y + 10, 72, 34, false) then
    cfg.main.miniScale = (cfg.main.miniScale % #MINI.SCALES) + 1; cfgDirty = true
  end
  if ui.pill('##minidrag', 'Atur Posisi HUD', rx - 44 - 8 - 92 - 8 - 72 - 8 - 114, y + 10, 114, 34, true) then
    cfg.main.mini = true; cfgDirty = true
    MINI.edit = true; window[0] = false
  end
  y = y + 60

  ui.settingRow(y, w, 'Auto-Hide Mini Player Saat Musik Pause',
    'Sembunyikan Mini Player HUD otomatis setelah musik dijeda selama 6 detik', 90)
  if ui.toggle('##tg_minihide', rx - 44, y + 16, cfg.main.miniHidePause) then
    cfg.main.miniHidePause = not cfg.main.miniHidePause
    cfgDirty = true
    flash('Auto-Hide Mini HUD: ' .. (cfg.main.miniHidePause and 'AKTIF' or 'MATI'))
  end
  y = y + 60

  ui.settingRow(y, w, 'Lirik Berjalan di Mini Player HUD',
    'Tampilkan baris lirik lagu yang sedang aktif di dalam kapsul Mini Player', 90)
  if ui.toggle('##tg_minilyr', rx - 44, y + 16, cfg.main.miniLyrics) then
    cfg.main.miniLyrics = not cfg.main.miniLyrics
    cfgDirty = true
    flash('Lirik Mini Player: ' .. (cfg.main.miniLyrics and 'AKTIF' or 'MATI'))
  end
  y = y + 60

  local kCustom = (cfg.main.karaokeFX or -1) >= 0 and (cfg.main.karaokeFY or -1) >= 0
  local kScaleName = MINI.KSNAMES[cfg.main.karaokeScale or 2] or 'Normal'
  ui.settingRow(y, w, 'Floating Karaoke Overlay (' .. kScaleName .. ')',
    'Posisi: ' .. (kCustom and 'Bebas (Seret di Mode Edit HUD)' or ((cfg.main.karaokePos == 2) and 'Atas' or 'Bawah')), 290)
  if ui.toggle('##tg_kar', rx - 44, y + 16, cfg.main.karaoke) then
    cfg.main.karaoke = not cfg.main.karaoke
    cfgDirty = true
    flash('Floating Karaoke HUD: ' .. (cfg.main.karaoke and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##kar_scale', 'Ukuran: ' .. kScaleName, rx - 44 - 8 - 106, y + 10, 106, 34, false) then
    cfg.main.karaokeScale = ((cfg.main.karaokeScale or 2) % #MINI.KSCALES) + 1; cfgDirty = true
  end
  if ui.pill('##kar_pos', (cfg.main.karaokePos == 2) and 'Preset: Atas' or 'Preset: Bawah', rx - 44 - 8 - 106 - 8 - 108, y + 10, 108, 34, false) then
    cfg.main.karaokePos = (cfg.main.karaokePos == 2) and 1 or 2
    cfg.main.karaokeFX, cfg.main.karaokeFY = -1, -1
    cfgDirty = true
  end
  y = y + 60

  ui.settingRow(y, w, 'Auto-Scroll Lirik Tersinkronisasi',
    'Gulir daftar lirik otomatis mengikuti ketukan waktu lagu di tab Lirik & Drawer', 90)
  if ui.toggle('##tg_lyrauto', rx - 44, y + 16, cfg.main.lyricAutoScroll) then
    cfg.main.lyricAutoScroll = not cfg.main.lyricAutoScroll
    ui.lyricAutoScroll = cfg.main.lyricAutoScroll
    cfgDirty = true
    flash('Auto-Scroll Lirik: ' .. (cfg.main.lyricAutoScroll and 'AKTIF' or 'MATI'))
  end
  y = y + 60

  local tposNames = { 'Tengah Atas', 'Kanan Atas', 'Kiri Atas', 'Kanan Bawah' }
  ui.settingRow(y, w, 'Notifikasi Glass Toast Pop-Up',
    'Kartu pop-up animasi saat ganti lagu & aksi penting', 200)
  if ui.toggle('##tg_toast', rx - 44, y + 16, cfg.main.toast) then
    cfg.main.toast = not cfg.main.toast
    cfgDirty = true
    flash('Notifikasi Toast: ' .. (cfg.main.toast and 'AKTIF' or 'MATI'))
  end
  if ui.pill('##toast_pos', tposNames[cfg.main.toastPos or 2] or 'Kanan Atas', rx - 44 - 10 - 126, y + 10, 126, 34, false) then
    cfg.main.toastPos = ((cfg.main.toastPos or 2) % #tposNames) + 1; cfgDirty = true
    flash('Posisi Toast: ' .. tposNames[cfg.main.toastPos])
  end
  y = y + 60

  ui.settingRow(y, w, 'Panel Inspektor Kanan (Antrean / Lirik / FX)',
    'Tampilkan panel samping kanan untuk mengatur urutan Antrean, Lirik Cepat & Preset FX', 90)
  if ui.toggle('##tg_drawer_set', rx - 44, y + 16, cfg.main.drawer) then
    cfg.main.drawer = not cfg.main.drawer
    cfgDirty = true
    flash('Panel Inspektor Kanan: ' .. (cfg.main.drawer and 'TAMPIL' or 'SEMBUNYI'))
  end
  y = y + 66

  -- ====================================================================
  -- BAGIAN 4: TEMA VISUAL, SLEEP TIMER & 9 HOTKEY BEBAS
  -- ====================================================================
  y = ui.settingSection(y, w, 'Tema Permukaan, Sleep Timer & Hotkey Bebas')

  local curSurf = SURFACES[clamp(cfg.main.surface or 1, 1, #SURFACES)] or SURFACES[1]
  ui.settingRow(y, w, 'Tema Permukaan Kaca: ' .. curSurf.name, 'Pilih 1 dari 5 permukaan dasar kaca studio', 190)
  if ui.pill('##surf_btn', 'Ganti: ' .. curSurf.name, rx - 176, y + 10, 176, 34, true) then
    cfg.main.surface = ((cfg.main.surface or 1) % #SURFACES) + 1
    syncSurface()
    cfgDirty = true
  end
  y = y + 60

  ui.settingRow(y, w, 'Warna Aksen Fokal: ' .. (accentNames[cfg.main.accent] or 'Ice Cyan'), 'Pilih 1 warna aksen terukur untuk elemen fokal aktif', 290)
  for i, c in ipairs(accents) do
    local cx = w - 38 - (#accents - i) * 26 - 8
    imgui.SetCursorPos(V2(cx - 12, y + 14))
    imgui.InvisibleButton('##ac' .. i, V2(24, 26))
    local a = imgui.GetItemRectMin()
    local dl = imgui.GetWindowDrawList()
    dl:AddCircleFilled(V2(a.x + 12, a.y + 13), 8.5, U32(c), 18)
    if cfg.main.accent == i then dl:AddCircle(V2(a.x + 12, a.y + 13), 11.5, U32(C.white), 20, 2) end
    if imgui.IsItemClicked() then cfg.main.accent = i; cfgDirty = true end
  end
  y = y + 60

  ui.settingRow(y, w, 'Transparansi Mini Player HUD', 'Atur seberapa tembus pandang HUD di layar game (25% - 100%)', 265)
  local slx, sly, slw = rx - 246, y + 19, 168
  local ch, nf = ui.slider('##miniopacity', slx, sly, slw, clamp((cfg.main.miniOpacity or 86) / 100, 0.25, 1), false, nil, false, 0.04)
  if ch then cfg.main.miniOpacity = math.floor(clamp(nf, 0.25, 1) * 100 + 0.5); cfgDirty = true end
  local fsop = pushFont('small')
  T(imgui.GetWindowDrawList(), imgui.GetWindowPos().x + rx - 64, imgui.GetWindowPos().y + y + 19 - imgui.GetScrollY(), U32(C.text), tostring(cfg.main.miniOpacity or 86) .. '%')
  popFont(fsop)
  y = y + 60

  local slLabel = 'Mati'
  local slDesc = 'Hentikan musik otomatis (volume mengecil halus di 15 detik terakhir)'
  if XT.sleepAt > 0 then
    local mins = math.max(1, math.ceil((XT.sleepAt - os.clock()) / 60))
    slLabel = mins .. ' Menit'
    slDesc = 'Musik akan berhenti otomatis dalam ' .. mins .. ' menit'
  end
  ui.settingRow(y, w, 'Sleep Timer Otomatis', slDesc, 130)
  if ui.pill('##sleep', slLabel, rx - 116, y + 10, 116, 34, XT.sleepAt > 0) then
    XT.sleepI = (XT.sleepI % #XT.sleepOpts) + 1
    local m = XT.sleepOpts[XT.sleepI]
    if m > 0 then
      XT.sleepAt = os.clock() + m * 60
      flash('Sleep Timer dipasang: ' .. m .. ' menit')
    else
      XT.sleepAt = 0; applyVolume(true)
      flash('Sleep Timer dimatikan')
    end
  end
  y = y + 60

  -- 9 Free Hotkeys across 3 clean rows
  ui.settingRow(y, w, 'Hotkey Menu, Mode Compact & Play/Pause', 'Klik tombol lalu tekan tombol keyboard (Backspace = hapus, Esc = batal)', 420)
  ui.bindPill('##bk_menu', 'Menu', 'key', rx - 130 * 3 - 16, y + 10, 130)
  ui.bindPill('##bk_comp', 'Compact', 'keyCompact', rx - 130 * 2 - 8, y + 10, 130)
  ui.bindPill('##bk_pause', 'Play/Pause', 'keyPause', rx - 130, y + 10, 130)
  y = y + 60

  ui.settingRow(y, w, 'Hotkey Navigasi Lagu & Favorit', 'Atur pintasan ganti lagu cepat & simpan ke Favorit saat berkendara', 420)
  ui.bindPill('##bk_prev', 'Prev', 'keyPrev', rx - 130 * 3 - 16, y + 10, 130)
  ui.bindPill('##bk_next', 'Next', 'keyNext', rx - 130 * 2 - 8, y + 10, 130)
  ui.bindPill('##bk_fav', 'Favorit', 'keyFav', rx - 130, y + 10, 130)
  y = y + 60

  ui.settingRow(y, w, 'Hotkey Volume Cepat & Karaoke HUD', 'Naik/turunkan volume ±5% atau nyalakan Karaoke langsung dari dalam game', 420)
  ui.bindPill('##bk_vup', 'Vol +5%', 'keyVolUp', rx - 130 * 3 - 16, y + 10, 130)
  ui.bindPill('##bk_vdn', 'Vol -5%', 'keyVolDn', rx - 130 * 2 - 8, y + 10, 130)
  ui.bindPill('##bk_kar', 'Karaoke', 'keyKaraoke', rx - 130, y + 10, 130)
  y = y + 60

  ui.settingRow(y, w, 'Koneksi Python YouTube Music Bridge (' .. (YT.online and 'ONLINE' or 'STANDBY') .. ')',
    'Streaming langsung via MoonRadioBridge (Port ' .. tostring(YT.port) .. ') tanpa file MP3 lokal', 220)
  if ui.pill('##openf2', 'Start Bridge', rx - 204, y + 10, 102, 34, not YT.online) then
    YT.tryLaunchPythonBridge(false)
  end
  if ui.pill('##rescan2', 'Muat Lagu YT', rx - 94, y + 10, 94, 34, true) then
    YT.requestSearch('', 'discover', 25)
  end
  y = y + 62

  local p = imgui.GetWindowPos()
  local sy = imgui.GetScrollY()
  local dl = imgui.GetWindowDrawList()
  local fs = pushFont('small')
  T(dl, p.x + 24, p.y + y - sy, U32(C.sub),
    'Command: /radio /rplay /ryt /rcari /rcompact /rglass /rnext /rprev /rpause /rvol /rmix /rall /rfav /rsmart /rautomix /rsleep /rmini /rminipos /rministyle /rlyrics /rkaraoke /rfx /rspeed')
  popFont(fs)
  imgui.SetCursorPos(V2(0, y + 32))
  imgui.Dummy(V2(1, 1))
  imgui.EndChild()
end

-- ---------- TAB 1: EXPLORE (FOCAL GLASS HERO DECK, MOOD LAUNCHERS, RECENT & CURATED CARDS) ----------
local CARD_W, CARD_H, CARD_GAP = 158, 212, 14
local recs = { key = '', mix = {}, pls = {}, seed = 0 }

recs.sample = function(src, n, seed)
  local c = {}
  for i = 1, #src do c[i] = src[i] end
  seededShuffle(c, seed)
  for i = #c, n + 1, -1 do c[i] = nil end
  return c
end

ui.buildRecs = function()
  local key = plVersion .. '/' .. libVersion .. '/' .. recs.seed
  if recs.key == key then return recs.mix, recs.pls end
  recs.key = key

  local sd = recs.seed
  local day = tonumber(os.date('%Y%m%d')) or 1
  local all = FP.all()
  local mix, pls, ne = {}, {}, {}
  for _, pl in ipairs(all) do
    if #plTracks(pl) > 0 then ne[#ne + 1] = pl end
  end

  local function card(title, sub, list, tint, label)
    if #list == 0 then return end
    mix[#mix + 1] = {
      title = title, sub = sub, art = list[1], tint = tint,
      onClick = function() playQueue(list, label or title, 1) end
    }
  end

  if #lib > 0 then
    mix[#mix + 1] = {
      title = cfg.main.smartShuffle and 'Smart Shuffle' or 'Acak Semua',
      sub = #lib .. ' lagu di Katalog', art = lib[(sd % #lib) + 1], tint = 1,
      onClick = function()
        local c = {}
        for i, t in ipairs(lib) do c[i] = t end
        SMART.shuffleList(c, S.cur)
        playQueue(c, cfg.main.smartShuffle and 'Smart Shuffle Semua' or 'Shuffle Semua', 1)
      end
    }
    local daily = recs.sample(lib, 30, day * 31 + 7)
    card('Mix Harian', #daily .. ' lagu pilihan hari ini', daily, 2)
    local rnd = recs.sample(lib, 25, sd * 977 + 3)
    card('Eksplorasi Katalog', #rnd .. ' lagu acak pilihan', rnd, 3)
  end

  if #lib > 1 then
    local nw = {}
    for i, t in ipairs(lib) do nw[i] = t end
    table.sort(nw, function(a, b) return (a.mtime or 0) > (b.mtime or 0) end)
    for i = #nw, 21, -1 do nw[i] = nil end
    card('Baru Ditambahkan', #nw .. ' lagu terbaru di katalog', nw, 4)
  end

  for i, pl in ipairs(all) do
    local tl = plTracks(pl)
    pls[#pls + 1] = {
      title = pl.name, sub = #tl .. ' lagu tersimpan',
      art = tl[1], tint = ((i - 1) % #accents) + 1,
      onClick = function() playMix({ pl }, false) end
    }
  end

  recs.mix, recs.pls = mix, pls
  return mix, pls
end

ui.drawHome = function(w, h)
  local sesMins = math.max(1, math.floor((os.clock() - XT.sesStart) / 60))
  local homeStatus = YT.homeLoading and 'Memuat rekomendasi terbaru dari YouTube Music...'
    or (string.format('%d lagu di Katalog  ·  %d diputar sesi ini (%d mnt)', #lib, XT.sesSongs, sesMins))
  ui.header('Beranda YouTube Music', homeStatus, nil, 232)
  if ui.pill('##ytrefresh', YT.homeLoading and 'Memuat...' or 'Segarkan YT', w - 236, 18, 106, 30, true) then
    local seedTr = S.cur or (#recentTracks > 0 and recentTracks[1]) or (#lib > 0 and lib[1]) or nil
    YT.requestHome(seedTr, false)
  end
  if ui.pill('##reroll', 'Acak Mix', w - 124, 18, 104, 30, false) then recs.seed = math.random(1, 999999) end
  local mix, pls = ui.buildRecs()

  imgui.SetCursorPos(V2(14, 74))
  imgui.BeginChild('##homegrid', V2(w - 28, h - 82), false, imgui.WindowFlags.NoBackground)
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  local cw = w - 38
  local cols = math.max(1, math.floor((cw + CARD_GAP) / (CARD_W + CARD_GAP)))

  -- [R-10] Focal Glass Hero Deck Banner
  imgui.SetCursorPos(V2(4, 2))
  imgui.Dummy(V2(cw, 124))
  local hp = imgui.GetItemRectMin()
  ui.drawGlassFocal(dl, hp.x, hp.y, hp.x + cw, hp.y + 124, UI_R.CARD, ac, nil, false)

  local ht, ha = nowInfo()
  local heroBtnX = math.max(260, cw - 134)
  local heroTextW = math.max(140, heroBtnX - 132)
  ui.drawPlayerArt(dl, hp.x + 60, hp.y + 62, 44, getArtTexture(S.cur), ui.vinylAngle, ac, false)
  local fsHero = pushFont('small')
  local fxBadge = (cfg.main.fxPreset and cfg.main.fxPreset > 1) and ('  ·  FX: ' .. FX_PRESETS[cfg.main.fxPreset].name) or ''
  if S.loading then
    ui.drawSpinner(dl, hp.x + 126, hp.y + 23, 5.5, U32(C.gold), 1.8)
    T(dl, hp.x + 138, hp.y + 15, U32(C.gold), 'Sedang Menyiapkan Stream YouTube Music...')
  elseif S.err and not S.playing then
    T(dl, hp.x + 120, hp.y + 15, U32(C.red), 'Gagal Memutar Stream' .. fxBadge)
  else
    local statusLabel = S.cur and (S.live and 'Live Broadcast' or (S.playing and 'Sedang Diputar' or 'Dijeda')) or 'Siap Streaming'
    T(dl, hp.x + 120, hp.y + 15, U32(S.playing and ac or C.sub), statusLabel .. fxBadge)
  end
  popFont(fsHero)
  local fbHero = pushFont('bold')
  T(dl, hp.x + 120, hp.y + 36, U32(C.text), ellipsize(ht, heroTextW, 'herot'))
  popFont(fbHero)
  local fsHero2 = pushFont('small')
  local haCol = S.loading and C.gold or ((not S.playing and S.err) and C.red or C.sub)
  T(dl, hp.x + 120, hp.y + 62, U32(haCol), ellipsize(ha, heroTextW, 'heroa'))
  local lyrNow = currentLyricText()
  ui.drawNote(dl, hp.x + 126, hp.y + 96, 12, U32(lyrNow and ac or C.sub, 0.9))
  T(dl, hp.x + 138, hp.y + 88, U32(lyrNow and C.text or C.sub, 0.9),
    ellipsize(lyrNow or 'Klik lagu atau playlist di bawah untuk langsung memutar dari YouTube Music', heroTextW - 18, 'herol'))
  popFont(fsHero2)

  if ui.pill('##heroPlay', S.loading and 'Batal' or (S.playing and 'Jeda' or 'Putar'), heroBtnX, 22, 118, 34, true) then togglePlay() end
  if ui.pill('##heroStage', 'Buka Player', heroBtnX, 66, 118, 34, false) then ui.tab = 2 end

  -- Quick Mood Launchers ([R-29] Unified single-accent highlight when active, matte when inactive)
  local y = 138
  local mW = math.floor((cw - 30) / 4)
  local moods = {
    { label = 'Bass Boost Mix',  icon = 'fx',   fx = 2, act = function() selectFxPreset(2, true); if #lib > 0 then local c = recs.sample(lib, 30, math.random(1, 99999)); SMART.shuffleList(c); playQueue(c, 'Bass Boost Mix', 1) end; flash('Mode Bass Boost Mix Diaktifkan') end },
    { label = 'Slowed + Reverb', icon = 'moon', fx = 5, act = function() selectFxPreset(5, true); if #lib > 0 then local c = recs.sample(lib, 30, math.random(1, 99999)); SMART.shuffleList(c); playQueue(c, 'Slowed Night Drive', 1) end; flash('Mode Slowed + Reverb Diaktifkan') end },
    { label = 'Nightcore Rush',  icon = 'bolt', fx = 4, act = function() selectFxPreset(4, true); if #lib > 0 then local c = recs.sample(lib, 30, math.random(1, 99999)); SMART.shuffleList(c); playQueue(c, 'Nightcore Rush', 1) end; flash('Mode Nightcore 1.18x Diaktifkan') end },
    { label = 'YT Radio Pintar', icon = 'dice', fx = nil, act = function()
      local seed = S.cur or (#recentTracks > 0 and recentTracks[1]) or (#lib > 0 and lib[math.random(#lib)])
      if seed and seed.videoId then
        YT.requestSearch(seed.videoId .. ';;' .. (seed.title or '') .. ' ' .. (seed.artist or ''), 'automix', cfg.main.autoMixCount or 25)
        flash('Menyiapkan Radio Pintar YouTube Music...', false, 'Berdasarkan: ' .. (seed.title or ''))
      else
        YT.requestSearch('', 'discover', 25)
      end
    end }
  }
  for i, md in ipairs(moods) do
    local mx = 4 + (i - 1) * (mW + 10)
    local isOn = md.fx and (cfg.main.fxPreset == md.fx)
    if ui.pill('##mood' .. i, md.label, mx, y, mW, 36, isOn, ac, md.icon) then md.act() end
  end
  y = y + 50

  local function sectionLabel(text, rightBtnLabel, rightBtnAct, btnId)
    imgui.SetCursorPos(V2(6, y)); imgui.Dummy(V2(10, 24))
    local a = imgui.GetItemRectMin()
    local fb = pushFont('bold')
    T(dl, a.x, a.y + 2, U32(C.text), ellipsize(text, cw - 130, 'sec_' .. text))
    popFont(fb)
    if rightBtnLabel and rightBtnAct then
      if ui.pill(btnId or ('##secbtn_' .. text), rightBtnLabel, cw - 108, y - 1, 108, 24, false) then
        rightBtnAct()
      end
    end
    y = y + 30
  end

  local function drawTrackShelf(tracks, secKey, maxItems)
    local count = math.min(#tracks, maxItems or 9)
    if count == 0 then return end
    local rCols = (cw >= 760) and 3 or 2
    local rW = math.floor((cw - (rCols - 1) * 10) / rCols)
    local rowH = 54
    for i = 1, count do
      local tr = tracks[i]
      local col = (i - 1) % rCols
      local row = math.floor((i - 1) / rCols)
      local rx = 4 + col * (rW + 10)
      local ry = y + row * (rowH + 8)
      imgui.SetCursorPos(V2(rx, ry))
      imgui.InvisibleButton('##shf_' .. secKey .. '_' .. i, V2(rW, rowH))
      local hov = imgui.IsItemHovered()
      local a = imgui.GetItemRectMin()
      local isCur = (S.cur == tr)
      ui.drawMatteCard(dl, a.x, a.y, a.x + rW, a.y + rowH, UI_R.CTRL, hov, isCur, ac)
      ui.drawArt(dl, a.x + 6, a.y + 6, 42, 6, getArtTexture(tr))
      if isCur and S.loading then
        dl:AddRectFilled(V2(a.x + 6, a.y + 6), V2(a.x + 48, a.y + 48), U32RGB(0, 0, 0, 0.62), 6, 15)
        ui.drawSpinner(dl, a.x + 27, a.y + 27, 10, U32(C.gold), 2.0)
      elseif hov then
        dl:AddCircleFilled(V2(a.x + 27, a.y + 27), 13, U32(ac, 0.92), 18)
        ui.drawIcon(dl, 'play', a.x + 28, a.y + 27, 8, U32(C.bg))
      end
      T(dl, a.x + 56, a.y + 7, U32(isCur and ac or C.text), ellipsize(tr.title, rW - 66, 'sht' .. secKey))
      local fs = pushFont('small')
      if isCur and S.loading then
        local el = math.max(0, os.clock() - (S.loadAt or os.clock()))
        T(dl, a.x + 56, a.y + 29, U32(C.gold), ellipsize(string.format('Memuat (%.1fs)...', el), rW - 66, 'shl'))
      else
        local subInfo = (tr.artist or 'YouTube Music') .. ((tr.durStr and tr.durStr ~= '') and ('  ·  ' .. tr.durStr) or '')
        T(dl, a.x + 56, a.y + 29, U32(C.sub), ellipsize(subInfo, rW - 66, 'sha' .. secKey))
      end
      popFont(fs)
      if imgui.IsItemClicked() then
        if cfg.main.autoMix and #tracks > 1 then
          local qList = { tr }
          for _, other in ipairs(tracks) do
            if other ~= tr then qList[#qList + 1] = other end
          end
          playQueue(qList, 'YouTube Music: ' .. tr.title, 1)
          if tr.videoId and #qList < 12 then
            YT.autoAppending = true
            YT.requestSearch(tr.videoId .. ';;' .. (tr.title or ''), 'automix_append', 15)
          end
        else
          for idx, lt in ipairs(lib) do
            if lt == tr then playIndex('lib', idx); break end
          end
        end
      elseif hov and imgui.IsMouseClicked(1) then
        enqueueTrack(tr, false)
      end
    end
    local rows = math.ceil(count / rCols)
    y = y + rows * (rowH + 8) + 8
  end

  if #recentTracks > 0 then
    sectionLabel('Baru Saja Diputar', 'Putar Semua', function()
      playQueue(recentTracks, 'Baru Saja Diputar', 1)
    end, '##btn_play_rec')
    drawTrackShelf(recentTracks, 'rec', 6)
  end

  -- Rak Lagu Langsung dari Beranda YouTube Music (Quick Picks, Untukmu, Trending)
  if #YT.homeShelves > 0 then
    for sIdx, shelf in ipairs(YT.homeShelves) do
      if shelf.tracks and #shelf.tracks > 0 then
        sectionLabel(shelf.name, 'Putar Semua', function()
          playQueue(shelf.tracks, 'YT Music: ' .. shelf.name, 1)
        end, '##btn_shf_' .. sIdx)
        drawTrackShelf(shelf.tracks, 'yt' .. sIdx, 9)
      end
    end
  end

  local function cards(items, sec)
    local artSz = CARD_W - 12
    for i, c in ipairs(items) do
      local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
      imgui.SetCursorPos(V2(4 + col * (CARD_W + CARD_GAP), y + row * (CARD_H + CARD_GAP)))
      imgui.InvisibleButton('##card' .. sec .. i, V2(CARD_W, CARD_H))
      local hov = imgui.IsItemHovered()
      local clicked = imgui.IsItemClicked()
      local a = imgui.GetItemRectMin()
      ui.drawMatteCard(dl, a.x, a.y, a.x + CARD_W, a.y + CARD_H, UI_R.CARD, hov, false, ac)
      ui.drawArt(dl, a.x + 6, a.y + 6, artSz, UI_R.CTRL, c.art and getArtTexture(c.art) or nil, c.tint)
      if hov then
        dl:AddCircleFilled(V2(a.x + CARD_W - 24, a.y + 6 + artSz - 18), 16, U32(ac), 20)
        ui.drawIcon(dl, 'play', a.x + CARD_W - 23, a.y + 6 + artSz - 18, 9.5, U32(C.bg))
      end
      local fb = pushFont('bold')
      T(dl, a.x + 8, a.y + artSz + 12, U32(C.text), ellipsize(c.title, CARD_W - 16, 'ct'))
      popFont(fb)
      local fs = pushFont('small')
      T(dl, a.x + 8, a.y + artSz + 34, U32(C.sub), ellipsize(c.sub, CARD_W - 16, 'cs'))
      popFont(fs)
      if clicked then c.onClick() end
    end
    y = y + math.ceil(#items / cols) * (CARD_H + CARD_GAP)
  end

  -- Playlist & Album Kurasi Resmi dari YouTube Music (Klik untuk langsung muat & putar)
  if #YT.homePlaylists > 0 then
    local ytCards = {}
    for i, yp in ipairs(YT.homePlaylists) do
      ytCards[#ytCards + 1] = {
        title = yp.title,
        sub = yp.sub ~= '' and yp.sub or 'Playlist YouTube Music',
        art = yp.art,
        tint = ((i - 1) % #accents) + 1,
        onClick = function()
          YT.requestSearch(yp.playlistId .. ';;' .. yp.title, 'playlist', 30)
          flash('Memuat Playlist YouTube Music: ' .. yp.title, false, 'Mohon tunggu sebentar...')
        end
      }
    end
    sectionLabel('Playlist & Album Pilihan YouTube Music')
    cards(ytCards, 'ytpl')
  end

  if #mix > 0 then
    sectionLabel('Mix Katalog Tersimpan')
    cards(mix, 'm')
  end
  if #pls > 0 then
    sectionLabel('Playlist Buatanku')
    cards(pls, 'p')
  end
  imgui.SetCursorPos(V2(0, y)); imgui.Dummy(V2(1, 8))
  imgui.EndChild()
end

-- ---------- TAB 4: PLAYLISTS MIXER & MANAGER ----------
local plv = { list = nil, n = -1, view = {} }
ui.getPlView = function(list)
  if plv.list ~= list or plv.n ~= #list then
    local v = {}
    for i = 1, #list do v[i] = i end
    plv.list, plv.n, plv.view = list, #list, v
  end
  return plv.view
end

ui.selectedPls = function()
  local out = {}
  for _, pl in ipairs(FP.all()) do if ui.plSel[pl] then out[#out + 1] = pl end end
  return out
end

ui.drawPlaylists = function(w, h)
  local allp = FP.all()
  local nsel = 0
  for _, pl in ipairs(allp) do if ui.plSel[pl] then nsel = nsel + 1 end end
  ui.header('Playlists & Multi-Mixer', #allp .. ' playlist tersedia  ·  ' .. nsel .. ' dicentang untuk digabung', nsel .. ' Selected')

  ui.styledInput('##plname', 'Nama playlist baru / ganti nama', ui.plName, 22, 80, 210)
  local nm = cleanName(ffi.string(ui.plName))
  if ui.pill('##plnew', '+ Buat', 240, 80, 72, 36, false) then
    if nm == '' then flash('Ketik nama playlist dulu', true)
    else
      local pl, created = createPlaylist(nm)
      ui.plView = pl; ui.delConfirm = nil
      ffi.fill(ui.plName, ffi.sizeof(ui.plName))
      if created then flash('Playlist "' .. pl.name .. '" dibuat') else flash('Playlist itu sudah ada', true) end
    end
  end

  local xp = w - 22 - 122
  if ui.pill('##plmixplay', 'Putar Campur', xp, 80, 122, 36, true) then
    local sel = ui.selectedPls()
    if #sel == 0 then flash('Centang satu atau lebih playlist di kiri', true) else playMix(sel, false) end
  end
  local xs = xp - 8 - 118
  if ui.pill('##plmixshuf', 'Acak Campur', xs, 80, 118, 36, false) then
    local sel = ui.selectedPls()
    if #sel == 0 then flash('Centang satu atau lebih playlist di kiri', true) else playMix(sel, true) end
  end
  local allSel = (#allp > 0 and nsel == #allp)
  if ui.pill('##plall', allSel and 'Reset' or 'Pilih Semua', xs - 8 - 100, 80, 100, 36, false) then
    ui.plSel = {}
    if not allSel then for _, pl in ipairs(allp) do ui.plSel[pl] = true end end
  end

  local LW = math.min(250, math.floor(w * 0.34))
  imgui.SetCursorPos(V2(14, 128))
  imgui.BeginChild('##pllist', V2(LW, h - 140), false, imgui.WindowFlags.NoBackground)
  do
    local dl = imgui.GetWindowDrawList()
    local ac = accent()
    local RH = 52
    for i, pl in ipairs(allp) do
      imgui.SetCursorPos(V2(0, (i - 1) * RH))
      imgui.InvisibleButton('##plrow' .. i, V2(LW - 10, RH - 4))
      local hov = imgui.IsItemHovered()
      local p0 = imgui.GetItemRectMin()
      local mx = imgui.GetIO().MousePos.x
      if imgui.IsItemClicked() then
        if mx - p0.x < 42 then
          if ui.plSel[pl] then ui.plSel[pl] = nil else ui.plSel[pl] = true end
        else
          ui.plView = pl; ui.delConfirm = nil
        end
      end
      local p1 = V2(p0.x + LW - 10, p0.y + RH - 4)
      local isView = (ui.plView == pl)
      ui.drawMatteCard(dl, p0.x, p0.y, p1.x, p1.y, UI_R.CTRL, hov, isView, ac)
      local midY = p0.y + (RH - 4) / 2
      local bx, by = p0.x + 12, midY - 9
      if ui.plSel[pl] then
        dl:AddRectFilled(V2(bx, by), V2(bx + 18, by + 18), U32(ac), 5, 15)
        dl:AddLine(V2(bx + 4, by + 9), V2(bx + 8, by + 13), U32(C.bg), 2)
        dl:AddLine(V2(bx + 8, by + 13), V2(bx + 14, by + 5), U32(C.bg), 2)
      else
        dl:AddRect(V2(bx, by), V2(bx + 18, by + 18), U32(hov and C.text or C.sub, 0.7), 5, 15, 1.5)
      end
      T(dl, p0.x + 40, p0.y + 6, U32(isView and ac or C.text), ellipsize(pl.name, LW - 56, 'pl'))
      local fs = pushFont('small')
      T(dl, p0.x + 40, p0.y + 27, U32(C.sub), #plTracks(pl) .. ' lagu tersimpan')
      popFont(fs)
    end
    imgui.SetCursorPos(V2(0, #allp * RH))
    imgui.Dummy(V2(1, 1))
  end
  imgui.EndChild()

  local RX = 14 + LW + 10
  local RW = w - RX - 14
  local RHh = h - 140
  imgui.SetCursorPos(V2(RX, 128))
  imgui.BeginChild('##plright', V2(RW, RHh), false,
    bit.bor(imgui.WindowFlags.NoBackground, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse))
  do
    local p = imgui.GetWindowPos()
    local dl = imgui.GetWindowDrawList()
    ui.drawMatteCard(dl, p.x, p.y, p.x + RW, p.y + RHh, UI_R.CARD, false, false)
    local pl = ui.plView
    local found = false
    for _, x in ipairs(allp) do if x == pl then found = true end end
    if not found then pl = allp[1]; ui.plView = pl end

    if pl then
      local tl = plTracks(pl)
      local fb = pushFont('bold')
      T(dl, p.x + 18, p.y + 12, U32(C.text), ellipsize(pl.name, RW - 36, 'pn'))
      popFont(fb)
      local fs = pushFont('small')
      T(dl, p.x + 18, p.y + 36, U32(C.sub), #tl .. ' lagu di dalam playlist ini')
      popFont(fs)

      local by = 58
      if ui.pill('##pv_play', 'Putar', 14, by, 68, 30, true) then playMix({ pl }, false) end
      if ui.pill('##pv_shuf', 'Acak', 88, by, 68, 30, false) then playMix({ pl }, true) end
      if ui.pill('##pv_ren', 'Ganti Nama', 162, by, 98, 30, false) then
        if nm == '' then flash('Ketik nama baru di kotak input atas dulu', true)
        else
          local ok, why = renamePlaylist(pl, nm)
          if ok then ffi.fill(ui.plName, ffi.sizeof(ui.plName)); flash('Nama playlist diperbarui')
          else flash(why == 'exists' and 'Nama sudah dipakai' or 'Nama kosong', true) end
        end
      end
      local armed = (ui.delConfirm == pl)
      if ui.pill('##pv_del', armed and 'Yakin?' or 'Hapus', 266, by, 84, 30, false, armed and C.red or nil) then
        if armed then
          deletePlaylist(pl); ui.plSel[pl] = nil; ui.plView = nil; ui.delConfirm = nil
          flash('Playlist dihapus')
        else
          ui.delConfirm = pl
        end
      end

      if #tl > 0 then
        imgui.SetCursorPos(V2(6, 98))
        local lo = {
          isCur = function(t) return S.cur == t end,
          onPlay = function(idx, t) playMix({ pl }, false, nil, t) end,
          del = function(idx, t) removeFromPlaylist(pl, t.path) end
        }
        ui.drawList('plview', tl, ui.getPlView(tl), RW - 12, RHh - 104, lo)
      else
        ui.emptyState(RW, RHh + 24, 'Playlist Ini Masih Kosong',
          'Klik tombol [+] di samping lagu pada tab Cari YT untuk menambahkan ke playlist ini', false)
      end
    else
      ui.emptyState(RW, RHh, 'Belum Ada Playlist',
        'Ketik nama playlist di kotak kiri atas lalu klik "+ Buat", atau simpan hasil pencarian di tab Cari YT', false)
    end
  end
  imgui.EndChild()
end

-- ======================================================================
-- ZENITH v3.5 SHELL: TOP COMMAND DECK, FREE QUEUE DRAWER, DOCK & COMPACT DECK
-- ======================================================================
local NAV_ITEMS = {
  { 1, 'Beranda',  'home'  },
  { 2, 'Player',   'nav1'  },
  { 3, 'Cari YT',  'nav2'  },
  { 4, 'Playlist', 'plist' },
  { 5, 'Radio',    'nav3'  },
  { 6, 'Lirik',    'mic'   },
  { 7, 'Audio FX', 'fx'    },
  { 8, 'Setelan',  'nav4'  }
}

ui.drawTopDeck = function(w, h)
  local p = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()

  -- Brand Emblem
  local cx, cy = p.x + 24, p.y + h / 2
  dl:AddCircleFilled(V2(cx, cy), 13.5, U32(ac, 0.92), 24)
  ui.drawNote(dl, cx, cy, 15.5, U32(C.bg))

  local fb = pushFont('bold')
  T(dl, p.x + 44, p.y + 10, U32(C.text), 'MoonRadio')
  popFont(fb)
  local fs = pushFont('small')
  T(dl, p.x + 44, p.y + 30, U32( YT.online and ac or C.sub, 0.85), YT.online and 'YT Music Online' or 'YT Standby')
  popFont(fs)

  -- Segmented Navigation Bar ([R-11] Crisp 8px tabs, single accent underline, anti-cutoff)
  local navX = 138
  local searchW = 152
  local rightReserved = searchW + 124
  local navAvail = math.max(340, w - navX - rightReserved)
  local itemW = math.floor((navAvail - (#NAV_ITEMS - 1) * 4) / #NAV_ITEMS)

  for idx, it in ipairs(NAV_ITEMS) do
    local id, label, icon = it[1], it[2], it[3]
    local ix = navX + (idx - 1) * (itemW + 4)
    local iy = 9
    local ih = h - 18
    imgui.SetCursorPos(V2(ix, iy))
    imgui.InvisibleButton('##topnav' .. id, V2(itemW, ih))
    local hov = imgui.IsItemHovered()
    local sel = (ui.tab == id)
    local a, b = imgui.GetItemRectMin(), imgui.GetItemRectMax()

    if sel then
      dl:AddRectFilled(a, b, U32(ac, 0.14), UI_R.CTRL, 15)
      dl:AddRect(a, b, U32(ac, 0.38), UI_R.CTRL, 15, 1)
      dl:AddRectFilled(V2(a.x + 12, b.y - 2.5), V2(b.x - 12, b.y), U32(ac), 1.5, 15)
    elseif hov then
      dl:AddRectFilled(a, b, U32(C.panel2, 0.55), UI_R.CTRL, 15)
    end

    local col = sel and U32(ac) or (hov and U32(C.white) or U32(C.sub))
    local fsNav = pushFont('small')
    local tsz = imgui.CalcTextSize(label)
    if itemW >= tsz.x + 30 then
      local totalW = 16 + tsz.x
      local startX = a.x + (itemW - totalW) / 2
      ui.drawIcon(dl, icon, startX + 5, (a.y + b.y) / 2, 7.0, col)
      T(dl, startX + 16, (a.y + b.y - tsz.y) / 2, col, label)
    else
      T(dl, a.x + math.max(2, (itemW - tsz.x) / 2), (a.y + b.y - tsz.y) / 2, col, ellipsize(label, itemW - 4, 'nv'))
    end
    popFont(fsNav)

    if imgui.IsItemClicked() then ui.tab = id end
  end

  -- Global Quick YouTube Music Search + Compact Toggle + Drawer Toggle + Close
  local sx = w - searchW - 116
  if ui.styledInput('##gsearch', 'Cari lagu YT...', ui.search, sx, 10, searchW) then
    ui.searchStr = ffi.string(ui.search):lower()
    local rawQ = trim(ffi.string(ui.search))
    if rawQ ~= '' then
      if ui.tab ~= 3 then ui.tab = 3 end
      if #rawQ >= 2 then
        YT.pendingQuery = rawQ
        YT.autoSearchAt = os.clock() + 0.65
        YT.pendingSugg = rawQ
        YT.autoSuggAt = os.clock() + 0.25
      end
    else
      YT.autoSearchAt = 0
      YT.pendingQuery = ''
      YT.autoSuggAt = 0
      YT.pendingSugg = ''
      YT.suggestions = {}
      YT.showSearchOnly = false
    end
  end
  if imgui.IsItemFocused() and wasKeyPressed(13) then
    local rawQ = trim(ffi.string(ui.search))
    if rawQ ~= '' then
      ui.tab = 3
      YT.autoSearchAt = 0
      YT.pendingQuery = ''
      YT.requestSearch(rawQ, YT.searchFilterVideos and 'videos' or 'search', 20)
    end
  end

  -- Toggle Compact Glass Deck Mode (Free Control)
  if ui.iconBtn('##tgl_compact', w - 92, h / 2, 15, 'compact', cfg.main.compact, 10.5) then
    cfg.main.compact = true
    cfgDirty = true
    flash('Mode Compact Glass Deck Aktif', false, 'Klik ikon Perbesar untuk kembali ke Studio penuh')
  end

  -- Toggle Right Inspector Drawer
  if ui.iconBtn('##tgl_drawer', w - 58, h / 2, 15, 'queue', cfg.main.drawer, 10.5) then
    cfg.main.drawer = not cfg.main.drawer
    cfgDirty = true
  end

  -- Close Window
  if ui.iconBtn('##closeall', w - 24, h / 2, 15, 'close', false, 10.5) then
    window[0] = false
  end
end

-- ---------- RIGHT LIVE INSPECTOR DRAWER (WITH FREE QUEUE REORDER & CLEAR) ----------
ui.drawRightDrawer = function(w, h)
  local p = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()

  local dTabs = { 'Antrean', 'Lirik', 'FX' }
  local tw = math.floor((w - 24 - 8) / 3)
  for i, nm in ipairs(dTabs) do
    local tx = 12 + (i - 1) * (tw + 4)
    if ui.pill('##drtab' .. i, nm, tx, 10, tw, 28, cfg.main.drawerTab == i) then
      cfg.main.drawerTab = i
      cfgDirty = true
    end
  end

  dl:AddLine(V2(p.x + 12, p.y + 46), V2(p.x + w - 12, p.y + 46), U32(C.white, 0.06), 1)

  local bodyY = 52
  local bodyH = h - bodyY - 8
  local dTab = cfg.main.drawerTab or 1

  if dTab == 1 then
    -- TAB 1: ANTREAN BERIKUTNYA + KONTROL BEBAS URUTAN (UP / DOWN / REMOVE / CLEAR)
    local lst = curList()
    local fs = pushFont('small')
    local srcLabel = (S.listName == 'queue') and (S.queueName or 'Antrean Kustom')
      or (S.listName == 'stations' and 'Daftar Radio' or 'Koleksi Library')
    T(dl, p.x + 12, p.y + bodyY, U32(C.text), ellipsize(srcLabel .. ' (' .. #lst .. ')', w - 116, 'drq'))
    popFont(fs)

    if #lst > 1 and ui.pill('##dr_shuf', cfg.main.smartShuffle and 'Mix' or 'Acak', w - 98, bodyY - 2, 42, 22, false) then
      if S.cur and not S.cur.url and cfg.main.autoMix and #lib > 1 then
        SMART.playAutoMix(S.cur)
      elseif S.listName ~= 'queue' then
        local c = {}
        for i, t in ipairs(lst) do c[i] = t end
        SMART.shuffleList(c, S.cur)
        playQueue(c, cfg.main.smartShuffle and 'Antrean Smart Shuffle' or 'Antrean Diacak', 1)
      else
        SMART.shuffleList(queue, S.cur)
        playIndex('queue', 1)
      end
    end
    if S.listName == 'queue' and #queue > 1 then
      if ui.pill('##dr_clr', 'Reset', w - 52, bodyY - 2, 42, 22, false) then
        if S.cur then queue = { S.cur }; S.index = 1 else queue = {}; S.index = 0 end
        flash('Antrean dibersihkan (menyisakan lagu aktif)')
      end
    end

    imgui.SetCursorPos(V2(8, bodyY + 24))
    local qH = math.max(60, bodyH - 26)
    imgui.BeginChild('##dr_qlist', V2(w - 16, qH), false, imgui.WindowFlags.NoBackground)
    local qdl = imgui.GetWindowDrawList()
    local QR = 46
    local n = #lst
    local scroll = imgui.GetScrollY()
    local first = math.max(1, math.floor(scroll / QR) + 1)
    local last = math.min(n, first + math.ceil(qH / QR) + 1)

    for i = first, last do
      local tr = lst[i]
      if tr then
        local rowW = w - 24
        imgui.SetCursorPos(V2(0, (i - 1) * QR))
        imgui.InvisibleButton('##drqrow' .. i, V2(rowW - 58, QR - 4))
        local hov = imgui.IsItemHovered()
        local p0 = imgui.GetItemRectMin()
        local p1 = V2(p0.x + rowW, p0.y + QR - 4)
        local isCur = (S.index == i)
        local mouseInRow = imgui.IsMouseHoveringRect(p0, p1)

        if isCur then
          ui.drawMatteCard(qdl, p0.x, p0.y, p1.x, p1.y, UI_R.CTRL, false, true, ac)
        elseif mouseInRow then
          qdl:AddRectFilled(p0, p1, U32(C.panel2, 0.65), UI_R.CTRL, 15)
        end
        local nm = tr.url and tr.name or tr.title
        local ar = tr.url and 'Radio Stream' or tr.artist
        local txtMaxW = mouseInRow and (rowW - 72) or (rowW - 18)
        local fs2 = pushFont('small')
        T(qdl, p0.x + 10, p0.y + 4, U32(isCur and ac or C.text), ellipsize(i .. '. ' .. nm, txtMaxW, 'dq1'))
        T(qdl, p0.x + 10, p0.y + 22, U32(C.sub), ellipsize(ar, txtMaxW, 'dq2'))
        popFont(fs2)
        if imgui.IsItemClicked() then
          playIndex(S.listName, i)
        end

        -- Free Queue Reorder Controls (Up / Down / Remove) on row hover
        if mouseInRow and not tr.url then
          local cy = p0.y + (QR - 4) / 2
          local ry = (i - 1) * QR + 9
          imgui.SetCursorPos(V2(rowW - 56, ry))
          if imgui.InvisibleButton('##qup' .. i, V2(18, 24)) then moveQueueItem(i, -1) end
          ui.drawIcon(qdl, 'up', p0.x + rowW - 47, cy, 6.5, U32(imgui.IsItemHovered() and ac or C.sub))

          imgui.SetCursorPos(V2(rowW - 37, ry))
          if imgui.InvisibleButton('##qdn' .. i, V2(18, 24)) then moveQueueItem(i, 1) end
          ui.drawIcon(qdl, 'down', p0.x + rowW - 28, cy, 6.5, U32(imgui.IsItemHovered() and ac or C.sub))

          if S.listName == 'queue' then
            imgui.SetCursorPos(V2(rowW - 18, ry))
            if imgui.InvisibleButton('##qrm' .. i, V2(18, 24)) then
              removeQueueItem(i)
              imgui.EndChild()
              return
            end
            ui.drawIcon(qdl, 'close', p0.x + rowW - 9, cy, 6.5, U32(imgui.IsItemHovered() and C.red or C.sub))
          end
        end
      end
    end
    imgui.SetCursorPos(V2(0, n * QR))
    imgui.Dummy(V2(1, 1))
    imgui.EndChild()

  elseif dTab == 2 then
    -- TAB 2: LIRIK CEPAT
    imgui.SetCursorPos(V2(10, bodyY))
    imgui.BeginChild('##dr_lyr', V2(w - 20, bodyH), false, imgui.WindowFlags.NoBackground)
    local ldl = imgui.GetWindowDrawList()
    local lp = imgui.GetWindowPos()
    local loy = lp.y - imgui.GetScrollY()
    if not S.cur or not S.lyrics or not S.lyrics.lines or #S.lyrics.lines == 0 then
      local fs = pushFont('small')
      T(ldl, lp.x + 8, loy + 20, U32(C.sub), 'Lirik belum tersedia untuk')
      T(ldl, lp.x + 8, loy + 40, U32(C.sub), 'lagu yang sedang diputar.')
      popFont(fs)
      if ui.pill('##dr_openlyr', 'Buka Tab Lirik', 8, 72, w - 36, 30, false) then ui.tab = 6 end
    else
      local active = currentLyricIndex()
      local RL = 34
      local io = imgui.GetIO()
      local now = os.clock()
      if imgui.IsWindowHovered() and math.abs(io.MouseWheel or 0) > 0.01 then
        ui.lyricManualUntil = now + 3.5
      end
      if cfg.main.lyricAutoScroll and S.lyrics.timed and active and now >= (ui.lyricManualUntil or 0) then
        local target = math.max(0, (active - 1) * RL - bodyH * 0.36)
        local cs = imgui.GetScrollY()
        imgui.SetScrollY(cs + (target - cs) * clamp(io.DeltaTime * 6, 0, 1))
      end
      local lines = S.lyrics.lines
      local n = #lines
      local scroll = imgui.GetScrollY()
      local first = math.max(1, math.floor(scroll / RL) + 1)
      local last = math.min(n, first + math.ceil(bodyH / RL) + 2)
      local fs = pushFont('small')
      for i = first, last do
        local ln = lines[i]
        if ln then
          imgui.SetCursorPos(V2(2, (i - 1) * RL))
          imgui.InvisibleButton('##drln' .. i, V2(w - 30, RL - 2))
          local p0 = imgui.GetItemRectMin()
          local isAct = S.lyrics.timed and (i == active)
          if isAct then
            ldl:AddRectFilled(p0, V2(p0.x + w - 30, p0.y + RL - 2), U32(ac, 0.14), UI_R.CTRL, 15)
          end
          T(ldl, p0.x + 8, p0.y + 7, U32(isAct and ac or C.sub, isAct and 1 or 0.78), ellipsize(ln.text, w - 44, 'drl'))
          if imgui.IsItemClicked() and ln.time and S.dur > 0 then
            seekTo(clamp((ln.time + lyricOffset) / S.dur, 0, 1))
          end
        end
      end
      popFont(fs)
      imgui.SetCursorPos(V2(0, n * RL))
      imgui.Dummy(V2(1, 1))
    end
    imgui.EndChild()

  else
    -- TAB 3: QUICK STUDIO FX + GLASS OPACITY SLIDER
    imgui.SetCursorPos(V2(10, bodyY))
    imgui.BeginChild('##dr_fx', V2(w - 20, bodyH), false, imgui.WindowFlags.NoBackground)
    local fdl = imgui.GetWindowDrawList()
    local fp = imgui.GetWindowPos()
    local foy = fp.y - imgui.GetScrollY()
    local fs = pushFont('small')
    T(fdl, fp.x + 4, foy + 2, U32(C.sub), 'Preset Suara Cepat')
    local y = 24
    for i = 1, 7 do
      local pr = FX_PRESETS[i]
      if ui.pill('##drfx' .. i, pr.name, 4, y, w - 32, 28, cfg.main.fxPreset == i) then
        selectFxPreset(i)
      end
      y = y + 34
    end
    T(fdl, fp.x + 4, foy + y + 2, U32(C.sub), string.format('Speed: %d%%  ·  Bass: %+d dB', cfg.main.speed or 100, cfg.main.eqBass or 0))
    popFont(fs)
    if ui.pill('##drfx_more', 'Studio FX Lengkap', 4, y + 26, w - 32, 30, true) then ui.tab = 7 end
    imgui.SetCursorPos(V2(0, y + 66))
    imgui.Dummy(V2(1, 1))
    imgui.EndChild()
  end
end

-- ---------- BOTTOM FLOATING GLASS TRANSPORT DOCK ----------
ui.drawTransportDock = function(w, h)
  local p = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  local title, artist = nowInfo()

  -- Top Row of Dock: Full-Width Interactive Seek Bar (Scroll Wheel = ±5s) + Indikator Loading
  local sx = 64
  local sw = w - 128
  local sy = 6
  local frac = (S.dur > 0) and clamp(S.pos / S.dur, 0, 1) or 0
  if S.seeking then frac = S.seekFrac end

  local fs = pushFont('small')
  if S.loading then
    local el = math.max(0, os.clock() - (S.loadAt or os.clock()))
    T(dl, p.x + 14, p.y + sy + 1, U32(C.gold), 'LOAD')
    T(dl, p.x + w - 50, p.y + sy + 1, U32(C.gold), string.format('%.1fs', el))
  elseif S.live then
    dl:AddCircleFilled(V2(p.x + 18, p.y + sy + 9), 4, U32(C.red), 10)
    T(dl, p.x + 26, p.y + sy + 1, U32(C.red), 'LIVE')
    T(dl, p.x + w - 50, p.y + sy + 1, U32(C.sub), 'RADIO')
  else
    T(dl, p.x + 14, p.y + sy + 1, U32(C.sub), fmtTime(S.seeking and S.seekFrac * S.dur or S.pos))
    T(dl, p.x + w - 50, p.y + sy + 1, U32(C.sub), fmtTime(S.dur))
  end
  popFont(fs)

  local disabled = S.live or S.dur <= 0 or S.handle == 0
  if S.loading then
    ui.drawLoadingBar(dl, p.x + sx, p.y + sy + 6, p.x + sx + sw, p.y + sy + 12, C.gold)
    imgui.SetCursorPos(V2(sx, sy)); imgui.Dummy(V2(sw, 18))
  elseif S.live and S.handle ~= 0 then
    dl:AddRectFilled(V2(p.x + sx, p.y + sy + 7), V2(p.x + sx + sw, p.y + sy + 11), U32(ac, 0.55), 2, 15)
    imgui.SetCursorPos(V2(sx, sy)); imgui.Dummy(V2(sw, 18))
  else
    local changed, nf, rel = ui.slider('##seek', sx, sy, sw, frac, disabled, S.dur)
    if changed then S.seeking = true; S.seekFrac = nf end
    if rel and S.seeking then S.seeking = false; seekTo(S.seekFrac) end
  end

  -- Left: Cover Art (Default ala YouTube Music) / Vinyl + Title + Artist / Loading Status + Fav
  local bodyY = 28
  local artS = 52
  ui.drawPlayerArt(dl, p.x + 14 + artS / 2, p.y + bodyY + artS / 2, artS / 2, getArtTexture(S.cur), ui.vinylAngle, ac, true)
  imgui.SetCursorPos(V2(14, bodyY))
  imgui.InvisibleButton('##dock_art_btn', V2(artS, artS))
  if imgui.IsItemClicked(0) then
    ui.tab = (ui.tab == 2) and 1 or 2
  elseif imgui.IsItemHovered() and imgui.IsMouseClicked(1) then
    cfg.main.playerArtStyle = ((cfg.main.playerArtStyle or 1) % #PLAYER_ART_STYLES) + 1
    cfgDirty = true
    flash('Gaya Gambar Player: ' .. PLAYER_ART_STYLES[cfg.main.playerArtStyle], false, 'Klik kanan cover art bawah untuk mengganti')
  end

  local cx = w / 2
  local cy = bodyY + 26
  local lxOff = 14 + artS + 12
  local maxLeftEnd = cx - 116
  local hasTrackBtns = (S.cur and S.cur.path and not S.cur.url)
  local lw = math.max(100, math.min(320, math.floor(maxLeftEnd - lxOff - (hasTrackBtns and 58 or 8))))

  local fb = pushFont('bold')
  T(dl, p.x + lxOff, p.y + bodyY + 5, U32(C.text), ellipsize(title, lw, 'bt'))
  popFont(fb)
  local fs2 = pushFont('small')
  local subCol = S.loading and C.gold or ((not S.playing and S.err) and C.red or C.sub)
  T(dl, p.x + lxOff, p.y + bodyY + 29, U32(subCol), ellipsize(artist, lw, 'ba'))
  popFont(fs2)

  local actX = lxOff + lw + 12
  if hasTrackBtns then
    local fav = isFav(S.cur)
    if ui.iconBtn('##favbar', actX, cy, 14, 'heart', fav, 10) then toggleFav(S.cur) end
    local hasBm = getBookmark(S.cur) ~= nil
    if ui.iconBtn('##bmbar', actX + 28, cy, 14, 'star', hasBm, 10) then
      toggleBookmark(S.cur, S.pos or 0)
    end
  end

  -- Center: Clean Transport Controls (Tanpa tombol -5s/+5s yang bikin sempit; cukup scroll di seek bar)
  if ui.iconBtn('##shuf', cx - 94, cy, 15, 'shuffle', cfg.main.shuffle, 10.5) then
    cfg.main.shuffle = not cfg.main.shuffle; cfgDirty = true
    local modeTxt = cfg.main.smartShuffle and 'Smart Shuffle (Se-Vibe)' or 'Shuffle Biasa'
    flash(modeTxt .. ': ' .. (cfg.main.shuffle and 'ON' or 'OFF'))
  end
  if imgui.IsItemHovered() and imgui.IsMouseClicked(1) then
    cfg.main.smartShuffle = not cfg.main.smartShuffle; cfgDirty = true
    S.smartBag = nil
    flash('Smart Shuffle Pintar: ' .. (cfg.main.smartShuffle and 'ON' or 'OFF'), false, 'Klik kanan pada tombol Shuffle')
  end
  if ui.iconBtn('##prev', cx - 50, cy, 16, 'prev', false, 11.5) then prevTrack() end

  -- [R-11 / R-13] Focal Play/Pause CTA Button (+ Indikator Spinner saat Loading)
  imgui.SetCursorPos(V2(cx - 23, cy - 23))
  imgui.InvisibleButton('##playbtn', V2(46, 46))
  local ph = imgui.IsItemHovered()
  if imgui.IsItemClicked() then togglePlay() end
  local pa = imgui.GetItemRectMin()
  local pulseR = 22 + (S.playing and (S.bassPulse or 0) * 3.5 or 0)
  if S.loading then
    dl:AddCircleFilled(V2(pa.x + 23, pa.y + 23), 21.5, U32(C.panel2, 0.95), 28)
    ui.drawSpinner(dl, pa.x + 23, pa.y + 23, 19.5, U32(C.gold), 2.6)
    ui.drawIcon(dl, 'close', pa.x + 23, pa.y + 23, 8.5, U32(C.text, 0.9))
  else
    if S.playing then
      dl:AddCircleFilled(V2(pa.x + 23, pa.y + 23), pulseR + 3, U32(ac, 0.20), 28)
    end
    dl:AddCircleFilled(V2(pa.x + 23, pa.y + 23), ph and 23 or 21.5, U32(ac), 28)
    ui.drawIcon(dl, (S.playing and S.state ~= 0) and 'pause' or 'play',
      pa.x + 23 + ((S.playing and S.state ~= 0) and 0 or 1.5), pa.y + 23, 11, U32(C.bg))
  end

  if ui.iconBtn('##next', cx + 50, cy, 16, 'next', false, 11.5) then nextTrack(false) end
  local rm = cfg.main.repeatMode
  if ui.iconBtn('##rep', cx + 94, cy, 15, rm == 2 and 'repeat1' or 'repeat', rm ~= 0, 10.5) then
    cfg.main.repeatMode = (rm + 1) % 3; cfgDirty = true
    local rNames = { [0] = 'Repeat: OFF', [1] = 'Repeat: Semua', [2] = 'Repeat: 1 Lagu' }
    flash(rNames[cfg.main.repeatMode])
  end

  -- Right: Quick FX Cycler + Volume Slider (Scroll Wheel = ±3%)
  local rx = w - 296
  local fxp = FX_PRESETS[cfg.main.fxPreset or 1] or FX_PRESETS[1]
  if rx > cx + 118 then
    if ui.pill('##bar_fx', 'FX: ' .. ellipsize(fxp.name, 74, 'bfx'), rx, cy - 13, 96, 26, (cfg.main.fxPreset or 1) > 1) then
      local nxt = ((cfg.main.fxPreset or 1) % 7) + 1
      selectFxPreset(nxt)
    end
  end

  local vx = w - 186
  if ui.iconBtn('##mute', vx, cy, 15, (S.muted or cfg.main.volume <= 0.001) and 'mute' or 'vol', S.muted, 10.5) then
    S.muted = not S.muted; applyVolume(true)
  end
  local vol = S.muted and 0 or cfg.main.volume
  local ch, nv = ui.slider('##vol', vx + 22, cy - 9, 108, vol, false, nil, false, 0.03)
  if ch then setVolume(nv) end
  local fs3 = pushFont('small')
  T(dl, p.x + vx + 138, p.y + cy - 8, U32(C.sub), string.format('%d%%', math.floor(vol * 100 + 0.5)))
  popFont(fs3)
end

-- ---------- COMPACT GLASS DECK MODE (FREE FLOATING CONTROLLER) ----------
ui.drawCompactDeck = function(w, h)
  local wp = imgui.GetWindowPos()
  local dl = imgui.GetWindowDrawList()
  local ac = accent()
  local io = imgui.GetIO()
  ui.updateBars(io.DeltaTime)

  ui.drawGlassShell(dl, wp.x, wp.y, wp.x + w, wp.y + h, UI_R.WIN, glassOpacity())
  ui.drawGlassFocal(dl, wp.x + 8, wp.y + 8, wp.x + w - 8, wp.y + h - 8, UI_R.CARD, ac, nil, false)

  -- Top Drag Header Bar
  imgui.SetCursorPos(V2(8, 8))
  imgui.InvisibleButton('##comp_drag', V2(w - 92, 34))
  if imgui.IsItemActive() then
    cfg.main.compactX = clamp(wp.x + io.MouseDelta.x, 4, math.max(4, io.DisplaySize.x - w - 4))
    cfg.main.compactY = clamp(wp.y + io.MouseDelta.y, 4, math.max(4, io.DisplaySize.y - h - 4))
    cfgDirty = true
  end
  if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
    cfg.main.compact = false; cfgDirty = true
  end

  local fs = pushFont('small')
  T(dl, wp.x + 20, wp.y + 15, U32(C.sub), 'MoonRadio Compact Deck  ·  Seret untuk pindah')
  popFont(fs)

  if ui.iconBtn('##comp_exp', w - 54, 24, 14, 'expand', false, 9.5) then
    cfg.main.compact = false; cfgDirty = true
  end
  if ui.iconBtn('##comp_cls', w - 24, 24, 14, 'close', false, 9.5) then
    window[0] = false
  end

  -- Track Info & Cover Art / Vinyl
  local title, artist = nowInfo()
  local curLyr = currentLyricText()
  ui.drawPlayerArt(dl, wp.x + 54, wp.y + 84, 34, getArtTexture(S.cur), ui.vinylAngle, ac, true)

  local fb = pushFont('bold')
  T(dl, wp.x + 102, wp.y + 46, U32(C.text), ellipsize(title, w - 196, 'cpt'))
  popFont(fb)
  local fs2 = pushFont('small')
  local cpSubCol = S.loading and C.gold or ((not S.playing and S.err) and C.red or C.sub)
  T(dl, wp.x + 102, wp.y + 69, U32(cpSubCol), ellipsize(artist, w - 196, 'cpa'))
  T(dl, wp.x + 102, wp.y + 92, U32(curLyr and ac or C.sub),
    ellipsize(curLyr or (S.cur and ('Vibe: ' .. SMART.vibeLabel(S.cur)) or 'Pilih lagu atau acak koleksi'), w - 118, 'cpl'))
  popFont(fs2)

  local fxp = FX_PRESETS[cfg.main.fxPreset or 1] or FX_PRESETS[1]
  if ui.pill('##cp_fx', 'FX: ' .. ellipsize(fxp.name, 58, 'cfx'), w - 92, 48, 76, 26, (cfg.main.fxPreset or 1) > 1) then
    selectFxPreset(((cfg.main.fxPreset or 1) % 7) + 1)
  end

  -- Seek Bar
  local sy = 128
  local frac = (S.dur > 0) and clamp(S.pos / S.dur, 0, 1) or 0
  if S.seeking then frac = S.seekFrac end
  local fs3 = pushFont('small')
  if S.loading then
    local el = math.max(0, os.clock() - (S.loadAt or os.clock()))
    T(dl, wp.x + 18, wp.y + sy + 1, U32(C.gold), 'LOAD')
    T(dl, wp.x + w - 48, wp.y + sy + 1, U32(C.gold), string.format('%.1fs', el))
    popFont(fs3)
    ui.drawLoadingBar(dl, wp.x + 58, wp.y + sy + 6, wp.x + w - 56, wp.y + sy + 12, C.gold)
    imgui.SetCursorPos(V2(58, sy)); imgui.Dummy(V2(w - 114, 18))
  else
    T(dl, wp.x + 18, wp.y + sy + 1, U32(C.sub), S.live and 'LIVE' or fmtTime(S.seeking and S.seekFrac * S.dur or S.pos))
    T(dl, wp.x + w - 48, wp.y + sy + 1, U32(C.sub), S.live and 'RADIO' or fmtTime(S.dur))
    popFont(fs3)
    local disabled = S.live or S.dur <= 0 or S.handle == 0
    local chS, nfS, relS = ui.slider('##cp_seek', 58, sy, w - 114, frac, disabled, S.dur)
    if chS then S.seeking = true; S.seekFrac = nfS end
    if relS and S.seeking then S.seeking = false; seekTo(S.seekFrac) end
  end

  -- Bottom Transport Row
  local cy = 176
  local cx = w * 0.42
  if ui.iconBtn('##cp_shuf', cx - 104, cy, 14, 'shuffle', cfg.main.shuffle, 10) then
    cfg.main.shuffle = not cfg.main.shuffle; cfgDirty = true
  end
  if ui.iconBtn('##cp_prev', cx - 64, cy, 15, 'prev', false, 11) then prevTrack() end

  imgui.SetCursorPos(V2(cx - 20, cy - 20))
  if imgui.InvisibleButton('##cp_play', V2(40, 40)) then togglePlay() end
  local pa = imgui.GetItemRectMin()
  dl:AddCircleFilled(V2(pa.x + 20, pa.y + 20), 20, U32(ac), 24)
  ui.drawIcon(dl, (S.playing and S.state ~= 0) and 'pause' or 'play',
    pa.x + 20 + ((S.playing and S.state ~= 0) and 0 or 1.5), pa.y + 20, 10, U32(C.bg))

  if ui.iconBtn('##cp_next', cx + 64, cy, 15, 'next', false, 11) then nextTrack(false) end
  local rm = cfg.main.repeatMode
  if ui.iconBtn('##cp_rep', cx + 104, cy, 14, rm == 2 and 'repeat1' or 'repeat', rm ~= 0, 10) then
    cfg.main.repeatMode = (rm + 1) % 3; cfgDirty = true
  end

  if S.cur and S.cur.path and not S.cur.url then
    if ui.iconBtn('##cp_fav', 28, cy, 14, 'heart', isFav(S.cur), 10) then toggleFav(S.cur) end
  end

  -- Volume Slider on Right
  local vx = w - 146
  if ui.iconBtn('##cp_mute', vx, cy, 14, (S.muted or cfg.main.volume <= 0.001) and 'mute' or 'vol', S.muted, 10) then
    S.muted = not S.muted; applyVolume(true)
  end
  local vol = S.muted and 0 or cfg.main.volume
  local chV, nvV = ui.slider('##cp_vol', vx + 20, cy - 9, 104, vol, false, nil, false, 0.03)
  if chV then setVolume(nvV) end
end

-- ---------- MAIN WINDOW INITIALIZE & RENDER ----------
ui.applyStyle = function()
  local st = imgui.GetStyle()
  st.WindowPadding = V2(0, 0)
  st.WindowRounding = UI_R.WIN
  st.ChildRounding = UI_R.CARD
  st.FrameRounding = UI_R.CTRL
  st.PopupRounding = UI_R.CARD
  st.GrabRounding = UI_R.CTRL
  st.ScrollbarRounding = 8
  st.ScrollbarSize = 7
  st.FramePadding = V2(12, 8)
  st.ItemSpacing = V2(8, 8)
  st.WindowBorderSize = 0
  st.ChildBorderSize = 0
  st.FrameBorderSize = 0
  local c = st.Colors
  c[imgui.Col.Text] = V4(C.text)
  c[imgui.Col.TextDisabled] = V4(C.sub)
  c[imgui.Col.WindowBg] = imgui.ImVec4(0, 0, 0, 0)
  c[imgui.Col.ChildBg] = imgui.ImVec4(0, 0, 0, 0)
  c[imgui.Col.PopupBg] = V4(C.panel)
  c[imgui.Col.FrameBg] = V4(C.panel2)
  c[imgui.Col.ScrollbarBg] = imgui.ImVec4(0, 0, 0, 0)
  c[imgui.Col.ScrollbarGrab] = V4(C.panel2)
end

imgui.OnInitialize(function()
  local io = imgui.GetIO()
  io.IniFilename = nil
  local ranges = io.Fonts:GetGlyphRangesCyrillic()
  local win = os.getenv('SystemRoot') or 'C:\\Windows'
  local reg, bold = win .. '\\Fonts\\segoeui.ttf', win .. '\\Fonts\\segoeuib.ttf'
  if doesFileExist(reg) then
    fonts.reg = io.Fonts:AddFontFromFileTTF(reg, 17, nil, ranges)
    fonts.small = io.Fonts:AddFontFromFileTTF(reg, 14, nil, ranges)
    if doesFileExist(bold) then
      fonts.bold = io.Fonts:AddFontFromFileTTF(bold, 18, nil, ranges)
      fonts.title = io.Fonts:AddFontFromFileTTF(bold, 25, nil, ranges)
    end
  end
  ui.applyStyle()
end)

local mainFrame
mainFrame = imgui.OnFrame(function()
  if mainFrame then
    mainFrame.HideCursor = false
    mainFrame.LockPlayer = true
  end
  return window[0]
end, function(self)
  self.HideCursor = false
  self.LockPlayer = true
  local io = imgui.GetIO()
  io.MouseDrawCursor = false
  ui.wantText = io.WantTextInput and true or false
  GA = 1
  HUD_OPACITY = 1
  ART.tick = ART.tick + 1; ART.loads = 0

  if not ui.wasOpen then ui.wasOpen = true; recs.seed = math.random(1, 999999) end

  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  local isCompact = cfg.main.compact
  local w, h, wx, wy
  if isCompact then
    w, h = 520, 212
    wx = (cfg.main.compactX and cfg.main.compactX >= 0) and clamp(cfg.main.compactX, 4, math.max(4, sw - w - 4)) or ((sw - w) / 2)
    wy = (cfg.main.compactY and cfg.main.compactY >= 0) and clamp(cfg.main.compactY, 4, math.max(4, sh - h - 4)) or ((sh - h) / 2)
  else
    w = clamp(cfg.main.winW or 1080, 780, math.max(780, sw - 20))
    h = clamp(cfg.main.winH or 680, 500, math.max(500, sh - 20))
    wx = (cfg.main.winX and cfg.main.winX >= 0) and clamp(cfg.main.winX, 4, math.max(4, sw - w - 4)) or ((sw - w) / 2)
    wy = (cfg.main.winY and cfg.main.winY >= 0) and clamp(cfg.main.winY, 4, math.max(4, sh - h - 4)) or ((sh - h) / 2)
  end

  imgui.SetNextWindowSize(V2(w, h), imgui.Cond.Always)
  imgui.SetNextWindowPos(V2(wx, wy), imgui.Cond.Always)

  local ac = accent()
  imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.ScrollbarGrab, V4(C.panel2))
  imgui.PushStyleColor(imgui.Col.ScrollbarGrabHovered, V4(ac, 0.7))
  imgui.PushStyleColor(imgui.Col.ScrollbarGrabActive, V4(ac, 1))
  imgui.PushStyleColor(imgui.Col.TextSelectedBg, V4(ac, 0.35))
  imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, V2(0, 0))
  local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
    imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse,
    imgui.WindowFlags.NoSavedSettings, imgui.WindowFlags.NoBackground)
  local f1 = pushFont('reg')

  if imgui.Begin('##MoonRadioZenith', window, flags) then
    if isCompact then
      ui.drawCompactDeck(w, h)
    else
      local wp = imgui.GetWindowPos()
      local dl = imgui.GetWindowDrawList()

      -- [R-10] Translucent Frosted Glass Window Shell
      ui.drawGlassShell(dl, wp.x, wp.y, wp.x + w, wp.y + h, UI_R.WIN, glassOpacity())

      local M = 10
      local TOP_H = 54
      local DOCK_H = 90
      local GAP = 8
      local showDrawer = cfg.main.drawer and (w >= 880)
      local DRAWER_W = showDrawer and 246 or 0

      local mainY = M + TOP_H + GAP
      local mainH = h - mainY - DOCK_H - GAP - M
      local mainW = w - 2 * M - (showDrawer and (DRAWER_W + GAP) or 0)
      local dockY = h - M - DOCK_H

      -- Structured Surface Layers ([R-10] Matte workspace + Focal Glass Transport Dock)
      ui.drawMatteCard(dl, wp.x + M, wp.y + M, wp.x + w - M, wp.y + M + TOP_H, UI_R.CARD, false, false)
      dl:AddRectFilled(V2(wp.x + M, wp.y + mainY), V2(wp.x + M + mainW, wp.y + mainY + mainH), U32(C.panel, 0.42), UI_R.CARD, 15)
      dl:AddRect(V2(wp.x + M, wp.y + mainY), V2(wp.x + M + mainW, wp.y + mainY + mainH), U32(C.white, 0.05), UI_R.CARD, 15, 1)

      if showDrawer then
        local dx = wp.x + M + mainW + GAP
        ui.drawMatteCard(dl, dx, wp.y + mainY, dx + DRAWER_W, wp.y + mainY + mainH, UI_R.CARD, false, false)
      end

      -- [R-10] Focal Glass Layer on Bottom Transport Dock
      ui.drawGlassFocal(dl, wp.x + M, wp.y + dockY, wp.x + w - M, wp.y + dockY + DOCK_H, UI_R.CARD, ac, nil, false)

      local cf = bit.bor(imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse, imgui.WindowFlags.NoBackground)

      -- Free Window Dragging from Top Deck Brand Area
      imgui.SetCursorPos(V2(M, M))
      imgui.InvisibleButton('##win_drag_zone', V2(144, TOP_H))
      if imgui.IsItemActive() then
        cfg.main.winX = clamp(wp.x + io.MouseDelta.x, 4, math.max(4, sw - w - 4))
        cfg.main.winY = clamp(wp.y + io.MouseDelta.y, 4, math.max(4, sh - h - 4))
        cfgDirty = true
      end
      if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
        cfg.main.compact = true; cfgDirty = true
      end

      -- 1. Top Command Bar
      imgui.SetCursorPos(V2(M, M))
      imgui.BeginChild('##topdeck', V2(w - 2 * M, TOP_H), false, cf)
      ui.drawTopDeck(w - 2 * M, TOP_H)
      imgui.EndChild()

      -- 2. Main Viewport
      imgui.SetCursorPos(V2(M, mainY))
      imgui.BeginChild('##content', V2(mainW, mainH), false, cf)
      if ui.tab == 1 then ui.drawHome(mainW, mainH)
      elseif ui.tab == 2 then ui.drawStage(mainW, mainH)
      elseif ui.tab == 3 then ui.drawLibrary(mainW, mainH)
      elseif ui.tab == 4 then ui.drawPlaylists(mainW, mainH)
      elseif ui.tab == 5 then ui.drawStations(mainW, mainH)
      elseif ui.tab == 6 then ui.drawLyrics(mainW, mainH)
      elseif ui.tab == 7 then ui.drawStudioFX(mainW, mainH)
      else ui.drawSettings(mainW, mainH) end
      imgui.EndChild()

      -- 3. Right Inspector Drawer
      if showDrawer then
        imgui.SetCursorPos(V2(M + mainW + GAP, mainY))
        imgui.BeginChild('##rightdrawer', V2(DRAWER_W, mainH), false, cf)
        ui.drawRightDrawer(DRAWER_W, mainH)
        imgui.EndChild()
      end

      -- 4. Bottom Floating Transport Dock
      imgui.SetCursorPos(V2(M, dockY))
      imgui.BeginChild('##dock', V2(w - 2 * M, DOCK_H), false, cf)
      ui.drawTransportDock(w - 2 * M, DOCK_H)
      imgui.EndChild()

      -- 5. Free Corner Resize Grip (Bottom-Right Corner)
      imgui.SetCursorPos(V2(w - 20, h - 20))
      imgui.InvisibleButton('##win_resize_grip', V2(20, 20))
      local rhov = imgui.IsItemHovered()
      if imgui.IsItemActive() then
        cfg.main.winW = clamp((cfg.main.winW or w) + io.MouseDelta.x, 780, sw - 16)
        cfg.main.winH = clamp((cfg.main.winH or h) + io.MouseDelta.y, 500, sh - 16)
        cfgDirty = true
      elseif rhov and imgui.IsMouseClicked(1) then
        cfg.main.winW, cfg.main.winH = 1080, 680
        cfg.main.winX, cfg.main.winY = -1, -1
        cfgDirty = true
        flash('Ukuran & posisi jendela direset ke standar (1080x680)')
      end
      local rgCol = U32(rhov and ac or C.sub, rhov and 0.9 or 0.45)
      dl:AddLine(V2(wp.x + w - 14, wp.y + h - 5), V2(wp.x + w - 5, wp.y + h - 14), rgCol, 1.5)
      dl:AddLine(V2(wp.x + w - 9, wp.y + h - 5), V2(wp.x + w - 5, wp.y + h - 9), rgCol, 1.5)

      -- 6. In-Menu Glass Flash Banner
      local now = os.clock()
      if now < FL.untilT then
        local rem = clamp((FL.untilT - now) / 0.35, 0, 1)
        imgui.SetCursorPos(V2(M + 18, mainY + mainH - 52))
        imgui.BeginChild('##flash', V2(mainW - 36, 42), false, bit.bor(cf, imgui.WindowFlags.NoInputs))
        local fp = imgui.GetWindowPos()
        local fd = imgui.GetWindowDrawList()
        local col = FL.err and C.red or ac
        local fsz = imgui.CalcTextSize(FL.text)
        local boxW = math.min(mainW - 40, math.max(220, fsz.x + 44))
        local fx = fp.x + (mainW - 36 - boxW) / 2
        fd:AddRectFilled(V2(fx, fp.y + 4), V2(fx + boxW, fp.y + 38), U32(C.side, 0.95 * rem), UI_R.CTRL, 15)
        fd:AddRect(V2(fx, fp.y + 4), V2(fx + boxW, fp.y + 38), U32(col, 0.45 * rem), UI_R.CTRL, 15, 1)
        T(fd, fx + 18, fp.y + 11, U32(C.white, rem), ellipsize(FL.text, boxW - 32, 'flt'))
        imgui.EndChild()
      end
    end
  end
  imgui.End()
  popFont(f1)
  imgui.PopStyleVar(1)
  imgui.PopStyleColor(5)
end)
mainFrame.HideCursor = false
mainFrame.LockPlayer = true

-- ======================================================================
-- GLASS TOAST NOTIFICATION SYSTEM
-- ======================================================================
local toastFrame
toastFrame = imgui.OnFrame(function()
  if toastFrame then
    toastFrame.HideCursor = true
    toastFrame.LockPlayer = false
  end
  if window[0] or not cfg.main.toast then return false end
  local now = os.clock()
  local hasTrackToast = (not cfg.main.mini) and (S.cur ~= nil) and (now < S.toastUntil)
  local hasActionToast = false
  for i = #TOASTS.list, 1, -1 do
    if now >= TOASTS.list[i].untilT then
      table.remove(TOASTS.list, i)
    else
      hasActionToast = true
    end
  end
  return hasTrackToast or hasActionToast
end, function(self)
  self.HideCursor = true
  self.LockPlayer = false
  ART.tick = ART.tick + 1; ART.loads = 0
  local io = imgui.GetIO()
  local now = os.clock()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  local ac = accent()

  local TW, TH = 360, 88
  local posMode = clamp(cfg.main.toastPos or 2, 1, 4)
  local tx, ty
  if posMode == 1 then tx, ty = (sw - TW) / 2, 18
  elseif posMode == 2 then tx, ty = sw - TW - 20, 18
  elseif posMode == 3 then tx, ty = 20, 18
  else tx, ty = sw - TW - 20, sh - TH - 96 end

  if (not cfg.main.mini) and S.cur ~= nil and now < S.toastUntil then
    GA = clamp((S.toastUntil - now) / 0.45, 0, 1) * clamp((now - S.toastStart) / 0.22, 0, 1)
    if GA > 0.01 then
      local slide = (1 - GA) * 24
      imgui.SetNextWindowSize(V2(TW, TH), imgui.Cond.Always)
      imgui.SetNextWindowPos(V2(tx, ty - slide), imgui.Cond.Always)
      imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
      local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
        imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoSavedSettings, imgui.WindowFlags.NoBackground)
      local f1 = pushFont('reg')
      if imgui.Begin('##MoonRadioToast', nil, flags) then
        local p = imgui.GetWindowPos()
        local dl = imgui.GetWindowDrawList()
        ui.updateBars(io.DeltaTime)
        ui.drawGlassFocal(dl, p.x, p.y, p.x + TW, p.y + TH, UI_R.CARD, ac, 0.92, true)

        ui.drawPlayerArt(dl, p.x + 40, p.y + 44, 26, getArtTexture(S.cur), ui.vinylAngle, ac, true)
        local title, artist = nowInfo()
        local fs0 = pushFont('small')
        if S.loading then
          ui.drawSpinner(dl, p.x + 83, p.y + 17, 4.5, U32(C.gold), 1.6)
          T(dl, p.x + 93, p.y + 9, U32(C.gold), 'Menyiapkan Stream YouTube Music...')
        elseif S.err and not S.playing then
          dl:AddCircleFilled(V2(p.x + 82, p.y + 17), 3.5, U32(C.red), 10)
          T(dl, p.x + 91, p.y + 9, U32(C.red), 'Gagal Memutar')
        else
          dl:AddCircleFilled(V2(p.x + 82, p.y + 17), 3.5, U32(S.live and C.red or ac), 10)
          T(dl, p.x + 91, p.y + 9, U32(ac), S.live and 'On Air Stream' or 'Sedang Diputar')
        end
        popFont(fs0)
        local fb = pushFont('bold')
        T(dl, p.x + 78, p.y + 27, U32(C.text), ellipsize(title, TW - 92, 'tt'))
        popFont(fb)
        local fs = pushFont('small')
        local tSubCol = S.loading and C.gold or ((not S.playing and S.err) and C.red or C.sub)
        T(dl, p.x + 78, p.y + 50, U32(tSubCol), ellipsize(artist, TW - 92, 'ta'))
        popFont(fs)

        if S.loading then
          ui.drawLoadingBar(dl, p.x + 78, p.y + 73, p.x + TW - 14, p.y + 77, C.gold)
        else
          local frac = (S.dur > 0) and clamp(S.pos / S.dur, 0, 1) or 1
          dl:AddRectFilled(V2(p.x + 78, p.y + 74), V2(p.x + TW - 14, p.y + 77), U32(C.panel2), 1.5, 15)
          dl:AddRectFilled(V2(p.x + 78, p.y + 74), V2(p.x + 78 + (TW - 92) * frac, p.y + 77), U32(ac), 1.5, 15)
        end
      end
      imgui.End()
      popFont(f1)
      imgui.PopStyleColor(1)
      ty = ty + TH + 10
    end
  end

  local item = TOASTS.list[#TOASTS.list]
  if item then
    GA = clamp((item.untilT - now) / 0.35, 0, 1) * clamp((now - item.startT) / 0.16, 0, 1)
    if GA > 0.01 then
      local AW, AH = 316, 58
      local ax = (posMode == 1) and ((sw - AW) / 2) or (posMode == 3 and 20 or (sw - AW - 20))
      imgui.SetNextWindowSize(V2(AW, AH), imgui.Cond.Always)
      imgui.SetNextWindowPos(V2(ax, ty), imgui.Cond.Always)
      imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
      local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
        imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoSavedSettings, imgui.WindowFlags.NoBackground)
      local f1 = pushFont('reg')
      if imgui.Begin('##MoonRadioActionToast', nil, flags) then
        local p = imgui.GetWindowPos()
        local dl = imgui.GetWindowDrawList()
        local col = (item.kind == 'err') and C.red or ac
        ui.drawGlassFocal(dl, p.x, p.y, p.x + AW, p.y + AH, UI_R.CARD, col, 0.92, true)
        dl:AddCircleFilled(V2(p.x + 24, p.y + AH / 2), 13, U32(col, 0.16), 18)
        ui.drawNote(dl, p.x + 24, p.y + AH / 2, 15, U32(col))
        local fb = pushFont('bold')
        T(dl, p.x + 46, p.y + 9, U32(C.text), ellipsize(item.title, AW - 58, 'att'))
        popFont(fb)
        local fs = pushFont('small')
        T(dl, p.x + 46, p.y + 32, U32(C.sub), ellipsize(item.sub, AW - 58, 'ats'))
        popFont(fs)
      end
      imgui.End()
      popFont(f1)
      imgui.PopStyleColor(1)
    end
  end
  GA = 1
end)
toastFrame.HideCursor = true
toastFrame.LockPlayer = false

-- ======================================================================
-- 4-MODE MINI PLAYER HUD + INTERACTIVE HOVER CONTROLS & UNIFIED HUD EDITOR
-- ======================================================================
MINI.miniMarquee = function(dl, x, y, maxw, col, text, el, fade, k)
  text = tostring(text or '')
  local sz = imgui.CalcTextSize(text)
  if sz.x <= maxw then T(dl, x, y, col, text); return end
  local gapw, speed, hold = 36 * k, 30 * k, 1.4
  local total = sz.x + gapw
  local period = total / speed + hold
  local ph = (el > 0) and (el % period) or 0
  local off = math.max(0, ph - hold) * speed
  local a, b = V2(x, y - 1), V2(x + maxw, y + sz.y + 1)
  dl:PushClipRect(a, b, true)
  T(dl, x - off, y, col, text)
  T(dl, x - off + total, y, col, text)
  dl:PopClipRect()
end

MINI.miniGamePaused = function()
  local ok, gp = pcall(function() return isGamePaused() end)
  return ok and gp or false
end

MINI.isCursorVisible = function()
  local ok, res = pcall(function()
    if type(sampIsCursorActive) == 'function' and sampIsCursorActive() then return true end
    if type(sampIsChatInputActive) == 'function' and (sampIsChatInputActive() or sampIsDialogActive()) then return true end
    return false
  end)
  return ok and res or false
end

MINI.miniWant = function()
  if not cfg.main.mini or window[0] or S.cur == nil then return false end
  if S.playing or S.loading then MINI.lastPlay = os.clock() end
  if cfg.main.miniHidePause and os.clock() - MINI.lastPlay > MINI.IDLE_HIDE then return false end
  if MINI.miniGamePaused() then return false end
  return true
end

local miniFrame
miniFrame = imgui.OnFrame(function()
  if window[0] then MINI.t = 0; MINI.want = false; MINI.edit = false; return false end
  local edit = MINI.edit
  local canInteract = edit or (cfg.main.miniInteractive and MINI.isCursorVisible())
  if miniFrame then
    miniFrame.HideCursor = not canInteract
    miniFrame.LockPlayer = edit and true or false
  end
  if edit then MINI.want = true; return true end
  MINI.want = MINI.miniWant()
  return MINI.want or MINI.t > 0.002
end, function(self)
  local edit = MINI.edit
  local canInteract = edit or (cfg.main.miniInteractive and MINI.isCursorVisible())
  self.HideCursor = not canInteract
  self.LockPlayer = edit and true or false
  ART.tick = ART.tick + 1; ART.loads = 0

  local io = imgui.GetIO()
  local dt = clamp(io.DeltaTime, 0, 0.1)
  local now = os.clock()

  local target = MINI.want and 1 or 0
  local d, step = target - MINI.t, dt * 3.4
  if d > step then MINI.t = MINI.t + step elseif d < -step then MINI.t = MINI.t - step else MINI.t = target end
  if MINI.t <= 0.002 then return end
  local e = 1 - (1 - MINI.t) ^ 3

  if MINI.lastStart ~= S.toastStart then
    MINI.lastStart = S.toastStart; MINI.t0 = now; MINI.flash = now
    MINI.sp = (S.dur > 0) and clamp(S.pos / S.dur, 0, 1) or 0
  end

  local style = clamp(math.floor(cfg.main.miniStyle or 1), 1, #MINI.STYLES)
  local k = MINI.SCALES[clamp(math.floor(cfg.main.miniScale or 2), 1, #MINI.SCALES)]
  local lyric = currentLyricText()
  local showMiniLyrics = cfg.main.miniLyrics and (lyric ~= nil) and (style ~= 4)

  local baseW = (style == 1) and 326 or (style == 2) and 336 or (style == 3) and 330 or 284
  local baseH = (style == 4) and 42 or (MINI.H + (showMiniLyrics and 20 or 0))
  local CW, CH, PAD = baseW * k, baseH * k, MINI.PAD
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y

  local fx, fy = cfg.main.miniFX or -1, cfg.main.miniFY or -1
  local bx, by, top
  if fx >= 0 and fy >= 0 then
    bx = fx * math.max(1, sw - CW)
    by = fy * math.max(1, sh - CH)
    top = (by + CH / 2) < sh / 2
  else
    local pos = clamp(math.floor(cfg.main.miniPos or 1), 1, #MINI.POS)
    if pos == 1 or pos == 6 then bx = (sw - CW) / 2
    elseif pos == 2 or pos == 5 then bx = sw - CW - MINI.MARGIN
    else bx = MINI.MARGIN end
    bx = bx + (cfg.main.miniX or 0)
    top = pos <= 3
    if top then by = MINI.MARGIN + (cfg.main.miniY or 0)
    else by = sh - CH - MINI.MARGIN - (cfg.main.miniY or 0) end
  end
  local slide = (1 - e) * (CH + MINI.MARGIN + 12)
  local cx, cy = bx, (top and (by - slide) or (by + slide))

  imgui.SetNextWindowSize(V2(CW + PAD * 2, CH + PAD * 2), imgui.Cond.Always)
  imgui.SetNextWindowPos(V2(cx - PAD, cy - PAD), imgui.Cond.Always)
  local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
    imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings, imgui.WindowFlags.NoBackground)
  if not canInteract then flags = bit.bor(flags, imgui.WindowFlags.NoInputs) end

  GA = clamp(MINI.t * 1.6, 0, 1)
  HUD_OPACITY = clamp((cfg.main.miniOpacity or 86) / 100, 0.25, 1)
  local f1 = pushFont('reg')

  if imgui.Begin('##MoonRadioMini', nil, flags) then
    pcall(imgui.SetWindowFontScale, k)
    local p = imgui.GetWindowPos()
    local dl = imgui.GetWindowDrawList()
    local ac = accent()
    local x0, y0 = p.x + PAD, p.y + PAD
    local x1, y1 = x0 + CW, y0 + CH
    ui.updateBars(dt, style == 1)

    local fl = clamp(1 - (now - MINI.flash) / 1.0, 0, 1)
    local title, artist = nowInfo()
    local subCol = U32(S.loading and C.gold or ((not S.playing and S.err) and C.red or C.sub))
    local frac = (S.dur > 0) and clamp(S.pos / S.dur, 0, 1) or 0
    MINI.sp = MINI.sp + (frac - MINI.sp) * clamp(dt * 10, 0, 1)

    local hoveredHud = canInteract and (not edit) and imgui.IsMouseHoveringRect(V2(x0, y0), V2(x1, y1))
    MINI.hoverT = clamp((MINI.hoverT or 0) + (hoveredHud and dt * 6 or -dt * 6), 0, 1)

    if style == 1 then
      -- STYLE 1: DYNAMIC ISLAND (FROSTED CAPSULE PILL)
      local R = CH / 2
      ui.drawGlassFocal(dl, x0, y0, x1, y1, R, ac, 0.94, true)
      if fl > 0.02 or edit then
        dl:AddRect(V2(x0, y0), V2(x1, y1), U32(ac, 0.25 + 0.55 * fl), R, 15, edit and 2.0 or 1.2)
      end

      local vr = (CH - 16 * k) / 2
      local vx, vy = x0 + 8 * k + vr, y0 + CH / 2
      ui.drawVinylDisc(dl, vx, vy, vr, getArtTexture(S.cur), ui.vinylAngle, ac)
      if S.loading then
        dl:AddCircleFilled(V2(vx, vy), vr, U32RGB(0, 0, 0, 0.62), 24)
        ui.drawSpinner(dl, vx, vy, vr * 0.55, U32(C.gold), 2.0)
      end

      local tx = vx + vr + 10 * k
      local maxw = (x1 - 48 * k) - tx
      local fade = U32(C.side, 0.94)
      local fb = pushFont('bold')
      MINI.miniMarquee(dl, tx, y0 + 7 * k, maxw, U32(C.text), title, now - MINI.t0, fade, k)
      popFont(fb)
      local fs = pushFont('small')
      MINI.miniMarquee(dl, tx, y0 + 27 * k, maxw, subCol, artist, now - MINI.t0 - 0.5, fade, k)
      if showMiniLyrics and lyric then
        ui.drawNote(dl, tx + 5 * k, y0 + 52 * k, 9 * k, U32(ac, 0.95))
        MINI.miniMarquee(dl, tx + 14 * k, y0 + 45 * k, maxw - 14 * k, U32(ac, 0.95), lyric, now - MINI.t0 - 0.9, fade, k)
      end
      popFont(fs)

      local ex, ey, EH = x1 - 40 * k, y0 + (CH - 24 * k) / 2, 24 * k
      local pick = { 3, 10, 19, 30 }
      for i, bi in ipairs(pick) do
        local v = bars[bi] or 0
        local bh = math.max(3 * k, v * EH)
        local bxx = ex + (i - 1) * 7 * k
        dl:AddRectFilled(V2(bxx, ey + (EH - bh) / 2), V2(bxx + 4.5 * k, ey + (EH + bh) / 2), U32(ac, 0.45 + 0.55 * v), 2 * k, 15)
      end

      local px0, px1, py = tx, x1 - 24 * k, y1 - 7 * k
      if S.loading then
        ui.drawLoadingBar(dl, px0, py, px1, py + 3 * k, C.gold)
      else
        dl:AddRectFilled(V2(px0, py), V2(px1, py + 3 * k), U32(C.panel2, 0.8), 1.5, 15)
        dl:AddRectFilled(V2(px0, py), V2(px0 + (px1 - px0) * MINI.sp, py + 3 * k), U32(ac), 1.5, 15)
      end

    elseif style == 2 then
      -- STYLE 2: GLASS DECK (ARCHITECTURAL FROSTED CARD)
      local R = UI_R.CARD * k
      ui.drawGlassFocal(dl, x0, y0, x1, y1, R, ac, 0.94, true)

      local AS = 48 * k
      local ax, ay = x0 + 10 * k, y0 + (CH - AS) / 2
      ui.drawArt(dl, ax, ay, AS, UI_R.CTRL * k, getArtTexture(S.cur))
      if S.loading then
        dl:AddRectFilled(V2(ax, ay), V2(ax + AS, ay + AS), U32RGB(0, 0, 0, 0.62), UI_R.CTRL * k, 15)
        ui.drawSpinner(dl, ax + AS / 2, ay + AS / 2, AS * 0.28, U32(C.gold), 2.0)
      end

      local tx = ax + AS + 12 * k
      local maxw = (x1 - 14 * k) - tx
      local fade = U32(C.side, 0.94)
      local fb = pushFont('bold')
      MINI.miniMarquee(dl, tx, y0 + 6 * k, maxw - 48 * k, U32(C.text), title, now - MINI.t0, fade, k)
      popFont(fb)
      local fs = pushFont('small')
      if S.loading then
        local el = math.max(0, now - (S.loadAt or now))
        T(dl, x1 - 52 * k, y0 + 8 * k, U32(C.gold), string.format('%.1fs', el))
      else
        T(dl, x1 - 52 * k, y0 + 8 * k, U32(ac), S.live and 'LIVE' or fmtTime(S.pos))
      end
      MINI.miniMarquee(dl, tx, y0 + 26 * k, maxw, subCol, artist, now - MINI.t0 - 0.5, fade, k)
      if showMiniLyrics and lyric then
        ui.drawNote(dl, tx + 5 * k, y0 + 51 * k, 9 * k, U32(ac, 0.95))
        MINI.miniMarquee(dl, tx + 14 * k, y0 + 44 * k, maxw - 14 * k, U32(C.text, 0.92), lyric, now - MINI.t0 - 0.9, fade, k)
      end
      popFont(fs)

      local px0, px1, py = tx, x1 - 12 * k, y1 - 9 * k
      if S.loading then
        ui.drawLoadingBar(dl, px0, py, px1, py + 3.5 * k, C.gold)
      else
        dl:AddRectFilled(V2(px0, py), V2(px1, py + 3.5 * k), U32(C.panel2, 0.9), 2, 15)
        dl:AddRectFilled(V2(px0, py), V2(px0 + (px1 - px0) * MINI.sp, py + 3.5 * k), U32(ac), 2, 15)
      end

    elseif style == 3 then
      -- STYLE 3: VINYL TURNTABLE (PROTRUDING SPINNING DISC)
      local wingY0 = y0 + 6 * k
      local wingY1 = y1 - 4 * k
      ui.drawGlassFocal(dl, x0 + 24 * k, wingY0, x1, wingY1, 14 * k, ac, 0.94, true)

      local vr = (CH - 4 * k) / 2
      local vx, vy = x0 + vr + 2 * k, y0 + CH / 2
      ui.drawVinylDisc(dl, vx, vy, vr, getArtTexture(S.cur), ui.vinylAngle, ac)
      if S.loading then
        dl:AddCircleFilled(V2(vx, vy), vr, U32RGB(0, 0, 0, 0.62), 24)
        ui.drawSpinner(dl, vx, vy, vr * 0.48, U32(C.gold), 2.2)
      end

      local tx = vx + vr + 10 * k
      local maxw = (x1 - 14 * k) - tx
      local fade = U32(C.side, 0.94)
      local fb = pushFont('bold')
      MINI.miniMarquee(dl, tx, wingY0 + 6 * k, maxw, U32(C.text), title, now - MINI.t0, fade, k)
      popFont(fb)
      local fs = pushFont('small')
      MINI.miniMarquee(dl, tx, wingY0 + 25 * k, maxw, subCol, artist, now - MINI.t0 - 0.5, fade, k)
      if showMiniLyrics and lyric then
        MINI.miniMarquee(dl, tx, wingY0 + 42 * k, maxw, U32(ac, 0.95), lyric, now - MINI.t0 - 0.9, fade, k)
      end
      popFont(fs)

      local px0, px1, py = tx, x1 - 14 * k, wingY1 - 8 * k
      if S.loading then
        ui.drawLoadingBar(dl, px0, py, px1, py + 3 * k, C.gold)
      else
        dl:AddRectFilled(V2(px0, py), V2(px1, py + 3 * k), U32(C.panel2), 1.5, 15)
        dl:AddRectFilled(V2(px0, py), V2(px0 + (px1 - px0) * MINI.sp, py + 3 * k), U32(ac), 1.5, 15)
      end

    else
      -- STYLE 4: MINIMAL RIBBON
      local R = CH / 2
      ui.drawGlassFocal(dl, x0, y0, x1, y1, R, ac, 0.92, true)
      ui.drawEq(dl, x0 + 18 * k, y0 + CH / 2, U32(ac))
      local tx = x0 + 34 * k
      local maxw = (x1 - 54 * k) - tx
      local fade = U32(C.side, 0.92)
      local fs = pushFont('small')
      MINI.miniMarquee(dl, tx, y0 + (CH - 16 * k) / 2, maxw, U32(C.text), title .. '  ·  ' .. artist, now - MINI.t0, fade, k)
      T(dl, x1 - 46 * k, y0 + (CH - 16 * k) / 2, U32(ac), S.live and 'LIVE' or fmtTime(S.pos))
      popFont(fs)
      dl:AddRectFilled(V2(x0 + R, y1 - 2.5 * k), V2(x0 + R + (CW - 2 * R) * MINI.sp, y1 - 1 * k), U32(ac), 1, 15)
    end

    -- Interactive Free Control Overlay on Mini Player (when cursor is active in-game)
    if (MINI.hoverT or 0) > 0.05 and not edit then
      local ha = MINI.hoverT
      local r = (style == 1 or style == 4) and (CH / 2) or (UI_R.CARD * k)
      dl:AddRectFilled(V2(x0, y0), V2(x1, y1), U32(C.bg, 0.82 * ha), r, 15)

      if hoveredHud and math.abs(io.MouseWheel or 0) > 0.01 then
        setVolume(cfg.main.volume + (io.MouseWheel > 0 and 0.03 or -0.03))
        flash('Volume: ' .. math.floor(cfg.main.volume * 100 + 0.5) .. '%', false, 'Scroll pada Mini HUD')
      end
      if hoveredHud and imgui.IsMouseClicked(1) then
        window[0] = true
      end

      local midY = PAD + CH / 2
      local mcx = PAD + CW / 2
      if ui.iconBtn('##mh_prev', mcx - 56 * k, midY, 14 * k, 'prev', false, 10 * k) then prevTrack() end
      if ui.iconBtn('##mh_play', mcx - 18 * k, midY, 16 * k, S.playing and 'pause' or 'play', true, 11 * k) then togglePlay() end
      if ui.iconBtn('##mh_next', mcx + 20 * k, midY, 14 * k, 'next', false, 10 * k) then nextTrack(false) end
      if ui.iconBtn('##mh_open', mcx + 58 * k, midY, 14 * k, 'expand', false, 9.5 * k) then window[0] = true end
    end

    if edit then
      imgui.SetCursorPos(V2(PAD, PAD))
      imgui.InvisibleButton('##minidragarea', V2(CW, CH))
      if imgui.IsItemActive() then
        local nx = clamp(bx + io.MouseDelta.x, 0, math.max(1, sw - CW))
        local ny = clamp(by + io.MouseDelta.y, 0, math.max(1, sh - CH))
        if math.abs(nx + CW / 2 - sw / 2) < 10 then
          nx = (sw - CW) / 2
          dl:AddLine(V2(sw / 2, 0), V2(sw / 2, sh), U32(ac, 0.45), 1)
        end
        cfg.main.miniFX = nx / math.max(1, sw - CW)
        cfg.main.miniFY = ny / math.max(1, sh - CH)
        cfgDirty = true
      end
    end
  end
  imgui.End()
  popFont(f1)
  GA = 1
  HUD_OPACITY = 1

  -- Unified Free HUD Studio Editor (Controls both Mini Player & Karaoke Overlay!)
  if edit then
    local py = top and sh * 0.68 or sh * 0.30
    imgui.SetNextWindowPos(V2(sw / 2, py), imgui.Cond.Always, V2(0.5, 0.5))
    local pf = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoSavedSettings, imgui.WindowFlags.NoMove)
    if imgui.Begin('##MoonRadioMiniEdit', nil, pf) then
      imgui.TextColored(V4(accent()), 'EDITOR TATA LETAK HUD BEBAS')
      imgui.Text('Seret Mini Player HUD atau Kotak Karaoke ke posisi mana pun di layar.')
      imgui.Separator()
      if imgui.Button('Selesai & Simpan') then MINI.edit = false; saveCfg() end
      imgui.SameLine()
      if imgui.Button('Gaya HUD: ' .. (MINI.STYLES[cfg.main.miniStyle or 1] or MINI.STYLES[1])) then
        cfg.main.miniStyle = ((cfg.main.miniStyle or 1) % #MINI.STYLES) + 1; cfgDirty = true
      end
      imgui.SameLine()
      if imgui.Button('Ukuran HUD: ' .. (MINI.SNAMES[cfg.main.miniScale] or MINI.SNAMES[2])) then
        cfg.main.miniScale = (cfg.main.miniScale % #MINI.SCALES) + 1; cfgDirty = true
      end
      imgui.SameLine()
      if imgui.Button('Ukuran Karaoke: ' .. (MINI.KSNAMES[cfg.main.karaokeScale or 2] or 'Normal')) then
        cfg.main.karaoke = true
        cfg.main.karaokeScale = ((cfg.main.karaokeScale or 2) % #MINI.KSCALES) + 1; cfgDirty = true
      end
      imgui.SameLine()
      if imgui.Button('Reset Posisi Default') then
        cfg.main.miniPos = (cfg.main.miniPos % #MINI.POS) + 1
        cfg.main.miniFX, cfg.main.miniFY = -1, -1
        cfg.main.karaokeFX, cfg.main.karaokeFY = -1, -1
        cfgDirty = true
      end
    end
    imgui.End()
  end
end)
miniFrame.HideCursor = true
miniFrame.LockPlayer = false

-- ======================================================================
-- FLOATING IN-GAME KARAOKE OVERLAY (WITH FREE DRAG & SCALE SUPPORT)
-- ======================================================================
local karaokeFrame
karaokeFrame = imgui.OnFrame(function()
  if karaokeFrame then
    karaokeFrame.HideCursor = not MINI.edit
    karaokeFrame.LockPlayer = MINI.edit and true or false
  end
  if window[0] then return false end
  if MINI.edit then return true end
  if not cfg.main.karaoke or not S.cur or not S.playing then return false end
  if MINI.miniGamePaused() then return false end
  return currentLyricText() ~= nil
end, function(self)
  local edit = MINI.edit
  self.HideCursor = not edit
  self.LockPlayer = edit and true or false
  local io = imgui.GetIO()
  local sw, sh = io.DisplaySize.x, io.DisplaySize.y
  local curLine, nextLine = currentLyricText()
  if not curLine and not edit then return end
  if edit and not curLine then
    curLine = 'Pratinjau Posisi Karaoke Bebas (Seret Kotak Ini)'
    nextLine = 'Baris lirik berikutnya akan tampil di sini saat lagu diputar'
  end

  local ks = MINI.KSCALES[clamp(cfg.main.karaokeScale or 2, 1, #MINI.KSCALES)] or 1.0
  local KW = math.min(math.floor(660 * ks), sw - 60)
  local KH = math.floor(66 * ks)
  local kfx, kfy = cfg.main.karaokeFX or -1, cfg.main.karaokeFY or -1
  local kx, ky
  if kfx >= 0 and kfy >= 0 then
    kx = kfx * math.max(1, sw - KW)
    ky = kfy * math.max(1, sh - KH)
  else
    kx = (sw - KW) / 2
    ky = (cfg.main.karaokePos == 2) and 86 or (sh - KH - 36)
  end

  imgui.SetNextWindowSize(V2(KW, KH), imgui.Cond.Always)
  imgui.SetNextWindowPos(V2(kx, ky), imgui.Cond.Always)
  local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
    imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings, imgui.WindowFlags.NoBackground)
  if not edit then flags = bit.bor(flags, imgui.WindowFlags.NoInputs) end

  local f1 = pushFont('reg')
  if imgui.Begin('##MoonRadioKaraoke', nil, flags) then
    pcall(imgui.SetWindowFontScale, ks)
    local p = imgui.GetWindowPos()
    local dl = imgui.GetWindowDrawList()
    local ac = accent()
    local prog = edit and 0.55 or currentLyricProgress()

    ui.drawGlassFocal(dl, p.x, p.y, p.x + KW, p.y + KH, UI_R.WIN, ac, 0.84, true)
    if edit then
      dl:AddRect(p, V2(p.x + KW, p.y + KH), U32(ac, 0.75), UI_R.WIN, 15, 1.8)
    end

    local fb = pushFont('bold')
    local l1 = ellipsize(curLine, KW - 56, 'kl1')
    local sz1 = imgui.CalcTextSize(l1)
    local tx1 = p.x + (KW - sz1.x) / 2 + 8
    local ty1 = p.y + 10 * ks
    ui.drawNote(dl, tx1 - 14 * ks, ty1 + 9 * ks, 13 * ks, U32(ac, 0.95))
    T(dl, tx1, ty1, U32(C.text, 0.42), l1)
    dl:PushClipRect(V2(tx1, ty1 - 2), V2(tx1 + sz1.x * prog, ty1 + sz1.y + 2), true)
    T(dl, tx1, ty1, U32(ac, 1.0), l1)
    dl:PopClipRect()
    popFont(fb)

    local fs = pushFont('small')
    local l2 = ellipsize(nextLine or (S.cur and S.cur.title or ''), KW - 40, 'kl2')
    local sz2 = imgui.CalcTextSize(l2)
    T(dl, p.x + (KW - sz2.x) / 2, p.y + 38 * ks, U32(C.sub, 0.88), l2)
    popFont(fs)

    if edit then
      imgui.SetCursorPos(V2(0, 0))
      imgui.InvisibleButton('##kardragarea', V2(KW, KH))
      if imgui.IsItemActive() then
        local nx = clamp(kx + io.MouseDelta.x, 0, math.max(1, sw - KW))
        local ny = clamp(ky + io.MouseDelta.y, 0, math.max(1, sh - KH))
        if math.abs(nx + KW / 2 - sw / 2) < 10 then nx = (sw - KW) / 2 end
        cfg.main.karaokeFX = nx / math.max(1, sw - KW)
        cfg.main.karaokeFY = ny / math.max(1, sh - KH)
        cfg.main.karaoke = true
        cfgDirty = true
      end
    end
  end
  imgui.End()
  popFont(f1)
end)
karaokeFrame.HideCursor = true
karaokeFrame.LockPlayer = false

-- ======================================================================
-- MAIN LOOP & SAMP CHAT COMMANDS (OPTIMIZED KEY & TICK DISPATCH)
-- ======================================================================
local function chat(msg)
  if type(sampAddChatMessage) == 'function' then
    sampAddChatMessage('{38D1F8}[MoonRadio] {FFFFFF}' .. msg, -1)
  end
end

local function favChat()
  if not S.cur or not S.cur.path then chat('Tidak ada lagu lokal yang sedang diputar'); return end
  chat(toggleFav(S.cur) and 'Ditambahkan ke Favorit' or 'Dihapus dari Favorit')
end

function main()
  if type(isSampAvailable) == 'function' then
    while not isSampAvailable() do wait(100) end
  end
  loadBookmarks()
  loadVibeOverrides()
  loadStations()
  loadPlaylists()
  loadPlugins()
  startScan()

  if type(sampRegisterChatCommand) == 'function' then
    sampRegisterChatCommand('radio', function() window[0] = not window[0] end)
    sampRegisterChatCommand('rplay', function(arg)
      local q = trim(tostring(arg or ''))
      if q == '' then
        chat('Pemakaian: /rplay [judul lagu / artis] — langsung streaming dari YouTube Music!')
        return
      end
      ffi.fill(ui.search, ffi.sizeof(ui.search))
      ffi.copy(ui.search, q, math.min(#q, ffi.sizeof(ui.search) - 1))
      ui.searchStr = q:lower()
      YT.requestSearch(q, 'playfirst', 10)
      chat('Mencari & memutar dari YouTube Music: ' .. q)
    end)
    sampRegisterChatCommand('ryt', function(arg)
      local q = trim(tostring(arg or ''))
      if q == '' then
        chat('Pemakaian: /ryt [judul lagu / artis] — langsung streaming dari YouTube Music!')
        return
      end
      ffi.fill(ui.search, ffi.sizeof(ui.search))
      ffi.copy(ui.search, q, math.min(#q, ffi.sizeof(ui.search) - 1))
      ui.searchStr = q:lower()
      YT.requestSearch(q, 'playfirst', 10)
      chat('Mencari & memutar dari YouTube Music: ' .. q)
    end)
    sampRegisterChatCommand('rcari', function(arg)
      local q = trim(tostring(arg or ''))
      if q == '' then
        chat('Pemakaian: /rcari [judul lagu / artis]')
        return
      end
      ffi.fill(ui.search, ffi.sizeof(ui.search))
      ffi.copy(ui.search, q, math.min(#q, ffi.sizeof(ui.search) - 1))
      ui.searchStr = q:lower()
      cfg.main.compact = false
      ui.tab = 3
      window[0] = true
      YT.requestSearch(q, 'search', 20)
      chat('Mencari di YouTube Music: ' .. q)
    end)
    sampRegisterChatCommand('rcompact', function()
      cfg.main.compact = not cfg.main.compact; cfgDirty = true
      window[0] = true
      chat('Mode Compact Glass Deck: ' .. (cfg.main.compact and 'AKTIF' or 'MATI'))
    end)
    sampRegisterChatCommand('rcover', function()
      cfg.main.playerArtStyle = ((cfg.main.playerArtStyle or 1) % #PLAYER_ART_STYLES) + 1
      cfgDirty = true
      local nm = PLAYER_ART_STYLES[cfg.main.playerArtStyle]
      flash('Gaya Gambar Player: ' .. nm)
      chat('Gaya Gambar Player diubah ke: ' .. nm)
    end)
    sampRegisterChatCommand('rglass', function(arg)
      local g = tonumber(arg)
      if g then
        cfg.main.glassAlpha = clamp(math.floor(g + 0.5), 55, 98); cfgDirty = true
        flash('Glass Opacity: ' .. cfg.main.glassAlpha .. '%')
        chat('Tingkat keburaman kaca diatur ke ' .. cfg.main.glassAlpha .. '%')
      else
        chat('Pemakaian: /rglass [55-98] (saat ini: ' .. (cfg.main.glassAlpha or 88) .. '%)')
      end
    end)
    sampRegisterChatCommand('rnext', function() S.skipOnErr = isTrackList(S.listName); nextTrack(false) end)
    sampRegisterChatCommand('rprev', function() prevTrack() end)
    sampRegisterChatCommand('rpause', function() togglePlay() end)
    sampRegisterChatCommand('rmix', function()
      local all = FP.all()
      if #all == 0 then chat('Belum ada playlist'); return end
      playMix(all, true, 'Campur Semua')
      chat('Mengacak semua playlist')
    end)
    sampRegisterChatCommand('rall', function()
      if #lib == 0 then chat('Library masih kosong'); return end
      local c = {}
      for i, t in ipairs(lib) do c[i] = t end
      SMART.shuffleList(c, S.cur)
      playQueue(c, cfg.main.smartShuffle and 'Smart Shuffle Semua' or 'Shuffle Semua', 1)
      chat('Mengacak seluruh koleksi lagu (' .. #lib .. ' lagu' .. (cfg.main.smartShuffle and ', mode Smart Shuffle' or '') .. ')')
    end)
    sampRegisterChatCommand('rsmart', function()
      cfg.main.smartShuffle = not cfg.main.smartShuffle
      S.smartBag = nil
      cfgDirty = true
      local st = cfg.main.smartShuffle and 'AKTIF (Anti-Tabrakan Mood)' or 'MATI (Acak Biasa)'
      flash('Smart Shuffle: ' .. st)
      chat('Smart Shuffle Pintar: ' .. st)
    end)
    sampRegisterChatCommand('rautomix', function()
      cfg.main.autoMix = not cfg.main.autoMix
      cfgDirty = true
      local st = cfg.main.autoMix and 'AKTIF' or 'MATI'
      flash('Auto Smart Mix: ' .. st)
      chat('Auto Smart Mix saat pilih lagu: ' .. st)
    end)
    sampRegisterChatCommand('rfav', function() favChat() end)
    sampRegisterChatCommand('rsleep', function(arg)
      local m = tonumber(arg)
      if not m or m <= 0 then
        XT.sleepAt = 0; XT.sleepI = 1; applyVolume(true)
        chat('Sleep timer dimatikan (pakai: /rsleep [menit])')
      else
        m = clamp(m, 1, 600)
        XT.sleepAt = os.clock() + m * 60
        chat('Musik berhenti otomatis dalam ' .. math.floor(m) .. ' menit')
      end
    end)
    sampRegisterChatCommand('rminipos', function()
      cfg.main.mini = true; cfgDirty = true
      MINI.edit = true; window[0] = false
    end)
    sampRegisterChatCommand('rministyle', function()
      cfg.main.miniStyle = ((cfg.main.miniStyle or 1) % #MINI.STYLES) + 1
      cfgDirty = true
      local nm = MINI.STYLES[cfg.main.miniStyle]
      flash('Gaya Mini Player: ' .. nm)
      chat('Gaya Mini Player diubah ke: ' .. nm)
    end)
    sampRegisterChatCommand('rlyrics', function()
      cfg.main.compact = false
      ui.tab = 6; window[0] = true
    end)
    sampRegisterChatCommand('rkaraoke', function()
      cfg.main.karaoke = not cfg.main.karaoke; cfgDirty = true
      local st = cfg.main.karaoke and 'AKTIF' or 'MATI'
      flash('Floating Karaoke HUD: ' .. st)
      chat('Floating Karaoke HUD: ' .. st)
    end)
    sampRegisterChatCommand('rmini', function()
      cfg.main.mini = not cfg.main.mini; cfgDirty = true
      chat('Mini player: ' .. (cfg.main.mini and 'ON' or 'OFF'))
    end)
    sampRegisterChatCommand('rvol', function(arg)
      local v = tonumber(arg)
      if v then
        v = clamp(v, 0, 100); setVolume(v / 100)
        flash('Volume: ' .. math.floor(v) .. '%')
        chat('Volume: ' .. math.floor(v) .. '%')
      else
        chat('Pemakaian: /rvol [0-100]')
      end
    end)
    sampRegisterChatCommand('rfx', function(arg)
      local idx = tonumber(arg)
      if idx and idx >= 0 and idx <= 7 then
        selectFxPreset(idx == 0 and 1 or idx)
        chat('Audio FX: ' .. FX_PRESETS[cfg.main.fxPreset].name)
      else
        local nxt = ((cfg.main.fxPreset or 1) % 7) + 1
        selectFxPreset(nxt)
        chat('Audio FX: ' .. FX_PRESETS[cfg.main.fxPreset].name .. ' (pakai /rfx 1-7)')
      end
    end)
    sampRegisterChatCommand('rspeed', function(arg)
      local sp = tonumber(arg)
      if sp then
        cfg.main.speed = clamp(math.floor(sp + 0.5), 50, 150)
        cfg.main.fxPreset = 8; cfgDirty = true; applyAudioFX()
        flash('Kecepatan Lagu: ' .. cfg.main.speed .. '%')
        chat('Kecepatan Lagu: ' .. cfg.main.speed .. '%')
      else
        chat('Pemakaian: /rspeed [50-150] (100 = normal)')
      end
    end)
  end

  local hasSampChatCheck = (type(sampIsChatInputActive) == 'function')
  local lastSave, lastUpd = os.clock(), 0

  while true do
    wait(0)
    local chatBusy = hasSampChatCheck and (sampIsChatInputActive() or sampIsDialogActive()) or false

    if not chatBusy and wasKeyPressed(cfg.main.key) then
      window[0] = not window[0]
    end

    if ui.bind then
      if wasKeyPressed(27) then ui.bind = nil
      elseif wasKeyPressed(8) then cfg.main[ui.bind] = 0; cfgDirty = true; ui.bind = nil
      else
        for kc = 7, 254 do
          if kc ~= 16 and kc ~= 17 and kc ~= 18 and kc ~= cfg.main.key and wasKeyPressed(kc) then
            cfg.main[ui.bind] = kc; cfgDirty = true; ui.bind = nil
            break
          end
        end
      end
    elseif not chatBusy and not ui.wantText then
      local c = cfg.main
      if c.keyNext > 0 and wasKeyPressed(c.keyNext) then S.skipOnErr = isTrackList(S.listName); nextTrack(false) end
      if c.keyPrev > 0 and wasKeyPressed(c.keyPrev) then prevTrack() end
      if c.keyPause > 0 and wasKeyPressed(c.keyPause) then togglePlay() end
      if c.keyFav > 0 and wasKeyPressed(c.keyFav) then favChat() end
      if (c.keyCompact or 0) > 0 and wasKeyPressed(c.keyCompact) then
        c.compact = not c.compact; cfgDirty = true
        window[0] = true
        flash('Mode Compact: ' .. (c.compact and 'AKTIF' or 'MATI'))
      end
      if (c.keyVolUp or 0) > 0 and wasKeyPressed(c.keyVolUp) then
        setVolume(c.volume + 0.05)
        flash('Volume: ' .. math.floor(c.volume * 100 + 0.5) .. '%')
      end
      if (c.keyVolDn or 0) > 0 and wasKeyPressed(c.keyVolDn) then
        setVolume(c.volume - 0.05)
        flash('Volume: ' .. math.floor(c.volume * 100 + 0.5) .. '%')
      end
      if (c.keyKaraoke or 0) > 0 and wasKeyPressed(c.keyKaraoke) then
        c.karaoke = not c.karaoke; cfgDirty = true
        flash('Floating Karaoke HUD: ' .. (c.karaoke and 'AKTIF' or 'MATI'))
      end
    end

    local now = os.clock()
    if XT.sleepAt > 0 then
      local rem = XT.sleepAt - now
      if rem <= 0 then
        XT.sleepAt = 0; XT.sleepI = 1
        if S.playing then togglePlay() end
        applyVolume(true)
        chat('Sleep timer selesai, musik dihentikan')
      elseif rem < 15 and S.handle ~= 0 and not S.muted then
        applyVolume(false)
      end
    end

    if not window[0] then ui.wasOpen = false; ui.wantText = false end
    scan.budget = window[0] and 0.004 or 0.0018
    if window[0] or now < S.toastUntil or now - lastUpd > 0.08 then updatePlayer(); lastUpd = now end
    if scan.running then stepScan() end
    if cfgDirty and now - lastSave > 15 then saveCfg(); lastSave = now end
  end
end

function onScriptTerminate(scr, quit)
  if scr == thisScript() then
    freeHandle()
    saveCfg()
  end
end
