import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class CardDetalle extends StatelessWidget {
  final int productId;
  final Function() onActionCompleted;
  int usuario;
  String? userEmail;
  Map<String, dynamic>? productDetails;
  bool isLoading = true;

  CardDetalle(this.usuario, this.productId, this.onActionCompleted,
      {super.key});

  void initState() {}

  Future<void> fetchUserEmailAndProductDetails() async {
    try {
      // Llamada al endpoint para obtener el correo del usuario
      final emailResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/get_correo?id_usuario=${usuario}'),
      );

      if (emailResponse.statusCode == 200) {
        final emailData = json.decode(emailResponse.body);
        if (emailData['status'] == 'success') {
          userEmail = emailData['correo_electronico'];
        } else {
          throw Exception(emailData['detail'] ?? "Error al obtener el correo");
        }
      } else {
        throw Exception("Error al obtener el correo: ${emailResponse.body}");
      }

      // Llamada al endpoint para obtener los detalles del producto
      final productResponse = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/get_producto?id_producto=${productId}'),
      );

      if (productResponse.statusCode == 200) {
        final productData = json.decode(productResponse.body);
        productDetails = productData['data'];
        isLoading = false;
      } else {
        throw Exception("Error al obtener los detalles del producto");
      }
    } catch (e) {
      print("Error fetching data: $e");

      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
          child: Column()),
    );
  }
}
