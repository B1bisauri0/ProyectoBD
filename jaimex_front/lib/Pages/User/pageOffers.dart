import 'dart:convert'; // Para decodificar JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/Pages/User/NuevoTamara/Detalle.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

// ignore: must_be_immutable
class PageOffers extends StatefulWidget {
  int ID;
  PageOffers(this.ID, {Key? key}) : super(key: key);

  @override
  State<PageOffers> createState() => _PageOffersState();
}

class _PageOffersState extends State<PageOffers> {
  List<dynamic> offers = []; // Lista de ofertas obtenidas del servidor
  int currentPage = 1; // Página actual
  bool isLoading = true; // Indicador de carga
  final int pageSize = 9; // Tamaño fijo por página
  List<dynamic> destacados = []; // Lista de productos destacados
  // Función para obtener ofertas del servidor
  List<dynamic> dataCat = [];
  bool isLoading2 = true;

  // Función para obtener el correo electrónico del usuario por ID
  Future<String?> getUserEmailById(int userId) async {
    final String url =
        "http://127.0.0.1:8000/get_usuario_by_id?id_usuario=$userId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse['status'] == 'success') {
          // Accedemos al correo desde el campo 'Correo_Electronico' dentro de 'data'
          final data = decodedResponse['data'];
          final email = data['Correo_Electronico'];
          print(email); // Confirmamos el correo en la consola
          return email;
        } else {
          print("Error: Usuario no encontrado");
          return null;
        }
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error fetching user email: $e");
      return null;
    }
  }

  Future<bool> upsertCarritoProducto(
      String correo, int productId, int cantidad) async {
    final String url =
        "http://127.0.0.1:8000/upsert_carrito_producto?correo_electronico=$correo&id_producto=$productId&cantidad=$cantidad";

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        print("Producto añadido o actualizado correctamente en el carrito.");
        return true;
      } else {
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("Error durante la operación de upsert: $e");
      return false;
    }
  }

  Future<void> fetchOffers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String url =
          'http://127.0.0.1:8000/get_ofertas?page_number=$currentPage&page_size=$pageSize';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          offers = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load offers. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching offers: $e');
    }
  }

  Future<void> fetchDestacados() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String url = 'http://127.0.0.1:8000/get_destacados';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          destacados = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load destacados. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching destacados: $e');
    }
  }

  Future<void> fetchTopProducts() async {
    final url = Uri.parse('http://127.0.0.1:8000/get_top_categorias');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          dataCat = result['data'];
          isLoading2 = false;
        });
      } else {
        throw Exception('Error al cargar los datos');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading2 = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOffers();
    fetchDestacados();
    fetchTopProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headerver(widget.ID, 0),
      backgroundColor: const Color.fromRGBO(32, 40, 51, 1),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding:
                  EdgeInsets.only(left: 70, right: 70, top: 40, bottom: 20),
              child: Text(
                "Ofertas Disponibles",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(102, 252, 241, 1),
                ),
              ),
            ),
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                    color: Color.fromRGBO(102, 252, 241, 1),
                  ))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.only(top: 16, left: 70, right: 70),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return InkWell(
                        onTap: () {},
                        child: Card(
                          elevation: 4,
                          color: Colors.white,
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 40, right: 40),
                                    child: Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          width: 500,
                                          height: 400,
                                          offer['URL_Imagen'].toString(),
                                          fit: BoxFit.cover,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            } else {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          (loadingProgress
                                                                  .expectedTotalBytes ??
                                                              1)
                                                      : null,
                                                ),
                                              );
                                            }
                                          },
                                          errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.error,
                                                  color: Colors.red, size: 40),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if ((offer['Descuento_Porcentaje'] ?? 0) > 0)
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        color: Colors.red,
                                        child: Text(
                                          '-${offer['Descuento_Porcentaje']}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      offer['Nombre_Producto'],
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromRGBO(70, 162, 159, 1),
                                        fontFamily: 'Inter',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Precio: \$${offer['Precio_Con_Descuento']}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Color.fromRGBO(32, 40, 51, 1),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsPage(
                                        offer['ID_Producto'],
                                        widget.ID,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 180, vertical: 20),
                                  backgroundColor:
                                      const Color.fromRGBO(70, 162, 159, 1),
                                ),
                                child: const Text(
                                  'Ver Detalles',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: () async {
                                  final correo =
                                      await getUserEmailById(widget.ID);

                                  if (correo != null) {
                                    final success = await upsertCarritoProducto(
                                      correo,
                                      offer['ID_Producto'],
                                      1,
                                    );

                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Producto añadido al carrito con éxito')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error al añadir el producto al carrito')),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error al obtener el correo del usuario')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 170, vertical: 20),
                                  backgroundColor:
                                      const Color.fromRGBO(70, 162, 159, 1),
                                ),
                                child: const Text(
                                  'Añadir Carrito',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                            fetchOffers();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(32, 40, 51, 1),
                    ),
                    child: const Text(
                      'Página Anterior',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentPage++;
                      });
                      fetchOffers();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      backgroundColor: const Color.fromRGBO(70, 162, 159, 1),
                    ),
                    child: const Text(
                      'Página Siguiente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Productos Destacados",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  destacados.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay productos destacados disponibles.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap:
                              true, // Permite que se ajuste al tamaño del contenido
                          physics:
                              const NeverScrollableScrollPhysics(), // Sin scroll interno
                          itemCount: destacados.length,
                          itemBuilder: (context, index) {
                            final destacado = destacados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              elevation: 4,
                              child: ListTile(
                                leading: Image.network(
                                  destacado['URL_Imagen'] ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error, size: 50);
                                  },
                                ),
                                title: Text(
                                  destacado['Nombre_Producto'] ??
                                      'Producto sin nombre',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Cantidad Vendida: ${destacado['Total_Vendido'] ?? 0}\n'
                                  'Precio Total: \$${destacado['Precio'] ?? 0}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsPage(
                                          destacado['ID_Producto'],
                                          widget.ID,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(70, 162, 159, 1),
                                  ),
                                  child: const Text(
                                    'Ver Detalles',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
// Aquí se inserta el Card del Top 3 Productos
            Center(
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: isLoading2
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Top 3 Productos",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "1. ${dataCat[0]['Nombre_Categoria']}",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              "2. ${dataCat[1]['Nombre_Categoria']}",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              "3. ${dataCat[2]['Nombre_Categoria']}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
