import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jaimex_front/data/productos.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

// ignore: must_be_immutable
class CrearProducto extends StatefulWidget {
  Productos productoNuevo = Productos(
      nombre: '',
      descripcion: '',
      categoria: '',
      marca: '',
      precio: 0,
      existencias: 0,
      urlImagen: '',
      calificacion: 0);
  int IDUsuario;

  CrearProducto(this.IDUsuario, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CrearProductoState createState() => _CrearProductoState();
}

class _CrearProductoState extends State<CrearProducto> {
  // DROPDOWN MENU
  String? _selectedBrand;
  String? _selectedCategory;
  List<String> _brands = [];
  List<String> _categories = [];

  // TEXTFIELDS
  int _charCount = 0;
  bool mostrarTextField = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _existenciasController = TextEditingController();
  final TextEditingController _urlImagenController = TextEditingController();

  Future<String> upsertProducto(
      Productos producto, BuildContext context) async {
    final url = Uri.parse('http://127.0.0.1:8000/upsert_productos');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(producto.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String message = data['message'];

        // Mostrar el mensaje en un dialog dependiendo de la respuesta
        _showMessageDialog(context, message);
        return message;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail']); // Detalle del error
      }
    } catch (e) {
      _showMessageDialog(context, 'Error al procesar el producto: $e');
      return "";
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

  void CrearProducto() {
    // Captura los datos del producto nuevo
    widget.productoNuevo.nombre = _nombreController.text;
    widget.productoNuevo.descripcion = _descripcionController.text;
    widget.productoNuevo.categoria = _selectedCategory ?? '';
    widget.productoNuevo.marca = _selectedBrand ?? '';
    widget.productoNuevo.precio = double.tryParse(_precioController.text) ?? 0;
    widget.productoNuevo.existencias =
        int.tryParse(_existenciasController.text) ?? 0;
    widget.productoNuevo.urlImagen = _urlImagenController.text;
    upsertProducto(widget.productoNuevo, context);
  }

  void _countCharacters(String text) {
    setState(() {
      _charCount = text.length; // Simplemente contamos la longitud del texto
    });
  }

  // Para obtener los nombres de las marcas
  Future<List<String>> fetchBrands() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllBrandName'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((brand) => brand['Nombre_Marca'] as String).toList();
    } else {
      throw Exception('Error al obtener las marcas');
    }
  }

  // Para obtener los nombres de las categorias
  Future<List<String>> fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllCategoryName'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((category) => category['Nombre_Categoria'] as String)
          .toList();
    } else {
      throw Exception('Error al obtener las categorías');
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      final brands = await fetchBrands();
      final categories = await fetchCategories();
      setState(() {
        _brands = brands;
        _categories = categories;
      });
    } catch (e) {
      // Manejo de errores
      print('Error al cargar datos: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headeradmin(widget.IDUsuario, 3),
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 1300,
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
                  padding: EdgeInsets.only(left: 60, right: 60, top: 250),
                  child: Column(
                    children: [
                      Text(
                        "¡Empecemos con la creación del producto que necesitas!",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 58,
                          color: Color.fromRGBO(32, 40, 51, 1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 50),
                      Text(
                        "Digita la información esencial para iniciar la creación de tu producto.",
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
                        "Crear Producto",
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
                              "Nombre del Producto",
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
                                    return 'El nombre del proyecto es obligatorio';
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
                                  labelText: 'Nombre del Producto',
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
                                    return 'La descripcion del proyecto obligatorio';
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
                            // Categoria
                            const SizedBox(height: 25),
                            const Text(
                              "Marca",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Dropdown de Marcas
                            Container(
                              width: 800,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Color.fromRGBO(32, 40, 51, 1),
                                value: _selectedBrand,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedBrand = newValue;
                                  });
                                },
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Seleccione una marca';
                                  }
                                  return null;
                                },
                                items: _brands.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                          fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Dropdown de Categorías

                            const Text(
                              "Categoría",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 800,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Color.fromRGBO(32, 40, 51, 1),
                                value: _selectedCategory,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Seleccione una categoría';
                                  }
                                  return null;
                                },
                                items: _categories
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                          fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 30),
                            // TEXTFIELD Precio
                            const Text(
                              "Precio",
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
                                controller: _precioController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El precio es obligatorio';
                                  }
                                  final parsedValue = double.tryParse(value);
                                  if (parsedValue == null) {
                                    return 'Por favor, introduce un número decimal válido';
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
                                  labelText: 'Precio',
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
                            // TEXTFIELD Existencias
                            SizedBox(height: 30),
                            const Text(
                              "Existencias",
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
                                controller: _existenciasController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Las existencias son obligatorias';
                                  }
                                  final parsedValue = int.tryParse(value);
                                  if (parsedValue == null) {
                                    return 'Por favor, introduce un número entero válido';
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
                                  labelText: 'Existencias',
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

                            // URL
                            SizedBox(height: 30),
                            const Text(
                              "URL de Imagen",
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
                                controller: _urlImagenController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La URL es obligatoria';
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
                                  labelText: 'URL de Imagen',
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
                                    if (_formKey.currentState!.validate()) {
                                      //enviarProyecto();
                                    }
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
                                      CrearProducto();
                                    }
                                  },
                                  child: const Text(
                                    "Crear Producto",
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
