import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/CREATE/crear_categoria.dart';
import 'package:jaimex_front/Pages/Admin/CREATE/crear_marca.dart';
import 'package:jaimex_front/Pages/Admin/CREATE/crear_oferta.dart';
import 'package:jaimex_front/Pages/Admin/CREATE/crear_producto.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/Reportes.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/admin_productos.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/historialPedidosAdmin.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/lista_Ofertas.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/lista_categorias%20.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/lista_marca.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/lista_usuarios.dart';

// ignore: must_be_immutable
class Headerbuttonadmin extends StatefulWidget {
  String title;
  int index;
  final int indexPagina;
  double sizeline;
  bool lineIsVisible;
  int user;

  Headerbuttonadmin(
      this.index, this.indexPagina, this.title, this.sizeline, this.user,
      {super.key, this.lineIsVisible = true});

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => _HeaderbuttonadminState(index);
}

class _HeaderbuttonadminState extends State<Headerbuttonadmin> {
  int index;
  final List _isHovering = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  _HeaderbuttonadminState(this.index);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) {
        setState(() {
          _isHovering[index] = value;
        });
      },
      onTap: () {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (CrearCategoria(widget.user)),
            ),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (CrearMarca(widget.user)),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (CrearOferta(widget.user)),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (CrearProducto(widget.user)),
            ),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (AdminProductos(widget.user)),
            ),
          );
        } else if (index == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (Historialpedidosadmin(widget.user)),
            ),
          );
        } else if (index == 6) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (ListaCategorias(widget.user)),
            ),
          );
        } else if (index == 7) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (ListaMarca(widget.user)),
            ),
          );
        } else if (index == 8) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (ListaOfertas(widget.user)),
            ),
          );
        } else if (index == 9) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (ListaUsuarios(widget.user)),
            ),
          );
        } else if (index == 10) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (ReportsPage(widget.user)),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: (widget.indexPagina == index || _isHovering[index])
                  ? const Color.fromRGBO(102, 252, 241, 1)
                  : const Color.fromRGBO(30, 30, 30, 1),
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 5),
          Visibility(
            maintainAnimation: true,
            maintainState: true,
            maintainSize: true,
            visible: widget.indexPagina == index || _isHovering[index],
            child: Container(
              height: 2,
              width: widget.sizeline,
              color: const Color.fromRGBO(102, 252, 241, 1),
            ),
          )
        ],
      ),
    );
  }
}
