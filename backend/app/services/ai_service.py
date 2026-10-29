import asyncio
import json

import httpx
from fastapi import HTTPException

from app.core.config import settings


def _extract_json(content: str) -> dict:
    cleaned = content.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("\n", 1)[-1]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3].strip()

    try:
        result = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=502,
            detail="Google Gemini returned invalid JSON",
        ) from exc

    if not isinstance(result, dict):
        raise HTTPException(
            status_code=502,
            detail="Google Gemini response must be a JSON object",
        )

    return result


async def generate_ai_response(prompt: str) -> dict:
    """Generate an itinerary through the Google AI Studio Gemini API."""
    if not settings.ai_api_key:
        raise HTTPException(
            status_code=503,
            detail="Google AI Studio API key is not configured",
        )

    model = settings.ai_model.strip()
    if not model:
        raise HTTPException(
            status_code=503,
            detail="Google Gemini model is not configured",
        )

    url = (
        f"{settings.ai_base_url.rstrip('/')}/models/"
        f"{model}:generateContent"
    )
    payload = {
        "systemInstruction": {
            "parts": [{
                "text": (
                    "You are TourKare, a personalized travel itinerary "
                    "planner. Follow the user's instructions and return "
                    "valid JSON only. Do not explain or reason."
                ),
            }],
        },
        "contents": [{
            "role": "user",
            "parts": [{"text": prompt}],
        }],
        "generationConfig": {
            "temperature": 0.2,
            "responseMimeType": "application/json",
        },
    }

    try:
        async with httpx.AsyncClient(timeout=None) as client:
            response = None
            for attempt in range(3):
                response = await client.post(
                    url,
                    params={"key": settings.ai_api_key},
                    headers={"Content-Type": "application/json"},
                    json=payload,
                )
                if response.status_code != 429 or attempt == 2:
                    break

                retry_after = response.headers.get("Retry-After")
                try:
                    delay = min(float(retry_after), 5.0)
                except (TypeError, ValueError):
                    delay = float(attempt + 1)
                await asyncio.sleep(delay)

            if response is None:
                raise HTTPException(
                    status_code=502,
                    detail="Google Gemini did not return a response",
                )

            if response.status_code == 429:
                raise HTTPException(
                    status_code=503,
                    detail=(
                        "Google AI Studio free tier is temporarily "
                        "rate-limited. Please retry shortly."
                    ),
                )

            if response.status_code in (401, 403):
                raise HTTPException(
                    status_code=503,
                    detail=(
                        "Google AI Studio authentication failed. "
                        "Check the API key and API access settings."
                    ),
                )

            response.raise_for_status()
            data = response.json()

    except HTTPException:
        raise
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502,
            detail="Could not connect to Google AI Studio",
        ) from exc
    except httpx.HTTPStatusError as exc:
        try:
            error = exc.response.json().get("error", {})
            message = error.get("message", "No error message provided")
        except (ValueError, AttributeError):
            message = exc.response.text[:500]

        print(f"Google AI Studio HTTP error: {exc.response.status_code}")
        print(f"Google AI Studio details: {message}")
        raise HTTPException(
            status_code=502,
            detail={
                "message": "Google Gemini request failed",
                "provider_status": exc.response.status_code,
                "provider_error": message,
            },
        ) from exc

    candidates = data.get("candidates", [])
    if not candidates:
        raise HTTPException(
            status_code=502,
            detail="Google Gemini returned no candidates",
        )

    parts = candidates[0].get("content", {}).get("parts", [])
    content = "".join(
        part.get("text", "")
        for part in parts
        if isinstance(part, dict)
    )
    if not content.strip():
        raise HTTPException(
            status_code=502,
            detail={
                "message": "Google Gemini returned an empty response",
                "finish_reason": candidates[0].get("finishReason"),
            },
        )

    return _extract_json(content)
