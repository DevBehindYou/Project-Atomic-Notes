import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:flutter/material.dart';

class TCPage extends StatelessWidget {
  const TCPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(text: "TERMS AND CONDITIONS"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('LAST UPDATED 14 AUG 2026'),
            const SizedBox(height: AppSpace.lg),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(7)),
                child: const Text(
                  "AGREEMENT TO OUR LEGAL TERMS",
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'Welcome to use Atomic Notes software and services! The software and services are provided by Atomic Notes Company Limited (hereinafter referred to as "we", "us", "our"). In order to use Atomic Notes software and services (hereinafter referred to as "the Software"), you should read and abide by the "Atomic Notes Terms of Use" (hereinafter referred to as "the Agreement") and the "Atomic Notes Privacy Policy". Please read carefully and fully understand the content of each clause, especially the clauses for exemption or limitation of liability, and the separate agreement for the use of a certain service, and choose to accept or not. Unless you have read and accepted all the terms of this agreement, you have no right to download, install or use this product and related services. Your download, installation, use, login and other actions shall be deemed to have read and agreed to the above agreement',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                "We operate the mobile application Atomic Notes (the 'App'), as well as any other related products and services that refer or link to these legal terms (the 'Legal Terms') (collectively, the 'Services').",
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'Atomic Notes is a local-first note-taking app with optional cloud sync. Notes are saved on your device first and sync to the cloud only when you choose. You can turn on end-to-end encryption, which seals your notes with AES-256-GCM using a recovery phrase that never leaves your device, so only you can read them. The app works fully offline, and you control cloud sync with the cloud sync button. A note contains a title, a body, and a creation date and time. Notes appear in a grid view.',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                "These Legal Terms constitute a legally binding agreement made between you, whether personally or on behalf of an entity ('you'), and Atomic Notes inc, concerning your access to and use of the Services. You agree that by accessing the Services, you have read, understood, and agreed to be bound by all of these Legal Terms. IF YOU DO NOT AGREE WITH ALL OF THESE LEGAL TERMS, THEN YOU ARE EXPRESSLY PROHIBITED FROM USING THE SERVICES AND YOU MUST DISCONTINUE USE IMMEDIATELY.",
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'The Services are intended for users who are at least 13 years of age. All users who are minors in the jurisdiction in which they reside (generally under the age of 18) must have the permission of, and be directly supervised by, their parent or guardian to use the Services. If you are a minor, you must have your parent or guardian read and agree to these Legal Terms prior to you using the Services.',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                '1. The scope of the Agreement',
                style: TextStyle(color: AppColors.onSurface, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: AppSpace.md, bottom: AppSpace.md),
              child: Text(
                '**1.1 The scope of the Agreement This agreement is an agreement between you and us regarding your download, installation, use, copying of this software, and use of Atomic Notes related services.\n\n**1.2 This license agreement points to content The license content under this agreement refers to the Atomic Notes software license and services (hereinafter referred to as "the service") that we provide to users.The content of this agreement also includes relevant agreements and business rules that we may continue to publish on this service. Once the above content is officially released, it is an integral part of this agreement, and you should also abide by it.',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'This Privacy Policy governs the collection, use, and protection of your information by our Note App with Cloud Sync. Please read this policy carefully to understand how we handle your data.',
                style: TextStyle(color: AppColors.onSurface, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: AppSpace.md, bottom: AppSpace.md),
              child: Text(
                '**1. Information Collected: - Your notes (their content), and the basic account information needed to sign in and sync: an email address, a username, and an authentication token. If you turn on end-to-end encryption, note content is stored only as ciphertext that the server cannot read.\n\n**2. Cloud Sync: - Cloud sync is optional. When it is on, your notes are stored in rows scoped to your account by row-level security, so only your signed-in account can read or write them. When it is off, your notes stay on your device.\n\n**3. Data Security: - Data is protected in transit by HTTPS and at rest by row-level access control. With end-to-end encryption enabled, note content is additionally sealed with AES-256-GCM on your device before upload, and the recovery phrase and encryption key never leave your device.\n\n**4. No Analytics or Tracking: - The app contains no analytics, no crash reporters, no advertising SDKs, and no third-party trackers, and it sets no tracking cookies.\n\n**5. No Advertising: - The app does not display ads.\n\n**6. No AI Training: - Your notes are never sent to an AI model and are never used as training data.\n\n**7. Third-Party Services: - The backend uses Supabase (managed Postgres and authentication) to store synced data. Please review the Supabase privacy policy for details on how that infrastructure handles data.\n\n**8. Your Controls: - You can enable or disable cloud sync at any time, and delete your cloud data from the app, so you choose where your notes are stored.\n\n**9. Updates: - This Privacy Policy may be updated to reflect changes in the app. Significant updates will be noted here.\n\n**10. Contact: - For questions about this Privacy Policy, contact devbehindyou@gmail.com.',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'Effective Date: 14-08-2026',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'Thank you for trusting our Atomic Notes App with Cloud Sync. We prioritize the security and privacy of your data to provide you with a seamless note-taking experience.',
                style: AppType.bodyMd,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
