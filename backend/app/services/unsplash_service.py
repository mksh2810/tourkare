import asyncio

import httpx

from app.core.config import settings


UNSPLASH_SEARCH_URL = "https://api.unsplash.com/search/photos"
_UNSPLASH_CONCURRENCY = 4
_unsplash_semaphore = asyncio.Semaphore(_UNSPLASH_CONCURRENCY)


async def search_image(
    item_name: str,
    destination: str,
) -> str:
    """
    Search Unsplash for an image matching an itinerary item.

    Returns:
        A hotlinked Unsplash image URL, or an empty string if
        no suitable image is found.
    """

    if not settings.unsplash_access_key:
        print("❌ Unsplash API key is missing")
        return ""

    query = f"{item_name} {destination}"

    headers = {
        "Authorization": f"Client-ID {settings.unsplash_access_key}",
    }

    params = {
        "query": query,
        "per_page": 1,
        "orientation": "landscape",
    }

    try:
        async with _unsplash_semaphore:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(
                    UNSPLASH_SEARCH_URL,
                    headers=headers,
                    params=params,
                )

        if response.status_code != 200:
            if response.status_code == 403:
                print("Unsplash rate limit reached; leaving image empty:", item_name)
            else:
                print(
                    "Unsplash request failed:",
                    response.status_code,
                    item_name,
                )
            return ""

        data = response.json()
        results = data.get("results", [])

        if not results:
            print("⚠️ No image found")
            return ""

        photo = results[0]
        urls = photo.get("urls", {})

        image_url = urls.get("regular", "")

        if not image_url:
            print("⚠️ Image result found, but URL is missing")
            return ""

        return image_url

    except (httpx.HTTPError, ValueError) as exc:
        print("Unsplash image search failed:", item_name, exc)
        return ""


async def search_images(
    items: list[tuple[str, str]],
) -> list[str]:
    """Fetch images with bounded concurrency to avoid provider rate limits."""
    if not items:
        return []

    return await asyncio.gather(
        *(search_image(item_name=name, destination=destination)
          for name, destination in items)
    )