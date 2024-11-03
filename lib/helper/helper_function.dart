import 'package:flutter/material.dart';

void displayMessageToUsers(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(message),
    ),
  );
}
