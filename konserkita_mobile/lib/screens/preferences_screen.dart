import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../utils/constants.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _catController = TextEditingController();
  final _locController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RecommendationProvider>();
      await provider.fetchPreferences();
      if (provider.preferences != null) {
        final prefs = provider.preferences!;
        if (prefs['preferred_categories'] != null) {
          _catController.text = (prefs['preferred_categories'] as List).join(', ');
        }
        if (prefs['preferred_locations'] != null) {
          _locController.text = (prefs['preferred_locations'] as List).join(', ');
        }
        if (prefs['min_price'] != null) {
          _minPriceController.text = double.parse(prefs['min_price'].toString()).toInt().toString();
        }
        if (prefs['max_price'] != null) {
          _maxPriceController.text = double.parse(prefs['max_price'].toString()).toInt().toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _catController.dispose();
    _locController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final provider = context.read<RecommendationProvider>();
    List<String>? cats = _catController.text.isEmpty ? null : _catController.text.split(',').map((e) => e.trim()).toList();
    List<String>? locs = _locController.text.isEmpty ? null : _locController.text.split(',').map((e) => e.trim()).toList();
    double? minP = double.tryParse(_minPriceController.text);
    double? maxP = double.tryParse(_maxPriceController.text);

    bool success = await provider.updatePreferences(
      preferredCategories: cats,
      preferredLocations: locs,
      minPrice: minP,
      maxPrice: maxP,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save preferences'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preferences'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personalize Your Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tell us what you like so we can show you the best events.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),

                  _buildTextField(_catController, 'Preferred Categories', 'e.g. Pop, Rock, Festival', Icons.music_note),
                  const SizedBox(height: 16),
                  _buildTextField(_locController, 'Preferred Locations', 'e.g. Jakarta, Bandung', Icons.location_on),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_minPriceController, 'Min Price (Rp)', '0', Icons.attach_money, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_maxPriceController, 'Max Price (Rp)', 'Unlimited', Icons.attach_money, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.secondaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save Preferences', style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
