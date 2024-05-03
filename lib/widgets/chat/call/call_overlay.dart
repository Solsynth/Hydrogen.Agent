import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/router.dart';

class CallOverlay extends StatelessWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));

    final chat = context.watch<ChatProvider>();

    if (chat.isCallShown || chat.currentCall == null) {
      return Container();
    }

    return DraggableFloatWidget(
      config: const DraggableFloatWidgetBaseConfig(
        initPositionYInTop: false,
        initPositionYMarginBorder: 50,
        borderTopContainTopBar: true,
        borderBottom: defaultBorderWidth,
        borderLeft: 8,
      ),
      child: Material(
        elevation: 6,
        color: Colors.transparent,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            height: 80,
            width: 80,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.call, size: 18),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.chatCallOngoingShort,
                  style: const TextStyle(fontSize: 12),
                )
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        SolianRouter.router.pushNamed(
          'chat.channel.call',
          extra: chat.currentCall!.info,
          pathParameters: {'channel': chat.currentCall!.channel.alias},
        );
      },
    );
  }
}
