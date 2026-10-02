// ignore_for_file: control_flow_in_finally

import 'package:flutter/material.dart';
import 'package:tourkare/screens/place_detail.dart';
import 'package:tourkare/services/api_service.dart';
import 'package:tourkare/services/database_service.dart';

class ItineraryScreen extends StatefulWidget {
  final int localTripId;
  final String destination;
  final int numberOfDays;
  final String budget;
  final List<String> interests;
  final String? selectedFoodPreference;

  const ItineraryScreen({
    super.key,
    required this.localTripId,
    required this.destination,
    required this.numberOfDays,
    required this.budget,
    required this.interests,
    this.selectedFoodPreference,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  bool isRegeneratingDay = false;
  String? regeneratingItemKey;
  int selectedDay = 1;

  Map<int, Map<String, dynamic>> itineraryData = {};
  double? backendEstimatedCost;
  bool isLoadingItinerary = true;
  String? itineraryError;

  @override
  void initState() {
    super.initState();
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    try {
      final response = await DatabaseService.getItinerary(widget.localTripId);

      if (response == null) {
        throw Exception('No saved itinerary found');
      }

      final rawItineraryData = response['itineraryData'];

      if (rawItineraryData is! Map) {
        throw Exception('Saved itinerary has an invalid format');
      }

      final converted = <int, Map<String, dynamic>>{};

      rawItineraryData.forEach((key, value) {
        final dayNumber = int.tryParse(key.toString());

        if (dayNumber != null && value is Map) {
          converted[dayNumber] = Map<String, dynamic>.from(value);
        }
      });

      if (converted.isEmpty) {
        throw Exception('Saved itinerary contains no days');
      }

      final savedEstimatedCost = response['estimated_cost'];
      final estimatedCost = savedEstimatedCost is num
          ? savedEstimatedCost.toDouble()
          : null;

      if (!mounted) return;

      setState(() {
        itineraryData = converted;
        backendEstimatedCost = estimatedCost;
        isLoadingItinerary = false;
        itineraryError = null;

        if (!itineraryData.containsKey(selectedDay)) {
          selectedDay = itineraryData.keys.reduce((a, b) => a < b ? a : b);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingItinerary = false;
        itineraryError = 'Failed to load your saved itinerary.';
      });

      debugPrint('Load itinerary error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingItinerary) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          title: const Text(
            'Your Itinerary',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (itineraryError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          title: const Text(
            'Your Itinerary',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 52,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  itineraryError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoadingItinerary = true;
                      itineraryError = null;
                    });
                    _loadItinerary();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentDayData =
        itineraryData[selectedDay] ??
        {
          'title': 'Explore ${widget.destination}',
          'places': [],
          'food': [],
          'activities': [],
        };

    final double estimatedCost =
        backendEstimatedCost ?? _getCalculatedTotalCost();

    final double budgetAmount =
        double.tryParse(widget.budget.replaceAll(',', '')) ?? 0;

    final double budgetPercentage = budgetAmount > 0
        ? (estimatedCost / budgetAmount).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),

        title: const Text(
          'Your Itinerary',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),

        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ========================================================
            // TRIP HEADER
            // ========================================================

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Color(0xFF7E57C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.card_travel,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        '${widget.numberOfDays} Days',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    widget.destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'A personalized trip planned around your interests',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  // Budget
                  Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 21,
                        ),

                        const SizedBox(width: 10),

                        const Text(
                          'Budget',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),

                        const Spacer(),

                        Text(
                          '₹${widget.budget}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ========================================================
            // BUDGET STATUS
            // ========================================================
            Row(
              children: [
                const Text(
                  'Estimated Cost',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                Text(
                  '₹${estimatedCost.toStringAsFixed(0)} / ₹${widget.budget}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),

              child: LinearProgressIndicator(
                value: budgetPercentage,
                minHeight: 9,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.deepPurple,
                ),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              estimatedCost <= budgetAmount
                  ? 'Your itinerary is within your budget'
                  : 'Your itinerary exceeds your budget',
              style: TextStyle(
                fontSize: 12,
                color: estimatedCost <= budgetAmount
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 28),

            // ========================================================
            // DAY NAVIGATION
            // ========================================================
            const Text(
              'Your Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 48,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                itemCount: widget.numberOfDays,

                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = selectedDay == day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                      });
                    },

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),

                      margin: const EdgeInsets.only(right: 10),

                      padding: const EdgeInsets.symmetric(horizontal: 18),

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepPurple : Colors.white,

                        borderRadius: BorderRadius.circular(15),

                        border: Border.all(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade200,
                        ),
                      ),

                      child: Text(
                        'Day $day',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,

                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // ========================================================
            // CURRENT DAY
            // ========================================================
            Text(
              'Day $selectedDay',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              currentDayData['title'] ?? 'Discover ${widget.destination}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 25),

            const Text(
              'Itinerary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            ...((currentDayData['places'] ?? []) as List).asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final place = entry.value;
              return _buildPlaceCard(
                name: place['name'],
                image: place['image'],
                location: place['location'],
                time: place['time'],
                price: (place['price'] as num?)?.toInt() ?? 0,
                rating: (place['rating'] as num?)?.toDouble() ?? 0.0,
                description: place['description'],
                itemIndex: index,
              );
            }),

            const SizedBox(height: 10),

            const Text(
              'Food',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...((currentDayData['food'] ?? []) as List).asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final foods = entry.value;
              return _buildFoodCard(
                restaurant: foods['restaurant'],
                image: foods['image'],
                location: foods['location'],
                meal: foods['meal'],
                time: foods['time'],
                price: (foods['price'] as num?)?.toInt() ?? 0,
                rating: (foods['rating'] as num?)?.toDouble() ?? 0.0,
                dishes: foods['dishes'],
                itemIndex: index,
              );
            }),

            const SizedBox(height: 25),

            const Text(
              'Activities & Adventure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...((currentDayData['activities'] ?? []) as List)
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  return _buildActivityCard(
                    name: activity['name'],
                    image: activity['image'],
                    location: activity['location'],
                    time: activity['time'],
                    duration: activity['duration'],
                    price: (activity['price'] as num?)?.toInt() ?? 0,
                    rating: (activity['rating'] as num?)?.toDouble() ?? 0.0,
                    description: activity['description'],
                    itemIndex: index,
                  );
                }),

            const SizedBox(height: 25),

            const SizedBox(height: 10),

            _buildDayCostCard(),

            const SizedBox(height: 25),

            // ========================================================
            // REGENERATE DAY
            // ========================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isRegeneratingDay || regeneratingItemKey != null
                    ? null
                    : _regenerateSelectedDay,

                icon: isRegeneratingDay
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurple,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.deepPurple),

                label: Text(
                  isRegeneratingDay ? 'Regenerating...' : 'Regenerate Day',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ========================================================
            // REGENERATE WHOLE TRIP
            // ========================================================
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  // Backend regeneration will be added later.
                },

                icon: const Icon(Icons.auto_awesome),

                label: const Text(
                  'Regenerate Entire Trip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DAY TITLE
  // ================================================================

  double _getDayCost(int day) {
    final dayData = itineraryData[day];

    if (dayData == null) return 0;

    double total = 0;

    final places = dayData['places'];
    if (places is List) {
      for (final place in places) {
        if (place is Map && place['price'] is num) {
          total += (place['price'] as num).toDouble();
        }
      }
    }

    final food = dayData['food'];
    if (food is List) {
      for (final item in food) {
        if (item is Map && item['price'] is num) {
          total += (item['price'] as num).toDouble();
        }
      }
    }

    final activities = dayData['activities'];
    if (activities is List) {
      for (final activity in activities) {
        if (activity is Map && activity['price'] is num) {
          total += (activity['price'] as num).toDouble();
        }
      }
    }

    return total;
  }

  double _getCalculatedTotalCost() {
    double total = 0;

    for (final day in itineraryData.keys) {
      total += _getDayCost(day);
    }

    return total;
  }

  Widget _buildPlaceCard({
    required String name,
    required String image,
    required String time,
    required int price,
    required double rating,
    required String description,
    required int itemIndex,
    required String location,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(
              name: name,
              image: image,
              time: time,
              price: price,
              rating: rating,
              description: description,
              destination: widget.destination,
              selectedDay: selectedDay, itemType: DetailItemType.place, location: location,
            ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 650;

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,

            child: isWide
                ? SizedBox(
                    height: 250,

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // =========================
                        // IMAGE
                        // =========================
                        Expanded(
                          flex: 4,

                          child: Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: double.infinity,

                                child: Image.network(
                                  image,
                                  fit: BoxFit.cover,

                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,

                                      child: const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 45,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Price
                              Positioned(
                                left: 12,
                                bottom: 12,

                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),

                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: Text(
                                    price == 0 ? 'Free' : '₹$price',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // =========================
                        // DETAILS
                        // =========================
                        Expanded(
                          flex: 6,

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                // Name + menu
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    PopupMenuButton<String>(
                                      enabled: regeneratingItemKey == null && !isRegeneratingDay,
                                      icon: regeneratingItemKey == 'place_$itemIndex'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.deepPurple,
                                              ),
                                            )
                                          : null,
                                      onSelected: (value) {
                                        if (value == 'regenerate') {
                                          _regenerateItem(
                                            itemType: 'place',
                                            itemIndex: itemIndex,
                                          );
                                        }

                                        if (value == 'delete') {
                                          _deleteItem(
                                            itemType: "place",
                                            itemIndex: itemIndex,
                                          );
                                        }
                                      },

                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'regenerate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.auto_awesome_outlined),
                                              SizedBox(width: 10),
                                              Text('Regenerate'),
                                            ],
                                          ),
                                        ),

                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_sharp),
                                              SizedBox(width: 10),
                                              Text('Remove'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 7),

                                // Rating
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),

                                    const SizedBox(width: 4),

                                    Text(
                                      rating.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Timing
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: Colors.deepPurple,
                                    ),

                                    const SizedBox(width: 7),

                                    Expanded(
                                      child: Text(
                                        time,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Description
                                Expanded(
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                // =====================================================
                // MOBILE
                // =====================================================
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // Image
                      Stack(
                        children: [
                          SizedBox(
                            height: 190,
                            width: double.infinity,

                            child: Image.network(
                              image,
                              fit: BoxFit.cover,

                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,

                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 45,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Price
                          Positioned(
                            left: 12,
                            bottom: 12,

                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Text(
                                price == 0 ? 'Free' : '₹$price',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Details
                      Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            // Name + menu
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                PopupMenuButton<String>(
                                      enabled: regeneratingItemKey == null && !isRegeneratingDay,
                                      icon: regeneratingItemKey == 'place_$itemIndex'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.deepPurple,
                                              ),
                                            )
                                          : null,
                                  onSelected: (value) {
                                    if (value == 'regenerate') {
                                      _regenerateItem(
                                        itemType: "place",
                                        itemIndex: itemIndex,
                                      );
                                    }

                                    if (value == 'delete') {
                                      _deleteItem(
                                        itemType: "place",
                                        itemIndex: itemIndex,
                                      );
                                    }
                                  },

                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'regenerate',
                                      child: Row(
                                        children: [
                                          Icon(Icons.auto_awesome_outlined),
                                          SizedBox(width: 10),
                                          Text('Regenerate'),
                                        ],
                                      ),
                                    ),

                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_sharp),
                                          SizedBox(width: 10),
                                          Text('Remove'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 7),

                            // Rating
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),

                                const SizedBox(width: 4),

                                Text(
                                  rating.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Timing
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: Colors.deepPurple,
                                ),

                                const SizedBox(width: 7),

                                Expanded(
                                  child: Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.45,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFoodCard({
    required String restaurant,
    required String image,
    required String meal,
    required String time,
    required int price,
    required double rating,
    required String dishes,
    required int itemIndex,
    required String location,
  }) {
    return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailScreen(
          name: restaurant,
          image: image,
          time: time,
          price: price,
          rating: rating,
          description: dishes,
          destination: widget.destination,
          selectedDay: selectedDay,
          itemType: DetailItemType.food,
          location: location,
          meal: meal,
        ),
      ),
    );
  },
  child: LayoutBuilder(
    builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 650;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),

          clipBehavior: Clip.antiAlias,

          child: isWide
              // =====================================================
              // WIDE
              // =====================================================
              ? SizedBox(
                  height: 220,

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // Image
                      Expanded(
                        flex: 4,

                        child: Image.network(
                          image,
                          fit: BoxFit.cover,

                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,

                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_outlined,
                                  size: 45,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Details
                      Expanded(
                        flex: 6,

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      restaurant,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  PopupMenuButton<String>(
                                      enabled: regeneratingItemKey == null && !isRegeneratingDay,
                                      icon: regeneratingItemKey == 'food_$itemIndex'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.deepPurple,
                                              ),
                                            )
                                          : null,
                                    onSelected: (value) {
                                      if (value == 'regenerate') {
                                        _regenerateItem(
                                          itemType: "food",
                                          itemIndex: itemIndex,
                                        );
                                      }

                                      if (value == 'delete') {
                                        _deleteItem(
                                          itemType: "food",
                                          itemIndex: itemIndex,
                                        );
                                      }
                                    },

                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'regenerate',

                                        child: Row(
                                          children: [
                                            Icon(Icons.auto_awesome_outlined),
                                            SizedBox(width: 10),
                                            Text('Regenerate'),
                                          ],
                                        ),
                                      ),

                                      PopupMenuItem(
                                        value: 'delete',

                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_sharp),
                                            SizedBox(width: 10),
                                            Text('Remove'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Meal
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),

                                child: Text(
                                  meal,
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Rating
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 19,
                                  ),

                                  const SizedBox(width: 4),

                                  Text(
                                    rating.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 9),

                              // Time
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_outlined,
                                    size: 17,
                                    color: Colors.deepPurple,
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    time,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 9),

                              // Dishes
                              Text(
                                dishes,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const Spacer(),

                              // Price
                              Row(
                                children: [
                                  const Icon(
                                    Icons.currency_rupee,
                                    size: 18,
                                    color: Colors.deepPurple,
                                  ),

                                  Text(
                                    '$price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const Text(
                                    ' / person',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
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
                )
              // =====================================================
              // MOBILE
              // =====================================================
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // Image
                    SizedBox(
                      height: 180,
                      width: double.infinity,

                      child: Image.network(
                        image,
                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,

                            child: const Center(
                              child: Icon(
                                Icons.restaurant_outlined,
                                size: 45,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              PopupMenuButton<String>(
                                      enabled: regeneratingItemKey == null && !isRegeneratingDay,
                                      icon: regeneratingItemKey == 'food_$itemIndex'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.deepPurple,
                                              ),
                                            )
                                          : null,
                                onSelected: (value) {
                                  if (value == 'regenerate') {
                                    _regenerateItem(
                                      itemType: "food",
                                      itemIndex: itemIndex,
                                    );
                                  }

                                  if (value == 'delete') {
                                    _deleteItem(
                                      itemType: "food",
                                      itemIndex: itemIndex,
                                    );
                                  }
                                },

                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'regenerate',

                                    child: Row(
                                      children: [
                                        Icon(Icons.auto_awesome_outlined),
                                        SizedBox(width: 10),
                                        Text('Regenerate'),
                                      ],
                                    ),
                                  ),

                                  PopupMenuItem(
                                    value: 'delete',

                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_sharp),
                                        SizedBox(width: 10),
                                        Text('Remove'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Meal
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Text(
                              meal,
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 19,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_outlined,
                                size: 17,
                                color: Colors.deepPurple,
                              ),

                              const SizedBox(width: 6),

                              Text(time, style: const TextStyle(fontSize: 12)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Dishes
                          Text(
                            dishes,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Price
                          Row(
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                size: 18,
                                color: Colors.deepPurple,
                              ),

                              Text(
                                '$price',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Text(
                                ' / person',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    ));
  }

  Widget _buildActivityCard({
    required String name,
    required String image,
    required String time,
    required String duration,
    required int price,
    required double rating,
    required String description,
    required int itemIndex,
    required String location,
  }) {
    return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailScreen(
          name: name,
          image: image,
          time: time,
          price: price,
          rating: rating,
          description: description,
          destination: widget.destination,
          selectedDay: selectedDay,
          itemType: DetailItemType.activity,
          location: location,
          duration: duration,
        ),
      ),
    );
  },
  child: LayoutBuilder(
    builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 650;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,

          child: isWide
              ? SizedBox(
                  height: 230,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =========================
                      // IMAGE
                      // =========================
                      Expanded(
                        flex: 4,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.landscape_outlined,
                                        size: 45,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Price
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  price == 0 ? 'Free' : '₹$price',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =========================
                      // DETAILS
                      // =========================
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + menu
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  PopupMenuButton<String>(
                                      enabled: regeneratingItemKey == null && !isRegeneratingDay,
                                      icon: regeneratingItemKey == 'activity_$itemIndex'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.deepPurple,
                                              ),
                                            )
                                          : null,
                                    onSelected: (value) {
                                      if (value == 'regenerate') {
                                        _regenerateItem(
                                          itemType: "activity",
                                          itemIndex: itemIndex,
                                        );
                                      }

                                      if (value == 'delete') {
                                        _deleteItem(
                                          itemType: "activity",
                                          itemIndex: itemIndex,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'regenerate',
                                        child: Row(
                                          children: [
                                            Icon(Icons.auto_awesome_outlined),
                                            SizedBox(width: 10),
                                            Text('Regenerate'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_sharp),
                                            SizedBox(width: 10),
                                            Text('Remove'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 7),

                              // Rating
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Time
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Duration
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timelapse,
                                    size: 18,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    duration,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Description
                              Expanded(
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              // =====================================================
              // MOBILE
              // =====================================================
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Stack(
                      children: [
                        SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.landscape_outlined,
                                    size: 45,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Price
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              price == 0 ? 'Free' : '₹$price',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + menu
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              PopupMenuButton<String>(
                                      enabled: regeneratingItemKey == null && !isRegeneratingDay,
                                      icon: regeneratingItemKey == 'activity_$itemIndex'
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.deepPurple,
                                              ),
                                            )
                                          : null,
                                onSelected: (value) {
                                  if (value == 'regenerate') {
                                    _regenerateItem(
                                      itemType: "activity",
                                      itemIndex: itemIndex,
                                    );
                                  }

                                  if (value == 'delete') {
                                    _deleteItem(
                                      itemType: "activity",
                                      itemIndex: itemIndex,
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'regenerate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.auto_awesome_outlined),
                                        SizedBox(width: 10),
                                        Text('Regenerate'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_sharp),
                                        SizedBox(width: 10),
                                        Text('Remove'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 7),

                          // Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Duration
                          Row(
                            children: [
                              const Icon(
                                Icons.timelapse,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                duration,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Description
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    ));
  }

  Widget _buildDayCostCard() {
    final double dayCost = _getDayCost(selectedDay);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.08),
            Colors.deepPurple.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day Cost',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                SizedBox(height: 3),
                Text(
                  'Total estimated cost for this day',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            '₹${dayCost.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _fullItineraryForRequest() {
    return {
      for (final entry in itineraryData.entries)
        entry.key.toString(): Map<String, dynamic>.from(entry.value),
    };
  }

  double _calculateItineraryCost(
    Map<String, dynamic> data,
  ) {
    double total = 0;

    for (final day in data.values) {
      if (day is! Map) continue;

      final places = day['places'];
      if (places is List) {
        for (final item in places) {
          if (item is Map) {
            total += (item['price'] as num?)?.toDouble() ?? 0;
          }
        }
      }

      final food = day['food'];
      if (food is List) {
        for (final item in food) {
          if (item is Map) {
            total += (item['price'] as num?)?.toDouble() ?? 0;
          }
        }
      }

      final activities = day['activities'];
      if (activities is List) {
        for (final item in activities) {
          if (item is Map) {
            total += (item['price'] as num?)?.toDouble() ?? 0;
          }
        }
      }
    }

    return total;
  }

  Future<void> _saveCurrentItinerary() async {
    final fullItinerary = _fullItineraryForRequest();
    final calculatedCost = _calculateItineraryCost(fullItinerary);

    setState(() {
      backendEstimatedCost = calculatedCost;
    });

    final updatedItinerary = <String, dynamic>{
      'estimated_cost': calculatedCost,
      'itineraryData': fullItinerary,
    };

    await DatabaseService.saveItinerary(
      tripId: widget.localTripId,
      itinerary: updatedItinerary,
    );
  }

  Future<void> _regenerateSelectedDay() async {
    if (isRegeneratingDay || regeneratingItemKey != null) {
      return;
    }

    final currentDay = itineraryData[selectedDay];

    if (currentDay == null) {
      return;
    }

    setState(() {
      isRegeneratingDay = true;
    });

    try {
      final response = await ApiService.regenerateDay(
        destination: widget.destination,
        budget: double.parse(
          widget.budget.replaceAll(',', ''),
        ),
        interests: widget.interests,
        foodPreference:
            widget.selectedFoodPreference ?? 'veg',
        dayNumber: selectedDay,
        currentDay: Map<String, dynamic>.from(currentDay),
        itineraryData: _fullItineraryForRequest(),
      );

      final regeneratedDay = response['day'];

      if (regeneratedDay is! Map) {
        throw Exception(
          'Invalid regenerated day received',
        );
      }

      setState(() {
        itineraryData[selectedDay] =
            Map<String, dynamic>.from(regeneratedDay);
      });

      await _saveCurrentItinerary();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Day $selectedDay regenerated successfully.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Regenerate day error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to regenerate the day.',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isRegeneratingDay = false;
      });
    }
  }

  Future<void> _regenerateItem({
    required String itemType,
    required int itemIndex,
  }) async {
    if (isRegeneratingDay || regeneratingItemKey != null) {
      return;
    }

    final currentDay = itineraryData[selectedDay];

    if (currentDay == null) {
      return;
    }

    final loadingKey = '${itemType}_$itemIndex';

    setState(() {
      regeneratingItemKey = loadingKey;
    });

    try {
      final response = await ApiService.regenerateItem(
        destination: widget.destination,
        budget: double.parse(
          widget.budget.replaceAll(',', ''),
        ),
        interests: widget.interests,
        foodPreference:
            widget.selectedFoodPreference ?? 'veg',
        dayNumber: selectedDay,
        itemType: itemType,
        itemIndex: itemIndex,
        currentDay: Map<String, dynamic>.from(currentDay),
        itineraryData: _fullItineraryForRequest(),
      );

      final regeneratedItem = response['item'];

      if (regeneratedItem is! Map) {
        throw Exception(
          'Invalid regenerated item received',
        );
      }

      final updatedDay =
          Map<String, dynamic>.from(currentDay);

      final String listKey;

      if (itemType == 'place') {
        listKey = 'places';
      } else if (itemType == 'food') {
        listKey = 'food';
      } else {
        listKey = 'activities';
      }

      final items = updatedDay[listKey];

      if (items is! List) {
        throw Exception(
          'Invalid $listKey data',
        );
      }

      if (itemIndex < 0 ||
          itemIndex >= items.length) {
        throw Exception(
          'Invalid item index',
        );
      }

      items[itemIndex] =
          Map<String, dynamic>.from(regeneratedItem);

      setState(() {
        itineraryData[selectedDay] = updatedDay;
      });

      await _saveCurrentItinerary();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item regenerated successfully.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Regenerate item error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to regenerate item.',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        regeneratingItemKey = null;
      });
    }
  }

  Future<void> _deleteItem({
    required String itemType,
    required int itemIndex,
  }) async {
    if (isRegeneratingDay || regeneratingItemKey != null) {
      return;
    }

    final currentDay = itineraryData[selectedDay];

    if (currentDay == null) {
      return;
    }

    final String listKey;

    if (itemType == 'place') {
      listKey = 'places';
    } else if (itemType == 'food') {
      listKey = 'food';
    } else {
      listKey = 'activities';
    }

    final updatedDay =
        Map<String, dynamic>.from(currentDay);

    final items = updatedDay[listKey];

    if (items is! List) {
      return;
    }

    if (itemIndex < 0 ||
        itemIndex >= items.length) {
      return;
    }

    items.removeAt(itemIndex);

    setState(() {
      itineraryData[selectedDay] = updatedDay;
    });

    try {
      await _saveCurrentItinerary();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item removed successfully.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Delete item error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save the change.',
          ),
        ),
      );
    }
  }

}
