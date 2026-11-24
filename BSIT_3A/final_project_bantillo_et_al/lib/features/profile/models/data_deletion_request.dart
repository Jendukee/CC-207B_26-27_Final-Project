// A customer data deletion request (table data_deletion_requests,
// migration 0007), shown on the Privacy and data page.
//
// OWNER: Member 2.

/// A customer's request for shop staff to review account-data deletion.
class DataDeletionRequest {
  const DataDeletionRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    this.reason,
  });

  factory DataDeletionRequest.fromMap(Map<String, dynamic> map) {
    return DataDeletionRequest(
      id: map['id'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      reason: map['reason'] as String?,
    );
  }

  final String id;
  final String status;
  final DateTime createdAt;
  final String? reason;

  String get statusLabel => switch (status) {
    'pending' => 'Pending review',
    'in_review' => 'In review',
    'completed' => 'Completed',
    'rejected' => 'Not approved',
    _ => 'Unknown',
  };
}
