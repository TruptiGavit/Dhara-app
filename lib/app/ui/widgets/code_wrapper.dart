import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarkdownCodeWrapperWidget extends StatefulWidget {
  final Widget child;
  final String text;
  final String language;

  const MarkdownCodeWrapperWidget(this.child, this.text, this.language, {super.key});

  @override
  State<MarkdownCodeWrapperWidget> createState() => _MarkdownCodeWrapperState();
}

class _MarkdownCodeWrapperState extends State<MarkdownCodeWrapperWidget> {
  // late Widget _switchWidget;
  bool hasCopied = false;

  @override
  void initState() {
    super.initState();
    // _switchWidget = Icon(Icons.copy_rounded, key: UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.language.isNotEmpty)
                  SelectionContainer.disabled(
                      child: Container(
                    margin: EdgeInsets.only(right: 2),
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            width: 0.5,
                            color: isDark ? Colors.white : Colors.black)),
                    child: Text(widget.language),
                  )),
              ],
            ),
          ),
        )
      ],
    );
  }

}