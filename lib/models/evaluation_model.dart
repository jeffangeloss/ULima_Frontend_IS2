class EvaluationComponent {
  final String id;
  final String nombre;
  final String sigla;
  final double peso;
  final String tipo;

  EvaluationComponent({
    required this.id,
    required this.nombre,
    required this.sigla,
    required this.peso,
    required this.tipo,
  });

  /// Convertir desde JSON
  factory EvaluationComponent.fromJson(Map<String, dynamic> json) {
    return EvaluationComponent(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      sigla: json['sigla']?.toString() ?? '',
      peso: double.tryParse(json['peso']?.toString() ?? '') ?? 0.0,
      tipo: json['tipo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'sigla': sigla,
      'peso': peso,
      'tipo': tipo,
    };
  }
}

class CourseSyllabus {
  final String cursoId;
  final String cursoNombre;
  final String? silaboUrl;
  final List<EvaluationComponent> evaluaciones;

  CourseSyllabus({
    required this.cursoId,
    required this.cursoNombre,
    this.silaboUrl,
    required this.evaluaciones,
  });

  double get pesoTotal => evaluaciones.fold(0, (sum, eval) => sum + eval.peso);

  /// Convertir desde JSON
  factory CourseSyllabus.fromJson(Map<String, dynamic> json) {
    final evaluacionesList = (json['evaluaciones'] as List?)
        ?.map((eval) {
          if (eval is Map) {
            return EvaluationComponent.fromJson(Map<String, dynamic>.from(eval));
          }
          return null;
        })
        .whereType<EvaluationComponent>()
        .toList() ?? const [];

    return CourseSyllabus(
      cursoId: json['cursoId']?.toString() ?? '',
      cursoNombre: json['cursoNombre']?.toString() ?? '',
      silaboUrl: json['silaboUrl']?.toString(),
      evaluaciones: evaluacionesList,
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'cursoId': cursoId,
      'cursoNombre': cursoNombre,
      'evaluaciones': evaluaciones.map((e) => e.toMap()).toList(),
      'pesoTotal': pesoTotal,
    };
  }
}
