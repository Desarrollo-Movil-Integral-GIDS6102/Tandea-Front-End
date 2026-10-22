/// Modalidad con la que el participante cubre su cuota.
enum MetodoPago {
  transferencia('transferencia', 'Transferencia'),
  efectivo('efectivo', 'Efectivo'),
  hibrido('hibrido', 'Híbrido');

  /// Valor que espera el backend en el campo `metodoPago`.
  final String valor;

  /// Texto visible para el usuario.
  final String etiqueta;

  const MetodoPago(this.valor, this.etiqueta);

  /// El comprobante es obligatorio cuando hay una parte por transferencia.
  bool get requiereComprobante => this != MetodoPago.efectivo;

  bool get esHibrido => this == MetodoPago.hibrido;

  static MetodoPago fromValor(String? valor) {
    return MetodoPago.values.firstWhere(
      (metodo) => metodo.valor == valor,
      orElse: () => MetodoPago.efectivo,
    );
  }
}
