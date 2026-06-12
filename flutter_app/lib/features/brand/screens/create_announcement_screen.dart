import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  int _step = 1;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Metadata
  List<Category> _categories = [];
  List<PlatformModel> _platforms = [];
  List<DeliverableType> _deliverableTypes = [];
  List<InfluencerTier> _tiers = [];

  // Form Field Controllers & State
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _durationController = TextEditingController();
  final _minFollowersController = TextEditingController();
  final _requirementsController = TextEditingController();

  int _selectedCategoryId = 0;
  DateTime _deadlineDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _deliveryDate;
  int? _influencerTierId;
  String? _thumbnailPath;
  String? _attachmentPath;
  final List<int> _selectedPlatforms = [];
  final List<Map<String, int>> _deliverables = []; // { id, quantity }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _durationController.dispose();
    _minFollowersController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getCategories(),
        api.getPlatforms(),
        api.getDeliverableTypes(),
        api.getInfluencerTiers(),
      ]);

      setState(() {
        _categories = results[0] as List<Category>;
        _platforms = results[1] as List<PlatformModel>;
        _deliverableTypes = results[2] as List<DeliverableType>;
        _tiers = results[3] as List<InfluencerTier>;

        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories[0].id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _thumbnailPath = image.path);
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _attachmentPath = result.files.single.path!);
    }
  }

  void _togglePlatform(int id) {
    setState(() {
      if (_selectedPlatforms.contains(id)) {
        _selectedPlatforms.remove(id);
      } else {
        _selectedPlatforms.add(id);
      }
    });
  }

  void _updateDeliverable(int id, int quantity) {
    setState(() {
      final index = _deliverables.indexWhere((d) => d['id'] == id);
      if (quantity <= 0) {
        if (index >= 0) _deliverables.removeAt(index);
      } else {
        if (index >= 0) {
          _deliverables[index] = {'id': id, 'quantity': quantity};
        } else {
          _deliverables.add({'id': id, 'quantity': quantity});
        }
      }
    });
  }

  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _selectedCategoryId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez remplir le titre, la description et sélectionner une catégorie',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_budgetMinController.text.isEmpty ||
        _budgetMaxController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir le budget'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    final bMin = double.tryParse(_budgetMinController.text) ?? 0;
    final bMax = double.tryParse(_budgetMaxController.text) ?? 0;
    if (bMin > bMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le budget minimum ne peut pas être supérieur au maximum',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      await ApiService().createAnnouncement(
        categoryId: _selectedCategoryId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        budgetMin: double.parse(_budgetMinController.text),
        budgetMax: double.parse(_budgetMaxController.text),
        deadline: dateFormat.format(_deadlineDate),
        deliveryDate: _deliveryDate != null
            ? dateFormat.format(_deliveryDate!)
            : null,
        duration: int.tryParse(_durationController.text),
        requirements: _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
        minFollowers: int.tryParse(_minFollowersController.text),
        influencerTierId: _influencerTierId,
        thumbnailPath: _thumbnailPath,
        attachmentPath: _attachmentPath,
        platforms: _selectedPlatforms.isNotEmpty ? _selectedPlatforms : null,
        deliverables: _deliverables.isNotEmpty ? _deliverables : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce publiée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $msg'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _nextStep() {
    if (_step == 1 && _validateStep1()) {
      setState(() => _step = 2);
    } else if (_step == 2 && _validateStep2()) {
      setState(() => _step = 3);
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Créer une annonce',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Basic Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildProgressNode(1, 'Général'),
                _buildProgressLine(_step >= 2),
                _buildProgressNode(2, 'Logistique'),
                _buildProgressLine(_step >= 3),
                _buildProgressNode(3, 'Requis'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_step > 1) ...[
                        Expanded(
                          child: _buildButton(
                            'Précédent',
                            onPressed: _prevStep,
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: _buildButton(
                          _step == 3 ? 'Publier' : 'Suivant',
                          onPressed: _step == 3 ? _handleSubmit : _nextStep,
                          isLoading: _isSubmitting,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Titre de l\'annonce *',
          'Ex: Ambassadeur marque cosmétique bio',
          _titleController,
        ),
        const SizedBox(height: 20),
        Text(
          'Catégorie *',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategoryId == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppColors.text,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategoryId = cat.id);
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Description *',
          'Décrivez votre projet, vos attentes...',
          _descController,
          maxLines: 4,
        ),
        const SizedBox(height: 20),
        Text(
          'Miniature',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.none,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: _thumbnailPath != null
                ? Image.file(File(_thumbnailPath!), fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter une image',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Budget Min (DZD) *',
                '0',
                _budgetMinController,
                type: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Budget Max (DZD) *',
                '0',
                _budgetMaxController,
                type: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDatePicker(
          'Date limite de candidature *',
          _deadlineDate,
          (date) => setState(() => _deadlineDate = date),
          minDate: DateTime.now(),
        ),
        const SizedBox(height: 20),
        _buildDatePicker(
          'Date de livraison souhaitée',
          _deliveryDate,
          (date) => setState(() => _deliveryDate = date),
          minDate: _deadlineDate,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Durée estimée (jours)',
          'Ex: 7',
          _durationController,
          type: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier Influenceur',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tiers.map((tier) {
            final isSelected = _influencerTierId == tier.id;
            return FilterChip(
              label: Text(
                tier.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.text,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _influencerTierId = val ? tier.id : null);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Minimum d\'abonnés',
          'Ex: 1000',
          _minFollowersController,
          type: TextInputType.number,
        ),
        const SizedBox(height: 20),
        Text(
          'Plateformes requises',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _platforms.map((p) {
            final isSelected = _selectedPlatforms.contains(p.id);
            return FilterChip(
              label: Text(
                p.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.text,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _togglePlatform(p.id),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Livrables attendus',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedPlatforms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Sélectionnez une plateforme pour voir les livrables',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ..._platforms.where((p) => _selectedPlatforms.contains(p.id)).map((
          platform,
        ) {
          final pDeliverables = _deliverableTypes
              .where((dt) => dt.platformId == platform.id)
              .toList();
          if (pDeliverables.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  platform.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ...pDeliverables.map((dt) {
                final current = _deliverables
                    .cast<Map<String, int>?>()
                    .firstWhere((d) => d?['id'] == dt.id, orElse: () => null);
                final quantity = current != null ? current['quantity']! : 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8, left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dt.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove,
                              size: 20,
                              color: AppColors.text,
                            ),
                            onPressed: () =>
                                _updateDeliverable(dt.id, quantity - 1),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.background,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              quantity.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _updateDeliverable(dt.id, quantity + 1),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
        const SizedBox(height: 20),
        _buildTextField(
          'Prérequis spécifiques',
          'Ex: mentions obligatoires, style...',
          _requirementsController,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Text(
          'Pièce jointe (PDF)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDocument,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _attachmentPath?.split('/').last ?? 'Ajouter un document',
                    style: GoogleFonts.inter(
                      color: _attachmentPath != null
                          ? AppColors.text
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    Function(DateTime) onChanged, {
    DateTime? minDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? minDate ?? DateTime.now(),
              firstDate: minDate ?? DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Sélectionner une date',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: date != null
                        ? AppColors.text
                        : AppColors.textTertiary,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressNode(int stepNum, String label) {
    bool isPast = _step >= stepNum;
    bool isCurrent = _step == stepNum;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPast ? AppColors.primary : AppColors.surface,
            border: Border.all(
              color: isPast ? AppColors.primary : AppColors.border,
              width: 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isPast && !isCurrent
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  stepNum.toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isPast ? Colors.white : AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent ? AppColors.text : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isPast) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        color: isPast ? AppColors.primary : AppColors.surface,
      ),
    );
  }

  Widget _buildButton(
    String text, {
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
    );
  }
}
