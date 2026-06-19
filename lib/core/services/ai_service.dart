import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatSession {
  final String id;
  final String userId;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}

class AiService {
  // Stocare in-memory pentru sesiuni și mesaje chat
  static final List<ChatSession> _sessions = [];
  static final List<ChatMessage> _messages = [];

  // ===================================================================
  // NOTĂ: Înlocuiește cu cheia ta API Gemini
  // Configurare: https://aistudio.google.com/app/apikey
  // ===================================================================
  static const String _apiKey = 'INSEREAZA_CHEIA_TA_API_GEMINI_AICI';

  static const String _systemPrompt = '''
Ești Asistentul e-Patrimoniu, un asistent digital specializat în evidența bunurilor imobiliare ale unităților administrativ-teritoriale din România.

Poți ajuta cu:
- Informații despre bunuri imobiliare (terenuri, clădiri, spații)
- Explicarea proceselor de tranzacții imobiliare (vânzare, închiriere, concesionare, dare în administrare)
- Informații despre contracte și licitații
- Explicarea documentelor necesare (HCL, extras carte funciară, plan cadastral)
- Legislație aplicabilă patrimoniului public și privat al UAT-urilor
- Proceduri administrative

Important:
- Ești DOAR informativ. Nu modifici date, nu creezi sau ștergi înregistrări.
- Răspunde ÎNTOTDEAUNA în limba română.
- Dacă nu știi răspunsul, spune că nu știi.
- Fii concis și precis.
- Când dai exemple de valori monetare, folosește RON.
''';

  /// Trimite mesaj și primește răspuns de la Gemini
  static Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> history,
  ) async {
    try {
      // Construim istoricul conversației
      final contents = <Map<String, dynamic>>[];

      // Adăugăm istoricul anterior (ultimele 10 mesaje)
      final recentHistory = history.length > 10
          ? history.sublist(history.length - 10)
          : history;

      for (final msg in recentHistory) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.content}],
        });
      }

      // Adăugăm mesajul curent
      contents.add({
        'role': 'user',
        'parts': [{'text': userMessage}],
      });

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': _systemPrompt}],
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2000,
            'topP': 0.9,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else if (_apiKey == 'INSEREAZA_CHEIA_TA_API_GEMINI_AICI') {
        return _mockResponse(userMessage);
      } else {
        return 'Eroare la comunicarea cu asistentul (${response.statusCode}). Reîncercați.';
      }
    } catch (e) {
      if (_apiKey == 'INSEREAZA_CHEIA_TA_API_GEMINI_AICI') {
        return _mockResponse(userMessage);
      }
      return 'Asistentul nu este disponibil momentan. Verificați conexiunea.';
    }
  }

  /// Mock responses pentru demo/test când nu există cheie API
  static String _mockResponse(String question) {
    final q = question.toLowerCase();
    if (q.contains('licitati') || q.contains('licitație')) {
      return '📋 **Licitații active în sistem:**\n\nPentru a vedea licitațiile active, accesați modulul **Licitații Online** din meniul principal. Acolo puteți vedea toate licitațiile cu statusul "Activă" sau "Publicată", prețul de pornire și data limită.\n\nPentru a participa la o licitație, trebuie să vă înregistrați ca participant și să depuneți garanția de participare.';
    }
    if (q.contains('bun') || q.contains('imobil') || q.contains('teren') || q.contains('cladire')) {
      return '🏢 **Bunuri imobiliare:**\n\nPatrimoniul UAT include terenuri, clădiri, spații și construcții. Fiecare bun are:\n- Număr cadastral și carte funciară\n- Valoare de inventar\n- Domeniu juridic (public/privat)\n- Status curent\n\nPentru detalii specifice, accesați modulul **Bunuri Imobile** din meniu.';
    }
    if (q.contains('contract')) {
      return '📝 **Contracte:**\n\nContractele de administrare a patrimoniului pot fi de închiriere, concesionare sau dare în administrare. Durata și valoarea se stabilesc prin HCL.\n\nPentru a vedea contractele active, accesați modulul **Contracte** din meniu.';
    }
    if (q.contains('document') || q.contains('hcl')) {
      return '📄 **Documente patrimoniu:**\n\nDocumentele necesare includ:\n- **HCL** - Hotărârea Consiliului Local pentru aprobarea tranzacțiilor\n- **Extras Carte Funciară** - pentru verificarea situației juridice\n- **Plan Cadastral** - pentru identificarea imobilului\n- **Raport de Evaluare** - pentru stabilirea valorii de piață\n\nToate documentele pot fi încărcate în modulul **Documente**.';
    }
    return '👋 Bună ziua! Sunt Asistentul e-Patrimoniu.\n\nVă pot ajuta cu informații despre:\n- 🏢 Bunuri imobiliare (terenuri, clădiri, spații)\n- 📝 Tranzacții și contracte\n- 🔨 Licitații online\n- 📄 Documente necesare\n- ⚖️ Legislație aplicabilă\n\nCe doriți să știți?';
  }

  // --- Gestionare sesiuni chat (in-memory) ---
  static Future<String> createSession(String userId) async {
    final now = DateTime.now();
    final session = ChatSession(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Sesiune nouă',
      createdAt: now,
      updatedAt: now,
    );
    _sessions.add(session);
    return session.id;
  }

  static Stream<List<ChatSession>> getSessions(String userId) {
    final result = _sessions
        .where((s) => s.userId == userId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Stream.value(result);
  }

  static Stream<List<ChatMessage>> getMessages(String sessionId) {
    final result = _messages
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Stream.value(result);
  }

  static Future<void> saveMessage(ChatMessage msg) async {
    _messages.add(msg);
    if (msg.isUser) {
      final session = _sessions.where((s) => s.id == msg.sessionId).firstOrNull;
      if (session != null) {
        session.title = msg.content.length > 50
            ? '${msg.content.substring(0, 50)}...'
            : msg.content;
        session.updatedAt = DateTime.now();
      }
    }
  }

  static Future<void> deleteSession(String sessionId) async {
    _messages.removeWhere((m) => m.sessionId == sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
  }
}
