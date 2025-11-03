import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/prashna/execution_log.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';

/// Minimalist, optimized timeline widget for execution logs
class ExecutionTimeline extends StatelessWidget {
  final ExecutionLog executionLog;
  final AppThemeColors? themeColors;

  const ExecutionTimeline({
    super.key,
    required this.executionLog,
    this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final events = executionLog.events;
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Summary header
        _buildSummaryHeader(),
        
        const SizedBox(height: 16),
        
        // Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final previousEvent = index > 0 ? events[index - 1] : null;
              final isLast = index == events.length - 1;
              
              return _buildTimelineItem(
                event: event,
                previousEvent: previousEvent,
                isLast: isLast,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No execution logs available',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Logs will appear here when available',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final summary = executionLog.summary;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (themeColors?.primary ?? Colors.indigo).withOpacity(0.1),
            (themeColors?.primary ?? Colors.indigo).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (themeColors?.primary ?? Colors.indigo).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColors?.primary ?? Colors.indigo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.speed,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execution Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeColors?.onSurface ?? Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Performance metrics and timing',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPerformanceBadge(summary.performanceRating),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.timer,
                  label: 'Total Time',
                  value: '${summary.totalTime.toStringAsFixed(1)}s',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.build,
                  label: 'Tools Used',
                  value: '${summary.toolCalls}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.smart_toy,
                  label: 'Model',
                  value: summary.model.split(':').first,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge(String rating) {
    Color color;
    IconData icon;
    
    switch (rating.toLowerCase()) {
      case 'fast':
        color = Colors.green;
        icon = Icons.flash_on;
        break;
      case 'normal':
        color = Colors.orange;
        icon = Icons.speed;
        break;
      case 'slow':
        color = Colors.red;
        icon = Icons.hourglass_bottom;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            rating,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required ExecutionEvent event,
    required ExecutionEvent? previousEvent,
    required bool isLast,
    required int index,
  }) {
    final color = _getEventColor(event.event);
    final duration = event.getDurationSince(previousEvent);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            // Time circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getEventIcon(event.event),
                size: 16,
                color: color,
              ),
            ),
            
            // Connecting line
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Event content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event header
                Row(
                  children: [
                    Text(
                      event.event.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeColors?.onSurface ?? Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    _buildTimeChip(event.formattedTime),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Event content
                Text(
                  _formatEventContent(event),
                  style: TextStyle(
                    fontSize: 13,
                    color: themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                
                // Duration chip for tool completions
                if (event.toolDuration != null) ...[
                  const SizedBox(height: 6),
                  _buildDurationChip(event.toolDuration!),
                ],
                
                // Time since previous event
                if (duration != null && duration > 0.1) ...[
                  const SizedBox(height: 6),
                  _buildDeltaChip(duration),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (themeColors?.primary ?? Colors.indigo).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: themeColors?.primary ?? Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildDurationChip(double duration) {
    final color = duration < 1.0 ? Colors.green : 
                  duration < 3.0 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '${duration.toStringAsFixed(2)}s',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaChip(double delta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '+${delta.toStringAsFixed(1)}s',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Color _getEventColor(ExecutionEventType eventType) {
    switch (eventType) {
      case ExecutionEventType.runStarted:
        return Colors.blue;
      case ExecutionEventType.toolCallStarted:
        return Colors.orange;
      case ExecutionEventType.toolCallCompleted:
        return Colors.green;
      case ExecutionEventType.runContent:
        return Colors.purple;
      case ExecutionEventType.runCompleted:
        return Colors.indigo;
      case ExecutionEventType.unknown:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(ExecutionEventType eventType) {
    switch (eventType) {
      case ExecutionEventType.runStarted:
        return Icons.play_circle_outline;
      case ExecutionEventType.toolCallStarted:
        return Icons.build_circle_outlined;
      case ExecutionEventType.toolCallCompleted:
        return Icons.check_circle_outline;
      case ExecutionEventType.runContent:
        return Icons.edit_outlined;
      case ExecutionEventType.runCompleted:
        return Icons.done_all;
      case ExecutionEventType.unknown:
        return Icons.help_outline;
    }
  }

  String _formatEventContent(ExecutionEvent event) {
    switch (event.event) {
      case ExecutionEventType.runStarted:
        return 'Query processing initiated';
      case ExecutionEventType.toolCallStarted:
        return 'Started ${event.toolName ?? 'tool'} execution';
      case ExecutionEventType.toolCallCompleted:
        return 'Completed ${event.toolName ?? 'tool'} execution';
      case ExecutionEventType.runContent:
        return 'Response generation started';
      case ExecutionEventType.runCompleted:
        return 'Response completed and ready';
      case ExecutionEventType.unknown:
        return event.content;
    }
  }
}
