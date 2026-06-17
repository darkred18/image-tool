import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/color_picker/color_picker_overlay.dart';
import 'package:image_tools/features/grid/grid_overlay.dart';

class ImageCanvas extends StatefulWidget {
  final String imageUrl;
  final EditPageController controller;

  const ImageCanvas({
    super.key,
    required this.imageUrl,
    required this.controller,
  });

  @override
  State<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  Size? _rawImageSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveImageDimensions();
  }

  @override
  void didUpdateWidget(covariant ImageCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 이미지 경로가 바뀌었거나(스와이프), 크롭된 경로가 새로 생성되었다면 다시 계산
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.controller.previewCropPath !=
            widget.controller.previewCropPath) {
      _clearStream();
      setState(() {
        _rawImageSize = null;
        _isLoading = true;
        _hasError = false;
      });
      _resolveImageDimensions();
    }
  }

  @override
  void dispose() {
    _clearStream();
    super.dispose();
  }

  void _clearStream() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
  }

  void _resolveImageDimensions() {
    try {
      final ImageProvider provider = FileImage(File(widget.imageUrl));
      _imageStream = provider.resolve(const ImageConfiguration());

      _imageListener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          final Size size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          if (synchronousCall) {
            _rawImageSize = size;
            _isLoading = false;
            _hasError = false;
          } else {
            if (mounted) {
              setState(() {
                _rawImageSize = size;
                _isLoading = false;
                _hasError = false;
              });
            }
          }
        },
        onError: (_, __) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
      );
      _imageStream!.addListener(_imageListener!);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Text('이미지 로드 실패', style: TextStyle(color: Colors.white)),
      );
    }
    if (_isLoading || _rawImageSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final FittedSizes fittedSizes = applyBoxFit(
              BoxFit.contain,
              _rawImageSize!,
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            final Size renderedSize = fittedSizes.destination;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.controller.updateImageWidgetSize(renderedSize);
            });

            return SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(
                        widget.controller.filterPreviewPath ??
                            widget.controller.previewCropPath ??
                            widget.imageUrl,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
