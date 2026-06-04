import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/organizer_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../models/event.dart';

class OrganizerEventFormScreen extends StatefulWidget {
  final Event? event;

  const OrganizerEventFormScreen({super.key, this.event});

  @override
  State<OrganizerEventFormScreen> createState() => _OrganizerEventFormScreenState();
}

class _OrganizerEventFormScreenState extends State<OrganizerEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bannerController = TextEditingController();
  
  int? _selectedCategoryId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizerProvider>().fetchCategories();
    });

    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _bannerController.text = widget.event!.bannerImage ?? '';
      _selectedCategoryId = widget.event!.category?.id;
      _selectedDate = DateTime.parse(widget.event!.date);
      
      final timeParts = widget.event!.time.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      
      _selectedStatus = widget.event!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
      }
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date')));
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a time')));
        return;
      }

      final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final timeStr = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category_id': _selectedCategoryId,
        'location': _locationController.text,
        'date': dateStr,
        'time': timeStr,
        'banner_image': _bannerController.text.isNotEmpty ? _bannerController.text : null,
      };

      final authProvider = context.read<AuthProvider>();
      final role = authProvider.user?.role;
      if ((role == 'admin' || role == 'super_admin') && _selectedStatus != null) {
        data['status'] = _selectedStatus!;
      }

      final provider = context.read<OrganizerProvider>();
      bool success;
      
      if (widget.event == null) {
        success = await provider.createEvent(data);
      } else {
        success = await provider.updateEvent(widget.event!.id, data);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.event == null ? 'Event created successfully' : 'Event updated successfully')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save event')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrganizerProvider>();
    final authProvider = context.read<AuthProvider>();
    final role = authProvider.user?.role;
    final isAdmin = role == 'admin' || role == 'super_admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && provider.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    value: _selectedCategoryId,
                    items: provider.categories.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 4,
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location / Venue', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a location' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
                            child: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bannerController,
                    decoration: const InputDecoration(labelText: 'Banner URL (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  
                  if (isAdmin) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      value: _selectedStatus ?? 'pending',
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'published', child: Text('Published')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedStatus = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: provider.isLoading ? null : _saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Event'),
                  ),
                ],
              ),
            ),
    );
  }
}
