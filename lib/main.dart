import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const Color ink = Color(0xFF172B4D);
const Color muted = Color(0xFF718096);
const Color violet = Color(0xFF6558F5);
const Color mint = Color(0xFF20B486);
const Color canvas = Color(0xFFF5F7FC);
const Color coral = Color(0xFFFF826E);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AttendanceStore();
  await store.load();
  runApp(ChangeNotifierProvider.value(value: store, child: const AttendanceApp()));
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: Brightness.light),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8EBF4))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: violet, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class Subject {
  Subject({required this.id, required this.name, required this.code, required this.color, this.present = 0, this.absent = 0, this.cancelled = 0});
  final String id;
  final String name;
  final String code;
  final Color color;
  int present;
  int absent;
  int cancelled;
  int get total => present + absent;
  double get percentage => total == 0 ? 0 : present / total * 100;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code, 'color': color.value, 'present': present, 'absent': absent, 'cancelled': cancelled};
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
    id: j['id'], name: j['name'], code: j['code'], color: Color(j['color']),
    present: j['present'] ?? 0, absent: j['absent'] ?? 0, cancelled: j['cancelled'] ?? 0,
  );
}

class AttendanceStore extends ChangeNotifier {
  final List<Subject> subjects = [
    Subject(id: '1', name: 'Data Structures', code: 'CS201', color: const Color(0xFF6558F5), present: 18, absent: 2),
    Subject(id: '2', name: 'Database Systems', code: 'CS202', color: const Color(0xFF20B486), present: 16, absent: 2),
    Subject(id: '3', name: 'Computer Networks', code: 'CS203', color: const Color(0xFFFF826E), present: 13, absent: 5),
    Subject(id: '4', name: 'Operating Systems', code: 'CS204', color: const Color(0xFF3998F5), present: 17, absent: 1),
  ];
  final List<Map<String, dynamic>> history = [];
  int _nextId = 5;

  int get totalClasses => subjects.fold(0, (sum, s) => sum + s.total);
  int get totalPresent => subjects.fold(0, (sum, s) => sum + s.present);
  double get overall => totalClasses == 0 ? 0 : totalPresent / totalClasses * 100;
  int get belowTarget => subjects.where((s) => s.total > 0 && s.percentage < 75).length;

  int classesNeeded(Subject s, {double target = 75}) {
    if (s.percentage >= target) return 0;
    // (present + x)/(total + x) >= target/100
    return ((target * s.total - 100 * s.present) / (100 - target)).ceil().clamp(0, 100000);
  }

