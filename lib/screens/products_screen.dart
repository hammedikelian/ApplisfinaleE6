// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  bool isLoading = true;
  String? selectedBrand;
  String? selectedFilter;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/products'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data;
          isLoading = false;
        });
        for (var product in data) {
          if ((product['stock'] ?? 0) == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("⚠️ Stock épuisé : ${product['nom']}"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        setState(() => isLoading = false);
        print('Erreur: Statut ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Erreur exception: $e');
    }
  }

  void showProductDialog({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nomCtrl = TextEditingController(text: product?['nom'] ?? '');
    final prixCtrl = TextEditingController(text: product?['prix']?.toString() ?? '');
    final prixAchatCtrl = TextEditingController(text: product?['prix_achat']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?['stock']?.toString() ?? '');
    final imageCtrl = TextEditingController(text: product?['image'] ?? '');
    final marqueCtrl = TextEditingController(text: product?['marque'] ?? '');
    final descriptionCtrl = TextEditingController(text: product?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(isEdit ? "Modifier le produit" : "Ajouter un produit", style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildInput(nomCtrl, 'Nom'),
              _buildInput(prixCtrl, 'Prix', isNumber: true),
              _buildInput(prixAchatCtrl, 'Prix Achat', isNumber: true),
              _buildInput(stockCtrl, 'Stock', isNumber: true, isStock: true),
              _buildInput(marqueCtrl, 'Marque'),
              _buildInput(imageCtrl, 'Image (chemin)'),
              _buildInput(descriptionCtrl, 'Description'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              final prix = double.tryParse(prixCtrl.text);
              final prixAchat = double.tryParse(prixAchatCtrl.text);
              final stock = int.tryParse(stockCtrl.text);

              if (prix == null || prixAchat == null || prix < 0 || prixAchat < 0 || stock == null || stock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Aucun champ ne peut être négatif ou vide"), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(context);
              final payload = {
                'nom': nomCtrl.text,
                'prix': prix,
                'prix_achat': prixAchat,
                'marque': marqueCtrl.text,
                'stock': stock,
                'image': imageCtrl.text,
                'description': descriptionCtrl.text,
              };
              final url = isEdit
                  ? "http://10.0.2.2:3000/products/${product!['id']}"
                  : 'http://10.0.2.2:3000/products';
              final method = isEdit ? http.patch : http.post;

              final res = await method(
                Uri.parse(url),
                headers: {"Content-Type": "application/json"},
                body: json.encode(payload),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                fetchProducts();
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {bool isNumber = false, bool isStock = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }



  List<dynamic> get filteredProducts {
    List<dynamic> filtered = [...products];
    if (selectedBrand != null && selectedBrand != 'Tous') {
      filtered = filtered.where((p) => p['marque'] == selectedBrand).toList();
    }
    if (selectedFilter == 'Prix croissant') {
      filtered.sort((a, b) {
        final prixA = double.tryParse(a['prix'].toString()) ?? 0;
        final prixB = double.tryParse(b['prix'].toString()) ?? 0;
        return prixA.compareTo(prixB);
      });
    } else if (selectedFilter == 'Prix décroissant') {
      filtered.sort((a, b) {
        final prixA = double.tryParse(a['prix'].toString()) ?? 0;
        final prixB = double.tryParse(b['prix'].toString()) ?? 0;
        return prixB.compareTo(prixA);
      });
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Catalogue Produits', style: TextStyle(letterSpacing: 1.2)),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => selectedFilter = value),
            icon: const Icon(Icons.filter_list),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Prix croissant', child: Text('Prix croissant')),
              PopupMenuItem(value: 'Prix décroissant', child: Text('Prix décroissant')),
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: () => showProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedBrand,
                    hint: const Text("Filtrer par marque"),
                    dropdownColor: Colors.grey[900],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'Tous',
                        child: Text('Tous les produits', style: TextStyle(color: Colors.white)),
                      ),
                      ...{for (var p in products) p['marque']}.where((m) => m != null).map(
                        (m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white))),
                      )
                    ],
                    onChanged: (value) => setState(() => selectedBrand = value),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final imagePath = product['image'];
                      final prix = double.tryParse(product['prix'].toString()) ?? 0;

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.redAccent, size: 40)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(product['nom'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text('$prix €', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.deepPurpleAccent),
                                        onPressed: () => showProductDialog(product: product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Supprimer le produit ?"),
                                              content: const Text("Cette action est irréversible."),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            final res = await http.delete(Uri.parse("http://10.0.2.2:3000/products/${product['id']}"));
                                            if (res.statusCode == 200) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Produit supprimé avec succès")),
                                              );
                                              fetchProducts();
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
