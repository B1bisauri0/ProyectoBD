import 'package:flutter/material.dart';
import 'package:jaimex_front/widgets/Base/inicio_sesion_card.dart';

// ignore: camel_case_types, must_be_immutable
class InicioSesion extends StatelessWidget {
  InicioSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // Fondo de pantalla
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login/login_background.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            // Scroll vertical y horizontal
            const SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    SizedBox(height: 90),
                    Row(
                      children: [
                        SizedBox(width: 350),
                        log_in(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
