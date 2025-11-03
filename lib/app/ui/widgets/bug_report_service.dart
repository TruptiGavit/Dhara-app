import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class BugReportService {
  static final BugReportService _instance = BugReportService._internal();
  static BugReportService get instance => _instance;
  BugReportService._internal();

  // Your contact details
  static const String whatsappNumber = '918618717972'; // Your WhatsApp number
  static const String email = 'namaste@bheri.in'; // Your email


  /// Show bug report options to user
  Future<void> showBugReportOptions(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20, // Avoid gesture bar
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.attach_email_rounded, color: Colors.red.shade600),
                ),
                const SizedBox(width: 12),
                const Text(
                  '🐛 Report a Bug',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Found something not working? Help us fix it!',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            
            const SizedBox(height: 24),
            
            // WhatsApp Option
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chat, color: Colors.green.shade600),
                ),
                title: const Text(
                  'Report via WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Attach your screenshot'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  reportBugWhatsApp();
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Email Option
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.email, color: Colors.blue.shade600),
                ),
                title: const Text(
                  'Report via Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Attach your screenshot'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  reportBugEmail();
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Report bug via WhatsApp
  Future<void> reportBugWhatsApp() async {
    try {
      print('📱 BugReportService: Starting WhatsApp bug report...');
      
      // Create simple message
      final message = '''🐛 Dhārā App Bug Report \n\nWhat happened ?  [Describe the problem here]\n\n\n\n📸 Please attach a screenshot if possible\n\nThanks for helping us improve Dhārā! 🙏''';
      ;
      
      // Open WhatsApp
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}';
      print('📱 BugReportService: Opening WhatsApp...');
      
      try {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
        print('📱 BugReportService: WhatsApp opened successfully');
      } catch (e) {
        // Fallback: Try alternative WhatsApp URL format
        try {
          final fallbackUrl = 'whatsapp://send?phone=$whatsappNumber&text=${Uri.encodeComponent(message)}';
          await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        } catch (e2) {
          // Final fallback: Generic sharing
          Share.share(message);
        }
      }
    } catch (e) {
      print('Error reporting bug via WhatsApp: $e');
    }
  }

  /// Report bug via Email
  Future<void> reportBugEmail() async {
    try {
      print('📧 BugReportService: Starting email bug report...');
      
      // Create simple email
      final subject = 'Dhārā App Bug Report';
      
      final body = '''Hi,



I found a bug in the Dhārā app.



What happened:  [Describe the problem]





Device: Android/iOS

App version: Latest



Please find screenshot attached if applicable.



Thanks!''';
      
      // Create email URL
      final emailUrl = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      
      try {
        await launchUrl(Uri.parse(emailUrl), mode: LaunchMode.externalApplication);
        print('📧 BugReportService: Email app opened successfully');
      } catch (e) {
        // Fallback: Generic sharing
        final shareText = '''Bug Report for Dhārā App

$body

Please send this to: $email''';
        Share.share(shareText);
      }
    } catch (e) {
      print('Error reporting bug via email: $e');
    }
  }
}
