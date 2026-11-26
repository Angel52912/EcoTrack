/// Modulo 1 y Modulo 2 - Capa `domain`.
///
/// Reglas de validacion del negocio. La UI unicamente *invoca* estas
/// funciones desde los `validator:` de los `TextFormField`; la logica de
/// negocio nunca vive dentro del metodo `build` (Regla de Oro).
class ReglasReporte {
  /// Codigo de identificacion: `EC-` + 4 digitos + `-` + 2 mayusculas.
  /// Ejemplo valido: `EC-2026-AL`.
  static final RegExp patronCodigo = RegExp(r'^EC-\d{4}-[A-Z]{2}$');

  /// Titulo: letras/digitos con espacios y puntuacion basica, minimo 5 chars.
  static final RegExp patronTitulo = RegExp(r'^[\wÁÉÍÓÚÑáéíóúñ .,\-()/]{5,80}$');

  /// Detalle: minimo 10 caracteres, maximo 400.
  static final RegExp patronDetalle = RegExp(r'^[\s\S]{10,400}$');

  /// Devuelve `null` si es valido o el mensaje de error en caso contrario.
  static String? validarCodigo(String? valor) {
    final codigo = valor?.trim() ?? '';
    if (codigo.isEmpty) return 'El codigo de identificacion es obligatorio';
    if (!patronCodigo.hasMatch(codigo)) {
      return 'Formato requerido: EC-2026-AL (4 digitos y 2 mayusculas)';
    }
    return null;
  }

  static String? validarTitulo(String? valor) {
    final titulo = valor?.trim() ?? '';
    if (titulo.isEmpty) return 'El titulo es obligatorio';
    if (!patronTitulo.hasMatch(titulo)) {
      return 'Usa de 5 a 80 caracteres validos';
    }
    return null;
  }

  static String? validarDetalle(String? valor) {
    final detalle = valor?.trim() ?? '';
    if (detalle.isEmpty) return 'Describe la novedad de campo';
    if (!patronDetalle.hasMatch(detalle)) {
      return 'El detalle debe tener entre 10 y 400 caracteres';
    }
    return null;
  }
}
