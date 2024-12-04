import 'package:flutter/material.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/Reportes.dart';
import 'package:jaimex_front/Pages/Admin/VIEWS/admin_productos.dart';
import 'package:jaimex_front/Pages/User/inicio_sesion.dart';
import 'package:jaimex_front/Pages/User/mis_productos.dart';
import 'package:jaimex_front/Pages/User/pageOffers.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/address.dart';
import 'package:jaimex_front/widgets/Base/Nuevo%20Ani/carrito.dart';

import 'package:jaimex_front/widgets/Base/Nuevo%20Tamara/profile_verificado.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminProductos(5),
    );
  }
}
