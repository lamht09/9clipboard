# Bản build trên máy là biến thể dev (bundle ID ".dev"); bản phát hành do CI build và ký (.github/workflows/release.yml).
APP      := build/9clipboard-dev.app
INSTALLED := /Applications/9clipboard-dev.app
# Chỉ đụng tới tiến trình của bản dev, không tắt bản release đang chạy song song.
PROC     := 9clipboard-dev\.app/Contents/MacOS/NineClipboard
IDENTITY := 9clipboard Dev
# swift-build trên Command Line Tools đôi khi quên nạp plugin macro của swift-testing → nạp tường minh.
TOOLCHAIN   := $(shell dirname $$(dirname $$(xcrun --find swift)))
TEST_FLAGS  := -Xswiftc -plugin-path -Xswiftc $(TOOLCHAIN)/lib/swift/host/plugins/testing

.PHONY: build bundle sign run test bench install cert release-cert clean

build:
	swift build -c release --arch arm64

bundle: build
	VARIANT=dev scripts/bundle.sh

sign: bundle
	codesign --force --deep --options runtime --sign "$(IDENTITY)" $(APP)

run: sign
	-pkill -f '$(PROC)'
	@# `open` lỗi -600 nếu bản cũ chưa thoát hẳn → chờ tiến trình biến mất.
	@while pgrep -f '$(PROC)' >/dev/null; do sleep 0.1; done
	open $(APP)

test:
	swift test $(TEST_FLAGS)

# Benchmark tìm kiếm ở bản release (mục tiêu < 10ms cho 2000 mục, DESIGN §10).
bench:
	swift test -c release -Xswiftc -enable-testing $(TEST_FLAGS) --filter searchesUnder10ms

install: sign
	-pkill -f '$(PROC)'
	@# `open` lỗi -600 nếu bản cũ chưa thoát hẳn → chờ tiến trình biến mất.
	@while pgrep -f '$(PROC)' >/dev/null; do sleep 0.1; done
	rm -rf $(INSTALLED)
	cp -R $(APP) /Applications/
	open $(INSTALLED)

cert:
	scripts/create-dev-cert.sh

# Tạo chứng chỉ ký bản phát hành cho CI (chạy một lần, xem docs/RELEASE.md).
release-cert:
	scripts/create-release-cert.sh

clean:
	rm -rf .build build
