# ServiceFlow — Unified Build Plan

**Status:** this supersedes the four independent design docs. Where they disagreed, the decision below is final. Build against this document.

---

## 0. Decisions that resolve the four designs

Each row is a fork the designs disagreed on. One answer each.

| # | Fork | **Decision** | Why this one |
|---|---|---|---|
| 1 | Where do providers live? | **`MaterialApp.builder`**, above the Navigator. Never inside `AuthWrapper` or `HomeShell`. | `home:` is a *route*. Providers placed in `AuthWrapper` are invisible to pushed routes — every `Navigator.push` would throw `ProviderNotFoundException` at runtime. `builder`'s `child` **is** the Navigator. |
| 2 | Role: stream or one-shot? | **One-shot `get()` with a 15s timeout, cached in a `State`.** Role change requires re-login. | Streaming the role tears down the whole route stack on any transient `permission-denied` or network blip, throwing the user out of a half-filled cart. Roles live on 2–3 hand-made accounts. |
| 3 | Draft cart: memory or Firestore? | **In memory**, in a route-scoped `ChangeNotifier`. | Makes "Save" mean something. If the draft were already in Firestore, Save would relabel already-saved data — which is exactly today's confusion. This is also the job the owner scoped Provider to. |
| 4 | Confirmed list shape | **One singleton doc: `clients/{id}/billing/confirmed`, with a `lines` map.** Not a subcollection of line docs. | One snapshot yields the lines *and* the total atomically, so the rendered rows always sum to the rendered total. Per-line attribution lives fine inside the nested map. 1 MB is not a constraint at ~30 lines. `neededDocs/cartDocs` is retired. |
| 5 | `totalAmount` vs `subtotal` | **`subtotal`.** `totalAmount` is deleted, not dual-written. | We are wiping the data (row 12), so the rename is free. `totalAmount` is overloaded — named "total", semantically a subtotal — and that overloading is what blocks discounts. |
| 6 | Totals: accumulate or fold? | **Fold, always.** A total is only ever produced by `lines.fold(...)` over the complete set inside the transaction. No code path increments a total. | This is the single sharpest live bug: `updatedTotal = existingTotal + addedTotal` (`select_doc_screen.dart:189`) vs `totalPrice = newQty * price` (`:175`) drift permanently after any reprice, and the profile renders 450 above a Total of 350. |
| 7 | `paymentStatus` | **Derived, never typed.** One function, mirrored byte-for-byte in rules. Both status `TextField`s are deleted. | Makes "Fully Paid / Paid ৳0 / Payable ৳5,000" structurally unwritable, in Dart *and* in the database. |
| 8 | Payments | **One `int paidAmount` on the client doc**, set absolutely via `setPaidAmount`. **No `payments` subcollection.** History comes free from the activity feed. | The spec says the section *tracks* money; it does not process it. A second source of truth needs a reconciliation feature to guard it. The activity entry gives who/when/how-much at zero extra cost. |
| 9 | Invoice | **Rendered live from `billing/confirmed` + the client doc. No `invoices` collection, no invoice counter.** Number = `clientCode`, date = `confirmedAt`. | Spec: *"Invoice is generated from that confirmed list."* Generated **from** = rendered. The pain is hand-*typing* an invoice, not archiving one. Prices are already frozen per line, so a reprint is stable. See owner question 3. |
| 10 | Comments vs status history | **One `activity` feed** with typed entries (`comment`, `file_status`, `payment`, `docs`, `client`). Every write path appends its entry **in the same transaction as the data change**. | The feed cannot disagree with the record it describes. Two of the owner's three bottlenecks (progress visibility, self-serve status) are answered by one screen: *"Where's Saiful Alam's file?"* → status chip + top of feed. |
| 11 | Doc item delete | **Both, CEO-only.** `isAvailable:false` = *Retire* (everyday action, hides from the picker); hard *Delete* allowed behind a confirm dialog. | Confirmed lines carry frozen `name`/`unitPrice`, so deleting a catalogue item cannot move any money or corrupt any file. The spec grants the CEO delete outright; refusing it is designer preference. |
| 12 | Migration | **Wipe and re-seed. Do not write a migration script.** Preserve `users/` only. | Doc IDs change scheme, `totalAmount` splits into five derived fields, status vocabularies change, the cart restructures. A correct lazy migration is ~150 lines of the riskiest code in the project, run against data the owner calls demo data. Console delete takes two minutes. |
| 13 | Client doc ID | **Auto-ID**, with `clientCode: "C0001"` as a display field. `clientCode` is never a lookup key. | Today `ctx.set(clients/C001, {...})` with no precondition means a reset counter silently *overwrites* a real client while its subcollections survive and reattach to the wrong person. Auto-ID turns that into a cosmetic duplicate code. |
| 14 | Client delete | **Real hard delete, CEO only**, cascading children first, behind a confirm dialog naming the client. `isActive` stays a separate CEO-only flag. | Spec says *"delete / edit clients"*. Firestore does not cascade — the app must delete `activity/*` and `billing/confirmed` before the parent. |
| 15 | Doc picker placement | **Inline in the client profile**, as a plain `Column` inside the existing `SingleChildScrollView`. `select_doc_screen.dart` is deleted. | Matches the spec's one-screen model, removes a push/pop round trip from a walk-in counter flow, and sidesteps the `showModalBottomSheet` + route-scoped-Provider trap entirely. No nested scrollable → no gesture fight, no sliver rewrite. |
| 16 | Composite indexes | **Zero.** `firestore.indexes.json` = `{"indexes":[],"fieldOverrides":[]}`. | Every query is single-field. `docItems.orderBy('name')` streams the whole menu and `isAvailable` is filtered in Dart, which avoids the one composite the designs wanted. |
| 17 | Catalogue cache provider | **None.** Two independent `StreamBuilder`s (Doc List tab, profile section). | The stale-price bug is killed by building the price map from `snapshot.data!.docs` in the *builder body* instead of in `itemBuilder`. A `DocItemsProvider` buys nothing beyond that. |
| 18 | `Senior Manager` | **Not a role.** Stage 3 re-provisions every `users/{uid}` doc by hand anyway; retype it to `ceo` or `employee` there. Unknown roles get a named, escapable error screen. | Aliasing exists only to avoid a lockout during a migration we are not doing. The reseed step forces the fix. See owner question 1. |

