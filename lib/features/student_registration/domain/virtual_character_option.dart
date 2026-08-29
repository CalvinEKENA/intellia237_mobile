class VirtualCharacterOption {
  const VirtualCharacterOption({
    required this.id,
    required this.name,
    required this.tagline,
  });

  final String id;
  final String name;
  final String tagline;
}

abstract final class VirtualCharacterCatalog {
  static const all = <VirtualCharacterOption>[
    VirtualCharacterOption(
      id: 'nova',
      name: 'Nova',
      tagline: 'Coach analytique et précis',
    ),
    VirtualCharacterOption(
      id: 'kibo',
      name: 'Kibo',
      tagline: 'Guide bienveillant et motivé',
    ),
    VirtualCharacterOption(
      id: 'zuri',
      name: 'Zuri',
      tagline: 'Mentor créatif et dynamique',
    ),
    VirtualCharacterOption(
      id: 'atlas',
      name: 'Atlas',
      tagline: 'Stratégiste rigoureux et calme',
    ),
  ];
}
