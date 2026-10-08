import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

const bleu = Color(0xFF00A2E8);
const vert = Color(0xFF22B14C);
const orange = Color(0xFFFF7F27);
const rouge = Color(0xFFED1C24);

const moisFr = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
];

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${moisFr[d.month - 1]} ${d.year}';

String formatTemps(int s) {
  final h = (s ~/ 3600).toString().padLeft(2, '0');
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$h : $m : $sec';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Discipline',
        home: const HomePage(),
      );
}

class TaskData {
  final TextEditingController nom =
      TextEditingController(text: 'NOM DE LA TACHE');
  int secondes = 0;
  bool enMarche = false;
  Timer? timer;

  void dispose() {
    timer?.cancel();
    nom.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final titre = TextEditingController(text: 'DISCIPLINE');
  DateTime date = DateTime.now();
  final List<TaskData> taches = [TaskData()];

  @override
  void dispose() {
    titre.dispose();
    for (final t in taches) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => date = d);
  }

  void ajouter() => setState(() => taches.add(TaskData()));

  void supprimer() {
    if (taches.isEmpty) return;
    setState(() {
      taches.removeLast().dispose();
    });
  }

  void demarrerOuStopper(TaskData t) {
    if (t.enMarche) {
      t.timer?.cancel();
      setState(() => t.enMarche = false);
      return;
    }
    if (t.secondes == 0) return;
    setState(() => t.enMarche = true);
    t.timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (t.secondes <= 1) {
        tm.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          t.secondes = 0;
          t.enMarche = false;
        });
      } else {
        setState(() => t.secondes--);
      }
    });
  }

  void reset(TaskData t) => setState(() => t.secondes = 0);

  Future<void> regler(TaskData t) async {
    if (t.enMarche) return;
    final h = TextEditingController(text: (t.secondes ~/ 3600).toString());
    final m =
        TextEditingController(text: ((t.secondes % 3600) ~/ 60).toString());
    final s = TextEditingController(text: (t.secondes % 60).toString());

    Widget champ(TextEditingController c, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: c,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(labelText: label),
            ),
          ),
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Régler la minuterie'),
        content: Row(children: [
          champ(h, 'Heures'),
          champ(m, 'Minutes'),
          champ(s, 'Secondes'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK')),
        ],
      ),
    );

    if (ok == true) {
      final hh = int.tryParse(h.text) ?? 0;
      final mm = (int.tryParse(m.text) ?? 0).clamp(0, 59);
      final ss = (int.tryParse(s.text) ?? 0).clamp(0, 59);
      setState(() => t.secondes = hh * 3600 + mm * 60 + ss);
    }
  }

  Widget boutonBlanc(String texte, VoidCallback? onTap) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white70,
            disabledForegroundColor: Colors.black38,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Text(texte,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      );

  Widget boutonOrange(String texte, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(),
        ),
        child:
            Text(texte, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget carteTache(int index, TaskData t) {
    final resetActif = !t.enMarche && t.secondes > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(children: [
        Container(
          color: vert,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            Text('${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 24),
            Expanded(
              child: TextField(
                controller: t.nom,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            Container(
              width: 50,
              height: 36,
              decoration: BoxDecoration(
                color: t.enMarche ? Colors.yellow : rouge,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () => regler(t),
              child: Container(
                height: 56,
                color: Colors.white,
                alignment: Alignment.center,
                child: Text(formatTemps(t.secondes),
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          boutonBlanc(t.enMarche ? 'STOP' : 'START',
              () => demarrerOuStopper(t)),
          const SizedBox(width: 8),
          boutonBlanc('RESET', resetActif ? () => reset(t) : null),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bleu,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: titre,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
            const SizedBox(height: 10),
            Row(children: [
              ElevatedButton(
                onPressed: choisirDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vert,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('DATE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(formatDate(date),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]),
            const SizedBox(height: 28),
            Row(children: [
              const Text('TACHE',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              boutonOrange('Ajouter', ajouter),
              const SizedBox(width: 16),
              boutonOrange('Supprimer', supprimer),
            ]),
            const SizedBox(height: 14),
            for (int i = 0; i < taches.length; i++) carteTache(i, taches[i]),
          ],
        ),
      ),
    );
  }
}
