import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1000;

    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A), // Modern Deep Black/Gray
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          // Main Content Row
          isMobile
              ? Column(children: _buildFooterSections())
              : Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.spaceEvenly,
                  children: _buildFooterSections(),
                ),

          const Divider(color: Colors.white10, height: 60),

          // Bottom Bar
          isMobile
              ? Column(
                  children: [
                    const Text(
                      '© 2025 Click & Fix. All rights reserved.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIcon(Icons.facebook),
                        _socialIcon(Icons.camera_alt_outlined),
                        _socialIcon(Icons.alternate_email),
                      ],
                    )
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '© 2025 Click & Fix. All rights reserved.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    Row(
                      children: [
                        _socialIcon(Icons.facebook),
                        _socialIcon(Icons.camera_alt_outlined), // Instagram
                        _socialIcon(Icons.alternate_email), // Twitter/X
                      ],
                    )
                  ],
                ),
        ],
      ),
    );
  }

  List<Widget> _buildFooterSections() {
    return [
      _footerColumn(
        'CLICK & FIX',
        [
          'Our mission is to make appliance repair easy, accessible, and affordable for everyone through smart technology.',
        ],
        isBrand: true,
      ),
      _footerColumn(
        'Quick Links',
        ['About Us', 'Repair Services', 'DIY Guides', 'Technician Support'],
      ),
      _footerColumn(
        'Support',
        ['Privacy Policy', 'Terms of Service', 'Contact Support', 'FAQs'],
      ),
    ];
  }

  Widget _footerColumn(String title, List<String> items, {bool isBrand = false}) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isBrand ? const Color(0xFF0061FF) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Icon(icon, color: Colors.white38, size: 20),
      ),
    );
  }
}