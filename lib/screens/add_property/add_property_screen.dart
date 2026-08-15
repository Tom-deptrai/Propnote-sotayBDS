import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/services/app_runtime.dart';
import '../../data/services/location_service.dart';
import '../../data/services/media_storage.dart';
import '../../models/contact.dart';
import '../../models/geo_point.dart';
import '../../models/property.dart';
import '../../models/property_document.dart';
import '../../models/property_photo.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../utils/formatters.dart';
import '../../utils/vn_number_formatter.dart';
import '../../widgets/area_picker_sheet.dart';
import '../../widgets/input_actions.dart';
import '../../widgets/manage_options_sheet.dart';
import '../../widgets/mini_map_preview.dart';
import '../../widgets/number_stepper.dart';
import 'widgets/contacts_editor.dart';
import 'widgets/document_picker_grid.dart';
import 'widgets/location_picker_screen.dart';
import 'widgets/photo_picker_grid.dart';
import 'widgets/status_selector.dart';

const GeoPoint _defaultLocation = GeoPoint(
  latitude: 21.0285,
  longitude: 105.8542,
);

class AddPropertyScreen extends StatefulWidget {
  final Property? existing;

  const AddPropertyScreen({super.key, this.existing});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _frontageController = TextEditingController();
  final _notesController = TextEditingController();

  // iOS's decimal pad has no built-in Done key, so these track focus to
  // show a small "Xong" bar above the keyboard for the numeric fields.
  final _priceFocus = FocusNode();
  final _areaFocus = FocusNode();
  final _frontageFocus = FocusNode();
  bool get _numericFieldFocused =>
      _priceFocus.hasFocus || _areaFocus.hasFocus || _frontageFocus.hasFocus;

  List<int> _photoSeeds = [];
  List<int> _documentSeeds = [];
  List<Contact> _contacts = [];
  PropertyStatus _status = PropertyStatus.selling;
  String? _areaId;
  GeoPoint _location = _defaultLocation;
  bool _locationTouched = false;
  bool _locating = false;
  String? _propertyType;
  int? _floors;
  final Set<String> _tags = {};
  DateTime? _surveyDate;
  bool _saving = false;
  late final String _propertyId;
  List<PropertyPhoto> _photos = [];
  List<PropertyDocument> _documents = [];
  MediaStorage? _mediaStorage;
  bool _saveCompleted = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    for (final node in [_priceFocus, _areaFocus, _frontageFocus]) {
      node.addListener(() => setState(() {}));
    }
    final p = widget.existing;
    _propertyId = p?.id ?? const Uuid().v4();
    if (p != null) {
      _titleController.text = p.title;
      _priceController.text = p.price > 0
          ? VnThousandsInputFormatter.formatEditUpdateStatic(p.price / 1e6)
          : '';
      _areaController.text = p.landArea > 0
          ? VnThousandsInputFormatter.formatEditUpdateStatic(p.landArea)
          : '';
      _frontageController.text = p.frontage != null
          ? VnThousandsInputFormatter.formatEditUpdateStatic(p.frontage!)
          : '';
      _notesController.text = p.notes;
      _photoSeeds = List.of(p.photoSeeds);
      _documentSeeds = List.of(p.documentSeeds);
      _photos = List.of(p.photos);
      _documents = List.of(p.documents);
      _contacts = List.of(p.contacts);
      _status = p.status;
      _areaId = p.areaId;
      _location = p.location ?? GeoPoint.fromLegacyNormalized(p.mapX, p.mapY);
      _locationTouched = p.location != null;
      _propertyType = p.propertyType;
      _floors = p.floors;
      _tags.addAll(p.tags);
      _surveyDate = p.surveyDate;
    } else {
      _surveyDate = DateTime.now();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaStorage ??= context.read<AppRuntime?>()?.mediaStorage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _frontageController.dispose();
    _notesController.dispose();
    _priceFocus.dispose();
    _areaFocus.dispose();
    _frontageFocus.dispose();
    if (!_saveCompleted) {
      final storage = _mediaStorage;
      if (storage != null) {
        unawaited(storage.cleanupDraft(_propertyId));
      }
    }
    super.dispose();
  }

  double get _priceValue => (parseVnNumber(_priceController.text) ?? 0) * 1e6;

