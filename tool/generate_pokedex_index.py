#!/usr/bin/env python3
"""Genera assets/data/pokedex_index.json a partir de datos reales de PokéAPI.

El índice es una instantánea ligera (≈1 entrada por especie) que permite a
PokéStudio buscar y filtrar al instante y sin conexión: nombre en español e
inglés, generación, tipos, estadísticas base, disponibilidad de sprites y
formas alternativas. Los detalles completos se siguen pidiendo a PokéAPI en
tiempo real desde la app.

Fuentes admitidas:
  * API REST en vivo (por defecto):   python3 tool/generate_pokedex_index.py
  * Copia local del repo PokeAPI/api-data (lo que sirve pokeapi.co):
        python3 tool/generate_pokedex_index.py --api-data /ruta/a/api-data

Respeta la política de uso justo de PokéAPI: con --live hace ~2 050 peticiones
secuenciales con una pausa corta entre ellas. Úsalo solo cuando salga una
generación nueva.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sys
import time
import urllib.request

LIVE_BASE = "https://pokeapi.co/api/v2/"
SPRITE_BASE = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/"
STAT_ORDER = ["hp", "attack", "defense", "special-attack", "special-defense", "speed"]
ROMAN = {"i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5, "vi": 6, "vii": 7, "viii": 8, "ix": 9, "x": 10}


class Source:
    def __init__(self, api_data: str | None, delay: float) -> None:
        self.api_data = api_data
        self.delay = delay

    def get(self, path: str) -> dict:
        path = path.strip("/")
        if path.startswith("api/v2/"):
            path = path[len("api/v2/"):]
        if self.api_data:
            file = os.path.join(self.api_data, "data", "api", "v2", path, "index.json")
            with open(file, encoding="utf-8") as fh:
                return json.load(fh)
        req = urllib.request.Request(LIVE_BASE + path + "/", headers={"User-Agent": "PokeStudio-index-generator"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        time.sleep(self.delay)
        return data


def resource_id(url: str) -> int:
    return int(url.rstrip("/").split("/")[-1])


def sprite_path(url: str | None) -> str | None:
    """Guarda la ruta relativa al repositorio de sprites (ahorra espacio)."""
    if not url:
        return None
    return url[len(SPRITE_BASE):] if url.startswith(SPRITE_BASE) else url


def build_entry(src: Source, species_id: int) -> dict:
    species = src.get(f"pokemon-species/{species_id}")
    names = {n["language"]["name"]: n["name"] for n in species["names"]}
    default = next(v for v in species["varieties"] if v["is_default"])
    pokemon_id = resource_id(default["pokemon"]["url"])
    pokemon = src.get(f"pokemon/{pokemon_id}")

    stats_by_name = {s["stat"]["name"]: s["base_stat"] for s in pokemon["stats"]}
    types = [t["type"]["name"] for t in sorted(pokemon["types"], key=lambda t: t["slot"])]
    sprites = pokemon["sprites"]
    artwork = (sprites.get("other") or {}).get("official-artwork") or {}
    generation = ROMAN[species["generation"]["name"].split("-")[1]]

    entry: dict = {
        "id": species["id"],
        "pokemonId": pokemon_id,
        "slug": species["name"],
        "es": names.get("es") or names.get("en") or species["name"],
        "en": names.get("en") or species["name"],
        "gen": generation,
        "types": types,
        "stats": [stats_by_name[s] for s in STAT_ORDER],
        "sprite": sprite_path(sprites.get("front_default")),
        "shiny": sprite_path(sprites.get("front_shiny")),
        "artwork": sprite_path(artwork.get("front_default")),
        "forms": [v["pokemon"]["name"] for v in species["varieties"] if not v["is_default"]],
    }
    for flag in ("is_legendary", "is_mythical", "is_baby"):
        if species.get(flag):
            entry[flag.replace("is_", "")] = True
    return entry


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--api-data", help="Ruta a una copia local de PokeAPI/api-data")
    parser.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "assets", "data", "pokedex_index.json"))
    parser.add_argument("--delay", type=float, default=0.15, help="Pausa entre peticiones en vivo (segundos)")
    parser.add_argument("--source-label", default=None, help="Texto que describe la fuente (se guarda en el índice)")
    args = parser.parse_args()

    src = Source(args.api_data, args.delay)
    listing = src.get("pokemon-species") if args.api_data else src.get("pokemon-species?limit=100000")
    count = listing["count"]
    entries = []
    for species_id in range(1, count + 1):
        entries.append(build_entry(src, species_id))
        if species_id % 100 == 0:
            print(f"  {species_id}/{count}", file=sys.stderr)

    index = {
        "version": 1,
        "generatedAt": dt.date.today().isoformat(),
        "source": args.source_label or ("PokeAPI/api-data" if args.api_data else LIVE_BASE),
        "spriteBase": SPRITE_BASE,
        "statOrder": STAT_ORDER,
        "count": len(entries),
        "entries": entries,
    }
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(index, fh, ensure_ascii=False, separators=(",", ":"))
    print(f"Índice con {len(entries)} especies escrito en {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
