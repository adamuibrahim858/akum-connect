class Bed {
  final String id;
  final String bedNumber;
  final bool isAvailable;
  final List<String> facilities;

  Bed({
    required this.id,
    required this.bedNumber,
    required this.isAvailable,
    required this.facilities,
  });
}

class Room {
  final String id;
  final String roomNumber;
  final List<Bed> beds;

  Room({
    required this.id,
    required this.roomNumber,
    required this.beds,
  });
}

class Block {
  final String id;
  final String name;
  final List<Room> rooms;

  Block({
    required this.id,
    required this.name,
    required this.rooms,
  });
}

// Mock Data Service
class HostelService {
  static List<Block> getAvailableBlocks() {
    return [
      Block(
        id: '1',
        name: 'Block A',
        rooms: [
          Room(
            id: '101',
            roomNumber: 'Room 101',
            beds: [
              Bed(
                id: 'A1',
                bedNumber: 'Bed A1',
                isAvailable: true,
                facilities: ['Fan', 'Reading Table', 'Wardrobe', 'Electricity', 'Water'],
              ),
              Bed(
                id: 'A2',
                bedNumber: 'Bed A2',
                isAvailable: false,
                facilities: ['Fan', 'Reading Table', 'Wardrobe', 'Electricity', 'Water'],
              ),
            ],
          ),
          Room(
            id: '102',
            roomNumber: 'Room 102',
            beds: [
              Bed(
                id: 'B1',
                bedNumber: 'Bed B1',
                isAvailable: true,
                facilities: ['Fan', 'Reading Table', 'Wardrobe', 'Electricity', 'Water'],
              ),
              Bed(
                id: 'B2',
                bedNumber: 'Bed B2',
                isAvailable: true,
                facilities: ['Fan', 'Reading Table', 'Wardrobe', 'Electricity', 'Water'],
              ),
            ],
          ),
        ],
      ),
      Block(
        id: '2',
        name: 'Block B',
        rooms: [
          Room(
            id: '201',
            roomNumber: 'Room 201',
            beds: [
              Bed(
                id: 'C1',
                bedNumber: 'Bed C1',
                isAvailable: false,
                facilities: ['Fan', 'Reading Table', 'Wardrobe', 'Electricity'],
              ),
              Bed(
                id: 'C2',
                bedNumber: 'Bed C2',
                isAvailable: false,
                facilities: ['Fan', 'Reading Table', 'Wardrobe', 'Electricity'],
              ),
            ],
          ),
        ],
      ),
      Block(
        id: '3',
        name: 'Block C',
        rooms: [
          Room(
            id: '301',
            roomNumber: 'Room 301',
            beds: [
              Bed(
                id: 'D1',
                bedNumber: 'Bed D1',
                isAvailable: true,
                facilities: ['Fan', 'Wardrobe', 'Water'],
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
