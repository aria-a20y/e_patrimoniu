import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

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

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      sessionId: d['sessionId'] ?? '',
      content: d['content'] ?? '',
      isUser: d['isUser'] ?? true,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'content': content,
    'isUser': isUser,
    'timestamp': FieldValue.serverTimestamp(),
  };
}

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? 'Sesiune nouă',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AiService {
  static final _firestore = FirebaseFirestore.instance;

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

  // --- Gestionare sesiuni chat ---
  static Future<String> createSession(String userId) async {
    final ref = await _firestore.collection(AppConfig.colChatSessions).add({
      'userId': userId,
      'title': 'Sesiune nouă',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<List<ChatSession>> getSessions(String userId) {
    return _firestore
        .collection(AppConfig.colChatSessions)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatSession.fromFirestore(d)).toList());
  }

  static Stream<List<ChatMessage>> getMessages(String sessionId) {
    return _firestore
        .collection(AppConfig.colChatMessages)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromFirestore(d)).toList());
  }

  static Future<void> saveMessage(ChatMessage msg) async {
    await _firestore
        .collection(AppConfig.colChatMessages)
        .add(msg.toFirestore());
    // Actualizăm titlul sesiunii cu primul mesaj al utilizatorului
    if (msg.isUser) {
      final title = msg.content.length > 50
          ? '${msg.content.substring(0, 50)}...'
          : msg.content;
      await _firestore.collection(AppConfig.colChatSessions).doc(msg.sessionId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'title': title,
      });
    }
  }

  static Future<void> deleteSession(String sessionId) async {
    // Ștergem mesajele
    final msgs = await _firestore
        .collection(AppConfig.colChatMessages)
        .where('sessionId', isEqualTo: sessionId)
        .get();
    for (final doc in msgs.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection(AppConfig.colChatSessions).doc(sessionId).delete();
  }
}
