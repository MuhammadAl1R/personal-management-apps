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
  List<FlSpot> _chartSpots = const [FlSpot(0, 0)];
  double _chartMaxY = 100000;
  double _chartMaxX = 6;
  String _selectedFilter = "Annually";
  List<String> _chartXLabels = [];

  Future<void> _selectDate(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _pickedDate) {
      setDialogState(() {
        _pickedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        );
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

    final alldata = await DatabaseHelper().getTransactions();

    alldata.sort((a, b) {
      DateTime dateA = DateTime.parse(a.date);
      DateTime dateB = DateTime.parse(b.date);
      return dateA.compareTo(dateB);
    });

    int Saldo = 0;

    List<Map<String, dynamic>> riwayatSaldo = [];

    for (var item in alldata) {
      if (item.isExpense) {
        Saldo -= item.amount;
      } else {
        Saldo += item.amount;
      }

      riwayatSaldo.add({'item': item, 'saldo_temporary': Saldo});
    }

    List<TransactionItem> ListFilter = [];
    DateTime now = DateTime.now();

    for (var record in riwayatSaldo) {
      TransactionItem item = record['item'];
      DateTime itemDate = DateTime.parse(item.date);
      bool isMatch = false;

      if (_selectedFilter == "Daily") {
        if (itemDate.year == now.year &&
            itemDate.month == now.month &&
            itemDate.day == now.day) {
          isMatch = true;
        }
      } else if (_selectedFilter == "Weekly") {
        DateTime startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
        if (itemDate.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            itemDate.isBefore(endOfWeek)) {
          isMatch = true;
        }
      } else {
        if (itemDate.year == now.year) {
          isMatch = true;
        }
      }

      if (isMatch) {
        ListFilter.add(item);
      }
    }

    setState(() {
      _transactions = ListFilter.reversed.toList();
      totalBalance = Saldo;
      _chartXLabels.clear();
      _generateChartData(riwayatSaldo);
      isLoading = false;
    });
  }

  void _generateChartData(List<Map<String, dynamic>> riwayatSeluruhnya) {
    List<FlSpot> spots = [];
    double maxY = 0;
    DateTime now = DateTime.now();

    if (_selectedFilter == "Annually") {
      _chartMaxX = 11;
      for (int i = 1; i <= 12; i++) {
        DateTime nextMonth = (i == 12)
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, i + 1, 1);
        int saldoPoin = 0;
        var past = riwayatSeluruhnya.where((r) {
          return DateTime.parse(r['item'].date).isBefore(nextMonth);
        });
        if (past.isNotEmpty) saldoPoin = past.last['saldo_temporary'];

        double y = saldoPoin.toDouble();
        if (y > maxY) maxY = y;
        spots.add(FlSpot((i - 1).toDouble(), y));
        _chartXLabels.add(DateFormat('MMM').format(DateTime(now.year, i)));
      }
    } else if (_selectedFilter == "Weekly") {
      _chartMaxX = 6;
      DateTime startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        DateTime myDay = startOfWeek.add(Duration(days: i));
        DateTime nextDay = myDay.add(const Duration(days: 1));

        int saldoPoin = 0;
        var past = riwayatSeluruhnya.where((r) {
          return DateTime.parse(r['item'].date).isBefore(nextDay);
        });
        if (past.isNotEmpty) saldoPoin = past.last['saldo_temporary'];

        double y = saldoPoin.toDouble();
        if (y > maxY) maxY = y;
        spots.add(FlSpot(i.toDouble(), y));
        _chartXLabels.add(DateFormat('EEE').format(myDay));
      }
    } else if (_selectedFilter == "Daily") {
      _chartMaxX = 6;
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      for (int i = 0; i <= 6; i++) {
        DateTime limitTime = startOfDay.add(Duration(hours: i * 4));

        int saldoPoin = 0;
        var past = riwayatSeluruhnya.where((r) {
          return DateTime.parse(
            r['item'].date,
          ).isBefore(limitTime.add(const Duration(seconds: 1)));
        });
        if (past.isNotEmpty) saldoPoin = past.last['saldo_temporary'];

        double y = saldoPoin.toDouble();
        if (y > maxY) maxY = y;
        spots.add(FlSpot(i.toDouble(), y));

        if (i == 6) {
          _chartXLabels.add("24:00");
        } else {
          _chartXLabels.add(DateFormat('HH:mm').format(limitTime));
        }
      }
    }

    _chartSpots = spots;
    _chartMaxY = maxY == 0
        ? 100000
        : maxY + (maxY * 0.2); // Add some visual headroom
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
                              _buildFilterButton("Daily"),
                              _buildFilterButton("Weekly"),
                              _buildFilterButton("Annually"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildChartSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    bool isActive = _selectedFilter == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
        _loadData();
      },
      child: Container(
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
                          date: DateFormat(
                            'yyyy-MM-dd HH:mm:ss',
                          ).format(_pickedDate),
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
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.only(right: 20, top: 30, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LineChart(_mainChartData()),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _chartMaxY / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => const Color(0xFF1E293B),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              return LineTooltipItem(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(flSpot.y),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
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
            interval: _chartMaxY / 4 == 0 ? 1 : _chartMaxY / 4,
            getTitlesWidget: _leftTitleWidgets,
            reservedSize: 45,
          ),
        ),
      ),
      minX: 0,
      maxX: _chartMaxX,
      minY: 0,
      maxY: _chartMaxY,

      lineBarsData: [
        LineChartBarData(
          spots: _chartSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xFF386BF6),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF386BF6),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF386BF6).withOpacity(0.25),
                const Color(0xFF386BF6).withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
    int index = value.toInt();
    String text = "";

    if (index >= 0 && index < _chartXLabels.length) {
      text = _chartXLabels[index];
    }

    return SideTitleWidget(
      child: Text(text, style: style),
      meta: meta,
    );
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
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      text = value.toStringAsFixed(0);
    }
    return Text(text, style: style, textAlign: TextAlign.right);
  }
}
