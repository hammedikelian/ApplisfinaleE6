// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        user = jsonDecode(userData);
      });
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget settingItem({required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurpleAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadUser,
        child: user == null
            ? ListView(
                children: [SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurpleAccent,
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      '${user!['prenom']} ${user!['nom']}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      user!['email'],
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 40, color: Colors.white24),
                  settingItem(icon: Icons.phone, title: user!['telephone']?.toString() ?? 'Aucun numéro'),
                  settingItem(icon: Icons.lock_outline, title: 'Changer le mot de passe'),
                  settingItem(icon: Icons.settings, title: "Préférences de l'application"),
                  settingItem(icon: Icons.info_outline, title: "À propos de l'application", onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'La League Admin',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.audiotrack),
                      children: const [
                        Text("Application d'administration de la boutique audio La League."),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Déconnexion"),
                  ),
                ],
              ),
      ),
    );
  }
}
