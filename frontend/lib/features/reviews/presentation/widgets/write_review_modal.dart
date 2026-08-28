import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class WriteReviewModal extends StatefulWidget {
  const WriteReviewModal({
    super.key,
    required this.productName,
    this.initialRating = 5,
    this.initialTitle,
    this.initialComment,
    required this.onSubmit,
    this.isEditing = false,
  });

  final String productName;
  final int initialRating;
  final String? initialTitle;
  final String? initialComment;
  final Future<void> Function(int rating, String? title, String? comment)
  onSubmit;
  final bool isEditing;

  static Future<void> show(
    BuildContext context, {
    required String productName,
    int initialRating = 5,
    String? initialTitle,
    String? initialComment,
    required Future<void> Function(int rating, String? title, String? comment)
    onSubmit,
    bool isEditing = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: WriteReviewModal(
          productName: productName,
          initialRating: initialRating,
          initialTitle: initialTitle,
          initialComment: initialComment,
          onSubmit: onSubmit,
          isEditing: isEditing,
        ),
      ),
    );
  }

  @override
  State<WriteReviewModal> createState() => _WriteReviewModalState();
}

class _WriteReviewModalState extends State<WriteReviewModal> {
  late int _rating;
  late TextEditingController _titleController;
  late TextEditingController _commentController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _commentController = TextEditingController(
      text: widget.initialComment ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        _rating,
        _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Review updated successfully!'
                  : 'Review submitted successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.isEditing ? 'Edit Review' : 'Write a Review',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.productName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Rating Stars Picker
            Center(
              child: Column(
                children: [
                  Text(
                    'Overall Rating',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int star = 1; star <= 5; star++)
                        IconButton(
                          iconSize: 36,
                          icon: Icon(
                            star <= _rating ? Icons.star : Icons.star_border,
                            color: AppColors.accent,
                          ),
                          onPressed: () => setState(() => _rating = star),
                        ),
                    ],
                  ),
                  Text(
                    _getRatingLabel(_rating),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Headline Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Review Title (optional)',
                hintText: 'e.g. Excellent quality, great battery life!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Comment Field
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Your Review (optional)',
                hintText:
                    'What did you like or dislike? How was your experience?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Update Review' : 'Submit Review',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    return switch (rating) {
      5 => '5 Stars — Excellent',
      4 => '4 Stars — Very Good',
      3 => '3 Stars — Average',
      2 => '2 Stars — Below Average',
      1 => '1 Star — Poor',
      _ => '',
    };
  }
}
