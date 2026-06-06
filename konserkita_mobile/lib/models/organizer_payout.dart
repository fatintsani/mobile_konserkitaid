class OrganizerPayout {
  final int id;
  final int organizerId;
  final int? eventId;
  final int requestedBy;
  final double amount;
  final double platformFee;
  final double netAmount;
  final String bankName;
  final String bankAccountName;
  final String bankAccountNumber;
  final String status;
  final String? adminNote;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;

  OrganizerPayout({
    required this.id,
    required this.organizerId,
    this.eventId,
    required this.requestedBy,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    required this.bankName,
    required this.bankAccountName,
    required this.bankAccountNumber,
    required this.status,
    this.adminNote,
    required this.requestedAt,
    this.approvedAt,
    this.paidAt,
  });

  factory OrganizerPayout.fromJson(Map<String, dynamic> json) {
    return OrganizerPayout(
      id: json['id'],
      organizerId: json['organizer_id'],
      eventId: json['event_id'],
      requestedBy: json['requested_by'],
      amount: double.parse(json['amount'].toString()),
      platformFee: double.parse(json['platform_fee'].toString()),
      netAmount: double.parse(json['net_amount'].toString()),
      bankName: json['bank_name'],
      bankAccountName: json['bank_account_name'],
      bankAccountNumber: json['bank_account_number'],
      status: json['status'],
      adminNote: json['admin_note'],
      requestedAt: DateTime.parse(json['requested_at']),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }
}

class PayoutBalance {
  final double grossRevenue;
  final double platformFee;
  final double netRevenue;
  final double totalPaidOut;
  final double totalLocked;
  final double availableBalance;

  PayoutBalance({
    required this.grossRevenue,
    required this.platformFee,
    required this.netRevenue,
    required this.totalPaidOut,
    required this.totalLocked,
    required this.availableBalance,
  });

  factory PayoutBalance.fromJson(Map<String, dynamic> json) {
    return PayoutBalance(
      grossRevenue: double.parse(json['gross_revenue'].toString()),
      platformFee: double.parse(json['platform_fee'].toString()),
      netRevenue: double.parse(json['net_revenue'].toString()),
      totalPaidOut: double.parse(json['total_paid_out'].toString()),
      totalLocked: double.parse(json['total_locked'].toString()),
      availableBalance: double.parse(json['available_balance'].toString()),
    );
  }
}
