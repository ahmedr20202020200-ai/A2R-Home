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

VERSION = "1.3"
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
SHOW_MAGIC = b"A2R-PC-SHOW"


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
        r = {"t": t, "x": num("x", 0, 1), "y": num("y", 0, 1)}
        if d.get("m") is not None:
            r["m"] = int(num("m", 1, 16, 1))  # رقم الشاشة (v1.3)؛ من غيره = الشاشة الأساسية
        return r
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
        if len(k) == 1 and not k.isascii() and k.isprintable():
            # حرف عربي (أو أي حرف مش إنجليزي): مالوش زرار VK — بنكتبه كنص يونيكود
            return {"t": "text", "s": k}
        if k not in VK and not (len(k) == 1 and k.isascii() and k.isalnum()):
            raise ValueError("key")
        mods = [m for m in d.get("mods", []) if m in ("ctrl", "alt", "shift", "win")]
        return {"t": t, "k": k, "mods": mods}
    if t == "media":
        k = str(d.get("k", ""))
        if k not in MEDIA:
            raise ValueError("media")
        return {"t": t, "k": k}
    raise ValueError("type")


def abs_to_virtual(x, y, mon, vs):
    """نسبة 0..1 جوه شاشة معيّنة → إحداثيات SendInput المطلقة (0..65535) على سطح المكتب الافتراضي كله.
    mon و vs = (left, top, width, height) بالبكسل الحقيقي."""
    ml, mt, mw, mh = mon
    vl, vt, vw, vh = vs
    px = ml + x * (mw - 1)
    py = mt + y * (mh - 1)
    nx = int(round((px - vl) * 65535.0 / max(1, vw - 1)))
    ny = int(round((py - vt) * 65535.0 / max(1, vh - 1)))
    return max(0, min(65535, nx)), max(0, min(65535, ny)), int(round(px)), int(round(py))


def pick_monitor(mons, m=None):
    """mons = قايمة {"i","x","y","w","h","primary"}. m = رقم الشاشة (1..)؛ من غيره = الأساسية."""
    if not mons:
        return None
    if m is not None:
        for d in mons:
            if d["i"] == m:
                return d
    for d in mons:
        if d.get("primary"):
            return d
    return mons[0]


def mons_from_mss(raw):
    """mss.monitors (أول عنصر = كل الشاشات) → قايمة شاشات؛ الأساسية هي اللي عند (0,0)."""
    out = []
    for i, d in enumerate(raw[1:], start=1):
        out.append({"i": i, "x": d["left"], "y": d["top"], "w": d["width"], "h": d["height"],
                    "primary": d["left"] == 0 and d["top"] == 0})
    if out and not any(d["primary"] for d in out):
        out[0]["primary"] = True
    return out


class InputBlocked(Exception):
    """ويندوز رفض الإدخال (شباك أدمن / شاشة القفل / UAC)."""


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


