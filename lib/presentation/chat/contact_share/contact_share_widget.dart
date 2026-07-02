// lib/presentation/chat/contact_share/contact_share_widget.dart
// Widget pour partager un contact (vCard) dans une conversation

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactShareWidget extends StatefulWidget {
  final Function(Map<String, String> contactData) onContactSelected;

  const ContactShareWidget({Key? key, required this.onContactSelected}) : super(key: key);

  @override
  State<ContactShareWidget> createState() => _ContactShareWidgetState();
}

class _ContactShareWidgetState extends State<ContactShareWidget> {
  List<Contact> _contacts = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      _loadContacts();
    } else {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _loadContacts() async {
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    setState(() {
      _contacts = contacts.toList();
      _hasPermission = true;
    });
  }

  Future<void> _shareContact(Contact contact) async {
    final vCard = _generateVCard(contact);
    final tempFile = File('${Directory.systemTemp.path}/contact_${contact.identifier}.vcf');
    await tempFile.writeAsString(vCard);
    await Share.shareXFiles([XFile(tempFile.path)], text: 'Contact : ${contact.displayName}');
    widget.onContactSelected({
      'name': contact.displayName ?? 'Sans nom',
      'phones': contact.phones?.map((p) => p.value).join(', ') ?? '',
      'emails': contact.emails?.map((e) => e.value).join(', ') ?? '',
    });
  }

  String _generateVCard(Contact contact) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:${contact.displayName}');
    for (var phone in contact.phones ?? []) {
      buffer.writeln('TEL;TYPE=${phone.type ?? 'CELL'}:${phone.value}');
    }
    for (var email in contact.emails ?? []) {
      buffer.writeln('EMAIL:${email.value}');
    }
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          AppBar(
            title: const Text('Partager un contact'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (!_hasPermission)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Permission contacts requise'),
                  ElevatedButton(
                    onPressed: _requestPermission,
                    child: const Text('Autoriser'),
                  ),
                ],
              ),
            )
          else if (_contacts.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(contact.displayName ?? 'Sans nom'),
                    subtitle: Text(contact.phones?.isNotEmpty == true
                        ? contact.phones!.first.value!
                        : 'Aucun téléphone'),
                    onTap: () => _shareContact(contact),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
