class AccountingPeriodModel {
  final int? periodoId;
  final int mes;
  final int anio;
  final String encargado;
  final String estado;

  const AccountingPeriodModel({
    this.periodoId,
    required this.mes,
    required this.anio,
    required this.encargado,
    this.estado = 'abierto',
  });

  factory AccountingPeriodModel.fromMap(Map<String, dynamic> data) {
    return AccountingPeriodModel(
      periodoId: data['periodo_id'] as int?,
      mes: data['mes'] as int,
      anio: data['anio'] as int,
      encargado: (data['encargado'] as String?) ?? 'Sin asignar',
      estado: (data['estado'] as String?) ?? 'abierto',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'periodo_id': periodoId,
      'mes': mes,
      'anio': anio,
      'encargado': encargado,
      'estado': estado,
    };
  }

  String get nombreMes => nombresMeses[mes - 1];

  static const List<String> nombresMeses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
}
