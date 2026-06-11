import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/screens/gallery_edit_screen.dart';

class ImageSelectGridScreen extends StatefulWidget {
  const ImageSelectGridScreen({super.key});

  @override
  State<ImageSelectGridScreen> createState() => _ImageSelectGridScreenState();
}

class _ImageSelectGridScreenState extends State<ImageSelectGridScreen> {
  final ImagePicker _picker = ImagePicker();
  // 불러온 모바일 기기 내부 이미지 경로 리스트
  List<String> _selectedImagePaths = [];

  /// 📸 모바일 갤러리에서 여러 장의 이미지를 불러오는 메서드
  Future<void> _pickImagesFromDevice() async {
    try {
      // image_picker의 다중 이미지 선택 기능 호출
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          // 불러온 이미지들의 물리 경로(path)를 리스트에 추가
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 다크 테마 느낌의 배경
      appBar: AppBar(
        title: const Text(
          '편집할 사진 선택',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 💡 앱바에 위치한 이미지 불러오기 버튼
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
          ? _buildEmptyState() // 이미지가 없을 때의 화면
          : _buildImageGrid(), // 이미지가 로드되었을 때의 그리드 뷰
    );
  }

  /// 🏜️ 아직 이미지를 불러오기 전 비어있는 상태 UI
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

  /// ⣿ 불러온 이미지들을 3열 그리드로 보여주는 UI
  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _selectedImagePaths.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 세 열로 나열
        crossAxisSpacing: 6, // 가로 간격
        mainAxisSpacing: 6, // 세로 간격
        childAspectRatio: 1.0, // 1:1 정방형 박스
      ),
      itemBuilder: (context, index) {
        final String path = _selectedImagePaths[index];

        return GestureDetector(
          onTap: () => _navigateToEditScreen(index),
          child: Stack(
            children: [
              // 기기 로컬 이미지를 띄울 때는 Image.file을 사용합니다.
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover, // 썸네일이므로 박스에 가득 채움
                  ),
                ),
              ),
              // 호버 효과나 번호 등을 넣고 싶다면 이 아래 Stack에 추가 가능합니다.
            ],
          ),
        );
      },
    );
  }

  void _navigateToEditScreen(int index) {
    // 1. 필요한 데이터를 채워서 컨트롤러 생성
    final editController = EditPageController(
      images: _selectedImagePaths, // 기기 안의 이미지 경로 리스트
      initialIndex: index, // 사용자가 클릭한 사진 번호
    );

    // 2. 컨트롤러를 들고 편집창으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryEditScreen(controller: editController),
      ),
    ).then((_) => editController.dispose()); // 3. 편집창 닫고 돌아오면 메모리에서 완전 삭제
  }
}
