# -*- coding: utf-8 -*-
"""A2R PC — برنامج صغير على الكمبيوتر (ويندوز) علشان تطبيق A2R Home يتحكم فيه من الموبايل.

- بيظهر شباك فيه عنوان الكمبيوتر + كود ربط من 6 أرقام.
- الموبايل بيلاقيه لوحده على نفس الشبكة (UDP 47801) ويكلّمه على HTTP 47800.
- أي أمر لازم يكون معاه التوكن اللي اتاخد بالكود. 5 أكواد غلط = قفل دقيقة.
- بيقبل بس أجهزة من الشبكة الداخلية (192.168.x / 10.x / 172.16-31.x).
- الملفات اللي جاية من الموبايل بتتحفظ في Downloads\\A2R.

مكتبات: stdlib + mss + Pillow (الاتنين بيتجمعوا جوه الـ exe).
"""
import io
import ipaddress
import json
import os
import queue
import re
import secrets
import socket
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse, quote

VERSION = "1.1"
HTTP_PORT = 47800
UDP_PORT = 47801
IS_WIN = sys.platform == "win32"
MAX_UPLOAD = 4 * 1024 * 1024 * 1024  # 4 جيجا

# ---------------------------------------------------------------- منطق صافي (عليه اختبارات)


def is_lan(ip):
    """بنقبل بس الشبكة الداخلية + الجهاز نفسه."""
    try:
        a = ipaddress.ip_address(ip.split("%")[0])
        if a.version == 6 and a.ipv4_mapped:
            a = a.ipv4_mapped
        return a.is_private or a.is_loopback or a.is_link_local
    except ValueError:
        return False


_BAD = re.compile(r'[<>:"/\\|?*\x00-\x1f]')
_RESERVED = {"CON", "PRN", "AUX", "NUL"} | {"COM%d" % i for i in range(1, 10)} | {"LPT%d" % i for i in range(1, 10)}


def safe_name(name):
    """اسم ملف آمن على ويندوز (من غير مسارات)."""
    name = (name or "").replace("\\", "/").split("/")[-1]
    name = _BAD.sub("_", name).strip(" .")
    if not name:
        name = "file"
    stem = name.split(".")[0].upper()
    if stem in _RESERVED:
        name = "_" + name
    return name[:180]


def unique_path(folder, name):
    """لو الاسم موجود: name (1).ext ، name (2).ext ..."""
    p = os.path.join(folder, name)
    if not os.path.exists(p):
        return p
    stem, ext = os.path.splitext(name)
    i = 1
    while True:
        p = os.path.join(folder, "%s (%d)%s" % (stem, i, ext))
        if not os.path.exists(p):
            return p
        i += 1


def inside(base, path):
    """المسار جوه فولدر المستخدم؟ (علشان محدش يقرا ملفات النظام)"""
    try:
        b = os.path.realpath(base)
        p = os.path.realpath(path)
        return os.path.commonpath([os.path.normcase(b), os.path.normcase(p)]) == os.path.normcase(b)
    except ValueError:
        return False


class Pairing:
    """كود الربط + القفل بعد 5 محاولات غلط."""

    def __init__(self, tokens=None, now=time.time, max_bad=5, lock_s=60):
        self.now = now
        self.max_bad = max_bad
        self.lock_s = lock_s
        self.tokens = dict(tokens or {})  # token -> اسم الجهاز
        self.bad = 0
        self.locked_until = 0.0
        self.lock = threading.Lock()
        self.new_code()

    def new_code(self):
        self.code = "%06d" % secrets.randbelow(1000000)
        return self.code

    def locked(self):
        return self.now() < self.locked_until

    def pair(self, code, device):
        """بيرجع (token, error)"""
        with self.lock:
            if self.locked():
                return None, "locked:%d" % int(self.locked_until - self.now() + 1)
            if not secrets.compare_digest(str(code).strip(), self.code):
                self.bad += 1
                if self.bad >= self.max_bad:
                    self.bad = 0
                    self.locked_until = self.now() + self.lock_s
                    self.new_code()
                    return None, "locked:%d" % self.lock_s
                return None, "bad_code"
            self.bad = 0
            t = secrets.token_hex(24)
            self.tokens[t] = (device or "phone")[:60]
            self.new_code()  # كل ربط بكود جديد
            return t, None

    def ok(self, token):
        if not token:
            return False
        with self.lock:
            return any(secrets.compare_digest(token, t) for t in self.tokens)

    def forget_all(self):
        with self.lock:
            self.tokens.clear()


