import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPickerDialog extends StatefulWidget {
  final Iterable<Contact> contacts;
  final void Function(Map<String, dynamic>)? onContactSelect;

  const ContactPickerDialog({
    super.key,
    required this.contacts,
    this.onContactSelect,
  });

  @override
  State<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  late TextEditingController _searchController;
  late List<Contact> _filteredContacts;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredContacts = List.from(widget.contacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  LinearGradient _getRandomGradient() {
    final colors = [
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
    ];
    colors.shuffle();
    return LinearGradient(
      colors: [colors[0], colors[1]],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  void _search(String query) {
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phone = contact.phones.firstOrNull?.number.toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) || phone.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      titlePadding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Contact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _filteredContacts.isEmpty
            ? const Center(child: Text('No contacts found'))
            : ListView.separated(
                itemCount: _filteredContacts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];

                  final displayName = contact.displayName.isNotEmpty ? contact.displayName : 'Unnamed Contact';

                  final phone = contact.phones.firstOrNull?.number ?? 'No number';

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getRandomGradient(),
                        ),
                        child: Center(
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(phone),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.pop(context);

                      if (widget.onContactSelect != null) {
                        final contactJson = {
                          'displayName': contact.displayName,
                          'givenName': contact.name.first,
                          'phones': contact.phones
                              .map((p) => {
                                    'label': p.label,
                                    'number': p.number,
                                  })
                              .toList(),
                          'postalAddresses': contact.addresses
                              .map((a) => {
                                    'label': a.label,
                                    'street': a.street,
                                    'city': a.city,
                                    'postcode': a.postalCode,
                                    'state': a.state,
                                    'country': a.country,
                                  })
                              .toList(),
                          'avatar': contact.photo != null ? base64Encode(contact.photo!) : null,
                        };

                        widget.onContactSelect!(contactJson);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
