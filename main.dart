// A2R Home — تطبيق 3 في 1: الشبكة + الكاست + الريسيفر
// ملف واحد (build.yml بينقله لـ lib/main.dart). المصادر في README.md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show DartPluginRegistrant;

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xml/xml.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;


// ======== ui_shell.dart ========
// ===================== الواجهة =====================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  await Oui.load();
  FlutterError.onError = (d) => AppLog.add('ERR', '${d.exception}');
  runApp(const A2RHome());
}

const Color kGold = Color(0xFFE6B24A);
const Color kBg = Color(0xFF0E1015);
const Color kSurface = Color(0xFF181B22);
const Color kSurface2 = Color(0xFF20242D);
const Color kLine = Color(0x1FFFFFFF);
const Color kMuted = Color(0xFFBFC5D0);
const Color kOk = Color(0xFF4CD08A);
const Color kBad = Color(0xFFFF6B6B);

class A2RHome extends StatelessWidget {
  const A2RHome({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kGold,
      brightness: Brightness.dark,
      primary: kGold,
      onPrimary: const Color(0xFF1A1405),
      surface: kSurface,
    );
    final round = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return MaterialApp(
      title: 'A2R Home',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: AppLockGate(child: w!)),
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: kSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: kLine)),
        ),
        listTileTheme: const ListTileThemeData(iconColor: kGold, contentPadding: EdgeInsets.symmetric(horizontal: 14)),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: round, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: round, foregroundColor: const Color(0xFFF2D28C), side: BorderSide(color: kGold.withValues(alpha: 0.55), width: 1))),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: round)),
        chipTheme: ChipThemeData(
          backgroundColor: kSurface2,
          selectedColor: kGold.withValues(alpha: 0.22),
          side: const BorderSide(color: kLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(round),
            side: const WidgetStatePropertyAll(BorderSide(color: kLine)),
            backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kGold.withValues(alpha: 0.20) : kSurface),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: kSurface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kLine)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGold)),
        ),
        dialogTheme: DialogThemeData(backgroundColor: kSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kSurface2,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: kGold.withValues(alpha: 0.22),
          height: 66,
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontSize: 12.5,
                fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
                color: s.contains(WidgetState.selected) ? kGold : kMuted,
              )),
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? kGold : kMuted)),
        ),
        dividerTheme: const DividerThemeData(color: kLine, space: 1),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: kGold),
      ),
      home: const Shell(),
    );
  }
}


/// زرار مربع بأيقونة وتحتها اسمه (شبكة 4 في الصف)
class _ActTile extends StatelessWidget {
  final IconData icon;
  final Widget label;
  final VoidCallback? onTap;
  const _ActTile({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 24 - 24 - 24) / 4;
    return SizedBox(
      width: w,
      child: Material(
        color: kSurface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 24, color: kGold),
              const SizedBox(height: 6),
              DefaultTextStyle.merge(style: const TextStyle(fontSize: 12, height: 1.25), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, child: label),
            ]),
          ),
        ),
      ),
    );
  }
}

/// حالة الاتصال الحالية (بتتحدث من كل تبويب) — بيعرضها الشريط اللي فوق
class Live {
  static bool router = false;
  static bool pc = false;
}

class StatusStrip extends StatefulWidget {
  const StatusStrip({super.key});
  @override
  State<StatusStrip> createState() => _StatusStripState();
}

class _StatusStripState extends State<StatusStrip> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _dot(String name, bool on) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: on ? kOk : kBad, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$name ${on ? 'متصل' : 'مش متصل'}', style: const TextStyle(fontSize: 13)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _dot('الراوتر', Live.router),
        _dot('الريسيفر', GmClient.active?.connected ?? false),
        _dot('الكمبيوتر', Live.pc),
      ]),
    );
  }
}

/// عنوان قسم صغير فوق الكروت
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: kGold), const SizedBox(width: 6)],
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// شكل "مفيش حاجة هنا" بأيقونة كبيرة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.hint, this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: kGold.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: kGold),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: kMuted)),
            ],
            if (action != null) ...[const SizedBox(height: 14), action!],
          ]),
        ),
      );
}

/// علامة صغيرة ملونة (HD، مشفرة، …)
class Badge2 extends StatelessWidget {
  final String text;
  final Color color;
  const Badge2(this.text, {super.key, this.color = kGold});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsetsDirectional.only(start: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

void toast(BuildContext c, String m) {
  if (!c.mounted) return;
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
}

Future<String?> askText(BuildContext c, String title, {String initial = '', String hint = '', bool obscure = false, TextInputType? type}) {
  final t = TextEditingController(text: initial);
  return showDialog<String>(
    context: c,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(controller: t, autofocus: true, obscureText: obscure, keyboardType: type, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(d, t.text), child: const Text('تمام')),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext c, String msg) async =>
    await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('لأ')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('أيوه')),
        ],
      ),
    ) ==
    true;

Future<void> shareLog() async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/a2r-home-log.txt');
  await f.writeAsString(AppLog.I.dump());
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'A2R Home log'));
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

/// قناة مطلوبة من اختصار الشاشة الرئيسية ("0:ProgramId" تلفزيون / "1:ProgramId" راديو)
final ValueNotifier<String?> kOpenChannel = ValueNotifier(null);

/// زرار من إشعار الريموت والتطبيق مفتوح
Future<void> sendRemoteKey(int k) async {
  final g = GmClient.active;
  if (g != null && g.connected) {
    await g.key(k);
  } else {
    final r = await Bg.run({'type': 'key', 'key': k});
    AppLog.add('STB', 'notif key $r');
  }
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  void initState() {
    super.initState();
    Native.askNotifyPermission();
    Native4.listen(
      openChannel: (d) async {
        if (mounted) setState(() => tab = 2);
        kOpenChannel.value = d;
      },
      notifKey: sendRemoteKey,
    );
    Native4.initialAction().then((d) {
      if (d != null && d.isNotEmpty && mounted) {
        setState(() => tab = 2);
        kOpenChannel.value = d;
      }
    });
    // المنبهات بتتمسح لو التطبيق اتحدّث — نرجّعها
    Schedule.rearm();
    Quota.rearm();
    NetWatch.rearm();
    ShareIn.init(context, (t) {
      if (mounted) setState(() => tab = t);
    });
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['الشبكة', 'العرض على التلفزيون', 'الريسيفر', 'الكمبيوتر'];
    const icons = [Icons.router_rounded, Icons.cast_rounded, Icons.satellite_alt_rounded, Icons.desktop_windows_rounded];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF2C766), Color(0xFFB8862A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icons[tab], color: const Color(0xFF1A1405), size: 22),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titles[tab]),
            Text('A2R Home • $appVersion', style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w400)),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: 'السجل',
            icon: const Icon(Icons.receipt_long_rounded, color: kMuted),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogPage())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        const StatusStrip(),
        Expanded(child: IndexedStack(index: tab, children: const [NetworkPage(), CastPage(), ReceiverPage(), PcPage()])),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => tab = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.router_outlined), selectedIcon: Icon(Icons.router_rounded), label: 'الشبكة'),
          NavigationDestination(icon: Icon(Icons.cast_outlined), selectedIcon: Icon(Icons.cast_rounded), label: 'الكاست'),
          NavigationDestination(icon: Icon(Icons.satellite_alt_outlined), selectedIcon: Icon(Icons.satellite_alt_rounded), label: 'الريسيفر'),
          NavigationDestination(icon: Icon(Icons.desktop_windows_outlined), selectedIcon: Icon(Icons.desktop_windows_rounded), label: 'الكمبيوتر'),
        ],
      ),
    );
  }
}

// ---------------- السجل ----------------
class LogPage extends StatefulWidget {
  const LogPage({super.key});
  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  String? tag;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل التشخيص'), actions: [
        IconButton(icon: const Icon(Icons.share), tooltip: 'شارك السجل', onPressed: shareLog),
        IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'امسح',
            onPressed: () => AppLog.I.clear()),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Wrap(spacing: 6, children: [
            for (final t in [null, 'ROUTER', 'LAN', 'CAST', 'STB', 'ERR'])
              ChoiceChip(label: Text(t ?? 'الكل'), selected: tag == t, onSelected: (_) => setState(() => tag = t)),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('الباسوردات بتتشال من السجل قبل الحفظ. لو حاجة مش شغالة، ابعت السجل ده.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: AppLog.I,
            builder: (c, _) {
              final l = AppLog.I.lines.where((e) => tag == null || e.tag == tag).toList().reversed.toList();
              return ListView.builder(
                itemCount: l.length,
                itemBuilder: (c, i) => Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: SelectableText(l[i].toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}


// ======== ui_net.dart ========
// ---------------- الشبكة ----------------
class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});
  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> with AutomaticKeepAliveClientMixin {
  PhoneNet? net;
  ZteRouter? router;
  String routerMsg = '';
  Map<String, dynamic> st = {};
  final Map<String, LanHost> hosts = {}; // key = ip
  List<String> blockedMacs = [];
  bool scanning = false;
  double progress = 0;
  Timer? auto;
  bool autoOn = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    auto?.cancel();
    router?.close();
    super.dispose();
  }

  Future<void> _start() async {
    net = await readPhoneNet();
    if (mounted) setState(() {});
    await _autoLogin();
    await refresh();
    auto = Timer.periodic(const Duration(seconds: 60), (_) {
      if (autoOn && !scanning) refresh(quiet: true);
    });
  }

  /// يدور على الراوتر: العنوان المحفوظ ← بوابة الواي فاي ← عناوين مشهورة
  Future<String?> findRouter() async {
    final c = gatewayCandidates(net?.ip, net?.gateway, Store.routerIp);
    AppLog.add('ROUTER', 'candidates $c');
    for (final ip in c) {
      final v = await ZteRouter.probe(ip);
      if (v != null) return ip;
    }
    return null;
  }

  Future<void> _autoLogin() async {
    final pw = await Store.routerPassword();
    if (pw == null || pw.isEmpty) {
      routerMsg = 'سجّل دخول الراوتر علشان تشوف الـ MAC وتحظر أجهزة';
      if (mounted) setState(() {});
      return;
    }
    final ip = Store.routerIp ?? await findRouter();
    if (ip == null) {
      routerMsg = 'ملقتش الراوتر — اكتب عنوانه بنفسك';
      if (mounted) setState(() {});
      return;
    }
    await _login(ip, pw, quiet: true);
  }

  Future<bool> _login(String ip, String pw, {bool quiet = false}) async {
    router?.close();
    final r = ZteRouter(ip);
    try {
      final res = await r.login(pw, force: schemeFromName(Store.loginScheme));
      if (!res.ok) {
        routerMsg = res.message;
        if (mounted) setState(() {});
        if (!quiet && mounted) toast(context, res.message);
        return false;
      }
      router = r;
      Store.routerIp = ip;
      Store.p.setBool('router_last_ok', true);
      routerMsg = 'متصل بالراوتر ($ip) — ${r.scheme?.name}';
      if (mounted) setState(() {});
      return true;
    } catch (e) {
      routerMsg = 'مقدرتش أكلم الراوتر على $ip: $e';
      if (mounted) setState(() {});
      return false;
    }
  }

  Future<void> loginDialog() async {
    var ip = Store.routerIp ?? net?.gateway ?? '';
    final ipC = TextEditingController(text: ip);
    final pwC = TextEditingController();
    var scheme = Store.loginScheme;
    var show = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, ss) => AlertDialog(
          title: const Text('دخول الراوتر'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ipC,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'عنوان الراوتر'),
                  ),
                ),
                IconButton(
                  tooltip: 'دوّر عليه',
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    Store.routerIp = null;
                    final f = await findRouter();
                    if (f != null) ipC.text = f;
                    if (d.mounted) toast(d, f == null ? 'ملقتش راوتر ZTE' : 'لقيته: $f');
                  },
                ),
              ]),
              const SizedBox(height: 4),
              Text('بوابة الواي فاي: ${net?.gateway ?? '؟'}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 10),
              TextField(
                controller: pwC,
                obscureText: !show,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'باسورد صفحة الراوتر (بتاعك)',
                  suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility), onPressed: () => ss(() => show = !show)),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: scheme,
                decoration: const InputDecoration(labelText: 'طريقة الدخول'),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تلقائي (مستحسن)')),
                  DropdownMenuItem(value: 'base64Md5', child: Text('قديم: Base64')),
                  DropdownMenuItem(value: 'sha256Md5', child: Text('جديد: SHA256 + LD')),
                  DropdownMenuItem(value: 'sha256Sha256', child: Text('SHA256 كامل')),
                ],
                onChanged: (v) => scheme = v ?? 'auto',
              ),
              const SizedBox(height: 6),
              const Text('الباسورد بيتحفظ مشفّر على الموبايل بس. انتبه: الراوتر بيقفل الدخول بعد كام محاولة غلط.',
                  style: TextStyle(fontSize: 12, color: Colors.white60)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('دخول')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    ip = ipC.text.trim();
    if (ip.isEmpty || pwC.text.isEmpty) {
      if (mounted) toast(context, 'اكتب العنوان والباسورد');
      return;
    }
    Store.loginScheme = scheme;
    if (await _login(ip, pwC.text)) {
      await Store.saveRouterPassword(pwC.text);
      await refresh();
    }
  }

  Future<void> logout() async {
    await Store.saveRouterPassword(null);
    router?.close();
    router = null;
    st = {};
    routerMsg = 'اتمسح باسورد الراوتر';
    setState(() {});
  }

  Future<void> refresh({bool quiet = false}) async {
    final before = hosts.keys.toSet();
    if (router != null) {
      try {
        if (!await router!.isLoggedIn()) {
          final pw = await Store.routerPassword();
          if (pw != null) await _login(router!.host, pw, quiet: true);
        }
        st = await router!.status();
        unawaited(NetLog.sample(st, source: 'app'));
        final list = await router!.stations();
        try {
          blockedMacs = (await router!.blockList()).macs;
        } catch (_) {}
        unawaited(DeviceWatch.update({for (final s in list) s.mac.isNotEmpty ? s.mac : s.ip}));
        unawaited(NewDevAlert.check(list));
        for (final s in list) {
          final key = s.ip.isEmpty ? s.mac : s.ip;
          final h = hosts.putIfAbsent(key, () => LanHost(key, source: 'router'));
          h.mac = s.mac;
          if (!isBadHostName(s.hostname)) {
            h.name = s.hostname;
            h.nameSrc = 'router';
            unawaited(NameCache.put(s.mac.isNotEmpty ? s.mac : s.ip, s.hostname, 'router'));
          } else if (isBadHostName(h.name)) {
            h.name = '';
          }
          h.wifi = s.wifi;
          h.connectTime = s.connectTime;
          h.vendor = Oui.vendorOf(s.mac);
          if (h.source == 'scan') h.source = 'both';
        }
      } catch (e) {
        AppLog.add('ROUTER', 'refresh error $e');
        routerMsg = 'خطأ مع الراوتر: $e';
      }
    }
    if (!quiet || router == null) await scan(silentNotify: before.isEmpty);
    // v5: الأجهزة اللي الراوتر رجّعلها "--" → NetBIOS / mDNS / DNS / المحفوظ
    try {
      if (Oui.table.isEmpty && !Store.p.containsKey('oui_auto_tried')) {
        await Store.p.setBool('oui_auto_tried', true);
        unawaited(Oui.download().then((_) {
          for (final h in hosts.values) {
            h.vendor = Oui.vendorOf(h.mac);
          }
          if (mounted) setState(() {});
        }).catchError((e) {
          AppLog.add('LAN', 'OUI auto ✗ $e');
        }));
      }
      final n = await resolveMissingNames(hosts.values.toList(), routerIp: router?.host ?? net?.gateway);
      if (n > 0) AppLog.add('NAMES', 'لقيت $n اسم زيادة');
    } catch (e) {
      AppLog.add('NAMES', 'resolve ✗ $e');
    }
    _checkNew(before);
    // v4: سجل الأجهزة + الباقة + المواعيد
    try {
      await DeviceHistory.update([for (final h in hosts.values) (key: h.mac.isNotEmpty ? h.mac : h.ip, name: (Store.deviceNames[h.mac] ?? (isBadHostName(h.name) ? '' : h.name)), ip: h.ip)]);
      if (router != null) {
        final total = (int.tryParse('${st['monthly_tx_bytes'] ?? ''}') ?? 0) + (int.tryParse('${st['monthly_rx_bytes'] ?? ''}') ?? 0);
        await Quota.sample(total);
        if (Schedule.rules.isNotEmpty) {
          final m = await Schedule.syncRouter(router: router);
          if (m.startsWith('تم')) blockedMacs = (await router!.blockList()).macs;
        }
      }
    } catch (e) {
      AppLog.add('ROUTER', 'v4 refresh $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> scan({bool silentNotify = false}) async {
    if (scanning) return;
    net ??= await readPhoneNet();
    final prefix = net!.prefix;
    if (prefix.isEmpty) {
      if (mounted) toast(context, 'الموبايل مش متوصل بواي فاي');
      return;
    }
    setState(() {
      scanning = true;
      progress = 0;
    });
    final res = await scanLan(prefix, onProgress: (p) {
      if (mounted) setState(() => progress = p);
    }, onFound: (h) {
      final ex = hosts[h.ip];
      if (ex == null) {
        hosts[h.ip] = h;
      } else {
        ex.openPorts.addAll(h.openPorts);
        ex.pingMs = h.pingMs;
        if (ex.source == 'router') ex.source = 'both';
      }
      if (mounted) setState(() {});
    });
    for (final h in res) {
      final t = hosts[h.ip];
      if (t != null && !isBadHostName(h.name) && isBadHostName(t.name)) {
        t.name = cleanHostName(h.name);
        t.nameSrc = h.nameSrc.isEmpty ? 'netbios' : h.nameSrc;
      }
    }
    if (mounted) setState(() => scanning = false);
  }

  void _checkNew(Set<String> before) {
    final known = Store.knownDevices;
    final keys = hosts.values.map((h) => h.mac.isNotEmpty ? h.mac : h.ip).toList();
    if (known.isEmpty) {
      Store.addKnown(keys);
      return;
    }
    final fresh = hosts.values.where((h) => !known.contains(h.mac.isNotEmpty ? h.mac : h.ip) && h.ip != net?.ip).toList();
    for (final h in fresh) {
      h.isNew = true;
      final n = label(h);
      Native.notify('جهاز جديد على الشبكة', '$n — ${h.ip}${h.mac.isEmpty ? '' : ' — ${h.mac}'}');
    }
    if (fresh.isNotEmpty) Store.addKnown(keys);
  }

  String label(LanHost h) {
    final names = Store.deviceNames;
    final custom = names[h.mac] ?? names[h.ip];
    if (custom != null && custom.trim().isNotEmpty) return custom;
    if (!isBadHostName(h.name)) return h.name;
    final c = NameCache.of(h.mac.isNotEmpty ? h.mac : h.ip);
    if (c != null) return c.name;
    final isMe = h.ip == net?.ip, isGw = h.ip == (router?.host ?? net?.gateway);
    return fallbackDeviceName(guessDeviceType(h.name, h.vendor, h.openPorts, isGateway: isGw, isMe: isMe), h.vendor);
  }

  int ipNum(String ip) {
    final p = ip.split('.');
    return p.length == 4 ? (int.tryParse(p[3]) ?? 999) : 999;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = hosts.values.toList()..sort((a, b) => ipNum(a.ip).compareTo(ipNum(b.ip)));
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(children: [
        _infoCard(),
        Card(
          child: ListTile(
            leading: const Icon(Icons.wifi_tethering_rounded, color: kGold),
            title: const Text('الأكسس بوينت (TOTOLINK)'),
            subtitle: Text('${TotoStore.ip}${TotoStore.macs.isEmpty ? '' : ' • ${TotoStore.macs.length} جهاز عليه'}', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => TotoPage(router: router, hosts: hosts.values.toList(), labelOf: label)));
              if (mounted) setState(() {});
            },
          ),
        ),
        _routerCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            Text('الأجهزة (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            if (scanning) SizedBox(width: 80, child: LinearProgressIndicator(value: progress)),
            IconButton(icon: const Icon(Icons.radar), tooltip: 'افحص الشبكة', onPressed: scanning ? null : () => refresh()),
          ]),
        ),
        if (router == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('أندرويد 10+ مش بيدّي الـ MAC بتاع الأجهزة التانية — الـ MAC والحظر محتاجين دخول الراوتر.',
                style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
          ),
        for (final h in list) _hostTile(h),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _infoCard() {
    final n = net;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 18, runSpacing: 6, children: [
          _kv('الواي فاي', n?.ssid ?? 'مش متصل بواي فاي'),
          _kv('IP الموبايل', n?.ip ?? 'مش متصل'),
          _kv('البوابة', n?.gateway ?? 'مش متصل'),
          _kv('النسخة', appVersion),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
          _ActTile(icon: Icons.speed, label: const Text('سرعة النت'), onTap: _speed),
          _ActTile(icon: Icons.network_ping, label: const Text('Ping'), onTap: () => _pingAsk()),
          _ActTile(icon: Icons.power_settings_new, label: const Text('تشغيل جهاز (WOL)'), onTap: () => _wol(null)),
          _ActTile(icon: Icons.qr_code_2_rounded, label: const Text('QR الواي فاي'), onTap: _qr),
          _ActTile(icon: Icons.monitor_heart_rounded, label: const Text('مراقبة الأجهزة'), onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceWatchPage(hosts: hosts.values.toList(), labelOf: label)));
            if (mounted) setState(() {});
          }),
          _ActTile(icon: Icons.show_chart_rounded, label: const Text('سجل الإشارة والسرعة'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignalHistoryPage()))),
          _ActTile(icon: Icons.settings_backup_restore_rounded, label: const Text('نسخة احتياطية + قفل'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage()))),
          _ActTile(icon: Icons.schedule_rounded, label: const Text('مواعيد الحظر'), onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => SchedulePage(router: router, devices: [
                  for (final h in hosts.values)
                    if (h.mac.isNotEmpty) (mac: h.mac, name: label(h))
                ])));
            if (mounted) setState(() {});
          }),
          _ActTile(icon: Icons.data_usage_rounded, label: const Text('باقة النت'), onTap: () {
            final total = (int.tryParse('${st['monthly_tx_bytes'] ?? ''}') ?? 0) + (int.tryParse('${st['monthly_rx_bytes'] ?? ''}') ?? 0);
            Navigator.push(context, MaterialPageRoute(builder: (_) => QuotaPage(routerTotal: router == null ? null : total)));
          }),
          _ActTile(icon: Icons.history_rounded, label: const Text('سجل الأجهزة'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
          _ActTile(icon: Icons.business, label: Text(Oui.table.isEmpty ? 'نزّل أسماء الشركات' : 'شركات: ${Oui.table.length}'), onTap: () async {
              toast(context, 'بنزّل القايمة (حوالي 6 ميجا)…');
              try {
                final n = await Oui.download();
                for (final h in hosts.values) {
                  h.vendor = Oui.vendorOf(h.mac);
                }
                if (mounted) toast(context, 'تم: $n شركة');
                setState(() {});
              } catch (e) {
                if (mounted) toast(context, 'فشل: $e');
              }
            },
          ),
        ]),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(k, style: const TextStyle(fontSize: 11, color: kMuted)),
        Text(v, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]);

  Widget _routerCard() {
    final r = router;
    Live.router = r != null;
    if (r == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.router),
          title: const Text('الراوتر (ZTE MF286R1)'),
          subtitle: Text(routerMsg.isEmpty ? 'مش متصل' : routerMsg),
          trailing: FilledButton(onPressed: loginDialog, child: const Text('دخول')),
        ),
      );
    }
    String g(String k) => '${st[k] ?? ''}';
    String gAny(List<String> ks) {
      for (final k in ks) {
        final v = g(k).trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }
    final tx = int.tryParse(g('monthly_tx_bytes')) ?? 0, rx = int.tryParse(g('monthly_rx_bytes')) ?? 0;
    final upK = (int.tryParse(g('realtime_tx_thrpt')) ?? 0) * 8 / 1000, downK = (int.tryParse(g('realtime_rx_thrpt')) ?? 0) * 8 / 1000;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.router, color: kGold),
            const SizedBox(width: 8),
            Expanded(child: Text(routerMsg, style: const TextStyle(fontSize: 12))),
            PopupMenuButton<String>(
              onSelected: _routerAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'sms', child: Text('الرسايل SMS')),
                PopupMenuItem(value: 'wifi', child: Text('باسورد الواي فاي')),
                PopupMenuItem(value: 'qr', child: Text('QR الواي فاي (للضيوف)')),
                PopupMenuItem(value: 'wifi_off', child: Text('قفل الواي فاي (تجريبي)')),
                PopupMenuItem(value: 'wifi_on', child: Text('فتح الواي فاي (تجريبي)')),
                PopupMenuItem(value: 'dns', child: Text('DNS الراوتر (تجريبي)')),
                PopupMenuItem(value: 'signal', child: Text('سجل الإشارة + الانقطاعات')),
                PopupMenuItem(value: 'place', child: Text('مكان الراوتر (أحسن إشارة)')),
                PopupMenuItem(value: 'reboot', child: Text('ريستارت الراوتر')),
                PopupMenuItem(value: 'login', child: Text('تغيير العنوان/الباسورد')),
                PopupMenuItem(value: 'logout', child: Text('امسح الباسورد')),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 18, runSpacing: 6, children: [
            _kv('الشبكة', '${g('network_provider')} ${g('network_type')}'),
            _kv('الإشارة', '${g('signalbar')}/5'),
            _kv('RSRP', g('lte_rsrp')),
            _kv('RSRQ', gAny(['lte_rsrq', 'Z4g_rsrq', 'lte_ca_pcell_rsrq'])),
            _kv('SINR', gAny(['lte_snr', 'Z4g_SINR', 'lte_sinr', 'Z5g_SINR'])),
            _kv('Band', gAny(['lte_band', 'lte_ca_pcell_band', 'wan_active_band', 'lte_main_band'])),
            _kv('IP الخارجي', g('wan_ipaddr')),
            _kv('دلوقتي ↓/↑', '${downK.toStringAsFixed(0)}/${upK.toStringAsFixed(0)} kbps'),
            _kv('استهلاك الشهر', fmtBytes(tx + rx)),
            if (g('sms_unread_num').isNotEmpty && g('sms_unread_num') != '0') _kv('رسايل جديدة', g('sms_unread_num')),
          ]),
          if (g('lte_rsrp').isNotEmpty) _signalHint(int.tryParse(g('lte_rsrp')) ?? 0),
        ]),
      ),
    );
  }

  Widget _signalHint(int rsrp) {
    final s = rsrp >= -80
        ? 'إشارة ممتازة'
        : rsrp >= -90
            ? 'إشارة كويسة'
            : rsrp >= -100
                ? 'إشارة متوسطة — جرب تحرك الراوتر جنب الشباك'
                : 'إشارة ضعيفة — حرّك الراوتر لمكان أعلى أو جنب الشباك';
    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white70)));
  }

  Future<void> _routerAction(String a) async {
    final r = router;
    if (r == null) return;
    try {
      switch (a) {
        case 'sms':
          await Navigator.push(context, MaterialPageRoute(builder: (_) => SmsPage(router: r)));
        case 'qr':
          await _qr();
        case 'wifi':
          final w = await r.wifiInfo();
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (d) => AlertDialog(
              title: const Text('الواي فاي'),
              content: SelectableText('الاسم: ${w.ssid}\nالباسورد: ${w.key.isEmpty ? '(الراوتر مرجّعهوش)' : w.key}'),
              actions: [
                TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: w.key)), child: const Text('انسخ')),
                TextButton(onPressed: () => Navigator.pop(d), child: const Text('تمام')),
              ],
            ),
          );
        case 'wifi_off':
        case 'wifi_on':
          final on = a == 'wifi_on';
          if (!on && !await confirm(context, 'لو قفلت الواي فاي الموبايل ده هيفصل كمان (لو متوصل بالواي فاي). متأكد؟')) return;
          final res = await r.set('SET_WIFI_INFO', {'wifiEnabled': on ? '1' : '0'});
          if (mounted) toast(context, 'رد الراوتر: ${res['result']}');
        case 'dns':
          await Navigator.push(context, MaterialPageRoute(builder: (_) => RouterDnsPage(router: r)));
        case 'signal':
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SignalHistoryPage()));
        case 'place':
          await Navigator.push(context, MaterialPageRoute(builder: (_) => RouterPlacePage(router: r)));
        case 'reboot':
          if (!await confirm(context, 'ريستارت للراوتر؟ النت هيقطع دقيقة أو اتنين.')) return;
          final ok = await r.reboot();
          if (mounted) toast(context, ok ? 'الراوتر بيعمل ريستارت' : 'الراوتر مردش بنجاح — شوف السجل');
        case 'login':
          await loginDialog();
        case 'logout':
          await logout();
      }
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  Widget _hostTile(LanHost h) {
    final isMe = h.ip == net?.ip, isGw = h.ip == (router?.host ?? net?.gateway);
    final type = guessDeviceType(h.name, h.vendor, h.openPorts, isGateway: isGw, isMe: isMe);
    final blocked = h.mac.isNotEmpty && blockedMacs.contains(h.mac);
    final sub = [
      type,
      if (h.mac.isNotEmpty) h.mac,
      if (h.vendor.isNotEmpty) h.vendor,
      if (h.vendor.isEmpty && isRandomMac(h.mac)) 'MAC عشوائي',
      if (h.nameSrc.isNotEmpty && !Store.deviceNames.containsKey(h.mac)) 'الاسم ${kNameSrcAr[h.nameSrc] ?? h.nameSrc}',
      if (h.source != 'scan') (h.wifi ? 'واي فاي' : 'كابل'),
      if (h.mac.isNotEmpty && TotoStore.macs.contains(h.mac)) 'عن طريق الأكسس',
      if (h.connectTime.isNotEmpty) 'متصل من ${_dur(h.connectTime)}',
    ].join(' • ');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: blocked ? Colors.red.shade900 : (h.isNew ? Colors.green.shade800 : const Color(0xFF2A2E35)),
          child: Icon(_icon(type), color: kGold),
        ),
        title: Row(children: [
          Flexible(child: Text(label(h), overflow: TextOverflow.ellipsis)),
          if (h.isNew) const Padding(padding: EdgeInsets.only(right: 6), child: Text('جديد', style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
          if (blocked) const Padding(padding: EdgeInsets.only(right: 6), child: Text('محظور', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
        ]),
        subtitle: Text('${h.ip}\n$sub', style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        onTap: () => _hostSheet(h, blocked, isMe),
      ),
    );
  }

  String _dur(String secs) {
    final s = int.tryParse(secs);
    if (s == null) return secs;
    if (s < 3600) return '${s ~/ 60} دقيقة';
    if (s < 86400) return '${s ~/ 3600} ساعة';
    return '${s ~/ 86400} يوم';
  }

  IconData _icon(String t) {
    switch (t) {
      case 'موبايل':
      case 'آيفون / أبل':
        return Icons.smartphone;
      case 'الراوتر':
        return Icons.router;
      case 'تلفزيون / شاشة':
        return Icons.tv;
      case 'ريسيفر':
      case 'كاميرا / ريسيفر':
        return Icons.satellite_alt;
      case 'كمبيوتر':
        return Icons.computer;
      case 'طابعة':
        return Icons.print;
      case 'الموبايل ده':
        return Icons.person_pin;
      default:
        return Icons.devices_other;
    }
  }

  Future<void> _hostSheet(LanHost h, bool blocked, bool isMe) async {
    await showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          ListTile(title: Text(label(h)), subtitle: Text('${h.ip}  ${h.mac}', textDirection: TextDirection.ltr)),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('سمّي الجهاز'),
            onTap: () async {
              Navigator.pop(c);
              final n = await askText(context, 'اسم الجهاز', initial: label(h));
              if (n != null) {
                await Store.setDeviceName(h.mac.isNotEmpty ? h.mac : h.ip, n);
                setState(() {});
              }
            },
          ),
          if (router != null && h.mac.isNotEmpty && !isMe)
            ListTile(
              leading: Icon(blocked ? Icons.lock_open : Icons.block, color: blocked ? Colors.green : Colors.redAccent),
              title: Text(blocked ? 'فك الحظر' : 'احظر من الواي فاي'),
              subtitle: const Text('عن طريق فلتر MAC في الراوتر (القايمة السودا)'),
              onTap: () async {
                Navigator.pop(c);
                if (!blocked && !await confirm(context, 'تحظر "${label(h)}" من الواي فاي؟')) return;
                try {
                  final ok = await router!.setBlocked(h.mac, label(h), !blocked);
                  if (mounted) toast(context, ok ? 'تم' : 'الراوتر مأكدش — شوف السجل');
                  await refresh(quiet: true);
                } catch (e) {
                  if (mounted) toast(context, 'خطأ: $e');
                }
              },
            ),
          ListTile(leading: const Icon(Icons.network_ping), title: const Text('Ping'), onTap: () {
            Navigator.pop(c);
            _ping(h.ip);
          }),
          if (!isMe)
            ListTile(
              leading: Icon(DeviceWatch.has(h.mac.isNotEmpty ? h.mac : h.ip) ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: kGold),
              title: Text(DeviceWatch.has(h.mac.isNotEmpty ? h.mac : h.ip) ? 'بطّل مراقبة الجهاز ده' : 'راقب الجهاز ده (إشعار لما يدخل/يخرج)'),
              onTap: () async {
                Navigator.pop(c);
                final k = h.mac.isNotEmpty ? h.mac : h.ip;
                final on = !DeviceWatch.has(k);
                await DeviceWatch.set(k, on ? label(h) : null, ip: h.ip);
                if (on) await Native.askNotifyPermission();
                if (mounted) toast(context, on ? 'هبعتلك إشعار لما «${label(h)}» يدخل أو يخرج من الشبكة' : 'اتشال من المراقبة');
                setState(() {});
              },
            ),
          ListTile(leading: const Icon(Icons.lan), title: const Text('فحص البورتات'), onTap: () async {
            Navigator.pop(c);
            toast(context, 'بفحص…');
            final p = await portScan(h.ip);
            h.openPorts.addAll(p);
            if (!mounted) return;
            setState(() {});
            await showDialog(
              context: context,
              builder: (d) => AlertDialog(
                title: Text('البورتات المفتوحة ${h.ip}'),
                content: Text(p.isEmpty ? 'مفيش بورتات مفتوحة من المشهورة' : p.map((e) => '$e  ${kPortNames[e] ?? ''}').join('\n')),
              ),
            );
          }),
          if (h.mac.isNotEmpty)
            ListTile(leading: const Icon(Icons.power_settings_new), title: const Text('شغّله عن بعد (WOL)'), onTap: () {
              Navigator.pop(c);
              _wol(h.mac);
            }),
          if (h.openPorts.contains(80) || h.openPorts.contains(8080))
            ListTile(leading: const Icon(Icons.open_in_browser), title: const Text('افتح صفحته'), onTap: () {
              Navigator.pop(c);
              launchUrl(Uri.parse('http://${h.ip}${h.openPorts.contains(80) ? '' : ':8080'}'), mode: LaunchMode.externalApplication);
            }),
          ListTile(leading: const Icon(Icons.copy), title: const Text('انسخ البيانات'), onTap: () {
            Clipboard.setData(ClipboardData(text: '${label(h)} ${h.ip} ${h.mac} ${h.vendor}'));
            Navigator.pop(c);
          }),
        ]),
      ),
    );
  }

  Future<void> _qr() async {
    var ssid = net?.ssid ?? '', pw = '';
    if (router != null) {
      try {
        final w = await router!.wifiInfo();
        if (w.ssid.isNotEmpty) ssid = w.ssid;
        pw = w.key;
      } catch (_) {}
    }
    if (mounted) await showWifiQr(context, ssid: ssid.replaceAll('"', ''), password: pw);
  }

  Future<void> _pingAsk() async {
    final ip = await askText(context, 'Ping لعنوان', initial: '8.8.8.8');
    if (ip != null && ip.trim().isNotEmpty) await _ping(ip.trim());
  }

  Future<void> _ping(String ip) async {
    final res = <String>[];
    for (var i = 0; i < 4; i++) {
      final ms = await pingOnce(ip);
      res.add(ms == null ? 'مفيش رد' : '$ms ms');
    }
    AppLog.add('LAN', 'ping $ip $res');
    if (mounted) toast(context, 'Ping $ip: ${res.join(' ، ')}');
  }

  Future<void> _wol(String? mac) async {
    mac ??= await askText(context, 'MAC الجهاز', hint: 'AA:BB:CC:DD:EE:FF');
    if (mac == null || mac.trim().isEmpty) return;
    try {
      await sendWol(mac.trim(), broadcast: net?.broadcast ?? '255.255.255.255');
      if (mounted) toast(context, 'اتبعت أمر التشغيل (الجهاز لازم يكون مفعّل Wake-on-LAN)');
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  Future<void> _speed() async {
    final v = ValueNotifier<double>(0);
    var done = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        title: const Text('سرعة التنزيل'),
        content: ValueListenableBuilder<double>(
          valueListenable: v,
          builder: (c, x, _) => Text('${x.toStringAsFixed(1)} ميجابت/ث', style: const TextStyle(fontSize: 28, color: kGold)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('قفل'))],
      ),
    );
    try {
      v.value = await speedTest(onTick: (m) {
        if (!done) v.value = m;
      });
      await SpeedLog.add(v.value);
    } catch (e) {
      if (mounted) toast(context, 'فشل الاختبار: $e');
    }
    done = true;
  }
}

// ---------------- الرسايل ----------------
class SmsPage extends StatefulWidget {
  final ZteRouter router;
  const SmsPage({super.key, required this.router});
  @override
  State<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> {
  List<ZteSms> msgs = [];
  bool loading = true;
  String err = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      msgs = await widget.router.sms();
      err = '';
    } catch (e) {
      err = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> compose() async {
    final n = TextEditingController(), t = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('رسالة جديدة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الرقم')),
          const SizedBox(height: 8),
          TextField(controller: t, maxLines: 4, decoration: const InputDecoration(labelText: 'الرسالة')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('ابعت')),
        ],
      ),
    );
    if (ok != true || n.text.trim().isEmpty || t.text.isEmpty) return;
    try {
      final r = await widget.router.sendSms(n.text.trim(), t.text);
      if (mounted) toast(context, r ? 'اتبعتت' : 'الراوتر مأكدش الإرسال — شوف السجل');
      await Future.delayed(const Duration(seconds: 2));
      await load();
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسايل الراوتر'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton(onPressed: compose, child: const Icon(Icons.edit)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : err.isNotEmpty
              ? Center(child: Text('مقدرتش أقرا الرسايل: $err'))
              : msgs.isEmpty
                  ? const Center(child: Text('مفيش رسايل'))
                  : ListView(children: [
                      for (final m in msgs)
                        Card(
                          child: ListTile(
                            title: Row(children: [
                              Text(m.number, textDirection: TextDirection.ltr, style: TextStyle(fontWeight: m.unread ? FontWeight.bold : FontWeight.normal)),
                              const Spacer(),
                              Text(m.date == null ? '' : '${m.date!.day}/${m.date!.month} ${m.date!.hour}:${m.date!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11, color: kMuted)),
                            ]),
                            subtitle: SelectableText(m.text),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (!await confirm(context, 'تمسح الرسالة؟')) return;
                                final ok = await widget.router.deleteSms([m.id]);
                                if (mounted) toast(context, ok ? 'اتمسحت' : 'الراوتر مأكدش');
                                await load();
                              },
                            ),
                          ),
                        ),
                    ]),
    );
  }
}


// ======== ui_cast.dart ========
// ---------------- الكاست ----------------
class QueueItem {
  final String title, url;
  final String? subtitle;
  final File? file; // لو من الموبايل
  final Map<String, String> headers; // Referer/User-Agent (للنت)
  bool viaPhone; // يعدّي على سيرفر الموبايل (proxy)
  final String? mime; // لو معروف (روابط يوتيوب مفيهاش امتداد)
  QueueItem(this.title, this.url, {this.subtitle, this.file, this.headers = const {}, this.viaPhone = false, this.mime});
}

/// طريقة العرض على الشاشة
enum CastWay { dlna, gm }

const String kChromeUa = 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36';

class CastState extends ChangeNotifier {
  CastState._();
  static final CastState I = CastState._();
  List<DlnaDevice> devices = [];
  DlnaDevice? current;
  DlnaClient? get client => current == null ? null : DlnaClient(current!);
  final List<QueueItem> queue = [];
  int playing = -1;
  Duration pos = Duration.zero, dur = Duration.zero;
  String state = '';
  String note = ''; // آخر حاجة حصلت (بالعربي)
  int volume = 30;
  bool searching = false;
  bool busy = false;
  CastWay way = CastWay.dlna;
  int _gmMedia = 0;
  String _gmUrl = '';
  int _seq = 0;
  /// كمّلنا الفيديو من الثانية دي (علشان زرار «من الأول»)
  int? resumedFrom;
  DateTime _lastSave = DateTime(2000);

  void _saveResume() {
    if (playing < 0 || playing >= queue.length || state != 'PLAYING') return;
    if (DateTime.now().difference(_lastSave).inSeconds < 10) return;
    _lastSave = DateTime.now();
    ResumeStore.put(ResumeStore.keyOf(queue[playing]), pos, dur);
  }

  Future<void> fromStart() async {
    resumedFrom = null;
    await seek(Duration.zero);
    if (playing >= 0 && playing < queue.length) await ResumeStore.put(ResumeStore.keyOf(queue[playing]), Duration.zero, dur);
    notifyListeners();
  }

  Future<void> _maybeResume(int i) async {
    if (i < 0 || i >= queue.length) return;
    final saved = ResumeStore.get(ResumeStore.keyOf(queue[i]));
    if (saved == null || saved < 30) return;
    try {
      await seek(Duration(seconds: saved));
      resumedFrom = saved;
      _note('كمّلت من ${fmtHms(Duration(seconds: saved))} (زي آخر مرة) — «من الأول» لو عايز تبدأ من الأول');
    } catch (e) {
      AppLog.add('CAST', 'resume seek ✗ $e');
    }
  }

  /// الريسيفر متوصّل في تبويب الريسيفر؟
  GmClient? get gm {
    final g = GmClient.active;
    return (g != null && g.connected) ? g : null;
  }

  bool get gmPossible => gm != null && (current == null || current!.ip == gm!.host);

  Future<void> discover() async {
    searching = true;
    notifyListeners();
    final extra = <String>{
      if (Store.castLocation != null) Store.castLocation!,
      // الـQmax بيعلن الـDLNA على 49152 — بنجربه مباشرة لو الـSSDP اتأخر
      if (Store.receiverIp != null) 'http://${Store.receiverIp}:49152/description.xml',
    };
    devices = await discoverRenderers(extra: extra.toList());
    if (current != null && !devices.any((d) => d.avTransport == current!.avTransport)) devices.insert(0, current!);
    if (current == null && devices.isNotEmpty) {
      // الافتراضي: الريسيفر، وبعده آخر شاشة اتستخدمت
      current = devices.firstWhere((d) => d.isReceiver,
          orElse: () => devices.firstWhere((d) => d.location == Store.castLocation, orElse: () => devices.first));
      _loadVolume();
    }
    if (devices.isEmpty && gm != null) way = CastWay.gm;
    searching = false;
    notifyListeners();
  }

  void select(DlnaDevice? d) {
    current = d;
    if (d != null) Store.castLocation = d.location;
    notifyListeners();
    _loadVolume();
  }

  void _loadVolume() {
    client?.getVolume().then((v) {
      if (v != null) {
        volume = v;
        notifyListeners();
      }
    }).catchError((_) {});
  }

  void setWay(CastWay w) {
    way = w;
    notifyListeners();
  }

  void _note(String s) {
    note = s;
    AppLog.add('CAST', s);
    notifyListeners();
  }

  String? _targetIp() => way == CastWay.gm ? gm?.host : current?.ip;

  /// الرابط اللي الشاشة هتفتحه (مباشر أو عبر الموبايل)
  Future<String> _urlFor(QueueItem q) async {
    final ip = await phoneIpFor(_targetIp());
    if (q.file != null) {
      if (ip == null) throw StateError('الموبايل لازم يكون على نفس الواي فاي بتاع الشاشة');
      return MediaServer.I.share(q.file!, ip);
    }
    if (q.viaPhone) {
      if (ip == null) throw StateError('الموبايل لازم يكون على نفس الواي فاي بتاع الشاشة');
      return MediaServer.I.proxy(q.url, {'User-Agent': kChromeUa, ...q.headers}, ip, mime: q.mime ?? await probeMime(q.url, q.headers));
    }
    return q.url;
  }

  Future<void> playIndex(int i) async {
    if (i < 0 || i >= queue.length) return;
    if (way == CastWay.dlna && client == null) {
      if (gm != null) {
        way = CastWay.gm;
      } else {
        throw StateError('اختار الشاشة الأول (أو اتصل بالريسيفر من تبويب الريسيفر)');
      }
    }
    if (way == CastWay.gm && gm == null) throw StateError('الريسيفر مش متصل — افتح تبويب الريسيفر واتصل الأول');
    final my = ++_seq;
    playing = i;
    resumedFrom = null;
    pos = dur = Duration.zero;
    state = '';
    busy = true;
    notifyListeners();
    final q = queue[i];
    try {
      // الصور: بنحوّلها JPEG ≤1920 بكسل (HEIC/PNG/WebP/صور 12 ميجا الريسيفر مش بيقدر يفتحها)
      final img = q.file != null && isImagePath(q.file!.path) ? await prepareCastImage(q.file!) : null;
      if (img != null) {
        await _castImage(img, q.title, my);
        return;
      }
      final mime = q.file != null ? mimeOf(q.file!.path) : q.mime ?? await probeMime(q.url, q.headers);
      final url = await _urlFor(q);
      _note('بشغّل "${q.title}" ${way == CastWay.gm ? 'بطريقة G-MScreen' : 'على ${current!.name}'}${q.viaPhone ? ' عبر الموبايل' : ''}…');
      if (way == CastWay.gm) {
        _gmMedia = gmMediaTypeFor(mime);
        _gmUrl = url;
        await gm!.castSend(_gmMedia, 0, url);
      } else {
        await client!.load(url, q.title, subtitle: q.subtitle, mime: mime);
      }
      _note('اتبعت للشاشة — مستني يبدأ…');
      unawaited(CastHistory.add(q));
      _watchStart(my, i);
    } catch (e) {
      AppLog.add('CAST', 'play ✗ $e');
      // زي Web Video Caster: لو الرابط المباشر اترفض نجرب عبر الموبايل
      if (q.file == null && !q.viaPhone && q.url.startsWith('http') && my == _seq) {
        _note('الشاشة رفضت الرابط المباشر — بجرب عبر الموبايل…');
        q.viaPhone = true;
        busy = false;
        return playIndex(i);
      }
      // ولو الـDLNA فشل خالص والريسيفر متوصّل نجرب طريقة G-MScreen
      if (way == CastWay.dlna && gmPossible && my == _seq) {
        _note('الـDLNA فشل — بجرب طريقة G-MScreen…');
        way = CastWay.gm;
        busy = false;
        return playIndex(i);
      }
      _note('مقدرتش أشغّل: ${castErrorAr(e)}');
      rethrow;
    } finally {
      if (my == _seq) {
        busy = false;
        notifyListeners();
      }
    }
  }

  /// null = لسه منعرفش، true = الـDLNA بيعرض صور، false = الصور بتشتغل بطريقة G-MScreen بس
  bool? dlnaImagesOk;

  // ---- v5: تشغيل تلقائي للي بعده + تكرار + مؤقت إيقاف ----
  bool autoNext = Store.p.getBool('cast_autonext') ?? true;
  /// 'off' | 'one' | 'all'
  String repeat = Store.p.getString('cast_repeat') ?? 'off';
  DateTime? sleepAt;
  bool sleepEndOfItem = false;
  Timer? _sleepT;

  void setAutoNext(bool v) {
    autoNext = v;
    Store.p.setBool('cast_autonext', v);
    notifyListeners();
  }

  void cycleRepeat() {
    repeat = nextRepeat(repeat);
    Store.p.setString('cast_repeat', repeat);
    notifyListeners();
  }

  /// minutes = 0 → إلغاء، -1 → بعد ما اللي شغال يخلص
  void setSleep(int minutes) {
    _sleepT?.cancel();
    sleepAt = null;
    sleepEndOfItem = minutes == -1;
    if (minutes > 0) {
      sleepAt = DateTime.now().add(Duration(minutes: minutes));
      _sleepT = Timer(Duration(minutes: minutes), () async {
        sleepAt = null;
        _note('مؤقت الإيقاف: وقفت العرض ⏹');
        try {
          await stop();
        } catch (_) {}
      });
    }
    notifyListeners();
  }

  Future<void> _onEnded() async {
    final next = nextQueueIndex(playing, queue.length, autoNext: autoNext, repeat: repeat, sleepAfter: sleepEndOfItem);
    if (sleepEndOfItem) {
      sleepEndOfItem = false;
      _note('مؤقت الإيقاف: خلص اللي كان شغال — وقفت ⏹');
      try {
        await stop();
      } catch (_) {}
      return;
    }
    if (next != null) await playIndex(next);
  }

  /// عرض صورة واحدة (للعرض العادي وللـ Slideshow)
  Future<void> showImage(File f, {String? title}) async {
    final img = await prepareCastImage(f);
    final my = ++_seq;
    await _castImage(img, title ?? f.uri.pathSegments.last, my);
  }

  /// v5: الصورة — G-MScreen الأول لو هي اللي نجحت قبل كده، وإلا سلّم تجارب DLNA، وآخر حاجة G-MScreen
  Future<bool> _castImage(File img, String title, int my) async {
    final gmFirst = gm != null && (way == CastWay.gm || dlnaImagesOk == false);
    if (gmFirst && await _gmImage(img, my)) return true;
    if (my != _seq) return false;
    var tried = 0;
    if (client != null) {
      final r = await _imageLadder(img, title, my);
      if (r.$1) return true;
      tried = r.$2;
    }
    if (my != _seq) return false;
    if (!gmFirst && await _gmImage(img, my, auto: true)) return true;
    if (my != _seq) return false;
    _note(tried == 0 ? kImageUnsupportedAr : imageAllFailedAr(tried));
    return false;
  }

  Future<bool> _waitFetch(String? id, int my, int seconds) async {
    for (var k = 0; k < seconds * 4; k++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (my != _seq) return false;
      if (id != null && MediaServer.I.fetched.contains(id)) return true;
    }
    return false;
  }

  /// (نجحت؟، عدد التجارب)
  Future<(bool, int)> _imageLadder(File img, String title, int my) async {
    final c = client!;
    final ip = await phoneIpFor(current!.ip);
    if (ip == null) throw StateError('الموبايل لازم يكون على نفس الواي فاي بتاع الشاشة');
    final r = await runImageLadder(
      order: imgLadderOrder(preferredId: ImgStore.preferred, learned: ImgStore.learned),
      share: (v, n) => MediaServer.I.shareImage(img, ip, v, '${v.id}-$my-$n'),
      load: (url, v) => c.loadImage(url, title, v),
      waitFetch: (url, v) => _waitFetch(MediaServer.idOfUrl(url), my, v.play == 'none' ? 5 : 4),
      note: _note,
      cancelled: () => my != _seq,
      stop: c.stop,
    );
    if (r.$1 != null) {
      if (r.$1!.id != 'wvc') ImgStore.preferred = r.$1!.id;
      dlnaImagesOk = true;
      _note('الصورة ظهرت ✓ (تجربة ${r.$2}: ${r.$1!.label}) — الطريقة دي اتحفظت للمرات الجاية');
      return (true, r.$2);
    }
    return (false, r.$2);
  }

  /// G-MScreen: لو تبويب الريسيفر مش متصل وفي ريسيفر محفوظ → نتصل في الخلفية
  Future<bool> _gmImage(File img, int my, {bool auto = false}) async {
    var g = gm;
    GmClient? mine;
    if (g == null && auto && Store.receiverIp != null) {
      _note('بجرب طريقة G-MScreen (بتصل بالريسيفر في الخلفية)…');
      final c = GmClient(Store.receiverIp!);
      try {
        await c.connect();
        g = c;
        mine = c;
      } catch (e) {
        AppLog.add('CAST', 'gm auto-connect ✗ $e');
        return false;
      }
    }
    if (g == null) return false;
    var ok = false;
    try {
      final ip = await phoneIpFor(g.host);
      if (ip == null) return false;
      final url = await MediaServer.I.shareImage(img, ip, kImgLadder.first, 'gm-$my');
      _note('بجرب طريقة G-MScreen…');
      await g.castSend(1, 0, url);
      if (await _waitFetch(MediaServer.idOfUrl(url), my, 6)) {
        dlnaImagesOk = false;
        _note('الصورة ظهرت ✓ (بطريقة G-MScreen — الصور الجاية هتتبعت بيها على طول)');
        ok = true;
        return true;
      }
      AppLog.add('CAST', 'gm image: الريسيفر مطلبش الصورة');
    } catch (e) {
      AppLog.add('CAST', 'gm image ✗ $e');
    } finally {
      // الريسيفر بيقبل موبايل واحد: لو اتصلنا إحنا وفشل نسيب المكان لتبويب الريسيفر/G-MScreen
      if (!ok && mine != null) {
        try {
          await mine.disconnect();
        } catch (_) {}
      }
    }
    return false;
  }

  /// لو الشاشة مبدأتش خلال 12 ثانية والرابط مباشر → نعيده عبر الموبايل
  void _watchStart(int my, int i) {
    Future(() async {
      for (var k = 0; k < 6; k++) {
        await Future.delayed(const Duration(seconds: 2));
        if (my != _seq) return;
        await poll();
        if (state == 'PLAYING' || state == 'PAUSED_PLAYBACK' || pos > Duration.zero) {
          _note('شغال ✓');
          await _maybeResume(i);
          return;
        }
      }
      if (my != _seq || i >= queue.length) return;
      final q = queue[i];
      if (q.file == null && !q.viaPhone && q.url.startsWith('http')) {
        _note('الشاشة مبدأتش — بعيد المحاولة عبر الموبايل…');
        q.viaPhone = true;
        try {
          await playIndex(i);
        } catch (_) {}
      } else {
        _note('الشاشة لسه مبدأتش ($state). لو مفيش صورة: جرّب الطريقة التانية أو ابعت السجل');
      }
    });
  }

  Future<void> add(QueueItem q, {bool playNow = true}) async {
    queue.add(q);
    notifyListeners();
    if (playNow) await playIndex(queue.length - 1);
  }

  // ---- أزرار التحكم (نفس الأزرار للطريقتين) ----
  Future<void> play() async => way == CastWay.gm ? gm?.castSend(_gmMedia, 1, _gmUrl) : client?.play();
  Future<void> pause() async => way == CastWay.gm ? gm?.castSend(_gmMedia, 2, _gmUrl) : client?.pause();
  Future<void> stop() async {
    _seq++;
    if (way == CastWay.gm) {
      await gm?.castSend(_gmMedia, 3, _gmUrl);
    } else {
      await client?.stop();
    }
    state = 'STOPPED';
    notifyListeners();
  }

  Future<void> seek(Duration d) async {
    if (d < Duration.zero) d = Duration.zero;
    if (way == CastWay.gm) {
      if (_gmMedia == 1) return; // الصور مفيهاش تقديم
      await gm?.castSend(_gmMedia, 4, _gmUrl, seekMs: d.inMilliseconds);
    } else {
      await client?.seek(d);
    }
  }

  Future<void> setVolume(int v) async {
    if (way == CastWay.dlna) await client?.setVolume(v);
  }

  Future<void> poll() async {
    if (playing < 0) return;
    try {
      if (way == CastWay.gm) {
        final g = gm;
        if (g == null) return;
        final s = await g.castInfo();
        if (s == null) return;
        final ended = state == 'PLAYING' && (s.state == 2 || s.mediaType == -1) && dur.inSeconds > 0 && (dur - pos).inSeconds < 8;
        pos = Duration(milliseconds: s.currentMs);
        dur = Duration(milliseconds: s.totalMs);
        state = s.mediaType == -1 ? 'NO_MEDIA_PRESENT' : s.stateName;
        _saveResume();
        notifyListeners();
        if (ended) await _onEnded();
        return;
      }
      final c = client;
      if (c == null) return;
      final s = await c.status();
      final ended = state == 'PLAYING' && s.state == 'STOPPED' && dur.inSeconds > 0 && (dur - pos).inSeconds < 8;
      pos = s.pos;
      dur = s.dur;
      state = s.state;
      _saveResume();
      notifyListeners();
      if (ended) await _onEnded();
    } catch (_) {}
  }
}

/// رسالة عربي واضحة لأي خطأ في الكاست
String castErrorAr(Object e) {
  if (e is SoapFault) return e.toString();
  if (e is TimeoutException) return 'الشاشة مردتش (اتأكد إنها شغالة وعلى نفس الواي فاي)';
  if (e is SocketException) {
    final m = e.message.isNotEmpty ? e.message : '${e.osError?.message ?? ''}';
    if (m.contains('refused')) return 'الشاشة رفضت الاتصال — يمكن الـDLNA مقفول فيها';
    if (m.contains('unreachable') || m.contains('No route')) return 'مش قادر أوصل للشاشة — الموبايل والشاشة لازم على نفس الواي فاي';
    return m.isEmpty ? 'مشكلة في الشبكة' : m;
  }
  if (e is StateError) return e.message;
  if (e is HttpException) return e.message;
  return '$e';
}

class CastPage extends StatefulWidget {
  const CastPage({super.key});
  @override
  State<CastPage> createState() => _CastPageState();
}

class _CastPageState extends State<CastPage> with AutomaticKeepAliveClientMixin {
  final cs = CastState.I;
  Timer? t;
  bool _polling = false;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    cs.discover();
    t = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_polling || cs.busy) return;
      _polling = true;
      try {
        await cs.poll();
      } finally {
        _polling = false;
      }
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (mounted) toast(context, 'خطأ: ${castErrorAr(e)}');
    }
  }

  Future<void> pickLocal() async {
    final r = await FilePicker.pickFiles(type: FileType.media);
    if (r.isEmpty) return;
    final ip = await phoneIpFor(cs.current?.ip ?? cs.gm?.host);
    if (ip == null) {
      if (mounted) toast(context, 'الموبايل لازم يكون على نفس الواي فاي');
      return;
    }
    String? sub;
    if (r.length == 1 && mimeOf(r.first.name).startsWith('video') && mounted) {
      final how = await showDialog<int>(
        context: context,
        builder: (d) => SimpleDialog(title: const Text('ترجمة للفيديو؟'), children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(d, 1), child: const Text('اختار ملف srt من الموبايل')),
          SimpleDialogOption(onPressed: () => Navigator.pop(d, 2), child: const Text('دوّر في OpenSubtitles')),
          SimpleDialogOption(onPressed: () => Navigator.pop(d, 0), child: const Text('من غير ترجمة')),
        ]),
      );
      File? p;
      if (how == 1) {
        final s = await FilePicker.pickFile(type: FileType.any);
        p = s == null ? null : await pickedToFile(s);
      } else if (how == 2 && mounted) {
        final nm = r.first.name.replaceAll(RegExp(r'\.[A-Za-z0-9]{2,4}$'), '').replaceAll(RegExp(r'[._]+'), ' ');
        p = await Navigator.push<File>(context, MaterialPageRoute(builder: (_) => SubSearchPage(initialQuery: nm)));
      }
      if (p != null) sub = await MediaServer.I.share(p, ip);
    }
    if (mounted) toast(context, 'بجهّز الملفات…');
    var first = true;
    for (final f in r) {
      final file = await pickedToFile(f);
      if (file == null) continue;
      await _run(() => cs.add(QueueItem(f.name, file.path, subtitle: sub, file: file), playNow: first));
      first = false;
    }
  }

  Future<void> addLink() async {
    final u = await askText(context, 'رابط فيديو مباشر', hint: 'https://…mp4 أو m3u8', type: TextInputType.url);
    if (u == null || u.trim().isEmpty) return;
    var s = u.trim();
    if (!s.contains('://')) s = 'http://$s';
    await _run(() => cs.add(QueueItem(Uri.tryParse(s)?.pathSegments.where((x) => x.isNotEmpty).lastOrNull ?? s, s)));
  }

  Future<void> manualRenderer() async {
    final ip = await askText(context, 'عنوان الشاشة / الريسيفر', hint: Store.receiverIp ?? '192.168.1.50', type: TextInputType.url);
    if (ip == null || ip.trim().isEmpty) return;
    final t = ip.trim();
    final locs = t.startsWith('http') ? [t] : ['http://$t:49152/description.xml', 'http://$t:1400/xml/device_description.xml', 'http://$t:8080/description.xml'];
    if (mounted) toast(context, 'بجرب $t…');
    for (final l in locs) {
      final d = await fetchRenderer(l);
      if (d != null) {
        cs.devices.removeWhere((x) => x.avTransport == d.avTransport);
        cs.devices.insert(0, d);
        cs.select(d);
        cs.setWay(CastWay.dlna);
        if (mounted) toast(context, 'لقيت ${d.name}');
        return;
      }
    }
    if (mounted) toast(context, 'ملقتش DLNA على $t');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: cs,
      builder: (c, _) => ListView(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.tv, color: kGold),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: cs.devices.any((d) => d.avTransport == cs.current?.avTransport) ? cs.current?.avTransport : null,
                    hint: Text(cs.searching ? 'بدوّر على الشاشات…' : (cs.devices.isEmpty ? 'ملقتش شاشات DLNA' : 'اختار الشاشة')),
                    items: [
                      for (final d in cs.devices)
                        DropdownMenuItem(
                            value: d.avTransport,
                            child: Text('${d.isReceiver ? 'الريسيفر — ' : ''}${d.name}  (${d.ip})', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => cs.select(cs.devices.firstWhere((d) => d.avTransport == v)),
                  ),
                ),
                IconButton(onPressed: cs.searching ? null : cs.discover, icon: const Icon(Icons.refresh), tooltip: 'دوّر تاني'),
                IconButton(onPressed: manualRenderer, icon: const Icon(Icons.edit_location_alt_outlined), tooltip: 'اكتب العنوان'),
              ]),
              Row(children: [
                const Text('الطريقة:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<CastWay>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: CastWay.dlna, label: Text('DLNA', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: CastWay.gm, label: Text('G-MScreen', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {cs.way},
                    onSelectionChanged: (s) {
                      if (s.first == CastWay.gm && cs.gm == null) {
                        toast(context, 'اتصل بالريسيفر من تبويب الريسيفر الأول');
                        return;
                      }
                      cs.setWay(s.first);
                    },
                  ),
                ),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
              cs.way == CastWay.gm
                  ? 'طريقة G-MScreen بتبعت الرابط للريسيفر على نفس اتصال الريموت (أمر 1063). لو مشتغلتش ارجع لـ DLNA.'
                  : 'DLNA زي Web Video Caster. الريسيفر بيظهر أول واحد لو متوصّل قبل كده. Chromecast مش مدعوم.',
              style: const TextStyle(fontSize: 12, color: Colors.white60)),
        ),
        if (cs.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(children: [
              if (cs.busy) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              if (cs.busy) const SizedBox(width: 8),
              Expanded(child: Text(cs.note, style: const TextStyle(fontSize: 12, color: kGold))),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              icon: const Icon(Icons.public),
              label: const Text('المتصفح'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowserPage())),
            ),
            FilledButton.tonalIcon(icon: const Icon(Icons.video_library), label: const Text('من الموبايل'), onPressed: pickLocal),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.live_tv),
              label: const Text('قنوات IPTV'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IptvPage())),
            ),
            FilledButton.tonalIcon(icon: const Icon(Icons.link), label: const Text('رابط'), onPressed: addLink),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.slideshow_rounded),
              label: const Text('عرض صور'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlideshowPage())),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.history_rounded),
              label: const Text('اللي اتعرض قبل كده'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CastHistoryPage())),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.school_rounded),
              label: const Text('تعلّم من Web Video Caster'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearnPage())),
            ),
          ]),
        ),
        if (cs.playing >= 0 && cs.playing < cs.queue.length) _remote(),
        if (cs.queue.isNotEmpty) CastExtrasBar(cs: cs),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            Text('قايمة التشغيل (${cs.queue.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (cs.queue.isNotEmpty)
              TextButton(
                  onPressed: () {
                    cs.queue.clear();
                    cs.playing = -1;
                    setState(() {});
                  },
                  child: const Text('فضّي')),
          ]),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (a, b) {
            final x = cs.queue.removeAt(a);
            cs.queue.insert(b, x);
            if (cs.playing == a) {
              cs.playing = b;
            } else if (a < cs.playing && b >= cs.playing) {
              cs.playing--;
            } else if (a > cs.playing && b <= cs.playing) {
              cs.playing++;
            }
            setState(() {});
          },
          children: [
            for (var i = 0; i < cs.queue.length; i++)
              ListTile(
                key: ValueKey('${cs.queue[i].url}#$i'),
                leading: Icon(i == cs.playing ? Icons.play_arrow : Icons.movie_outlined, color: i == cs.playing ? kGold : null),
                title: Text(cs.queue[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${cs.queue[i].viaPhone ? '[عبر الموبايل] ' : ''}${cs.queue[i].url}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 11)),
                onTap: () => _run(() => cs.playIndex(i)),
                onLongPress: cs.queue[i].file != null
                    ? null
                    : () {
                        final q = cs.queue[i];
                        q.viaPhone = !q.viaPhone;
                        toast(context, q.viaPhone ? 'هيتشغل عبر الموبايل (للروابط اللي محتاجة دخول/هيدرز)' : 'هيتشغل الرابط مباشرة');
                        setState(() {});
                      },
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    cs.queue.removeAt(i);
                    if (cs.playing == i) cs.playing = -1;
                    if (cs.playing > i) cs.playing--;
                    setState(() {});
                  },
                ),
              ),
          ],
        ),
        if (cs.queue.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('ضغطة طويلة على رابط = تشغيله عبر الموبايل أو مباشرة', style: TextStyle(fontSize: 11, color: Colors.white38)),
          ),
        const SizedBox(height: 60),
      ]),
    );
  }

  Widget _remote() {
    final max = cs.dur.inSeconds.toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Text(cs.queue[cs.playing].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${cs.way == CastWay.gm ? 'G-MScreen' : 'DLNA'} • ${castStateAr(cs.state)}', style: const TextStyle(fontSize: 11, color: kMuted)),
          if (cs.resumedFrom != null)
            TextButton.icon(onPressed: () => _run(cs.fromStart), icon: const Icon(Icons.restart_alt_rounded, size: 18), label: Text('كمّلت من ${fmtHms(Duration(seconds: cs.resumedFrom!))} — من الأول')),
          Row(children: [
            Text(fmtHms(cs.pos), style: const TextStyle(fontSize: 11)),
            Expanded(
              child: Slider(
                value: cs.pos.inSeconds.toDouble().clamp(0, max <= 0 ? 1 : max),
                max: max <= 0 ? 1 : max,
                onChanged: max <= 0 ? null : (v) => setState(() => cs.pos = Duration(seconds: v.round())),
                onChangeEnd: max <= 0 ? null : (v) => _run(() => cs.seek(Duration(seconds: v.round()))),
              ),
            ),
            Text(fmtHms(cs.dur), style: const TextStyle(fontSize: 11)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(icon: const Icon(Icons.skip_previous), onPressed: cs.playing > 0 ? () => _run(() => cs.playIndex(cs.playing - 1)) : null),
            IconButton(icon: const Icon(Icons.replay_10), onPressed: () => _run(() => cs.seek(cs.pos - const Duration(seconds: 10)))),
            IconButton.filled(icon: const Icon(Icons.play_arrow), onPressed: () => _run(cs.play)),
            IconButton(icon: const Icon(Icons.pause), onPressed: () => _run(cs.pause)),
            IconButton(icon: const Icon(Icons.stop), onPressed: () => _run(cs.stop)),
            IconButton(icon: const Icon(Icons.forward_30), onPressed: () => _run(() => cs.seek(cs.pos + const Duration(seconds: 30)))),
            IconButton(icon: const Icon(Icons.skip_next), onPressed: cs.playing + 1 < cs.queue.length ? () => _run(() => cs.playIndex(cs.playing + 1)) : null),
          ]),
          if (cs.way == CastWay.dlna && cs.current?.rendering != null)
            Row(children: [
              const Icon(Icons.volume_down, size: 18),
              Expanded(
                child: Slider(
                  value: cs.volume.toDouble().clamp(0, 100),
                  max: 100,
                  onChanged: (v) => setState(() => cs.volume = v.round()),
                  onChangeEnd: (v) => _run(() => cs.setVolume(v.round())),
                ),
              ),
              const Icon(Icons.volume_up, size: 18),
            ]),
        ]),
      ),
    );
  }
}

String castStateAr(String s) => const {
      'PLAYING': 'شغال',
      'PAUSED_PLAYBACK': 'متوقف مؤقتًا',
      'STOPPED': 'واقف',
      'TRANSITIONING': 'بيحمّل…',
      'NO_MEDIA_PRESENT': 'مفيش حاجة شغالة',
    }[s] ??
    (s.isEmpty ? '…' : s);

/// لو الملف جاي content:// بننسخه للكاش علشان السيرفر يقدر يقرا أي جزء منه (Range)
Future<File?> pickedToFile(PlatformFile f) async {
  try {
    final p = f.path;
    if (p != null && await File(p).exists()) return File(p);
    final dir = Directory('${(await getTemporaryDirectory()).path}/cast');
    await dir.create(recursive: true);
    final out = File('${dir.path}/${f.name.replaceAll(RegExp(r'[^\w.\-]+'), '_')}');
    final sink = out.openWrite();
    await sink.addStream(f.readAsByteStream());
    await sink.close();
    return out;
  } catch (e) {
    AppLog.add('CAST', 'pick copy error $e');
    return null;
  }
}

// ---------------- المتصفح اللي بيلقط الفيديوهات ----------------
const String kSnifferJs = r'''
(function(){
 if (window.__a2r) return; window.__a2r = 1;
 var seen = {};
 function send(k, u){ try{ A2R.postMessage(k + u); }catch(e){} }
 function rep(u, k){ try{ if(!u) return; u = String(u); if(u.indexOf('blob:')===0){ if(!seen['blob']){ seen['blob']=1; send('b:', location.href);} return; } if(u.indexOf('data:')===0) return; u = new URL(u, location.href).href; var key=(k||'u:')+u; if(seen[key]) return; seen[key]=1; send(k||'u:', u);}catch(e){} }
 function isMediaType(ct){ ct = (ct||'').toLowerCase(); return ct.indexOf('video/')===0 || ct.indexOf('audio/')===0 || ct.indexOf('mpegurl')>=0 || ct.indexOf('dash+xml')>=0; }
 var of = window.fetch;
 if (of) window.fetch = function(i, o){
   var u = ''; try{ u = typeof i === 'string' ? i : (i && i.url) || ''; rep(u); }catch(e){}
   var p = of.apply(this, arguments);
   try{ p.then(function(r){ try{ if(isMediaType(r.headers.get('content-type'))) rep(r.url || u, 'm:'); }catch(e){} }); }catch(e){}
   return p;
 };
 var oo = XMLHttpRequest.prototype.open;
 XMLHttpRequest.prototype.open = function(m, u){
   var x = this; rep(u);
   try{ x.addEventListener('readystatechange', function(){ if(x.readyState===2){ try{ if(isMediaType(x.getResponseHeader('content-type'))) rep(x.responseURL || u, 'm:'); }catch(e){} } }); }catch(e){}
   return oo.apply(this, arguments);
 };
 function scan(){
   document.querySelectorAll('video,source,audio').forEach(function(v){
     if(v.tagName==='VIDEO' && !seen['vid']){ seen['vid']=1; send('v:', location.href); }
     if(v.src) rep(v.src, 'm:'); if(v.currentSrc) rep(v.currentSrc, 'm:');
   });
   try{ performance.getEntriesByType('resource').forEach(function(e){ rep(e.name); }); }catch(e){}
 }
 setInterval(scan, 1500); scan();
})();
''';

/// مانع الإعلانات: بيتحقن بعد الصفحة — بيقفل النوافذ المنبثقة ويشيل إطارات/عناصر الإعلانات
String adblockJs(List<String> hosts) => '''
(function(){
 if (window.__a2rAd) return; window.__a2rAd = 1;
 var H = ${jsonEncode(hosts)};
 function bad(u){ try{ var h = new URL(u, location.href).hostname.toLowerCase(); for (var i=0;i<H.length;i++){ if(h===H[i] || h.slice(-H[i].length-1)==='.'+H[i]) return true; } }catch(e){} return false; }
 try{ window.open = function(){ try{ A2R.postMessage('p:popup'); }catch(e){} return null; }; }catch(e){}
 var SEL = 'ins.adsbygoogle,.adsbygoogle,[id^="google_ads"],[id^="div-gpt-ad"],[class*="ad-banner"],[class*="adsbox"],[data-ad-slot],iframe[src*="ads"]';
 function clean(){
   document.querySelectorAll('iframe,script[src],img[src],a[href]').forEach(function(e){
     var u = e.src || e.href || ''; if(u && bad(u)){ if(e.tagName==='A'){ e.removeAttribute('href'); e.onclick=null; } else { e.remove(); } }
   });
   try{ document.querySelectorAll(SEL).forEach(function(e){ e.style.setProperty('display','none','important'); }); }catch(e){}
   document.querySelectorAll('a[target="_blank"]').forEach(function(a){ if(bad(a.href)) a.removeAttribute('href'); });
 }
 clean(); setInterval(clean, 2000);
})();
''';

/// دومينات الإعلانات المشهورة (مواقع الأفلام والماتشات بتستخدمها للـ popups)
const List<String> kAdHosts = [
  'doubleclick.net', 'googlesyndication.com', 'googleadservices.com', 'adservice.google.com', '2mdn.net',
  'adnxs.com', 'amazon-adsystem.com', 'criteo.com', 'pubmatic.com', 'rubiconproject.com', 'openx.net',
  'smartadserver.com', 'moatads.com', 'taboola.com', 'outbrain.com', 'revcontent.com', 'mgid.com',
  'popads.net', 'popcash.net', 'propellerads.com', 'propellerclick.com', 'adsterra.com', 'adsterratech.com',
  'exoclick.com', 'exosrv.com', 'juicyads.com', 'trafficjunky.net', 'onclickads.net', 'onclkds.com',
  'adskeeper.com', 'hilltopads.net', 'a-ads.com', 'clickadu.com', 'admaven.com', 'ad-maven.com',
  'popunder.net', 'adcash.com', 'zeropark.com', 'richpush.co', 'monetag.com', 'galaksion.com',
  'bidvertiser.com', 'yllix.com', 'adf.ly', 'shorte.st', 'highperformanceformat.com', 'profitablegatecpm.com',
  'realsrv.com', 'tsyndicate.com', 'adspyglass.com', 'popmyads.com', 'clickaine.com', 'pushame.com',
];

bool isAdHost(String host, [List<String> list = kAdHosts]) {
  final h = host.toLowerCase();
  for (final d in list) {
    if (h == d || h.endsWith('.$d')) return true;
  }
  return false;
}

bool isAdUrl(String url) => isAdHost(Uri.tryParse(url)?.host ?? '');

/// يوتيوب: الفيديو بيتبعت مقطّع ومحمي (MSE/blob) — مش بنستخرجه (شروط يوتيوب + بيبوظ كل شوية)
bool isYouTubeUrl(String url) {
  final h = (Uri.tryParse(url)?.host ?? '').toLowerCase();
  return h == 'youtu.be' || h == 'youtube.com' || h.endsWith('.youtube.com') || h == 'youtube-nocookie.com' || h.endsWith('.youtube-nocookie.com');
}

/// رابط ينفع يتبعت للشاشة؟ (مش مقاطع يوتيوب ولا blob)
bool castableUrl(String url, {bool mimeConfirmed = false}) {
  final u = url.toLowerCase();
  if (!u.startsWith('http')) return false;
  final host = Uri.tryParse(u)?.host ?? '';
  if (host.endsWith('googlevideo.com') || isYouTubeUrl(u)) return false;
  // مقاطع HLS (.ts / .m4s) لوحدها مش بتتعرض — بنستنى الـ m3u8
  if (RegExp(r'\.(ts|m4s|aac)(\?|#|$)').hasMatch(u)) return false;
  return mimeConfirmed || looksLikeMedia(url);
}

class BrowserEntry {
  final String url, title;
  final int ts;
  BrowserEntry(this.url, this.title, this.ts);
  Map<String, dynamic> toJson() => {'u': url, 't': title, 's': ts};
  static BrowserEntry? fromJson(dynamic m) =>
      m is Map && m['u'] is String ? BrowserEntry(m['u'] as String, '${m['t'] ?? ''}', (m['s'] as num?)?.toInt() ?? 0) : null;
}

/// المفضلة والسجل بتاع المتصفح (SharedPreferences)
class BrowserStore {
  static List<BrowserEntry> _read(String k) {
    try {
      return (jsonDecode(Store.p.getString(k) ?? '[]') as List).map(BrowserEntry.fromJson).whereType<BrowserEntry>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(String k, List<BrowserEntry> l) => Store.p.setString(k, jsonEncode(l.map((e) => e.toJson()).toList()));

  static List<BrowserEntry> get bookmarks => _read('br_bm');
  static List<BrowserEntry> get history => _read('br_hist');
  static bool isBookmarked(String url) => bookmarks.any((e) => e.url == url);

  static Future<bool> toggleBookmark(String url, String title) async {
    final l = bookmarks;
    final had = l.any((e) => e.url == url);
    if (had) {
      l.removeWhere((e) => e.url == url);
    } else {
      l.insert(0, BrowserEntry(url, title.isEmpty ? url : title, DateTime.now().millisecondsSinceEpoch));
    }
    await _write('br_bm', l);
    return !had;
  }

  static Future<void> removeBookmark(String url) async => _write('br_bm', bookmarks..removeWhere((e) => e.url == url));

  static Future<void> addHistory(String url, String title, {int max = 150}) async {
    if (!url.startsWith('http')) return;
    await _write('br_hist', historyAdd(history, BrowserEntry(url, title, DateTime.now().millisecondsSinceEpoch), max: max));
  }

  static Future<void> clearHistory() => Store.p.remove('br_hist');
  static bool get adblock => Store.p.getBool('br_adblock') ?? true;
  static set adblock(bool v) => Store.p.setBool('br_adblock', v);
}

/// يضيف للسجل: الأحدث فوق، من غير تكرار نفس الرابط، وبحد أقصى
List<BrowserEntry> historyAdd(List<BrowserEntry> l, BrowserEntry e, {int max = 150}) {
  final out = [e, ...l.where((x) => x.url != e.url)];
  return out.length > max ? out.sublist(0, max) : out;
}

class BrowserPage extends StatefulWidget {
  /// v5: يفتح على رابط معيّن (من المشاركة أو صفحة DNS الراوتر)
  final String? initialUrl;
  const BrowserPage({super.key, this.initialUrl});
  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController web;
  final urlC = TextEditingController();
  final List<String> found = [];
  String title = '';
  String url = '';
  double prog = 0;
  bool hasVideo = false; // في عنصر فيديو في الصفحة
  bool blobOnly = false; // الفيديو جاي من blob (مقطّع/محمي)
  int adsBlocked = 0;
  bool canBack = false, canFwd = false;
  bool adblock = BrowserStore.adblock;
  DateTime _lastBack = DateTime(2000);
  int _backTaps = 0;

  bool get youtube => isYouTubeUrl(url);
  String? get ytId => ytVideoId(url);
  bool ytBusy = false;

  /// يوتيوب: نجيب الجودات ونخليه يختار
  Future<void> castYouTube() async {
    final id = ytId;
    if (id == null || ytBusy) return;
    setState(() => ytBusy = true);
    YtResult? r;
    try {
      r = await YouTubeCast.streams(id);
    } catch (e) {
      if (mounted) toast(context, YouTubeCast.errorAr(e));
    }
    if (mounted) setState(() => ytBusy = false);
    if (r == null || !mounted) return;
    final pick = await showModalBottomSheet<YtChoice>(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.75),
          child: ListView(shrinkWrap: true, children: [
            const SectionTitle('اختار الجودة', icon: Icons.high_quality_rounded),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                  'يوتيوب بيبعت الجودات العالية صورة لوحدها وصوت لوحده، والريسيفر مبيقدرش يجمعهم — فاللي ظاهر هنا بس اللي فيه صورة وصوت مع بعض.',
                  style: TextStyle(fontSize: 12, color: kMuted)),
            ),
            if (r!.muxed.isNotEmpty) const SectionTitle('فيديو + صوت (مضمون)', icon: Icons.movie_rounded),
            for (final ch in r.muxed)
              ListTile(
                leading: const Icon(Icons.play_circle_fill_rounded, color: kGold),
                title: Text(ch.label),
                subtitle: Text(ch.detail, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(c, ch),
              ),
            if (r.hls.isNotEmpty) const SectionTitle('HLS — جودة أعلى (لو الريسيفر بيشغّل m3u8)', icon: Icons.hd_rounded),
            for (final (i, ch) in r.hls.indexed)
              ListTile(
                leading: Icon(i == 0 ? Icons.auto_awesome_rounded : Icons.stream_rounded, color: kGold),
                title: Text(i == 0 && ch.height < 99999 ? 'أعلى جودة — ${ch.label}' : ch.label),
                subtitle: Text(i == 0 ? 'لو مشتغلش، ارجع واختار من «فيديو + صوت»' : ch.detail, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(c, ch),
              ),
          ]),
        ),
      ),
    );
    if (pick == null) return;
    AppLog.add('CAST', 'youtube $id اختار ${pick.label} ${pick.hls ? 'HLS' : 'muxed'} ${ytLogUrl(pick.url)}');
    await web.runJavaScript("document.querySelectorAll('video').forEach(function(v){try{v.pause()}catch(e){}})").catchError((_) {});
    final name = title.replaceAll(RegExp(r'\s*-\s*YouTube\s*$'), '');
    try {
      await CastState.I.add(QueueItem('${name.isEmpty ? 'YouTube' : name} (${pick.label})', pick.url,
          mime: pick.mime, headers: {'User-Agent': kChromeUa, 'Referer': 'https://www.youtube.com/', 'Origin': 'https://www.youtube.com'}));
      if (mounted) toast(context, 'اتبعت للشاشة — ${pick.label}');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  void _msg(String m) {
    if (m.length < 2) return;
    final k = m.substring(0, 2), v = m.substring(2);
    switch (k) {
      case 'u:':
        _found(v, false);
      case 'm:':
        _found(v, true);
      case 'v:':
        if (!hasVideo) setState(() => hasVideo = true);
      case 'b:':
        if (!blobOnly) setState(() => blobOnly = true);
      case 'p:':
        setState(() => adsBlocked++);
      default:
        _found(m, false); // نسخة قديمة من السكريبت
    }
  }

  void _found(String u, bool mime) {
    if (!castableUrl(u, mimeConfirmed: mime) || found.contains(u)) return;
    AppLog.add('CAST', 'sniffed${mime ? '(mime)' : ''} $u');
    setState(() => found.insert(0, u));
  }

  Future<void> _nav() async {
    final b = await web.canGoBack(), f = await web.canGoForward();
    if (mounted && (b != canBack || f != canFwd)) setState(() {
      canBack = b;
      canFwd = f;
    });
  }

  @override
  void initState() {
    super.initState();
    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(kChromeUa)
      ..addJavaScriptChannel('A2R', onMessageReceived: (m) => _msg(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (r) {
          if (adblock && isAdUrl(r.url)) {
            AppLog.add('CAST', 'adblock ✗ ${r.url}');
            setState(() => adsBlocked++);
            return NavigationDecision.prevent;
          }
          if (looksLikeMedia(r.url) && castableUrl(r.url)) {
            _found(r.url, false);
            return NavigationDecision.prevent;
          }
          if (!r.url.startsWith('http')) return NavigationDecision.prevent; // intent:// وغيره
          return NavigationDecision.navigate;
        },
        onPageStarted: (u) {
          urlC.text = u;
          setState(() {
            url = u;
            found.clear();
            hasVideo = false;
            blobOnly = false;
          });
          _nav();
        },
        onProgress: (p) => setState(() => prog = p / 100),
        onPageFinished: (u) async {
          await web.runJavaScript(kSnifferJs).catchError((_) {});
          if (adblock) await web.runJavaScript(adblockJs(kAdHosts)).catchError((_) {});
          title = await web.getTitle() ?? '';
          url = u;
          BrowserStore.addHistory(u, title);
          _nav();
          if (mounted) setState(() {});
        },
        onUrlChange: (c) {
          if (c.url == null) return;
          url = c.url!;
          urlC.text = url;
          _found(c.url!, false);
          _nav();
          if (mounted) setState(() {});
        },
      ))
      ..loadRequest(Uri.parse(widget.initialUrl ?? Store.homePage));
  }

  void go(String s) {
    s = s.trim();
    if (s.isEmpty) return;
    final u = s.startsWith('http') ? s : (s.contains('.') && !s.contains(' ') ? 'https://$s' : 'https://www.google.com/search?q=${Uri.encodeComponent(s)}');
    web.loadRequest(Uri.parse(u));
  }

  void close() {
    if (mounted) Navigator.of(context).pop();
  }

  /// زرار الرجوع: يرجع صفحة، ولو الصفحة مرجعتش (يوتيوب بيعمل كده) أو مفيش صفحات → يقفل المتصفح
  Future<void> back() async {
    final now = DateTime.now();
    _backTaps = now.difference(_lastBack) < const Duration(milliseconds: 1500) ? _backTaps + 1 : 1;
    _lastBack = now;
    if (_backTaps >= 3) return close(); // 3 دوسات ورا بعض = اقفل على طول
    if (!await web.canGoBack()) return close();
    final before = await web.currentUrl();
    await web.goBack();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (await web.currentUrl() == before && before != null) close();
  }

  Future<void> cast(String u) async {
    final name = title.isNotEmpty ? title : (Uri.parse(u).pathSegments.lastOrNull ?? 'فيديو');
    try {
      await CastState.I.add(QueueItem(name, u, headers: {if (url.startsWith('http')) 'Referer': url, 'User-Agent': kChromeUa}));
      if (mounted) toast(context, 'اتبعت للشاشة');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _list(bool bookmarks) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (c, ss) {
        final l = bookmarks ? BrowserStore.bookmarks : BrowserStore.history;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SectionTitle(bookmarks ? 'المفضلة' : 'السجل', icon: bookmarks ? Icons.star_rounded : Icons.history_rounded,
                  trailing: !bookmarks && l.isNotEmpty
                      ? TextButton(onPressed: () async {
                          await BrowserStore.clearHistory();
                          ss(() {});
                        }, child: const Text('امسح الكل'))
                      : null),
              if (l.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Text(bookmarks ? 'مفيش مواقع في المفضلة — دوس النجمة وانت في الموقع' : 'السجل فاضي', style: const TextStyle(color: kMuted))),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final e in l)
                    ListTile(
                      leading: Icon(bookmarks ? Icons.star_rounded : Icons.public, color: kGold, size: 20),
                      title: Text(e.title.isEmpty ? e.url : e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(e.url, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 11)),
                      onTap: () => Navigator.pop(c, e.url),
                      trailing: bookmarks
                          ? IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () async {
                              await BrowserStore.removeBookmark(e.url);
                              ss(() {});
                            })
                          : null,
                    ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
    if (picked != null) go(picked);
  }

  Future<void> _menu(String v) async {
    switch (v) {
      case 'bm':
        await _list(true);
      case 'hist':
        await _list(false);
      case 'home':
        Store.homePage = url;
        toast(context, 'اتحفظت كصفحة رئيسية');
      case 'ad':
        setState(() => adblock = !adblock);
        BrowserStore.adblock = adblock;
        toast(context, adblock ? 'مانع الإعلانات اشتغل' : 'مانع الإعلانات اتقفل');
        web.reload();
    }
    if (mounted) setState(() {});
  }

  Widget _banner() {
    String? t;
    IconData icon = Icons.info_outline_rounded;
    if (ytId != null) {
      return const SizedBox.shrink(); // زرار الكاست الذهبي ظاهر
    } else if (hasVideo && found.isEmpty && blobOnly) {
      t = 'الفيديو ده بيشتغل بطريقة محمية/مقطّعة (blob) — لو ملقيتش زرار الكاست بعد ما يشتغل، الموقع ده مش هينفع يتبعت.';
    } else if (hasVideo && found.isEmpty) {
      t = 'شغّل الفيديو الأول — زرار الكاست الذهبي هيظهر أول ما ألقط رابطه.';
    }
    if (t == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: kSurface2,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: kGold, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }

  void _foundSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: kSurface,
        builder: (c) => SafeArea(
          child: ListView(shrinkWrap: true, children: [
            const ListTile(title: Text('الفيديوهات اللي اتلقطت — دوس علشان تبعت للشاشة')),
            for (final u in found)
              ListTile(
                leading: Text(mimeOf(u).split('/').last.replaceAll('x-mpegURL', 'm3u8'), style: const TextStyle(color: kGold, fontSize: 11)),
                title: Text(u, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(c);
                  cast(u);
                },
                trailing: IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => Clipboard.setData(ClipboardData(text: u))),
              ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final starred = BrowserStore.isBookmarked(url);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'اقفل المتصفح', onPressed: close),
          title: TextField(
            controller: urlC,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: go,
            decoration: const InputDecoration(hintText: 'اكتب رابط أو ابحث', border: InputBorder.none, filled: false),
          ),
          actions: [
            IconButton(
              icon: Icon(starred ? Icons.star_rounded : Icons.star_outline_rounded, color: kGold),
              tooltip: 'المفضلة',
              onPressed: () async {
                final on = await BrowserStore.toggleBookmark(url, title);
                if (mounted) toast(context, on ? 'اتضاف للمفضلة' : 'اتشال من المفضلة');
                setState(() {});
              },
            ),
            PopupMenuButton<String>(
              onSelected: _menu,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'bm', child: ListTile(leading: Icon(Icons.star_rounded), title: Text('المفضلة'))),
                const PopupMenuItem(value: 'hist', child: ListTile(leading: Icon(Icons.history_rounded), title: Text('السجل'))),
                const PopupMenuItem(value: 'home', child: ListTile(leading: Icon(Icons.home_outlined), title: Text('خليها الصفحة الرئيسية'))),
                PopupMenuItem(
                  value: 'ad',
                  child: ListTile(
                    leading: Icon(adblock ? Icons.shield_rounded : Icons.shield_outlined, color: adblock ? kOk : null),
                    title: Text(adblock ? 'مانع الإعلانات: شغال' : 'مانع الإعلانات: مقفول'),
                    subtitle: adsBlocked > 0 ? Text('اتمنع $adsBlocked') : null,
                  ),
                ),
              ],
            ),
          ],
          bottom: prog < 1 ? PreferredSize(preferredSize: const Size.fromHeight(2), child: LinearProgressIndicator(value: prog)) : null,
        ),
        body: Column(children: [
          _banner(),
          Expanded(child: WebViewWidget(controller: web)),
        ]),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 52,
            decoration: const BoxDecoration(color: kSurface, border: Border(top: BorderSide(color: kLine))),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded), tooltip: 'رجوع', onPressed: back),
                IconButton(icon: const Icon(Icons.arrow_forward_rounded), tooltip: 'قدام', onPressed: canFwd ? () => web.goForward() : null),
                IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'تحديث', onPressed: () => web.reload()),
                IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'الرئيسية', onPressed: () => go(Store.homePage)),
                IconButton(icon: const Icon(Icons.close_rounded, color: kBad), tooltip: 'اقفل', onPressed: close),
              ]),
            ),
          ),
        ),
        floatingActionButton: ytId != null
            ? FloatingActionButton.extended(
                backgroundColor: kGold,
                foregroundColor: const Color(0xFF1A1405),
                icon: ytBusy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1405))) : const Icon(Icons.cast_rounded),
                label: Text(ytBusy ? 'بجيب الجودات…' : 'ابعت للشاشة'),
                onPressed: ytBusy ? null : castYouTube,
              )
            : found.isEmpty
            ? null
            : FloatingActionButton.extended(
                backgroundColor: kGold,
                foregroundColor: const Color(0xFF1A1405),
                icon: const Icon(Icons.cast_rounded),
                label: Text(found.length == 1 ? 'ابعت للشاشة' : '${found.length} فيديو'),
                onPressed: () => found.length == 1 ? cast(found.first) : _foundSheet(),
              ),
      ),
    );
  }
}

// ---------------- IPTV ----------------
class IptvPage extends StatefulWidget {
  const IptvPage({super.key});
  @override
  State<IptvPage> createState() => _IptvPageState();
}

class _IptvPageState extends State<IptvPage> {
  List<M3uItem> items = [];
  String q = '', group = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<File> _cache() async => File('${(await getApplicationSupportDirectory()).path}/playlist.m3u');

  Future<void> _loadSaved() async {
    final f = await _cache();
    if (await f.exists()) {
      items = parseM3u(await f.readAsString());
      if (mounted) setState(() {});
    }
  }

  Future<void> _set(String txt) async {
    items = parseM3u(txt);
    await (await _cache()).writeAsString(txt);
    if (mounted) {
      setState(() {});
      toast(context, '${items.length} قناة');
    }
  }

  Future<void> fromUrl() async {
    final u = await askText(context, 'رابط قايمة m3u', initial: Store.m3uUrl ?? '', type: TextInputType.url);
    if (u == null || u.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      final r = await http.get(Uri.parse(u.trim())).timeout(const Duration(seconds: 30));
      Store.m3uUrl = u.trim();
      await _set(utf8.decode(r.bodyBytes, allowMalformed: true));
    } catch (e) {
      if (mounted) toast(context, 'فشل: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> fromFile() async {
    final r = await FilePicker.pickFile(type: FileType.any);
    if (r == null) return;
    await _set(utf8.decode(await r.readAsBytes(), allowMalformed: true));
  }

  @override
  Widget build(BuildContext context) {
    final groups = items.map((e) => e.group).where((g) => g.isNotEmpty).toSet().toList()..sort();
    final shown = items.where((e) => (group.isEmpty || e.group == group) && (q.isEmpty || e.name.toLowerCase().contains(q.toLowerCase()))).take(500).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('قنوات IPTV'), actions: [
        IconButton(icon: const Icon(Icons.link), tooltip: 'من رابط', onPressed: fromUrl),
        IconButton(icon: const Icon(Icons.file_open_outlined), tooltip: 'من ملف', onPressed: fromFile),
      ]),
      body: Column(children: [
        if (loading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'دوّر'), onChanged: (v) => setState(() => q = v))),
            if (groups.isNotEmpty) ...[
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: group,
                items: [const DropdownMenuItem(value: '', child: Text('الكل')), for (final g in groups) DropdownMenuItem(value: g, child: Text(g))],
                onChanged: (v) => setState(() => group = v ?? ''),
              ),
            ],
          ]),
        ),
        if (items.isEmpty) const Expanded(child: Center(child: Text('حمّل قايمة m3u من رابط أو ملف'))),
        if (items.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: shown.length,
              itemBuilder: (c, i) => ListTile(
                leading: const Icon(Icons.live_tv),
                title: Text(shown[i].name),
                subtitle: Text(shown[i].group, style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  try {
                    await CastState.I.add(QueueItem(shown[i].name, shown[i].url));
                    if (context.mounted) toast(context, 'بيتشغل على الشاشة');
                  } catch (e) {
                    if (context.mounted) toast(context, '$e');
                  }
                },
                trailing: IconButton(icon: const Icon(Icons.phone_android), tooltip: 'شغّل على الموبايل', onPressed: () => Native.openVideo(shown[i].url)),
              ),
            ),
          ),
      ]),
    );
  }
}


// ======== ui_stb.dart ========
// ---------------- الريسيفر ----------------
class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});
  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  GmClient? gm;
  /// v5: مجموعة مفضلة مختارة كفلتر
  String? group;
  /// v5: كنا متصلين قبل ما التطبيق يروح الخلفية → نرجع نتصل لوحدنا
  bool _wasConnected = false;
  String msg = '';
  bool busy = false;
  Map<String, StbInfo> found = {};
  List<StbChannel> channels = [];
  String? playingId;
  bool radio = false;
  String q = '';
  bool favOnly = false;
  bool hdOnly = false;
  bool ftaOnly = false;
  int view = 0; // 0 ريموت، 1 قنوات، 2 ضبط الطبق
  bool touchpad = Store.p.getBool('stb_touchpad') ?? false;

  @override
  bool get wantKeepAlive => true;

  bool get connected => gm?.connected == true;

  Set<String> get favs => (Store.p.getStringList('stb_favs') ?? []).toSet();
  Future<void> toggleFav(String id) async {
    final f = favs;
    f.contains(id) ? f.remove(id) : f.add(id);
    await Store.p.setStringList('stb_favs', f.toList());
    setState(() {});
  }

  bool notifRemote = Store.p.getBool('stb_notif') ?? false;

  @override
  void initState() {
    super.initState();
    kOpenChannel.addListener(_openFromShortcut);
    WidgetsBinding.instance.addObserver(this);
    if (notifRemote) Native4.remoteNotif(true);
    if (kOpenChannel.value != null) WidgetsBinding.instance.addPostFrameCallback((_) => _openFromShortcut());
  }

  @override
  void dispose() {
    kOpenChannel.removeListener(_openFromShortcut);
    WidgetsBinding.instance.removeObserver(this);
    gm?.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) _wasConnected = connected || _wasConnected;
    if (s == AppLifecycleState.resumed && StbPrefs.autoReconnect && !busy && !connected && Store.receiverIp != null && (_wasConnected || gm != null)) {
      AppLog.add('STB', 'رجوع للتطبيق → بعيد الاتصال بالريسيفر');
      connect(Store.receiverIp!).then((_) {
        if (connected && mounted) toast(context, 'رجعت اتصلت بالريسيفر ✓');
      });
    }
  }

  void _recent(StbChannel ch) {
    StbPrefs.addRecent(ch);
    if (mounted) setState(() {});
  }

  Future<void> _zapTo(StbChannel ch) async {
    HapticFeedback.lightImpact();
    try {
      await gm!.zap(ch);
      playingId = ch.id;
      _recent(ch);
      setState(() {});
    } catch (e) {
      if (mounted) toast(context, 'مقدرتش أغير القناة: $e');
    }
  }

  /// اختصار قناة من الشاشة الرئيسية: نتصل لو مش متصلين وبعدين نغيّر القناة
  Future<void> _openFromShortcut() async {
    final d = kOpenChannel.value;
    if (d == null || d.length < 3) return;
    kOpenChannel.value = null;
    final radio = d.startsWith('1:');
    final id = d.substring(2);
    if (!connected && Store.receiverIp != null) await connect(Store.receiverIp!);
    if (!connected) {
      if (mounted) toast(context, 'مقدرتش أتصل بالريسيفر');
      return;
    }
    final ch = channels.where((c) => c.id == id && c.radio == radio).firstOrNull ?? StbChannel(id, 'قناة $id', radio, 0, const {});
    try {
      await gm!.zap(ch);
      setState(() => playingId = id);
      _recent(ch);
      AppLog.add('STB', 'shortcut zap $d');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> pinChannel(StbChannel ch) async {
    final ok = await Native4.pinShortcut('ch_${ch.radio ? 1 : 0}_${ch.id}', ch.name, '${ch.radio ? 1 : 0}:${ch.id}');
    if (mounted) toast(context, ok ? 'وافق على الإضافة للشاشة الرئيسية' : 'الشاشة الرئيسية (اللانشر) مش بتقبل اختصارات');
  }

  Future<void> setNotifRemote(bool on) async {
    notifRemote = on;
    await Store.p.setBool('stb_notif', on);
    if (on) await Native.askNotifyPermission();
    await Native4.remoteNotif(on, title: gm?.info?.model ?? 'ريموت الريسيفر');
    if (mounted) {
      setState(() {});
      if (on) toast(context, 'الريموت في الإشعارات — بيشتغل لما الموبايل على واي فاي البيت');
    }
  }

  Future<void> voice() async {
    if (!connected) {
      toast(context, 'اتصل بالريسيفر الأول');
      return;
    }
    final heard = await Native4.voice(prompt: 'قول: افتح MBC • قناة 105 • علّي الصوت • اقفل');
    if (heard.isEmpty) return;
    if (channels.isEmpty) await loadChannels();
    final c = parseVoiceCommand(heard, channels);
    AppLog.add('STB', 'voice "${heard.first}" → ${c.kind.name} ${c.describe}');
    if (!mounted) return;
    switch (c.kind) {
      case VoiceKind.none:
        toast(context, 'مفهمتش «${c.heard}» — جرّب تاني');
      case VoiceKind.keys:
        if (c.keys.first == K.power && !await confirm(context, 'أقفل/أفتح الريسيفر؟')) return;
        for (final k in c.keys) {
          await key(k);
          await Future.delayed(const Duration(milliseconds: 250));
        }
        if (mounted) toast(context, '«${c.heard}» ✓');
      case VoiceKind.number:
        for (final k in digitKeys(c.number)) {
          await key(k);
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted) toast(context, 'قناة ${c.number}');
      case VoiceKind.channel:
        await gm!.zap(c.channel!);
        setState(() => playingId = c.channel!.id);
        if (mounted) toast(context, c.channel!.name);
    }
  }

  Future<void> discover() async {
    setState(() {
      busy = true;
      msg = 'بسمع إعلانات الريسيفر (6 ثواني)…';
    });
    found = await discoverReceivers();
    if (found.isEmpty) {
      final net = await readPhoneNet();
      setState(() => msg = 'مفيش إعلانات — بدوّر على بورت 20000 في الشبكة…');
      final hosts = await scanLan(net.prefix);
      for (final h in hosts.where((h) => h.openPorts.contains(kStbPort))) {
        found[h.ip] = StbInfo('', 'ريسيفر؟', h.ip, 0, 0, 0, 0);
      }
    }
    setState(() {
      busy = false;
      msg = found.isEmpty ? 'ملقتش ريسيفر — اكتب العنوان بنفسك (من قايمة الشبكة في الريسيفر)' : 'لقيت ${found.length} — دوس عليه للاتصال';
    });
  }

  Future<void> connect(String ip) async {
    setState(() {
      busy = true;
      msg = 'بتصل بـ $ip…';
    });
    await gm?.disconnect();
    // لو الكاست فتح اتصال في الخلفية (الريسيفر بيقبل موبايل واحد) نقفله الأول
    if (GmClient.active != null && GmClient.active != gm) await GmClient.active!.disconnect();
    final c = GmClient(ip);
    c.onNotify = (t) {
      AppLog.add('STB', 'notify $t');
      if (t == 2001) _refreshPlaying();
      if (t == 2002) loadChannels();
    };
    c.addListener(() {
      if (mounted) setState(() {});
    });
    try {
      final i = await c.connect();
      gm = c;
      Store.receiverIp = ip;
      found.clear();
      msg = '${i.model} • ${i.ip}';
      _refreshPlaying();
    } catch (e) {
      msg = 'فشل الاتصال: $e';
      AppLog.add('STB', 'connect fail $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _refreshPlaying() async {
    playingId = await gm?.playingId();
    final ch = channels.where((c) => c.id == playingId).firstOrNull;
    if (ch != null) StbPrefs.addRecent(ch);
    if (mounted) setState(() {});
  }

  Future<void> loadChannels() async {
    if (gm == null) return;
    setState(() {
      busy = true;
      msg = 'بحمّل القنوات…';
    });
    try {
      channels = await gm!.channels(progress: (n) {
        if (mounted) setState(() => msg = 'بحمّل القنوات… $n');
      });
      msg = '${gm?.info?.model ?? 'الريسيفر'} • ${channels.length} قناة';
    } catch (e) {
      msg = 'مقدرتش أحمّل القنوات: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> key(int k) async {
    try {
      if (gm == null) throw StateError('مش متصل بالريسيفر');
      await gm!.key(k);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> manual() async {
    final ip = await askText(context, 'عنوان الريسيفر', initial: Store.receiverIp ?? '', hint: '192.168.x.x', type: TextInputType.number);
    if (ip != null && ip.trim().isNotEmpty) await connect(ip.trim());
  }

  Future<void> showInfo() async {
    if (gm == null) return;
    Map<String, dynamic> st = {};
    try {
      st = await gm!.state();
    } catch (e) {
      if (mounted) toast(context, '$e');
      return;
    }
    if (!mounted) return;
    const names = {
      'ProductName': 'الموديل',
      'SoftwareVersion': 'السوفت وير',
      'SerialNumber': 'الرقم التسلسلي',
      'ChannelNum': 'عدد القنوات',
      'MaxNumOfPrograms': 'أقصى عدد قنوات',
      'MuteState': 'الصوت مقفول',
      'SleepSwitch': 'مؤقت النوم شغال',
      'SleepTime': 'مؤقت النوم (دقيقة)',
      'ScreenLock': 'قفل الشاشة',
      'PowerMode': 'وضع الباور',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      builder: (c) => ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 20), children: [
        const SectionTitle('معلومات الريسيفر', icon: Icons.info_outline_rounded),
        ListTile(
          leading: const Icon(Icons.bedtime_rounded, color: kGold),
          title: const Text('مؤقت النوم'),
          onTap: () {
            Navigator.pop(c);
            sleepTimer();
          },
        ),
        if (gm?.info != null)
          ListTile(dense: true, title: const Text('ضبط الطبق من الموبايل'), trailing: Text(gm!.info!.satFinder == null ? '؟' : (gm!.info!.satFinder! ? 'مدعوم' : 'مش مدعوم'), style: const TextStyle(color: kMuted))),
        for (final e in st.entries)
          ListTile(dense: true, title: Text(names[e.key] ?? e.key), trailing: Text('${e.value}', style: const TextStyle(color: kMuted))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      _header(),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.settings_remote_rounded), label: Text('الريموت')),
              ButtonSegment(value: 1, icon: Icon(Icons.format_list_bulleted_rounded), label: Text('القنوات')),
              ButtonSegment(value: 2, icon: Icon(Icons.network_check_rounded), label: Text('ضبط الطبق')),
            ],
            selected: {view},
            onSelectionChanged: (s) {
              HapticFeedback.selectionClick();
              setState(() => view = s.first);
              if (view != 0 && channels.isEmpty && connected) loadChannels();
            },
          ),
        ),
      ),
      Expanded(
        child: !connected && found.isEmpty
            ? EmptyState(
                icon: Icons.satellite_alt_rounded,
                title: 'مش متصل بالريسيفر',
                hint: 'الموبايل والريسيفر لازم يكونوا على نفس الواي فاي.\nاقفل تطبيق G-MScreen على أي موبايل تاني الأول.',
                action: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                  FilledButton.icon(onPressed: busy ? null : discover, icon: const Icon(Icons.search_rounded), label: const Text('دوّر على الريسيفر')),
                  if (Store.receiverIp != null)
                    OutlinedButton.icon(onPressed: busy ? null : () => connect(Store.receiverIp!), icon: const Icon(Icons.link_rounded), label: Text('اتصل بـ ${Store.receiverIp}')),
                ]),
              )
            : !connected
                ? ListView(children: [
                    const SectionTitle('الريسيفرات اللي لقيتها', icon: Icons.settings_input_antenna_rounded),
                    for (final e in found.entries)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.satellite_alt_rounded),
                          title: Text(e.value.model.isEmpty ? 'ريسيفر' : e.value.model),
                          subtitle: Text('${e.key}${e.value.serial.isEmpty ? '' : ' • S/N ${e.value.serial}'}'),
                          trailing: const Icon(Icons.chevron_left_rounded),
                          onTap: () => connect(e.key),
                        ),
                      ),
                  ])
                : view == 0
                    ? (touchpad ? _touchpad() : RemoteControl(onKey: key))
                    : view == 1
                        ? _channels()
                        : DishPage(gm: gm!, channels: channels, playingId: playingId, onZapped: (id) => setState(() => playingId = id)),
      ),
    ]);
  }

  Widget _header() {
    final on = connected;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? kOk : (busy ? kGold : kBad),
              boxShadow: [BoxShadow(color: (on ? kOk : kBad).withValues(alpha: 0.6), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(on ? (gm?.info?.model ?? 'متصل') : 'الريسيفر', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(msg.isEmpty ? 'Qmax • بروتوكول G-MScreen' : msg, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
          if (busy) const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          if (on) IconButton(tooltip: 'أمر صوتي', icon: const Icon(Icons.mic_rounded, color: kGold), onPressed: voice),
          if (on && view == 0)
            IconButton(
              tooltip: touchpad ? 'زراير' : 'تاتش باد',
              icon: Icon(touchpad ? Icons.dialpad_rounded : Icons.touch_app_rounded, color: kGold),
              onPressed: () {
                setState(() => touchpad = !touchpad);
                Store.p.setBool('stb_touchpad', touchpad);
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: kMuted),
            onSelected: (v) {
              if (v == 'find') discover();
              if (v == 'ip') manual();
              if (v == 'info') showInfo();
              if (v == 'reload') loadChannels();
              if (v == 'notif') setNotifRemote(!notifRemote);
              if (v == 'timers' && gm != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TimersPage(gm: gm!, channels: channels, playingId: playingId)));
              }
              if (v == 'off') {
                gm?.disconnect();
                setState(() {
                  gm = null;
                  msg = 'اتقفل الاتصال';
                });
              }
            },
            itemBuilder: (c) => [
              const PopupMenuItem(value: 'find', child: ListTile(leading: Icon(Icons.search_rounded), title: Text('دوّر على ريسيفر'))),
              const PopupMenuItem(value: 'ip', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('عنوان يدوي'))),
              if (on) const PopupMenuItem(value: 'info', child: ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('معلومات الريسيفر'))),
              if (on) const PopupMenuItem(value: 'timers', child: ListTile(leading: Icon(Icons.alarm_rounded), title: Text('المؤقتات (تسجيل/تشغيل)'))),
              if (on) const PopupMenuItem(value: 'reload', child: ListTile(leading: Icon(Icons.refresh_rounded), title: Text('حدّث القنوات'))),
              PopupMenuItem(value: 'notif', child: ListTile(leading: const Icon(Icons.notifications_active_rounded), title: Text(notifRemote ? 'شيل الريموت من الإشعارات' : 'ريموت في الإشعارات'))),
              if (on) const PopupMenuItem(value: 'off', child: ListTile(leading: Icon(Icons.link_off_rounded), title: Text('اقفل الاتصال'))),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _touchpad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              key(K.ok);
            },
            onDoubleTap: () {
              HapticFeedback.mediumImpact();
              key(K.exit);
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
              key(K.menu);
            },
            onPanEnd: (d) {
              final v = d.velocity.pixelsPerSecond;
              if (v.distance < 200) return;
              HapticFeedback.selectionClick();
              if (v.dx.abs() > v.dy.abs()) {
                key(v.dx > 0 ? K.right : K.left);
              } else {
                key(v.dy > 0 ? K.down : K.up);
              }
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E222A), Color(0xFF14171D)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: kLine),
              ),
              alignment: Alignment.center,
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swipe_rounded, size: 54, color: kGold),
                SizedBox(height: 12),
                Text('اسحب في أي اتجاه = الأسهم', style: TextStyle(fontSize: 15)),
                SizedBox(height: 4),
                Text('دوسة = OK  •  دوستين = خروج  •  ضغطة طويلة = القايمة', style: TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            RemoteKey(icon: Icons.volume_down_rounded, onTap: () => key(K.volDown), repeat: true),
            RemoteKey(icon: Icons.volume_off_rounded, onTap: () => key(K.mute)),
            RemoteKey(icon: Icons.volume_up_rounded, onTap: () => key(K.volUp), repeat: true),
            RemoteKey(label: 'CH−', onTap: () => key(K.chDown)),
            RemoteKey(label: 'CH+', onTap: () => key(K.chUp)),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip(String t, bool v, ValueChanged<bool> f, {IconData? icon}) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: FilterChip(
          avatar: icon == null ? null : Icon(icon, size: 16),
          label: Text(t),
          selected: v,
          showCheckmark: false,
          onSelected: (x) {
            HapticFeedback.selectionClick();
            f(x);
          },
        ),
      );

  Widget _channels() {
    final f = favs;
    final shown = channels
        .where((c) =>
            c.radio == radio &&
            (!favOnly || f.contains(c.id) || c.fav) &&
            (group == null || StbPrefs.groupHas(group!, c)) &&
            (!hdOnly || c.hd) &&
            (!ftaOnly || !c.scrambled) &&
            (q.isEmpty || c.name.toLowerCase().contains(q.toLowerCase()) || '${c.index + 1}' == q.trim()))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'دوّر بالاسم أو الرقم'),
          onChanged: (v) => setState(() => q = v),
        ),
      ),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          _filterChip(radio ? 'راديو' : 'تلفزيون', true, (_) => setState(() => radio = !radio), icon: radio ? Icons.radio_rounded : Icons.tv_rounded),
          _filterChip('المفضلة', favOnly, (v) => setState(() => favOnly = v), icon: Icons.star_rounded),
          _filterChip('HD', hdOnly, (v) => setState(() => hdOnly = v)),
          _filterChip('مفتوحة', ftaOnly, (v) => setState(() => ftaOnly = v), icon: Icons.lock_open_rounded),
          for (final g in StbPrefs.groups) _filterChip(g.name, group == g.name, (v) => setState(() => group = v ? g.name : null), icon: Icons.folder_special_rounded),
          ActionChip(
            avatar: const Icon(Icons.create_new_folder_rounded, size: 18),
            label: const Text('المجموعات'),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => StbGroupsPage(channels: channels)));
              if (group != null && !StbPrefs.groups.any((g) => g.name == group)) group = null;
              if (mounted) setState(() {});
            },
          ),
        ]),
      ),
      if (q.isEmpty && StbPrefs.recent.isNotEmpty && connected)
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            const Padding(padding: EdgeInsets.only(top: 12, left: 6, right: 6), child: Text('آخر قنوات:', style: TextStyle(fontSize: 12, color: kMuted))),
            for (final r in StbPrefs.recent.where((r) => r.radio == radio))
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: ActionChip(
                  label: Text(r.name, style: TextStyle(fontSize: 12, color: r.id == playingId ? kGold : null)),
                  onPressed: () => _zapTo(channels.where((c) => c.id == r.id && c.radio == r.radio).firstOrNull ?? StbChannel(r.id, r.name, r.radio, 0, const {})),
                ),
              ),
          ]),
        ),
      Expanded(
        child: channels.isEmpty
            ? EmptyState(
                icon: Icons.live_tv_rounded,
                title: busy ? 'بحمّل القنوات…' : 'مفيش قنوات لسه',
                action: busy ? null : FilledButton.icon(onPressed: loadChannels, icon: const Icon(Icons.download_rounded), label: const Text('حمّل القنوات')),
              )
            : shown.isEmpty
                ? const EmptyState(icon: Icons.search_off_rounded, title: 'مفيش قنوات بالفلتر ده')
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: shown.length,
                    itemBuilder: (c, i) {
                      final ch = shown[i];
                      final on = ch.id == playingId;
                      final isFav = f.contains(ch.id) || ch.fav;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: on ? kGold.withValues(alpha: 0.12) : kSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: on ? kGold.withValues(alpha: 0.6) : kLine),
                        ),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          leading: Container(
                            width: 44,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10)),
                            child: Text('${ch.index + 1}', style: TextStyle(fontWeight: FontWeight.w700, color: on ? kGold : Colors.white70, fontSize: 12)),
                          ),
                          title: Row(children: [
                            Flexible(child: Text(ch.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: on ? kGold : null, fontWeight: on ? FontWeight.w700 : FontWeight.w500))),
                            if (ch.hd) const Badge2('HD'),
                            if (ch.scrambled) const Badge2('مشفرة', color: kBad),
                            if (ch.locked) const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: Icon(Icons.lock_rounded, size: 14, color: kMuted)),
                          ]),
                          subtitle: on ? const Text('شغالة دلوقتي', style: TextStyle(fontSize: 11, color: kGold)) : null,
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(isFav ? Icons.star_rounded : Icons.star_outline_rounded, color: kGold),
                              onPressed: () => toggleFav(ch.id),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(StbPrefs.groupsOf(ch).isEmpty ? Icons.folder_open_rounded : Icons.folder_special_rounded, color: kMuted),
                              tooltip: 'مجموعات',
                              onPressed: () async {
                                await pickStbGroups(context, ch);
                                if (mounted) setState(() {});
                              },
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.play_circle_outline_rounded, color: kMuted),
                              tooltip: 'اتفرج على الموبايل',
                              onPressed: () => watch(ch),
                            ),
                          ]),
                          onLongPress: () => _details(ch),
                          onTap: () => _zapTo(ch),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  void _details(StbChannel ch) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (c, sc) => ListView(controller: sc, children: [
          SectionTitle(ch.name, icon: Icons.live_tv_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(spacing: 8, children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  gm?.zap(ch);
                  setState(() => playingId = ch.id);
                },
                icon: const Icon(Icons.tv_rounded),
                label: const Text('شغّلها على التلفزيون'),
              ),
              OutlinedButton.icon(onPressed: () => watch(ch), icon: const Icon(Icons.phone_android_rounded), label: const Text('على الموبايل')),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  pinChannel(ch);
                },
                icon: const Icon(Icons.add_to_home_screen_rounded),
                label: const Text('اختصار على الشاشة'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  renameCh(ch);
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('غيّر الاسم'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: kBad),
                onPressed: () {
                  Navigator.pop(c);
                  deleteCh(ch);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('امسحها'),
              ),
            ]),
          ),
          const SectionTitle('بيانات القناة من الريسيفر'),
          for (final e in ch.raw.entries)
            ListTile(dense: true, title: Text(e.key, style: const TextStyle(fontSize: 13)), trailing: Text('${e.value}', style: const TextStyle(color: kMuted))),
        ]),
      ),
    );
  }

  Future<void> renameCh(StbChannel ch) async {
    final n = await askText(context, 'اسم جديد لـ ${ch.name}', initial: ch.name);
    if (n == null || n.trim().isEmpty || n.trim() == ch.name || gm == null) return;
    try {
      await gm!.renameChannel(ch, n.trim());
      if (mounted) toast(context, 'اتبعت — بحدّث القايمة');
      await Future.delayed(const Duration(milliseconds: 800));
      await loadChannels();
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  Future<void> deleteCh(StbChannel ch) async {
    if (gm == null) return;
    final ok = await confirm(context, 'مسح «${ch.name}» من على الريسيفر نهائي — هترجع بس لو عملت بحث تاني على القمر.\n\nتمسحها؟');
    if (!ok) return;
    try {
      await gm!.deleteChannels([ch]);
      if (mounted) toast(context, 'اتمسحت — بحدّث القايمة');
      await Future.delayed(const Duration(milliseconds: 800));
      await loadChannels();
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  Future<void> sleepTimer() async {
    if (gm == null) return;
    final m = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      builder: (c) => ListView(shrinkWrap: true, children: [
        const SectionTitle('مؤقت النوم للريسيفر', icon: Icons.bedtime_rounded),
        for (final v in [0, 15, 30, 60, 90, 120])
          ListTile(title: Text(v == 0 ? 'اقفل المؤقت' : '$v دقيقة'), onTap: () => Navigator.pop(c, v)),
      ]),
    );
    if (m == null) return;
    try {
      await gm!.setSleep(m);
      if (mounted) toast(context, m == 0 ? 'المؤقت اتقفل' : 'الريسيفر هيقفل بعد $m دقيقة');
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  Future<void> watch(StbChannel ch) async {
    try {
      final u = await gm!.streamUrl(ch);
      if (u == null) {
        if (mounted) toast(context, 'الريسيفر مرجّعش رابط بث (ممكن مش بيدعم SAT>IP) — شوف السجل');
        return;
      }
      AppLog.add('STB', 'stream url $u');
      final ok = await Native.openVideo(u);
      if (!ok && mounted) {
        await Clipboard.setData(ClipboardData(text: u));
        if (mounted) toast(context, 'مفيش مشغل يفتح الرابط — اتنسخ، افتحه في VLC');
      }
    } catch (e) {
      if (mounted) toast(context, 'خطأ: $e');
    }
  }
}

// ---------------- الريموت ----------------
/// زرار ريموت: بيتحرك لما يتداس + اهتزاز + تكرار لو فضلت داسس
class RemoteKey extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? fg;
  final double size;
  final double? width;
  final bool repeat;
  final bool circle;
  const RemoteKey({super.key, this.label, this.icon, required this.onTap, this.color, this.fg, this.size = 54, this.width, this.repeat = false, this.circle = true});
  @override
  State<RemoteKey> createState() => _RemoteKeyState();
}

class _RemoteKeyState extends State<RemoteKey> {
  bool down = false;
  Timer? _rep;

  void _fire() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _start() {
    setState(() => down = true);
    _fire();
    if (widget.repeat) {
      _rep = Timer(const Duration(milliseconds: 450), () {
        _rep = Timer.periodic(const Duration(milliseconds: 160), (_) => _fire());
      });
    }
  }

  void _end() {
    _rep?.cancel();
    _rep = null;
    if (mounted) setState(() => down = false);
  }

  @override
  void dispose() {
    _rep?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? kSurface2;
    final w = widget.width ?? widget.size;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _end(),
        onTapCancel: _end,
        child: AnimatedScale(
          scale: down ? 0.90 : 1,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: w,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: down ? Color.lerp(bg, Colors.white, 0.15) : bg,
              shape: widget.circle && widget.width == null ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.circle && widget.width == null ? null : BorderRadius.circular(widget.size / 2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              boxShadow: down ? [] : [const BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: widget.icon != null
                ? Icon(widget.icon, color: widget.fg ?? Colors.white, size: widget.size * 0.44)
                : Text(widget.label ?? '', style: TextStyle(color: widget.fg ?? Colors.white, fontWeight: FontWeight.w700, fontSize: widget.size * 0.26)),
          ),
        ),
      ),
    );
  }
}

/// دايرة الأسهم الكبيرة + OK في النص
class DPad extends StatelessWidget {
  final void Function(int key) onKey;
  final double size;
  const DPad({super.key, required this.onKey, this.size = 236});

  Widget _arrow(IconData i, int k, Alignment a) => Align(
        alignment: a,
        child: RemoteKey(icon: i, onTap: () => onKey(k), color: Colors.transparent, size: size * 0.27, repeat: true),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFF2A2F39), Color(0xFF1A1D24)], radius: 0.75),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
        ),
        _arrow(Icons.keyboard_arrow_up_rounded, K.up, Alignment.topCenter),
        _arrow(Icons.keyboard_arrow_down_rounded, K.down, Alignment.bottomCenter),
        _arrow(Icons.keyboard_arrow_left_rounded, K.left, Alignment.centerLeft),
        _arrow(Icons.keyboard_arrow_right_rounded, K.right, Alignment.centerRight),
        Center(
          child: RemoteKey(
            label: 'OK',
            onTap: () => onKey(K.ok),
            size: size * 0.38,
            color: kGold,
            fg: const Color(0xFF1A1405),
          ),
        ),
      ]),
    );
  }
}

/// زرار طويل زي ريموت الصوت/القنوات (+ فوق، − تحت)
class Rocker extends StatelessWidget {
  final String label;
  final IconData up, down;
  final VoidCallback onUp, onDown;
  const Rocker({super.key, required this.label, required this.up, required this.down, required this.onUp, required this.onDown});
  @override
  Widget build(BuildContext context) => Container(
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(33),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RemoteKey(icon: up, onTap: onUp, color: Colors.transparent, size: 52, repeat: true),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
          RemoteKey(icon: down, onTap: onDown, color: Colors.transparent, size: 52, repeat: true),
        ]),
      );
}

class RemoteControl extends StatelessWidget {
  final void Function(int key) onKey;
  const RemoteControl({super.key, required this.onKey});

  Widget _k(String t, int k, {IconData? icon, Color? color, Color? fg, double size = 50, double? width}) =>
      RemoteKey(label: t, icon: icon, onTap: () => onKey(k), color: color, fg: fg, size: size, width: width);

  Widget _row(List<Widget> c, {MainAxisAlignment a = MainAxisAlignment.spaceEvenly}) => Row(mainAxisAlignment: a, children: c);

  Widget _color(Color c, int k) => RemoteKey(onTap: () => onKey(k), color: c, size: 30, width: 58);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1C2028), Color(0xFF121419)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: kLine),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(children: [
              _row([
                _k('', K.power, icon: Icons.power_settings_new_rounded, color: const Color(0xFF8E2B2B)),
                _k('TV/R', K.tvRadio, size: 46),
                _k('', K.mute, icon: Icons.volume_off_rounded),
              ], a: MainAxisAlignment.spaceBetween),
              const SizedBox(height: 8),
              _row([
                _k('', K.menu, icon: Icons.menu_rounded),
                _k('EPG', K.epg),
                _k('', K.info, icon: Icons.info_outline_rounded),
              ]),
              const SizedBox(height: 6),
              DPad(onKey: onKey),
              const SizedBox(height: 6),
              _row([
                _k('', K.exit, icon: Icons.arrow_back_rounded),
                _k('', K.fav, icon: Icons.star_rounded, fg: kGold),
                _k('', K.recall, icon: Icons.history_rounded),
              ]),
              const SizedBox(height: 10),
              _row([
                Rocker(label: 'VOL', up: Icons.add_rounded, down: Icons.remove_rounded, onUp: () => onKey(K.volUp), onDown: () => onKey(K.volDown)),
                Column(children: [
                  _k('', K.audio, icon: Icons.graphic_eq_rounded, size: 46),
                  _k('', K.subtitle, icon: Icons.subtitles_outlined, size: 46),
                  _k('', K.sat, icon: Icons.satellite_alt_rounded, size: 46),
                ]),
                Rocker(label: 'CH', up: Icons.keyboard_arrow_up_rounded, down: Icons.keyboard_arrow_down_rounded, onUp: () => onKey(K.chUp), onDown: () => onKey(K.chDown)),
              ]),
              const SizedBox(height: 12),
              _row([
                _color(const Color(0xFFD64545), K.red),
                _color(const Color(0xFF3FAE5A), K.green),
                _color(const Color(0xFFE2B33C), K.yellow),
                _color(const Color(0xFF3F7FD6), K.blue),
              ]),
              const SizedBox(height: 10),
              for (final r in const [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
              ])
                _row([for (final n in r) _k('$n', K.digit(n), size: 58, width: 84)]),
              _row([
                _k('TXT', K.teletext, size: 58, width: 84),
                _k('0', K.digit(0), size: 58, width: 84),
                _k('', K.find, icon: Icons.search_rounded, size: 58, width: 84),
              ]),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              _row([
                _k('', K.rew, icon: Icons.fast_rewind_rounded, size: 44),
                _k('', K.play, icon: Icons.play_arrow_rounded, size: 44),
                _k('', K.pause, icon: Icons.pause_rounded, size: 44),
                _k('', K.stop, icon: Icons.stop_rounded, size: 44),
                _k('', K.ff, icon: Icons.fast_forward_rounded, size: 44),
              ]),
              _row([
                _k('', K.record, icon: Icons.fiber_manual_record_rounded, fg: kBad, size: 44),
                _k('USB', K.usb, size: 44),
                _k('P−', K.pageUp, size: 44),
                _k('P+', K.pageDown, size: 44),
                _k('', K.sleep, icon: Icons.bedtime_outlined, size: 44),
              ]),
              _row([
                _k('Res', K.resolution, size: 44),
                _k('F1', K.f1, size: 44),
                _k('F2', K.f2, size: 44),
                _k('', K.pauseLive, icon: Icons.pause_circle_outline_rounded, size: 44),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------- ضبط الطبق ----------------
/// قراية القوة/الجودة من رد الريسيفر — بيدوّر على أي مفتاح اسمه شبه strength/quality
class SignalReading {
  final double? strength, quality, snr;
  final bool? locked;
  const SignalReading({this.strength, this.quality, this.snr, this.locked});
  bool get empty => strength == null && quality == null;
}

double? _pct(dynamic v) {
  final d = double.tryParse('$v'.replaceAll('%', '').trim());
  if (d == null || d.isNaN) return null;
  if (d > 100 && d <= 255) return d / 255 * 100;
  if (d > 255 && d <= 1000) return d / 10;
  return d.clamp(0, 100).toDouble();
}

SignalReading parseSignal(dynamic r) {
  final flat = <String, dynamic>{};
  void walk(dynamic x) {
    if (x is Map) {
      x.forEach((k, v) {
        if (v is Map || v is List) {
          walk(v);
        } else {
          flat['$k'.toLowerCase()] = v;
        }
      });
    } else if (x is List) {
      for (final e in x) {
        walk(e);
      }
    }
  }

  walk(r);
  double? find(List<String> keys) {
    for (final e in flat.entries) {
      if (keys.any((k) => e.key.contains(k))) {
        final p = _pct(e.value);
        if (p != null) return p;
      }
    }
    return null;
  }

  final snrRaw = flat.entries.where((e) => e.key.contains('snr') || e.key.contains('cn') || e.key.contains('mer')).map((e) => double.tryParse('${e.value}')).firstWhere((v) => v != null, orElse: () => null);
  final lockV = flat.entries.where((e) => e.key.contains('lock') && !e.key.contains('screen')).map((e) => '${e.value}').firstWhere((_) => true, orElse: () => '');
  return SignalReading(
    strength: find(['strength', 'level', 'intensity', 'power', 'signal_s', 'sig']),
    quality: find(['quality', 'qual', 'signal_q']),
    snr: snrRaw,
    locked: lockV.isEmpty ? null : (lockV == '1' || lockV.toLowerCase() == 'true'),
  );
}

/// فترة الصفارة حسب الجودة: كل ما الإشارة أحسن الصفارة أسرع
int beepIntervalMs(double q) => (1400 - (q.clamp(0, 100) * 12.4)).round().clamp(150, 1400);

class Gauge extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  const Gauge({super.key, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final v = (value ?? 0).clamp(0, 100) / 100;
    return Column(children: [
      SizedBox(
        width: 138,
        height: 138,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: v.toDouble()),
              duration: const Duration(milliseconds: 350),
              builder: (c, x, _) => CircularProgressIndicator(
                value: x,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: kSurface2,
                color: Color.lerp(kBad, color, x),
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(value == null ? '—' : '${value!.round()}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
          ]),
        ]),
      ),
    ]);
  }
}

class DishPage extends StatefulWidget {
  final GmClient gm;
  final List<StbChannel> channels;
  final String? playingId;
  final void Function(String id) onZapped;
  const DishPage({super.key, required this.gm, required this.channels, required this.playingId, required this.onZapped});
  @override
  State<DishPage> createState() => _DishPageState();
}

class _DishPageState extends State<DishPage> {
  Timer? beep;
  SignalReading sig = const SignalReading();
  String raw = '';
  bool running = false, busy = false, sound = true, finderOn = false;
  int _gen = 0;
  String q = '';
  late FinderCfg cfg = _loadCfg();
  final freqC = TextEditingController(), symC = TextEditingController();

  static FinderCfg _loadCfg() {
    try {
      return FinderCfg.fromJson(jsonDecode(Store.p.getString('finder_cfg') ?? '{}') as Map);
    } catch (_) {
      return const FinderCfg();
    }
  }

  @override
  void initState() {
    super.initState();
    freqC.text = cfg.freq > 0 ? '${cfg.freq}' : '';
    symC.text = '${cfg.sym}';
  }

  void _save(FinderCfg c) {
    setState(() => cfg = c);
    Store.p.setString('finder_cfg', jsonEncode(c.toJson()));
  }

  @override
  void dispose() {
    _gen++;
    beep?.cancel();
    if (finderOn) widget.gm.finderEnd().catchError((_) {});
    freqC.dispose();
    symC.dispose();
    super.dispose();
  }

  void _scheduleBeep() {
    beep?.cancel();
    if (!running || !sound) return;
    final qv = (sig.quality ?? 0) > 0 ? sig.quality : sig.strength; // زي G-MScreen: الجودة لو موجودة، وإلا القوة
    if (qv == null) return;
    beep = Timer.periodic(Duration(milliseconds: beepIntervalMs(qv)), (_) {
      SystemSound.play(SystemSoundType.click);
      if (qv >= 70) HapticFeedback.lightImpact();
    });
  }

  Future<void> start() async {
    final f = int.tryParse(freqC.text.trim()) ?? 0;
    final sr = int.tryParse(symC.text.trim()) ?? 0;
    if (f < 900 || sr < 1000) {
      toast(context, 'اكتب الترددة (مثلاً 11013) والـSymbol Rate (مثلاً 27500) أو خدهم من قناة');
      return;
    }
    _save(cfg.copyWith(freq: f, sym: sr));
    final sup = widget.gm.info?.satFinder;
    if (sup == false) {
      final ok = await confirm(context, 'الريسيفر ده بيقول إنه مش بيدعم ضبط الطبق من الموبايل (SatFinder). G-MScreen نفسه بيخفي الخاصية دي عنده.\n\nتجرب برضه؟');
      if (!ok || !mounted) return;
    }
    final my = ++_gen;
    setState(() {
      busy = true;
      raw = '';
    });
    try {
      AppLog.add('STB', 'satfinder start ${jsonEncode(cfg.toJson())}');
      await widget.gm.finderStart();
      finderOn = true;
      await widget.gm.finderLock(cfg);
      if (!mounted || my != _gen) return;
      setState(() {
        busy = false;
        running = true;
      });
      _loop(my);
    } catch (e) {
      AppLog.add('STB', 'satfinder failed: $e');
      if (mounted) {
        setState(() {
          busy = false;
          raw = 'خطأ: $e';
        });
        toast(context, 'الريسيفر رفض: $e');
      }
      await _end();
    }
  }

  Future<void> _loop(int my) async {
    var fails = 0;
    while (mounted && my == _gen && running) {
      try {
        final s = await widget.gm.finderSq();
        fails = 0;
        if (!mounted || my != _gen) return;
        setState(() {
          sig = s;
          raw = 'القوة ${s.strength?.round() ?? '-'}%  الجودة ${s.quality?.round() ?? '-'}%';
        });
        _scheduleBeep();
      } catch (e) {
        fails++;
        if (mounted) setState(() => raw = 'خطأ: $e');
        if (fails >= 5) {
          stop();
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _end() async {
    if (!finderOn) return;
    finderOn = false;
    try {
      await widget.gm.finderEnd();
    } catch (_) {}
  }

  void stop() {
    _gen++;
    beep?.cancel();
    _end();
    if (mounted) setState(() => running = false);
  }

  void fromChannel(StbChannel c) {
    final n = finderFromChannel(cfg, c.raw);
    if (n == null) {
      toast(context, 'الريسيفر مش باعت ترددة القناة دي — اكتبها بإيدك');
      return;
    }
    freqC.text = '${n.freq}';
    symC.text = '${n.sym}';
    _save(n);
    toast(context, '${c.name}: ${n.freq} ${n.pol == 0 ? 'H' : 'V'} ${n.sym}');
  }

  Widget _drop(String label, List<String> items, int value, void Function(int) on) => DropdownButtonFormField<int>(
        initialValue: value.clamp(0, items.length - 1),
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [for (var i = 0; i < items.length; i++) DropdownMenuItem(value: i, child: Text(items[i], overflow: TextOverflow.ellipsis))],
        onChanged: running ? null : (v) => on(v ?? 0),
      );

  Future<void> showOnTv() async {
    HapticFeedback.mediumImpact();
    try {
      await widget.gm.key(K.info);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = q.isEmpty ? <StbChannel>[] : widget.channels.where((c) => c.name.toLowerCase().contains(q.toLowerCase())).take(8).toList();
    final presetIdx = kSatPresets.indexWhere((p) => p.$2 == cfg.angle && p.$3 == cfg.dir);
    final sup = widget.gm.info?.satFinder;
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      if (sup == false)
        Card(
          color: kBad.withValues(alpha: 0.12),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('الريسيفر ده مش معلن إنه بيدعم ضبط الطبق من الموبايل — ممكن ميردش. استخدم زرار Info تحت.', style: TextStyle(fontSize: 12)),
          ),
        ),
      const SectionTitle('١. القمر والترددة', icon: Icons.satellite_alt_rounded),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<int>(
              initialValue: presetIdx < 0 ? null : presetIdx,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'القمر', isDense: true),
              hint: Text('${cfg.satName} ${cfg.angle}°${cfg.dir == 0 ? 'E' : 'W'}'),
              items: [for (var i = 0; i < kSatPresets.length; i++) DropdownMenuItem(value: i, child: Text(kSatPresets[i].$1))],
              onChanged: running ? null : (i) => i == null ? null : _save(cfg.copyWith(satName: kSatPresets[i].$1, angle: kSatPresets[i].$2, dir: kSatPresets[i].$3)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: freqC, enabled: !running, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الترددة MHz', hintText: '11013', isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: symC, enabled: !running, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Symbol Rate', isDense: true))),
            ]),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [ButtonSegment(value: 0, label: Text('H أفقي')), ButtonSegment(value: 1, label: Text('V رأسي'))],
              selected: {cfg.pol},
              onSelectionChanged: running ? null : (v) => _save(cfg.copyWith(pol: v.first)),
            ),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'أو خد الترددة من قناة (اكتب اسمها)', isDense: true), onChanged: (v) => setState(() => q = v)),
            for (final c in list)
              ListTile(
                dense: true,
                leading: const Icon(Icons.tv_rounded),
                title: Text(c.name),
                trailing: const Icon(Icons.download_rounded, size: 18),
                onTap: () {
                  fromChannel(c);
                  setState(() => q = '');
                },
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('إعدادات الـLNB (سيبها زي ما هي لو مش متأكد)', style: TextStyle(fontSize: 13)),
              children: [
                _drop('نوع الـLNB', kLnbTypes, cfg.lnbType, (v) => _save(cfg.copyWith(lnbType: v))),
                const SizedBox(height: 8),
                _drop('باور الـLNB', kLnbPowers, cfg.lnbPower, (v) => _save(cfg.copyWith(lnbPower: v))),
                const SizedBox(height: 8),
                _drop('22K', k22kModes, cfg.k22, (v) => _save(cfg.copyWith(k22: v))),
                const SizedBox(height: 8),
                _drop('DiSEqC 1.0', kDiseqcModes, cfg.diseqc, (v) => _save(cfg.copyWith(diseqc: v))),
                const SizedBox(height: 8),
              ],
            ),
          ]),
        ),
      ),
      const SectionTitle('٢. الإشارة', icon: Icons.network_check_rounded),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Gauge(label: 'القوة', value: sig.strength, color: kGold),
              Gauge(label: 'الجودة', value: sig.quality, color: kOk),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : (running ? stop : start),
                  icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(busy ? 'بيقفل على الترددة…' : (running ? 'وقّف القياس' : 'ابدأ القياس')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'الصفارة',
                onPressed: () {
                  setState(() => sound = !sound);
                  _scheduleBeep();
                },
                icon: Icon(sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('وقت القياس الريسيفر بيسيب القناة ويقفل على الترددة دي. لما توقف بيرجع. الصفارة بتسرع كل ما الجودة تعلى.', style: TextStyle(fontSize: 12, color: kMuted)),
            if (raw.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(raw, style: const TextStyle(fontSize: 12, color: kMuted))),
          ]),
        ),
      ),
      const SectionTitle('٣. على شاشة التلفزيون', icon: Icons.tv_rounded),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FilledButton.tonalIcon(onPressed: showOnTv, icon: const Icon(Icons.signal_cellular_alt_rounded), label: const Text('زرار Info')),
            const SizedBox(height: 6),
            OutlinedButton.icon(onPressed: () => widget.gm.key(K.exit), icon: const Icon(Icons.close_rounded), label: const Text('Exit')),
            const SizedBox(height: 8),
            const Text('حرّك الطبق شوية شوية (يمين/شمال الأول، وبعدين فوق/تحت) واستنى ثانية بعد كل حركة.', style: TextStyle(fontSize: 12, color: kMuted)),
          ]),
        ),
      ),
    ]);
  }
}


// ======== log.dart ========
// سجل تشخيص لكل الطلبات (الراوتر، الشبكة، الكاست، الريسيفر) — يتبعت بزرار "شارك السجل"

class LogLine {
  final DateTime t;
  final String tag;
  final String msg;
  LogLine(this.tag, this.msg) : t = DateTime.now();
  @override
  String toString() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')} [$tag] $msg';
  }
}

class AppLog extends ChangeNotifier {
  AppLog._();
  static final AppLog I = AppLog._();
  static const int maxLines = 3000;
  final List<LogLine> lines = [];

  /// أي كلمة سر أو باسورد بتتشال قبل ما تتكتب في السجل.
  static String redact(String s) {
    return s
        .replaceAllMapped(
            RegExp(r'(?<![A-Za-z0-9_])(password|passwd|WPAPSK1|AD)=([^&\s]*)',
                caseSensitive: false),
            (m) => '${m[1]}=***')
        .replaceAllMapped(
            RegExp(r'"(WPAPSK1|password|WPAPSK1_encode)"\s*:\s*"[^"]*"', caseSensitive: false),
            (m) => '"${m[1]}":"***"')
        // روابط يوتيوب: الهوست + itag بس (التوقيع ميتكتبش في السجل)
        .replaceAllMapped(RegExp(r'https?://([A-Za-z0-9.\-]*googlevideo\.com)[^\s"<>&]*(?:&amp;[^\s"<>]*)*'), (m) {
          final it = RegExp(r'itag[=/](\d+)').firstMatch(m[0]!)?.group(1);
          return 'https://${m[1]}/…${it == null ? '' : 'itag=$it'}';
        });
  }

  static void add(String tag, String msg) {
    final l = LogLine(tag, redact(msg));
    I.lines.add(l);
    if (I.lines.length > maxLines) I.lines.removeRange(0, I.lines.length - maxLines);
    if (kDebugMode) debugPrint(l.toString());
    I.notifyListeners();
  }

  String dump({String? tag}) {
    final b = StringBuffer('A2R Home log — ${DateTime.now()}\n');
    for (final l in lines) {
      if (tag == null || l.tag == tag) b.writeln(l);
    }
    return b.toString();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }
}


// ======== store.dart ========
// تخزين الإعدادات: العادي في SharedPreferences، والباسورد في flutter_secure_storage بس


class Store {
  static late SharedPreferences p;
  static const _sec = FlutterSecureStorage();

  static Future<void> init() async {
    p = await SharedPreferences.getInstance();
  }

  // ---- الراوتر ----
  static String? get routerIp => p.getString('router_ip');
  static set routerIp(String? v) =>
      v == null ? p.remove('router_ip') : p.setString('router_ip', v);
  static String get loginScheme => p.getString('login_scheme') ?? 'auto';
  static set loginScheme(String v) => p.setString('login_scheme', v);

  static Future<String?> routerPassword() => _sec.read(key: 'router_pw');
  static Future<void> saveRouterPassword(String? v) => v == null
      ? _sec.delete(key: 'router_pw')
      : _sec.write(key: 'router_pw', value: v);

  // ---- أسماء الأجهزة اللي بتسميها بنفسك (MAC أو IP → اسم) ----
  static Map<String, String> get deviceNames {
    try {
      return Map<String, String>.from(jsonDecode(p.getString('dev_names') ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> setDeviceName(String key, String name) async {
    final m = deviceNames;
    if (name.trim().isEmpty) {
      m.remove(key);
    } else {
      m[key] = name.trim();
    }
    await p.setString('dev_names', jsonEncode(m));
  }

  /// الأجهزة اللي اتشافت قبل كده (علشان تنبيه "جهاز جديد")
  static Set<String> get knownDevices => (p.getStringList('known_devs') ?? []).toSet();
  static Future<void> addKnown(Iterable<String> keys) async {
    final s = knownDevices..addAll(keys);
    await p.setStringList('known_devs', s.toList());
  }

  // ---- الريسيفر ----
  static String? get receiverIp => p.getString('stb_ip');
  static set receiverIp(String? v) =>
      v == null ? p.remove('stb_ip') : p.setString('stb_ip', v);
  static String get clientUuid {
    var u = p.getString('stb_uuid');
    if (u == null) {
      final r = Random.secure();
      u = 'a2r-home-${List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join()}';
      p.setString('stb_uuid', u);
    }
    return u;
  }

  // ---- الكاست ----
  static String? get m3uUrl => p.getString('m3u_url');
  static set m3uUrl(String? v) => v == null ? p.remove('m3u_url') : p.setString('m3u_url', v);
  static String get homePage => p.getString('home_page') ?? 'https://www.google.com';
  static set homePage(String v) => p.setString('home_page', v);
  static String? get castLocation => p.getString('cast_loc');
  static set castLocation(String? v) => v == null ? p.remove('cast_loc') : p.setString('cast_loc', v);
}

const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'تجريبي');


// ======== native.dart ========
// ===================== جسر أندرويد (MainActivity.kt بيتكتب من build.yml) =====================
class Native {
  static const _ch = MethodChannel('a2r/native');
  static int _locks = 0;

  /// أندرويد بيرمي باكتات multicast/broadcast إلا لو في MulticastLock
  static Future<void> multicastLock(bool on) async {
    _locks += on ? 1 : -1;
    if (_locks < 0) _locks = 0;
    try {
      await _ch.invokeMethod('multicastLock', {'on': _locks > 0});
    } catch (_) {}
  }

  static Future<void> notify(String title, String body) async {
    try {
      await _ch.invokeMethod('notify', {'title': title, 'body': body});
    } catch (_) {}
  }

  static Future<void> askNotifyPermission() async {
    try {
      await _ch.invokeMethod('askNotify');
    } catch (_) {}
  }

  /// صورة → JPEG (بيتعمل في Kotlin: بيفهم HEIC ويلف حسب EXIF)
  static Future<bool> toJpeg(String src, String dst, {int max = 1920, int quality = 90}) async {
    try {
      return await _ch.invokeMethod('toJpeg', {'src': src, 'dst': dst, 'max': max, 'q': quality}) == true;
    } catch (_) {
      return false;
    }
  }

  /// يفتح رابط فيديو (rtsp/http) في مشغل خارجي زي VLC/MX
  static Future<bool> openVideo(String url) async {
    try {
      return await _ch.invokeMethod('openVideo', {'url': url}) == true;
    } catch (_) {
      return false;
    }
  }
}


// ======== zte_router.dart ========
// عميل راوتر ZTE (MF286R1 اتصالات وغيره من سلسلة MF) عن طريق واجهة goform بتاعة صفحة الراوتر.
// المصادر (اتقرت مش اتجربت على راوتر أحمد):
//  - Superbox (MF286R معاد تسميته): الباسورد Base64 و AD = md5(md5(wa_inner_version+cr_version)+RD)
//    https://blog.aydindogm.us/posts/superbox-hacks-v1/
//  - سكريبت Miononno/lteforum (MC801A/MC888...): password = SHA256(SHA256(pw)+LD)
//    https://gist.github.com/tpoechtrager/766140c49a711a2177820ea42556de3c
// علشان كده التطبيق بيكتشف الطريقة لوحده (لو الراوتر بيرجّع LD يبقى SHA256) وتقدر تغيرها من الإعدادات.



/// طرق الدخول المعروفة
enum ZteScheme { base64Md5, sha256Md5, sha256Sha256 }

String md5Hex(String s) => md5.convert(utf8.encode(s)).toString();
String sha256Hex(String s) => sha256.convert(utf8.encode(s)).toString();

/// باسورد الدخول حسب الطريقة
String zteLoginPassword(ZteScheme s, String pw, String ld) {
  switch (s) {
    case ZteScheme.base64Md5:
      return base64.encode(utf8.encode(pw));
    case ZteScheme.sha256Md5:
    case ZteScheme.sha256Sha256:
      final h1 = sha256Hex(pw).toUpperCase();
      return sha256Hex(h1 + ld).toUpperCase();
  }
}

/// AD = hash(hash(wa_inner_version + cr_version) + RD)
String zteAd(ZteScheme s, String inner, String cr, String rd) {
  final h = s == ZteScheme.sha256Sha256 ? sha256Hex : md5Hex;
  return h(h(inner + cr) + rd);
}

/// يختار الطريقة: لو في LD يبقى SHA256، غير كده Base64
ZteScheme detectScheme(String ld, String innerVersion) {
  if (ld.trim().isEmpty) return ZteScheme.base64Md5;
  final v = innerVersion.toUpperCase();
  if (v.contains('MC888') || v.contains('MC889')) return ZteScheme.sha256Sha256;
  return ZteScheme.sha256Md5;
}

ZteScheme? schemeFromName(String n) {
  for (final s in ZteScheme.values) {
    if (s.name == n) return s;
  }
  return null;
}

/// جهاز متوصل حسب قايمة الراوتر
class RouterStation {
  final String mac;
  final String ip;
  final String hostname;
  final String connectTime;
  final bool wifi;
  RouterStation({
    required this.mac,
    required this.ip,
    required this.hostname,
    required this.connectTime,
    required this.wifi,
  });
}

String _pick(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  // دوّر على أي مفتاح فيه الكلمة (الفيرموير بيختلف في الأسماء)
  for (final e in m.entries) {
    final k = e.key.toString().toLowerCase();
    for (final want in keys) {
      if (k.contains(want.toLowerCase()) && e.value != null && e.value.toString().isNotEmpty) {
        return e.value.toString().trim();
      }
    }
  }
  return '';
}

String normMac(String m) {
  final hex = m.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
  if (hex.length != 12) return m.toUpperCase();
  return List.generate(6, (i) => hex.substring(i * 2, i * 2 + 2)).join(':');
}

/// يقرا station_list / lan_station_list من رد goform
List<RouterStation> parseStations(Map<String, dynamic> j) {
  final out = <RouterStation>[];
  void read(dynamic list, bool wifi) {
    if (list is String && list.trim().startsWith('[')) {
      try {
        list = jsonDecode(list);
      } catch (_) {}
    }
    if (list is! List) return;
    for (final e in list) {
      if (e is! Map) continue;
      final mac = _pick(e, ['mac_addr', 'mac', 'MAC']);
      final ip = _pick(e, ['ip_addr', 'ip', 'IP']);
      if (mac.isEmpty && ip.isEmpty) continue;
      out.add(RouterStation(
        mac: mac.isEmpty ? '' : normMac(mac),
        ip: ip,
        hostname: _pick(e, ['hostname', 'host_name', 'name', 'devName']),
        connectTime: _pick(e, ['connect_time', 'conn_time', 'time']),
        wifi: wifi,
      ));
    }
  }

  read(j['station_list'], true);
  read(j['lan_station_list'], false);
  // بعض الفيرموير: قايمة واحدة باسم تاني
  if (out.isEmpty) {
    for (final e in j.entries) {
      if (e.key.toLowerCase().contains('station')) read(e.value, !e.key.contains('lan'));
    }
  }
  // شيل التكرار (نفس الـ MAC)
  final seen = <String>{};
  return out.where((s) => seen.add(s.mac.isEmpty ? s.ip : s.mac)).toList();
}

/// قايمة الحظر: "aa:bb;cc:dd" → List
List<String> splitList(String? s) => (s ?? '')
    .split(RegExp(r'[;,]'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// نص الرسايل عند ZTE بيبقى UCS-2 hex (4 أرقام لكل حرف)
String decodeZteText(String hex) {
  final h = hex.trim();
  if (h.isEmpty) return '';
  if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(h)) return h;
  if (h.length % 4 == 0) {
    final codes = <int>[];
    for (var i = 0; i < h.length; i += 4) {
      codes.add(int.parse(h.substring(i, i + 4), radix: 16));
    }
    return String.fromCharCodes(codes);
  }
  if (h.length % 2 == 0) {
    final bytes = <int>[];
    for (var i = 0; i < h.length; i += 2) {
      bytes.add(int.parse(h.substring(i, i + 2), radix: 16));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
  return h;
}

String encodeZteText(String s) =>
    s.codeUnits.map((c) => c.toRadixString(16).padLeft(4, '0')).join().toUpperCase();

/// تاريخ ZTE: "24,11,23,10,05,33,+8" → DateTime
DateTime? parseZteDate(String s) {
  final p = s.split(RegExp(r'[,;]'));
  if (p.length < 6) return null;
  try {
    final n = p.take(6).map((e) => int.parse(e.trim())).toList();
    return DateTime(2000 + n[0], n[1], n[2], n[3], n[4], n[5]);
  } catch (_) {
    return null;
  }
}

String zteSmsTime(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  final off = t.timeZoneOffset.inHours;
  return '${two(t.year % 100)};${two(t.month)};${two(t.day)};${two(t.hour)};${two(t.minute)};${two(t.second)};${off >= 0 ? '+' : ''}$off';
}

class ZteSms {
  final String id;
  final String number;
  final String text;
  final DateTime? date;
  final bool unread;
  ZteSms(this.id, this.number, this.text, this.date, this.unread);
}

List<ZteSms> parseSms(Map<String, dynamic> j) {
  final m = j['messages'];
  if (m is! List) return [];
  return [
    for (final e in m)
      if (e is Map)
        ZteSms(
          '${e['id'] ?? ''}',
          '${e['number'] ?? ''}',
          decodeZteText('${e['content'] ?? ''}'),
          parseZteDate('${e['date'] ?? ''}'),
          '${e['tag'] ?? ''}' == '1',
        )
  ];
}

class ZteLoginResult {
  final bool ok;
  final String code;
  final String message;
  ZteLoginResult(this.ok, this.code, this.message);
}

/// اللي بيكلم الراوتر
class ZteRouter {
  String host;
  ZteRouter(this.host);

  final http.Client _c = http.Client();
  String _cookie = '';
  ZteScheme? scheme;
  String innerVersion = '';
  String crVersion = '';
  bool loggedIn = false;

  String get base => 'http://$host';
  Map<String, String> get _headers => {
        'Referer': '$base/index.html',
        'X-Requested-With': 'XMLHttpRequest',
        if (_cookie.isNotEmpty) 'Cookie': _cookie,
      };

  void _takeCookie(http.Response r) {
    final sc = r.headers['set-cookie'];
    if (sc == null || sc.isEmpty) return;
    // ممكن أكتر من كوكي مفصولين بفاصلة
    final parts = sc.split(RegExp(r',(?=[^;]+=)'));
    final jar = <String, String>{};
    for (final c in _cookie.split('; ')) {
      final i = c.indexOf('=');
      if (i > 0) jar[c.substring(0, i)] = c.substring(i + 1);
    }
    for (final p in parts) {
      final kv = p.split(';').first.trim();
      final i = kv.indexOf('=');
      if (i > 0) jar[kv.substring(0, i)] = kv.substring(i + 1);
    }
    _cookie = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// GET goform_get_cmd_process
  Future<Map<String, dynamic>> get(List<String> cmds, {Map<String, String> extra = const {}}) async {
    final q = <String, String>{
      'isTest': 'false',
      'cmd': cmds.join(','),
      if (cmds.length > 1) 'multi_data': '1',
      ...extra,
      '_': '${DateTime.now().millisecondsSinceEpoch}',
    };
    final u = Uri.parse('$base/goform/goform_get_cmd_process').replace(queryParameters: q);
    AppLog.add('ROUTER', 'GET ${u.query}');
    final r = await _c.get(u, headers: _headers).timeout(const Duration(seconds: 8));
    _takeCookie(r);
    final body = utf8.decode(r.bodyBytes, allowMalformed: true);
    AppLog.add('ROUTER', '← ${r.statusCode} ${body.length > 1500 ? '${body.substring(0, 1500)}…' : body}');
    if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
    final d = jsonDecode(body);
    if (d is Map<String, dynamic>) return d;
    throw const FormatException('رد مش JSON');
  }

  Future<String> getOne(String cmd) async {
    try {
      final j = await get([cmd]);
      return '${j[cmd] ?? ''}';
    } catch (_) {
      return '';
    }
  }

  /// POST goform_set_cmd_process (بيضيف AD لو الراوتر بيستخدمه)
  Future<Map<String, dynamic>> set(String goformId, Map<String, String> fields, {bool withAd = true}) async {
    final body = <String, String>{'isTest': 'false', 'goformId': goformId, ...fields};
    if (withAd && innerVersion.isNotEmpty && scheme != null && !body.containsKey('AD')) {
      final rd = await getOne('RD');
      if (rd.isNotEmpty) body['AD'] = zteAd(scheme!, innerVersion, crVersion, rd);
    }
    AppLog.add('ROUTER', 'POST ${body.entries.map((e) => '${e.key}=${e.value}').join('&')}');
    final r = await _c
        .post(Uri.parse('$base/goform/goform_set_cmd_process'),
            headers: {..._headers, 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
            body: body)
        .timeout(const Duration(seconds: 10));
    _takeCookie(r);
    final txt = utf8.decode(r.bodyBytes, allowMalformed: true);
    AppLog.add('ROUTER', '← ${r.statusCode} $txt');
    try {
      final d = jsonDecode(txt);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {'result': txt};
  }

  /// هل العنوان ده راوتر ZTE؟ (بيرجّع رقم الفيرموير لو أيوه)
  static Future<String?> probe(String host, {Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final u = Uri.parse('http://$host/goform/goform_get_cmd_process')
          .replace(queryParameters: {'isTest': 'false', 'cmd': 'wa_inner_version', '_': '1'});
      final r = await http.get(u, headers: {'Referer': 'http://$host/index.html'}).timeout(timeout);
      final b = utf8.decode(r.bodyBytes, allowMalformed: true);
      AppLog.add('ROUTER', 'probe $host → ${r.statusCode} ${b.length > 200 ? b.substring(0, 200) : b}');
      if (r.statusCode == 200 && b.trim().startsWith('{')) {
        final j = jsonDecode(b);
        if (j is Map) return '${j['wa_inner_version'] ?? ''}';
      }
    } catch (e) {
      AppLog.add('ROUTER', 'probe $host ✗ $e');
    }
    return null;
  }

  /// محاولة دخول واحدة بس (علشان الراوتر بيقفل بعد كام غلطة)
  Future<ZteLoginResult> login(String password, {ZteScheme? force}) async {
    final info = await get(['wa_inner_version', 'cr_version', 'RD', 'LD', 'psw_fail_num_str', 'login_lock_time'])
        .catchError((_) => <String, dynamic>{});
    innerVersion = '${info['wa_inner_version'] ?? ''}';
    crVersion = '${info['cr_version'] ?? ''}';
    var ld = '${info['LD'] ?? ''}';
    if (ld.isEmpty) ld = await getOne('LD');
    var rd = '${info['RD'] ?? ''}';
    if (rd.isEmpty) rd = await getOne('RD');
    final lock = '${info['login_lock_time'] ?? ''}';
    final left = '${info['psw_fail_num_str'] ?? ''}';
    if (left == '0' && lock.isNotEmpty && lock != '0') {
      return ZteLoginResult(false, 'locked', 'الراوتر قافل الدخول مؤقتاً ($lock ثانية) من كتر المحاولات الغلط. استنى وجرب تاني.');
    }
    scheme = force ?? detectScheme(ld, innerVersion);
    AppLog.add('ROUTER', 'login scheme=${scheme!.name} inner=$innerVersion cr=$crVersion LD=${ld.isEmpty ? '-' : 'yes'} RD=${rd.isEmpty ? '-' : 'yes'}');
    final fields = <String, String>{'password': zteLoginPassword(scheme!, password, ld)};
    if (innerVersion.isNotEmpty && rd.isNotEmpty) {
      fields['AD'] = zteAd(scheme!, innerVersion, crVersion, rd);
    }
    final r = await set('LOGIN', fields, withAd: false);
    final code = '${r['result'] ?? ''}';
    loggedIn = code == '0' || code == '4';
    if (loggedIn) return ZteLoginResult(true, code, 'تم الدخول');
    final after = await getOne('psw_fail_num_str');
    final tries = after.isEmpty ? '' : ' (فاضل $after محاولات قبل القفل)';
    if (code == '3') {
      return ZteLoginResult(false, code, 'الباسورد غلط$tries. لو متأكد منه، غيّر "طريقة الدخول" من الإعدادات وابعت السجل.');
    }
    if (code == '1') return ZteLoginResult(false, code, 'الراوتر رفض الدخول (1)$tries');
    return ZteLoginResult(false, code, 'رد غير معروف من الراوتر: $code$tries — ابعت السجل');
  }

  Future<bool> isLoggedIn() async {
    final s = await getOne('loginfo');
    loggedIn = s == 'ok';
    return loggedIn;
  }

  Future<List<RouterStation>> stations() async {
    final j = await get(['station_list', 'lan_station_list']).catchError((_) => <String, dynamic>{});
    var list = parseStations(j);
    if (list.isEmpty) {
      list = parseStations(await get(['station_list']).catchError((_) => <String, dynamic>{}));
    }
    return list;
  }

  // ---- الحظر (قايمة سودا في فلتر MAC بتاع الواي فاي) ----
  Future<({String mode, List<String> macs, List<String> names})> blockList() async {
    final j = await get(['ACL_mode', 'wifi_mac_black_list', 'wifi_hostname_black_list']);
    return (
      mode: '${j['ACL_mode'] ?? ''}',
      macs: splitList('${j['wifi_mac_black_list'] ?? ''}').map(normMac).toList(),
      names: splitList('${j['wifi_hostname_black_list'] ?? ''}'),
    );
  }

  /// حظر/فك أكتر من جهاز في أمر واحد (المواعيد)
  Future<bool> setBlockedMany({Map<String, String> add = const {}, Set<String> remove = const {}}) async {
    final cur = await blockList();
    final macs = [...cur.macs];
    final names = [...cur.names];
    for (final m0 in remove) {
      final i = macs.indexOf(normMac(m0));
      if (i >= 0) {
        macs.removeAt(i);
        if (i < names.length) names.removeAt(i);
      }
    }
    for (final e in add.entries) {
      final m = normMac(e.key);
      if (!macs.contains(m)) {
        macs.add(m);
        names.add(e.value.isEmpty ? 'A2R' : e.value.replaceAll(';', ' '));
      }
    }
    final r = await set('WIFI_MAC_FILTER', {
      'ACL_mode': macs.isEmpty ? '0' : '2',
      'wifi_mac_black_list': macs.join(';'),
      'wifi_hostname_black_list': names.join(';'),
    });
    return '${r['result']}' == 'success' || '${r['result']}' == '0';
  }

  Future<bool> setBlocked(String mac, String name, bool block) async {
    final cur = await blockList();
    final macs = [...cur.macs];
    final names = [...cur.names];
    final m = normMac(mac);
    final i = macs.indexOf(m);
    if (block && i < 0) {
      macs.add(m);
      names.add(name.isEmpty ? 'A2R' : name.replaceAll(';', ' '));
    } else if (!block && i >= 0) {
      macs.removeAt(i);
      if (i < names.length) names.removeAt(i);
    }
    final r = await set('WIFI_MAC_FILTER', {
      'ACL_mode': macs.isEmpty ? '0' : '2',
      'wifi_mac_black_list': macs.join(';'),
      'wifi_hostname_black_list': names.join(';'),
    });
    return '${r['result']}' == 'success' || '${r['result']}' == '0';
  }

  Future<Map<String, dynamic>> status() => get([
        'network_type', 'network_provider', 'signalbar', 'lte_rsrp', 'lte_rsrq', 'lte_rssi',
        'lte_snr', 'Z5g_SINR', 'lte_band', 'Z4g_rsrq', 'lte_ca_pcell_rsrq', 'Z4g_SINR', 'lte_sinr',
        'lte_ca_pcell_band', 'wan_active_band', 'lte_main_band', 'wan_ipaddr', 'ppp_status', 'realtime_tx_thrpt',
        'realtime_rx_thrpt', 'monthly_tx_bytes', 'monthly_rx_bytes', 'realtime_time',
        'SSID1', 'sms_unread_num', 'wa_inner_version',
      ]);

  Future<List<ZteSms>> sms() async {
    final j = await get(['sms_data_total'], extra: {
      'page': '0',
      'data_per_page': '100',
      'mem_store': '1',
      'tags': '10',
      'order_by': 'order by id desc',
    });
    return parseSms(j);
  }

  Future<bool> sendSms(String number, String text) async {
    final r = await set('SEND_SMS', {
      'notCallback': 'true',
      'Number': number,
      'sms_time': zteSmsTime(DateTime.now()),
      'MessageBody': encodeZteText(text),
      'ID': '-1',
      'encode_type': 'UNICODE',
    });
    return '${r['result']}' == 'success';
  }

  Future<bool> deleteSms(List<String> ids) async {
    final r = await set('DELETE_SMS', {'msg_id': '${ids.join(';')};', 'notCallback': 'true'});
    return '${r['result']}' == 'success';
  }

  Future<bool> reboot() async {
    final r = await set('REBOOT_DEVICE', {});
    return '${r['result']}' == 'success';
  }

  /// اسم وباسورد الواي فاي (لو الفيرموير بيرجعه)
  Future<({String ssid, String key})> wifiInfo() async {
    final j = await get(['SSID1', 'WPAPSK1', 'WPAPSK1_encode']);
    var key = '${j['WPAPSK1'] ?? ''}';
    final enc = '${j['WPAPSK1_encode'] ?? ''}';
    if (key.isEmpty && enc.isNotEmpty) {
      try {
        key = utf8.decode(base64.decode(enc));
      } catch (_) {
        key = enc;
      }
    }
    return (ssid: '${j['SSID1'] ?? ''}', key: key);
  }

  void close() => _c.close();
}

/// العناوين اللي بنجربها لو الموبايل مقالش البوابة
List<String> gatewayCandidates(String? phoneIp, String? wifiGateway, String? saved) {
  final out = <String>[];
  void add(String? s) {
    if (s == null) return;
    final t = s.trim();
    if (t.isEmpty || t == '0.0.0.0' || out.contains(t)) return;
    out.add(t);
  }

  add(saved);
  add(wifiGateway);
  if (phoneIp != null && RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(phoneIp)) {
    final p = phoneIp.split('.');
    add('${p[0]}.${p[1]}.${p[2]}.1');
    add('${p[0]}.${p[1]}.${p[2]}.254');
  }
  for (final c in ['192.168.0.1', '192.168.1.1', '192.168.8.1', '192.168.32.1', '192.168.100.1', '10.0.0.1']) {
    add(c);
  }
  return out;
}


// ======== lan.dart ========
// ===================== فحص الشبكة من غير الراوتر =====================
// بيلف على كل العناوين في نفس الشبكة (/24) ويجرّب يفتح اتصال على بورتات معروفة؛
// لو الجهاز رد (حتى برفض) يبقى موجود. الـ MAC مش متاح من غير الراوتر على أندرويد 10+.

class LanHost {
  final String ip;
  String name;
  String mac;
  String vendor;
  final Set<int> openPorts = {};
  String source; // scan / router / both
  bool wifi = true;
  String connectTime = '';
  bool isNew = false;
  bool blocked = false;
  int? pingMs;
  /// الاسم جه منين: router / netbios / mdns / dns / cache
  String nameSrc = '';
  LanHost(this.ip, {this.name = '', this.mac = '', this.vendor = '', this.source = 'scan'});
}

const List<int> kProbePorts = [80, 443, 8080, 62078, 8009, 554, 20000, 7000, 5555, 9100, 445, 139, 1900, 8008];

/// بورت → معناه
const Map<int, String> kPortNames = {
  21: 'FTP', 22: 'SSH', 23: 'Telnet', 53: 'DNS', 80: 'ويب', 139: 'ويندوز (NetBIOS)',
  443: 'ويب آمن', 445: 'مشاركة ملفات ويندوز', 554: 'بث فيديو RTSP (كاميرا/ريسيفر)',
  1900: 'UPnP', 5555: 'ADB أندرويد', 7000: 'AirPlay', 8008: 'Chromecast', 8009: 'Chromecast/Android TV',
  8080: 'ويب', 9100: 'طابعة', 20000: 'ريسيفر G-MScreen', 49152: 'UPnP/DLNA', 62078: 'آيفون/آيباد',
};

/// تخمين نوع الجهاز من الاسم والشركة والبورتات
String guessDeviceType(String name, String vendor, Set<int> ports, {bool isGateway = false, bool isMe = false}) {
  if (isMe) return 'الموبايل ده';
  if (isGateway) return 'الراوتر';
  final n = '${name.toLowerCase()} ${vendor.toLowerCase()}';
  if (ports.contains(20000)) return 'ريسيفر';
  if (ports.contains(62078) || n.contains('iphone') || n.contains('ipad') || n.contains('apple')) return 'آيفون / أبل';
  if (ports.contains(8009) || ports.contains(8008) || n.contains('chromecast') || n.contains('tv')) return 'تلفزيون / شاشة';
  if (ports.contains(9100) || n.contains('printer') || n.contains('epson') || n.contains('canon') || n.contains('hp')) return 'طابعة';
  if (ports.contains(554) && !ports.contains(80)) return 'كاميرا / ريسيفر';
  if (n.contains('desktop-') || n.contains('laptop-') || ports.contains(445) || ports.contains(139)) return 'كمبيوتر';
  const phones = ['android', 'galaxy', 'samsung', 'redmi', 'xiaomi', 'poco', 'huawei', 'honor', 'oppo', 'vivo', 'realme', 'infinix', 'tecno', 'itel', 'nokia', 'oneplus', 'motorola', 'sm-', 'zte'];
  for (final p in phones) {
    if (n.contains(p)) return 'موبايل';
  }
  return 'جهاز';
}

/// MAC عشوائي (خاصية الخصوصية في الموبايلات الحديثة) لو البت الثاني في أول بايت = 1
bool isRandomMac(String mac) {
  final h = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (h.length < 2) return false;
  final b = int.tryParse(h.substring(0, 2), radix: 16) ?? 0;
  return (b & 0x02) != 0;
}

// ---- قاعدة الشركات (OUI) من IEEE — بتتحمّل مرة واحدة لو عايز ----
const String kOuiUrl = 'https://standards-oui.ieee.org/oui/oui.txt';

/// يقرا سطور "28-6F-B9   (hex)\t\tNokia Shanghai Bell" → {"286FB9": "Nokia Shanghai Bell"}
Map<String, String> parseOuiText(String txt) {
  final out = <String, String>{};
  final re = RegExp(r'^\s*([0-9A-Fa-f]{2})-([0-9A-Fa-f]{2})-([0-9A-Fa-f]{2})\s+\(hex\)\s+(.+?)\s*$', multiLine: true);
  for (final m in re.allMatches(txt)) {
    out['${m[1]}${m[2]}${m[3]}'.toUpperCase()] = m[4]!.trim();
  }
  return out;
}

class Oui {
  static Map<String, String> table = {};
  static Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/oui.json');
  static Future<void> load() async {
    try {
      final f = await _file();
      if (await f.exists()) table = Map<String, String>.from(jsonDecode(await f.readAsString()) as Map);
    } catch (_) {}
  }

  static Future<int> download() async {
    AppLog.add('LAN', 'downloading OUI list');
    final r = await http.get(Uri.parse(kOuiUrl)).timeout(const Duration(seconds: 90));
    if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
    final t = parseOuiText(utf8.decode(r.bodyBytes, allowMalformed: true));
    if (t.length < 1000) throw const FormatException('الملف ناقص');
    table = t;
    await (await _file()).writeAsString(jsonEncode(t));
    return t.length;
  }

  static String vendorOf(String mac) {
    if (mac.isEmpty) return '';
    if (isRandomMac(mac)) return 'MAC عشوائي (خصوصية)';
    final h = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (h.length < 6) return '';
    return table[h.substring(0, 6)] ?? '';
  }
}

/// معلومات شبكة الموبايل
class PhoneNet {
  String? ip, gateway, mask, ssid, bssid, broadcast;
  String get prefix {
    final p = (ip ?? '').split('.');
    return p.length == 4 ? '${p[0]}.${p[1]}.${p[2]}' : '';
  }
}

Future<PhoneNet> readPhoneNet() async {
  final n = PhoneNet();
  final ni = NetworkInfo();
  Future<String?> safe(Future<String?> Function() f) async {
    try {
      return await f();
    } catch (e) {
      AppLog.add('LAN', 'network_info error $e');
      return null;
    }
  }

  n.ip = await safe(ni.getWifiIP);
  n.gateway = await safe(ni.getWifiGatewayIP);
  n.mask = await safe(ni.getWifiSubmask);
  n.broadcast = await safe(ni.getWifiBroadcast);
  n.ssid = (await safe(ni.getWifiName))?.replaceAll('"', '');
  n.bssid = await safe(ni.getWifiBSSID);
  if (n.ip == null) {
    // احتياطي: أول عنوان IPv4 خاص على الموبايل
    try {
      for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
        for (final a in i.addresses) {
          final s = a.address;
          if (s.startsWith('192.168.') || s.startsWith('10.') || RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(s)) {
            n.ip = s;
            break;
          }
        }
        if (n.ip != null) break;
      }
    } catch (_) {}
  }
  AppLog.add('LAN', 'phone ip=${n.ip} gw=${n.gateway} mask=${n.mask} ssid=${n.ssid}');
  return n;
}

/// هل في جهاز على العنوان ده؟ (اتصال اتقبل أو اترفض = موجود)
Future<Set<int>?> probeHost(String ip, {List<int> ports = kProbePorts, Duration timeout = const Duration(milliseconds: 450)}) async {
  final open = <int>{};
  var alive = false;
  await Future.wait(ports.map((p) async {
    try {
      final s = await Socket.connect(ip, p, timeout: timeout);
      open.add(p);
      alive = true;
      s.destroy();
    } on SocketException catch (e) {
      final code = e.osError?.errorCode;
      // 111 = ECONNREFUSED: الجهاز موجود والبورت مقفول
      if (code == 111 || code == 61 || code == 10061) alive = true;
    } catch (_) {}
  }));
  return alive ? open : null;
}

/// ping عن طريق برنامج النظام (موجود على أندرويد)
Future<int?> pingOnce(String ip) async {
  try {
    final sw = Stopwatch()..start();
    final r = await Process.run('ping', ['-c', '1', '-W', '1', ip]).timeout(const Duration(seconds: 3));
    final out = '${r.stdout}';
    final m = RegExp(r'time[=<]([\d.]+)').firstMatch(out);
    if (r.exitCode == 0) return m != null ? double.parse(m[1]!).round() : sw.elapsedMilliseconds;
  } catch (_) {}
  return null;
}

/// اسم ويندوز/سامبا (NetBIOS node status على UDP 137)
List<int> netbiosQuery() {
  final b = BytesBuilder();
  b.add([0x13, 0x37, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20]);
  // الاسم "*" مشفّر
  final name = List<int>.filled(16, 0x00);
  name[0] = 0x2A;
  for (final c in name) {
    b.add([0x41 + (c >> 4), 0x41 + (c & 0x0F)]);
  }
  b.add([0x00, 0x00, 0x21, 0x00, 0x01]);
  return b.toBytes();
}

String? parseNetbiosReply(List<int> d) {
  // header 12 + name 34 + type/class 4 + ttl 4 + rdlength 2 + count 1
  if (d.length < 57) return null;
  var off = 12;
  // تخطى الاسم
  while (off < d.length && d[off] != 0) {
    off += d[off] + 1;
  }
  off += 1 + 4 + 4 + 2;
  if (off >= d.length) return null;
  final count = d[off];
  off++;
  for (var i = 0; i < count && off + 18 <= d.length; i++) {
    final raw = d.sublist(off, off + 15);
    final suffix = d[off + 15];
    final flags = (d[off + 16] << 8) | d[off + 17];
    off += 18;
    final group = (flags & 0x8000) != 0;
    if (suffix == 0x00 && !group) {
      final s = String.fromCharCodes(raw).trim();
      if (s.isNotEmpty) return s;
    }
  }
  return null;
}

Future<String?> netbiosName(String ip) async {
  RawDatagramSocket? s;
  try {
    s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    s.send(netbiosQuery(), InternetAddress(ip), 137);
    final c = Completer<String?>();
    final sub = s.listen((e) {
      if (e == RawSocketEvent.read) {
        final dg = s!.receive();
        if (dg != null && !c.isCompleted) c.complete(parseNetbiosReply(dg.data));
      }
    });
    final r = await c.future.timeout(const Duration(milliseconds: 700), onTimeout: () => null);
    await sub.cancel();
    return r;
  } catch (_) {
    return null;
  } finally {
    s?.close();
  }
}

Future<String?> reverseName(String ip) async {
  try {
    final a = await InternetAddress(ip).reverse().timeout(const Duration(milliseconds: 800));
    if (a.host != ip) return a.host;
  } catch (_) {}
  return null;
}

/// فحص كل الشبكة (حتى 254 عنوان) — onFound بيتنده لكل جهاز يظهر
Future<List<LanHost>> scanLan(String prefix, {void Function(LanHost h)? onFound, void Function(double p)? onProgress, int parallel = 24}) async {
  final found = <LanHost>[];
  if (prefix.isEmpty) return found;
  final ips = [for (var i = 1; i < 255; i++) '$prefix.$i'];
  var idx = 0, done = 0;
  AppLog.add('LAN', 'scan $prefix.1-254');
  Future<void> worker() async {
    while (idx < ips.length) {
      final ip = ips[idx++];
      var ports = await probeHost(ip);
      int? ms;
      if (ports == null) {
        ms = await pingOnce(ip);
        if (ms != null) ports = <int>{};
      }
      if (ports != null) {
        final h = LanHost(ip)..pingMs = ms;
        h.openPorts.addAll(ports);
        found.add(h);
        onFound?.call(h);
      }
      done++;
      onProgress?.call(done / ips.length);
    }
  }

  await Future.wait(List.generate(parallel, (_) => worker()));
  // الأسماء
  await Future.wait(found.map((h) async {
    final nb = await netbiosName(h.ip);
    if (nb != null && !isBadHostName(nb)) {
      h.name = nb;
      h.nameSrc = 'netbios';
      return;
    }
    final rv = await reverseName(h.ip);
    if (rv != null && !isBadHostName(cleanHostName(rv))) {
      h.name = cleanHostName(rv);
      h.nameSrc = 'dns';
    }
  }));
  AppLog.add('LAN', 'scan done: ${found.length} hosts');
  return found;
}

/// فحص بورتات جهاز واحد
const List<int> kCommonPorts = [21, 22, 23, 53, 80, 139, 443, 445, 554, 1900, 5000, 5555, 7000, 8000, 8008, 8009, 8080, 8443, 9000, 9100, 20000, 49152, 62078];

Future<List<int>> portScan(String ip, {List<int> ports = kCommonPorts}) async {
  final open = <int>[];
  await Future.wait(ports.map((p) async {
    try {
      final s = await Socket.connect(ip, p, timeout: const Duration(milliseconds: 900));
      open.add(p);
      s.destroy();
    } catch (_) {}
  }));
  open.sort();
  AppLog.add('LAN', 'ports $ip → $open');
  return open;
}

/// باكت Wake-on-LAN: 6×FF + الـ MAC مكرر 16 مرة
List<int> wolPacket(String mac) {
  final h = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (h.length != 12) throw const FormatException('MAC غلط');
  final m = List.generate(6, (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16));
  return [...List.filled(6, 0xFF), for (var i = 0; i < 16; i++) ...m];
}

Future<void> sendWol(String mac, {String broadcast = '255.255.255.255'}) async {
  final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  s.broadcastEnabled = true;
  final pkt = wolPacket(mac);
  for (final port in [9, 7]) {
    s.send(pkt, InternetAddress(broadcast), port);
  }
  s.close();
  AppLog.add('LAN', 'WOL sent to $mac via $broadcast');
}

/// اختبار سرعة تنزيل (ميجابت/ثانية)
const String kSpeedUrl = 'https://speed.cloudflare.com/__down?bytes=25000000';

Future<double> speedTest({void Function(double mbps)? onTick}) async {
  final c = http.Client();
  try {
    final sw = Stopwatch()..start();
    final res = await c.send(http.Request('GET', Uri.parse(kSpeedUrl))).timeout(const Duration(seconds: 15));
    var bytes = 0;
    await for (final chunk in res.stream) {
      bytes += chunk.length;
      final s = sw.elapsedMilliseconds / 1000;
      if (s > 0) onTick?.call(bytes * 8 / s / 1e6);
      if (sw.elapsed > const Duration(seconds: 15)) break;
    }
    final mbps = bytes * 8 / (sw.elapsedMilliseconds / 1000) / 1e6;
    AppLog.add('LAN', 'speed ${mbps.toStringAsFixed(1)} Mbps ($bytes bytes)');
    return mbps;
  } finally {
    c.close();
  }
}

String fmtBytes(num b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}


// ======== cast.dart ========
// ===================== الكاست (DLNA / UPnP) =====================
// اكتشاف الشاشات بـ SSDP، والتحكم بـ AVTransport + RenderingControl (SOAP).
// Chromecast مش مدعوم في النسخة دي (محتاج Cast SDK) — أغلب الشاشات السمارت بتدعم DLNA.

class SsdpReply {
  final String location;
  final String st;
  final String usn;
  final String server;
  final String from;
  SsdpReply(this.location, this.st, this.usn, this.server, this.from);
}

String ssdpSearch(String st, {int mx = 2}) =>
    'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: $mx\r\nST: $st\r\nUSER-AGENT: Android UPnP/1.1 A2RHome/1.0\r\n\r\n';

Map<String, String> parseHttpHeaders(String txt) {
  final out = <String, String>{};
  for (final line in txt.split(RegExp(r'\r?\n')).skip(1)) {
    final i = line.indexOf(':');
    if (i > 0) out[line.substring(0, i).trim().toUpperCase()] = line.substring(i + 1).trim();
  }
  return out;
}

SsdpReply? parseSsdp(String txt, String from) {
  final first = txt.split(RegExp(r'\r?\n')).first.toUpperCase();
  if (!first.startsWith('HTTP/1.1 200') && !first.startsWith('NOTIFY')) return null;
  final h = parseHttpHeaders(txt);
  final loc = h['LOCATION'];
  if (loc == null || loc.isEmpty) return null;
  return SsdpReply(loc, h['ST'] ?? h['NT'] ?? '', h['USN'] ?? '', h['SERVER'] ?? '', from);
}

/// يبعت M-SEARCH ويجمع الردود
Future<List<SsdpReply>> ssdpDiscover(List<String> sts, {Duration wait = const Duration(seconds: 3)}) async {
  final out = <String, SsdpReply>{};
  RawDatagramSocket? s;
  try {
    await Native.multicastLock(true);
    s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    s.broadcastEnabled = true;
    final sub = s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s!.receive();
      if (d == null) return;
      final r = parseSsdp(utf8.decode(d.data, allowMalformed: true), d.address.address);
      if (r != null) out.putIfAbsent(r.location, () => r);
    });
    for (var k = 0; k < 2; k++) {
      for (final st in sts) {
        s.send(utf8.encode(ssdpSearch(st)), InternetAddress('239.255.255.250'), 1900);
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    await Future.delayed(wait);
    await sub.cancel();
  } catch (e) {
    AppLog.add('CAST', 'ssdp error $e');
  } finally {
    s?.close();
    await Native.multicastLock(false);
  }
  AppLog.add('CAST', 'ssdp → ${out.length} replies');
  return out.values.toList();
}

class DlnaDevice {
  final String name;
  final String model;
  final String location;
  final String? avTransport;
  final String? rendering;
  final String ip;
  DlnaDevice(this.name, this.model, this.location, this.avTransport, this.rendering, this.ip);
  bool get isReceiver => ip.isNotEmpty && ip == Store.receiverIp;
}

String _resolve(String base, String path) {
  final t = path.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  // بعض الأجهزة (زي الـQmax) بتبعت مسار من غير / وفيه ":" زي _urn:schemas-upnp-org:service:AVTransport_control
  final rel = (t.startsWith('/') || t.startsWith('./') || t.startsWith('../')) ? t : './$t';
  try {
    return Uri.parse(base).resolve(Uri.encodeFull(rel)).toString();
  } catch (_) {
    final b = Uri.parse(base);
    return '${b.scheme}://${b.host}:${b.port}/${t.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

/// يقرا وصف الجهاز (description.xml) ويطلع روابط التحكم
DlnaDevice? parseDeviceDescription(String xmlText, String location) {
  try {
    final doc = XmlDocument.parse(xmlText.trim());
    String text(XmlElement e, String tag) =>
        e.descendants.whereType<XmlElement>().where((x) => x.name.local == tag).map((x) => x.innerText.trim()).firstWhere((_) => true, orElse: () => '');
    final root = doc.rootElement;
    var base = text(root, 'URLBase');
    if (base.isEmpty) base = location;
    String? av, rc;
    for (final svc in root.descendants.whereType<XmlElement>().where((x) => x.name.local == 'service')) {
      final type = text(svc, 'serviceType');
      final ctrl = text(svc, 'controlURL');
      if (ctrl.isEmpty) continue;
      if (type.contains('AVTransport')) av ??= _resolve(base, ctrl);
      if (type.contains('RenderingControl')) rc ??= _resolve(base, ctrl);
    }
    if (av == null) return null;
    final name = text(root, 'friendlyName');
    return DlnaDevice(name.isEmpty ? Uri.parse(location).host : name, text(root, 'modelName'), location, av, rc, Uri.parse(location).host);
  } catch (e) {
    AppLog.add('CAST', 'bad description $location: $e');
    return null;
  }
}

/// يجيب وصف جهاز واحد (بمحاولة تانية — الـQmax ساعات بيقفل أول اتصال "Broken pipe")
Future<DlnaDevice?> fetchRenderer(String location) async {
  for (var k = 0; k < 2; k++) {
    try {
      final res = await http.get(Uri.parse(location), headers: {'User-Agent': kDlnaUa}).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) {
        AppLog.add('CAST', 'desc $location → ${res.statusCode}');
        continue;
      }
      final d = parseDeviceDescription(utf8.decode(res.bodyBytes, allowMalformed: true), location);
      if (d != null) AppLog.add('CAST', 'renderer "${d.name}" ${d.ip} av=${d.avTransport} rc=${d.rendering}');
      return d;
    } catch (e) {
      AppLog.add('CAST', 'desc $location ✗ $e');
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }
  return null;
}

/// يدوّر على الشاشات (SSDP) + آخر شاشة اتستخدمت + الريسيفر المحفوظ
Future<List<DlnaDevice>> discoverRenderers({List<String> extra = const []}) async {
  final replies = await ssdpDiscover([
    'urn:schemas-upnp-org:device:MediaRenderer:1',
    'urn:schemas-upnp-org:service:AVTransport:1',
  ]);
  final locs = <String>{...replies.map((r) => r.location), ...extra};
  final out = <DlnaDevice>[];
  final seen = <String>{};
  await Future.wait(locs.map((l) async {
    final d = await fetchRenderer(l);
    if (d != null && seen.add(d.avTransport!)) out.add(d);
  }));
  // الريسيفر الأول
  out.sort((a, b) => (b.isReceiver ? 1 : 0) - (a.isReceiver ? 1 : 0));
  return out;
}

String xmlEsc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

const Map<String, String> kExtMime = {
  'm3u8': 'application/x-mpegURL',
  'm3u': 'application/x-mpegURL',
  'mpd': 'application/dash+xml',
  'mp4': 'video/mp4',
  'm4v': 'video/mp4',
  'mkv': 'video/x-matroska',
  'webm': 'video/webm',
  'avi': 'video/x-msvideo',
  'mov': 'video/quicktime',
  'ts': 'video/mp2t',
  'm2ts': 'video/mp2t',
  'mts': 'video/mp2t',
  'flv': 'video/x-flv',
  '3gp': 'video/3gpp',
  'mpg': 'video/mpeg',
  'mpeg': 'video/mpeg',
  'vob': 'video/mpeg',
  'wmv': 'video/x-ms-wmv',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'aac': 'audio/aac',
  'ac3': 'audio/ac3',
  'wav': 'audio/wav',
  'flac': 'audio/flac',
  'ogg': 'audio/ogg',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'bmp': 'image/bmp',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'srt': 'text/srt',
  'vtt': 'text/vtt',
};

String? extOf(String url) {
  var u = url.toLowerCase().split('#').first.split('?').first;
  final slash = u.lastIndexOf('/');
  if (slash >= 0) u = u.substring(slash + 1);
  final dot = u.lastIndexOf('.');
  if (dot < 0 || dot == u.length - 1) return null;
  return u.substring(dot + 1);
}

bool hasKnownExt(String url) => kExtMime.containsKey(extOf(url));

String mimeOf(String url) => kExtMime[extOf(url)] ?? 'video/mp4';

bool isHlsMime(String m) => m.toLowerCase().contains('mpegurl');
bool isLiveMime(String m) => isHlsMime(m) || m.toLowerCase().contains('dash');

// نفس الأعلام اللي تطبيقات الكاست المعروفة (Web Video Caster/BubbleUPnP) بتبعتها:
// OP=01 = يسمح بالتقديم (Range)، FLAGS = streaming + background + DLNA 1.5
const String kDlnaFlags = 'DLNA.ORG_FLAGS=01700000000000000000000000000000';
const String kDlnaUa = 'Android/UPnP/1.0 DLNADOC/1.50 A2RHome/1.0';

// الصور: بروفايل JPEG_LRG + أعلام Interactive/Background (مش Streaming) — زي BubbleUPnP
const String kDlnaImageFlags = 'DLNA.ORG_FLAGS=00F00000000000000000000000000000';
String dlnaFeatures(String mime) => mime.startsWith('image/jpeg')
    ? 'DLNA.ORG_PN=JPEG_LRG;DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kDlnaImageFlags'
    : mime.startsWith('image')
        ? 'DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kDlnaImageFlags'
        : isLiveMime(mime)
            ? 'DLNA.ORG_OP=00;DLNA.ORG_CI=0;$kDlnaFlags'
            : 'DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kDlnaFlags';

String protocolInfoFor(String mime, {bool dlna = true}) => 'http-get:*:$mime:${dlna ? dlnaFeatures(mime) : '*'}';

/// DIDL-Lite (وصف الملف اللي بيتبعت للشاشة) + ترجمة لو موجودة
String buildDidl(String url, String title, {String? mime, String? subtitleUrl, bool dlnaFlags = true}) {
  final m = mime ?? mimeOf(url);
  final cls = m.startsWith('image')
      ? 'object.item.imageItem.photo'
      : m.startsWith('audio')
          ? 'object.item.audioItem.musicTrack'
          : 'object.item.videoItem';
  final sub = subtitleUrl == null
      ? ''
      : '<sec:CaptionInfoEx sec:type="srt">${xmlEsc(subtitleUrl)}</sec:CaptionInfoEx>'
          '<res protocolInfo="http-get:*:text/srt:*">${xmlEsc(subtitleUrl)}</res>';
  return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" '
      'xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/" xmlns:sec="http://www.sec.co.kr/" xmlns:pv="http://www.pv.com/pvns/">'
      '<item id="0" parentID="-1" restricted="1"><dc:title>${xmlEsc(title)}</dc:title>'
      '<upnp:class>$cls</upnp:class>'
      '<res protocolInfo="${protocolInfoFor(m, dlna: dlnaFlags)}"${subtitleUrl == null ? '' : ' pv:subtitleFileUri="${xmlEsc(subtitleUrl)}" pv:subtitleFileType="srt"'}>${xmlEsc(url)}</res>'
      '$sub</item></DIDL-Lite>';
}

String soapEnvelope(String service, String action, Map<String, String> args) {
  final a = args.entries.map((e) => '<${e.key}>${xmlEsc(e.value)}</${e.key}>').join();
  return '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
      '<s:Body><u:$action xmlns:u="urn:schemas-upnp-org:service:$service:1">$a</u:$action></s:Body></s:Envelope>';
}

/// يطلع قيمة عنصر من رد SOAP
String? soapValue(String xml, String tag) {
  final m = RegExp('<(?:\\w+:)?$tag(?:\\s[^>]*)?>([\\s\\S]*?)</(?:\\w+:)?$tag>').firstMatch(xml);
  return m?.group(1);
}

const Map<int, String> kUpnpErrAr = {
  401: 'الجهاز مش بيدعم الأمر ده',
  402: 'الجهاز رفض البيانات',
  501: 'الجهاز رفض الأمر',
  701: 'الجهاز مش جاهز للأمر ده دلوقتي',
  702: 'مفيش فيديو محمّل على الجهاز',
  704: 'صيغة التشغيل مش مدعومة',
  705: 'الجهاز مش قادر يقرا الفيديو',
  710: 'التقديم بالطريقة دي مش مدعوم',
  711: 'الوقت اللي اخترته مش صالح',
  714: 'نوع الملف مش مدعوم على الجهاز',
  716: 'الجهاز مقدرش يوصل للرابط',
  718: 'رقم الجلسة غلط',
};

class SoapFault implements Exception {
  final String action;
  final int http;
  final int? code;
  final String desc;
  SoapFault(this.action, this.http, this.code, this.desc);
  static SoapFault parse(String action, int http, String body) =>
      SoapFault(action, http, int.tryParse((soapValue(body, 'errorCode') ?? '').trim()), (soapValue(body, 'errorDescription') ?? '').trim());
  @override
  String toString() {
    final ar = code == null ? null : kUpnpErrAr[code];
    return '$action: ${ar ?? 'الجهاز رد بخطأ'} (${code ?? http}${desc.isEmpty ? '' : ' $desc'})';
  }
}

String fmtHms(Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

Duration parseHms(String? s) {
  if (s == null) return Duration.zero;
  final p = s.trim().split(':');
  if (p.length != 3) return Duration.zero;
  final sec = double.tryParse(p[2]) ?? 0;
  return Duration(hours: int.tryParse(p[0]) ?? 0, minutes: int.tryParse(p[1]) ?? 0, milliseconds: (sec * 1000).round());
}

String _cut(String s, int n) => s.length > n ? '${s.substring(0, n)}…(${s.length})' : s;

class DlnaClient {
  final DlnaDevice dev;
  DlnaClient(this.dev);

  Future<String> _call(String service, String url, String action, Map<String, String> args) async {
    final body = soapEnvelope(service, action, args);
    AppLog.add('CAST', '→ ${dev.name} $action $url\n${_cut(body, 1800)}');
    final r = await http
        .post(Uri.parse(url),
            headers: {
              'Content-Type': 'text/xml; charset="utf-8"',
              'SOAPAction': '"urn:schemas-upnp-org:service:$service:1#$action"',
              'User-Agent': kDlnaUa,
            },
            body: utf8.encode(body))
        .timeout(const Duration(seconds: 10));
    final txt = utf8.decode(r.bodyBytes, allowMalformed: true);
    AppLog.add('CAST', '← $action ${r.statusCode} ${_cut(txt, 700)}');
    if (r.statusCode != 200) throw SoapFault.parse(action, r.statusCode, txt);
    return txt;
  }

  Future<String> av(String action, [Map<String, String> args = const {}]) =>
      _call('AVTransport', dev.avTransport!, action, {'InstanceID': '0', ...args});

  /// زي Web Video Caster: Stop → SetAVTransportURI (بوصف كامل، ولو اترفض: وصف بسيط، ولو اترفض: من غير وصف) → Play
  Future<void> load(String url, String title, {String? subtitle, String? mime}) async {
    final m = mime ?? mimeOf(url);
    try {
      await av('Stop');
    } catch (_) {}
    final metas = <(String, String)>[
      ('كامل', buildDidl(url, title, mime: m, subtitleUrl: subtitle)),
      ('بسيط', buildDidl(url, title, mime: m, subtitleUrl: subtitle, dlnaFlags: false)),
      ('من غير وصف', ''),
    ];
    Object? last;
    for (final meta in metas) {
      try {
        await av('SetAVTransportURI', {'CurrentURI': url, 'CurrentURIMetaData': meta.$2});
        last = null;
        AppLog.add('CAST', 'SetAVTransportURI ok (وصف ${meta.$1})');
        break;
      } catch (e) {
        last = e;
        AppLog.add('CAST', 'SetAVTransportURI (وصف ${meta.$1}) ✗ $e');
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    if (last != null) throw last;
    await Future.delayed(const Duration(milliseconds: 500));
    if (m.startsWith('image')) {
      // أجهزة كتير بتعرض الصورة بعد SetAVTransportURI على طول وبترفض Play — مش هنعتبره فشل
      try {
        await play();
      } catch (e) {
        AppLog.add('CAST', 'Play للصورة اترفض (عادي في أجهزة كتير): $e');
      }
      return;
    }
    for (var i = 0; i < 4; i++) {
      try {
        await play();
        return;
      } catch (e) {
        // بعض الأجهزة بتشغّل لوحدها بعد SetAVTransportURI وترفض Play
        final st = await transportState();
        if (st == 'PLAYING' || st == 'TRANSITIONING') return;
        if (i == 3) rethrow;
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  /// v5: صورة بطريقة إرسال معيّنة (من سلّم التجارب)
  Future<void> loadImage(String url, String title, ImgVariant v) async {
    try {
      await av('Stop');
    } catch (_) {}
    if (v.play == 'wait') {
      for (var k = 0; k < 6; k++) {
        final st = await transportState();
        if (st == 'STOPPED' || st == 'NO_MEDIA_PRESENT' || st.isEmpty) break;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    await av('SetAVTransportURI', {'CurrentURI': url, 'CurrentURIMetaData': buildImageDidl(url, title, v)});
    if (v.play == 'none') return;
    await Future.delayed(Duration(milliseconds: v.play == 'wait' ? 1000 : 500));
    try {
      await play();
    } catch (e) {
      AppLog.add('CAST', 'Play للصورة اترفض: $e');
    }
  }

  Future<String> transportState() async {
    try {
      return (soapValue(await av('GetTransportInfo'), 'CurrentTransportState') ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  Future<void> play() => av('Play', {'Speed': '1'});
  Future<void> pause() => av('Pause');
  Future<void> stop() => av('Stop');
  Future<void> seek(Duration d) => av('Seek', {'Unit': 'REL_TIME', 'Target': fmtHms(d)});

  Future<({Duration pos, Duration dur, String state})> status() async {
    final p = await av('GetPositionInfo');
    final st = await transportState();
    return (pos: parseHms(soapValue(p, 'RelTime')), dur: parseHms(soapValue(p, 'TrackDuration')), state: st);
  }

  Future<int?> getVolume() async {
    if (dev.rendering == null) return null;
    final r = await _call('RenderingControl', dev.rendering!, 'GetVolume', {'InstanceID': '0', 'Channel': 'Master'});
    return int.tryParse((soapValue(r, 'CurrentVolume') ?? '').trim());
  }

  Future<void> setVolume(int v) async {
    if (dev.rendering == null) return;
    await _call('RenderingControl', dev.rendering!, 'SetVolume',
        {'InstanceID': '0', 'Channel': 'Master', 'DesiredVolume': '${v.clamp(0, 100)}'});
  }
}

/// عنوان الموبايل اللي على نفس شبكة الشاشة (لو الموبايل عليه أكتر من شبكة)
Future<String?> phoneIpFor(String? targetIp) async {
  String? first;
  try {
    final tp = targetIp?.split('.');
    for (final ni in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in ni.addresses) {
        if (a.isLoopback) continue;
        final p = a.address.split('.');
        if (tp != null && tp.length == 4 && p.length == 4 && p[0] == tp[0] && p[1] == tp[1] && p[2] == tp[2]) return a.address;
        if (ni.name.startsWith('wlan')) first ??= a.address;
      }
    }
  } catch (_) {}
  return first ?? (await readPhoneNet()).ip;
}

/// نوع الملف من الرابط، ولو الرابط مفيهوش امتداد نسأل السيرفر (HEAD)
Future<String> probeMime(String url, Map<String, String> headers) async {
  if (hasKnownExt(url) || !url.startsWith('http')) return mimeOf(url);
  final c = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    for (final method in ['HEAD', 'GET']) {
      try {
        final rq = await c.openUrl(method, Uri.parse(url)).timeout(const Duration(seconds: 6));
        headers.forEach(rq.headers.set);
        if (method == 'GET') rq.headers.set('Range', 'bytes=0-1');
        final rs = await rq.close().timeout(const Duration(seconds: 6));
        final ct = (rs.headers.contentType?.mimeType ?? '').toLowerCase();
        rs.drain<void>().catchError((_) {});
        AppLog.add('CAST', 'probe $method ${rs.statusCode} type=$ct');
        if (ct.startsWith('video/') || ct.startsWith('audio/') || ct.startsWith('image/')) return ct;
        if (ct.contains('mpegurl')) return 'application/x-mpegURL';
        if (ct.contains('dash')) return 'application/dash+xml';
      } catch (e) {
        AppLog.add('CAST', 'probe $method ✗ $e');
      }
    }
  } finally {
    c.close(force: true);
  }
  return mimeOf(url);
}

/// يعيد كتابة قايمة m3u8 علشان كل الأجزاء تعدّي على الموبايل (proxy)
String rewriteM3u8(String text, Uri base, String Function(String absUrl) mk) {
  final out = StringBuffer();
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty) {
      out.writeln(raw);
    } else if (line.startsWith('#')) {
      out.writeln(line.replaceAllMapped(RegExp(r'URI="([^"]+)"'), (m) => 'URI="${mk(base.resolve(m[1]!).toString())}"'));
    } else {
      out.writeln(mk(base.resolve(line).toString()));
    }
  }
  return out.toString();
}

class _Shared {
  final File? file;
  final String? remote;
  final Map<String, String> headers;
  final String mime;
  String? subtitleUrl;
  /// للصور (v5): طريقة الإرسال اللي بتحدد هيدرز الرد
  final ImgVariant? img;
  _Shared({this.file, this.remote, this.headers = const {}, required this.mime, this.subtitleUrl, this.img});
}

/// سيرفر صغير جوه الموبايل: بيقدّم ملفات الموبايل، وبيعدّي روابط النت اللي محتاجة هيدرز/HTTPS (زي وضع الـproxy في Web Video Caster)
class MediaServer {
  MediaServer._();
  static final MediaServer I = MediaServer._();
  HttpServer? _srv;
  final Map<String, _Shared> _items = {};
  final Map<String, String> _byKey = {};
  String _host = '';
  /// الملفات اللي الشاشة طلبتها فعلًا (علشان نعرف لو الريسيفر رفض الصورة من غير ما يطلبها)
  final Set<String> fetched = {};
  /// الملفات اللي الشاشة عملتلها HEAD بس
  final Set<String> headed = {};
  static String? idOfUrl(String url) {
    final s = Uri.tryParse(url)?.pathSegments ?? const [];
    return s.length >= 2 && (s[0] == 'f' || s[0] == 'p') ? s[1] : null;
  }

  Future<String> _base(String phoneIp) async {
    _srv ??= await _start();
    _host = phoneIp;
    return 'http://$phoneIp:${_srv!.port}';
  }

  String _id(String key, _Shared Function() make) {
    final old = _byKey[key];
    if (old != null) return old;
    final id = '${_items.length + 1}';
    _items[id] = make();
    _byKey[key] = id;
    return id;
  }

  static String _name(String s) {
    final n = s.split('?').first.split('/').where((x) => x.isNotEmpty).lastOrNull ?? 'media';
    return Uri.encodeComponent(n.length > 60 ? n.substring(n.length - 60) : n);
  }

  Future<String> share(File f, String phoneIp, {String? subtitleUrl}) async {
    final b = await _base(phoneIp);
    final id = _id('f:${f.path}', () => _Shared(file: f, mime: mimeOf(f.path), subtitleUrl: subtitleUrl));
    if (subtitleUrl != null) _items[id]!.subtitleUrl = subtitleUrl;
    return '$b/f/$id/${_name(f.path)}';
  }

  /// صورة بطريقة إرسال معيّنة — رابط جديد لكل تجربة علشان نعرف التجربة دي بالذات اتطلبت ولا لأ
  Future<String> shareImage(File f, String phoneIp, ImgVariant v, String tag) async {
    final b = await _base(phoneIp);
    final id = _id('img:${f.path}:$tag', () => _Shared(file: f, mime: 'image/jpeg', img: v));
    fetched.remove(id);
    headed.remove(id);
    return imgUrlFor(b, id, _name(f.path), v.url);
  }

  Future<String> proxy(String url, Map<String, String> headers, String phoneIp, {String? mime}) async {
    final b = await _base(phoneIp);
    final id = _id('p:$url', () => _Shared(remote: url, headers: Map.of(headers), mime: mime ?? mimeOf(url)));
    return '$b/p/$id/${_name(url)}';
  }

  Future<HttpServer> _start() async {
    final s = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    s.autoCompress = false;
    s.idleTimeout = const Duration(seconds: 60);
    // دارت بيزوّد هيدرز (x-frame-options, x-content-type-options...) الريسيفرات الرخيصة مش بتحبها
    s.defaultResponseHeaders.clear();
    AppLog.add('CAST', 'media server on port ${s.port}');
    s.listen((q) => _handle(q), onError: (e) => AppLog.add('CAST', 'server error $e'));
    return s;
  }

  void _dlnaHeaders(HttpResponse res, String mime, _Shared it) {
    res.headers.set('transferMode.dlna.org', mime.startsWith('image') ? 'Interactive' : 'Streaming');
    res.headers.set('contentFeatures.dlna.org', dlnaFeatures(mime));
    res.headers.set('Access-Control-Allow-Origin', '*');
    if (it.subtitleUrl != null) res.headers.set('CaptionInfo.sec', it.subtitleUrl!);
  }

  Future<void> _handle(HttpRequest q) async {
    final seg = q.uri.pathSegments;
    final res = q.response;
    try {
      final it = seg.length >= 2 ? _items[seg[1]] : null;
      if (it == null || (seg[0] != 'f' && seg[0] != 'p')) {
        res.statusCode = 404;
        await res.close();
        return;
      }
      if (q.method == 'GET') fetched.add(seg[1]);
      if (q.method == 'HEAD') headed.add(seg[1]);
      AppLog.add('CAST', 'serve ${q.method} /${seg[0]}/${seg[1]} from ${q.connectionInfo?.remoteAddress.address} range=${q.headers.value('range')}');
      if (it.file != null) {
        await _serveFile(q, it);
      } else {
        await _serveProxy(q, it);
      }
    } catch (e) {
      AppLog.add('CAST', 'serve error $e');
      try {
        await res.close();
      } catch (_) {}
    }
  }

  Future<void> _serveFile(HttpRequest q, _Shared it) async {
    final res = q.response;
    final f = it.file!;
    final len = await f.length();
    final iv = it.img;
    if (iv != null && iv.hdr != 'lower') {
      // v5: هيدرز بالحروف الصح ومن غير هيدرز دارت الزيادة (x-frame-options...)
      for (final h in ['x-frame-options', 'x-xss-protection', 'x-content-type-options']) {
        res.headers.removeAll(h);
      }
      res.headers.set('Content-Type', 'image/jpeg', preserveHeaderCase: true);
      res.headers.set('Accept-Ranges', 'bytes', preserveHeaderCase: true);
      res.headers.set('Date', HttpDate.format(DateTime.now()), preserveHeaderCase: true);
      res.headers.set('Server', 'Linux/3.0 UPnP/1.0 DLNADOC/1.50 A2RHome/1.0', preserveHeaderCase: true);
      for (final (k, v) in imgServeHeaders(iv)) {
        res.headers.set(k, v, preserveHeaderCase: true);
      }
    } else {
      res.headers.set('Content-Type', it.mime);
      res.headers.set('Accept-Ranges', 'bytes');
      _dlnaHeaders(res, it.mime, it);
    }
    final range = parseRange(q.headers.value('range'), len);
    if (q.headers.value('range') != null && range == null) {
      res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      res.headers.set('Content-Range', 'bytes */$len');
      await res.close();
      return;
    }
    if (range != null) {
      res.statusCode = HttpStatus.partialContent;
      final exact = iv != null && iv.hdr != 'lower';
      res.headers.set('Content-Range', 'bytes ${range.$1}-${range.$2}/$len', preserveHeaderCase: exact);
      res.contentLength = range.$2 - range.$1 + 1;
      if (exact) res.headers.set('Content-Length', '${range.$2 - range.$1 + 1}', preserveHeaderCase: true);
      if (q.method != 'HEAD') await res.addStream(f.openRead(range.$1, range.$2 + 1));
    } else {
      res.contentLength = len;
      if (iv != null && iv.hdr != 'lower') res.headers.set('Content-Length', '$len', preserveHeaderCase: true);
      if (q.method != 'HEAD') await res.addStream(f.openRead());
    }
    await res.close();
  }

  Future<void> _serveProxy(HttpRequest q, _Shared it) async {
    final res = q.response;
    final c = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = (_, __, ___) => true;
    try {
      final up = Uri.parse(it.remote!);
      final hls = isHlsMime(it.mime) || extOf(it.remote!) == 'm3u8';
      final rq = await c.openUrl(q.method == 'HEAD' && !hls ? 'HEAD' : 'GET', up);
      it.headers.forEach(rq.headers.set);
      final range = q.headers.value('range');
      if (range != null && !hls) rq.headers.set('Range', range);
      final rs = await rq.close();
      final ct = rs.headers.contentType?.mimeType.toLowerCase() ?? '';
      AppLog.add('CAST', 'proxy ← ${rs.statusCode} $ct len=${rs.contentLength}');
      if (hls || ct.contains('mpegurl')) {
        final body = await utf8.decodeStream(rs);
        final finalUri = rs.redirects.isEmpty ? up : up.resolveUri(rs.redirects.last.location);
        final base = 'http://$_host:${_srv!.port}';
        final text = body.trimLeft().startsWith('#EXTM3U')
            ? rewriteM3u8(body, finalUri, (abs) {
                final id = _id('p:$abs', () => _Shared(remote: abs, headers: it.headers, mime: extOf(abs) == 'm3u8' ? 'application/x-mpegURL' : 'video/mp2t'));
                return '$base/p/$id/${_name(abs)}';
              })
            : body;
        final bytes = utf8.encode(text);
        res.statusCode = rs.statusCode >= 400 ? rs.statusCode : 200;
        res.headers.set('Content-Type', 'application/x-mpegURL');
        res.headers.set('Cache-Control', 'no-cache');
        _dlnaHeaders(res, 'application/x-mpegURL', it);
        res.contentLength = bytes.length;
        if (q.method != 'HEAD') res.add(bytes);
        await res.close();
        return;
      }
      res.statusCode = rs.statusCode;
      final mime = (ct.isEmpty || ct.contains('octet') || ct.contains('text/plain')) ? it.mime : ct;
      res.headers.set('Content-Type', mime);
      res.headers.set('Accept-Ranges', 'bytes');
      final cr = rs.headers.value('content-range');
      if (cr != null) res.headers.set('Content-Range', cr);
      if (rs.contentLength >= 0) res.contentLength = rs.contentLength;
      _dlnaHeaders(res, mime, it);
      if (q.method == 'HEAD') {
        rs.drain<void>().catchError((_) {});
      } else {
        await res.addStream(rs);
      }
      await res.close();
    } finally {
      c.close();
    }
  }
}

/// "bytes=100-" → (100, len-1)
(int, int)? parseRange(String? h, int len) {
  if (h == null || len <= 0) return null;
  final m = RegExp(r'bytes\s*=\s*(\d*)\s*-\s*(\d*)').firstMatch(h);
  if (m == null) return null;
  final a = m[1]!, b = m[2]!;
  if (a.isEmpty && b.isEmpty) return null;
  int start, end;
  if (a.isEmpty) {
    final n = int.tryParse(b) ?? 0;
    if (n <= 0) return null;
    start = (len - n).clamp(0, len - 1);
    end = len - 1;
  } else {
    start = int.parse(a);
    end = b.isEmpty ? len - 1 : int.parse(b);
  }
  if (start >= len || end < start) return null;
  return (start, end.clamp(start, len - 1));
}

// ---- قوائم IPTV (m3u) ----
class M3uItem {
  final String name;
  final String url;
  final String group;
  final String logo;
  M3uItem(this.name, this.url, this.group, this.logo);
}

List<M3uItem> parseM3u(String txt) {
  final out = <M3uItem>[];
  String? name, group, logo;
  for (var line in const LineSplitter().convert(txt)) {
    line = line.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#EXTINF')) {
      final c = line.lastIndexOf(',');
      name = c >= 0 ? line.substring(c + 1).trim() : '';
      group = RegExp(r'group-title="([^"]*)"').firstMatch(line)?.group(1) ?? '';
      logo = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1) ?? '';
    } else if (line.startsWith('#EXTGRP:')) {
      group = line.substring(8).trim();
    } else if (!line.startsWith('#')) {
      out.add(M3uItem((name == null || name.isEmpty) ? line : name, line, group ?? '', logo ?? ''));
      name = group = logo = null;
    }
  }
  return out;
}

/// هل الرابط ده فيديو؟ (للمتصفح)
bool looksLikeMedia(String url) {
  final u = url.toLowerCase();
  if (u.startsWith('blob:') || u.startsWith('data:')) return false;
  return RegExp(r'\.(m3u8|mp4|mpd|webm|mkv|mov|m4v|mp3|m4a)(\?|#|$)').hasMatch(u) ||
      u.contains('mime=video');
}


// ======== stb.dart ========
// ===================== الريسيفر (بروتوكول G-MScreen) =====================
// المصدر الأساسي: مشروع ha-viark (MIT) — docs/PROTOCOL.md و protocol.py
//   https://github.com/jorgediez/ha-viark  (اتجرب على Viark SAT 4K، ومقارن بتطبيق GMScreen وبرنامج PC-GMScreen)
// مش متجرب على Qmax H1/H8 — أحمد بيستخدم G-MScreen معاهم فالمفروض نفس البروتوكول.

const int kStbPort = 20000;
const int kStbDiscoveryPort = 25860;
const String kLoginMagic = '39WwijOog54a';

/// "Start" + طول البودي (7 أرقام) + "End" + البودي
List<int> gmFrame(List<int> body) =>
    [...ascii.encode('Start${body.length.toString().padLeft(7, '0')}End'), ...body];

/// عكس البلوك و XOR بـ 0x5B
List<int> gmDeobfuscate(List<int> b) => [for (final x in b.reversed) x ^ 0x5B];

class StbInfo {
  final String serial, model, ip;
  final int platform, swVersion, swSub, flags;
  /// البايت 85 من بلوك الدخول: bit0 = SatFinder، bit1 = DLNA، bit2 = OTT (GsMobileLoginInfo في G-MScreen)
  final int flags2;
  StbInfo(this.serial, this.model, this.ip, this.platform, this.swVersion, this.swSub, this.flags, [this.flags2 = -1]);
  /// null = مش معروف (ريسيفر اتلقط من البث بس)
  bool? get satFinder => flags2 < 0 ? null : (flags2 & 0x01) != 0;
  bool get spectrum => (flags & 0x80) != 0;
  bool get noFreeSlot => flags & 0x01 != 0;
  bool get useJson => flags & 0x40 != 0;
  bool get satMenu => flags & 0x04 != 0;
  int get sat2ip => (flags >> 3) & 0x03;
}

StbInfo? gmParseLoginBlock(List<int> raw) {
  if (raw.length != 108) return null;
  final p = gmDeobfuscate(raw);
  if (ascii.decode(p.sublist(0, 12), allowInvalid: true) != kLoginMagic) return null;
  int be(int a, int n) {
    var v = 0;
    for (var i = 0; i < n; i++) {
      v = (v << 8) | p[a + i];
    }
    return v;
  }

  int le(int a, int n) {
    var v = 0;
    for (var i = n - 1; i >= 0; i--) {
      v = (v << 8) | p[a + i];
    }
    return v;
  }

  final serial = '${be(12, 3).toString().padLeft(6, '0')}${be(15, 3).toString().padLeft(6, '0')}';
  var mEnd = 20;
  while (mEnd < 52 && p[mEnd] != 0) {
    mEnd++;
  }
  final model = ascii.decode(p.sublist(20, mEnd), allowInvalid: true).trim();
  final ip = '${p[71]}.${p[70]}.${p[69]}.${p[68]}';
  return StbInfo(serial, model, ip, p[72], be(73, 2), le(80, 4), p[84], p[85]);
}

/// تحويل الطلب لـ JSON (كل القيم نصوص) أو XML حسب الريسيفر
/// رقم يتبعت رقم (مش نص) في JSON — G-MScreen بيبعت طلبات الـSatFinder (402) كده
class GmNum {
  final int v;
  const GmNum(this.v);
  @override
  String toString() => '$v';
}

String gmEncode(int request, Map<String, dynamic> fields, {required bool json}) {
  if (json) {
    final m = <String, dynamic>{'request': '$request'};
    fields.forEach((k, v) {
      if (v is GmNum) {
        m[k] = v.v;
      } else if (v is List) {
        m[k] = [for (final e in v) (e as Map).map((a, b) => MapEntry('$a', '$b'))];
      } else {
        m[k] = '$v';
      }
    });
    return jsonEncode(m);
  }
  final b = StringBuffer();
  fields.forEach((k, v) {
    if (k == 'array' && v is List) {
      for (final e in v) {
        b.write('<parm>');
        (e as Map).forEach((a, c) => b.write('<$a>${xmlEsc('$c')}</$a>'));
        b.write('</parm>');
      }
    } else {
      b.write('<$k>${xmlEsc('$v')}</$k>');
    }
  });
  const decl = "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>";
  return b.isEmpty ? '$decl<Command request="$request" />' : '$decl<Command request="$request">$b</Command>';
}

String gmLoginXml(String name, String uuid) =>
    "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><Command request=\"998\"><data>${xmlEsc(name)}</data><uuid>${xmlEsc(uuid)}</uuid></Command>";

class GmPacket {
  final int type, status;
  final List<int> body; // بعد فك zlib
  GmPacket(this.type, this.status, this.body);
}

int _u32(List<int> b, int o) => b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

/// بيقطّع الداتا اللي جاية لباكتات GCDH؛ بيرجع اللي اتقرا ويسيب الباقي في buf
List<GmPacket> gmTakePackets(List<int> buf) {
  final out = <GmPacket>[];
  while (true) {
    // دوّر على "GCDH"
    var i = -1;
    for (var k = 0; k + 4 <= buf.length; k++) {
      if (buf[k] == 0x47 && buf[k + 1] == 0x43 && buf[k + 2] == 0x44 && buf[k + 3] == 0x48) {
        i = k;
        break;
      }
    }
    if (i < 0) {
      if (buf.length > 3) buf.removeRange(0, buf.length - 3);
      return out;
    }
    if (i > 0) buf.removeRange(0, i);
    if (buf.length < 16) return out;
    final len = _u32(buf, 4), type = _u32(buf, 8), status = _u32(buf, 12);
    if (len > 20 * 1024 * 1024) {
      buf.removeRange(0, 4);
      continue;
    }
    if (buf.length < 16 + len) return out;
    final raw = buf.sublist(16, 16 + len);
    buf.removeRange(0, 16 + len);
    List<int> body = raw;
    if (raw.length >= 2 && raw[0] == 0x78) {
      try {
        body = zlib.decode(raw);
      } catch (_) {}
    }
    out.add(GmPacket(type, status, body));
  }
}

/// تنضيف الحروف الغريبة اللي الريسيفر بيحطها قبل الأسماء
dynamic gmClean(dynamic v) {
  if (v is String) return v.replaceAll(RegExp(r'^[\x00-\x1F]+|[\x00-\x1F]+$'), '').trim();
  if (v is List) return v.map(gmClean).toList();
  if (v is Map) return v.map((k, e) => MapEntry('$k', gmClean(e)));
  return v;
}

dynamic gmDecodeBody(List<int> body, bool json) {
  if (body.isEmpty) return null;
  final txt = utf8.decode(body, allowMalformed: true);
  if (json || txt.trimLeft().startsWith('[') || txt.trimLeft().startsWith('{')) {
    try {
      return gmClean(jsonDecode(txt));
    } catch (_) {
      // بعض الفيرموير بيحط حروف تحكم خام جوه الأسماء — نشيلها ونجرب تاني
      try {
        return gmClean(jsonDecode(txt.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')));
      } catch (_) {}
    }
  }
  try {
    final doc = XmlDocument.parse(txt);
    final parms = doc.findAllElements('parm').toList();
    Map<String, String> rec(XmlElement e) => {
          for (final c in e.childElements) c.name.local: c.innerText,
        };
    if (parms.isNotEmpty) return gmClean(parms.map(rec).toList());
    return gmClean([rec(doc.rootElement)]);
  } catch (_) {
    return txt;
  }
}

class StbChannel {
  final String id, name;
  final bool radio;
  final int index;
  final Map<String, dynamic> raw;
  StbChannel(this.id, this.name, this.radio, this.index, this.raw);
  bool _flag(String k) {
    final v = '${raw[k] ?? ''}'.trim();
    return v.isNotEmpty && v != '0' && v.toLowerCase() != 'false';
  }

  // الحقول دي جاية من رد الريسيفر نفسه (طلب 0) — شفناها في سجل Qmax H8
  bool get hd => _flag('HD');
  bool get scrambled => _flag('Scramble');
  bool get locked => _flag('Lock');
  bool get fav => _flag('FavBit');
  bool get hasEpg => _flag('EPG');
}

List<StbChannel> gmParseChannels(dynamic d, int startIndex) {
  if (d is! List) return [];
  final out = <StbChannel>[];
  var i = startIndex;
  for (final e in d) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final id = '${m['ServiceID'] ?? m['ProgramId'] ?? ''}';
    final name = '${m['ServiceName'] ?? m['Name'] ?? ''}';
    final radio = '${m['Radio'] ?? '0'}' == '1';
    final idx = int.tryParse('${m['ServiceIndex'] ?? ''}') ?? i;
    out.add(StbChannel(id, name.isEmpty ? 'قناة $id' : name, radio, idx, m));
    i++;
  }
  return out;
}

const Map<int, String> kStbStatus = {
  1: 'فشل', 2: 'صيغة غلط', 3: 'الريسيفر مفيهوش ذاكرة', 5: 'الريسيفر مردش', 9: 'باسورد غلط',
  16: 'القناة بتتسجل', 17: 'في قايمة مفتوحة على التلفزيون — اقفلها الأول',
};

/// أكواد زراير الريموت
class K {
  static const up = 1, down = 2, left = 3, right = 4, ok = 5, menu = 6, exit = 7;
  static const red = 8, green = 9, yellow = 10, blue = 11;
  static int digit(int n) => 12 + n;
  static const tvRadio = 22, mute = 23, resolution = 24, sleep = 26, recall = 29, sat = 30,
      subtitle = 31, epg = 32, fav = 33, teletext = 34, volUp = 35, volDown = 36,
      pageUp = 37, pageDown = 38, find = 39, power = 42, usb = 43, f1 = 44, f2 = 45,
      audio = 54, pauseLive = 55, info = 57, record = 58, rew = 59, ff = 60, play = 61,
      stop = 62, pause = 63, prev = 64, next = 65, chUp = 69, chDown = 70;
}

class GmClient extends ChangeNotifier {
  String host;
  GmClient(this.host);
  /// الاتصال المفتوح حاليًا من تبويب الريسيفر (الريسيفر بيقبل موبايل واحد بس، فالكاست بيستخدم نفس الاتصال)
  static GmClient? active;
  Socket? _s;
  StreamSubscription? _sub;
  Timer? _keep;
  final List<int> _buf = [];
  final Map<int, Completer<GmPacket>> _wait = {};
  Completer<List<int>>? _loginWait;
  StbInfo? info;
  bool json = true;
  bool get connected => _s != null;
  void Function(int type)? onNotify;

  static String hexPreview(List<int> b, [int n = 48]) =>
      b.take(n).map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ') + (b.length > n ? ' …(${b.length})' : '');

  Future<StbInfo> connect() async {
    await disconnect();
    AppLog.add('STB', 'connect $host:$kStbPort');
    final s = await Socket.connect(host, kStbPort, timeout: const Duration(seconds: 6));
    _s = s;
    s.setOption(SocketOption.tcpNoDelay, true);
    _loginWait = Completer<List<int>>();
    _sub = s.listen(_onData, onError: (e) {
      AppLog.add('STB', 'socket error $e');
      _lost();
    }, onDone: () {
      AppLog.add('STB', 'socket closed by receiver');
      _lost();
    });
    final login = utf8.encode(gmLoginXml('A2R Home', Store.clientUuid));
    AppLog.add('STB', '→ 998 login');
    s.add(gmFrame(login));
    final raw = await _loginWait!.future.timeout(const Duration(seconds: 8), onTimeout: () {
      throw TimeoutException('الريسيفر مردّش على الدخول');
    });
    final i = gmParseLoginBlock(raw);
    if (i == null) {
      await disconnect();
      throw const FormatException('الرد مش من ريسيفر G-MScreen (ابعت السجل)');
    }
    if (i.noFreeSlot) {
      await disconnect();
      throw const SocketException('الريسيفر مشغول — اقفل تطبيق G-MScreen من على أي موبايل تاني وجرب');
    }
    info = i;
    json = i.useJson;
    AppLog.add('STB', 'login ok model=${i.model} sn=${i.serial} platform=${i.platform} sw=${i.swVersion}.${i.swSub} flags=0x${i.flags.toRadixString(16)} flags2=0x${i.flags2.toRadixString(16)} satfinder=${i.satFinder} ${json ? 'JSON' : 'XML'}');
    _keep = Timer.periodic(const Duration(seconds: 10), (_) => send(26, {}, reply: false).catchError((_) => null));
    GmClient.active = this;
    notifyListeners();
    return i;
  }

  void _onData(List<int> d) {
    AppLog.add('STB', '← ${d.length}B ${hexPreview(d)}');
    _buf.addAll(d);
    if (_loginWait != null && !_loginWait!.isCompleted) {
      if (_buf.length >= 108) {
        final b = _buf.sublist(0, 108);
        _buf.removeRange(0, 108);
        _loginWait!.complete(b);
      } else {
        return;
      }
    }
    for (final p in gmTakePackets(_buf)) {
      AppLog.add('STB', '← type=${p.type} status=${p.status} body=${p.body.length}B ${p.body.isEmpty ? '' : utf8.decode(p.body.take(300).toList(), allowMalformed: true)}');
      if (p.type >= 2000 && p.type < 3000) {
        onNotify?.call(p.type);
        continue;
      }
      final c = _wait.remove(p.type);
      if (c != null && !c.isCompleted) c.complete(p);
    }
  }

  void _lost() {
    _keep?.cancel();
    _keep = null;
    _s?.destroy();
    _s = null;
    for (final c in _wait.values) {
      if (!c.isCompleted) c.completeError(const SocketException('الاتصال بالريسيفر اتقطع'));
    }
    _wait.clear();
    if (_loginWait != null && !_loginWait!.isCompleted) {
      _loginWait!.completeError(const SocketException('الريسيفر قفل الاتصال'));
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (GmClient.active == this) GmClient.active = null;
    _keep?.cancel();
    _keep = null;
    await _sub?.cancel();
    _sub = null;
    _s?.destroy();
    _s = null;
    _buf.clear();
    _wait.clear();
  }

  Future<dynamic> send(int request, Map<String, dynamic> fields, {bool reply = true, Duration timeout = const Duration(seconds: 12)}) async {
    if (_s == null) await connect();
    final body = gmEncode(request, fields, json: json);
    if (request != 26) AppLog.add('STB', '→ $request $body');
    Completer<GmPacket>? c;
    if (reply) {
      _wait.remove(request);
      c = _wait[request] = Completer<GmPacket>();
    }
    _s!.add(gmFrame(utf8.encode(body)));
    if (c == null) return null;
    final p = await c.future.timeout(timeout, onTimeout: () {
      _wait.remove(request);
      throw TimeoutException('الريسيفر مردش على طلب $request');
    });
    if (p.status != 0) throw StateError(kStbStatus[p.status] ?? 'خطأ ${p.status}');
    return gmDecodeBody(p.body, json);
  }

  static Map<String, dynamic> first(dynamic r) {
    if (r is List && r.isNotEmpty && r.first is Map) return Map<String, dynamic>.from(r.first as Map);
    if (r is Map) return Map<String, dynamic>.from(r);
    return {};
  }

  Future<Map<String, dynamic>> state() async {
    try {
      final m = first(await send(14, {}));
      if (m.isNotEmpty) return m;
    } catch (_) {}
    return first(await send(15, {}));
  }

  Future<List<StbChannel>> channels({void Function(int got)? progress}) async {
    final st = await state();
    final total = int.tryParse('${st['ChannelNum'] ?? ''}') ?? 0;
    final out = <StbChannel>[];
    var from = 0;
    final end = total > 0 ? total - 1 : 4999;
    while (from <= end) {
      final to = (from + 99).clamp(0, end);
      final page = await send(0, {'FromIndex': '$from', 'ToIndex': '$to'}, timeout: const Duration(seconds: 20));
      final ch = gmParseChannels(page, from);
      if (ch.isEmpty) break;
      out.addAll(ch);
      progress?.call(out.length);
      from = to + 1;
    }
    return out;
  }

  Future<String?> playingId() async {
    try {
      final v = first(await send(3, {}))['Data'];
      return v == null || '$v'.isEmpty ? null : '$v';
    } catch (_) {
      return null;
    }
  }

  Future<void> key(int code) => send(1040, {
        'array': [
          {'KeyValue': '$code'}
        ]
      }, reply: false);

  Future<void> zap(StbChannel c) => send(1000, {
        'array': [
          {'TvState': c.radio ? '1' : '0', 'ProgramId': c.id}
        ]
      });

  Future<void> power() => send(1041, {}, reply: false);

  /// رابط البث للموبايل (مش بيغير القناة على التلفزيون)
  Future<String?> streamUrl(StbChannel c) async {
    final r = await send(1009, {
      'array': [
        {'TvState': c.radio ? '1' : '0', 'ProgramId': c.id}
      ]
    });
    if (r is String) return RegExp(r'(rtsp|http)s?://\S+').firstMatch(r)?.group(0);
    final m = first(r);
    for (final v in m.values) {
      final s = '$v';
      if (s.startsWith('rtsp://') || s.startsWith('http')) return s;
    }
    final any = RegExp(r'(rtsp|http)s?://[^"\s<]+').firstMatch(jsonEncode(r));
    return any?.group(0);
  }

  Future<void> stopStream() => send(1012, {}, reply: false);

  // ---------- ضبط الطبق (SatFinder) — من G-MScreen 1.0.22176: mktvsmart.screen.satfinder.l ----------
  /// 401 = ابدأ وضع الـSatFinder (الرد status 0 = تمام)
  Future<void> finderStart() => send(401, {}, timeout: const Duration(seconds: 8));

  /// 402 = اقفل على ترددة (الريسيفر بيعمل tune عليها)
  Future<void> finderLock(FinderCfg c) => send(402, gmFinderLockFields(c), timeout: const Duration(seconds: 10));

  /// 403 = اقرا القوة والجودة: [{"strength":N,"quality":N}] من 0 لـ 100
  Future<SignalReading> finderSq() async => gmParseSq(await send(403, {}, timeout: const Duration(seconds: 4)));

  /// 405 = اخرج من وضع الـSatFinder
  Future<void> finderEnd() => send(405, {}, reply: false);

  // ---------- تعديل القنوات — من GsChannelListFragment + JsonParser.serialize ----------
  /// 1001 = تغيير اسم قناة
  Future<void> renameChannel(StbChannel c, String name) => _sendLoose(1001, gmRenameFields(c, name));

  /// 1002 = مسح قنوات (نهائي من على الريسيفر)
  Future<void> deleteChannels(List<StbChannel> list) => _sendLoose(1002, gmDeleteFields(list));

  /// 1050 = مؤقت النوم (0 = اقفله) — من GsParentControlActivity
  Future<void> setSleep(int minutes) => _sendLoose(1050, gmSleepFields(minutes));

  // ---- العرض على الريسيفر بطريقة G-MScreen نفسه (1063 + 31) ----
  // من BaseCastViewModel / UrlLinkViewModel / LiveScreenActivity: 1063 = {mediaType, actionCode, url, seekTime}
  // mediaType: 0 فيديو، 1 صورة، 2 صوت. actionCode: 0 تشغيل، 1 كمّل، 2 إيقاف مؤقت، 3 وقف، 4 تقديم (seekTime بالملي ثانية)
  Future<void> castSend(int mediaType, int action, String url, {int seekMs = 0}) =>
      _sendLoose(1063, gmCastFields(mediaType, action, url, seekMs));

  /// 31 = حالة التشغيل (stateCode 0 شغال، 1 متوقف مؤقت، 2 واقف، 3 فاضي؛ الأوقات بالملي ثانية)
  Future<GmCastInfo?> castInfo() async {
    try {
      return gmParseCastInfo(await send(31, {}, timeout: const Duration(seconds: 4)));
    } catch (e) {
      AppLog.add('STB', 'cast info ✗ $e');
      return null;
    }
  }

  // ---- المؤقتات (SubEventTimerDispFragment / SubTimerAddTimerActivity) ----
  /// 1 = قايمة المؤقتات
  Future<List<GmTimer>> timers() async => gmParseTimers(await send(1, {}, timeout: const Duration(seconds: 8)));

  /// 11 = وقت الريسيفر
  Future<DateTime?> stbTime() async {
    try {
      return gmParseStbTime(await send(11, {}, timeout: const Duration(seconds: 5)));
    } catch (_) {
      return null;
    }
  }

  /// 1021 إضافة / 1022 تعديل. لو الريسيفر رد بـ 15 يبقى في تعارض مع مؤقت تاني ورقمه في Data
  Future<int?> saveTimer(GmTimer t, {required bool edit}) async {
    final req = edit ? 1022 : 1021;
    final p = await sendPacket(req, {'array': [gmTimerFields(t)]});
    if (p == null || p.status == 0) return null;
    if (p.status == 15) {
      final d = gmDecodeBody(p.body, json);
      final m = GmClient.first(d);
      return int.tryParse('${m['Data'] ?? ''}') ?? -1;
    }
    throw StateError(kStbStatus[p.status] ?? 'الريسيفر رفض المؤقت (${p.status})');
  }

  /// 1023 = استبدال المؤقت اللي متعارض (رقمه من رد 15)
  Future<void> replaceTimer(GmTimer t, int conflictIndex) =>
      _sendLoose(1023, {'array': [gmTimerFields(t.copyWithIndex(conflictIndex))]});

  /// 1020 = مسح مؤقت (TimerIndex = ترتيبه في القايمة)
  Future<void> deleteTimer(GmTimer t) => _sendLoose(1020, {'array': [gmTimerFields(t)]});

  /// زي send بس بيرجّع الرد كله من غير ما يرمي خطأ لو الحالة مش 0 (null لو مفيش رد)
  Future<GmPacket?> sendPacket(int request, Map<String, dynamic> fields, {Duration timeout = const Duration(seconds: 6)}) async {
    if (_s == null) await connect();
    final body = gmEncode(request, fields, json: json);
    AppLog.add('STB', '→ $request $body');
    _wait.remove(request);
    final c = _wait[request] = Completer<GmPacket>();
    _s!.add(gmFrame(utf8.encode(body)));
    try {
      return await c.future.timeout(timeout);
    } on TimeoutException {
      _wait.remove(request);
      AppLog.add('STB', 'no reply to $request');
      return null;
    }
  }

  /// G-MScreen نفسه مش بيستنى رد على الطلبات دي — بنستنى شوية، ولو مفيش رد نكمّل
  Future<void> _sendLoose(int req, Map<String, dynamic> f) async {
    try {
      await send(req, f, timeout: const Duration(seconds: 5));
    } on TimeoutException {
      AppLog.add('STB', 'no reply to $req (normal for G-MScreen) — continuing');
    }
  }
}

/// إعدادات الترددة اللي بنقيس عليها (نفس حقول DataConvertLockTpSettingInfo)
class FinderCfg {
  final String satName;
  final double angle; // بالدرجات
  final int dir; // 0 = شرق، 1 = غرب
  final int freq; // MHz
  final int sym; // kS/s
  final int pol; // 0 = H، 1 = V
  final int lnbType, lnbPower, k22, diseqc; // أرقام من القوايم اللي تحت
  const FinderCfg({this.satName = 'Nilesat', this.angle = 7.0, this.dir = 1, this.freq = 0, this.sym = 27500, this.pol = 0, this.lnbType = 0, this.lnbPower = 0, this.k22 = 0, this.diseqc = 0});
  FinderCfg copyWith({String? satName, double? angle, int? dir, int? freq, int? sym, int? pol, int? lnbType, int? lnbPower, int? k22, int? diseqc}) => FinderCfg(
      satName: satName ?? this.satName, angle: angle ?? this.angle, dir: dir ?? this.dir, freq: freq ?? this.freq, sym: sym ?? this.sym, pol: pol ?? this.pol,
      lnbType: lnbType ?? this.lnbType, lnbPower: lnbPower ?? this.lnbPower, k22: k22 ?? this.k22, diseqc: diseqc ?? this.diseqc);
  Map<String, dynamic> toJson() => {'satName': satName, 'angle': angle, 'dir': dir, 'freq': freq, 'sym': sym, 'pol': pol, 'lnbType': lnbType, 'lnbPower': lnbPower, 'k22': k22, 'diseqc': diseqc};
  static FinderCfg fromJson(Map m) {
    int i(String k, int d) => int.tryParse('${m[k] ?? ''}') ?? d;
    return FinderCfg(satName: '${m['satName'] ?? 'Nilesat'}', angle: double.tryParse('${m['angle'] ?? ''}') ?? 7.0, dir: i('dir', 1), freq: i('freq', 0), sym: i('sym', 27500), pol: i('pol', 0),
        lnbType: i('lnbType', 0), lnbPower: i('lnbPower', 0), k22: i('k22', 0), diseqc: i('diseqc', 0));
  }
}

// نفس القوايم اللي في G-MScreen (res/values/arrays.xml) — الريسيفر بياخد النص والرقم الاتنين
const kLnbTypes = ['Universal', '9750/10750', '5150/5750', '5750/5150', 'Unicable A', 'Unicable B', 'Unicable C', 'Unicable D', '05150', '05750', '09750', '10600', '10700', '10750'];
const kLnbPowers = ['13V/18V', '13V', '18V', '0V'];
const k22kModes = ['Off', 'On', 'Auto'];
const kDiseqcModes = ['None', 'LNB1', 'LNB2', 'LNB3', 'LNB4', 'Burst A', 'Burst B', 'Auto'];

/// أشهر الأقمار اللي بتتشاف من مصر (الزاوية + الاتجاه)
const kSatPresets = <(String, double, int)>[
  ('Nilesat 7°W', 7.0, 1),
  ('Eutelsat 8°W', 8.0, 1),
  ('Badr / Arabsat 26°E', 26.0, 0),
  ('Es\'hailSat 25.5°E', 25.5, 0),
  ('Arabsat 30.5°E', 30.5, 0),
  ('Hotbird 13°E', 13.0, 0),
  ('Turksat 42°E', 42.0, 0),
  ('Yahsat 52.5°E', 52.5, 0),
];

String _idx(List<String> l, int i) => l[i.clamp(0, l.length - 1)];

Map<String, dynamic> gmFinderLockFields(FinderCfg c) => {
      'sat_angle': GmNum((c.angle * 10).round()),
      'sat_direction': GmNum(c.dir),
      'cur_tuned_freq': GmNum(c.freq),
      'request_sym': GmNum(c.sym),
      'vertical_polor': GmNum(c.pol),
      'lnb_type_string': _idx(kLnbTypes, c.lnbType),
      'lnb_type_index': GmNum(c.lnbType.clamp(0, kLnbTypes.length - 1)),
      'lnb_power_string': _idx(kLnbPowers, c.lnbPower),
      'lnb_power_index': GmNum(c.lnbPower.clamp(0, kLnbPowers.length - 1)),
      '22K_string': _idx(k22kModes, c.k22),
      '22K_index': GmNum(c.k22.clamp(0, k22kModes.length - 1)),
      'diseqc10_string': _idx(kDiseqcModes, c.diseqc),
      'diseqc10_index': GmNum(c.diseqc.clamp(0, kDiseqcModes.length - 1)),
    };

/// رد 403: G-MScreen بيقرا "strength" و"quality" (0–100) ويعرضهم %
SignalReading gmParseSq(dynamic r) {
  Map? m;
  if (r is List && r.isNotEmpty && r.first is Map) m = r.first as Map;
  if (r is Map) m = r;
  if (m == null) return const SignalReading();
  double? v(String k) {
    final d = double.tryParse('${m![k] ?? ''}');
    return d?.clamp(0, 100).toDouble();
  }

  return SignalReading(strength: v('strength'), quality: v('quality'));
}

/// الترددة من بيانات القناة (لو الريسيفر بيبعتها في قايمة القنوات)
FinderCfg? finderFromChannel(FinderCfg base, Map<String, dynamic> raw) {
  int? n(List<String> ks) {
    for (final k in ks) {
      final x = int.tryParse('${raw[k] ?? ''}'.trim());
      if (x != null && x > 0) return x;
    }
    return null;
  }

  final f = n(['Freq', 'Frequency', 'TpFreq']);
  if (f == null) return null;
  var sr = n(['SR', 'SymbolRate', 'Sym']) ?? base.sym;
  if (sr > 100000) sr = sr ~/ 1000; // لو جاي بالـS/s
  final pv = '${raw['POL'] ?? raw['Polar'] ?? raw['Pol'] ?? ''}'.trim().toUpperCase();
  final pol = pv.startsWith('V') || pv == '1' ? 1 : (pv.startsWith('H') || pv == '0' ? 0 : base.pol);
  return base.copyWith(freq: f > 100000 ? f ~/ 1000 : f, sym: sr, pol: pol);
}

Map<String, dynamic> gmRenameFields(StbChannel c, String name) => {
      'array': [
        {'TvState': c.radio ? '1' : '0', 'ProgramId': c.id, 'ProgramName': name}
      ]
    };

Map<String, dynamic> gmDeleteFields(List<StbChannel> list) => {
      'TvState': list.isNotEmpty && list.first.radio ? '1' : '0',
      'array': [
        for (final c in list) {'ProgramId': c.id}
      ],
      'TotalNum': '${list.length}',
    };

Map<String, dynamic> gmSleepFields(int minutes) => minutes <= 0 ? {'SleepSwitch': '0'} : {'SleepSwitch': '1', 'SleepTime': '$minutes'};

/// بيسمع إعلانات الريسيفرات على UDP 25860 (الريسيفر هو اللي بيبعت، مش إحنا)
Future<Map<String, StbInfo>> discoverReceivers({Duration wait = const Duration(seconds: 6)}) async {
  final found = <String, StbInfo>{};
  RawDatagramSocket? s;
  try {
    await Native.multicastLock(true);
    s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, kStbDiscoveryPort, reuseAddress: true);
    s.broadcastEnabled = true;
    final sub = s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = s!.receive();
      if (d == null) return;
      AppLog.add('STB', 'udp ${d.address.address} ${d.data.length}B');
      final i = gmParseLoginBlock(d.data);
      if (i != null) found[d.address.address] = i;
    });
    await Future.delayed(wait);
    await sub.cancel();
  } catch (e) {
    AppLog.add('STB', 'discovery error $e');
  } finally {
    s?.close();
    await Native.multicastLock(false);
  }
  return found;
}


// ======== كاست + مؤقتات بطريقة G-MScreen (من قراءة كود التطبيق الرسمي 1.0.22176) ========
int gmMediaTypeFor(String mime) => mime.startsWith('image') ? 1 : mime.startsWith('audio') ? 2 : 0;

/// JsonParser.serialize حالة 1063 (DataConvertCastPlayModel): الأرقام بتتبعت أرقام مش نص
Map<String, dynamic> gmCastFields(int mediaType, int action, String url, int seekMs) => {
      'mediaType': GmNum(mediaType),
      'actionCode': GmNum(action),
      'url': url,
      'seekTime': GmNum(seekMs),
    };

class GmCastInfo {
  final int mediaType, state, currentMs, totalMs;
  final String title, url;
  GmCastInfo(this.mediaType, this.state, this.currentMs, this.totalMs, this.title, this.url);
  String get stateName => const {0: 'PLAYING', 1: 'PAUSED_PLAYBACK', 2: 'STOPPED', 3: 'NO_MEDIA_PRESENT'}[state] ?? '$state';
}

/// JsonParser.parse النوع 35 (رد طلب 31)
GmCastInfo? gmParseCastInfo(dynamic r) {
  final m = GmClient.first(r);
  if (m.isEmpty) return null;
  int i(String k, int d) => int.tryParse('${m[k] ?? ''}') ?? d;
  return GmCastInfo(i('mediaType', -1), i('stateCode', 3), i('currentTime', 0), i('totalTime', 0), '${m['title'] ?? ''}', '${m['url'] ?? ''}');
}

class GmTimer {
  final int index; // ترتيبه في قايمة الريسيفر
  final String programId, programName;
  final int month, day, startH, startM, endH, endM; // endH ممكن تبقى 24+ لو بيخلص تاني يوم
  final int repeat; // 0 مرة، 1 يومي، 2 أسبوعي، 3 أيام الشغل، 4 الويك إند
  final int status; // bit 2 = تسجيل، bit 8 = يقفل الريسيفر بعده
  final int eventId;
  const GmTimer({this.index = 0, required this.programId, this.programName = '', required this.month, required this.day, required this.startH, required this.startM, required this.endH, required this.endM, this.repeat = 0, this.status = 0, this.eventId = 0});
  bool get record => status & 2 == 2;
  bool get standby => status & 8 == 8;
  GmTimer copyWithIndex(int i) => GmTimer(index: i, programId: programId, programName: programName, month: month, day: day, startH: startH, startM: startM, endH: endH, endM: endM, repeat: repeat, status: status, eventId: eventId);
}

const kTimerRepeats = ['مرة واحدة', 'يومي', 'أسبوعي', 'أيام الشغل', 'الويك إند'];

/// JsonParser.serialize حالة 1020-1023 (DataConvertTimeModel) — كله نص
Map<String, String> gmTimerFields(GmTimer t) => {
      'TimerIndex': '${t.index}',
      'TimerProgramId': t.programId,
      'TimerMonth': '${t.month}',
      'TimerDay': '${t.day}',
      'TimerStartHour': '${t.startH}',
      'TimerStartMin': '${t.startM}',
      'TimerEndHour': '${t.endH}',
      'TimerEndMin': '${t.endM}',
      'TimerRepeat': '${t.repeat}',
      'TimerStatus': '${t.status}',
      'TimerEventID': '${t.eventId}',
    };

/// JsonParser.parse النوع 1 (رد طلب 1) — الترتيب هو رقم المؤقت
List<GmTimer> gmParseTimers(dynamic r) {
  final out = <GmTimer>[];
  if (r is! List) return out;
  var k = 0;
  for (final e in r) {
    if (e is! Map) continue;
    int i(String key) => int.tryParse('${e[key] ?? ''}') ?? 0;
    out.add(GmTimer(
        index: k++,
        programId: '${e['TimerProgramSatTpId'] ?? e['TimerProgramId'] ?? ''}',
        programName: '${e['TimerProgramName'] ?? ''}',
        month: i('TimerMonth'),
        day: i('TimerDay'),
        startH: i('TimerStartHour'),
        startM: i('TimerStartMin'),
        endH: i('TimerEndHour'),
        endM: i('TimerEndMin'),
        repeat: i('TimerRepeat'),
        status: i('TimerStatus'),
        eventId: i('TimerEventID')));
  }
  return out;
}

/// JsonParser.parse النوع 9 (رد طلب 11)
DateTime? gmParseStbTime(dynamic r) {
  final m = GmClient.first(r);
  int? i(String k) => int.tryParse('${m[k] ?? ''}');
  final y = i('StbYear'), mo = i('StbMonth'), d = i('StbDay');
  if (y == null || mo == null || d == null || y < 2000) return null;
  return DateTime(y, mo, d, i('StbHour') ?? 0, i('StbMin') ?? 0);
}


// ---------------- المؤقتات ----------------
class TimersPage extends StatefulWidget {
  final GmClient gm;
  final List<StbChannel> channels;
  final String? playingId;
  const TimersPage({super.key, required this.gm, required this.channels, this.playingId});
  @override
  State<TimersPage> createState() => _TimersPageState();
}

class _TimersPageState extends State<TimersPage> {
  List<GmTimer> list = [];
  bool busy = true;
  String msg = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      list = await widget.gm.timers();
      msg = list.isEmpty ? 'مفيش مؤقتات' : '';
    } catch (e) {
      msg = 'مقدرتش أقرا المؤقتات: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  String _hm(int h, int m) => '${h % 24}:${m.toString().padLeft(2, '0')}${h >= 24 ? ' (+1 يوم)' : ''}';

  Future<void> edit([GmTimer? t]) async {
    final r = await Navigator.push<GmTimer>(
        context, MaterialPageRoute(builder: (_) => TimerEditPage(gm: widget.gm, channels: widget.channels, playingId: widget.playingId, timer: t, nextIndex: list.length)));
    if (r == null || !mounted) return;
    setState(() => busy = true);
    try {
      final conflict = await widget.gm.saveTimer(r, edit: t != null);
      if (conflict != null && mounted) {
        final name = (conflict >= 0 && conflict < list.length) ? '«${list[conflict].programName}» ${_hm(list[conflict].startH, list[conflict].startM)}' : 'مؤقت تاني';
        if (await confirm(context, 'الوقت ده متعارض مع $name.\nتستبدله بالمؤقت الجديد؟')) {
          await widget.gm.replaceTimer(r, conflict);
        }
      }
      if (mounted) toast(context, 'اتحفظ ✓');
    } catch (e) {
      if (mounted) toast(context, 'فشل: $e');
    }
    await load();
  }

  Future<void> del(GmTimer t) async {
    if (!await confirm(context, 'تمسح مؤقت «${t.programName}»؟')) return;
    setState(() => busy = true);
    try {
      await widget.gm.deleteTimer(t);
    } catch (e) {
      if (mounted) toast(context, 'فشل: $e');
    }
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مؤقتات الريسيفر'), actions: [IconButton(onPressed: busy ? null : load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: busy ? null : () => edit(), icon: const Icon(Icons.add_alarm), label: const Text('مؤقت جديد')),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(msg, style: const TextStyle(color: kMuted))),
              for (final t in list)
                Card(
                  child: ListTile(
                    leading: Icon(t.record ? Icons.fiber_manual_record : Icons.alarm, color: t.record ? Colors.redAccent : kGold),
                    title: Text(t.programName.isEmpty ? 'قناة ${t.programId}' : t.programName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${t.day}/${t.month}  •  ${_hm(t.startH, t.startM)} ← ${_hm(t.endH, t.endM)}\n'
                        '${kTimerRepeats[t.repeat.clamp(0, kTimerRepeats.length - 1)]}${t.record ? ' • تسجيل' : ''}${t.standby ? ' • يقفل بعده' : ''}'),
                    isThreeLine: true,
                    onTap: () => edit(t),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => del(t)),
                  ),
                ),
              const SizedBox(height: 80),
            ]),
    );
  }
}

class TimerEditPage extends StatefulWidget {
  final GmClient gm;
  final List<StbChannel> channels;
  final String? playingId;
  final GmTimer? timer;
  final int nextIndex;
  const TimerEditPage({super.key, required this.gm, required this.channels, this.playingId, this.timer, required this.nextIndex});
  @override
  State<TimerEditPage> createState() => _TimerEditPageState();
}

class _TimerEditPageState extends State<TimerEditPage> {
  String programId = '', programName = '';
  int month = 1, day = 1, sh = 0, sm = 0, eh = 0, em = 0, repeat = 0, status = 0;
  DateTime? stbNow;

  @override
  void initState() {
    super.initState();
    final t = widget.timer;
    if (t != null) {
      programId = t.programId;
      programName = t.programName;
      month = t.month;
      day = t.day;
      sh = t.startH;
      sm = t.startM;
      eh = t.endH % 24;
      em = t.endM;
      repeat = t.repeat;
      status = t.status;
    } else {
      final ch = widget.channels.where((c) => c.id == widget.playingId).firstOrNull ?? widget.channels.firstOrNull;
      programId = ch?.id ?? '';
      programName = ch?.name ?? '';
      final n = DateTime.now();
      month = n.month;
      day = n.day;
      sh = eh = n.hour;
      sm = em = n.minute;
    }
    widget.gm.stbTime().then((d) {
      if (d == null || !mounted) return;
      setState(() {
        stbNow = d;
        if (widget.timer == null) {
          month = d.month;
          day = d.day;
          sh = eh = d.hour;
          sm = em = d.minute;
        }
      });
    });
  }

  Future<void> pickChannel() async {
    final q = TextEditingController();
    final r = await showModalBottomSheet<StbChannel>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (c, ss) {
        final f = q.text.trim().toLowerCase();
        final shown = widget.channels.where((x) => !x.radio && (f.isEmpty || x.name.toLowerCase().contains(f))).take(300).toList();
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(c).size.height * .8,
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(8), child: TextField(controller: q, onChanged: (_) => ss(() {}), decoration: const InputDecoration(hintText: 'دوّر على قناة', prefixIcon: Icon(Icons.search)))),
              Expanded(
                child: ListView(children: [for (final ch in shown) ListTile(title: Text(ch.name), onTap: () => Navigator.pop(c, ch))]),
              ),
            ]),
          ),
        );
      }),
    );
    if (r != null) {
      setState(() {
        programId = r.id;
        programName = r.name;
      });
    }
  }

  Future<void> pickDate() async {
    final base = stbNow ?? DateTime.now();
    final d = await showDatePicker(context: context, firstDate: DateTime(base.year, base.month, base.day), lastDate: base.add(const Duration(days: 60)), initialDate: _date());
    if (d != null) {
      setState(() {
        month = d.month;
        day = d.day;
      });
    }
  }

  DateTime _date() {
    final base = stbNow ?? DateTime.now();
    var d = DateTime(base.year, month, day);
    if (d.isBefore(DateTime(base.year, base.month, base.day))) d = DateTime(base.year + 1, month, day);
    final first = DateTime(base.year, base.month, base.day);
    final last = base.add(const Duration(days: 60));
    return d.isBefore(first) ? first : (d.isAfter(last) ? first : d);
  }

  Future<void> pickTime(bool start) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start ? sh : eh, minute: start ? sm : em));
    if (t == null) return;
    setState(() {
      if (start) {
        sh = t.hour;
        sm = t.minute;
      } else {
        eh = t.hour;
        em = t.minute;
      }
    });
  }

  void save() {
    if (programId.isEmpty) {
      toast(context, 'اختار القناة');
      return;
    }
    // زي M() في G-MScreen: لازم البداية تكون بعد وقت الريسيفر (للمؤقت اللي مرة واحدة)
    final now = stbNow ?? DateTime.now();
    final start = DateTime(_date().year, month, day, sh, sm);
    if (repeat == 0 && start.isBefore(now)) {
      toast(context, 'الوقت ده فات — اختار وقت بعد ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      return;
    }
    Navigator.pop(
        context,
        GmTimer(
            index: widget.timer?.index ?? widget.nextIndex,
            programId: programId,
            programName: programName,
            month: month,
            day: day,
            startH: sh,
            startM: sm,
            endH: eh,
            endM: em,
            repeat: repeat,
            status: status,
            eventId: widget.timer?.eventId ?? 0));
  }

  String _hm(int h, int m) => '$h:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.timer == null ? 'مؤقت جديد' : 'تعديل المؤقت')),
      body: ListView(children: [
        if (stbNow != null)
          Padding(padding: const EdgeInsets.all(12), child: Text('وقت الريسيفر: ${stbNow!.day}/${stbNow!.month} ${_hm(stbNow!.hour, stbNow!.minute)}', style: const TextStyle(color: kMuted))),
        ListTile(leading: const Icon(Icons.tv), title: const Text('القناة'), subtitle: Text(programName.isEmpty ? programId : programName), onTap: pickChannel),
        ListTile(leading: const Icon(Icons.event), title: const Text('اليوم'), subtitle: Text('$day/$month'), onTap: pickDate),
        ListTile(leading: const Icon(Icons.play_circle_outline), title: const Text('البداية'), subtitle: Text(_hm(sh, sm)), onTap: () => pickTime(true)),
        ListTile(
            leading: const Icon(Icons.stop_circle_outlined),
            title: const Text('النهاية'),
            subtitle: Text('${_hm(eh, em)}${(eh * 60 + em) <= (sh * 60 + sm) ? '  (اليوم اللي بعده)' : ''}'),
            onTap: () => pickTime(false)),
        ListTile(
          leading: const Icon(Icons.repeat),
          title: const Text('التكرار'),
          trailing: DropdownButton<int>(
            value: repeat.clamp(0, kTimerRepeats.length - 1),
            items: [for (var i = 0; i < kTimerRepeats.length; i++) DropdownMenuItem(value: i, child: Text(kTimerRepeats[i]))],
            onChanged: (v) => setState(() => repeat = v ?? 0),
          ),
        ),
        SwitchListTile(
            secondary: const Icon(Icons.fiber_manual_record, color: Colors.redAccent),
            title: const Text('تسجيل (محتاج فلاشة/هارد في الريسيفر)'),
            value: status & 2 == 2,
            onChanged: (v) => setState(() => status = v ? status | 2 : status & ~2)),
        SwitchListTile(
            secondary: const Icon(Icons.power_settings_new),
            title: const Text('يرجع standby بعد ما يخلص'),
            value: status & 8 == 8,
            onChanged: (v) => setState(() => status = v ? status | 8 : status & ~8)),
        Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('احفظ على الريسيفر'))),
      ]),
    );
  }
}

// ======== youtube.dart ========
// كاست فيديوهات يوتيوب من المتصفح (زي Web Video Caster) — بمكتبة youtube_explode_dart (Dart خالص).
// استخدام شخصي في البيت. يوتيوب بيغير طريقته كل فترة، فلو وقف: حدّث نسخة المكتبة في build.yml.

/// رقم الفيديو من أي رابط يوتيوب (watch / youtu.be / shorts / embed / live / m.youtube.com)
String? ytVideoId(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || !u.hasScheme) return null;
  final h = u.host.toLowerCase();
  bool ok(String? id) => id != null && RegExp(r'^[0-9A-Za-z_\-]{11}$').hasMatch(id);
  if (h == 'youtu.be') {
    final id = u.pathSegments.isEmpty ? null : u.pathSegments.first;
    return ok(id) ? id : null;
  }
  if (!(h == 'youtube.com' || h.endsWith('.youtube.com') || h == 'youtube-nocookie.com' || h.endsWith('.youtube-nocookie.com'))) return null;
  final v = u.queryParameters['v'];
  if (u.path == '/watch' || u.path == '/watch/') return ok(v) ? v : null;
  final seg = u.pathSegments;
  if (seg.length >= 2 && const ['shorts', 'embed', 'live', 'v', 'e'].contains(seg[0])) return ok(seg[1]) ? seg[1] : null;
  return null;
}

/// جودة واحدة ينفع تتبعت للشاشة
class YtChoice {
  final String label; // "720p"
  final String detail; // "mp4 • 24 MB"
  final String url;
  final String mime;
  final int height;
  final int itag;
  final bool hls;
  YtChoice(this.label, this.detail, this.url, this.mime, this.height, this.itag, {this.hls = false});
}

class YtResult {
  final String id;
  final List<YtChoice> muxed; // فيديو+صوت في ملف واحد (أضمن حاجة — غالبًا لحد 360p)
  final List<YtChoice> hls; // HLS (جودات أعلى/بث مباشر — لو الريسيفر بيشغّل m3u8)
  final DateTime at;
  YtResult(this.id, this.muxed, this.hls) : at = DateTime.now();
  bool get isEmpty => muxed.isEmpty && hls.isEmpty;
}

/// ترتيب: الأعلى جودة الأول، ومن غير تكرار نفس الارتفاع
List<YtChoice> ytSortChoices(List<YtChoice> l) {
  final s = [...l]..sort((a, b) => b.height != a.height ? b.height.compareTo(a.height) : a.itag.compareTo(b.itag));
  final seen = <String>{};
  return s.where((c) => seen.add('${c.hls}-${c.height}')).toList();
}

/// للسجل: الهوست + itag بس (من غير التوقيع وباقي الباراميترات)
String ytLogUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return '?';
  final itag = u.queryParameters['itag'] ?? RegExp(r'/itag/(\d+)').firstMatch(u.path)?.group(1);
  return '${u.host}${itag == null ? '' : ' itag=$itag'}';
}

class YouTubeCast {
  static yte.YoutubeExplode? _yt;
  static final Map<String, YtResult> _cache = {};

  static String errorAr(Object e) {
    final s = '$e';
    if (e is TimeoutException || e is SocketException) return 'النت بطيء أو مقطوع — جرّب تاني';
    if (e is yte.VideoRequiresPurchaseException) return 'الفيديو ده مدفوع — مينفعش يتبعت';
    if (e is yte.VideoUnplayableException || s.contains('unplayable') || s.contains('Sign in')) {
      return 'يوتيوب مش سامح بتشغيل الفيديو ده برا تطبيقه (خاص / للكبار / ممنوع في البلد)';
    }
    return 'يوتيوب غيّر حاجة — جرّب تاني أو حدّث التطبيق';
  }

  static Future<YtResult> streams(String id) async {
    final c = _cache[id];
    if (c != null && DateTime.now().difference(c.at) < const Duration(hours: 2)) return c;
    final yt = _yt ??= yte.YoutubeExplode();
    AppLog.add('CAST', 'youtube $id: بجيب الجودات…');
    final muxed = <YtChoice>[];
    final hls = <YtChoice>[];
    Object? firstErr;
    try {
      final m = await yt.videos.streamsClient.getManifest(id).timeout(const Duration(seconds: 25));
      for (final s in m.muxed) {
        muxed.add(YtChoice(s.qualityLabel, '${s.container.name} • ${fmtBytes(s.size.totalBytes)}', s.url.toString(),
            s.container.name == 'webm' ? 'video/webm' : 'video/mp4', s.videoResolution.height, s.tag));
      }
      for (final s in m.hls.whereType<yte.HlsMuxedStreamInfo>()) {
        hls.add(YtChoice(s.qualityLabel, 'HLS', s.url.toString(), 'application/x-mpegURL', s.videoResolution.height, s.tag, hls: true));
      }
    } catch (e) {
      firstErr = e;
      AppLog.add('CAST', 'youtube $id manifest ✗ ${e.runtimeType}: ${ytShortErr(e)}');
    }
    // HLS (عميل iOS): جودات أعلى فيها صوت وصورة مع بعض
    if (hls.isEmpty) {
      try {
        final m = await yt.videos.streamsClient.getManifest(id, ytClients: [yte.YoutubeApiClient.ios]).timeout(const Duration(seconds: 25));
        for (final s in m.hls.whereType<yte.HlsMuxedStreamInfo>()) {
          hls.add(YtChoice(s.qualityLabel, 'HLS', s.url.toString(), 'application/x-mpegURL', s.videoResolution.height, s.tag, hls: true));
        }
        if (muxed.isEmpty) {
          for (final s in m.muxed) {
            muxed.add(YtChoice(s.qualityLabel, '${s.container.name} • ${fmtBytes(s.size.totalBytes)}', s.url.toString(), 'video/mp4', s.videoResolution.height, s.tag));
          }
        }
      } catch (e) {
        AppLog.add('CAST', 'youtube $id ios/hls ✗ ${e.runtimeType}: ${ytShortErr(e)}');
      }
    }
    // بث مباشر: رابط HLS الرئيسي (جودة تلقائية)
    try {
      final live = await yt.videos.streamsClient.getHttpLiveStreamUrl(yte.VideoId(id)).timeout(const Duration(seconds: 15));
      hls.insert(0, YtChoice('تلقائي (بث مباشر)', 'HLS', live, 'application/x-mpegURL', 99999, 0, hls: true));
    } catch (_) {/* مش بث مباشر — عادي */}
    final r = YtResult(id, ytSortChoices(muxed), ytSortChoices(hls));
    AppLog.add('CAST', 'youtube $id: muxed=${r.muxed.map((c) => '${c.label}/${c.itag}').join(',')} hls=${r.hls.map((c) => c.label).join(',')}');
    if (r.isEmpty) throw firstErr ?? StateError('مفيش جودات');
    _cache[id] = r;
    return r;
  }
}

String ytShortErr(Object e) {
  final s = '$e'.replaceAll(RegExp(r'https?://\S+'), '<url>');
  return s.length > 200 ? s.substring(0, 200) : s;
}

// ======== cast_images.dart ========
const String kImageUnsupportedAr =
    'الريسيفر استلم أمر الصورة بس مطلبهاش من الموبايل — غالبًا مش بيعرض صور عن طريق الشبكة (DLNA). الفيديو شغال عادي؛ للصور جرّب فلاشة USB. لو عايزنا نتأكد ابعت السجل.';

bool isImagePath(String p) => mimeOf(p).startsWith('image');

/// اسم ملف الـJPEG المتجهّز (ثابت لنفس الصورة علشان الكاش)
String castJpegName(String path, int len, int modMs) =>
    'img_${md5Hex('$path|$len|$modMs').substring(0, 16)}.jpg';

/// يجهّز الصورة للريسيفر: JPEG، أقصى ضلع 1920، متلفّة صح (EXIF). لو التحويل فشل والصورة JPEG أصلًا نبعتها زي ما هي.
Future<File> prepareCastImage(File f, {int max = 1920}) async {
  try {
    final st = await f.stat();
    final dir = Directory('${(await getTemporaryDirectory()).path}/cast_img');
    await dir.create(recursive: true);
    final out = File('${dir.path}/${castJpegName(f.path, st.size, st.modified.millisecondsSinceEpoch)}');
    if (await out.exists() && await out.length() > 0) return out;
    final ok = await Native.toJpeg(f.path, out.path, max: max);
    AppLog.add('CAST', 'صورة ${f.uri.pathSegments.last} (${fmtBytes(st.size)}) → JPEG ${ok ? fmtBytes(await out.length()) : 'فشل'}');
    if (ok) return out;
  } catch (e) {
    AppLog.add('CAST', 'تجهيز الصورة ✗ $e');
  }
  if (mimeOf(f.path) == 'image/jpeg') return f;
  throw StateError('مقدرتش أحوّل الصورة لـ JPEG (نوعها: ${extOf(f.path) ?? '؟'})');
}

// ======== v4_native.dart ========
// جسر أندرويد للمميزات الجديدة (المنبه، الإشعار-ريموت، الصوت، الاختصارات) + الشغل في الخلفية

class Native4 {
  static const _ch = MethodChannel('a2r/native');

  static Future<T?> _call<T>(String m, [Map<String, dynamic>? a]) async {
    try {
      return await _ch.invokeMethod<T>(m, a);
    } catch (e) {
      AppLog.add('ERR', 'native $m ✗ $e');
      return null;
    }
  }

  /// بيرجع "exact" أو "inexact"
  static Future<String?> setAlarm(int id, DateTime at, Map<String, dynamic> task, {bool exact = true}) =>
      _call<String>('setAlarm', {'id': id, 'at': at.millisecondsSinceEpoch, 'task': jsonEncode(task), 'exact': exact});
  static Future<void> cancelAlarm(int id) => _call('cancelAlarm', {'id': id});
  static Future<void> remoteNotif(bool on, {String title = 'ريموت الريسيفر'}) => _call('remoteNotif', {'on': on, 'title': title});
  static Future<List<String>> voice({String prompt = 'قول الأمر'}) async {
    final r = await _call<List<dynamic>>('voice', {'lang': 'ar-EG', 'prompt': prompt});
    return r?.map((e) => '$e').toList() ?? [];
  }

  static Future<bool> pinShortcut(String id, String label, String data) async => await _call<bool>('pinShortcut', {'id': id, 'label': label, 'data': data}) == true;
  static Future<String?> initialAction() => _call<String>('initialAction');

  /// الأوامر اللي جاية من أندرويد للتطبيق وهو مفتوح
  static void listen({required Future<void> Function(String data) openChannel, required Future<void> Function(int key) notifKey}) {
    _ch.setMethodCallHandler((c) async {
      if (c.method == 'openChannel') await openChannel('${c.arguments}');
      if (c.method == 'notifKey') await notifKey((c.arguments as num).toInt());
      if (c.method == 'shareIn') await ShareIn.handle('${c.arguments}');
      return null;
    });
  }
}

/// نقطة الدخول للشغل في الخلفية (Kotlin A2RBg بيشغّلها في محرك Flutter من غير شاشة)
@pragma('vm:entry-point')
Future<void> a2rBgMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  const ch = MethodChannel('a2r/native');
  var result = '';
  Map<String, dynamic> task = {};
  try {
    await Store.init();
    task = Map<String, dynamic>.from(jsonDecode(await ch.invokeMethod<String>('bgTask') ?? '{}') as Map);
    result = await Bg.run(task).timeout(const Duration(seconds: 40));
  } catch (e) {
    result = 'خطأ: $e';
  }
  try {
    await Store.p.setString('bg_last', '${DateTime.now().toIso8601String().substring(0, 16)} ${task['type']}: $result');
  } catch (_) {}
  try {
    await ch.invokeMethod('bgDone');
  } catch (_) {}
}

class Bg {
  static Future<String> run(Map<String, dynamic> t) async {
    switch (t['type']) {
      case 'sched':
        final r = await Schedule.syncRouter(background: true);
        await Schedule.rearm();
        return r;
      case 'quota':
        final r = await Quota.backgroundCheck();
        await Quota.rearm();
        return r;
      case 'rearm':
        await Schedule.rearm();
        await Quota.rearm();
        await NetWatch.rearm();
        return 'rearm';
      case 'watch':
        final r = await NetWatch.backgroundCheck();
        await NetWatch.rearm();
        return r;
      case 'key':
        final ip = Store.receiverIp;
        if (ip == null) return 'مفيش ريسيفر محفوظ';
        final g = GmClient(ip);
        try {
          await g.connect();
          await g.key((t['key'] as num).toInt());
          await Future.delayed(const Duration(milliseconds: 400));
        } finally {
          await g.disconnect();
        }
        return 'key ${t['key']}';
    }
    return 'مش معروف';
  }

  /// دخول الراوتر من الخلفية — بس لو آخر دخول من التطبيق نجح (علشان الراوتر ميقفلش بسبب محاولات غلط)
  static Future<ZteRouter?> router() async {
    if (Store.p.getBool('router_last_ok') != true) return null;
    final ip = Store.routerIp;
    final pw = await Store.routerPassword();
    if (ip == null || pw == null || pw.isEmpty) return null;
    final r = ZteRouter(ip);
    try {
      final res = await r.login(pw, force: schemeFromName(Store.loginScheme)).timeout(const Duration(seconds: 15));
      if (!res.ok) {
        // باسورد اتغير أو الراوتر قافل؟ نوقف الخلفية لحد ما يدخل من التطبيق تاني
        await Store.p.setBool('router_last_ok', false);
        r.close();
        return null;
      }
      return r;
    } catch (_) {
      r.close();
      return null;
    }
  }
}

// ======== v4_net.dart ========
// مواعيد الحظر + باقة النت + سجل الأجهزة + QR الواي فاي

/// قاعدة حظر: جهاز (MAC) محظور في أيام معينة من ساعة لساعة (ممكن تعدّي نص الليل)
class BlockRule {
  String id, mac, name;
  Set<int> days; // 1=الاتنين … 7=الحد (زي DateTime.weekday)
  int from, to; // دقايق من نص الليل
  bool enabled;
  BlockRule({required this.id, required this.mac, required this.name, required this.days, required this.from, required this.to, this.enabled = true});

  Map<String, dynamic> toJson() => {'id': id, 'mac': mac, 'name': name, 'days': days.toList()..sort(), 'from': from, 'to': to, 'on': enabled};
  static BlockRule fromJson(Map m) => BlockRule(
        id: '${m['id']}',
        mac: normMac('${m['mac']}'),
        name: '${m['name'] ?? ''}',
        days: ((m['days'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet(),
        from: (m['from'] as num?)?.toInt() ?? 0,
        to: (m['to'] as num?)?.toInt() ?? 0,
        enabled: m['on'] != false,
      );

  /// شغالة دلوقتي؟ (لو from > to يبقى بتعدّي نص الليل: اليوم اللي بدأت فيه هو اللي بيتحسب)
  bool activeAt(DateTime t) {
    if (!enabled || days.isEmpty) return false;
    final m = t.hour * 60 + t.minute;
    final today = days.contains(t.weekday);
    final yesterday = days.contains(t.weekday == 1 ? 7 : t.weekday - 1);
    if (from == to) return today; // اليوم كله
    if (from < to) return today && m >= from && m < to;
    return (today && m >= from) || (yesterday && m < to);
  }
}

String fmtMin(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
const List<String> kDayNamesAr = ['الاتنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الحد'];

/// الـ MACs اللي المفروض تكون محظورة دلوقتي
Set<String> macsBlockedAt(List<BlockRule> rules, DateTime t) => rules.where((r) => r.activeAt(t)).map((r) => r.mac).toSet();

/// أقرب وقت بعد [now] حالة أي قاعدة بتتغير فيه (بداية أو نهاية)
DateTime? nextRuleEvent(List<BlockRule> rules, DateTime now) {
  DateTime? best;
  final base = DateTime(now.year, now.month, now.day);
  for (final r in rules.where((r) => r.enabled && r.days.isNotEmpty)) {
    for (var d = 0; d <= 8; d++) {
      final day = DateTime(base.year, base.month, base.day + d);
      for (final m in {r.from, r.to}) {
        final t = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
        if (!t.isAfter(now)) continue;
        // الحدث ده بيغيّر حاجة فعلًا؟
        final before = r.activeAt(t.subtract(const Duration(minutes: 1)));
        final after = r.activeAt(t);
        if (before == after) continue;
        if (best == null || t.isBefore(best)) best = t;
        break;
      }
    }
  }
  return best;
}

/// يحسب الحظر المطلوب: يضيف اللي لازم يتحظر، ويشيل بس اللي المواعيد هي اللي حظرته (الحظر اليدوي ميتلمسش)
({Set<String> add, Set<String> remove}) scheduleDiff({required Set<String> current, required Set<String> wanted, required Set<String> managed, required Set<String> appliedBySchedule}) {
  final add = wanted.difference(current);
  final remove = current.where((m) => managed.contains(m) && !wanted.contains(m) && appliedBySchedule.contains(m)).toSet();
  return (add: add, remove: remove);
}

class Schedule {
  static List<BlockRule> get rules {
    try {
      return (jsonDecode(Store.p.getString('sched_rules') ?? '[]') as List).map((e) => BlockRule.fromJson(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<BlockRule> l) async {
    await Store.p.setString('sched_rules', jsonEncode(l.map((e) => e.toJson()).toList()));
    await rearm();
  }

  static Set<String> get applied => (Store.p.getStringList('sched_applied') ?? []).toSet();
  static Future<void> setApplied(Set<String> s) => Store.p.setStringList('sched_applied', s.toList());

  /// المنبه الجاي (عند أقرب بداية/نهاية)
  static Future<String> rearm() async {
    final n = nextRuleEvent(rules, DateTime.now());
    if (n == null) {
      await Native4.cancelAlarm(1001);
      await Store.p.remove('sched_next');
      return 'مفيش مواعيد';
    }
    final kind = await Native4.setAlarm(1001, n.add(const Duration(seconds: 5)), {'type': 'sched'});
    await Store.p.setString('sched_next', '${n.toIso8601String()}|$kind');
    return '$n $kind';
  }

  /// يطبّق الحظر على الراوتر (من التطبيق أو من الخلفية)
  static Future<String> syncRouter({ZteRouter? router, bool background = false}) async {
    final l = rules;
    if (l.isEmpty) return 'مفيش قواعد';
    final r = router ?? await Bg.router();
    if (r == null) return 'مقدرتش أدخل الراوتر (الموبايل لازم يكون على واي فاي البيت)';
    try {
      final cur = await r.blockList();
      final wanted = macsBlockedAt(l, DateTime.now());
      final managed = l.map((e) => e.mac).toSet();
      final d = scheduleDiff(current: cur.macs.toSet(), wanted: wanted, managed: managed, appliedBySchedule: applied);
      if (d.add.isEmpty && d.remove.isEmpty) return 'مفيش تغيير';
      final names = {for (final x in l) x.mac: x.name};
      final ok = await r.setBlockedMany(add: {for (final m in d.add) m: names[m] ?? ''}, remove: d.remove);
      if (ok) await setApplied(applied.union(d.add).difference(d.remove));
      final msg = '${ok ? 'تم' : 'الراوتر مأكدش'}: حظر ${d.add.length} / فك ${d.remove.length}';
      AppLog.add('ROUTER', 'schedule $msg add=${d.add} remove=${d.remove}');
      if (background && ok) {
        for (final m in d.add) {
          Native.notify('مواعيد الحظر', 'اتحظر ${names[m]?.isNotEmpty == true ? names[m] : m}');
        }
        for (final m in d.remove) {
          Native.notify('مواعيد الحظر', 'اتفك الحظر عن ${names[m]?.isNotEmpty == true ? names[m] : m}');
        }
      }
      return msg;
    } finally {
      if (router == null) r.close();
    }
  }
}

// ---------------- باقة النت ----------------
String dayKey(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// بداية الشهر بتاع الباقة حسب يوم التجديد (لو اليوم 31 والشهر أقصر → آخر يوم)
DateTime quotaPeriodStart(DateTime now, int resetDay) {
  int clampDay(int y, int m) => min(resetDay, DateTime(y, m + 1, 0).day);
  final thisStart = DateTime(now.year, now.month, clampDay(now.year, now.month));
  if (!now.isBefore(thisStart)) return thisStart;
  final py = now.month == 1 ? now.year - 1 : now.year, pm = now.month == 1 ? 12 : now.month - 1;
  return DateTime(py, pm, clampDay(py, pm));
}

/// يضيف قراءة عداد الراوتر (monthly_tx+rx) لاستهلاك اليوم. لو العداد رجع لورا (اتصفّر) نعتبر القراءة كلها جديدة.
({Map<String, int> daily, int last}) quotaAddSample(Map<String, int> daily, int? last, int total, DateTime now, {int keepDays = 70}) {
  final d = Map<String, int>.from(daily);
  if (last != null) {
    final diff = total >= last ? total - last : total;
    final k = dayKey(now);
    d[k] = (d[k] ?? 0) + diff;
  }
  final cut = dayKey(now.subtract(Duration(days: keepDays)));
  d.removeWhere((k, _) => k.compareTo(cut) < 0);
  return (daily: d, last: total);
}

int quotaUsedSince(Map<String, int> daily, DateTime start) {
  final s = dayKey(start);
  return daily.entries.where((e) => e.key.compareTo(s) >= 0).fold(0, (a, e) => a + e.value);
}

/// التنبيه اللي لازم يطلع (80 أو 95) لو لسه مطلعش في الفترة دي
int? quotaAlertDue(double pct, int alreadyAlerted) {
  if (pct >= 95 && alreadyAlerted < 95) return 95;
  if (pct >= 80 && alreadyAlerted < 80) return 80;
  return null;
}

class Quota {
  static double get gb => Store.p.getDouble('quota_gb') ?? 0;
  static int get resetDay => Store.p.getInt('quota_day') ?? 1;
  static Map<String, int> get daily {
    try {
      return Map<String, int>.from((jsonDecode(Store.p.getString('quota_daily') ?? '{}') as Map).map((k, v) => MapEntry('$k', (v as num).toInt())));
    } catch (_) {
      return {};
    }
  }

  static int? get last => Store.p.getInt('quota_last');

  /// تعويض يدوي: "استهلكت لحد دلوقتي X" (للشهر الأول قبل ما التطبيق يبدأ يعدّ)
  static int get offset {
    final p = Store.p.getString('quota_off_period');
    return p == dayKey(quotaPeriodStart(DateTime.now(), resetDay)) ? (Store.p.getInt('quota_off') ?? 0) : 0;
  }

  static Future<void> setOffset(int bytesUsedNow) async {
    final start = quotaPeriodStart(DateTime.now(), resetDay);
    final counted = quotaUsedSince(daily, start);
    await Store.p.setString('quota_off_period', dayKey(start));
    await Store.p.setInt('quota_off', max(0, bytesUsedNow - counted));
  }

  static int get used => quotaUsedSince(daily, quotaPeriodStart(DateTime.now(), resetDay)) + offset;
  static double get pct => gb <= 0 ? 0 : used * 100 / (gb * 1e9);

  static Future<void> sample(int total) async {
    if (total <= 0) return;
    final r = quotaAddSample(daily, last, total, DateTime.now());
    await Store.p.setString('quota_daily', jsonEncode(r.daily));
    await Store.p.setInt('quota_last', r.last);
    await _alert();
  }

  static Future<void> _alert() async {
    if (gb <= 0) return;
    final period = dayKey(quotaPeriodStart(DateTime.now(), resetDay));
    final saved = (Store.p.getString('quota_alert') ?? '').split(':');
    final already = saved.length == 2 && saved[0] == period ? int.tryParse(saved[1]) ?? 0 : 0;
    final due = quotaAlertDue(pct, already);
    if (due == null) return;
    await Store.p.setString('quota_alert', '$period:$due');
    Native.notify('باقة النت: $due%', 'استهلكت ${fmtBytes(used)} من ${gb.toStringAsFixed(0)} جيجا${due >= 95 ? ' — الباقة قربت تخلص!' : ''}');
  }

  static Future<String> rearm() async {
    if (gb <= 0) {
      await Native4.cancelAlarm(1002);
      return 'مفيش باقة';
    }
    await Native4.setAlarm(1002, DateTime.now().add(const Duration(hours: 1)), {'type': 'quota'}, exact: false);
    return 'كل ساعة';
  }

  static Future<String> backgroundCheck() async {
    if (gb <= 0) return 'مفيش باقة';
    final r = await Bg.router();
    if (r == null) return 'مقدرتش أدخل الراوتر';
    try {
      final st = await r.get(['monthly_tx_bytes', 'monthly_rx_bytes']);
      final total = (int.tryParse('${st['monthly_tx_bytes']}') ?? 0) + (int.tryParse('${st['monthly_rx_bytes']}') ?? 0);
      await sample(total);
      // سجل الأجهزة كمان (كل ساعة)
      try {
        final list = await r.stations();
        await DeviceHistory.update([for (final s in list) (key: s.mac.isEmpty ? s.ip : s.mac, name: isBadHostName(s.hostname) ? (NameCache.of(s.mac.isEmpty ? s.ip : s.mac)?.name ?? '') : s.hostname, ip: s.ip)]);
      } catch (_) {}
      return 'استهلاك ${fmtBytes(used)} (${pct.toStringAsFixed(0)}%)';
    } finally {
      r.close();
    }
  }
}

// ---------------- سجل الأجهزة ----------------
class DevSeen {
  String name, ip;
  int first, last, joins;
  DevSeen(this.name, this.ip, this.first, this.last, this.joins);
  Map<String, dynamic> toJson() => {'n': name, 'ip': ip, 'f': first, 'l': last, 'j': joins};
  static DevSeen fromJson(Map m) => DevSeen('${m['n'] ?? ''}', '${m['ip'] ?? ''}', (m['f'] as num).toInt(), (m['l'] as num).toInt(), (m['j'] as num?)?.toInt() ?? 1);
}

/// يحدّث السجل: جهاز جديد = أول ظهور؛ لو كان غايب أكتر من 15 دقيقة ورجع = دخلة جديدة
Map<String, DevSeen> historyUpdate(Map<String, DevSeen> h, List<({String key, String name, String ip})> present, DateTime now, {Duration gap = const Duration(minutes: 15)}) {
  final t = now.millisecondsSinceEpoch;
  final out = Map<String, DevSeen>.from(h);
  for (final p in present) {
    if (p.key.isEmpty) continue;
    final e = out[p.key];
    if (e == null) {
      out[p.key] = DevSeen(isBadHostName(p.name) ? '' : p.name, p.ip, t, t, 1);
    } else {
      if (t - e.last > gap.inMilliseconds) e.joins++;
      e.last = t;
      if (!isBadHostName(p.name)) e.name = p.name;
      if (isBadHostName(e.name)) e.name = '';
      if (p.ip.isNotEmpty) e.ip = p.ip;
    }
  }
  return out;
}

class DeviceHistory {
  static Map<String, DevSeen> get all {
    try {
      return (jsonDecode(Store.p.getString('dev_hist') ?? '{}') as Map).map((k, v) => MapEntry('$k', DevSeen.fromJson(v as Map)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> update(List<({String key, String name, String ip})> present) async {
    final h = historyUpdate(all, present, DateTime.now());
    await Store.p.setString('dev_hist', jsonEncode(h.map((k, v) => MapEntry(k, v.toJson()))));
  }

  static Future<void> clear() => Store.p.remove('dev_hist');
}

// ---------------- QR الواي فاي ----------------
String _qrEsc(String s) => s.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

/// صيغة QR اللي كاميرا أي موبايل بتفهمها
String wifiQrString(String ssid, String password, {bool hidden = false}) {
  final t = password.isEmpty ? 'nopass' : 'WPA';
  return 'WIFI:T:$t;S:${_qrEsc(ssid)};${password.isEmpty ? '' : 'P:${_qrEsc(password)};'}${hidden ? 'H:true;' : ''};';
}

class QrPainter extends CustomPainter {
  final String data;
  QrPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    final qr = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
    final n = qr.moduleCount, quiet = 2;
    final cell = size.width / (n + quiet * 2);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final p = Paint()..color = Colors.black;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (qr.isDark(r, c)) canvas.drawRect(Rect.fromLTWH((c + quiet) * cell, (r + quiet) * cell, cell + 0.4, cell + 0.4), p);
      }
    }
  }

  @override
  bool shouldRepaint(QrPainter o) => o.data != data;
}

Future<void> showWifiQr(BuildContext context, {String ssid = '', String password = ''}) async {
  final sC = TextEditingController(text: ssid), pC = TextEditingController(text: password);
  await showDialog(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, ss) => AlertDialog(
        title: const Text('شارك الواي فاي'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (sC.text.isNotEmpty)
              SizedBox(width: 230, height: 230, child: CustomPaint(painter: QrPainter(wifiQrString(sC.text, pC.text)))),
            const SizedBox(height: 8),
            const Text('خلي الضيف يفتح الكاميرا على الكود ده', style: TextStyle(fontSize: 12, color: kMuted)),
            TextField(controller: sC, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'اسم الشبكة'), onChanged: (_) => ss(() {})),
            TextField(controller: pC, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الباسورد'), onChanged: (_) => ss(() {})),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('تمام'))],
      ),
    ),
  );
}

// ======== v4_net_ui.dart ========
class SchedulePage extends StatefulWidget {
  final List<({String mac, String name})> devices;
  final ZteRouter? router;
  const SchedulePage({super.key, required this.devices, this.router});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<BlockRule> rules = Schedule.rules;
  String status = '';

  Future<void> _save() async {
    await Schedule.save(rules);
    if (widget.router != null) status = await Schedule.syncRouter(router: widget.router);
    if (mounted) setState(() {});
  }

  Future<void> edit([BlockRule? r]) async {
    final isNew = r == null;
    final devs = widget.devices.where((d) => d.mac.isNotEmpty).toList();
    if (isNew && devs.isEmpty) {
      toast(context, 'ادخل الراوتر الأول علشان أعرف الـ MAC بتاع الأجهزة');
      return;
    }
    final x = r == null
        ? BlockRule(id: '${DateTime.now().millisecondsSinceEpoch}', mac: devs.first.mac, name: devs.first.name, days: {1, 2, 3, 4, 5, 6, 7}, from: 0, to: 7 * 60)
        : BlockRule.fromJson(r.toJson());
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, ss) => AlertDialog(
          title: Text(isNew ? 'ميعاد حظر جديد' : 'تعديل الميعاد'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: devs.any((e) => e.mac == x.mac) ? x.mac : null,
                decoration: const InputDecoration(labelText: 'الجهاز'),
                items: [for (final e in devs) DropdownMenuItem(value: e.mac, child: Text('${e.name} (${e.mac.substring(9)})', overflow: TextOverflow.ellipsis))],
                onChanged: (v) => ss(() {
                  x.mac = v ?? x.mac;
                  x.name = devs.firstWhere((e) => e.mac == x.mac).name;
                }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () async {
                  final t = await showTimePicker(context: d, initialTime: TimeOfDay(hour: x.from ~/ 60, minute: x.from % 60));
                  if (t != null) ss(() => x.from = t.hour * 60 + t.minute);
                }, child: Text('من ${fmtMin(x.from)}'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () async {
                  final t = await showTimePicker(context: d, initialTime: TimeOfDay(hour: x.to ~/ 60, minute: x.to % 60));
                  if (t != null) ss(() => x.to = t.hour * 60 + t.minute);
                }, child: Text('لـ ${fmtMin(x.to)}'))),
              ]),
              if (x.from > x.to) const Padding(padding: EdgeInsets.only(top: 4), child: Text('بيعدّي نص الليل (لحد تاني يوم)', style: TextStyle(fontSize: 11, color: kMuted))),
              const SizedBox(height: 8),
              Wrap(spacing: 4, children: [
                for (var i = 1; i <= 7; i++)
                  FilterChip(
                    label: Text(kDayNamesAr[i - 1], style: const TextStyle(fontSize: 12)),
                    selected: x.days.contains(i),
                    showCheckmark: false,
                    onSelected: (v) => ss(() => v ? x.days.add(i) : x.days.remove(i)),
                  ),
              ]),
            ]),
          ),
          actions: [
            if (!isNew) TextButton(onPressed: () {
              rules.removeWhere((e) => e.id == x.id);
              Navigator.pop(d, true);
            }, child: const Text('امسح', style: TextStyle(color: kBad))),
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () {
              rules.removeWhere((e) => e.id == x.id);
              rules.add(x);
              Navigator.pop(d, true);
            }, child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok == true) await _save();
  }

  @override
  Widget build(BuildContext context) {
    final next = (Store.p.getString('sched_next') ?? '').split('|');
    return Scaffold(
      appBar: AppBar(title: const Text('مواعيد الحظر')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.add_alarm_rounded), label: const Text('ميعاد جديد')),
      body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
                'التطبيق هو اللي بيحظر/يفك في الميعاد (عن طريق قايمة MAC السودا في الراوتر). لازم الموبايل ده يكون على واي فاي البيت ومفتوح النت وقتها. '
                'راوترك مفيهوش "رقابة أبوية بمواعيد" مؤكدة نقدر نستخدمها، فعلشان كده بنعملها من الموبايل.\n'
                'انتبه: الحظر بالـ MAC — لو الموبايل التاني مفعّل "MAC عشوائي" لازم تقفله للشبكة دي.',
                style: TextStyle(fontSize: 12, color: kMuted)),
          ),
        ),
        if (status.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(status, style: const TextStyle(color: kGold))),
        if (next.length == 2) Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text('التغيير الجاي: ${next[0].replaceFirst('T', ' ').substring(0, 16)}${next[1] == 'inexact' ? ' (أندرويد ممكن يأخره كام دقيقة — فعّل "المنبهات والتذكيرات" للتطبيق)' : ''}', style: const TextStyle(fontSize: 12, color: kMuted)),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Text('آخر شغل في الخلفية: ${Store.p.getString('bg_last') ?? '—'}', style: const TextStyle(fontSize: 11, color: kMuted))),
        if (rules.isEmpty) const EmptyState(icon: Icons.schedule_rounded, title: 'مفيش مواعيد', hint: 'مثال: موبايل الولد يتقفل من 12 بالليل لـ 7 الصبح'),
        for (final r in rules)
          Card(
            child: ListTile(
              leading: Icon(Icons.block, color: r.activeAt(DateTime.now()) ? kBad : kMuted),
              title: Text(r.name.isEmpty ? r.mac : r.name),
              subtitle: Text('${fmtMin(r.from)} ← ${fmtMin(r.to)} • ${r.days.length == 7 ? 'كل يوم' : (r.days.toList()..sort()).map((d) => kDayNamesAr[d - 1]).join('، ')}${r.activeAt(DateTime.now()) ? '\nمحظور دلوقتي' : ''}'),
              trailing: Switch(value: r.enabled, onChanged: (v) {
                r.enabled = v;
                _save();
              }),
              onTap: () => edit(r),
            ),
          ),
      ]),
    );
  }
}

class QuotaPage extends StatefulWidget {
  final int? routerTotal;
  const QuotaPage({super.key, this.routerTotal});
  @override
  State<QuotaPage> createState() => _QuotaPageState();
}

class _QuotaPageState extends State<QuotaPage> {
  Future<void> settings() async {
    final gC = TextEditingController(text: Quota.gb > 0 ? Quota.gb.toStringAsFixed(0) : '');
    final dC = TextEditingController(text: '${Quota.resetDay}');
    final uC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('الباقة'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: gC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'حجم الباقة (جيجا) — 0 = مفيش تنبيه')),
            TextField(controller: dC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'يوم التجديد في الشهر (1-31)')),
            TextField(controller: uC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'استهلكت كام جيجا لحد النهارده؟ (اختياري)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    await Store.p.setDouble('quota_gb', double.tryParse(gC.text.trim()) ?? 0);
    await Store.p.setInt('quota_day', (int.tryParse(dC.text.trim()) ?? 1).clamp(1, 31));
    final u = double.tryParse(uC.text.trim());
    if (u != null) await Quota.setOffset((u * 1e9).round());
    await Quota.rearm();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = Quota.daily;
    final days = List.generate(30, (i) => DateTime.now().subtract(Duration(days: 29 - i)));
    final maxV = max(1, days.map((t) => d[dayKey(t)] ?? 0).fold(0, max));
    final pct = Quota.pct;
    return Scaffold(
      appBar: AppBar(title: const Text('باقة النت'), actions: [IconButton(icon: const Icon(Icons.tune_rounded), onPressed: settings)]),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Quota.gb <= 0 ? 'حدد حجم الباقة من ⚙ علشان التنبيهات' : 'استهلكت ${fmtBytes(Quota.used)} من ${Quota.gb.toStringAsFixed(0)} جيجا',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (Quota.gb > 0) LinearProgressIndicator(value: (pct / 100).clamp(0, 1), minHeight: 10, color: pct >= 95 ? kBad : (pct >= 80 ? Colors.orange : kGold), borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 6),
              Text('من ${dayKey(quotaPeriodStart(DateTime.now(), Quota.resetDay))} • تنبيه عند 80% و 95% (بيتشيك كل ساعة تقريبًا لما الموبايل على واي فاي البيت)',
                  style: const TextStyle(fontSize: 11, color: kMuted)),
              if (widget.routerTotal != null) Text('عداد الراوتر للشهر: ${fmtBytes(widget.routerTotal!)}', style: const TextStyle(fontSize: 11, color: kMuted)),
            ]),
          ),
        ),
        const SectionTitle('استهلاك آخر 30 يوم', icon: Icons.bar_chart_rounded),
        SizedBox(
          height: 170,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final t in days)
                Expanded(
                  child: Tooltip(
                    message: '${dayKey(t)}: ${fmtBytes(d[dayKey(t)] ?? 0)}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 4 + 150 * (d[dayKey(t)] ?? 0) / maxV,
                      decoration: BoxDecoration(color: kGold.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        for (final t in days.reversed.where((t) => (d[dayKey(t)] ?? 0) > 0).take(14))
          ListTile(dense: true, title: Text(dayKey(t)), trailing: Text(fmtBytes(d[dayKey(t)] ?? 0))),
        if (d.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('لسه مفيش قراءات — التطبيق بيبدأ يعدّ من دلوقتي', style: TextStyle(color: kMuted))),
      ]),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _t(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dayKey(t)} ${fmtMin(t.hour * 60 + t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final names = Store.deviceNames;
    final l = DeviceHistory.all.entries.toList()..sort((a, b) => b.value.last.compareTo(a.value.last));
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الأجهزة'), actions: [
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
          if (await confirm(context, 'تمسح السجل؟')) {
            await DeviceHistory.clear();
            setState(() {});
          }
        }),
      ]),
      body: l.isEmpty
          ? const EmptyState(icon: Icons.history_rounded, title: 'السجل فاضي', hint: 'بيتملى لما تفتح تبويب الشبكة (وكل ساعة لو حددت باقة)')
          : ListView(children: [
              for (final e in l)
                ListTile(
                  leading: const Icon(Icons.devices_other, color: kGold),
                  title: Text(names[e.key] ?? (e.value.name.isNotEmpty ? e.value.name : e.key)),
                  subtitle: Text('أول مرة: ${_t(e.value.first)}\nآخر مرة: ${_t(e.value.last)} • ${e.value.ip} • دخل ${e.value.joins} مرة', style: const TextStyle(fontSize: 12)),
                  isThreeLine: true,
                ),
            ]),
    );
  }
}

// ======== v4_voice.dart ========
// أوامر صوتية للريسيفر: "افتح MBC" ، "قناة 105" ، "علي الصوت" ، "اقفل"

String normAr(String s) {
  var t = s.toLowerCase();
  t = t.replaceAll(RegExp('[\u064B-\u0652\u0640]'), ''); // تشكيل وتطويل
  t = t.replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ؤ', 'و').replaceAll('ئ', 'ي');
  const ind = '٠١٢٣٤٥٦٧٨٩', per = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ind[i], '$i').replaceAll(per[i], '$i');
  }
  t = t.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

const Map<String, int> _numWords = {
  'صفر': 0, 'واحد': 1, 'واحده': 1, 'اتنين': 2, 'اثنين': 2, 'اثنان': 2, 'تلاته': 3, 'ثلاثه': 3, 'تلات': 3, 'اربعه': 4, 'اربع': 4,
  'خمسه': 5, 'خمس': 5, 'سته': 6, 'ست': 6, 'سبعه': 7, 'سبع': 7, 'تمانيه': 8, 'ثمانيه': 8, 'تمن': 8, 'تسعه': 9, 'تسع': 9, 'عشره': 10, 'عشر': 10,
  'حداشر': 11, 'اتناشر': 12, 'تلتاشر': 13, 'اربعتاشر': 14, 'خمستاشر': 15, 'ستاشر': 16, 'سبعتاشر': 17, 'تمنتاشر': 18, 'تسعتاشر': 19,
  'عشرين': 20, 'تلاتين': 30, 'ثلاثين': 30, 'اربعين': 40, 'خمسين': 50, 'ستين': 60, 'سبعين': 70, 'تمانين': 80, 'ثمانين': 80, 'تسعين': 90,
  'ميه': 100, 'مائه': 100, 'مية': 100, 'ميتين': 200, 'تلتميه': 300, 'ربعميه': 400, 'خمسميه': 500, 'ستميه': 600, 'سبعميه': 700, 'تمنميه': 800, 'تسعميه': 900,
  'الف': 1000, 'الفين': 2000,
};

/// "مية وخمسة" → 105 ، "105" → 105
int? parseArNumber(String s) {
  final d = RegExp(r'\d+').firstMatch(s);
  if (d != null) return int.parse(d.group(0)!);
  var total = 0;
  var any = false;
  for (var w in normAr(s).split(' ')) {
    if (w.startsWith('و') && w.length > 2 && !_numWords.containsKey(w)) w = w.substring(1);
    final v = _numWords[w];
    if (v != null) {
      total += v;
      any = true;
    }
  }
  return any ? total : null;
}

// أسماء الحروف الإنجليزي زي ما بتتنطق بالعربي ("ام بي سي" → mbc)
const Map<String, String> _letterNames = {
  'اي': 'a', 'ايه': 'a', 'بي': 'b', 'سي': 'c', 'دي': 'd', 'اف': 'f', 'جي': 'g', 'اتش': 'h', 'اتشي': 'h', 'جاي': 'j', 'جيه': 'j',
  'كي': 'k', 'كيه': 'k', 'ال': 'l', 'ام': 'm', 'ان': 'n', 'او': 'o', 'كيو': 'q', 'ار': 'r', 'اس': 's', 'تي': 't', 'يو': 'u',
  'في': 'v', 'دبليو': 'w', 'دبل': 'w', 'اكس': 'x', 'واي': 'y', 'زد': 'z', 'زي': 'z',
};

const Map<String, String> _arLatin = {
  'ا': 'a', 'ب': 'b', 'ت': 't', 'ث': 's', 'ج': 'g', 'ح': 'h', 'خ': 'kh', 'د': 'd', 'ذ': 'z', 'ر': 'r', 'ز': 'z', 'س': 's', 'ش': 'sh',
  'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh', 'ف': 'f', 'ق': 'k', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ه': 'h',
  'و': 'o', 'ي': 'i', 'ء': '',
};

/// النص العربي بالحروف اللاتيني (أسماء الحروف الأول، وبعدين نطق تقريبي)
String arToLatin(String s) {
  final out = <String>[];
  for (final w in normAr(s).split(' ')) {
    if (w.isEmpty) continue;
    if (_letterNames.containsKey(w)) {
      out.add(_letterNames[w]!);
    } else if (RegExp(r'^[a-z0-9]+$').hasMatch(w)) {
      out.add(w);
    } else {
      out.add(w.split('').map((c) => _arLatin[c] ?? c).join());
    }
  }
  // حروف ورا بعض (m b c) تتلزق
  return out.join(' ').replaceAllMapped(RegExp(r'\b([a-z]) (?=[a-z]\b)'), (m) => m[1]!);
}

/// الهيكل: من غير حروف العلة والمسافات (علشان "rotana" ≈ "روتانا")
String skeleton(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').replaceAll('c', 'k').replaceAll('q', 'k').replaceAll('ph', 'f').replaceAll(RegExp(r'(?<!^)[aeiouy]'), '');

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)].reduce(min);
    }
    prev = cur;
  }
  return prev[b.length];
}

double _sim(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 1;
  final s = 1 - levenshtein(a, b) / max(a.length, b.length);
  final contains = (b.contains(a) || a.contains(b)) && min(a.length, b.length) >= 3 ? 0.85 : 0.0;
  return max(s, contains);
}

/// درجة تشابه اسم القناة مع اللي اتقال
double channelScore(String spoken, String channelName) {
  final digitsS = RegExp(r'\d+').allMatches(normAr(spoken)).map((m) => m[0]).join(' ');
  final digitsC = RegExp(r'\d+').allMatches(channelName).map((m) => m[0]).join(' ');
  final a1 = normAr(spoken).replaceAll(RegExp(r'\d'), '').replaceAll(' ', ''), c1 = normAr(channelName).replaceAll(RegExp(r'\d'), '').replaceAll(' ', '');
  final lat = arToLatin(spoken).replaceAll(RegExp(r'\d'), '');
  var s = max(_sim(a1, c1), max(_sim(lat.replaceAll(' ', ''), c1.replaceAll(RegExp(r'[^a-z]'), '')), _sim(skeleton(lat), skeleton(channelName.replaceAll(RegExp(r'\d'), '')))));
  if (digitsS.isNotEmpty || digitsC.isNotEmpty) s = digitsS == digitsC ? s + 0.1 : s - 0.25;
  return s;
}

enum VoiceKind { keys, number, channel, none }

class VoiceCmd {
  final VoiceKind kind;
  final List<int> keys;
  final int number;
  final StbChannel? channel;
  final String heard;
  const VoiceCmd(this.kind, {this.keys = const [], this.number = 0, this.channel, this.heard = ''});
  String get describe => switch (kind) {
        VoiceKind.keys => 'زرار',
        VoiceKind.number => 'قناة رقم $number',
        VoiceKind.channel => channel!.name,
        VoiceKind.none => 'مفهمتش',
      };
}

const _openWords = ['افتح', 'افتحلي', 'شغل', 'شغللي', 'حط', 'هات', 'روح', 'روح علي', 'حطلي', 'عايز', 'عاوز', 'قناه'];

/// يفهم الأمر من اقتراحات التعرف على الكلام (أول اقتراح يتفهم بيكسب)
VoiceCmd parseVoiceCommand(List<String> texts, List<StbChannel> channels) {
  for (final raw in texts) {
    final t = normAr(raw);
    if (t.isEmpty) continue;
    bool has(List<String> w) => w.any((x) => RegExp('(^| )${RegExp.escape(x)}( |\$)').hasMatch(t));
    if (has(['علي الصوت', 'ارفع الصوت', 'على الصوت', 'زود الصوت', 'صوت اعلي', 'volume up'])) return VoiceCmd(VoiceKind.keys, keys: const [K.volUp, K.volUp, K.volUp], heard: raw);
    if (has(['وطي الصوت', 'واطي الصوت', 'قلل الصوت', 'اخفض الصوت', 'نزل الصوت', 'صوت اوطي', 'volume down'])) return VoiceCmd(VoiceKind.keys, keys: const [K.volDown, K.volDown, K.volDown], heard: raw);
    if (has(['اكتم', 'كتم', 'اسكت', 'mute', 'اقفل الصوت', 'شيل الصوت'])) return VoiceCmd(VoiceKind.keys, keys: const [K.mute], heard: raw);
    if (has(['اقفل', 'اطفي', 'قفل', 'power', 'اقفل الريسيفر', 'اطفي الريسيفر', 'افتح الريسيفر'])) return VoiceCmd(VoiceKind.keys, keys: const [K.power], heard: raw);
    if (has(['اللي بعدها', 'القناه اللي بعدها', 'التاليه', 'بعدها', 'next'])) return VoiceCmd(VoiceKind.keys, keys: const [K.chUp], heard: raw);
    if (has(['اللي قبلها', 'القناه اللي قبلها', 'السابقه', 'قبلها', 'previous'])) return VoiceCmd(VoiceKind.keys, keys: const [K.chDown], heard: raw);
    if (has(['رجوع', 'خروج', 'ارجع', 'اخرج', 'exit', 'back'])) return VoiceCmd(VoiceKind.keys, keys: const [K.exit], heard: raw);
    if (has(['القائمه', 'القايمه', 'منيو', 'menu'])) return VoiceCmd(VoiceKind.keys, keys: const [K.menu], heard: raw);
    if (has(['دليل', 'epg'])) return VoiceCmd(VoiceKind.keys, keys: const [K.epg], heard: raw);
    // "قناة 105" / "رقم 105" / "105"
    final numOnly = RegExp(r'^(قناه |رقم |القناه رقم |القناه |channel )?([\d]+)$').firstMatch(t);
    final words = t.replaceAll(RegExp(r'^(قناه|رقم|القناه رقم|القناه|افتح|شغل)\s*'), '');
    final wn = RegExp(r'\d').hasMatch(words) ? null : parseArNumber(words);
    if (numOnly != null) return VoiceCmd(VoiceKind.number, number: int.parse(numOnly.group(2)!), heard: raw);
    if (wn != null && words.split(' ').every((w) => _numWords.containsKey(w) || _numWords.containsKey(w.startsWith('و') ? w.substring(1) : w))) {
      return VoiceCmd(VoiceKind.number, number: wn, heard: raw);
    }
    // اسم قناة
    var q = t;
    for (final w in _openWords) {
      if (q.startsWith('$w ')) q = q.substring(w.length + 1);
    }
    if (q.isEmpty || channels.isEmpty) continue;
    StbChannel? best;
    var bestS = 0.0;
    for (final c in channels) {
      if (c.radio) continue;
      final s = channelScore(q, c.name);
      if (s > bestS) {
        bestS = s;
        best = c;
      }
    }
    if (best != null && bestS >= 0.6) return VoiceCmd(VoiceKind.channel, channel: best, heard: raw);
  }
  return VoiceCmd(VoiceKind.none, heard: texts.isEmpty ? '' : texts.first);
}

/// رقم القناة بالزراير: 1 0 5 OK
List<int> digitKeys(int n) => [...'$n'.split('').map((c) => K.digit(int.parse(c))), K.ok];

// ======== v4_cast.dart ========
// عرض صور (Slideshow) + كمّل الفيديو من مكان ما وقفت

/// مكان الوقوف المحفوظ لكل فيديو (بالثواني)
class ResumeStore {
  static Map<String, int> get _m {
    try {
      return Map<String, int>.from((jsonDecode(Store.p.getString('resume_pos') ?? '{}') as Map).map((k, v) => MapEntry('$k', (v as num).toInt())));
    } catch (_) {
      return {};
    }
  }

  static String keyOf(QueueItem q) => q.file?.path ?? q.url.split('?').first;
  static int? get(String k) => _m[k];

  static Future<void> put(String k, Duration pos, Duration dur) async {
    final m = _m;
    final v = resumeValue(pos, dur);
    if (v == null) {
      if (m.remove(k) == null) return;
    } else {
      m.remove(k);
      m[k] = v;
    }
    while (m.length > 200) {
      m.remove(m.keys.first);
    }
    await Store.p.setString('resume_pos', jsonEncode(m));
  }
}

/// نحفظ بس لو الفيديو أطول من دقيقتين، وعدّى 30 ثانية، ومش فاضل أقل من 30 ثانية (يعني خلص)
int? resumeValue(Duration pos, Duration dur) {
  if (dur.inSeconds < 120 || pos.inSeconds < 30 || dur.inSeconds - pos.inSeconds < 30) return null;
  return pos.inSeconds;
}

/// ترتيب الصور: عادي أو عشوائي (مع بذرة علشان الاختبارات)
List<int> slideOrder(int n, {bool shuffle = false, int? seed}) {
  final l = List<int>.generate(n, (i) => i);
  if (shuffle) l.shuffle(Random(seed));
  return l;
}

class SlideshowPage extends StatefulWidget {
  const SlideshowPage({super.key});
  @override
  State<SlideshowPage> createState() => _SlideshowPageState();
}

class _SlideshowPageState extends State<SlideshowPage> {
  final cs = CastState.I;
  List<File> files = [];
  List<int> order = [];
  int at = -1;
  int seconds = Store.p.getInt('slide_sec') ?? 6;
  bool shuffle = Store.p.getBool('slide_shuffle') ?? false;
  bool loop = true;
  bool running = false;

  @override
  void dispose() {
    _run++;
    running = false;
    super.dispose();
  }

  Future<void> pick() async {
    final r = await FilePicker.pickFiles(type: FileType.image);
    if (r.isEmpty) return;
    final out = <File>[];
    for (final f in r) {
      final x = await pickedToFile(f);
      if (x != null) out.add(x);
    }
    setState(() {
      files = out;
      order = slideOrder(files.length, shuffle: shuffle);
      at = -1;
    });
  }

  Future<void> show(int i) async {
    if (files.isEmpty) return;
    if (i >= order.length) {
      if (!loop) {
        stop();
        return;
      }
      order = slideOrder(files.length, shuffle: shuffle);
      i = 0;
    }
    if (i < 0) i = order.length - 1;
    setState(() => at = i);
    try {
      await cs.showImage(files[order[i]], title: 'صورة ${i + 1}');
    } catch (e) {
      if (mounted) toast(context, castErrorAr(e));
      stop();
    }
  }

  int _run = 0;

  /// لفة العرض: أول صورة بنستنى نعرف الريسيفر بيعرض صور بأنهي طريقة قبل ما نكمّل
  Future<void> start() async {
    if (files.isEmpty) return;
    final my = ++_run;
    setState(() => running = true);
    var i = at < 0 ? 0 : at;
    while (mounted && running && my == _run) {
      await show(i);
      if (!running || my != _run) return;
      var wait = seconds;
      if (cs.dlnaImagesOk == null) wait = max(wait, 15);
      for (var k = 0; k < wait * 4 && running && my == _run; k++) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
      i = at + 1;
      if (i >= order.length && !loop) return stop();
    }
  }

  void stop() {
    _run++;
    if (mounted) setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عرض صور على التلفزيون')),
      body: ListenableBuilder(
        listenable: cs,
        builder: (c, _) => ListView(padding: const EdgeInsets.all(12), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الشاشة: ${cs.current?.name ?? (cs.gm != null ? 'الريسيفر (G-MScreen)' : 'مش متحددة — اختارها من تبويب الكاست')}'),
                if (cs.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(cs.note, style: const TextStyle(fontSize: 12, color: kGold))),
                const SizedBox(height: 4),
                const Text('الصور بتتحوّل JPEG مقاس 1920 قبل ما تتبعت (أسرع وأي ريسيفر يفتحها).', style: TextStyle(fontSize: 11, color: kMuted)),
              ]),
            ),
          ),
          FilledButton.icon(onPressed: pick, icon: const Icon(Icons.photo_library_rounded), label: Text(files.isEmpty ? 'اختار صور' : '${files.length} صورة — غيّر')),
          const SizedBox(height: 10),
          Row(children: [
            const Text('كل'),
            Expanded(
              child: Slider(
                value: seconds.toDouble(),
                min: 3,
                max: 30,
                divisions: 27,
                label: '$seconds ث',
                onChanged: (v) => setState(() => seconds = v.round()),
                onChangeEnd: (v) => Store.p.setInt('slide_sec', seconds),
              ),
            ),
            Text('$seconds ثانية'),
          ]),
          SwitchListTile(
            title: const Text('ترتيب عشوائي'),
            value: shuffle,
            onChanged: (v) {
              setState(() {
                shuffle = v;
                order = slideOrder(files.length, shuffle: v);
              });
              Store.p.setBool('slide_shuffle', v);
            },
          ),
          SwitchListTile(title: const Text('يعيد من الأول لما يخلص'), value: loop, onChanged: (v) => setState(() => loop = v)),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton.filledTonal(icon: const Icon(Icons.skip_previous_rounded), onPressed: files.isEmpty ? null : () => show(at - 1)),
              IconButton.filled(iconSize: 36, icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded), onPressed: files.isEmpty ? null : (running ? stop : start)),
              IconButton.filledTonal(icon: const Icon(Icons.skip_next_rounded), onPressed: files.isEmpty ? null : () => show(at + 1)),
            ]),
          ),
          if (at >= 0 && files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(children: [
                Text('${at + 1} / ${files.length}', style: const TextStyle(color: kMuted)),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(files[order[at]], height: 220, fit: BoxFit.contain, cacheHeight: 440)),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ======== v4_pc.dart ========
// تبويب الكمبيوتر: ماوس وكيبورد + شاشة الكمبيوتر + ملفات — مع برنامج A2R-PC.exe على ويندوز

const int kPcHttpPort = 47800, kPcUdpPort = 47801;

// ---------------- OpenSubtitles (بحث وتنزيل ترجمات جوه التطبيق) ----------------
/// المفتاح واليوزر والباسورد بتكتبهم انت في التطبيق ومتخزنين في تخزين آمن على موبايلك بس. مفيش حاجة منهم في الكود.
class OsClient {
  static const _sec = FlutterSecureStorage();
  static const _ua = 'A2R Home v1.0';
  String? _token;
  String _base = 'https://api.opensubtitles.com/api/v1';

  static Future<String> apiKey() async => (await _sec.read(key: 'os_key')) ?? '';
  static Future<String> user() async => (await _sec.read(key: 'os_user')) ?? '';
  static Future<void> save(String key, String user, String pass) async {
    Future<void> w(String k, String v) => v.trim().isEmpty ? _sec.delete(key: k) : _sec.write(key: k, value: v.trim());
    await w('os_key', key);
    await w('os_user', user);
    await w('os_pass', pass);
  }

  Future<Map<String, String>> _h({bool auth = false}) async => {
        'Api-Key': await apiKey(),
        'User-Agent': _ua,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  /// تسجيل الدخول اختياري: من غيره التنزيل محدود (حوالي 5 في اليوم على نفس الشبكة)
  Future<void> _login() async {
    if (_token != null) return;
    final u = await _sec.read(key: 'os_user'), p = await _sec.read(key: 'os_pass');
    if (u == null || u.isEmpty || p == null || p.isEmpty) return;
    final r = await http.post(Uri.parse('$_base/login'), headers: await _h(), body: jsonEncode({'username': u, 'password': p})).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw StateError('تسجيل الدخول في OpenSubtitles فشل (${r.statusCode}) — راجع اليوزر والباسورد');
    final m = jsonDecode(r.body) as Map;
    _token = '${m['token']}';
    final b = '${m['base_url'] ?? ''}';
    if (b.isNotEmpty) _base = 'https://$b/api/v1';
  }

  Future<List<OsSub>> search(String q, List<String> langs) async {
    if ((await apiKey()).isEmpty) throw StateError('اكتب مفتاح OpenSubtitles الأول');
    final uri = Uri.parse('$_base/subtitles').replace(queryParameters: {'query': q, 'languages': langs.join(','), 'order_by': 'download_count', 'order_direction': 'desc'});
    final r = await http.get(uri, headers: await _h()).timeout(const Duration(seconds: 20));
    if (r.statusCode == 401 || r.statusCode == 403) throw StateError('المفتاح مرفوض — راجع مفتاح OpenSubtitles');
    if (r.statusCode != 200) throw StateError('OpenSubtitles رد بـ ${r.statusCode}');
    final out = <OsSub>[];
    for (final e in (jsonDecode(r.body)['data'] as List? ?? const [])) {
      final a = (e as Map)['attributes'] as Map? ?? {};
      final files = a['files'] as List? ?? const [];
      if (files.isEmpty) continue;
      final f = files.first as Map;
      out.add(OsSub(
          fileId: (f['file_id'] as num).toInt(),
          name: '${a['release'] ?? f['file_name'] ?? ''}',
          lang: '${a['language'] ?? ''}',
          downloads: (a['download_count'] as num?)?.toInt() ?? 0));
    }
    return out;
  }

  /// بينزّل الترجمة ويحفظها srt في فولدر مؤقت
  Future<File> download(OsSub s) async {
    await _login();
    final r = await http
        .post(Uri.parse('$_base/download'), headers: await _h(auth: true), body: jsonEncode({'file_id': s.fileId, 'sub_format': 'srt'}))
        .timeout(const Duration(seconds: 20));
    final m = r.body.isEmpty ? {} : jsonDecode(r.body) as Map;
    if (r.statusCode == 406) throw StateError('خلص حد التنزيل النهارده — سجّل يوزر وباسورد OpenSubtitles في الإعدادات أو جرب بكرة');
    if (r.statusCode != 200 || m['link'] == null) throw StateError('التنزيل فشل (${r.statusCode}) ${m['message'] ?? ''}');
    final f = await http.get(Uri.parse('${m['link']}'), headers: {'User-Agent': _ua}).timeout(const Duration(seconds: 30));
    if (f.statusCode != 200 || f.bodyBytes.isEmpty) throw StateError('ملف الترجمة مجاش');
    final dir = Directory('${(await getTemporaryDirectory()).path}/subs');
    await dir.create(recursive: true);
    final file = File('${dir.path}/os_${s.fileId}.srt');
    await file.writeAsBytes(f.bodyBytes);
    return file;
  }
}

class OsSub {
  final int fileId;
  final String name, lang;
  final int downloads;
  const OsSub({required this.fileId, required this.name, required this.lang, required this.downloads});
}

Future<void> osSettingsDialog(BuildContext context) async {
  final k = TextEditingController(text: await OsClient.apiKey());
  final u = TextEditingController(text: await OsClient.user());
  final p = TextEditingController();
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('إعدادات OpenSubtitles'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('المفتاح (API key) مجاني: سجّل حساب على opensubtitles.com ← Consumers ← New. اليوزر والباسورد اختياريين وبيزودوا حد التنزيل اليومي. كله بيتخزن على موبايلك بس.', style: TextStyle(fontSize: 12, color: kMuted, height: 1.5)),
          const SizedBox(height: 10),
          TextField(controller: k, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'مفتاح API')),
          const SizedBox(height: 8),
          TextField(controller: u, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'اليوزر (اختياري)')),
          const SizedBox(height: 8),
          TextField(controller: p, obscureText: true, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الباسورد (اختياري، سيبه فاضي لو مش عايز تغيّره)')),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))],
    ),
  );
  if (ok != true) return;
  final oldPass = p.text.isEmpty ? (await const FlutterSecureStorage().read(key: 'os_pass')) ?? '' : p.text;
  await OsClient.save(k.text, u.text, u.text.trim().isEmpty ? '' : oldPass);
}

/// شاشة البحث: بترجع ملف srt اللي اتنزل (أو null)
class SubSearchPage extends StatefulWidget {
  final String initialQuery;
  const SubSearchPage({super.key, this.initialQuery = ''});
  @override
  State<SubSearchPage> createState() => _SubSearchPageState();
}

class _SubSearchPageState extends State<SubSearchPage> {
  late final TextEditingController qc = TextEditingController(text: widget.initialQuery);
  final os = OsClient();
  List<OsSub> res = [];
  bool busy = false;
  String msg = '';
  int lang = 0; // 0 عربي، 1 إنجليزي، 2 الاتنين

  Future<void> _search() async {
    if (qc.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      msg = '';
    });
    try {
      res = await os.search(qc.text.trim(), const [['ar'], ['en'], ['ar', 'en']][lang]);
      if (res.isEmpty) msg = 'مفيش نتايج — جرب اسم الفيلم بالإنجليزي';
    } catch (e) {
      msg = '$e'.replaceFirst('Bad state: ', '');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _pick(OsSub s) async {
    setState(() {
      busy = true;
      msg = '';
    });
    try {
      final f = await os.download(s);
      if (mounted) Navigator.pop(context, f);
      return;
    } catch (e) {
      msg = '$e'.replaceFirst('Bad state: ', '');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ترجمة من OpenSubtitles'), actions: [IconButton(icon: const Icon(Icons.key_rounded), tooltip: 'الإعدادات', onPressed: () => osSettingsDialog(context))]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: qc,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(hintText: 'اسم الفيلم أو المسلسل', suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: busy ? null : _search)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<int>(
            segments: const [ButtonSegment(value: 0, label: Text('عربي')), ButtonSegment(value: 1, label: Text('إنجليزي')), ButtonSegment(value: 2, label: Text('الاتنين'))],
            selected: {lang},
            onSelectionChanged: (v) => setState(() => lang = v.first),
          ),
        ),
        if (busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(msg, style: const TextStyle(color: kBad))),
        Expanded(
          child: ListView.builder(
            itemCount: res.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(res[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
              subtitle: Text('${res[i].lang} • ${res[i].downloads} تنزيل', style: const TextStyle(fontSize: 12, color: kMuted)),
              trailing: const Icon(Icons.download_rounded, color: kGold),
              onTap: busy ? null : () => _pick(res[i]),
            ),
          ),
        ),
      ]),
    );
  }
}

class PcInfo {
  final String host, name;
  final int port;
  const PcInfo(this.host, this.name, [this.port = kPcHttpPort]);
}

/// رد البرنامج على البحث: {"a2r":"pc","name":"..","port":47800}
PcInfo? parsePcReply(String host, String text) {
  try {
    final m = jsonDecode(text);
    if (m is! Map || m['a2r'] != 'pc') return null;
    return PcInfo(host, '${m['name'] ?? host}', (m['port'] as num?)?.toInt() ?? kPcHttpPort);
  } catch (_) {
    return null;
  }
}

/// حركة الماوس من التاتش: سرعة أعلى للحركة السريعة (تسارع بسيط)
({int dx, int dy}) touchToMouse(double dx, double dy, double speed) {
  final v = sqrt(dx * dx + dy * dy);
  final acc = v > 18 ? 2.2 : (v > 8 ? 1.5 : 1.0);
  return (dx: (dx * speed * acc).round(), dy: (dy * speed * acc).round());
}

/// مكان اللمسة على صورة الشاشة (BoxFit.contain) → نسبة 0..1 من شاشة الكمبيوتر، أو null لو برة الصورة
Offset? tapToScreen(Offset p, Size box, Size img) {
  if (img.width <= 0 || img.height <= 0) return null;
  final s = min(box.width / img.width, box.height / img.height);
  final w = img.width * s, h = img.height * s;
  final ox = (box.width - w) / 2, oy = (box.height - h) / 2;
  final x = (p.dx - ox) / w, y = (p.dy - oy) / h;
  if (x < 0 || y < 0 || x > 1 || y > 1) return null;
  return Offset(x, y);
}

class PcClient {
  final String host;
  final int port;
  String? token;
  final HttpClient _h = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  PcClient(this.host, {this.port = kPcHttpPort, this.token});

  Uri _u(String p, [Map<String, String>? q]) => Uri(scheme: 'http', host: host, port: port, path: p, queryParameters: q);

  Future<HttpClientResponse> _req(String method, String p, {Map<String, String>? q, Object? json, Duration timeout = const Duration(seconds: 8)}) async {
    final r = await _h.openUrl(method, _u(p, q)).timeout(timeout);
    if (token != null) r.headers.set('X-A2R-Token', token!);
    if (json != null) {
      final b = utf8.encode(jsonEncode(json));
      r.headers.contentType = ContentType.json;
      r.contentLength = b.length;
      r.add(b);
    }
    return r.close().timeout(timeout);
  }

  Future<Map<String, dynamic>> _json(String method, String p, {Map<String, String>? q, Object? json}) async {
    final res = await _req(method, p, q: q, json: json);
    final t = await utf8.decoder.bind(res).join();
    final m = t.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(t) as Map);
    if (res.statusCode == 401) throw const PcAuthError();
    if (res.statusCode >= 400) throw StateError(pcErrAr('${m['error'] ?? res.statusCode}'));
    return m;
  }

  Future<String> pair(String code) async {
    final m = await _json('POST', '/pair', json: {'code': code.trim(), 'device': 'A2R Home'});
    token = '${m['token']}';
    return '${m['name'] ?? host}';
  }

  Future<Map<String, dynamic>> info() => _json('GET', '/info');
  Future<void> input(List<Map<String, dynamic>> cmds) => _json('POST', '/input', json: cmds);
  Future<void> power(String a) => _json('POST', '/power', json: {'a': a, 'confirm': true});
  Future<List<Map<String, dynamic>>> procs() async {
    final m = await _json('GET', '/procs');
    return [for (final e in (m['procs'] as List? ?? const [])) Map<String, dynamic>.from(e as Map)];
  }

  Future<void> killProc(int pid) => _json('POST', '/kill', json: {'pid': pid, 'confirm': true});
  Future<Map<String, dynamic>> files([String? path]) => _json('GET', '/files', q: path == null ? null : {'path': path});

  Future<Uint8List?> frame({int width = 1280, int quality = 60}) async {
    final res = await _req('GET', '/frame.jpg', q: {'w': '$width', 'q': '$quality'}, timeout: const Duration(seconds: 6));
    if (res.statusCode == 401) throw const PcAuthError();
    if (res.statusCode != 200) {
      await res.drain();
      return null;
    }
    final b = BytesBuilder(copy: false);
    await for (final c in res) {
      b.add(c);
    }
    return b.takeBytes();
  }

  Future<void> upload(File f, void Function(double) progress) async {
    final len = await f.length();
    final r = await _h.openUrl('POST', _u('/upload', {'name': f.uri.pathSegments.last}));
    r.headers.set('X-A2R-Token', token ?? '');
    r.contentLength = len;
    var sent = 0;
    await r.addStream(f.openRead().map((c) {
      sent += c.length;
      progress(sent / max(1, len));
      return c;
    }));
    final res = await r.close();
    final t = await utf8.decoder.bind(res).join();
    if (res.statusCode == 401) throw const PcAuthError();
    if (res.statusCode != 200) throw StateError('الرفع فشل: $t');
  }

  Future<File> download(String path, String name, void Function(double) progress) async {
    final res = await _req('GET', '/file', q: {'path': path}, timeout: const Duration(seconds: 20));
    if (res.statusCode != 200) {
      await res.drain();
      throw StateError('مقدرتش أنزّل الملف');
    }
    final dir = Directory('${(await getExternalStorageDirectory() ?? await getTemporaryDirectory()).path}/A2R-PC');
    await dir.create(recursive: true);
    final out = File('${dir.path}/${name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}');
    final sink = out.openWrite();
    var got = 0;
    final total = res.contentLength;
    await for (final c in res) {
      sink.add(c);
      got += c.length;
      if (total > 0) progress(got / total);
    }
    await sink.close();
    return out;
  }

  void close() => _h.close(force: true);

  /// يدوّر على الكمبيوتر في الشبكة (broadcast)
  static Future<List<PcInfo>> discover({Duration wait = const Duration(seconds: 3)}) async {
    final out = <String, PcInfo>{};
    await Native.multicastLock(true);
    RawDatagramSocket? s;
    try {
      s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      s.broadcastEnabled = true;
      s.listen((e) {
        if (e != RawSocketEvent.read) return;
        final d = s!.receive();
        if (d == null) return;
        final p = parsePcReply(d.address.address, utf8.decode(d.data, allowMalformed: true));
        if (p != null) out[p.host] = p;
      });
      final msg = utf8.encode('A2R-PC?');
      for (var i = 0; i < 3; i++) {
        s.send(msg, InternetAddress('255.255.255.255'), kPcUdpPort);
        await Future.delayed(wait ~/ 3);
      }
    } catch (e) {
      AppLog.add('PC', 'discover $e');
    } finally {
      s?.close();
      await Native.multicastLock(false);
    }
    return out.values.toList();
  }
}

class PcAuthError implements Exception {
  const PcAuthError();
  @override
  String toString() => 'الكمبيوتر لغى الربط — اربط تاني بالكود';
}

String pcErrAr(String e) {
  if (e == 'bad_code') return 'الكود غلط';
  if (e.startsWith('locked')) return 'محاولات غلط كتير — استنى دقيقة (الكود هيتغير)';
  if (e == 'not_lan') return 'لازم تكون على نفس الشبكة';
  if (e == 'outside_home') return 'الفولدر ده برة ملفات المستخدم';
  if (e == 'no_route') return 'نسخة A2R-PC.exe قديمة — نزّل الأحدث من Releases';
  if (e == 'protected') return 'دي عملية نظام ومحمية';
  if (e == 'no_such_pid') return 'العملية دي اتقفلت قبل كده';
  if (e == 'kill_failed') return 'ويندوز رفض يقفلها';
  return e;
}

class PcSaved {
  static ({String host, String name, String token})? get() {
    final s = Store.p.getString('pc_saved');
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map;
      return (host: '${m['h']}', name: '${m['n']}', token: '${m['t']}');
    } catch (_) {
      return null;
    }
  }

  static Future<void> put(String host, String name, String token) => Store.p.setString('pc_saved', jsonEncode({'h': host, 'n': name, 't': token}));
  static Future<void> clear() => Store.p.remove('pc_saved');
}

class PcPage extends StatefulWidget {
  const PcPage({super.key});
  @override
  State<PcPage> createState() => _PcPageState();
}

class _PcPageState extends State<PcPage> with AutomaticKeepAliveClientMixin {
  PcClient? pc;
  String name = '';
  String msg = '';
  bool busy = false;
  List<PcInfo> found = [];
  int view = 0; // 0 ماوس/كيبورد ، 1 الشاشة ، 2 الملفات

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = PcSaved.get();
    if (s != null) {
      pc = PcClient(s.host, token: s.token);
      name = s.name;
      _check();
    }
  }

  @override
  void dispose() {
    pc?.close();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final i = await pc!.info();
      unawaited(PcWake.learn(pc!));
      setState(() => msg = '${i['name']} • ${pc!.host}');
    } on PcAuthError {
      await PcSaved.clear();
      setState(() {
        pc = null;
        msg = 'الكمبيوتر لغى الربط — اربط تاني';
      });
    } catch (e) {
      setState(() => msg = PcWake.macs.isEmpty
          ? 'الكمبيوتر مش بيرد — شغّل A2R PC عليه (${pc!.host})'
          : 'الكمبيوتر مش بيرد — لو مقفول جرّب «شغّل الكمبيوتر» من القايمة (⋮)');
    }
  }

  Future<void> discover() async {
    setState(() {
      busy = true;
      msg = 'بدوّر على الكمبيوتر…';
    });
    found = await PcClient.discover();
    setState(() {
      busy = false;
      msg = found.isEmpty ? 'ملقتش — اتأكد إن A2R PC شغال وإن الكمبيوتر على نفس الواي فاي (أو اكتب العنوان اللي ظاهر في الشباك)' : 'دوس على الكمبيوتر واكتب الكود';
    });
  }

  Future<void> pairWith(String host) async {
    final code = await askText(context, 'كود الربط (6 أرقام ظاهرين على الكمبيوتر)', type: TextInputType.number);
    if (code == null || code.trim().isEmpty) return;
    final c = PcClient(host);
    setState(() => busy = true);
    try {
      final n = await c.pair(code);
      await PcSaved.put(host, n, c.token!);
      pc?.close();
      setState(() {
        pc = c;
        name = n;
        msg = '$n • $host';
        found = [];
      });
      AppLog.add('PC', 'paired $host');
    } catch (e) {
      c.close();
      if (mounted) toast(context, '$e'.replaceFirst('Bad state: ', ''));
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> manual() async {
    final ip = await askText(context, 'عنوان الكمبيوتر', hint: '192.168.x.x', type: TextInputType.number);
    if (ip != null && ip.trim().isNotEmpty) await pairWith(ip.trim());
  }

  Future<void> unpair() async {
    if (!await confirm(context, 'تلغي الربط مع $name؟')) return;
    await PcSaved.clear();
    pc?.close();
    setState(() {
      pc = null;
      msg = '';
    });
  }

  void onErr(Object e) {
    if (e is PcAuthError) {
      PcSaved.clear();
      setState(() => pc = null);
    }
    if (mounted) toast(context, '$e'.replaceFirst('Bad state: ', ''));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Live.pc = pc != null;
    if (pc == null) return _pairView();
    return Column(children: [
      Card(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: ListTile(
          leading: const Icon(Icons.desktop_windows_rounded, color: kGold),
          title: Text(name),
          subtitle: Text(msg.isEmpty ? pc!.host : msg, style: const TextStyle(fontSize: 12, color: kMuted)),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'check') _check();
              if (v == 'unpair') unpair();
              if (v == 'wol') PcWake.wake(context);
            },
            itemBuilder: (c) => [
              const PopupMenuItem(value: 'check', child: Text('اتأكد من الاتصال')),
              if (PcWake.macs.isNotEmpty) const PopupMenuItem(value: 'wol', child: Text('شغّل الكمبيوتر (Wake-on-LAN)')),
              const PopupMenuItem(value: 'unpair', child: Text('الغي الربط')),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, icon: Icon(Icons.mouse_rounded), label: Text('ماوس')),
            ButtonSegment(value: 1, icon: Icon(Icons.screenshot_monitor_rounded), label: Text('الشاشة')),
            ButtonSegment(value: 2, icon: Icon(Icons.folder_rounded), label: Text('ملفات')),
          ],
          selected: {view},
          onSelectionChanged: (s) => setState(() => view = s.first),
        ),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: switch (view) {
          0 => PcMousePad(pc: pc!, onErr: onErr),
          1 => PcScreenView(pc: pc!, onErr: onErr),
          _ => PcFilesView(pc: pc!, onErr: onErr),
        },
      ),
    ]);
  }

  Widget _pairView() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تحكم في الكمبيوتر من الموبايل', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
                '1) نزّل A2R-PC.exe على الكمبيوتر (من صفحة Releases في GitHub) وشغّله.\n'
                '2) لو ويندوز سأل عن الجدار الناري (Firewall) اختار "Private networks" ووافق.\n'
                '3) الكمبيوتر والموبايل على نفس الراوتر — دوّر واكتب الكود اللي ظاهر في الشباك.',
                style: TextStyle(fontSize: 13, color: kMuted, height: 1.6)),
            const SizedBox(height: 10),
            Row(children: [
              FilledButton.icon(onPressed: busy ? null : discover, icon: const Icon(Icons.search_rounded), label: const Text('دوّر')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: busy ? null : manual, icon: const Icon(Icons.edit_rounded), label: const Text('عنوان يدوي')),
            ]),
          ]),
        ),
      ),
      if (busy) const LinearProgressIndicator(),
      if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(msg, style: const TextStyle(color: kMuted))),
      for (final p in found)
        Card(
          child: ListTile(
            leading: const Icon(Icons.desktop_windows_rounded, color: kGold),
            title: Text(p.name),
            subtitle: Text(p.host),
            trailing: const Icon(Icons.link_rounded),
            onTap: () => pairWith(p.host),
          ),
        ),
    ]);
  }
}

/// بيجمع حركات الماوس ويبعتها كل 35ms (بدل طلب لكل حركة)
class _InputBatcher {
  final PcClient pc;
  final void Function(Object) onErr;
  double _dx = 0, _dy = 0, _sc = 0;
  final List<Map<String, dynamic>> _q = [];
  Timer? _t;
  bool _sending = false;
  _InputBatcher(this.pc, this.onErr);

  void move(double dx, double dy) {
    _dx += dx;
    _dy += dy;
    _kick();
  }

  void scroll(double dy) {
    _sc += dy;
    _kick();
  }

  void cmd(Map<String, dynamic> c) {
    _flushMove();
    _q.add(c);
    _kick();
  }

  void _flushMove() {
    if (_dx.abs() >= 1 || _dy.abs() >= 1) {
      _q.add({'t': 'move', 'dx': _dx.round(), 'dy': _dy.round()});
      _dx = _dy = 0;
    }
    if (_sc.abs() >= 1) {
      _q.add({'t': 'scroll', 'dy': _sc.round().clamp(-50, 50)});
      _sc = 0;
    }
  }

  void _kick() => _t ??= Timer(const Duration(milliseconds: 35), _send);

  Future<void> _send() async {
    _t = null;
    if (_sending) return _kick();
    _flushMove();
    if (_q.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_q);
    _q.clear();
    _sending = true;
    try {
      await pc.input(batch);
    } catch (e) {
      onErr(e);
    } finally {
      _sending = false;
    }
  }

  void dispose() => _t?.cancel();
}

class PcMousePad extends StatefulWidget {
  final PcClient pc;
  final void Function(Object) onErr;
  const PcMousePad({super.key, required this.pc, required this.onErr});
  @override
  State<PcMousePad> createState() => _PcMousePadState();
}

class _PcMousePadState extends State<PcMousePad> {
  late final _InputBatcher b = _InputBatcher(widget.pc, widget.onErr);
  final txt = TextEditingController();
  double speed = Store.p.getDouble('pc_speed') ?? 1.6;
  bool dragging = false;
  int _fingers = 0;
  Offset _lp = Offset.zero;

  @override
  void dispose() {
    b.dispose();
    txt.dispose();
    super.dispose();
  }

  void key(String k, [List<String> mods = const []]) {
    HapticFeedback.selectionClick();
    b.cmd({'t': 'key', 'k': k, 'mods': mods});
  }

  Future<void> power(String a, String label) async {
    if (a != 'lock' && !await confirm(context, '$label الكمبيوتر؟')) return;
    try {
      await widget.pc.power(a);
      if (mounted) toast(context, a == 'shutdown' || a == 'restart' ? '$label خلال 5 ثواني (إلغاء ← من القايمة)' : '$label ✓');
    } catch (e) {
      widget.onErr(e);
    }
  }

  Widget _k(String label, VoidCallback f, {IconData? icon}) => Padding(
        padding: const EdgeInsets.all(3),
        child: ActionChip(avatar: icon == null ? null : Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 12)), onPressed: f),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
      SizedBox(
        height: 300,
        child: Row(children: [
          Expanded(
            child: Listener(
              onPointerDown: (_) => _fingers++,
              onPointerUp: (_) => _fingers = max(0, _fingers - 1),
              onPointerCancel: (_) => _fingers = max(0, _fingers - 1),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  b.cmd({'t': 'click', 'b': 'left'});
                },
                onDoubleTap: () => b.cmd({'t': 'click', 'b': 'left', 'n': 2}),
                onLongPressStart: (_) {
                  _lp = Offset.zero;
                  HapticFeedback.heavyImpact();
                  setState(() => dragging = true);
                  b.cmd({'t': 'down', 'b': 'left'});
                },
                onLongPressMoveUpdate: (d) {
                  final delta = d.offsetFromOrigin - _lp;
                  _lp = d.offsetFromOrigin;
                  final m = touchToMouse(delta.dx, delta.dy, speed);
                  b.move(m.dx.toDouble(), m.dy.toDouble());
                },
                onLongPressEnd: (_) {
                  setState(() => dragging = false);
                  b.cmd({'t': 'up', 'b': 'left'});
                },
                onPanUpdate: (d) {
                  if (_fingers >= 2) {
                    b.scroll(d.delta.dy / 6);
                    return;
                  }
                  final m = touchToMouse(d.delta.dx, d.delta.dy, speed);
                  b.move(m.dx.toDouble(), m.dy.toDouble());
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E222A), Color(0xFF14171D)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: dragging ? kGold : kLine),
                  ),
                  alignment: Alignment.center,
                  child: Text(dragging ? 'بتسحب… ارفع صباعك علشان تسيب' : 'حرّك صباعك = ماوس\nدوسة = كليك • دوستين = دبل كليك\nضغطة طويلة = سحب • صباعين = سكرول',
                      textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 12, height: 1.7)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // شريط السكرول
          GestureDetector(
            onVerticalDragUpdate: (d) => b.scroll(d.delta.dy / 4),
            child: Container(
              width: 44,
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Padding(padding: EdgeInsets.all(6), child: Icon(Icons.keyboard_arrow_up_rounded, color: kMuted)),
                Icon(Icons.unfold_more_rounded, color: kGold),
                Padding(padding: EdgeInsets.all(6), child: Icon(Icons.keyboard_arrow_down_rounded, color: kMuted)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: FilledButton.tonal(onPressed: () => b.cmd({'t': 'click', 'b': 'left'}), child: const Text('كليك شمال'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.tonal(onPressed: () => b.cmd({'t': 'click', 'b': 'right'}), child: const Text('كليك يمين'))),
      ]),
      Row(children: [
        const Text('السرعة', style: TextStyle(color: kMuted, fontSize: 12)),
        Expanded(
          child: Slider(value: speed, min: 0.6, max: 4, onChanged: (v) => setState(() => speed = v), onChangeEnd: (v) => Store.p.setDouble('pc_speed', v)),
        ),
      ]),
      TextField(
        controller: txt,
        decoration: InputDecoration(
          labelText: 'اكتب على الكمبيوتر (عربي أو إنجليزي)',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_rounded, color: kGold),
            onPressed: () {
              if (txt.text.isEmpty) return;
              b.cmd({'t': 'text', 's': txt.text});
              txt.clear();
            },
          ),
        ),
        onSubmitted: (v) {
          if (v.isNotEmpty) b.cmd({'t': 'text', 's': v});
          b.cmd({'t': 'key', 'k': 'enter', 'mods': <String>[]});
          txt.clear();
        },
      ),
      const SizedBox(height: 6),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(children: [
          _k('Enter', () => key('enter')),
          _k('⌫', () => key('backspace')),
          _k('Esc', () => key('esc')),
          _k('Tab', () => key('tab')),
          _k('←', () => key('left')),
          _k('↑', () => key('up')),
          _k('↓', () => key('down')),
          _k('→', () => key('right')),
          _k('Win', () => key('win')),
          _k('Alt+Tab', () => key('tab', ['alt'])),
          _k('Ctrl+C', () => key('c', ['ctrl'])),
          _k('Ctrl+V', () => key('v', ['ctrl'])),
          _k('Ctrl+Z', () => key('z', ['ctrl'])),
          _k('Space', () => key('space')),
          _k('F5', () => key('f5')),
          _k('F11', () => key('f11')),
          _k('Alt+F4', () => key('f4', ['alt'])),
        ]),
      ),
      const SectionTitle('صوت وميديا', icon: Icons.music_note_rounded),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final e in const [
            ('prev', Icons.skip_previous_rounded),
            ('play', Icons.play_arrow_rounded),
            ('next', Icons.skip_next_rounded),
            ('voldown', Icons.volume_down_rounded),
            ('volup', Icons.volume_up_rounded),
            ('mute', Icons.volume_off_rounded),
          ])
            IconButton.filledTonal(icon: Icon(e.$2), onPressed: () => b.cmd({'t': 'media', 'k': e.$1})),
        ]),
      ),
      const SectionTitle('الكمبيوتر', icon: Icons.power_settings_new_rounded),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: () => power('lock', 'قفل'), icon: const Icon(Icons.lock_rounded), label: const Text('قفل')),
        OutlinedButton.icon(onPressed: () => power('sleep', 'نوّم'), icon: const Icon(Icons.bedtime_rounded), label: const Text('سليب')),
        OutlinedButton.icon(onPressed: () => power('restart', 'ريستارت'), icon: const Icon(Icons.restart_alt_rounded), label: const Text('ريستارت')),
        OutlinedButton.icon(
          onPressed: () => power('shutdown', 'اطفي'),
          icon: const Icon(Icons.power_settings_new_rounded, color: kBad),
          label: const Text('اطفي', style: TextStyle(color: kBad)),
        ),
        TextButton(onPressed: () => widget.pc.power('cancel').catchError(widget.onErr), child: const Text('إلغاء الإطفاء')),
      ]),
      PcExtras(pc: widget.pc, onErr: widget.onErr),
    ]);
  }
}

class PcScreenView extends StatefulWidget {
  final PcClient pc;
  final void Function(Object) onErr;
  const PcScreenView({super.key, required this.pc, required this.onErr});
  @override
  State<PcScreenView> createState() => _PcScreenViewState();
}

class _PcScreenViewState extends State<PcScreenView> {
  Uint8List? img;
  Size imgSize = Size.zero;
  bool running = true, control = true;
  int quality = Store.p.getInt('pc_q') ?? 55;
  int width = Store.p.getInt('pc_w') ?? 1280;
  int fps = 0, _frames = 0;
  DateTime _t0 = DateTime.now();
  int _gen = 0;
  late final _InputBatcher b = _InputBatcher(widget.pc, widget.onErr);
  final tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _loop();
  }

  @override
  void dispose() {
    _gen++;
    b.dispose();
    super.dispose();
  }

  Future<void> _loop() async {
    final my = ++_gen;
    var fails = 0;
    while (mounted && running && my == _gen) {
      try {
        final f = await widget.pc.frame(width: width, quality: quality);
        if (f != null && mounted) {
          if (imgSize == Size.zero || _frames % 30 == 0) {
            final im = await decodeImageFromList(f);
            imgSize = Size(im.width.toDouble(), im.height.toDouble());
            im.dispose();
          }
          _frames++;
          final el = DateTime.now().difference(_t0).inMilliseconds;
          if (el > 1000) {
            fps = (_frames * 1000 / el).round();
            _frames = 0;
            _t0 = DateTime.now();
          }
          setState(() => img = f);
          fails = 0;
        }
      } catch (e) {
        fails++;
        if (e is PcAuthError || fails >= 5) {
          widget.onErr(e);
          if (mounted) setState(() => running = false);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  void _at(Offset local, Size box, Map<String, dynamic> then) {
    final p = tapToScreen(local, box, imgSize);
    if (p == null) return;
    b.cmd({'t': 'abs', 'x': p.dx, 'y': p.dy});
    b.cmd(then);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          IconButton(
            icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: kGold),
            onPressed: () {
              setState(() => running = !running);
              if (running) _loop();
            },
          ),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              value: quality <= 40 ? 35 : (quality <= 60 ? 55 : 80),
              items: const [
                DropdownMenuItem(value: 35, child: Text('جودة واطية (أسرع)')),
                DropdownMenuItem(value: 55, child: Text('جودة متوسطة')),
                DropdownMenuItem(value: 80, child: Text('جودة عالية')),
              ],
              onChanged: (v) {
                setState(() {
                  quality = v!;
                  width = v == 35 ? 960 : (v == 55 ? 1280 : 1920);
                });
                Store.p.setInt('pc_q', quality);
                Store.p.setInt('pc_w', width);
              },
            ),
          ),
          Text('$fps fps', style: const TextStyle(fontSize: 11, color: kMuted)),
          IconButton(
            tooltip: control ? 'تحكم (دوس = كليك)' : 'تكبير/تحريك بس',
            icon: Icon(control ? Icons.touch_app_rounded : Icons.zoom_in_rounded, color: control ? kGold : kMuted),
            onPressed: () => setState(() => control = !control),
          ),
        ]),
      ),
      Expanded(
        child: img == null
            ? Center(child: running ? const CircularProgressIndicator() : const Text('متوقف', style: TextStyle(color: kMuted)))
            : LayoutBuilder(
                builder: (c, cons) {
                  final box = Size(cons.maxWidth, cons.maxHeight);
                  return InteractiveViewer(
                    transformationController: tc,
                    maxScale: 5,
                    panEnabled: !control,
                    child: GestureDetector(
                      onTapUp: control ? (d) => _at(d.localPosition, box, {'t': 'click', 'b': 'left'}) : null,
                      onDoubleTapDown: control ? (d) => _at(d.localPosition, box, {'t': 'click', 'b': 'left', 'n': 2}) : null,
                      onDoubleTap: control ? () {} : null,
                      onLongPressStart: control ? (d) => _at(d.localPosition, box, {'t': 'click', 'b': 'right'}) : null,
                      onPanStart: control ? (d) => _at(d.localPosition, box, {'t': 'down', 'b': 'left'}) : null,
                      onPanUpdate: control
                          ? (d) {
                              final p = tapToScreen(d.localPosition, box, imgSize);
                              if (p != null) b.cmd({'t': 'abs', 'x': p.dx, 'y': p.dy});
                            }
                          : null,
                      onPanEnd: control ? (_) => b.cmd({'t': 'up', 'b': 'left'}) : null,
                      child: SizedBox(width: box.width, height: box.height, child: Image.memory(img!, fit: BoxFit.contain, gaplessPlayback: true)),
                    ),
                  );
                },
              ),
      ),
      const Padding(
        padding: EdgeInsets.all(6),
        child: Text('دوسة = كليك • دوستين = دبل كليك • ضغطة طويلة = كليك يمين • اسحب = سحب • لتكبير الصورة اقفل وضع التحكم', style: TextStyle(fontSize: 11, color: kMuted)),
      ),
    ]);
  }
}

class PcFilesView extends StatefulWidget {
  final PcClient pc;
  final void Function(Object) onErr;
  const PcFilesView({super.key, required this.pc, required this.onErr});
  @override
  State<PcFilesView> createState() => _PcFilesViewState();
}

class _PcFilesViewState extends State<PcFilesView> {
  String? path, up;
  List<Map<String, dynamic>> items = [];
  bool loading = false;
  String progress = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load([String? p]) async {
    setState(() => loading = true);
    try {
      final r = await widget.pc.files(p);
      path = '${r['path']}';
      up = r['up'] == null ? null : '${r['up']}';
      items = List<Map<String, dynamic>>.from((r['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (e) {
      widget.onErr(e);
    }
    if (mounted) setState(() => loading = false);
  }

  String _join(String dir, String n) => dir.endsWith('\\') || dir.endsWith('/') ? '$dir$n' : '$dir${dir.contains('\\') ? '\\' : '/'}$n';

  Future<void> send() async {
    final r = await FilePicker.pickFiles();
    if (r.isEmpty) return;
    for (final f in r) {
      final file = await pickedToFile(f);
      if (file == null) continue;
      try {
        await widget.pc.upload(file, (p) {
          if (mounted) setState(() => progress = '${f.name}: ${(p * 100).toStringAsFixed(0)}%');
        });
        AppLog.add('PC', 'upload ${f.name} ${fmtBytes(await file.length())}');
      } catch (e) {
        widget.onErr(e);
        break;
      }
    }
    if (mounted) {
      setState(() => progress = 'اتبعتوا لـ Downloads\\A2R على الكمبيوتر ✓');
      load(path);
    }
  }

  Future<void> get(Map<String, dynamic> it) async {
    try {
      final f = await widget.pc.download(_join(path!, '${it['n']}'), '${it['n']}', (p) {
        if (mounted) setState(() => progress = '${it['n']}: ${(p * 100).toStringAsFixed(0)}%');
      });
      if (!mounted) return;
      setState(() => progress = 'اتنزل ✓');
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
    } catch (e) {
      widget.onErr(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          FilledButton.icon(onPressed: send, icon: const Icon(Icons.upload_rounded), label: const Text('ابعت للكمبيوتر')),
          const SizedBox(width: 8),
          IconButton(onPressed: up == null ? null : () => load(up), icon: const Icon(Icons.arrow_upward_rounded)),
          IconButton(onPressed: () => load(), icon: const Icon(Icons.home_rounded), tooltip: 'Downloads\\A2R'),
          IconButton(onPressed: () => load(path), icon: const Icon(Icons.refresh_rounded)),
        ]),
      ),
      if (progress.isNotEmpty) Padding(padding: const EdgeInsets.all(4), child: Text(progress, style: const TextStyle(fontSize: 12, color: kGold))),
      if (path != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(path!, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 11, color: kMuted))),
      if (loading) const LinearProgressIndicator(),
      Expanded(
        child: items.isEmpty
            ? const EmptyState(icon: Icons.folder_open_rounded, title: 'الفولدر فاضي', hint: 'اللي بتبعته من الموبايل بيتحفظ هنا')
            : ListView(children: [
                for (final it in items)
                  ListTile(
                    leading: Icon(it['d'] == true ? Icons.folder_rounded : Icons.insert_drive_file_outlined, color: it['d'] == true ? kGold : kMuted),
                    title: Text('${it['n']}', textDirection: TextDirection.ltr),
                    subtitle: it['d'] == true ? null : Text(fmtBytes((it['s'] as num?) ?? 0)),
                    trailing: it['d'] == true ? null : const Icon(Icons.download_rounded),
                    onTap: () => it['d'] == true ? load(_join(path!, '${it['n']}')) : get(it),
                  ),
              ]),
      ),
    ]);
  }
}

// ======== cast_images_v5.dart ========
// الصور على الريسيفر: سلّم تجارب (كل تجربة بطريقة إرسال مختلفة) + الطريقة اللي نجحت بتتحفظ
// السبب: في سجل أحمد الريسيفر عمل HEAD للصورة ومطلبهاش (GET) أبدًا، و Web Video Caster بيعرضها عادي.

const String kImgFlagsInteractive = 'DLNA.ORG_FLAGS=00F00000000000000000000000000000';
const String kImgFlagsStreaming = 'DLNA.ORG_FLAGS=01700000000000000000000000000000';

/// طريقة واحدة لإرسال صورة
class ImgVariant {
  final String id;
  final String label;
  /// upnp:class
  final String cls;
  /// 'full' = JPEG_LRG + أعلام Interactive | 'plain' = * | 'pn' = JPEG_LRG بس | 'stream' = أعلام زي الفيديو | 'custom'
  final String pi;
  /// نبعت وصف (DIDL) ولا CurrentURIMetaData فاضي
  final bool meta;
  /// 'play' = Play بعد نص ثانية | 'wait' = نستنى STOPPED وبعدين ثانية وبعدين Play | 'none' = من غير Play
  final String play;
  /// هيدرز رد السيرفر: 'lower' (زي v4) | 'dlna' (Interactive بحروف صح) | 'plain' (من غير DLNA) | 'stream' (زي الفيديو) | 'custom'
  final String hdr;
  /// 'ext' = .../اسم.jpg | 'noext' = /f/ID | 'query' = /f/ID?f=img.jpg
  final String url;
  /// للطريقة المتعلّمة من Web Video Caster: الوصف كامل فيه {URL}
  final String? customMeta;
  final String? customPi;
  final Map<String, String>? customHeaders;
  const ImgVariant(this.id, this.label,
      {this.cls = 'object.item.imageItem.photo',
      this.pi = 'plain',
      this.meta = true,
      this.play = 'play',
      this.hdr = 'plain',
      this.url = 'ext',
      this.customMeta,
      this.customPi,
      this.customHeaders});

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'cls': cls,
        'pi': pi,
        'meta': meta,
        'play': play,
        'hdr': hdr,
        'url': url,
        if (customMeta != null) 'customMeta': customMeta,
        if (customPi != null) 'customPi': customPi,
        if (customHeaders != null) 'customHeaders': customHeaders,
      };

  static ImgVariant? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      return ImgVariant(j['id'] as String, (j['label'] ?? j['id']) as String,
          cls: (j['cls'] ?? 'object.item.imageItem.photo') as String,
          pi: (j['pi'] ?? 'plain') as String,
          meta: j['meta'] != false,
          play: (j['play'] ?? 'play') as String,
          hdr: (j['hdr'] ?? 'plain') as String,
          url: (j['url'] ?? 'ext') as String,
          customMeta: j['customMeta'] as String?,
          customPi: j['customPi'] as String?,
          customHeaders: j['customHeaders'] == null ? null : Map<String, String>.from(j['customHeaders'] as Map));
    } catch (_) {
      return null;
    }
  }
}

/// الترتيب: الأبسط (زي أغلب تطبيقات الكاست) الأول، وآخر واحدة هي طريقة v4 اللي فشلت (للمقارنة بس)
const List<ImgVariant> kImgLadder = [
  // الأول: نفس وصف v4 بالظبط بس هيدرز الرد بالحروف الصح ومن غير هيدرز دارت الزيادة
  // (سجل أحمد: الريسيفر عمل HEAD وبعدين سكت — غالبًا مفهمش هيدرز الرد اللي كانت كلها حروف صغيرة)
  ImgVariant('dlna', 'DLNA كامل بحروف صح', pi: 'full', hdr: 'dlna', play: 'play'),
  ImgVariant('plain', 'وصف بسيط + هيدرز عادية', pi: 'plain', hdr: 'plain', play: 'wait'),
  ImgVariant('stream', 'زي الفيديو (Streaming)', pi: 'stream', hdr: 'stream', play: 'play'),
  ImgVariant('noplay', 'من غير Play', pi: 'plain', hdr: 'plain', play: 'none'),
  ImgVariant('nometa', 'من غير وصف', meta: false, hdr: 'plain', play: 'wait'),
  ImgVariant('item', 'imageItem + JPEG_LRG', cls: 'object.item.imageItem', pi: 'pn', hdr: 'dlna', play: 'play'),
  ImgVariant('noext', 'رابط من غير امتداد', pi: 'plain', hdr: 'plain', url: 'noext', play: 'wait'),
  ImgVariant('query', 'رابط ?f=img.jpg', pi: 'plain', hdr: 'stream', url: 'query', play: 'play'),
  ImgVariant('v4', 'طريقة v4 القديمة', pi: 'full', hdr: 'lower', play: 'play'),
];

/// ترتيب التجارب: المتعلّمة من WVC → اللي نجحت آخر مرة → الباقي
List<ImgVariant> imgLadderOrder({String? preferredId, ImgVariant? learned}) {
  final out = <ImgVariant>[];
  if (learned != null) out.add(learned);
  final pref = kImgLadder.where((v) => v.id == preferredId);
  out.addAll(pref.where((v) => !out.any((o) => o.id == v.id)));
  out.addAll(kImgLadder.where((v) => !out.any((o) => o.id == v.id)));
  return out;
}

String imgProtocolInfo(ImgVariant v) {
  switch (v.pi) {
    case 'full':
      return 'http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_LRG;DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kImgFlagsInteractive';
    case 'pn':
      return 'http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_LRG';
    case 'stream':
      return 'http-get:*:image/jpeg:DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kImgFlagsStreaming';
    case 'custom':
      return v.customPi ?? 'http-get:*:image/jpeg:*';
    default:
      return 'http-get:*:image/jpeg:*';
  }
}

/// وصف الصورة (DIDL-Lite) حسب الطريقة
String buildImageDidl(String url, String title, ImgVariant v) {
  if (!v.meta) return '';
  if (v.customMeta != null && v.customMeta!.isNotEmpty) {
    return v.customMeta!.replaceAll('{URL}', xmlEsc(url)).replaceAll('{TITLE}', xmlEsc(title));
  }
  return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" '
      'xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">'
      '<item id="1" parentID="0" restricted="1"><dc:title>${xmlEsc(title)}</dc:title>'
      '<upnp:class>${v.cls}</upnp:class>'
      '<res protocolInfo="${xmlEsc(imgProtocolInfo(v))}">${xmlEsc(url)}</res>'
      '</item></DIDL-Lite>';
}

/// هيدرز رد سيرفر الموبايل للصورة (بالحروف زي ما هي: بعض الريسيفرات بتقارن الاسم بالحروف)
List<(String, String)> imgServeHeaders(ImgVariant v) {
  switch (v.hdr) {
    case 'dlna':
      return [
        ('transferMode.dlna.org', 'Interactive'),
        ('contentFeatures.dlna.org', 'DLNA.ORG_PN=JPEG_LRG;DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kImgFlagsInteractive'),
      ];
    case 'stream':
      return [
        ('transferMode.dlna.org', 'Streaming'),
        ('contentFeatures.dlna.org', 'DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kImgFlagsStreaming'),
      ];
    case 'custom':
      return (v.customHeaders ?? const {}).entries.map((e) => (e.key, e.value)).toList();
    default:
      return const [];
  }
}

String imgUrlFor(String base, String id, String name, String mode) {
  switch (mode) {
    case 'noext':
      return '$base/f/$id';
    case 'query':
      return '$base/f/$id?f=img.jpg';
    default:
      return '$base/f/$id/$name';
  }
}

/// سلّم التجارب نفسه (منفصل علشان يتختبر): بيرجّع الطريقة اللي نجحت (أو null) وعدد التجارب
Future<(ImgVariant?, int)> runImageLadder({
  required List<ImgVariant> order,
  required Future<String> Function(ImgVariant v, int n) share,
  required Future<void> Function(String url, ImgVariant v) load,
  required Future<bool> Function(String url, ImgVariant v) waitFetch,
  void Function(String msg)? note,
  bool Function()? cancelled,
  Future<void> Function()? stop,
}) async {
  for (var n = 0; n < order.length; n++) {
    if (cancelled?.call() ?? false) return (null, n);
    final v = order[n];
    note?.call('صورة: تجربة ${n + 1} من ${order.length} (${v.label})…');
    AppLog.add('CAST', 'صورة: تجربة ${n + 1} من ${order.length} [${v.id}] class=${v.cls} pi=${imgProtocolInfo(v)} meta=${v.meta} play=${v.play} hdr=${v.hdr} url=${v.url}');
    final url = await share(v, n);
    final id = MediaServer.idOfUrl(url);
    try {
      await load(url, v);
    } catch (e) {
      AppLog.add('CAST', 'صورة: تجربة ${n + 1} (${v.id}) ✗ الريسيفر رفض: $e');
      continue;
    }
    if (await waitFetch(url, v)) {
      AppLog.add('CAST', 'صورة: تجربة ${n + 1} (${v.id}) ✓ الريسيفر طلب الصورة (GET)');
      return (v, n + 1);
    }
    if (cancelled?.call() ?? false) return (null, n + 1);
    AppLog.add('CAST',
        'صورة: تجربة ${n + 1} (${v.id}) ✗ ${id != null && MediaServer.I.headed.contains(id) ? 'الريسيفر عمل HEAD بس ومطلبش الصورة' : 'الريسيفر مطلبش حاجة'}');
  }
  try {
    await stop?.call();
  } catch (_) {}
  return (null, order.length);
}

String xmlUnesc(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

String learnedCountAr(int n) => n == 1 ? 'طريقة واحدة' : '$n طرق';

String imageAllFailedAr(int n) =>
    'الريسيفر مرضيش يحمّل الصورة بأي طريقة من ${learnedCountAr(n)} جرّبتهم. Web Video Caster بيعرض صور على نفس الريسيفر، '
    'يعني العيب في طريقة الإرسال مش في الريسيفر: افتح «تعلّم من Web Video Caster» هنا في الكاست، ابعت صورة منه، وبعدين ابعتلي السجل.';

// ---------- «تعلّم من Web Video Caster»: شاشة DLNA وهمية على الموبايل ----------

/// (service, action) من هيدر SOAPACTION أو من البودي
(String, String) parseSoapAction(String? soapActionHeader, String body) {
  final h = (soapActionHeader ?? '').replaceAll('"', '').trim();
  final m = RegExp(r'service:(\w+):\d+#(\w+)').firstMatch(h);
  if (m != null) return (m[1]!, m[2]!);
  final b = RegExp(r'<(?:\w+:)?(\w+)\s+xmlns(?::\w+)?="urn:schemas-upnp-org:service:(\w+):\d+"').firstMatch(body);
  if (b != null) return (b[2]!, b[1]!);
  return ('', '');
}

const String kLearnSink = 'http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_LRG,http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_MED,'
    'http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_SM,http-get:*:image/jpeg:*,http-get:*:image/png:*,http-get:*:image/gif:*,'
    'http-get:*:video/mp4:*,http-get:*:video/x-matroska:*,http-get:*:video/mpeg:*,http-get:*:video/mp2t:*,'
    'http-get:*:application/x-mpegURL:*,http-get:*:application/vnd.apple.mpegurl:*,http-get:*:audio/mpeg:*,http-get:*:audio/mp4:*';

/// حالة الشاشة الوهمية (علشان GetTransportInfo وغيره)
class LearnState {
  String state = 'NO_MEDIA_PRESENT';
  String uri = '';
  String metaEsc = '';
  int volume = 30;
  bool mute = false;
}

/// رد الشاشة الوهمية على أي أمر SOAP
String learnSoapReply(String service, String action, String body, LearnState st) {
  String v(String tag) => soapValue(body, tag) ?? '';
  final out = <String, String>{};
  switch (action) {
    case 'SetAVTransportURI':
      st.uri = xmlUnesc(v('CurrentURI')).trim();
      st.metaEsc = v('CurrentURIMetaData');
      st.state = 'STOPPED';
      break;
    case 'Play':
      st.state = 'PLAYING';
      break;
    case 'Pause':
      st.state = 'PAUSED_PLAYBACK';
      break;
    case 'Stop':
      st.state = 'STOPPED';
      break;
    case 'GetTransportInfo':
      out.addAll({'CurrentTransportState': st.state, 'CurrentTransportStatus': 'OK', 'CurrentSpeed': '1'});
      break;
    case 'GetPositionInfo':
      out.addAll({
        'Track': '1',
        'TrackDuration': '00:00:00',
        'TrackMetaData': xmlUnesc(st.metaEsc),
        'TrackURI': st.uri,
        'RelTime': '00:00:00',
        'AbsTime': '00:00:00',
        'RelCount': '0',
        'AbsCount': '0',
      });
      break;
    case 'GetMediaInfo':
      out.addAll({
        'NrTracks': st.uri.isEmpty ? '0' : '1',
        'MediaDuration': '00:00:00',
        'CurrentURI': st.uri,
        'CurrentURIMetaData': xmlUnesc(st.metaEsc),
        'NextURI': '',
        'NextURIMetaData': '',
        'PlayMedium': 'NETWORK',
        'RecordMedium': 'NOT_IMPLEMENTED',
        'WriteStatus': 'NOT_IMPLEMENTED',
      });
      break;
    case 'GetCurrentTransportActions':
      out['Actions'] = 'Play,Stop,Pause,Seek';
      break;
    case 'GetTransportSettings':
      out.addAll({'PlayMode': 'NORMAL', 'RecQualityMode': 'NOT_IMPLEMENTED'});
      break;
    case 'GetDeviceCapabilities':
      out.addAll({'PlayMedia': 'NETWORK', 'RecMedia': 'NOT_IMPLEMENTED', 'RecQualityModes': 'NOT_IMPLEMENTED'});
      break;
    case 'GetVolume':
      out['CurrentVolume'] = '${st.volume}';
      break;
    case 'SetVolume':
      st.volume = int.tryParse(v('DesiredVolume')) ?? st.volume;
      break;
    case 'GetMute':
      out['CurrentMute'] = st.mute ? '1' : '0';
      break;
    case 'SetMute':
      st.mute = v('DesiredMute') == '1' || v('DesiredMute').toLowerCase() == 'true';
      break;
    case 'GetProtocolInfo':
      out.addAll({'Source': '', 'Sink': kLearnSink});
      break;
    case 'GetCurrentConnectionIDs':
      out['ConnectionIDs'] = '0';
      break;
    case 'GetCurrentConnectionInfo':
      out.addAll({
        'RcsID': '0',
        'AVTransportID': '0',
        'ProtocolInfo': '',
        'PeerConnectionManager': '',
        'PeerConnectionID': '-1',
        'Direction': 'Input',
        'Status': 'OK',
      });
      break;
  }
  final a = out.entries.map((e) => '<${e.key}>${xmlEsc(e.value)}</${e.key}>').join();
  return '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
      '<s:Body><u:${action}Response xmlns:u="urn:schemas-upnp-org:service:$service:1">$a</u:${action}Response></s:Body></s:Envelope>';
}

String learnDescXml(String uuid) => '<?xml version="1.0" encoding="utf-8"?>'
    '<root xmlns="urn:schemas-upnp-org:device-1-0" xmlns:dlna="urn:schemas-dlna-org:device-1-0">'
    '<specVersion><major>1</major><minor>0</minor></specVersion><device>'
    '<deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>'
    '<friendlyName>A2R تعلّم</friendlyName><manufacturer>A2R</manufacturer><modelName>A2R Learn</modelName>'
    '<modelNumber>1</modelNumber><UDN>$uuid</UDN><dlna:X_DLNADOC>DMR-1.50</dlna:X_DLNADOC>'
    '<serviceList>'
    '${_learnSvc('AVTransport')}${_learnSvc('RenderingControl')}${_learnSvc('ConnectionManager')}'
    '</serviceList></device></root>';

String _learnSvc(String s) => '<service><serviceType>urn:schemas-upnp-org:service:$s:1</serviceType>'
    '<serviceId>urn:upnp-org:serviceId:$s</serviceId><SCPDURL>/learn/$s.xml</SCPDURL>'
    '<controlURL>/learn/$s/control</controlURL><eventSubURL>/learn/$s/event</eventSubURL></service>';

const Map<String, List<String>> _kLearnActions = {
  'AVTransport': [
    'SetAVTransportURI:InstanceID,CurrentURI,CurrentURIMetaData:',
    'SetNextAVTransportURI:InstanceID,NextURI,NextURIMetaData:',
    'GetMediaInfo:InstanceID:NrTracks,MediaDuration,CurrentURI,CurrentURIMetaData,NextURI,NextURIMetaData,PlayMedium,RecordMedium,WriteStatus',
    'GetTransportInfo:InstanceID:CurrentTransportState,CurrentTransportStatus,CurrentSpeed',
    'GetPositionInfo:InstanceID:Track,TrackDuration,TrackMetaData,TrackURI,RelTime,AbsTime,RelCount,AbsCount',
    'GetDeviceCapabilities:InstanceID:PlayMedia,RecMedia,RecQualityModes',
    'GetTransportSettings:InstanceID:PlayMode,RecQualityMode',
    'GetCurrentTransportActions:InstanceID:Actions',
    'Stop:InstanceID:',
    'Play:InstanceID,Speed:',
    'Pause:InstanceID:',
    'Seek:InstanceID,Unit,Target:',
    'Next:InstanceID:',
    'Previous:InstanceID:',
  ],
  'RenderingControl': [
    'ListPresets:InstanceID:CurrentPresetNameList',
    'SelectPreset:InstanceID,PresetName:',
    'GetVolume:InstanceID,Channel:CurrentVolume',
    'SetVolume:InstanceID,Channel,DesiredVolume:',
    'GetMute:InstanceID,Channel:CurrentMute',
    'SetMute:InstanceID,Channel,DesiredMute:',
  ],
  'ConnectionManager': [
    'GetProtocolInfo::Source,Sink',
    'GetCurrentConnectionIDs::ConnectionIDs',
    'GetCurrentConnectionInfo:ConnectionID:RcsID,AVTransportID,ProtocolInfo,PeerConnectionManager,PeerConnectionID,Direction,Status',
  ],
};

/// وصف الخدمة (SCPD) — متغير حالة لكل اسم معامل (string) علشان أي برنامج كاست يقبله
String learnScpd(String service) {
  final acts = _kLearnActions[service] ?? const [];
  final vars = <String>{};
  final sb = StringBuffer('<?xml version="1.0" encoding="utf-8"?><scpd xmlns="urn:schemas-upnp-org:service-1-0">'
      '<specVersion><major>1</major><minor>0</minor></specVersion><actionList>');
  for (final a in acts) {
    final p = a.split(':');
    sb.write('<action><name>${p[0]}</name><argumentList>');
    for (final (dir, list) in [('in', p[1]), ('out', p[2])]) {
      for (final n in list.split(',').where((x) => x.isNotEmpty)) {
        vars.add('A_ARG_$n');
        sb.write('<argument><name>$n</name><direction>$dir</direction><relatedStateVariable>A_ARG_$n</relatedStateVariable></argument>');
      }
    }
    sb.write('</argumentList></action>');
  }
  sb.write('</actionList><serviceStateTable>');
  sb.write('<stateVariable sendEvents="yes"><name>LastChange</name><dataType>string</dataType></stateVariable>');
  for (final v in vars) {
    sb.write('<stateVariable sendEvents="no"><name>$v</name><dataType>string</dataType></stateVariable>');
  }
  sb.write('</serviceStateTable></scpd>');
  return sb.toString();
}

/// رد على M-SEARCH (لو نوع البحث يخصنا) — أو null
List<String> learnSsdpReplies(String msg, String location, String uuid) {
  final first = msg.split(RegExp(r'\r?\n')).first.toUpperCase();
  if (!first.startsWith('M-SEARCH')) return const [];
  final st = parseHttpHeaders(msg)['ST'] ?? '';
  const types = [
    'upnp:rootdevice',
    'urn:schemas-upnp-org:device:MediaRenderer:1',
    'urn:schemas-upnp-org:service:AVTransport:1',
    'urn:schemas-upnp-org:service:RenderingControl:1',
    'urn:schemas-upnp-org:service:ConnectionManager:1',
  ];
  final List<String> hit;
  if (st == 'ssdp:all') {
    hit = types;
  } else if (st == uuid) {
    hit = [uuid];
  } else if (types.contains(st)) {
    hit = [st];
  } else {
    return const [];
  }
  return hit
      .map((t) => 'HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nDATE: ${HttpDate.format(DateTime.now())}\r\nEXT:\r\n'
          'LOCATION: $location\r\nSERVER: Android/1.0 UPnP/1.0 A2RLearn/1.0\r\nST: $t\r\n'
          'USN: ${t == uuid ? uuid : '$uuid::$t'}\r\n\r\n')
      .toList();
}

/// اللي اتسجّل من آخر صورة WVC بعتها
class LearnedCast {
  String uri = '';
  String metaEsc = '';
  bool sentPlay = false;
  final List<String> actions = [];
  /// هيدرز رد سيرفر WVC بالحروف زي ما هي (من HEAD)
  Map<String, String> headHeaders = {};
  String headStatus = '';
  String getStatus = '';
  Map<String, String> getHeaders = {};

  String get meta => xmlUnesc(metaEsc);
  String? get protocolInfo => RegExp(r'protocolInfo="([^"]*)"').firstMatch(meta)?.group(1);
  String? get upnpClass => RegExp(r'<upnp:class>([^<]*)</upnp:class>').firstMatch(meta)?.group(1);
  bool get looksImage => (protocolInfo ?? '').contains('image/') || (upnpClass ?? '').contains('imageItem') || _hdr('content-type').startsWith('image');

  String _hdr(String name) {
    for (final m in [headHeaders, getHeaders]) {
      for (final e in m.entries) {
        if (e.key.toLowerCase() == name) return e.value;
      }
    }
    return '';
  }

  /// نحوّلها لطريقة إرسال نستخدمها مع الريسيفر الحقيقي
  ImgVariant toVariant() {
    var tmpl = meta;
    if (uri.isNotEmpty) tmpl = tmpl.replaceAll(xmlEsc(uri), '{URL}').replaceAll(uri, '{URL}');
    final hdrs = <String, String>{};
    for (final m in [getHeaders, headHeaders]) {
      for (final e in m.entries) {
        final k = e.key.toLowerCase();
        if (k.endsWith('.dlna.org') || k == 'captioninfo.sec' || k == 'realtimeinfo.dlna.org') hdrs[e.key] = e.value;
      }
    }
    final path = Uri.tryParse(uri)?.path ?? '';
    final hasExt = RegExp(r'\.(jpe?g|png|gif|webp)$', caseSensitive: false).hasMatch(path);
    return ImgVariant('wvc', 'طريقة Web Video Caster',
        meta: metaEsc.trim().isNotEmpty,
        pi: 'custom',
        customPi: protocolInfo,
        customMeta: tmpl.trim().isEmpty ? null : tmpl,
        hdr: 'custom',
        customHeaders: hdrs,
        play: sentPlay ? 'wait' : 'none',
        url: hasExt ? 'ext' : 'noext');
  }

  String summaryAr() {
    final b = StringBuffer();
    b.writeln('الأوامر: ${actions.join(' ← ')}');
    b.writeln('الرابط: $uri');
    b.writeln('protocolInfo: ${protocolInfo ?? '(مفيش وصف)'}');
    b.writeln('upnp:class: ${upnpClass ?? '-'}');
    b.writeln('Play: ${sentPlay ? 'اتبعت' : 'متبعتش'}');
    if (headStatus.isNotEmpty) b.writeln('HEAD: $headStatus');
    headHeaders.forEach((k, v) => b.writeln('  $k: $v'));
    if (getStatus.isNotEmpty) b.writeln('GET: $getStatus');
    getHeaders.forEach((k, v) => b.writeln('  $k: $v'));
    return b.toString().trim();
  }
}

/// يقرا الهيدرز بالحروف زي ما هي (HttpClient بتاع دارت بيصغّرها، فبنستخدم socket)
Future<(String, Map<String, String>)> rawHttpHeaders(String url, String method, {Map<String, String> extra = const {}}) async {
  final u = Uri.parse(url);
  final s = await Socket.connect(u.host, u.hasPort ? u.port : 80, timeout: const Duration(seconds: 5));
  try {
    final path = u.hasQuery ? '${u.path}?${u.query}' : (u.path.isEmpty ? '/' : u.path);
    final req = StringBuffer('$method $path HTTP/1.1\r\nHost: ${u.host}:${u.port}\r\nUser-Agent: $kDlnaUa\r\n'
        'getcontentFeatures.dlna.org: 1\r\nConnection: close\r\n');
    extra.forEach((k, v) => req.write('$k: $v\r\n'));
    req.write('\r\n');
    s.write(req.toString());
    await s.flush();
    final buf = <int>[];
    final done = Completer<void>();
    late StreamSubscription sub;
    sub = s.listen((d) {
      buf.addAll(d);
      if (latin1.decode(buf, allowInvalid: true).contains('\r\n\r\n') && !done.isCompleted) done.complete();
    }, onDone: () {
      if (!done.isCompleted) done.complete();
    }, onError: (_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future.timeout(const Duration(seconds: 6), onTimeout: () {});
    await sub.cancel();
    return parseRawHead(utf8.decode(buf, allowMalformed: true));
  } finally {
    s.destroy();
  }
}

(String, Map<String, String>) parseRawHead(String txt) {
  final end = txt.indexOf('\r\n\r\n');
  final head = end >= 0 ? txt.substring(0, end) : txt;
  final lines = head.split('\r\n');
  final out = <String, String>{};
  for (final l in lines.skip(1)) {
    final i = l.indexOf(':');
    if (i > 0) out[l.substring(0, i).trim()] = l.substring(i + 1).trim();
  }
  return (lines.isEmpty ? '' : lines.first.trim(), out);
}

/// الشاشة الوهمية «A2R تعلّم»: Web Video Caster يشوفها كشاشة DLNA، ولما يبعتلها صورة بنسجّل هو بيبعت إيه بالظبط
class LearnRenderer extends ChangeNotifier {
  LearnRenderer._();
  static final LearnRenderer I = LearnRenderer._();
  bool on = false;
  String status = '';
  HttpServer? _http;
  RawDatagramSocket? _udp;
  Timer? _alive;
  String _location = '';
  final LearnState st = LearnState();
  LearnedCast? last;
  final List<String> events = [];
  String get uuid => 'uuid:a2r-learn-${md5Hex(Store.clientUuid).substring(0, 12)}';

  void _ev(String s) {
    events.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} $s');
    if (events.length > 40) events.removeLast();
    AppLog.add('LEARN', s);
    notifyListeners();
  }

  Future<void> start() async {
    if (on) return;
    final ip = await phoneIpFor(Store.receiverIp);
    if (ip == null || !_isLan(ip)) {
      status = 'الموبايل لازم يكون على واي فاي البيت';
      notifyListeners();
      return;
    }
    try {
      _http = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _http!.autoCompress = false;
      _http!.listen(_onHttp, onError: (e) => AppLog.add('LEARN', 'http error $e'));
      _location = 'http://$ip:${_http!.port}/learn/desc.xml';
      await Native.multicastLock(true);
      try {
        _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 1900, reuseAddress: true, reusePort: true);
      } catch (_) {
        _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 1900, reuseAddress: true);
      }
      _udp!.multicastLoopback = true;
      try {
        _udp!.joinMulticast(InternetAddress('239.255.255.250'));
      } catch (e) {
        AppLog.add('LEARN', 'joinMulticast ✗ $e');
      }
      _udp!.listen(_onUdp);
      on = true;
      status = 'شغالة: افتح Web Video Caster ودوّر على شاشة «A2R تعلّم» وابعتلها صورة';
      _ev('بدأت — $_location');
      _notify('ssdp:alive');
      _alive = Timer.periodic(const Duration(seconds: 8), (_) => _notify('ssdp:alive'));
    } catch (e) {
      status = 'مقدرتش أشغّلها: $e';
      AppLog.add('LEARN', 'start ✗ $e');
      await stop();
    }
    notifyListeners();
  }

  static bool _isLan(String ip) =>
      ip.startsWith('192.168.') || ip.startsWith('10.') || RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip);

  void _notify(String nts) {
    final u = _udp;
    if (u == null) return;
    const types = [
      'upnp:rootdevice',
      'urn:schemas-upnp-org:device:MediaRenderer:1',
      'urn:schemas-upnp-org:service:AVTransport:1',
      'urn:schemas-upnp-org:service:RenderingControl:1',
      'urn:schemas-upnp-org:service:ConnectionManager:1',
    ];
    for (final t in [uuid, ...types]) {
      final msg = 'NOTIFY * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nCACHE-CONTROL: max-age=1800\r\nLOCATION: $_location\r\n'
          'NT: $t\r\nNTS: $nts\r\nSERVER: Android/1.0 UPnP/1.0 A2RLearn/1.0\r\nUSN: ${t == uuid ? uuid : '$uuid::$t'}\r\n\r\n';
      try {
        u.send(utf8.encode(msg), InternetAddress('239.255.255.250'), 1900);
      } catch (_) {}
    }
  }

  void _onUdp(RawSocketEvent e) {
    if (e != RawSocketEvent.read) return;
    final d = _udp?.receive();
    if (d == null) return;
    final msg = utf8.decode(d.data, allowMalformed: true);
    final replies = learnSsdpReplies(msg, _location, uuid);
    if (replies.isEmpty) return;
    AppLog.add('LEARN', 'M-SEARCH من ${d.address.address}:${d.port} ST=${parseHttpHeaders(msg)['ST']}');
    Future.delayed(const Duration(milliseconds: 60), () {
      for (final r in replies) {
        try {
          _udp?.send(utf8.encode(r), d.address, d.port);
        } catch (_) {}
      }
    });
  }

  Future<void> _onHttp(HttpRequest q) async {
    final res = q.response;
    final p = q.uri.path;
    final from = q.connectionInfo?.remoteAddress.address ?? '?';
    try {
      if (!_isLan(from) && from != '127.0.0.1') {
        res.statusCode = 403;
        await res.close();
        return;
      }
      if (q.method == 'SUBSCRIBE' || q.method == 'UNSUBSCRIBE') {
        res.headers.set('SID', 'uuid:a2r-learn-sub-1', preserveHeaderCase: true);
        res.headers.set('TIMEOUT', 'Second-1800', preserveHeaderCase: true);
        await res.close();
        return;
      }
      if (p == '/learn/desc.xml') {
        _ev('${q.headers.value('user-agent') ?? from} فتح وصف الشاشة');
        return await _xml(res, learnDescXml(uuid));
      }
      final m = RegExp(r'^/learn/(\w+)\.xml$').firstMatch(p);
      if (m != null) return await _xml(res, learnScpd(m[1]!));
      final c = RegExp(r'^/learn/(\w+)/control$').firstMatch(p);
      if (c != null && q.method == 'POST') {
        final body = await utf8.decodeStream(q);
        final (svc0, action) = parseSoapAction(q.headers.value('soapaction'), body);
        final svc = svc0.isEmpty ? c[1]! : svc0;
        AppLog.add('LEARN', '← $action\n${body.length > 3000 ? body.substring(0, 3000) : body}');
        _record(action, body);
        return await _xml(res, learnSoapReply(svc, action, body, st));
      }
      res.statusCode = 404;
      await res.close();
    } catch (e) {
      AppLog.add('LEARN', 'http ✗ $e');
      try {
        await res.close();
      } catch (_) {}
    }
  }

  Future<void> _xml(HttpResponse res, String xml) async {
    final b = utf8.encode(xml);
    res.headers.set('Content-Type', 'text/xml; charset="utf-8"', preserveHeaderCase: true);
    res.headers.set('Server', 'Android/1.0 UPnP/1.0 A2RLearn/1.0', preserveHeaderCase: true);
    res.contentLength = b.length;
    res.add(b);
    await res.close();
  }

  void _record(String action, String body) {
    if (action.startsWith('Get')) return;
    if (action == 'SetAVTransportURI') {
      final lc = LearnedCast();
      lc.actions.add(action);
      lc.uri = xmlUnesc(soapValue(body, 'CurrentURI') ?? '').trim();
      lc.metaEsc = soapValue(body, 'CurrentURIMetaData') ?? '';
      last = lc;
      _ev('WVC بعت رابط: ${lc.uri}');
      AppLog.add('LEARN', 'SetAVTransportURI كامل:\n$body');
      _probe(lc);
    } else if (last != null) {
      last!.actions.add(action);
      if (action == 'Play') last!.sentPlay = true;
      _ev('WVC بعت $action');
    } else {
      _ev('WVC بعت $action');
    }
    notifyListeners();
  }

  Future<void> _probe(LearnedCast lc) async {
    if (!lc.uri.startsWith('http')) return;
    try {
      final (s, h) = await rawHttpHeaders(lc.uri, 'HEAD');
      lc.headStatus = s;
      lc.headHeaders = h;
      AppLog.add('LEARN', 'HEAD ${lc.uri} → $s\n${h.entries.map((e) => '${e.key}: ${e.value}').join('\n')}');
    } catch (e) {
      lc.headStatus = 'فشل: $e';
    }
    try {
      final (s, h) = await rawHttpHeaders(lc.uri, 'GET');
      lc.getStatus = s;
      lc.getHeaders = h;
      AppLog.add('LEARN', 'GET ${lc.uri} → $s\n${h.entries.map((e) => '${e.key}: ${e.value}').join('\n')}');
    } catch (e) {
      lc.getStatus = 'فشل: $e';
    }
    AppLog.add('LEARN', 'الخلاصة:\n${lc.summaryAr()}');
    notifyListeners();
  }

  Future<void> stop() async {
    _alive?.cancel();
    _alive = null;
    if (_udp != null) {
      _notify('ssdp:byebye');
      _udp?.close();
      _udp = null;
      await Native.multicastLock(false);
    }
    await _http?.close(force: true);
    _http = null;
    if (on) _ev('وقفت');
    on = false;
    status = '';
    notifyListeners();
  }
}

class ImgStore {
  static String? get preferred => Store.p.getString('img_variant');
  static set preferred(String? v) => v == null ? Store.p.remove('img_variant') : Store.p.setString('img_variant', v);
  static ImgVariant? get learned {
    final s = Store.p.getString('img_learned');
    if (s == null) return null;
    try {
      return ImgVariant.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  static set learned(ImgVariant? v) => v == null ? Store.p.remove('img_learned') : Store.p.setString('img_learned', jsonEncode(v.toJson()));
}

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});
  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final lr = LearnRenderer.I;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    lr.addListener(_up);
  }

  void _up() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    lr.removeListener(_up);
    lr.stop(); // بتقفل لوحدها أول ما تخرج من الشاشة
    super.dispose();
  }

  Future<void> _copy() async {
    final lc = lr.last;
    if (lc == null) return;
    final v = lc.toVariant();
    ImgStore.learned = v;
    ImgStore.preferred = null;
    CastState.I.dlnaImagesOk = null;
    AppLog.add('LEARN', 'اتحفظت طريقة WVC: ${jsonEncode(v.toJson())}');
    if (mounted) toast(context, 'اتحفظت — الصور الجاية هتتبعت للريسيفر بطريقة Web Video Caster الأول');
    setState(() {});
  }

  /// نبعت نفس أوامر WVC بالظبط (بنفس رابط WVC) للريسيفر الحقيقي
  Future<void> _replay() async {
    final lc = lr.last;
    final c = CastState.I.client;
    if (lc == null) return;
    if (c == null) {
      toast(context, 'اختار الريسيفر في الكاست الأول');
      return;
    }
    setState(() => sending = true);
    try {
      try {
        await c.av('Stop');
      } catch (_) {}
      await c.av('SetAVTransportURI', {'CurrentURI': lc.uri, 'CurrentURIMetaData': lc.meta});
      if (lc.sentPlay) {
        await Future.delayed(const Duration(milliseconds: 700));
        try {
          await c.play();
        } catch (e) {
          AppLog.add('LEARN', 'replay Play ✗ $e');
        }
      }
      if (mounted) toast(context, 'اتبعت للريسيفر بنفس أوامر WVC — بص على الشاشة (وسيب WVC مفتوح علشان الرابط بتاعه)');
    } catch (e) {
      if (mounted) toast(context, 'الريسيفر رفض: ${castErrorAr(e)}');
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final lc = lr.last;
    final saved = ImgStore.learned;
    return Scaffold(
      appBar: AppBar(title: const Text('تعلّم من Web Video Caster')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Text(
            'الفكرة: الموبايل بيعمل نفسه شاشة اسمها «A2R تعلّم». افتح Web Video Caster، اختار الشاشة دي، وابعت صورة. '
            'هنسجّل هو بيبعت إيه بالظبط، وبعدين نبعت الصور للريسيفر بنفس الطريقة.\n'
            'شغالة على واي فاي البيت بس، وبتقفل لوحدها لما تخرج من الصفحة.',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        SwitchListTile(
          value: lr.on,
          title: const Text('شغّل الشاشة الوهمية'),
          subtitle: Text(lr.status.isEmpty ? 'مقفولة' : lr.status, style: const TextStyle(fontSize: 12)),
          onChanged: (v) => v ? lr.start() : lr.stop(),
        ),
        if (saved != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: kGold),
              title: const Text('في طريقة WVC محفوظة'),
              subtitle: Text(saved.customPi ?? '-', style: const TextStyle(fontSize: 11)),
              trailing: TextButton(
                  onPressed: () => setState(() => ImgStore.learned = null), child: const Text('امسحها')),
            ),
          ),
        if (lc != null) ...[
          const SizedBox(height: 8),
          Text(lc.looksImage ? 'اتسجّلت صورة من WVC ✓' : 'اتسجّل ملف من WVC (مش باين إنه صورة — ابعت صورة)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: kGold)),
          const SizedBox(height: 6),
          SelectableText(lc.summaryAr(), style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: _copy, icon: const Icon(Icons.copy_all), label: const Text('انسخ الطريقة دي')),
            FilledButton.tonalIcon(
                onPressed: sending ? null : _replay,
                icon: const Icon(Icons.cast),
                label: const Text('ابعتها للريسيفر بنفس أوامر WVC')),
          ]),
        ],
        const SizedBox(height: 12),
        if (lr.events.isNotEmpty) const Text('اللي حصل:', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final e in lr.events) Text(e, style: const TextStyle(fontSize: 11, color: kMuted)),
        const SizedBox(height: 12),
        const Text('بعد ما تخلص ابعتلي السجل (من شاشة السجل ← مشاركة).', style: TextStyle(fontSize: 12, color: kMuted)),
      ]),
    );
  }
}

// ======== names_v5.dart ========
// أسماء الأجهزة: الراوتر بيرجّع "--" لأجهزة كتير، فبنكمّل: NetBIOS ← mDNS ← DNS عكسي ← الشركة + النوع

/// أسماء مالهاش معنى من الراوتر/الشبكة
bool isBadHostName(String? s) {
  final t = (s ?? '').trim().toLowerCase();
  if (t.isEmpty) return true;
  const bad = {'--', '-', '*', '?', 'unknown', 'null', '(null)', 'none', 'n/a', 'localhost', 'anonymous', 'android', 'espressif'};
  if (bad.contains(t)) return true;
  if (RegExp(r'^[-*_.\s]+$').hasMatch(t)) return true;
  if (RegExp(r'^\d{1,3}([.-]\d{1,3}){3}$').hasMatch(t)) return true; // عنوان IP مش اسم
  if (RegExp(r'^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$').hasMatch(t)) return true; // MAC مش اسم
  return false;
}

/// نضّف الاسم: شيل .local و .lan والدومين بتاع الراوتر
String cleanHostName(String s) {
  var t = s.trim();
  if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  for (final suf in ['.local', '.lan', '.home', '.localdomain', '.router']) {
    if (t.toLowerCase().endsWith(suf)) t = t.substring(0, t.length - suf.length);
  }
  return t;
}

/// اسم الجهاز لما مفيش اسم: «موبايل Samsung» / «كمبيوتر» / «(اسم مش معروف)»
String fallbackDeviceName(String type, String vendor) {
  final v = vendor.startsWith('MAC عشوائي') ? '' : vendor.split(RegExp(r'[,(]')).first.trim();
  final shortV = v.split(' ').take(2).join(' ');
  final typed = type == 'جهاز' || type.isEmpty ? '' : type;
  if (typed.isNotEmpty && shortV.isNotEmpty) return '$typed $shortV';
  if (shortV.isNotEmpty) return 'جهاز $shortV';
  if (typed.isNotEmpty) return typed;
  return '(اسم مش معروف)';
}

/// 192.168.7.5 → 5.7.168.192.in-addr.arpa
String reverseArpa(String ip) => '${ip.split('.').reversed.join('.')}.in-addr.arpa';

/// سؤال mDNS (PTR) — qu=true يطلب الرد مباشر للموبايل
List<int> mdnsPtrQuery(String name, {int id = 0, bool qu = true}) {
  final b = BytesBuilder();
  b.add([id >> 8 & 0xFF, id & 0xFF, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]);
  for (final l in name.split('.')) {
    final e = utf8.encode(l);
    b.addByte(e.length);
    b.add(e);
  }
  b.addByte(0);
  b.add([0x00, 0x0C, qu ? 0x80 : 0x00, 0x01]);
  return b.toBytes();
}

/// يقرا اسم DNS (فيه ضغط بالمؤشرات)
(String, int) _dnsName(List<int> d, int off) {
  final parts = <String>[];
  var jumped = false, ret = off, guard = 0;
  while (off < d.length && guard++ < 64) {
    final l = d[off];
    if (l == 0) {
      off++;
      break;
    }
    if (l & 0xC0 == 0xC0) {
      if (off + 1 >= d.length) break;
      if (!jumped) ret = off + 2;
      off = ((l & 0x3F) << 8) | d[off + 1];
      jumped = true;
      continue;
    }
    if (off + 1 + l > d.length) break;
    parts.add(utf8.decode(d.sublist(off + 1, off + 1 + l), allowMalformed: true));
    off += 1 + l;
  }
  return (parts.join('.'), jumped ? ret : off);
}

/// رد mDNS/DNS → أول اسم PTR يخص العنوان المطلوب (أو أي A record اسمه .local للعنوان ده)
String? parseMdnsPtr(List<int> d, String arpa) {
  if (d.length < 12) return null;
  final qd = d[4] << 8 | d[5], an = d[6] << 8 | d[7], ns = d[8] << 8 | d[9], ar = d[10] << 8 | d[11];
  var off = 12;
  for (var i = 0; i < qd; i++) {
    off = _dnsName(d, off).$2 + 4;
  }
  final ip = arpa.replaceAll('.in-addr.arpa', '').split('.').reversed.join('.');
  String? aName;
  for (var i = 0; i < an + ns + ar && off + 10 <= d.length; i++) {
    final (name, o) = _dnsName(d, off);
    off = o;
    if (off + 10 > d.length) break;
    final type = d[off] << 8 | d[off + 1];
    final rdlen = d[off + 8] << 8 | d[off + 9];
    final rd = off + 10;
    if (rd + rdlen > d.length) break;
    if (type == 12 && name.toLowerCase() == arpa.toLowerCase()) {
      final n = _dnsName(d, rd).$1;
      if (n.isNotEmpty) return n;
    }
    if (type == 1 && rdlen == 4 && d.sublist(rd, rd + 4).join('.') == ip && name.isNotEmpty) aName ??= name;
    off = rd + rdlen;
  }
  return aName;
}

/// mDNS: بنسأل الجهاز نفسه على 5353 + المجموعة 224.0.0.251 (الرد بييجي للموبايل مباشر)
Future<String?> mdnsName(String ip, {Duration timeout = const Duration(milliseconds: 1200)}) async {
  RawDatagramSocket? s;
  try {
    s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final arpa = reverseArpa(ip);
    final q = mdnsPtrQuery(arpa, id: 0);
    for (final to in [ip, '224.0.0.251']) {
      try {
        s.send(q, InternetAddress(to), 5353);
      } catch (_) {}
    }
    final c = Completer<String?>();
    final sub = s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final dg = s!.receive();
      if (dg == null || c.isCompleted) return;
      final n = parseMdnsPtr(dg.data, arpa);
      if (n != null && !isBadHostName(cleanHostName(n))) c.complete(cleanHostName(n));
    }, onError: (_) {});
    final r = await c.future.timeout(timeout, onTimeout: () => null);
    await sub.cancel();
    return r;
  } catch (_) {
    return null;
  } finally {
    s?.close();
  }
}

/// DNS عكسي عن طريق الراوتر مباشرة (port 53) — بعض الراوترات بتعرف أسماء DHCP
Future<String?> routerDnsName(String ip, String routerIp, {Duration timeout = const Duration(milliseconds: 900)}) async {
  RawDatagramSocket? s;
  try {
    s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final arpa = reverseArpa(ip);
    final q = mdnsPtrQuery(arpa, id: 0x5a5a, qu: false);
    q[2] = 0x01; // recursion desired
    s.send(q, InternetAddress(routerIp), 53);
    final c = Completer<String?>();
    final sub = s.listen((e) {
      if (e != RawSocketEvent.read) return;
      final dg = s!.receive();
      if (dg == null || c.isCompleted) return;
      final n = parseMdnsPtr(dg.data, arpa);
      c.complete(n == null || isBadHostName(cleanHostName(n)) ? null : cleanHostName(n));
    }, onError: (_) {});
    final r = await c.future.timeout(timeout, onTimeout: () => null);
    await sub.cancel();
    return r;
  } catch (_) {
    return null;
  } finally {
    s?.close();
  }
}

/// كاش الأسماء لكل MAC (علشان الاسم ميختفيش لو مرة الراوتر رجّع "--")
class NameCache {
  static Map<String, Map<String, String>> get all {
    try {
      return (jsonDecode(Store.p.getString('name_cache') ?? '{}') as Map)
          .map((k, v) => MapEntry('$k', Map<String, String>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  static ({String name, String src})? of(String key) {
    final e = all[key];
    if (e == null || isBadHostName(e['n'])) return null;
    return (name: e['n']!, src: e['s'] ?? '');
  }

  static Future<void> put(String key, String name, String src) async {
    if (key.isEmpty || isBadHostName(name)) return;
    final a = all;
    a[key] = {'n': name, 's': src};
    await Store.p.setString('name_cache', jsonEncode(a));
  }
}

const Map<String, String> kNameSrcAr = {
  'router': 'من الراوتر',
  'netbios': 'من ويندوز (NetBIOS)',
  'mdns': 'من mDNS',
  'dns': 'من DNS الراوتر',
  'cache': 'محفوظ من قبل',
  'custom': 'اسمك',
};

/// يدوّر على أسماء الأجهزة اللي ملهاش اسم — كله بالتوازي وبحد أقصى للوقت
Future<int> resolveMissingNames(Iterable<LanHost> hosts, {String? routerIp}) async {
  var found = 0;
  await Future.wait(hosts.where((h) => isBadHostName(h.name) && h.ip.isNotEmpty).map((h) async {
    final key = h.mac.isNotEmpty ? h.mac : h.ip;
    String? n;
    var src = '';
    final results = await Future.wait([
      netbiosName(h.ip),
      mdnsName(h.ip),
      if (routerIp != null) routerDnsName(h.ip, routerIp) else Future.value(null),
      reverseName(h.ip),
    ]).timeout(const Duration(seconds: 3), onTimeout: () => [null, null, null, null]);
    const srcs = ['netbios', 'mdns', 'dns', 'dns'];
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r != null && !isBadHostName(cleanHostName(r))) {
        n = cleanHostName(r);
        src = srcs[i];
        break;
      }
    }
    if (n == null) {
      final c = NameCache.of(key);
      if (c != null) {
        n = c.name;
        src = 'cache';
      }
    } else {
      await NameCache.put(key, n, src);
    }
    AppLog.add('NAMES', '${h.ip} ${h.mac} → ${n ?? '(مفيش)'} ${src.isEmpty ? '' : '[$src]'} netbios=${results[0]} mdns=${results[1]} dns=${results[2]} rev=${results[3]}');
    if (n != null) {
      h.name = n;
      h.nameSrc = src;
      found++;
    }
  }));
  return found;
}

// ======== features_v5.dart ========
// v5: DNS الراوتر، سجل الإشارة/الانقطاعات/السرعة، مكان الراوتر، مراقبة الأجهزة، سجل الكاست، مؤقت/تكرار،
// المشاركة من أي تطبيق، مجموعات القنوات، إضافات الكمبيوتر، نسخة احتياطية، قفل بالرقم السري

// ---------------- أدوات عامة ----------------
bool isIpv4(String s) {
  final p = s.trim().split('.');
  if (p.length != 4) return false;
  for (final x in p) {
    if (x.isEmpty || x.length > 3 || !RegExp(r'^\d+$').hasMatch(x)) return false;
    final n = int.parse(x);
    if (n > 255) return false;
    if (x.length > 1 && x.startsWith('0')) return false;
  }
  return p.first != '0';
}

String dayKeyOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String hhmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String durAr(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} ثانية';
  if (d.inMinutes < 60) return '${d.inMinutes} دقيقة';
  final h = d.inHours, m = d.inMinutes % 60;
  return m == 0 ? '$h ساعة' : '$h ساعة و$m دقيقة';
}

List<dynamic> _jsonList(String key) {
  try {
    final v = jsonDecode(Store.p.getString(key) ?? '[]');
    return v is List ? v : [];
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _jsonMap(String key) {
  try {
    final v = jsonDecode(Store.p.getString(key) ?? '{}');
    return v is Map ? Map<String, dynamic>.from(v) : {};
  } catch (_) {
    return {};
  }
}

// ---------------- DNS الراوتر ----------------
// الدليل: مكتبة zte-cpe-rs (اتجربت على ZTE MF289F) وسكريبت Miononno المشهور لراوترات ZTE:
//   goformId=ROUTER_DNS_SETTING  dns_mode=manual|auto  prefer_dns_manual  standby_dns_manual  (+AD)
// وقراية القيم: cmd=dns_mode,prefer_dns_manual,standby_dns_manual
// مش متجرّب على MF286R1 بتاع أحمد → «تجريبي»: بنقرا الأول، وبعد التغيير بنقرا تاني ونقارن، والقديم محفوظ للتراجع.
class DnsPreset {
  final String name, primary, secondary, note;
  const DnsPreset(this.name, this.primary, this.secondary, [this.note = '']);
}

const List<DnsPreset> kDnsPresets = [
  DnsPreset('Google', '8.8.8.8', '8.8.4.4', 'سريع ومستقر'),
  DnsPreset('Cloudflare', '1.1.1.1', '1.0.0.1', 'سريع'),
  DnsPreset('AdGuard', '94.140.14.14', '94.140.15.15', 'يمنع إعلانات'),
  DnsPreset('Cloudflare Family', '1.1.1.3', '1.0.0.3', 'يحجب مواقع الكبار'),
  DnsPreset('Quad9', '9.9.9.9', '149.112.112.112', 'بيحجب مواقع ضارة'),
];

const List<String> kDnsReadCmds = ['dns_mode', 'prefer_dns_manual', 'standby_dns_manual', 'prefer_dns_auto', 'standby_dns_auto', 'wan_ipaddr'];

/// (الوضع، الأساسي، الاحتياطي) من رد الراوتر
({String mode, String primary, String secondary, bool supported}) parseRouterDns(Map<String, dynamic> j) {
  final mode = '${j['dns_mode'] ?? ''}'.trim().toLowerCase();
  final manual = mode == 'manual';
  final p = '${j[manual ? 'prefer_dns_manual' : 'prefer_dns_auto'] ?? ''}'.trim();
  final s = '${j[manual ? 'standby_dns_manual' : 'standby_dns_auto'] ?? ''}'.trim();
  return (mode: mode, primary: p, secondary: s, supported: mode == 'manual' || mode == 'auto');
}

Map<String, String> routerDnsFields(String? primary, String? secondary) => {
      'dns_mode': primary == null ? 'auto' : 'manual',
      'prefer_dns_manual': primary ?? '',
      'standby_dns_manual': secondary ?? '',
    };

/// القراية بعد التغيير طابقت المطلوب؟
bool routerDnsApplied(Map<String, dynamic> j, String? primary, String? secondary) {
  final r = parseRouterDns(j);
  if (primary == null) return r.mode == 'auto';
  return r.mode == 'manual' && '${j['prefer_dns_manual'] ?? ''}'.trim() == primary && '${j['standby_dns_manual'] ?? ''}'.trim() == (secondary ?? '');
}

String dnsLabel(String mode, String p, String s) {
  if (mode == 'auto') return 'تلقائي من الشبكة${p.isNotEmpty ? ' ($p${s.isNotEmpty ? ' / $s' : ''})' : ''}';
  if (mode == 'manual') {
    final k = kDnsPresets.where((x) => x.primary == p).firstOrNull;
    return '${k?.name ?? 'يدوي'}: $p${s.isNotEmpty ? ' / $s' : ''}';
  }
  return 'مش معروف';
}

class RouterDnsPage extends StatefulWidget {
  final ZteRouter router;
  const RouterDnsPage({super.key, required this.router});
  @override
  State<RouterDnsPage> createState() => _RouterDnsPageState();
}

class _RouterDnsPageState extends State<RouterDnsPage> {
  Map<String, dynamic> raw = {};
  bool loading = true, busy = false;
  String msg = '';
  final pC = TextEditingController(), sC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    setState(() => loading = true);
    try {
      raw = await widget.router.get(kDnsReadCmds);
      AppLog.add('DNS', 'قراية: ${jsonEncode(raw)}');
    } catch (e) {
      msg = 'مقدرتش أقرا الـ DNS: $e';
    }
    if (mounted) setState(() => loading = false);
  }

  ({String? p, String? s})? get _prev {
    final m = _jsonMap('dns_prev');
    if (m.isEmpty) return null;
    return (p: m['p'] as String?, s: m['s'] as String?);
  }

  Future<void> _apply(String? p, String? s, {bool undo = false}) async {
    if (p != null && (!isIpv4(p) || (s != null && s.isNotEmpty && !isIpv4(s)))) {
      toast(context, 'اكتب عنوان صحيح زي 8.8.8.8');
      return;
    }
    final target = p == null ? 'تلقائي من الشبكة' : '$p${(s ?? '').isNotEmpty ? ' / $s' : ''}';
    if (!await confirm(context, 'تغيّر DNS الراوتر لـ $target؟\n\nده هيأثر على كل الأجهزة. الأمر ده «تجريبي» على راوترك — هقرا القيمة بعد التغيير وأقولك لو اتطبقت، وتقدر ترجع بدوسة.')) return;
    final cur = parseRouterDns(raw);
    setState(() => busy = true);
    try {
      if (!undo) {
        await Store.p.setString('dns_prev', jsonEncode(cur.mode == 'manual' ? {'p': '${raw['prefer_dns_manual'] ?? ''}', 's': '${raw['standby_dns_manual'] ?? ''}'} : {'p': null, 's': null}));
      }
      final res = await widget.router.set('ROUTER_DNS_SETTING', routerDnsFields(p, p == null ? null : (s ?? '')));
      AppLog.add('DNS', 'رد التغيير: ${jsonEncode(res)}');
      await Future.delayed(const Duration(seconds: 2));
      raw = await widget.router.get(kDnsReadCmds);
      AppLog.add('DNS', 'قراية بعد التغيير: ${jsonEncode(raw)}');
      final ok = routerDnsApplied(raw, p, p == null ? null : (s ?? ''));
      msg = ok
          ? 'اتطبق ✓ — الأجهزة هتاخد الـ DNS الجديد لما تفصل وتوصل الواي فاي (أو بعد شوية)'
          : 'الراوتر رد بـ «${res['result'] ?? '?'}» بس القراية مش مطابقة — يمكن الفيرموير ده مش بيقبل الأمر. جرّب من صفحة الراوتر (الزرار تحت) وابعتلي السجل.';
    } catch (e) {
      msg = 'خطأ: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = parseRouterDns(raw);
    final prev = _prev;
    return Scaffold(
      appBar: AppBar(title: const Text('DNS الراوتر (تجريبي)')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(12), children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dns_rounded, color: kGold),
                  title: Text(d.supported ? dnsLabel(d.mode, d.primary, d.secondary) : 'الراوتر مرجّعش إعداد الـ DNS'),
                  subtitle: const Text('الـ DNS الحالي للراوتر (لكل الأجهزة)', style: TextStyle(fontSize: 12, color: kMuted)),
                  trailing: IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _read),
                ),
              ),
              if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(msg, style: const TextStyle(color: kGold))),
              if (busy) const LinearProgressIndicator(),
              if (!d.supported)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('الراوتر مرجّعش dns_mode، فمش هبعت أوامر تغيير متخمّنة. غيّره من صفحة الراوتر نفسها:', style: TextStyle(color: kMuted)),
                )
              else ...[
                const SectionTitle('اختار', icon: Icons.tune_rounded),
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded),
                  title: const Text('تلقائي من الشبكة (اتصالات)'),
                  onTap: busy ? null : () => _apply(null, null),
                ),
                for (final x in kDnsPresets)
                  ListTile(
                    leading: Icon(x.primary == d.primary && d.mode == 'manual' ? Icons.radio_button_checked : Icons.radio_button_off, color: kGold),
                    title: Text(x.name),
                    subtitle: Text('${x.primary} / ${x.secondary}${x.note.isEmpty ? '' : ' — ${x.note}'}', textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                    onTap: busy ? null : () => _apply(x.primary, x.secondary),
                  ),
                const SectionTitle('يدوي', icon: Icons.edit_rounded),
                Row(children: [
                  Expanded(child: TextField(controller: pC, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الأساسي'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: sC, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الاحتياطي'))),
                ]),
                const SizedBox(height: 8),
                FilledButton(onPressed: busy ? null : () => _apply(pC.text.trim(), sC.text.trim()), child: const Text('طبّق')),
                if (prev != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.undo_rounded),
                      label: Text('ارجع للقديم (${prev.p == null ? 'تلقائي' : '${prev.p} / ${prev.s ?? ''}'})'),
                      onPressed: busy ? null : () => _apply(prev.p, prev.s, undo: true),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('افتح صفحة الراوتر'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BrowserPage(initialUrl: widget.router.base))),
              ),
              const SectionTitle('DNS للموبايل ده بس', icon: Icons.smartphone_rounded),
              const Text(
                  'لو عايز تغيّر للموبايل ده بس من غير الراوتر: الإعدادات ← الشبكة والإنترنت ← DNS الخاص (Private DNS) ← اكتب مثلًا dns.adguard-dns.com (يمنع إعلانات) أو one.one.one.one',
                  style: TextStyle(color: kMuted, fontSize: 13, height: 1.6)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.settings_rounded),
                label: const Text('افتح إعدادات الشبكة'),
                onPressed: () async {
                  final ok = await Native5.openSettings('android.settings.WIRELESS_SETTINGS');
                  if (!ok && context.mounted) toast(context, 'مقدرتش أفتح الإعدادات — افتحها بنفسك');
                },
              ),
            ]),
    );
  }
}

class Native5 {
  static const _ch = MethodChannel('a2r/native');
  static Future<bool> openSettings(String action) async {
    try {
      return await _ch.invokeMethod('openSettings', {'action': action}) == true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> initialShare() async {
    try {
      return await _ch.invokeMethod<String>('initialShare');
    } catch (_) {
      return null;
    }
  }
}

// ---------------- سجل الإشارة + الانقطاعات + السرعة ----------------
bool pppConnected(String s) {
  final t = s.toLowerCase();
  return t == 'ppp_connected' || t == 'ipv6_connected' || t == 'ipv4_ipv6_connected' || t == 'connected';
}

/// خطوة واحدة في سجل الانقطاع: بيرجع (فتح انقطاع جديد من، انقطاع اتقفل (من، لـ))
({int? openStart, (int, int)? closed}) outageStep(int? openStart, bool nowConnected, int t) {
  if (!nowConnected) return (openStart: openStart ?? t, closed: null);
  if (openStart != null) return (openStart: null, closed: (openStart, t));
  return (openStart: null, closed: null);
}

class NetLog {
  static List<(int, int, int)> get signal => [
        for (final e in _jsonList('net_sig'))
          if (e is List && e.length >= 3) ((e[0] as num).toInt(), (e[1] as num).toInt(), (e[2] as num).toInt())
      ];
  static List<(int, int)> get outages => [
        for (final e in _jsonList('net_out'))
          if (e is List && e.length >= 2) ((e[0] as num).toInt(), (e[1] as num).toInt())
      ];
  static int? get openOutage => Store.p.getInt('net_out_open');

  /// عينة من رد status: RSRP + الإشارة + حالة الاتصال (مرة كل دقيقة بالكتير)
  static Future<void> sample(Map<String, dynamic> st, {String source = 'app'}) async {
    final t = DateTime.now().millisecondsSinceEpoch;
    final rsrp = int.tryParse('${st['lte_rsrp'] ?? ''}'.trim());
    final bar = int.tryParse('${st['signalbar'] ?? ''}'.trim()) ?? -1;
    final last = Store.p.getInt('net_sig_last') ?? 0;
    if (rsrp != null && t - last >= 55000) {
      final l = _jsonList('net_sig');
      l.add([t, rsrp, bar]);
      while (l.length > 3000) {
        l.removeAt(0);
      }
      await Store.p.setString('net_sig', jsonEncode(l));
      await Store.p.setInt('net_sig_last', t);
    }
    final ppp = '${st['ppp_status'] ?? ''}'.trim();
    if (ppp.isEmpty) return;
    final r = outageStep(openOutage, pppConnected(ppp), t);
    if (r.openStart != null && openOutage == null) AppLog.add('NET', 'النت قطع ($ppp) [$source]');
    if (r.openStart == null) {
      await Store.p.remove('net_out_open');
    } else {
      await Store.p.setInt('net_out_open', r.openStart!);
    }
    if (r.closed != null) {
      final l = _jsonList('net_out');
      l.add([r.closed!.$1, r.closed!.$2]);
      while (l.length > 500) {
        l.removeAt(0);
      }
      await Store.p.setString('net_out', jsonEncode(l));
      AppLog.add('NET', 'النت رجع بعد ${durAr(Duration(milliseconds: r.closed!.$2 - r.closed!.$1))} [$source]');
    }
  }
}

class SpeedLog {
  static List<(int, double)> get all => [
        for (final e in _jsonList('speed_log'))
          if (e is List && e.length >= 2) ((e[0] as num).toInt(), (e[1] as num).toDouble())
      ];
  static Future<void> add(double mbps) async {
    if (mbps <= 0) return;
    final l = _jsonList('speed_log')..add([DateTime.now().millisecondsSinceEpoch, double.parse(mbps.toStringAsFixed(2))]);
    while (l.length > 200) {
      l.removeAt(0);
    }
    await Store.p.setString('speed_log', jsonEncode(l));
  }
}

/// رسم خطي بسيط (من غير مكتبات)
class MiniChart extends StatelessWidget {
  final List<(int, double)> points;
  final double? minY, maxY;
  final double height;
  final String unit;
  const MiniChart({super.key, required this.points, this.minY, this.maxY, this.height = 160, this.unit = ''});
  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: height, child: const Center(child: Text('لسه مفيش بيانات كفاية', style: TextStyle(color: kMuted))));
    }
    return SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _ChartPainter(points, minY, maxY, unit)));
  }
}

class _ChartPainter extends CustomPainter {
  final List<(int, double)> pts;
  final double? minY, maxY;
  final String unit;
  _ChartPainter(this.pts, this.minY, this.maxY, this.unit);
  @override
  void paint(Canvas c, Size s) {
    final lo = minY ?? pts.map((e) => e.$2).reduce(min);
    var hi = maxY ?? pts.map((e) => e.$2).reduce(max);
    if (hi <= lo) hi = lo + 1;
    final t0 = pts.first.$1, t1 = pts.last.$1 == t0 ? t0 + 1 : pts.last.$1;
    const padL = 34.0, padB = 16.0;
    final w = s.width - padL, h = s.height - padB;
    final grid = Paint()
      ..color = kLine
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 4; i++) {
      final y = h * i / 4;
      c.drawLine(Offset(padL, y), Offset(s.width, y), grid);
      tp.text = TextSpan(text: (hi - (hi - lo) * i / 4).toStringAsFixed(0), style: const TextStyle(fontSize: 9, color: kMuted));
      tp.layout();
      tp.paint(c, Offset(0, y - 6));
    }
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = padL + w * (pts[i].$1 - t0) / (t1 - t0);
      final y = h - h * ((pts[i].$2.clamp(lo, hi) - lo) / (hi - lo));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    c.drawPath(
        path,
        Paint()
          ..color = kGold
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    for (final (i, t) in [(0, t0), (1, t1)]) {
      tp.text = TextSpan(text: hhmm(t), style: const TextStyle(fontSize: 9, color: kMuted));
      tp.layout();
      tp.paint(c, Offset(i == 0 ? padL : s.width - tp.width, h + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter o) => o.pts != pts;
}

/// يجمع الانقطاعات حسب اليوم (الأحدث الأول)
Map<String, List<(int, int)>> outagesByDay(List<(int, int)> l) {
  final out = <String, List<(int, int)>>{};
  for (final e in l.reversed) {
    out.putIfAbsent(dayKeyOf(e.$1), () => []).add(e);
  }
  return out;
}

class SignalHistoryPage extends StatefulWidget {
  const SignalHistoryPage({super.key});
  @override
  State<SignalHistoryPage> createState() => _SignalHistoryPageState();
}

class _SignalHistoryPageState extends State<SignalHistoryPage> {
  int hours = 24;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sig = NetLog.signal.where((e) => now - e.$1 <= hours * 3600000).map((e) => (e.$1, e.$2.toDouble())).toList();
    final outs = NetLog.outages;
    final open = NetLog.openOutage;
    final sp = SpeedLog.all;
    final byDay = outagesByDay(outs);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الشبكة'),
          bottom: const TabBar(tabs: [Tab(text: 'الإشارة'), Tab(text: 'الانقطاعات'), Tab(text: 'السرعة')]),
        ),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(12), children: [
            Wrap(spacing: 8, children: [
              for (final hh in [6, 24, 72]) ChoiceChip(label: Text('$hh ساعة'), selected: hours == hh, onSelected: (_) => setState(() => hours = hh)),
            ]),
            const SizedBox(height: 8),
            const Text('RSRP (كل ما يقرب من -70 أحسن)', style: TextStyle(color: kMuted, fontSize: 12)),
            MiniChart(points: sig, minY: -125, maxY: -65),
            if (sig.isNotEmpty)
              Text('أقل: ${sig.map((e) => e.$2).reduce(min).toStringAsFixed(0)} • أعلى: ${sig.map((e) => e.$2).reduce(max).toStringAsFixed(0)} • متوسط: ${(sig.map((e) => e.$2).reduce((a, b) => a + b) / sig.length).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            SwitchListTile(
              value: NetWatch.enabled,
              title: const Text('سجّل في الخلفية كل ربع ساعة تقريبًا'),
              subtitle: const Text('بيدخل الراوتر من الخلفية — التطبيق مفتوح بيسجّل كل دقيقة لوحده', style: TextStyle(fontSize: 12, color: kMuted)),
              onChanged: (v) async {
                await NetWatch.setEnabled(v);
                setState(() {});
              },
            ),
          ]),
          ListView(padding: const EdgeInsets.all(12), children: [
            if (open != null)
              Card(
                color: kBad.withValues(alpha: 0.15),
                child: ListTile(leading: const Icon(Icons.wifi_off_rounded, color: kBad), title: Text('النت قاطع من ${hhmm(open)}'), subtitle: Text(durAr(Duration(milliseconds: now - open)))),
              ),
            if (byDay.isEmpty && open == null) const EmptyState(icon: Icons.check_circle_rounded, title: 'مفيش انقطاعات متسجلة'),
            for (final e in byDay.entries) ...[
              SectionTitle('${e.key} — ${e.value.length} مرة، ${durAr(Duration(milliseconds: e.value.fold<int>(0, (a, x) => a + x.$2 - x.$1)))}', icon: Icons.calendar_today_rounded),
              for (final o in e.value) ListTile(dense: true, leading: const Icon(Icons.portable_wifi_off_rounded, color: kBad), title: Text('${hhmm(o.$1)} ← ${hhmm(o.$2)}'), trailing: Text(durAr(Duration(milliseconds: o.$2 - o.$1)))),
            ],
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('بيتسجل من حالة الاتصال في الراوتر (ppp_status) وإنت فاتح التطبيق أو من التسجيل في الخلفية — الانقطاعات الأقصر من فترة التسجيل ممكن متظهرش.',
                  style: TextStyle(fontSize: 12, color: kMuted)),
            ),
          ]),
          ListView(padding: const EdgeInsets.all(12), children: [
            const Text('سرعة التنزيل (ميجابت/ث) — من زرار «سرعة النت»', style: TextStyle(color: kMuted, fontSize: 12)),
            MiniChart(points: sp, minY: 0),
            for (final s in sp.reversed.take(50)) ListTile(dense: true, title: Text('${s.$2.toStringAsFixed(1)} ميجابت/ث'), trailing: Text('${dayKeyOf(s.$1)} ${hhmm(s.$1)}')),
          ]),
        ]),
      ),
    );
  }
}

/// RSRP → 0..100 (للصوت والمؤشر)
double rsrpQuality(int rsrp) => ((rsrp + 120) / 50 * 100).clamp(0, 100).toDouble();

class RouterPlacePage extends StatefulWidget {
  final ZteRouter router;
  const RouterPlacePage({super.key, required this.router});
  @override
  State<RouterPlacePage> createState() => _RouterPlacePageState();
}

class _RouterPlacePageState extends State<RouterPlacePage> {
  Timer? poll, beep;
  int? rsrp, best;
  String bar = '', net = '';
  bool sound = true;
  final List<(int, double)> trail = [];

  @override
  void initState() {
    super.initState();
    poll = Timer.periodic(const Duration(milliseconds: 1500), (_) => _tick());
    _tick();
  }

  @override
  void dispose() {
    poll?.cancel();
    beep?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    try {
      final j = await widget.router.get(['lte_rsrp', 'signalbar', 'network_type']);
      final v = int.tryParse('${j['lte_rsrp'] ?? ''}'.trim());
      if (!mounted) return;
      setState(() {
        rsrp = v;
        bar = '${j['signalbar'] ?? ''}';
        net = '${j['network_type'] ?? ''}';
        if (v != null) {
          if (best == null || v > best!) best = v;
          trail.add((DateTime.now().millisecondsSinceEpoch, v.toDouble()));
          if (trail.length > 120) trail.removeAt(0);
        }
      });
      _beep();
    } catch (_) {}
  }

  void _beep() {
    beep?.cancel();
    if (!sound || rsrp == null) return;
    beep = Timer.periodic(Duration(milliseconds: beepIntervalMs(rsrpQuality(rsrp!))), (_) => SystemSound.play(SystemSoundType.click));
  }

  @override
  Widget build(BuildContext context) {
    final q = rsrp == null ? 0.0 : rsrpQuality(rsrp!);
    final col = q >= 70 ? kOk : (q >= 40 ? kGold : kBad);
    return Scaffold(
      appBar: AppBar(title: const Text('مكان الراوتر'), actions: [
        IconButton(
          icon: Icon(sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
          onPressed: () {
            setState(() => sound = !sound);
            _beep();
          },
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('لف بالراوتر في الأوضة (جنب الشباك/أعلى مكان) — الصوت بيسرع كل ما الإشارة تتحسن. خلي كل مكان 10 ثواني علشان القراية تثبت.',
            style: TextStyle(color: kMuted, height: 1.5)),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: q / 100, strokeWidth: 16, color: col, backgroundColor: kSurface2)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(rsrp == null ? '—' : '$rsrp', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: col)),
                const Text('RSRP dBm', style: TextStyle(color: kMuted)),
                Text('$bar/5  $net', style: const TextStyle(fontSize: 13)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Text('أحسن قراية: ${best ?? '—'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: kGold)),
        const SizedBox(height: 12),
        MiniChart(points: trail, minY: -125, maxY: -65, height: 120),
      ]),
    );
  }
}

// ---------------- مراقبة الأجهزة ----------------
class DeviceWatch {
  static Map<String, dynamic> get all => _jsonMap('dev_watch');
  static bool has(String k) => all.containsKey(k);

  static Future<void> set(String key, String? name, {String ip = ''}) async {
    final a = all;
    if (name == null) {
      a.remove(key);
    } else {
      a[key] = {'n': name, 'ip': ip, 'on': null, 't': 0};
    }
    await Store.p.setString('dev_watch', jsonEncode(a));
    await NetWatch.rearm();
  }

  static List<dynamic> get events => _jsonList('dev_watch_ev');

  /// present = مفاتيح الأجهزة اللي في قايمة الراوتر دلوقتي. بيرجّع التغييرات (للاختبار)
  static Future<List<(String, bool)>> update(Set<String> present) async {
    final a = all;
    if (a.isEmpty) return const [];
    final ch = watchChanges(a, present);
    if (ch.isEmpty) return ch;
    final t = DateTime.now().millisecondsSinceEpoch;
    final ev = events;
    for (final (k, on) in ch) {
      final e = Map<String, dynamic>.from(a[k] as Map);
      final first = e['on'] == null;
      e['on'] = on;
      e['t'] = t;
      a[k] = e;
      if (!first) {
        ev.add([t, k, e['n'], on]);
        Native.notify(on ? 'دخل الشبكة: ${e['n']}' : 'خرج من الشبكة: ${e['n']}', '${hhmm(t)}${on ? ' — متوصل دلوقتي' : ' — مش ظاهر في الراوتر'}');
        AppLog.add('WATCH', '${e['n']} ${on ? 'دخل' : 'خرج'}');
      }
    }
    while (ev.length > 300) {
      ev.removeAt(0);
    }
    await Store.p.setString('dev_watch', jsonEncode(a));
    await Store.p.setString('dev_watch_ev', jsonEncode(ev));
    return ch;
  }
}

/// التغييرات بين المحفوظ واللي ظاهر دلوقتي
List<(String, bool)> watchChanges(Map<String, dynamic> watched, Set<String> present) {
  final out = <(String, bool)>[];
  for (final e in watched.entries) {
    final on = present.contains(e.key);
    final was = (e.value as Map)['on'];
    if (was != on) out.add((e.key, on));
  }
  return out;
}

/// تنبيه لما جهاز جديد (عمره ما ظهر قبل كده) يدخل الشبكة
class NewDevAlert {
  static bool get enabled => Store.p.getBool('newdev_on') ?? false;
  static Set<String> get known => (Store.p.getStringList('newdev_known') ?? []).toSet();

  static Future<void> setEnabled(bool v) async {
    await Store.p.setBool('newdev_on', v);
    if (!v) await Store.p.remove('newdev_known');
    await NetWatch.rearm();
  }

  /// أول مرة بيحفظ اللي موجود من غير إشعار. بعد كده أي MAC جديد = إشعار. بيرجّع الجدد (للاختبار)
  static Future<List<RouterStation>> check(List<RouterStation> list) async {
    if (!enabled) return const [];
    final seen = known;
    final first = !(Store.p.containsKey('newdev_known'));
    final fresh = <RouterStation>[];
    for (final s in list) {
      final k = s.mac.isNotEmpty ? s.mac.toUpperCase() : s.ip;
      if (k.isEmpty) continue;
      if (seen.add(k) && !first) fresh.add(s);
    }
    await Store.p.setStringList('newdev_known', seen.toList());
    for (final s in fresh) {
      final n = s.hostname.isNotEmpty ? s.hostname : (Oui.vendorOf(s.mac).isNotEmpty ? Oui.vendorOf(s.mac) : 'جهاز مجهول');
      Native.notify('جهاز جديد دخل الشبكة', '$n • ${s.ip} • ${s.mac}');
      AppLog.add('NEWDEV', '$n ${s.ip} ${s.mac}');
    }
    return fresh;
  }
}

class NetWatch {
  static bool get enabled => Store.p.getBool('netwatch_on') ?? false;
  static Future<void> setEnabled(bool v) async {
    await Store.p.setBool('netwatch_on', v);
    await rearm();
  }

  static Future<String> rearm() async {
    if (!enabled && DeviceWatch.all.isEmpty && !NewDevAlert.enabled) {
      await Native4.cancelAlarm(1003);
      return 'off';
    }
    await Native4.setAlarm(1003, DateTime.now().add(const Duration(minutes: 15)), {'type': 'watch'}, exact: false);
    return 'كل ربع ساعة';
  }

  static Future<String> backgroundCheck() async {
    final r = await Bg.router();
    if (r == null) return 'مقدرتش أدخل الراوتر';
    try {
      final st = await r.status();
      await NetLog.sample(st, source: 'bg');
      if (DeviceWatch.all.isNotEmpty || NewDevAlert.enabled) {
        final list = await r.stations();
        await DeviceWatch.update({for (final s in list) s.mac.isNotEmpty ? s.mac : s.ip});
        await NewDevAlert.check(list);
      }
      return 'RSRP ${st['lte_rsrp']} ${st['ppp_status']}';
    } finally {
      r.close();
    }
  }
}

class DeviceWatchPage extends StatefulWidget {
  final List<LanHost> hosts;
  final String Function(LanHost) labelOf;
  const DeviceWatchPage({super.key, required this.hosts, required this.labelOf});
  @override
  State<DeviceWatchPage> createState() => _DeviceWatchPageState();
}

class _DeviceWatchPageState extends State<DeviceWatchPage> {
  Timer? t;
  final Map<String, List<(int, double)>> lat = {};
  final Map<String, int?> lastMs = {};

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 5), (_) => _ping());
    _ping();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Future<void> _ping() async {
    final w = DeviceWatch.all;
    await Future.wait(w.entries.map((e) async {
      final ip = widget.hosts.where((h) => (h.mac.isNotEmpty ? h.mac : h.ip) == e.key).firstOrNull?.ip ?? '${(e.value as Map)['ip'] ?? ''}';
      if (ip.isEmpty) return;
      final ms = await pingOnce(ip);
      lastMs[e.key] = ms;
      final l = lat.putIfAbsent(e.key, () => []);
      l.add((DateTime.now().millisecondsSinceEpoch, (ms ?? -1).toDouble()));
      if (l.length > 60) l.removeAt(0);
    }));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = DeviceWatch.all;
    final ev = DeviceWatch.events.reversed.take(60).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مراقبة الأجهزة')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        SwitchListTile(
          value: NewDevAlert.enabled,
          title: const Text('نبّهني لو جهاز جديد دخل الشبكة'),
          subtitle: const Text('أي جهاز عمره ما ظهر في الراوتر قبل كده. أول مرة بيحفظ الأجهزة الحالية من غير إشعار. محتاج دخول الراوتر.', style: TextStyle(fontSize: 12, color: kMuted)),
          onChanged: (v) async {
            await NewDevAlert.setEnabled(v);
            if (v) await Native.askNotifyPermission();
            if (mounted) setState(() {});
          },
        ),
        const Text('إشعار لما جهاز يدخل أو يخرج من الشبكة (حسب قايمة الراوتر — بيتأخر دقايق لحد ما الراوتر يحس إن الجهاز خرج). في الخلفية بيتشيّك كل ربع ساعة تقريبًا.',
            style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
        if (w.isEmpty) const EmptyState(icon: Icons.visibility_rounded, title: 'مفيش أجهزة متراقبة — اختار من تحت أو من قايمة الجهاز'),
        for (final e in w.entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.circle, size: 12, color: (e.value as Map)['on'] == true ? kOk : ((e.value as Map)['on'] == false ? kBad : kMuted)),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${(e.value as Map)['n']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(lastMs[e.key] == null ? 'مبيردش على ping' : '${lastMs[e.key]} ms', style: const TextStyle(fontSize: 12, color: kMuted)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      await DeviceWatch.set(e.key, null);
                      setState(() {});
                    },
                  ),
                ]),
                MiniChart(points: (lat[e.key] ?? []).where((x) => x.$2 >= 0).toList(), minY: 0, height: 70),
                const Text('ملحوظة: الموبايلات النايمة ساعات مبتردش على ping وهي متوصلة', style: TextStyle(fontSize: 11, color: kMuted)),
              ]),
            ),
          ),
        const SectionTitle('ضيف جهاز', icon: Icons.add_rounded),
        for (final h in widget.hosts.where((h) => !w.containsKey(h.mac.isNotEmpty ? h.mac : h.ip)))
          ListTile(
            dense: true,
            title: Text(widget.labelOf(h)),
            subtitle: Text(h.ip, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
            trailing: const Icon(Icons.add_circle_outline_rounded, color: kGold),
            onTap: () async {
              await DeviceWatch.set(h.mac.isNotEmpty ? h.mac : h.ip, widget.labelOf(h), ip: h.ip);
              await Native.askNotifyPermission();
              setState(() {});
            },
          ),
        if (ev.isNotEmpty) const SectionTitle('آخر الأحداث', icon: Icons.history_rounded),
        for (final x in ev)
          if (x is List && x.length >= 4)
            ListTile(
              dense: true,
              leading: Icon(x[3] == true ? Icons.login_rounded : Icons.logout_rounded, color: x[3] == true ? kOk : kBad),
              title: Text('${x[2]} ${x[3] == true ? 'دخل' : 'خرج'}'),
              trailing: Text('${dayKeyOf((x[0] as num).toInt())} ${hhmm((x[0] as num).toInt())}', style: const TextStyle(fontSize: 12)),
            ),
      ]),
    );
  }
}

// ---------------- الكاست: سجل + تكرار + مؤقت ----------------
String nextRepeat(String r) => r == 'off' ? 'all' : (r == 'all' ? 'one' : 'off');

/// اللي يشتغل بعد ما الحالي يخلص (null = نقف)
int? nextQueueIndex(int playing, int len, {required bool autoNext, required String repeat, bool sleepAfter = false}) {
  if (sleepAfter || len == 0 || playing < 0) return null;
  if (repeat == 'one') return playing;
  if (!autoNext) return null;
  if (playing + 1 < len) return playing + 1;
  if (repeat == 'all') return 0;
  return null;
}

class CastHistory {
  static List<Map<String, dynamic>> get all => [
        for (final e in _jsonList('cast_hist'))
          if (e is Map) Map<String, dynamic>.from(e)
      ];

  static Map<String, dynamic> entryOf(QueueItem q, int t) => {
        't': t,
        'title': q.title,
        'url': q.file == null ? q.url : '',
        'file': q.file?.path ?? '',
        if (q.mime != null) 'mime': q.mime,
        if (q.headers.isNotEmpty) 'h': q.headers,
        if (q.viaPhone) 'via': true,
      };

  static List<Map<String, dynamic>> addTo(List<Map<String, dynamic>> l, Map<String, dynamic> e, {int max = 60}) {
    final key = '${e['file']}|${e['url']}';
    final out = l.where((x) => '${x['file']}|${x['url']}' != key).toList()..add(e);
    while (out.length > max) {
      out.removeAt(0);
    }
    return out;
  }

  static Future<void> add(QueueItem q) async {
    // الروابط المؤقتة (يوتيوب googlevideo) بتبوظ بعد شوية — مش بنحفظها
    if (q.file == null && q.url.contains('googlevideo.com')) return;
    await Store.p.setString('cast_hist', jsonEncode(addTo(all, entryOf(q, DateTime.now().millisecondsSinceEpoch))));
  }

  static QueueItem? toItem(Map<String, dynamic> e) {
    final f = '${e['file'] ?? ''}';
    if (f.isNotEmpty) {
      final file = File(f);
      if (!file.existsSync()) return null;
      return QueueItem('${e['title']}', f, file: file);
    }
    final u = '${e['url'] ?? ''}';
    if (u.isEmpty) return null;
    return QueueItem('${e['title']}', u,
        mime: e['mime'] as String?, headers: e['h'] is Map ? Map<String, String>.from(e['h'] as Map) : const {}, viaPhone: e['via'] == true);
  }
}

class CastHistoryPage extends StatefulWidget {
  const CastHistoryPage({super.key});
  @override
  State<CastHistoryPage> createState() => _CastHistoryPageState();
}

class _CastHistoryPageState extends State<CastHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final l = CastHistory.all.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('اللي اتعرض قبل كده'), actions: [
        if (l.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              if (!await confirm(context, 'تمسح السجل؟')) return;
              await Store.p.remove('cast_hist');
              setState(() {});
            },
          ),
      ]),
      body: l.isEmpty
          ? const EmptyState(icon: Icons.history_rounded, title: 'لسه معرضتش حاجة')
          : ListView(children: [
              for (final e in l)
                ListTile(
                  leading: Icon('${e['file']}'.isNotEmpty ? Icons.phone_android_rounded : Icons.link_rounded, color: kGold),
                  title: Text('${e['title']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${dayKeyOf((e['t'] as num).toInt())} ${hhmm((e['t'] as num).toInt())}', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.cast_rounded),
                  onTap: () async {
                    final q = CastHistory.toItem(e);
                    if (q == null) {
                      toast(context, 'الملف مبقاش موجود على الموبايل');
                      return;
                    }
                    Navigator.pop(context);
                    try {
                      await CastState.I.add(q);
                    } catch (_) {}
                  },
                ),
            ]),
    );
  }
}

class CastExtrasBar extends StatelessWidget {
  final CastState cs;
  const CastExtrasBar({super.key, required this.cs});

  Future<void> _sleep(BuildContext context) async {
    final v = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          const ListTile(title: Text('وقّف العرض بعد…')),
          for (final m in [15, 30, 45, 60, 90, 120]) ListTile(title: Text('$m دقيقة'), onTap: () => Navigator.pop(c, m)),
          ListTile(title: const Text('لما اللي شغال يخلص'), onTap: () => Navigator.pop(c, -1)),
          if (cs.sleepAt != null || cs.sleepEndOfItem) ListTile(title: const Text('إلغاء المؤقت', style: TextStyle(color: kBad)), onTap: () => Navigator.pop(c, 0)),
        ]),
      ),
    );
    if (v != null) cs.setSleep(v);
  }

  @override
  Widget build(BuildContext context) {
    final rep = cs.repeat;
    final sleepTxt = cs.sleepEndOfItem
        ? 'بعد اللي شغال'
        : (cs.sleepAt == null ? 'مؤقت' : '${max(0, cs.sleepAt!.difference(DateTime.now()).inMinutes)} د');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilterChip(label: const Text('اللي بعده لوحده'), selected: cs.autoNext, onSelected: cs.setAutoNext),
        ActionChip(
          avatar: Icon(rep == 'one' ? Icons.repeat_one_rounded : Icons.repeat_rounded, size: 18, color: rep == 'off' ? kMuted : kGold),
          label: Text(rep == 'off' ? 'من غير تكرار' : (rep == 'all' ? 'كرر القايمة' : 'كرر ده')),
          onPressed: cs.cycleRepeat,
        ),
        ActionChip(
          avatar: Icon(Icons.bedtime_rounded, size: 18, color: cs.sleepAt != null || cs.sleepEndOfItem ? kGold : kMuted),
          label: Text(sleepTxt),
          onPressed: () => _sleep(context),
        ),
      ]),
    );
  }
}

// ---------------- «شارك لـ A2R Home» من أي تطبيق ----------------
final RegExp _kDirectMedia = RegExp(r'\.(mp4|m4v|mkv|webm|mov|avi|ts|m3u8|mp3|m4a|aac|flac|jpe?g|png|gif|webp)(\?|$)', caseSensitive: false);

/// أول رابط في النص المتشارك
String? firstUrl(String text) => RegExp(r'https?://[^\s<>"]+').firstMatch(text)?.group(0);

bool isDirectMediaUrl(String u) => _kDirectMedia.hasMatch(Uri.tryParse(u)?.path ?? u);

class ShareIn {
  static BuildContext Function()? _ctx;
  static void Function(int tab)? _goTab;
  static void init(BuildContext ctx, void Function(int tab) goTab) {
    final st = ctx;
    _ctx = () => st;
    _goTab = goTab;
    Native5.initialShare().then((s) {
      if (s != null && s.isNotEmpty) handle(s);
    });
  }

  static Future<void> handle(String json) async {
    Map<String, dynamic> d;
    try {
      d = Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return;
    }
    AppLog.add('SHARE', 'وصل: ${json.length > 300 ? json.substring(0, 300) : json}');
    final ctx = _ctx?.call();
    if (ctx == null || !ctx.mounted) return;
    final files = [
      for (final f in (d['files'] as List? ?? const []))
        if (f is Map && '${f['path']}'.isNotEmpty) File('${f['path']}')
    ];
    final cs = CastState.I;
    if (files.isNotEmpty) {
      _goTab?.call(1);
      if (cs.current == null && cs.gm == null) await cs.discover();
      var first = true;
      for (final f in files) {
        try {
          await cs.add(QueueItem(f.uri.pathSegments.last, f.path, file: f), playNow: first);
        } catch (e) {
          AppLog.add('SHARE', 'cast ✗ $e');
        }
        first = false;
      }
      return;
    }
    final url = firstUrl('${d['text'] ?? ''}');
    if (url == null) {
      if (ctx.mounted) toast(ctx, 'اللي اتشارك مفيهوش رابط');
      return;
    }
    if (!ctx.mounted) return;
    final pc = PcSaved.get();
    final pick = await showModalBottomSheet<String>(
      context: ctx,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          ListTile(title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12))),
          ListTile(leading: const Icon(Icons.cast_rounded, color: kGold), title: const Text('اعرضه على التلفزيون'), onTap: () => Navigator.pop(c, 'tv')),
          ListTile(leading: const Icon(Icons.public_rounded), title: const Text('افتحه في متصفح التطبيق (يلقط الفيديو)'), onTap: () => Navigator.pop(c, 'web')),
          if (pc != null) ListTile(leading: const Icon(Icons.desktop_windows_rounded), title: Text('افتحه على الكمبيوتر (${pc.name})'), onTap: () => Navigator.pop(c, 'pc')),
        ]),
      ),
    );
    if (pick == null || !ctx.mounted) return;
    if (pick == 'pc' && pc != null) {
      final c = PcClient(pc.host, token: pc.token);
      try {
        await c.openUrl(url);
        if (ctx.mounted) toast(ctx, 'اتفتح على الكمبيوتر ✓');
      } catch (e) {
        if (ctx.mounted) toast(ctx, '$e'.replaceFirst('Bad state: ', ''));
      } finally {
        c.close();
      }
      return;
    }
    _goTab?.call(1);
    if (pick == 'tv' && isDirectMediaUrl(url)) {
      if (cs.current == null && cs.gm == null) await cs.discover();
      try {
        await cs.add(QueueItem(Uri.tryParse(url)?.pathSegments.where((x) => x.isNotEmpty).lastOrNull ?? url, url));
      } catch (_) {}
      return;
    }
    // صفحة (يوتيوب/موقع): المتصفح بيلقط الفيديو وفيه زرار الكاست واختيار الجودة
    if (ctx.mounted) await Navigator.push(ctx, MaterialPageRoute(builder: (_) => BrowserPage(initialUrl: url)));
  }
}

// ---------------- الريسيفر: آخر القنوات + مجموعات ----------------
class StbGroup {
  String name;
  List<String> keys;
  StbGroup(this.name, this.keys);
  Map<String, dynamic> toJson() => {'n': name, 'k': keys};
}

String stbKey(StbChannel c) => '${c.radio ? 1 : 0}:${c.id}';

/// بيقرا ملف المجموعات (تصدير A2R Home أو قايمة بسيطة) — بيرجع null لو الملف مش مفهوم
List<StbGroup>? parseStbGroups(String text) {
  try {
    final d = jsonDecode(text);
    final list = d is Map ? d['groups'] : d;
    if (list is! List) return null;
    return [
      for (final g in list)
        if (g is Map && '${g['n'] ?? ''}'.trim().isNotEmpty) StbGroup('${g['n']}'.trim(), [for (final k in (g['k'] as List? ?? const [])) '$k'])
    ];
  } catch (_) {
    return null;
  }
}

List<StbGroup> mergeStbGroups(List<StbGroup> mine, List<StbGroup> incoming) {
  final out = [for (final g in mine) StbGroup(g.name, [...g.keys])];
  for (final g in incoming) {
    final ex = out.where((x) => x.name == g.name).firstOrNull;
    if (ex == null) {
      out.add(StbGroup(g.name, [...g.keys]));
    } else {
      for (final k in g.keys) {
        if (!ex.keys.contains(k)) ex.keys.add(k);
      }
    }
  }
  return out;
}

class StbPrefs {
  static bool get autoReconnect => Store.p.getBool('stb_autoreconnect') ?? true;
  static set autoReconnect(bool v) => Store.p.setBool('stb_autoreconnect', v);

  static List<({String id, String name, bool radio})> get recent => [
        for (final e in _jsonList('stb_recent'))
          if (e is Map) (id: '${e['id']}', name: '${e['n']}', radio: e['r'] == true)
      ];

  static void addRecent(StbChannel c) {
    final l = recent.where((e) => !(e.id == c.id && e.radio == c.radio)).toList();
    l.insert(0, (id: c.id, name: c.name, radio: c.radio));
    Store.p.setString('stb_recent', jsonEncode([for (final e in l.take(15)) {'id': e.id, 'n': e.name, 'r': e.radio}]));
  }

  static List<StbGroup> get groups => parseStbGroups(Store.p.getString('stb_groups') ?? '[]') ?? [];
  static Future<void> saveGroups(List<StbGroup> g) => Store.p.setString('stb_groups', jsonEncode([for (final x in g) x.toJson()]));
  static bool groupHas(String name, StbChannel c) => groups.where((g) => g.name == name).firstOrNull?.keys.contains(stbKey(c)) ?? false;
  static List<String> groupsOf(StbChannel c) => [for (final g in groups) if (g.keys.contains(stbKey(c))) g.name];
}

const List<String> kDefaultGroups = ['أخبار', 'رياضة', 'أفلام', 'مسلسلات', 'أطفال', 'ديني'];

Future<void> pickStbGroups(BuildContext context, StbChannel ch) async {
  var gs = StbPrefs.groups;
  await showModalBottomSheet(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, ss) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          ListTile(title: Text('«${ch.name}» في مجموعات:')),
          for (final g in gs)
            CheckboxListTile(
              value: g.keys.contains(stbKey(ch)),
              title: Text(g.name),
              onChanged: (v) async {
                v == true ? g.keys.add(stbKey(ch)) : g.keys.remove(stbKey(ch));
                await StbPrefs.saveGroups(gs);
                ss(() {});
              },
            ),
          ListTile(
            leading: const Icon(Icons.add_rounded, color: kGold),
            title: const Text('مجموعة جديدة'),
            onTap: () async {
              final n = await askText(context, 'اسم المجموعة', hint: 'أخبار، رياضة…');
              if (n == null || n.trim().isEmpty) return;
              gs = [...gs, StbGroup(n.trim(), [stbKey(ch)])];
              await StbPrefs.saveGroups(gs);
              ss(() {});
            },
          ),
          if (gs.isEmpty)
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text('اعمل المجموعات المعتادة (${kDefaultGroups.join('، ')})'),
              onTap: () async {
                gs = [for (final n in kDefaultGroups) StbGroup(n, [])];
                await StbPrefs.saveGroups(gs);
                ss(() {});
              },
            ),
        ]),
      ),
    ),
  );
}

class StbGroupsPage extends StatefulWidget {
  final List<StbChannel> channels;
  const StbGroupsPage({super.key, required this.channels});
  @override
  State<StbGroupsPage> createState() => _StbGroupsPageState();
}

class _StbGroupsPageState extends State<StbGroupsPage> {
  late List<StbGroup> gs = StbPrefs.groups;

  Future<void> _save() async {
    await StbPrefs.saveGroups(gs);
    setState(() {});
  }

  Future<void> _export() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/a2r-channel-groups.json');
    await f.writeAsString(const JsonEncoder.withIndent(' ').convert({'app': 'A2R Home', 'type': 'stb_groups', 'groups': [for (final g in gs) g.toJson()]}));
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'مجموعات قنوات A2R Home'));
  }

  Future<void> _import() async {
    final p = await FilePicker.pickFile(type: FileType.any);
    if (p == null) return;
    final f = await pickedToFile(p);
    if (f == null) return;
    final inc = parseStbGroups(await f.readAsString());
    if (inc == null) {
      if (mounted) toast(context, 'الملف ده مش ملف مجموعات');
      return;
    }
    gs = mergeStbGroups(gs, inc);
    await _save();
    if (mounted) toast(context, 'اتضاف ${inc.length} مجموعة');
  }

  String _name(String k) {
    final radio = k.startsWith('1:');
    final id = k.substring(2);
    return widget.channels.where((c) => c.id == id && c.radio == radio).firstOrNull?.name ?? 'قناة $id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مجموعات القنوات'), actions: [
        IconButton(tooltip: 'تصدير', icon: const Icon(Icons.ios_share_rounded), onPressed: gs.isEmpty ? null : _export),
        IconButton(tooltip: 'استيراد', icon: const Icon(Icons.file_open_rounded), onPressed: _import),
      ]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded),
        onPressed: () async {
          final n = await askText(context, 'اسم المجموعة');
          if (n == null || n.trim().isEmpty) return;
          gs.add(StbGroup(n.trim(), []));
          await _save();
        },
      ),
      body: Column(children: [
        SwitchListTile(
          value: StbPrefs.autoReconnect,
          title: const Text('ارجع اتصل بالريسيفر لوحدك لما أرجع للتطبيق'),
          onChanged: (v) => setState(() => StbPrefs.autoReconnect = v),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('المجموعات دي على الموبايل بس (مش بتغيّر حاجة في الريسيفر). اسحب علشان ترتب، ودوس على المجموعة علشان ترتب قنواتها.', style: TextStyle(fontSize: 12, color: kMuted)),
        ),
        Expanded(
          child: gs.isEmpty
              ? const EmptyState(icon: Icons.folder_special_rounded, title: 'مفيش مجموعات — دوس + أو زرار المجموعات جنب أي قناة')
              : ReorderableListView(
                  onReorder: (a, b) async {
                    if (b > a) b--;
                    gs.insert(b, gs.removeAt(a));
                    await _save();
                  },
                  children: [
                    for (final g in gs)
                      ListTile(
                        key: ValueKey(g.name),
                        leading: const Icon(Icons.drag_handle_rounded),
                        title: Text(g.name),
                        subtitle: Text('${g.keys.length} قناة'),
                        onTap: () => _editGroup(g),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'rename') {
                              final n = await askText(context, 'اسم جديد', initial: g.name);
                              if (n != null && n.trim().isNotEmpty) g.name = n.trim();
                            }
                            if (v == 'del' && mounted && await confirm(context, 'تمسح مجموعة «${g.name}»؟')) gs.remove(g);
                            await _save();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'rename', child: Text('غيّر الاسم')),
                            PopupMenuItem(value: 'del', child: Text('امسح')),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ]),
    );
  }

  Future<void> _editGroup(StbGroup g) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, ss) => SizedBox(
          height: MediaQuery.of(c).size.height * 0.6,
          child: g.keys.isEmpty
              ? const EmptyState(icon: Icons.live_tv_rounded, title: 'المجموعة فاضية — ضيف قنوات من قايمة القنوات')
              : ReorderableListView(
                  onReorder: (a, b) async {
                    if (b > a) b--;
                    g.keys.insert(b, g.keys.removeAt(a));
                    await _save();
                    ss(() {});
                  },
                  children: [
                    for (final k in g.keys)
                      ListTile(
                        key: ValueKey(k),
                        leading: const Icon(Icons.drag_handle_rounded),
                        title: Text(_name(k)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: () async {
                            g.keys.remove(k);
                            await _save();
                            ss(() {});
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------- الكمبيوتر: حافظة، لينك، عرض تقديمي، معلومات، مؤقت إطفاء، تشغيل عن بعد ----------------
extension PcClientV5 on PcClient {
  Future<String> clipGet() async => '${(await _json('GET', '/clip'))['text'] ?? ''}';
  Future<void> clipSet(String text) => _json('POST', '/clip', json: {'text': text});
  Future<void> openUrl(String url) => _json('POST', '/open', json: {'url': url});
  Future<Map<String, dynamic>> sysinfo() => _json('GET', '/sysinfo');
  Future<void> shutdownIn(int minutes) => _json('POST', '/power', json: {'a': 'shutdown_in', 'minutes': minutes, 'confirm': true});
}

String fmtUptime(int secs) {
  final d = secs ~/ 86400, h = (secs % 86400) ~/ 3600, m = (secs % 3600) ~/ 60;
  return [if (d > 0) '$d يوم', if (h > 0) '$h ساعة', '$m دقيقة'].join(' ');
}

class PcWake {
  static List<String> get macs => Store.p.getStringList('pc_macs') ?? [];
  static Future<void> learn(PcClient pc) async {
    try {
      final i = await pc.sysinfo();
      final m = [for (final x in (i['macs'] as List? ?? const [])) normMac('$x')].where((x) => x.length == 17).toList();
      if (m.isNotEmpty) await Store.p.setStringList('pc_macs', m);
    } catch (_) {}
  }

  static Future<void> wake(BuildContext context) async {
    final n = await readPhoneNet();
    final bc = <String>{'255.255.255.255', if ((n.broadcast ?? '').isNotEmpty) n.broadcast!, if (n.prefix.isNotEmpty) '${n.prefix}.255'};
    try {
      for (final m in macs) {
        for (final b in bc) {
          await sendWol(m, broadcast: b);
        }
      }
      if (context.mounted) {
        toast(context, 'اتبعت أمر التشغيل ✓ — لازم Wake-on-LAN يكون شغال في البيوس والكارت، وغالبًا بيشتغل بس لو الكمبيوتر متوصل بكابل');
      }
    } catch (e) {
      if (context.mounted) toast(context, 'فشل: $e');
    }
  }
}

class PcExtras extends StatelessWidget {
  final PcClient pc;
  final void Function(Object) onErr;
  const PcExtras({super.key, required this.pc, required this.onErr});

  Future<void> _run(BuildContext context, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      onErr(e);
    }
  }

  Future<void> _info(BuildContext context) async {
    final i = await pc.sysinfo();
    if (!context.mounted) return;
    String pct(Object? v) => v == null ? '—' : '${(v as num).toStringAsFixed(0)}%';
    String gb(Object? v) => v == null ? '—' : '${((v as num) / 1e9).toStringAsFixed(1)} جيجا';
    final bat = i['battery'] is Map ? i['battery'] as Map : null;
    await showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('${i['name'] ?? 'الكمبيوتر'}'),
        content: Text([
          'المعالج: ${pct(i['cpu'])}',
          'الرامات: ${pct(i['ram_pct'])} من ${gb(i['ram_total'])}',
          'الهارد (${i['disk_path'] ?? 'C:'}): فاضي ${gb(i['disk_free'])} من ${gb(i['disk_total'])}',
          if (bat != null) 'البطارية: ${bat['pct']}%${bat['plugged'] == true ? ' (على الشاحن)' : ''}',
          if (i['uptime'] != null) 'شغال من: ${fmtUptime((i['uptime'] as num).toInt())}',
          if (i['shutdown_at'] != null) 'هيطفي الساعة ${hhmm(((i['shutdown_at'] as num) * 1000).toInt())}',
        ].join('\n'), style: const TextStyle(height: 1.8)),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('تمام'))],
      ),
    );
  }

  Future<void> _timer(BuildContext context) async {
    final m = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(children: [
          const ListTile(title: Text('اطفي الكمبيوتر بعد…')),
          for (final x in [15, 30, 60, 90, 120, 180]) ListTile(title: Text('$x دقيقة'), onTap: () => Navigator.pop(c, x)),
          ListTile(title: const Text('إلغاء أي إطفاء متجدول', style: TextStyle(color: kBad)), onTap: () => Navigator.pop(c, 0)),
        ]),
      ),
    );
    if (m == null) return;
    if (m == 0) {
      await pc.power('cancel');
      if (context.mounted) toast(context, 'اتلغى الإطفاء');
      return;
    }
    await pc.shutdownIn(m);
    if (context.mounted) toast(context, 'الكمبيوتر هيطفي بعد $m دقيقة (ويندوز هيظهر تنبيه) — «إلغاء الإطفاء» لو غيرت رأيك');
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('إضافات', icon: Icons.extension_rounded),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.content_paste_go_rounded),
          label: const Text('ابعت الحافظة للكمبيوتر'),
          onPressed: () => _run(context, () async {
            final t = (await Clipboard.getData('text/plain'))?.text ?? '';
            if (t.isEmpty) {
              if (context.mounted) toast(context, 'الحافظة فاضية');
              return;
            }
            await pc.clipSet(t);
            if (context.mounted) toast(context, 'اتنسخ على الكمبيوتر ✓ (Ctrl+V هناك)');
          }),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.content_paste_rounded),
          label: const Text('هات حافظة الكمبيوتر'),
          onPressed: () => _run(context, () async {
            final t = await pc.clipGet();
            await Clipboard.setData(ClipboardData(text: t));
            if (context.mounted) toast(context, t.isEmpty ? 'حافظة الكمبيوتر فاضية' : 'اتنسخ على الموبايل ✓');
          }),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('افتح لينك على الكمبيوتر'),
          onPressed: () => _run(context, () async {
            final clip = (await Clipboard.getData('text/plain'))?.text ?? '';
            if (!context.mounted) return;
            final u = await askText(context, 'الرابط', initial: firstUrl(clip) ?? '', type: TextInputType.url);
            if (u == null || u.trim().isEmpty) return;
            final url = u.trim().startsWith('http') ? u.trim() : 'https://${u.trim()}';
            await pc.openUrl(url);
            if (context.mounted) toast(context, 'اتفتح ✓');
          }),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.slideshow_rounded),
          label: const Text('عرض تقديمي'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PcPresentPage(pc: pc, onErr: onErr))),
        ),
        OutlinedButton.icon(icon: const Icon(Icons.list_alt_rounded), label: const Text('العمليات'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PcProcsPage(pc: pc)))),
        OutlinedButton.icon(icon: const Icon(Icons.memory_rounded), label: const Text('معلومات الكمبيوتر'), onPressed: () => _run(context, () => _info(context))),
        OutlinedButton.icon(icon: const Icon(Icons.timer_rounded), label: const Text('مؤقت إطفاء'), onPressed: () => _run(context, () => _timer(context))),
      ]),
    ]);
  }
}

class PcProcsPage extends StatefulWidget {
  final PcClient pc;
  const PcProcsPage({super.key, required this.pc});
  @override
  State<PcProcsPage> createState() => _PcProcsPageState();
}

class _PcProcsPageState extends State<PcProcsPage> {
  List<Map<String, dynamic>> list = [];
  bool busy = true;
  String err = '';
  String q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      err = '';
    });
    try {
      list = await widget.pc.procs();
    } catch (e) {
      err = '$e'.replaceFirst('Bad state: ', '');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _kill(Map<String, dynamic> p) async {
    if (!await confirm(context, 'تقفل ${p['name']} (رقم ${p['pid']})؟\nأي شغل مش محفوظ فيه هيضيع.')) return;
    try {
      await widget.pc.killProc((p['pid'] as num).toInt());
      if (mounted) toast(context, 'اتقفلت ✓');
      await _load();
    } catch (e) {
      if (mounted) toast(context, '$e'.replaceFirst('Bad state: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final p in list)
        if (q.isEmpty || '${p['name']}'.toLowerCase().contains(q.toLowerCase())) p
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('العمليات على الكمبيوتر'), actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: busy ? null : _load)]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(decoration: const InputDecoration(hintText: 'دوّر باسم البرنامج', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
        ),
        if (busy) const LinearProgressIndicator(),
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(err, style: const TextStyle(color: kBad))),
        Expanded(
          child: ListView.builder(
            itemCount: shown.length,
            itemBuilder: (c, i) {
              final p = shown[i];
              final prot = p['protected'] == true;
              return ListTile(
                leading: Icon(prot ? Icons.lock_outline_rounded : Icons.apps_rounded, color: prot ? kMuted : kGold),
                title: Text('${p['name']}', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                subtitle: Text('${p['mem_mb']} ميجا • رقم ${p['pid']}', style: const TextStyle(fontSize: 12, color: kMuted)),
                trailing: prot ? null : IconButton(icon: const Icon(Icons.close_rounded, color: kBad), tooltip: 'اقفل', onPressed: () => _kill(p)),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class PcPresentPage extends StatelessWidget {
  final PcClient pc;
  final void Function(Object) onErr;
  const PcPresentPage({super.key, required this.pc, required this.onErr});

  void _k(String k, [List<String> mods = const []]) {
    HapticFeedback.mediumImpact();
    pc.input([
      {'t': 'key', 'k': k, 'mods': mods}
    ]).catchError(onErr);
  }

  @override
  Widget build(BuildContext context) {
    Widget big(String t, IconData i, VoidCallback f) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              onPressed: f,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 64), const SizedBox(height: 8), Text(t, style: const TextStyle(fontSize: 20))]),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('عرض تقديمي')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            OutlinedButton(onPressed: () => _k('f5'), child: const Text('ابدأ من الأول (F5)')),
            OutlinedButton(onPressed: () => _k('f5', ['shift']), child: const Text('من الشريحة دي')),
            OutlinedButton(onPressed: () => _k('b'), child: const Text('شاشة سودا (B)')),
            OutlinedButton(onPressed: () => _k('w'), child: const Text('شاشة بيضا (W)')),
            OutlinedButton(onPressed: () => _k('esc'), child: const Text('إنهاء (Esc)')),
          ]),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              big('السابقة', Icons.arrow_back_rounded, () => _k('left')),
              big('التالية', Icons.arrow_forward_rounded, () => _k('right')),
            ]),
          ),
        ),
        const Padding(padding: EdgeInsets.all(8), child: Text('بيشتغل مع PowerPoint وPDF وأغلب برامج العرض', style: TextStyle(color: kMuted, fontSize: 12))),
      ]),
    );
  }
}

// ---------------- نسخة احتياطية للإعدادات ----------------
/// المفاتيح اللي مش بتتنقل (توكن الكمبيوتر، القفل، الكاش المؤقت)
bool backupSkipKey(String k) {
  final l = k.toLowerCase();
  return l == 'pc_saved' || l.startsWith('app_lock') || l.contains('password') || l.contains('token') || l == 'oui_auto_tried' || l == 'router_last_ok' || l == 'bg_last';
}

Map<String, dynamic> buildBackup(Map<String, Object?> prefs, DateTime now) => {
      'app': 'A2R Home',
      'type': 'settings',
      'v': 1,
      'at': now.toIso8601String(),
      'prefs': {
        for (final e in prefs.entries)
          if (!backupSkipKey(e.key) && e.value != null)
            e.key: {
              't': e.value is bool ? 'b' : (e.value is int ? 'i' : (e.value is double ? 'd' : (e.value is List ? 'l' : 's'))),
              'v': e.value,
            }
      },
    };

/// بيرجع عدد المفاتيح أو يرمي FormatException
Future<int> restoreBackup(SharedPreferences p, String text) async {
  final d = jsonDecode(text);
  if (d is! Map || d['app'] != 'A2R Home' || d['prefs'] is! Map) throw const FormatException('الملف ده مش نسخة A2R Home');
  var n = 0;
  for (final e in (d['prefs'] as Map).entries) {
    final k = '${e.key}';
    if (backupSkipKey(k) || e.value is! Map) continue;
    final t = e.value['t'], v = e.value['v'];
    if (t == 'b' && v is bool) await p.setBool(k, v);
    if (t == 'i' && v is num) await p.setInt(k, v.toInt());
    if (t == 'd' && v is num) await p.setDouble(k, v.toDouble());
    if (t == 's' && v is String) await p.setString(k, v);
    if (t == 'l' && v is List) await p.setStringList(k, [for (final x in v) '$x']);
    n++;
  }
  return n;
}

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool lockOn = AppLock.enabled;

  Future<Uint8List> _bytes() async {
    final m = {for (final k in Store.p.getKeys()) k: Store.p.get(k)};
    return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent(' ').convert(buildBackup(m, DateTime.now()))));
  }

  String get _fname {
    final d = DateTime.now();
    return 'A2R-Home-backup-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.json';
  }

  Future<void> _save() async {
    try {
      final u = await FilePicker.saveFile(fileName: _fname, bytes: await _bytes(), mimeType: 'application/json', dialogTitle: 'احفظ النسخة (اختار Download)');
      if (mounted) toast(context, u == null ? 'اتلغى' : 'اتحفظت ✓');
    } catch (e) {
      if (mounted) toast(context, 'مقدرتش أحفظ: $e');
    }
  }

  Future<void> _share() async {
    final f = File('${(await getTemporaryDirectory()).path}/$_fname');
    await f.writeAsBytes(await _bytes());
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'نسخة إعدادات A2R Home'));
  }

  Future<void> _restore() async {
    final p = await FilePicker.pickFile(type: FileType.any);
    if (p == null) return;
    final f = await pickedToFile(p);
    if (f == null || !mounted) return;
    if (!await confirm(context, 'ترجّع الإعدادات من الملف ده؟ الإعدادات الحالية اللي بنفس الاسم هتتغير.')) return;
    try {
      final n = await restoreBackup(Store.p, await f.readAsString());
      await Schedule.rearm();
      await Quota.rearm();
      await NetWatch.rearm();
      if (mounted) toast(context, 'رجعت $n إعداد ✓ — اقفل التطبيق وافتحه تاني علشان كله يتحدّث');
    } catch (e) {
      if (mounted) toast(context, '$e'.replaceFirst('FormatException: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسخة احتياطية + قفل')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('النسخة فيها: أسماء الأجهزة، مواعيد الحظر، الباقة، المفضلة والمجموعات، العلامات، السجلات، إعدادات الكاست. '
            'مش فيها باسورد الراوتر (متخزن مشفّر على الموبايل بس) ولا ربط الكمبيوتر.',
            style: TextStyle(color: kMuted, height: 1.6)),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_alt_rounded), label: const Text('احفظ نسخة (Downloads)')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.share_rounded), label: const Text('شارك النسخة (واتساب/درايف…)')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _restore, icon: const Icon(Icons.restore_rounded), label: const Text('رجّع من نسخة')),
        const Divider(height: 32),
        SwitchListTile(
          value: lockOn,
          title: const Text('قفل التطبيق برقم سري'),
          subtitle: const Text('بيطلبه لما تفتح التطبيق أو ترجعله بعد دقيقة. لو نسيته مفيش استرجاع غير مسح بيانات التطبيق.', style: TextStyle(fontSize: 12, color: kMuted)),
          onChanged: (v) async {
            if (v) {
              final a = await askText(context, 'رقم سري (4-8 أرقام)', obscure: true, type: TextInputType.number);
              if (a == null || !RegExp(r'^\d{4,8}$').hasMatch(a)) {
                if (mounted && a != null) toast(context, 'لازم 4 لـ 8 أرقام');
                return;
              }
              if (!mounted) return;
              final b = await askText(context, 'اكتبه تاني', obscure: true, type: TextInputType.number);
              if (b != a) {
                if (mounted) toast(context, 'الرقمين مش زي بعض');
                return;
              }
              await AppLock.setPin(a);
            } else {
              if (!await AppLock.askAndVerify(context)) return;
              await AppLock.setPin(null);
            }
            setState(() => lockOn = AppLock.enabled);
          },
        ),
      ]),
    );
  }
}

// ---------------- قفل التطبيق ----------------
String pinHash(String salt, String pin) => sha256.convert(utf8.encode('a2r:$salt:$pin')).toString();

class AppLock {
  static bool get enabled => Store.p.getBool('app_lock_on') ?? false;
  static const _k = 'app_lock_pin';

  static Future<void> setPin(String? pin) async {
    if (pin == null) {
      await Store._sec.delete(key: _k);
      await Store.p.setBool('app_lock_on', false);
      return;
    }
    final salt = md5Hex('${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 30)}').substring(0, 16);
    await Store._sec.write(key: _k, value: '$salt:${pinHash(salt, pin)}');
    await Store.p.setBool('app_lock_on', true);
  }

  static Future<bool> verify(String pin) async {
    final s = await Store._sec.read(key: _k);
    if (s == null || !s.contains(':')) return true; // مفيش رقم محفوظ → منقفلش التطبيق على صاحبه
    final i = s.indexOf(':');
    return pinHash(s.substring(0, i), pin) == s.substring(i + 1);
  }

  static Future<bool> askAndVerify(BuildContext context) async {
    final p = await askText(context, 'الرقم السري', obscure: true, type: TextInputType.number);
    if (p == null) return false;
    final ok = await verify(p);
    if (!ok && context.mounted) toast(context, 'غلط');
    return ok;
  }
}

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});
  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool locked = AppLock.enabled;
  DateTime? _away;
  String entered = '';
  int bad = 0;
  DateTime? waitUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) _away = DateTime.now();
    if (s == AppLifecycleState.resumed && AppLock.enabled && _away != null && DateTime.now().difference(_away!).inSeconds >= 60) {
      setState(() {
        locked = true;
        entered = '';
      });
    }
  }

  Future<void> _digit(String d) async {
    if (waitUntil != null && DateTime.now().isBefore(waitUntil!)) return;
    HapticFeedback.selectionClick();
    setState(() => entered += d);
    if (entered.length < 4) return;
    if (await AppLock.verify(entered)) {
      setState(() {
        locked = false;
        entered = '';
        bad = 0;
      });
    } else if (entered.length >= 8) {
      _fail();
    }
  }

  void _fail() {
    bad++;
    HapticFeedback.heavyImpact();
    setState(() {
      entered = '';
      if (bad >= 5) {
        waitUntil = DateTime.now().add(const Duration(seconds: 30));
        bad = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!locked) return widget.child;
    // التطبيق نفسه بيفضل شغال تحت (علشان ميضيعش مكانك) والقفل فوقه
    return Stack(children: [Offstage(child: widget.child), Positioned.fill(child: _lockScreen())]);
  }

  Widget _lockScreen() {
    final wait = waitUntil != null && DateTime.now().isBefore(waitUntil!);
    Widget key(String t, {VoidCallback? f}) => Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 72,
            height: 72,
            child: OutlinedButton(style: OutlinedButton.styleFrom(shape: const CircleBorder()), onPressed: f ?? () => _digit(t), child: Text(t, style: const TextStyle(fontSize: 24))),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_rounded, size: 48, color: kGold),
            const SizedBox(height: 12),
            Text(wait ? 'استنى 30 ثانية' : 'اكتب الرقم السري', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('•' * entered.length, style: const TextStyle(fontSize: 32, letterSpacing: 8, color: kGold)),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(children: [
                for (final row in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                ])
                  Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d)]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  key('⌫', f: () => setState(() => entered = entered.isEmpty ? '' : entered.substring(0, entered.length - 1))),
                  key('0'),
                  key('✓', f: entered.length >= 4 ? _fail : null),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}


// ======== toto_v5.dart ========
// الأكسس بوينت TOTOLINK N300RT (فيرموير Realtek "boa" القديم)
// المبدأ: التطبيق مش بيخمّن أسماء فورمات — بيقرا صفحات الجهاز نفسه ويبعت نفس الفورم اللي الصفحة فيها
// بنفس القيم الحالية ويغيّر الحقل المطلوب بس. أي حاجة خطيرة ممنوعة في الكود (قايمة حظر).

class HtmlOption {
  final String value, text;
  final bool selected;
  HtmlOption(this.value, this.text, this.selected);
}

class HtmlField {
  final String name, type, value;
  final bool checked;
  final int? maxLength;
  final List<HtmlOption> options;
  HtmlField(this.name, this.type, this.value, {this.checked = false, this.maxLength, this.options = const []});
  bool get isButton => type == 'submit' || type == 'button' || type == 'reset' || type == 'image';
  String get selectedValue {
    final s = options.where((o) => o.selected).firstOrNull ?? options.firstOrNull;
    return s?.value ?? '';
  }

  String get selectedText => (options.where((o) => o.selected).firstOrNull ?? options.firstOrNull)?.text ?? '';
}

class HtmlForm {
  final String page, action, method, name;
  final List<HtmlField> fields;
  final String body; // HTML جوه الفورم
  HtmlForm(this.page, this.action, this.method, this.name, this.fields, this.body);
  HtmlField? field(bool Function(HtmlField f) t) => fields.where(t).firstOrNull;
  Iterable<HtmlField> get dataFields => fields.where((f) => !f.isButton && f.name.isNotEmpty);
  Iterable<HtmlField> get buttons => fields.where((f) => f.isButton && f.name.isNotEmpty);
  String describe() {
    final b = StringBuffer('FORM page=$page action=$action method=$method name=$name\n');
    for (final f in fields) {
      final secret = totoIsSecretName(f.name) || f.type == 'password';
      b.write('  ${f.type} ${f.name}=${secret ? '***' : f.value}');
      if (f.type == 'checkbox' || f.type == 'radio') b.write(f.checked ? ' [x]' : ' [ ]');
      if (f.maxLength != null) b.write(' max=${f.maxLength}');
      if (f.options.isNotEmpty) b.write(' {${f.options.map((o) => '${o.selected ? '*' : ''}${o.value}:${o.text}').join(', ')}}');
      b.writeln();
    }
    return b.toString();
  }
}

String htmlDecode(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)));

String stripTags(String s) => htmlDecode(s.replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ').replaceAll(RegExp(r'<[^>]*>'), ' '))
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// خصائص التاج: name="x" name='x' name=x و checked لوحدها
Map<String, String> attrsOf(String tag) {
  final out = <String, String>{};
  final inner = tag.replaceFirst(RegExp(r'^<\s*[A-Za-z]+'), '').replaceFirst(RegExp(r'/?>$'), '');
  for (final m in RegExp(r'''([A-Za-z_:][-A-Za-z0-9_:.]*)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?''').allMatches(inner)) {
    out[m[1]!.toLowerCase()] = htmlDecode(m[2] ?? m[3] ?? m[4] ?? '');
  }
  return out;
}

List<HtmlForm> parseForms(String html, String page) {
  final out = <HtmlForm>[];
  final noComments = html.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  for (final fm in RegExp(r'<form\b([^>]*)>([\s\S]*?)(?:</form>|(?=<form\b)|$)', caseSensitive: false).allMatches(noComments)) {
    final fa = attrsOf('<form${fm[1]}>');
    final body = fm[2]!;
    final fields = <HtmlField>[];
    for (final m in RegExp(r'<(input|select|textarea)\b([^>]*)>([\s\S]*?</select>|[\s\S]*?</textarea>)?', caseSensitive: false).allMatches(body)) {
      final tag = m[1]!.toLowerCase();
      final a = attrsOf('<$tag${m[2]}>');
      final name = a['name'] ?? '';
      final ml = int.tryParse(a['maxlength'] ?? '');
      if (tag == 'input') {
        fields.add(HtmlField(name, (a['type'] ?? 'text').toLowerCase(), a['value'] ?? '', checked: a.containsKey('checked'), maxLength: ml));
      } else if (tag == 'select') {
        final opts = <HtmlOption>[];
        for (final o in RegExp(r'<option\b([^>]*)>([^<]*)', caseSensitive: false).allMatches(m[3] ?? '')) {
          final oa = attrsOf('<option${o[1]}>');
          final text = htmlDecode(o[2]!).trim();
          opts.add(HtmlOption(oa['value'] ?? text, text, oa.containsKey('selected')));
        }
        fields.add(HtmlField(name, 'select', '', options: opts));
      } else {
        final t = (m[3] ?? '').replaceFirst(RegExp(r'</textarea>$', caseSensitive: false), '');
        fields.add(HtmlField(name, 'textarea', htmlDecode(t), maxLength: ml));
      }
    }
    out.add(HtmlForm(page, fa['action'] ?? '', (fa['method'] ?? 'get').toLowerCase(), fa['name'] ?? fa['id'] ?? '', fields, body));
  }
  return out;
}

// ---- الأمان: قايمة الحظر ----
const List<String> kTotoBlockWords = [
  'upload', 'reset', 'default', 'factory', 'syscmd', 'wps', 'wsc', 'upgrade', 'firmware', 'flash', 'config', 'saveconf', 'reload',
  'opmode', 'operation', 'wan', 'repeater', 'vxd', 'wisp', 'tcpip', 'lan_ip', 'lanip', 'dhcp', 'passwordsetup', 'password', 'admin',
  'ntp', 'ping', 'diag', 'tracert', 'syslog', 'telnet', 'ssh', 'remote', 'ddns', 'dmz', 'route', 'iptv', 'vpn', 'schedule', 'cmd', 'shell',
];

/// الحقول اللي ممكن نغيّرها (لو نفس الكلمة في قايمة الحظر بنستثنيها لحقل واحد بالاسم ده بس)
bool totoIsSecretName(String n) => RegExp(r'pass|psk|pwd|key|secret', caseSensitive: false).hasMatch(n);

/// سبب منع الفورم (null = مسموح). بيبص على الـ action واسم الفورم وكل الحقول (مش الزراير اللي مش هنبعتها)
String? totoBlockReason(HtmlForm f, {Set<String> allowNames = const {}}) {
  String? hit(String s) {
    final l = s.toLowerCase();
    for (final w in kTotoBlockWords) {
      if (l.contains(w)) return w;
    }
    return null;
  }

  final a = hit(f.action) ?? hit(f.name);
  if (a != null) return 'الفورم ($a) ممنوع';
  for (final x in f.dataFields) {
    if (allowNames.contains(x.name)) continue;
    // "submit-url" عادي في Realtek
    if (x.name.toLowerCase() == 'submit-url') continue;
    final h = hit(x.name);
    if (h != null) return 'فيه حقل ممنوع (${x.name})';
  }
  if (f.fields.any((x) => x.type == 'file')) return 'فورم رفع ملفات ممنوع';
  if (!f.action.contains('boafrm/') && !f.action.toLowerCase().startsWith('/goform/') && !f.action.toLowerCase().startsWith('goform/')) {
    return 'الفورم مش بيروح لـ boafrm (${f.action.isEmpty ? 'فاضي' : f.action})';
  }
  return null;
}

/// حقول قيمتها بتتملا بالجافاسكريبت لما الصفحة تفتح (يبقى القيمة اللي في الـ HTML مش الحقيقية)
Set<String> jsFilledFields(String html, Iterable<String> names) {
  final scripts = RegExp(r'<script[^>]*>([\s\S]*?)</script>', caseSensitive: false).allMatches(html).map((m) => m[1]!).join('\n');
  final out = <String>{};
  for (final n in names) {
    if (n.isEmpty) continue;
    final e = RegExp.escape(n);
    if (RegExp('(\\.|\\[["\'])$e(["\']\\])?\\s*\\.\\s*(value|checked|selectedIndex|defaultChecked)\\s*=(?!=)').hasMatch(scripts) ||
        RegExp('getElementById\\(\\s*["\']$e["\']\\s*\\)\\s*\\.\\s*(value|checked|selectedIndex)\\s*=(?!=)').hasMatch(scripts)) {
      out.add(n);
    }
  }
  return out;
}

/// البيانات اللي هتتبعت: نفس القيم الحالية + التغيير + زرار الإرسال
Map<String, String> formPayload(HtmlForm f, Map<String, String> changes, {String? submit}) {
  final out = <String, String>{};
  for (final x in f.dataFields) {
    if (x.type == 'checkbox' || x.type == 'radio') {
      if (x.checked) out[x.name] = x.value.isEmpty ? 'on' : x.value;
    } else if (x.type == 'select') {
      out[x.name] = x.selectedValue;
    } else {
      out[x.name] = x.value;
    }
  }
  out.addAll(changes);
  if (submit != null) {
    final b = f.buttons.where((x) => x.name == submit).firstOrNull;
    if (b != null) out[b.name] = b.value;
  }
  return out;
}

String totoMask(String s) => s.replaceAllMapped(
    RegExp(r'(^|[&?\s])([A-Za-z0-9_\-]*(?:pass|psk|pwd|key|secret)[A-Za-z0-9_\-]*)=([^&\s]*)', caseSensitive: false), (m) => '${m[1]}${m[2]}=***');

/// روابط الصفحات من HTML/JS (href/src/location/نصوص فيها .htm)
List<String> discoverPages(String html) {
  final out = <String>{};
  for (final m in RegExp(r'''["'=\s(]/?([A-Za-z0-9_\-/]+\.(?:htm|html|asp))(?:[?#][^"'\s)]*)?''', caseSensitive: false).allMatches(html)) {
    final p = '/${m[1]!.replaceFirst(RegExp(r'^/+'), '')}';
    if (totoPageSafe(p)) out.add(p);
  }
  return out.toList();
}

/// الصفحات اللي ينفع نفتحها GET (قراية بس)
bool totoPageSafe(String p) {
  final l = p.toLowerCase();
  if (!RegExp(r'^/[a-z0-9_\-/]+\.(htm|html|asp)$').hasMatch(l)) return false;
  for (final w in ['boafrm', 'goform', 'cgi', 'syscmd', 'upgrade', 'upload', 'config', 'logout', 'reboot_now']) {
    if (l.contains(w)) return false;
  }
  return true;
}

class HtmlRow {
  final List<String> cells;
  final String html;
  HtmlRow(this.cells, this.html);
}

List<HtmlRow> tableRows(String html) => [
      for (final r in RegExp(r'<tr\b[^>]*>([\s\S]*?)(?=<tr\b|</table>|$)', caseSensitive: false).allMatches(html))
        HtmlRow([for (final c in RegExp(r'<t[dh]\b[^>]*>([\s\S]*?)(?=<t[dh]\b|</tr>|$)', caseSensitive: false).allMatches(r[1]!)) stripTags(c[1]!)], r[0]!)
    ];

final RegExp kMacRe = RegExp(r'\b([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}\b|\b[0-9A-Fa-f]{12}\b');
final RegExp kIpRe = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');

class TotoClient {
  final String mac;
  String ip = '', name = '', extra = '', page = '';
  TotoClient(this.mac);
}

/// صفوف فيها MAC → عملاء (من جدول الواي فاي أو DHCP)
List<TotoClient> clientsFromRows(List<HtmlRow> rows, String page) {
  final out = <TotoClient>[];
  for (final r in rows) {
    if (r.html.toLowerCase().contains('<table')) continue; // صف بيلف جدول جوه جدول
    final macCell = r.cells.indexWhere((c) => kMacRe.hasMatch(c) && c.length <= 20);
    if (macCell < 0) continue;
    final c = TotoClient(normMac(kMacRe.firstMatch(r.cells[macCell])![0]!));
    final rest = <String>[];
    for (var i = 0; i < r.cells.length; i++) {
      if (i == macCell) continue;
      final v = r.cells[i];
      if (c.ip.isEmpty && kIpRe.hasMatch(v)) {
        c.ip = kIpRe.firstMatch(v)![0]!;
      } else if (v.isNotEmpty && v.length <= 40) {
        rest.add(v);
      }
    }
    final nm = rest.where((v) => RegExp(r'[A-Za-z]').hasMatch(v) && !RegExp(r'^(yes|no|on|off|\d+(\.\d+)?\s*\w{0,4})$', caseSensitive: false).hasMatch(v)).firstOrNull;
    c.name = nm ?? '';
    c.extra = rest.where((v) => v != nm).join(' • ');
    c.page = page;
    out.add(c);
  }
  return out;
}

/// جداول الحالة: "عنوان | قيمة"
List<MapEntry<String, String>> statusPairs(String html) {
  final out = <MapEntry<String, String>>[];
  for (final r in tableRows(html)) {
    if (r.cells.length == 2 && r.cells[0].isNotEmpty && r.cells[0].length < 40 && r.cells[1].isNotEmpty && r.cells[1].length < 80) {
      out.add(MapEntry(r.cells[0].replaceFirst(RegExp(r'\s*:\s*$'), ''), r.cells[1]));
    }
  }
  return out;
}

/// لو الصفحة صفحة دخول: نوعها
class TotoLogin {
  final String kind; // basic / form / none / captcha
  final HtmlForm? form;
  final String note;
  TotoLogin(this.kind, {this.form, this.note = ''});
}

TotoLogin detectLogin(int status, String? wwwAuth, String body, String page) {
  if (status == 401 && (wwwAuth ?? '').toLowerCase().contains('basic')) return TotoLogin('basic');
  for (final f in parseForms(body, page)) {
    if (f.fields.any((x) => x.type == 'password')) {
      if (f.dataFields.any((x) => RegExp(r'captcha|verif|code|check_?num', caseSensitive: false).hasMatch(x.name) && x.type != 'hidden')) {
        return TotoLogin('captcha', form: f, note: 'صفحة الدخول فيها كود تحقق — استخدم صفحة الجهاز');
      }
      final js = RegExp(r'hex_md5|md5\(|base64|btoa\(|encrypt', caseSensitive: false).hasMatch(body);
      return TotoLogin('form', form: f, note: js ? 'صفحة الدخول ممكن تشفّر الباسورد بالجافاسكريبت قبل ما تبعته' : '');
    }
  }
  return TotoLogin('none');
}

/// يبني الدخول من فورم الجهاز نفسه
Map<String, String> loginPayload(HtmlForm f, String user, String pass) {
  final ch = <String, String>{};
  for (final x in f.dataFields) {
    if (x.type == 'password') {
      ch[x.name] = pass;
    } else if ((x.type == 'text' || x.type == 'email') && RegExp(r'user|name|login|account', caseSensitive: false).hasMatch(x.name)) {
      ch[x.name] = user;
    }
  }
  final sub = f.buttons.where((b) => b.type == 'submit').firstOrNull?.name;
  return formPayload(f, ch, submit: sub);
}

/// اختيار عنوان فاضي للأكسس في شبكة البيت: برا مدى الـ DHCP ومش مستخدم
List<String> suggestApIps(String prefix, {int? dhcpStart, int? dhcpEnd, required Set<String> used}) {
  final out = <String>[];
  bool inDhcp(int n) => dhcpStart != null && dhcpEnd != null && n >= dhcpStart && n <= dhcpEnd;
  for (var n = 250; n >= 200 && out.length < 6; n--) {
    final ip = '$prefix.$n';
    if (!inDhcp(n) && !used.contains(ip)) out.add(ip);
  }
  if (out.isEmpty && dhcpStart != null && dhcpStart > 3) {
    for (var n = dhcpStart - 1; n >= 2 && out.length < 6; n--) {
      final ip = '$prefix.$n';
      if (!used.contains(ip)) out.add(ip);
    }
  }
  return out;
}

int? lastOctet(String? ip) {
  final p = (ip ?? '').split('.');
  return p.length == 4 ? int.tryParse(p[3]) : null;
}

String prefixOf(String ip) {
  final p = ip.split('.');
  return p.length == 4 ? '${p[0]}.${p[1]}.${p[2]}' : '';
}

// ---- تخزين ----
class TotoStore {
  static String get ip => Store.p.getString('toto_ip') ?? '192.168.2.2';
  static set ip(String v) => Store.p.setString('toto_ip', v);
  static String get user => Store.p.getString('toto_user') ?? 'admin';
  static set user(String v) => Store.p.setString('toto_user', v);
  static Future<String?> pass() => Store._sec.read(key: 'toto_pw');
  static Future<void> savePass(String? v) => v == null ? Store._sec.delete(key: 'toto_pw') : Store._sec.write(key: 'toto_pw', value: v);
  /// الأجهزة اللي جدول الأكسس قال إنها متوصلة بيه (MAC)
  static Set<String> get macs => (Store.p.getStringList('toto_macs') ?? []).toSet();
  static set macs(Set<String> v) => Store.p.setStringList('toto_macs', v.toList());
}

// ---- الاتصال بالجهاز ----
class TotoDevice {
  final String host;
  String kind = 'none';
  String? _basic;
  final Map<String, String> cookies = {};
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);
  final Map<String, String> pages = {}; // path → html
  TotoDevice(this.host) {
    _http.badCertificateCallback = (c, h, p) => h == host;
  }

  void close() => _http.close(force: true);

  Future<({int status, Map<String, String> headers, String body})> _req(String method, String path, {Map<String, String>? form, String? referer}) async {
    final uri = Uri.parse('http://$host${path.startsWith('/') ? '' : '/'}$path');
    final rq = await _http.openUrl(method, uri).timeout(const Duration(seconds: 6));
    rq.followRedirects = false;
    if (_basic != null) rq.headers.set('Authorization', 'Basic $_basic');
    if (cookies.isNotEmpty) rq.headers.set('Cookie', cookies.entries.map((e) => '${e.key}=${e.value}').join('; '));
    rq.headers.set('Referer', referer ?? 'http://$host/');
    String? bodyStr;
    if (form != null) {
      bodyStr = form.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
      rq.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
      rq.contentLength = utf8.encode(bodyStr).length;
      rq.write(bodyStr);
    }
    final rs = await rq.close().timeout(const Duration(seconds: 8));
    final bytes = await rs.fold<List<int>>([], (a, b) => a..addAll(b)).timeout(const Duration(seconds: 10));
    final body = utf8.decode(bytes, allowMalformed: true);
    final h = <String, String>{};
    rs.headers.forEach((k, v) => h[k] = v.join(', '));
    for (final c in rs.cookies) {
      cookies[c.name] = c.value;
    }
    AppLog.add('TOTO', '$method $path${bodyStr == null ? '' : ' body=${totoMask(bodyStr)}'} → ${rs.statusCode} '
        'server=${h['server'] ?? '-'} loc=${h['location'] ?? '-'} auth=${h['www-authenticate'] ?? '-'} len=${bytes.length}');
    return (status: rs.statusCode, headers: h, body: body);
  }

  /// GET لصفحة آمنة بس
  Future<({int status, Map<String, String> headers, String body})> get(String path) async {
    if (!totoPageSafe(path) && path != '/') throw StateError('الصفحة دي مش مسموح أفتحها: $path');
    var r = await _req('GET', path);
    for (var i = 0; i < 2 && (r.status == 301 || r.status == 302 || r.status == 303) && (r.headers['location'] ?? '').isNotEmpty; i++) {
      final l = Uri.parse(r.headers['location']!);
      if (l.host.isNotEmpty && l.host != host) break;
      if (!totoPageSafe(l.path) && l.path != '/') break;
      r = await _req('GET', l.path);
    }
    return r;
  }

  /// هل ده TOTOLINK / Realtek boa؟
  Future<String?> identify() async {
    final r = await get('/');
    final b = r.body.toLowerCase();
    final s = (r.headers['server'] ?? '').toLowerCase();
    final hit = b.contains('totolink') || s.contains('boa') || b.contains('boafrm') || b.contains('home.htm') || (r.headers['www-authenticate'] ?? '').toLowerCase().contains('totolink');
    AppLog.add('TOTO', 'identify $host server=${r.headers['server']} title=${RegExp(r'<title>([^<]*)', caseSensitive: false).firstMatch(r.body)?.group(1)} hit=$hit');
    return hit ? (r.headers['server'] ?? 'web') : null;
  }

  /// محاولة دخول واحدة. بيرجع رسالة خطأ أو null لو تمام
  Future<String?> login(String user, String pass) async {
    var r = await get('/home.htm');
    var page = '/home.htm';
    // تحويل بالجافاسكريبت لصفحة الدخول
    final jsLoc = RegExp(r'''location(?:\.href)?\s*=\s*["']/?([A-Za-z0-9_\-/]+\.(?:htm|html|asp))''').firstMatch(r.body)?.group(1);
    if (r.status == 200 && jsLoc != null && !r.body.toLowerCase().contains('type="password"') && totoPageSafe('/$jsLoc') && r.body.length < 3000) {
      page = '/$jsLoc';
      r = await get(page);
    }
    var lg = detectLogin(r.status, r.headers['www-authenticate'], r.body, page);
    if (lg.kind == 'none' && r.status == 200) {
      kind = 'none';
      pages[page] = r.body;
      return null; // مفتوح من غير دخول (أو الجلسة لسه شغالة)
    }
    if (lg.kind == 'captcha') return lg.note;
    if (lg.kind == 'basic') {
      _basic = base64.encode(utf8.encode('$user:$pass'));
      final r2 = await get('/home.htm');
      if (r2.status == 401) {
        _basic = null;
        return 'اسم المستخدم أو الباسورد غلط';
      }
      kind = 'basic';
      pages['/home.htm'] = r2.body;
      return null;
    }
    if (lg.kind == 'form' && lg.form != null) {
      final f = lg.form!;
      if (lg.note.isNotEmpty) AppLog.add('TOTO', 'تنبيه: ${lg.note}');
      AppLog.add('TOTO', 'login form:\n${f.describe()}');
      final action = f.action.isEmpty ? page : (f.action.startsWith('/') ? f.action : '/${f.action}');
      if (!action.toLowerCase().contains('login') && !action.toLowerCase().contains('boafrm')) return 'فورم الدخول غريب ($action) — مش هبعت الباسورد له';
      final p = await _req('POST', action, form: loginPayload(f, user, pass), referer: 'http://$host$page');
      if (p.status >= 400) return 'الجهاز رفض الدخول (${p.status})';
      final r2 = await get('/home.htm');
      final again = detectLogin(r2.status, r2.headers['www-authenticate'], r2.body, '/home.htm');
      if (again.kind != 'none') return 'الدخول مانفعش — الباسورد غلط${lg.note.isNotEmpty ? ' أو ${lg.note}' : ''}';
      kind = 'form';
      pages['/home.htm'] = r2.body;
      return null;
    }
    return 'مش لاقي صفحة دخول مفهومة (${r.status})';
  }

  static const List<String> kExtraPages = ['/status.htm', '/wlstatbl.htm', '/dhcptbl.htm', '/wlactrl.htm', '/wlbasic.htm', '/wlwpa.htm', '/reboot.htm', '/menu.htm'];

  /// يقرا صفحات الجهاز (من القايمة + أسماء Realtek المعروفة) — GET بس
  Future<void> crawl({int maxPages = 40}) async {
    final queue = <String>[...pages.keys, '/home.htm', ...kExtraPages];
    final seen = <String>{};
    while (queue.isNotEmpty && seen.length < maxPages) {
      final p = queue.removeAt(0);
      if (!seen.add(p)) continue;
      try {
        final r = pages.containsKey(p) && p != '/home.htm' ? null : await get(p);
        if (r != null) {
          if (r.status != 200) continue;
          if (detectLogin(r.status, null, r.body, p).kind != 'none') continue;
          pages[p] = r.body;
        }
        for (final n in discoverPages(pages[p] ?? '')) {
          if (!seen.contains(n)) queue.add(n);
        }
      } catch (e) {
        AppLog.add('TOTO', 'GET $p ✗ $e');
      }
    }
  }

  List<HtmlForm> get forms => [for (final e in pages.entries) ...parseForms(e.value, e.key)];

  /// بيبعت فورم الجهاز (بعد كل فحوص الأمان)
  Future<int> submit(HtmlForm f, Map<String, String> payload) async {
    final reason = totoBlockReason(f, allowNames: payload.keys.where((k) => !f.dataFields.any((x) => x.name == k)).toSet());
    if (reason != null) throw StateError('ممنوع: $reason');
    final action = f.action.startsWith('/') ? f.action : '/${f.action}';
    final r = f.method == 'post' ? await _req('POST', action, form: payload, referer: 'http://$host${f.page}') : throw StateError('الفورم مش POST');
    return r.status;
  }
}

/// فحص قبل أي تغيير: ممنوع + قيم بتتملا بالجافاسكريبت
String? totoPreflight(HtmlForm f, String pageHtml, Set<String> changing) {
  final b = totoBlockReason(f);
  if (b != null) return b;
  final js = jsFilledFields(pageHtml, f.dataFields.map((x) => x.name).where((n) => !changing.contains(n)));
  if (js.isNotEmpty) return 'الصفحة بتملا قيم (${js.take(4).join('، ')}) بالجافاسكريبت — لو بعتّ هيتبعت قيم غلط';
  if (f.method != 'post') return 'الفورم مش POST';
  return null;
}

/// يلاقي فورم الريستارت (مش جدول الريستارت)
HtmlForm? findRebootForm(List<HtmlForm> forms) => forms.where((f) {
      final a = '${f.action} ${f.name}'.toLowerCase();
      return a.contains('reboot') && !a.contains('sche') && !f.dataFields.any((x) => x.type == 'text' || x.type == 'select');
    }).firstOrNull;

/// اسم الشبكة: فورم فيه ssid ونوعه AP (مش Client/WDS)
({HtmlForm form, HtmlField ssid})? findSsidForm(List<HtmlForm> forms) {
  for (final f in forms) {
    final s = f.field((x) => RegExp(r'^ssid\d*$', caseSensitive: false).hasMatch(x.name) && x.type == 'text');
    if (s == null) continue;
    final mode = f.field((x) => RegExp(r'^mode\d*$', caseSensitive: false).hasMatch(x.name) && x.type == 'select');
    if (mode == null) continue;
    final t = mode.selectedText.toLowerCase();
    if (!t.contains('ap') || t.contains('client') || t.contains('wds')) continue;
    return (form: f, ssid: s);
  }
  return null;
}

({HtmlForm form, HtmlField key})? findWifiKeyForm(List<HtmlForm> forms) {
  for (final f in forms) {
    final k = f.field((x) => RegExp(r'^(psk_?value|wpa_?psk|pskValue)\d*$', caseSensitive: false).hasMatch(x.name) && (x.type == 'password' || x.type == 'text'));
    if (k != null) return (form: f, key: k);
  }
  return null;
}

/// فورم إضافة MAC للحظر: فيه حقل mac + اختيار (معطّل/مسموح/ممنوع)
({HtmlForm form, HtmlField mac, HtmlField? mode, HtmlOption? deny, HtmlField? comment, String? addBtn})? findMacAddForm(List<HtmlForm> forms) {
  for (final f in forms) {
    final mac = f.field((x) => RegExp(r'^mac(addr)?\d*$', caseSensitive: false).hasMatch(x.name) && x.type == 'text');
    if (mac == null) continue;
    final mode = f.field((x) => x.type == 'select' && x.options.any((o) => o.text.toLowerCase().contains('deny')));
    final deny = mode?.options.where((o) => o.text.toLowerCase().contains('deny')).firstOrNull;
    final comment = f.field((x) => RegExp(r'comment|desc', caseSensitive: false).hasMatch(x.name) && x.type == 'text');
    final add = f.buttons.where((b) => RegExp(r'add', caseSensitive: false).hasMatch(b.name)).firstOrNull?.name;
    return (form: f, mac: mac, mode: mode, deny: deny, comment: comment, addBtn: add);
  }
  return null;
}

/// فورم مسح MAC: صف فيه الـ MAC + checkbox + زرار "Delete Selected" (مش Delete All)
({HtmlForm form, String checkbox, String delBtn})? findMacDelete(List<HtmlForm> forms, String mac) {
  final hex = mac.replaceAll(':', '').toUpperCase();
  for (final f in forms) {
    final del = f.buttons.where((b) => RegExp(r'del', caseSensitive: false).hasMatch(b.name) && !RegExp(r'all', caseSensitive: false).hasMatch('${b.name} ${b.value}')).firstOrNull;
    if (del == null) continue;
    for (final r in tableRows(f.body)) {
      if (!r.cells.any((c) => c.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase() == hex)) continue;
      final cb = RegExp(r'<input\b[^>]*>', caseSensitive: false).allMatches(r.html).map((m) => attrsOf(m[0]!)).where((a) => (a['type'] ?? '').toLowerCase() == 'checkbox').firstOrNull;
      if (cb != null && (cb['name'] ?? '').isNotEmpty) return (form: f, checkbox: cb['name']!, delBtn: del.name);
    }
  }
  return null;
}

String macForField(String mac, HtmlField f) => (f.maxLength != null && f.maxLength! <= 12) ? mac.replaceAll(':', '').toUpperCase() : normMac(mac);

/// يدوّر على صفحة TOTOLINK في شبكة الموبايل
Future<List<String>> scanForToto(String prefix, {List<String> extra = const []}) async {
  final cands = <String>{...extra, '$prefix.1', '$prefix.2', '$prefix.254'};
  final open = <String>[];
  final ips = [for (var i = 1; i < 255; i++) '$prefix.$i'];
  for (var i = 0; i < ips.length; i += 32) {
    await Future.wait(ips.skip(i).take(32).map((ip) async {
      try {
        final s = await Socket.connect(ip, 80, timeout: const Duration(milliseconds: 350));
        s.destroy();
        open.add(ip);
      } catch (_) {}
    }));
  }
  cands.addAll(open);
  final found = <String>[];
  await Future.wait(cands.map((ip) async {
    final d = TotoDevice(ip);
    try {
      if (await d.identify() != null) found.add(ip);
    } catch (_) {
    } finally {
      d.close();
    }
  }));
  AppLog.add('TOTO', 'scan $prefix.x → web=${open.length} totolink=$found');
  return found;
}

Future<bool> port80Open(String ip) async {
  try {
    final s = await Socket.connect(ip, 80, timeout: const Duration(milliseconds: 1500));
    s.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

// ---- الشاشة ----
class TotoPage extends StatefulWidget {
  final ZteRouter? router;
  final List<LanHost> hosts;
  final String Function(LanHost) labelOf;
  const TotoPage({super.key, required this.router, required this.hosts, required this.labelOf});
  @override
  State<TotoPage> createState() => _TotoPageState();
}

class _TotoPageState extends State<TotoPage> {
  final ipC = TextEditingController(text: TotoStore.ip);
  TotoDevice? dev;
  bool busy = false;
  String status = '';
  bool? reachable;
  PhoneNet? net;
  List<String> suggest = [];
  String dhcpInfo = '';
  List<TotoClient> clients = [];
  List<MapEntry<String, String>> info = [];

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    dev?.close();
    super.dispose();
  }

  Future<void> _run(String msg, Future<void> Function() f) async {
    if (busy) return;
    setState(() {
      busy = true;
      status = msg;
    });
    try {
      await f();
    } catch (e) {
      AppLog.add('TOTO', '✗ $e');
      if (mounted) setState(() => status = '$e'.replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _check() => _run('بشوف الأكسس…', () async {
        net = await readPhoneNet();
        final ip = ipC.text.trim();
        reachable = await port80Open(ip);
        status = reachable! ? 'الأكسس رد على $ip' : 'الأكسس مش بيرد على $ip';
        if (!reachable! && net?.prefix.isNotEmpty == true && prefixOf(ip) != net!.prefix) await _suggest();
      });

  Future<void> _suggest() async {
    final prefix = net?.prefix ?? '';
    if (prefix.isEmpty) return;
    int? s, e;
    if (widget.router != null) {
      try {
        final j = await widget.router!.get(['lan_ipaddr', 'lan_netmask', 'dhcpEnabled', 'dhcpStart', 'dhcpEnd']);
        AppLog.add('TOTO', 'ZTE DHCP raw: $j');
        if (prefixOf('${j['dhcpStart']}') == prefix) s = lastOctet('${j['dhcpStart']}');
        if (prefixOf('${j['dhcpEnd']}') == prefix) e = lastOctet('${j['dhcpEnd']}');
      } catch (err) {
        AppLog.add('TOTO', 'ZTE DHCP read ✗ $err');
      }
    }
    dhcpInfo = s != null && e != null ? 'الراوتر بيوزّع من $prefix.$s لـ $prefix.$e' : 'مقدرتش أقرا مدى الـ DHCP من الراوتر — اتأكد إن العنوان برا المدى من صفحة الراوتر';
    final used = {for (final h in widget.hosts) h.ip, net?.ip ?? '', net?.gateway ?? ''};
    final c = suggestApIps(prefix, dhcpStart: s, dhcpEnd: e, used: used);
    final free = <String>[];
    for (final ip in c) {
      if (free.length >= 2) break;
      final alive = await probeHost(ip, ports: const [80, 443, 22, 53]) != null || await pingOnce(ip) != null;
      if (!alive) free.add(ip);
    }
    suggest = free;
  }

  Future<void> _scan() => _run('بدوّر على الأكسس في الشبكة…', () async {
        net ??= await readPhoneNet();
        final extra = [for (final h in widget.hosts) if (RegExp(r'toto|zioncom', caseSensitive: false).hasMatch(h.vendor + h.name)) h.ip];
        final f = await scanForToto(net!.prefix, extra: extra);
        if (f.isEmpty) {
          status = 'ملقتش صفحة TOTOLINK على ${net!.prefix}.x';
        } else {
          ipC.text = f.first;
          TotoStore.ip = f.first;
          reachable = true;
          status = 'لقيته على ${f.join('، ')}';
        }
      });

  Future<void> _login() async {
    final ip = ipC.text.trim();
    if (!isIpv4(ip)) {
      toast(context, 'العنوان مش مظبوط');
      return;
    }
    TotoStore.ip = ip;
    var pw = await TotoStore.pass();
    if (!mounted) return;
    if (pw == null) {
      final u = await askText(context, 'اسم المستخدم', initial: TotoStore.user);
      if (u == null || !mounted) return;
      TotoStore.user = u.trim().isEmpty ? 'admin' : u.trim();
      pw = await askText(context, 'باسورد صفحة الأكسس', obscure: true);
      if (pw == null) return;
    }
    final pass = pw;
    await _run('بدخل (محاولة واحدة)…', () async {
      dev?.close();
      final d = TotoDevice(ip);
      final err = await d.login(TotoStore.user, pass);
      if (err != null) {
        d.close();
        await TotoStore.savePass(null);
        status = err;
        return;
      }
      await TotoStore.savePass(pass);
      dev = d;
      status = 'دخلت ✓ — بقرا الصفحات…';
      if (mounted) setState(() {});
      await _read();
    });
  }

  Future<void> _read() async {
    final d = dev!;
    d.pages.removeWhere((k, v) => k != '/home.htm');
    await d.crawl();
    final cl = <String, TotoClient>{};
    final inf = <MapEntry<String, String>>[];
    for (final e in d.pages.entries) {
      final l = e.key.toLowerCase();
      if (l.contains('status') || l.contains('home')) inf.addAll(statusPairs(e.value));
      final isAcl = l.contains('ac') && l.contains('ctrl') || l.contains('filter');
      if (isAcl) continue;
      if (RegExp(r'sta|client|dhcp|tbl', caseSensitive: false).hasMatch(l)) {
        for (final c in clientsFromRows(tableRows(e.value), e.key)) {
          final ex = cl[c.mac];
          if (ex == null) {
            cl[c.mac] = c;
          } else {
            if (ex.ip.isEmpty) ex.ip = c.ip;
            if (ex.name.isEmpty) ex.name = c.name;
          }
        }
      }
    }
    final seen = <String>{};
    info = [for (final e in inf) if (seen.add(e.key)) e];
    clients = cl.values.toList();
    TotoStore.macs = {for (final c in clients) c.mac};
    status = 'اتقرا ${d.pages.length} صفحة • ${clients.length} جهاز على الأكسس • ${d.forms.length} فورم';
    AppLog.add('TOTO', status);
  }

  void _dumpForms() {
    final d = dev;
    if (d == null) return;
    AppLog.add('TOTO', '===== صفحات الأكسس (${d.pages.length}) =====');
    for (final e in d.pages.entries) {
      AppLog.add('TOTO', 'PAGE ${e.key} len=${e.value.length} links=${discoverPages(e.value).join(' ')}');
    }
    for (final f in d.forms) {
      final why = totoBlockReason(f);
      AppLog.add('TOTO', '${f.describe()}  → ${why == null ? 'مسموح' : 'ممنوع: $why'}');
    }
    toast(context, 'اتكتبت في السجل ✓ — افتح السجل وشاركه');
  }

  Future<bool> _apply(String title, HtmlForm f, Map<String, String> changes, {String? submit, required String summary}) async {
    final pageHtml = dev!.pages[f.page] ?? '';
    final why = totoPreflight(f, pageHtml, changes.keys.toSet());
    if (why != null) {
      AppLog.add('TOTO', '$title: مش هبعت — $why\n${f.describe()}');
      if (mounted) {
        await showDialog(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(title),
            content: Text('مش هقدر أعملها من التطبيق بأمان: $why.\nاعملها من صفحة الجهاز نفسها، وابعتلي السجل علشان أظبطها.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d), child: const Text('تمام')),
              TextButton(
                onPressed: () {
                  Navigator.pop(d);
                  _openWeb(f.page);
                },
                child: const Text('افتح الصفحة'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    if (!mounted || !await confirm(context, '«تجريبي» $summary\nهيتبعت نفس فورم الجهاز (${f.action}) بكل قيمه الحالية والتغيير ده بس.')) return false;
    final code = await dev!.submit(f, formPayload(f, changes, submit: submit));
    AppLog.add('TOTO', '$title → HTTP $code');
    return code < 400;
  }

  void _openWeb([String page = '/home.htm']) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => BrowserPage(initialUrl: 'http://${ipC.text.trim()}$page')));

  Future<void> _reboot() => _run('ريستارت…', () async {
        final f = findRebootForm(dev!.forms);
        if (f == null) {
          status = 'ملقتش فورم الريستارت في صفحات الجهاز';
          return;
        }
        final btn = f.buttons.where((b) => b.type == 'submit').firstOrNull?.name;
        if (await _apply('ريستارت', f, {}, submit: btn, summary: 'ريستارت للأكسس؟ النت هيقطع على الأجهزة المتوصلة بيه دقيقة أو اتنين.')) {
          status = 'اتبعت الريستارت — استنى دقيقتين وبعدين «اقرا تاني»';
        }
      });

  Future<void> _ssid() async {
    final r = findSsidForm(dev!.forms);
    if (r == null) {
      setState(() => status = 'ملقتش فورم اسم الشبكة في وضع AP (لو الأكسس مكرر/Client التطبيق مش هيلمسه)');
      return;
    }
    final n = await askText(context, 'اسم الواي فاي الجديد (إنجليزي، لحد 32 حرف)', initial: r.ssid.value);
    if (n == null) return;
    final v = n.trim();
    if (v.isEmpty || v.length > 32 || !RegExp(r'^[\x20-\x7E]+$').hasMatch(v)) {
      if (mounted) toast(context, 'الاسم لازم حروف إنجليزي/أرقام ولحد 32');
      return;
    }
    await _run('بغيّر الاسم…', () async {
      final btn = r.form.buttons.where((b) => b.type == 'submit' && RegExp(r'save|apply', caseSensitive: false).hasMatch('${b.name} ${b.value}')).firstOrNull?.name;
      if (!await _apply('اسم الواي فاي', r.form, {r.ssid.name: v}, submit: btn, summary: 'تغيير اسم شبكة الأكسس لـ «$v»؟ الأجهزة المتوصلة بيه هتفصل ولازم تتوصل بالاسم الجديد.')) return;
      await Future.delayed(const Duration(seconds: 3));
      await _read();
      final after = findSsidForm(dev!.forms)?.ssid.value;
      status = after == v ? 'اتغيّر الاسم ✓ (اتأكدت من الصفحة)' : 'اتبعت، بس الصفحة لسه بتقول «${after ?? '؟'}» — ممكن يحتاج ريستارت أو الجهاز رفض';
    });
  }

  Future<void> _key() async {
    final r = findWifiKeyForm(dev!.forms);
    if (r == null) {
      setState(() => status = 'ملقتش فورم باسورد الواي فاي');
      return;
    }
    final k = await askText(context, 'باسورد الواي فاي الجديد (8-63 حرف إنجليزي)', obscure: true);
    if (k == null) return;
    if (k.length < 8 || k.length > 63 || !RegExp(r'^[\x20-\x7E]+$').hasMatch(k)) {
      if (mounted) toast(context, 'لازم من 8 لـ 63 حرف إنجليزي/أرقام');
      return;
    }
    await _run('بغيّر الباسورد…', () async {
      final btn = r.form.buttons.where((b) => b.type == 'submit' && RegExp(r'save|apply', caseSensitive: false).hasMatch('${b.name} ${b.value}')).firstOrNull?.name;
      if (!await _apply('باسورد الواي فاي', r.form, {r.key.name: k}, submit: btn, summary: 'تغيير باسورد واي فاي الأكسس؟ كل الأجهزة المتوصلة بيه هتفصل ولازم تكتب الجديد.')) return;
      await Future.delayed(const Duration(seconds: 3));
      await _read();
      final after = findWifiKeyForm(dev!.forms)?.key.value ?? '';
      status = after == k ? 'اتغيّر ✓ (اتأكدت من الصفحة)' : 'اتبعت — الصفحة مش بتعرض الباسورد فمقدرش أتأكد؛ جرّب تتصل بالجديد';
    });
  }

  Future<void> _block(TotoClient c) => _run('بحظر ${c.mac}…', () async {
        final r = findMacAddForm(dev!.forms);
        if (r == null) {
          status = 'ملقتش فورم التحكم بالـ MAC';
          return;
        }
        final ch = <String, String>{r.mac.name: macForField(c.mac, r.mac)};
        if (r.comment != null) ch[r.comment!.name] = 'A2R';
        var note = '';
        if (r.mode != null) {
          final cur = r.mode!.selectedText.toLowerCase();
          if (cur.contains('allow')) {
            status = 'الأكسس شغال بنظام «المسموح بس» — الإضافة هتسمح للجهاز مش تحظره. مش هعمل حاجة.';
            return;
          }
          if (r.deny == null) {
            status = 'مش لاقي اختيار «Deny» في الفورم';
            return;
          }
          if (!cur.contains('deny')) note = '\nالتحكم بالـ MAC مقفول دلوقتي — هيتشغل بنظام «امنع اللي في القايمة» (القايمة فيها الجهاز ده بس).';
          ch[r.mode!.name] = r.deny!.value;
        }
        if (await _apply('حظر', r.form, ch, submit: r.addBtn, summary: 'حظر ${c.name.isEmpty ? c.mac : c.name} من واي فاي الأكسس؟ (هيقدر يتوصل بالراوتر الأساسي عادي)$note')) {
          await Future.delayed(const Duration(seconds: 2));
          await _read();
          status = findMacDelete(dev!.forms, c.mac) != null ? 'اتحظر ✓ (ظهر في قايمة الجهاز)' : 'اتبعت — بس مش لاقيه في قايمة الحظر بعد القراية';
        }
      });

  Future<void> _unblock(TotoClient c) => _run('بفك الحظر…', () async {
        final r = findMacDelete(dev!.forms, c.mac);
        if (r == null) {
          status = 'الجهاز ده مش في قايمة الحظر بتاعة الأكسس';
          return;
        }
        if (await _apply('فك الحظر', r.form, {r.checkbox: 'ON'}, submit: r.delBtn, summary: 'فك حظر ${c.mac}؟')) {
          await Future.delayed(const Duration(seconds: 2));
          await _read();
          status = findMacDelete(dev!.forms, c.mac) == null ? 'اتفك الحظر ✓' : 'اتبعت — بس لسه موجود في القايمة';
        }
      });

  List<TotoClient> get _blockedList {
    final d = dev;
    if (d == null) return [];
    final out = <TotoClient>[];
    for (final e in d.pages.entries) {
      final l = e.key.toLowerCase();
      if (!(l.contains('ac') && l.contains('ctrl') || l.contains('filter'))) continue;
      out.addAll(clientsFromRows(tableRows(e.value), e.key));
    }
    return out;
  }

  Widget _wrongSubnetCard() {
    final ip = ipC.text.trim();
    final p = net?.prefix ?? '192.168.7';
    return Card(
      color: const Color(0xFF2A2210),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الأكسس بوينت على عنوان $ip والموبايل على شبكة $p — علشان التطبيق يوصله دايمًا: غيّر عنوانه لعنوان من شبكة البيت',
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.6)),
          const SizedBox(height: 8),
          Text(
            [
              'الخطوات (من صفحة الأكسس نفسها، بإيدك — التطبيق مش بيغيّر عنوان الأكسس):',
              '⚠ الأول افتح «Operation Mode»: الخطوات دي بس لو الوضع Repeater أو Bridge/AP. لو WISP أو Gateway متغيّرش عنوانه (النت هيقطع على الأجهزة اللي عليه) — كمّل ادخله بالعنوان اليدوي زي ما بتعمل.',
              '1) وصّل الموبايل بالأكسس بعنوان يدوي زي ما بتعمل، وافتح $ip',
              '2) Network ← LAN',
              '3) IP Address: ${suggest.isNotEmpty ? suggest.first : '$p.250'}${suggest.length > 1 ? ' (أو ${suggest[1]})' : ''}',
              '4) Subnet Mask: 255.255.255.0',
              '5) Default Gateway: $p.1',
              '6) DHCP Server: Disabled (الراوتر هو اللي يوزّع)',
              '7) Save / Apply واستنى يعمل ريستارت',
              '8) رجّع الموبايل على DHCP العادي، واكتب العنوان الجديد هنا أو دوس «دوّر في الشبكة»',
            ].join('\n'),
            style: const TextStyle(height: 1.7, fontSize: 13),
          ),
          if (dhcpInfo.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(dhcpInfo, style: const TextStyle(fontSize: 12, color: kMuted))),
          if (suggest.isNotEmpty)
            Text('العناوين المقترحة اتجربت بـ ping ومحدش راد عليها دلوقتي', style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      ),
    );
  }

  Widget _clientTile(TotoClient c, {bool blocked = false}) {
    final z = widget.hosts.where((h) => h.mac == c.mac).firstOrNull;
    final name = z != null ? widget.labelOf(z) : (c.name.isNotEmpty ? c.name : '(اسم مش معروف)');
    return ListTile(
      leading: Icon(blocked ? Icons.block_rounded : Icons.devices_other_rounded, color: blocked ? kBad : kGold),
      title: Text(name),
      subtitle: Text([c.mac, if ((z?.ip ?? c.ip).isNotEmpty) z?.ip ?? c.ip, if (z != null) 'في قايمة الراوتر', if (c.extra.isNotEmpty) c.extra].join(' • '), style: const TextStyle(fontSize: 12)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => v == 'b' ? _block(c) : _unblock(c),
        itemBuilder: (_) => [
          if (!blocked) const PopupMenuItem(value: 'b', child: Text('احظره من الأكسس (تجريبي)')),
          const PopupMenuItem(value: 'u', child: Text('فك الحظر (تجريبي)')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ip = ipC.text.trim();
    final wrongNet = reachable == false && (net?.prefix ?? '').isNotEmpty && prefixOf(ip) != net!.prefix;
    final blocked = _blockedList;
    return Scaffold(
      appBar: AppBar(title: const Text('الأكسس بوينت (TOTOLINK)'), actions: [
        IconButton(tooltip: 'افتح صفحة الجهاز', icon: const Icon(Icons.public_rounded), onPressed: () => _openWeb()),
      ]),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: ipC,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'عنوان الأكسس'),
              onSubmitted: (v) {
                TotoStore.ip = v.trim();
                _check();
              },
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: busy ? null : _check, child: const Text('جرّب')),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: busy || reachable != true ? null : _login, icon: const Icon(Icons.login_rounded), label: Text(dev == null ? 'ادخل' : 'ادخل تاني')),
          OutlinedButton.icon(onPressed: busy ? null : _scan, icon: const Icon(Icons.radar_rounded), label: const Text('دوّر في الشبكة')),
          if (dev != null) OutlinedButton.icon(onPressed: busy ? null : () => _run('بقرا…', _read), icon: const Icon(Icons.refresh_rounded), label: const Text('اقرا تاني')),
          if (dev != null) OutlinedButton.icon(onPressed: _dumpForms, icon: const Icon(Icons.bug_report_rounded), label: const Text('شارك صفحات الجهاز')),
          TextButton(
            onPressed: () async {
              await TotoStore.savePass(null);
              if (mounted) toast(context, 'اتمسح الباسورد المحفوظ');
            },
            child: const Text('انسى الباسورد'),
          ),
        ]),
        if (busy) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
        if (status.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(status, style: const TextStyle(height: 1.5))),
        if (wrongNet) _wrongSubnetCard(),
        if (dev != null) ...[
          if (info.isNotEmpty) ...[
            const SectionTitle('حالة الجهاز', icon: Icons.info_outline_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in info.take(30))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${e.key}: ${e.value}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13)),
                    ),
                ]),
              ),
            ),
          ],
          const SectionTitle('الأجهزة المتوصلة بالأكسس', icon: Icons.wifi_rounded),
          if (clients.isEmpty) const Text('ملقتش جدول أجهزة في صفحات الجهاز (شارك صفحات الجهاز وابعتلي السجل)', style: TextStyle(color: kMuted)),
          for (final c in clients) Card(child: _clientTile(c)),
          if (blocked.isNotEmpty) ...[
            const SectionTitle('محظورين من الأكسس', icon: Icons.block_rounded),
            for (final c in blocked) Card(child: _clientTile(c, blocked: true)),
          ],
          const SectionTitle('تحكم (تجريبي)', icon: Icons.tune_rounded),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: busy ? null : _ssid, icon: const Icon(Icons.wifi_rounded), label: const Text('اسم الواي فاي')),
            OutlinedButton.icon(onPressed: busy ? null : _key, icon: const Icon(Icons.key_rounded), label: const Text('باسورد الواي فاي')),
            OutlinedButton.icon(onPressed: busy ? null : _reboot, icon: const Icon(Icons.restart_alt_rounded), label: const Text('ريستارت')),
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('التطبيق مش بيلمس: تحديث السوفت وير، حفظ/استرجاع/ضبط المصنع، وضع التشغيل، الاتصال بالراوتر (المكرر)، عنوان الأكسس، الـ DHCP، باسورد الدخول، WPS.',
                style: TextStyle(fontSize: 12, color: kMuted, height: 1.5)),
          ),
        ],
      ]),
    );
  }
}
