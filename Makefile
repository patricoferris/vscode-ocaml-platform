.DEFAULT_GOAL := all

.PHONY: all
all:
	opam exec -- dune build --root .

.PHONY: deps
deps: ## Install development dependencies
	opam install -y ocamlformat ocamlformat-rpc ocaml-lsp-server $(DEV_DEPS)
	npm install
	opam install --deps-only --with-test --with-doc -y .

.PHONY: create_switch
create_switch:
	opam switch create . 4.13.1 --no-install

.PHONY: switch
switch: create_switch deps ## Create an opam switch and install development dependencies

.PHONY: build
build: ## Build the project
	opam exec -- dune build src/vscode_ocaml_platform.bc.js
	yarn esbuild _build/default/src/vscode_ocaml_platform.bc.js \
		--bundle \
		--external:vscode \
		--outdir=dist \
		--platform=node \
		--target=es6 \
		--sourcemap

.PHONY: build-release
build-release:
	opam exec -- dune build src/vscode_ocaml_platform.bc.js --profile=release
	yarn esbuild _build/default/src/vscode_ocaml_platform.bc.js \
		--bundle \
		--external:vscode \
		--outdir=dist \
		--platform=node \
		--target=es6 \
		--minify-whitespace \
		--minify-syntax \
		--sourcemap \
		--sources-content=false

.PHONY: install
install: all ## Install the packages on the system
	opam exec -- dune install --root .

.PHONY: start
start: all ## Run the produced executable
	opam exec -- dune build @run --force --no-buffer

.PHONY: test
test: ## Run the unit tests
	opam exec -- dune build --root . @runtest
	npm run test

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	opam exec -- dune clean --root .
	rm -r dist/

.PHONY: doc
doc: ## Generate odoc documentation
	opam exec -- dune build --root . @doc

.PHONY: fmt
fmt: ## Format the codebase with ocamlformat
	opam exec -- dune build --root . --auto-promote @fmt
	npm run fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	opam exec -- dune build @all -w --terminal-persistence=clear-on-rebuild

.PHONY: vs-pkg
vs-pkg: build # Builds and packages the extension for installment
	npm run -- vsce package --out ./test_extension.vsix

.PHONY: vs-install
vs-install: pkg # Builds, packages, and installs the extension to your VS Code
	code --force --install-extension test_extension.vsix

.PHONY: nix/opam-selection.nix
nix/opam-selection.nix:
	nix-shell -A resolve default.nix
