enum AuthorityType {
  president,
  premierMinistre,
  ministre,
  gouverneur,
  depute,
  senateur,
  autre;

  // Méthode pour convertir la valeur de la base de données en Enum
  static AuthorityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'president': return AuthorityType.president;
      case 'premier_ministre': return AuthorityType.premierMinistre;
      case 'ministre': return AuthorityType.ministre;
      case 'gouverneur': return AuthorityType.gouverneur;
      case 'depute': return AuthorityType.depute;
      case 'senateur': return AuthorityType.senateur;
      default: return AuthorityType.autre;
    }
  }
}
