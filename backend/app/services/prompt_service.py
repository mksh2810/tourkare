import json

from app.schemas.itinerary import (
    RegenerateDayRequest,
    RegenerateItemRequest,
    TripCreate,
)


def build_itinerary_prompt(trip: TripCreate) -> str:
    interests = ", ".join(trip.interests) or "general sightseeing"
    days = ", ".join(f'"{day}"' for day in range(1, trip.days + 1))

    daily_cap = round(trip.budget / trip.days, 2)

    return f"""Create a {trip.days}-day itinerary for {trip.destination}.
Total budget INR {trip.budget}; hard maximum per day INR {daily_cap};
interests: {interests}; food: {trip.food_preference}.
Return ONLY compact JSON: {{"estimated_cost":0,"itineraryData":{{"1":{{"title":"","places":[],"food":[],"activities":[]}}}}}}.
Day keys must be {days}. Each day must contain exactly 4 places, 2 food items, and 3 activities. Use these
exact fields (never rename them):
place={{"name":"","image":"","location":"","time":"","price":0,"rating":0,"description":""}}
food={{"restaurant":"","image":"","location":"","meal":"","time":"","price":0,"rating":0,"dishes":""}}
activity={{"name":"","image":"","location":"","time":"","duration":"","price":0,"rating":0,"description":""}}
Use short, natural-language strings with normal spaces between words and numeric
prices/ratings (0-5). The sum of every price on every day must be <= INR
{daily_cap}; keep all prices modest and make free attractions price 0. Keep items
realistic, nearby,
non-duplicated, budget-safe, and compatible with the food preference. No transport,
accommodation, markdown, comments, explanations, precise addresses, or extra keys."""


def build_regenerate_day_prompt(request: RegenerateDayRequest) -> str:
    itinerary = {
        str(day_number): day.model_dump()
        for day_number, day in request.itinerary_data.items()
    }
    interests = ", ".join(request.interests) or "general sightseeing"

    return f"""Replace only day {request.day_number} in a {len(itinerary)}-day trip.
Destination: {request.destination}; budget INR {request.budget}; interests: {interests};
food: {request.food_preference}. Existing itinerary:
{json.dumps(itinerary, separators=(",", ":"))}
Return ONLY {{"title":"","places":[],"food":[],"activities":[]}} with exactly 4
places, 2 food items, and 3 activities. Do not duplicate another day. Use short
strings, practical times, numeric prices/ratings, specific short locations, and
image "". Follow food restrictions. No markdown, explanations, extra keys, or
other days."""


def build_regenerate_item_prompt(request: RegenerateItemRequest) -> str:
    itinerary = {
        str(day_number): day.model_dump()
        for day_number, day in request.itinerary_data.items()
    }
    current_day = request.current_day.model_dump()
    interests = ", ".join(request.interests) or "general sightseeing"

    return f"""Generate exactly one replacement {request.item_type} for day
{request.day_number} in {request.destination}. Budget INR {request.budget};
interests: {interests}; food: {request.food_preference}.
Current day: {json.dumps(current_day, separators=(",", ":"))}
Existing trip: {json.dumps(itinerary, separators=(",", ":"))}
Do not duplicate an existing item. Match the schedule. Use short strings, a
specific location, numeric price/rating (0-5), and image "". Follow food rules.
Return ONLY one compact JSON object with the correct fields:

place: {{"name":"","image":"","location":"","time":"","price":0,"rating":0,"description":""}}
food: {{"restaurant":"","image":"","location":"","meal":"","time":"","price":0,"rating":0,"dishes":""}}
activity: {{"name":"","image":"","location":"","time":"","duration":"","price":0,"rating":0,"description":""}}

No markdown, explanations, arrays, day objects, or extra keys."""
