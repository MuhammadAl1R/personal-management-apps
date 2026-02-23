class TransactionItem {
  int? id;
  String title;
  int amount;
  bool isExpense;
  String date;
  String category;

  TransactionItem({
    this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isExpense': isExpense ? 1 : 0,
      'date': date,
      'category': category,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      isExpense: map['isExpense'] == 1,
      date: map['date'],
      category: map['category'] 
    );
  }
}