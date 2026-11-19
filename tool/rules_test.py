"""Live security-rules test against iba-roombook-3057d via REST."""
import json, random, string, urllib.request, urllib.error
from datetime import datetime, timedelta, timezone

KEY = "AIzaSyAVZ2BAEg1bMwnq84ikcOEQ6y6mq8QhyqI"
P = "iba-roombook-3057d"
BASE = f"https://firestore.googleapis.com/v1/projects/{P}/databases/(default)/documents"
NAME = f"projects/{P}/databases/(default)/documents"
PKT = timezone(timedelta(hours=5))


def call(method, url, body=None, token=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"{}")


def rid(n=20):
    return "".join(random.choices(string.ascii_letters + string.digits, k=n))


def signup(tag):
    email = f"rulestest-{tag}-{rid(5).lower()}@khi.iba.edu.pk"
    s, r = call("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={KEY}",
                {"email": email, "password": rid(16), "returnSecureToken": True})
    assert s == 200, r
    return {"email": email, "uid": r["localId"], "tok": r["idToken"], "name": f"RulesTest {tag}"}


def S(v): return {"stringValue": v}
def TS(d): return {"timestampValue": d.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}


results = []
def check(num, who, desc, expect, status):
    got = "ALLOW" if status == 200 else f"DENY ({status})"
    ok = (expect == "ALLOW") == (status == 200)
    results.append((num, who, desc, expect, got, "PASS" if ok else "FAIL"))


def book_commit(user, room, start):
    """Same three writes the app's transaction makes."""
    end = start + timedelta(minutes=30)
    millis = int(start.timestamp() * 1000)
    lock_id = f"{room}_{millis}"
    bid = rid()
    writes = [
        {"update": {"name": f"{NAME}/bookings/{bid}", "fields": {
            "roomId": S(room), "roomName": S("Room-9184-1"), "date": S(start.strftime("%Y-%m-%d")),
            "slotStart": TS(start), "slotEnd": TS(end), "userId": S(user["uid"]),
            "userName": S(user["name"]), "status": S("active"), "lockId": S(lock_id)}},
         "currentDocument": {"exists": False},
         "updateTransforms": [{"fieldPath": "createdAt", "setToServerValue": "REQUEST_TIME"}]},
        {"update": {"name": f"{NAME}/slotLocks/{lock_id}", "fields": {
            "bookingId": S(bid), "roomId": S(room), "slotStart": TS(start), "userId": S(user["uid"])}}},
        {"update": {"name": f"{NAME}/users/{user['uid']}", "fields": {
            "activeBookingIds": {"arrayValue": {"values": [S(bid)]}}}},
         "updateMask": {"fieldPaths": ["activeBookingIds"]}},
    ]
    s, r = call("POST", f"{BASE}:commit", {"writes": writes}, user["tok"])
    return s, bid


def cancel(user, bid):
    return call("PATCH", f"{BASE}/bookings/{bid}?updateMask.fieldPaths=status&updateMask.fieldPaths=cancelledBy",
                {"fields": {"status": S("cancelled"), "cancelledBy": S(user["uid"])}}, user["tok"])[0]


A, B = signup("a"), signup("b")
created_bookings = []
try:
    for u in (A, B):
        # extra: sign-up profile that claims admin must be rejected
        s, _ = call("PATCH", f"{BASE}/users/{u['uid']}?currentDocument.exists=false",
                    {"fields": {"uid": S(u["uid"]), "name": S(u["name"]), "email": S(u["email"]),
                                "role": S("admin"), "activeBookingIds": {"arrayValue": {}}}}, u["tok"])
        if u is A:
            check("0", "student", "sign-up creating own profile with `role: admin`", "DENY", s)
        s, _ = call("PATCH", f"{BASE}/users/{u['uid']}?currentDocument.exists=false",
                    {"fields": {"uid": S(u["uid"]), "name": S(u["name"]), "email": S(u["email"]),
                                "role": S("student"), "activeBookingIds": {"arrayValue": {}}}}, u["tok"])
        assert s == 200, ("profile create failed", s)

    s, _ = call("PATCH", f"{BASE}/users/{A['uid']}?updateMask.fieldPaths=role",
                {"fields": {"role": S("admin")}}, A["tok"])
    check("1", "student", "update own `users/{uid}` → `role: \"admin\"` (self-promotion)", "DENY", s)

    s, _ = call("PATCH", f"{BASE}/users/{A['uid']}?updateMask.fieldPaths=name",
                {"fields": {"name": S("RulesTest a renamed")}}, A["tok"])
    check("2", "student", "update own `users/{uid}` → `name`", "ALLOW", s)

    s, _ = call("PATCH", f"{BASE}/users/{B['uid']}?updateMask.fieldPaths=name",
                {"fields": {"name": S("hacked")}}, A["tok"])
    check("2b", "student", "update another user's profile", "DENY", s)

    day = (datetime.now(PKT) + timedelta(days=6)).date()
    slot = datetime(day.year, day.month, day.day, 20, 30, tzinfo=PKT)

    # booking for someone else
    s, _ = call("POST", f"{BASE}/bookings", {"fields": {
        "roomId": S("room1"), "userId": S(B["uid"]), "status": S("active"),
        "slotStart": TS(slot), "slotEnd": TS(slot + timedelta(minutes=30))}}, A["tok"])
    check("3", "student", "create booking with `userId` = someone else", "DENY", s)

    s, b_bid = book_commit(B, "room1", slot)
    check("3b", "student", "create own booking + slot lock (what the app's transaction writes)", "ALLOW", s)
    created_bookings.append(b_bid)

    s, _ = call("GET", f"{BASE}/bookings/{b_bid}", token=A["tok"])
    check("3c", "student", "read another student's booking", "ALLOW", s)

    s, a_bid = book_commit(A, "room1", slot)
    check("7", "student", "book a slot whose lock points to someone else's ACTIVE booking (double-book bypassing the app)", "DENY", s)

    s = cancel(A, b_bid)
    check("4", "student", "update another student's booking → `cancelled`", "DENY", s)

    s, _ = call("DELETE", f"{BASE}/bookings/{b_bid}", token=B["tok"])
    check("5", "student", "delete own booking", "DENY", s)

    s, _ = call("DELETE", f"{BASE}/slotLocks/room1_{int(slot.timestamp()*1000)}", token=B["tok"])
    check("5b", "student", "delete a slot lock", "DENY", s)

    s = cancel(B, b_bid)
    check("4b", "student", "cancel own booking before it starts", "ALLOW", s)

    s, a_bid = book_commit(A, "room1", slot)
    check("7b", "student", "book the same slot after it was cancelled", "ALLOW", s)
    if s == 200:
        created_bookings.append(a_bid)
        cancel(A, a_bid)

    s, _ = call("PATCH", f"{BASE}/rooms/room1?updateMask.fieldPaths=capacity",
                {"fields": {"capacity": {"integerValue": "99"}}}, A["tok"])
    check("9", "student", "edit a room", "DENY", s)

    s, _ = call("GET", f"{BASE}/bookings?pageSize=1")
    check("8", "signed out", "read `bookings`", "DENY", s)
finally:
    for u in (A, B):
        call("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:delete?key={KEY}", {"idToken": u["tok"]})

print(json.dumps({"results": results, "users": [A["uid"], B["uid"]], "bookings": created_bookings,
                  "slot": slot.isoformat()}, indent=1))
