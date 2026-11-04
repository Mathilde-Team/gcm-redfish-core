# gcm-redfish-core

Client Redfish générique (DMTF standard, indépendant du constructeur) et
outils d'inventaire firmware multi-constructeur (HPE, Dell, Lenovo/IBM),
conçus comme le cœur — indépendant de GTK — du futur plugin Redfish de
GNOME Connection Manager (GCM).

## Pourquoi ce dépôt est séparé de GCM

Cette bibliothèque ne dépend d'aucune interface graphique : elle peut être
réutilisée par le plugin GTK de GCM, par une interface web future, ou en
ligne de commande. Le plugin GTK lui-même vit dans un dépôt séparé
(`gcm-plugin-redfish`).

## Ce que fait la bibliothèque

- **`redfish_client.py`** — client Redfish générique : session, inventaire
  système/firmware, actions d'alimentation, SNMP/syslog, RAID (lecture
  seule — voir plus bas), Virtual Media, santé/capteurs, logs matériels,
  suivi de tâches, boot one-shot, LED d'identification, sessions actives,
  date/heure et NTP, licence, mise à jour firmware unitaire (SimpleUpdate),
  BIOS (via le mécanisme standard @Redfish.Settings), réseau du Manager,
  certificats TLS.
- **`catalog_import.py`** — importeurs pour peupler un `Repository` de
  paquets firmware disponibles à partir de vrais catalogues constructeur
  (Catalog.xml Dell, métadonnées Smart Component HPE). Contient aussi les
  classifieurs `classify_dell_component` / `classify_hpe_component` /
  `classify_lenovo_component`.
- **`knowledge_base.py`** / **`dependency_engine.py`** — moteur de
  dépendances firmware (paliers, prérequis croisés, incompatibilités).
  Ce module n'est plus une priorité du projet (voir "Décisions de scope"
  ci-dessous) mais reste fonctionnel et testé.
- **`models.py`** / **`firmware_version.py`** — modèles de données
  partagés (ServerProfile, FirmwarePackage, FirmwareVersion, etc.).

## Décisions de scope (volontaires)

Pour limiter les risques et rester sur des bases fiables, certaines
fonctionnalités ont été explicitement exclues ou limitées :

- **Aucun calcul de chemin de mise à jour firmware** (paliers/dépendances
  entre versions) : aucune source publique fiable n'a été trouvée chez
  HPE/Dell/Lenovo, ni via LVFS/fwupd, ni via les outils propriétaires
  (OneView/OpenManage Enterprise/XClarity Administrator). Le moteur de
  dépendances existe dans le code mais n'est plus alimenté ni prioritaire.
- **RAID : lecture seule.** Pas de création/suppression de volume — jugé
  trop risqué (perte de données possible, support très inégal selon
  constructeur, confirmé absent sur Lenovo XCC par exemple).
- **Pas de gestion des comptes BMC** (création/suppression/droits) — même
  logique de risque que le RAID en écriture.
- **Réseau du Manager : standard uniquement.** Le bascule "port dédié vs
  partagé" n'est pas standardisé par le schéma Redfish et n'est donc pas
  implémenté (chaque constructeur le gère via ses propres attributs OEM).

## Installation

```bash
pip install -e .
# ou, avec les dépendances de test :
pip install -e ".[dev]"
```

## Lancer les tests

Aucun matériel Redfish réel n'est nécessaire : les tests utilisent un faux
transport HTTP simulant les réponses standard DMTF.

```bash
pip install -e ".[dev]"
make test      # tous les tests sous coverage, seuil 95 % lignes + branches
```

`make test` est la commande du job « Qualité (lint, tests) » de la CI : le
seuil est lu dans `pyproject.toml` (`[tool.coverage.report] fail_under`).
Un script de test isolé se lance aussi directement, par exemple
`python tests/test_engine.py`.

## Socle qualité Mathilde-Team

Le dépôt suit le [socle qualité](https://github.com/Mathilde-Team/.github/blob/main/SOCLE.md) :

| Fichier | Rôle |
|---|---|
| `.github/workflows/ci.yml` | Job « Qualité (lint, tests) » (yamllint, syntaxe des scripts, `make test`) et tests Python 3.10 / 3.11 |
| `.github/workflows/guard-main.yml` | Refuse toute PR vers `main` qui ne vient pas de `dev` |
| `.github/workflows/branch-protection.yml` | Compare chaque jour la protection réelle de `main` et `dev` aux règles versionnées |
| `.github/branch-protection/{main,dev}.json` | Règles de protection, applicables telles quelles par un administrateur |
| `.github/workflows/maj-branches.yml` | Met à jour les PR vers `dev` à chaque avancée de `dev` |
| `.github/workflows/desassignation.yml` | Retire les assignés inactifs depuis 24 h |

Mise en place restante, réservée à un administrateur (audit Mathilde-Team/.github#1) :

1. renommer la branche par défaut `master` en `main` (Settings → Branches) ;
2. lancer `scripts/appliquer_socle.sh Mathilde-Team/gcm-redfish-core` depuis
   `Mathilde-Team/.github` : création de `dev` et application des protections
   versionnées ici.

Ensuite, toutes les PR ciblent `dev`, et `main` n'est alimentée que par une
PR `dev` → `main`.

## Scripts utilitaires (scripts/)

- **fetch_dell_catalog.py** — télécharge et échantillonne le vrai
  catalogue Dell (Catalog.xml) pour analyse.
- **analyze_dell_catalog.py** — classe tous les composants d'un catalogue
  complet et produit des statistiques de couverture + un XML des
  composants non reconnus, pour expertise humaine.

## Exemple d'usage

```python
from gcm_redfish_core import RedfishClient

with RedfishClient("https://192.168.1.100", "admin", "password", verify_ssl=False) as client:
    system_path = client.list_system_paths()[0]
    profile = client.build_server_profile(system_path)
    print(profile.vendor, profile.model)
    for component_type, state in profile.components.items():
        print(f"  {component_type}: {state.current_version}")
```

## Licence

GPL-3.0-or-later (voir LICENSE) — le cœur du plugin Redfish de GNOME
Connection Manager (Gcm4, GPLv3) : même licence, le « ou toute version
ultérieure » étant porté par les métadonnées de `pyproject.toml`.
