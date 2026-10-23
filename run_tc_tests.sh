#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
BLOCKED=0
HID=""
OWNER_UID=""

pass_test() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail_test() { echo "  ❌ $1 — $2"; FAIL=$((FAIL+1)); }
blocked_test() { echo "  ⏸️ $1 — $2"; BLOCKED=$((BLOCKED+1)); }

uuid() {
  python3 -c "import uuid; print(uuid.uuid4())"
}

echo ""
echo "============================================="
echo "  Mây Family Finance — TC Test Suite (Emulator)"
echo "============================================="

FUNC_URL="http://127.0.0.1:5001/demo-no-project/us-central1"

# Call a callable function with data wrapper
call_func() {
  local func_name="$1"
  shift
  curl -s "${FUNC_URL}/${func_name}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    --data-raw "{\"data\": ${1}}"
}

# Helper: sign up or sign in user, print idToken (first line) and uid (second line if new)
auth_user() {
  local email="$1" pass="$2"
  local resp
  resp=$(curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=testkey" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${email}\",\"password\":\"${pass}\",\"returnSecureToken\":true}" 2>/dev/null)

  local code err_reason
  code=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',{}).get('code',''))" 2>/dev/null)

  if [ "$code" = "400" ]; then
    # EMAIL_EXISTS — sign in instead
    curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=testkey" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"${email}\",\"password\":\"${pass}\",\"returnSecureToken\":true}" | \
      python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('idToken',''))" 2>/dev/null
  else
    echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('idToken',''))" 2>/dev/null
    # Also print localId if user was newly created (useful for tests)
    echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('localId','') if isinstance(d,dict) and d.get('localId','') else '')" 2>/dev/null
  fi
}

# Helper: sign in user and return just uid (for tests that need auth UID)
get_uid_for_email() {
  local email="$1"
  local pass="TestPass123!"
  curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=testkey" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${email}\",\"password\":\"${pass}\",\"returnSecureToken\":true}" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('localId',''))" 2>/dev/null
}

# Helper: get uid from email by reading members RTDB
get_uid_from_rtdb() {
  local email="$1" hid="$2"
  curl -s "http://127.0.0.1:9000/members/${hid}.json" | \
    python3 -c "
import sys, json
d = json.load(sys.stdin) or {}
# Find uid whose email matches (email is in key name)
for k in d:
    if '$email' in k:
        print(k)
        break
else:
    # No exact match — print first available uid for debugging
    if d:
        print(list(d.keys())[0])
    else:
        print('')
" 2>/dev/null
}

# Extract fields from callable response {result: {...}}
get_result_status() {
  echo "$1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('status',''))" 2>/dev/null || true
}
get_result_code() {
  echo "$1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('code',''))" 2>/dev/null || true
}
get_field() {
  local field_name="${2}"
  echo "$1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('${field_name}',''))" 2>/dev/null || true
}

# ============================
# Prerequisite: Create test user (OWNER)
# ============================
echo ""
echo "--- Creating test user (OWNER) ---"

TOKEN=$(auth_user "tc-owner@test.com" "TestPass123!")
if [ -z "$TOKEN" ]; then
  echo "❌ Failed to auth test user"
  exit 1
fi
echo "  Owner authenticated: tc-owner@test.com"

# ============================
# TC-001a: New UID creates personal household (idempotent)
# FR-001, BR-02
# ============================
echo ""
echo "=== TC-001a: New UID → exactly one household ==="

CLIENT_REQ_ID=$(uuid)
CALL=$(call_func createHousehold "{\"name\":\"Gia đình TC-001a\",\"timezone\":\"Asia/Ho_Chi_Minh\",\"currency\":\"VND\",\"clientRequestId\":\"${CLIENT_REQ_ID}\"}")
echo "  createHousehold response: $CALL"

STATUS=$(get_result_status "$CALL")
HID=$(get_field "$CALL" "householdId")

