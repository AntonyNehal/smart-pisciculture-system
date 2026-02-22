import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class WaterQualityPage extends StatefulWidget {
  const WaterQualityPage({super.key});

  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  Timer? _updateTimer;

  // Simulated sensor values
  double temperature = 26.5;
  double ph = 7.2;
  double dissolvedOxygen = 6.8;
  double ammonia = 0.15;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animationController.forward();
    _startSimulation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    // Simulate sensor readings changing every 3 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          temperature = 25.0 + random.nextDouble() * 3;
          ph = 6.8 + random.nextDouble() * 0.8;
          dissolvedOxygen = 6.0 + random.nextDouble() * 2;
          ammonia = 0.05 + random.nextDouble() * 0.3;
        });
      }
    });
  }

  String _getStatus(String parameter, double value) {
    switch (parameter) {
      case 'temperature':
        if (value >= 24 && value <= 28) return 'Optimal';
        if (value >= 22 && value <= 30) return 'Good';
        return 'Warning';
      case 'ph':
        if (value >= 7.0 && value <= 7.5) return 'Optimal';
        if (value >= 6.5 && value <= 8.0) return 'Good';
        return 'Warning';
      case 'oxygen':
        if (value >= 6.5) return 'Optimal';
        if (value >= 5.0) return 'Good';
        return 'Warning';
      case 'ammonia':
        if (value <= 0.2) return 'Optimal';
        if (value <= 0.5) return 'Good';
        return 'Warning';
      default:
        return 'Good';
    }
  }

  // Changed the return type to MaterialColor so we can use shade indexing like [700].
  MaterialColor _getStatusColor(String status) {
    switch (status) {
      case 'Optimal':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Warning':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  List<Color> _getGradientColors(MaterialColor color) {
    return [color[300]!, color[600]!];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[400]!,
              Colors.cyan[600]!,
              Colors.teal[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 20),
                      _buildMainMetricsGrid(),
                      const SizedBox(height: 20),
                      _buildDetailedReadings(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            'Water Quality Monitor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2 + _pulseController.value * 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sensors,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _pulseController.value * 0.05,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'All Systems Normal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().substring(11, 19)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMetricsGrid() {
    final metrics = [
      {
        'icon': Icons.thermostat,
        'label': 'Temperature',
        'value': temperature.toStringAsFixed(1),
        'unit': '°C',
        'parameter': 'temperature',
        'color': Colors.orange,
      },
      {
        'icon': Icons.science,
        'label': 'pH Level',
        'value': ph.toStringAsFixed(1),
        'unit': '',
        'parameter': 'ph',
        'color': Colors.deepPurple,
      },
      {
        'icon': Icons.air,
        'label': 'Dissolved O₂',
        'value': dissolvedOxygen.toStringAsFixed(1),
        'unit': 'mg/L',
        'parameter': 'oxygen',
        'color': Colors.lightBlue,
      },
      {
        'icon': Icons.bubble_chart,
        'label': 'Ammonia',
        'value': ammonia.toStringAsFixed(2),
        'unit': 'mg/L',
        'parameter': 'ammonia',
        'color': Colors.amber,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        final delay = 0.2 + (index * 0.1);
        return _buildMetricCard(
          icon: metric['icon'] as IconData,
          label: metric['label'] as String,
          value: metric['value'] as String,
          unit: metric['unit'] as String,
          parameter: metric['parameter'] as String,
          color: metric['color'] as MaterialColor,
          delay: delay,
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String parameter,
    required MaterialColor color,
    required double delay,
  }) {
    final status = _getStatus(parameter, double.parse(value));
    final statusColor = _getStatusColor(status);

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color[300]!.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getGradientColors(color),
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor[700],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: color[700],
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedReadings() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Parameter Ranges',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRangeIndicator(
              'Temperature',
              temperature,
              24.0,
              28.0,
              '°C',
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildRangeIndicator(
              'pH Level',
              ph,
              7.0,
              7.5,
              '',
              Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            _buildRangeIndicator(
              'Dissolved Oxygen',
              dissolvedOxygen,
              6.5,
              8.0,
              'mg/L',
              Colors.lightBlue,
            ),
            const SizedBox(height: 16),
            _buildRangeIndicator(
              'Ammonia',
              ammonia,
              0.0,
              0.2,
              'mg/L',
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeIndicator(
    String label,
    double value,
    double optimalMin,
    double optimalMax,
    String unit,
    MaterialColor color,
  ) {
    final isOptimal = value >= optimalMin && value <= optimalMax;
    final max = optimalMax * 1.5;
    final percentage = (value / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${value.toStringAsFixed(label == 'Ammonia' ? 2 : 1)} $unit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOptimal
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Optimal: $optimalMin - $optimalMax $unit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
