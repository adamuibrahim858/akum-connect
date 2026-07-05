import 'package:flutter/material.dart';
import '../../models/hostel_model.dart';

class BedSelectionPage extends StatefulWidget {
  final Room room;

  const BedSelectionPage({super.key, required this.room});

  @override
  State<BedSelectionPage> createState() => _BedSelectionPageState();
}

class _BedSelectionPageState extends State<BedSelectionPage> {
  late List<Bed> beds;

  @override
  void initState() {
    super.initState();
    beds = widget.room.beds;
  }

  void _reserveBed(Bed bed) {
    if (!bed.isAvailable) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Reservation"),
          content: Text("Are you sure you want to reserve ${bed.bedNumber}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Mock updating the state
                setState(() {
                  final index = beds.indexWhere((b) => b.id == bed.id);
                  if (index != -1) {
                    beds[index] = Bed(
                      id: bed.id,
                      bedNumber: bed.bedNumber,
                      isAvailable: false,
                      facilities: bed.facilities,
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${bed.bedNumber} successfully reserved!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _showBedDetails(Bed bed) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bed.bedNumber,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    bed.isAvailable ? Icons.check_circle : Icons.cancel,
                    color: bed.isAvailable ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bed.isAvailable ? "Available" : "Occupied",
                    style: TextStyle(
                      fontSize: 16,
                      color: bed.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text(
                "Facilities included:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bed.facilities.map((f) => Chip(label: Text(f))).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: bed.isAvailable ? () {
                    Navigator.pop(context);
                    _reserveBed(bed);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text(
                    "Reserve Bed",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.room.roomNumber} - Beds"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: beds.length,
        itemBuilder: (context, index) {
          final bed = beds[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            color: bed.isAvailable ? Colors.white : Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: bed.isAvailable ? Colors.green.withValues(alpha:0.5) : Colors.grey.shade300,
                width: 1,
              ),
            ),
            elevation: bed.isAvailable ? 2 : 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: bed.isAvailable ? Colors.green : Colors.grey,
                child: const Icon(Icons.single_bed, color: Colors.white),
              ),
              title: Text(
                bed.bedNumber,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bed.isAvailable ? Colors.black87 : Colors.grey,
                ),
              ),
              subtitle: Text(
                bed.isAvailable ? "Available" : "Occupied",
                style: TextStyle(
                  color: bed.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: bed.isAvailable ? const Icon(Icons.check_circle_outline, color: Colors.green) : const Icon(Icons.block, color: Colors.red),
              onTap: () {
                _showBedDetails(bed);
              },
            ),
          );
        },
      ),
    );
  }
}
