import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for fonts

class WorkerProfileTerms extends StatelessWidget {
  const WorkerProfileTerms({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // AppBar background color
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
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
            // Terms of Service Title
            Text(
              'TERMS OF SERVICE',
              style: GoogleFonts.bebasNeue(
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // Spacing between title and the first section

            // Section 1: Acceptance of Terms
            _buildSectionTitle('1. Acceptance of Terms'),
            _buildParagraph(
                'By registering for, accessing, or using the app, you agree to comply with and be legally bound by these Terms, as well as our Privacy Policy. If you do not agree to these Terms, you must not use the app.'),

            // Section 2: Eligibility
            _buildSectionTitle('2. Eligibility'),
            _buildParagraph(
                'To use the app, you must be at least 18 years old and have the legal capacity to enter into a binding contract. By using the app, you represent and warrant that you meet these requirements.'),

            // Section 3: Account Registration
            _buildSectionTitle('3. Account Registration'),
            _buildBulletPoint('Account Creation: To access certain features of the app, including posting or requesting services, you must create an account. You agree to provide accurate and complete information during the registration process and to keep your account information up to date.'),
            _buildBulletPoint('Account Security: You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must immediately notify us of any unauthorized use of your account.'),
            _buildBulletPoint('Prohibited Activities: You agree not to use the app for any illegal or unauthorized purpose, or to engage in any activity that violates these Terms.'),

            // Section 4: Use of the App
            _buildSectionTitle('4. Use of the App'),
            _buildBulletPoint('Service Listings: Workers may list services they offer, including descriptions, pricing, and availability. Customers can search for and select services that meet their needs.'),
            _buildBulletPoint('Matching Process: The app facilitates the connection between customers and workers. Once a customer selects a service, they can make an offer, which the worker can accept or decline.'),
            _buildBulletPoint('Reviews and Ratings: After a service is completed, both customers and workers are encouraged to leave reviews and ratings to help maintain the quality and trustworthiness of the platform.'),
            _buildBulletPoint('Prohibited Content: You agree not to post, upload, or share any content that is offensive, defamatory, obscene, or otherwise violates the rights of others or applicable laws.'),

            // Section 5: Transactions and Payments
            _buildSectionTitle('5. Transactions and Payments'),
            _buildBulletPoint('No Payment Processing: The app does not process payments or provide any payment methods within the platform. All financial transactions between customers and workers must be handled independently outside of the app.'),
            _buildBulletPoint('Encouragement to Transact Within the App: We strongly encourage users to conduct interactions and agreements within the app to ensure a record of the transaction and to facilitate dispute resolution if necessary.'),

            // Section 6: User Responsibilities
            _buildSectionTitle('6. User Responsibilities'),
            _buildBulletPoint('Compliance with Laws: You agree to comply with all applicable laws, regulations, and ordinances in connection with your use of the app and the services offered or requested.'),
            _buildBulletPoint('Truthful Information: You agree to provide accurate and truthful information in your profile, service listings, and communications with other users.'),
            _buildBulletPoint('No Guarantee of Services: While we strive to connect customers with reliable workers, we do not guarantee the quality, safety, or legality of the services provided by workers or the accuracy of any listings.'),

            // Section 7: Termination and Suspension
            _buildSectionTitle('7. Termination and Suspension'),
            _buildBulletPoint('Termination by You: You may terminate your account at any time by contacting us or through the account settings in the app.'),
            _buildBulletPoint('Termination by Us: We reserve the right to suspend or terminate your account at our discretion if we believe you have violated these Terms or engaged in any behaviour that is harmful to the platform or its users.'),
            _buildBulletPoint('Effect of Termination: Upon termination of your account, your right to access and use the app will immediately cease. All provisions of these Terms that by their nature should survive termination shall survive.'),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method for section titles
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // Helper method for paragraphs
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: GoogleFonts.roboto(fontSize: 14),
      ),
    );
  }

  // Helper method for bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
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
