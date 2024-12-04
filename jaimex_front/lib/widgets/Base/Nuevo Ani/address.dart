import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/AddressForm.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/Metodos.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/carrito.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class Address extends StatefulWidget {
  final int userId;

  Address({required this.userId});

  @override
  _AddressState createState() => _AddressState();
}

class _AddressState extends State<Address> {
  String? email;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;
  String? errorMessage;

  // Track the selected address index
  int? selectedAddressIndex;

  final String getUserUrl = "http://127.0.0.1:8000/get_usuario_by_id";
  final String getAddressUrl = "http://127.0.0.1:8000/get_user_directions";
  final String updateAddressUrl = "http://127.0.0.1:8000/upsert_direccion";

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
            fetchAddresses();
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

  Future<void> fetchAddresses() async {
    if (email == null) return;

    try {
      final response = await http.get(Uri.parse(
          "$getAddressUrl?id_usuario=${widget.userId}&correo_electronico=$email"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          setState(() {
            addresses = List<Map<String, dynamic>>.from(data["data"]);
            isLoading = false;
          });
        } else {
          throw Exception("Error fetching addresses: ${data['detail']}");
        }
      } else {
        throw Exception(
            "Failed to fetch addresses with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching addresses: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openAddressForm({int? addressIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(
            existingAddress:
                addressIndex != null ? addresses[addressIndex] : null,
            email: email,
            userID: widget.userId),
      ),
    ).then((_) => fetchUserDetails()); // Reload data when returning
  }

  void _selectAddress(int index) {
    setState(() {
      // Select the clicked address and deselect others
      selectedAddressIndex = index == selectedAddressIndex ? null : index;
    });
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
                            "Mis Direcciones",
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
                              addresses.isEmpty
                                  ? Center(
                                      child: Text(
                                        "No hay direcciones disponibles",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 300, // Set a fixed height
                                      child: ListView.builder(
                                        itemCount: addresses.length,
                                        itemBuilder: (context, index) {
                                          final address = addresses[index];
                                          return Card(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: ListTile(
                                              title: Text(address[
                                                      'Direccion'] ??
                                                  "Dirección no disponible"),
                                              subtitle: Text(
                                                '${address['Ciudad'] ?? "Ciudad no disponible"}, '
                                                '${address['Provincia'] ?? "Provincia no disponible"}, '
                                                '${address['Pais'] ?? "País no disponible"}',
                                              ),
                                              leading: GestureDetector(
                                                onTap: () =>
                                                    _selectAddress(index),
                                                child: CircleAvatar(
                                                  radius:
                                                      14, // Smaller circle radius
                                                  backgroundColor:
                                                      selectedAddressIndex ==
                                                              index
                                                          ? Color(
                                                              0xFF46A29F) // Selected color
                                                          : Colors.transparent,
                                                  child: selectedAddressIndex ==
                                                          index
                                                      ? Icon(Icons.check,
                                                          color: Colors.white,
                                                          size:
                                                              20) // Larger check icon
                                                      : Icon(
                                                          Icons
                                                              .radio_button_unchecked,
                                                          color: Colors.grey,
                                                          size:
                                                              20), // Larger unselected icon
                                                ),
                                              ),
                                              trailing: IconButton(
                                                icon: Icon(Icons.edit),
                                                onPressed: () =>
                                                    _openAddressForm(
                                                        addressIndex: index),
                                                color: Color(0xFF46A29F),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => _openAddressForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF46A29F),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                ),
                                child: Text(
                                  "Agregar Nueva Dirección",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              40), // Added space between the white rectangle and the buttons
                      // Row to include the "Atrás" and "Siguiente" buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 70),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // "Atrás" button
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to the Carrito screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Carrito(userId: widget.userId)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(
                                    0xFF46A29F), // Same color as "Agregar Nueva Dirección"
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                              ),
                              child: Text(
                                "Atrás",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // "Siguiente" button
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to the Metodos screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Metodos(userId: widget.userId)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(
                                    0xFF46A29F), // Same color as "Agregar Nueva Dirección"
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                              ),
                              child: Text(
                                "Siguiente",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
