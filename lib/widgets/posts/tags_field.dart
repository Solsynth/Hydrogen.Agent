import 'package:flutter/material.dart';
import 'package:textfield_tags/textfield_tags.dart';

class TagsField extends StatelessWidget {
  final List<String>? initialTags;
  final String hintText;

  const TagsField({
    super.key,
    this.initialTags,
    required this.hintText,
    required StringTagController<String> tagsController,
  }) : _tagsController = tagsController;

  final StringTagController<String> _tagsController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: TextFieldTags<String>(
        initialTags: initialTags,
        letterCase: LetterCase.small,
        textfieldTagsController: _tagsController,
        textSeparators: const [' ', ','],
        inputFieldBuilder: (context, inputFieldValues) {
          return TextField(
            controller: inputFieldValues.textEditingController,
            focusNode: inputFieldValues.focusNode,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              border: InputBorder.none,
              prefixIconConstraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              prefixIcon: inputFieldValues.tags.isNotEmpty
                  ? SingleChildScrollView(
                      controller: inputFieldValues.tagScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: inputFieldValues.tags.map((String tag) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            margin: const EdgeInsets.only(right: 10.0),
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
                                  onTap: () {
                                    //print("$tag selected");
                                  },
                                ),
                                const SizedBox(width: 4.0),
                                InkWell(
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 14.0,
                                    color: Color.fromARGB(255, 233, 233, 233),
                                  ),
                                  onTap: () {
                                    inputFieldValues.onTagRemoved(tag);
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : null,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: inputFieldValues.onTagChanged,
            onSubmitted: inputFieldValues.onTagSubmitted,
          );
        },
      ),
    );
  }
}
