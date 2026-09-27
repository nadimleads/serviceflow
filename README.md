# ServiceFlow App  

**ServiceFlow** is a workflow automation app designed for consultancy firms to simplify internal operations and client management.

**Service Flow app**, where I followed an **Agile-based iterative development approach**.

---

## 📌 Problem  

In some companies, most processes were completely manual:

- Client invoices were typed manually  
- Client details were recorded manually and lacked proper tracking.
- Document counts and billing were tracked manually  
- Employee work progress reports were maintained manually  
- Even while giving updates to the clients, it required calling multiple teams to check progress.

This led to delays, miscommunication, and wasted time.

---

## 💡 Solution  

ServiceFlow digitizes and automates the workflow by providing:

(Surface level overview)
- 📄 Automated invoice generation  
- 📊 Employee work progress tracking  
- 🔄 Real-time task & status updates  
- 📱 Centralized client management  
- ⚡ Faster and smoother team communication  

The goal is to reduce manual effort, improve transparency, and increase operational efficiency.

---

## Tech Stack  

- **Flutter**  
- **Firebase** (Authentication & Firestore)  
- **Provider** (State Management)

---

## Architecture

The code follows a layered clean architecture, organised feature-first under `lib/features/`.

```
lib/
├── main.dart                      # Firebase init, then runApp
├── app/
│   ├── app.dart                   # MultiProvider → MaterialApp → AuthScope
│   └── injection.dart             # composition root: wires use cases to Firebase repositories
├── core/                          # shared, feature-agnostic code
│   ├── utils/safe_read.dart       # tolerant readers for raw document maps
│   └── widgets/loading_screen.dart
└── features/
    ├── auth/                      # sign-in, session resolution, role
    ├── clients/                   # clients, their file, and the needed-documents cart
    ├── catalogue/                 # the document / price list ("doc items")
    └── home/                      # the signed-in shell (tabs, app bar)
```

Inside a feature:

| Layer | Folder | Contains | May import |
|---|---|---|---|
| **Domain** | `domain/` | `entities/` (plain Dart objects), `repositories/` (abstract interfaces), `usecases/` (one callable class per operation) | Nothing outside `domain/`. No Flutter, no Firebase. |
| **Data** | `data/` | `repositories/` (Firestore / FirebaseAuth implementations), `mappers/` (the only code that knows a wire field name) | Domain, `core/`, Firebase SDKs |
| **Presentation** | `presentation/` | `screens/`, `widgets/`, and the session plumbing | Domain (entities and use cases), `core/`, Flutter |

The dependency rule: arrows point inward. Presentation and data both depend on domain; domain depends on nothing. A screen reaches a use case with `context.read<CreateClient>()` — every use case is provided above `MaterialApp` by `app/injection.dart` — and never sees a repository or a `FirebaseFirestore` instance.

Pure business rules — the cart arithmetic in `ClientCart`, role parsing in `AppRole`, session resolution in `ResolveSession` — live in domain and are covered by `flutter test`.

---

# Author 
Nadim N. Zubary 
(Solo Developer)


## Project Status  
🚧
Done Upto **Requirement Analysis and Designing** now,
**This project is currently under Development phase.**  
Features are actively being built and improved.