  int safeAbsences(Subject s, {double target = 75}) {
    if (s.total == 0 || s.percentage < target) return 0;
    // (present)/(total + x) >= target/100
    return ((100 * s.present / target) - s.total).floor().clamp(0, 100000);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('attendly_subjects');
    if (raw != null) {
      try {
        final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        subjects
          ..clear()
          ..addAll(decoded.map(Subject.fromJson));
        _nextId = subjects.length + 1;
      } catch (_) {}
    }
    final h = prefs.getString('attendly_history');
    if (h != null) {
      try { history.addAll((jsonDecode(h) as List).cast<Map<String, dynamic>>()); } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendly_subjects', jsonEncode(subjects.map((s) => s.toJson()).toList()));
    await prefs.setString('attendly_history', jsonEncode(history));
  }

  void addSubject(String name, String code) {
    subjects.add(Subject(id: '${_nextId++}', name: name.trim(), code: code.trim().toUpperCase(), color: [violet, mint, coral, const Color(0xFF3998F5)][subjects.length % 4]));
    _save(); notifyListeners();
  }

  void mark(Subject s, String status) {
    if (status == 'Present') s.present++;
    if (status == 'Absent') s.absent++;
    if (status == 'Cancelled') s.cancelled++;
    if (status != 'Cancelled') {
      history.insert(0, {'subject': s.name, 'status': status, 'date': DateTime.now().toIso8601String()});
    }
    _save(); notifyListeners();
  }

  void undoLast(Subject s) {
    if (s.present > 0) s.present--;
    _save(); notifyListeners();
  }

  void resetSampleData() {
    subjects
      ..clear()
      ..addAll([
        Subject(id: '1', name: 'Data Structures', code: 'CS201', color: violet, present: 18, absent: 2),
        Subject(id: '2', name: 'Database Systems', code: 'CS202', color: mint, present: 16, absent: 2),
        Subject(id: '3', name: 'Computer Networks', code: 'CS203', color: coral, present: 13, absent: 5),
        Subject(id: '4', name: 'Operating Systems', code: 'CS204', color: const Color(0xFF3998F5), present: 17, absent: 1),
      ]);
    history.clear(); _save(); notifyListeners();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [DashboardPage(), SubjectsPage(), HistoryPage(), CalculatorPage(), SettingsPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: ink.withOpacity(.05), blurRadius: 20, offset: const Offset(0, -4))]),
        child: NavigationBar(
          height: 70, selectedIndex: index, backgroundColor: Colors.white, indicatorColor: violet.withOpacity(.12),
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded, color: violet), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.menu_book_rounded), selectedIcon: Icon(Icons.menu_book_rounded, color: violet), label: 'Subjects'),
            NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.history_rounded, color: violet), label: 'History'),
            NavigationDestination(icon: Icon(Icons.calculate_rounded), selectedIcon: Icon(Icons.calculate_rounded, color: violet), label: 'Calculator'),
            NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded, color: violet), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AttendanceStore>();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 18, wide ? 32 : 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(gradient: const LinearGradient(colors: [violet, Color(0xFF938AFF)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 25)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ATTENDLY', style: TextStyle(fontSize: 12, letterSpacing: 2.2, fontWeight: FontWeight.w800, color: violet)),
              SizedBox(height: 3), Text('Good to see you!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
            ])),
            CircleAvatar(backgroundColor: const Color(0xFFEAE8FF), child: const Text('S', style: TextStyle(color: violet, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 24),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5144E8), Color(0xFF8175FF)]), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: violet.withOpacity(.22), blurRadius: 24, offset: const Offset(0, 12))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YOUR ATTENDANCE', style: TextStyle(color: Color(0xFFDCD8FF), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8), Text('Stay on track.', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5), Text('Every class counts towards your goal.', style: TextStyle(color: Color(0xFFE5E2FF), fontSize: 12)),
                ])),
                SizedBox(width: 105, height: 105, child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(child: CircularProgressIndicator(value: store.overall / 100, strokeWidth: 9, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF75F0C5)))),
                  Column(mainAxisSize: MainAxisSize.min, children: [Text('${store.overall.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)), const Text('overall', style: TextStyle(color: Color(0xFFE5E2FF), fontSize: 11))]),
                ])),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _HeroStat(label: 'ATTENDED', value: '${store.totalPresent}', icon: Icons.check_circle_outline_rounded)),
                Container(height: 38, width: 1, color: Colors.white24),
                Expanded(child: _HeroStat(label: 'TOTAL CLASSES', value: '${store.totalClasses}', icon: Icons.calendar_month_rounded)),
                Container(height: 38, width: 1, color: Colors.white24),
                Expanded(child: _HeroStat(label: 'NEED ATTENTION', value: '${store.belowTarget}', icon: Icons.flag_outlined)),
              ]),
            ]),
          ),
          const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subject overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
            TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllSubjectsDialogPage())), child: const Text('View all')),
          ]),
          const SizedBox(height: 6),
          if (wide)
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.25, crossAxisSpacing: 14, mainAxisSpacing: 14), itemCount: store.subjects.length, itemBuilder: (_, i) => SubjectCard(subject: store.subjects[i]))
          else
            ...store.subjects.map((s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SubjectCard(subject: s))),
          const SizedBox(height: 10),
          const Text('Quick tip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 12),
          const QuoteCard(),
        ]),
      );
    });
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value, required this.icon});
  final String label, value; final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 17, color: const Color(0xFFDCD8FF)), const SizedBox(height: 7),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2), Text(label, style: const TextStyle(color: Color(0xFFDCD8FF), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: .5), maxLines: 1, overflow: TextOverflow.ellipsis),
  ]));
}

class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject});
  final Subject subject;
  @override
  Widget build(BuildContext context) {
    final low = subject.percentage < 75;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFEEF0F6)), boxShadow: [BoxShadow(color: ink.withOpacity(.025), blurRadius: 14, offset: const Offset(0, 5))]),
      child: Column(children: [
        Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: subject.color.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.menu_book_rounded, color: subject.color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 4), Text(subject.code, style: const TextStyle(fontSize: 11, color: muted, letterSpacing: .5))])),
          Text('${subject.percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: low ? const Color(0xFFE35D6A) : subject.color)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: subject.percentage / 100, minHeight: 7, backgroundColor: const Color(0xFFF0F1F7), color: low ? const Color(0xFFE35D6A) : subject.color)),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: Text('${subject.present} present  •  ${subject.absent} absent', style: const TextStyle(fontSize: 11, color: muted))),
          if (low) const Text('Below 75%', style: TextStyle(fontSize: 10, color: Color(0xFFE35D6A), fontWeight: FontWeight.w700)) else const Icon(Icons.check_circle_rounded, color: mint, size: 17),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => context.read<AttendanceStore>().mark(subject, 'Present'), icon: const Icon(Icons.check_rounded, size: 17), label: const Text('Present'), style: OutlinedButton.styleFrom(foregroundColor: mint, side: const BorderSide(color: Color(0xFFCDEFE3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 9),
          Expanded(child: OutlinedButton.icon(onPressed: () => context.read<AttendanceStore>().mark(subject, 'Absent'), icon: const Icon(Icons.close_rounded, size: 17), label: const Text('Absent'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE35D6A), side: const BorderSide(color: Color(0xFFF6D7DB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ]),
      ]),
    );
  }
}

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AttendanceStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('My subjects', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () => _showAddSubject(context), icon: const Icon(Icons.add_circle_rounded, color: violet, size: 30))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 25), children: [
        const Text('Keep every class accounted for.', style: TextStyle(color: muted, fontSize: 13)),
        const SizedBox(height: 18),
        ...store.subjects.map((s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SubjectCard(subject: s))),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () => _showAddSubject(context), icon: const Icon(Icons.add), label: const Text('Add a subject'), style: FilledButton.styleFrom(backgroundColor: violet, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      ]),
    );
  }
}

