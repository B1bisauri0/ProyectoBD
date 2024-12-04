import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/User/inicio_sesion.dart';
import 'package:jaimex_front/widgets/Encabezado/Botones/HeaderButtonAdmin.dart';

// ignore: must_be_immutable
class Headeradmin extends StatefulWidget implements PreferredSizeWidget {
  int usuario;
  int index;

  Headeradmin(this.usuario, this.index, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HeaderadminState createState() => _HeaderadminState();

  @override
  Size get preferredSize => const Size.fromRadius(38);
}

class _HeaderadminState extends State<Headeradmin> {
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
          top: 10,
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
                fontSize: 30,
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      0, widget.index, "Crear Categoria", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      1, widget.index, "Crear Marca", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      2, widget.index, "Crear Oferta", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      3, widget.index, "Crear Producto", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      4, widget.index, "Ver Productos", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      5, widget.index, "Ver Historial", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      6, widget.index, "Ver Categorias", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      7, widget.index, "Ver Marcas", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      8, widget.index, "Ver Ofertas", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      9, widget.index, "Ver Usuarios", 100, widget.usuario),
                  const SizedBox(width: 30),
                  Headerbuttonadmin(
                      10, widget.index, "Reportes", 60, widget.usuario),
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
                    builder: (context) => (InicioSesion()),
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
                // Perfil
                /*
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => (UsuarioAdmin(widget.usuario)),
                  ),
                );*/
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
