// GENERADO por tool/generate_type_chart.py. No editar a mano.
// Fuente: PokéAPI /type/{1..18} · damage_relations · 2026-10-17
// Tabla vigente (Gen. VI en adelante). Las tablas antiguas viven en
// `past_damage_relations` y se incorporarán con las reglas por generación.

import '../models/pokemon_type.dart';

/// Tipos que reciben ×2 de cada tipo atacante.
const Map<PokemonType, Set<PokemonType>> kSuperEffectiveAgainst = <PokemonType, Set<PokemonType>>{
  PokemonType.normal: <PokemonType>{},
  PokemonType.fire: <PokemonType>{PokemonType.grass, PokemonType.ice, PokemonType.bug, PokemonType.steel},
  PokemonType.water: <PokemonType>{PokemonType.fire, PokemonType.ground, PokemonType.rock},
  PokemonType.grass: <PokemonType>{PokemonType.water, PokemonType.ground, PokemonType.rock},
  PokemonType.electric: <PokemonType>{PokemonType.water, PokemonType.flying},
  PokemonType.ice: <PokemonType>{PokemonType.grass, PokemonType.ground, PokemonType.flying, PokemonType.dragon},
  PokemonType.fighting: <PokemonType>{PokemonType.normal, PokemonType.ice, PokemonType.rock, PokemonType.dark, PokemonType.steel},
  PokemonType.poison: <PokemonType>{PokemonType.grass, PokemonType.fairy},
  PokemonType.ground: <PokemonType>{PokemonType.fire, PokemonType.electric, PokemonType.poison, PokemonType.rock, PokemonType.steel},
  PokemonType.flying: <PokemonType>{PokemonType.grass, PokemonType.fighting, PokemonType.bug},
  PokemonType.psychic: <PokemonType>{PokemonType.fighting, PokemonType.poison},
  PokemonType.bug: <PokemonType>{PokemonType.grass, PokemonType.psychic, PokemonType.dark},
  PokemonType.rock: <PokemonType>{PokemonType.fire, PokemonType.ice, PokemonType.flying, PokemonType.bug},
  PokemonType.ghost: <PokemonType>{PokemonType.psychic, PokemonType.ghost},
  PokemonType.dragon: <PokemonType>{PokemonType.dragon},
  PokemonType.dark: <PokemonType>{PokemonType.psychic, PokemonType.ghost},
  PokemonType.steel: <PokemonType>{PokemonType.ice, PokemonType.rock, PokemonType.fairy},
  PokemonType.fairy: <PokemonType>{PokemonType.fighting, PokemonType.dragon, PokemonType.dark},
};

/// Tipos que reciben ×½ de cada tipo atacante.
const Map<PokemonType, Set<PokemonType>> kNotVeryEffectiveAgainst = <PokemonType, Set<PokemonType>>{
  PokemonType.normal: <PokemonType>{PokemonType.rock, PokemonType.steel},
  PokemonType.fire: <PokemonType>{PokemonType.fire, PokemonType.water, PokemonType.rock, PokemonType.dragon},
  PokemonType.water: <PokemonType>{PokemonType.water, PokemonType.grass, PokemonType.dragon},
  PokemonType.grass: <PokemonType>{PokemonType.fire, PokemonType.grass, PokemonType.poison, PokemonType.flying, PokemonType.bug, PokemonType.dragon, PokemonType.steel},
  PokemonType.electric: <PokemonType>{PokemonType.grass, PokemonType.electric, PokemonType.dragon},
  PokemonType.ice: <PokemonType>{PokemonType.fire, PokemonType.water, PokemonType.ice, PokemonType.steel},
  PokemonType.fighting: <PokemonType>{PokemonType.poison, PokemonType.flying, PokemonType.psychic, PokemonType.bug, PokemonType.fairy},
  PokemonType.poison: <PokemonType>{PokemonType.poison, PokemonType.ground, PokemonType.rock, PokemonType.ghost},
  PokemonType.ground: <PokemonType>{PokemonType.grass, PokemonType.bug},
  PokemonType.flying: <PokemonType>{PokemonType.electric, PokemonType.rock, PokemonType.steel},
  PokemonType.psychic: <PokemonType>{PokemonType.psychic, PokemonType.steel},
  PokemonType.bug: <PokemonType>{PokemonType.fire, PokemonType.fighting, PokemonType.poison, PokemonType.flying, PokemonType.ghost, PokemonType.steel, PokemonType.fairy},
  PokemonType.rock: <PokemonType>{PokemonType.fighting, PokemonType.ground, PokemonType.steel},
  PokemonType.ghost: <PokemonType>{PokemonType.dark},
  PokemonType.dragon: <PokemonType>{PokemonType.steel},
  PokemonType.dark: <PokemonType>{PokemonType.fighting, PokemonType.dark, PokemonType.fairy},
  PokemonType.steel: <PokemonType>{PokemonType.fire, PokemonType.water, PokemonType.electric, PokemonType.steel},
  PokemonType.fairy: <PokemonType>{PokemonType.fire, PokemonType.poison, PokemonType.steel},
};

/// Tipos inmunes (×0) a cada tipo atacante.
const Map<PokemonType, Set<PokemonType>> kNoEffectAgainst = <PokemonType, Set<PokemonType>>{
  PokemonType.normal: <PokemonType>{PokemonType.ghost},
  PokemonType.fire: <PokemonType>{},
  PokemonType.water: <PokemonType>{},
  PokemonType.grass: <PokemonType>{},
  PokemonType.electric: <PokemonType>{PokemonType.ground},
  PokemonType.ice: <PokemonType>{},
  PokemonType.fighting: <PokemonType>{PokemonType.ghost},
  PokemonType.poison: <PokemonType>{PokemonType.steel},
  PokemonType.ground: <PokemonType>{PokemonType.flying},
  PokemonType.flying: <PokemonType>{},
  PokemonType.psychic: <PokemonType>{PokemonType.dark},
  PokemonType.bug: <PokemonType>{},
  PokemonType.rock: <PokemonType>{},
  PokemonType.ghost: <PokemonType>{PokemonType.normal},
  PokemonType.dragon: <PokemonType>{PokemonType.fairy},
  PokemonType.dark: <PokemonType>{},
  PokemonType.steel: <PokemonType>{},
  PokemonType.fairy: <PokemonType>{},
};
