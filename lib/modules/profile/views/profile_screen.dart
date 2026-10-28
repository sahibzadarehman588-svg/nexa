import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/controllers/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: profileController.showImagePickerBottomSheet,
                    child: Stack(
                      children: [
                        Obx(() {
                          if (profileController.profilePhotoUrl.value.isNotEmpty) {
                            return CircleAvatar(
                              radius: 50,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profileController.profilePhotoUrl.value,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  placeholder: (context, url) => const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppColors.surface,
                                  ),
                                  errorWidget: (context, url, error) {
                                    // Silently handle image loading errors (e.g., object not found)
                                    // Clear the invalid URL after a short delay to prevent repeated errors
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (profileController.profilePhotoUrl.value == url) {
                                        profileController.profilePhotoUrl.value = '';
                                      }
                                    });
                                    return const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.surface,
                                    );
                                  },
                                ),
                              ),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary,
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.surface,
                              ),
                            );
                          }
                        }),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                            child: Obx(() => profileController.isUploadingPhoto.value
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.surface,
                                      ),
                                    ),
                                  )
                                : const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: AppColors.surface,
                                    ),
                                  )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Text(
                        profileController.name.value,
                        style: AppTextStyles.headline4,
                      )),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        profileController.email.value,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Information Card
            Card(
              elevation: 2,
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile Information',
                          style: AppTextStyles.headline6,
                        ),
                        Obx(() => profileController.isEditing.value
                            ? TextButton(
                                onPressed: profileController.cancelEditing,
                                child: const Text('Cancel'),
                              )
                            : IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: profileController.startEditing,
                              )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Obx(() => profileController.isEditing.value
                        ? _buildEditNameField(profileController)
                        : _buildNameDisplay(profileController)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Email', profileController.email.value),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Theme Settings Card
            Card(
              elevation: 2,
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: AppTextStyles.headline6,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => Column(
                      children: [
                        _buildThemeOption(
                          context,
                          themeController,
                          ThemeController.lightMode,
                          'Light Mode',
                          Icons.light_mode_outlined,
                        ),
                        const SizedBox(height: 8),
                        _buildThemeOption(
                          context,
                          themeController,
                          ThemeController.darkMode,
                          'Dark Mode',
                          Icons.dark_mode_outlined,
                        ),
                        const SizedBox(height: 8),
                        _buildThemeOption(
                          context,
                          themeController,
                          ThemeController.systemMode,
                          'System Default',
                          Icons.settings_suggest_outlined,
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account Actions
            Card(
              elevation: 2,
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Actions',
                      style: AppTextStyles.headline6,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text('Logout'),
                      onTap: profileController.logout,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameDisplay(ProfileController controller) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.name.value,
              style: AppTextStyles.body1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditNameField(ProfileController controller) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: controller.editedName.value)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.editedName.value.length),
                ),
              onChanged: (value) => controller.editedName.value = value,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.saveName,
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('Save'),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.body1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeController themeController,
    String themeValue,
    String label,
    IconData icon,
  ) {
    final isSelected = themeController.selectedTheme.value == themeValue;
    
    return InkWell(
      onTap: () => themeController.setTheme(themeValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
