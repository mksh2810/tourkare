import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tourkare/screens/itinerary.dart';
import 'package:tourkare/services/api_service.dart';
import 'package:tourkare/services/database_service.dart';

class AIGeneratingScreen extends StatefulWidget {
  final int localTripId;
  final String destination;
  final String budgetText;
  final double budget;
  final int numberOfDays;
  final List<String> interests;
  final String foodPreference;

  const AIGeneratingScreen({
    super.key,
    required this.localTripId,
    required this.destination,
    required this.budgetText,
    required this.budget,
    required this.numberOfDays,
    required this.interests,
    required this.foodPreference,
  });

  @override
  State<AIGeneratingScreen> createState() => _AIGeneratingScreenState();
}

class _AIGeneratingScreenState extends State<AIGeneratingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _pulseController;
  Timer? _messageTimer;

  int _messageIndex = 0;
  bool _isGenerating = true;
  String? _errorMessage;

  final List<String> _messages = [
    'Finding places you\'ll love... 🗺️',
    'Balancing your budget... 💸',
    'Planning the perfect day... ✨',
    'Checking travel times... 🚗',
    'Adding some fun to the trip... 🎉',
    'Making sure you don\'t wake up at 6 AM... 😴',
    'Asking Google Maps for emotional support... 🗺️',
    'Packing the virtual bags... 🧳',
    'Almost there... probably. 🤞',
  ];

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.92,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _messageTimer = Timer.periodic(
      const Duration(milliseconds: 2600),
      (_) {
        if (!mounted || !_isGenerating) return;
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      },
    );

    _generateItinerary();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateItinerary() async {
    if (!_isGenerating) {
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
        _messageIndex = 0;
      });
    }

    try {
      final result = await ApiService.createTrip(
        destination: widget.destination,
        days: widget.numberOfDays,
        budget: widget.budget,
        interests: widget.interests,
        selectedFoodPreference: widget.foodPreference,
      );

      await DatabaseService.saveItinerary(
        tripId: widget.localTripId,
        itinerary: result,
      );

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryScreen(
            localTripId: widget.localTripId,
            destination: widget.destination,
            budget: widget.budgetText,
            numberOfDays: widget.numberOfDays,
            interests: widget.interests,
            selectedFoodPreference: widget.foodPreference,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Generate itinerary error: $e');

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _errorMessage =
            'We couldn\'t generate your itinerary right now.\nPlease try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isGenerating,
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                final value = _backgroundController.value * 2 * 3.1415926535;

                return CustomPaint(
                  size: Size.infinite,
                  painter: _GradientFlowPainter(value),
                );
              },
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      _buildLogo(),
                      const SizedBox(height: 34),
                      Text(
                        _isGenerating
                            ? 'AI is planning your trip'
                            : 'Something went wrong',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _isGenerating
                              ? _messages[_messageIndex]
                              : (_errorMessage ?? ''),
                          key: ValueKey(
                            _isGenerating
                                ? _messageIndex
                                : _errorMessage,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_isGenerating)
                        _buildProgressIndicator()
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isGenerating = true;
                              _errorMessage = null;
                              _messageIndex = 0;
                            });
                            _generateItinerary();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (_isGenerating)
                        Text(
                          'Grab a snack. This may take a moment. 🍿',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseController.value,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  blurRadius: 35,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 54,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 230,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Creating your personalized itinerary...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientFlowPainter extends CustomPainter {
  final double animationValue;

  _GradientFlowPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF24103D),
          Color(0xFF4B1D73),
          Color(0xFF1B4965),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    _drawBlob(
      canvas,
      size,
      Offset(
        size.width * (0.18 + 0.12 * math.sin(animationValue)),
        size.height * (0.18 + 0.08 * math.cos(animationValue)),
      ),
      size.width * 0.42,
      const Color(0xFF8E5DE7),
    );

    _drawBlob(
      canvas,
      size,
      Offset(
        size.width * (0.84 + 0.10 * math.cos(animationValue * 0.8)),
        size.height * (0.48 + 0.12 * math.sin(animationValue * 0.8)),
      ),
      size.width * 0.38,
      const Color(0xFF39B7D8),
    );

    _drawBlob(
      canvas,
      size,
      Offset(
        size.width * (0.36 + 0.12 * math.sin(animationValue * 0.65)),
        size.height * (0.90 + 0.06 * math.cos(animationValue)),
      ),
      size.width * 0.48,
      const Color(0xFF6D3FB8),
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.72),
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientFlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
