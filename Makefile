# Commandes du socle : le job « Qualité (lint, tests) » (.github/workflows/ci.yml)
# appelle les mêmes cibles, pour qu'un test local et le CI ne divergent jamais.
# Prérequis : environnement avec le paquet installé (uv pip install -e ".[dev]").
.PHONY: test

PYTHON ?= python

# Tests lancés comme des scripts (sans pytest, gcm-redfish-core#7), sauf le
# test du script du socle check_branch_protection.py repris de modele-depot
# (pytest). Seuil (95 %) et branches lus dans pyproject.toml.
TESTS_SCRIPTS = \
	tests/test_engine.py \
	tests/test_catalog_import.py \
	tests/test_redfish_client.py \
	tests/test_redfish_client_erreurs.py \
	tests/test_moteur_et_import_limites.py \
	tests/test_loguru_regles.py

test:
	rm -f .coverage .coverage.*
	set -e; for t in $(TESTS_SCRIPTS); do $(PYTHON) -m coverage run $$t; done
	$(PYTHON) -m coverage run -m pytest -q tests/test_check_branch_protection.py
	$(PYTHON) -m coverage combine
	$(PYTHON) -m coverage report
