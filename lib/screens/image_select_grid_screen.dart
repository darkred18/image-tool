import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/screens/gallery_edit_screen.dart';

// ✅ StatefulWidget → ConsumerStatefulWidget으로 변경
class ImageSelectScreen extends ConsumerStatefulWidget {
  const ImageSelectScreen({super.key});

  @override
  ConsumerState<ImageSelectScreen> createState() =>
      _ImageSelectGridScreenState();
}

class _ImageSelectGridScreenState extends ConsumerState<ImageSelectScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedImagePaths = [];

  Future<void> _pickImagesFromDevice() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImagePaths = pickedFiles.map((file) => file.path).toList();
        });
      }
    } catch (e) {
      debugPrint("이미지 불러오기 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  void _navigateToEditScreen(int index) {
    // ✅ 화면 이동 전에 Provider에 먼저 값 설정 - 타이밍 문제 완전 해결
    resetEditStates(ref);
    ref.read(imagesProvider.notifier).state = _selectedImagePaths;
    ref.read(currentIndexProvider.notifier).state = index;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GalleryEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          '편집할 사진 선택',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _pickImagesFromDevice,
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.blueAccent,
            ),
            label: const Text(
              '이미지 불러오기',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _selectedImagePaths.isEmpty
          ? _buildEmptyState()
          : _buildImageGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '우측 상단의 [이미지 불러오기]를 눌러\n모바일의 사진을 추가해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _selectedImagePaths.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final String path = _selectedImagePaths[index];
        return GestureDetector(
          onTap: () => _navigateToEditScreen(index),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
