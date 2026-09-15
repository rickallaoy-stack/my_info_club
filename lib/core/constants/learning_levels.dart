enum LearningLevel {
  debutant,
  novice,
  intermediaire,
  expert,
}

extension LearningLevelLabel on LearningLevel {
  String get label {
    switch (this) {
      case LearningLevel.debutant:
        return 'Débutant';
      case LearningLevel.novice:
        return 'Novice';
      case LearningLevel.intermediaire:
        return 'Intermédiaire';
      case LearningLevel.expert:
        return 'Expert';
    }
  }
}

LearningLevel? learningLevelFromName(String? name) {
  final normalized = name
      ?.toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .trim();

  switch (normalized) {
    case 'debutant':
      return LearningLevel.debutant;
    case 'novice':
      return LearningLevel.novice;
    case 'intermediaire':
      return LearningLevel.intermediaire;
    case 'expert':
      return LearningLevel.expert;
    default:
      return null;
  }
}
