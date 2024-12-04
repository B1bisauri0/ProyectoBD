import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/UPDATE/editar_oferta.dart';

import 'package:jaimex_front/data/oferta.dart';

// ignore: must_be_immutable
class Cardoferta extends StatelessWidget {
  final Oferta oferta;
  final Function() onActionCompleted;
  int IDUsuario;

  Cardoferta(this.IDUsuario, this.oferta, this.onActionCompleted, {super.key});

  bool verficado = false;

  void initState() {}

  @override
  Widget build(BuildContext context) {
    String formattedDateIni = oferta.fechaInicio!;
    String formattedDateFin = oferta.fechaFin!;
    String actionText = verficado ? 'Desactivar' : 'Activar';
    String nombreC = oferta.IDProducto.toString() + " " + oferta.producto!;
    String descuento = oferta.descuento.toString();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarOferta(IDUsuario, oferta),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    nombreC,
                    style: const TextStyle(
                      color: Color.fromRGBO(70, 162, 159, 1),
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  PopupMenuButton(
                    color: Colors.white,
                    iconSize: 37,
                    iconColor: Color.fromRGBO(70, 162, 159, 1),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Text(actionText),
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
                      onActionCompleted();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Vigente de:',
                style: const TextStyle(
                  color: Color.fromRGBO(32, 40, 51, 1),
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Desde $formattedDateIni hasta $formattedDateFin',
                style: const TextStyle(
                  color: Color.fromRGBO(32, 40, 51, 1),
                  fontFamily: 'Inter',
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Descuento: $descuento%',
                style: const TextStyle(
                  color: Color.fromRGBO(32, 40, 51, 1),
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