### Non-negotiable invariants

1. **Every total is a fold over the complete line set**, computed inside the transaction. Nothing increments a total, ever.
2. **A line's `unitPrice` and `name` are frozen when the line is created.** Re-adding does not reprice. Catalogue edits are never retroactive.
3. **`paymentStatus` is derived from amounts.** No UI writes it. No API sets it without moving money.
4. **All money reads go through `asInt`.** Never `int x = data['n'] ?? 0` — that is an unchecked `dynamic → int` cast that throws on the first double or console-typed string.
5. **Never use `1 << 40` or any magic upper clamp.** This project has a web target; on dart2js `int <<` returns 0 for shifts > 31, so `clamp(0, 1 << 40)` silently zeroes every amount in the app.

```dart
// lib/core/read.dart — the only numeric reader in the app.
int asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}
```

```dart
// lib/core/enums.dart — mirrored byte-for-byte in firestore.rules.
static PaymentStatus derive({required int totalPayable, required int paidAmount}) {
  if (paidAmount <= 0) return PaymentStatus.due;
  if (paidAmount >= totalPayable) return PaymentStatus.fullPaid;
  return PaymentStatus.partiallyPaid;
}
```

Two branches, not three. `(0, 0)` → **Due** (new client). `(0, 5000)` → **Full Paid** with `dueAmount: -5000`, rendered as **"Advance ৳5,000"** in green. `dueAmount` is **never clamped** — the negative number *is* the credit, and clamping it deletes the only record that the office holds the client's money. When `totalPayable == 0` the payment card prints **"Nothing billed yet"** instead of the status word; that is UI copy, not a fourth state.

---

## 1. Final Firestore schema

Money is `int`, whole BDT. No doubles, no paisa. Enum values are stable snake_case wire strings; display labels live in Dart only.

### `users/{uid}` — hand-created in the console. **The app never writes here.**

| Field | Type | Notes |
|---|---|---|
| `role` | `String` | `'ceo'` \| `'employee'`. Compared trimmed + lowercased in Dart and in rules. |
| `displayName` | `String` | Required. Every `*ByName` field and every activity entry reads it. Falls back to the email local-part if absent. |
| `email` | `String` | Convenience mirror of the Auth record. |

### `counters/clientCounter`

| Field | Type |
|---|---|
| `lastId` | `int` |

### `docItems/{autoId}` — the catalogue ("restaurant menu")

