import 'package:flutter/material.dart';
import 'package:jaimex_front/data/marca.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Admin/cardMarca.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

// ignore: must_be_immutable
class ListaMarca extends StatefulWidget {
  int usuario;

  ListaMarca(this.usuario, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ListaMarcaState createState() => _ListaMarcaState();
}

class _ListaMarcaState extends State<ListaMarca> {
  List<Marca> _marcas = [];
  List<Marca> _filteredMarcas = [];
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Marca>> _futureMarcas;

  @override
  void initState() {
    super.initState();
    _futureMarcas = fetchMarcas();
    _searchController.addListener(_filterProyectos);
  }

  Future<List<Marca>> fetchMarcas() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllMarcas'));

    if (response.statusCode == 200) {
      // Decodificar la respuesta JSON
      List jsonResponse = json.decode(response.body);

      // Mapear la respuesta a una lista de objetos Marca
      List<Marca> marcas =
          jsonResponse.map((marca) => Marca.fromJson(marca)).toList();

      // Actualizar el estado si es necesario
      setState(() {
        _marcas = marcas;
        _filteredMarcas =
            marcas; // Inicializa la lista filtrada con todas las marcas
      });

      return marcas;
    } else {
      // Manejo de errores
      throw Exception('Failed to load marcas');
    }
  }

  void _filterProyectos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMarcas = _marcas.where((proyecto) {
        final match = proyecto.nombre.toLowerCase().contains(query);
        return match;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headeradmin(widget.usuario, 7),
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: FutureBuilder<List<Marca>>(
        future: _futureMarcas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1820, // Fixed width for horizontal scrolling
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 100, top: 30, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marcas',
                              style: TextStyle(
                                color: Color.fromRGBO(102, 252, 241, 1),
                                fontFamily: 'Inter',
                                fontSize: 64,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 50),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 100, top: 30),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Buscar marca',
                                    labelStyle: const TextStyle(
                                      color: Color.fromRGBO(102, 252, 241, 1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(102, 252, 241, 1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(102, 252, 241, 1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      borderSide: const BorderSide(
                                          color: Color.fromRGBO(
                                              102, 252, 241, 0.8)),
                                    ),
                                    fillColor: Colors.white,
                                    //filled: true,
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color.fromRGBO(102, 252, 241, 0.8),
                                    ),
                                  ),
                                  style: TextStyle(
                                      color:
                                          Color.fromRGBO(102, 252, 241, 0.8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 25,
                                mainAxisSpacing: 25,
                                childAspectRatio: 2.3,
                              ),
                              itemCount: _filteredMarcas.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 10,
                                  height: 100,
                                  child: Cardmarca(widget.usuario,
                                      _filteredMarcas[index], fetchMarcas),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text('No se encontraron marcas'));
          }
        },
      ),
    );
  }
}
