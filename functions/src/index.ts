/** Mây Family Finance — Functions Entry Point (index)
 *
 * Exports only triggers. All business logic lives in modules subdirectory handler files.
 */

// -- Callable Functions --
export { createHousehold } from './modules/households/handler/create_household.js';
export { updateHousehold } from './modules/households/handler/update_household.js';
export { inviteHouseholdMember } from './modules/households/handler/invite_member.js';
export { acceptHouseholdInvite } from './modules/households/handler/accept_invite.js';
export { createLedgerEvent } from './modules/ledger/handler/create_ledger_event.js';
export { reverseLedgerEvent } from './modules/ledger/handler/reverse_ledger_event.js';
export { confirmReceiptDraft } from './modules/receipts/handler/confirm_receipt.js';

// -- RTDB Event Triggers (projector) --
export { projectLedgerEvent } from './modules/ledger/triggers/project_ledger_event.js';

// -- Scheduled Tasks --
// export { buildAnalyticsSummary } from './modules/ledger/jobs/build_analytics_summary.js';

// -- FCM Topic Subscriptions / User-facing push --
// export { subscribeUserToTopics } from './modules/notifications/handler/subscribe_user_topics.js';
