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
      tagline: 'Coach analytique et precis',
    ),
    VirtualCharacterOption(
      id: 'kibo',
      name: 'Kibo',
      tagline: 'Guide bienveillant et motive',
    ),
    VirtualCharacterOption(
      id: 'zuri',
      name: 'Zuri',
      tagline: 'Mentor creatif et dynamique',
    ),
    VirtualCharacterOption(
      id: 'atlas',
      name: 'Atlas',
      tagline: 'Strategiste rigoureux et calme',
    ),
  ];
}
