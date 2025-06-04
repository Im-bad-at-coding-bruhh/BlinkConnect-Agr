import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticleScreen extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool isDarkMode;
  final VoidCallback? onDelete;

  const NewsArticleScreen({
    Key? key,
    required this.article,
    required this.isDarkMode,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('=== Article Debug Info ===');
    print('Article title: ${article['title']}');
    print('Content length: ${article['content']?.length ?? 0}');
    print('Number of images: ${article['contentImages']?.length ?? 0}');
    if (article['contentImages'] != null) {
      for (var i = 0; i < article['contentImages'].length; i++) {
        final image = article['contentImages'][i];
        print('Image $i:');
        print('  - Position: ${image['position']}');
        print('  - Has placeholder: ${image['placeholder'] != null}');
        print('  - Has image data: ${image['image'] != null}');
        if (image['image'] != null) {
          print('  - Image data length: ${image['image'].length}');
        }
      }
    }
    print('========================');

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildThumbnail(),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    onDelete?.call();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article['title'] ?? 'Untitled',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author and Date
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Posted by ${article['authorName'] ?? 'Unknown'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(article['createdAt']),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content with embedded images
                  _buildContentWithImages(
                    article['content'] ?? '',
                    article['contentImages'] ?? [],
                    isDarkMode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    try {
      if (article['thumbnailBase64'] != null) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: MemoryImage(
                base64Decode(article['thumbnailBase64']),
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error decoding thumbnail: $e');
    }

    return Container(
      color: const Color(0xFF6C5DD3),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContentWithImages(
    String content,
    List<dynamic> images,
    bool isDarkMode,
  ) {
    final List<Widget> widgets = [];

    try {
      print('=== Building Content ===');
      print('Content: $content');
      print('Images: $images');

      // First, split the content into paragraphs
      final paragraphs = content.split('\n\n');
      print('Number of paragraphs: ${paragraphs.length}');

      // Process each paragraph
      for (var i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i].trim();
        if (paragraph.isEmpty) continue;

        print('Processing paragraph $i: $paragraph');

        // Check if this paragraph contains any image placeholders
        bool hasImage = false;
        for (var image in images) {
          final placeholder = image['placeholder']?.toString().trim() ?? '';
          print('Checking image placeholder: "$placeholder"');
          if (placeholder.isNotEmpty && paragraph.contains(placeholder)) {
            print('Found image placeholder in paragraph');

            // Split the paragraph at the image placeholder
            final parts = paragraph.split(placeholder);
            print('Split into ${parts.length} parts');

            // Add text before the image
            if (parts[0].trim().isNotEmpty) {
              print('Adding text before image: ${parts[0].trim()}');
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    parts[0].trim(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.6,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            // Add the image
            try {
              if (image['image'] != null) {
                print(
                    'Adding image with data length: ${image['image'].length}');
                final imageBytes = base64Decode(image['image']);
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              } else {
                print('Image data is null for placeholder: $placeholder');
              }
            } catch (e) {
              print('Error decoding image: $e');
              widgets.add(
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.red),
                  ),
                ),
              );
            }

            // Add text after the image
            if (parts.length > 1 && parts[1].trim().isNotEmpty) {
              print('Adding text after image: ${parts[1].trim()}');
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    parts[1].trim(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.6,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            hasImage = true;
            break;
          }
        }

        // If no image was found in this paragraph, add it as plain text
        if (!hasImage) {
          print('Adding paragraph as plain text: $paragraph');
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                paragraph,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          );
        }
      }

      print('=== Finished Building Content ===');
      print('Total widgets created: ${widgets.length}');
    } catch (e) {
      print('Error building content with images: $e');
      print(e.toString());
      // If there's an error, just show the content as plain text
      final paragraphs = content.split('\n\n');
      for (var i = 0; i < paragraphs.length; i++) {
        if (paragraphs[i].trim().isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                paragraphs[i].trim(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown date';
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown date';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown date';
    }
  }
}
