import 'package:flutter/material.dart';

class BackendUnavailableScreen extends StatelessWidget {
  const BackendUnavailableScreen({
    super.key,
    required this.appTitle,
    required this.message,
    this.accentColor = const Color(0xFFB71C1C),
  });

  final String appTitle;
  final String message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6EEE8), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: accentColor.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          color: accentColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$appTitle backend unavailable',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Add valid Supabase URL and anon key, then rebuild or relaunch this app.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
