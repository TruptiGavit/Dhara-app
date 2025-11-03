import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/prashna/execution_log.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';

/// Minimalist, optimized execution logs tab widget
class ExecutionLogsTab extends StatelessWidget {
  final ExecutionLog? executionLog;
  final AppThemeColors? themeColors;

  const ExecutionLogsTab({
    super.key,
    required this.executionLog,
    this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    if (executionLog == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Only show raw backend data - no confusing calculations
        Expanded(
          child: _buildDetailedTimeline(),
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
            color: themeColors?.isDark == true ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No execution logs available',
            style: TextStyle(
              color: themeColors?.isDark == true ? Colors.grey.shade400 : Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Execution timing will appear here',
            style: TextStyle(
              color: themeColors?.isDark == true ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildDetailedTimeline() {
    final entries = executionLog!.entries;
    final stats = executionLog!.stats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean header with key info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              // Model info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColors?.isDark == true ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  executionLog!.model,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: themeColors?.onSurface ?? Colors.black87,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Total time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  executionLog!.formattedTotalTime,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              // Event count
              Text(
                '${entries.length} events',
                style: TextStyle(
                  fontSize: 10,
                  color: themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Timeline entries
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildTimelineEntry(entry, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineEntry(ExecutionLogEntry entry, int index) {
    return _ExpandableTimelineEntry(
      entry: entry,
      index: index,
      themeColors: themeColors,
      entryColor: _getEntryColor(entry.type),
    );
  }

  Color _getEntryColor(LogEntryType type) {
    switch (type) {
      case LogEntryType.runStart:
        return Colors.blue;
      case LogEntryType.runComplete:
        return Colors.green;
      case LogEntryType.toolStart:
        return Colors.orange;
      case LogEntryType.toolComplete:
        return Colors.green;
      case LogEntryType.response:
        return Colors.purple;
      case LogEntryType.other:
        return Colors.grey;
    }
  }

  IconData _getEntryIcon(LogEntryType type) {
    switch (type) {
      case LogEntryType.runStart:
        return Icons.play_arrow;
      case LogEntryType.runComplete:
        return Icons.check_circle_outline;
      case LogEntryType.toolStart:
        return Icons.build_outlined;
      case LogEntryType.toolComplete:
        return Icons.check;
      case LogEntryType.response:
        return Icons.chat_bubble_outline;
      case LogEntryType.other:
        return Icons.info_outline;
    }
  }

  /// Helper method to get color shades
  Color _getShade(Color color, int shade) {
    switch (shade) {
      case 700:
        return Color.fromRGBO(
          (color.red * 0.7).round(),
          (color.green * 0.7).round(),
          (color.blue * 0.7).round(),
          1.0,
        );
      default:
        return color;
    }
  }
}

/// Expandable timeline entry with show more/less functionality
class _ExpandableTimelineEntry extends StatefulWidget {
  final ExecutionLogEntry entry;
  final int index;
  final AppThemeColors? themeColors;
  final Color entryColor;

  const _ExpandableTimelineEntry({
    required this.entry,
    required this.index,
    required this.themeColors,
    required this.entryColor,
  });

  @override
  State<_ExpandableTimelineEntry> createState() => _ExpandableTimelineEntryState();
}

class _ExpandableTimelineEntryState extends State<_ExpandableTimelineEntry> {
  bool _isExpanded = false;
  static const int _maxLength = 200; // Characters to show before truncation

  bool get _shouldTruncate => widget.entry.content.length > _maxLength;
  
  String get _displayContent {
    if (!_shouldTruncate || _isExpanded) {
      return widget.entry.content;
    }
    return '${widget.entry.content.substring(0, _maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.themeColors?.isDark == true 
            ? Colors.grey.shade800.withOpacity(0.2) 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.entryColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Index, Event Name, Time
          Row(
            children: [
              // Index
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.entryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: widget.entryColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Event name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.entryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.entry.event,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.entryColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              // Content length indicator for long content
              if (_shouldTruncate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.entry.content.length} chars',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.orange,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Timestamp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.themeColors?.isDark == true ? Colors.grey.shade700 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.entry.formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.themeColors?.onSurface ?? Colors.black87,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Content with truncation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.themeColors?.isDark == true 
                  ? Colors.grey.shade700.withOpacity(0.3) 
                  : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.themeColors?.isDark == true ? Colors.grey.shade600 : Colors.grey.shade300,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayContent,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.themeColors?.onSurface ?? Colors.black87,
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                ),
                
                // Show more/less button for long content
                if (_shouldTruncate) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.entryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.entryColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 12,
                            color: widget.entryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExpanded ? 'Show less' : 'Show more',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.entryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
