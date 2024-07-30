import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/services.dart';

class TagsField extends StatefulWidget {
  final List<String>? initialTags;
  final String hintText;
  final Function(List<String>) onUpdate;

  const TagsField({
    super.key,
    this.initialTags,
    required this.hintText,
    required this.onUpdate,
  });

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  static final List<String> _dividers = [' ', ','];

  late final _Debounceable<List<String>?, String> _debouncedSearch;

  final List<String> _currentTags = List.empty(growable: true);

  String? _currentSearchProbe;
  List<String> _lastAutocompleteResult = List.empty();
  TextEditingController? _textEditingController;

  Future<List<String>?> _searchTags(String probe) async {
    _currentSearchProbe = probe;

    final client = ServiceFinder.configureClient('interactive');
    final resp = await client.get(
      '/tags?take=10&probe=$_currentSearchProbe',
    );

    if (_currentSearchProbe != probe) {
      return null;
    }
    _currentSearchProbe = null;

    return resp.body.map((x) => x['alias']).toList().cast<String>();
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<List<String>?, String>(_searchTags);
    if (widget.initialTags != null) {
      _currentTags.addAll(widget.initialTags!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final result = await _debouncedSearch(textEditingValue.text);
        if (result == null) {
          return _lastAutocompleteResult;
        }
        _lastAutocompleteResult = result;
        return result;
      },
      onSelected: (String value) {
        if (value.isEmpty) return;
        if (!_currentTags.contains(value)) {
          setState(() => _currentTags.add(value));
        }
        _textEditingController?.clear();
        widget.onUpdate(_currentTags);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        _textEditingController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            prefixIconConstraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            prefixIcon: _currentTags.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _currentTags.map((String tag) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          margin: const EdgeInsets.only(left: 7.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              InkWell(
                                child: const Icon(
                                  Icons.cancel,
                                  size: 14.0,
                                  color: Color.fromARGB(255, 233, 233, 233),
                                ),
                                onTap: () {
                                  setState(() => _currentTags.remove(tag));
                                  widget.onUpdate(_currentTags);
                                },
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ).paddingOnly(right: 5),
                  )
                : null,
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onChanged: (value) {
            for (final divider in _dividers) {
              if (value.endsWith(divider)) {
                final tagValue = value.substring(0, value.length - 1);
                if (tagValue.isEmpty) return;
                if (!_currentTags.contains(tagValue)) {
                  setState(() => _currentTags.add(tagValue));
                }
                controller.clear();
                widget.onUpdate(_currentTags);
                break;
              }
            }
          },
          onSubmitted: (_) {
            onSubmitted();
          },
        );
      },
    );
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(const Duration(milliseconds: 500), _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

class _CancelException implements Exception {
  const _CancelException();
}
