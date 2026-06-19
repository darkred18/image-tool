import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';

class ImageCanvas extends ConsumerStatefulWidget {
  final String imageUrl;
  final int index;

  const ImageCanvas({super.key, required this.imageUrl, required this.index});

  @override
  ConsumerState<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends ConsumerState<ImageCanvas> {
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
    final oldPreview = ref
        .read(perspectiveCropProvider)
        .previewPaths[oldWidget.index];
    final newPreview = ref
        .read(perspectiveCropProvider)
        .previewPaths[widget.index];

    if (oldWidget.imageUrl != widget.imageUrl || oldPreview != newPreview) {
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
      final provider = FileImage(File(widget.imageUrl));
      _imageStream = provider.resolve(const ImageConfiguration());

      _imageListener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          final size = Size(
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
          if (mounted)
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
        },
      );
      _imageStream!.addListener(_imageListener!);
    } catch (_) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
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

    // 표시할 이미지 경로 결정 (filter > crop preview > 원본 순)
    final cropState = ref.watch(perspectiveCropProvider);
    final filterPreviewPath = ref.watch(filterProvider).filterPreviewPath;
    final displayPath =
        filterPreviewPath ??
        cropState.previewPaths[widget.index] ??
        widget.imageUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fittedSizes = applyBoxFit(
          BoxFit.contain,
          _rawImageSize!,
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        final renderedSize = fittedSizes.destination;

        // 자기 index 기준으로 저장 → 옆 페이지가 덮어쓰는 버그 방지
        final savedSize = ref.read(imageWidgetSizesProvider)[widget.index];
        if (savedSize != renderedSize) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final current = Map<int, Size>.from(
                ref.read(imageWidgetSizesProvider),
              );
              current[widget.index] = renderedSize;
              ref.read(imageWidgetSizesProvider.notifier).state = current;
            }
          });
        }

        return SizedBox.expand(
          child: Image.file(File(displayPath), fit: BoxFit.contain),
        );
      },
    );
  }
}
