import os
import requests
import logging

logger = logging.getLogger(__name__)

BASE_URL = "https://api.schiphol.nl/public-flights"


def _headers() -> dict:
    return {
        "app_id": os.environ["SCHIPHOL_APP_ID"],
        "app_key": os.environ["SCHIPHOL_APP_KEY"],
        "ResourceVersion": "v4",
        "Accept": "application/json",
    }


def fetch_flights(max_pages: int = 3) -> list[dict]:
    """
    Endpoint: GET /flights
    Retorna voos de chegada e partida de Schiphol.
    """
    records = []
    for page in range(max_pages):
        logger.info(f"[flights] buscando página {page}...")
        resp = requests.get(
            f"{BASE_URL}/flights",
            headers=_headers(),
            params={"page": page, "sort": "+scheduleTime"},
            timeout=30,
        )
        resp.raise_for_status()
        batch = resp.json().get("flights", [])
        if not batch:
            break
        records.extend(batch)
        logger.info(f"[flights] página {page}: {len(batch)} registros")

    logger.info(f"[flights] total extraído: {len(records)}")
    return records


def fetch_destinations(max_pages: int = 5) -> list[dict]:
    """
    Endpoint: GET /destinations
    Retorna aeroportos de destino com código IATA e país.
    """
    records = []
    for page in range(max_pages):
        logger.info(f"[destinations] buscando página {page}...")
        resp = requests.get(
            f"{BASE_URL}/destinations",
            headers=_headers(),
            params={"page": page},
            timeout=30,
        )
        resp.raise_for_status()
        batch = resp.json().get("destinations", [])
        if not batch:
            break
        records.extend(batch)
        logger.info(f"[destinations] página {page}: {len(batch)} registros")

    logger.info(f"[destinations] total extraído: {len(records)}")
    return records