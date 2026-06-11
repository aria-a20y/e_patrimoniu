import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  String? _currentSessionId;
  final _msgCtl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  List<ChatMessage> _messages = [];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _createOrLoadSession();
  }

  @override
  void dispose() {
    _msgCtl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOrLoadSession() async {
    final id = await AiService.createSession(_uid);
    setState(() => _currentSessionId = id);
  }

  Future<void> _send() async {
    final text = _msgCtl.text.trim();
    if (text.isEmpty || _currentSessionId == null) return;
    _msgCtl.clear();
    setState(() => _sending = true);

    final userMsg = ChatMessage(
      id: DateTime.now().toString(),
      sessionId: _currentSessionId!,
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() => _messages = [..._messages, userMsg]);
    await AiService.saveMessage(userMsg);
    _scrollToBottom();

    try {
      final response = await AiService.sendMessage(text, _messages);
      final aiMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentSessionId!,
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() => _messages = [..._messages, aiMsg]);
      await AiService.saveMessage(aiMsg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    if (isWide) return _buildWideLayout();
    return _buildNarrowLayout();
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        SizedBox(width: 260, child: _buildSessionsSidebar()),
        Expanded(child: _buildChatArea()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return _buildChatArea();
  }

  Widget _buildSessionsSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createOrLoadSession,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Sesiune nouă', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: StreamBuilder<List<ChatSession>>(
              stream: AiService.getSessions(_uid),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final sessions = snap.data!;
                if (sessions.isEmpty) return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nicio sesiune anterioară', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  ),
                );
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    final isSelected = s.id == _currentSessionId;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentSessionId = s.id;
                          _messages = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.greenPale : null,
                          border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
                        ),
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 16, color: isSelected ? AppTheme.greenEmerald : AppTheme.textGrey),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.title, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppTheme.greenDark : AppTheme.textDark), overflow: TextOverflow.ellipsis),
                            Text(DateFormat('dd.MM HH:mm').format(s.updatedAt), style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
                          ])),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textGrey),
                            onPressed: () async {
                              await AiService.deleteSession(s.id);
                              if (s.id == _currentSessionId) _createOrLoadSession();
                            },
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            padding: EdgeInsets.zero,
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      color: AppTheme.bgGrey,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.smart_toy_rounded, color: AppTheme.greenEmerald, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Asistent e-Patrimoniu', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                Row(children: [
                  CircleAvatar(radius: 4, backgroundColor: AppTheme.successGreen),
                  SizedBox(width: 5),
                  Text('Online', style: TextStyle(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.w500)),
                ]),
              ]),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // Messages
          Expanded(
            child: _currentSessionId == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<ChatMessage>>(
                  stream: AiService.getMessages(_currentSessionId!),
                  builder: (context, snap) {
                    final messages = snap.data ?? [];
                    if (messages.isEmpty) return _buildWelcomeView();
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (_sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == messages.length) return _buildTypingIndicator();
                        return _buildMessageBubble(messages[i]);
                      },
                    );
                  },
                ),
          ),
          // Input
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.smart_toy_rounded, color: AppTheme.greenEmerald, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Asistentul tău e-Patrimoniu', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Pune o întrebare despre bunuri imobiliare, tranzacții, contracte sau licitații.', style: TextStyle(fontSize: 14, color: AppTheme.textGrey, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Ce documente sunt necesare pentru o licitație?',
                'Cum funcționează concesionarea unui bun public?',
                'Care sunt etapele vânzării unui bun din domeniu privat?',
                'Ce este numărul cadastral?',
              ].map((q) => InkWell(
                onTap: () { _msgCtl.text = q; _send(); },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(q, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: AppTheme.greenPale, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppTheme.greenEmerald),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.greenEmerald : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: isUser ? Colors.white : AppTheme.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 15,
              backgroundColor: AppTheme.greenDark,
              child: Text(
                (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                    ? FirebaseAuth.instance.currentUser!.displayName![0] : 'U').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppTheme.greenPale, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_rounded, size: 16, color: AppTheme.greenEmerald),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 4),
              _dot(0), _dot(150), _dot(300),
              const SizedBox(width: 4),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (_, v, __) => Container(
        width: 7, height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppTheme.greenEmerald.withValues(alpha: 0.3 + 0.7 * v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgGrey,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtl,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textDark),
                        decoration: const InputDecoration(
                          hintText: 'Scrieți un mesaj...',
                          hintStyle: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _sending ? AppTheme.borderColor : AppTheme.greenEmerald,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
