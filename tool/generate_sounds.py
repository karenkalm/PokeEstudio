#!/usr/bin/env python3
"""Genera los efectos de sonido retro de PokéStudio (originales, sin muestras).

Ondas cuadradas y triangulares sintetizadas al estilo de las consolas
portátiles. Uso:  python3 tool/generate_sounds.py
"""
import math
import os
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def note(freq, ms, wave_kind='square', duty=0.25, volume=0.22, slide_to=None):
    n = int(RATE * ms / 1000)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq if slide_to is None else freq + (slide_to - freq) * t
        phase += f / RATE
        p = phase % 1.0
        if wave_kind == 'square':
            v = 1.0 if p < duty else -1.0
        elif wave_kind == 'triangle':
            v = 4 * abs(p - 0.5) - 1
        else:
            v = math.sin(2 * math.pi * p)
        attack = min(1.0, i / (RATE * 0.002))          # 2 ms de entrada
        release = math.exp(-4.0 * t)                     # caída suave
        samples.append(v * volume * attack * release)
    return samples


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    tail = int(RATE * 0.004)
    for i in range(min(tail, len(samples))):            # evita el "clic" final
        samples[-1 - i] *= i / tail
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32767)) for s in samples))


C6, E6, G6, C7, B5, G5, D5, A4, E4 = 1046.5, 1318.5, 1568.0, 2093.0, 987.8, 784.0, 587.3, 440.0, 329.6

write('tap', note(1200, 28, 'triangle', volume=0.30))
write('select', note(B5, 34) + note(E6, 46))
write('open', note(C6, 30) + note(E6, 30) + note(G6, 60))
write('back', note(G5, 36) + note(D5, 54))
write('arrow', note(700, 60, 'triangle', volume=0.32, slide_to=1150))
write('toggle', note(1500, 22, 'square', duty=0.5, volume=0.16))
write('success', note(C6, 40) + note(E6, 40) + note(G6, 40) + note(C7, 110))
write('error', note(A4, 80, duty=0.5, volume=0.18) + silence(15) + note(E4, 120, duty=0.5, volume=0.18))
print('Sonidos generados en', os.path.abspath(OUT))
