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

    if (q.contains('cadastral') || q.contains('carte funciara') || q.contains('carte funciară') || q.contains('numar cadastral') || q.contains('număr cadastral')) {
      return 'Numărul cadastral este un identificator unic atribuit fiecărui imobil — teren sau construcție — în cadrul sistemului național de cadastru și carte funciară, gestionat de Agenția Națională de Cadastru și Publicitate Imobiliară (ANCPI).\n\nAcest număr permite identificarea exactă a imobilului în documentele oficiale și în baza de date națională. El apare în extrasul de carte funciară și în planul cadastral.\n\nCartea funciară este documentul public în care sunt înscrise toate drepturile reale asociate unui imobil: dreptul de proprietate, servituțile, ipotecile, privilegiile și orice alte sarcini. Orice tranzacție imobiliară implică obligatoriu consultarea cărții funciare pentru a verifica situația juridică actuală a imobilului.\n\nPentru a obține un număr cadastral nou, proprietarul trebuie să apeleze la un expert autorizat ANCPI care realizează măsurătorile topografice, întocmește documentația cadastrală și o depune la Biroul de Cadastru și Publicitate Imobiliară (BCPI) competent. Înscrierea în cartea funciară se face printr-o cerere de recepție și înscriere.\n\nExtrasul de carte funciară pentru informare poate fi obținut de orice persoană, în timp ce extrasul pentru autentificare este necesar în momentul semnării unui act notarial.';
    }

    if (q.contains('licitati') || q.contains('licitație') || q.contains('licitaţie')) {
      return 'Licitația publică este procedura prin care unitățile administrativ-teritoriale pot valorifica bunurile din patrimoniul lor privat sau pot concesiona ori închiria bunuri din domeniul public.\n\nEtapele principale ale unei licitații publice sunt:\n\n1. Inițierea procedurii — autoritatea publică adoptă o hotărâre de consiliu local prin care aprobă scoaterea la licitație a bunului, prețul minim de pornire și condițiile de participare.\n\n2. Publicitatea — anunțul de licitație se publică în Monitorul Oficial al județului, pe site-ul instituției și la sediul acesteia, cu minimum 20 de zile înainte de data organizării.\n\n3. Participarea — persoanele interesate achiziționează caietul de sarcini, depun dosarul de participare și garanția de participare, care reprezintă de regulă 10% din prețul de pornire.\n\n4. Desfășurarea licitației — se desfășoară în fața unei comisii desemnate prin dispoziție a primarului. Participanții depun oferte scrise sau participă la licitație cu strigare, în funcție de procedura aleasă.\n\n5. Atribuirea — câștigătorul este cel care oferă prețul cel mai mare, cu respectarea tuturor condițiilor din caietul de sarcini. Comisia întocmește un proces-verbal de adjudecare.\n\n6. Încheierea contractului — în termenul legal de la adjudecare se semnează contractul corespunzător (vânzare-cumpărare, concesiune sau închiriere), autentificat notarial dacă este cazul.\n\nDacă licitația nu se finalizează cu oferte valabile, se poate organiza o a doua licitație cu un preț de pornire redus, conform prevederilor legale.';
    }

    if (q.contains('concesion')) {
      return 'Concesionarea este modalitatea prin care o autoritate publică — numită concedent — acordă unui operator privat — numit concesionar — dreptul de a exploata un bun din domeniul public sau de a presta un serviciu public, pe o perioadă determinată, în schimbul unei redevențe.\n\nPrincipalele caracteristici ale concesiunii:\n- Bunul rămâne în proprietatea publică pe toată durata contractului\n- Concesionarul plătește o redevență periodică stabilită prin contract și aprobată prin HCL\n- Durata maximă a concesiunii este de 49 de ani, cu posibilitate de prelungire\n- Concesionarul poate realiza investiții pe bunul concesionat, care revin la final în proprietatea concedentului, fără despăgubire, dacă nu s-a convenit altfel\n- Contractul poate fi reziliat de plin drept dacă concesionarul nu respectă obligațiile asumate\n\nProcedura de concesionare:\n1. Întocmirea studiului de oportunitate și aprobarea lui prin HCL\n2. Adoptarea HCL privind aprobarea concesionării și a caietului de sarcini\n3. Organizarea licitației publice deschise — sau negocierea directă în cazuri speciale prevăzute de lege\n4. Semnarea contractului de concesiune\n5. Înregistrarea în evidențele de cadastru și publicitate imobiliară\n\nLegislația aplicabilă: OUG nr. 57/2019 — Codul administrativ și Legea nr. 100/2016 privind concesiunile de lucrări și concesiunile de servicii.';
    }

    if (q.contains('vânzar') || q.contains('vanzar') || q.contains('etapele') || q.contains('domeniu privat')) {
      return 'Vânzarea unui bun imobil din domeniul privat al unei unități administrativ-teritoriale se realizează prin licitație publică, în conformitate cu prevederile Codului administrativ (OUG nr. 57/2019).\n\nEtapele procedurii de vânzare:\n\n1. Identificarea și evaluarea bunului — se întocmește un raport de evaluare de către un evaluator autorizat ANEVAR, care stabilește valoarea de piață a imobilului.\n\n2. Aprobarea prin HCL — consiliul local adoptă o hotărâre prin care aprobă vânzarea, stabilește prețul minim (cel puțin valoarea din raportul de evaluare) și condițiile procedurii.\n\n3. Documentația de atribuire — se întocmesc caietul de sarcini, regulamentul de licitație și documentele de participare pe care le vor completa ofertanții.\n\n4. Publicitatea licitației — anunțul se publică în presa locală și pe site-ul instituției cu cel puțin 20 de zile înainte de data licitației.\n\n5. Desfășurarea licitației — comisia desemnată verifică ofertele depuse și adjudecă bunul celui mai mare ofertant care îndeplinește condițiile.\n\n6. Autentificarea contractului de vânzare-cumpărare — actul se încheie la notar public, cu achitarea tuturor taxelor și impozitelor aferente.\n\n7. Înscrierea în cartea funciară — dreptul de proprietate se transferă cumpărătorului prin înscrierea în CF la BCPI competent.\n\nVeniturile obținute din vânzarea bunurilor din domeniul privat constituie venituri ale bugetului local și se utilizează conform legii finanțelor publice locale.';
    }

    if (q.contains('bun') || q.contains('imobil') || q.contains('teren') || q.contains('clădir') || q.contains('cladire') || q.contains('spatiu') || q.contains('spațiu') || q.contains('patrimoniu')) {
      return 'Patrimoniul unităților administrativ-teritoriale cuprinde totalitatea bunurilor mobile și imobile aflate în proprietatea acestora. Din punct de vedere juridic, bunurile se împart în două categorii distincte:\n\nDomeniu public — bunurile de uz sau de interes public local, care nu pot fi înstrăinate, nu pot fi urmărite silit și sunt imprescriptibile. Exemple: drumuri publice, piețe, parcuri, clădiri ale primăriei, școli, spitale publice.\n\nDomeniu privat — bunurile aflate în proprietatea UAT care nu fac parte din domeniul public. Acestea pot fi înstrăinate prin vânzare, concesionate sau închiriate în condițiile legii.\n\nFiecare bun imobil din patrimoniu are asociate:\n- Date de identificare: adresă, număr cadastral, număr de carte funciară, suprafață exactă\n- Valoarea de inventar actualizată\n- Destinația și modul de folosință curent\n- Documentele justificative ale dreptului de proprietate\n- Istoricul operațiunilor efectuate\n\nInventarierea patrimoniului public se realizează conform Legii nr. 213/1998 privind bunurile proprietate publică și OUG nr. 57/2019 — Codul administrativ. UAT-urile au obligația de a ține la zi inventarul bunurilor și de a-l actualiza ori de câte ori intervin modificări.';
    }

    if (q.contains('contract')) {
      return 'În administrarea patrimoniului public local, cele mai frecvente tipuri de contracte sunt:\n\n1. Contractul de vânzare-cumpărare — prin care un bun din domeniul privat al UAT este înstrăinat unui terț. Necesită autentificare notarială și înscriere în cartea funciară pentru transferul dreptului de proprietate.\n\n2. Contractul de concesiune — permite unui operator privat să exploateze un bun public pe termen lung, până la 49 de ani, în schimbul unei redevențe periodice. Reglementat de OUG 57/2019 și Legea 100/2016.\n\n3. Contractul de închiriere — acordă dreptul de folosință temporară a unui bun, fără transferul proprietății. Durata este de regulă de maxim 5 ani, cu posibilitate de prelungire. Chiria se actualizează anual cu indicele prețurilor de consum.\n\n4. Contractul de dare în administrare — bunurile din domeniul public pot fi date în administrarea regiilor autonome sau instituțiilor publice, care le gestionează fără plata unei redevențe.\n\n5. Contractul de comodat — transmiterea folosinței gratuite a unui bun, de regulă către asociații, ONG-uri sau instituții publice subordonate.\n\nToate contractele care implică bunuri publice trebuie aprobate prin hotărâre de consiliu local și se înregistrează în registrul contractelor al instituției. Modificările esențiale ale contractelor (prelungire, modificarea valorii) necesită acte adiționale aprobate tot prin HCL.';
    }

    if (q.contains('document') || q.contains('hcl') || q.contains('hotărâre') || q.contains('hotarare') || q.contains('necesare')) {
      return 'Pentru operațiunile cu bunuri imobiliare ale unităților administrativ-teritoriale, documentele necesare variază în funcție de tipul operațiunii. Iată principalele categorii:\n\nDocumente de identificare a imobilului:\n- Extras de carte funciară pentru informare sau pentru autentificare, obținut de la BCPI teritorial\n- Plan de amplasament și delimitare — documentul tehnic cu coordonatele și suprafața exactă\n- Fișa bunului imobil din inventarul domeniului public sau privat al UAT\n\nDocumente administrative:\n- Hotărârea Consiliului Local (HCL) — actul de decizie obligatoriu pentru orice operațiune cu bunuri publice\n- Raportul de specialitate al compartimentului responsabil din primărie\n- Raportul de evaluare întocmit de un evaluator autorizat ANEVAR\n- Caietul de sarcini — pentru licitații și concesiuni\n\nDocumente tehnice:\n- Certificat de urbanism — pentru operațiunile care implică construcții sau schimbări de destinație\n- Autorizație de construire sau de demolare, după caz\n- Proces-verbal de recepție la terminarea lucrărilor\n\nDocumente juridice:\n- Contractul (vânzare-cumpărare, concesiune, închiriere), autentificat notarial dacă este cazul\n- Titlul de proprietate original al UAT\n- Adeverință fiscală privind absența datoriilor\n\nToate documentele se arhivează conform Legii Arhivelor Naționale nr. 16/1996. Documentele privind proprietatea se păstrează pe durată nedeterminată.';
    }

    if (q.contains('legislat') || q.contains('lege') || q.contains('oug') || q.contains('cod administrativ') || q.contains('juridic')) {
      return 'Principalele acte normative care reglementează patrimoniul public al unităților administrativ-teritoriale din România sunt:\n\nLegislație generală:\n- OUG nr. 57/2019 — Codul administrativ: reglementează regimul juridic al domeniului public și privat al UAT, procedurile de înstrăinare, concesionare, dare în administrare și închiriere.\n- Legea nr. 213/1998 privind bunurile proprietate publică: stabilește ce bunuri aparțin domeniului public al statului și al UAT-urilor.\n- Legea nr. 287/2009 — Codul civil: reglementează drepturile reale, inclusiv proprietatea, servituțile, superficia și uzufructul.\n\nCadastru și publicitate imobiliară:\n- Legea nr. 7/1996 a cadastrului și publicității imobiliare: organizarea sistemului de înregistrare a imobilelor și de publicitate prin cartea funciară.\n\nConcesiuni:\n- Legea nr. 100/2016 privind concesiunile de lucrări și concesiunile de servicii.\n\nAchiziții publice:\n- Legea nr. 98/2016 privind achizițiile publice: aplicabilă când UAT cumpără bunuri, servicii sau lucrări.\n\nFinanțe publice locale:\n- Legea nr. 273/2006 privind finanțele publice locale: veniturile din valorificarea bunurilor se constituie venituri ale bugetului local.\n\nArhivare:\n- Legea nr. 16/1996 a Arhivelor Naționale: obligații de păstrare și gestionare a documentelor instituțiilor publice.\n\nLegislația se actualizează frecvent. Se recomandă verificarea formei în vigoare pe Monitorul Oficial sau platforme legislative precum Lege5.ro.';
    }

    if (q.contains('închiriere') || q.contains('inchiriere') || q.contains('chirie')) {
      return 'Închirierea bunurilor din domeniul public sau privat al unităților administrativ-teritoriale este una dintre cele mai frecvente modalități de valorificare a patrimoniului, fără a transfera dreptul de proprietate.\n\nPrincipalele caracteristici:\n- Chiriaşul obține dreptul de folosință temporară a bunului, nu proprietatea\n- Durata se stabilește prin HCL și contract, de regulă între 1 și 5 ani, cu posibilitate de prelungire\n- Chiria se stabilește prin licitație publică sau prin negociere directă, în funcție de situație\n- Valoarea chiriei se actualizează anual cu indicele prețurilor de consum publicat de INS\n\nProcedura de închiriere prin licitație:\n1. Adoptarea HCL privind aprobarea închirierii și a prețului minim al chiriei\n2. Întocmirea caietului de sarcini cu condițiile de utilizare a bunului\n3. Publicarea anunțului de licitație\n4. Desfășurarea licitației și desemnarea câștigătorului\n5. Semnarea contractului de închiriere\n\nObligațiile principale ale chiriaşului:\n- Plata chiriei la termenele stabilite contractual\n- Folosirea bunului exclusiv conform destinației stabilite în contract\n- Întreținerea corespunzătoare și restituirea bunului în starea inițială\n- Interzicerea subînchirierii fără acordul expres al proprietarului\n\nNerespectarea obligațiilor contractuale poate duce la rezilierea contractului și evacuarea chiriaşului.';
    }

    return 'Înțeleg întrebarea dumneavoastră. Pot oferi informații detaliate despre următoarele subiecte legate de patrimoniul public:\n\n- Bunuri imobiliare ale UAT și regimul lor juridic (domeniu public vs. privat)\n- Proceduri de licitație publică pentru valorificarea bunurilor\n- Concesionarea și închirierea bunurilor publice\n- Tipuri de contracte utilizate în administrarea patrimoniului\n- Documente necesare pentru diferite tipuri de tranzacții\n- Legislație aplicabilă (Codul administrativ, Legea 213/1998 etc.)\n- Cadastru, carte funciară și număr cadastral\n- Etapele vânzării unui bun din domeniul privat\n\nReformulați întrebarea folosind unul dintre aceste subiecte și vă voi oferi informații complete și detaliate.';
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

  /// Sync getter — folosit direct în setState (înlocuiește StreamBuilder)
  static List<ChatSession> getSessionsList(String userId) {
    return _sessions
        .where((s) => s.userId == userId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Sync getter — folosit direct în setState (înlocuiește StreamBuilder)
  static List<ChatMessage> getMessagesList(String sessionId) {
    return _messages
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
