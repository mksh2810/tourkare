import re

from fastapi import HTTPException

from app.schemas.itinerary import DayItinerary, ItineraryResponse
from app.services.ai_service import generate_ai_response
from app.services.prompt_service import build_itinerary_prompt
from app.services.unsplash_service import search_images


def normalize_ai_text(value: object) -> object:
    if isinstance(value, dict):
        return {
            key: normalize_ai_text(item)
            for key, item in value.items()
        }

    if isinstance(value, list):
        return [normalize_ai_text(item) for item in value]

    if not isinstance(value, str):
        return value

    return re.sub(r"(?<=[a-z])(?=[A-Z])", " ", value).strip()


def normalize_ai_itinerary(itinerary_data: dict) -> dict:
    """Normalize common field aliases returned by free routed models."""
    normalized = {}
    aliases_used = False

    for day_key, raw_day in itinerary_data.items():
        if not isinstance(raw_day, dict):
            normalized[day_key] = raw_day
            continue

        day = dict(raw_day)
        if "title" in day:
            day["title"] = normalize_ai_text(day["title"])
        places = []
        for raw_place in day.get("places", []):
            item = {
                key: normalize_ai_text(value)
                for key, value in raw_place.items()
            }
            if "description" not in item and "details" in item:
                item["description"] = item["details"]
                aliases_used = True
            places.append(item)

        food_items = []
        for raw_food in day.get("food", []):
            item = {
                key: normalize_ai_text(value)
                for key, value in raw_food.items()
            }
            if "restaurant" not in item and "name" in item:
                item["restaurant"] = item["name"]
                aliases_used = True
            if "meal" not in item:
                item["meal"] = item.get("category", "meal")
                aliases_used = True
            if "dishes" not in item:
                item["dishes"] = item.get("description", "")
                aliases_used = True
            food_items.append(item)

        activities = []
        for raw_activity in day.get("activities", []):
            item = {
                key: normalize_ai_text(value)
                for key, value in raw_activity.items()
            }
            if "duration" not in item:
                item["duration"] = "1 hour"
                aliases_used = True
            activities.append(item)

        day["places"] = places
        day["food"] = food_items
        day["activities"] = activities
        normalized[day_key] = day

    if aliases_used:
        print("Normalized common aliases in AI itinerary response")

    return normalized


async def add_images(
    itinerary_data: dict,
    destination: str,
) -> dict:
    """
    Add Unsplash images to places, food, and activities.

    If an image cannot be found, the item's image remains empty.
    """

    image_requests: list[tuple[str, str, dict]] = []

    for day_data in itinerary_data.values():
        if not isinstance(day_data, dict):
            continue

        # -------------------------
        # Places
        # -------------------------
        places = day_data.get("places", [])

        if isinstance(places, list):
            for place in places:
                if not isinstance(place, dict):
                    continue

                name = place.get("name", "").strip()

                if name:
                    image_requests.append((name, destination, place))

        # -------------------------
        # Food
        # -------------------------
        food = day_data.get("food", [])

        if isinstance(food, list):
            for item in food:
                if not isinstance(item, dict):
                    continue

                restaurant = item.get("restaurant", "").strip()

                if restaurant:
                    image_requests.append((restaurant, destination, item))

        # -------------------------
        # Activities
        # -------------------------
        activities = day_data.get("activities", [])

        if isinstance(activities, list):
            for activity in activities:
                if not isinstance(activity, dict):
                    continue

                name = activity.get("name", "").strip()

                if name:
                    image_requests.append((name, destination, activity))

    image_urls = await search_images(
        [(name, item_destination) for name, item_destination, _ in image_requests]
    )
    for image_url, (_, _, item) in zip(image_urls, image_requests):
        item["image"] = image_url

    return itinerary_data


async def generate_itinerary(trip):
    prompt = build_itinerary_prompt(trip)

    # -------------------------
    # Generate itinerary using AI
    # -------------------------
    try:
        ai_response = await generate_ai_response(prompt)

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="Failed to generate itinerary from AI",
        ) from exc

    # -------------------------
    # Check itineraryData
    # -------------------------
    itinerary_data = ai_response.get("itineraryData")

    if not isinstance(itinerary_data, dict):
        raise HTTPException(
            status_code=502,
            detail="AI response is missing valid itineraryData",
        )

    itinerary_data = normalize_ai_itinerary(itinerary_data)

    # -------------------------
    # Check requested days
    # -------------------------
    expected_days = {
        str(day)
        for day in range(1, trip.days + 1)
    }

    actual_days = set(itinerary_data.keys())

    if actual_days != expected_days:
        raise HTTPException(
            status_code=502,
            detail={
                "message": "AI returned incorrect day structure",
                "expected_days": sorted(expected_days),
                "received_days": sorted(actual_days),
            },
        )

    # -------------------------
    # Validate itinerary
    # -------------------------
    validated_itinerary = {}
    estimated_cost = 0.0

    try:
        for day_number in range(1, trip.days + 1):
            day_key = str(day_number)

            # Validate the complete day's structure
            day = DayItinerary.model_validate(
                itinerary_data[day_key]
            )

            validated_itinerary[day_number] = day

            # Add place prices
            for place in day.places:
                estimated_cost += place.price

            # Add food prices
            for food in day.food:
                estimated_cost += food.price

            # Add activity prices
            for activity in day.activities:
                estimated_cost += activity.price

    except Exception as exc:
        print(
            "AI itinerary schema validation failed:",
            str(exc),
        )
        raise HTTPException(
            status_code=502,
            detail={
                "message": (
                    "AI response does not match the expected "
                    "itinerary schema"
                ),
                "validation_error": str(exc),
            },
        ) from exc

    # -------------------------
    # Calculate total cost
    # -------------------------
    estimated_cost = round(estimated_cost, 2)

    # -------------------------
    # Check budget
    # -------------------------
    if estimated_cost > trip.budget:
        print(
            "Generated itinerary exceeded budget:",
            f"estimated={estimated_cost}, budget={trip.budget}",
        )
        raise HTTPException(
            status_code=422,
            detail={
                "message": "Generated itinerary exceeds the requested budget",
                "budget": trip.budget,
                "estimated_cost": estimated_cost,
            },
        )

    # -------------------------
    # Convert Pydantic models
    # back to dictionaries
    # -------------------------
    enriched_itinerary = {
        str(day_number): day.model_dump()
        for day_number, day in validated_itinerary.items()
    }

    # -------------------------
    # Add Unsplash images
    # -------------------------
    enriched_itinerary = await add_images(
        itinerary_data=enriched_itinerary,
        destination=trip.destination,
    )

    # -------------------------
    # Validate enriched data
    # -------------------------
    final_itinerary = {
        int(day_number): DayItinerary.model_validate(day_data)
        for day_number, day_data in enriched_itinerary.items()
    }

    # -------------------------
    # Return final response
    # -------------------------
    return ItineraryResponse(
        estimated_cost=estimated_cost,
        itineraryData=final_itinerary,
    )