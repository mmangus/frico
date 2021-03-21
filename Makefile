SOURCE_FILES := src/frico/*.py tests/*.py
BLUE := \033[1;34m
GREEN := \033[1;32m
NOCOLOR := \033[0m
FRAME_TOP := ┏━┅┉
FRAME_BOTTOM := ┗━┅┉
STEP_TOP := @echo "$(BLUE)$(FRAME_TOP)$(NOCOLOR)"
STEP_BOTTOM := @echo "$(BLUE)$(FRAME_BOTTOM)$(NOCOLOR)"
SUCCESS := @echo "$(GREEN)$(FRAME_TOP)\n┋ All tests complete: success! \n$(FRAME_BOTTOM)$(NOCOLOR)"

# this project uses dependencies to skip redundant steps, but  make aliases
# don't work as expected when used as dependencies, so assign vars :|
venv=.venv/bin/activate
install=.venv/.install
hooks=.venv/.hooks
pipcompile=.venv/bin/pip-compile
format=.venv/.format
lint=.venv/.lint
formatcheck=.venv/.format-check
typecheck=.venv/.typecheck
unit=.venv/.unit

all: $(install)

# TODO: make step styling less repetitive
$(venv):
	$(STEP_TOP)
	@echo "$(BLUE)┋ Creating venv...$(NOCOLOR)"
	@python3 -m venv .venv
	@echo "$(GREEN)Installed virtual environment: .venv$(NOCOLOR)"
	$(STEP_BOTTOM)

$(hooks): $(venv)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Configuring git hooks...$(NOCOLOR)"
	@git config core.hooksPath git-hooks
	@touch $(hooks)
	$(STEP_BOTTOM)

$(pipcompile): $(hooks)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Installing pip-tools...$(NOCOLOR)"
	@.venv/bin/python3 -m pip install pip-tools
	$(STEP_BOTTOM)

requirements.txt: requirements.in $(pipcompile)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Compiling pinned dependencies...$(NOCOLOR)"
	@CUSTOM_COMPILE_COMMAND="make" .venv/bin/pip-compile requirements.in
	$(STEP_BOTTOM)

$(install): requirements.txt
	$(STEP_TOP)
	@echo "$(BLUE)┋ Installing requirements...$(NOCOLOR)"
	@.venv/bin/python3 -m pip install -r requirements.txt
	@touch $(install)
	$(STEP_BOTTOM)

.PHONY: clean
clean:
	@rm -rf .venv

$(format): $(install)  $(shell find -name *.py)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Formatting...$(NOCOLOR)"
	@echo "isort `.venv/bin/isort --version-number)`"
	@.venv/bin/isort $(SOURCE_FILES)
	@.venv/bin/black --version
	@.venv/bin/black $(SOURCE_FILES)
	@touch $(format)
	$(STEP_BOTTOM)

# for CI use, bail out of anything needs to be reformatted
$(formatcheck): $(install) $(shell find -name *.py)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Checking format...$(NOCOLOR)"
	@echo "isort `.venv/bin/isort --version-number)`"
	@.venv/bin/isort --diff $(SOURCE_FILES)
	@.venv/bin/isort --check-only $(SOURCE_FILES)
	@.venv/bin/black --version
	@.venv/bin/black --check $(SOURCE_FILES)
	@touch $(formatcheck)
	$(STEP_BOTTOM)

$(lint): $(install) $(shell find -name *.py)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Linting...$(NOCOLOR)"
	@echo "flake8 `.venv/bin/flake8 --version)`"
	@.venv/bin/flake8 $(SOURCE_FILES)
	@echo "$(GREEN)No complaints."
	@touch $(lint)
	$(STEP_BOTTOM)

$(typecheck): $(install) $(shell find -name *.py)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Type checking...$(NOCOLOR)"
	@.venv/bin/mypy --version
	@.venv/bin/mypy $(SOURCE_FILES)
	@touch $(typecheck)
	$(STEP_BOTTOM)

$(unit): $(install) $(shell find -name *.py)
	$(STEP_TOP)
	@echo "$(BLUE)┋ Running unit and doc tests...$(NOCOLOR)"
	@.venv/bin/pytest
	@touch $(unit)
	$(STEP_BOTTOM)

.PHONY: success
success:
	$(SUCCESS)

.venv/.test: $(format) $(lint) $(typecheck) $(unit) success
	@touch .venv/.test
test: .venv/.test

.venv/.test-ci: $(formatcheck) $(lint) $(typecheck) $(unit) success
	@touch .venv/.test-ci
test-ci: .venv/.test-ci
