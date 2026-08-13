import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../utils/formatters.dart';
import '../../widgets/area_picker_sheet.dart';
import '../../widgets/mini_map_preview.dart';
import '../../widgets/number_stepper.dart';
import 'widgets/location_picker_screen.dart';
import 'widgets/photo_picker_grid.dart';
import 'widgets/status_selector.dart';

const Offset _mockCurrentLocation = Offset(0.40, 0.46);

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

  List<int> _photoSeeds = [0];
  PropertyStatus _status = PropertyStatus.unsurveyed;
  String? _areaId;
  Offset _location = _mockCurrentLocation;
  String _propertyType = mockPropertyTypes.first;
  int? _floors;
  final Set<String> _tags = {};
  DateTime? _surveyDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _titleController.text = p.title;
      _priceController.text = p.price > 0
          ? (p.price / 1e6).toStringAsFixed(
              p.price % 1e6 == 0 ? 0 : 1,
            )
          : '';
      _areaController.text = p.landArea > 0 ? p.landArea.toStringAsFixed(0) : '';
      _frontageController.text = p.frontage?.toStringAsFixed(1) ?? '';
      _notesController.text = p.notes;
      _photoSeeds = List.of(p.photoSeeds);
      _status = p.status;
      _areaId = p.areaId;
      _location = Offset(p.mapX, p.mapY);
      _propertyType = p.propertyType;
      _floors = p.floors;
      _tags.addAll(p.tags);
      _surveyDate = p.surveyDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _frontageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _priceValue =>
      (double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0) * 1e6;

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
    if (result != null) setState(() => _location = result);
  }

  void _useCurrentLocation() {
    setState(() => _location = _mockCurrentLocation);
    showAppSnackBar('Đã dùng vị trí hiện tại (demo)');
  }

  void _save() {
    final state = context.read<AppState>();
    if (_titleController.text.trim().isEmpty) {
      showAppSnackBar('Vui lòng nhập tên hoặc địa chỉ ngắn');
      return;
    }
    final areaId = _areaId ?? state.areas.first.id;
    final existing = widget.existing;
    final property = Property(
      id: existing?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      address: _titleController.text.trim(),
      areaId: areaId,
      status: _status,
      price: _priceValue,
      landArea: double.tryParse(_areaController.text) ?? 0,
      propertyType: _propertyType,
      frontage: double.tryParse(_frontageController.text),
      floors: _floors,
      tags: _tags.toList(),
      notes: _notesController.text.trim(),
      surveyDate: _surveyDate,
      createdAt: existing?.createdAt ?? DateTime.now(),
      mapX: _location.dx,
      mapY: _location.dy,
      photoSeeds: _photoSeeds.isEmpty ? const [0] : _photoSeeds,
    );
    if (_isEditing) {
      state.updateProperty(property);
    } else {
      state.addProperty(property);
    }
    Navigator.pop(context);
    showAppSnackBar(_isEditing ? 'Đã lưu thay đổi' : 'Đã lưu bất động sản');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _areaId ??= state.areas.isNotEmpty ? state.areas.first.id : null;
    final areaName = _areaId == null ? 'Chọn khu vực' : state.areaName(_areaId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa bất động sản' : 'Thêm bất động sản'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const _SectionLabel('Ảnh'),
          PhotoPickerGrid(
            photoSeeds: _photoSeeds,
            onChanged: (v) => setState(() => _photoSeeds = v),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Tên / địa chỉ ngắn'),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'VD: Nhà phố Trung Kính',
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Trạng thái'),
          StatusSelector(
            selected: _status,
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Khu vực'),
          _TapField(
            icon: Icons.folder_outlined,
            label: areaName,
            onTap: _pickArea,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Vị trí'),
          MiniMapPreview(
            normalizedPosition: _location,
            onTap: _pickOnMap,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Vị trí hiện tại'),
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
          const SizedBox(height: 24),
          const _SectionLabel('Thông tin chính'),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Giá (triệu đồng)',
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '12500'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Diện tích (m²)',
                  child: TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
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
          const SizedBox(height: 16),
          const _SectionLabel('Loại bất động sản', top: 0),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mockPropertyTypes.map((t) {
              final selected = t == _propertyType;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _propertyType = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Mặt tiền (m)',
                  child: TextField(
                    controller: _frontageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: '4.2'),
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
          const SizedBox(height: 24),
          const _SectionLabel('Tags'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mockTagOptions.map((t) {
              final selected = _tags.contains(t);
              return FilterChip(
                label: Text(t),
                selected: selected,
                showCheckmark: false,
                onSelected: (v) => setState(
                  () => v ? _tags.add(t) : _tags.remove(t),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Ghi chú'),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Ghi chú nhanh về bất động sản này...',
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Ngày khảo sát'),
          _TapField(
            icon: Icons.event_outlined,
            label: _surveyDate == null
                ? 'Chọn ngày khảo sát'
                : formatDate(_surveyDate!),
            onTap: _pickDate,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Lưu thay đổi' : 'Lưu bất động sản'),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double top;

  const _SectionLabel(this.text, {this.top = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
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

  const _TapField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
