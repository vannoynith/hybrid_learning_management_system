import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hybridlms/models/course.dart';
import 'file_preview_page.dart'; // Import the new preview page

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
                style: GoogleFonts.poppins(
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
                vertical: 24,
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Thumbnail Section
                      if (course.thumbnailUrl != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Thumbnail',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : 22,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                course.thumbnailUrl!,
                                height: isMobile ? 150 : 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: isMobile ? 150 : 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Text(
                                          'Thumbnail failed to load',
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      // Course Description Section
                      if (course.description != null &&
                          course.description!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Description',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : 22,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.description!,
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      // Course Content Section
                      Text(
                        'Course Content',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 20 : 24,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      if (course.modules == null || course.modules!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No content available.',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
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
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  module['name']?.toString() ??
                                      'Unnamed Module',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 16 : 18,
                                    color: const Color(0xFFFF6949),
                                  ),
                                ),
                                initiallyExpanded: moduleIndex == 0,
                                tilePadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 20,
                                  vertical: 8,
                                ),
                                childrenPadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 20,
                                  vertical: 8,
                                ),
                                children: [
                                  // Module Description
                                  if (module['description'] != null &&
                                      module['description'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        module['description'],
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  if (module['lessons'] == null ||
                                      (module['lessons'] as List).isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'No lessons available.',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
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
                                        return Card(
                                          elevation: 1,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              isMobile ? 12 : 16,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lesson['name']?.toString() ??
                                                      'Unnamed Lesson',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize:
                                                        isMobile ? 16 : 18,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                if (lesson['text'] != null &&
                                                    (lesson['text'] as String)
                                                        .isNotEmpty)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Lesson Text',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  isMobile
                                                                      ? 14
                                                                      : 16,
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        lesson['text'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize:
                                                                  isMobile
                                                                      ? 14
                                                                      : 16,
                                                              color:
                                                                  Colors
                                                                      .grey[800],
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
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
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final url = urls[index];
            final fileName = url.toString().split('/').last;
            final isImage = RegExp(
              r'\.(jpg|jpeg|png|gif|bmp|webp)$',
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 8,
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
                  size: isMobile ? 24 : 28,
                ),
                title: Text(
                  fileName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFF6949),
                  size: 20,
                ),
                onTap: () async {
                  try {
                    print('Navigating to preview for URL: $url');
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FilePreviewPage(),
                        settings: RouteSettings(
                          arguments: {'url': url, 'fileName': fileName},
                        ),
                      ),
                    );
                  } catch (e) {
                    _showErrorSnackBar(
                      context,
                      'Error navigating to preview: $e',
                    );
                  }
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
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
