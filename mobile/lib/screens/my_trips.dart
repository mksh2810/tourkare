import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourkare/screens/homepage.dart';

import 'package:tourkare/screens/itinerary.dart';
import 'package:tourkare/widgets/navbar.dart';
import 'package:tourkare/services/database_service.dart';

class MyTrips extends StatefulWidget {
  const new({super.key});

  @override
  State<MyTrips> createState() => _MyTripsState();
}

class _MyTripsState extends State<MyTrips> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        trips = [];
        isLoading = false;
      });

      return;
    }

    try {
      final savedTrips = await DatabaseService.getTrips(user.uid);

      final enrichedTrips = <Map<String, dynamic>>[];

      for (final trip in savedTrips) {
        final tripData = Map<String, dynamic>.from(trip);

        final tripId = tripData['id'];

        if (tripId is int) {
          final savedItinerary = await DatabaseService.getItinerary(tripId);

          if (savedItinerary != null) {
            // Estimated cost from the backend response
            final estimatedCost = savedItinerary['estimated_cost'];

            if (estimatedCost is num) {
              tripData['estimatedCost'] = estimatedCost.toInt();
            } else {
              tripData['estimatedCost'] = 0;
            }

            // Try to get an image from the first place
            final itineraryData = savedItinerary['itineraryData'];

            if (itineraryData is Map && itineraryData.isNotEmpty) {
              final firstDay = itineraryData.values.first;

              if (firstDay is Map) {
                final places = firstDay['places'];

                if (places is List && places.isNotEmpty) {
                  final firstPlace = places.first;

                  if (firstPlace is Map) {
                    final image = firstPlace['image'];

                    if (image is String && image.isNotEmpty) {
                      tripData['image'] = image;
                    }
                  }
                }
              }
            }
          }
        }

        // Safe defaults
        tripData['estimatedCost'] ??= 0;
        tripData['image'] ??= '';

        enrichedTrips.add(tripData);
      }

      if (!mounted) return;

      setState(() {
        trips = enrichedTrips;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load trips error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load your trips.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'My Trips',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),

        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: trips.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Trips',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Plan, explore and revisit your experiences',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),

                  const SizedBox(height: 25),

                  ...trips.map((trip) => _buildTripCard(trip)),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final int estCost = (trip['estimatedCost'] as num?)?.toInt() ?? 0;
    final int budget = (trip['budget'] as num?)?.toInt() ?? 0;
    final bool withinBudget = estCost <= budget;

    return GestureDetector(
      onTap: () {
        _openTrip(trip);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,

                  child:
                      trip['image'] is String &&
                          (trip['image'] as String).isNotEmpty
                      ? Image.network(
                          trip['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 45,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 45,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),

                Positioned(
                  top: 14,
                  left: 14,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      '${trip['days']} Days',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,

                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),

                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),

                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteTrip(trip);
                        }
                      },

                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined, size: 20),
                              SizedBox(width: 10),

                              Text('Delete Trip'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip['destination'],
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.account_balance_wallet_outlined,
                          'Budget',
                          '₹${trip['budget']}',
                        ),
                      ),

                      Expanded(
                        child: _buildInfoItem(
                          Icons.auto_awesome,
                          'Estimated',
                          '₹$estCost',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: withinBudget
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          withinBudget
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          size: 18,
                          color: withinBudget ? Colors.green : Colors.red,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          withinBudget
                              ? 'Within your Budget'
                              : 'Exceeds your Budget',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: withinBudget ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Divider(color: Colors.grey.shade200, height: 1),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 17,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        'Created ${trip['created_at']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, size: 18, color: Colors.deepPurple),
        ),

        const SizedBox(width: 9),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  void _openTrip(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItineraryScreen(
          localTripId: trip['id'] as int,
          destination: trip['destination'] as String,
          numberOfDays: trip['days'] as int,
          budget: trip['budget'].toString(),
          interests: List<String>.from(jsonDecode(trip['interests'] as String)),
        ),
      ),
    );
  }

  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    final tripId = trip['id'];

    if (tripId is! int) {
      return;
    }

    // Ask for confirmation
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip?'),
          content: Text(
            'Are you sure you want to delete your ${trip['destination']} trip?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      // Delete from SQLite
      await DatabaseService.deleteTrip(tripId);

      if (!mounted) return;

      // Remove it from the currently displayed list
      setState(() {
        trips.removeWhere((item) => item['id'] == tripId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${trip['destination']} trip deleted.'),
          backgroundColor: Colors.deepPurple,
        ),
      );
    } catch (e) {
      debugPrint('Delete trip error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete the trip.')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 100,
              height: 100,

              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
              ),

              child: const Icon(
                Icons.card_travel,
                size: 48,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'No trips yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            Text(
              'Your generated itineraries will appear here.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => Homepage()),
                );
              },
              icon: const Icon(Icons.add),

              label: const Text(
                'Plan a Trip',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                elevation: 0,

                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
