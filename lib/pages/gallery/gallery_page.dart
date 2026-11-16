import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/nexio.dart';
import '../../models/photo_memory.dart';
import '../../providers/gallery_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nexio_glass.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gallery = context.read<GalleryProvider>();
      if (!gallery.loaded) gallery.load();
    });
  }

  void _errorListener() {
    final gallery = context.read<GalleryProvider>();
    if (gallery.lastError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(gallery.lastError!)));
      gallery.clearError();
    }
  }

  void _addSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () async {
                final gallery = context.read<GalleryProvider>();
                Navigator.pop(ctx);
                final path = await gallery.pickImage(fromCamera: true);
                if (path != null && mounted) await gallery.addPhoto(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('从相册选择'),
              onTap: () async {
                final gallery = context.read<GalleryProvider>();
                Navigator.pop(ctx);
                final path = await gallery.pickImage(fromCamera: false);
                if (path != null && mounted) await gallery.addPhoto(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    _errorListener();

    return NexioPageScaffold(
      title: '照片记录',

      bottomInset: 40,
      leading: GlassCircleButton(
        icon: Icons.arrow_back,
        semanticLabel: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        GlassCircleButton(
          icon: Icons.add_a_photo_outlined,
          semanticLabel: '添加照片',
          onPressed: _addSheet,
        ),
      ],
      children: [
        if (gallery.photos.isEmpty)
          const NexioCard(
            child: EmptyState(
                icon: Icons.photo_album_outlined,
                text: '点右上角相机图标，添加宝宝的可爱瞬间'),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (i, photo) in gallery.photos.indexed)
                NexioReveal(index: i, child: _PhotoCard(photo: photo)),
            ],
          ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final PhotoMemory photo;
  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final busy = gallery.processing && gallery.processingIndex == photo.id;
    final display = photo.cutoutPath ?? photo.originalPath;
    final df = DateFormat('yyyy/MM/dd');

    return NexioCard(
      radius: 16,
      padding: EdgeInsets.zero,
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(display),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: NexioColors.textAction)),
                ),
                if (busy)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                if (photo.cutoutPath != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: NexioTag(text: '已抠图', color: NexioColors.primary),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(df.format(photo.createdAt), style: NexioType.footnote2),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final gallery = context.read<GalleryProvider>();
    bool showCutout = photo.cutoutPath != null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(DateFormat('yyyy年MM月dd日').format(photo.createdAt),
              style: NexioType.t3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(showCutout && photo.cutoutPath != null
                        ? photo.cutoutPath!
                        : photo.originalPath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                        height: 120,
                        child: Center(child: Icon(Icons.broken_image_outlined))),
                  ),
                ),
              ),
              if (photo.cutoutPath != null) ...[
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('抠图')),
                    ButtonSegment(value: false, label: Text('原图')),
                  ],
                  selected: {showCutout},
                  onSelectionChanged: (v) => setDialog(() => showCutout = v.first),
                ),
              ],
            ],
          ),
          actions: [
            if (photo.cutoutPath == null)
              TextButton.icon(
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('AI 去背景'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await gallery.cutout(photo);
                },
              ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('删除'),
              onPressed: () {
                Navigator.pop(ctx);
                gallery.delete(photo);
              },
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }
}