import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Services/auth_provider.dart' as app_auth;

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
  List<Map<String, dynamic>> _contentBlocks = [];
  File? _thumbnailImage;
  bool _isCreatingNews = false;
  final ImagePicker _picker = ImagePicker();
  DateTime? _expiryDateTime;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    for (var block in _contentBlocks) {
      if (block['type'] == 'text') {
        block['controller'].dispose();
      }
    }
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

  Future<void> _addTextBlock() async {
    setState(() {
      _contentBlocks.add({
        'type': 'text',
        'controller': TextEditingController(),
      });
    });
  }

  Future<void> _addImageBlock() async {
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
        _contentBlocks.add({
          'type': 'image',
          'file': File(pickedFile.path),
        });
      });
    } catch (e, stackTrace) {
      print('Error in _addImageBlock: $e');
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

  Future<void> _selectExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _expiryDateTime ?? DateTime.now(),
        ),
      );
      if (pickedTime != null) {
        setState(() {
          _expiryDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createNews() async {
    if (_titleController.text.trim().isEmpty ||
        _summaryController.text.trim().isEmpty ||
        _contentBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields and add content'),
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

      final List<Map<String, String>> contentData = [];
      for (var block in _contentBlocks) {
        if (block['type'] == 'text') {
          contentData.add({
            'type': 'text',
            'data': block['controller'].text.trim(),
          });
        } else if (block['type'] == 'image') {
          final imageBytes = await (block['file'] as File).readAsBytes();
          final imageBase64 = base64Encode(imageBytes);
          contentData.add({
            'type': 'image',
            'data': imageBase64,
          });
        }
      }

      // Get username directly from Firestore (like dashboard)
      String? authorName;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        authorName = userDoc.data()?['username'] as String?;
      } catch (e) {
        // ignore, fallback below
      }
      authorName = (authorName != null && authorName.isNotEmpty)
          ? authorName
          : (user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName
              : (user.email != null && user.email!.isNotEmpty)
                  ? user.email!.split('@')[0]
                  : 'Admin';

      // Create the document data
      final Map<String, dynamic> documentData = {
        'title': _titleController.text.trim(),
        'summary': _summaryController.text.trim(),
        'content': contentData,
        'thumbnailBase64': thumbnailBase64,
        'authorId': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_expiryDateTime != null) {
        documentData['expiresAt'] = Timestamp.fromDate(_expiryDateTime!);
      }

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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contentBlocks.length,
                itemBuilder: (context, index) {
                  final block = _contentBlocks[index];
                  Widget content;
                  if (block['type'] == 'text') {
                    content = TextField(
                      controller: block['controller'],
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Enter text content...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    );
                  } else if (block['type'] == 'image') {
                    content = Image.file(block['file'] as File);
                  } else {
                    content = const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: content,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              if (block['type'] == 'text') {
                                block['controller'].dispose();
                              }
                              _contentBlocks.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTextBlock,
                  icon: const Icon(Icons.text_fields, color: Colors.white),
                  label: Text('Add Text',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5DD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addImageBlock,
                  icon: const Icon(Icons.add_photo_alternate,
                      color: Colors.white),
                  label: Text('Add Image',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5DD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expiry Date
            Text(
              'Auto-delete Date (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectExpiryDate,
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text('Select Date',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5DD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_expiryDateTime != null)
                  Expanded(
                    child: Text(
                      'Expires: ${_expiryDateTime!.toLocal().toString().substring(0, 16)}',
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
