String digitsForWhatsApp(String phone) =>
    phone.replaceAll(RegExp(r'[^\d]'), '');

const String developerWhatsAppNumber = '353892580774';
const String developerFeedbackEmail = 'rob@ixrqq.pro';

Uri developerWhatsAppUri(
  String text, {
  String whatsappNumber = developerWhatsAppNumber,
}) {
  final digits = digitsForWhatsApp(whatsappNumber);
  return Uri.https('wa.me', digits, {'text': text});
}

String developerCorrectionMessage(String pageLabel) =>
    'Hi Rob, I spotted something incorrect on $pageLabel.';

String developerFeedbackMessage(String feedback) => feedback;

Uri developerCorrectionUri({
  String pageLabel = 'this page',
  String whatsappNumber = developerWhatsAppNumber,
  String email = developerFeedbackEmail,
}) {
  final text = developerCorrectionMessage(pageLabel);
  final digits = digitsForWhatsApp(whatsappNumber);
  if (digits.isNotEmpty) {
    return developerWhatsAppUri(text, whatsappNumber: whatsappNumber);
  }
  return Uri(
    scheme: 'mailto',
    path: email,
    query:
        'subject=${Uri.encodeComponent('App correction')}&body=${Uri.encodeComponent(text)}',
  );
}

Uri developerFeedbackUri(
  String feedback, {
  String whatsappNumber = developerWhatsAppNumber,
}) {
  return developerWhatsAppUri(
    developerFeedbackMessage(feedback),
    whatsappNumber: whatsappNumber,
  );
}
