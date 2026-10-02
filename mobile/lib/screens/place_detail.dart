import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum DetailItemType { place, food, activity }

class PlaceDetailScreen extends StatelessWidget {
  final String name;
  final String image;
  final String time;
  final int price;
  final double rating;
  final String description;
  final String destination;
  final int selectedDay;
  final DetailItemType itemType;
  final String location;

  // Food-specific
  final String? meal;
  final String? dishes;

  // Activity-specific
  final String? duration;

  const PlaceDetailScreen({
    super.key,
    required this.name,
    required this.image,
    required this.time,
    required this.price,
    required this.rating,
    required this.description,
    required this.destination,
    required this.selectedDay,
    required this.itemType,
    required this.location,
    this.meal,
    this.dishes,
    this.duration,
  });

  String get typeLabel {
    switch (itemType) {
      case DetailItemType.place:
        return 'Place';
      case DetailItemType.food:
        return 'Food';
      case DetailItemType.activity:
        return 'Activity';
    }
  }

  IconData get typeIcon {
    switch (itemType) {
      case DetailItemType.place:
        return Icons.place_outlined;
      case DetailItemType.food:
        return Icons.restaurant_outlined;
      case DetailItemType.activity:
        return Icons.local_activity_outlined;
    }
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final searchQuery = '$name, $location';

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(searchQuery)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } catch (e) {
      debugPrint('Google Maps error: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ============================================================
            // HERO IMAGE
            // ============================================================

            Stack(
              children: [
                SizedBox(
                  height: 330,
                  width: double.infinity,
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(
                                  typeIcon,
                                  size: 55,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(typeIcon, size: 55, color: Colors.grey),
                          ),
                        ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 45,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 19,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ============================================================
            // MAIN CONTENT
            // ============================================================
            Transform.translate(
              offset: const Offset(0, -35),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ======================================================
                    // TAGS
                    // ======================================================

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(
                          icon: Icons.location_on_outlined,
                          text: destination,
                          purple: true,
                        ),
                        _buildTag(
                          icon: typeIcon,
                          text: typeLabel,
                          purple: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ======================================================
                    // NAME
                    // ======================================================
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 9),

                    // ======================================================
                    // RATING
                    // ======================================================
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 21,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ======================================================
                    // DESCRIPTION
                    // ======================================================
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ======================================================
                    // ESSENTIAL INFO
                    // ======================================================
                    const Text(
                      'Essential Info',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.currency_rupee,
                            title: 'Price',
                            value: price == 0 ? 'Free' : '₹$price',
                            subtitle: itemType == DetailItemType.food
                                ? 'Estimated cost per person'
                                : price == 0
                                ? 'No entry fee'
                                : 'Estimated cost',
                          ),

                          const SizedBox(height: 18),

                          _buildInfoRow(
                            icon: Icons.access_time_rounded,
                            title: itemType == DetailItemType.food
                                ? 'Meal Time'
                                : 'Suggested Time',
                            value: time,
                            subtitle: itemType == DetailItemType.food
                                ? meal ?? 'Meal'
                                : 'Recommended time',
                          ),

                          if (itemType == DetailItemType.activity &&
                              duration != null &&
                              duration!.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _buildInfoRow(
                              icon: Icons.timelapse_rounded,
                              title: 'Duration',
                              value: duration!,
                              subtitle: 'Recommended activity duration',
                            ),
                          ],

                          if (itemType == DetailItemType.food &&
                              dishes != null &&
                              dishes!.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _buildInfoRow(
                              icon: Icons.restaurant_menu_outlined,
                              title: 'Dishes',
                              value: dishes!,
                              subtitle: 'Recommended food',
                            ),
                          ],

                          if (itemType == DetailItemType.place) ...[
                            const SizedBox(height: 18),
                            _buildInfoRow(
                              icon: Icons.timelapse_rounded,
                              title: 'Suggested Duration',
                              value: '1 - 3 Hours',
                              subtitle: 'Recommended time to explore',
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ======================================================
                    // FOOD DETAILS
                    // ======================================================
                    if (itemType == DetailItemType.food) ...[
                      const SizedBox(height: 25),

                      Row(
                        children: [
                          _buildAITag(),
                          const SizedBox(width: 8),
                          const Text(
                            'Food Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (meal != null && meal!.isNotEmpty) ...[
                              _buildAISuggestion('Recommended for $meal'),
                              const SizedBox(height: 12),
                            ],
                            if (dishes != null && dishes!.isNotEmpty)
                              _buildAISuggestion('Try: $dishes'),
                          ],
                        ),
                      ),
                    ],

                    // ======================================================
                    // THINGS TO DO
                    // ======================================================
                    if (itemType == DetailItemType.place) ...[
                      const SizedBox(height: 25),

                      const Text(
                        'Things to Do',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildActivityItem(
                              icon: Icons.camera_alt_outlined,
                              title: 'Take Photos',
                              description:
                                  'Capture the highlights and surroundings.',
                            ),
                            const SizedBox(height: 16),
                            _buildActivityItem(
                              icon: Icons.directions_walk_outlined,
                              title: 'Explore the Area',
                              description: 'Walk around and discover nearby attractions.',
                            ),
                            const SizedBox(height: 16),
                            _buildActivityItem(
                              icon: Icons.restaurant_outlined,
                              title: 'Try Local Food',
                              description: 'Experience popular local food and specialties.',
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ======================================================
                    // ACTIVITY DETAILS
                    // ======================================================
                    if (itemType == DetailItemType.activity) ...[
                      const SizedBox(height: 25),

                      Row(
                        children: [
                          _buildAITag(),
                          const SizedBox(width: 8),
                          const Text(
                            'Activity Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAISuggestion('Scheduled for $time'),
                            const SizedBox(height: 12),
                            if (duration != null && duration!.isNotEmpty)
                              _buildAISuggestion(
                                'Expected duration: $duration',
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 25),

                    // ======================================================
                    // AI REVIEW SUMMARY
                    // ======================================================
                    Row(
                      children: [
                        _buildAITag(),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Review Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAISuggestion('Popular option among visitors'),
                          const SizedBox(height: 12),
                          _buildAISuggestion(
                            'Best experienced during the recommended time',
                          ),
                          const SizedBox(height: 12),
                          _buildAISuggestion(
                            'Good match for your selected itinerary',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ======================================================
                    // LOCATION
                    // ======================================================
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Map preview
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: const Color(0xFFE9E7EF),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 70,
                                  color: Colors.deepPurple.shade200,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.deepPurple,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        location,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _openGoogleMaps(context);
                                },
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text(
                                  'VIEW ON MAP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  side: const BorderSide(
                                    color: Colors.deepPurple,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ======================================================
                    // WHY AI RECOMMENDS THIS
                    // ======================================================
                    Row(
                      children: [
                        _buildAITag(),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Why AI Recommends This',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This $typeLabel was selected for Day '
                            '$selectedDay because it fits well with '
                            'your trip to $destination.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          _buildAISuggestion('Fits your selected itinerary'),

                          const SizedBox(height: 11),

                          _buildAISuggestion('Matches your available time'),

                          const SizedBox(height: 11),

                          _buildAISuggestion(
                            'Provides a good experience for this destination',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required bool purple,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: purple
            ? Colors.deepPurple.withValues(alpha: 0.10)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: purple ? Colors.deepPurple : Colors.grey.shade700,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: purple ? Colors.deepPurple : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: Colors.deepPurple),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.deepPurple),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAITag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Colors.deepPurple),
          SizedBox(width: 5),
          Text(
            'AI INSIGHT',
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestion(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
