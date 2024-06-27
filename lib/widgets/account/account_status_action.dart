import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/providers/account_status.dart';

class AccountStatusAction extends StatefulWidget {
  final Status? currentStatus;

  const AccountStatusAction({super.key, this.currentStatus});

  @override
  State<AccountStatusAction> createState() => _AccountStatusActionState();
}

class _AccountStatusActionState extends State<AccountStatusAction> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final StatusProvider provider = Get.find();

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'accountChangeStatus'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          if (_isBusy)
            const LinearProgressIndicator()
                .paddingOnly(bottom: 14)
                .animate()
                .slideY(curve: Curves.fastEaseInToSlowEaseOut),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: StatusProvider.presetStatuses.entries
                  .map(
                    (x) => ActionChip(
                      avatar: x.value.$1,
                      label: Text(x.value.$2),
                      tooltip: x.value.$3,
                      onPressed: _isBusy
                          ? null
                          : () async {
                              setState(() => _isBusy = true);
                              try {
                                await provider.setStatus(
                                  x.key,
                                  x.value.$2,
                                  0,
                                  isInvisible: x.key == 'invisible',
                                  isSilent: x.key == 'silent',
                                );
                                Navigator.of(context).pop(true);
                              } catch (e) {
                                context.showErrorDialog(e);
                              }
                              setState(() => _isBusy = false);
                            },
                    ).paddingOnly(right: 6),
                  )
                  .toList(),
            ).paddingSymmetric(horizontal: 18),
          ),
          const Divider(thickness: 0.3, height: 0.3)
              .paddingSymmetric(vertical: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: widget.currentStatus != null
                ? const Icon(Icons.edit)
                : const Icon(Icons.add),
            title: Text('accountCustomStatus'.tr),
            onTap: _isBusy
                ? null
                : () async {
                    final val = await showDialog(
                      context: context,
                      builder: (context) => AccountStatusEditorDialog(
                        currentStatus: widget.currentStatus,
                      ),
                    );
                    if (val == true) {
                      Navigator.of(context).pop(true);
                    }
                  },
          ),
          if (widget.currentStatus != null)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.clear),
              title: Text('accountClearStatus'.tr),
              onTap: _isBusy
                  ? null
                  : () async {
                      setState(() => _isBusy = true);
                      try {
                        await provider.clearStatus();
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        context.showErrorDialog(e);
                      }
                      setState(() => _isBusy = false);
                    },
            ),
        ],
      ),
    );
  }
}

class AccountStatusEditorDialog extends StatefulWidget {
  final Status? currentStatus;

  const AccountStatusEditorDialog({super.key, this.currentStatus});

  @override
  State<AccountStatusEditorDialog> createState() =>
      _AccountStatusEditorDialogState();
}

class _AccountStatusEditorDialogState extends State<AccountStatusEditorDialog> {
  bool _isBusy = false;

  int _attitude = 0;
  DateTime? _clearAt;
  bool _isInvisible = false;
  bool _isSilent = false;

  final _labelController = TextEditingController();
  final _clearAtController = TextEditingController();

  void selectClearAt() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _clearAt?.toLocal() ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final picked = pickedDate.copyWith(
      hour: pickedTime.hour,
      minute: pickedTime.minute,
    );
    setState(() {
      _clearAt = picked;
      _clearAtController.text = DateFormat('y/M/d HH:mm').format(_clearAt!);
    });
  }

  Future<void> applyStatus() async {
    final StatusProvider provider = Get.find();

    setState(() => _isBusy = true);
    try {
      await provider.setStatus(
        'custom',
        _labelController.value.text,
        _attitude,
        clearAt: _clearAt,
        isSilent: _isSilent,
        isInvisible: _isInvisible,
        isUpdate: widget.currentStatus != null,
      );
      Navigator.pop(context, true);
    } catch (e) {
      context.showErrorDialog(e);
    }
    setState(() => _isBusy = false);
  }

  void syncWidget() {
    if (widget.currentStatus != null) {
      _clearAt = widget.currentStatus!.clearAt;
      if (_clearAt != null) {
        _clearAtController.text = DateFormat('y/M/d HH:mm').format(_clearAt!);
      }

      _labelController.text = widget.currentStatus!.label;
      _attitude = widget.currentStatus!.attitude;
      _isInvisible = widget.currentStatus!.isInvisible;
      _isSilent = widget.currentStatus!.isNoDisturb;
    }
  }

  @override
  void initState() {
    syncWidget();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('accountCustomStatus'.tr),
      content: Container(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isBusy)
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: const LinearProgressIndicator().animate().scaleX(),
              ),
            const SizedBox(height: 18),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.label),
                border: const OutlineInputBorder(),
                labelText: 'accountStatusLabel'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _clearAtController,
              readOnly: true,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.event_busy),
                border: const OutlineInputBorder(),
                labelText: 'accountStatusClearAt'.tr,
              ),
              onTap: () => selectClearAt(),
            ),
            const SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                runSpacing: 0,
                children: [
                  ChoiceChip(
                    avatar: Icon(
                      Icons.radio_button_unchecked,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selected: _attitude == 2,
                    label: Text('accountStatusNegative'.tr),
                    onSelected: (val) {
                      if (val) setState(() => _attitude = 2);
                    },
                  ),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.contrast,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selected: _attitude == 0,
                    label: Text('accountStatusNeutral'.tr),
                    onSelected: (val) {
                      if (val) setState(() => _attitude = 0);
                    },
                  ),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.circle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selected: _attitude == 1,
                    label: Text('accountStatusPositive'.tr),
                    onSelected: (val) {
                      if (val) setState(() => _attitude = 1);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                runSpacing: 0,
                children: [
                  ChoiceChip(
                    selected: _isSilent,
                    label: Text('accountStatusSilent'.tr),
                    onSelected: (val) {
                      setState(() => _isSilent = val);
                    },
                  ),
                  ChoiceChip(
                    selected: _isInvisible,
                    label: Text('accountStatusInvisible'.tr),
                    onSelected: (val) {
                      setState(() => _isInvisible = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: _isBusy ? null : () => applyStatus(),
          child: Text('apply'.tr),
        ),
      ],
    );
  }
}
