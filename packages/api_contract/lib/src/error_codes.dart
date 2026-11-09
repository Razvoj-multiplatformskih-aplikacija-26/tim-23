/// Kodovi grešaka. Server šalje kôd i podatke pravila, a poruku pravi klijent.
abstract final class ErrorCodes {
  // Pravila domena.
  static const invalidDonorName = 'invalid-donor-name';
  static const ageOutOfRange = 'age-out-of-range';
  static const lastDonationInFuture = 'last-donation-in-future';
  static const tooSoonToDonate = 'too-soon-to-donate';
  static const activeAppointmentExists = 'active-appointment-exists';
  static const slotFull = 'slot-full';
  static const slotInPast = 'slot-in-past';
  static const slotNotInDrive = 'slot-not-in-drive';
  static const cancellationTooLate = 'cancellation-too-late';
  static const appointmentStarted = 'appointment-started';
  static const checkInOutsideWindow = 'check-in-outside-window';
  static const appointmentNotStarted = 'appointment-not-started';
  static const invalidDeferralReason = 'invalid-deferral-reason';
  static const invalidTransition = 'invalid-transition';
  static const notFound = 'not-found';
  static const notAllowed = 'not-allowed';

  // Greške zahteva i prijave.
  static const badRequest = 'bad-request';
  static const unsupportedMediaType = 'unsupported-media-type';
  static const payloadTooLarge = 'payload-too-large';
  static const serverError = 'server-error';
  static const invalidCredentials = 'invalid-credentials';
  static const sessionExpired = 'session-expired';
  static const signInRequired = 'sign-in-required';
}
