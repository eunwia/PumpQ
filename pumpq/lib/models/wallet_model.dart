class WalletModel {
  final int walletId;
  final double balance;

  const WalletModel({required this.walletId, required this.balance});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['wallet_id'] as int,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

class WalletTransactionModel {
  final int wtId;
  final double amount;
  final String transactionType;
  final String? referenceId;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.wtId,
    required this.amount,
    required this.transactionType,
    this.referenceId,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      wtId: json['wt_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      referenceId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isTopUp => transactionType.startsWith('topup_');

  String get displayLabel {
    if (transactionType.startsWith('topup_')) {
      final method = transactionType.replaceFirst('topup_', '').toUpperCase();
      return 'Top-up via $method';
    }
    return transactionType;
  }
}