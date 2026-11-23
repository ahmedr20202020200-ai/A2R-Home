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

const Color kGold = Color(0xFFD4A63A);

class A2RHome extends StatelessWidget {
  const A2RHome({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: kGold, brightness: Brightness.dark, primary: kGold);
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
        scaffoldBackgroundColor: const Color(0xFF111316),
        cardTheme: const CardThemeData(color: Color(0xFF1B1E23), margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
      ),
      home: const Shell(),
    );
  }
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
    const titles = ['الشبكة', 'الكاست', 'الريسيفر'];
    return Scaffold(
      appBar: AppBar(
        title: Text('A2R Home — ${titles[tab]}'),
        actions: [
          IconButton(
            tooltip: 'السجل',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogPage())),
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: const [NetworkPage(), CastPage(), ReceiverPage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.router_outlined), label: 'الشبكة'),
          NavigationDestination(icon: Icon(Icons.cast), label: 'الكاست'),
          NavigationDestination(icon: Icon(Icons.satellite_alt), label: 'الريسيفر'),
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
            _kv('RSRQ', g('lte_rsrq')),
            _kv('SINR', g('lte_snr').isNotEmpty ? g('lte_snr') : g('Z5g_SINR')),
            _kv('Band', g('lte_band')),
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
  QueueItem(this.title, this.url, {this.subtitle});
}

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
  int volume = 30;
  bool searching = false;

  Future<void> discover() async {
    searching = true;
    notifyListeners();
    devices = await discoverRenderers();
    if (current != null && !devices.any((d) => d.avTransport == current!.avTransport)) devices.insert(0, current!);
    if (current == null && devices.length == 1) current = devices.first;
    searching = false;
    notifyListeners();
  }

  void select(DlnaDevice? d) {
    current = d;
    notifyListeners();
    client?.getVolume().then((v) {
      if (v != null) {
        volume = v;
        notifyListeners();
      }
    }).catchError((_) {});
  }

  Future<void> playIndex(int i) async {
    final c = client;
    if (c == null) throw StateError('اختار شاشة الأول');
    if (i < 0 || i >= queue.length) return;
    playing = i;
    notifyListeners();
    await c.load(queue[i].url, queue[i].title, subtitle: queue[i].subtitle);
  }

  Future<void> add(QueueItem q, {bool playNow = true}) async {
    queue.add(q);
    notifyListeners();
    if (playNow) await playIndex(queue.length - 1);
  }

  Future<void> poll() async {
    final c = client;
    if (c == null || playing < 0) return;
    try {
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

class CastPage extends StatefulWidget {
  const CastPage({super.key});
  @override
  State<CastPage> createState() => _CastPageState();
}

class _CastPageState extends State<CastPage> with AutomaticKeepAliveClientMixin {
  final cs = CastState.I;
  Timer? t;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    cs.discover();
    t = Timer.periodic(const Duration(seconds: 2), (_) => cs.poll());
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
      if (mounted) toast(context, 'خطأ: $e');
    }
  }

  Future<void> pickLocal() async {
    final r = await FilePicker.pickFiles(type: FileType.media);
    if (r.isEmpty) return;
    final net = await readPhoneNet();
    if (net.ip == null) {
      if (mounted) toast(context, 'الموبايل لازم يكون على نفس الواي فاي');
      return;
    }
    String? sub;
    if (r.length == 1 && mimeOf(r.first.name).startsWith('video') && mounted && await confirm(context, 'تضيف ملف ترجمة (srt)؟')) {
      final s = await FilePicker.pickFile(type: FileType.any);
      final p = s == null ? null : await pickedToFile(s);
      if (p != null) sub = await MediaServer.I.share(p, net.ip!);
    }
    if (mounted) toast(context, 'بجهّز الملفات…');
    var first = true;
    for (final f in r) {
      final file = await pickedToFile(f);
      if (file == null) continue;
      final url = await MediaServer.I.share(file, net.ip!);
      await _run(() => cs.add(QueueItem(f.name, url, subtitle: sub), playNow: first));
      first = false;
    }
  }

  Future<void> addLink() async {
    final u = await askText(context, 'رابط فيديو مباشر', hint: 'https://…mp4 أو m3u8', type: TextInputType.url);
    if (u == null || u.trim().isEmpty) return;
    await _run(() => cs.add(QueueItem(Uri.parse(u.trim()).pathSegments.lastOrNull ?? u, u.trim())));
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
            child: Row(children: [
              const Icon(Icons.tv, color: kGold),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: cs.current?.avTransport,
                  hint: Text(cs.searching ? 'بدوّر على الشاشات…' : (cs.devices.isEmpty ? 'ملقتش شاشات DLNA' : 'اختار الشاشة')),
                  items: [
                    for (final d in cs.devices)
                      DropdownMenuItem(value: d.avTransport, child: Text('${d.name}  (${d.ip})', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => cs.select(cs.devices.firstWhere((d) => d.avTransport == v)),
                ),
              ),
              IconButton(onPressed: cs.searching ? null : cs.discover, icon: const Icon(Icons.refresh)),
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('الشاشات السمارت (سامسونج/LG/سوني/أندرويد TV) لازم يكون فيها DLNA شغال. Chromecast مش مدعوم في النسخة دي.',
              style: TextStyle(fontSize: 12, color: Colors.white60)),
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
        if (cs.playing >= 0) _remote(),
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
                subtitle: Text(cs.queue[i].url, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 11)),
                onTap: () => _run(() => cs.playIndex(i)),
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
        const SizedBox(height: 60),
      ]),
    );
  }

  Widget _remote() {
    final c = cs.client;
    final max = cs.dur.inSeconds.toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Text(cs.queue[cs.playing].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(cs.state, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          Row(children: [
            Text(fmtHms(cs.pos), style: const TextStyle(fontSize: 11)),
            Expanded(
              child: Slider(
                value: cs.pos.inSeconds.toDouble().clamp(0, max <= 0 ? 1 : max),
                max: max <= 0 ? 1 : max,
                onChanged: max <= 0 ? null : (v) => setState(() => cs.pos = Duration(seconds: v.round())),
                onChangeEnd: max <= 0 ? null : (v) => _run(() => c!.seek(Duration(seconds: v.round()))),
              ),
            ),
            Text(fmtHms(cs.dur), style: const TextStyle(fontSize: 11)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(icon: const Icon(Icons.skip_previous), onPressed: cs.playing > 0 ? () => _run(() => cs.playIndex(cs.playing - 1)) : null),
            IconButton(icon: const Icon(Icons.replay_10), onPressed: () => _run(() => c!.seek(cs.pos - const Duration(seconds: 10) < Duration.zero ? Duration.zero : cs.pos - const Duration(seconds: 10)))),
            IconButton.filled(icon: const Icon(Icons.play_arrow), onPressed: () => _run(c!.play)),
            IconButton(icon: const Icon(Icons.pause), onPressed: () => _run(c!.pause)),
            IconButton(icon: const Icon(Icons.stop), onPressed: () => _run(c!.stop)),
            IconButton(icon: const Icon(Icons.forward_30), onPressed: () => _run(() => c!.seek(cs.pos + const Duration(seconds: 30)))),
            IconButton(icon: const Icon(Icons.skip_next), onPressed: cs.playing + 1 < cs.queue.length ? () => _run(() => cs.playIndex(cs.playing + 1)) : null),
          ]),
          Row(children: [
            const Icon(Icons.volume_down, size: 18),
            Expanded(
              child: Slider(
                value: cs.volume.toDouble().clamp(0, 100),
                max: 100,
                onChanged: (v) => setState(() => cs.volume = v.round()),
                onChangeEnd: (v) => _run(() => c!.setVolume(v.round())),
              ),
            ),
            const Icon(Icons.volume_up, size: 18),
          ]),
        ]),
      ),
    );
  }
}

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
      await CastState.I.add(QueueItem(name, u));
      if (mounted) toast(context, 'بيتشغل على ${CastState.I.current?.name}');
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
  int view = 0; // 0 ريموت، 1 قنوات

  @override
  bool get wantKeepAlive => true;

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
      // احتياطي: دوّر على أي جهاز فاتح بورت 20000
      final net = await readPhoneNet();
      setState(() => msg = 'مفيش إعلانات — بدوّر على بورت 20000 في الشبكة…');
      final hosts = await scanLan(net.prefix);
      for (final h in hosts.where((h) => h.openPorts.contains(kStbPort))) {
        found[h.ip] = StbInfo('', 'ريسيفر؟', h.ip, 0, 0, 0, 0);
      }
    }
    setState(() {
      busy = false;
      msg = found.isEmpty ? 'ملقتش ريسيفر — اكتب العنوان بنفسك (من قايمة الشبكة في الريسيفر)' : 'لقيت ${found.length}';
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
    try {
      final i = await c.connect();
      gm = c;
      Store.receiverIp = ip;
      msg = 'متصل: ${i.model} (${i.ip})';
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
      msg = '${channels.length} قناة';
    } catch (e) {
      msg = 'مقدرتش أحمّل القنوات: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> key(int k) async {
    HapticFeedback.selectionClick();
    try {
      if (gm == null) throw StateError('مش متصل');
      await gm!.key(k);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> manual() async {
    final ip = await askText(context, 'عنوان الريسيفر', initial: Store.receiverIp ?? '', hint: '192.168.x.x', type: TextInputType.number);
    if (ip != null && ip.trim().isNotEmpty) await connect(ip.trim());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Row(children: [
              Icon(Icons.satellite_alt, color: gm?.connected == true ? Colors.greenAccent : kGold),
              const SizedBox(width: 8),
              Expanded(child: Text(msg.isEmpty ? 'Qmax H1 / H8 — بروتوكول G-MScreen' : msg, style: const TextStyle(fontSize: 13))),
              if (busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            Wrap(spacing: 6, children: [
              TextButton.icon(onPressed: busy ? null : discover, icon: const Icon(Icons.search), label: const Text('دوّر')),
              TextButton.icon(onPressed: busy ? null : manual, icon: const Icon(Icons.edit), label: const Text('عنوان يدوي')),
              if (Store.receiverIp != null && gm?.connected != true)
                TextButton.icon(onPressed: busy ? null : () => connect(Store.receiverIp!), icon: const Icon(Icons.link), label: Text('اتصل ${Store.receiverIp}')),
              if (gm?.connected == true) TextButton.icon(onPressed: () => key(K.power), icon: const Icon(Icons.power_settings_new, color: Colors.redAccent), label: const Text('باور')),
            ]),
            for (final e in found.entries)
              ListTile(
                dense: true,
                leading: const Icon(Icons.settings_input_antenna),
                title: Text('${e.value.model} — ${e.key}'),
                subtitle: e.value.serial.isEmpty ? null : Text('S/N ${e.value.serial}'),
                onTap: () => connect(e.key),
              ),
            const Text('لو تطبيق G-MScreen مفتوح على موبايل تاني الريسيفر ممكن يرفض. والريسيفر في Standby العميق مش بيرد.',
                style: TextStyle(fontSize: 11, color: Colors.white54)),
          ]),
        ),
      ),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, icon: Icon(Icons.settings_remote), label: Text('الريموت')),
          ButtonSegment(value: 1, icon: Icon(Icons.list), label: Text('القنوات')),
        ],
        selected: {view},
        onSelectionChanged: (s) {
          setState(() => view = s.first);
          if (view == 1 && channels.isEmpty) loadChannels();
        },
      ),
      Expanded(child: view == 0 ? _remote() : _channels()),
    ]);
  }

  Widget _btn(String t, int k, {IconData? icon, Color? color}) => Padding(
        padding: const EdgeInsets.all(3),
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: color ?? const Color(0xFF262A31),
            foregroundColor: Colors.white,
            minimumSize: const Size(56, 44),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          onPressed: () => key(k),
          child: icon != null ? Icon(icon) : Text(t, style: const TextStyle(fontSize: 13)),
        ),
      );

  Widget _remote() {
    return ListView(padding: const EdgeInsets.all(8), children: [
      // تاتش باد: اسحب = أسهم، دوسة = OK، دوستين = رجوع
      GestureDetector(
        onTap: () => key(K.ok),
        onDoubleTap: () => key(K.exit),
        onLongPress: () => key(K.menu),
        onPanEnd: (d) {
          final v = d.velocity.pixelsPerSecond;
          if (v.distance < 200) return;
          if (v.dx.abs() > v.dy.abs()) {
            key(v.dx > 0 ? K.right : K.left);
          } else {
            key(v.dy > 0 ? K.down : K.up);
          }
        },
        child: Container(
          height: 170,
          decoration: BoxDecoration(color: const Color(0xFF1B1E23), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
          alignment: Alignment.center,
          child: const Text('اسحب للأسهم • دوسة = OK\nدوستين = خروج • ضغطة طويلة = القايمة', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        ),
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn('Menu', K.menu, icon: Icons.menu),
            _btn('', K.up, icon: Icons.keyboard_arrow_up),
            _btn('Exit', K.exit, icon: Icons.undo),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn('', K.left, icon: Icons.keyboard_arrow_left),
            _btn('OK', K.ok, color: const Color(0xFF6B5418)),
            _btn('', K.right, icon: Icons.keyboard_arrow_right),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn('Info', K.info, icon: Icons.info_outline),
            _btn('', K.down, icon: Icons.keyboard_arrow_down),
            _btn('EPG', K.epg),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn('', K.volDown, icon: Icons.volume_down),
            _btn('', K.mute, icon: Icons.volume_off),
            _btn('', K.volUp, icon: Icons.volume_up),
            const SizedBox(width: 12),
            _btn('CH-', K.chDown),
            _btn('CH+', K.chUp),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn('', K.red, color: Colors.red.shade800),
            _btn('', K.green, color: Colors.green.shade800),
            _btn('', K.yellow, color: Colors.amber.shade800),
            _btn('', K.blue, color: Colors.blue.shade800),
          ]),
          for (final row in [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final n in row) _btn('$n', K.digit(n))]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn('TV/R', K.tvRadio),
            _btn('0', K.digit(0)),
            _btn('Recall', K.recall),
          ]),
          const SizedBox(height: 6),
          Wrap(alignment: WrapAlignment.center, children: [
            _btn('FAV', K.fav),
            _btn('SAT', K.sat),
            _btn('Audio', K.audio),
            _btn('Sub', K.subtitle),
            _btn('TXT', K.teletext),
            _btn('Find', K.find),
            _btn('USB', K.usb),
            _btn('P-', K.pageUp),
            _btn('P+', K.pageDown),
            _btn('', K.rew, icon: Icons.fast_rewind),
            _btn('', K.play, icon: Icons.play_arrow),
            _btn('', K.pause, icon: Icons.pause),
            _btn('', K.ff, icon: Icons.fast_forward),
            _btn('', K.stop, icon: Icons.stop),
            _btn('', K.record, icon: Icons.fiber_manual_record, color: Colors.red.shade900),
            _btn('Sleep', K.sleep),
            _btn('Res', K.resolution),
          ]),
        ]),
      ),
      const SizedBox(height: 6),
      const Text('إشارة الطبق: افتح قايمة البحث/التركيب على الريسيفر من الريموت هنا — البروتوكول المعروف مفيهوش قراية للإشارة.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54)),
    ]);
  }

  Widget _channels() {
    final f = favs;
    final shown = channels
        .where((c) => c.radio == radio && (!favOnly || f.contains(c.id)) && (q.isEmpty || c.name.toLowerCase().contains(q.toLowerCase())))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(6),
        child: Row(children: [
          Expanded(child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'دوّر على قناة'), onChanged: (v) => setState(() => q = v))),
          IconButton(icon: Icon(radio ? Icons.radio : Icons.tv), tooltip: 'تلفزيون/راديو', onPressed: () => setState(() => radio = !radio)),
          IconButton(icon: Icon(favOnly ? Icons.star : Icons.star_border, color: kGold), tooltip: 'المفضلة', onPressed: () => setState(() => favOnly = !favOnly)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: busy ? null : loadChannels),
        ]),
      ),
      const Text('المفضلة هنا محفوظة في التطبيق بس. تعديل القنوات (تغيير الاسم/مسح/نقل) مش مدعوم في البروتوكول المعروف.',
          style: TextStyle(fontSize: 11, color: Colors.white54)),
      Expanded(
        child: ListView.builder(
          itemCount: shown.length,
          itemBuilder: (c, i) {
            final ch = shown[i];
            final on = ch.id == playingId;
            return ListTile(
              dense: true,
              leading: Text('${ch.index + 1}', style: TextStyle(color: on ? kGold : Colors.white54)),
              title: Text(ch.name, style: TextStyle(color: on ? kGold : null, fontWeight: on ? FontWeight.bold : null)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(f.contains(ch.id) ? Icons.star : Icons.star_border, size: 20, color: kGold), onPressed: () => toggleFav(ch.id)),
                IconButton(icon: const Icon(Icons.phone_android, size: 20), tooltip: 'اتفرج على الموبايل', onPressed: () => watch(ch)),
              ]),
              onTap: () async {
                try {
                  await gm!.zap(ch);
                  playingId = ch.id;
                  setState(() {});
                } catch (e) {
                  if (mounted) toast(context, 'مقدرتش أغير القناة: $e');
                }
              },
            );
          },
        ),
      ),
    ]);
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
        'lte_snr', 'Z5g_SINR', 'lte_band', 'wan_ipaddr', 'ppp_status', 'realtime_tx_thrpt',
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
}

