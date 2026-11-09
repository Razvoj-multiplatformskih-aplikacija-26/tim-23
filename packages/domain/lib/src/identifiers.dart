/// Identifikatori kao posebni tipovi.
///
/// Svi su u osnovi String, ali ih kompajler razlikuje: DonorId ne može
/// slučajno da se prosledi tamo gde se traži AppointmentId.
extension type const DonorId(String value) {}

extension type const AppointmentId(String value) {}

extension type const DriveId(String value) {}

/// Nalog u sistemu (davalac ili osoblje). Davalac ima isti id kao njegov nalog.
extension type const UserId(String value) {}
