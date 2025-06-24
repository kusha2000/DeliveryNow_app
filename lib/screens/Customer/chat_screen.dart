// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/services/firebase_services.dart';

class ChatScreen extends StatefulWidget {
  final String? customerId;
  final String? customerName;
  final String? orderId;
  final bool isCustomer;

  const ChatScreen({
    Key? key,
    this.customerId,
    this.customerName,
    this.orderId,
    this.isCustomer = false,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseServices _firebaseServices = FirebaseServices();

  late AnimationController _notificationAnimationController;
  late AnimationController _quickReplyAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _showNotificationCard = false;
  bool _showQuickReplies = false;
  DateTime? _selectedRescheduleDate;
  Map<String, dynamic>? _notificationData;
  bool _isPlayingTts = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchNotification();
  }

  void _initializeAnimations() {
    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _quickReplyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _notificationAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _notificationAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _fetchNotification() async {
    if (widget.orderId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('parcel_tracking_number', isEqualTo: widget.orderId)
          .where('isclosed', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _notificationData = querySnapshot.docs.first.data();
          _notificationData!['notificationId'] = querySnapshot.docs.first.id;
          _showNotificationCard = true;
        });
        _notificationAnimationController.forward();
        _sendNotificationMessage();
      }
    } catch (e) {
      print('Error fetching notification: $e');
    }
  }

