// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    fetchUsers();
  }

  Future<void> fetchCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        currentUser = json.decode(userData);
      });
    }
  }

  Future<void> fetchUsers() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:3000/users'));
      setState(() {
        users = json.decode(res.body);
      });
    } catch (e) {
      print("Erreur lors de la requête: $e");
      showMessage('Erreur de chargement', isError: true);
    }
  }

  void showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> promoteUser(int id) async {
    final res = await http.patch(Uri.parse('http://10.0.2.2:3000/users/$id/promote'));
    if (res.statusCode == 200) {
      showMessage('Utilisateur promu');
      fetchUsers();
    } else {
      showMessage('Erreur promotion', isError: true);
    }
  }

  Future<void> demoteUser(int id) async {
    final res = await http.patch(Uri.parse('http://10.0.2.2:3000/users/$id/demote'));
    if (res.statusCode == 200) {
      showMessage('Utilisateur rétrogradé');
      fetchUsers();
    } else {
      showMessage('Erreur rétrogradation', isError: true);
    }
  }

  Future<void> deleteUser(int id) async {
    final res = await http.delete(Uri.parse('http://10.0.2.2:3000/users/$id'));
    if (res.statusCode == 200) {
      showMessage('Utilisateur supprimé');
      fetchUsers();
    } else {
      showMessage('Erreur suppression', isError: true);
    }
  }

  void showEditDialog(Map<String, dynamic> user) {
    final _formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> controllers = {
      'nom': TextEditingController(text: user['nom']),
      'prenom': TextEditingController(text: user['prenom']),
      'email': TextEditingController(text: user['email']),
      'telephone': TextEditingController(text: user['telephone']),
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Modifier l'utilisateur", style: TextStyle(color: Colors.white)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: entry.value,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: entry.key.toUpperCase(),
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Map<String, dynamic> updated = {};
              controllers.forEach((key, ctrl) {
                if (ctrl.text != user[key]) {
                  updated[key] = ctrl.text;
                }
              });

              if (updated.isEmpty) {
                showMessage("Aucun changement détecté", isError: true);
                return;
              }

              final res = await http.patch(
                Uri.parse('http://10.0.2.2:3000/users/${user['id']}'),
                headers: {"Content-Type": "application/json"},
                body: json.encode(updated),
              );

              if (res.statusCode == 200) {
                showMessage("Utilisateur mis à jour");
                fetchUsers();
              } else {
                showMessage("Erreur de mise à jour", isError: true);
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void showUserDetailsSheet(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Text('${user['prenom']} ${user['nom']}',
                style: const TextStyle(
                    fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Email : ${user['email']}',
                style: const TextStyle(color: Colors.white70)),
            Text('Téléphone : ${user['telephone'] ?? "-"}',
                style: const TextStyle(color: Colors.white70)),
            Text('Rôle : ${user['role']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            if (currentUser != null && currentUser!['role'] == 'super_admin')
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showEditDialog(user),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Modifier", style: TextStyle(color: Colors.white)),
                  ),
                  if (user['role'] == 'admin')
                    OutlinedButton.icon(
                      onPressed: () => promoteUser(user['id']),
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      label: const Text("Promouvoir", style: TextStyle(color: Colors.white)),
                    ),
                  if (user['role'] == 'super_admin')
                    OutlinedButton.icon(
                      onPressed: () => demoteUser(user['id']),
                      icon: const Icon(Icons.arrow_downward, color: Colors.white),
                      label: const Text("Rétrograder en Admin", style: TextStyle(color: Colors.white)),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => deleteUser(user['id']),
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    label: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget userCard(Map<String, dynamic> user) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text('${user['prenom']} ${user['nom']}',
                  style: const TextStyle(color: Colors.white)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user['role'] == 'super_admin'
                    ? Colors.purple
                    : user['role'] == 'admin'
                        ? Colors.blue
                        : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user['role'],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () => showUserDetailsSheet(user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Gestion des utilisateurs",
            style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w300)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: users.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(
                    child: Text(
                      "Aucun utilisateur trouvé",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: users.map((user) => userCard(user)).toList(),
              ),
      ),
    );
  }
}
