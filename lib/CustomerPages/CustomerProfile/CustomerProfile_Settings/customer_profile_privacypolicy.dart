import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for fonts

class CustomerProfilePrivacypolicy extends StatelessWidget {
  const CustomerProfilePrivacypolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.roboto(
            // Apply Roboto font
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.blueAccent, // Set AppBar background color
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // Change to arrow_back_ios_new
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Policy Title with BebasNeue font below the AppBar
            Text(
              'PRIVACY POLICY',
              style: GoogleFonts.bebasNeue(
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Types of Data We Collect
            Text(
              '1. Types of Data We Collect',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We collect various types of information to ensure the best possible experience for both customers and workers using our platform. This includes:',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Personal Identification Information: Name, email address, phone number, and other contact details provided during the registration process.'),
            _buildBulletPoint('Profile Information: Information you provide when creating a profile, including your bio, profile picture, and qualifications (for workers).'),
            _buildBulletPoint('Service-Related Information: Details about the services you provide (for workers) or seek (for customers), such as service descriptions, pricing, availability, and offers.'),
            _buildBulletPoint('Communication Data: Any messages, reviews, or feedback exchanged between users, including inquiries and responses related to service listings.'),
            _buildBulletPoint('Usage Data: Information on how you interact with the app, such as search history, service selections, offers made or accepted, and other in-app activities.'),
            _buildBulletPoint('Technical Data: Data related to the device and network you use to access our app, such as IP address, browser type, operating system, and app version.'),

            const SizedBox(height: 16),

            // Section 2: Use of Your Personal Data
            Text(
              '2. Use of Your Personal Data',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The personal data we collect is utilized to:',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Match Customers and Workers: Facilitate the process of connecting customers with suitable workers based on service requests, offers, and availability.'),
            _buildBulletPoint('Enhance User Experience: Personalize your experience by suggesting services or listings that match your preferences and past interactions.'),
            _buildBulletPoint('Communication and Notifications: Send you updates, notifications, and communications related to your account, service requests, offers, or other app-related activities.'),
            _buildBulletPoint('Review and Rating System: Enable customers and workers to leave reviews and ratings after a service is completed, contributing to the overall trust and quality of the platform.'),
            _buildBulletPoint('Security and Integrity: Monitor activities within the app to prevent fraud, abuse, or any other activities that could compromise the security and integrity of the platform.'),
            _buildBulletPoint('Analytics and Improvements: Analyze usage patterns and user behavior to improve our app\'s features, design, and performance.'),

            const SizedBox(height: 16),

            // Section 3: Disclosure of Your Personal Data
            Text(
              '3. Disclosure of Your Personal Data',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We may disclose your personal data in the following circumstances:',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Service Providers and Partners: We may share your data with third-party service providers who assist us in operating our platform, providing customer support, or analyzing data to improve our services.'),
            _buildBulletPoint('Legal Compliance: If required by law, or to comply with legal processes, we may disclose your information to governmental authorities or other relevant parties.'),
            _buildBulletPoint('Protection of Rights: We may disclose your data if we believe it\'s necessary to enforce our terms of service, protect our rights, users, or others from harm, or investigate potential violations.'),
            _buildBulletPoint('Business Transfers: In the event of a merger, acquisition, or sale of all or a portion of our assets, your data may be transferred as part of that transaction, subject to the same privacy protections.'),
            _buildBulletPoint('With Your Consent: We may share your data in other ways if you provide explicit consent.'),

            const SizedBox(height: 16),

            // Section 4: Encouragement to Transact Within the App
            Text(
              '4. Transact Within the App',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For your safety and the integrity of our platform, we strongly encourage all users to conduct their interactions and agreements within the app. This ensures that we can monitor and verify all exchanges, which is crucial for investigating and resolving any disputes or issues that may arise. Interactions or transactions conducted outside the app are beyond our control, and we cannot be held responsible for any problems that may occur in such cases.',
              style: GoogleFonts.roboto(fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Section 5: Data Security
            Text(
              '5. Data Security',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We take your privacy and data security seriously. We implement a variety of security measures to protect your personal information from unauthorized access, disclosure, alteration, or destruction. However, no method of transmission over the Internet or electronic storage is completely secure, and we cannot guarantee absolute security.',
              style: GoogleFonts.roboto(fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Section 6: Retention of Data
            Text(
              '6. Retention of Data',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will retain your personal data only as long as necessary to fulfill the purposes outlined in this privacy policy, comply with legal obligations, resolve disputes, and enforce our agreements. Once your data is no longer needed, we will securely delete or anonymize it.',
              style: GoogleFonts.roboto(fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Section 7: Your Rights and Choices
            Text(
              '7. Your Rights and Choices',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have certain rights regarding your personal data, including:',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            _buildBulletPoint('Access and Correction: You can access and update your personal information at any time through your account settings.'),
            _buildBulletPoint('Data Portability: You may request a copy of your personal data in a structured, commonly used, and machine-readable format.'),
            _buildBulletPoint('Deletion: You can request the deletion of your personal data, subject to certain legal obligations or our legitimate business needs.'),
            _buildBulletPoint('Consent Withdrawal: You can withdraw your consent for data processing at any time, although this may affect your ability to use certain features of the app.'),
            _buildBulletPoint('Objections and Complaints: You have the right to object to our processing of your personal data or file a complaint with a data protection authority.'),

            const SizedBox(height: 16),

            // Section 8: Changes to This Privacy Policy
            Text(
              '8. Changes to This Privacy Policy',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We may update this privacy policy from time to time. When we do, we will post the updated version on our platform and notify you through the app. We encourage you to review the privacy policy periodically to stay informed about how we are protecting your personal data.',
              style: GoogleFonts.roboto(fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Section 9: Contact Us
            Text(
              '9. Contact Us',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have any questions or concerns about this privacy policy or our data practices, please contact us at 09165307504.',
              style: GoogleFonts.roboto(fontSize: 14),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method for creating bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
