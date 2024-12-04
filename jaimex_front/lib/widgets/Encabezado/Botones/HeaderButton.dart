import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/Reportes.dart';
import 'package:jaimex_front/Pages/User/mis_productos.dart';
import 'package:jaimex_front/Pages/User/pageOffers.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/carrito.dart';

// ignore: must_be_immutable
class HeaderButtonVer extends StatefulWidget {
  String title;
  int index;
  int usuario;
  final int indexPagina;
  double sizeline;
  bool lineIsVisible;

  HeaderButtonVer(
      this.index, this.indexPagina, this.title, this.sizeline, this.usuario,
      {super.key, this.lineIsVisible = true});

  @override
  State<StatefulWidget> createState() => _HeaderButtonVerState(index);
}

class _HeaderButtonVerState extends State<HeaderButtonVer> {
  int index;
  final List _isHovering = [
    false,
    false,
    false,
  ];

  _HeaderButtonVerState(this.index);

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
              builder: (context) => (PageOffers(widget.usuario)),
            ),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (MisProductos(widget.usuario)),
            ),
          );
        } else if (index == 2) {
          // AÑADIR CARRITO
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (Carrito(userId: widget.usuario)),
            ),
          );
        } else if (index == 3) {
          // AÑADIR EXTRA
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (ReportsPage(widget.usuario)),
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
              fontSize: 18,
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
