import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/negotiation_service.dart';
import '../Models/negotiation_model.dart';
import '../Services/auth_service.dart';
import 'theme_provider.dart';
import 'negotiation_detail_screen.dart';

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({Key? key}) : super(key: key);

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen>
    with SingleTickerProviderStateMixin {
  final NegotiationService _negotiationService = NegotiationService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'countered':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view negotiations')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Negotiations'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C5DD3),
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
          indicatorColor: const Color(0xFF6C5DD3),
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_cart_rounded),
              text: 'Active Bids',
            ),
            Tab(
              icon: Icon(Icons.history_rounded),
              text: 'History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<Negotiation>>(
            stream: _negotiationService.getBids(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final bids = snapshot.data ?? [];
              final activeBids = bids
                  .where((bid) =>
                      bid.status == 'pending' || bid.status == 'countered')
                  .toList();

              if (activeBids.isEmpty) {
                return Center(
                  child: Text(
                    'No Active Negotiations',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: activeBids.length,
                itemBuilder: (context, index) {
                  final bid = activeBids[index];
                  final isSeller = bid.sellerId == currentUser.uid;

                  // Get message maps from the values of the messages map
                  final messages = bid.messages.values.toList();

                  messages.sort((a, b) {
                    final aTime = (a['timestamp'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    final bTime = (b['timestamp'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    return bTime.compareTo(aTime);
                  });

                  final lastMessageText = messages.isNotEmpty
                      ? messages.first['message'] as String
                      : 'No messages yet';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDarkMode ? const Color(0xFF0A0A18) : Colors.white,
                    elevation: isDarkMode ? 8 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isDarkMode
                          ? const BorderSide(color: Colors.white54, width: 0.8)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NegotiationDetailScreen(
                              bid: bid,
                              isSeller: isSeller,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    bid.productName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStatusChip(bid.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Original Price: \$${bid.originalPrice}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'Bid Amount: \$${bid.bidAmount}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'Quantity: ${bid.quantity} units',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessageText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (messages.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(messages.first['timestamp']
                                        as Timestamp),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          StreamBuilder<List<Negotiation>>(
            stream: _negotiationService.getBids(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final bids = snapshot.data ?? [];
              final historyBids = bids
                  .where((bid) =>
                      bid.status == 'accepted' || bid.status == 'rejected')
                  .toList();

              if (historyBids.isEmpty) {
                return Center(
                  child: Text(
                    'No Negotiation History',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: historyBids.length,
                itemBuilder: (context, index) {
                  final bid = historyBids[index];
                  final isSeller = bid.sellerId == currentUser.uid;

                  // Get message maps from the values of the messages map
                  final messages = bid.messages.values.toList();

                  messages.sort((a, b) {
                    final aTime = (a['timestamp'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    final bTime = (b['timestamp'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    return bTime.compareTo(aTime);
                  });

                  final lastMessageText = messages.isNotEmpty
                      ? messages.first['message'] as String
                      : 'No messages yet';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDarkMode ? const Color(0xFF0A0A18) : Colors.white,
                    elevation: isDarkMode ? 8 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isDarkMode
                          ? const BorderSide(color: Colors.white54, width: 0.8)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NegotiationDetailScreen(
                              bid: bid,
                              isSeller: isSeller,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    bid.productName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStatusChip(bid.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Original Price: \$${bid.originalPrice}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'Bid Amount: \$${bid.bidAmount}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'Quantity: ${bid.quantity} units',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessageText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (messages.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(messages.first['timestamp']
                                        as Timestamp),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
