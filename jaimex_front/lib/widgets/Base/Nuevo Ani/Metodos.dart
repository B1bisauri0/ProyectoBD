import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/MetodoForm.dart';
import 'dart:convert';

import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/address.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/compra.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class Metodos extends StatefulWidget {
  final int userId;

  Metodos({required this.userId});

  @override
  _MetodosState createState() => _MetodosState();
}

class _MetodosState extends State<Metodos> {
  String? email;
  List<Map<String, dynamic>> paymentMethods = [];
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  String? errorMessage;

  // Track the selected method index
  int? selectedMethodIndex;

  final String getUserUrl = "http://127.0.0.1:8000/get_usuario_by_id";
  final String getMetodoUrl = "http://127.0.0.1:8000/get_user_metodo";
  final String checkMaxMetodoUrl =
      "http://127.0.0.1:8000/check_max_metodos_pago";
  final String insertMetodoUrl = "http://127.0.0.1:8000/insert_metodo_pago";
  final String getCartUrl = "http://127.0.0.1:8000/get_carrito";
  final String purchaseUrl = "http://127.0.0.1:8000/purchase";

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
            fetchMetodos();
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

  Future<void> fetchMetodos() async {
    if (email == null) return;

    try {
      final response = await http.get(Uri.parse(
          "$getMetodoUrl?id_usuario=${widget.userId}&correo_electronico=$email"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          setState(() {
            paymentMethods = List<Map<String, dynamic>>.from(data["data"]);
            isLoading = false;
          });
        } else {
          throw Exception("Error fetching payment methods: ${data['detail']}");
        }
      } else {
        throw Exception(
            "Failed to fetch payment methods with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching payment methods: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headerver(widget.userId, 2),
      backgroundColor: Color(0xFF202833),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 80),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 70),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Mis Métodos de Pago",
                            style: TextStyle(
                              color: Color(0xFF66FCF1),
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 70),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              paymentMethods.isEmpty
                                  ? Center(
                                      child: Text(
                                        "No tienes métodos de pago disponibles",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 300,
                                      child: ListView.builder(
                                        itemCount: paymentMethods.length,
                                        itemBuilder: (context, index) {
                                          final metodo = paymentMethods[index];
                                          return Card(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: ListTile(
                                              title: Text(metodo['Tipo'] ??
                                                  "Método no disponible"),
                                              subtitle: Text(metodo[
                                                      'Detalles'] ??
                                                  "Detalles no disponibles"),
                                              leading: GestureDetector(
                                                onTap: () => setState(() {
                                                  selectedMethodIndex = index;
                                                }),
                                                child: CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      selectedMethodIndex ==
                                                              index
                                                          ? Color(0xFF46A29F)
                                                          : Colors.transparent,
                                                  child: selectedMethodIndex ==
                                                          index
                                                      ? Icon(Icons.check,
                                                          color: Colors.white)
                                                      : Icon(
                                                          Icons
                                                              .radio_button_unchecked,
                                                          color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _openMetodoForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF46A29F),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                ),
                                child: Text(
                                  "Agregar Nuevo Método de Pago",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height:
                                      20), // Space between the button and the white rectangle
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              20), // Space between the white rectangle and buttons
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center the buttons
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width *
                                0.35, // Shorter width, 35% of screen width
                            padding: EdgeInsets.symmetric(horizontal: 70),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Address(userId: widget.userId)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF46A29F),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Atrás",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20), // Space between the two buttons
                          Container(
                            width: MediaQuery.of(context).size.width *
                                0.35, // Shorter width, 35% of screen width
                            padding: EdgeInsets.symmetric(horizontal: 70),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Compra(userId: widget.userId)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF46A29F),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Siguiente",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  void _openMetodoForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MetodoFormScreen(email: email, userId: widget.userId),
      ),
    );
  }
}
