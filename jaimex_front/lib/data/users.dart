import 'package:intl/intl.dart';

// Modelo de usuario
class User {
  int? id;
  String nombre;
  String apellido;
  String contrasena;
  String correo;
  String numeroTel;
  String tipo;
  DateTime? ingreso;

  User({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.contrasena,
    required this.correo,
    required this.numeroTel,
    required this.tipo,
    this.ingreso,
  });

  // Convertir de JSON a instancia de User
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['ID_Usuario'],
        nombre: json['Nombre'] ?? '',
        apellido: json['Apellido'] ?? '',
        contrasena: json['Contrasena'] ?? '',
        correo: json['Correo_Electronico'] ?? '',
        numeroTel: json['Telefono'] ?? '',
        tipo: json['Tipo_Usuario'] ?? '',
        ingreso: json['Fecha_Registro'] != null
            ? DateFormat('yyyy-MM-dd').parse(json['Fecha_Registro'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'ID_Usuario': id,
        'Nombre': nombre,
        'Apellido': apellido,
        'Contraseña': contrasena,
        'Correo_Electronico': correo,
        'Telefono': numeroTel,
        'Tipo_Usuario': tipo,
        'Fecha_Registro':
            ingreso != null ? DateFormat('yyyy-MM-dd').format(ingreso!) : null,
      };
}
