import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/admin_productos.dart';
import 'package:jaimex_front/Pages/User/pageOffers.dart';
import 'package:jaimex_front/Pages/User/registro.dart';
import 'package:jaimex_front/data/users.dart';

class log_in extends StatefulWidget {
  const log_in();

  @override
  State<log_in> createState() => _log_inState();
}

class _log_inState extends State<log_in> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  bool _obscureText = true;
  String? _passwordError;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login(BuildContext context) async {
    final correo = _correoController.text;
    final contrasena = _contrasenaController.text;

    try {
      // Enviar la solicitud HTTP
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/userLogIn'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'electronicMail': correo,
          'profilePassword': contrasena,
        }),
      );

      // Decodificar respuesta JSON
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final resultCode = data['resultCode'];
        final userID = data['userID'];
        final userType = data['userType'];
        final errorMessage = data['errorMessage'];

        if (resultCode == 0) {
          // Login exitoso: manejar por tipo de cuenta
          if (userType == 'administrador') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => (AdminProductos(userID)),
              ),
            );
          } else if (userType == 'cliente') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => (PageOffers(userID)),
              ),
            );
          } else {
            print('Tipo de usuario desconocido: $userType');
            _showErrorDialog(
                context, 'Tipo de usuario desconocido. Contacta soporte.');
          }
        } else {
          // Manejo de errores específicos devueltos por el backend
          final error = errorMessage ?? getErrorMessage(resultCode);
          _showErrorDialog(context, error);
        }
      } else {
        // Respuesta HTTP no exitosa
        _showErrorDialog(
            context, 'Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      // Manejo de errores de red o excepciones
      _showErrorDialog(context, 'Error de conexión: ${e.toString()}');
    }
  }

// Obtener el mensaje de error
  String getErrorMessage(int errorCode) {
    switch (errorCode) {
      case 60004:
        return 'El correo electrónico no está registrado.';
      case 60005:
        return 'El correo electrónico tiene un formato inválido.';
      case 60006:
        return 'Las credenciales no coinciden.';
      default:
        return 'Error desconocido. Código: $errorCode';
    }
  }

// Mostrar diálogo de error
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Form(
          key: _formKey,
          child: Container(
            width: 600,
            height: 800,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 50, top: 60, right: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 120),
                        child: Text(
                          "Jaimex",
                          style: TextStyle(
                            fontFamily: 'Shrikhand',
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(38, 18, 0, 1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 125),
                        child: Text(
                          "Jaimex",
                          style: TextStyle(
                            fontFamily: 'Shrikhand',
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromRGBO(102, 252, 241, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 180),
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        fontFamily: 'Dubai',
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(117, 117, 117, 1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          "Correo Electronico",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            color: Color.fromRGBO(46, 22, 0, 1),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 800,
                          child: TextFormField(
                            controller: _correoController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El correo electronico es obligatorio';
                              }
                              return null;
                            },
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: Color.fromRGBO(117, 117, 117, 1),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Correo Electronico',
                              labelStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 10.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          "Contraseña",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            color: Color.fromRGBO(46, 22, 0, 1),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 800,
                          child: TextFormField(
                            controller: _contrasenaController,
                            obscureText: _obscureText,
                            validator: (value) {
                              if (_passwordError != null) {
                                return _passwordError; // Muestra el error almacenado
                              }
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es obligatoria';
                              }
                              return null;
                            },
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: Color.fromRGBO(117, 117, 117, 1),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 10.0),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.only(left: 122),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 20),
                        backgroundColor: Color.fromRGBO(102, 252, 241, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _login(context);
                      },
                      child: const Text(
                        "Ingresar",
                        style: TextStyle(
                          color: Color.fromRGBO(32, 40, 51, 1),
                          fontFamily: 'Dubai',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.only(left: 122),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 20),
                        backgroundColor: Color.fromRGBO(102, 252, 241, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => (Registro()),
                          ),
                        );
                      },
                      child: const Text(
                        "Registro",
                        style: TextStyle(
                          color: Color.fromRGBO(32, 40, 51, 1),
                          fontFamily: 'Dubai',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 600,
          height: 800,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/login/login_image.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

String getErrorMessage(int errorCode) {
  switch (errorCode) {
    case 50007:
      return 'No existe una cuenta registrada con el correo electrónico ingresado';
    case 50008:
      return 'Contraseña inválida para la cuenta ingresada';
    case 60001:
      return 'Cuenta administradora';
    case 60002:
      return 'Cuenta verificada';
    case 60003:
      return 'Cuenta no verificada';
    default:
      return 'Error desconocido';
  }
}
