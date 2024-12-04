import 'package:flutter/material.dart';
import 'package:jaimex_front/data/categoria.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Admin/cardCategoria.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

// ignore: must_be_immutable
class ListaCategorias extends StatefulWidget {
  int usuario;
  ListaCategorias(this.usuario, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ListaCategoriasState createState() => _ListaCategoriasState();
}

class _ListaCategoriasState extends State<ListaCategorias> {
  List<Categoria> _categoria = [];
  List<Categoria> _filteredCategoria = [];
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Categoria>> _futureCategoria;

  @override
  void initState() {
    super.initState();
    _futureCategoria = fetchCategoria();
    _searchController.addListener(_filterProyectos);
  }

  Future<List<Categoria>> fetchCategoria() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllCategoria'));

    if (response.statusCode == 200) {
      // Decodificar la respuesta JSON
      List jsonResponse = json.decode(response.body);

      // Mapear la respuesta a una lista de objetos Marca
      List<Categoria> categoria = jsonResponse
          .map((categoria) => Categoria.fromJson(categoria))
          .toList();

      // Actualizar el estado si es necesario
      setState(() {
        _categoria = categoria;
        _filteredCategoria =
            categoria; // Inicializa la lista filtrada con todas las marcas
      });

      return categoria;
    } else {
      // Manejo de errores
      throw Exception('Failed to load marcas');
    }
  }

  void _filterProyectos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategoria = _categoria.where((proyecto) {
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
      appBar: Headeradmin(widget.usuario, 6),
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: FutureBuilder<List<Categoria>>(
        future: _futureCategoria,
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
                              itemCount: _filteredCategoria.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 10,
                                  height: 100,
                                  child: Cardcategoria(
                                      widget.usuario,
                                      _filteredCategoria[index],
                                      fetchCategoria),
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