  Future<void> _pickArea() async {
    final state = context.read<AppState>();
    final result = await showAreaPickerSheet(context, selectedAreaId: _areaId);
    if (result != null) setState(() => _areaId = result);
    if (mounted && _areaId == null && state.areas.isNotEmpty) {
      setState(() => _areaId ??= state.areas.first.id);
    }
  }

  Future<void> _pickDate() async {
    DateTime temp = _surveyDate ?? DateTime.now();
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _surveyDate = temp);
                    Navigator.pop(context);
                  },
                  child: const Text('Xong'),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: temp,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2020),
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickOnMap() async {
    final result = await showLocationPickerScreen(context, initial: _location);
    if (result != null) {
      setState(() {
        _location = result;
        _locationTouched = true;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) return;
    setState(() => _locating = true);
    try {
      final point = await runtime.locationService.currentLocation();
      if (!mounted) return;
      setState(() {
        _location = point;
        _locationTouched = true;
      });
      showAppSnackBar('Đã dùng vị trí hiện tại');
    } on LocationFailure catch (error) {
      if (!mounted) return;
      final canOpenSettings =
          error.reason == LocationFailureReason.serviceDisabled ||
          error.reason == LocationFailureReason.permissionDeniedForever;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.userMessage),
          action: canOpenSettings
              ? SnackBarAction(
                  label: 'Cài đặt',
                  onPressed: () =>
                      runtime.locationService.openSettings(error.reason),
                )
              : null,
        ),
      );
    } catch (error) {
      showAppSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _voiceInputTitle() async {
    final text = await showVoiceInput(context);
    if (text == null || !mounted) return;
    final current = _titleController.text.trim();
    _titleController.text = current.isEmpty ? text : '$current $text';
    _titleController.selection = TextSelection.collapsed(
      offset: _titleController.text.length,
    );
  }

  Future<void> _voiceInputNotes() async {
    final text = await showVoiceInput(context);
    if (text == null || !mounted) return;
    final current = _notesController.text.trim();
    _notesController.text = current.isEmpty ? text : '$current $text';
    _notesController.selection = TextSelection.collapsed(
      offset: _notesController.text.length,
    );
  }

  Future<void> _manageTypes() async {
    await showManageOptionsSheet(
      context,
      title: 'Loại bất động sản',
      emptyHint: 'Chưa có loại BĐS nào.',
      optionsOf: (s) => s.propertyTypes,
      usageCountOf: (s, name) => s.propertyTypeUsageCount(name),
      onAdd: (s, name) => s.addPropertyType(name),
      onRename: (s, oldName, newName) async {
        await s.renamePropertyType(oldName, newName);
        final renamed =
            !s.propertyTypes.contains(oldName) &&
            s.propertyTypes.contains(newName);
        if (renamed && _propertyType == oldName) {
          setState(() => _propertyType = newName);
        }
      },
      onDelete: (s, name) => s.deletePropertyType(name),
      canDeleteWhenUsed: false,
      onReorder: (s, oldIndex, newIndex) =>
          s.reorderPropertyTypes(oldIndex, newIndex),
    );
    if (!mounted) return;
    final state = context.read<AppState>();
    if (_propertyType != null && !state.propertyTypes.contains(_propertyType)) {
      setState(
        () => _propertyType = state.propertyTypes.isNotEmpty
            ? state.propertyTypes.first
            : null,
      );
    }
  }

  Future<void> _manageTags() async {
    await showManageOptionsSheet(
      context,
      title: 'Tags',
      emptyHint: 'Chưa có tag nào.',
      optionsOf: (s) => s.tagOptions,
      usageCountOf: (s, name) => s.tagUsageCount(name),
      onAdd: (s, name) => s.addTagOption(name),
      onRename: (s, oldName, newName) async {
        await s.renameTagOption(oldName, newName);
        final renamed =
            !s.tagOptions.contains(oldName) && s.tagOptions.contains(newName);
        if (renamed && _tags.contains(oldName)) {
          setState(() {
            _tags
              ..remove(oldName)
              ..add(newName);
          });
        }
      },
      onDelete: (s, name) => s.deleteTagOption(name),
      onReorder: (s, oldIndex, newIndex) =>
          s.reorderTagOptions(oldIndex, newIndex),
    );
    if (!mounted) return;
    final state = context.read<AppState>();
    setState(() => _tags.retainAll(state.tagOptions));
  }

  Future<bool> _confirmIncompleteFields(List<String> missing) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thiếu thông tin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn chưa nhập:'),
            const SizedBox(height: 10),
            for (final m in missing)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      m,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bổ sung'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vẫn lưu'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _validateAndSave() async {
    if (_titleController.text.trim().isEmpty) {
      showAppSnackBar('Vui lòng nhập tên hoặc địa chỉ ngắn');
      return;
    }

    final missing = <String>[];
    final price = parseVnNumber(_priceController.text);
    final area = parseVnNumber(_areaController.text);
    if (price == null || price <= 0) missing.add('Giá');
    if (area == null || area <= 0) missing.add('Diện tích');
    if (!_locationTouched) missing.add('Vị trí');

    if (missing.isNotEmpty) {
      final proceed = await _confirmIncompleteFields(missing);
      if (!proceed) return;
    }
    if (mounted) await _performSave();
  }

  Future<void> _performSave() async {
    if (_saving) return;
    final state = context.read<AppState>();
    if (state.areas.isEmpty || state.propertyTypeModels.isEmpty) {
      showAppSnackBar('Cần ít nhất một khu vực và một loại BĐS');
      return;
    }
    final areaId = _areaId ?? state.areas.first.id;
    final existing = widget.existing;
    final propertyType =
        _propertyType ??
        (state.propertyTypes.isNotEmpty ? state.propertyTypes.first : 'Khác');
    final typeModel = state.propertyTypeModels.firstWhere(
      (type) => type.name == propertyType,
    );
    final selectedTagModels = state.tagModels
        .where((tag) => _tags.contains(tag.name))
        .toList();
    final normalizedLocation = _location.toLegacyNormalized();
    final now = DateTime.now();
    setState(() => _saving = true);
    MediaCommit? mediaCommit;
    var propertyPersisted = false;
    var savedPhotos = _photos;
    var savedDocuments = _documents;
    try {
      final storage = _mediaStorage;
      if (storage != null) {
        mediaCommit = await storage.commitDraft(
          propertyId: _propertyId,
          photos: _photos,
          documents: _documents,
        );
        savedPhotos = mediaCommit.photos;
        savedDocuments = mediaCommit.documents;
      }
      final property = Property(
        id: _propertyId,
        title: _titleController.text.trim(),
        address: _titleController.text.trim(),
        areaId: areaId,
        status: _status,
        price: _priceValue,
        landArea: parseVnNumber(_areaController.text) ?? 0,
        propertyTypeId: typeModel.id,
        propertyType: propertyType,
        frontage: parseVnNumber(_frontageController.text),
        floors: _floors,
        tagIds: selectedTagModels.map((tag) => tag.id).toList(),
        tags: selectedTagModels.map((tag) => tag.name).toList(),
        notes: _notesController.text.trim(),
        surveyDate: _surveyDate,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        mapX: normalizedLocation.x,
        mapY: normalizedLocation.y,
        latitude: _locationTouched ? _location.latitude : null,
        longitude: _locationTouched ? _location.longitude : null,
        photos: savedPhotos,
        documents: savedDocuments,
        photoSeeds: _photoSeeds,
        documentSeeds: _documentSeeds,
        contacts: _contacts,
      );
      if (_isEditing) {
        await state.updateProperty(property);
      } else {
        await state.addProperty(property);
      }
      propertyPersisted = true;
      final removedPaths = <String>[
        for (final photo in existing?.photos ?? const <PropertyPhoto>[])
          if (!savedPhotos.any((current) => current.id == photo.id)) ...[
            photo.relativePath,
            if (photo.thumbnailRelativePath != null)
              photo.thumbnailRelativePath!,
          ],
        for (final document
            in existing?.documents ?? const <PropertyDocument>[])
          if (!savedDocuments.any((current) => current.id == document.id)) ...[
            document.relativePath,
            if (document.thumbnailRelativePath != null)
              document.thumbnailRelativePath!,
          ],
      ];
      try {
        await _mediaStorage?.deletePaths(removedPaths);
        await _mediaStorage?.cleanupDraft(_propertyId);
      } catch (error, stackTrace) {
        debugPrint('Không thể dọn media sau khi lưu: $error\n$stackTrace');
      }
      _saveCompleted = true;
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(_isEditing ? 'Đã lưu thay đổi' : 'Đã lưu bất động sản');
    } catch (_) {
      if (!propertyPersisted) await mediaCommit?.rollback();
      if (mounted) showAppSnackBar('Không thể lưu bất động sản');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _areaId ??= state.areas.isNotEmpty ? state.areas.first.id : null;
    _propertyType ??= state.propertyTypes.isNotEmpty
        ? state.propertyTypes.first
        : null;
    final areaName = _areaId == null
        ? 'Chọn khu vực'
        : state.areaName(_areaId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Chỉnh sửa bất động sản' : 'Thêm bất động sản',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const _SectionLabel('Ảnh'),
            PhotoPickerGrid(
              propertyId: _propertyId,
              photos: _photos,
              photoSeeds: _photoSeeds,
              onPhotosChanged: (v) => setState(() => _photos = v),
              onChanged: (v) => setState(() => _photoSeeds = v),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Tên / địa chỉ ngắn'),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'VD: Nhà phố Trung Kính',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic_none_rounded, size: 21),
                  color: AppColors.textSecondary,
                  onPressed: _voiceInputTitle,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Trạng thái'),
            StatusSelector(
              selected: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Khu vực'),
            _TapField(
              icon: Icons.folder_outlined,
              label: areaName,
              onTap: _pickArea,
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Vị trí'),
            MiniMapPreview(
              location: _location,
              status: _status,
              onTap: _pickOnMap,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      _locating ? 'Đang lấy vị trí...' : 'Vị trí hiện tại',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickOnMap,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Chọn trên bản đồ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Thông tin chính'),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Giá (triệu đồng)',
                    child: TextField(
                      controller: _priceController,
                      focusNode: _priceFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [VnThousandsInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: '12.500'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Diện tích (m²)',
                    child: TextField(
                      controller: _areaController,
                      focusNode: _areaFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [VnThousandsInputFormatter()],
                      decoration: const InputDecoration(hintText: '72'),
                    ),
                  ),
                ),
              ],
            ),
            if (_priceValue > 0) ...[
              const SizedBox(height: 6),
              Text(
                '≈ ${formatPriceShort(_priceValue)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Loại bất động sản', bottom: 0),
                _ManageLink(onTap: _manageTypes),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.propertyTypes.map((t) {
                final selected = t == _propertyType;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _propertyType = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Mặt tiền (m)',
                    child: TextField(
                      controller: _frontageController,
                      focusNode: _frontageFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [VnThousandsInputFormatter()],
                      decoration: const InputDecoration(hintText: '4,2'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Số tầng',
                    child: NumberStepper(
                      value: _floors,
                      onChanged: (v) => setState(() => _floors = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Tags', bottom: 0),
                _ManageLink(onTap: _manageTags),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.tagOptions.map((t) {
                final selected = _tags.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (v) =>
                      setState(() => v ? _tags.add(t) : _tags.remove(t)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Ghi chú'),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Ghi chú nhanh về bất động sản này...',
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: IconButton(
                    icon: const Icon(Icons.mic_none_rounded, size: 21),
                    color: AppColors.textSecondary,
                    onPressed: _voiceInputNotes,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Ngày khảo sát'),
            _TapField(
              icon: Icons.event_outlined,
              label: _surveyDate == null
                  ? 'Chưa khảo sát'
                  : formatDate(_surveyDate!),
              onTap: _pickDate,
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Tài liệu / Hình bổ sung'),
            DocumentPickerGrid(
              propertyId: _propertyId,
              documents: _documents,
              documentSeeds: _documentSeeds,
              onDocumentsChanged: (v) => setState(() => _documents = v),
              onChanged: (v) => setState(() => _documentSeeds = v),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Liên hệ'),
            ContactsEditor(
              contacts: _contacts,
              onChanged: (v) => setState(() => _contacts = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_numericFieldFocused)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => FocusScope.of(context).unfocus(),
                      child: const Text('Xong'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: ElevatedButton(
                onPressed: _saving ? null : _validateAndSave,
                child: Text(
                  _saving
                      ? 'Đang lưu...'
                      : (_isEditing ? 'Lưu thay đổi' : 'Lưu bất động sản'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageLink extends StatelessWidget {
  final VoidCallback onTap;

  const _ManageLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 14, color: AppColors.navy),
            SizedBox(width: 4),
            Text(
              'Quản lý',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double bottom;

  const _SectionLabel(this.text, {this.bottom = 8});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TapField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
