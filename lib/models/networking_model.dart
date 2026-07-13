class SocialLinkDto {
  const SocialLinkDto({required this.platform, required this.url, this.label});

  final String platform;
  final String url;
  final String? label;

  factory SocialLinkDto.fromJson(Map<String, dynamic> json) {
    final rawPlatform = json['platform'];
    final rawUrl = json['url'];
    final rawLabel = json['label'];
    if (rawPlatform is! String || rawPlatform.trim().isEmpty) {
      throw const FormatException('Invalid networking platform.');
    }
    if (rawUrl is! String || rawUrl.trim().isEmpty) {
      throw const FormatException('Invalid networking URL.');
    }
    if (rawLabel != null && rawLabel is! String) {
      throw const FormatException('Invalid networking label.');
    }
    final normalizedLabel = (rawLabel as String?)?.trim();
    return SocialLinkDto(
      platform: rawPlatform.trim(),
      url: rawUrl.trim(),
      label: normalizedLabel == null || normalizedLabel.isEmpty
          ? null
          : normalizedLabel,
    );
  }

  Map<String, dynamic> toJson() {
    final trimmedLabel = label?.trim();
    return <String, dynamic>{
      'platform': platform,
      'url': url.trim(),
      'label': trimmedLabel == null || trimmedLabel.isEmpty
          ? null
          : trimmedLabel,
    };
  }
}

class NetworkingCardDto {
  const NetworkingCardDto({required this.optIn, required this.links});

  final bool optIn;
  final List<SocialLinkDto> links;

  SocialLinkDto? get link {
    if (links.length > 1) {
      throw StateError('A networking card cannot contain more than one link.');
    }
    return links.isEmpty ? null : links.first;
  }

  factory NetworkingCardDto.fromJson(Map<String, dynamic> json) {
    final rawOptIn = json['optIn'];
    if (rawOptIn is! bool) {
      throw const FormatException('Networking optIn must be a boolean.');
    }
    final rawLinks = json['links'];
    if (rawLinks is! List) {
      throw const FormatException('Networking links must be a list.');
    }
    if (rawLinks.length > 1) {
      throw const FormatException(
        'Networking response contains more than one link.',
      );
    }
    final links = rawLinks
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Invalid networking link.');
          }
          return SocialLinkDto.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);

    return NetworkingCardDto(optIn: rawOptIn, links: links);
  }

  Map<String, dynamic> toJson() {
    if (links.length > 1) {
      throw StateError('A networking card cannot contain more than one link.');
    }
    return <String, dynamic>{
      'optIn': optIn,
      'links': links.map((link) => link.toJson()).toList(growable: false),
    };
  }
}
