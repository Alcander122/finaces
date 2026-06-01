/// Mensajes de error y contenido estático (Única fuente de verdad para la UI)
abstract class ErrorStrings {
  // --- 1. ERRORES DE AUTENTICACIÓN ---
  static const invalidCredentials = "Las credenciales son incorrectas.";
  static const userNotFound = "No encontramos un usuario con este correo.";
  static const wrongPassword = "La contraseña es incorrecta.";
  static const invalidEmail = "El formato del correo es inválido.";
  static const emailInUse = "Este correo ya está registrado.";
  static const weakPassword = "La contraseña es muy débil.";
  static const accountDisabled = "La cuenta está deshabilitada.";
  static const operationNotAllowed = "Método de autenticación no habilitado.";
  static const processCanceledByUser = "Proceso cancelado por el usuario.";
  static const requiresRecentLogin =
      "Por seguridad, vuelve a iniciar sesión e intenta de nuevo.";
  static const invalidCredential = "Credenciales inválidas.";
  static const accountExistsWithDifferentCredential =
      "El correo ya está registrado con otro método de inicio de sesión.";
  static const authCancelled = "Proceso de autenticación cancelado.";
  static const authMethodDisabled =
      "Este método de ingreso no está habilitado.";
  static const passwordResetTooManyRequests =
      "Demasiados intentos. Intenta más tarde.";

  // --- 2. ERRORES DE RED Y SISTEMA ---
  static const networkError =
      "Revisa tu conexión a internet e intenta de nuevo.";
  static const unexpectedError =
      "Ocurrió un error inesperado. Estamos trabajando en ello.";

  // --- 3. VALIDACIONES DE FORMULARIOS (NUEVO) ---
  static const requiredField = "Este campo es obligatorio.";
  static const invalidFormat = "Formato inválido.";
  static const invalidAmount = "El monto debe ser mayor a cero.";
  static const maxCharacters = "Has superado el límite de caracteres.";
  static const passwordMismatch = "Las contraseñas no coinciden.";

  // --- 4. BASE DE DATOS Y EGRESOS (NUEVO) ---
  static const saveFailed = "No pudimos guardar tu gasto. Inténtalo de nuevo.";
  static const saveIngresoFailed =
      "No pudimos guardar tu ingreso. Inténtalo de nuevo.";
  static const deleteFailed = "No se pudo eliminar. Revisa tu conexión.";
  static const loadFailed =
      "Problemas al cargar tus datos. Desliza para actualizar.";
  static const dataNotFound = "Este registro ya no existe o fue eliminado.";
  static const permissionDenied =
      "No tienes permisos para realizar esta acción.";

  // --- 5. ESTADOS VACÍOS Y UX FEEDBACK (NUEVO) ---
  static const noEgresosFound = "No tienes gastos registrados en este periodo.";
  static const noIngresosFound =
      "No tienes ingresos registrados en este periodo.";
  static const offlineSaved = "Sin conexión. Guardado localmente.";

  // --- 6. ÉXITO ---
  static const registrationSuccess = "Registro completado con éxito.";
  static const profileUpdateSuccess = "Perfil actualizado correctamente.";
  static const passwordResetSuccess =
      "Hemos enviado un enlace a tu correo (revisa la carpeta de spam).";
  static const passwordResetFailed =
      "Error al enviar el enlace de recuperación.";

  // --- 7. LEGALES Y TÉRMINOS ---
  static const termsNotAccepted = "Debes aceptar los términos y condiciones.";
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

  // --- 8. BANCOS ---
  static const bankSyncFailed = "No pudimos actualizar el catálogo de bancos, utilizando copia local.";
  static const bankInvalidCatalog = "El archivo de bancos remoto no cumple con el formato correcto.";
  static const bankEmptySelection = "Por favor, selecciona un banco de la lista.";
  static const bankInvalidAccountNumber = "El número de cuenta ingresado debe contener entre 5 y 20 caracteres numéricos.";
}
