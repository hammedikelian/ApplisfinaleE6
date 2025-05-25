// ignore_for_file: unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'StockOrderScreen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool showReapro = false;
  String filter = 'all';
  List<Map<String, dynamic>> clientOrders = [];
  List<dynamic> reaproOrders = [];

  @override
  void initState() {
    super.initState();
    fetchClientOrders();
    fetchReaproOrders();
  }

  Future<void> fetchClientOrders() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:3000/ventes'));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      setState(() {
        clientOrders = data.map<Map<String, dynamic>>((item) => {
              'orderId': item['id'],
              'status': item['statut'] ?? 'en attente',
              'date': item['date_vente'] ?? '',
              'produit': item['produit_nom'] ?? '',
              'quantite': item['quantite'],
              'total': item['total'],
              'client': '${item['client_prenom'] ?? ''} ${item['client_nom'] ?? ''}'.trim(),
            }).toList();
      });
    } else {
      print("Erreur chargement ventes : ${res.statusCode}");
    }
  }

  Future<void> fetchReaproOrders() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:3000/stock/approvisionnements'));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      setState(() {
        reaproOrders = data;
      });
    }
  }

  Future<void> updateClientOrderStatus(int orderId, String newStatus) async {
    final res = await http.patch(
      Uri.parse('http://10.0.2.2:3000/ventes/$orderId/statut'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'statut': newStatus}),
    );

    if (res.statusCode == 200) {
      await fetchClientOrders();
      Navigator.pop(context);
    } else {
      print('Erreur mise à jour statut : ${res.body}');
    }
  }

  Future<void> updateReaproStatus(int orderId, String newStatus) async {
    final res = await http.patch(
      Uri.parse('http://10.0.2.2:3000/stock/approvisionnements/$orderId/statut'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'statut': newStatus}),
    );

    if (res.statusCode == 200) {
      await fetchReaproOrders();
      Navigator.pop(context);
    } else {
      print('Erreur mise à jour statut réappro : ${res.body}');
    }
  }

  Widget buildClientOrders() {
    List<Map<String, dynamic>> filtered = clientOrders;

    if (filter == 'pending') {
      filtered = clientOrders.where((o) => o['status'] == 'en attente').toList();
    } else if (filter == 'received') {
      filtered = clientOrders.where((o) => o['status'] == 'expédiée').toList();
    } else if (filter == 'recent') {
      filtered = List.from(clientOrders)..sort((a, b) => b['date'].compareTo(a['date']));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: filter,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Filtrer par',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Toutes les commandes')),
              DropdownMenuItem(value: 'pending', child: Text('En attente')),
              DropdownMenuItem(value: 'received', child: Text('Expédiées')),
              DropdownMenuItem(value: 'recent', child: Text('Les plus récentes')),
            ],
            onChanged: (val) => setState(() => filter = val!),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aucune commande client', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return buildOrderCard(
                      title: 'Commande #${order['orderId']} - ${order['produit']}',
                      subtitle: '${order['quantite']} pcs • ${order['total']} € • ${order['date']}',
                      status: order['status'],
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text('Commande #${order['orderId']}', style: const TextStyle(color: Colors.white)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Produit : ${order['produit']}', style: const TextStyle(color: Colors.white70)),
                              Text('Quantité : ${order['quantite']}', style: const TextStyle(color: Colors.white70)),
                              Text('Prix total : ${order['total']} €', style: const TextStyle(color: Colors.white70)),
                              Text('Date : ${order['date']}', style: const TextStyle(color: Colors.white70)),
                              Text('Client : ${order['client']}', style: const TextStyle(color: Colors.white70)),
                              Text('Statut : ${order['status']}', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                final newStatus = order['status'] == 'expédiée' ? 'en attente' : 'expédiée';
                                updateClientOrderStatus(order['orderId'], newStatus);
                              },
                              child: const Text("Changer le statut", style: TextStyle(color: Colors.amberAccent)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Fermer", style: TextStyle(color: Colors.deepPurpleAccent)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget buildReaproOrders() {
    List<dynamic> filtered = reaproOrders;

    if (filter == 'pending') {
      filtered = reaproOrders.where((o) => o['statut'] == 'commandée').toList();
    } else if (filter == 'received') {
      filtered = reaproOrders.where((o) => o['statut'] == 'reçue').toList();
    } else if (filter == 'recent') {
      filtered.sort((a, b) => b['date_commande'].compareTo(a['date_commande']));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: filter,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Filtrer par',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Toutes les commandes')),
              DropdownMenuItem(value: 'pending', child: Text('En attente')),
              DropdownMenuItem(value: 'received', child: Text('Réceptionnées')),
              DropdownMenuItem(value: 'recent', child: Text('Les plus récentes')),
            ],
            onChanged: (val) => setState(() => filter = val!),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aucune commande de réapprovisionnement', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return buildOrderCard(
                      title: 'Réappro #${order['id']} - ${order['produit_nom']}',
                      subtitle: '${order['quantite']} pcs • ${order['type_livraison']} • ${order['prix_total']} €',
                      status: order['statut'],
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text('Réappro #${order['id']}', style: const TextStyle(color: Colors.white)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Produit : ${order['produit_nom']}', style: const TextStyle(color: Colors.white70)),
                              Text('Quantité : ${order['quantite']}', style: const TextStyle(color: Colors.white70)),
                              Text('Livraison : ${order['type_livraison']}', style: const TextStyle(color: Colors.white70)),
                              Text('Prix total : ${order['prix_total']} €', style: const TextStyle(color: Colors.white70)),
                              Text('Statut actuel : ${order['statut']}', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                final newStatus = order['statut'] == 'reçue' ? 'commandée' : 'reçue';
                                updateReaproStatus(order['id'], newStatus);
                              },
                              child: const Text("Changer le statut", style: TextStyle(color: Colors.amberAccent)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Fermer", style: TextStyle(color: Colors.deepPurpleAccent)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget buildOrderCard({
    required String title,
    required String subtitle,
    String? status,
    VoidCallback? onTap,
  }) {
    Color badgeColor;
    String badgeLabel;

    if (status == 'reçue' || status == 'expédiée') {
      badgeColor = Colors.greenAccent;
      badgeLabel = status == 'reçue' ? 'Reçue' : 'Expédiée';
    } else if (status == 'commandée' || status == 'en attente') {
      badgeColor = Colors.orangeAccent;
      badgeLabel = 'En attente';
    } else {
      badgeColor = Colors.grey;
      badgeLabel = status ?? '';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
          child: Text(badgeLabel, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        backgroundColor: Colors.deepPurpleAccent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => setState(() => showReapro = false),
                child: Text('Commandes Clients', style: TextStyle(color: showReapro ? Colors.white54 : Colors.white, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setState(() => showReapro = true),
                child: Text('Commandes Réapro', style: TextStyle(color: showReapro ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchClientOrders();
          await fetchReaproOrders();
        },
        child: showReapro ? buildReaproOrders() : buildClientOrders(),
      ),
      floatingActionButton: showReapro
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOrderScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text("Nouvelle commande"),
              backgroundColor: Colors.deepPurple,
            )
          : null,
    );
  }
}
