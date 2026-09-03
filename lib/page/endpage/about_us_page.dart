import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/app_info.dart';
import 'package:atomic_notes/utility/component/logo_container.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:flutter/material.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(
        text: "About",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LogoContainer(),
            const SizedBox(height: AppSpace.xl),

            // Masthead block: the colophon data as mono metadata.
            EditorialModule(
              inverted: true,
              padding: const EdgeInsets.all(AppSpace.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonoLabel('BUILD', color: AppColors.signal),
                  const SizedBox(height: AppSpace.sm),
                  EditorialHeading(
                    'Notes, kept\nlocal first.',
                    style: AppType.headlineLg.copyWith(color: AppColors.paper),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(AppInfoText.versionLabel,
                      style: AppType.labelMonoSm
                          .copyWith(color: AppColors.outlineVariant)),
                  Text(AppInfoText.copyright,
                      style: AppType.labelMonoSm
                          .copyWith(color: AppColors.outlineVariant)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('OVERVIEW'),
            const SizedBox(height: AppSpace.md),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "Welcome to Atomic Notes. It keeps note-taking simple and keeps your data yours. Notes live on your device first and sync to the cloud only when you choose. There are no trackers, no ads, and no AI reading your notes.",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "Our Vision:\nCapturing your thoughts should be effortless and private. Turn on end-to-end encryption and every note is sealed with AES-256-GCM using a recovery phrase that never leaves your device, so only you can read them.",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: AppSpace.md, bottom: AppSpace.md),
              child: Text(
                "Key Features:\n**Offline First: Create, edit, and open your notes with no internet connection. Every change saves to your device instantly.\n\n**Optional End-to-End Encryption: Turn it on and your notes are sealed with AES-256-GCM before they leave your device. The recovery phrase never leaves your device, so the server only ever stores unreadable ciphertext.\n\n**No Tracking: No analytics, no crash reporters, no ad SDKs, and no third-party trackers.\n\n**No AI on Your Notes: Your notes are never sent to a model and never used as training data.\n\n**Your Cloud, Your Choice: Cloud sync is optional and fully under your control. Turn it off and your notes stay on this device only.",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "Join Us on this Secure Journey:\nAt Atomic Notes, we invite you to join us on this secure journey of capturing thoughts, making ideas tangible, and staying organized with the utmost privacy. Your feedback is crucial in shaping the future of our Note App, so please reach out and share your thoughts.",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "Thank you for choosing Atomic Notes as your secure note-taking companion. Let's create, capture, and organize securely together!",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "**The operating system may still gather usage data.",
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(7)),
                child: const Text(
                  "App License Agreement",
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "This App License Agreement 'Agreement' is entered into between the end user 'User' and 'Atomic Notes', the creator of the app Atomic Notes. By installing and using the App, the User agrees to the terms and conditions outlined in this Agreement",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: AppSpace.md, bottom: AppSpace.md),
              child: Text(
                "**1. Grant of License: - Atomic grants the User a non-exclusive, non-transferable license to use the App on compatible devices solely for personal or business purposes.\n\n*2. Restrictions: - The User may not reverse engineer, modify, distribute, sell, or sublicense the App.\n - Any attempt to circumvent the security measures of the App is strictly prohibited.\n\n**3. Ownership: - Atomic retains all rights, title, and interest in and to the App, including all intellectual property rights.\n\n**4. Updates: - Atomic may provide updates to the App to enhance functionality or address issues. The User agrees to install these updates promptly.\n\n**5. User Responsibilities: - The User is responsible for maintaining the security of login credentials associated with the App.\n - Any data entered or generated by the User within the App remains the User's property.\n\n**6. Privacy: - Atomic adheres to its Privacy Policy, and the User agrees to the terms outlined in that policy.\n\n**7. Termination: - This license is effective until terminated by the User or Ensync. The User may terminate it at any time by uninstalling the App.\n\n**8. Warranty Disclaimer: - The App is provided 'as is' without warranties of any kind, either express or implied, including, but not limited to, the implied warranties of merchantability, fitness for a particular purpose, or non-infringement.\n\n**9. Limitation of Liability: - Atomic shall not be liable for any direct, indirect, incidental, special, or consequential damages arising out of the use or inability to use the App.\n\n**10. Governing Law: - This Agreement is governed by and construed in accordance with the laws of [User Jurisdiction].\n\n**11. Entire Agreement: - This Agreement constitutes the entire understanding between the User and Atomic Notes and supersedes all prior agreements, whether oral or written.\n\n**Contact Information: - For questions or concerns regarding this Agreement, please contact [devbehindyou@email.com].",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "By installing and using the App, the User acknowledges having read and agreed to the terms and conditions outlined in this License Agreement.",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "Effective Date: 24/12/2023",
                style: AppType.bodyMd,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "Thank you for using our App responsibly and respecting the terms of this License Agreement.",
                style: AppType.bodyMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
