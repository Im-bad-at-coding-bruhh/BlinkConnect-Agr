import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewsEditorScreen extends StatefulWidget {
  final bool isDarkMode;

  const NewsEditorScreen({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<NewsEditorScreen> createState() => _NewsEditorScreenState();
}

class _NewsEditorScreenState extends State<NewsEditorScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  File? _thumbnailImage;
  final List<Map<String, dynamic>> _contentImages = [];
  bool _isCreatingNews = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      setState(() {
        _thumbnailImage = File(pickedFile.path);
      });
    } catch (e, stackTrace) {
      print('Error in _pickThumbnail: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting thumbnail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addContentImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      setState(() {
        _contentImages.add({
          'path': pickedFile.path,
          'position': _contentController.text.length,
        });
      });
    } catch (e, stackTrace) {
      print('Error in _addContentImage: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeContentImage(int index) {
    if (index >= 0 && index < _contentImages.length) {
      setState(() {
        _contentImages.removeAt(index);
      });
    }
  }

  void _insertImageAtCursor() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      // Get the current cursor position
      final cursorPosition = _contentController.selection.baseOffset;
      // Add double line breaks before and after the image placeholder
      final imagePlaceholder =
          '\n\n[IMAGE_${DateTime.now().millisecondsSinceEpoch}]\n\n';

      if (cursorPosition == -1) {
        // If no cursor position, append to the end
        setState(() {
          _contentController.text = _contentController.text + imagePlaceholder;
          _contentImages.add({
            'path': pickedFile.path,
            'position':
                _contentController.text.length - imagePlaceholder.length,
            'placeholder': imagePlaceholder,
          });
        });
      } else {
        // Insert at cursor position
        final text = _contentController.text;
        final newText = text.substring(0, cursorPosition) +
            imagePlaceholder +
            text.substring(cursorPosition);

        setState(() {
          _contentController.text = newText;
          _contentImages.add({
            'path': pickedFile.path,
            'position': cursorPosition,
            'placeholder': imagePlaceholder,
          });
        });

        // Move cursor after the placeholder
        _contentController.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + imagePlaceholder.length),
        );
      }
    } catch (e, stackTrace) {
      print('Error in _insertImageAtCursor: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createNews() async {
    if (_titleController.text.trim().isEmpty ||
        _summaryController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_thumbnailImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a thumbnail image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingNews = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to create news');
      }

      // Convert thumbnail to base64
      final thumbnailBytes = await _thumbnailImage!.readAsBytes();
      final thumbnailBase64 = base64Encode(thumbnailBytes);

      // Convert content images to base64 and remove placeholders
      final List<Map<String, dynamic>> contentImagesBase64 = [];
      String finalContent = _contentController.text;

      // Debug print
      print('Number of content images: ${_contentImages.length}');
      for (var img in _contentImages) {
        print('Image position: ${img['position']}, path: ${img['path']}');
      }

      // Sort images by position in descending order to maintain correct positions
      final sortedImages = List<Map<String, dynamic>>.from(_contentImages)
        ..sort((a, b) => (b['position'] ?? 0).compareTo(a['position'] ?? 0));

      // Process each image
      for (var image in sortedImages) {
        try {
          final originalPosition = image['position'] as int;
          final placeholder = image['placeholder'] as String;
          final file = File(image['path']);

          if (!await file.exists()) {
            print('File does not exist: ${image['path']}');
            continue;
          }

          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            print('File is empty: ${image['path']}');
            continue;
          }

          final base64Image = base64Encode(bytes);
          contentImagesBase64.add({
            'image': base64Image,
            'position': originalPosition,
            'placeholder': placeholder,
          });
        } catch (e) {
          print('Error processing image: $e');
          print('Image data: $image');
        }
      }

      // Remove all image placeholders from the content
      for (var image in sortedImages) {
        final placeholder = image['placeholder'] as String;
        finalContent = finalContent.replaceAll(placeholder, '');
      }

      // Debug print
      print('Final number of processed images: ${contentImagesBase64.length}');
      for (var img in contentImagesBase64) {
        print(
            'Processed image position: ${img['position']}, has image: ${img['image'] != null}');
      }

      // Create the document data
      final Map<String, dynamic> documentData = {
        'title': _titleController.text.trim(),
        'summary': _summaryController.text.trim(),
        'content': finalContent,
        'thumbnailBase64': thumbnailBase64,
        'contentImages': contentImagesBase64,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Admin',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add the document to Firestore
      await FirebaseFirestore.instance
          .collection('announcements')
          .add(documentData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('News posted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating news: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating news: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingNews = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create News',
          style: GoogleFonts.poppins(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreatingNews ? null : _createNews,
            child: _isCreatingNews
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF6C5DD3)),
                    ),
                  )
                : Text(
                    'Post',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C5DD3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Section
            Text(
              'Thumbnail Image *',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (_thumbnailImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_thumbnailImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickThumbnail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5DD3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.image, color: Colors.white),
              label: Text(
                'Select Thumbnail',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Title *',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter news title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: GoogleFonts.poppins(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Text(
              'Summary *',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter a brief summary (will be shown in the feed)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: GoogleFonts.poppins(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              'Content *',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                TextField(
                  controller: _contentController,
                  maxLines: 10,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText:
                        'Write your news article here...\n\nTip: Press Enter twice to create a new paragraph.\nTip: Place your cursor where you want to insert an image, then click the image button below.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                    height: 1.6,
                    fontSize: 16,
                  ),
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: FloatingActionButton.small(
                    onPressed: _insertImageAtCursor,
                    backgroundColor: const Color(0xFF6C5DD3),
                    child: const Icon(Icons.add_photo_alternate,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Images Preview
            if (_contentImages.isNotEmpty) ...[
              Text(
                'Content Images Preview',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _contentImages.length,
                  itemBuilder: (context, index) {
                    final image = _contentImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(image['path'])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeContentImage(index),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Position: ${image['position']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
