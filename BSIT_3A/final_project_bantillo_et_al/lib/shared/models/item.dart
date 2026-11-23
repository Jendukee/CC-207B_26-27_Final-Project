// A rentable gown or suit (one row of the `items` table).
// Shared by catalog, inventory, reservation, bookings and reports.
//
// Note: `condition` is the PHYSICAL state only. Whether an item is booked
// on a date comes from bookings / get_blocked_dates, never from this field.
//
// OWNER: team lead. Change only via a reviewed PR.

/// items.type
enum ItemType {
  /// Gowns (debut, wedding, prom, Filipiniana, etc.).
  gown('gown', 'Gown'),

  /// Suits and barong.
  suit('suit', 'Suit');

  const ItemType(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to users.
  final String label;

  /// Parses the database value.
  static ItemType fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => gown);
}

/// items.age_group
enum AgeGroup {
  /// Children's sizes.
  kids('kids', 'Kids'),

  /// Adult sizes.
  adult('adult', 'Adult');

  const AgeGroup(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to users.
  final String label;

  /// Parses the database value.
  static AgeGroup fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => adult);
}

/// items.condition: physical state of the garment.
enum ItemCondition {
  /// Ready to rent.
  available('available', 'Available'),

  /// Temporarily out for cleaning or repair.
  cleaningRepair('cleaning_repair', 'Cleaning / Repair'),

  /// No longer rented out.
  retired('retired', 'Retired');

  const ItemCondition(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to users.
  final String label;

  /// Parses the database value.
  static ItemCondition fromDb(String value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => available);
}

/// One rentable item.
class Item {
  /// Creates an item.
  const Item({
    required this.id,
    required this.name,
    required this.type,
    required this.ageGroup,
    required this.size,
    required this.price,
    this.description = '',
    this.inclusions = const [],
    this.photoUrls = const [],
    this.condition = ItemCondition.available,
    this.createdAt,
  });

  /// Builds an item from a Supabase row.
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ItemType.fromDb(map['type'] as String),
      ageGroup: AgeGroup.fromDb(map['age_group'] as String),
      size: map['size'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      inclusions: List<String>.from(map['inclusions'] as List? ?? const []),
      photoUrls: List<String>.from(map['photo_urls'] as List? ?? const []),
      condition: ItemCondition.fromDb(map['condition'] as String),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }

  /// Primary key (uuid).
  final String id;

  /// Display name, e.g. "Ivory Ball Gown".
  final String name;

  /// Gown or suit.
  final ItemType type;

  /// Kids or adult.
  final AgeGroup ageGroup;

  /// Size label, e.g. "S", "M", "8-10".
  final String size;

  /// Rental price in pesos for one booking (pickup, event, return days).
  final double price;

  /// Long description.
  final String description;

  /// What comes with the rental (veil, petticoat, necktie...).
  final List<String> inclusions;

  /// Public URLs in the item-photos bucket.
  final List<String> photoUrls;

  /// Physical condition.
  final ItemCondition condition;

  /// When the item was added.
  final DateTime? createdAt;

  /// Row for insert/update. `id` and `created_at` are left to the database.
  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.dbValue,
        'age_group': ageGroup.dbValue,
        'size': size,
        'price': price,
        'description': description,
        'inclusions': inclusions,
        'photo_urls': photoUrls,
        'condition': condition.dbValue,
      };
}
