import 'package:flutter/material.dart';
import 'package:jaimex_front/widgets/Base/registro_card.dart';

// ignore: camel_case_types
class Registro extends StatelessWidget {
  const Registro({super.key});

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
                  image:
                      AssetImage('assets/images/login/backgroupRegister.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    Row(
                      children: [
                        SizedBox(width: 370),
                        Registrocard(),
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