void _showAddSubject(BuildContext context) {
  final name = TextEditingController(); final code = TextEditingController();
  final key = GlobalKey<FormState>();
  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (ctx) => Padding(
    padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(ctx).viewInsets.bottom + 24),
    child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Add a subject', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
      const SizedBox(height: 6), const Text('Add the details to start tracking attendance.', style: TextStyle(color: muted)),
      const SizedBox(height: 20),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Subject name', hintText: 'e.g. Software Engineering'), textCapitalization: TextCapitalization.words, validator: (v) => v == null || v.trim().length < 2 ? 'Enter a valid subject name' : null),
      const SizedBox(height: 12),
      TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Subject code', hintText: 'e.g. CS205'), textCapitalization: TextCapitalization.characters, validator: (v) => v == null || v.trim().isEmpty ? 'Enter a subject code' : null),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
        if (key.currentState!.validate()) { context.read<AttendanceStore>().addSubject(name.text, code.text); Navigator.pop(ctx); }
      }, style: FilledButton.styleFrom(backgroundColor: violet, minimumSize: const Size.fromHeight(52)), child: const Text('Save subject'))),
    ])),
  ));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final history = context.watch<AttendanceStore>().history;
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance history', style: TextStyle(fontWeight: FontWeight.w800))),
      body: history.isEmpty
        ? const EmptyState(icon: Icons.history_rounded, title: 'Your story starts here', message: 'Mark a class as present or absent and your recent activity will appear here.')
        : ListView.separated(padding: const EdgeInsets.all(20), itemCount: history.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, i) {
          final item = history[i]; final present = item['status'] == 'Present'; final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
          return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: (present ? mint : coral).withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(present ? Icons.check_rounded : Icons.close_rounded, color: present ? mint : coral)),
            const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['subject'] ?? 'Subject', style: const TextStyle(color: ink, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: muted, fontSize: 12))])),
            Text(item['status'] ?? '', style: TextStyle(color: present ? mint : coral, fontWeight: FontWeight.w800)),
          ]));
        }),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}
class _CalculatorPageState extends State<CalculatorPage> {
  String? selectedId;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AttendanceStore>();
    final matching = store.subjects.where((s) => s.id == selectedId);
    final selected = matching.isNotEmpty ? matching.first : (store.subjects.isNotEmpty ? store.subjects.first : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Smart calculator', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF172B4D), Color(0xFF304D7D)]), borderRadius: BorderRadius.circular(25)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF9B94FF), size: 30), SizedBox(height: 14),
          Text('Plan your next class.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8), Text('Choose a subject to see how to reach or maintain 75% attendance.', style: TextStyle(color: Color(0xFFD5DDED), height: 1.4)),
        ])),
        const SizedBox(height: 22),
        const Text('Select subject', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selected?.id, decoration: const InputDecoration(prefixIcon: Icon(Icons.menu_book_rounded)),
          items: store.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.code})', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => selectedId = v),
        ),
        const SizedBox(height: 20),
        if (selected != null) ...[
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CURRENT ATTENDANCE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10), Text('${selected.percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: selected.percentage < 75 ? coral : mint)),
            Text('${selected.present} attended out of ${selected.total} classes', style: const TextStyle(color: muted)),
            const SizedBox(height: 18), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: selected.percentage / 100, minHeight: 9, color: selected.percentage < 75 ? coral : mint, backgroundColor: const Color(0xFFF0F1F7))),
          ])),
          const SizedBox(height: 14),
          _CalcResult(icon: Icons.school_rounded, color: violet, title: selected.percentage >= 75 ? 'You are above the target' : 'Classes needed to reach 75%', value: selected.percentage >= 75 ? '0 classes' : '${store.classesNeeded(selected)} classes', detail: selected.percentage >= 75 ? 'Keep attending to maintain your buffer.' : 'Attend the next ${store.classesNeeded(selected)} classes without missing one.'),
          const SizedBox(height: 12),
          _CalcResult(icon: Icons.event_available_rounded, color: mint, title: 'Safe absences from here', value: selected.percentage >= 75 ? '${store.safeAbsences(selected)} classes' : '0 classes', detail: selected.percentage >= 75 ? 'Maximum additional absences before dropping below 75%, assuming every other class is attended.' : 'First attend classes until you reach the required threshold.'),
        ],
        const SizedBox(height: 18),
        const Text('Calculation assumes future classes are held and only recorded Present/Absent classes count.', style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
      ]),
    );
  }
}