def run_shutdown(args, cancel_only=False, runner=None):
    """أوامر shutdown.exe: بنلغي أي إطفاء متجدول الأول (لو في واحد ويندوز بيرفض الجديد — خطأ 1190)
    وبنتأكد إن الأمر اتقبل. cancel_only: إلغاء بس (1116 = مفيش حاجة متجدولة = تمام)."""
    run = runner or (lambda a: subprocess.run(["shutdown"] + a, capture_output=True, timeout=15,
                                              creationflags=0x08000000 if IS_WIN else 0).returncode)
    rc = run(["/a"])
    if cancel_only:
        if rc not in (0, 1116):
            raise RuntimeError("shutdown_failed")
        return
    rc = run(list(args))
    if rc != 0:
        raise RuntimeError("shutdown_failed")


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

    M_ABS, M_VDESK = 0x8000, 0x4000

    def _send(*inputs):
        arr = (INPUT * len(inputs))(*inputs)
        n = user32.SendInput(len(inputs), arr, ctypes.sizeof(INPUT))
        if n != len(inputs):
            # ويندوز رفض (UIPI: شباك أدمن، شاشة القفل، UAC)
            raise InputBlocked("blocked")

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

    def virtual_rect():
        # كل الشاشات مع بعض (SM_XVIRTUALSCREEN.. SM_CYVIRTUALSCREEN)
        return (user32.GetSystemMetrics(76), user32.GetSystemMetrics(77),
                max(1, user32.GetSystemMetrics(78)), max(1, user32.GetSystemMetrics(79)))

    _k32w = ctypes.windll.kernel32
    _adv = ctypes.windll.advapi32
    _k32w.OpenProcess.restype = wintypes.HANDLE
    _k32w.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    _adv.OpenProcessToken.argtypes = (wintypes.HANDLE, wintypes.DWORD, ctypes.POINTER(wintypes.HANDLE))
    _adv.GetTokenInformation.argtypes = (wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(wintypes.DWORD))
    user32.GetForegroundWindow.restype = wintypes.HWND

    def _elevated_pid(pid):
        """True = البرنامج ده شغال أدمن (أو مقدرناش نقراه = غالبًا أدمن)."""
        h = _k32w.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
        if not h:
            return True
        try:
            tok = wintypes.HANDLE()
            if not _adv.OpenProcessToken(h, 0x0008, ctypes.byref(tok)):  # TOKEN_QUERY
                return True
            try:
                el = wintypes.DWORD()
                ln = wintypes.DWORD()
                if not _adv.GetTokenInformation(tok, 20, ctypes.byref(el), 4, ctypes.byref(ln)):  # TokenElevation
                    return False
                return bool(el.value)
            finally:
                _k32w.CloseHandle(tok)
        finally:
            _k32w.CloseHandle(h)

    try:
        SELF_ADMIN = bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        SELF_ADMIN = False

    def input_warning():
        """قبل ما ننفّذ: الشباك اللي قدام شغال أدمن واحنا لأ؟ (ويندوز هيتجاهل الماوس والكيبورد فيه بصمت)"""
        if SELF_ADMIN:
            return None
        try:
            hw = user32.GetForegroundWindow()
            if not hw:
                return "locked"  # شاشة القفل / UAC
            pid = wintypes.DWORD()
            user32.GetWindowThreadProcessId(hw, ctypes.byref(pid))
            if pid.value and pid.value != os.getpid() and _elevated_pid(pid.value):
                return "admin"
        except Exception:
            pass
        return None

    def do_input(c):
        t = c["t"]
        if t == "move":
            _send(_mouse(M_MOVE, c["dx"], c["dy"]))
        elif t == "abs":
            mon = pick_monitor(GRAB.monitors(), c.get("m"))
            if mon is None:
                x0, y0, w, h = screen_rect()
                mon = {"x": x0, "y": y0, "w": w, "h": h}
            nx, ny, px, py = abs_to_virtual(c["x"], c["y"], (mon["x"], mon["y"], mon["w"], mon["h"]), virtual_rect())
            # حركة ماوس حقيقية (مش SetCursorPos) علشان كل البرامج تحس بيها
            try:
                _send(_mouse(M_MOVE | M_ABS | M_VDESK, nx, ny))
            except InputBlocked:
                user32.SetCursorPos(px, py)
                raise
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
            run_shutdown(["/s", "/t", "5"])
        elif a == "restart":
            run_shutdown(["/r", "/t", "5"])
        elif a == "cancel":
            run_shutdown(["/a"], cancel_only=True)

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
    SELF_ADMIN = False

    def do_input(c):
        pass

    def input_warning():
        return None

    def virtual_rect():
        return 0, 0, 1920, 1080

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
        run_shutdown(["/s", "/t", str(minutes * 60)])
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


# ---------------------------------------------------------------- العمليات (Task Manager)
PROTECTED = {"system", "system idle process", "registry", "smss.exe", "csrss.exe", "wininit.exe", "winlogon.exe",
             "services.exe", "lsass.exe", "svchost.exe", "dwm.exe", "fontdrvhost.exe", "memory compression"}


WARN_KILL = {"explorer.exe"}  # مش محمية بس لازم تحذير (شريط المهام وسطح المكتب)


def self_pids():
    """البرنامج نفسه: الـ exe بتاع PyInstaller بيشتغل كعمليتين (الأب بيفك الملفات والابن هو البرنامج)."""
    pids = {os.getpid()}
    try:
        pids.add(os.getppid())
    except Exception:
        pass
    return pids


def self_names():
    if getattr(sys, "frozen", False):
        return {os.path.basename(sys.executable).lower()}
    return set()


