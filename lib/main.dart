
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Deep navy blue
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF29B6F6),
          surface: const Color(0xFFE3F2FD),
          background: const Color(0xFFE3F2FD),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Deep navy blue
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF29B6F6),
          surface: const Color(0xFF102841),
          background: const Color(0xFF071A2F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF071A2F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessageData> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late AnimationController _typingController;
  
  // Your API key is hardcoded here
  String _apiKey = 'your precious api key';

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    // Add welcome message after a short delay
    Future.delayed(Duration(milliseconds: 300), () {
      _addBotMessage("Hello! I'm your Gemini AI assistant. How can I help you today?");
    });
  }
  
  @override
  void dispose() {
    _typingController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    
    // Dispose all animation controllers
    for (final message in _messages) {
      message.animationController.dispose();
    }
    
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();
    
    if (text.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessageData(
      text: text,
      isUser: true,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      )..forward(),
      isTyping: false,
    );
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    try {
      final response = await _getGeminiResponse(text);
      _addBotMessage(response);
    } catch (e) {
      _addBotMessage("Sorry, I couldn't process that request. ${e.toString()}");
    }
    
    setState(() {
      _isLoading = false;
    });
    
    _scrollToBottom();
  }
  
  void _addBotMessage(String message) {
    final botMessage = ChatMessageData(
      text: message,
      isUser: false,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      )..forward(),
      isTyping: true,
      typingDuration: Duration(milliseconds: message.length * 20), // Adjust typing speed
    );
    
    setState(() {
      _messages.add(botMessage);
    });
    
    // After typing animation completes, set isTyping to false
    Future.delayed(botMessage.typingDuration, () {
      if (mounted) {
        setState(() {
          botMessage.isTyping = false;
        });
      }
    });
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _getGeminiResponse(String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$_apiKey'
    );
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to get response: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Chat')
          .animate()
          .fadeIn(duration: 500.ms)
          .slide(begin: const Offset(0, -0.5), duration: 500.ms),
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF071A2F), const Color(0xFF102841)]
              : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        )
                        .animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        )
                        .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1500.ms)
                        .then()
                        .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 1500.ms),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 1000.ms)
                        .slide(),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (_, int index) => ChatMessage(data: _messages[index]),
                  ),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDot(0),
                      _buildDot(1),
                      _buildDot(2),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A2547) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? const Color(0xFF102841) 
                              : const Color(0xFFE3F2FD),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: _isLoading ? null : _handleSubmitted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isLoading 
                          ? null 
                          : () => _handleSubmitted(_textController.text),
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      child: const Icon(Icons.send),
                    ).animate()
                     .scaleXY(begin: 0.8, end: 1, duration: 300.ms, curve: Curves.elasticOut)
                     .shimmer(delay: 300.ms, duration: 1800.ms),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(
          (0.2 * index + _typingController.value) % 1.0
        );
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 8 + (value * 4),
          width: 8 + (value * 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6 + (value * 0.4)),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      },
    );
  }
}

class ChatMessageData {
  final String text;
  final bool isUser;
  final AnimationController animationController;
  bool isTyping;
  final Duration typingDuration;
  
  ChatMessageData({
    required this.text,
    required this.isUser,
    required this.animationController,
    this.isTyping = false,
    this.typingDuration = const Duration(milliseconds: 2000),
  });
}

class ChatMessage extends StatefulWidget {
  final ChatMessageData data;

  const ChatMessage({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  late String _visibleText;
  late int _characterCount;
  late Duration _typingDuration;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _visibleText = widget.data.isUser ? widget.data.text : '';
    _characterCount = 0;
    _typingDuration = widget.data.typingDuration;
    
    // For user messages, show text immediately
    // For bot messages, simulate typing
    if (!widget.data.isUser && widget.data.isTyping) {
      _startTypingAnimation();
    }
  }
  
  @override
  void didUpdateWidget(ChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // When isTyping changes, update animation
    if (oldWidget.data.isTyping != widget.data.isTyping) {
      if (widget.data.isTyping) {
        _startTypingAnimation();
      } else {
        _stopTypingAnimation();
        setState(() {
          _visibleText = widget.data.text;
        });
      }
    }
  }
  
  void _startTypingAnimation() {
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }
    
    final text = widget.data.text;
    final charCount = text.length;
    
    if (charCount == 0) return;
    
    // Calculate time per character based on total duration
    final timePerChar = _typingDuration.inMilliseconds / charCount;
    
    _typingTimer = Timer.periodic(Duration(milliseconds: timePerChar.round()), (timer) {
      if (_characterCount < charCount) {
        setState(() {
          _characterCount++;
          _visibleText = text.substring(0, _characterCount);
        });
      } else {
        _stopTypingAnimation();
      }
    });
  }
  
  void _stopTypingAnimation() {
    _typingTimer?.cancel();
    _typingTimer = null;
  }
  
  @override
  void dispose() {
    _stopTypingAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = widget.data.isUser;
    
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: widget.data.animationController, 
        curve: Curves.easeOutQuad,
      ),
      child: FadeTransition(
        opacity: widget.data.animationController,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(isUser ? 0.2 : -0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: widget.data.animationController,
            curve: Curves.easeOutQuad,
          )),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.smart_toy,
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? const Color(0xFF1976D2) 
                          : isDark 
                              ? const Color(0xFF0D47A1) 
                              : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 16 : 4),
                        topRight: Radius.circular(isUser ? 4 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      gradient: isUser 
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1976D2),
                                const Color(0xFF0D47A1),
                              ],
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Stack(
                      children: [
                        SelectableText(
                          _visibleText,
                          style: TextStyle(
                            color: isUser 
                                ? Colors.white
                                : isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (widget.data.isTyping && !isUser)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF29B6F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ).animate(
                              onPlay: (controller) => controller.repeat(reverse: true),
                            ).fadeOut(duration: 600.ms),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isUser)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF29B6F6),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

