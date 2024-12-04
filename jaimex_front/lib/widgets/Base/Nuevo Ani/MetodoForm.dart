import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jaimex_front/widgets/Encabezado/Appbar/headerVer.dart';

class MetodoFormScreen extends StatefulWidget {
  final String? email;
  final int? userId;
  final Map<String, dynamic>? existingMetodo;

  MetodoFormScreen({
    required this.email,
    required this.userId,
    this.existingMetodo, // Optional parameter for editing
  });

  @override
  _MetodoFormScreenState createState() => _MetodoFormScreenState();
}

class _MetodoFormScreenState extends State<MetodoFormScreen> {
  String? _selectedMetodo;
  late TextEditingController _detailsController;
  int? _metodoId; // Store the ID of the payment method for editing

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();

    // If an existing metodo is passed, set the form fields with its values
    if (widget.existingMetodo != null) {
      _selectedMetodo = widget.existingMetodo!['metodo_pago'];
      _detailsController.text = widget.existingMetodo!['detalles'];
      _metodoId = widget.existingMetodo![
          'metodo_id']; // Assuming 'metodo_id' is the field name for the ID
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _saveMetodo() async {
    print("Attempting to save payment method...");
    print("Selected Metodo: $_selectedMetodo");
    print("Details: ${_detailsController.text}");

    if (_selectedMetodo == null || _detailsController.text.isEmpty) {
      _showErrorDialog('Please fill out all fields.');
      return;
    }

    // Define the payload with required fields
    final newMetodo = {
      'metodo_id': _metodoId, // Add metodo_id for editing
      'metodo_pago': _selectedMetodo,
      'detalles': _detailsController.text,
      'correo_electronico': widget.email, // User email
      'usuario_id': widget.userId, // Use passed user ID
      'tipo': _selectedMetodo, // Map dropdown selection to 'tipo'
      'principal': 0, // Set principal to 0
    };

    const String apiUrl =
        "http://127.0.0.1:8000/update_payment_method"; // Endpoint for updating

    try {
      print("Sending PUT request to $apiUrl with payload: $newMetodo");
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newMetodo),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Decoded Response: $data');

        if (data['status'] == 'success') {
          Navigator.pop(context, newMetodo);
        } else {
          _showErrorDialog(data['message'] ?? 'An error occurred');
        }
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        print('Error Response: $error');
        _showErrorDialog(error['detail'] ?? 'An error occurred');
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorDialog('Failed to save payment method: $e');
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
      appBar: Headerver(widget.userId!, 2),
      backgroundColor: Color(0xFF202833),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingMetodo != null
                    ? "Editar Método de Pago"
                    : "Agregar Método de Pago",
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
                    DropdownButtonFormField<String>(
                      value: _selectedMetodo,
                      items: [
                        DropdownMenuItem(
                          child: Text("Tarjeta de Crédito"),
                          value: "Tarjeta de Crédito",
                        ),
                        DropdownMenuItem(
                          child: Text("Tarjeta de Débito"),
                          value: "Tarjeta de Débito",
                        ),
                        DropdownMenuItem(
                          child: Text("PayPal"),
                          value: "PayPal",
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMetodo = value;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Método de Pago'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _detailsController,
                      decoration: InputDecoration(labelText: 'Detalles'),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _saveMetodo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF46A29F),
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                          child: Text(
                            widget.existingMetodo != null
                                ? "Actualizar Método"
                                : "Guardar Método",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Go back to the previous screen
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
