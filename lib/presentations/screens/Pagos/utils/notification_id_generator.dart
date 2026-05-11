import 'dart:convert';
import 'package:crypto/crypto.dart';

class NotificationIdGenerator {
  /// Genera un entero determinista de 32 bits a partir de un String usando MD5.
  /// Esto es crítico porque flutter_local_notifications solo acepta IDs `int`,
  /// y los IDs de Firestore son `String`.
  static int generateDeterministicId(String paymentId, int daysOffset) {
    // Concatenamos el ID del pago y el offset para asegurar unicidad
    final String key = '${paymentId}_$daysOffset';
    
    // Generar MD5 del string
    final bytes = utf8.encode(key);
    final digest = md5.convert(bytes);
    
    // Tomar los primeros 4 bytes y convertirlos a un entero de 32-bits sin signo (positivo)
    int hashInt = 0;
    for (int i = 0; i < 4; i++) {
      hashInt = (hashInt << 8) + digest.bytes[i];
    }
    
    // Asegurarse de que cabe en un int32 de Dart/Java (remover el bit de signo)
    return hashInt & 0x7FFFFFFF;
  }
}
