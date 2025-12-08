class NewsArticle {
  final int id;
  final String titre;
  final String slug;
  final String contenu;
  final String? resume;
  final String? categorie;
  final String? imageUrl;
  final DateTime? datePublication;
  final String? auteurNom;

  NewsArticle({
    required this.id,
    required this.titre,
    required this.slug,
    required this.contenu,
    this.resume,
    this.categorie,
    this.imageUrl,
    this.datePublication,
    this.auteurNom,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final auteur = json['auteur'];
    String? auteurNom;
    if (auteur != null) {
      final prenom = auteur['prenom'] ?? '';
      final nom = auteur['nom'] ?? '';
      auteurNom = ('$prenom $nom').trim();
      if (auteurNom.isEmpty) auteurNom = null;
    }

    return NewsArticle(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      slug: json['slug'] ?? '',
      contenu: json['contenu'] ?? '',
      resume: json['resume'],
      categorie: json['categorie'],
      imageUrl: json['image_couverture_url'],
      datePublication: json['date_publication'] != null
          ? DateTime.tryParse(json['date_publication'])
          : null,
      auteurNom: auteurNom,
    );
  }
}