def parse_tasklist(out, extra_pids=(), extra_names=()):
    """يحوّل ناتج tasklist /fo csv /nh لقايمة {name,pid,mem_mb} مرتبة بالرامات."""
    import csv
    extra_pids = set(extra_pids)
    extra_names = {n.lower() for n in extra_names}
    rows = []
    for r in csv.reader(io.StringIO(out)):
        if len(r) < 5:
            continue
        try:
            pid = int(r[1])
            mem = int(re.sub(r"[^0-9]", "", r[4]) or 0) / 1024.0
        except ValueError:
            continue
        low = r[0].lower()
        rows.append({"name": r[0], "pid": pid, "mem_mb": round(mem, 1),
                     "protected": low in PROTECTED or pid <= 4 or pid in extra_pids or low in extra_names,
                     "self": pid in extra_pids or low in extra_names,
                     "warn": low in WARN_KILL})
    rows.sort(key=lambda x: -x["mem_mb"])
    return rows


def decode_console(b):
    """tasklist بيطبع بصفحة الـ OEM (مش ANSI) — علشان الأسامي العربي متطلعش رموز."""
    for enc in ("oem", "mbcs", "utf-8"):
        try:
            return b.decode(enc)
        except (LookupError, UnicodeDecodeError):
            continue
    return b.decode("utf-8", "replace")


def unicode_names():
    """pid → اسم البرنامج بيونيكود كامل (Toolhelp32) — أدق من tasklist للأسامي العربي."""
    names = {}
    if not IS_WIN:
        return names
    try:
        class PE(ctypes.Structure):
            _fields_ = [("dwSize", wintypes.DWORD), ("cntUsage", wintypes.DWORD), ("th32ProcessID", wintypes.DWORD),
                        ("th32DefaultHeapID", ctypes.c_size_t), ("th32ModuleID", wintypes.DWORD), ("cntThreads", wintypes.DWORD),
                        ("th32ParentProcessID", wintypes.DWORD), ("pcPriClassBase", wintypes.LONG), ("dwFlags", wintypes.DWORD),
                        ("szExeFile", ctypes.c_wchar * 260)]
        k = ctypes.windll.kernel32
        k.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
        snap = k.CreateToolhelp32Snapshot(0x2, 0)
        if not snap or snap == wintypes.HANDLE(-1).value:
            return names
        try:
            e = PE()
            e.dwSize = ctypes.sizeof(PE)
            ok = k.Process32FirstW(snap, ctypes.byref(e))
            while ok:
                names[int(e.th32ProcessID)] = e.szExeFile
                ok = k.Process32NextW(snap, ctypes.byref(e))
        finally:
            k.CloseHandle(snap)
    except Exception:
        pass
    return names


def list_procs():
    if not IS_WIN:
        return []
    out = subprocess.run(["tasklist", "/fo", "csv", "/nh"], capture_output=True, creationflags=0x08000000, timeout=15).stdout
    rows = parse_tasklist(decode_console(out) if hasattr(out, "decode") else out, self_pids(), self_names())
    un = unicode_names()
    for r in rows:
        if r["pid"] in un and un[r["pid"]]:
            r["name"] = un[r["pid"]]
    return rows


def kill_proc(pid):
    pid = int(pid)
    if pid in self_pids() or pid <= 4:
        raise ValueError("protected")
    for p in list_procs():
        if p["pid"] == pid:
            if p["protected"]:
                raise ValueError("protected")
            break
    else:
        raise ValueError("no_such_pid")
    if IS_WIN:
        r = subprocess.run(["taskkill", "/PID", str(pid), "/F"], capture_output=True, creationflags=0x08000000, timeout=15)
        if r.returncode != 0:
            raise ValueError("kill_failed")


def frame_key(raw, cursor):
    """بصمة سريعة للصورة + مكان الماوس — لو متغيرتش منبعتش الصورة تاني (توفير نت ومعالج)."""
    import zlib
    return "%08x" % (zlib.crc32(bytes(raw[::61])) ^ (hash(cursor) & 0xFFFFFFFF))


