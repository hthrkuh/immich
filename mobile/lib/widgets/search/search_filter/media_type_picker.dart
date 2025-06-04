import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openapi/api.dart';

class MediaTypePicker extends HookWidget {
  const MediaTypePicker({super.key, required this.onSelect, this.filter});

  final Function(AssetType) onSelect;
  final AssetType? filter;

  @override
  Widget build(BuildContext context) {
    final selectedMediaType = useState(filter ?? AssetType.OTHER);

    return ListView(
      shrinkWrap: true,
      children: [
        RadioListTile(
          key: const Key("all"),
          title: const Text("all").tr(),
          value: AssetType.OTHER,
          onChanged: (value) {
            selectedMediaType.value = value!;
            onSelect(value);
          },
          groupValue: selectedMediaType.value,
        ),
        RadioListTile(
          key: const Key("image"),
          title: const Text("image").tr(),
          value: AssetType.IMAGE,
          onChanged: (value) {
            selectedMediaType.value = value!;
            onSelect(value);
          },
          groupValue: selectedMediaType.value,
        ),
        RadioListTile(
          key: const Key("video"),
          title: const Text("video").tr(),
          value: AssetType.VIDEO,
          onChanged: (value) {
            selectedMediaType.value = value!;
            onSelect(value);
          },
          groupValue: selectedMediaType.value,
        ),
      ],
    );
  }
}