String _resolve(String base, String path) {
  if (path.startsWith('http')) return path;
  return Uri.parse(base).resolve(path).toString();
}

/// يقرا وصف الجهاز (description.xml) ويطلع روابط التحكم
DlnaDevice? parseDeviceDescription(String xmlText, String location) {
  try {
    final doc = XmlDocument.parse(xmlText);
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

Future<List<DlnaDevice>> discoverRenderers() async {
  final replies = await ssdpDiscover([
    'urn:schemas-upnp-org:device:MediaRenderer:1',
    'urn:schemas-upnp-org:service:AVTransport:1',
  ]);
  final out = <DlnaDevice>[];
  final seen = <String>{};
  await Future.wait(replies.map((r) async {
    try {
      final res = await http.get(Uri.parse(r.location)).timeout(const Duration(seconds: 4));
      final d = parseDeviceDescription(utf8.decode(res.bodyBytes, allowMalformed: true), r.location);
      if (d != null && seen.add(d.avTransport!)) out.add(d);
    } catch (e) {
      AppLog.add('CAST', 'desc ${r.location} ✗ $e');
    }
  }));
  return out;
}

String xmlEsc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String mimeOf(String url) {
  final u = url.toLowerCase().split('?').first;
  if (u.endsWith('.m3u8')) return 'application/x-mpegURL';
  if (u.endsWith('.mpd')) return 'application/dash+xml';
  if (u.endsWith('.mkv')) return 'video/x-matroska';
  if (u.endsWith('.webm')) return 'video/webm';
  if (u.endsWith('.avi')) return 'video/x-msvideo';
  if (u.endsWith('.mov')) return 'video/quicktime';
  if (u.endsWith('.ts')) return 'video/mp2t';
  if (u.endsWith('.mp3')) return 'audio/mpeg';
  if (u.endsWith('.m4a') || u.endsWith('.aac')) return 'audio/mp4';
  if (u.endsWith('.jpg') || u.endsWith('.jpeg')) return 'image/jpeg';
  if (u.endsWith('.png')) return 'image/png';
  if (u.endsWith('.gif')) return 'image/gif';
  if (u.endsWith('.srt')) return 'text/srt';
  if (u.endsWith('.vtt')) return 'text/vtt';
  return 'video/mp4';
}

/// DIDL-Lite (وصف الملف اللي بيتبعت للشاشة) + ترجمة لو موجودة
String buildDidl(String url, String title, {String? mime, String? subtitleUrl}) {
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
      'xmlns:sec="http://www.sec.co.kr/" xmlns:pv="http://www.pv.com/pvns/">'
      '<item id="0" parentID="-1" restricted="1"><dc:title>${xmlEsc(title)}</dc:title>'
      '<upnp:class>$cls</upnp:class>'
      '<res protocolInfo="http-get:*:$m:*"${subtitleUrl == null ? '' : ' pv:subtitleFileUri="${xmlEsc(subtitleUrl)}" pv:subtitleFileType="srt"'}>${xmlEsc(url)}</res>'
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
  final m = RegExp('<(?:\\w+:)?$tag>([\\s\\S]*?)</(?:\\w+:)?$tag>').firstMatch(xml);
  return m?.group(1);
}

String fmtHms(Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

Duration parseHms(String? s) {
  if (s == null) return Duration.zero;
  final p = s.split(':');
  if (p.length != 3) return Duration.zero;
  final sec = double.tryParse(p[2]) ?? 0;
  return Duration(hours: int.tryParse(p[0]) ?? 0, minutes: int.tryParse(p[1]) ?? 0, milliseconds: (sec * 1000).round());
}

class DlnaClient {
  final DlnaDevice dev;
  DlnaClient(this.dev);

  Future<String> _call(String service, String url, String action, Map<String, String> args) async {
    final body = soapEnvelope(service, action, args);
    AppLog.add('CAST', '→ ${dev.name} $action ${args.keys.join(',')}');
    final r = await http
        .post(Uri.parse(url),
            headers: {
              'Content-Type': 'text/xml; charset="utf-8"',
              'SOAPAction': '"urn:schemas-upnp-org:service:$service:1#$action"',
            },
            body: utf8.encode(body))
        .timeout(const Duration(seconds: 8));
    final txt = utf8.decode(r.bodyBytes, allowMalformed: true);
    AppLog.add('CAST', '← ${r.statusCode} ${txt.length > 400 ? txt.substring(0, 400) : txt}');
    if (r.statusCode != 200) throw HttpException('$action فشل (${r.statusCode})');
    return txt;
  }

  Future<String> av(String action, [Map<String, String> args = const {}]) =>
      _call('AVTransport', dev.avTransport!, action, {'InstanceID': '0', ...args});

  Future<void> load(String url, String title, {String? subtitle}) async {
    try {
      await av('Stop');
    } catch (_) {}
    await av('SetAVTransportURI', {'CurrentURI': url, 'CurrentURIMetaData': buildDidl(url, title, subtitleUrl: subtitle)});
    await play();
  }

  Future<void> play() => av('Play', {'Speed': '1'});
  Future<void> pause() => av('Pause');
  Future<void> stop() => av('Stop');
  Future<void> seek(Duration d) => av('Seek', {'Unit': 'REL_TIME', 'Target': fmtHms(d)});

  Future<({Duration pos, Duration dur, String state})> status() async {
    final p = await av('GetPositionInfo');
    String st = '';
    try {
      st = soapValue(await av('GetTransportInfo'), 'CurrentTransportState') ?? '';
    } catch (_) {}
    return (pos: parseHms(soapValue(p, 'RelTime')), dur: parseHms(soapValue(p, 'TrackDuration')), state: st);
  }

  Future<int?> getVolume() async {
    if (dev.rendering == null) return null;
    final r = await _call('RenderingControl', dev.rendering!, 'GetVolume', {'InstanceID': '0', 'Channel': 'Master'});
    return int.tryParse(soapValue(r, 'CurrentVolume') ?? '');
  }

  Future<void> setVolume(int v) async {
    if (dev.rendering == null) return;
    await _call('RenderingControl', dev.rendering!, 'SetVolume',
        {'InstanceID': '0', 'Channel': 'Master', 'DesiredVolume': '${v.clamp(0, 100)}'});
  }
}

/// سيرفر صغير جوه الموبايل علشان الشاشة تقرا ملفات الموبايل (فيديو/صور/ترجمة)
class MediaServer {
  MediaServer._();
  static final MediaServer I = MediaServer._();
  HttpServer? _srv;
  final Map<String, File> _files = {};

  Future<String> share(File f, String phoneIp) async {
    _srv ??= await _start();
    final id = '${_files.length + 1}';
    _files[id] = f;
    final name = Uri.encodeComponent(f.uri.pathSegments.last);
    return 'http://$phoneIp:${_srv!.port}/f/$id/$name';
  }

  Future<HttpServer> _start() async {
    final s = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    AppLog.add('CAST', 'media server on port ${s.port}');
    s.listen(_handle, onError: (e) => AppLog.add('CAST', 'server error $e'));
    return s;
  }

  Future<void> _handle(HttpRequest q) async {
    final seg = q.uri.pathSegments;
    final res = q.response;
    try {
      if (seg.length < 2 || seg[0] != 'f' || !_files.containsKey(seg[1])) {
        res.statusCode = 404;
        await res.close();
        return;
      }
      final f = _files[seg[1]]!;
      final len = await f.length();
      res.headers.set('Content-Type', mimeOf(f.path));
      res.headers.set('Accept-Ranges', 'bytes');
      res.headers.set('transferMode.dlna.org', 'Streaming');
      res.headers.set('contentFeatures.dlna.org', 'DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000');
      final range = parseRange(q.headers.value('range'), len);
      AppLog.add('CAST', 'serve ${q.method} ${f.path.split('/').last} range=${q.headers.value('range')}');
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
    } catch (e) {
      AppLog.add('CAST', 'serve error $e');
      try {
        await res.close();
      } catch (_) {}
    }
  }
}

/// "bytes=100-" → (100, len-1)
(int, int)? parseRange(String? h, int len) {
  if (h == null || len <= 0) return null;
  final m = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(h);
  if (m == null) return null;
  final a = m[1]!, b = m[2]!;
  int start, end;
  if (a.isEmpty) {
    final n = int.tryParse(b) ?? 0;
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
  StbInfo(this.serial, this.model, this.ip, this.platform, this.swVersion, this.swSub, this.flags);
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
  return StbInfo(serial, model, ip, p[72], be(73, 2), le(80, 4), p[84]);
}

/// تحويل الطلب لـ JSON (كل القيم نصوص) أو XML حسب الريسيفر
String gmEncode(int request, Map<String, dynamic> fields, {required bool json}) {
  if (json) {
    final m = <String, dynamic>{'request': '$request'};
    fields.forEach((k, v) {
      if (v is List) {
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
    AppLog.add('STB', 'login ok model=${i.model} sn=${i.serial} platform=${i.platform} sw=${i.swVersion}.${i.swSub} flags=0x${i.flags.toRadixString(16)} ${json ? 'JSON' : 'XML'}');
    _keep = Timer.periodic(const Duration(seconds: 10), (_) => send(26, {}, reply: false).catchError((_) => null));
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
}

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
