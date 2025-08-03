/// Mensajes de error y contenido estático
abstract class ErrorStrings {
  // Errores de autenticación
  static const invalidCredentials = "Credenciales incorrectas";
  static const userNotFound = "Usuario no encontrado";
  static const wrongPassword = "Contraseña incorrecta";
  static const invalidEmail = "Correo inválido";
  static const emailInUse = "El correo ya está registrado";
  static const weakPassword = "Contraseña muy débil";
  
  // Errores de red
  static const networkError = "Error de conexión";
  
  // Generales
  static const unexpectedError = "Error inesperado";
  static const requiredField = "Campo obligatorio";
  static const invalidFormat = "Formato inválido";
  static const passwordMismatch = "Contraseñas no coinciden";
  
  // Términos y privacidad
  static const termsNotAccepted = "Debe aceptar los términos";
  static const termsAndConditionsTitle = "Términos y Condiciones";
  static const privacyPolicyTitle = "Política de Privacidad";
  
   // Mensajes de términos y condiciones - ADAPTADOS PARA COLOMBIA
  static const termsAndConditionsContent = 
    "Al aceptar estos términos, usted reconoce y acepta que:\n"
    "• Cumplimos con la Ley 1581 de 2012 y el Decreto 1377 de 2013, normativa colombiana que regula la protección de datos personales, garantizando que nadie tendrá acceso a su información financiera, incluso nosotros como administradores.\n"
    "• La información proporcionada puede ser utilizada exclusivamente para análisis de consumo de créditos y gestión financiera personal, pero solo se procesarán datos relevantes, excluyendo expresamente números de cuentas, saldos y cualquier dato bancario sensible.\n"
    "• Nuestra aplicación cumple con las normativas de seguridad financiera establecidas en la Circular Externa 007 de 2013 de la Superintendencia Financiera de Colombia y la Ley 1328 de 2009 (Ley de Protección al Usuario de Servicios Financieros).\n"
    "• Usted conserva en todo momento el derecho a conocer, actualizar, rectificar y solicitar la eliminación de sus datos personales, según establece el Artículo 8 de la Ley 1581 de 2012.\n"
    "• Los datos serán conservados únicamente durante el tiempo necesario para los fines para los que fueron recogidos, conforme a lo establecido en el Artículo 9 de la Ley 1581 de 2012.";
  
  // Política de privacidad adaptada para Colombia
  static const privacyPolicyContent = 
    "Nuestra política de privacidad garantiza que:\n"
    "• Sus datos personales y financieros son tratados con la máxima confidencialidad, conforme a los estándares de seguridad establecidos en la Resolución 1578 de 2021 de la Superintendencia de Industria y Comercio y la Circular Externa 007 de 2013 de la Superintendencia Financiera de Colombia.\n"
    "• No compartiremos su información con terceros sin su consentimiento expreso, excepto cuando sea requerido por ley o autoridades competentes en cumplimiento de obligaciones legales.\n"
    "• Implementamos medidas técnicas y organizativas apropiadas para garantizar un nivel de seguridad adecuado al riesgo, incluyendo cifrado AES-256 para datos en tránsito y reposo, según lo establecido en el Artículo 10 de la Ley 1581 de 2012.\n"
    "• Sus datos solo serán utilizados para los fines establecidos en esta política y nunca para fines comerciales no autorizados.\n"
    "• Usted tiene derecho a presentar quejas o reclamos ante la Superintendencia de Industria y Comercio si considera que se ha vulnerado su derecho a la protección de datos, conforme al Artículo 14 de la Ley 1581 de 2012.";
  
  // Mensajes de éxito
  static const registrationSuccess = "Registro exitoso";
}