DISCOVER_MAGIC = b"A2R-PC?"


def discovery_reply(name, port=HTTP_PORT):
    return json.dumps({"a2r": "pc", "name": name, "port": port, "v": VERSION}).encode("utf-8")


def parse_input(d):
    """يتأكد من شكل أمر الماوس/الكيبورد قبل ما يتنفّذ. بيرجع dict نضيف أو يرمي ValueError."""
    if not isinstance(d, dict):
        raise ValueError("not an object")
    t = d.get("t")
    num = lambda k, lo, hi, dv=0: max(lo, min(hi, float(d.get(k, dv))))
    if t == "move":
        return {"t": t, "dx": int(num("dx", -5000, 5000)), "dy": int(num("dy", -5000, 5000))}
    if t == "abs":
        return {"t": t, "x": num("x", 0, 1), "y": num("y", 0, 1)}
    if t in ("click", "down", "up"):
        b = d.get("b", "left")
        if b not in ("left", "right", "middle"):
            raise ValueError("button")
        return {"t": t, "b": b, "n": int(num("n", 1, 3, 1))}
    if t == "scroll":
        return {"t": t, "dy": int(num("dy", -50, 50)), "dx": int(num("dx", -50, 50))}
    if t == "text":
        s = str(d.get("s", ""))[:2000]
        return {"t": t, "s": s}
    if t == "key":
        k = str(d.get("k", "")).lower()
        if k not in VK and not (len(k) == 1 and k.isalnum()):
            raise ValueError("key")
        mods = [m for m in d.get("mods", []) if m in ("ctrl", "alt", "shift", "win")]
        return {"t": t, "k": k, "mods": mods}
    if t == "media":
        k = str(d.get("k", ""))
        if k not in MEDIA:
            raise ValueError("media")
        return {"t": t, "k": k}
    raise ValueError("type")


VK = {
    "enter": 0x0D, "backspace": 0x08, "tab": 0x09, "esc": 0x1B, "space": 0x20, "delete": 0x2E,
    "left": 0x25, "up": 0x26, "right": 0x27, "down": 0x28, "home": 0x24, "end": 0x23,
    "pageup": 0x21, "pagedown": 0x22, "win": 0x5B, "ctrl": 0x11, "alt": 0x12, "shift": 0x10,
    "printscreen": 0x2C, "insert": 0x2D,
    **{"f%d" % i: 0x6F + i for i in range(1, 13)},
}
MEDIA = {"play": 0xB3, "next": 0xB0, "prev": 0xB1, "stop": 0xB2, "volup": 0xAF, "voldown": 0xAE, "mute": 0xAD}
EXTENDED = {0x25, 0x26, 0x27, 0x28, 0x24, 0x23, 0x21, 0x22, 0x2E, 0x2D, 0x5B} | set(MEDIA.values())


def list_dir(path):
    out = []
    try:
        with os.scandir(path) as it:
            for e in it:
                if e.name.startswith(".") or e.name.lower() in ("desktop.ini", "ntuser.dat"):
                    continue
                try:
                    st = e.stat()
                    out.append({"n": e.name, "d": e.is_dir(), "s": 0 if e.is_dir() else st.st_size, "m": int(st.st_mtime)})
                except OSError:
                    pass
    except OSError:
        pass
    out.sort(key=lambda x: (not x["d"], x["n"].lower()))
    return out


# ---------------------------------------------------------------- ويندوز (ماوس/كيبورد/شاشة)

# ---- v1.1: لينك، حافظة، مؤقت إطفاء، معلومات الجهاز ----


def validate_open_url(u):
    """بنفتح بس http/https — من غير أوامر أو ملفات."""
    if not isinstance(u, str) or not (1 <= len(u) <= 2000):
        raise ValueError("bad_url")
    if re.search(r"[\s\x00-\x1f\"<>^`|]", u):
        raise ValueError("bad_url")
    pu = urlparse(u)
    if pu.scheme not in ("http", "https") or not pu.netloc:
        raise ValueError("only_http")
    return u


