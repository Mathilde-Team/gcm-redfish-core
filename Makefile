# Commandes du socle : le job « Qualité (lint, tests) » (.github/workflows/ci.yml)
# appelle les mêmes cibles, pour qu'un test local et le CI ne divergent jamais.
# Prérequis : environnement avec le paquet installé (uv pip install -e ".[dev]").
.PHONY: test

# `coverage run` (script) et non `python -m coverage run` : sous Python 3.10,
# la forme -m ne place pas tests/ dans sys.path et les imports entre scripts
# de tests (test_redfish_client_erreurs → test_redfish_client) échouent.
COVERAGE ?= coverage

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
	set -e; for t in $(TESTS_SCRIPTS); do $(COVERAGE) run $$t; done
	$(COVERAGE) run -m pytest -q tests/test_check_branch_protection.py
	$(COVERAGE) combine
	$(COVERAGE) report
