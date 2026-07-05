import 'package:flutter/material.dart';
import '../../models/hostel_model.dart';
import 'bed_selection_page.dart';

class RoomSelectionPage extends StatelessWidget {
  final Block block;

  const RoomSelectionPage({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${block.name} - Rooms"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: block.rooms.length,
        itemBuilder: (context, index) {
          final room = block.rooms[index];
          int availableBeds = room.beds.where((b) => b.isAvailable).length;

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.door_front_door, color: Colors.white),
              ),
              title: Text(
                room.roomNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "$availableBeds/${room.beds.length} Beds Available",
                style: TextStyle(
                  color: availableBeds > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BedSelectionPage(room: room),
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
