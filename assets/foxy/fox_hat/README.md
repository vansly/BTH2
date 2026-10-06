# Art nhân vật Player

Toàn bộ art của Player nằm trong **hai sprite sheet** ở thư mục này, kèm file `.json` do
Aseprite xuất ra cạnh mỗi sheet.

| Sheet | Kích thước | Lưới | Chứa |
|---|---|---|---|
| `foxy_hat_sprite_sheet.png` | 256 × 960 | 4 cột × 15 hàng | walk, idle, hit, jump, atk |
| `foxy_hat_actions_sprite_sheet.png` | 192 × 576 | 3 cột × 9 hàng | pushing, carring |

Bài thực hành chỉ dùng sheet thứ nhất. Sheet `actions` để dành cho phần bài tập
(đẩy vật, bê vật).

## Bố cục (bắt buộc)

- **Ô: 64 × 64 px.**
- **Cột = hướng**, đúng thứ tự: `0` = nhìn xuống (mặt trước), `1` = nhìn ngang, `2` = nhìn
  lên (lưng). Hướng *trái* không vẽ riêng — game lấy cột `1` rồi lật ngang bằng
  `Sprite3D.flip_h`; cờ lật là một khoá trong animation `_left`, không do code đặt.
- **Hàng = khung hình** của animation.
- Sheet rộng 4 cột nhưng **cột thứ 4 bỏ trống**; game không bao giờ đọc tới nó.
- Vì lưới đều nên `Sprite3D` chỉ cần `hframes = 4`, `vframes = 15`, và
  **`frame = hàng × 4 + cột`**. Không cần `SpriteFrames`, không cần `AnimatedSprite3D`.
- **Chân nhân vật (pixel không trong suốt thấp nhất) nằm đúng hàng 53** trong ô, với
  `walk` và `idle` — hai nhóm chiếm nhiều thời gian nhất trên màn hình. Lệch hàng
  giữa chúng là nhân vật nhấp nhô khi đổi trạng thái. `jump`, `atk`, `hit` cố ý cao hơn
  1–2 px (nhún người) nên không tính vào mốc này.
- Nền trong suốt. Không nén khi import (`compress/mode=0`, không mipmap, và
  `detect_3d/compress_to=0`) — pixel art hiển thị bằng `texture_filter = NEAREST` và
  `alpha_cut = DISCARD`, nén VRAM sẽ làm nhoè viền.

> ⚠️ `detect_3d/compress_to` mặc định là `1`. Với giá trị đó, **lần đầu texture được dùng
> trên một node 3D Godot sẽ tự động re-import sang nén VRAM** và pixel art bị mờ, không báo
> lỗi gì. Thả sheet mới vào thư mục thì nhớ đặt lại về `0`.

## Vẽ to bằng nào

Game là pixel-art tile 32 px, mỗi ô lưới trong world là 2 m — nên **1 px = 0.0625 m**
(`pixel_size = 0.0625` trên mọi Sprite3D của game). Suy ra:

- Ô 64 × 64 px hiện ra trong game là một khung **4 × 4 m**.
- Nhân vật cao 35 px trên canvas ⇒ cao **2.19 m** trong game, xấp xỉ chiều cao hộp va chạm.
- Một ô sàn trong game rộng 2 m ⇒ đúng **32 px** trên canvas. Đây là thước đo tiện nhất:
  nhân vật cao khoảng một ô sàn là vừa.
- Gốc của `Sprite3D` nằm ở tâm ô, chân ở hàng 53, nên node phải nhấc lên
  **`y = 1.34375`** thì chân mới chạm mặt đất.

## Tag và nhịp

Nhịp lấy **thẳng từ file `.json`** của Aseprite, không đặt lại trong code:

| Tag | Hàng | Nhịp | Animation trong game |
|---|---|---|---|
| `walk` | 0–3 | 200 ms/khung (5 fps) | `run_down`, `run_left`, `run_right`, `run_up` |
| `idle` | 4–5 | 300 ms/khung (3.33 fps) | `idle_down`, `idle_left`, `idle_right`, `idle_up` |
| `hit` | 6–8 | 100 ms/khung (10 fps) | (chưa dùng) |
| `jump` | 9–10 | 400 ms/khung (2.5 fps) | `jump_down`, `jump_left`, `jump_right`, `jump_up` |
| `atk` | 11–14 | 100 ms/khung (10 fps) | (chưa dùng — dành cho bài tập) |

`fall` không có art riêng: giữ khung **cuối** của `jump` (`fall_*` bốn hướng).

> ⚠️ Ba hàng `atk` (11–14) ở cột `1` có lưỡi kiếm **chạm mép phải ô** và cột `2` có mảnh
> kiếm **chạm mép trái ô** — art bị cắt phẳng tại biên 64 px, trong game sẽ thấy kiếm cụt.
> Cần vẽ lại cho gọn trong ô, hoặc mở rộng ô (xem phần "Điều nên sửa" bên dưới).

## Thay art xong thì làm gì

Xuất đè lên PNG **và** file `.json` đi kèm, rồi dựng lại thư viện animation:

```bash
# 1. import lại (đồng thời gán UID cho file mới)
"D:/setup/dev/godot/Godot_v4.7-stable_win64.exe" --headless --path . --import

# 2. dựng lại thư viện animation từ sheet
"D:/setup/dev/godot/Godot_v4.7-stable_win64.exe" --headless --path . --script res://tools/build_player_anims.gd
```

Bước 2 sinh ra `scenes/player/player_anims.tres` — một `AnimationLibrary` gồm 16 animation
(4 trạng thái × 4 hướng; `_left` và `_right` cùng cột `1`, chỉ khác khoá `flip_h`) cộng
`RESET`. Mỗi animation có hai track `Sprite3D:frame` và `Sprite3D:flip_h`. Chạy lại bao
nhiêu lần cũng được: script tự giữ UID cũ nên `player.tscn` không bị mất tham chiếu.

Thêm `--` rồi `--skip=idle_down,run_down` để **bỏ bớt** vài animation — bản `start` dùng
cách này để chừa hai animation cho học viên tự tạo trong editor.

Thêm **tag mới** (ví dụ vẽ thêm tư thế `fall` riêng) thì phải khai báo trong hằng `SPEC` của
`tools/build_player_anims.gd` — thả art vào sheet không tự có tác dụng.

## Điều nên sửa ở sheet (chưa làm)

- **Kiếm của `atk` bị cắt** ở biên ô (cột `1` mép phải, cột `2` mép trái). Hai cách: vẽ lại
  đòn chém gọn trong 64 px, hoặc đổi ô sang 96 × 64 rồi cập nhật `hframes`, `pixel_size`
  không đổi nhưng `Position.y` của `Sprite3D` tính lại theo hàng chân mới.
- **Cột thứ 4 trống** chiếm 25 % texture và buộc `hframes = 4` dù chỉ có 3 hướng. Sheet
  `actions` đã là 3 cột (192 px). Thống nhất về 3 cột thì công thức thành `hàng × 3 + cột`
  và mọi số `frame` trong tài liệu đổi theo.
- **`idle` không nằm ở hàng 0.** Khung mặc định `frame = 0` là khung chạy, nên editor và
  animation `RESET` phải nhớ số 16. Đưa `idle` lên đầu thì tư thế nghỉ là frame `0`.
- **Tên tag không khớp tên trong game**: `walk` → `run`, `atk` → `Attack`, và `carring` viết
  sai chính tả (`carrying`). Tên file JSON cũng không khớp PNG (`foxy_sprite_sheet.json` đi
  với `foxy_hat_sprite_sheet.png`).
