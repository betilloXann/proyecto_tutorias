import 'package:flutter/material.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/text_input_field.dart';

class VerifyCodeView extends StatelessWidget {
  final emailCtrl = TextEditingController();

  VerifyCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6EEF8),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo.png", height: 80),
            Text("Verificar Código",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                    (_) => Container(
                  width: 45,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
            PrimaryButton(
              text: "Enviar código",
              onPressed: () {},
            ),
            TextButton(
                onPressed: () {}, child: Text("Reenviar código")),
          ],
        ),
      ),
    );
  }
}
