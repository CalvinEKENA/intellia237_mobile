import '../domain/school_establishment.dart';

/// Catalogue local des etablissements de Yaounde et Douala.
///
/// Utilise directement par le picker sans passer par Firebase.
abstract final class EstablishmentCatalog {
  static List<SchoolEstablishment> search(String query) {
    if (query.isEmpty) return _all;

    final normalized = _normalize(query);
    return _all.where((e) {
      return _normalize(e.name).contains(normalized) ||
          _normalize(e.city ?? '').contains(normalized);
    }).toList();
  }

  /// Tous les etablissements, tries par ville puis par nom.
  static final List<SchoolEstablishment> _all = _buildAll();

  static List<SchoolEstablishment> _buildAll() {
    final list = <SchoolEstablishment>[
      ..._parse('etab_yde', 'Yaounde', _yaoundeRaw),
      ..._parse('etab_dla', 'Douala', _doualaRaw),
    ];
    list.sort((a, b) {
      final c = (a.city ?? '').compareTo(b.city ?? '');
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return List.unmodifiable(list);
  }

  static List<SchoolEstablishment> _parse(
    String prefix,
    String city,
    String raw,
  ) {
    final seen = <String>{};
    final out = <SchoolEstablishment>[];
    var i = 1;

    for (final line in raw.split('\n')) {
      final name = line.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (!seen.add(key)) continue;

      out.add(SchoolEstablishment(
        id: '${prefix}_${i.toString().padLeft(3, '0')}',
        name: name,
        city: city,
      ));
      i++;
    }
    return out;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('e\u0301', 'e') // é composé
        .replaceAll('e\u0300', 'e') // è composé
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00e8', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00eb', 'e')
        .replaceAll('\u00e0', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e4', 'a')
        .replaceAll('\u00ee', 'i')
        .replaceAll('\u00ef', 'i')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f6', 'o')
        .replaceAll('\u00f9', 'u')
        .replaceAll('\u00fb', 'u')
        .replaceAll('\u00fc', 'u')
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u0153', 'oe')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ---------------------------------------------------------------------------
// Yaounde - Lycees et Colleges
// ---------------------------------------------------------------------------
const _yaoundeRaw = '''
Lyc\u00e9e de Mballa II
Lyc\u00e9e d'Elig-Essono
Lyc\u00e9e d'Emana
Lyc\u00e9e Bilingue de Nkoleton
Lyc\u00e9e de Nkolondom
Lyc\u00e9e Technique Charles Atangana
Lyc\u00e9e Technique de Nsam-Efoulan
Lyc\u00e9e de la Cit\u00e9 Verte
Lyc\u00e9e de Tsinga
Lyc\u00e9e Technique de Yaound\u00e9 II
Lyc\u00e9e G\u00e9n\u00e9ral Leclerc
Lyc\u00e9e Bilingue d'Application
Lyc\u00e9e de Biyem-Assi
Lyc\u00e9e de Ngoa-Ekell\u00e9
Lyc\u00e9e de Nsam-Efoulan
Lyc\u00e9e d'Afan Oyoa
Lyc\u00e9e d'Ahala
Lyc\u00e9e Bilingue de Mimboman
Lyc\u00e9e Bilingue d'Anguissa
Lyc\u00e9e de Nkolndongo
Lyc\u00e9e Bilingue d'Ekounou
Lyc\u00e9e de Minkan
Lyc\u00e9e d'Odza
Lyc\u00e9e Technique d'Ekounou
Lyc\u00e9e Bilingue d'Essos
Lyc\u00e9e de Ngousso-Ngoulmekong
Lyc\u00e9e de Nkolmesseng
Lyc\u00e9e Bilingue de Mendong
Lyc\u00e9e Bilingue d'Etoug-Eb\u00e9
Lyc\u00e9e Bilingue de Nkolbisson
Lyc\u00e9e d'Ekorezok
Lyc\u00e9e Technique Bilingue de Nkolbisson
Coll\u00e8ge Jean Tabi
Coll\u00e8ge Protestant Johnston
CETI Sacr\u00e9-Coeur de Mokolo
Coll\u00e8ge FX Vogt
S\u00e9minaire Sainte Th\u00e9r\u00e8se
CETI Notre Dame des Victoires
Academic College of Excellence
Bilik-City Bilingual Complex
Centre \u00c9ducatif d'Ekoudou Bastos (CEEB)
CES de Nyom
CETI Benigna
CETIF Benigna
Coll\u00e8ge Bilingue Priv\u00e9 La\u00efc William Booth
Coll\u00e8ge Bilingue Seat of Wisdom
Coll\u00e8ge Bilingue Sibafo
Coll\u00e8ge de l'Unit\u00e9
CETG de l'Unit\u00e9
Coll\u00e8ge Fido
Coll\u00e8ge Iplex Education
Coll\u00e8ge Oliveraie de Nyom
Coll\u00e8ge Omgba Ndongo
Coll\u00e8ge Peniel
Coll\u00e8ge Priv\u00e9 Bilingue Les Pierres Pr\u00e9cieuses
Coll\u00e8ge Priv\u00e9 La\u00efc Charles Mbakop
Coll\u00e8ge Priv\u00e9 La\u00efc Enfant d'Afrique
Coll\u00e8ge Priv\u00e9 La\u00efc Fapo
Coll\u00e8ge Priv\u00e9 La\u00efc Institut Jean Body Zibi
Coll\u00e8ge Priv\u00e9 La\u00efc La Forge
Coll\u00e8ge Priv\u00e9 La\u00efc La Victoire
Coll\u00e8ge Priv\u00e9 La\u00efc l'\u00c9mergence
Coll\u00e8ge Priv\u00e9 La\u00efc Marcel Bayardon
Coll\u00e8ge Priv\u00e9 La\u00efc Mvom-Nnam
Coll\u00e8ge Sainte Famille
Coll\u00e8ge Socrate Elandi
Coll\u00e8ge Technique Industriel
Complexe Scolaire Bilingual Metenou
Complexe Scolaire Ile \u00c9ducative
Complexe Scolaire Internationale La Gaiet\u00e9
Complexe Scolaire Ornel Bilingual Academy
Complexe Scolaire Saint Andr\u00e9
CTI Nyom
Fondation Tsoungui
Gopal Bilingual Secondary School
Institut Bilingue d'Etoudi
Institut Bilingue Toumwa
Institut Blaise Pascal
Institut Matamfen
Institut Moderne Mbassi
Institut Polyvalent Junior
ISDIC
Chuo Bilingual Comprehensive College
Coll\u00e8ge Les Coccinelles
Coll\u00e8ge Bilingue Bethlehem Legrand
Coll\u00e8ge Bilingue Lincoln
Coll\u00e8ge Elohim
Coll\u00e8ge Priv\u00e9 La\u00efc La Gr\u00e2ce
Coll\u00e8ge Rosa Parks
Institut Bilingue Michelann
Institut Jean Body Zibi
Institut Notre Dame de la Paix
Coll\u00e8ge Beno\u00eet XVI
Coll\u00e8ge Diderot
Coll\u00e8ge La Gr\u00e2ce Tchetgna
Coll\u00e8ge Les Futurs Boss
Coll\u00e8ge Priv\u00e9 La\u00efc Atangana Fouda Albert
Coll\u00e8ge Priv\u00e9 La\u00efc Bilingue Les Bambis
CSE Bilingue David
Coll\u00e8ge Priv\u00e9 La\u00efc La Colombe
Coll\u00e8ge Priv\u00e9 La\u00efc Les Sapins
Complexe Scolaire \u00c9vang\u00e9lique de Pentec\u00f4te
English High School Yaound\u00e9
Fondation Scolaire AA
Frazati Bilingual College
Institut Pascal
Institut Polyvalent Bilingue des Nations
Institut Pol. de la R\u00e9novation P\u00e9dagogique
Institut Priv\u00e9 La\u00efc Paul Momo
Institut Victor Hugo
Wecare Secondary School
Institut Siantou
Institut Mbe
Institut Petou
Institut Gazolent
Institut Priv\u00e9 La\u00efc Central (INSTIC)
Coll\u00e8ge Bilingue Shakespeare
Coll\u00e8ge Frantz Fanon
Coll\u00e8ge Polyvalent Les Laur\u00e9ats
Coll\u00e8ge Priv\u00e9 Madeleine
Coll\u00e8ge de la Mefou''';

// ---------------------------------------------------------------------------
// Douala - Lycees et Colleges
// ---------------------------------------------------------------------------
const _doualaRaw = '''
Lyc\u00e9e Joss
Lyc\u00e9e d'Akwa
Lyc\u00e9e Bilingue de Deido
Lyc\u00e9e TSF Mongo Joseph
Lyc\u00e9e Bilingue de Douala 2
Lyc\u00e9e Bilingue de New-Bell
Lyc\u00e9e Bilingue du G\u00e9nie Militaire
Lyc\u00e9e Bilingue de Bobongo Petit Paris
Lyc\u00e9e Bilingue de Japoma
Lyc\u00e9e Bilingue de Mbanga Pongo
Lyc\u00e9e Bilingue de Ngodi Bakoko
Lyc\u00e9e Bilingue de Nyalla
Lyc\u00e9e Bilingue de Nylon Brazzaville
Lyc\u00e9e Bilingue de Nylon Ndogpassi
CES Bilingue Moungui de Logbessou
Lyc\u00e9e de Ndog-Hem
Lyc\u00e9e d'Oyack
Lyc\u00e9e de PK 21
Lyc\u00e9e Bilingue de Bonab\u00e9ri
Lyc\u00e9e Bilingue de Bonassama
Lyc\u00e9e Bilingue de Mambanda
Lyc\u00e9e Bilingue de Sodiko
Lyc\u00e9e Bilingue de Bojongo
CES Bilingue de Minkwelle
Lyc\u00e9e Polyvalent de Douala
Lyc\u00e9e Bilingue de B\u00e9panda
Lyc\u00e9e Bilingue de Logpom
Lyc\u00e9e d'Akwa Nord
Lyc\u00e9e de la Cit\u00e9 des Palmiers
Lyc\u00e9e de la Cit\u00e9 SIC
Lyc\u00e9e de Makepe
Lyc\u00e9e Bilingue de Manoka
Coll\u00e8ge Libermann
Coll\u00e8ge De La Salle
Coll\u00e8ge Saint Esprit
Coll\u00e8ge Maria Goretti
Sacred Heart College
Coll\u00e8ge \u00c9vang\u00e9lique New Bell
Coll\u00e8ge Saint Michel (Bassa)
Coll\u00e8ge Chevreul (Bassa)
Coll\u00e8ge Saint Charles Borrom\u00e9e
Coll\u00e8ge Notre Dame des Nations
Institut du Renouveau
Coll\u00e8ge Priv\u00e9 La\u00efc de Secr\u00e9tariat et Commerce
Institut des Techniques Industrielles et Commerciales (ITIC)
Institut Secondaire de Technologie (IST)
Institut Professionnel d'H\u00f4tellerie (IPH)
Institut Priv\u00e9 La\u00efc des Techniques Administratives et Commerciales (INTAC)
CETI Bilingue Nguega
Fondation Bilingue Pierre Marie Ndjoko
Institut La Madone
Institut Priv\u00e9 La\u00efc Polyvalent Minfang
Institut Priv\u00e9 Saint Louis
Institut Priv\u00e9 Yuliana
Atlanta Bilingual Comprehensive High School
Atlantic Bilingual College Grand Hangar
Coll\u00e8ge du Levant
Coll\u00e8ge Lamartine
Institut Polyvalent Fosso
Institut Polyvalent Mitanyou
Institut Polyvalent Nanfah
Memory Bilingual Secondary School
Rapha Bilingual School Complex''';
