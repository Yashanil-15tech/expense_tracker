import 'package:flutter/material.dart';

class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int? pageIndex;
  final Offset? targetPosition;
  final Size? targetSize;
  final TourHighlightShape shape;
  final String? interactionHint;
  final bool allowInteraction; // NEW: Allow clicking through overlay

  TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.blue,
    this.pageIndex,
    this.targetPosition,
    this.targetSize,
    this.shape = TourHighlightShape.rectangle,
    this.interactionHint,
    this.allowInteraction = false, // By default, don't allow interaction
  });
}

enum TourHighlightShape { rectangle, circle }

class FeatureTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final Function(int)? onPageChange;

  const FeatureTourOverlay({
    Key? key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
    this.onPageChange,
  }) : super(key: key);

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    if (widget.steps[_currentStep].pageIndex != null && widget.onPageChange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPageChange!(widget.steps[_currentStep].pageIndex!);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < widget.steps.length - 1) {
      final nextStep = widget.steps[_currentStep + 1];
      final currentStepPage = widget.steps[_currentStep].pageIndex;
      
      if (nextStep.pageIndex != null && 
          nextStep.pageIndex != currentStepPage && 
          widget.onPageChange != null) {
        widget.onPageChange!(nextStep.pageIndex!);
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _completeTour();
    }
  }

  void _previousStep() async {
    if (_currentStep > 0) {
      final prevStep = widget.steps[_currentStep - 1];
      final currentStepPage = widget.steps[_currentStep].pageIndex;
      
      if (prevStep.pageIndex != null && 
          prevStep.pageIndex != currentStepPage && 
          widget.onPageChange != null) {
        widget.onPageChange!(prevStep.pageIndex!);
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _skipTour() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    }
    Navigator.of(context).pop();
  }

  void _completeTour() {
    widget.onComplete();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.steps[_currentStep];
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Overlay with cutout - blocks interaction EXCEPT highlighted area
          IgnorePointer(
            ignoring: currentStep.allowInteraction,
            child: CustomPaint(
              size: size,
              painter: SpotlightPainter(
                targetPosition: currentStep.targetPosition,
                targetSize: currentStep.targetSize,
                shape: currentStep.shape,
              ),
            ),
          ),

          // Static pointer (no pulsing)
          if (currentStep.targetPosition != null && 
              currentStep.targetSize != null && 
              currentStep.interactionHint != null)
            Positioned(
              left: currentStep.targetPosition!.dx + currentStep.targetSize!.width / 2 - 60,
              top: currentStep.targetPosition!.dy - 70,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: currentStep.color,
                      size: 40,
                      shadows: [
                        Shadow(
                          color: currentStep.color.withOpacity(0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: currentStep.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: currentStep.color.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        currentStep.interactionHint!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tour card - does NOT block interaction
          Positioned.fill(
            child: SafeArea(
              child: IgnorePointer(
                ignoring: currentStep.allowInteraction,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _skipTour,
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        label: const Text(
                                          'Skip',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: currentStep.color,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_currentStep + 1}/${widget.steps.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: (_currentStep + 1) / widget.steps.length,
                                      backgroundColor: Colors.white.withOpacity(0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(currentStep.color),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Tour card
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Card(
                                elevation: 12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        currentStep.color.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: currentStep.color.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: currentStep.color.withOpacity(0.15),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            currentStep.icon,
                                            size: 52,
                                            color: currentStep.color,
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Title
                                        Text(
                                          currentStep.title,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[900],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),

                                        // Description
                                        Text(
                                          currentStep.description,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[700],
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 28),

                                        // Navigation buttons
                                        Row(
                                          children: [
                                            if (_currentStep > 0)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _previousStep,
                                                  icon: const Icon(Icons.arrow_back),
                                                  label: const Text('Back'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: currentStep.color,
                                                    side: BorderSide(color: currentStep.color, width: 2),
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (_currentStep > 0) const SizedBox(width: 12),
                                            Expanded(
                                              flex: _currentStep > 0 ? 1 : 2,
                                              child: ElevatedButton(
                                                onPressed: _nextStep,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: currentStep.color,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  elevation: 4,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _currentStep < widget.steps.length - 1
                                                          ? 'Next'
                                                          : 'Finish',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      _currentStep < widget.steps.length - 1
                                                          ? Icons.arrow_forward
                                                          : Icons.check_circle,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Offset? targetPosition;
  final Size? targetSize;
  final TourHighlightShape shape;

  SpotlightPainter({
    this.targetPosition,
    this.targetSize,
    this.shape = TourHighlightShape.rectangle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    if (targetPosition != null && targetSize != null) {
      final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

      final highlightPath = Path();
      if (shape == TourHighlightShape.circle) {
        final center = Offset(
          targetPosition!.dx + targetSize!.width / 2,
          targetPosition!.dy + targetSize!.height / 2,
        );
        final radius = (targetSize!.width > targetSize!.height
                ? targetSize!.width
                : targetSize!.height) /
            2 +
            12;
        highlightPath.addOval(Rect.fromCircle(center: center, radius: radius));
      } else {
        highlightPath.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              targetPosition!.dx - 12,
              targetPosition!.dy - 12,
              targetSize!.width + 24,
              targetSize!.height + 24,
            ),
            const Radius.circular(16),
          ),
        );
      }

      final combinedPath = Path.combine(PathOperation.difference, path, highlightPath);
      canvas.drawPath(combinedPath, paint);

      // Glowing border
      final borderPaint = Paint()
        ..color = Colors.yellowAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(highlightPath, borderPaint);
      
      // Solid border
      final solidBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(highlightPath, solidBorderPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}