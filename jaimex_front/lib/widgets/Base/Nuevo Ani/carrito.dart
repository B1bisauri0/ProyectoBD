import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/address.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class Carrito extends StatefulWidget {
  final int userId;

  const Carrito({Key? key, required this.userId}) : super(key: key);

  @override
  _CarritoState createState() => _CarritoState();
}

class _CarritoState extends State<Carrito> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  String? email;

  final String getUserUrl = "http://127.0.0.1:8000/get_usuario_by_id";
  final String getCartUrl = "http://127.0.0.1:8000/get_carrito";
  final String updateCartUrl = "http://127.0.0.1:8000/upsert_carrito_producto";
  final String deleteCartUrl =
      "http://127.0.0.1:8000/delete_producto_from_carrito";

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      final response =
          await http.get(Uri.parse("$getUserUrl?id_usuario=${widget.userId}"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          setState(() {
            email = data["data"]["Correo_Electronico"];
            fetchCartItems(); // Fetch cart items once email is retrieved
          });
        } else {
          throw Exception("Error fetching user: ${data['detail']}");
        }
      } else {
        throw Exception(
            "Failed to fetch user with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching user: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCartItems() async {
    if (email == null) return; // Ensure email is available before fetching cart

    try {
      final response =
          await http.get(Uri.parse("$getCartUrl?id_usuario=${widget.userId}"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          setState(() {
            cartItems = List<Map<String, dynamic>>.from(data["data"]);
            isLoading = false;
          });
        } else {
          throw Exception("Error fetching cart: ${data['detail']}");
        }
      } else {
        throw Exception(
            "Failed to fetch cart with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching cart: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateCart(int productId, int quantity) async {
    if (email == null) return; // Ensure email is available before updating cart

    try {
      final response = await http.post(
        Uri.parse(
            '$updateCartUrl?correo_electronico=$email&id_producto=$productId&cantidad=$quantity'),
        headers: {"Content-Type": "application/json"},
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          fetchCartItems();
        } else {
          throw Exception("Error updating cart: ${data['detail']}");
        }
      } else {
        throw Exception(
            "Failed to update cart with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error updating cart: $error");
    }
  }

  // Add the deleteCartItem function
  Future<void> deleteCartItem(int cartId, int productId) async {
    try {
      final response = await http.delete(
        Uri.parse("$deleteCartUrl?id_carrito=$cartId&id_producto=$productId"),
        headers: {"Content-Type": "application/json"},
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          fetchCartItems(); // Refresh cart after deletion
        } else {
          throw Exception(
              "Error deleting product from cart: ${data['detail']}");
        }
      } else {
        throw Exception(
            "Failed to delete product with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error deleting product from cart: $error");
    }
  }

  // Navigate to Address screen
  void navigateToAddressScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Address(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headerver(widget.userId, 2),
      backgroundColor: Color(0xFF202833), // Set the background color
      body: SingleChildScrollView(
        // Make the entire body scrollable
        child: Column(
          children: [
            SizedBox(height: 80), // Margin for the top bar

            // Title container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 70),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Carrito de Compras",
                  style: TextStyle(
                    color: Color(0xFF66FCF1), // Title color
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Add space between title and white rectangle
            SizedBox(height: 20),

            // Main content in a white rectangle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 70),
              child: Container(
                padding:
                    EdgeInsets.all(16), // Padding inside the white rectangle
                decoration: BoxDecoration(
                  color: Colors.white, // White background for the container
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                child: cartItems.isEmpty
                    ? Center(
                        child: Text(
                          isLoading
                              ? "Cargando..."
                              : "No hay productos en el carrito",
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap:
                            true, // Ensure the ListView adapts to content size
                        physics:
                            NeverScrollableScrollPhysics(), // Disable scrolling inside ListView
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];

                          if (item["Cantidad"] == null) {
                            return SizedBox
                                .shrink(); // Skip this item if any required field is null
                          }

                          int quantity =
                              item["Cantidad"] ?? 0; // Default to 0 if null
                          int productId = item["ID_Producto"]; // Product ID
                          double totalDescuento =
                              item["Total_Descuento"] ?? 0.0;
                          double total = item["Total"] ?? 0.0;
                          int cartId =
                              item["ID_Carrito"]; // Get cart ID for deletion

                          return ListTile(
                            leading: Image.network(
                              item["URL_Imagen"] ??
                                  "https://via.placeholder.com/150",
                              width: 50, // Optional: fixed size for image
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(item["Nombre_Producto"] ?? "Producto"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Precio: \$${item["Total"]}", // Price
                                  style: TextStyle(fontSize: 16),
                                ),
                                if (totalDescuento !=
                                    total) // Show discount if different
                                  Text(
                                    "Oferta: \$${totalDescuento}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors
                                          .red, // Highlight discount in red
                                    ),
                                  ),
                                Text(
                                  "Cantidad: $quantity", // Quantity
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    if (quantity > 1) {
                                      updateCart(productId,
                                          quantity - 1); // Decrease quantity
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    updateCart(productId,
                                        quantity + 1); // Increase quantity
                                  },
                                ),
                                // Trash bin button to delete product from cart
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Colors.red), // Red trash bin icon
                                  onPressed: () {
                                    deleteCartItem(
                                        cartId, productId); // Delete product
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Add the "Siguiente" button below the white rectangle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
              child: Align(
                alignment: Alignment.centerRight, // Align to the right
                child: ElevatedButton(
                  onPressed: navigateToAddressScreen,
                  child: Text(
                    "Siguiente",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF46A29F), // Button color
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
