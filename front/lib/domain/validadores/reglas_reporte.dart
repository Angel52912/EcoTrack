/// Capa `domain` - Reglas de validacion del formulario (RegExp).
///
/// La UI solo *invoca* estas funciones desde los `validator:` de los
/// `TextFormField`; la logica nunca vive dentro de un metodo `build`.
class ReglasReporte {
  ReglasReporte._();

  /// `EC-` + 4 digitos + `-` + 2 mayusculas. Ejemplo: `EC-2026-AL`.
  static final RegExp patronCodigo = RegExp(r'^EC-\d{4}-[A-Z]{2}$');

  /// Letras, digitos, espacios y puntuacion basica: de 5 a 80 caracteres.
  static final RegExp patronTitulo = RegExp(
    r'^[\wÁÉÍÓÚÑÜáéíóúñü .,\-()/]{5,80}$',
  );

  /// Cualquier texto de 10 a 400 caracteres.
  static final RegExp patronDetalle = RegExp(r'^[\s\S]{10,400}$');

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
