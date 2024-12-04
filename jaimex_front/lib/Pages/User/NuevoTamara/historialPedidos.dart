import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:jaimex_front/data/pedido.dart';

// ignore: must_be_immutable
class Historialpedidos extends StatefulWidget {
  int IDUsuario;
  Historialpedidos(this.IDUsuario);
  @override
  _HistorialpedidosState createState() => _HistorialpedidosState();
}

class _HistorialpedidosState extends State<Historialpedidos> {
  List<Pedido> _orderData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  String _selectedDate = '';
  late String nombre;

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  // Fetch data from the API with pagination
  Future<void> _fetchOrderHistory({int pageNumber = 1, String? date}) async {
    final usuarioID = widget.IDUsuario;
    final pageSize = 10;

    try {
      String url =
          'http://127.0.0.1:8000/get_historial_pedidos?usuarioID=$usuarioID&page_number=$pageNumber&page_size=$pageSize';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _orderData = List<Pedido>.from(
                data['data'].map((order) => Pedido.fromJson(order)));
            _isLoading = false;
            nombre = _orderData.first.nombreUsuario;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load data: ${data['status']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load data: $error';
        _isLoading = false;
      });
    }
  }

  // Handle page navigation
  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _fetchOrderHistory(pageNumber: _currentPage, date: _selectedDate);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _fetchOrderHistory(pageNumber: _currentPage, date: _selectedDate);
    }
  }

  // Handle date selection
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
      });
      _fetchOrderHistory(pageNumber: _currentPage, date: _selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(32, 40, 51, 1),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Padding(
                  padding: const EdgeInsets.only(top: 40, left: 70, right: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedidos de $nombre',
                        style: TextStyle(
                          color: Color.fromRGBO(102, 252, 241, 1),
                          fontFamily: 'Inter',
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 30),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 60, top: 30, bottom: 30, right: 60),
                          child:
                              // Data Table
                              Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'Nombre Usuario',
                                      style: TextStyle(
                                        color: Color.fromRGBO(30, 30, 30, 1),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                      label: Text(
                                    'Pedido ID',
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    'Fecha Pedido',
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    'Estado',
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    'Precio Total',
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    'Dirección',
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    'Detalles Método',
                                    style: TextStyle(
                                      color: Color.fromRGBO(30, 30, 30, 1),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  )),
                                ],
                                rows: _orderData.map((pedido) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                        pedido.nombreUsuario,
                                        style: TextStyle(
                                          color: Color.fromRGBO(30, 30, 30, 1),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                        ),
                                      )),
                                      DataCell(Text(
                                        pedido.pedidoID.toString(),
                                        style: TextStyle(
                                          color: Color.fromRGBO(30, 30, 30, 1),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                        ),
                                      )),
                                      DataCell(Text(
                                        pedido.fechaPedido,
                                        style: TextStyle(
                                          color: Color.fromRGBO(30, 30, 30, 1),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                        ),
                                      )),
                                      DataCell(Text(
                                        pedido.estado,
                                        style: TextStyle(
                                          color: Color.fromRGBO(30, 30, 30, 1),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                        ),
                                      )),
                                      DataCell(Text(
                                        pedido.precioTotal.toString(),
                                        style: TextStyle(
                                          color: Color.fromRGBO(30, 30, 30, 1),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                        ),
                                      )),
                                      DataCell(
                                        Container(
                                          constraints: BoxConstraints(
                                              maxWidth:
                                                  400), // Establece un máximo ancho para la celda
                                          child: Text(
                                            pedido.direccion,
                                            style: TextStyle(
                                              color:
                                                  Color.fromRGBO(30, 30, 30, 1),
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.normal,
                                              fontSize: 16,
                                            ),
                                            softWrap:
                                                true, // Esto permite que el texto se divida en varias líneas
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          constraints:
                                              BoxConstraints(maxWidth: 300),
                                          child: Text(
                                            pedido.detallesMetodo,
                                            style: TextStyle(
                                              color:
                                                  Color.fromRGBO(30, 30, 30, 1),
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.normal,
                                              fontSize: 16,
                                            ),
                                            softWrap:
                                                true, // Permite el salto de línea
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Pagination Controls
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: _goToPreviousPage,
                          ),
                          Text(
                            'Página $_currentPage',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                            onPressed: _goToNextPage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
