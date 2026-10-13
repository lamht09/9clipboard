# 9clipboard

[English](README.md) · **Tiếng Việt**

Trình quản lý lịch sử clipboard cho macOS (Apple Silicon). Bấm **⌥V** để mở dải thẻ ở đáy màn hình, chọn một thẻ là dán luôn vào app đang dùng.

- Lưu text, rich text và ảnh; tìm fuzzy không dấu tiếng Việt (`da nang` → “Đà Nẵng”)
- Ghim vào các Pinboard, mục đã ghim không bị xoá
- Mật khẩu (từ 1Password, Passwords…) tự xoá sau 15 phút; loại trừ app, tạm dừng ghi
- Dữ liệu chỉ nằm trên máy, không có network

Thiết kế: [docs/DESIGN.md](docs/DESIGN.md) · Kế hoạch: [docs/PLAN.md](docs/PLAN.md) · Tiến độ: [docs/STATE.md](docs/STATE.md)

## Yêu cầu

- macOS 14 trở lên, Apple Silicon (mọi máy Apple Silicon, kể cả M1, đều cập nhật được lên macOS 14)
- Swift 6 (Command Line Tools là đủ, không cần Xcode): `xcode-select --install`

## Build và cài

```sh
make cert      # chỉ chạy một lần: tạo chứng chỉ tự ký "9clipboard Dev" trong Keychain
make install   # build release, ký, copy vào /Applications và mở app
```

Các lệnh khác:

| Lệnh | Việc |
|---|---|
| `make run` | Build, ký và chạy từ `build/9clipboard.app` |
| `make test` | Chạy unit test của `ClipCore` (đừng dùng `swift test` trần, xem STATE.md) |
| `make bench` | Đo tìm kiếm 2000 mục ở bản release (mục tiêu < 10ms) |
| `scripts/make-icon.sh` | Vẽ lại `Resources/AppIcon.icns` |

**Vì sao cần chứng chỉ tự ký:** macOS nhớ quyền Trợ năng theo chữ ký của app. Ký ad-hoc thì mỗi lần build là một chữ ký mới và quyền bị mất; ký bằng cùng một chứng chỉ thì quyền được giữ.

## Cấp quyền

Lần đầu chạy, app xin quyền **Trợ năng (Accessibility)** để gửi phím ⌘V vào app đang dùng:

System Settings › Quyền riêng tư & Bảo mật › Trợ năng › bật **9clipboard**.

Không cấp cũng dùng được: chọn thẻ thì nội dung được copy, bạn tự bấm ⌘V. Trạng thái quyền xem ở Cài đặt › Quyền.

## Phím tắt trong panel

| Phím | Việc |
|---|---|
| gõ chữ | Tìm kiếm |
| `←` `→` | Chọn thẻ |
| `Enter` / click | Dán |
| `⇧Enter` | Dán dạng text thuần |
| `⌘1`…`⌘9` | Dán nhanh thẻ thứ 1–9 |
| `Space` | Xem trước cỡ lớn (khi ô tìm trống) |
| `Tab` / `⇧Tab` | Đổi tab lọc |
| `⌘P` | Ghim vào Pinboard |
| `⌘⌫` | Xoá thẻ |
| `Esc` | Đóng xem trước → xoá ô tìm → đóng panel |

Đổi phím tắt mở panel, giới hạn lịch sử, chạy khi đăng nhập… ở menu bar › **Cài đặt…** (⌘,).

## Dữ liệu

`~/Library/Application Support/9clipboard/` (quyền 0700): `clips.sqlite`, ảnh gốc trong `blobs/`, thumbnail trong `thumbs/`. Xoá thư mục này là xoá sạch lịch sử.

Nếu sửa DB bằng `sqlite3`, luôn chạy `pragma foreign_keys=on;` trước, nếu không sẽ sót dòng mồ côi và app không khởi động được.

## Giấy phép

[MIT](LICENSE)
