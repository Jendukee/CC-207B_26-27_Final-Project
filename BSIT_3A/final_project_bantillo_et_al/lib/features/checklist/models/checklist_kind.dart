// Which checklist is being filled in. Private to the checklist feature.
//
// OWNER: Member 3.

/// checklists.kind
enum ChecklistKind {
  /// Handing the item to the customer (pickup day).
  release('release', 'Release'),

  /// Receiving the item back (return day).
  returned('return', 'Return');

  const ChecklistKind(this.dbValue, this.label);

  /// Value stored in the database.
  final String dbValue;

  /// Text shown to users.
  final String label;
}
