import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/data/productos.dart';
import 'package:jaimex_front/widgets/Admin/cardProductosAdmin.dart';
import 'package:jaimex_front/widgets/Base/cardProductos.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class MisProductos extends StatefulWidget {
  final int usuarioID;

  const MisProductos(this.usuarioID, {super.key});

  @override
  _MisProductosState createState() => _MisProductosState();
}

class _MisProductosState extends State<MisProductos> {
  // ignore: unused_field
  late List<Productos> _productos = [];
  late List<Productos> _filteredProductos = [];
  late Future<List<String>> _brands;
  late Future<List<String>> _categories;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedBrand;
  String? _selectedCategory;
  late final Future<List<String>> futureList;
  double _maxPrice = 100; // Valor inicial arbitrario, será actualizado.
  double _selectedMaxPrice = 100;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadProyectos(); // Cargar los proyectos iniciales
    _brands = fetchBrands();
    _categories = fetchCategories();
    _fetchMaxPrice();
  }

  Future<void> _fetchMaxPrice() async {
    final response = await http
        .get(Uri.parse('http://127.0.0.1:8000/get_max_price_products'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _maxPrice = data[0]['MaxPrecio'] as double;
        _selectedMaxPrice = _maxPrice; // Actualiza el rango seleccionado.
      });
    } else {
      throw Exception('Error al obtener el precio máximo');
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _filterProductos();
    });
  }

  Future<void> _filterProductos() async {
    final query = _searchController.text; // Nombre del producto
    final brand = _selectedBrand; // Marca seleccionada
    final category = _selectedCategory; // Categoría seleccionada
    final maxPrice = _selectedMaxPrice; // Precio máximo seleccionado

    // Construir la URL con los parámetros de consulta
    final url = Uri.http(
      '127.0.0.1:8000',
      '/filterProduct',
      {
        'product_name': query,
        'max_price': maxPrice.toString(),
        'brand': brand ?? '',
        'category': category ?? '',
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['resultCode'] == 0) {
          setState(() {
            _filteredProductos = (data['products'] as List)
                .map((json) => Productos.fromJson(json))
                .toList();
            _productos = _filteredProductos;
            for (var producto in _filteredProductos) {
              print('isDescuento: ${producto.isDescuento}');
            }
          });
        } else {
          print(data['message']); // Mensaje descriptivo del error
          setState(() {
            _filteredProductos = [];
          });
        }
      } else {
        throw Exception('Error al filtrar productos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al filtrar productos: $e');
      setState(() {
        _filteredProductos = [];
      });
    }
  }

  Future<void> _loadProyectos() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/getAllProducts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      List<Productos> proyectos =
          jsonList.map((json) => Productos.fromJson(json)).toList();
      setState(() {
        _productos = proyectos;
        _filteredProductos = proyectos;
        print(_productos);
      });
    } else {
      throw Exception('No se pudieron cargar los productos');
    }
  }

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

  void _onBrandSelected(String? brand) {
    setState(() {
      _selectedBrand = brand;
    });
    _filterProductos();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headerver(widget.usuarioID, 1),
      backgroundColor: const Color.fromRGBO(32, 40, 51, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(left: 70.0, right: 70, top: 20, bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Productos',
                    style: TextStyle(
                      color: Color.fromRGBO(102, 252, 241, 1),
                      fontFamily: 'Inter',
                      fontSize: 70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0, top: 15),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar proyectos',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Rango de Precios',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              Slider(
                activeColor: Color.fromRGBO(102, 252, 241, 1),
                inactiveColor: Colors.white,
                value: _selectedMaxPrice,
                min: 0,
                max: _maxPrice,
                divisions: 10,
                label: '\$${_selectedMaxPrice.toStringAsFixed(2)}',
                onChanged: (double value) {
                  setState(() {
                    _selectedMaxPrice = value;
                  });
                  _filterProductos();
                },
              ),
              const SizedBox(height: 20),
              HorizontalSelectableList(
                futureList: _brands, //fetchBrands(),
                title: 'Marcas',
                onItemSelected: _onBrandSelected,
              ),
              HorizontalSelectableList(
                futureList: _categories, //fetchCategories(),
                title: 'Categorías',
                onItemSelected: _onCategorySelected,
              ),
              const SizedBox(height: 20),
              Center(
                child: _filteredProductos.isEmpty
                    ? const Text(
                        'No se encontraron productos.',
                        style: TextStyle(color: Colors.white, fontSize: 30),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 60,
                          mainAxisSpacing: 50,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _filteredProductos.length,
                        itemBuilder: (context, index) {
                          return Cardproductos(
                            _filteredProductos[index],
                            widget.usuarioID,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HorizontalSelectableList extends StatefulWidget {
  final Future<List<String>> futureList;
  final String title;
  final Function(String?) onItemSelected;

  const HorizontalSelectableList({
    required this.futureList,
    required this.title,
    required this.onItemSelected, // Asegúrate de pasar la función
    Key? key,
  }) : super(key: key);

  @override
  _HorizontalSelectableListState createState() =>
      _HorizontalSelectableListState();
}

class _HorizontalSelectableListState extends State<HorizontalSelectableList> {
  String? _selectedItem; // Variable para rastrear el elemento seleccionado.

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: FutureBuilder<List<String>>(
            future: widget.futureList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                  color: Color.fromRGBO(102, 252, 241, 1),
                ));
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No se encontraron datos',
                        style: TextStyle(color: Colors.white)));
              } else {
                // Agregar el elemento 'Todos'
                final items = ['Todos', ...snapshot.data!];

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected =
                        _selectedItem == item; // Verificar selección.

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedItem = item == 'Todos' ? null : item;
                        });
                        widget.onItemSelected(
                            _selectedItem); // Actualiza el valor en MisProductos
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color.fromRGBO(102, 252, 241, 1)
                              : Color.fromRGBO(70, 162, 159, 1),
                          borderRadius: BorderRadius.circular(20.0),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3.0)
                              : null, // Borde para el seleccionado.
                        ),
                        child: Center(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: isSelected
                                  ? Color.fromRGBO(32, 40, 51, 1)
                                  : Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
