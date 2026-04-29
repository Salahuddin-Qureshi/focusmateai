import 'package:flutter/material.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:focusmate_ai/services/usage_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen>
    with WidgetsBindingObserver {
  List<AppUsageInfo> _usageList = [];
  List<DailyUsageData> _weeklyData = [];
  Map<String, dynamic> _dailyComparison = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  DateTime _selectedDate = DateTime.now();

  final List<DateTime> _recentDates = List.generate(
    7,
    (index) => DateTime.now().subtract(Duration(days: index)),
  ).reversed.toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndLoad();
    }
  }

  Future<void> _checkPermissionAndLoad() async {
    final hasPermission = await UsageService.checkPermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }

    if (hasPermission) {
      await _loadWeeklyData();
      await _loadComparison();
      await _loadStats();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWeeklyData() async {
    final data = await UsageService.getWeeklyTotalUsage();
    if (mounted) {
      setState(() {
        _weeklyData = data;
      });
    }
  }

  Future<void> _loadComparison() async {
    final comp = await UsageService.getDailyComparison();
    if (mounted) {
      setState(() {
        _dailyComparison = comp;
      });
    }
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);
    final stats = await UsageService.getUsageStats(date: _selectedDate);
    if (mounted) {
      setState(() {
        _usageList = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await UsageService.grantPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Wellbeing'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professional Hero Section (Total Time)
              if (_hasPermission && !_isLoading) _buildHeroSection(),
              
              const SizedBox(height: 24),
              
              // Category Distribution
              if (_hasPermission && !_isLoading) _buildCategoryDistribution(),
              
              const SizedBox(height: 32),
              
              const Text(
                'Daily Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(),
              
              const SizedBox(height: 20),
              
              // Weekly Bar Chart
              if (_hasPermission && !_isLoading) ...[
                _buildWeeklyChart(),
                const SizedBox(height: 16),
                _buildDailyScreenTimeList(),
              ],
              
              const SizedBox(height: 32),
              
              const Text(
                'Most Used Apps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 16),
              
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (!_hasPermission)
                _buildPermissionDeniedView()
              else if (_usageList.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _usageList.length,
                  itemBuilder: (context, index) {
                    final item = _usageList[index];
                    return _appUsageCard(item);
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appUsageCard(AppUsageInfo item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => _showAppDetails(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.category.name.toUpperCase(),
                      style: TextStyle(color: AppColors.textDim, fontSize: 10, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.usageTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // Progress mini bar
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (item.minutes / (_dailyComparison['totalMinutes'] ?? 100)).clamp(0, 1).toDouble(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final totalMin = _dailyComparison['totalMinutes'] ?? 0;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final change = _dailyComparison['changePercentage'] ?? '0';
    final isIncrease = _dailyComparison['isIncrease'] ?? false;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Screen Time', style: TextStyle(color: AppColors.textDim)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${h}h ${m}m', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isIncrease ? Colors.redAccent : Colors.greenAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$change% ${isIncrease ? 'increase' : 'decrease'}',
                    style: TextStyle(
                      color: isIncrease ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(' vs yesterday', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentViolet.withAlpha(50), width: 4),
          ),
          child: CircularProgressIndicator(
            value: (totalMin / 480).clamp(0, 1).toDouble(), // 8 hour goal
            strokeWidth: 6,
            backgroundColor: Colors.white10,
            color: AppColors.accentViolet,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution() {
    // Basic calculation for category distribution
    Map<AppCategory, int> dist = {
      AppCategory.social: 0,
      AppCategory.productivity: 0,
      AppCategory.entertainment: 0,
      AppCategory.other: 0,
    };
    
    for (var app in _usageList) {
      dist[app.category] = (dist[app.category] ?? 0) + app.minutes;
    }
    
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: Row(
              children: dist.entries.map((e) {
                final weight = e.value / total;
                if (weight == 0) return const SizedBox();
                return Expanded(
                  flex: (weight * 100).toInt(),
                  child: Container(color: _getCategoryColor(e.key)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dist.entries.where((e) => e.value > 0).take(3).map((e) {
            return Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _getCategoryColor(e.key), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(e.key.name.toUpperCase(), style: TextStyle(color: AppColors.textDim, fontSize: 10)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getCategoryColor(AppCategory cat) {
    switch (cat) {
      case AppCategory.social: return Colors.purpleAccent;
      case AppCategory.productivity: return Colors.blueAccent;
      case AppCategory.entertainment: return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Widget _buildWeeklyChart() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: 24,
      blur: 20,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(5)],
      ),
      borderGradient: LinearGradient(
        colors: [
          AppColors.accentViolet.withAlpha(50),
          Colors.white.withAlpha(10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 12, left: 12, right: 12),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _weeklyData.length) {
                      final day = DateFormat('E').format(_weeklyData[value.toInt()].date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(day[0], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(_weeklyData.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _weeklyData[i].totalMinutes.toDouble(),
                    color: _weeklyData[i].date.day == _selectedDate.day 
                      ? AppColors.accentCyan 
                      : AppColors.accentViolet.withAlpha(150),
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: _weeklyData.map((e) => e.totalMinutes).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                      color: Colors.white10,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyScreenTimeList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._weeklyData.map((data) {
            final dayStr = DateFormat('EEEE, MMM d').format(data.date);
            final h = data.totalMinutes ~/ 60;
            final m = data.totalMinutes % 60;
            final isToday = data.date.day == DateTime.now().day && data.date.month == DateTime.now().month;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday ? 'Today ($dayStr)' : dayStr,
                    style: TextStyle(
                      color: isToday ? AppColors.accentCyan : Colors.white70,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    h > 0 ? '${h}h ${m}m' : '${m}m',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppColors.accentCyan : Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    if (!_hasPermission) return const SizedBox();
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recentDates.length,
        itemBuilder: (context, index) {
          final date = _recentDates[index];
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          final isToday = date.day == DateTime.now().day;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadStats();
            },
            child: Container(
              margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentViolet : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                isToday ? 'Today' : DateFormat('EE').format(date),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 60, color: AppColors.textDim.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No usage data recorded.', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: ElevatedButton(
        onPressed: _requestPermission,
        child: const Text('Grant Usage Permission'),
      ),
    );
  }

  void _showAppDetails(AppUsageInfo app) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AppDetailsSheet(app: app),
    );
  }
}

class _AppDetailsSheet extends StatefulWidget {
  final AppUsageInfo app;
  const _AppDetailsSheet({required this.app});

  @override
  State<_AppDetailsSheet> createState() => _AppDetailsSheetState();
}

class _AppDetailsSheetState extends State<_AppDetailsSheet> {
  List<DailyUsageData> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await UsageService.getAppWeeklyUsage(widget.app.packageName);
    if (mounted) {
      setState(() {
        _history = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 400,
      borderRadius: 32,
      blur: 25,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.background.withAlpha(240),
          AppColors.background.withAlpha(210),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [widget.app.color.withAlpha(100), Colors.white.withAlpha(20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.app.icon, color: widget.app.color, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.app.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.app.usageTime,
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Last 7 Days',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _history.length) {
                                  final day = DateFormat(
                                    'E',
                                  ).format(_history[value.toInt()].date);
                                  return Text(
                                    day[0],
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          _history.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _history[i].totalMinutes.toDouble(),
                                color: widget.app.color,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
