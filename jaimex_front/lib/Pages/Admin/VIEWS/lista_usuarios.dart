import 'package:flutter/material.dart';
import 'package:jaimex_front/data/users.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Admin/cardUser.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

// ignore: must_be_immutable
class ListaUsuarios extends StatefulWidget {
  int usuario;

  ListaUsuarios(this.usuario, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ListaUsuariosState createState() => _ListaUsuariosState();
}

class _ListaUsuariosState extends State<ListaUsuarios> {
  late List<User> _user = [];
  late List<User> _filteredUser = [];
  final TextEditingController _searchController = TextEditingController();
  late Future<List<User>> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = fetchProyectos();
    _searchController.addListener(_filterProyectos);
  }

  Future<List<User>> fetchProyectos() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllUsuarios'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      List<User> usuarios =
          jsonResponse.map((usuarios) => User.fromJson(usuarios)).toList();
      setState(() {
        _user = usuarios;
        _filteredUser = usuarios;
      });
      return usuarios;
    } else {
      throw Exception('Failed to load proyectos');
    }
  }

  void _filterProyectos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUser = _user.where((proyecto) {
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
      appBar: Headeradmin(widget.usuario, 8),
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: FutureBuilder<List<User>>(
        future: _futureUser,
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
                              'Usuarios',
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
                                    labelText: 'Buscar usuario',
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
                                        color: Color.fromRGBO(102, 252, 241, 1),
                                      ),
                                    ),
                                    fillColor: Colors.white,

                                    //filled: true,
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color.fromRGBO(102, 252, 241, 1),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Color.fromRGBO(102, 252, 241, 1),
                                  ),
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
                                childAspectRatio: 1.9,
                              ),
                              itemCount: _filteredUser.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 10,
                                  height: 100,
                                  child: Carduser(
                                      _filteredUser[index], fetchProyectos),
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
            return const Center(child: Text('No se encontraron usuarios'));
          }
        },
      ),
    );
  }
}