class _CalcResult extends StatelessWidget {
  const _CalcResult({required this.icon, required this.color, required this.title, required this.value, required this.detail});
  final IconData icon; final Color color; final String title, value, detail;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
    const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7), Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(detail, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
    ])),
  ]));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [violet, Color(0xFF938AFF)]), borderRadius: BorderRadius.circular(24)), child: const Row(children: [
        CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person_rounded, color: Colors.white, size: 30)),
        SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Student profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Your learning, your progress.', style: TextStyle(color: Color(0xFFE5E2FF)))])),
      ])),
      const SizedBox(height: 22),
      const _SettingTile(icon: Icons.flag_rounded, title: 'Attendance target', subtitle: 'Default target is 75%', trailing: '75%'),
      const _SettingTile(icon: Icons.palette_outlined, title: 'App appearance', subtitle: 'Light theme • Material 3'),
      const _SettingTile(icon: Icons.cloud_sync_outlined, title: 'Data storage', subtitle: 'Attendance saved on this device'),
      const _SettingTile(icon: Icons.api_rounded, title: 'API integration', subtitle: 'Optional daily quote endpoint'),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Reset sample data?'), content: const Text('This replaces your current subjects and clears history with the original demo data.'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { context.read<AttendanceStore>().resetSampleData(); Navigator.pop(ctx); }, child: const Text('Reset')),
      ])), icon: const Icon(Icons.restart_alt_rounded), label: const Text('Reset demo data'), style: OutlinedButton.styleFrom(foregroundColor: coral, minimumSize: const Size.fromHeight(52), side: const BorderSide(color: Color(0xFFF4D4D1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      const SizedBox(height: 22),
      const Center(child: Text('ATTENDLY  •  UID FLUTTER PROJECT', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800))),
      const SizedBox(height: 5), const Center(child: Text('Made for better class habits.', style: TextStyle(color: muted, fontSize: 12))),
    ]),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.subtitle, this.trailing});
  final IconData icon; final String title, subtitle; final String? trailing;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: violet.withOpacity(.09), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: violet)),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted, fontSize: 12))])),
    if (trailing != null) Text(trailing!, style: const TextStyle(color: violet, fontWeight: FontWeight.w900)),
  ]));
}

class QuoteCard extends StatefulWidget {
  const QuoteCard({super.key});
  @override
  State<QuoteCard> createState() => _QuoteCardState();
}
class _QuoteCardState extends State<QuoteCard> {
  String quote = 'Small steps every day lead to big results.';
  String author = 'Your daily reminder';
  bool loading = false;
  Future<void> refreshQuote() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty && mounted) { setState(() { quote = data[0]['q'] ?? quote; author = data[0]['a'] ?? author; }); }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load a quote. Showing your saved tip.')));
    } finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFEAF8F3), borderRadius: BorderRadius.circular(20)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: mint.withOpacity(.14), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.lightbulb_outline_rounded, color: mint)),
    const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('"$quote"', style: const TextStyle(color: Color(0xFF285F50), fontWeight: FontWeight.w700, height: 1.45)),
      const SizedBox(height: 6), Text('— $author', style: const TextStyle(color: Color(0xFF588578), fontSize: 11)),
      const SizedBox(height: 9), InkWell(onTap: loading ? null : refreshQuote, child: Row(mainAxisSize: MainAxisSize.min, children: [if (loading) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)) else const Icon(Icons.refresh_rounded, size: 15, color: mint), const SizedBox(width: 5), const Text('Refresh quote', style: TextStyle(color: mint, fontWeight: FontWeight.w800, fontSize: 12))])),
    ])),
  ]));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon; final String title, message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(36), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 86, height: 86, decoration: BoxDecoration(color: violet.withOpacity(.1), borderRadius: BorderRadius.circular(28)), child: Icon(icon, color: violet, size: 40)),
    const SizedBox(height: 20), Text(title, style: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
    const SizedBox(height: 8), Text(message, style: const TextStyle(color: muted, height: 1.5), textAlign: TextAlign.center),
  ])));
}

class AllSubjectsDialogPage extends StatelessWidget {
  const AllSubjectsDialogPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('All subjects')), body: Consumer<AttendanceStore>(builder: (context, store, _) => ListView(padding: const EdgeInsets.all(20), children: store.subjects.map((s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SubjectCard(subject: s))).toList()));
}
