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
    int currentPosition = 0;

    try {
      // Sort images by position
      final sortedImages = List<Map<String, dynamic>>.from(images)
        ..sort((a, b) => (a['position'] ?? 0).compareTo(b['position'] ?? 0));

      for (var image in sortedImages) {
        final position = image['position'] as int? ?? 0;

        // Add text before the image
        if (currentPosition < position) {
          final textBeforeImage = content.substring(currentPosition, position);
          if (textBeforeImage.isNotEmpty) {
            widgets.add(
              Text(
                textBeforeImage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            );
          }
        }

        // Add the image
        try {
          if (image['image'] != null) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(image['image']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error_outline, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }
        } catch (e) {
          print('Error decoding content image: $e');
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

        currentPosition = position;
      }

      // Add remaining text
      if (currentPosition < content.length) {
        final remainingText = content.substring(currentPosition);
        if (remainingText.isNotEmpty) {
          widgets.add(
            Text(
              remainingText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.6,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error building content with images: $e');
      // If there's an error, just show the content as plain text
      widgets.add(
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 16,
            height: 1.6,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      );
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
