import 'package:flutter/material.dart';

class BarcodeNewNameBrand extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController brandController;

  BarcodeNewNameBrand({
    required this.nameController,
    required this.brandController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    width: 0.0,
                    color: const Color.fromARGB(255, 194, 228, 224)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(width: 0.0, color: Colors.white),
              ),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: TextField(
            controller: brandController,
            decoration: InputDecoration(
              labelText: 'Brand',
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    width: 0.0,
                    color: const Color.fromARGB(255, 194, 228, 224)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(width: 0.0, color: Colors.white),
              ),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
