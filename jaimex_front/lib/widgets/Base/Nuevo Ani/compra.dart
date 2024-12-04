import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/Pages/User/pageOffers.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class Compra extends StatefulWidget {
  final int userId;

  const Compra({Key? key, required this.userId}) : super(key: key);

  @override
  _CompraState createState() => _CompraState();
}

class _CompraState extends State<Compra> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  String? email;

  final String getUserUrl = "http://127.0.0.1:8000/get_usuario_by_id";
  final String getCartUrl = "http://127.0.0.1:8000/get_carrito";
  final String processPaymentUrl = "http://127.0.0.1:8000/purchase";

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      final response =
          await http.get(Uri.parse("$getUserUrl?id_usuario=${widget.userId}"));
      print("Fetching user details for ID ${widget.userId}...");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("User data: ${json.encode(data)}");

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
      print("Fetching cart items for user with email: $email");
      final response =
          await http.get(Uri.parse("$getCartUrl?id_usuario=${widget.userId}"));
      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("Cart items data: ${json.encode(data)}");

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

  // Mock function to process the payment
  Future<void> processPayment() async {
    final paymentData = {};

    try {
      // Modify the URL to include the `id_usuario` in the query string
      final paymentUrl =
          Uri.parse("$processPaymentUrl?id_usuario=${widget.userId}");

      final response = await http.post(
        paymentUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            paymentData), // Body can remain empty or only contain other necessary data
      );

      print("Payment response status: ${response.statusCode}");
      print("Payment response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          // Show success message and handle any additional state changes
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Pago Exitoso"),
              content: Text("El pago se ha procesado con éxito."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => (PageOffers(widget.userId)),
                      ),
                    );
                  },
                  child: Text("Aceptar"),
                ),
              ],
            ),
          );
        } else {
          print("Error details: ${data['detail']}");
          throw Exception("Error processing payment: ${data['detail']}");
        }
      } else {
        print("Failed to process payment. Response: ${response.body}");
        throw Exception(
            "Failed to process payment with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error processing payment: $error");
      // Show error message if payment fails
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error de Pago"),
          content: Text(
              "Hubo un problema al procesar el pago. Inténtalo nuevamente."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Aceptar"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headerver(widget.userId, 2),
      backgroundColor: Color(0xFF202833),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  "Resumen del pedido",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          double totalPrice = item['Precio'] * item['Cantidad'];
                          double totalDiscounted = item['Total_Descuento'];
                          double totalPriceWithShipping =
                              item['Total_Con_Envio'];

                          return ListTile(
                            title: Text(item['Nombre_Producto'] ??
                                "Producto no disponible"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Precio: \$${totalPrice.toStringAsFixed(2)}'),
                                if (item['Total_Descuento'] != item['Precio'])
                                  Text(
                                      'Oferta: \$${totalDiscounted.toStringAsFixed(2)}'),
                                Text('Cantidad: ${item['Cantidad']}'),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Precio con Envío:",
                                    style: TextStyle(fontSize: 14)),
                                Text(
                                  '\$${totalPriceWithShipping.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Total con Envío: \$${calculateTotalWithShipping()}",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 250),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Atrás'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF46A29F),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 250),
                    child: ElevatedButton(
                      onPressed: () {
                        processPayment(); // Trigger payment process
                      },
                      child: Text('Pagar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF46A29F),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  double calculateTotalWithShipping() {
    double total = 0;
    for (var item in cartItems) {
      total += item['Total_Con_Envio'];
    }
    return total;
  }
}
