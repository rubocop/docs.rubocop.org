.PHONY: npm build deploy
.DEFAULT_GOAL := build

npm: package.json
	npm install --no-fund --no-audit --no-progress --save-dev --loglevel=error
	npm run antora -- --version

build: npm
	npm run antora -- --fetch antora-playbook.yml
