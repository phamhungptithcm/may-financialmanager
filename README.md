# May — Mây Family Finance v2.0

> **Status:** Design proposal only — NOT deployed, NOT audited, NOT implemented  
> **Version:** 2.0 · 2026-10-20  
> **Language:** Vietnamese UI copy; English identifiers and technical contracts

## Overview

A Flutter + Firebase mobile app for household financial tracking: income/expense logging, budgeting, savings goals, investment tracking, receipt OCR, native OS widgets, and in-app notifications. Built for Vietnamese families — Tiền Mặt / Mây.

This repository is a **complete engineering specification** with zero implemented application code (beyond the CocoIndex scaffolding). No Flutter app code, no compiled binaries, no running services exist yet.

## Product Summary

| Dimension | Details |
|-----------|---------|
| Platform | Flutter/Dart iOS + Android (single codebase, adaptive Cupertino/Material) |
| Backend | Firebase Functions v2 (TypeScript), Realtime Database, Cloud Storage |
| Auth | Google Sign-In, Apple Sign-In, Phone OTP (optional) |
| Data model | Immutable double-entry ledger (`LedgerEvent`) + eventual-consistent read projections |
| Tenancy | Household multi-tenant; `householdId` is the privacy boundary |
| RBAC | OWNER → ADMIN → EDITOR → VIEWER (4 roles, 8 permission dimensions) |
| Currency | VND-first, integer minor units, 0 decimal places; USD support prepared |
| Pricing | Free (discreet ads); **Mây Plus** ad-free at target VN prices ~19k/month, 190k/year |
| Billing | Apple StoreKit + Google Play Billing with server-side verification |
| OCR | Vietnamese receipt scanning; manual review mandatory — no auto-posting |
| Notifications | FCM/APNs push + in-app inbox; quiet hours; redacted lock screen |
| Widgets | 9 widget types (NET_WORTH, INCOME, EXPENSE, BUDGET, etc.); native OS widgets |
| Security | App Check, RTDB rules, Storage deny-by-default, signed URLs, RBAC in all Functions |

## Project Status

- **Specs complete:** 13 spec docs + contracts + schemas + rules drafts (27 files)
- **Provider integrations:** NONE configured — all Firebase, Apple, Google, AdMob, OCR services marked NO/TBD in the integration checklist
- **Implementation status:** ZERO app code. The `main.py` and `pyproject.toml` are a bare CocoIndex template scaffold.
- **Rules drafts:** Restrictive RTDB and Storage rules must pass emulator tests before any deploy.

## Reading Order

1. [`docs/README.md`](docs/README.md) — Master index of all docs, reading order, and file inventory
2. [`docs/specs/00_DECISIONS_SCOPE.md`](docs/specs/00_DECISIONS_SCOPE.md) — Architecture decisions & scope priorities
3. [`docs/specs/01_PRD.md`](docs/specs/01_PRD.md) — Product Requirements (39 FRs)
4. [`docs/specs/02_UI_UX.md`](docs/specs/02_UI_UX.md) — UI/UX spec (48 screens/routes)
5. [`docs/specs/03_ARCHITECTURE.md`](docs/specs/03_ARCHITECTURE.md) — System architecture & data flow
6. [`docs/specs/04_RTDB_SCHEMA.md`](docs/specs/04_RTDB_SCHEMA.md) — Data model & RTDB path dictionary
7. [`docs/specs/05_FUNCTIONS_CATALOG.md`](docs/specs/05_FUNCTIONS_CATALOG.md) — 53 backend functions with contracts
8. [`docs/specs/06_API_CONTRACTS.md`](docs/specs/06_API_CONTRACTS.md) — API contracts & error semantics
9. [`docs/specs/12_PRODUCT_ANALYTICS.md`](docs/specs/12_PRODUCT_ANALYTICS.md) — Event taxonomy & dashboards
10. [`docs/specs/13_CONFIGURATION_RUNBOOK.md`](docs/specs/13_CONFIGURATION_RUNBOOK.md) — External setup runbook

## Directory Structure

