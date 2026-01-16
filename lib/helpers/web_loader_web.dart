// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void removeWebLoader() {
  final loader = html.document.querySelector('.loading-container');
  if (loader != null) {
    loader.remove();
  }
}
