import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solian/models/account.dart';
import 'package:solian/widgets/account/avatar.dart';
import 'dart:math' as math;

class NoContentWidget extends StatefulWidget {
  final Account? userinfo;
  final bool isSpeaking;

  const NoContentWidget({super.key, this.userinfo, required this.isSpeaking});

  @override
  State<NoContentWidget> createState() => _NoContentWidgetState();
}

class _NoContentWidgetState extends State<NoContentWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(NoContentWidget old) {
    super.didUpdateWidget(old);
    if (widget.isSpeaking) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.animateTo(0, duration: 300.ms).then((_) => _animationController.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = math.min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) * 0.1;

    return Container(
      alignment: Alignment.center,
      child: Center(
        child: Animate(
            autoPlay: false,
            controller: _animationController,
            effects: [
              CustomEffect(
                begin: widget.isSpeaking ? 2 : 0,
                end: 8,
                curve: Curves.easeInOut,
                duration: 1250.ms,
                builder: (context, value, child) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(radius + 8)),
                    border: value > 0 ? Border.all(color: Colors.green, width: value) : null,
                  ),
                  child: child,
                ),
              )
            ],
            child: AccountAvatar(
              source: widget.userinfo!.avatar,
              backgroundColor: Colors.transparent,
              radius: radius,
              direct: true,
            )),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
