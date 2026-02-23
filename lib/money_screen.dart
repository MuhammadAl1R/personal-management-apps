import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/database_helper.dart';
import 'package:task_management/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  List<TransactionItem> _transactions = [];

  int totalBalance = 0;
  bool isLoading = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool isExpense = true;
  DateTime _pickedDate = DateTime.now();
  List<FlSpot> _chartSpots = const [FlSpot(0,0)];
  double _chartMaxY = 100000;


  Future<void> _selectDate(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _pickedDate) {
      setDialogState(() {
        _pickedDate = picked;
      });
    }
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp.',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper().getTransactions();

    int balance = 0;

    for (var item in data) {
      if (item.isExpense) {
        balance = balance - item.amount;
      } else {
        balance = balance + item.amount;
      }
    }
    _generateChartData(data);
    setState(() {
      _transactions = data;
      totalBalance = balance;
      isLoading = false;
    });
  }

  void _generateChartData(List<TransactionItem> data) {
    if (data.isEmpty) {
      _chartSpots = const [
        FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0), FlSpot(3, 0),
        FlSpot(4, 0), FlSpot(5, 0), FlSpot(6, 0)
      ];
      _chartMaxY = 100000;
      return;
    } 

    List<FlSpot> spots = [];
    double maxY = 0;

    var recentData = data.take(7).toList().reversed.toList();

    for (int i = 0; i < recentData.length; i++) {
      double amount = recentData[i].amount.toDouble();
      if (amount > maxY) maxY = amount;
      spots.add(FlSpot(i.toDouble(), amount));
    }

    for (int i = recentData.length; i < 7;i++) {
      spots.add(FlSpot(i.toDouble(),0));
    }

    _chartSpots = spots;
    _chartMaxY = maxY == 0 ? 100000 : maxY + (maxY * 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF386BF6),
        onPressed: () {
          _showAddTransactionDialog();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  color: Colors.blue,
                  strokeAlign: 12,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'ZenDots',
                                color: Colors.black,
                                height: 0.0,
                              ),
                            ),
                            Text(
                              "Muhammad Ali R",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: "ZenDots",
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${DateTime.now().hour.toString().padLeft(2, '0')}.${DateTime.now().minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 70,
                                fontFamily: "GE Jarida",
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Balance",
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "InstrumentSans",
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: Colors.black,
                                height: 1,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 11),
                              child: Text(
                                formatRupiah(totalBalance),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: "Jura",
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: Colors.black,
                                  height: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildFilterButton("Daily", false),
                              _buildFilterButton("Weekly", false),
                              _buildFilterButton("Annually", true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildChartSection()
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isActive
            ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    _titleController.clear();
    _amountController.clear();
    _categoryController.clear();
    isExpense = true;
    _pickedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (conte, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                "Add Transaction",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => isExpense = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isExpense
                                      ? Colors.red.shade400
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Expense",
                                  style: TextStyle(
                                    color: isExpense
                                        ? Colors.white
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => isExpense = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !isExpense
                                      ? Colors.green.shade500
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Income",
                                  style: TextStyle(
                                    color: !isExpense
                                        ? Colors.white
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Nominal",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Nama Transaksi",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: "Category"),
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Date: ${DateFormat('yyyy-MM-dd').format(_pickedDate)}",
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF386BF6),
                      ),
                      onTap: () async {
                        await _selectDate(context, setDialogState);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF386BF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty &&
                        _amountController.text.isNotEmpty &&
                        _categoryController.text.isNotEmpty) {
                      await DatabaseHelper().insertTransaction(
                        TransactionItem(
                          title: _titleController.text,
                          amount: int.parse(_amountController.text),
                          isExpense: isExpense,
                          date: DateFormat('yyyy-MM-dd').format(_pickedDate),
                          category: _categoryController.text.isEmpty
                              ? "Lainnya"
                              : _categoryController.text,
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                      _loadData();
                      _showSuccessDialog();
                    }
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(60),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 40),
                height: 270,
                width: 270,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Berhasil!",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Transaksi berhasil disimpan!",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF386BF6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "OK!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF386BF6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF386BF6).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.only(right: 16, top: 24, left: 0, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
          ),
      child: LineChart(_mainChartData()),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _chartMaxY / 4,
            getTitlesWidget: _leftTitleWidgets,
            reservedSize: 40,
          ),
        ),
      ),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: _chartMaxY,

      lineBarsData: [
        LineChartBarData(
          spots: _chartSpots,
          isCurved: true,
          color: const Color(0xFF386BF6),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF386BF6).withOpacity(0.3),
                Colors.white.withOpacity(0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('JAN', style: style);
        break;
      case 2:
        text = const Text('MAR', style: style);
        break;
      case 4:
        text = const Text('MAY', style: style);
        break;
      case 6:
        text = const Text('JUL', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(child: text, meta: meta);
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == meta.max || value == meta.min) return Container();
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    if (value >= 1000000) {
      text = '${(value/1000000).toStringAsFixed(1)}M';
    }else if (value >=1000) {
      text = '${(value/1000).toStringAsFixed(0)}k';
    } else {
      text = value.toStringAsFixed(0);
    }
    return Text(
      text,
      style: style,
      textAlign: TextAlign.right,
    );
  }
}
