class CommunicationStatus {
  final String provider;
  final String whatsapp;
  final String sms;
  final bool dryRun;
  final bool configured;
  final bool customerAutomation;

  const CommunicationStatus({
    required this.provider,
    required this.whatsapp,
    required this.sms,
    required this.dryRun,
    required this.configured,
    required this.customerAutomation,
  });

  factory CommunicationStatus.fromJson(Map<String, dynamic> json) =>
      CommunicationStatus(
        provider: json['provider']?.toString() ?? 'None',
        whatsapp: json['whatsapp']?.toString() ?? 'Disabled',
        sms: json['sms']?.toString() ?? 'Disabled',
        dryRun: json['dryRun'] == true,
        configured: json['configured'] == true,
        customerAutomation: json['customerAutomation'] == true,
      );
}
