import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:jaimex_front/Pages/User/NuevoTamara/historialPedidos.dart';
import 'package:jaimex_front/data/users.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class UsuarioAutentificado extends StatefulWidget {
  final int userId; // ID del usuario

  UsuarioAutentificado(this.userId, {super.key});

  @override
  State<UsuarioAutentificado> createState() => _UsuarioAutentificadoState();
}

class _UsuarioAutentificadoState extends State<UsuarioAutentificado> {
  late TextEditingController nameController = TextEditingController();
  late TextEditingController surnameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController phoneController = TextEditingController();
  late TextEditingController userTypeController = TextEditingController();

  bool isEditable = false;
  User? user;

  @override
  void initState() {
    super.initState();
    fetchUserById(widget.userId);
  }

  Future<void> fetchUserById(int id) async {
    final url =
        Uri.parse('http://127.0.0.1:8000/get_usuario_by_id?id_usuario=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(response.body);
        setState(() {
          user = User.fromJson(data["data"]);
          nameController.text = user!.nombre;
          surnameController = TextEditingController(text: user?.apellido);
          emailController = TextEditingController(text: user?.correo);
          passwordController = TextEditingController(text: user?.contrasena);
          phoneController = TextEditingController(text: user?.numeroTel);
          userTypeController =
              TextEditingController(text: user?.tipo ?? 'Desconocido');
        });
      } else {
        showErrorDialog(context, 'Error al cargar el usuario.');
      }
    } catch (e) {
      showErrorDialog(context, 'Error: $e');
    }
  }

  Future<void> updateUser() async {
    final url = Uri.parse('http://127.0.0.1:8000/update_user');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': widget.userId,
          'nombre': nameController.text,
          'apellido': surnameController.text,
          'correo': emailController.text,
          'contrasena': passwordController.text,
          'numero_tel': phoneController.text,
          'tipo_usuario': user!.tipo ?? 'cliente',
        }),
      );
      print(user!.tipo);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final outCode = jsonResponse['out_code'];
        if (outCode == 0) {
          showSuccessDialog(context, 'Usuario actualizado correctamente.');
        } else {
          //showErrorDialog(context, 'Error: Código de error $outCode');
        }
      } else {
        showSuccessDialog(context, 'Usuario actualizado correctamente.');
      }
    } catch (e) {
      //showErrorDialog(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      appBar: Headerver(widget.userId, -1),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  // NOMBRE DEL PROYECTO
                  const Text(
                    "Perfil de Usuario",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 50,
                      color: Color.fromRGBO(102, 252, 241, 1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 800,
                    child: TextFormField(
                      controller: nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.white,
                        labelText: 'Nombre',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.white,
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
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
                      enabled: isEditable,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 800,
                    child: TextFormField(
                      controller: surnameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El apellido es obligatorio';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.white,
                        labelText: 'Apellido',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.white,
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
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
                      enabled: isEditable,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 800,
                    child: TextFormField(
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El correo es obligatorio';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.white,
                        labelText: 'Correo',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.white,
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
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
                      enabled: isEditable,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 800,
                    child: TextFormField(
                      controller: passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La contraseña es obligatoria';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.white,
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.white,
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
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
                      enabled: isEditable,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 800,
                    child: TextFormField(
                      controller: phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El telefono es obligatorio';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.white,
                        labelText: 'Teléfono',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.white,
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
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
                      enabled: isEditable,
                    ),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isEditable = !isEditable;
                          });
                        },
                        child: Text(isEditable ? 'Cancelar' : 'Editar'),
                      ),
                      ElevatedButton(
                        onPressed: isEditable ? updateUser : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text('Guardar Cambios'),
                      ),
                    ],
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              (Historialpedidos(widget.userId)),
                        ),
                      );
                    },
                    child: Text('Ver Pedidos'),
                  ),
                ],
              ),
            ),
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Éxito'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
