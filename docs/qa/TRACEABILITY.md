# Requirements → UI → Functions → DB → Test Traceability

| Requirement | UI | Functions | RTDB paths | Tests |
|---|---|---|---|---|
| FR-001/002 Sign-in & onboarding | UI-01..04 | F01, F02 | users, households, members, userHouseholds | TC-001 |
| FR-003/004 family invites/roles | UI-38,39 | F03..F07 | invites, members, userHouseholds | TC-002,003,035 |
| FR-005/006 accounts/category | UI-26..28 | F08..F10 | accounts,categories | TC-007,030 |
| FR-007/008 ledger CRUD | UI-09..14 | F11,F14 | ledgerEvents,transactionList,accountMovements | TC-004..008,031 |
| FR-009 reversal/correction | UI-13,14 | F12,F13,F14,F41 | ledgerOperations,ledgerEvents | TC-008,009,037 |
| FR-010 paginated list | UI-09 | F14 | transactionList | TC-010 |
| FR-011..013 OCR | UI-15..19 | F26..F29 | receiptJobs,receiptDrafts | TC-011..013,036 |
| FR-014/015 budgets | UI-23..25 | F16,F17 | budgets,budgetStatus | TC-014,015 |
| FR-016/017 home widgets | UI-05..08 | F35,F36 | widgetLayouts,widgetSnapshots | TC-021,022 |
| FR-018/019 analytics | UI-20..22 | F14,F15,F41 | summaries,transactionList | TC-016,017 |
| FR-020/021 wealth | UI-26..30 | F20,F21,F24 | assets,assetValuations,netWorthSnapshots | TC-018 |
| FR-022..024 savings/investment | UI-31..34 | F18,F19,F22,F23,F25 | goals,holdings,cashflows,growthInsights | TC-019,020 |
| FR-025/026 notifications | UI-35..37 | F30..F34 | notificationInbox,notificationSettings | TC-023,024 |
| FR-028 ads | UI-05/plus | F37..F40 | entitlements | TC-025,026,038 |
| FR-029/030 subscriptions | UI-41..44 | F37..F40 | purchaseEvents,entitlements | TC-026..029,039 |
| FR-031 timezone/currency | UI-03,UI-40 | F02,F11,F15 | households,ledgerEvents,summaries | TC-016,030 |
| FR-032 offline/error | all | F11, F26..F29 | outbox local/receiptJobs | TC-031 |
| FR-033 export | UI-45 | F43 | exportJobs | TC-032 |
| FR-034 delete | UI-46 | F44 | deletionJobs | TC-033 |
| FR-035 accessibility | all | — | widgetLayouts/settings | TC-034,040 |
| FR-036 schedules | UI-35,36 | F33,F34 | notificationSettings,inbox | TC-024 |
| FR-037 bill due and settlement | UI-47,48 | F47,F48,F33 | bills,ledgerEvents | TC-041 |
| FR-038 personal profile/read inbox | UI-40,35 | F46,F50 | users,notificationRead | TC-042 |
| FR-039 ownership transfer | UI-38 | F51,F52 | ownershipTransferRequests,households,members | TC-043 |
| FR-011 private receipt preview | UI-18 | F53 | receiptJobs,Storage | TC-044 |

Owners must mark each row status `Not started → Implemented → Tested → Reviewed → Released` in project tracker. Do not infer feature completeness from file existence alone.
