class Marca {
  int? ID;
  String nombre;
  String descripcion;

  Marca({
    this.ID,
    required this.nombre,
    required this.descripcion,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
        'id_marca': ID ?? null,
        'nombre_marca': nombre,
        'descripcion': descripcion,
      };

  // Convertir de JSON a instancia de User
  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        ID: json['ID_Marca'] ?? '',
        nombre: json['Nombre_Marca'] ?? '',
        descripcion: json['Descripcion'] ?? '',
      );
}