def clamp_minutes(m):
    m = int(m)
    if not (1 <= m <= 1440):
        raise ValueError("minutes")
    return m


def parse_getmac(out):
    """من getmac /fo csv /nh → قايمة MAC (AA:BB:..) للكروت الحقيقية."""
    macs = []
    for line in out.splitlines():
        m = re.search(r"([0-9A-Fa-f]{2}(?:-[0-9A-Fa-f]{2}){5})", line)
        if m:
            mac = m.group(1).replace("-", ":").upper()
            if mac not in macs and mac != "00:00:00:00:00:00":
                macs.append(mac)
    return macs


def pc_macs():
    macs = []
    if IS_WIN:
        try:
            out = subprocess.run(["getmac", "/fo", "csv", "/nh"], capture_output=True, text=True, timeout=5,
                                 creationflags=0x08000000).stdout
            macs = parse_getmac(out)
        except Exception:
            pass
    if not macs:
        import uuid
        n = uuid.getnode()
        if not (n >> 40) & 1:  # مش عنوان عشوائي
            macs = [":".join("%02X" % ((n >> (8 * i)) & 0xFF) for i in reversed(range(6)))]
    return macs


if IS_WIN:
    import ctypes
    from ctypes import wintypes

    user32 = ctypes.windll.user32
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)  # علشان الإحداثيات تطابق الشاشة الحقيقية
    except Exception:
        try:
            user32.SetProcessDPIAware()
        except Exception:
            pass

    ULONG_PTR = ctypes.c_size_t

    class MOUSEINPUT(ctypes.Structure):
        _fields_ = [("dx", wintypes.LONG), ("dy", wintypes.LONG), ("mouseData", wintypes.DWORD),
                    ("dwFlags", wintypes.DWORD), ("time", wintypes.DWORD), ("dwExtraInfo", ULONG_PTR)]

    class KEYBDINPUT(ctypes.Structure):
        _fields_ = [("wVk", wintypes.WORD), ("wScan", wintypes.WORD), ("dwFlags", wintypes.DWORD),
                    ("time", wintypes.DWORD), ("dwExtraInfo", ULONG_PTR)]

    class HARDWAREINPUT(ctypes.Structure):
        _fields_ = [("uMsg", wintypes.DWORD), ("wParamL", wintypes.WORD), ("wParamH", wintypes.WORD)]

    class _U(ctypes.Union):
        _fields_ = [("mi", MOUSEINPUT), ("ki", KEYBDINPUT), ("hi", HARDWAREINPUT)]

    class INPUT(ctypes.Structure):
        _fields_ = [("type", wintypes.DWORD), ("u", _U)]

    user32.SendInput.argtypes = (wintypes.UINT, ctypes.POINTER(INPUT), ctypes.c_int)
    user32.SendInput.restype = wintypes.UINT

    M_MOVE, M_LD, M_LU, M_RD, M_RU, M_MD, M_MU, M_WHEEL, M_HWHEEL = 0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x800, 0x1000
    K_EXT, K_UP, K_UNI = 0x1, 0x2, 0x4

    def _send(*inputs):
        arr = (INPUT * len(inputs))(*inputs)
        user32.SendInput(len(inputs), arr, ctypes.sizeof(INPUT))

    def _mouse(flags, dx=0, dy=0, data=0):
        i = INPUT(type=0)
        i.u.mi = MOUSEINPUT(dx, dy, data & 0xFFFFFFFF, flags, 0, 0)
        return i

    def _key(vk=0, scan=0, flags=0):
        i = INPUT(type=1)
        if vk in EXTENDED:
            flags |= K_EXT
        i.u.ki = KEYBDINPUT(vk, scan, flags, 0, 0)
        return i

    def screen_rect():
        # الشاشة الأساسية
        return 0, 0, user32.GetSystemMetrics(0), user32.GetSystemMetrics(1)

    def do_input(c):
        t = c["t"]
        if t == "move":
            _send(_mouse(M_MOVE, c["dx"], c["dy"]))
        elif t == "abs":
            x0, y0, w, h = screen_rect()
            user32.SetCursorPos(int(x0 + c["x"] * (w - 1)), int(y0 + c["y"] * (h - 1)))
        elif t in ("click", "down", "up"):
            dn, up = {"left": (M_LD, M_LU), "right": (M_RD, M_RU), "middle": (M_MD, M_MU)}[c["b"]]
            if t == "down":
                _send(_mouse(dn))
            elif t == "up":
                _send(_mouse(up))
            else:
                for _ in range(c["n"]):
                    _send(_mouse(dn), _mouse(up))
        elif t == "scroll":
            if c["dy"]:
                _send(_mouse(M_WHEEL, data=-c["dy"] * 40))
            if c["dx"]:
                _send(_mouse(M_HWHEEL, data=c["dx"] * 40))
        elif t == "text":
            seq = []
            for ch in c["s"].replace("\r\n", "\n"):
                if ch == "\n":
                    seq += [_key(0x0D), _key(0x0D, flags=K_UP)]
                    continue
                b = ch.encode("utf-16-le")
                for j in range(0, len(b), 2):
                    code = b[j] | (b[j + 1] << 8)
                    seq += [_key(0, code, K_UNI), _key(0, code, K_UNI | K_UP)]
            for j in range(0, len(seq), 64):
                _send(*seq[j:j + 64])
        elif t == "key":
            k = c["k"]
            vk = VK.get(k) or ord(k.upper())
            mods = [VK[m] for m in c["mods"]]
            seq = [_key(m) for m in mods] + [_key(vk), _key(vk, flags=K_UP)] + [_key(m, flags=K_UP) for m in reversed(mods)]
            _send(*seq)
        elif t == "media":
            vk = MEDIA[c["k"]]
            _send(_key(vk), _key(vk, flags=K_UP))

    def cursor_pos():
        p = wintypes.POINT()
        user32.GetCursorPos(ctypes.byref(p))
        return p.x, p.y

    def do_power(a):
        if a == "lock":
            user32.LockWorkStation()
        elif a == "sleep":
            # Sleep (مش Hibernate لو Hibernate مقفول)
            ctypes.windll.powrprof.SetSuspendState(0, 1, 0)
        elif a == "shutdown":
            subprocess.Popen(["shutdown", "/s", "/t", "5"], creationflags=0x08000000)
        elif a == "restart":
            subprocess.Popen(["shutdown", "/r", "/t", "5"], creationflags=0x08000000)
        elif a == "cancel":
            subprocess.Popen(["shutdown", "/a"], creationflags=0x08000000)

    def downloads_dir():
        try:
            from ctypes import windll, c_wchar_p, byref
            import uuid
            fid = uuid.UUID("{374DE290-123F-4565-9164-39C4925E467B}")
            guid = (ctypes.c_byte * 16).from_buffer_copy(fid.bytes_le)
            p = c_wchar_p()
            if windll.shell32.SHGetKnownFolderPath(byref(guid), 0, None, byref(p)) == 0:
                r = p.value
                windll.ole32.CoTaskMemFree(p)
                return r
        except Exception:
            pass
        return os.path.join(os.path.expanduser("~"), "Downloads")
