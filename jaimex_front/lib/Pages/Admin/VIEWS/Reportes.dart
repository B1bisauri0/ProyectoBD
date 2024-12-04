import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:jaimex_front/widgets/Encabezado/Appbar/headerAdmin.dart';

class ReportsPage extends StatefulWidget {
  int usuario;
  ReportsPage(this.usuario);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<dynamic> topClientes = [];
  List<dynamic> ventasCC = [];
  List<dynamic> ventasPorMes = [];
  Map<int, double> barChartData = {};

  bool isLoadingTopClientes = false;
  bool isLoadingVentasCC = false;
  bool isLoadingVentasPorMes = false;
  bool isLoadingChart = false;

  int yearFilter = 2024;

  @override
  void initState() {
    super.initState();
    fetchTopClientes();
    fetchVentasCC(1, 10);
    fetchVentasPorMes(yearFilter, 1, 12);
    fetchChartData(yearFilter, 1, 100);
  }

  Future<void> fetchTopClientes() async {
    setState(() {
      isLoadingTopClientes = true;
    });
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:8000/get_top_clientes'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            topClientes = data['data'];
          });
        } else {
          throw Exception(data['detail'] ?? "Unknown error");
        }
      } else {
        throw Exception("Failed to fetch Top Clients: ${response.body}");
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingTopClientes = false;
      });
    }
  }

  Future<void> fetchVentasCC(int pageNumber, int pageSize) async {
    setState(() {
      isLoadingVentasCC = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'http://127.0.0.1:8000/get_ventas_cc?page_number=$pageNumber&page_size=$pageSize'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            ventasCC = data['data'];
          });
        } else {
          throw Exception(data['detail'] ?? "Unknown error");
        }
      } else {
        throw Exception(
            "Failed to fetch Sales by Client and Category: ${response.body}");
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingVentasCC = false;
      });
    }
  }

  Future<void> fetchVentasPorMes(int year, int pageNumber, int pageSize) async {
    setState(() {
      isLoadingVentasPorMes = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'http://127.0.0.1:8000/get_ventas_por_mes?year=$year&page_number=$pageNumber&page_size=$pageSize'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            ventasPorMes = data['data'];
          });
        } else {
          throw Exception(data['detail'] ?? "Unknown error");
        }
      } else {
        throw Exception("Failed to fetch Sales by Month: ${response.body}");
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingVentasPorMes = false;
      });
    }
  }

  Future<void> fetchChartData(int year, int pageNumber, int pageSize) async {
    setState(() {
      isLoadingChart = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'http://127.0.0.1:8000/get_ventas_por_mes_gui?year=$year&page_number=$pageNumber&page_size=$pageSize'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> ventas = data['data'];
          Map<int, double> aggregatedData = {};

          // Aggregate sales by month
          for (var venta in ventas) {
            int month = _monthNumber(venta['Mes']);
            double quantity = venta['Cantidad'].toDouble();

            if (aggregatedData.containsKey(month)) {
              aggregatedData[month] = aggregatedData[month]! + quantity;
            } else {
              aggregatedData[month] = quantity;
            }
          }

          setState(() {
            barChartData = aggregatedData;
          });
        } else {
          throw Exception(data['detail'] ?? "Unknown error");
        }
      } else {
        throw Exception("Failed to fetch chart data: ${response.body}");
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingChart = false;
      });
    }
  }

  int _monthNumber(String month) {
    const monthNames = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return monthNames[month] ?? 0;
  }

  Widget buildBarChart() {
    if (barChartData.isEmpty) {
      return const Center(child: Text("No data available for the chart."));
    }

    List<BarChartGroupData> barGroups = barChartData.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [BarChartRodData(toY: entry.value, width: 15)],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                _monthName(value.toInt()),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barGroups: barGroups,
      ),
    );
  }

  String _monthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return month >= 1 && month <= 12 ? monthNames[month - 1] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Headeradmin(widget.usuario, 10),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: fetchTopClientes,
                child: const Text("Top Clientes"),
              ),
              ElevatedButton(
                onPressed: () => fetchVentasCC(1, 10),
                child: const Text("Ventas por cliente y categoria"),
              ),
              ElevatedButton(
                onPressed: () => fetchVentasPorMes(yearFilter, 1, 12),
                child: const Text("Ventas por mes"),
              ),
              ElevatedButton(
                onPressed: () => fetchChartData(yearFilter, 1, 100),
                child: const Text("Refrescar Carrito"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                // Top Clients
                if (isLoadingTopClientes)
                  const Center(child: CircularProgressIndicator()),
                if (topClientes.isNotEmpty) ...[
                  const Text(
                    "Top Clients",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...topClientes.map((cliente) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${cliente['NombreCompleto']}"),
                        Text("Orders: ${cliente['Total_Pedidos']}"),
                        Text(
                            "Total Purchases: \$${cliente['Monto_Total_Compras']}"),
                        const Divider(),
                      ],
                    );
                  }),
                ],
                // Sales by Client & Category
                if (isLoadingVentasCC)
                  const Center(child: CircularProgressIndicator()),
                if (ventasCC.isNotEmpty) ...[
                  const Text(
                    "Sales by Client & Category",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...ventasCC.map((venta) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Client: ${venta['NombreUsuario']}"),
                        Text("Product: ${venta['NombreProducto']}"),
                        Text("Category: ${venta['NombreCategoria']}"),
                        Text("Quantity: ${venta['Cantidad']}"),
                        Text("Total: \$${venta['Total']}"),
                        const Divider(),
                      ],
                    );
                  }),
                ],
                // Sales by Month
                if (isLoadingVentasPorMes)
                  const Center(child: CircularProgressIndicator()),
                if (ventasPorMes.isNotEmpty) ...[
                  const Text(
                    "Sales by Month",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...ventasPorMes.map((venta) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Month: ${venta['Mes']}"),
                        Text("Product: ${venta['NombreProducto']}"),
                        Text("Total: \$${venta['Total']}"),
                        const Divider(),
                      ],
                    );
                  }),
                ],
                // Chart
                const Text(
                  "Monthly Sales Chart",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                SizedBox(
                  height: 300,
                  child: isLoadingChart
                      ? const Center(child: CircularProgressIndicator())
                      : buildBarChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