class Grabber:
    """تصوير الشاشة من thread واحد ثابت بنفس أداة mss (mss على ويندوز لازم يتصوّر من نفس الـ thread اللي فتحه)
    بدل ما نفتح أداة جديدة مع كل صورة."""

    def __init__(self):
        self.q = queue.Queue()
        self._t = None
        self._start = threading.Lock()
        self._mss = None
        self._mons = None
        self._mons_t = 0.0

    def _ensure(self):
        with self._start:
            if self._t is None or not self._t.is_alive():
                self._t = threading.Thread(target=self._run, daemon=True, name="a2r-grab")
                self._t.start()

    def _run(self):
        while True:
            fn, args, box, ev = self.q.get()
            try:
                box["r"] = fn(*args)
            except Exception as e:  # noqa
                box["e"] = e
            finally:
                ev.set()

    def _call(self, fn, *args, timeout=10):
        self._ensure()
        ev, box = threading.Event(), {}
        self.q.put((fn, args, box, ev))
        if not ev.wait(timeout):
            raise RuntimeError("grab_timeout")
        if "e" in box:
            raise box["e"]
        return box["r"]

    def _get(self):
        if self._mss is None:
            import mss
            self._mss = mss.mss()
        return self._mss

    def _reset(self):
        try:
            if self._mss is not None:
                self._mss.close()
        except Exception:
            pass
        self._mss = None
        self._mons = None

    def _monitors_w(self):
        now = time.time()
        if self._mons is not None and now - self._mons_t < 5:
            return self._mons
        try:
            self._mons = mons_from_mss(self._get().monitors)
        except Exception:
            x0, y0, w, h = screen_rect()
            self._mons = [{"i": 1, "x": x0, "y": y0, "w": w, "h": h, "primary": True}]
        self._mons_t = now
        return self._mons

    def monitors(self):
        try:
            return self._call(self._monitors_w, timeout=5)
        except Exception:
            x0, y0, w, h = screen_rect()
            return [{"i": 1, "x": x0, "y": y0, "w": w, "h": h, "primary": True}]

    def _grab_w(self, width, quality, m, draw_cursor, last):
        from PIL import Image, ImageDraw
        mon = pick_monitor(self._monitors_w(), m)
        try:
            raw = self._get().grab({"left": mon["x"], "top": mon["y"], "width": mon["w"], "height": mon["h"]})
        except Exception:
            # الشاشة اتغيرت (اتفصلت / دقة جديدة / قفل) — نبدأ من جديد مرة واحدة
            self._reset()
            mon = pick_monitor(self._monitors_w(), m)
            raw = self._get().grab({"left": mon["x"], "top": mon["y"], "width": mon["w"], "height": mon["h"]})
        cx, cy = cursor_pos()
        cx -= mon["x"]
        cy -= mon["y"]
        inside_ = 0 <= cx < raw.size[0] and 0 <= cy < raw.size[1]
        cur = (cx / max(1, mon["w"] - 1), cy / max(1, mon["h"] - 1)) if inside_ else None
        key = frame_key(raw.bgra, (cx, cy, bool(draw_cursor), int(width), int(quality), mon["i"]))
        if last and last == key:
            return None, mon["w"], mon["h"], 0, 0, key, cur, mon["i"]
        img = Image.frombuffer("RGB", raw.size, raw.bgra, "raw", "BGRX", 0, 1)
        width = max(320, min(int(width), img.width))
        if width < img.width:
            img = img.resize((width, max(1, int(img.height * width / img.width))), Image.BILINEAR, reducing_gap=2.0)
        if draw_cursor and inside_:
            sx = img.width / float(raw.size[0])
            px, py = cx * sx, cy * sx
            d = ImageDraw.Draw(img)
            r = max(5, img.width // 200)
            d.polygon([(px, py), (px, py + 3 * r), (px + 2 * r, py + 2 * r)], fill=(255, 255, 255), outline=(0, 0, 0))
        b = io.BytesIO()
        img.save(b, "JPEG", quality=max(20, min(95, int(quality))))
        return b.getvalue(), mon["w"], mon["h"], img.width, img.height, key, cur, mon["i"]

    def grab(self, width=1280, quality=60, m=None, draw_cursor=True, last=None):
        """بيرجع (jpeg أو None لو زي اللي قبلها, شاشة w, h, صورة w, h, key, مكان الماوس 0..1 أو None, رقم الشاشة)"""
        return self._call(self._grab_w, width, quality, m, draw_cursor, last)


GRAB = Grabber()


def grab_jpeg(width=1280, quality=60):
    """للتوافق مع الاختبارات/النسخ القديمة."""
    r = GRAB.grab(width, quality)
    return r[0], r[1], r[2]


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
    show_req = False
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
        if code >= 400:
            # ممكن جسم الطلب لسه متقراش (رفض بدري) — نقفل الاتصال علشان باقيه ميتقريش كأنه طلب جديد
            self.send_header("Connection", "close")
            self.close_connection = True
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
                return self._json(200, {"name": socket.gethostname(), "w": w, "h": h, "v": VERSION, "recv": RECV_DIR, "home": HOME, "macs": pc_macs(),
                                        "mons": GRAB.monitors(), "admin": SELF_ADMIN})
            if u.path == "/sysinfo":
                return self._json(200, sysinfo())
            if u.path == "/clip":
                return self._json(200, {"text": clip_get()})
            if u.path == "/procs":
                return self._json(200, {"procs": list_procs()[:300], "self": os.getpid()})
            if u.path == "/frame.jpg":
                m = int(q["m"]) if q.get("m", "").isdigit() else None
                data, w, h, iw, ih, key, cur, mi = GRAB.grab(int(q.get("w", 1280)), int(q.get("q", 60)), m,
                                                             q.get("c", "1") != "0", q.get("h") or None)
                self.send_response(200 if data is not None else 204)
                self.send_header("Content-Type", "image/jpeg")
                self.send_header("Content-Length", str(len(data) if data is not None else 0))
                self.send_header("X-Screen", "%dx%d" % (w, h))
                if data is not None:
                    self.send_header("X-Img", "%dx%d" % (iw, ih))
                self.send_header("X-Hash", key)
                self.send_header("X-Mon", str(mi))
                self.send_header("X-Cursor", "%.5f,%.5f" % cur if cur else "-")
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                if data is not None:
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
                parsed = [parse_input(c) for c in cmds[:50]]
                warn = input_warning()
                try:
                    for c in parsed:
                        do_input(c)
                except InputBlocked:
                    return self._json(409, {"error": "blocked", "why": warn or "blocked"})
                return self._json(200, {"ok": True, "warn": warn} if warn else {"ok": True})
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
                    try:
                        shutdown_in(m)
                    except RuntimeError:
                        return self._json(400, {"error": "shutdown_failed"})
                    log("إطفاء بعد %d دقيقة" % m)
                    State.shutdown_at = int(time.time()) + m * 60
                    return self._json(200, {"ok": True, "at": State.shutdown_at})
                if a in ("shutdown", "restart", "cancel"):
                    # بننفّذ هنا علشان نعرف لو ويندوز رفض (قبل كده كان بيقول تمام على طول)
                    try:
                        do_power(a)
                    except RuntimeError:
                        return self._json(400, {"error": "shutdown_failed"})
                    State.shutdown_at = None if a == "cancel" else int(time.time()) + 5
                    log("أمر: " + a)
                    return self._json(200, {"ok": True})
                log("أمر: " + a)
                self._json(200, {"ok": True})
                threading.Timer(0.3, do_power, args=(a,)).start()
                return
            if u.path == "/kill":
                d = json.loads(self._body(4096) or b"{}")
                if d.get("confirm") is not True:
                    return self._json(400, {"error": "need_confirm"})
                try:
                    kill_proc(d.get("pid"))
                except (TypeError, ValueError) as e:
                    return self._json(400, {"error": str(e) if str(e) in ("protected", "no_such_pid", "kill_failed") else "bad_pid"})
                log("اتقفلت عملية %s" % d.get("pid"))
                return self._json(200, {"ok": True})
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
            elif data.strip() == SHOW_MAGIC and addr[0] == "127.0.0.1":
                State.show_req = True  # حد فتح البرنامج تاني وهو شغال → نظهر الشباك
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


# ---------------------------------------------------------------- الجدار الناري + التشغيل مع ويندوز (v1.3)
FW_RULE = "A2R PC"
RUN_KEY = r"Software\Microsoft\Windows\CurrentVersion\Run"
RUN_NAME = "A2R PC"


def exe_path():
    return sys.executable if getattr(sys, "frozen", False) else os.path.abspath(sys.argv[0])


def firewall_cmd(exe):
    """أمر واحد (cmd /c) بيمسح قواعد A2R القديمة ويضيف قاعدتين للبرنامج ده بس وللشبكة الداخلية بس
    (remoteip=localsubnet) — TCP 47800 و UDP 47801. بيشتغل في أي نوع شبكة (Private/Public)."""
    q = '"%s"' % exe
    parts = ['netsh advfirewall firewall delete rule name="%s"' % FW_RULE]
    for proto, port in (("TCP", HTTP_PORT), ("UDP", UDP_PORT)):
        parts.append('netsh advfirewall firewall add rule name="%s" dir=in action=allow program=%s protocol=%s localport=%d '
                     'remoteip=localsubnet profile=any enable=yes' % (FW_RULE, q, proto, port))
    return " & ".join(parts)


def firewall_ok():
    if not IS_WIN:
        return None
    try:
        r = subprocess.run(["netsh", "advfirewall", "firewall", "show", "rule", "name=" + FW_RULE], capture_output=True,
                           timeout=10, creationflags=0x08000000)
        return r.returncode == 0
    except Exception:
        return None


def firewall_allow():
    """بيطلب صلاحية أدمن (رسالة UAC) مرة واحدة ويضيف القاعدة."""
    if not IS_WIN:
        return False
    r = ctypes.windll.shell32.ShellExecuteW(None, "runas", "cmd.exe", "/c " + firewall_cmd(exe_path()), None, 0)
    return r > 32


def startup_value(exe):
    return '"%s" --tray' % exe


def startup_get():
    if not IS_WIN:
        return False
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, RUN_KEY) as k:
            v, _ = winreg.QueryValueEx(k, RUN_NAME)
            return bool(v)
    except OSError:
        return False


