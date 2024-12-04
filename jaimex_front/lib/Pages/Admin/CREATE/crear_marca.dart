import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/lista_marca.dart';
import 'package:jaimex_front/data/marca.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

// ignore: must_be_immutable
class CrearMarca extends StatefulWidget {
  Marca marcaNueva = Marca(
    nombre: '',
    descripcion: '',
  );
  int IDUsuario;

  CrearMarca(this.IDUsuario, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CrearMarcaState createState() => _CrearMarcaState();
}

class _CrearMarcaState extends State<CrearMarca> {
  // TEXTFIELDS
  int _charCount = 0;
  bool mostrarTextField = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  Future<String> upsertMarca(Marca marca, BuildContext context) async {
    final url = Uri.parse('http://127.0.0.1:8000/upsert_marca');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(marca.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Navegar a la nueva pantalla
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaMarca(widget.IDUsuario),
          ),
        );
        final data = jsonDecode(response.body);
        return data['message'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail']); // Detalle del error
      }
    } catch (e) {
      _showMessageDialog(context, e.toString());
      return "";
      //throw Exception('Error al procesar la marca: $e');
    }
  }

  void _showMessageDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message.contains("Error") ? "Error" : "Éxito"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void CrearMarca() {
    // Captura los datos del producto nuevo
    widget.marcaNueva.nombre = _nombreController.text;
    widget.marcaNueva.descripcion = _descripcionController.text;
    upsertMarca(widget.marcaNueva, context);
  }

  void _countCharacters(String text) {
    setState(() {
      _charCount = text.length; // Simplemente contamos la longitud del texto
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headeradmin(widget.IDUsuario, 1),
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height - 55,
                width: 710,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(102, 252, 241, 0.8), // Color de fondo
                  border: Border(
                    right: BorderSide(
                      color: Colors.white,
                      width: 2.0, // Grosor del borde
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 60, right: 60, top: 200),
                  child: Column(
                    children: [
                      Text(
                        "¡Empecemos con la creación de la marca que necesitas!",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 58,
                          color: Color.fromRGBO(32, 40, 51, 1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 50),
                      Text(
                        "Digita la información esencial para iniciar la creación de la nueva marca.",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 30,
                          color: Color.fromRGBO(11, 12, 16, 1),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.only(left: 100, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Crear Marca",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 58,
                          color: Color.fromRGBO(102, 252, 241, 1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20, top: 30, right: 280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NOMBRE DEL PROYECTO
                            const Text(
                              "Nombre de Marca",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 800,
                              child: TextFormField(
                                controller: _nombreController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El nombre de la marca es obligatoria';
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
                                  labelText: 'Nombre de Marca',
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
                            // Descripcion
                            const SizedBox(height: 30),
                            const Text(
                              "Descripción",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 800,
                              child: TextFormField(
                                controller: _descripcionController,
                                onChanged: _countCharacters,
                                maxLines: 5,
                                minLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La descripcion de la categoría es obligatoria';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Descripción',
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
                            const SizedBox(height: 5),
                            Text(
                              'Caracteres: $_charCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[300],
                                fontFamily: 'Inter',
                              ),
                            ),

                            // BOTON CREAR
                            SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50, vertical: 25),
                                    backgroundColor:
                                        Color.fromRGBO(102, 252, 241, 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ListaMarca(widget.IDUsuario),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Cancelar",
                                    style: TextStyle(
                                      color: Color.fromRGBO(32, 40, 51, 1),
                                      fontFamily: 'Inter',
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 250),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50, vertical: 25),
                                    backgroundColor:
                                        Color.fromRGBO(102, 252, 241, 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      CrearMarca();
                                    }
                                  },
                                  child: const Text(
                                    "Crear Oferta",
                                    style: TextStyle(
                                      color: Color.fromRGBO(32, 40, 51, 1),
                                      fontFamily: 'Inter',
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
