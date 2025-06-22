import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticleScreen extends StatefulWidget {
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
  State<NewsArticleScreen> createState() => _NewsArticleScreenState();
}

class _NewsArticleScreenState extends State<NewsArticleScreen> {
  @override
  Widget build(BuildContext context) {
    List<Widget> contentWidgets = [];
    if (widget.article['content'] is List) {
      (widget.article['content'] as List).forEach((block) {
        if (block['type'] == 'text') {
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                block['data'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          );
        } else if (block['type'] == 'image' && block['data'] != null) {
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.memory(
                base64Decode(block['data']),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      });
    } else if (widget.article['content'] is String) {
      // Fallback for old string content
      contentWidgets.add(
        Text(
          widget.article['content'] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 16,
            height: 1.6,
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildArticleHeader(),
                  const SizedBox(height: 24),
                  ...contentWidgets,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildThumbnail(),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (widget.onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              widget.onDelete?.call();
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  Widget _buildArticleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.article['title'] ?? 'Untitled',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              'Posted by ${widget.article['authorName'] ?? 'Unknown'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.article['createdAt']),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    try {
      if (widget.article['thumbnailBase64'] != null) {
        final decodedBytes = base64Decode(widget.article['thumbnailBase64']);
        if (decodedBytes.isNotEmpty) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(decodedBytes),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
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

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return 'Unknown date';

    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is DateTime) {
      date = createdAt;
    } else {
      return 'Invalid date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
