import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FilePreviewPage extends StatefulWidget {
  const FilePreviewPage({super.key});

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  late String url;
  late String fileName;
  late bool isLoading;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    url = args['url']?.toString() ?? '';
    fileName = args['fileName']?.toString() ?? '';
    isLoading = true;
    _initializePreview();
  }

  Future<void> _initializePreview() async {
    final isImage = RegExp(
      r'\.(jpg|jpeg|png|gif|bmp|webp)$',
      caseSensitive: false,
    ).hasMatch(fileName);
    final isVideo = RegExp(
      r'\.(mp4|mov|avi|wmv)$',
      caseSensitive: false,
    ).hasMatch(fileName);
    final isPdf = RegExp(r'\.(pdf)$', caseSensitive: false).hasMatch(fileName);

    if (isVideo) {
      _videoController = VideoPlayerController.network(url)
        ..initialize()
            .then((_) {
              _chewieController = ChewieController(
                videoPlayerController: _videoController!,
                autoPlay: true,
                looping: false,
                aspectRatio: 16 / 9,
                showControls: true,
                materialProgressColors: ChewieProgressColors(
                  playedColor: const Color(0xFFFF6949),
                  handleColor: const Color(0xFFFF6949),
                  backgroundColor: Colors.grey[300]!,
                  bufferedColor: Colors.grey[500]!,
                ),
              );
              setState(() => isLoading = false);
            })
            .catchError((e) {
              setState(() => isLoading = false);
              _showErrorSnackBar(context, 'Error loading video: $e');
            });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            const Center(child: LoadingIndicator()),
            Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6949),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isImage = RegExp(
      r'\.(jpg|jpeg|png|gif|bmp|webp)$',
      caseSensitive: false,
    ).hasMatch(fileName);
    final isVideo = RegExp(
      r'\.(mp4|mov|avi|wmv)$',
      caseSensitive: false,
    ).hasMatch(fileName);
    final isPdf = RegExp(r'\.(pdf)$', caseSensitive: false).hasMatch(fileName);
    final isDocument = RegExp(
      r'\.(doc|docx|xls|xlsx|ppt|pptx|txt)$',
      caseSensitive: false,
    ).hasMatch(fileName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "File Preview",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 18 : 22,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFFF6949),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isImage)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(20.0),
                        minScale: 0.1,
                        maxScale: 5.0,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Center(
                                child: Text(
                                  'Failed to load image',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  )
                else if (isVideo &&
                    _chewieController != null &&
                    _chewieController!
                        .videoPlayerController
                        .value
                        .isInitialized)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Chewie(controller: _chewieController!),
                  )
                else if (isPdf)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      height: isMobile ? 400 : 600,
                      child: WebViewWidget(
                        controller:
                            WebViewController()
                              ..setJavaScriptMode(JavaScriptMode.unrestricted)
                              ..setBackgroundColor(const Color(0x00000000))
                              ..loadRequest(Uri.parse(url)),
                      ),
                    ),
                  )
                else if (isDocument)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 100,
                            color: const Color(0xFFFF6949),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Opening $fileName externally...',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 16 : 18,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                _showErrorSnackBar(
                                  context,
                                  'Cannot open $fileName',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6949),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Open',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Unsupported file type: $fileName',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 16 : 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
