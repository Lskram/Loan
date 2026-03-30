// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<void> purgeLegacyLocalStoreData() async {
  html.window.localStorage.remove('loan_management_app_db_v1');
}
