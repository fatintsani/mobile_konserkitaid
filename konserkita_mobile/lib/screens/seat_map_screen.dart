import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/seat_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/event_provider.dart';
import '../utils/constants.dart';

class SeatMapScreen extends StatefulWidget {
  final int eventId;

  const SeatMapScreen({super.key, required this.eventId});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SeatProvider>().fetchSeatMap(widget.eventId);
    });
  }

  Widget _buildSeat(Map<String, dynamic> seat) {
    final seatProvider = context.watch<SeatProvider>();
    final isSelected = seatProvider.selectedSeatIds.contains(seat['id']);
    final status = seat['status'];

    Color seatColor = Colors.grey[300]!; // available
    if (status == 'sold') seatColor = Colors.red;
    if (status == 'held') seatColor = Colors.orange;
    if (isSelected || status == 'selected') seatColor = AppConstants.primaryColor;

    return GestureDetector(
      onTap: () {
        if (status == 'available' || status == 'selected') {
          context.read<SeatProvider>().toggleSeatSelection(seat['id'], status);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seat is not available')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          )
        ),
        child: Center(
          child: Text(
            '${seat['seat_number']}',
            style: TextStyle(
              fontSize: 12,
              color: (status == 'available' && !isSelected) ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kursi'),
      ),
      body: Consumer<SeatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.seatMapData == null) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor));
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          final data = provider.seatMapData;
          if (data == null) {
            return const Center(child: Text('No seat map data.'));
          }

          final sections = data['sections'] as List;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.grey[300]!, 'Available'),
                    _buildLegendItem(AppConstants.primaryColor, 'Selected'),
                    _buildLegendItem(Colors.red, 'Sold'),
                    _buildLegendItem(Colors.orange, 'Held'),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Stage Area
                        Container(
                          width: 300,
                          height: 60,
                          margin: const EdgeInsets.only(top: 20, bottom: 40),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: const Center(
                            child: Text('STAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                          ),
                        ),
                        // Sections
                        ...sections.map((section) {
                          final seatsByRow = section['seats'] as Map<String, dynamic>;
                          final rowLabels = seatsByRow.keys.toList()..sort();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              children: [
                                Text(section['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                ...rowLabels.map((rowLabel) {
                                  final seats = seatsByRow[rowLabel] as List;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 30, child: Text(rowLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      ...seats.map((seat) => _buildSeat(seat)),
                                      SizedBox(width: 30, child: Text(rowLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${provider.selectedSeatIds.length} Kursi Terpilih', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ElevatedButton(
                      onPressed: provider.selectedSeatIds.isEmpty || provider.isLoading ? null : () async {
                        final success = await provider.holdSeats(widget.eventId);
                        if (success) {
                          if (mounted) {
                            final checkoutProvider = context.read<CheckoutProvider>();
                            checkoutProvider.clearCart();
                            // Wait, if we select seats here, we need to know what TicketType it maps to!
                            // Or the user can go to TicketSelectionScreen, select tickets, then select seats?
                            // This depends on the flow. 
                            context.push('/event/${widget.eventId}/tickets');
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(provider.error ?? 'Gagal memesan kursi')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                      child: provider.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Lanjut', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
