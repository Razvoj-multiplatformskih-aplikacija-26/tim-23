/// Izvor trenutnog vremena. Bloc-ovi ga dobijaju spolja, pa testovi
/// mogu da zadaju vreme koje im treba.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();
