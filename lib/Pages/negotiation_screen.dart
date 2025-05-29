import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/negotiation_service.dart';
import '../Models/negotiation_model.dart';
import '../Services/auth_service.dart';
import 'theme_provider.dart';

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
        automaticallyImplyLeading: false,
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
                return const Center(child: Text('No Active Negotiations'));
              }

              return ListView.builder(
                itemCount: activeBids.length,
                itemBuilder: (context, index) {
                  final bid = activeBids[index];
                  final isSeller = bid.sellerId == currentUser.uid;
                  final isBuyer = bid.buyerId == currentUser.uid;

                  // Get the last message
                  final lastMessage = bid.messages.entries
                      .map((e) => e.value as Map<String, dynamic>)
                      .toList()
                    ..sort((a, b) {
                      final aTime = (a['timestamp'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;
                      final bTime = (b['timestamp'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;
                      return bTime.compareTo(aTime);
                    });

                  final lastMessageText = lastMessage.isNotEmpty
                      ? lastMessage.first['message'] as String
                      : 'No messages yet';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    bid.productName,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
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
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Bid Amount: \$${bid.bidAmount}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Quantity: ${bid.quantity} units',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessageText,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastMessage.isNotEmpty)
                                  Text(
                                    _formatTimestamp(lastMessage
                                        .first['timestamp'] as Timestamp),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
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
                return const Center(child: Text('No Negotiation History'));
              }

              return ListView.builder(
                itemCount: historyBids.length,
                itemBuilder: (context, index) {
                  final bid = historyBids[index];
                  final isSeller = bid.sellerId == currentUser.uid;
                  final isBuyer = bid.buyerId == currentUser.uid;

                  // Get the last message
                  final lastMessage = bid.messages.entries
                      .map((e) => e.value as Map<String, dynamic>)
                      .toList()
                    ..sort((a, b) {
                      final aTime = (a['timestamp'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;
                      final bTime = (b['timestamp'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;
                      return bTime.compareTo(aTime);
                    });

                  final lastMessageText = lastMessage.isNotEmpty
                      ? lastMessage.first['message'] as String
                      : 'No messages yet';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    bid.productName,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
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
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Bid Amount: \$${bid.bidAmount}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Quantity: ${bid.quantity} units',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessageText,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastMessage.isNotEmpty)
                                  Text(
                                    _formatTimestamp(lastMessage
                                        .first['timestamp'] as Timestamp),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
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

class NegotiationDetailScreen extends StatefulWidget {
  final Negotiation bid;
  final bool isSeller;

  const NegotiationDetailScreen({
    Key? key,
    required this.bid,
    required this.isSeller,
  }) : super(key: key);

  @override
  State<NegotiationDetailScreen> createState() =>
      _NegotiationDetailScreenState();
}

class _NegotiationDetailScreenState extends State<NegotiationDetailScreen> {
  final NegotiationService _negotiationService = NegotiationService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _counterAmountController =
      TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _counterAmountController.dispose();
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

  void _showCounterOfferDialog(BuildContext context, Negotiation bid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Make Counter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _counterAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Counter Offer Amount',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _messageController.clear();
              _counterAmountController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final counterAmount =
                  double.tryParse(_counterAmountController.text);
              if (counterAmount != null) {
                try {
                  await _negotiationService.updateBidStatus(
                    bidId: widget.bid.id,
                    status: 'countered',
                    message: _messageController.text.isEmpty
                        ? 'Counter offer of \$$counterAmount for ${widget.bid.quantity} units'
                        : _messageController.text,
                    counterAmount: counterAmount,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _messageController.clear();
                    _counterAmountController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Counter offer sent successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBidStatus(String bidId, String status) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'accepted' ? 'Accept Bid' : 'Reject Bid'),
        content: Text(
          status == 'accepted'
              ? 'Are you sure you want to accept this bid? The product will be added to the buyer\'s cart.'
              : 'Are you sure you want to reject this bid? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: status == 'accepted' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'accepted' ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _negotiationService.updateBidStatus(
        bidId: bidId,
        status: status,
        message: status == 'accepted'
            ? 'Bid accepted'
            : status == 'rejected'
                ? 'Bid rejected'
                : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bid ${status} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isCurrentUser) {
    final timestamp = message['timestamp'] as Timestamp?;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? const Color(0xFF6C5DD3)
              : (isDarkMode ? const Color(0xFF0A0A18) : Colors.grey[300]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['message'] as String,
              style: TextStyle(
                color: isCurrentUser
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            if (message['price'] != null)
              Text(
                'Price: \$${message['price']}',
                style: TextStyle(
                  color: isCurrentUser
                      ? Colors.white70
                      : (isDarkMode ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser
                      ? Colors.white70
                      : (isDarkMode ? Colors.white54 : Colors.black54),
                ),
              ),
          ],
        ),
      ),
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
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(widget.bid.productName),
        backgroundColor:
            isDarkMode ? const Color(0xFF0A0A18) : const Color(0xFFCCE0CC),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('bids')
            .doc(widget.bid.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final updatedBid = Negotiation.fromMap(snapshot.data!.id, data);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF0A0A18) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: isDarkMode
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF6C5DD3).withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 5,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  updatedBid.productName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                _buildStatusChip(updatedBid.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Original Price: \$${updatedBid.originalPrice}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'Bid Amount: \$${updatedBid.bidAmount}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              'Quantity: ${updatedBid.quantity} units',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sort messages by timestamp and display in chronological order
                    ...(() {
                      final sortedMessages =
                          updatedBid.messages.entries.toList()
                            ..sort((a, b) {
                              final aTime = (a.value['timestamp'] as Timestamp?)
                                      ?.millisecondsSinceEpoch ??
                                  0;
                              final bTime = (b.value['timestamp'] as Timestamp?)
                                      ?.millisecondsSinceEpoch ??
                                  0;
                              return aTime.compareTo(bTime);
                            });

                      return sortedMessages.map((entry) {
                        final message = entry.value as Map<String, dynamic>;
                        final isCurrentUser =
                            message['senderId'] == currentUser.uid;
                        return _buildMessageBubble(message, isCurrentUser);
                      });
                    })(),
                  ],
                ),
              ),
              if (updatedBid.status == 'pending' && widget.isSeller)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _updateBidStatus(updatedBid.id, 'rejected'),
                        child: const Text('Reject'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showCounterOfferDialog(context, updatedBid),
                        child: const Text('Counter'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _updateBidStatus(updatedBid.id, 'accepted'),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                )
              else if (updatedBid.status == 'countered')
                Builder(
                  builder: (context) {
                    // Get the last message to determine whose turn it is
                    final lastMessage = updatedBid.messages.entries
                        .map((e) => e.value as Map<String, dynamic>)
                        .toList()
                      ..sort((a, b) {
                        final aTime = (a['timestamp'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0;
                        final bTime = (b['timestamp'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0;
                        return bTime.compareTo(aTime);
                      });

                    if (lastMessage.isEmpty) return const SizedBox.shrink();

                    final lastSenderId =
                        lastMessage.first['senderId'] as String;
                    final isLastSenderCurrentUser =
                        lastSenderId == currentUser.uid;

                    // Only show buttons if it's the user's turn (last message was from the other person)
                    if (!isLastSenderCurrentUser)
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _updateBidStatus(updatedBid.id, 'rejected'),
                              child: const Text('Reject'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _showCounterOfferDialog(context, updatedBid),
                              child: const Text('Counter'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _updateBidStatus(updatedBid.id, 'accepted'),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      );
                    return const SizedBox.shrink();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
