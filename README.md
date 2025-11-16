# GenNews - Mạng xã hội Tin tức

Chào mừng bạn đến với GenNews! Đây là một dự án ứng dụng mạng xã hội được xây dựng bằng Flutter, nơi mọi người có thể chia sẻ, bình luận và tương tác với các bài viết, tin tức.

Đây là một dự án tuyệt vời để bắt đầu nếu bạn là người mới làm quen với Flutter và muốn tìm hiểu cách xây dựng một ứng dụng hoàn chỉnh với các tính năng thực tế.

## ✨ Các tính năng chính

* **Xác thực người dùng:** Đăng ký, đăng nhập và đăng xuất an toàn bằng Firebase Authentication.
* **Thiết lập hồ sơ:** Người dùng mới sẽ được yêu cầu thiết lập hồ sơ (tên, ảnh đại diện, ngày sinh, giới tính) trước khi vào ứng dụng.
* **Trang chủ (Home Feed):** Cuộn xem các bài viết mới nhất từ những người bạn theo dõi.
* **Tìm kiếm thông minh:** Tìm kiếm bạn bè và người dùng khác bằng tên hoặc `@handle`.
* **Tương tác xã hội:** Thích, bình luận và **chia sẻ lại** bài viết của người khác, giống như trên Facebook.
* **Trang cá nhân:** Xem và chỉnh sửa thông tin cá nhân, xem lại các bài viết đã đăng.
* **Thông báo:** (Đang phát triển) Nhận thông báo khi có người theo dõi bạn, thích hoặc bình luận bài viết của bạn.

## Screenshots (Đang cập nhật)

*(Bạn có thể tự thêm ảnh chụp màn hình ứng dụng của mình vào đây để README thêm phần sinh động)*

---

## 🚀 Bắt đầu

Để chạy được dự án này trên máy của bạn, hãy làm theo các bước hướng dẫn chi tiết dưới đây. Đừng lo, các bước này được viết cho cả những người chưa có nhiều kinh nghiệm!

### 1. Cài đặt các công cụ cần thiết

Trước tiên, bạn cần có Flutter và Android Studio trên máy tính.

*   **Cài đặt Flutter:** Nếu chưa có, hãy làm theo hướng dẫn tại trang chủ của Flutter: [Get Started with Flutter](https://flutter.dev/docs/get-started/install).
*   **Cài đặt Android Studio:** Đây là công cụ chính để lập trình. Tải về tại: [Android Studio](https://developer.android.com/studio).
*   **Cài đặt Git:** Cần thiết để quản lý mã nguồn. Tải về tại: [Git](https://git-scm.com/downloads).

### 2. Thiết lập dự án Firebase

Dự án này sử dụng Firebase của Google để xử lý dữ liệu và xác thực người dùng. Đây là bước quan trọng nhất.

1.  **Tạo dự án trên Firebase:**
    *   Truy cập [Firebase Console](https://console.firebase.google.com/) và đăng nhập bằng tài khoản Google của bạn.
    *   Nhấn vào **"Add project"** (Thêm dự án), đặt tên cho dự án (ví dụ: `gennews-app`) và làm theo các bước để tạo.

2.  **Thêm ứng dụng Android vào dự án Firebase:**
    *   Trong trang tổng quan của dự án, nhấn vào biểu tượng **Android** (</>).
    *   **Android package name:** Mở file `android/app/build.gradle.kts` trong dự án của bạn và tìm dòng `applicationId`. Copy giá trị đó (ví dụ: `com.example.chuyende`) và dán vào đây.
    *   Nhấn **"Register app"** (Đăng ký ứng dụng).

3.  **Tải file cấu hình:**
    *   Firebase sẽ yêu cầu bạn tải về một file có tên `google-services.json`.
    *   **Quan trọng:** Kéo file `google-services.json` này và thả vào thư mục `android/app/` trong dự án của bạn trên Android Studio.

4.  **Kích hoạt các dịch vụ Firebase:**
    *   Trong menu bên trái của Firebase Console, vào **Build**.
    *   **Authentication:** Nhấn vào, chọn tab **"Sign-in method"**, và bật (Enable) phương thức **Email/Password**.
    *   **Firestore Database:** Nhấn vào, chọn **"Create database"**, chọn chế độ **Test mode** (Chế độ thử nghiệm) để dễ dàng bắt đầu. *Lưu ý: Chế độ này cho phép mọi người đọc/ghi dữ liệu, cần được bảo mật lại cho ứng dụng thực tế.*
    *   **Storage:** Nhấn vào, chọn **"Get started"**, và cũng chọn chế độ **Test mode**.

### 3. Tải và Cài đặt dự án

1.  **Chạy các lệnh trong Terminal:**
    Mở Terminal (hoặc Command Prompt), sau đó copy và chạy lần lượt từng lệnh dưới đây:

    ```sh
    # 1. Tải mã nguồn về máy
    git clone https://github.com/Hugz211104/appchuyende.git

    # 2. Di chuyển vào thư mục vừa tải về
    cd appchuyende

    # 3. Cài đặt tất cả các thư viện cần thiết
    flutter pub get
    ```

2.  **Mở dự án trong Android Studio:**
    *   Sau khi các lệnh trên chạy xong, mở Android Studio.
    *   Chọn **"Open an Existing Project"** (hoặc "Open") và trỏ đến thư mục `appchuyende`.

### 4. Chạy ứng dụng!

1.  **Chọn thiết bị:** Đảm bảo bạn đã chọn một máy ảo (Emulator) hoặc đã kết nối điện thoại Android thật.
2.  **Chạy:** Nhấn vào nút **Run** (biểu tượng tam giác màu xanh) trên thanh công cụ của Android Studio.

Lần đầu tiên chạy có thể sẽ hơi lâu. Sau khi hoàn tất, ứng dụng GenNews sẽ hiện lên trên thiết bị của bạn!

---

## 🤝 Đóng góp

Nếu bạn có ý tưởng gì mới hay muốn đóng góp cho dự án, đừng ngần ngại tạo một "Pull Request" nhé! Mọi sự đóng góp đều được chào đón.

Chúc bạn có những giờ phút vui vẻ với Flutter!
