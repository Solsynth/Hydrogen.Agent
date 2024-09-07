import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/controllers/post_editor_controller.dart';

class PostEditorDateDialog extends StatefulWidget {
  final PostEditorController controller;

  const PostEditorDateDialog({super.key, required this.controller});

  @override
  State<PostEditorDateDialog> createState() => _PostEditorDateDialogState();
}

class _PostEditorDateDialogState extends State<PostEditorDateDialog> {
  final TextEditingController _publishedAtController = TextEditingController();
  final TextEditingController _publishedUntilController =
      TextEditingController();

  final _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  void _selectDate(int mode) async {
    final initial = mode == 0
        ? widget.controller.publishedAt.value
        : widget.controller.publishedUntil.value;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial?.toLocal(),
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 5),
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
    if (mode == 0) {
      setState(() {
        widget.controller.publishedAt.value = picked;
        _publishedAtController.text = _dateFormatter.format(picked);
      });
    } else {
      widget.controller.publishedUntil.value = pickedDate;
      _publishedUntilController.text = _dateFormatter.format(picked);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller.publishedAt.value != null) {
      _publishedAtController.text =
          _dateFormatter.format(widget.controller.publishedAt.value!);
    }
    if (widget.controller.publishedUntil.value != null) {
      _publishedUntilController.text =
          _dateFormatter.format(widget.controller.publishedUntil.value!);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _publishedAtController.dispose();
    _publishedUntilController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('postPublishDate'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _publishedAtController,
            readOnly: true,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              labelText: 'postPublishAt'.tr,
            ),
            onTap: () => _selectDate(0),
          ),
          const Gap(16),
          TextField(
            controller: _publishedUntilController,
            readOnly: true,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              labelText: 'postPublishedUntil'.tr,
            ),
            onTap: () => _selectDate(1),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.controller.publishedAt.value = null;
            widget.controller.publishedUntil.value = null;
            _publishedAtController.clear();
            _publishedUntilController.clear();
          },
          child: Text('clear'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
