import 'package:flutter/material.dart';
import 'bug_report_service.dart';

class BetaFloatingButton extends StatefulWidget {
  const BetaFloatingButton({
    Key? key,
  }) : super(key: key);

  @override
  State<BetaFloatingButton> createState() => _BetaFloatingButtonState();
}

class _BetaFloatingButtonState extends State<BetaFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the pulsing animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15 * _pulseAnimation.value,
                    spreadRadius: 5 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _showBugReport(context),
                backgroundColor: Colors.red.shade600,
                elevation: 8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.attach_email_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 28,
                    ),
                    // Small beta indicator
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBugReport(BuildContext context) {
    // Stop the pulsing animation temporarily
    _animationController.stop();
    
    BugReportService.instance.showBugReportOptions(context).then((_) {
      // Resume animation after dialog closes
      if (mounted) {
        _animationController.repeat(reverse: true);
      }
    });
  }
}

class BetaCompactButton extends StatelessWidget {
  const BetaCompactButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          onTap: () => BugReportService.instance.showBugReportOptions(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attach_email_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Report Bug',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