else:  # للاختبارات على لينكس بس
    def do_input(c):
        pass

    def do_power(a):
        pass

    def cursor_pos():
        return 0, 0

    def screen_rect():
        return 0, 0, 1920, 1080

    def downloads_dir():
        return os.path.join(os.path.expanduser("~"), "Downloads")



if IS_WIN:
    import ctypes as _ct
    from ctypes import wintypes as _wt

    class _MEM(_ct.Structure):
        _fields_ = [("dwLength", _wt.DWORD), ("dwMemoryLoad", _wt.DWORD), ("ullTotalPhys", _ct.c_ulonglong),
                    ("ullAvailPhys", _ct.c_ulonglong), ("ullTotalPageFile", _ct.c_ulonglong), ("ullAvailPageFile", _ct.c_ulonglong),
                    ("ullTotalVirtual", _ct.c_ulonglong), ("ullAvailVirtual", _ct.c_ulonglong), ("ullAvailExtendedVirtual", _ct.c_ulonglong)]

    class _PWR(_ct.Structure):
        _fields_ = [("ACLineStatus", _ct.c_ubyte), ("BatteryFlag", _ct.c_ubyte), ("BatteryLifePercent", _ct.c_ubyte),
                    ("SystemStatusFlag", _ct.c_ubyte), ("BatteryLifeTime", _wt.DWORD), ("BatteryFullLifeTime", _wt.DWORD)]

    _k32 = _ct.windll.kernel32
    _u32 = _ct.windll.user32
    _k32.GetTickCount64.restype = _ct.c_ulonglong
    _k32.GlobalAlloc.restype = _wt.HGLOBAL
    _k32.GlobalAlloc.argtypes = [_wt.UINT, _ct.c_size_t]
    _k32.GlobalLock.restype = _wt.LPVOID
    _k32.GlobalLock.argtypes = [_wt.HGLOBAL]
    _k32.GlobalUnlock.argtypes = [_wt.HGLOBAL]
    _u32.GetClipboardData.restype = _wt.HANDLE
    _u32.SetClipboardData.restype = _wt.HANDLE
    _u32.SetClipboardData.argtypes = [_wt.UINT, _wt.HANDLE]

    def _cpu_times():
        i, k, u = _wt.FILETIME(), _wt.FILETIME(), _wt.FILETIME()
        _k32.GetSystemTimes(_ct.byref(i), _ct.byref(k), _ct.byref(u))
        f = lambda t: (t.dwHighDateTime << 32) | t.dwLowDateTime
        return f(i), f(k) + f(u)

    def cpu_percent():
        i1, t1 = _cpu_times()
        time.sleep(0.4)
        i2, t2 = _cpu_times()
        dt = t2 - t1
        return round(100.0 * (1 - (i2 - i1) / dt), 1) if dt > 0 else None

    def sysinfo_os():
        m = _MEM()
        m.dwLength = _ct.sizeof(_MEM)
        _k32.GlobalMemoryStatusEx(_ct.byref(m))
        p = _PWR()
        bat = None
        if _k32.GetSystemPowerStatus(_ct.byref(p)) and p.BatteryFlag != 128 and p.BatteryLifePercent != 255:
            bat = {"pct": int(p.BatteryLifePercent), "plugged": p.ACLineStatus == 1}
        return {"cpu": cpu_percent(), "ram_pct": int(m.dwMemoryLoad), "ram_total": int(m.ullTotalPhys),
                "uptime": int(_k32.GetTickCount64() // 1000), "battery": bat}

    def clip_get():
        if not _u32.OpenClipboard(None):
            raise RuntimeError("clipboard_busy")
        try:
            h = _u32.GetClipboardData(13)  # CF_UNICODETEXT
            if not h:
                return ""
            ptr = _k32.GlobalLock(h)
            try:
                return _ct.wstring_at(ptr) if ptr else ""
            finally:
                _k32.GlobalUnlock(h)
        finally:
            _u32.CloseClipboard()

    def clip_set(text):
        data = _ct.create_unicode_buffer(text)
        size = _ct.sizeof(data)
        if not _u32.OpenClipboard(None):
            raise RuntimeError("clipboard_busy")
        try:
            _u32.EmptyClipboard()
            h = _k32.GlobalAlloc(0x0002, size)  # GMEM_MOVEABLE
            ptr = _k32.GlobalLock(h)
            _ct.memmove(ptr, data, size)
            _k32.GlobalUnlock(h)
            if not _u32.SetClipboardData(13, h):
                raise RuntimeError("clipboard_set")
        finally:
            _u32.CloseClipboard()

    def open_url(u):
        os.startfile(u)

    def shutdown_in(minutes):
        subprocess.Popen(["shutdown", "/s", "/t", str(minutes * 60)], creationflags=0x08000000)
else:  # للاختبارات
    _CLIP = {"t": ""}

    def sysinfo_os():
        return {"cpu": None, "ram_pct": None, "ram_total": None, "uptime": None, "battery": None}

    def clip_get():
        return _CLIP["t"]

    def clip_set(text):
        _CLIP["t"] = text

    def open_url(u):
        State.opened.append(u)

    def shutdown_in(minutes):
        State.opened.append("shutdown:%d" % minutes)


def sysinfo():
    import shutil
    d = sysinfo_os()
    root = os.environ.get("SystemDrive", "C:") + "\\" if IS_WIN else "/"
    try:
        du = shutil.disk_usage(root)
        d.update({"disk_path": root, "disk_total": du.total, "disk_free": du.free})
    except Exception:
        pass
    d.update({"name": socket.gethostname(), "macs": pc_macs(), "v": VERSION, "shutdown_at": State.shutdown_at})
    return d


def grab_jpeg(width=1280, quality=60):
    import mss
    from PIL import Image, ImageDraw
    with mss.mss() as s:
        mon = s.monitors[1]
        shot = s.grab(mon)
    img = Image.frombytes("RGB", shot.size, shot.bgra, "raw", "BGRX")
    # نرسم مكان الماوس (الصورة مفيهاش الماوس)
    cx, cy = cursor_pos()
    cx -= mon["left"]
    cy -= mon["top"]
    if 0 <= cx < img.width and 0 <= cy < img.height:
        d = ImageDraw.Draw(img)
        r = max(6, img.width // 220)
        d.polygon([(cx, cy), (cx, cy + 3 * r), (cx + 2 * r, cy + 2 * r)], fill=(255, 255, 255), outline=(0, 0, 0))
    width = max(320, min(int(width), img.width))
    if width < img.width:
        img = img.resize((width, int(img.height * width / img.width)), Image.BILINEAR)
    b = io.BytesIO()
    img.save(b, "JPEG", quality=max(20, min(95, int(quality))))
    return b.getvalue(), mon["width"], mon["height"]


# ---------------------------------------------------------------- السيرفر

APP_DIR = os.path.join(os.environ.get("APPDATA") or os.path.expanduser("~"), "A2R-PC")
TOKENS_FILE = os.path.join(APP_DIR, "tokens.json")
HOME = os.path.expanduser("~")
RECV_DIR = os.path.join(downloads_dir(), "A2R")


def load_tokens():
    try:
        with open(TOKENS_FILE, "r", encoding="utf-8") as f:
            d = json.load(f)
            return d if isinstance(d, dict) else {}
    except Exception:
        return {}


def save_tokens(t):
    try:
        os.makedirs(APP_DIR, exist_ok=True)
        tmp = TOKENS_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(t, f)
        os.replace(tmp, TOKENS_FILE)
    except Exception:
        pass


class State:
    pairing = None
    events = queue.Queue()  # رسايل للشباك
    shutdown_at = None  # وقت الإطفاء المتجدول (epoch)
    opened = []  # للاختبارات


def log(msg):
    State.events.put(time.strftime("%H:%M:%S ") + msg)


class Handler(BaseHTTPRequestHandler):
    server_version = "A2R-PC/" + VERSION
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        pass

    def _json(self, code, obj):
        b = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(b)

    def _body(self, limit=1 << 20):
        n = int(self.headers.get("Content-Length") or 0)
        if n > limit:
            raise ValueError("too big")
        return self.rfile.read(n) if n else b""

    def _guard(self):
        if not is_lan(self.client_address[0]):
            self._json(403, {"error": "not_lan"})
            return False
        if self.path.startswith("/pair") or self.path.startswith("/hello"):
            return True
        if not State.pairing.ok(self.headers.get("X-A2R-Token", "")):
            self._json(401, {"error": "need_pair"})
            return False
        return True

    def do_GET(self):
        if not self._guard():
            return
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        try:
            if u.path == "/hello":
                return self._json(200, {"a2r": "pc", "name": socket.gethostname(), "v": VERSION})
            if u.path == "/info":
                x0, y0, w, h = screen_rect()
                return self._json(200, {"name": socket.gethostname(), "w": w, "h": h, "v": VERSION, "recv": RECV_DIR, "home": HOME, "macs": pc_macs()})
            if u.path == "/sysinfo":
                return self._json(200, sysinfo())
            if u.path == "/clip":
                return self._json(200, {"text": clip_get()})
            if u.path == "/frame.jpg":
                data, w, h = grab_jpeg(int(q.get("w", 1280)), int(q.get("q", 60)))
                self.send_response(200)
                self.send_header("Content-Type", "image/jpeg")
                self.send_header("Content-Length", str(len(data)))
                self.send_header("X-Screen", "%dx%d" % (w, h))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(data)
                return
            if u.path == "/files":
                p = q.get("path") or RECV_DIR
                os.makedirs(RECV_DIR, exist_ok=True)
                if not (inside(HOME, p) or inside(RECV_DIR, p)):
                    return self._json(403, {"error": "outside_home"})
                parent = os.path.dirname(os.path.realpath(p))
                return self._json(200, {"path": os.path.realpath(p), "up": parent if inside(HOME, parent) and parent != os.path.realpath(p) else None, "items": list_dir(p)})
            if u.path == "/file":
                p = q.get("path", "")
                if not (inside(HOME, p) or inside(RECV_DIR, p)) or not os.path.isfile(p):
                    return self._json(404, {"error": "not_found"})
                size = os.path.getsize(p)
                self.send_response(200)
                self.send_header("Content-Type", "application/octet-stream")
                self.send_header("Content-Length", str(size))
                self.send_header("Content-Disposition", "attachment; filename*=UTF-8''" + quote(os.path.basename(p)))
                self.end_headers()
                with open(p, "rb") as f:
                    while True:
                        b = f.read(256 * 1024)
                        if not b:
                            break
                        self.wfile.write(b)
                log("اتبعت للموبايل: " + os.path.basename(p))
                return
            self._json(404, {"error": "no_route"})
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            try:
                self._json(500, {"error": str(e)})
            except Exception:
                pass

    def do_POST(self):
        if not self._guard():
            return
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        try:
            if u.path == "/pair":
                d = json.loads(self._body(4096) or b"{}")
                tok, err = State.pairing.pair(d.get("code", ""), d.get("device", ""))
                if err:
                    log("كود غلط من " + self.client_address[0])
                    return self._json(403, {"error": err})
                save_tokens(State.pairing.tokens)
                log("اتربط: %s (%s)" % (State.pairing.tokens[tok], self.client_address[0]))
                return self._json(200, {"token": tok, "name": socket.gethostname()})
            if u.path == "/input":
                d = json.loads(self._body(64 * 1024) or b"{}")
                cmds = d if isinstance(d, list) else [d]
                for c in cmds[:50]:
                    do_input(parse_input(c))
                return self._json(200, {"ok": True})
            if u.path == "/power":
                d = json.loads(self._body(4096) or b"{}")
                a = d.get("a")
                if a not in ("lock", "sleep", "shutdown", "restart", "cancel", "shutdown_in"):
                    return self._json(400, {"error": "bad_action"})
                if a in ("shutdown", "restart", "sleep", "shutdown_in") and d.get("confirm") is not True:
                    return self._json(400, {"error": "need_confirm"})
                if a == "shutdown_in":
                    try:
                        m = clamp_minutes(d.get("minutes"))
                    except (TypeError, ValueError):
                        return self._json(400, {"error": "bad_minutes"})
                    log("إطفاء بعد %d دقيقة" % m)
                    shutdown_in(m)
                    State.shutdown_at = int(time.time()) + m * 60
                    return self._json(200, {"ok": True, "at": State.shutdown_at})
                if a == "cancel":
                    State.shutdown_at = None
                log("أمر: " + a)
                self._json(200, {"ok": True})
                threading.Timer(0.3, do_power, args=(a,)).start()
                return
            if u.path == "/clip":
                d = json.loads(self._body(512 * 1024) or b"{}")
                t = d.get("text")
                if not isinstance(t, str) or len(t) > 200000:
                    return self._json(400, {"error": "bad_text"})
                clip_set(t)
                log("اتنسخ من الموبايل (%d حرف)" % len(t))
                return self._json(200, {"ok": True})
            if u.path == "/open":
                d = json.loads(self._body(8192) or b"{}")
                try:
                    url = validate_open_url(d.get("url"))
                except ValueError as e:
                    return self._json(400, {"error": str(e)})
                log("فتح لينك: " + url[:80])
                open_url(url)
                return self._json(200, {"ok": True})
            if u.path == "/upload":
                n = int(self.headers.get("Content-Length") or 0)
                if n <= 0 or n > MAX_UPLOAD:
                    return self._json(400, {"error": "bad_size"})
                os.makedirs(RECV_DIR, exist_ok=True)
                dst = unique_path(RECV_DIR, safe_name(q.get("name", "file")))
                part = dst + ".part"
                left = n
                with open(part, "wb") as f:
                    while left > 0:
                        b = self.rfile.read(min(256 * 1024, left))
                        if not b:
                            break
                        f.write(b)
                        left -= len(b)
                if left:
                    os.remove(part)
                    return self._json(400, {"error": "incomplete"})
                os.replace(part, dst)
                log("وصل من الموبايل: " + os.path.basename(dst))
                return self._json(200, {"ok": True, "path": dst})
            self._json(404, {"error": "no_route"})
        except ValueError as e:
            self._json(400, {"error": str(e)})
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            try:
                self._json(500, {"error": str(e)})
            except Exception:
                pass


def udp_loop():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("", UDP_PORT))
    while True:
        try:
            data, addr = s.recvfrom(256)
            if data.strip() == DISCOVER_MAGIC and is_lan(addr[0]):
                s.sendto(discovery_reply(socket.gethostname()), addr)
        except Exception:
            time.sleep(0.5)


def local_ips():
    ips = set()
    try:
        u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        u.connect(("10.255.255.255", 1))
        ips.add(u.getsockname()[0])
        u.close()
    except Exception:
        pass
    try:
        for i in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ips.add(i[4][0])
    except Exception:
        pass
    return sorted(ip for ip in ips if not ip.startswith("127."))


def single_instance():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("0.0.0.0", HTTP_PORT))
        s.close()
        return True
    except OSError:
        return False


def main():
    import tkinter as tk
    from tkinter import messagebox

    if not single_instance():
        r = tk.Tk()
        r.withdraw()
        messagebox.showinfo("A2R PC", "البرنامج شغال بالفعل (أو البورت 47800 مستخدم).")
        return
    State.pairing = Pairing(load_tokens())
    srv = ThreadingHTTPServer(("0.0.0.0", HTTP_PORT), Handler)
    srv.daemon_threads = True
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    threading.Thread(target=udp_loop, daemon=True).start()

    root = tk.Tk()
    root.title("A2R PC")
    root.geometry("360x330")
    root.configure(bg="#14171D")
    gold, fg, muted = "#E9B949", "#F2F2F2", "#9AA0A6"
    tk.Label(root, text="A2R PC", fg=gold, bg="#14171D", font=("Segoe UI", 18, "bold")).pack(pady=(14, 2))
    ip_l = tk.Label(root, text="", fg=fg, bg="#14171D", font=("Segoe UI", 11))
    ip_l.pack()
    tk.Label(root, text="كود الربط", fg=muted, bg="#14171D", font=("Segoe UI", 10)).pack(pady=(12, 0))
    code_l = tk.Label(root, text="", fg=gold, bg="#14171D", font=("Consolas", 30, "bold"))
    code_l.pack()
    info_l = tk.Label(root, text="", fg=muted, bg="#14171D", font=("Segoe UI", 9))
    info_l.pack()
    log_l = tk.Label(root, text="مستني الموبايل…", fg=fg, bg="#14171D", font=("Segoe UI", 9), wraplength=330, justify="center")
    log_l.pack(pady=8)

    def forget():
        if messagebox.askyesno("A2R PC", "تلغي ربط كل الموبايلات؟ هيحتاجوا الكود تاني."):
            State.pairing.forget_all()
            save_tokens({})
            log("اتلغى ربط كل الأجهزة")

    def open_recv():
        os.makedirs(RECV_DIR, exist_ok=True)
        if IS_WIN:
            os.startfile(RECV_DIR)

    bar = tk.Frame(root, bg="#14171D")
    bar.pack(pady=4)
    tk.Button(bar, text="فولدر الملفات", command=open_recv).pack(side="left", padx=4)
    tk.Button(bar, text="إلغاء ربط الكل", command=forget).pack(side="left", padx=4)

    def tick():
        ip_l.config(text="  •  ".join(local_ips()) or "مش متصل بشبكة")
        p = State.pairing
        if p.locked():
            code_l.config(text="------")
            info_l.config(text="محاولات غلط كتير — استنى %d ثانية" % int(p.locked_until - time.time() + 1))
        else:
            code_l.config(text=p.code)
            info_l.config(text="أجهزة مربوطة: %d" % len(p.tokens))
        try:
            while True:
                log_l.config(text=State.events.get_nowait())
        except queue.Empty:
            pass
        root.after(700, tick)

    tick()
    root.mainloop()
    srv.shutdown()


if __name__ == "__main__":
    main()
