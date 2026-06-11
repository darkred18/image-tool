import 'package:flutter/material.dart';
import 'package:image_tools/screens/image_select_grid_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Tools',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // GalleryEditScreen은 EditPageController를 필수로 요구하므로
      // 진입점은 이미지 선택 화면으로 설정합니다.
      home: const ImageSelectGridScreen(),
    );
  }
}
