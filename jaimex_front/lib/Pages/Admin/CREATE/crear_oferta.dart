import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/lista_Ofertas.dart';
import 'package:jaimex_front/data/oferta.dart';
import 'package:jaimex_front/data/productos.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

// ignore: must_be_immutable
class CrearOferta extends StatefulWidget {
  Oferta ofertaNueva = Oferta(
    IDProducto: -1,
    descuento: 1,
    fechaInicio: '',
    fechaFin: '',
  );
  int IDUsuario;

  CrearOferta(this.IDUsuario, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CrearOfertaState createState() => _CrearOfertaState();
}

class _CrearOfertaState extends State<CrearOferta> {
  // DROPDOWN MENU

  int? _selectedProductId;
  // ignore: unused_field
  String? _selectedProductName;
  List<Productos> _productos = [];

  // DROPDOWN

  // FECHA CONTROLLER
  final TextEditingController _fechaControllerIni = TextEditingController();
  final TextEditingController _fechaControllerFin = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime? _selectedDate;

  // TEXTFIELDS
  bool mostrarTextField = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descuentoController = TextEditingController();

  Future<String> upsertOferta(Oferta oferta, BuildContext context) async {
    final url = Uri.parse('http://127.0.0.1:8000/upsert_descuentos');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(oferta.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaOfertas(widget.IDUsuario),
          ),
        );
        return data['message'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail']); // Detalle del error
      }
    } catch (e) {
      _showMessageDialog(context, e.toString());
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

  void CrearOferta() {
    // Captura los datos del producto nuevo
    widget.ofertaNueva.ID = null;
    widget.ofertaNueva.IDProducto = _selectedProductId ?? 0;
    widget.ofertaNueva.descuento = double.parse(_descuentoController.text);
    widget.ofertaNueva.fechaInicio = _fechaControllerIni.text;
    widget.ofertaNueva.fechaFin = _fechaControllerFin.text;

    upsertOferta(widget.ofertaNueva, context);
  }

  void _selectDateIni(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Fecha inicial
      firstDate: DateTime(2000), // Fecha mínima permitida
      lastDate: DateTime(2101), // Fecha máxima permitida
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _fechaControllerIni.text =
            _dateFormat.format(_selectedDate!); // Formato de la fecha
      });
    }
  }

  void _selectDateFin(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Fecha inicial
      firstDate: DateTime(2000), // Fecha mínima permitida
      lastDate: DateTime(2101), // Fecha máxima permitida
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _fechaControllerFin.text =
            _dateFormat.format(_selectedDate!); // Formato de la fecha
      });
    }
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

  Future<void> _loadProductos() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllProducts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      List<Productos> productos =
          jsonList.map((json) => Productos.fromJson(json)).toList();
      setState(() {
        _productos = productos; // Carga los productos en la lista global
      });
    } else {
      throw Exception('No se pudieron cargar los productos');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headeradmin(widget.IDUsuario, 2),
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 1150,
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
                        "Crear Oferta",
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
                            // DROPDOWN MENU DE LOS PROYECTOS
                            const SizedBox(height: 10),

                            Container(
                              width: 800,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromRGBO(70, 162, 159, 1),
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonFormField<Productos>(
                                dropdownColor:
                                    const Color.fromRGBO(32, 40, 51, 1),
                                value: _selectedProductId != null
                                    ? _productos.firstWhere(
                                        (prod) => prod.ID == _selectedProductId,
                                        // ignore: null_check_always_fails
                                        orElse: () => null!)
                                    : null,
                                onChanged: (Productos? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedProductId = newValue
                                          .ID; // Guarda el ID seleccionado
                                      _selectedProductName = newValue
                                          .nombre; // Guarda el nombre seleccionado
                                    });
                                  }
                                },
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Seleccione un producto';
                                  }
                                  return null;
                                },
                                items: _productos
                                    .map<DropdownMenuItem<Productos>>(
                                        (Productos producto) {
                                  return DropdownMenuItem<Productos>(
                                    value: producto,
                                    child: Text(
                                      '${producto.ID} - ${producto.nombre}', // Muestra ID y nombre juntos
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // TEXTFIELD Descuento
                            const Text(
                              "Porcentaje de Descuento",
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
                                controller: _descuentoController,
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

                            // FECHA INICIO

                            const SizedBox(height: 30),
                            const Text(
                              "Fecha de Inicio",
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
                                style: TextStyle(color: Colors.white),
                                controller: _fechaControllerIni,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor selecciona una fecha';
                                  }

                                  // Convertir el valor ingresado en un DateTime
                                  DateTime? fechaIngresada =
                                      _dateFormat.parse(value);

                                  // Obtener la fecha actual
                                  DateTime fechaActual = DateTime.now();

                                  return null;
                                },
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Selecciona una Fecha Inicial',
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
                                onTap: () => _selectDateIni(context),
                              ),
                            ),

                            // FECHA FINAL

                            const SizedBox(height: 30),
                            const Text(
                              "Fecha de Fin",
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
                                style: TextStyle(color: Colors.white),
                                controller: _fechaControllerFin,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor selecciona una fecha';
                                  }

                                  // Convertir el valor ingresado en un DateTime
                                  DateTime? fechaIngresada =
                                      _dateFormat.parse(value);

                                  // Obtener la fecha actual
                                  DateTime fechaActual = DateTime.now();

                                  // Comparar si la fecha ingresada es menor o igual a la fecha actual
                                  if (fechaIngresada.isBefore(fechaActual)) {
                                    return 'La fecha debe ser mayor a la actual';
                                  }

                                  return null;
                                },
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Selecciona una Fecha Final',
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
                                onTap: () => _selectDateFin(context),
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
                                    if (_formKey.currentState!.validate()) {}
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
                                      CrearOferta();
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
