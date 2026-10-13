APP      := build/9clipboard.app
IDENTITY := 9clipboard Dev
# swift-build trên Command Line Tools đôi khi quên nạp plugin macro của swift-testing → nạp tường minh.
TOOLCHAIN   := $(shell dirname $$(dirname $$(xcrun --find swift)))
TEST_FLAGS  := -Xswiftc -plugin-path -Xswiftc $(TOOLCHAIN)/lib/swift/host/plugins/testing

.PHONY: build bundle sign run test bench install cert clean

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
	swift test $(TEST_FLAGS)

# Benchmark tìm kiếm ở bản release (mục tiêu < 10ms cho 2000 mục, DESIGN §10).
bench:
	swift test -c release -Xswiftc -enable-testing $(TEST_FLAGS) --filter searchesUnder10ms

install: sign
	-pkill -x NineClipboard
	rm -rf /Applications/9clipboard.app
	cp -R $(APP) /Applications/
	open /Applications/9clipboard.app

cert:
	scripts/create-dev-cert.sh

clean:
	rm -rf .build build
