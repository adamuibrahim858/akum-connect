import 'package:flutter/material.dart';
import '../../models/hostel_model.dart';
import 'room_selection_page.dart';

class HostelPage extends StatelessWidget {
  const HostelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final blocks = HostelService.getAvailableBlocks();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostel Booking"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.apartment, color: Colors.white),
              ),
              title: Text(
                block.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text("${block.rooms.length} Rooms Available"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomSelectionPage(block: block),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
