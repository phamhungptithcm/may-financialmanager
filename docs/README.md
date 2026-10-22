# Mây Family Finance — Engineering Specification v2.0

**Ngày** 2026-10-20 · **Ngôn ngữ** Tiếng Việt, identifiers & technical contracts English · **Trạng thái** Design proposal — NOT deployed, NOT audited.

Bộ tài liệu source-of-truth để triển khai app mobile Flutter + Firebase, gồm requirements, UX, backend, API, RTDB, bảo mật, 3rd-party integrations, kiểm thử, lộ trình và prompt giao việc cho Codex/Claude Code.

**Inventory hiện tại:** 39 functional requirements, 48 route/screen entries, 53 backend functions/handlers, 54 Flutter components, 44 minimum test scenarios. Các số này là kế hoạch triển khai, không phải kết quả production.

## Bắt đầu
1. Đọc `specs/00_DECISIONS_SCOPE.md` để hiểu lựa chọn và phạm vi v1.
2. Đọc `specs/01_PRD.md` và `specs/02_UI_UX.md` để hiểu workflow/acceptance.
3. Đọc `specs/03_ARCHITECTURE.md`, `specs/04_RTDB_SCHEMA.md`, `specs/05_FUNCTIONS_CATALOG.md` trước khi viết backend.
4. Đọc `specs/06_API_CONTRACTS.md`, `contracts/domain-contracts.ts`, `schemas/*.json` để thống nhất DTO.
5. Đọc `specs/07_INTEGRATIONS.md` và `specs/08_SECURITY_PRIVACY.md` trước khi kết nối dịch vụ thật.
6. Đọc `specs/09_COMPONENT_LIBRARY.md`, `specs/10_TESTING_ACCEPTANCE.md`, `specs/11_DELIVERY_PLAN.md`.
7. Dán **toàn bộ** `prompts/MASTER_PROMPT.md` vào coding agent, rồi lần lượt `prompts/PHASE_PROMPTS.md`.

## Danh sách
- `specs/00_DECISIONS_SCOPE.md` — architecture decisions, non-goals, assumptions.
- `specs/01_PRD.md` — chức năng, business rules, user stories, metrics.
- `specs/02_UI_UX.md` — sitemap, 44 màn hình/trạng thái, luồng UX, copy, motion.
- `specs/03_ARCHITECTURE.md` — clean architecture, command/read projections, offline, scale.
- `specs/04_RTDB_SCHEMA.md` — path dictionary, index, retention, validation, ledger examples.
- `specs/05_FUNCTIONS_CATALOG.md` — **53 functions/handlers**, input/output, auth, side-effects, errors, idempotency.
- `specs/06_API_CONTRACTS.md` — request/response envelope, callable, state machines, event contracts.
- `specs/07_INTEGRATIONS.md` — Auth, OCR, Storage, FCM, native widgets, IAP, AdMob/UMP, App Check, analytics, optional future APIs.
- `specs/08_SECURITY_PRIVACY.md` — RBAC, tenant isolation, threat model, privacy, deletion, logs.
- `specs/09_COMPONENT_LIBRARY.md` — 54 Flutter reusable components và design tokens.
- `specs/10_TESTING_ACCEPTANCE.md` — test cases, CI, release & security gates.
- `specs/11_DELIVERY_PLAN.md` — milestones, task sequencing, DoD.
- `specs/12_PRODUCT_ANALYTICS.md` — event taxonomy privacy preserving.
- `specs/13_CONFIGURATION_RUNBOOK.md` — Firebase/Apple/Google/AdMob/OCR external account setup and secret inventory.
- `qa/INTEGRATION_CHECKLIST.md` — live readiness matrix (currently NOT CONFIGURED).
- `prompts/MASTER_PROMPT.md` — prompt chính build end-to-end.
- `prompts/PHASE_PROMPTS.md` — prompt từng giai đoạn, có checkpoints.
- `contracts/domain-contracts.ts` — shared TS domain DTO reference, không tự nhận là project runnable.
- `schemas/*.json` — JSON Schema draft-2020-12 contracts.
- `firebase/database.rules.json` — **restrictive rule draft**, chạy Emulator Rules Tests mới được deploy.
- `firebase/storage.rules` — **deny-all client-rule draft**; authorized Cloud Functions may mint short-lived GCS signed URLs after membership verification; use Emulator/security review.
- `qa/TRACEABILITY.md` — trace requirements → UI → Functions → tests.
- `reference/` — blueprint v1 để tham khảo, không override v2.

## Quy ước bắt buộc
- Source of truth giao dịch: immutable `ledgerEvents`; projections là eventual-consistent và rebuildable.
- Tiền dùng số nguyên minor units, không dùng `double`; VND exponent 0. Bài toán đa tiền tệ phải có FX riêng.
- `householdId` là tenant boundary; Cloud Functions verify membership/role trên server từng request.
- Mọi write tài chính/role/subscription chỉ qua trusted backend; SDK admin bypass rules → bắt buộc authorization trong Functions.
- Read riêng theo household; notification/token/purchase entitlement theo UID; không public URL cho hóa đơn.
- Mây Plus: **cá nhân** mua để tắt quảng cáo cho chính UID; không làm tăng quyền truy cập dữ liệu gia đình.
- Real price phải hiển thị từ store catalog; 19.000₫ / 190.000₫ là giá target VN, chưa phải production offer.
- Chạy TestFlight/Internal Testing và Emulator trước production; tài liệu không phải chứng nhận compliance.

## Kỹ thuật khuyến nghị
Flutter stable + Dart, Riverpod, go_router, freezed/json_serializable, intl; Functions v2 TypeScript với zod; RTDB + Storage; Firebase Auth/App Check/FCM/Crashlytics/Remote Config; Cloud Tasks/Scheduler; iOS WidgetKit SwiftUI, Android Glance Kotlin; in_app_purchase or official StoreKit/Billing integration; google_mobile_ads + UMP. **Pin versions khi khởi tạo repo dựa trên upstream stable hiện tại; không đoán package versions.**

## Tài liệu bên ngoài
Xem URL và quyết định ở `specs/07_INTEGRATIONS.md`; cần xem lại tại thời điểm coding/release. Tài liệu Apple/Google đôi khi thay đổi SDK/API và store policies.
