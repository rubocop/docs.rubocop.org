.PHONY: install build redirects
.DEFAULT_GOAL := build

install: package.json
	npm install --no-fund --no-audit --no-progress --save-dev --loglevel=error
	npm run antora -- --version

build: install
	npm run antora -- --fetch antora-playbook.yml

redirects: build
	bash generate-redirects.sh