| Field | Type | Notes |
|---|---|---|
| `name` | `String` | 1–100 chars, non-empty |
| `price` | `int` | ≥ 0 (a waived/bundled doc is legitimate — delete `doc_list.dart:35`'s `price <= 0` row filter) |
| `isAvailable` | `bool` | `false` = retired. Hidden from the picker, still renders on confirmed lists. CEO-only. |
| `createdAt` | `Timestamp` | `serverTimestamp()` |
| `createdByUid` | `String` | == `request.auth.uid` |
| `createdByName` | `String` | |
| `updatedAt` | `Timestamp?` | CEO edits |
| `updatedByUid` | `String?` | |

### `clients/{autoId}`

| Field | Type | At create | Written by |
|---|---|---|---|
| `clientCode` | `String` | `'C0001'` | counter; immutable after create; display only |
| `name` | `String` | required | user |
| `phone` | `String` | required | user |
| `address` | `String` | `''` | user |
| `fileDetails` | `String` | `''` | user — the spec's "Details" |
| `targetCountry` | `String` | `''` | user † |
| `fileType` | `String` | `''` | user † |
| `givenPapers` | `String` | `''` | user † |
| `fileStatus` | `String` | `'opened_file'` | enum wire value |
| `paymentStatus` | `String` | `'due'` | **derived** |
| `subtotal` | `int` | `0` | **derived** — fold of `billing/confirmed.lines` |
| `discountAmount` | `int` | `0` | **inert placeholder** — nothing writes it in v1 |
| `totalPayable` | `int` | `0` | **derived** = `subtotal - discountAmount` |
| `paidAmount` | `int` | `0` | user, via `setPaidAmount` |
| `dueAmount` | `int` | `0` | **derived** = `totalPayable - paidAmount`. **May be negative** = advance |
| `isActive` | `bool` | `true` | CEO-only flag |
| `createdAt` | `Timestamp` | `serverTimestamp()` | |
| `createdByUid` / `createdByName` | `String` | | |
| `updatedAt` | `Timestamp` | | every write |
| `updatedByUid` | `String` | | every write |

† Exceeds the spec's five client fields but is already rendered and editable and is necessary in visa work — see owner question 4. **`email` is dropped**: written at create, rendered by no screen, absent from the edit dialog. A field the user can never see or correct is worse than no field.

There is no `fileStatusIndex` and no `fileStatusUpdatedBy*`. Ordering lives in Dart; "who moved this to Submitted and when" comes from the activity feed the profile already streams.

### `clients/{id}/billing/confirmed` — singleton, doc ID is literally `confirmed`

```
lines : Map<String /*docItemId*/, {
  name        : String      // frozen copy — survives catalogue rename/delete
  unitPrice   : int         // frozen at Save — survives catalogue reprice
  quantity    : int         // >= 1
  lineTotal   : int         // == unitPrice * quantity
  addedByUid  : String
  addedByName : String
  addedAt     : Timestamp   // Timestamp.now(); attribution only
}>
subtotal        : int        // == fold of lineTotal. Recomputed, never accumulated.
confirmedAt     : Timestamp  // serverTimestamp — ALSO the optimistic-concurrency token
confirmedByUid  : String
confirmedByName : String
```

Written with `set()` — **no merge**. `set(merge: true)` deep-merges nested maps and structurally cannot delete a removed key, which is why removal has never worked (`select_doc_screen.dart:191`).

### `clients/{id}/activity/{autoId}` — append-only work-progress feed

| Field | Type | Notes |
|---|---|---|
| `type` | `String` | `'comment'` \| `'file_status'` \| `'payment'` \| `'docs'` \| `'client'` |
| `body` | `String?` | comment text, 1–2000 chars. Absent on system entries. |
| `authorUid` | `String` | == `request.auth.uid` |
| `authorName` | `String` | denormalised — renders 50 entries with **zero** extra reads |
| `authorRole` | `String` | |
| `createdAt` | `Timestamp` | == `request.time` |
| `meta` | `Map?` | type-specific |

| `type` | `meta` |
|---|---|
| `file_status` | `{from, to, note}` |
| `payment` | `{from, to, note}` — `from`/`to` are `paidAmount` before/after |
| `docs` | `{added: [names], removed: [names], subtotalFrom, subtotalTo}` |
| `client` | `{event: 'created'}` |
| `comment` | absent |

No `system` flag (it is exactly `type != 'comment'`, derived at render). No `editedAt`. Comments cannot be edited — delete and repost. Comments can be hard-deleted by their author or the CEO. **System entries are immutable to everyone**, including the CEO: a wrong status is corrected by changing the status again, which appends a new entry.

**Enum wire values**

```
fileStatus     : opened_file → processing → submitted → (success | reject)
paymentStatus  : due | partially_paid | full_paid
role           : ceo | employee
```

Legal `fileStatus` transitions (Dart only — rules enforce *membership*, not adjacency):

```
opened_file → {processing}
processing  → {submitted, opened_file}
submitted   → {success, reject, processing}
success     → {submitted}
reject      → {submitted}
```

Forward one step at a time (skipping Processing means somebody forgot to record that documents were being made — that gap is the report). Backward one step allowed (files get bounced). Terminal states reopen to Submitted. CEO may move anywhere, to correct a mistake. Note field on the transition sheet is **optional** — compulsory paperwork in an office of three produces `.` in a text box, not information.

---

## 2. `firestore.rules` (complete, deployable)

Register it in `firebase.json` alongside the existing `flutter` block:

```json
"firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" }
```

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function profileExists() {
      return signedIn()
        && exists(/databases/$(database)/documents/users/$(request.auth.uid));
    }
    function profile() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    // Hand-typed in a console with no validation: tolerate case and whitespace.
    function role() {
      return profileExists() && 'role' in profile() && profile().role is string
        ? profile().role.trim().lower() : '';
    }
    function isCeo()   { return role() == 'ceo'; }
    function isStaff() { return role() == 'ceo' || role() == 'employee'; }

    function filled(v, maxLen) {
      return v is string && v.size() > 0 && v.size() <= maxLen;
    }
    function nonNegInt(v) { return v is int && v >= 0; }

    // Mirrors PaymentStatus.derive() in Dart. Keep the two in step.
    function expectedStatus(d) {
      return d.paidAmount <= 0 ? 'due'
           : d.paidAmount >= d.totalPayable ? 'full_paid'
           : 'partially_paid';
    }
    // dueAmount may be NEGATIVE (advance). Only subtotal/discount/paid are non-negative.
    function ledgerOk(d) {
      return nonNegInt(d.subtotal) && nonNegInt(d.discountAmount)
          && nonNegInt(d.paidAmount)
          && d.totalPayable is int && d.dueAmount is int
          && d.discountAmount <= d.subtotal
          && d.totalPayable == d.subtotal - d.discountAmount
          && d.dueAmount    == d.totalPayable - d.paidAmount
          && d.paymentStatus == expectedStatus(d);
    }

    function clientKeys() {
      return ['clientCode','name','phone','address','fileDetails',
              'targetCountry','fileType','givenPapers',
              'fileStatus','paymentStatus',
              'subtotal','discountAmount','totalPayable','paidAmount','dueAmount',
              'isActive','createdAt','createdByUid','createdByName',
              'updatedAt','updatedByUid'];
    }
    function requiredClientKeys() {
      return ['clientCode','name','phone','fileStatus','paymentStatus',
              'subtotal','discountAmount','totalPayable','paidAmount','dueAmount',
              'isActive','createdAt','createdByUid'];
    }
    // THE permission boundary. An Employee adding docs or recording a payment MUST
    // write clients/{id} — the same doc the spec says only the CEO may "edit".
    // So the client rule is FIELD-scoped, not document-scoped. See owner question 2.
    function employeeEditableClientKeys() {
      return ['subtotal','totalPayable','paidAmount','dueAmount','paymentStatus',
              'fileStatus','updatedAt','updatedByUid'];
    }
    function clientShapeOk(d) {
      return d.keys().hasOnly(clientKeys())
          && d.keys().hasAll(requiredClientKeys())
          && filled(d.name, 120) && filled(d.phone, 40) && filled(d.clientCode, 20)
          && d.fileStatus in ['opened_file','processing','submitted','success','reject']
          && d.isActive is bool
          && ledgerOk(d);
    }
    function docItemShapeOk(d) {
      return d.keys().hasOnly(['name','price','isAvailable','createdAt',
                               'createdByUid','createdByName','updatedAt','updatedByUid'])
          && d.keys().hasAll(['name','price','isAvailable','createdAt','createdByUid'])
          && filled(d.name, 100) && nonNegInt(d.price) && d.isAvailable is bool;
    }

    // Accounts and roles are created by hand in the console, per spec. Denying ALL
    // client writes is what makes self-promotion to 'ceo' impossible. 'get' on your
    // own uid is allowed even with no profile doc, so AuthScope can tell
    // "document absent" from "permission denied".
    match /users/{uid} {
      allow get:  if signedIn() && (request.auth.uid == uid || isCeo());
      allow list: if isCeo();
      allow create, update, delete: if false;
    }

    // Both roles create clients, so both need the counter. Strict +1 only.
    match /counters/{counterId} {
      allow get:  if isStaff();
      allow list: if false;
      allow create: if isStaff()
                    && request.resource.data.keys().hasOnly(['lastId'])
                    && request.resource.data.lastId == 1;
      allow update: if isStaff()
                    && request.resource.data.diff(resource.data)
                         .affectedKeys().hasOnly(['lastId'])
                    && request.resource.data.lastId == resource.data.lastId + 1;
      allow delete: if false;
    }

    // Both roles CREATE; only the CEO edits or deletes — and isAvailable is an edit.
    match /docItems/{itemId} {
      allow read: if isStaff();
      allow create: if isStaff() && docItemShapeOk(request.resource.data)
                    && request.resource.data.createdByUid == request.auth.uid
                    && request.resource.data.createdAt == request.time;
      allow update: if isCeo() && docItemShapeOk(request.resource.data)
                    && request.resource.data.createdAt    == resource.data.createdAt
                    && request.resource.data.createdByUid == resource.data.createdByUid;
      allow delete: if isCeo();
    }

    match /clients/{clientId} {
      allow get, list: if isStaff();

      allow create: if isStaff() && clientShapeOk(request.resource.data)
                    && request.resource.data.fileStatus     == 'opened_file'
                    && request.resource.data.subtotal       == 0
                    && request.resource.data.discountAmount == 0
                    && request.resource.data.paidAmount     == 0
                    && request.resource.data.isActive       == true
                    && request.resource.data.createdByUid   == request.auth.uid
                    && request.resource.data.createdAt      == request.time;

      allow update: if isStaff() && clientShapeOk(request.resource.data)
                    && request.resource.data.clientCode   == resource.data.clientCode
                    && request.resource.data.createdAt    == resource.data.createdAt
                    && request.resource.data.createdByUid == resource.data.createdByUid
                    && ( isCeo()
                         || request.resource.data.diff(resource.data)
                              .affectedKeys().hasOnly(employeeEditableClientKeys()) );

      allow delete: if isCeo();

      // "Confirmed Needed Doc". Both roles add docs. Delete is CEO-only so the
      // client-delete cascade can run.
      match /billing/{docId} {
        allow read: if isStaff();
        allow create, update: if isStaff() && docId == 'confirmed'
          && request.resource.data.keys().hasOnly(
               ['lines','subtotal','confirmedAt','confirmedByUid','confirmedByName'])
          && request.resource.data.keys().hasAll(
               ['lines','subtotal','confirmedAt','confirmedByUid'])
          && request.resource.data.lines is map
          && nonNegInt(request.resource.data.subtotal)
          && request.resource.data.confirmedByUid == request.auth.uid
          && request.resource.data.confirmedAt    == request.time;
        allow delete: if isCeo() && docId == 'confirmed';
      }

      // The work-progress log. Both roles write. Nothing is editable.
      match /activity/{entryId} {
        allow read: if isStaff();
        allow create: if isStaff()
          && request.resource.data.keys().hasOnly(
               ['type','body','authorUid','authorName','authorRole','createdAt','meta'])
          && request.resource.data.keys().hasAll(
               ['type','authorUid','authorName','createdAt'])
          && request.resource.data.type in
               ['comment','file_status','payment','docs','client']
          && (request.resource.data.type != 'comment'
              || filled(request.resource.data.body, 2000))
          && request.resource.data.authorUid == request.auth.uid
          && request.resource.data.createdAt == request.time;
        allow update: if false;      // a rewritable log is not a log
        allow delete: if isStaff()
          && resource.data.type == 'comment'
          && (resource.data.authorUid == request.auth.uid || isCeo());
      }
    }
  }
}
```

**Read cost:** `role()` triggers one `exists()` + one `get()` on `users/{uid}`, cached within a single evaluation. The limit is 10 document accesses per single-document request; this uses 2.

**`hasOnly` on create is an intentional coupling.** Adding a field means editing rules. That is the point: it turns "a typo writes an orphan field nobody ever sees" into a visible `permission-denied` at the moment of the typo. Put that sentence in the repo README.

**Rules Playground cases to run before releasing** (each is a real bug this rule set closes):

| Actor | Operation | Expect |
|---|---|---|
| Employee | create client with the zeroed shape | allow |
| Employee | update client changing `name` | **deny** |
| Employee | update client `fileStatus` → `processing` | allow |
| Employee | update client money keys + `updatedAt` | allow |
| Employee | write `discountAmount` to a *different* value | **deny** |
| Employee | write `discountAmount` to the *same* value alongside allowed keys | allow ← the save transaction depends on this |
| Employee | update `docItems/y` `price` or `isAvailable` | **deny** |
| Employee | write own `users/{uid}.role = 'ceo'` | **deny** |
| CEO | client with `paymentStatus:'full_paid'`, `paidAmount:0`, `totalPayable:5000` | **deny** |
| Employee | `counters/clientCounter.lastId` + 5 | **deny** |
| Employee | write `clients/x/billing/draft_abc` | **deny** |
| Employee | delete a colleague's comment | **deny** |
| Employee | delete a `file_status` activity entry | **deny** |

---

## 3. Stages

Each stage compiles, runs, and is testable on its own.

### Stage 1 — Session + shared shell ← **the unblocker**

*Nothing below this can be gated on role, because today the role is fetched once in `auth_wrapper.dart:48` and thrown away, which is the mechanical reason `doc_list.dart` has no role check at all.* Schema-neutral: the existing screens keep reading the old field names and keep working.

**Create**
- `lib/app/auth_scope.dart` — `AuthScope` (owns the single `authStateChanges` stream), `_SessionLoader` (a `StatefulWidget`, so the role `get()` is not re-issued on every rebuild — that is today's bug at `auth_wrapper.dart:29`), `AuthenticatedProviders` (`MultiProvider(key: ValueKey(uid))` with `Provider<AppUser>.value`, `Provider<ClientRepository>`, `Provider<DocItemRepository>`).
- `lib/app/session_error_screen.dart` — distinguishes **error** / **document absent** / **unrecognised role**, names the offending value, and carries **Retry + Sign out**. Today `auth_wrapper.dart:42-46` collapses all three into a bare `"No role assigned."` with no way out; once rules land, that screen is what *every* misconfiguration looks like.
- `lib/app/home_shell.dart` — two tabs in an `IndexedStack`, `NavigationBar`, logout icon on the app bar.
- `lib/app/clients_tab.dart` — `CeoDashboard`'s list body, moved verbatim for now.
- `lib/app/catalogue_tab.dart` — wraps `DocListScreen` for now.
- `lib/app/logout.dart` — `popUntil(isFirst)` then `signOut()`.
- `lib/models/app_user.dart` — `AppUser {uid, email, displayName, role}`, `bool get isCeo`, `AppRole.tryParse` (trim + lowercase).
- `lib/widgets/ceo_only.dart` — `CeoOnly(child:)`, using `context.read<AppUser>().isCeo`.

**Modify**
- `lib/main.dart` — `builder: (context, child) => AuthScope(child: child!)`. **Add a comment block warning that moving this into `AuthWrapper` or `HomeShell` breaks every pushed route at runtime, not compile time.**
- `lib/auth/auth_wrapper.dart` — collapses to two lines: `FirebaseAuth.instance.currentUser == null ? Welcomescreen() : HomeShell()`. No second auth stream; `AuthScope` rebuilds the Navigator from scratch on every auth transition, so a synchronous read is race-free here.
- `lib/auth/login.dart` — **delete** the `pushAndRemoveUntil(→ AuthWrapper)` at `:42-45` (it leaves two auth streams and two role fetches alive). Add `if (!mounted) return;` to both catch blocks. Nothing replaces the push — signing in rebuilds the Navigator on its own.
- `lib/ceo/custome_appbar.dart` — delete the hardcoded `height: 220` (it overflows the 170px `preferredSize` slot on every screen), raise `preferredSize` to 180, add an `actions` slot for logout.
- `lib/doc/doc_list.dart` — **delete the ungated `isAvailable` Switch** (`:58-66`) and wrap the whole `PopupMenuButton` in `CeoOnly`. **This must land in the same commit as the Employee shell**, or Employees briefly get ungated edit of the entire catalogue.

**Delete**
- `lib/ceo/ceo_dashboard.dart`, `lib/employee/employee_dashboard.dart`.

**Two mechanical rules to write down and never violate:**
1. Anything returned from `MaterialApp.builder` other than `child` renders **above** the Navigator, so `LoadingScreen` and `SessionErrorScreen` must not call `Navigator.of`, `showDialog`, or `ScaffoldMessenger`.
2. Below `AuthWrapper`, **never** call `FirebaseAuth.instance.currentUser` — `ceo_dashboard.dart:23,28` force-unwraps it and throws on the rebuild that races sign-out. Read `context.read<AppUser>()`.

**Verify before moving on:** push into a client profile and successfully call `context.read<AppUser>()`. That single check is where the `MaterialApp.builder` seam either works or it doesn't.

---

### Stage 2 — Core domain layer + the one test that matters

*Everything after this codes against one vocabulary; the money derivation is the only pure logic in the project and the only thing worth a test.* No UI change.

**Create**
- `lib/core/read.dart` — `asInt`, `asString`, `asBool`, `asMap`, `asTimestamp`. Two rules enforced everywhere: never `snap['field']` / `snap.get('field')` (both throw `StateError` on a missing field, making the `?? ''` after them dead defence — `doc_list.dart:30-32`, `auth_wrapper.dart:48`); always `snap.data()` then map indexing.
- `lib/core/enums.dart` — `AppRole`, `FileStatus` (with `wire`, `label`, `allowedNext`, `canMoveTo({required bool isCeo})`), `PaymentStatus` (with `derive`).
- `lib/core/billing.dart` — `BillingSummary.fromLines()` (folds, never accumulates) + `toClientFields()` returning the exact six fields the client doc carries and rules re-verify.
- `lib/core/money.dart` — `formatTaka(int)` and `formatDate(Timestamp?)` via `intl` (already a dependency, currently unused). Two functions, no more.
- `lib/core/errors.dart` — `showWriteError(context, e)` mapping `FirebaseException.code == 'unavailable'` to **"No connection — nothing was saved"**, `'permission-denied'` to a permission message. Capture `ScaffoldMessenger.of(context)` *before* the await.
- `lib/models/client.dart`, `lib/models/doc_item.dart`, `lib/models/activity_entry.dart` — `fromDoc` factories, the single place that knows a wire field name.
- `test/billing_test.dart` — the six-row derivation table, `fromLines` over an empty map / a null line / a zero-quantity line, and a regression for the reprice drift.

**Delete**
- `test/widget_test.dart` — the untouched counter template; it fails if run.
- `lib/loading.dart` stays (reused as `LoadingScreen`; it is currently dead code).

**Modify**
- `pubspec.yaml` — drop `shared_preferences` (Firebase Auth already persists the session) and `build_runner` (no code generator in the project).

---

### Stage 3 — Wipe, rules, and the new write shapes ← **the cut-over**

*This is the one irreversible stage; after it the app runs entirely on v2 schema.* Sequence is **wipe → deploy rules → release the app, as one change**. Deploying rules ahead of the client breaks it instantly.

**Console work first (no code):**
1. Enumerate `users/` and list every distinct `role`. Retype each to lowercase `'ceo'` or `'employee'` — **including whoever currently holds `'Senior Manager'`** — and **add `displayName`** to each.
2. ```bash
   firebase firestore:delete clients  --recursive -f --project serviceflow-69ea6
   firebase firestore:delete docItems --recursive -f --project serviceflow-69ea6
   firebase firestore:delete counters --recursive -f --project serviceflow-69ea6
   ```
   `--recursive` is mandatory: Firestore does not cascade to subcollections.
3. Seed `counters/clientCounter = { lastId: 0 }`.

**Create**
- `firestore.rules` (§2 verbatim), `firestore.indexes.json` = `{"indexes":[],"fieldOverrides":[]}`.
- `lib/data/client_repository.dart` — `createClient` (auto-ID ref generated *before* the transaction so `clientRef.id` is available for navigation; `SetOptions(merge: true)` on the counter; `padLeft(4)`; returns `({String id, String code})`), `watchClients`, `watchClient`, `deleteClient`, `setActive`, `updateIdentity`.
- `lib/data/doc_item_repository.dart` — `watchCatalogue`, `create`, `update`, `setAvailability`, `delete`, each CEO-write guarded by a `_requireCeo()` programming-error catch (rules are the enforcement; this is the loud failure if a UI gate is forgotten).
- `lib/doc/new_doc_item_sheet.dart` — `add_new_doc.dart`'s form as a bottom sheet with a FAB on the Doc List, matching the spec's *"both roles can CREATE a new Doc Item and set its price **there**"*. **Must write `createdByUid` and `createdByName`** or every create fails the rule (`add_new_doc.dart:33` has `createdBy` commented out).

**Modify**
- `firebase.json` — add the `firestore` block.
- `lib/client/add_new_client.dart` — write the v2 shape via the repository. **Only `name` and `phone` required**; today's blanket `Required` validator (`:148-150`) means a walk-in with no email or no papers yet handed over cannot be created at all, which obstructs the exact flow the app exists to serve. Add the `mounted` guard to the catch (`:84-87`).
- `lib/doc/doc_list.dart` — `orderBy('name')` (today's order is auto-ID, i.e. random), `.data()`-based defensive reads, search field, CEO-only popup with **Edit / Retire / Relist / Delete permanently**. The delete dialog says plainly: *"Client files that already list it keep their own copy of the name and price, so no bill changes. It just disappears from the menu."* That is true because of the frozen-line invariant.
- `lib/app/clients_tab.dart` — `orderBy('createdAt', descending: true).limit(50)`, status chip from `FileStatus.label`. Show inactive clients dimmed with an `Inactive` chip — **do not** re-enable `ceo_dashboard.dart:34`'s commented-out `where('active')` filter; a ledger must never hide a client who owes money. Fix the empty-state copy that currently promises a filter which is not running.
- `lib/client/clients_profile.dart` — read-only rendering on the new field names for now.

**Known gap between Stage 3 and Stage 4:** the old cart code is gone and the new one is not in yet, so no documents can be added to a client. The data was just wiped, so nothing regresses. Do not enter real client data until Stage 4 lands.

**One thing to expect:** `FieldValue.serverTimestamp()` reads as `null` in the local cache until the server acknowledges, and Firestore excludes documents whose `orderBy` field is null. A just-created client is briefly absent from the All Clients stream. Sub-second online, and the create flow navigates straight to the new profile so nobody sees it. Do **not** "fix" it with `Timestamp.now()` — the `createdAt == request.time` rule requires the sentinel.

---

### Stage 4 — Needed Doc cart, Confirmed list, Save

*This is where the accumulator drift, the stale-price cache, the two divergent cart transactions and the broken removal path all die at once.*

**Create**
- `lib/provider/client_cart.dart` — `CartLine` and `ClientCartNotifier`. **The notifier owns its own `billing/confirmed` subscription.** Feeding it from a `StreamBuilder` in `build()` causes `notifyListeners()` during build *and* — the serious one — every emission re-seeding over the user's unsaved picks. Re-seed only when `!isDirty`; record `_baseConfirmedAt` when seeded.
- `lib/client/client_profile_screen.dart` — `static Route<void> route(String clientId)` wrapping the screen in `ChangeNotifierProvider<ClientCartNotifier>`. Takes **only** `clientId`; the `clientsName` param at `clients_profile.dart:9` is redundant (the screen already streams the doc).
- `lib/client/needed_doc_section.dart` — the catalogue, inline. Builds `Map<docItemId, (name, price)>` from `snapshot.data!.docs` **in the builder body, before returning any rows** — `select_doc_screen.dart:60-61` fills that cache inside `itemBuilder`, which runs only for visible rows, and `:165` writes from it, so a row scrolled out of view carries a stale price into the ledger. Rows are a plain `Column`, never a nested `ListView`. Search field, collapse/expand header showing `3 selected · ৳5,000`, 25-row render cap with *"…and 22 more — search to narrow"*. Footer: running total, `[Cancel]`, `[Save]` (enabled only when dirty).
- `lib/client/confirmed_doc_section.dart` — read-only list of `cart.lines` with `added by Rina · 3d ago` per line, bold total, `[Generate invoice]`.

**Save transaction** (`ClientCartNotifier.commit`) — the **only** writer to `billing/confirmed`:
- All reads before all writes; `if (!snap.exists) throw StateError('This client no longer exists.')` after every `tx.get(clientRef)` — `tx.update` on a deleted doc throws `not-found`, and the CEO deleting a client while an employee has the profile open is reachable here.
- **Optimistic concurrency:** if `prevData['confirmedAt'] != expectedConfirmedAt`, throw `ConcurrentEditException`. Without it, in-memory draft + full-replace Save means whoever saves second silently erases the first person's lines, with no error and no trace. The profile shows a persistent banner: *"Someone else changed this list. Reload to see it — your unsaved changes will be lost."*
- `subtotal` is `BillingSummary.fromLines(...)`, folded. `discountAmount` is **read from the client doc and written back unchanged** — that is why an Employee's save passes the rule (`affectedKeys()` reports only keys whose value *changed*), and why it must not be hardcoded to 0.
- Appends the `docs` activity entry in the same transaction. `addedNames`/`removedNames` are computed **before** `runTransaction` from a snapshot copy of the draft — Firestore re-runs the callback on contention and it must be deterministic.
- **On failure the cart is never cleared.** It stays dirty and intact so the user can retry.

**Off-menu lines** (catalogue item retired or deleted): compute `onMenu` at render time by set membership — no stored flag. They render in the Needed Doc card with `−` enabled and `+` hidden, so they can be reduced or removed but not re-added. They never disappear silently; their frozen `name` and `unitPrice` are still what the client owes.

**Delete**
- `lib/client/select_doc_screen.dart` and `_updateDocQuantity` in `clients_profile.dart:276-324`, **in the same commit**. Leaving either alive restores the two-writers bug.
- `lib/client/clients_profile.dart` once its sections are all extracted.

---

### Stage 5 — Payments and File Status

*The two derived-state paths. Both currently write a status string without moving the thing the status describes.*

**Create**
- `lib/client/payment_section.dart` — renders from `BillingSummary`: Subtotal / Discount (only when > 0) / Total Payable / Paid / **Due** (red when > 0) or **Advance** (green when `dueAmount < 0`) / Status. Two controls: **Record payment** (a number field seeded with the current `paidAmount`, labelled *"Total received so far"* — it is a running total, and mislabelling it is how a ledger goes wrong) and **Settle full balance** (calls `setPaidAmount(totalPayable)`).
- `lib/client/file_status_stepper.dart` — pinned under the client name, above every card. Four nodes, the last being the outcome. `[Update status]` opens a sheet listing **only** `allowedNext(current)`; illegal states are simply absent.
- `ClientRepository.setPaidAmount` and `.changeFileStatus` — both transactions, both appending their activity entry in the same write.

**Modify / delete inside `clients_profile.dart`'s remains**
- **Delete the free-text Payment Status `TextField`** (`:243-246`, `:263`) and the free-text **File Status `TextField`** (`:176-179`, `:203`). These are how `'File Opened'` and `'Fully Paid'` got into the database, and with rules enforcing membership they would now hard-fail with an opaque `permission-denied`.
- **Delete `_markAsFullyPaid`** (`:20-49`). It writes `paymentStatus` and never touches `paidAmount`; under a derived status it becomes a silent no-op.
- Wrap the Basic Information pencil (`:373`), the File Information pencil (`:413`) and the `isActive` switch (`:383-391`) in `CeoOnly`.

---

### Stage 6 — Work Progress feed

*This is the stub that single-handedly defeats two of the owner's three bottlenecks: `clients_profile.dart:646-659` renders `const Text("No comments yet")` unconditionally with `onPressed: () {}`.*

**Create**
- `lib/client/activity_section.dart` — titled **Work Progress**, not "Comments". Composer pinned at the **top** so a new entry lands directly beneath it with no scroll hunt. `StreamBuilder` over `.orderBy('createdAt', descending: true).limit(50)` — single-field, no index. Human comments get an avatar initial, name + role chip, relative time, full body, and a `⋮` **Delete** for the author or the CEO. System entries get one muted icon line — visually subordinate, never hidden. The interleaving *is* the story of the file.
- `ClientRepository.addComment`.
- An 8-line `shortAgo(DateTime?)` in `lib/core/money.dart` using plain `Duration` arithmetic with a `DateFormat` fallback past 30 days. No new dependency.

`createdAt` is null on the local echo of a just-posted comment. Render **"just now"** for null, not an empty string.

By this stage every write path — docs Save, payment, status change, client create — already appends its entry, so the feed is populated from day one and never empty.

---

### Stage 7 — Invoice screen

*Pure render. No new collection, no counter, no rules, no index, no packages.*

**Create**
- `lib/client/invoice_screen.dart` — reads the two snapshots the profile already holds.

| Element | Source |
|---|---|
| Invoice number | `clients/{id}.clientCode` |
| Date | `billing/confirmed.confirmedAt` |
| Bill to | `clients/{id}.name`, `.phone`, `.address` |
| Lines | `billing/confirmed.lines`, sorted by name: name, unitPrice, quantity, lineTotal |
| Subtotal / Discount / Total payable | `clients/{id}.subtotal`, `.discountAmount`, `.totalPayable` |
| Paid / Due | `clients/{id}.paidAmount`, `.dueAmount` |
| Status | `PaymentStatus.label` |

Amounts are stable across catalogue repricing because `unitPrice` is frozen per line at Save. Screenshot-able and shareable through the OS as-is.

---

### Stage 8 — CEO destructive actions and cleanup

*Client delete lands last because its cascade must know every subcollection, and `activity` only exists after Stage 6.*

- `ClientRepository.deleteClient` — page `activity` in batches of 200, delete `billing/confirmed`, then the parent. Every step idempotent, so a re-run finishes an interrupted delete. Behind an ordinary confirm dialog naming the client.
- Sweep the three deprecated `Color.withOpacity` calls to `withValues(alpha:)` (`ceo_dashboard.dart:102` and friends warn on this toolchain).
- Optional: a single `ThemeData` in `main.dart`, now that ad-hoc colour literals scattered across every screen finally have somewhere to live.

---

## 4. The shared-shell refactor — explicit

**It is Stage 1, and it is the highest-leverage change in the project.**

Today `CeoDashboard` is 225 lines wiring a clients stream and four nav destinations; `EmployeeDashboard` is 30 lines whose entire body is `Center(child: Text("Welcome Employee"))` and whose only control is a logout button. The spec grants Employee five capabilities; **zero are reachable**. Of the six post-login screens that exist, an Employee can reach one — their own stub. Meanwhile the spec's *only* permission difference (CEO-alone edit/delete) is 0% realised in either direction: edit is ungated for everyone, delete does not exist for anyone.

**Do not build a parallel `EmployeeDashboard`.** That duplicates 225 lines and guarantees drift. Delete both dashboards and serve both roles from one `HomeShell`, gating on `context.read<AppUser>().isCeo`.

**What it touches:** `main.dart`, `auth/auth_wrapper.dart`, `auth/login.dart`, `ceo/custome_appbar.dart`, `doc/doc_list.dart`; creates `app/auth_scope.dart`, `app/session_error_screen.dart`, `app/home_shell.dart`, `app/clients_tab.dart`, `app/catalogue_tab.dart`, `app/logout.dart`, `models/app_user.dart`, `widgets/ceo_only.dart`; deletes `ceo/ceo_dashboard.dart` and `employee/employee_dashboard.dart`.

**Nav:** two tabs (All Clients, Doc List) in an `IndexedStack`, a FAB on each (Add Client, New Doc Item), and logout as an app-bar icon. The current bar hardcodes `currentIndex: 0` while pushing routes, so tapping "Add Client" highlights "Logout" — two honest tabs plus two FABs covers the same five entry points without the lying highlight, and putting New Doc Item on the Doc List screen matches the spec literally.

**The complete `CeoOnly` call-site list — six, and no more:**

1. Doc List: Edit name/price
2. Doc List: Retire / Relist (`isAvailable`)
3. Doc List: Delete permanently
4. Client profile: Basic Information edit pencil
5. Client profile: File Information edit pencil
6. Client profile: `isActive` switch and Delete client

Everything else — Add Client, New Doc Item, add/remove docs, Save, advance File Status, record a payment, comment, generate invoice — renders unconditionally for both roles.

If you ever find yourself adding a seventh capability getter, the spec changed. Hiding a widget is UX; `firestore.rules` is the enforcement.

---

## 5. Decisions the owner must make

1. **Is `Senior Manager` a real tier?** `auth_wrapper.dart:54-56` routes it to the full CEO surface, granting the spec's CEO-only powers to a role the spec does not acknowledge, with nothing in the UI marking it as elevated. Stage 3 retypes every `users/{uid}` doc by hand, so the fix is free — but you must say whether that account becomes `ceo`, becomes `employee`, or gets deleted. If it is a genuine third tier it needs its own permission set in the spec; it cannot keep aliasing CEO.

2. **May an Employee advance `fileStatus` and record payments?** `fileStatus` is a client field, so strictly an Employee touching it is "editing a client". But the stated reason this app exists is that *"the client-facing employee had to phone the document-making team"* — if only the CEO can record progress, the CEO becomes the phone call, and the front-desk employee taking the cash cannot record it. **Shipping default: yes.** One-token reversal: delete `'fileStatus'` from `employeeEditableClientKeys()`; for payments delete `'paidAmount'`, `'dueAmount'` and `'paymentStatus'` **together**, or the ledger invariant in rules rejects the write.

3. **Is a live-rendered invoice enough, or do you need dated archived invoices?** Today's decision: the invoice always reflects the client's *current* confirmed list. Hand a client a ৳5,000 printout on Monday, add a document on Friday, and reprinting shows ৳6,500. That is correct as a statement of what they owe, but the paper in their hand is now stale. **If an accountant needs a numbered series, or you need several dated invoices per client, say so now** — it means adding `clients/{id}/invoices/{autoId}` with a copied line array, plus a global-vs-per-client numbering decision. Adding it later is a clean backfill from `billing/confirmed`; deciding after the office has been printing for a month is not.

4. **Keep `targetCountry`, `fileType`, `givenPapers`?** The spec's client fields are Name, Phone, Details, Address, Created At. These three exceed that list, are already rendered and editable, and are necessary in visa work. Default: keep, with only Name and Phone required. `email` is being dropped either way — it was write-once, rendered by no screen, and absent from the edit dialog.

5. **Number grouping: `1,250,000` (Western) or `12,50,000` (South-Asian lakh)?** One string in `lib/core/money.dart` — `'en_US'` or `'en_IN'`. Both verified working with `intl 0.20.2`. Never use `'en_BD'`; `NumberFormat` throws on an unregistered locale at runtime.

6. **Does the client receive paper?** If yes, PDF export becomes real scope with a real cost: the built-in PDF fonts have **no glyph for ৳ (U+09F3)**, so it needs either an embedded Bengali TTF (~400 KB asset, licence decision) or `BDT 5,000` in PDF output only. If the on-screen invoice plus a screenshot is enough, no new packages ever ship.

---

## 6. NOT NOW

| Deferred | Safe because | Do it when |
|---|---|---|
| **Discount UI** | `discountAmount: int = 0` exists on every client from day one and `totalPayable = subtotal - discountAmount` is already computed by `BillingSummary` and re-verified by rules. Today the arithmetic is a no-op. | The owner asks. Then: a CEO-only dialog sets `discountAmount`, and it joins `employeeEditableClientKeys()` **or** the CEO re-clamps after any line change — otherwise an Employee removing a line drops `subtotal` below the stored discount and `ledgerOk` rejects the write. No formula edits, no backfill. |
| **`discountType` / `discountValue` / `discountReason`** | These are *inputs* to computing `discountAmount`, and nothing reads them. A field exists on day one if and only if an existing formula or query reads it. | Same trigger as above. Adding three strings to `clientKeys()` is a one-line rules edit, not a migration. |
| **"Who owes us money" receivables view** | `dueAmount` is **stored**, not computed in a widget, so the query is already possible: `where('dueAmount', isGreaterThan: 0).orderBy('dueAmount')` — a range filter plus `orderBy` on the *same* field stays single-field and needs no composite index. | Client count passes ~100, or someone asks for a debtors list. |
| **`payments` subcollection** | `paidAmount` is a plain int and the `payment` activity entry already records who/when/from/to for every change. Purely additive later: `paidAmount` becomes its sum, one new match block in rules, no field renames. | Someone asks "what did this client pay and when, by method" and the activity feed is not enough — i.e. an accountant, or cash handled by more than two people. |
| **Archived invoice documents** | `billing/confirmed` already freezes `name` and `unitPrice` per line, so it is exactly the source to backfill from. | Owner question 3 comes back "yes". |
| **PDF / print / share** | The PDF builder would be a pure function of the confirmed lines + client doc — no Firestore, no state — so it carries zero data-model risk when added. | Owner question 6 comes back "yes". Budget the ৳ glyph problem. |
| **Tests beyond `test/billing_test.dart`** | The billing derivation is the only pure logic in the project and the only place a bug is silent. Everything else is Firestore-shaped, and there is no fake Firestore in the dependency list — adding one is a project of its own. Repositories take `FirebaseFirestore` by constructor because it costs nothing, not because a suite is queued. | A second person joins, or a bug ships twice from the same file. |
| **Pagination / search on the clients list** | `.orderBy('createdAt', descending: true).limit(50)` is already bounded and ordered — an improvement on today's unbounded, unordered full-collection stream. Filtering `isActive` in Dart is strictly cheaper than the round trips an index would save at this size. | The list exceeds 50 and someone scrolls looking for a name. Then search becomes a `ChangeNotifier` holding the query string — genuine cross-widget state between an app-bar field and the list body. |
| **Offline writes** | Every money action is a `runTransaction`, and Firestore transactions require a server round trip — unlike `set`/`update` they are **not** queued from cache. This is a deliberate trade of offline entry for consistent derived money fields in a one-office app. `showWriteError` makes `code == 'unavailable'` say *"No connection — nothing was saved. Your list is still here."* instead of failing silently, and a failed Save never clears the cart. | The office moves to a location with bad connectivity, or staff start billing off-site. That is a re-architecture (queued deltas, not derived totals), not a patch. |
| **Live role updates** | The role is read once at login. Roles belong to two or three hand-made accounts; nobody demotes a CEO mid-session. Streaming it costs a mid-session route-stack teardown on any transient error. | Never, realistically. If it is ever wanted, re-introduce the session stream and accept the teardown. |
| **Cross-client analytics** (`collectionGroup` over lines, "how many Asset Evaluations did we sell this month") | Not answerable against a map key — this is the one real cost of the map model, and nobody has asked for it. | Someone asks. Then add a flat `soldLines` collection written alongside Save; do not restructure `billing/confirmed`. |
| **Comment editing, soft delete, tombstones, filter chips, activity paging** | Three colleagues, an internal notes field, `limit(50)` newest-first. A governance model for an organisation with adversaries is not what this is. Comments are hard-deleted by author or CEO; system entries are immutable to everyone. | Never, at this headcount. |
| **`docsVersion` on anything but the confirmed list** | Concurrent edits to `paidAmount` and `fileStatus` are last-write-wins, which is correct for a single office — the loser's write is a complete value, not a corrupted hybrid. The one place it is not benign (full-replace of the line set) is already guarded by the `confirmedAt` token, where it costs nothing because the transaction reads that document anyway. | The app leaves the office. |