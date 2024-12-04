import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  final String? email;
  final int userID;

  AddressFormScreen(
      {this.existingAddress, required this.userID, required this.email});

  @override
  _AddressFormScreenState createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.existingAddress?['Direccion'] ?? '');
    _cityController =
        TextEditingController(text: widget.existingAddress?['Ciudad'] ?? '');
    _provinceController =
        TextEditingController(text: widget.existingAddress?['Provincia'] ?? '');
    _postalCodeController = TextEditingController(
        text: widget.existingAddress?['Codigo_Postal'] ?? '');
    _countryController =
        TextEditingController(text: widget.existingAddress?['Pais'] ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _saveAddress() async {
    final newAddress = {
      'direccion': _addressController.text,
      'ciudad': _cityController.text,
      'provincia': _provinceController.text,
      'codigo_postal': _postalCodeController.text,
      'pais': _countryController.text,
      'principal': '0',
    };

    final email = widget.email;
    if (email == null) {
      _showErrorDialog('Email is required');
      return;
    }

    const String apiUrl = "http://127.0.0.1:8000/upsert_direccion";

    final queryParameters = {
      'correo_electronico': email,
      ...newAddress,
    };

    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
      });

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          print('Decoded Response: $data');

          if (data['status'] == 'success') {
            Navigator.pop(context, newAddress);
          } else {
            _showErrorDialog(data['message'] ?? 'An error occurred');
          }
        } catch (e) {
          print('Error parsing response: $e');
          _showErrorDialog('Failed to parse the response');
        }
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        print('Error Response: $error');
        _showErrorDialog(error['detail'] ?? 'An error occurred');
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorDialog('Failed to save address: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headerver(widget.userID, 2),
      backgroundColor: Color(0xFF202833),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingAddress == null
                    ? "Agregar Dirección"
                    : "Editar Dirección",
                style: TextStyle(
                  color: Color(0xFF66FCF1),
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Dirección'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(labelText: 'Ciudad'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _provinceController,
                      decoration: InputDecoration(labelText: 'Provincia'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _postalCodeController,
                      decoration: InputDecoration(labelText: 'Código Postal'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _countryController,
                      decoration: InputDecoration(labelText: 'País'),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _saveAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF46A29F),
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                          child: Text(
                            widget.existingAddress == null
                                ? "Agregar Dirección"
                                : "Guardar Cambios",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Go back to the Address screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF46A29F),
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
