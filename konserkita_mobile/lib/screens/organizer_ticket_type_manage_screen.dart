import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/organizer_provider.dart';
import '../utils/constants.dart';

class OrganizerTicketTypeManageScreen extends StatefulWidget {
  final int eventId;

  const OrganizerTicketTypeManageScreen({super.key, required this.eventId});

  @override
  State<OrganizerTicketTypeManageScreen> createState() => _OrganizerTicketTypeManageScreenState();
}

class _OrganizerTicketTypeManageScreenState extends State<OrganizerTicketTypeManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchEventDetail(widget.eventId);
    });
  }

  void _showTicketTypeDialog(BuildContext context, {Map<String, dynamic>? ticketType}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: ticketType != null ? ticketType['name'] : '');
    final priceController = TextEditingController(text: ticketType != null ? ticketType['price'].toString() : '');
    final quotaController = TextEditingController(text: ticketType != null ? ticketType['quota'].toString() : '');
    String status = ticketType != null ? ticketType['status'] ?? 'available' : 'available';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final provider = context.watch<OrganizerProvider>();
            return AlertDialog(
              title: Text(ticketType == null ? 'Add Ticket Type' : 'Edit Ticket Type'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name (e.g. VIP)'),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: quotaController,
                        decoration: const InputDecoration(labelText: 'Quota'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Status'),
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 'available', child: Text('Available')),
                          DropdownMenuItem(value: 'sold_out', child: Text('Sold Out')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            status = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final data = {
                              'name': nameController.text,
                              'price': priceController.text,
                              'quota': quotaController.text,
                              'status': status,
                            };
                            bool success;
                            if (ticketType == null) {
                              success = await provider.createTicketType(widget.eventId, data);
                            } else {
                              success = await provider.updateTicketType(widget.eventId, ticketType['id'], data);
                            }

                            if (ctx.mounted) {
                              if (success) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(ticketType == null ? 'Added successfully' : 'Updated successfully')),
                                );
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(provider.error ?? 'Failed')),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
                  child: provider.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int ticketTypeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ticket Type?'),
        content: const Text('Are you sure? This cannot be undone. You cannot delete this if tickets are already sold.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<OrganizerProvider>();
              final success = await provider.deleteTicketType(widget.eventId, ticketTypeId);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(success ? 'Deleted successfully' : (provider.error ?? 'Failed to delete'))),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();
    final event = provider.eventDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Ticket Types'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTicketTypeDialog(context),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading && event == null
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Event not found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: event['ticket_types']?.length ?? 0,
                  itemBuilder: (context, index) {
                    final tt = event['ticket_types'][index];
                    return Card(
                      child: ListTile(
                        title: Text(tt['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Price: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(num.tryParse(tt['price']?.toString() ?? '0') ?? 0)}\nQuota: ${tt['quota']} | Status: ${tt['status']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTicketTypeDialog(context, ticketType: tt),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, tt['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
