import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StockOrderScreen extends StatefulWidget {
  const StockOrderScreen({super.key});

  @override
  State<StockOrderScreen> createState() => _StockOrderScreenState();
}

class _StockOrderScreenState extends State<StockOrderScreen> {
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  List<String> selectedBrands = [];
  dynamic selectedProduct;
  int quantity = 1;
  String deliveryType = 'standard';
  bool isLoading = false;
  List<String> allBrands = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:3000/api/products'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final brands = data.map<String>((p) => p['marque'].toString()).toSet().toList();
      setState(() {
        allProducts = data;
        allBrands = brands;
        selectedBrands = [];
        filteredProducts = [];
        selectedProduct = null;
      });
    }
  }

  void filterProducts() {
    setState(() {
      filteredProducts = allProducts
          .where((p) => selectedBrands.contains(p['marque']))
          .toList();
      selectedProduct = null;
    });
  }

  double calculateTotal() {
    if (selectedProduct == null) return 0;
    final double price = double.tryParse(selectedProduct['prix_achat'].toString()) ?? 0;
    double total = price * quantity;
    if (deliveryType == 'express') {
      total += 3.99;
    }
    return total;
  }

  Future<void> submitOrder() async {
    if (selectedProduct == null || quantity <= 0) {
      showSnack("Veuillez remplir tous les champs.", true);
      return;
    }

    final body = {
      "produit_id": selectedProduct['id'],
      "quantite": quantity,
      "type_livraison": deliveryType,
      "prix_total": calculateTotal()
    };

    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse('http://10.0.2.2:3000/stock/approvisionnements'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      showSnack("Commande passée avec succès !");
      Navigator.pop(context);
    } else {
      showSnack("Erreur lors de l'envoi", true);
    }
  }

  void showSnack(String message, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Commande de stock'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: allProducts.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                children: [
                  const Text("Sélectionnez une ou plusieurs marques",
                      style: TextStyle(color: Colors.white70)),
                  Wrap(
                    spacing: 8,
                    children: allBrands.map((brand) {
                      final selected = selectedBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            selected
                                ? selectedBrands.remove(brand)
                                : selectedBrands.add(brand);
                            filterProducts();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (filteredProducts.isNotEmpty)
                    DropdownButtonFormField<dynamic>(
                      value: selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Produit',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      dropdownColor: Colors.grey[900],
                      items: filteredProducts.map<DropdownMenuItem>((product) {
                        return DropdownMenuItem(
                          value: product,
                          child:
                              Text(product['nom'], style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedProduct = value);
                      },
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) {
                      setState(() => quantity = int.tryParse(value) ?? 1);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Type de livraison', style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      Radio(
                        value: 'standard',
                        groupValue: deliveryType,
                        onChanged: (value) => setState(() => deliveryType = value!),
                      ),
                      const Text('Standard (2 jours)', style: TextStyle(color: Colors.white)),
                      Radio(
                        value: 'express',
                        groupValue: deliveryType,
                        onChanged: (value) => setState(() => deliveryType = value!),
                      ),
                      const Text('Express', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  if (deliveryType == 'express')
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "+ 3.99€ de frais de livraison express",
                        style: TextStyle(color: Colors.amberAccent),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    "Prix total : ${calculateTotal().toStringAsFixed(2)} € TTC",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : submitOrder,
                    icon: const Icon(Icons.shopping_cart),
                    label: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Commander"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
