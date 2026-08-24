import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/item_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class ReportFoundScreen extends StatefulWidget {
  const ReportFoundScreen({super.key});

  @override
  State<ReportFoundScreen> createState() => _ReportFoundScreenState();
}

class _ReportFoundScreenState extends State<ReportFoundScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _titleCtrl      = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _locationCtrl   = TextEditingController();
  final _dateCtrl       = TextEditingController();
  final _timeCtrl       = TextEditingController();
  final _additionalCtrl = TextEditingController();

  int?   _selectedCategoryId;
  File?  _selectedImage;
  final  _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (picked != null) setState(() => _selectedImage = File(picked.path));
    } catch (_) {
      if (mounted) AppHelpers.showError(context, 'Could not access camera/gallery.');
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ItemProvider>();
    final response = await provider.createItem(
      type:                  'found',
      title:                 _titleCtrl.text.trim(),
      description:           _descCtrl.text.trim(),
      categoryId:            _selectedCategoryId,
      location:              _locationCtrl.text.trim(),
      dateOccurred:          _dateCtrl.text.trim(),
      timeOccurred:          _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
      image:                 _selectedImage,
      additionalInformation: _additionalCtrl.text.trim().isEmpty ? null : _additionalCtrl.text.trim(),
    );
    if (!mounted) return;
    if (response.success) {
      AppHelpers.showSuccess(context, 'Found item reported! Thank you for helping the community.');
      Navigator.pop(context);
    } else {
      AppHelpers.showError(context, response.message);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _additionalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider     = context.watch<ItemProvider>();
    final categories   = provider.categories;
    final isSubmitting = provider.isSubmitting;

    return LoadingOverlay(
      isLoading: isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Found Item'),
          backgroundColor: AppTheme.foundColor.withOpacity(0.1),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.foundColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.foundColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volunteer_activism_rounded, color: AppTheme.foundColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Great job! Help reunite this item with its owner.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontFamily: 'Outfit'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Image Upload
                GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Stack(
                              children: [
                                Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedImage = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Add Photo (Optional)', style: TextStyle(color: Colors.grey.shade400, fontFamily: 'Outfit')),
                              Text('JPEG, PNG, WebP • Max 5MB', style: TextStyle(fontSize: 11, color: Colors.grey.shade300, fontFamily: 'Outfit')),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Item Name *', hint: 'e.g. Blue Backpack',
                  controller: _titleCtrl,
                  prefixIcon: const Icon(Icons.label_rounded, size: 20),
                  validator: (v) => Validators.minLength(v, 3, 'Item name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true, fillColor: Colors.white,
                  ),
                  hint: const Text('Select a category', style: TextStyle(fontFamily: 'Outfit')),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, style: const TextStyle(fontFamily: 'Outfit')),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Description *', hint: 'Describe the item in detail...',
                  controller: _descCtrl, maxLines: 4, maxLength: 2000,
                  validator: (v) => Validators.minLength(v, 10, 'Description'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Location Found *', hint: 'e.g. Main Street Bus Stop',
                  controller: _locationCtrl,
                  prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                  validator: (v) => Validators.required(v, 'Location'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(flex: 3, child: DatePickerField(label: 'Date Found *', controller: _dateCtrl, validator: Validators.date)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: TimePickerField(label: 'Time (optional)', controller: _timeCtrl)),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Additional Information', hint: 'Where is the item now? How to contact?',
                  controller: _additionalCtrl, maxLines: 3, maxLength: 1000,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submit,
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: const Text('Report Found Item'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.foundColor),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
