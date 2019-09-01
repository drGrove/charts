SHELL := /bin/bash

.PHONY: lint
lint:
	helm lint charts/*/
