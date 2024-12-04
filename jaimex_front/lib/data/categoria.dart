class Categoria {
  int? ID;
  String nombre;
  String descripcion;

  Categoria({
    this.ID,
    required this.nombre,
    required this.descripcion,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
        'id_categoria': ID ?? null,
        'nombre_categoria': nombre,
        'descripcion': descripcion,
      };

  // Convertir de JSON a instancia de User
  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        ID: json['ID_Categoria'] ?? '',
        nombre: json['Nombre_Categoria'] ?? '',
        descripcion: json['Descripcion'] ?? '',
      );
}
