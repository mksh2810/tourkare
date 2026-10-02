import 'package:flutter/material.dart';
import 'package:tourkare/screens/ai_generating_screen.dart';
import 'package:tourkare/services/database_service.dart';
import 'package:tourkare/widgets/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController destinationController = TextEditingController();

  final TextEditingController budgetController = TextEditingController();

  final TextEditingController customInterestController =
      TextEditingController();

  String selectedFoodPreference = 'veg';

  final Set<String> selectedInterests = {};
  final List<String> interests = [
    '🏖️ Beaches',
    '🏛️ History',
    '🍴 Food',
    '🏔️ Nature',
    '🛍️ Shopping',
    '🎭 Culture',
    '🏕️ Adventure',
    '🌃 Nightlife',
    '📸 Photography',
    '🧘 Relaxation',
  ];

  int numberOfDays = 3;

  String? heroImage;
  bool imageLoading = true;

  bool isCreatingItinerary = false;

  @override
  void initState() {
    super.initState();
    loadHeroImage();
  }

  @override
  void dispose() {
    destinationController.dispose();
    budgetController.dispose();
    customInterestController.dispose();
    super.dispose();
  }

  Future<void> loadHeroImage() async {
    final image = await ApiService.getHeroImage();

    if (!mounted) return;

    setState(() {
      heroImage = image;
      imageLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Row(
          children: [
            Icon(Icons.flight_takeoff, color: Colors.deepPurple),

            SizedBox(width: 8),

            Text(
              'TourKare',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ========================================================
            // HERO IMAGE
            // ========================================================

            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,

                  child: imageLoading
                      ? Container(
                          color: Colors.deepPurple.shade200,

                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : heroImage != null
                      ? Image.network(
                          heroImage!,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,

                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.deepPurple.shade200,

                              child: const Icon(
                                Icons.landscape,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.deepPurple.shade200,

                          child: const Icon(
                            Icons.landscape,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                ),

                // Dark gradient
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,

                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ),

                // Hero text
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: 25,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Plan less.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Travel more.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Your personalized trip starts here.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ========================================================
            // FORM
            // ========================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),

              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // DESTINATION
                  // ==================================================

                  const Text(
                    'Where are you going?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: destinationController,

                    decoration: InputDecoration(
                      hintText: 'e.g. Goa, Manali',

                      prefixIcon: const Icon(Icons.location_on_outlined),

                      filled: true,
                      fillColor: const Color(0xFFF7F7FA),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ==================================================
                  // DAYS + BUDGET
                  // ==================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============================================================
                      // DAYS
                      // ============================================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How many days?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              height: 56,
                              width: double.infinity,

                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Calendar icon
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 20,
                                    ),

                                    const SizedBox(width: 18),

                                    // Minus button
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (numberOfDays > 1) {
                                          setState(() {
                                            numberOfDays--;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.remove, size: 22),
                                    ),

                                    const SizedBox(width: 8),

                                    // Number of days
                                    Text(
                                      '$numberOfDays',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Plus button
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        if (numberOfDays < 30) {
                                          setState(() {
                                            numberOfDays++;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 22),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Space between the two fields
                      const SizedBox(width: 14),

                      // ============================================================
                      // BUDGET
                      // ============================================================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'What is your budget?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              height: 56,
                              width: double.infinity,

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                child: Row(
                                  children: [
                                    const Text(
                                      '₹',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.black54,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: TextField(
                                        controller: budgetController,

                                        keyboardType: TextInputType.number,

                                        textAlignVertical:
                                            TextAlignVertical.center,

                                        decoration: const InputDecoration(
                                          hintText: '10,000',
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // INTERESTS
                  // ==================================================
                  const Text(
                    'What do you like?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    '${selectedInterests.length}/5',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade400,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Choose upto 5 interests',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 9,
                    runSpacing: 9,

                    children: [
                      ...interests.map((interest) => _interestChip(interest)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // CUSTOM INTEREST
                  // ==================================================
                  TextField(
                    controller: customInterestController,
                    textInputAction: TextInputAction.done,

                    onSubmitted: (value) {
                      addCustomInterest();
                    },

                    decoration: InputDecoration(
                      hintText: 'Add another interest',

                      prefixIcon: const Icon(Icons.add_circle_outline),

                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: addCustomInterest,
                      ),

                      filled: true,
                      fillColor: const Color(0xFFF7F7FA),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  DropdownButtonFormField<String>(
                    initialValue: selectedFoodPreference,
                    decoration: InputDecoration(
                      labelText: 'Food Preference',
                      prefixIcon: const Icon(
                        Icons.restaurant,
                        color: Color(0xFF514A55),
                      ),
                      filled: true,
                      fillColor: Color(0xFFF7F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 17,
                      ),
                    ),
                    
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF514A55),
                      size: 28,
                    ),

                    dropdownColor: const Color(0xFFF7F7FA),

                    borderRadius: BorderRadius.circular(24),

                    elevation: 4,

                    menuMaxHeight: 320,

                    items: const [
                      DropdownMenuItem(value: 'veg', child: Text('Vegetarian')),
                      DropdownMenuItem(
                        value: 'non_veg',
                        child: Text('Non-Vegetarian'),
                      ),
                      DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                      DropdownMenuItem(value: 'jain', child: Text('Jain')),
                      DropdownMenuItem(
                        value: 'eggetarian',
                        child: Text('Eggetarian'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedFoodPreference = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // CREATE ITINERARY BUTTON
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 58,

                    child: ElevatedButton(
                      onPressed: isCreatingItinerary ? null : createItinerary,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,

                        foregroundColor: Colors.white,

                        disabledBackgroundColor: Colors.deepPurple.shade300,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isCreatingItinerary
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),

                                Text(
                                  'Creating your itinerary...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome),

                                SizedBox(width: 8),

                                Text(
                                  'Create my itinerary',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  // ==============================================================
  // INTEREST CHIP
  // ==============================================================

  Widget _interestChip(String label) {
    final bool selected = selectedInterests.contains(label);

    return FilterChip(
      label: Text(label),

      selected: selected,

      onSelected: (value) {
        setState(() {
          if (value) {
            if (selectedInterests.length >= 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You can select upto 5 interests only.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            setState(() {
              selectedInterests.add(label);
            });
          } else {
            selectedInterests.remove(label);
          }
        });
      },

      backgroundColor: const Color(0xFFF7F7FA),

      selectedColor: Colors.deepPurple.shade100,

      checkmarkColor: Colors.deepPurple,

      side: BorderSide.none,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  void addCustomInterest() {
    final interest = customInterestController.text.trim();
    if (interest.isEmpty) return;
    if (selectedInterests.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can select upto 5 interests only.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      interests.add('✨ $interest');
      selectedInterests.add('✨ $interest');
      customInterestController.clear();
    });
  }

  Future<void> createItinerary() async {
    final destination = destinationController.text.trim();
    final budgetText = budgetController.text.trim();
    final budget = double.tryParse(budgetText.replaceAll(',', ''));

    // Validation
    if (destination.isEmpty) {
      showValidationDialog('Destination Required');
      return;
    } else if (budget == null || budget <= 0) {
      showValidationDialog('Enter a valid budget');
      return;
    } else if (selectedInterests.isEmpty) {
      showValidationDialog('At least 1 interest Required');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showValidationDialog('Please log in to continue');
      return;
    }

    setState(() {
      isCreatingItinerary = true;
    });

    try {
      // Save the trip immediately so the generated itinerary has a local ID.
      final localTripId = await DatabaseService.createTrip(
        userId: user.uid,
        destination: destination,
        days: numberOfDays,
        budget: budget,
        interests: selectedInterests.toList(),
      );

      if (!mounted) return;

      // Move to the dedicated AI loading screen. The API request and
      // itinerary saving happen there while the user sees the animation.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIGeneratingScreen(
            localTripId: localTripId,
            destination: destination,
            budgetText: budgetText,
            budget: budget,
            numberOfDays: numberOfDays,
            interests: selectedInterests.toList(),
            foodPreference: selectedFoodPreference,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showValidationDialog('Failed to create itinerary. Please try again.');

      debugPrint('Create itinerary error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isCreatingItinerary = false;
        });
      }
    }
  }

  void showValidationDialog(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.deepPurple),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Ok',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
