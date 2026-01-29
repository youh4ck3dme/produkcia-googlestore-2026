import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../shared/utils/biz_snackbar.dart';

class ReceiptViewerScreen extends StatelessWidget {
  final String imageUrl;
  final bool isLocal; // true ak je to lokálny súbor (napr. práve odfotený)

  const ReceiptViewerScreen({
    super.key,
    required this.imageUrl,
    this.isLocal = false,
  });

  Future<void> _share(BuildContext context) async {
    try {
      if (isLocal) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(imageUrl)], text: 'Bloček z BizAgent');
      } else {
        // Download first to share
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Dio().download(imageUrl, path);
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(path)], text: 'Bloček z BizAgent');
      }
    } catch (e) {
      if (context.mounted) {
        BizSnackbar.showError(context, 'Zdieľanie zlyhalo: $e');
      }
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'BizAgent_Blocek_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${appDir.path}/$fileName';

      if (isLocal) {
        await File(imageUrl).copy(savePath);
      } else {
        await Dio().download(imageUrl, savePath);
      }

      if (context.mounted) {
        BizSnackbar.showSuccess(context, 'Bloček bol uložený do dokumentov');
      }
    } catch (e) {
      if (context.mounted) {
        BizSnackbar.showError(context, 'Sťahovanie zlyhalo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _download(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: 'receipt_$imageUrl',
            child: isLocal
                ? Image.file(File(imageUrl))
                : Image.network(
                    imageUrl,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.white, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Obrázok sa nepodarilo načítať',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
