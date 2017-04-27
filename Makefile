APP_NAME = recorded-ssh

ifneq ($(shell which brew),)
	VIRTUALENV_PATH = $(HOME)/.virtualenvs/$(APP_NAME)
endif

ifdef WORKON_HOME
	VIRTUALENV_PATH = $(WORKON_HOME)/$(APP_NAME)
endif

ifdef VIRTUAL_ENV
	VIRTUALENV_PATH = $(VIRTUAL_ENV)
endif

ifneq ($(wildcard .heroku/python/bin/python),)
	VIRTUALENV_PATH = .heroku/python
endif

ifndef VIRTUALENV_PATH
	VIRTUALENV_PATH = .virtualenv
endif
VIRTUALENV_BIN = $(VIRTUALENV_PATH)/bin

ifndef ANSIBLE_ARGS
	ANSIBLE_ARGS =
endif

ANSIBLE_PLAYBOOK = $(VIRTUALENV_BIN)/ansible-playbook
BREW := $(shell which brew)
PIP = $(VIRTUALENV_BIN)/pip
PIP_VERSION = 9.0.1
PYTHON = $(ENV) $(VIRTUALENV_BIN)/python
SETUPTOOLS_VERSION = 34.3.2

.PHONY: playbook
playbook:
ifndef ASCIINEMA_TOKEN
	$(error ASCIINEMA_TOKEN is not set)
endif
ifndef GITHUB_ORG
	$(error GITHUB_ORG is not set)
endif
ifndef GITHUB_TEAMS
	$(error GITHUB_TEAMS is not set)
endif
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is not set)
endif
	$(ANSIBLE_PLAYBOOK) "-e 'ASCIINEMA_TOKEN=$(ASCIINEMA_TOKEN) GITHUB_ORG=$(GITHUB_ORG) GITHUB_TEAMS=$(GITHUB_TEAMS) GITHUB_TOKEN=$(GITHUB_TOKEN)'" $(ANSIBLE_ARGS) server.yml  
