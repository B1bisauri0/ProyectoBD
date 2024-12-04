import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/UPDATE/editar_marca.dart';
import 'package:jaimex_front/data/marca.dart';

// ignore: must_be_immutable
class Cardmarca extends StatelessWidget {
  final Marca marca;
  final Function() onActionCompleted;
  int usuario;

  Cardmarca(this.usuario, this.marca, this.onActionCompleted, {super.key});

  bool verficado = false;

  void initState() {}

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditarMarca(marca, usuario)),
        );
      },
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    marca.nombre,
                    style: const TextStyle(
                      color: Color.fromRGBO(32, 40, 51, 1),
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
                        child: Text("Acción"),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 1) {
                        print("delete");
                        // Acción adicional
                        onActionCompleted();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      marca.descripcion,
                      style: const TextStyle(
                        color: Color.fromRGBO(32, 40, 51, 1),
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
