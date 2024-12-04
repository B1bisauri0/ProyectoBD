import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/Pages/User/NuevoTamara/Detalle.dart';
import 'package:jaimex_front/data/productos.dart';

class Cardproductos extends StatefulWidget {
  final Productos producto;
  final int usuarioID;

  const Cardproductos(this.producto, this.usuarioID, {Key? key})
      : super(key: key);

  @override
  _CardproductosState createState() => _CardproductosState();
}

class _CardproductosState extends State<Cardproductos> {
  final formatter = NumberFormat("#,##0.00", "es_ES");
  String? userEmail;
  bool isLoading = true;
  bool isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    fetchUserEmail();
  }

  Future<void> fetchUserEmail() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/get_correo?id_usuario=${widget.usuarioID}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userEmail = data['correo_electronico'];
            isLoading = false;
          });
        } else {
          throw Exception(data['detail'] ?? "Error al obtener el correo");
        }
      } else {
        throw Exception("Error al obtener el correo: ${response.body}");
      }
    } catch (e) {
      print("Error fetching user email: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addToCart(int productId, int quantity) async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No se pudo obtener el correo del usuario")),
      );
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      final url = Uri.parse(
        'http://127.0.0.1:8000/upsert_carrito_producto?correo_electronico=$userEmail&id_producto=$productId&cantidad=$quantity',
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Producto añadido al carrito con éxito!")),
          );
        } else {
          throw Exception(responseData['detail'] ?? "Error desconocido");
        }
      } else {
        throw Exception("Error al añadir al carrito: ${response.body}");
      }
    } catch (e) {
      print("Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al añadir al carrito")),
      );
    } finally {
      setState(() {
        isAddingToCart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 20),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 400,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: CircularProgressIndicator(), // Indicador de carga
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.producto.urlImagen!,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return Center(
                    child: Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
          if ((widget.producto.isDescuento ?? 0) > 0)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.red,
                child: Text(
                  '-${widget.producto.isDescuento}%',
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
    );
  }

  Widget _buildDetails() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto.nombre!,
                  style: const TextStyle(
                    color: Color.fromRGBO(30, 30, 30, 1),
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Precio: \$${formatter.format(widget.producto.precio)}",
                  style: const TextStyle(
                    color: Color.fromRGBO(117, 117, 117, 1),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    double calificacion = widget.producto.calificacion!;
                    if (index < calificacion.floor()) {
                      return const Icon(Icons.star,
                          color: Colors.amber, size: 30);
                    } else if (index < calificacion && calificacion % 1 != 0) {
                      return const Icon(Icons.star_half,
                          color: Colors.amber, size: 30);
                    } else {
                      return const Icon(Icons.star_border,
                          color: Colors.grey, size: 30);
                    }
                  }),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  backgroundColor: const Color.fromRGBO(70, 162, 159, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 4,
                ),
                onPressed: isAddingToCart
                    ? null
                    : () {
                        addToCart(widget.producto.ID!, 1);
                      },
                child: const Text(
                  "Añadir al carrito",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 40,
                height: 40,
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(
                          widget.producto.ID!,
                          widget.usuarioID,
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color.fromRGBO(70, 162, 159, 1),
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
