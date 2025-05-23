.PHONY: build install clean

install:
	npm ci

compile:
	npx tsc --noEmit

clean:
	rm -rf node_modules build

format:
	npx prettier --write .

#---------
## Building

dev:
	NODE_ENV=development npx vite build --mode development --watch

# This is what Google wants us to upload when we release a new version to the Addon "store"
build-chrome: install update-chrome zip-build-chrome

update-chrome:
	VITE_TARGET_BROWSER=chrome npx vite build

# This is what Mozilla wants us to upload when we release a new version to the Addon "store"
build-firefox: install update-firefox zip-build-firefox

update-firefox:
	VITE_TARGET_BROWSER=firefox npx vite build

# Add Safari build targets
build-safari: install update-safari zip-build-safari

update-safari:
	VITE_TARGET_BROWSER=safari npx vite build

#---------
## Zipping

# To build a zip archive for uploading to the Chrome Web Store or Mozilla Addons
zip-build-chrome:
	mkdir -p artifacts && cd build && zip -FS ../artifacts/chrome.zip -r *

zip-build-firefox:
	mkdir -p artifacts && cd build && zip -FS ../artifacts/firefox.zip -r *

zip-build-safari:
	mkdir -p artifacts && cd build && zip -FS ../artifacts/safari.zip -r *

# To build a source archive, wanted by Mozilla reviewers. Include media subdir.
# NOTE: we include the .git in the media archive so that it lines up with the output
# of vite
zip-src:
	(rm -rfv build && mkdir -p artifacts build)
	# archive the main repo
	git archive --prefix=aw-watcher-web/ -o build/aw-watcher-web.zip HEAD
	# archive the media subrepo
	(cd media/ && git archive --prefix=aw-watcher-web/media/ --add-file=.git -o ../build/media.zip HEAD)
	# extract the archives into a single directory
	(cd build && unzip -q aw-watcher-web.zip)
	(cd build && unzip -q media.zip)
	# zip the whole thing
	(cd build && zip -r ../artifacts/src.zip aw-watcher-web)
	# clean up
	(cd build && rm -r aw-watcher-web media.zip aw-watcher-web.zip)

#---------
## Reproducibility

test-reproducibility-setup:
	mkdir -p artifacts build
	(cd build && rm -rf aw-watcher-web && unzip -q ../artifacts/src.zip)

# Tests whether the zipped src reliably builds the same as the archive
test-reproducibility-chrome: zip-src build-chrome test-reproducibility-setup
	@echo "Building from src-zip..."
	@(cd build/aw-watcher-web && make build-chrome && cp artifacts/chrome.zip ../../artifacts/reproducibility-chrome.zip)
	@rm -r build/aw-watcher-web
	@echo "Checking..."
	@test "$$(wc -c artifacts/chrome.zip | awk '{print $$1}')" = \
		"$$(wc -c artifacts/reproducibility-chrome.zip | awk '{print $$1}')" \
		|| (echo "❌ Build artifacts are not the same size" && exit 1)
	@echo "✅ Build artifacts are the same size"

# Tests whether the zipped src reliably builds the same as the archive
test-reproducibility-firefox: zip-src build-firefox test-reproducibility-setup
	@echo "Building from src-zip..."
	@(cd build/aw-watcher-web && make build-firefox && cp artifacts/firefox.zip ../../artifacts/reproducibility-firefox.zip)
	@rm -r build/aw-watcher-web
	@echo "Checking..."
	@test "$$(wc -c artifacts/firefox.zip | awk '{print $$1}')" = \
		"$$(wc -c artifacts/reproducibility-firefox.zip | awk '{print $$1}')" \
		|| (echo "❌ Build artifacts are not the same size" && exit 1)
	@echo "✅ Build artifacts are the same size"

# Tests whether the zipped src reliably builds the same as the archive
test-reproducibility-safari: zip-src build-safari test-reproducibility-setup
	@echo "Building from src-zip..."
	@(cd build/aw-watcher-web && make build-safari && cp artifacts/safari.zip ../../artifacts/reproducibility-safari.zip)
	@rm -r build/aw-watcher-web
	@echo "Checking..."
	@test "$$(wc -c artifacts/safari.zip | awk '{print $$1}')" = \
		"$$(wc -c artifacts/reproducibility-safari.zip | awk '{print$$1}')" \
		|| (echo "❌ Build artifacts are not the same size" && exit 1)
	@echo "✅ Build artifacts are the same size"
