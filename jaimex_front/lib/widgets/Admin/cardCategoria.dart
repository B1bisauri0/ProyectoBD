import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/UPDATE/editar_categoria.dart';
import 'package:jaimex_front/data/categoria.dart';

// ignore: must_be_immutable
class Cardcategoria extends StatelessWidget {
  final Categoria categoria;
  final Function() onActionCompleted;
  int usuario;

  Cardcategoria(this.usuario, this.categoria, this.onActionCompleted,
      {super.key});

  bool verficado = false;

  void initState() {}

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditarCategoria(usuario, categoria)),
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
                    categoria.nombre,
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
                      categoria.descripcion,
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
