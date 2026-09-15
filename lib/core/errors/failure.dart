/// Représentation générique d'une erreur métier/réseau,
/// retournée par les repositories au lieu de laisser fuiter des exceptions Supabase.
class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}
