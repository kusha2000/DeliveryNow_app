import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:fl_chart/fl_chart.dart';

class RiderStatisticsScreen extends StatefulWidget {
  final UserModel rider;

  const RiderStatisticsScreen({super.key, required this.rider});

  @override
  State<RiderStatisticsScreen> createState() => _RiderStatisticsScreenState();
}

class _RiderStatisticsScreenState extends State<RiderStatisticsScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Statistics
  int _totalDeliveries = 0;
  int _completedDeliveries = 0;
  int _pendingDeliveries = 0;
  int _cancelledDeliveries = 0;
  double _completionRate = 0;
  double _averageRating = 0;

  // Weekly data
  List<double> _weeklyDeliveryData = List.filled(7, 0);
  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  // Status distribution
  Map<String, int> _statusDistribution = {
    'pending': 0,
    'in_progress': 0,
    'delivered': 0,
    'cancelled': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadDeliveryData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deliveries = await _firebaseServices.fetchAllDeliveriesForOneRider(
        riderId: widget.rider.uid,
      );

      setState(() {
        _totalDeliveries = deliveries.length;
        _completedDeliveries =
            deliveries.where((d) => d.status == 'delivered').length;
        _pendingDeliveries = deliveries
            .where((d) => d.status == 'pending' || d.status == 'in_progress')
            .length;
        _cancelledDeliveries =
            deliveries.where((d) => d.status == 'cancelled').length;

        _completionRate = _totalDeliveries > 0
            ? (_completedDeliveries / _totalDeliveries) * 100
            : 0;

        final ratings = deliveries
            .where((d) => d.stars != null)
            .map((d) => d.stars!)
            .toList();

        _averageRating = ratings.isNotEmpty
            ? ratings.reduce((a, b) => a + b) / ratings.length
            : 0;

        _processWeeklyData(deliveries);
        _processStatusDistribution(deliveries);
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading statistics: $e');
    }
  }

  void _processWeeklyData(List<DeliveryModel> deliveries) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));

    _weeklyDeliveryData = List.filled(7, 0);

    for (var delivery in deliveries) {
      final deliveryDate = delivery.assignedDate.toDate();
      if (deliveryDate.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        final weekday = deliveryDate.weekday - 1;
        if (weekday >= 0 && weekday < 7) {
          _weeklyDeliveryData[weekday]++;
        }
      }
    }
  }

  void _processStatusDistribution(List<DeliveryModel> deliveries) {
    _statusDistribution = {
      'pending': 0,
      'in_progress': 0,
      'delivered': 0,
      'cancelled': 0,
    };

    for (var delivery in deliveries) {
      if (_statusDistribution.containsKey(delivery.status)) {
        _statusDistribution[delivery.status] =
            (_statusDistribution[delivery.status] ?? 0) + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Statistics...',
                      style: TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatsGrid(),
                          const SizedBox(height: 32),
                          _buildWeeklyChart(),
                          const SizedBox(height: 32),
                          _buildStatusChart(),
                          const SizedBox(height: 32),
                          _buildPerformanceMetrics(),
                          const SizedBox(height: 20),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Total Deliveries',
              _totalDeliveries.toString(),
              Icons.local_shipping_rounded,
              AppColors.primaryColor,
              AppColors.primaryLightColor,
            ),
            _buildStatCard(
              'Completed',
              _completedDeliveries.toString(),
              Icons.check_circle_rounded,
              AppColors.successColor,
              AppColors.emeraldColor,
            ),
            _buildStatCard(
              'Completion Rate',
              '${_completionRate.toStringAsFixed(1)}%',
              Icons.trending_up_rounded,
              AppColors.tealColor,
              AppColors.cyanColor,
            ),
            _buildStatCard(
              'Average Rating',
              _averageRating.toStringAsFixed(1),
              Icons.star_rounded,
              AppColors.primaryColor,
              AppColors.amberColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color startColor, Color endColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor.withOpacity(0.8), endColor.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.whiteColor,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.whiteColor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Weekly Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _weeklyDeliveryData.isNotEmpty
                      ? (_weeklyDeliveryData.reduce((a, b) => a > b ? a : b) +
                          2)
                      : 10,
                  barGroups: List.generate(
                    7,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _weeklyDeliveryData[index],
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryLightColor,
                            ],
                          ),
                          width: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _weekDays[value.toInt()],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.borderColor.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.indigoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: AppColors.indigoColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Status Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value:
                                _statusDistribution['delivered']?.toDouble() ??
                                    0,
                            color: AppColors.successColor,
                            title: '${_statusDistribution['delivered'] ?? 0}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value:
                                _statusDistribution['pending']?.toDouble() ?? 0,
                            color: AppColors.warningColor,
                            title: '${_statusDistribution['pending'] ?? 0}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: _statusDistribution['in_progress']
                                    ?.toDouble() ??
                                0,
                            color: AppColors.infoColor,
                            title: '${_statusDistribution['in_progress'] ?? 0}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value:
                                _statusDistribution['cancelled']?.toDouble() ??
                                    0,
                            color: AppColors.errorColor,
                            title: '${_statusDistribution['cancelled'] ?? 0}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Delivered', AppColors.successColor,
                          _statusDistribution['delivered'] ?? 0),
                      _buildLegendItem('Pending', AppColors.warningColor,
                          _statusDistribution['pending'] ?? 0),
                      _buildLegendItem('In Progress', AppColors.infoColor,
                          _statusDistribution['in_progress'] ?? 0),
                      _buildLegendItem('Cancelled', AppColors.errorColor,
                          _statusDistribution['cancelled'] ?? 0),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.violetColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: AppColors.violetColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Pending Orders',
                    _pendingDeliveries.toString(),
                    Icons.pending_actions_rounded,
                    AppColors.warningColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricItem(
                    'Cancelled Orders',
                    _cancelledDeliveries.toString(),
                    Icons.cancel_rounded,
                    AppColors.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
