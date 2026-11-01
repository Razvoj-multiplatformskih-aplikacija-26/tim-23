part of 'booking_bloc.dart';

sealed class BookingEvent {
  const BookingEvent();
}

final class BookingRequested extends BookingEvent {
  const BookingRequested();
}

final class BookingSlotSelected extends BookingEvent {
  const BookingSlotSelected(this.slotStart);

  final DateTime slotStart;
}

final class BookingSubmitted extends BookingEvent {
  const BookingSubmitted();
}

/// Ekran je prikazao poruku o ishodu, pa je Bloc briše.
final class BookingNoticeAcknowledged extends BookingEvent {
  const BookingNoticeAcknowledged();
}
