import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/User/inicio_sesion.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Tamara/profile_verificado.dart';
import 'package:jaimex_front/widgets/Encabezado/Botones/HeaderButton.dart';

// ignore: must_be_immutable
class Headerver extends StatefulWidget implements PreferredSizeWidget {
  int user;
  int index;

  Headerver(this.user, this.index, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HeaderverState createState() => _HeaderverState();

  @override
  Size get preferredSize => const Size.fromRadius(38);
}

class _HeaderverState extends State<Headerver> {
  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 2, color: Color.fromRGBO(189, 189, 189, 1)),
        ),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          bottom: 5,
          top: 5,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/images/Header/logo.png'),
            ),
            const SizedBox(width: 15),
            const Text(
              "Jaimex",
              style: TextStyle(
                color: Color.fromRGBO(30, 30, 30, 1),
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 30),
                  HeaderButtonVer(0, widget.index, "Inicio", 50, widget.user),
                  const SizedBox(width: 30),
                  HeaderButtonVer(
                      1, widget.index, "Ver Productos", 130, widget.user),
                  const SizedBox(width: 30),
                  HeaderButtonVer(
                      2, widget.index, "Mi Carrito", 100, widget.user),
                  const SizedBox(width: 30),
                ],
              ),
            ),
            // BOTON PARA INICIAR SESION
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InicioSesion(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 23,
                    vertical: 20,
                  ),
                  foregroundColor: Color.fromRGBO(32, 40, 51, 1),
                  backgroundColor: const Color.fromRGBO(102, 252, 241, 1)),
              child: const Text(
                "Cerrar Sesión",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            InkWell(
              onTap: () {
                print(widget.index);
                // PERFIL
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => (UsuarioAutentificado(widget.user)),
                  ),
                );
              },
              child: Image(
                image: AssetImage('assets/images/Header/User.jpg'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
