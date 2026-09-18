String digitsForWhatsApp(String phone) =>
    phone.replaceAll(RegExp(r'[^\d]'), '');

const String developerWhatsAppNumber = '353892580774';
const String developerFeedbackEmail = 'rob@ixrqq.pro';

String developerCorrectionMessage(String pageLabel) =>
    'Hi Rob, I spotted something incorrect on $pageLabel.';

Uri developerCorrectionUri({
  String pageLabel = 'this page',
  String whatsappNumber = developerWhatsAppNumber,
  String email = developerFeedbackEmail,
}) {
  final text = developerCorrectionMessage(pageLabel);
  final digits = digitsForWhatsApp(whatsappNumber);
  if (digits.isNotEmpty) {
    return Uri.https('wa.me', digits, {'text': text});
  }
  return Uri(
    scheme: 'mailto',
    path: email,
    query:
        'subject=${Uri.encodeComponent('App correction')}&body=${Uri.encodeComponent(text)}',
  );
}
