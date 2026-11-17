#!/usr/bin/env python3
"""Découpe un fichier texte en parties de 4 500 caractères."""

import argparse
from pathlib import Path


TAILLE_PARTIE = 4_500


def main():
    parser = argparse.ArgumentParser(
        description="Découpe un fichier texte en parties de 4 500 caractères."
    )
    parser.add_argument("fichier", type=Path, help="fichier texte à découper")
    chemin = parser.parse_args().fichier

    try:
        with chemin.open("r", encoding="utf-8", newline="") as source:
            texte = source.read()
    except (OSError, UnicodeError) as erreur:
        parser.error(f"impossible de lire {chemin} : {erreur}")

    parties = [
        texte[debut : debut + TAILLE_PARTIE]
        for debut in range(0, len(texte), TAILLE_PARTIE)
    ] or [""]
    sorties = [
        chemin.with_name(f"{chemin.stem}{numero:02d}{chemin.suffix}")
        for numero in range(1, len(parties) + 1)
    ]

    deja_presents = [sortie for sortie in sorties if sortie.exists()]
    if deja_presents:
        noms = ", ".join(str(sortie) for sortie in deja_presents)
        parser.error(f"fichier(s) de sortie déjà présent(s) : {noms}")

    try:
        for sortie, partie in zip(sorties, parties):
            with sortie.open("w", encoding="utf-8", newline="") as destination:
                destination.write(partie)
    except OSError as erreur:
        parser.error(f"impossible d’écrire les fichiers de sortie : {erreur}")

    print(f"{len(sorties)} fichier(s) créé(s).")


if __name__ == "__main__":
    main()
