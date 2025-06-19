import 'package:flutter/material.dart';
import 'package:hybridlms/models/course.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentViewerPage extends StatelessWidget {
  const ContentViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Course course = ModalRoute.of(context)!.settings.arguments as Course;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            toolbarHeight: 60,
            titleSpacing: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Content: ${course.title}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 18 : 22,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6949), Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFFFF6949),
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Content',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : 20,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      if (course.modules == null || course.modules!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'No content available.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: course.modules!.length,
                          itemBuilder: (context, moduleIndex) {
                            final module = course.modules![moduleIndex];
                            return ExpansionTile(
                              title: Text(
                                module['name']?.toString() ?? 'Unnamed Module',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 14 : 16,
                                  color: const Color(0xFFFF6949),
                                ),
                              ),
                              initiallyExpanded: moduleIndex == 0,
                              children: [
                                if (module['lessons'] == null ||
                                    (module['lessons'] as List).isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'No lessons available.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontSize: isMobile ? 12 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                else
                                  ...List.generate(
                                    (module['lessons'] as List).length,
                                    (lessonIndex) {
                                      final lesson =
                                          module['lessons'][lessonIndex];
                                      return ExpansionTile(
                                        title: Text(
                                          lesson['name']?.toString() ??
                                              'Unnamed Lesson',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: isMobile ? 13 : 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        initiallyExpanded:
                                            lessonIndex == 0 &&
                                            moduleIndex == 0,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 8.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (lesson['text'] != null &&
                                                    (lesson['text'] as String)
                                                        .isNotEmpty)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Lesson Text:',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  isMobile
                                                                      ? 12
                                                                      : 14,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        lesson['text'],
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontSize:
                                                                  isMobile
                                                                      ? 12
                                                                      : 14,
                                                              color:
                                                                  Colors
                                                                      .grey[800],
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                    ],
                                                  ),
                                                if ((lesson['documents'] !=
                                                            null &&
                                                        (lesson['documents']
                                                                as List)
                                                            .isNotEmpty) ||
                                                    (lesson['videos'] != null &&
                                                        (lesson['videos']
                                                                as List)
                                                            .isNotEmpty) ||
                                                    (lesson['images'] != null &&
                                                        (lesson['images']
                                                                as List)
                                                            .isNotEmpty))
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (lesson['documents'] !=
                                                              null &&
                                                          (lesson['documents']
                                                                  as List)
                                                              .isNotEmpty)
                                                        _buildContentSection(
                                                          context,
                                                          'Documents',
                                                          lesson['documents'],
                                                          isMobile,
                                                        ),
                                                      if (lesson['videos'] !=
                                                              null &&
                                                          (lesson['videos']
                                                                  as List)
                                                              .isNotEmpty)
                                                        _buildContentSection(
                                                          context,
                                                          'Videos',
                                                          lesson['videos'],
                                                          isMobile,
                                                        ),
                                                      if (lesson['images'] !=
                                                              null &&
                                                          (lesson['images']
                                                                  as List)
                                                              .isNotEmpty)
                                                        _buildContentSection(
                                                          context,
                                                          'Images',
                                                          lesson['images'],
                                                          isMobile,
                                                        ),
                                                    ],
                                                  ),
                                                if ((lesson['documents'] ==
                                                            null ||
                                                        (lesson['documents']
                                                                as List)
                                                            .isEmpty) &&
                                                    (lesson['videos'] == null ||
                                                        (lesson['videos']
                                                                as List)
                                                            .isEmpty) &&
                                                    (lesson['images'] == null ||
                                                        (lesson['images']
                                                                as List)
                                                            .isEmpty) &&
                                                    (lesson['text'] == null ||
                                                        (lesson['text']
                                                                as String)
                                                            .isEmpty))
                                                  Text(
                                                    'No content available for this lesson.',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontSize:
                                                              isMobile
                                                                  ? 12
                                                                  : 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    String title,
    List<dynamic> urls,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        ...urls.map((url) {
          final fileName = url.toString().split('/').last;
          final isImage = RegExp(
            r'\.(jpg|jpeg|png|gif|bmp)$',
            caseSensitive: false,
          ).hasMatch(url);
          final isVideo = RegExp(
            r'\.(mp4|mov|avi|wmv)$',
            caseSensitive: false,
          ).hasMatch(url);
          final isDocument = RegExp(
            r'\.(pdf|doc|docx|xls|xlsx|ppt|pptx|txt)$',
            caseSensitive: false,
          ).hasMatch(url);

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (isImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Image.network(
                      url,
                      height: isMobile ? 100 : 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: isMobile ? 100 : 150,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 14,
                    vertical: 6,
                  ),
                  leading: Icon(
                    isImage
                        ? Icons.image
                        : isVideo
                        ? Icons.videocam
                        : isDocument
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,
                    color: const Color(0xFFFF6949),
                    size: isMobile ? 20 : 24,
                  ),
                  title: Text(
                    fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        _showErrorSnackBar(
                          context,
                          'Cannot open $title file: $fileName',
                        );
                      }
                    } catch (e) {
                      _showErrorSnackBar(
                        context,
                        'Error opening $title file: $e',
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
      ],
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
                style: const TextStyle(color: Colors.white),
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
