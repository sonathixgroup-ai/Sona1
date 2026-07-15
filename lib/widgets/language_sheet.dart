import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  final langs = const [
  {'code':'fr', 'name':'Français', 'flag':'🇫🇷'},
  {'code':'en', 'name':'English', 'flag':'🇬🇧'},
  {'code':'ar', 'name':'العربية', 'flag':'🇸🇦'},
  {'code':'zh', 'name':'中文', 'flag':'🇨🇳'},
  {'code':'pt', 'name':'Português', 'flag':'🇵🇹'}, // <-- AJOUTE CETTE LIGNE
  {'code':'ln', 'name':'Lingala', 'flag':'🇨🇩'},
  {'code':'kg', 'name':'Kikongo', 'flag':'🇨🇩'},
  {'code':'sw', 'name':'Kiswahili', 'flag':'🇹🇿'},
];
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: Text("common.choose_lang".tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        const SizedBox(height: 12),
       ...langs.map((l) {
          final isActive = context.locale.languageCode == l['code'];
          return ListTile(
            leading: Text(l['flag'] as String, style: const TextStyle(fontSize: 24)),
            title: Text(l['name'] as String, style: TextStyle(fontWeight: isActive? FontWeight.bold : FontWeight.w500)),
            trailing: isActive? const Icon(Icons.check_circle, color: Color(0xFFF7B500)) : null,
            onTap: () async {
              await context.setLocale(Locale(l['code'] as String));
              if(context.mounted) Navigator.pop(context);
            },
          );
        })
      ]),
    );
  }
}
