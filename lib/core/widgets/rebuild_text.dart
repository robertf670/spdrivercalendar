import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RebuildText extends StatefulWidget {
  final Widget child;
  
  const RebuildText({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _RebuildTextState createState() => _RebuildTextState();
}

class _RebuildTextState extends State<RebuildText> with WidgetsBindingObserver {
  static const platform = MethodChannel('app.channel/text_rendering');
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceRebuild();
    }
  }

  Future<void> _forceRebuild() async {
    try {
      await platform.invokeMethod('forceRebuild');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error forcing rebuild: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 
