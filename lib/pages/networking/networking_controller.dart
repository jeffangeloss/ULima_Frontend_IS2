import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/networking_model.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/networking_service.dart';
import 'networking_link_launcher.dart';
import 'networking_validators.dart';

enum NetworkingViewStatus { loading, ready, error }

class NetworkingController extends GetxController {
  NetworkingController({
    required NetworkingGateway gateway,
    required this.user,
    this.careerLabel = '',
    NetworkingLinkLauncher? linkLauncher,
  }) : _gateway = gateway,
       _linkLauncher = linkLauncher ?? ExternalNetworkingLinkLauncher();

  static const supportedPlatforms = <String>[
    'linkedin',
    'instagram',
    'github',
    'x',
    'website',
    'other',
  ];

  final NetworkingGateway _gateway;
  final NetworkingLinkLauncher _linkLauncher;
  final UserModel? user;
  final String careerLabel;

  final status = NetworkingViewStatus.loading.obs;
  final optIn = false.obs;
  final hasLinkDraft = false.obs;
  final isEditingLink = false.obs;
  final platform = supportedPlatforms.first.obs;
  final isSaving = false.obs;
  final formRevision = 0.obs;
  final loadError = ''.obs;
  final saveMessage = ''.obs;
  final saveSucceeded = false.obs;
  final persistedOptIn = false.obs;
  final persistedLink = Rxn<SocialLinkDto>();
  final urlController = TextEditingController();
  final labelController = TextEditingController();

  String get fullName => user?.fullName.trim() ?? '';
  String get code => user?.code ?? '';
  bool get isStudent => !(user?.isTeacher ?? false);

  String get roleLabel {
    if (!(user?.isTeacher ?? false)) return 'Alumno';
    final teacherLabel = user?.teacherLabel?.trim().toLowerCase() ?? '';
    return teacherLabel.contains('jefe') || teacherLabel == 'jp'
        ? 'Jefe de Práctica'
        : 'Docente';
  }

  String get primaryDetail {
    final career = careerLabel.trim();
    if (isStudent && career.isNotEmpty) return career;
    return '';
  }

  String get secondaryDetail {
    final parts = <String>[
      if (code.isNotEmpty) code,
      if (roleLabel.isNotEmpty) roleLabel,
    ];
    return parts.join(' · ');
  }

  bool get showLabelField =>
      platform.value == 'website' || platform.value == 'other';

  bool get canSave => hasUnsavedChanges && !isSaving.value;

  bool get hasUnsavedChanges {
    formRevision.value;
    return optIn.value != persistedOptIn.value ||
        !_sameLink(draftLink, persistedLink.value);
  }

  SocialLinkDto? get draftLink {
    if (!hasLinkDraft.value) return null;
    final label = labelController.text.trim();
    return SocialLinkDto(
      platform: platform.value,
      url: urlController.text.trim(),
      label: label.isEmpty ? null : label,
    );
  }

  SocialLinkDto? get previewLink => draftLink ?? persistedLink.value;

  @override
  void onInit() {
    super.onInit();
    urlController.addListener(_syncUrlText);
    labelController.addListener(_syncLabelText);
    load();
  }

  void _syncUrlText() {
    formRevision.value++;
    saveMessage.value = '';
    saveSucceeded.value = false;
  }

  void _syncLabelText() {
    formRevision.value++;
    saveMessage.value = '';
    saveSucceeded.value = false;
  }

  Future<void> load() async {
    status.value = NetworkingViewStatus.loading;
    loadError.value = '';
    saveMessage.value = '';
    saveSucceeded.value = false;
    try {
      final card = await _gateway.fetchMine();
      if (isClosed) return;
      _applyCard(card);
      status.value = NetworkingViewStatus.ready;
    } on ApiException catch (error) {
      if (isClosed) return;
      loadError.value = error.message;
      status.value = NetworkingViewStatus.error;
    } catch (_) {
      if (isClosed) return;
      loadError.value =
          'No se pudo cargar tu carnet. Verifica tu conexión e intenta de nuevo.';
      status.value = NetworkingViewStatus.error;
    }
  }