```
May/
├── pyproject.toml                # CocoIndex app skeleton (template only)
├── main.py                       # Empty cocoindex template
├── README.md                     # This file
│
└── docs/
    ├── README.md                 # Master index + reading order
    ├── ALL_IN_ONE_SPEC.md        # Consolidated spec (~210 KB, all 13 specs)
    ├── MANIFEST.json             # File inventory with sha256 hashes
    ├── MASTER_PROMPT.md          # End-to-end build prompt for coding agents
    ├── PHASE_PROMPTS.md          # Phase-by-phase prompts (Phases 0–7 + review)
    │
    ├── specs/                    # Core spec documents (v2.0)
    │   ├── 00_DECISIONS_SCOPE.md
    │   ├── 01_PRD.md
    │   ├── 02_UI_UX.md
    │   ├── 03_ARCHITECTURE.md
    │   ├── 04_RTDB_SCHEMA.md
    │   ├── 05_FUNCTIONS_CATALOG.md
    │   ├── 06_API_CONTRACTS.md
    │   ├── 07_INTEGRATIONS.md
    │   ├── 08_SECURITY_PRIVACY.md
    │   ├── 09_COMPONENT_LIBRARY.md
    │   ├── 10_TESTING_ACCEPTANCE.md
    │   ├── 11_DELIVERY_PLAN.md
    │   ├── 12_PRODUCT_ANALYTICS.md
    │   └── 13_CONFIGURATION_RUNBOOK.md
    │
    ├── contracts/
    │   └── domain-contracts.ts   # TypeScript DTO reference (not runnable)
    │
    ├── schemas/
    │   ├── ledger-event.schema.json      # JSON Schema for LedgerEvent
    │   └── receipt-draft.schema.json     # JSON Schema for ReceiptDraft
    │
    ├── firebase/
    │   ├── database.rules.json   # RTDB Security Rules (deny-by-default draft)
    │   ├── storage.rules         # Storage Rules (deny-all draft, signed URLs)
    │   └── firebase.json.example # Emulator config
    │
    ├── qa/
    │   ├── TRACEABILITY.md         # Cross-reference table (req → UI → function → DB → test)
    │   ├── INTEGRATION_CHECKLIST.md  # Provider readiness matrix (all NO/TBD)
    │   ├── VERIFICATION.md           # Build verification summary
    │   └── FUNCTIONS_MATRIX.csv      # CSV of all 53 functions
    │
    ├── reference/                    # Blueprint v1 — does NOT override v2
    │   ├── architecture_v1.md
    │   └── functions_v1.md
    │
    ├── prompts/                      # Prompt artifacts
    │   ├── MASTER_PROMPT.md
    │   └── PHASE_PROMPTS.md
    │
    ├── "Family Finance — End-to-end UX Flow.jam"  # Figma Jam design file
    └── "FamilyClanMockupFullFlow.html"            # HTML mockup/prototype
```

## Delivery Plan (8 Phases)

| Phase | Scope | Status |
|-------|-------|--------|
| **0** | Repo, toolchain, Firebase emulator, CI, Auth, App Check, design tokens | Not started |
| **1** | Auth + household + accounts, RBAC rules, 24 foundation components | Not started |
| **2** | Immutable ledger, projections, budgets, reports (hardest/core) | Not started |
| **3** | Wealth/savings/investment, net worth, goals | Not started |
| **4** | Receipt camera/OCR, private Storage, manual fallback | Not started |
| **5** | Widgets & push notifications, native OS widgets | Not started |
| **6** | Mây Plus + Free ads (IAP, AdMob, UMP) | Not started |
| **7** | Privacy export/delete, release, monitoring, accessibility | Not started |

## Key Specs Count

- **39** functional requirements (FR-001 to FR-039)
- **48** UI screens/routes (UI-01 to UI-48)
- **53** backend functions/handlers (F01 to F53)
- **54** Flutter reusable components (24 atoms + 23 domain + 7 widget framework)
- **44** minimum test scenarios (TC-001 to TC-044)

## Critical Constraints

- Monetary values: **integer minor units only**, never `double`. VND exponent 0.
- Every write to financial data must pass through Cloud Functions with Auth + App Check + RBAC validation. Admin SDK bypasses rules.
- Ledger is immutable — corrections via REVERSAL event, not in-place edits.
- Receipt OCR results are **never auto-posted** to the ledger. User review required.
- Mây Plus is per-user personal entitlement, **not** household-shared.
- Real store price must be displayed; target prices (~19k/190k VND) are only targets.
- RTDB Rules and Storage Rules are drafts — must pass emulator tests before deploy.
- All external credentials go in Secret Manager, never committed to Git.

## Getting Started (CocoIndex)

> This is the CocoIndex app scaffold — not related to the Mây Family Finance product.

```bash
uv run cocoindex update main.py
```