def startup_set(on):
    if not IS_WIN:
        return
    import winreg
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, RUN_KEY, 0, winreg.KEY_SET_VALUE) as k:
        if on:
            winreg.SetValueEx(k, RUN_NAME, 0, winreg.REG_SZ, startup_value(exe_path()))
        else:
            try:
                winreg.DeleteValue(k, RUN_NAME)
            except OSError:
                pass


def tray_image():
    from PIL import Image, ImageDraw
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((2, 2, 62, 62), 14, fill=(20, 23, 29, 255))
    d.rectangle((14, 18, 50, 40), outline=(233, 185, 73, 255), width=4)
    d.rectangle((28, 42, 36, 48), fill=(233, 185, 73, 255))
    d.rectangle((20, 48, 44, 52), fill=(233, 185, 73, 255))
    return img


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
        # شغال بالفعل (يمكن مستخبي جنب الساعة) — نقوله يظهر الشباك
        try:
            u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            u.sendto(SHOW_MAGIC, ("127.0.0.1", UDP_PORT))
            u.close()
        except Exception:
            pass
        if "--tray" not in sys.argv:
            r = tk.Tk()
            r.withdraw()
            messagebox.showinfo("A2R PC", "البرنامج شغال بالفعل — شباكه هيظهر (أو دوّر على أيقونته جنب الساعة).\n"
                                          "لو مظهرش: البورت 47800 مستخدم من برنامج تاني.")
        return
    State.pairing = Pairing(load_tokens())
    srv = ThreadingHTTPServer(("0.0.0.0", HTTP_PORT), Handler)
    srv.daemon_threads = True
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    threading.Thread(target=udp_loop, daemon=True).start()

    root = tk.Tk()
    root.title("A2R PC")
    root.geometry("380x470")
    root.configure(bg="#14171D")
    gold, fg, muted, bad = "#E9B949", "#F2F2F2", "#9AA0A6", "#E5735A"
    tk.Label(root, text="A2R PC  v" + VERSION, fg=gold, bg="#14171D", font=("Segoe UI", 18, "bold")).pack(pady=(14, 2))
    ip_l = tk.Label(root, text="", fg=fg, bg="#14171D", font=("Segoe UI", 11))
    ip_l.pack()
    tk.Label(root, text="كود الربط", fg=muted, bg="#14171D", font=("Segoe UI", 10)).pack(pady=(12, 0))
    code_l = tk.Label(root, text="", fg=gold, bg="#14171D", font=("Consolas", 30, "bold"))
    code_l.pack()
    info_l = tk.Label(root, text="", fg=muted, bg="#14171D", font=("Segoe UI", 9))
    info_l.pack()
    log_l = tk.Label(root, text="مستني الموبايل…", fg=fg, bg="#14171D", font=("Segoe UI", 9), wraplength=350, justify="center")
    log_l.pack(pady=6)

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

    # ---- الجدار الناري
    fw_box = tk.Frame(root, bg="#1C2028")
    fw_box.pack(fill="x", padx=12, pady=(8, 2))
    fw_l = tk.Label(fw_box, text="", fg=muted, bg="#1C2028", font=("Segoe UI", 9), wraplength=340, justify="center")
    fw_l.pack(pady=(6, 2))

    def fw_refresh():
        ok = firewall_ok()
        if ok:
            fw_l.config(text="الجدار الناري: مسموح للموبايل يوصل ✓", fg="#7BC67E")
            fw_b.config(text="ظبّطه تاني")
        else:
            fw_l.config(text="لو الموبايل مش لاقي الكمبيوتر: غالبًا الجدار الناري (Firewall) مانعه.\n"
                             "دوس الزرار ووافق على رسالة ويندوز — بيسمح للبرنامج ده بس ومن شبكة البيت بس.", fg=muted)
            fw_b.config(text="اسمح في الجدار الناري")

    def fw_do():
        if firewall_allow():
            log("اتطلبت صلاحية الجدار الناري — وافق على رسالة ويندوز")
            root.after(4000, fw_refresh)
            root.after(12000, fw_refresh)
        else:
            log("الجدار الناري: اتلغت أو ويندوز رفض")

    fw_b = tk.Button(fw_box, text="اسمح في الجدار الناري", command=fw_do)
    fw_b.pack(pady=(0, 6))
    if IS_WIN:
        fw_refresh()
    else:
        fw_box.pack_forget()

    # ---- التشغيل مع ويندوز
    start_v = tk.BooleanVar(value=startup_get())

    def start_toggle():
        try:
            startup_set(start_v.get())
            log("هيشتغل لوحده مع ويندوز ✓" if start_v.get() else "مش هيشتغل مع ويندوز")
        except Exception as e:
            start_v.set(startup_get())
            log("مقدرتش أغيّر التشغيل مع ويندوز: %s" % e)

    tk.Checkbutton(root, text="يشتغل لوحده مع ويندوز (مستخبي جنب الساعة)", variable=start_v, command=start_toggle,
                   fg=fg, bg="#14171D", selectcolor="#14171D", activebackground="#14171D", activeforeground=fg,
                   font=("Segoe UI", 9)).pack(pady=(6, 0))

    # ---- أيقونة جنب الساعة: قفل الشباك = يستخبى، والبرنامج يفضل شغال
    tray = {"icon": None}

    def really_quit():
        try:
            if tray["icon"] is not None:
                tray["icon"].stop()
        except Exception:
            pass
        root.destroy()

    def show_window():
        root.deiconify()
        root.lift()
        try:
            root.focus_force()
        except Exception:
            pass

    try:
        import pystray

        icon = pystray.Icon("A2R PC", tray_image(), "A2R PC — شغال", menu=pystray.Menu(
            pystray.MenuItem("افتح الشباك", lambda: root.after(0, show_window), default=True),
            pystray.MenuItem("اقفل البرنامج خالص", lambda: root.after(0, really_quit)),
        ))
        threading.Thread(target=icon.run, daemon=True).start()
        tray["icon"] = icon
    except Exception:
        tray["icon"] = None

    told = {"v": False}

    def on_close():
        if tray["icon"] is not None:
            root.withdraw()
            if not told["v"]:
                told["v"] = True
                try:
                    tray["icon"].notify("البرنامج لسه شغال جنب الساعة — الموبايل يقدر يتحكم. علشان تقفله خالص: كليك يمين على الأيقونة.", "A2R PC")
                except Exception:
                    pass
        else:
            # من غير أيقونة: نصغّر بس، والقفل الحقيقي من الزرار
            root.iconify()

    root.protocol("WM_DELETE_WINDOW", on_close)
    tk.Button(root, text="اقفل البرنامج خالص", command=lambda: messagebox.askyesno(
        "A2R PC", "تقفل البرنامج؟ الموبايل مش هيقدر يتحكم لحد ما تفتحه تاني.") and really_quit(),
              fg=bad).pack(pady=(8, 4))
    tk.Label(root, text="قفل الشباك (X) بيخبيه بس — البرنامج يفضل شغال", fg=muted, bg="#14171D",
             font=("Segoe UI", 8)).pack()

    if "--tray" in sys.argv:
        if tray["icon"] is not None:
            root.withdraw()
        else:
            root.iconify()

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
        if State.show_req:
            State.show_req = False
            show_window()
        root.after(700, tick)

    tick()
    root.mainloop()
    srv.shutdown()


if __name__ == "__main__":
    main()
