# Entry points for working on this repo.
#
# The gate recipes here are the single definition of what a gate runs. CI calls
# these targets rather than repeating the commands in YAML, so adding a gate is
# one edit and the local run and the CI run cannot drift apart. A gate that only
# makes sense on a runner belongs in a workflow step of its own.

# Tracked files plus the untracked ones git would let you commit. --others is
# what makes a just-written script visible before `git add`; without it the gate
# never saw the file, and for a test that meant reporting green over an
# assertion nobody had executed. --exclude-standard leaves .gitignore
# authoritative, so scratch stays out — this is not a glob of the working tree.
#
# A tracked file deleted but not staged stays in the lists, and the linter then
# errors on a path it cannot open. That is the rule holding, not an exception:
# the index is what a plain `git commit` ships, so the file is still
# committable. Stage the deletion.
LS_FILES := git ls-files --cached --others --exclude-standard

SH_FILES   := $(shell $(LS_FILES) '*.sh')
PY_FILES   := $(shell $(LS_FILES) '*.py')
# Both pathspecs are needed: '*/scripts/test-*.sh' reaches a skill's own scripts
# directory and never the root one.
TEST_FILES := $(shell $(LS_FILES) '*/scripts/test-*.sh' 'scripts/test-*.sh')

.DEFAULT_GOAL := help

.PHONY: help
help: ## List the available targets
	@awk 'BEGIN { FS = ":.*##" } /^[a-zA-Z_-]+:.*##/ { printf "  \033[1m%-8s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# Everything CI gates on, in the order a failure is cheapest to read.
.PHONY: check
check: lint-sh lint-py validate test ## Run every gate CI runs

.PHONY: lint-sh
lint-sh: ## Run shellcheck over every committable shell script
	shellcheck $(SH_FILES)

# --select is pinned to match CI exactly. ruff is unpinned and its default rule
# set grows over time, so without it a ruff release turns the gate red over
# style the scripts never opted into.
.PHONY: lint-py
lint-py: ## Run ruff over every committable Python script
	pipx run ruff check --select E4,E7,E9,F $(PY_FILES)

# The body-ceiling check grandfathers each skill at the size it measured on the
# merge base, so it needs one. Without a base it says so loudly and measures
# against the tier ceilings alone. It is not made --strict here: a clone with no
# remote is the ordinary case for this repo, and a gate that cannot run on a
# fresh clone is a gate nobody runs.
.PHONY: validate
validate: ## Validate skill frontmatter, description length, and script modes
	scripts/validate-skills.py

.PHONY: test
test: ## Run every committable test script
	@rc=0; for t in $(TEST_FILES); do \
	    printf '=== %s\n' "$$t"; \
	    bash "$$t" || rc=1; \
	done; exit $$rc
