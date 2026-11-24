/// In-memory reservation details passed between the flow's steps.
class ReservationDraft {
  const ReservationDraft({
    required this.itemId,
    required this.eventDate,
    this.measurements = const {},
  });

  final String itemId;
  final DateTime eventDate;
  final Map<String, dynamic> measurements;

  ReservationDraft withMeasurements(Map<String, dynamic> value) =>
      ReservationDraft(
        itemId: itemId,
        eventDate: eventDate,
        measurements: Map<String, dynamic>.unmodifiable(value),
      );
}
