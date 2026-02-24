import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key});

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  String get _deviceName {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS)     return 'iPhone / iPad';
      if (Platform.isWindows) return 'Windows PC';
      if (Platform.isMacOS)   return 'Mac';
      if (Platform.isLinux)   return 'Linux';
    } catch (_) {}
    return 'Unknown Device';
  }

  IconData get _deviceIcon {
    if (kIsWeb) return Icons.language_rounded;
    try {
      if (Platform.isAndroid) return Icons.phone_android_rounded;
      if (Platform.isIOS)     return Icons.phone_iphone_rounded;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
        return Icons.computer_rounded;
    } catch (_) {}
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: steelBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_deviceIcon, color: steelBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Connected Device',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(_deviceName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: navyBlue)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('Active',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }
}