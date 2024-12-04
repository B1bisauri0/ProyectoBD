import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jaimex_front/data/users.dart';

// ignore: must_be_immutable
class Carduser extends StatelessWidget {
  final User usuario;
  final Function() onActionCompleted;

  Carduser(this.usuario, this.onActionCompleted, {super.key});

  bool verficado = false;

  void initState() {}

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        DateFormat('dd/MM/yyyy').format(usuario.ingreso ?? DateTime.now());
    String actionText = verficado ? 'Desactivar' : 'Activar';
    String nombreC = usuario.nombre + " " + usuario.apellido;
    String correo = usuario.correo;
    String tel = usuario.numeroTel;

    return Card(
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
                    color: Color.fromRGBO(32, 40, 51, 1),
                    fontFamily: 'Inter',
                    fontSize: 20,
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
                      print(tel);
                      // Ejecutar eliminación
                      String username = usuario.nombre;
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
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color.fromRGBO(70, 162, 159, 1),
                ),
                const SizedBox(width: 20),
                Text(
                  'Miembro desde $formattedDate',
                  style: const TextStyle(
                    color: Color.fromRGBO(32, 40, 51, 1),
                    fontFamily: 'Inter',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Correo: $correo',
              style: const TextStyle(
                color: Color.fromRGBO(32, 40, 51, 1),
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Teléfono: $tel',
              style: const TextStyle(
                color: Color.fromRGBO(32, 40, 51, 1),
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
