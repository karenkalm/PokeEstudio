#!/usr/bin/env python3
"""Genera lib/shared/domain/type_chart_data.dart desde /type/{id} de PokéAPI.

Usa `damage_relations` (tabla vigente, Gen. VI en adelante) de los 18 tipos
jugables. Igual que el generador del índice, acepta la API en vivo o una copia
local de PokeAPI/api-data:

    python3 tool/generate_type_chart.py --api-data /ruta/a/api-data
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import urllib.request

# Orden de presentación (el de los juegos actuales).
ORDER = ["normal", "fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground",
         "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
CAMEL = {s: s for s in ORDER}


def load(api_data: str | None, type_id: int) -> dict:
    if api_data:
        with open(os.path.join(api_data, "data", "api", "v2", "type", str(type_id), "index.json"), encoding="utf-8") as fh:
            return json.load(fh)
    req = urllib.request.Request(f"https://pokeapi.co/api/v2/type/{type_id}/", headers={"User-Agent": "PokeStudio-type-chart"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def dart_set(names: list[str]) -> str:
    items = ", ".join(f"PokemonType.{CAMEL[n]}" for n in sorted(names, key=ORDER.index))
    return f"<PokemonType>{{{items}}}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-data")
    parser.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "lib", "shared", "domain", "type_chart_data.dart"))
    args = parser.parse_args()

    relations = {}
    for type_id in range(1, 19):
        data = load(args.api_data, type_id)
        dr = data["damage_relations"]
        relations[data["name"]] = {
            "double": [t["name"] for t in dr["double_damage_to"]],
            "half": [t["name"] for t in dr["half_damage_to"]],
            "none": [t["name"] for t in dr["no_damage_to"]],
        }
    assert sorted(relations) == sorted(ORDER), relations.keys()

    lines = [
        "// GENERADO por tool/generate_type_chart.py. No editar a mano.",
        f"// Fuente: PokéAPI /type/{{1..18}} · damage_relations · {dt.date.today().isoformat()}",
        "// Tabla vigente (Gen. VI en adelante). Las tablas antiguas viven en",
        "// `past_damage_relations` y se incorporarán con las reglas por generación.",
        "",
        "import '../models/pokemon_type.dart';",
        "",
    ]
    for key, const_name, doc in (
        ("double", "kSuperEffectiveAgainst", "Tipos que reciben ×2 de cada tipo atacante."),
        ("half", "kNotVeryEffectiveAgainst", "Tipos que reciben ×½ de cada tipo atacante."),
        ("none", "kNoEffectAgainst", "Tipos inmunes (×0) a cada tipo atacante."),
    ):
        lines.append(f"/// {doc}")
        lines.append(f"const Map<PokemonType, Set<PokemonType>> {const_name} = <PokemonType, Set<PokemonType>>{{")
        for attacker in ORDER:
            lines.append(f"  PokemonType.{CAMEL[attacker]}: {dart_set(relations[attacker][key])},")
        lines.append("};")
        lines.append("")
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print("Tabla de tipos escrita en", args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