  void setOptIn(bool value) {
    optIn.value = value;
    formRevision.value++;
    saveMessage.value = '';
    saveSucceeded.value = false;
  }

  void setPlatform(String? value) {
    if (value == null || !supportedPlatforms.contains(value)) return;
    platform.value = value;
    if (!showLabelField) labelController.clear();
    formRevision.value++;
    saveMessage.value = '';
    saveSucceeded.value = false;
  }

  void startAddingLink() {
    hasLinkDraft.value = true;
    isEditingLink.value = true;
    platform.value = supportedPlatforms.first;
    urlController.clear();
    labelController.clear();
    formRevision.value++;
    saveMessage.value = '';
  }

  void startEditingLink() {
    if (!hasLinkDraft.value) return;
    isEditingLink.value = true;
    formRevision.value++;
    saveMessage.value = '';
    saveSucceeded.value = false;
  }

  void removeLink() {
    hasLinkDraft.value = false;
    isEditingLink.value = false;
    urlController.clear();
    labelController.clear();
    formRevision.value++;
    saveMessage.value = '';
    saveSucceeded.value = false;
  }

  Future<void> save() async {
    if (isSaving.value) return;

    final validationMessage = _validateBeforeSave();
    if (validationMessage != null) {
      saveSucceeded.value = false;
      saveMessage.value = validationMessage;
      return;
    }

    final link = draftLink;

    isSaving.value = true;
    saveMessage.value = '';
    saveSucceeded.value = false;
    try {
      final updated = await _gateway.updateMine(
        NetworkingCardDto(optIn: optIn.value, links: [?link]),
      );
      if (isClosed) return;
      _applyCard(updated);
      isEditingLink.value = false;
      saveMessage.value = 'Carnet actualizado correctamente.';
      saveSucceeded.value = true;
    } on ApiException catch (error) {
      if (isClosed) return;
      saveMessage.value = error.message;
    } catch (_) {
      if (isClosed) return;
      saveMessage.value =
          'No se pudieron guardar los cambios. Intenta nuevamente.';
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }

  Future<void> openPreviewLink() async {
    final link = previewLink;
    final validationError = validateNetworkingUrl(link?.url);
    if (link == null || validationError != null) {
      saveSucceeded.value = false;
      saveMessage.value =
          validationError ?? 'Agrega un enlace para poder probarlo.';
      return;
    }

    try {
      final opened = await _linkLauncher.open(Uri.parse(link.url));
      if (isClosed) return;
      if (!opened) saveMessage.value = 'No se pudo abrir este enlace.';
    } catch (_) {
      if (!isClosed) saveMessage.value = 'No se pudo abrir este enlace.';
    }
  }

  String? _validateBeforeSave() {
    if (!hasLinkDraft.value) return null;

    final urlError = validateNetworkingUrl(urlController.text);
    if (urlError != null) return urlError;

    if (showLabelField && labelController.text.trim().isEmpty) {
      return 'Escribe un nombre visible para este enlace.';
    }

    return null;
  }

  void _applyCard(NetworkingCardDto card) {
    optIn.value = card.optIn;
    persistedOptIn.value = card.optIn;
    final link = card.link;
    persistedLink.value = link;
    hasLinkDraft.value = link != null;
    isEditingLink.value = false;
    platform.value = supportedPlatforms.contains(link?.platform)
        ? link!.platform
        : supportedPlatforms.first;
    urlController.text = link?.url ?? '';
    labelController.text = link?.label ?? '';
    formRevision.value++;
  }

  bool _sameLink(SocialLinkDto? a, SocialLinkDto? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.platform == b.platform &&
        a.url.trim() == b.url.trim() &&
        _normalizedLabel(a.label) == _normalizedLabel(b.label);
  }

  String? _normalizedLabel(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void onClose() {
    urlController.removeListener(_syncUrlText);
    labelController.removeListener(_syncLabelText);
    urlController.dispose();
    labelController.dispose();
    super.onClose();
  }
}
