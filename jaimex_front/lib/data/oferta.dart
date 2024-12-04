class Oferta {
  int? ID;
  int? IDProducto;
  String? producto;
  double? descuento; // En porcentaje
  String? fechaInicio;
  String? fechaFin;

  Oferta({
    this.ID,
    this.IDProducto,
    this.producto,
    this.descuento,
    this.fechaInicio,
    this.fechaFin,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
        'des_id': ID,
        'pro_id': IDProducto,
        'producto': producto,
        'descuento_porcentaje': descuento,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
      };

  // Convertir de JSON a instancia de User
  factory Oferta.fromJson(Map<String, dynamic> json) => Oferta(
        ID: json['ID_Descuento'] ?? '',
        IDProducto: json['ID_Producto'] ?? '',
        producto: json['Nombre_Producto'] ?? '',
        descuento: json['Descuento_Porcentaje'] ?? '',
        fechaInicio: json['Fecha_Inicio'] ?? '',
        fechaFin: json['Fecha_Fin'] ?? '',
      );
}
