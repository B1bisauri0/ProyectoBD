import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/Pages/User/inicio_sesion.dart';
import 'package:jaimex_front/data/users.dart';

class Registrocard extends StatefulWidget {
  const Registrocard({super.key});

  @override
  State<Registrocard> createState() => _RegistrocardState();
}

class _RegistrocardState extends State<Registrocard> {
  final _createKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  bool isVerified = false;

  String? _correoError;
  String? _telefonoError;

  // Función para registrar un usuario
  Future<void> registerUser(User user) async {
    try {
      String apiUrl = 'http://127.0.0.1:8000/registerUser';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['resultCode'] != 0) {
          print(responseBody['resultCode'].toString());
          // Verificar el código de error y asignar el mensaje
          setState(() {
            if (responseBody['resultCode'].toString() == "60002") {
              _correoError = "El correo electrónico ya está registrado.";
              _telefonoError = null;
            } else if (responseBody['resultCode'].toString() == "60001") {
              _correoError = null;
              _telefonoError = "El número de teléfono ya está registrado.";
            } else {
              _correoError = null;
              _telefonoError = null;
            }
          });
        } else {
          setState(() {
            _correoError = null;
            _telefonoError = null;

            print("Registrado con exito");
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (InicioSesion()),
            ),
          );
        }
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  void crearUsuario() {
    if (_createKey.currentState?.validate() ?? false) {
      User usuarioNuevo = User(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        contrasena: _contrasenaController.text,
        correo: _correoController.text,
        numeroTel: _telefonoController.text,
        tipo: "cliente",
        ingreso: DateTime.now(),
        id: 1,
      );

      registerUser(usuarioNuevo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _createKey,
      child: Container(
        width: 1190,
        //height: 850,
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
        child: Row(
          children: [
            Container(
              width: 650,
              height: 750,
              decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/images/login/register_Image.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Container(
              width: 500,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 0, top: 10, right: 0, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    const Padding(
                      padding: EdgeInsets.only(left: 100),
                      child: Text(
                        "Crear Cuenta",
                        style: TextStyle(
                          fontFamily: 'Dubai',
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(70, 162, 159, 1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Text(
                                "Nombre",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  color: Color.fromRGBO(46, 22, 0, 1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 215),
                              Text(
                                "Apellido",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  color: Color.fromRGBO(46, 22, 0, 1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: 240,
                                child: TextFormField(
                                  controller: _nombreController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El nombre es obligatorio';
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Nombre',
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
                              SizedBox(width: 20),
                              SizedBox(
                                width: 240,
                                child: TextFormField(
                                  controller: _apellidoController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El apellido es obligatorio';
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Apellido',
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
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Text(
                                "Teléfono",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  color: Color.fromRGBO(46, 22, 0, 1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 520,
                            child: TextFormField(
                              controller: _telefonoController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El telefono es obligatorio';
                                }
                                if (_telefonoError != null) {
                                  return _telefonoError; // Mostrar el error de la API si existe
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _telefonoError = null;
                                });
                              },
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Teléfono',
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
                          const SizedBox(height: 20),
                          const Text(
                            "Correo Electrónico",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              color: Color.fromRGBO(46, 22, 0, 1),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 520,
                            child: TextFormField(
                              controller: _correoController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El correo electrónico es obligatorio';
                                }
                                String pattern =
                                    r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
                                RegExp regex = RegExp(pattern);
                                if (!regex.hasMatch(value)) {
                                  return 'El correo ingresado no es válido';
                                }
                                if (_correoError != null) {
                                  return _correoError; // Mostrar el error de la API si existe
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _correoError = null;
                                });
                              },
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color.fromRGBO(117, 117, 117, 1),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico',
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
                          const SizedBox(height: 20),
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
                            width: 520,
                            child: TextFormField(
                              controller: _contrasenaController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Debes de ingresar una contraseña obligatorio';
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 100, vertical: 20),
                          backgroundColor:
                              const Color.fromRGBO(102, 252, 241, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_createKey.currentState!.validate()) {
                            crearUsuario();
                          } else {
                            setState(() {});
                          }
                        },
                        child: const Text(
                          "Crear Usuario",
                          style: TextStyle(
                            color: Color.fromRGBO(32, 40, 51, 1),
                            fontFamily: 'Dubai',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 140, vertical: 20),
                          backgroundColor:
                              const Color.fromRGBO(102, 252, 241, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => (InicioSesion()),
                            ),
                          );
                        },
                        child: const Text(
                          "Log In",
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
          ],
        ),
      ),
    );
  }
}
