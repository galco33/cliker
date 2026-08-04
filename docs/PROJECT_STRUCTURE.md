# Organisation du projet

```text
cliker/
├── assets/
│   └── icons/
│       └── app_icon.svg
├── docs/
│   └── PROJECT_STRUCTURE.md
├── scenes/
│   └── game/
│       └── clicker_game.tscn
├── scripts/
│   └── game/
│       ├── clicker_game.gd
│       └── clicker_game.gd.uid
├── project.godot
└── README.md
```

## Conventions

- Les noms de fichiers et dossiers utilisent l’anglais et le `snake_case`.
- Une scène et son contrôleur portent le même nom de base.
- Les scènes principales du jeu vont dans `scenes/game/`.
- Les contrôleurs de jeu vont dans `scripts/game/`.
- Les images, icônes, sons et polices vont dans un sous-dossier adapté de `assets/`.
- Les nouveaux systèmes doivent rester séparés : par exemple `scripts/save/`, `scripts/audio/` ou `scripts/data/` lorsqu’ils deviennent nécessaires.
- La racine reste réservée à la configuration et à la documentation générale.

## Points d’entrée

- Scène principale : `res://scenes/game/clicker_game.tscn`
- Script principal : `res://scripts/game/clicker_game.gd`
- Icône de l’application : `res://assets/icons/app_icon.svg`
