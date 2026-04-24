import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../providers/reports_provider.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = ReportType.collection;
  String _selectedMaterial = WasteMaterial.plastic;
  final _descriptionController = TextEditingController();

  ReportLocation? _location;
  bool _locating = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useDefaultLocation();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _location = ReportLocation(
            lat: pos.latitude,
            lng: pos.longitude,
            address: 'Medellín (ubicación actual)',
          ));
    } catch (_) {
      _useDefaultLocation();
    } finally {
      setState(() => _locating = false);
    }
  }

  void _useDefaultLocation() {
    setState(() => _location = const ReportLocation(
          lat: AppConstants.medellinLat,
          lng: AppConstants.medellinLng,
          address: 'Medellín, Colombia (ubicación aproximada)',
        ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor captura tu ubicación primero')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(reportsNotifierProvider.notifier).createReport(
            type: _selectedType,
            material: _selectedMaterial,
            location: _location!,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.eco, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Gracias por contribuir a Medellín!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.completed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Text('Tipo de reporte',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _TypeSelector(
                  selected: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
                const SizedBox(height: 20),

                // Material selector
                Text('Material',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _MaterialGrid(
                  selected: _selectedMaterial,
                  onChanged: (v) => setState(() => _selectedMaterial = v),
                ),
                const SizedBox(height: 20),

                // Location
                Text('Ubicación',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _LocationCard(
                  location: _location,
                  locating: _locating,
                  onGetLocation: _getLocation,
                  onUseDefault: _useDefaultLocation,
                ),
                const SizedBox(height: 20),

                // Description
                Text('Descripción (opcional)',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe brevemente el problema o material...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.forestGreen,
                    ),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _submitting ? 'Enviando...' : 'Enviar Reporte',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ReportType.all.map((type) {
        final isSelected = selected == type;
        final icon = type == ReportType.criticalPoint
            ? Icons.warning_amber
            : Icons.recycling;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.forestGreen
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.forestGreen
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MaterialGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MaterialGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WasteMaterial.all.map((material) {
        final isSelected = selected == material;
        final color =
            AppColors.materialColors[material] ?? AppColors.forestGreen;
        return FilterChip(
          label: Text(material),
          selected: isSelected,
          onSelected: (_) => onChanged(material),
          selectedColor: color.withValues(alpha: 0.2),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isSelected ? color : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
          side: BorderSide(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final ReportLocation? location;
  final bool locating;
  final VoidCallback onGetLocation;
  final VoidCallback onUseDefault;

  const _LocationCard({
    required this.location,
    required this.locating,
    required this.onGetLocation,
    required this.onUseDefault,
  });

  @override
  Widget build(BuildContext context) {
    if (location != null) {
      return ListTile(
        tileColor: AppColors.completed.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.completed.withValues(alpha: 0.3)),
        ),
        leading: const Icon(Icons.location_on, color: AppColors.completed),
        title: Text(location!.address ?? 'Ubicación capturada'),
        subtitle: Text(
          '${location!.lat.toStringAsFixed(5)}, '
          '${location!.lng.toStringAsFixed(5)}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onGetLocation,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Usar mi ubicación actual'),
            trailing: locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: locating ? null : onGetLocation,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: const Text('Usar centro de Medellín'),
            subtitle: const Text('Útil si no tienes GPS disponible'),
            onTap: onUseDefault,
          ),
        ],
      ),
    );
  }
}
