import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';


  static Future<String?> getHeroImage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hero-image'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['image_url'];
      }

      debugPrint(
        'Failed to fetch hero image: ${response.statusCode}',
      );

      return null;
    } catch (e) {
      debugPrint(
        'Error fetching hero image: $e',
      );

      return null;
    }
  }


  static Future<Map<String, dynamic>> createTrip({
    required String destination,
    required int days,
    required double budget,
    required List<String> interests,
    required String selectedFoodPreference,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final idToken = await user.getIdToken();

    if (idToken == null) {
      throw Exception(
        'Could not get Firebase ID token',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/itinerary/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'destination': destination,
        'days': days,
        'budget': budget,
        'interests': interests,
        'food_preference': selectedFoodPreference,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data as Map<String, dynamic>;
    }

    debugPrint(
      'Failed to generate itinerary: '
      '${response.statusCode} ${response.body}',
    );

    throw Exception(
      'Failed to generate itinerary: ${response.body}',
    );
  }


  static Future<Map<String, dynamic>> regenerateDay({
    required String destination,
    required double budget,
    required List<String> interests,
    required String foodPreference,
    required int dayNumber,
    required Map<String, dynamic> currentDay,
    required Map<String, dynamic> itineraryData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final idToken = await user.getIdToken();

    if (idToken == null) {
      throw Exception(
        'Could not get Firebase ID token',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/itinerary/regenerate-day'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'destination': destination,
        'budget': budget,
        'interests': interests,
        'food_preference': foodPreference,
        'day_number': dayNumber,
        'current_day': currentDay,
        'itinerary_data': itineraryData,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data as Map<String, dynamic>;
    }

    debugPrint(
      'Failed to regenerate day: '
      '${response.statusCode} ${response.body}',
    );

    throw Exception(
      'Failed to regenerate day: ${response.body}',
    );
  }


  static Future<Map<String, dynamic>> regenerateItem({
    required String destination,
    required double budget,
    required List<String> interests,
    required String foodPreference,
    required int dayNumber,
    required String itemType,
    required int itemIndex,
    required Map<String, dynamic> currentDay,
    required Map<String, dynamic> itineraryData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final idToken = await user.getIdToken();

    if (idToken == null) {
      throw Exception(
        'Could not get Firebase ID token',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/itinerary/regenerate-item'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'destination': destination,
        'budget': budget,
        'interests': interests,
        'food_preference': foodPreference,
        'day_number': dayNumber,
        'item_type': itemType,
        'item_index': itemIndex,
        'current_day': currentDay,
        'itinerary_data': itineraryData,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data as Map<String, dynamic>;
    }

    debugPrint(
      'Failed to regenerate item: '
      '${response.statusCode} ${response.body}',
    );

    throw Exception(
      'Failed to regenerate item: ${response.body}',
    );
  }
}