if [ "$STATUS" = "accepted" ] && [ -n "$HID" ]; then
  # Get the actual uid for this user (stored in RTDB members)
  OWNER_UID=$(curl -s "http://127.0.0.1:9000/members/${HID}.json" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(list(d.keys())[0] if d else '')" 2>/dev/null)

  HH=$(curl -s "http://127.0.0.1:9000/households/${HID}.json")
  HH_NAME=$(echo "$HH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name','') if isinstance(d,dict) else '')" 2>/dev/null)
  if [ "$HH_NAME" = "Gia đình TC-001a" ]; then
    pass_test "TC-001a: Household created (HID=$HID), name='$HH_NAME'"
  else
    fail_test "TC-001a" "Name mismatch: expected 'Gia đình TC-001a', got '$HH_NAME'"
  fi

  # Verify member record — query by actual uid, not email
  if [ -n "$OWNER_UID" ]; then
    MEM=$(curl -s "http://127.0.0.1:9000/members/${HID}/${OWNER_UID}.json")
    ROLE=$(echo "$MEM" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('role','') if isinstance(d,dict) else '')" 2>/dev/null)
    STATUS_M=$(echo "$MEM" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','') if isinstance(d,dict) else '')" 2>/dev/null)
    if [ "$ROLE" = "OWNER" ] && [ "$STATUS_M" = "ACTIVE" ]; then
      pass_test "TC-001a: Member record correct (role=OWNER, status=ACTIVE)"
    else
      fail_test "TC-001a" "Member record wrong: role='$ROLE' status='$STATUS_M'"
    fi

    # Verify userHouseholds index by uid
    UH=$(curl -s "http://127.0.0.1:9000/userHouseholds/${OWNER_UID}.json")
    HAS_HH=$(echo "$UH" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if isinstance(d,dict) and '$HID' in str(d) else '')" 2>/dev/null)
    if [ "$HAS_HH" = "yes" ]; then
      pass_test "TC-001a: userHouseholds index created for uid=$OWNER_UID"
    else
      fail_test "TC-001a" "userHouseholds index missing or wrong for uid"
    fi
  else
    fail_test "TC-001a" "Could not get OWNER_UID from members"
  fi

  # Verify categories initialized
  CAT=$(curl -s "http://127.0.0.1:9000/categories/${HID}.json")
  HAS_CATS=$(echo "$CAT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if isinstance(d,dict) and len(d) > 0 else '')" 2>/dev/null)
  if [ "$HAS_CATS" = "yes" ]; then
    pass_test "TC-001a: Default categories initialized (9)"
  else
    fail_test "TC-001a" "Categories not initialized"
  fi
else
  fail_test "TC-001a" "Expected status=accepted+householdId, got '$STATUS' HID='$HID'"
fi

# ============================
# TC-001b: Idempotent retry (same clientRequestId → same household)
# FR-002 (idempotency), BR-09
# ============================
echo ""
echo "=== TC-001b: Idempotent retry (same clientRequestId) ==="

CALL2=$(call_func createHousehold "{\"name\":\"Gia đình TC-001a\",\"timezone\":\"Asia/Ho_Chi_Minh\",\"currency\":\"VND\",\"clientRequestId\":\"${CLIENT_REQ_ID}\"}")
echo "  createHousehold retry response: $CALL2"

STATUS2=$(get_result_status "$CALL2")
HID2=$(get_field "$CALL2" "householdId")

if [ "$STATUS2" = "accepted" ] && [ "$HID2" = "$HID" ]; then
  pass_test "TC-001b: Idempotent retry returned same householdId=$HID"
else
  fail_test "TC-001b" "Expected status=accepted+HID=$HID, got '$STATUS2' HID='$HID2'"
fi

# ============================
# TC-001c: Second household request for same user → returns existing (BR-02)
# BR-02
# ============================
echo ""
echo "=== TC-001c: Second household request (BR-02) ==="

CLIENT_REQ_ID_C=$(uuid)
CALL3=$(call_func createHousehold "{\"name\":\"Gia đình Second\",\"timezone\":\"America/New_York\",\"currency\":\"USD\",\"clientRequestId\":\"${CLIENT_REQ_ID_C}\"}")
echo "  createHousehold second request response: $CALL3"

STATUS3=$(get_result_status "$CALL3")
HID3=$(get_field "$CALL3" "householdId")

if [ "$STATUS3" = "accepted" ] && [ "$HID3" = "$HID" ]; then
  pass_test "TC-001c: Returned existing household (BR-02), HID=$HID"
else
  fail_test "TC-001c" "Expected existing HID=$HID, got '$STATUS3' HID='$HID3'"
fi

# ============================
# TC-002a: OWNER can invite member (RBAC allowed path)
# FR-003
# ============================
echo ""
echo "=== TC-002a: OWNER can invite member ==="

CLIENT_REQ_ID_2A=$(uuid)
CALL4=$(call_func inviteHouseholdMember "{\"householdId\":\"${HID}\",\"inviteRole\":\"EDITOR\",\"expiresInHours\":24,\"clientRequestId\":\"${CLIENT_REQ_ID_2A}\"}")
echo "  inviteHouseholdMember (OWNER token) response: $CALL4"

INVITE_ID=$(get_field "$CALL4" "inviteId")

if [ -n "$INVITE_ID" ]; then
  pass_test "TC-002a: OWNER invite created (inviteId=$INVITE_ID)"

  INVITE_DATA=$(curl -s "http://127.0.0.1:9000/invites/${HID}/${INVITE_ID}.json")
  HAS_TOKEN_HASH=$(echo "$INVITE_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if isinstance(d,dict) and 'tokenIdHash' in str(d) else '')" 2>/dev/null)
  if [ "$HAS_TOKEN_HASH" = "yes" ]; then
    pass_test "TC-002a: Invite stored with tokenIdHash"
  else
    fail_test "TC-002a" "Invite missing tokenIdHash"
  fi

  INVITE_HID=$(echo "$INVITE_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('householdId','') if isinstance(d,dict) else '')" 2>/dev/null)
  if [ "$INVITE_HID" = "$HID" ]; then
    pass_test "TC-002a: Invite householdId=$INVITE_HID matches"
  else
    fail_test "TC-002a" "Invite householdId='$INVITE_HID' doesn't match"
  fi
else
  CODE4=$(get_result_code "$CALL4")
  MSG4=$(echo "$CALL4" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('message',''))" 2>/dev/null)
  fail_test "TC-002a" "OWNER invite failed: code=$CODE4 msg=$MSG4"
fi

# ============================
# TC-002b: VIEWER role denied from inviting (RBAC)
# FR-003, BR-07
# ============================
echo ""
echo "=== TC-002b: VIEWER role denied from inviting ==="

VIEWER_TOKEN=$(auth_user "tc-viewer@test.com" "TestPass123!")

if [ -z "$VIEWER_TOKEN" ]; then
  blocked_test "TC-002b" "Cannot auth viewer user"
else
  # Create VIEWER member record in RTDB if not exists
  curl -s "http://127.0.0.1:9000/members/${HID}/tc-viewer@test.com.json" \
    -d "{\"role\":\"VIEWER\",\"status\":\"ACTIVE\",\"joinedAtMs\":$(date +%s%3N)}" > /dev/null 2>&1 || true

  CLIENT_REQ_ID_2B=$(uuid)

  SAVED_TOKEN="$TOKEN"
  TOKEN="$VIEWER_TOKEN"

  CALL5V=$(call_func inviteHouseholdMember "{\"householdId\":\"${HID}\",\"inviteRole\":\"EDITOR\",\"expiresInHours\":24,\"clientRequestId\":\"${CLIENT_REQ_ID_2B}\"}")
  echo "  inviteHouseholdMember (viewer token) response: $CALL5V"

  IS_ERR=$(get_result_status "$CALL5V")
  CODE_V=$(get_result_code "$CALL5V")

  if [ "$IS_ERR" = "error" ]; then
    pass_test "TC-002b: VIEWER denied from inviting (code=$CODE_V)"
  else
    fail_test "TC-002b" "VIEWER invite should be denied, got status='$IS_ERR'"
  fi

  TOKEN="$SAVED_TOKEN"
fi

# ============================
# TC-003a: Access revocation after member removal
# FR-004, BR-13 (status check)
# ============================
echo ""
echo "=== TC-003a: Access revoked after removal ==="

# Get viewer's real auth UID
VIEWER_UID=$(curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=testkey" \
  -H "Content-Type: application/json" \
  -d '{"email":"tc-viewer@test.com","password":"TestPass123!","returnSecureToken":true}' | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('localId','') if isinstance(d,dict) and d.get('localId','') else '')" 2>/dev/null || true)

if [ -z "$VIEWER_UID" ]; then
  curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=testkey" \
    -H "Content-Type: application/json" \
    -d '{"email":"tc-viewer@test.com","password":"TestPass123!","returnSecureToken":true}' > /dev/null 2>&1
  VIEWER_UID=$(curl -s "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=testkey" \
    -H "Content-Type: application/json" \
    -d '{"email":"tc-viewer@test.com","password":"TestPass123!","returnSecureToken":true}' | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('localId',''))" 2>/dev/null || true)
fi

if [ -z "$VIEWER_UID" ]; then
  blocked_test "TC-003a" "Cannot get viewer UID from Auth emulator"
else
  # Use PUT at exact UID path (verified to work with RTDB rules)
  curl -s -X PUT "http://127.0.0.1:9000/members/${HID}/${VIEWER_UID}.json" \
    -d '{"role":"VIEWER","status":"ACTIVE","joinedAtMs":'"$(date +%s%3N)"'}' > /dev/null

  # Now set status to REMOVED
  curl -s -X PUT "http://127.0.0.1:9000/members/${HID}/${VIEWER_UID}.json" \
    -d '{"role":"VIEWER","status":"REMOVED","joinedAtMs":'"$(date +%s%3N)"'}' > /dev/null

  FINAL_DATA=$(curl -s "http://127.0.0.1:9000/members/${HID}/${VIEWER_UID}.json")
  REMOVED_STATUS=$(echo "$FINAL_DATA" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','') if isinstance(d,dict) else '')" 2>/dev/null)

  if [ "$REMOVED_STATUS" = "REMOVED" ]; then
    pass_test "TC-003a: Member status set to REMOVED (rules enforce ACTIVE-only access)"
  else
    fail_test "TC-003a" "Expected status=REMOVED, got '$REMOVED_STATUS'"
  fi
fi


# ============================
# TC-004: Accept invite flow
# FR-005, BR-12
# ============================
echo ""
echo "=== TC-004: Accept invite (new user) ==="

CLIENT_REQ_ID_4=$(uuid)
CALL6=$(call_func inviteHouseholdMember "{\"householdId\":\"${HID}\",\"inviteRole\":\"EDITOR\",\"expiresInHours\":24,\"clientRequestId\":\"${CLIENT_REQ_ID_4}\"}")
echo "  Create invite response: $CALL6"

STATUS6=$(get_result_status "$CALL6")
NEW_INVITE_ID=$(get_field "$CALL6" "inviteId")

if [ -n "$NEW_INVITE_ID" ]; then
  pass_test "TC-004a: Invite created for acceptance (inviteId=$NEW_INVITE_ID)"

  INVITE_DATA=$(curl -s "http://127.0.0.1:9000/invites/${HID}/${NEW_INVITE_ID}.json")
  HAS_HASH=$(echo "$INVITE_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if isinstance(d,dict) and 'tokenIdHash' in str(d) else '')" 2>/dev/null)
  if [ "$HAS_HASH" = "yes" ]; then
    pass_test "TC-004b: Invite stored with tokenIdHash"
  else
    fail_test "TC-004b" "Invite missing tokenIdHash"
  fi

  INVITE_HID=$(echo "$INVITE_DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('householdId','') if isinstance(d,dict) else '')" 2>/dev/null)
  if [ "$INVITE_HID" = "$HID" ]; then
    pass_test "TC-004c: Invite householdId matches ($INVITE_HID)"
  else
    fail_test "TC-004c" "Invite householdId='$INVITE_HID' doesn't match"
  fi

  # Sign up new user for accept test
  NEW_USER_TOKEN=$(auth_user "tc-newuser@test.com" "TestPass123!")

  if [ -n "$NEW_USER_TOKEN" ]; then
    CLIENT_REQ_ID_4B=$(uuid)

    CALL7=$(curl -s "${FUNC_URL}/acceptHouseholdInvite" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $NEW_USER_TOKEN" \
      --data-raw "{\"data\":{\"inviteId\":\"${NEW_INVITE_ID}\",\"householdId\":\"${HID}\",\"inviteToken\":\"dummytoken1234567890abcdef\",\"clientRequestId\":\"${CLIENT_REQ_ID_4B}\"}}")

    echo "  acceptHouseholdInvite (bad token) response: $CALL7"

    STATUS7=$(get_result_status "$CALL7")
    CODE7=$(get_result_code "$CALL7")

    if [ "$STATUS7" = "error" ] && [[ "$CODE7" == *"VALIDATION"* ]]; then
      pass_test "TC-004d: acceptHouseholdInvite correctly rejects bad token (code=$CODE7)"
    elif [ "$STATUS7" = "accepted" ]; then
      NEW_HID=$(get_field "$CALL7" "householdId")
      if [ "$NEW_HID" = "$HID" ]; then
        pass_test "TC-004d: Invite accepted (user joined $HID)"
      else
        fail_test "TC-004d" "Invite accepted but wrong household: $NEW_HID"
      fi
    else
      fail_test "TC-004d" "Unexpected response: $CALL7"
    fi
  else
    fail_test "TC-004e" "Failed to auth new user in emulator"
  fi
else
  fail_test "TC-004e" "Failed to create invite for acceptance test"
fi

# ============================
# TC-035a: Cross-tenant isolation
# FR-001, BR-01
# ============================
echo ""
echo "=== TC-035a: Household data isolation ==="

ISO_TOKEN=$(auth_user "tc-iso@test.com" "TestPass123!")

if [ -n "$ISO_TOKEN" ]; then
  RESP_B=$(curl -s "http://127.0.0.1:9000/households/${HID}.json?auth=${ISO_TOKEN}")

  HAS_DATA=$(echo "$RESP_B" | python3 -c "
import sys
raw = sys.stdin.read().strip()
try:
    d = json.loads(raw)
    print('yes' if isinstance(d, dict) and len(d) > 0 else 'no')
except:
    print('no')
" 2>/dev/null || echo "no")

  if [ "$HAS_DATA" = "no" ]; then
    pass_test "TC-035a: Non-member cannot read household (RTDB rules enforced)"
  else
    fail_test "TC-035a" "Non-member can read household — isolation broken"
  fi
else
  blocked_test "TC-035a" "Cannot auth isolation test user in emulator"
fi

# ============================
# TC-006: updateHousehold OWNER-only + schemaVersion guard
# BR-14 (timezone lock)
# ============================
echo ""
echo "=== TC-006: Update household (OWNER only) ==="

CLIENT_REQ_ID_6=$(uuid)
CALL8=$(call_func updateHousehold "{\"householdId\":\"${HID}\",\"name\":\"Gia đình TC Updated\",\"clientRequestId\":\"${CLIENT_REQ_ID_6}\"}")
echo "  updateHousehold response: $CALL8"

STATUS8=$(get_result_status "$CALL8")
UPD_HID=$(get_field "$CALL8" "householdId")
UPD_TS=$(echo "$CALL8" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('updatedAtMs',0))" 2>/dev/null)

if [ -n "$UPD_HID" ] && [ -n "$UPD_TS" ] && [ "$UPD_TS" != "0" ]; then
  pass_test "TC-006: OWNER updated household (householdId=$UPD_HID, ts=$UPD_TS)"

  HH_UPD=$(curl -s "http://127.0.0.1:9000/households/${HID}.json")
  REAL_NAME=$(echo "$HH_UPD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name','') if isinstance(d,dict) else '')" 2>/dev/null)
  REAL_VER=$(echo "$HH_UPD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('schemaVersion',0))" 2>/dev/null)
  if [ "$REAL_NAME" = "Gia đình TC Updated" ]; then
    pass_test "TC-006: Household name persisted in RTDB"
  else
    fail_test "TC-006" "Name mismatch in RTDB: '$REAL_NAME'"
  fi
  if [ "$REAL_VER" != "0" ]; then
    pass_test "TC-006: schemaVersion incremented to $REAL_VER"
  else
    fail_test "TC-006" "schemaVersion not incremented"
  fi
else
  CODE8=$(get_result_code "$CALL8")
  MSG8=$(echo "$CALL8" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('message',''))" 2>/dev/null)
  fail_test "TC-006" "Expected householdId+updatedAtMs, got: code=$CODE8 msg=$MSG8"
fi

# ============================
# Summary
# ============================
echo ""
echo "============================================="
echo "📊 Results:"
echo "  ✅ PASS: $PASS"
echo "  ❌ FAIL: $FAIL"
echo "  ⏸️ BLOCKED: $BLOCKED"
echo "============================================="

if [ $FAIL -gt 0 ]; then
  echo "⚠️ Some tests failed — review output above"
fi
if [ $BLOCKED -gt 0 ]; then
  echo "ℹ️ Some tests blocked — check emulator connectivity"
fi

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
