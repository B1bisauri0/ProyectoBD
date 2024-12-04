import 'package:intl/intl.dart';

class Productos {
  int? ID;
  String? nombre;
  String? descripcion;
  String? categoria;
  String? marca;
  double? precio;
  int? existencias;
  String? urlImagen;
  double? calificacion;
  DateTime? ingreso;
  double? isDescuento;

  Productos({
    this.ID,
    this.nombre,
    this.descripcion,
    this.categoria,
    this.marca,
    this.precio,
    this.existencias,
    this.urlImagen,
    this.calificacion,
    this.ingreso,
    this.isDescuento,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
        'id_producto': ID ?? null,
        'nombre_producto': nombre,
        'descripcion': descripcion,
        'categoria': categoria,
        'marca': marca,
        'precio': precio,
        'existencias': existencias,
        'url_imagen': urlImagen,
      };

  // Convertir de JSON a instancia de User
  factory Productos.fromJson(Map<String, dynamic> json) => Productos(
        ID: json['ID_Producto'] ?? '',
        nombre: json['Nombre_Producto'] ?? '',
        descripcion: json['Descripcion'] ?? '',
        categoria: json['Nombre_Categoria'] ?? '',
        marca: json['Nombre_Marca'] ?? '',
        precio: json['Precio'] ?? 0,
        existencias: json['Existencias'] ?? 0,
        urlImagen: json['URL_Imagen'] ?? '',
        calificacion: json['Calificacion_Promedio'] ?? 0,
        ingreso: json['Fecha_Creacion'] != null
            ? DateFormat('yyyy-MM-dd').parse(json['Fecha_Creacion'])
            : null,
        isDescuento: json['IsDescuento'] ?? 0,
      );
}