  Future<void> _sendNotificationMessage() async {
    if (_notificationData == null) return;

    final notificationText =
        _notificationData!['notification_text'] ?? 'New delivery assigned';

    await _sendMessage(
      message: notificationText,
      isSystem: true,
      messageType: 'notification',
    );

    // Show quick reply buttons for customers only after a delay
    if (widget.isCustomer) {
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _showQuickReplies = true;
          });
          _quickReplyAnimationController.forward();
        }
      });
    }
  }

  Future<void> _sendMessage({
    required String message,
    bool isSystem = false,
    String messageType = 'text',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _firebaseServices.getCurrentUser();
      if (currentUser == null) return;

      // Fix the logic for setting customerId and receiverId
      String customerId;
      String receiverId;

      if (widget.isCustomer) {
        // Customer is sending message
        customerId = currentUser.uid; // Customer's ID
        receiverId = _notificationData != null
            ? _notificationData!['riderId'] ?? 'unknown'
            : 'unknown'; // Rider's ID
      } else {
        // Staff/Rider is sending message
        customerId =
            widget.customerId ?? 'unknown'; // Customer's ID from widget
        receiverId = widget.customerId ?? 'unknown'; // Customer's ID (receiver)
      }

      final chatData = {
        'message': message,
        'senderId': isSystem ? 'system' : currentUser.uid,
        'senderType':
            isSystem ? 'system' : (widget.isCustomer ? 'customer' : 'rider'),
        'receiverId': receiverId,
        'receiverType': widget.isCustomer ? 'rider' : 'customer',
        'customerId': customerId,
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': messageType,
        'orderId': widget.orderId,
        'isRead': false,
        'additionalData': additionalData,
      };

      print('Sending message with data: $chatData'); // Debug log

      await FirebaseFirestore.instance.collection('chats').add(chatData);

      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _showQuickReplies = false;
    });

    await _sendMessage(
      message:
          "✅ Delivery confirmed! Thank you for scheduling. I confirm the delivery for the proposed date and time.",
      messageType: 'confirmation',
    );

    // Update notification status
    if (_notificationData != null) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(_notificationData!['notificationId'])
          .update({'isclosed': true});
    }

    setState(() {
      _showNotificationCard = false;
    });
    _notificationAnimationController.reverse();
  }

  Future<void> _handleRescheduleRequest() async {
    await _showDatePicker();
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.cardColor,
              onSurface: AppColors.textPrimaryColor,
              background: AppColors.backgroundColor,
              onBackground: AppColors.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRescheduleDate = picked;
        _showQuickReplies = false;
      });

      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      await _sendMessage(
        message:
            "📅 Reschedule requested: Can we please reschedule the delivery to $formattedDate? Awaiting your confirmation.",
        messageType: 'reschedule_request',
        additionalData: {
          'requestedDate': picked.toIso8601String(),
          'formattedDate': formattedDate,
        },
      );

      // Update notification status
      if (_notificationData != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(_notificationData!['notificationId'])
            .update({'isclosed': true});
      }

      setState(() {
        _showNotificationCard = false;
      });
      _notificationAnimationController.reverse();
    }
  }

  Future<void> _handleApproveReschedule(
      Map<String, dynamic> messageData) async {
    final additionalData =
        messageData['additionalData'] as Map<String, dynamic>?;
    if (additionalData == null) return;

    final requestedDate = DateTime.parse(additionalData['requestedDate']);
    final formattedDate = additionalData['formattedDate'];

    await _sendMessage(
      message:
          "✅ Reschedule approved: Delivery rescheduled to $formattedDate. Thank you!",
      messageType: 'reschedule_approved',
    );

    // Update delivery date in Firestore
    await FirebaseFirestore.instance
        .collection('deliveries')
        .where('packageId', isEqualTo: widget.orderId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({
          'assignedDate': Timestamp.fromDate(requestedDate),
        });
      }
    });
  }

  Future<void> _handleAskAnotherDate(Map<String, dynamic> messageData) async {
    await _sendMessage(
      message:
          "📅 Please suggest another date: The requested date is not suitable. Could you please provide alternative dates for delivery?",
      messageType: 'ask_another_date',
    );
  }

  Future<void> _handleRejectReschedule(Map<String, dynamic> messageData) async {
    await _sendMessage(
      message:
          "❌ Reschedule rejected: Unfortunately, we cannot accommodate the reschedule request. The original delivery date remains unchanged.",
      messageType: 'reschedule_rejected',
    );
  }

  Widget _buildInlineMiniNotificationCard() {
    if (_notificationData == null) return SizedBox.shrink();

    final notificationText =
        _notificationData!['notification_text'] ?? 'New delivery assigned';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: 4,
        color: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(0.15),
                AppColors.cardColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Notification',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          'Package #${_notificationData!['parcel_tracking_number'] ?? widget.orderId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notificationText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _isPlayingTts
                                ? Icons.stop_circle
                                : Icons.play_circle,
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _notificationData!['customer_name'] ??
                              widget.customerName ??
                              'Customer',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _notificationData!['delivery_date'] ?? 'Today',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    if (!_showQuickReplies || !widget.isCustomer) return SizedBox.shrink();

    return AnimatedBuilder(
      animation: _quickReplyAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _quickReplyAnimationController.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleConfirm,
                    icon: Icon(Icons.check_circle,
                        size: 18, color: AppColors.whiteColor),
                    label: Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: AppColors.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleRescheduleRequest,
                    icon: Icon(Icons.schedule,
                        size: 18, color: AppColors.whiteColor),
                    label: Text('Reschedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningColor,
                      foregroundColor: AppColors.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRescheduleActionButtons(Map<String, dynamic> messageData) {
    return Container(
      margin: EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reschedule Actions:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _handleApproveReschedule(messageData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: AppColors.whiteColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: AppColors.whiteColor),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Approve',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _handleAskAnotherDate(messageData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningColor,
                      foregroundColor: AppColors.whiteColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range,
                            size: 16, color: AppColors.whiteColor),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Another Date',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _handleRejectReschedule(messageData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorColor,
                      foregroundColor: AppColors.whiteColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel,
                            size: 16, color: AppColors.whiteColor),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Reject',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> messageData) {
    final isMe =
        messageData['senderType'] == (widget.isCustomer ? 'customer' : 'rider');
    final isSystem = messageData['senderType'] == 'system';
    final isNotification = messageData['messageType'] == 'notification';
    final isRescheduleRequest =
        messageData['messageType'] == 'reschedule_request' &&
            !widget.isCustomer;
    final message = messageData['message'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final orderId = messageData['orderId'] ?? '';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isSystem
            ? CrossAxisAlignment.center
            : isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        children: [
          if (orderId.isNotEmpty && !isSystem && widget.isCustomer) ...[
            Container(
              margin: EdgeInsets.only(bottom: 4),
              child: Text(
                'Order: $orderId',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (isNotification && isSystem) ...[
            _buildInlineMiniNotificationCard(),
            SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: isSystem
                ? MainAxisAlignment.center
                : isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [
              if (!isMe && !isSystem) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSystem
                        ? AppColors.surfaceColor
                        : isMe
                            ? AppColors.primaryColor
                            : AppColors.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe
                              ? AppColors.whiteColor
                              : AppColors.textPrimaryColor,
                          fontSize: 14,
                        ),
                      ),
                      if (timestamp != null) ...[
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            color: isMe
                                ? AppColors.whiteColor.withOpacity(0.7)
                                : AppColors.textSecondaryColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.delivery_dining,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ],
          ),
          if (isRescheduleRequest) _buildRescheduleActionButtons(messageData),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _notificationAnimationController.dispose();
    _quickReplyAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.whiteColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: AppColors.whiteColor,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isCustomer
                        ? 'Support Chat'
                        : (widget.customerName ?? 'Customer'),
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.isCustomer
                        ? 'Order #${widget.orderId ?? 'N/A'}'
                        : 'Online',
                    style: TextStyle(
                      color: AppColors.whiteColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.phone, color: AppColors.whiteColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('orderId', isEqualTo: widget.orderId)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: AppColors.textPrimaryColor),
                    ),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textMutedColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Start a conversation!',
                          style: TextStyle(
                            color: AppColors.textMutedColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    return _buildMessage(messageData);
                  },
                );
              },
            ),
          ),
          _buildQuickReplies(),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: AppColors.textPrimaryColor),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppColors.textMutedColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final message = _messageController.text.trim();
                      if (message.isNotEmpty) {
                        _messageController.clear();
                        await _sendMessage(message: message);
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
