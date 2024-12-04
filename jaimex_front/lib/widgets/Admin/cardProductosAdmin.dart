import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jaimex_front/Pages/Admin/UPDATE/editar_producto.dart';
import 'package:jaimex_front/data/productos.dart';

class Cardproductosadmin extends StatelessWidget {
  final Productos producto;
  final formatter = NumberFormat("#,##0.00", "es_ES");
  final int usuarioID;

  Cardproductosadmin(this.producto, this.usuarioID, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditarProducto(usuarioID, producto)),
        );
      },
      child: Container(
        width: 1000,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 520,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors
                      .grey[300], // Color de fondo mientras se carga la imagen
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: CircularProgressIndicator(), // Indicador de carga
                    ),
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          producto.urlImagen!,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                                ),
                              );
                            }
                          },
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stackTrace) {
                            return Center(
                              child: Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    // Si el producto tiene descuento, mostramos la etiqueta

                    if ((producto.isDescuento ?? 0) > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          color: Colors.red,
                          child: Text(
                            '-${producto.isDescuento}%', // Aquí se muestra el porcentaje
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: PopupMenuButton(
                        color: Colors.white,
                        iconSize: 37,
                        iconColor: Color.fromRGBO(70, 162, 159, 1),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 1,
                            child: Text('Eliminar'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 1) {
                            // Ejecutar eliminación
                            /*final response = await http.post(
                        /*Uri.parse(
                            'http://127.0.0.1:8000/deactivateUserProfile?profileNickName=$username'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({'profileNickName': usuario.nombre}),
                        */
                        
                      );*/
                            /*if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Usuario $actionTextAux exitosamente')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error al desactivar usuario')),
                        );
                      }*/
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre!,
                            style: const TextStyle(
                              color: Color.fromRGBO(30, 30, 30, 1),
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Precio: \$${formatter.format(producto.precio)}",
                            style: const TextStyle(
                              color: Color.fromRGBO(117, 117, 117, 1),
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (index) {
                              double calificacion = producto.calificacion!;
                              if (index < calificacion.floor()) {
                                return const Icon(Icons.star,
                                    color: Colors.amber, size: 30);
                              } else if (index < calificacion &&
                                  calificacion % 1 != 0) {
                                return const Icon(Icons.star_half,
                                    color: Colors.amber, size: 30);
                              } else {
                                return const Icon(Icons.star_border,
                                    color: Colors.grey, size: 30);
                              }
                            }),
                          ),
                        ],
                      ),
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
