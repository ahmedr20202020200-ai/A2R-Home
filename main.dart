// A2R Home — تطبيق 3 في 1: الشبكة + الكاست + الريسيفر
// ملف واحد (build.yml بينقله لـ lib/main.dart). المصادر في README.md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xml/xml.dart';


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
const Color kMuted = Color(0xFF9AA1AD);
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
      builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
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
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: round, side: const BorderSide(color: kLine))),
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

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  void initState() {
    super.initState();
    Native.askNotifyPermission();
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['الشبكة', 'العرض على التلفزيون', 'الريسيفر'];
    const icons = [Icons.router_rounded, Icons.cast_rounded, Icons.satellite_alt_rounded];
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
      body: IndexedStack(index: tab, children: const [NetworkPage(), CastPage(), ReceiverPage()]),
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
        final list = await router!.stations();
        try {
          blockedMacs = (await router!.blockList()).macs;
        } catch (_) {}
        for (final s in list) {
          final key = s.ip.isEmpty ? s.mac : s.ip;
          final h = hosts.putIfAbsent(key, () => LanHost(key, source: 'router'));
          h.mac = s.mac;
          if (s.hostname.isNotEmpty) h.name = s.hostname;
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
    _checkNew(before);
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
      if (h.name.isNotEmpty && (hosts[h.ip]?.name ?? '').isEmpty) hosts[h.ip]!.name = h.name;
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
      final n = Store.deviceNames[h.mac] ?? (h.name.isEmpty ? h.ip : h.name);
      Native.notify('جهاز جديد على الشبكة', '$n — ${h.ip}${h.mac.isEmpty ? '' : ' — ${h.mac}'}');
    }
    if (fresh.isNotEmpty) Store.addKnown(keys);
  }

  String label(LanHost h) {
    final names = Store.deviceNames;
    return names[h.mac] ?? names[h.ip] ?? (h.name.isNotEmpty ? h.name : h.ip);
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
        child: Wrap(spacing: 18, runSpacing: 6, children: [
          _kv('الواي فاي', n?.ssid ?? '—'),
          _kv('IP الموبايل', n?.ip ?? '—'),
          _kv('البوابة', n?.gateway ?? '—'),
          _kv('النسخة', appVersion),
          ActionChip(avatar: const Icon(Icons.speed, size: 18), label: const Text('سرعة النت'), onPressed: _speed),
          ActionChip(avatar: const Icon(Icons.network_ping, size: 18), label: const Text('Ping'), onPressed: () => _pingAsk()),
          ActionChip(avatar: const Icon(Icons.power_settings_new, size: 18), label: const Text('تشغيل جهاز (WOL)'), onPressed: () => _wol(null)),
          ActionChip(
            avatar: const Icon(Icons.business, size: 18),
            label: Text(Oui.table.isEmpty ? 'نزّل أسماء الشركات' : 'شركات: ${Oui.table.length}'),
            onPressed: () async {
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
      ),
    );
  }

  Widget _kv(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(k, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        Text(v, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]);

  Widget _routerCard() {
    final r = router;
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
                PopupMenuItem(value: 'wifi_off', child: Text('قفل الواي فاي (تجريبي)')),
                PopupMenuItem(value: 'wifi_on', child: Text('فتح الواي فاي (تجريبي)')),
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
      if (h.source != 'scan') (h.wifi ? 'واي فاي' : 'كابل'),
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
                                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
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
  QueueItem(this.title, this.url, {this.subtitle, this.file, this.headers = const {}, this.viaPhone = false});
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
      return MediaServer.I.proxy(q.url, {'User-Agent': kChromeUa, ...q.headers}, ip, mime: await probeMime(q.url, q.headers));
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
    pos = dur = Duration.zero;
    state = '';
    busy = true;
    notifyListeners();
    final q = queue[i];
    try {
      final mime = q.file != null ? mimeOf(q.file!.path) : await probeMime(q.url, q.headers);
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

  /// لو الشاشة مبدأتش خلال 12 ثانية والرابط مباشر → نعيده عبر الموبايل
  void _watchStart(int my, int i) {
    Future(() async {
      for (var k = 0; k < 6; k++) {
        await Future.delayed(const Duration(seconds: 2));
        if (my != _seq) return;
        await poll();
        if (state == 'PLAYING' || state == 'PAUSED_PLAYBACK' || pos > Duration.zero) {
          _note('شغال ✓');
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
        notifyListeners();
        if (ended && playing + 1 < queue.length) await playIndex(playing + 1);
        return;
      }
      final c = client;
      if (c == null) return;
      final s = await c.status();
      final ended = state == 'PLAYING' && s.state == 'STOPPED' && dur.inSeconds > 0 && (dur - pos).inSeconds < 8;
      pos = s.pos;
      dur = s.dur;
      state = s.state;
      notifyListeners();
      if (ended && playing + 1 < queue.length) await playIndex(playing + 1);
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
    if (r.length == 1 && mimeOf(r.first.name).startsWith('video') && mounted && await confirm(context, 'تضيف ملف ترجمة (srt)؟')) {
      final s = await FilePicker.pickFile(type: FileType.any);
      final p = s == null ? null : await pickedToFile(s);
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
          ]),
        ),
        if (cs.playing >= 0 && cs.playing < cs.queue.length) _remote(),
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
          Text('${cs.way == CastWay.gm ? 'G-MScreen' : 'DLNA'} • ${castStateAr(cs.state)}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
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
 function rep(u){ try{ if(!u) return; u = new URL(u, location.href).href; if(seen[u]) return; seen[u]=1; A2R.postMessage(u);}catch(e){} }
 var of = window.fetch; if (of) window.fetch = function(i, o){ try{ rep(typeof i === 'string' ? i : i.url); }catch(e){} return of.apply(this, arguments); };
 var oo = XMLHttpRequest.prototype.open; XMLHttpRequest.prototype.open = function(m, u){ rep(u); return oo.apply(this, arguments); };
 function scan(){ document.querySelectorAll('video,source,audio').forEach(function(v){ if(v.src && v.src.indexOf('blob:')!==0) rep(v.src); if(v.currentSrc && v.currentSrc.indexOf('blob:')!==0) rep(v.currentSrc); });
   try{ performance.getEntriesByType('resource').forEach(function(e){ rep(e.name); }); }catch(e){} }
 setInterval(scan, 1500); scan();
})();
''';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});
  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController web;
  final urlC = TextEditingController();
  final List<String> found = [];
  String title = '';
  double prog = 0;

  void _found(String u) {
    if (!looksLikeMedia(u) || found.contains(u)) return;
    AppLog.add('CAST', 'sniffed $u');
    setState(() => found.insert(0, u));
  }

  @override
  void initState() {
    super.initState();
    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('A2R', onMessageReceived: (m) => _found(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (r) {
          if (looksLikeMedia(r.url)) {
            _found(r.url);
            return NavigationDecision.prevent;
          }
          if (!r.url.startsWith('http')) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
        onPageStarted: (u) {
          urlC.text = u;
          setState(() => found.clear());
        },
        onProgress: (p) => setState(() => prog = p / 100),
        onPageFinished: (u) async {
          await web.runJavaScript(kSnifferJs).catchError((_) {});
          title = await web.getTitle() ?? '';
          if (mounted) setState(() {});
        },
        onUrlChange: (c) {
          if (c.url != null) _found(c.url!);
        },
      ))
      ..loadRequest(Uri.parse(Store.homePage));
  }

  void go(String s) {
    s = s.trim();
    if (s.isEmpty) return;
    final u = s.startsWith('http') ? s : (s.contains('.') && !s.contains(' ') ? 'https://$s' : 'https://www.google.com/search?q=${Uri.encodeComponent(s)}');
    web.loadRequest(Uri.parse(u));
  }

  Future<void> cast(String u) async {
    final name = title.isNotEmpty ? title : (Uri.parse(u).pathSegments.lastOrNull ?? 'فيديو');
    try {
      await CastState.I.add(QueueItem(name, u, headers: {if (urlC.text.startsWith('http')) 'Referer': urlC.text, 'User-Agent': kChromeUa}));
      if (mounted) toast(context, 'اتبعت للشاشة');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) async {
        if (did) return;
        if (await web.canGoBack()) {
          await web.goBack();
        } else if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: TextField(
            controller: urlC,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: go,
            decoration: const InputDecoration(hintText: 'اكتب رابط أو ابحث', border: InputBorder.none),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => web.reload()),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'خليها الصفحة الرئيسية',
              onPressed: () {
                Store.homePage = urlC.text;
                toast(context, 'اتحفظت كصفحة رئيسية');
              },
            ),
          ],
          bottom: prog < 1 ? PreferredSize(preferredSize: const Size.fromHeight(2), child: LinearProgressIndicator(value: prog)) : null,
        ),
        body: WebViewWidget(controller: web),
        floatingActionButton: found.isEmpty
            ? null
            : FloatingActionButton.extended(
                icon: const Icon(Icons.cast),
                label: Text('${found.length} فيديو'),
                onPressed: () => showModalBottomSheet(
                  context: context,
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
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => Clipboard.setData(ClipboardData(text: u)),
                          ),
                        ),
                    ]),
                  ),
                ),
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

class _ReceiverPageState extends State<ReceiverPage> with AutomaticKeepAliveClientMixin {
  GmClient? gm;
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

  @override
  void dispose() {
    gm?.disconnect();
    super.dispose();
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
                              icon: const Icon(Icons.play_circle_outline_rounded, color: kMuted),
                              tooltip: 'اتفرج على الموبايل',
                              onPressed: () => watch(ch),
                            ),
                          ]),
                          onLongPress: () => _details(ch),
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            try {
                              await gm!.zap(ch);
                              playingId = ch.id;
                              setState(() {});
                            } catch (e) {
                              if (mounted) toast(context, 'مقدرتش أغير القناة: $e');
                            }
                          },
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
            (m) => '"${m[1]}":"***"');
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
    h.name = await netbiosName(h.ip) ?? await reverseName(h.ip) ?? h.name;
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

String dlnaFeatures(String mime) => isLiveMime(mime) ? 'DLNA.ORG_OP=00;DLNA.ORG_CI=0;$kDlnaFlags' : 'DLNA.ORG_OP=01;DLNA.ORG_CI=0;$kDlnaFlags';

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
  _Shared({this.file, this.remote, this.headers = const {}, required this.mime, this.subtitleUrl});
}

/// سيرفر صغير جوه الموبايل: بيقدّم ملفات الموبايل، وبيعدّي روابط النت اللي محتاجة هيدرز/HTTPS (زي وضع الـproxy في Web Video Caster)
class MediaServer {
  MediaServer._();
  static final MediaServer I = MediaServer._();
  HttpServer? _srv;
  final Map<String, _Shared> _items = {};
  final Map<String, String> _byKey = {};
  String _host = '';

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

  Future<String> proxy(String url, Map<String, String> headers, String phoneIp, {String? mime}) async {
    final b = await _base(phoneIp);
    final id = _id('p:$url', () => _Shared(remote: url, headers: Map.of(headers), mime: mime ?? mimeOf(url)));
    return '$b/p/$id/${_name(url)}';
  }

  Future<HttpServer> _start() async {
    final s = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    s.autoCompress = false;
    s.idleTimeout = const Duration(seconds: 60);
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
    res.headers.set('Content-Type', it.mime);
    res.headers.set('Accept-Ranges', 'bytes');
    _dlnaHeaders(res, it.mime, it);
    final range = parseRange(q.headers.value('range'), len);
    if (q.headers.value('range') != null && range == null) {
      res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      res.headers.set('Content-Range', 'bytes */$len');
      await res.close();
      return;
    }
    if (range != null) {
      res.statusCode = HttpStatus.partialContent;
      res.headers.set('Content-Range', 'bytes ${range.$1}-${range.$2}/$len');
      res.contentLength = range.$2 - range.$1 + 1;
      if (q.method != 'HEAD') await res.addStream(f.openRead(range.$1, range.$2 + 1));
    } else {
      res.contentLength = len;
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
