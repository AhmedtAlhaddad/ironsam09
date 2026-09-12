import 'package:url_launcher/url_launcher.dart';

class WhatsAppOrderService {
  const WhatsAppOrderService({this.phoneNumber = '218928077643'});

  final String phoneNumber;

  Uri buildOrderUri(String message) {
    return Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );
  }

  Future<bool> send(String message) {
    return launchUrl(
      buildOrderUri(message),
      mode: LaunchMode.externalApplication,
    );
  }
}
