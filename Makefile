APP      := build/9clipboard.app
IDENTITY := 9clipboard Dev

.PHONY: build bundle sign run test install cert clean

build:
	swift build -c release --arch arm64

bundle: build
	scripts/bundle.sh

sign: bundle
	codesign --force --deep --options runtime --sign "$(IDENTITY)" $(APP)

run: sign
	-pkill -x NineClipboard
	open $(APP)

test:
	swift test

install: sign
	-pkill -x NineClipboard
	rm -rf /Applications/9clipboard.app
	cp -R $(APP) /Applications/
	open /Applications/9clipboard.app

cert:
	scripts/create-dev-cert.sh

clean:
	rm -rf .build build
