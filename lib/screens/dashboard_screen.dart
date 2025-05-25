// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart';
import 'package:applis_final/screens/StockOrderScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool showStatsDay = false;

  Map<String, dynamic>? statsToday;
  Map<String, dynamic>? statsMonth;
  List<dynamic> topProducts = [];
  Map<String, double> pieData = {};

  final List<Color> neonColors = [
    Color(0xFFFF00FF), // magenta
    Color(0xFF00FFFF), // cyan
    Color(0xFFFF1493), // deep pink
  ];

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final todayRes = await http.get(Uri.parse('http://10.0.2.2:3000/dashboard/stats-today'));
      final monthRes = await http.get(Uri.parse('http://10.0.2.2:3000/dashboard/stats-month'));
      final topRes = await http.get(Uri.parse('http://10.0.2.2:3000/dashboard/top-products'));

      final decoded = json.decode(topRes.body);
      final Iterable<dynamic> topProductsData = (decoded is List)
          ? decoded
          : (decoded['data'] ?? []);

      final Map<String, double> chartData = {};
      for (var item in topProductsData) {
        final value = double.tryParse(item['total_vendus'].toString());
        if (value != null && value > 0) {
          chartData[item['nom']] = value;
        }
      }

      setState(() {
        statsToday = json.decode(todayRes.body);
        statsMonth = json.decode(monthRes.body);
        topProducts = topProductsData.toList();
        pieData = chartData;
      });
    } catch (e) {
      print('Erreur: $e');
    }
  }

  Widget statItem(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value == null || value == 'null' ? '0' : value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget sectionCard({required String title, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w400)),
              const SizedBox(height: 12),
              child
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        title: const Text("LA LEAGUE",
            style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w300,
                fontSize: 18,
                color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionCard(
              title: '📊 Statistiques du jour',
              onTap: () => setState(() => showStatsDay = !showStatsDay),
              child: showStatsDay
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        statItem("Commandes", statsToday?['commandes']?.toString()),
                        statItem("Ventes", statsToday?['ventes']?.toString()),
                        statItem("Chiffre d'affaire (€)", statsToday?['chiffre_affaire']?.toString()),
                      ],
                    )
                  : const Text("Appuyez pour voir les statistiques",
                      style: TextStyle(color: Colors.white54)),
            ),
            sectionCard(
              title: '📦 Gestion des commandes',
              onTap: () => Navigator.pushNamed(context, '/orders'),
              child: const Text("Appuyez pour accéder à la gestion des commandes",
                  style: TextStyle(color: Colors.white54)),
            ),
            sectionCard(
              title: '👥 Gestion des utilisateurs',
              onTap: () => Navigator.pushNamed(context, '/users'),
              child: const Text("Appuyez pour accéder à la gestion des utilisateurs",
                  style: TextStyle(color: Colors.white54)),
            ),
            sectionCard(
              title: '🥇 Top 3 ventes du mois',
              child: pieData.isNotEmpty
                  ? Column(
                      children: [
                        PieChart(
                          dataMap: pieData,
                          chartType: ChartType.disc,
                          chartRadius: MediaQuery.of(context).size.width / 2.5,
                          colorList: neonColors,
                          legendOptions: const LegendOptions(
                            showLegends: false,
                          ),
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: false,
                            showChartValues: true,
                            showChartValueBackground: false,
                            chartValueStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...pieData.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final label = entry.value.key;
                          final value = entry.value.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: neonColors[index % neonColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "$label (${value.toInt()} vendus)",
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    )
                  : const Center(
                      child: Text(
                        "Aucune donnée de vente disponible",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
            sectionCard(
              title: '📅 Statistiques du mois',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statItem("Commandes", statsMonth?['commandes']?.toString()),
                  statItem("Ventes", statsMonth?['ventes']?.toString()),
                  statItem("Chiffre d'affaire (€)", statsMonth?['chiffre_affaire']?.toString()),
                ],
              ),
            ),
            sectionCard(
              title: '📦 Gestion du stock',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockOrderScreen()),
                );
              },
              child: const Text("Appuyez pour accéder à la gestion du stock",
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
