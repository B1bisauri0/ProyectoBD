import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class ProductDetailsPage extends StatefulWidget {
  final int productId;
  final int userId; // ID del usuario para obtener el correo

  const ProductDetailsPage(this.productId, this.userId);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? productDetails;
  String? userEmail;
  bool isLoading = true;
  bool isAddingToCart = false;
  List<dynamic> reviews = []; // Lista de reseñas
  int pageNumber = 1; // Página actual de reseñas
  bool isFetchingReviews = false; // Estado para la carga de reseñas
  bool hasMoreReviews = true; // Si hay más reseñas por cargar
  bool isSubmittingReview = false; // Estado para la carga de enviar reseñas
  TextEditingController reviewController = TextEditingController();
  int? rating; // Calificación de la reseña
  List<dynamic> relatedProducts = [];

  @override
  void initState() {
    super.initState();
    fetchUserEmailAndProductDetails();
    fetchReviews(); // Cargar reseñas al iniciar
  }

  Future<void> fetchUserEmailAndProductDetails() async {
    try {
      // Llamada al endpoint para obtener el correo del usuario
      final emailResponse = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/get_correo?id_usuario=${widget.userId}'),
      );

      if (emailResponse.statusCode == 200) {
        final emailData = json.decode(emailResponse.body);
        if (emailData['status'] == 'success') {
          setState(() {
            userEmail = emailData['correo_electronico'];
          });
        } else {
          throw Exception(emailData['detail'] ?? "Error al obtener el correo");
        }
      } else {
        throw Exception("Error al obtener el correo: ${emailResponse.body}");
      }

      // Llamada al endpoint para obtener los detalles del producto
      final productResponse = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/get_producto?id_producto=${widget.productId}'),
      );

      if (productResponse.statusCode == 200) {
        final productData = json.decode(productResponse.body);
        setState(() {
          productDetails = productData['data'];
          isLoading = false;
        });
        await fetchRelatedProducts(productData['data']['Nombre_Categoria']);
      } else {
        throw Exception("Error al obtener los detalles del producto");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchRelatedProducts(String category) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/get_productos_by_categoria?categoria=$category'),
      );

      if (response.statusCode == 200) {
        final relatedData = json.decode(response.body);
        if (relatedData['status'] == 'success') {
          setState(() {
            relatedProducts = relatedData[
                'data']; // Llena la lista con productos relacionados
          });
        } else {
          throw Exception(relatedData['detail'] ??
              "Error al obtener productos relacionados");
        }
      } else {
        throw Exception(
            "Error al obtener productos relacionados: ${response.body}");
      }
    } catch (e) {
      print("Error fetching related products: $e");
    }
  }

  Future<void> fetchReviews() async {
    if (isFetchingReviews || !hasMoreReviews) return;

    setState(() {
      isFetchingReviews = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/get_resenas?id_producto=${widget.productId}&page_number=$pageNumber&page_size=10'),
      );

      if (response.statusCode == 200) {
        final reviewData = json.decode(response.body);
        if (reviewData['status'] == 'success') {
          final List<dynamic> fetchedReviews = reviewData['data'];

          setState(() {
            reviews.addAll(fetchedReviews);
            pageNumber++;
            if (fetchedReviews.length < 10) {
              hasMoreReviews =
                  false; // Si hay menos de 10 reseñas, no hay más páginas
            }
          });
        } else {
          throw Exception(reviewData['detail'] ?? "Error al obtener reseñas");
        }
      } else {
        throw Exception("Error al obtener reseñas: ${response.body}");
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    } finally {
      setState(() {
        isFetchingReviews = false;
      });
    }
  }

  Future<void> addToCart(int productId, int quantity) async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo obtener el correo del usuario")),
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
            SnackBar(content: Text("Producto añadido al carrito con éxito!")),
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
        SnackBar(content: Text("Error al añadir al carrito")),
      );
    } finally {
      setState(() {
        isAddingToCart = false;
      });
    }
  }

  Future<void> submitReview() async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo obtener el correo del usuario")),
      );
      return;
    }

    if (rating == null || reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Debe proporcionar una calificación y un comentario")),
      );
      return;
    }

    setState(() {
      isSubmittingReview = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/upsert_resena'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "correo_electronico": userEmail,
          "reseña_id": null, // Nueva reseña
          "id_producto": widget.productId,
          "calificacion": rating,
          "comentario": reviewController.text,
          "fecha": DateTime.now().toIso8601String(), // Fecha de hoy
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Reseña añadida con éxito!")),
          );
          setState(() {
            reviews.clear();
            pageNumber = 1;
            hasMoreReviews = true;
          });
          fetchReviews(); // Recargar reseñas
        } else {
          throw Exception(responseData['detail'] ?? "Error desconocido");
        }
      } else {
        throw Exception("Error al añadir la reseña: ${response.body}");
      }
    } catch (e) {
      print("Error adding review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al añadir la reseña")),
      );
    } finally {
      setState(() {
        isSubmittingReview = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      appBar: Headerver(widget.userId, 1),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 40, top: 30),
                    child: Text(
                      'Detalles del Producto',
                      style: TextStyle(
                        color: Color.fromRGBO(102, 252, 241, 1),
                        fontFamily: 'Inter',
                        fontSize: 60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // CARD DETALLE
                  Padding(
                    padding: EdgeInsets.only(left: 40, top: 30),
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 40,
                          top: 30,
                          right: 40,
                          bottom: 30,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize
                              .min, // Permite que la Card se ajuste a su contenido
                          children: [
                            Text(
                              productDetails?['Nombre_Producto'] ?? '',
                              style: TextStyle(
                                color: Color.fromRGBO(70, 162, 159, 1),
                                fontFamily: 'Inter',
                                fontSize: 35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 20),
                            if (productDetails != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(
                                  productDetails?['URL_Imagen'] ?? '',
                                  height: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image, size: 200);
                                  },
                                ),
                              ),
                            SizedBox(height: 20),
                            // Contener la descripción con límites máximos
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    100, // Altura máxima para la descripción
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  productDetails?['Descripcion'] ?? '',
                                  style: TextStyle(
                                    color: Color.fromRGBO(31, 40, 51, 1),
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Precio: \$${productDetails?['Precio'] ?? ''}",
                              style: TextStyle(
                                color: Color.fromRGBO(31, 40, 51, 1),
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromRGBO(70, 162, 159, 1),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 20),
                              ),
                              onPressed: isAddingToCart
                                  ? null
                                  : () {
                                      addToCart(widget.productId, 1);
                                    },
                              icon: Icon(
                                Icons.shopping_cart,
                                color: Color.fromRGBO(31, 40, 51, 1),
                              ),
                              label: isAddingToCart
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Text(
                                      "Añadir al Carrito",
                                      style: TextStyle(
                                        color: Color.fromRGBO(31, 40, 51, 1),
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Divider(color: Colors.white),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, top: 20, bottom: 20, right: 40),
                    child: Text(
                      "Productos Relacionados",
                      style: TextStyle(
                        color: Color.fromRGBO(102, 252, 241, 1),
                        fontFamily: 'Inter',
                        fontSize: 45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, top: 10, bottom: 20, right: 40),
                    child: Container(
                      height: 350,
                      child: relatedProducts.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: relatedProducts.length,
                              itemBuilder: (context, index) {
                                final product = relatedProducts[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsPage(
                                          product['ID_Producto'],
                                          widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 30,
                                        bottom: 30,
                                        left: 30,
                                        right: 30,
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(height: 10),
                                          Image.network(
                                            product?['URL_Imagen'] ?? '',
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(Icons.broken_image,
                                                  size: 200);
                                            },
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            product['Nombre_Producto'] ?? '',
                                            style: TextStyle(
                                              color:
                                                  Color.fromRGBO(31, 40, 51, 1),
                                              fontFamily: 'Inter',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            "\$${product['Precio'] ?? ''}",
                                            style: TextStyle(
                                              color:
                                                  Color.fromRGBO(31, 40, 51, 1),
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                "No hay productos relacionados disponibles",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(color: Colors.white),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, top: 10, bottom: 10, right: 40),
                    child: Text(
                      "Reseñas",
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(102, 252, 241, 1),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 40, right: 40),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return ListTile(
                          title: Text(
                            review['NombreUsuario'] ?? 'Anónimo',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Text(
                            review['Comentario'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Text(
                            "${review['Calificacion']} ⭐",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                            ),
                          ),
                          textColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  if (isFetchingReviews)
                    Center(child: CircularProgressIndicator()),
                  if (hasMoreReviews && !isFetchingReviews)
                    TextButton(
                      onPressed: fetchReviews,
                      child: Text("Cargar más reseñas"),
                    ),
                  SizedBox(height: 20),
                  Divider(
                    color: Colors.white,
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, top: 10, bottom: 20, right: 40),
                    child: Text(
                      "Escribir Reseña",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 40, right: 40),
                    child: TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        hintText: "Escribe tu reseña aquí",
                        hintStyle: TextStyle(
                          color: Colors.white, // Color del texto del hint
                        ),
                        //filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12), // Padding para el contenido
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Bordes redondeados
                          borderSide: BorderSide(
                            color: Colors.white, // Color del borde
                            width: 1.5, // Grosor del borde
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2, // Grosor del borde enfocado
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 1.5, // Grosor del borde no enfocado
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, right: 40, top: 20, bottom: 20),
                    child: DropdownButton<int>(
                      dropdownColor: Color.fromRGBO(31, 40, 51, 1),
                      value: rating,
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem(
                          child: Text(
                            "${index + 1} ⭐",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          value: index + 1,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          rating = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 40, right: 40, top: 10, bottom: 30),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(70, 162, 159, 1),
                          fixedSize: Size(300, 40)),
                      onPressed: isSubmittingReview
                          ? null
                          : () {
                              submitReview();
                            },
                      child: isSubmittingReview
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              "Enviar Reseña",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
