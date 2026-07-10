import 'package:flutter/services.dart';

List<TextInputFormatter> phoneNumberInputFormatters() => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ];
