# LimpeX — Multi-Platform Home Services Marketplace

Cross-platform application connecting customers with home service providers.

## About

LimpeX is an academic project developed as a Final Course Project (TCC), focused on simplifying the search, hiring, and management of home services while promoting the formalization of self-employed professionals via local business registration (MEI/CNPJ in Brazil).

## Key Features

- **Multi-platform App:** Flutter-based mobile and web application.
- **Role Management:** Support for Customers, Service Providers, and Administrators.
- **Automated Address Lookup:** Real-time CEP validation and address auto-fill.
- **Tax & Business Formalization:** Tax identification verification (CNPJ via BrasilAPI) and dedicated onboarding track for formalization.
- **Service Request Lifecycle:** Scheduling, booking, and managing home service requests.
- **In-App Messaging & Reviews:** Direct chat communication and mutual rating system.

## Technologies

- **Frontend:** Flutter, Dart
- **Backend:** Node.js, TypeScript, Express.js
- **Database:** PostgreSQL (`pg` driver)
- **Authentication & Security:** JWT (JSON Web Token), Bcrypt
- **External Integrations:** BrasilAPI (CNPJ lookups), ViaCEP (Address lookups)
- **Architecture:** MVVM (Frontend), Layered / Controller-Service-Repository (Backend)
- **Version Control:** Git, GitHub

## Architecture

### Mobile / Frontend
The Flutter application follows a clean architecture based on:
- **MVVM** (Model-View-ViewModel)
- **Services** (External APIs & Data Fetching)
- **Repositories** (Data Abstraction & Local Storage)

---

# 🚀 LimpeX API — Backend Services

The **LimpeX API** is the core backend service responsible for managing business logic, user authentication, data persistence, and tax compliance integration within the LimpeX ecosystem.

---

## 🛠️ Tech Stack & Dependencies

- **Language / Runtime:** Node.js with TypeScript
- **Web Framework:** Express.js
- **Database:** PostgreSQL (`pg` driver)
- **Authentication:** JWT (JSON Web Token) & Bcrypt (Password Hashing)
- **External Integrations:**
  - **BrasilAPI:** Dynamic and free registration query for tax IDs (CNPJ)
  - **ViaCEP:** Address auto-complete and location lookup
- **CORS & Security:** Configured middleware for cross-origin integration with Flutter (Mobile and Web)

---

## 🗄️ Database Schema (PostgreSQL)

The LimpeX database structure consists of the following core tables:

1. `perfil` (Role): Role definitions within the system (`CONTRATANTE`, `PRESTADOR`, `ADMINISTRADOR`).
2. `usuario` (User): Central table storing credentials, contact info, and account status.
3. `usuario_perfil` (User_Role): Many-to-many relationship mapping users to their roles.
4. `localizacao` & `endereco` (Location & Address): Management of geolocation, neighborhoods, and service coverage areas.
5. `prestador` (Provider): Business/tax data (CPF/CNPJ), company name, micro-business status, and validation seal.
6. `trilha_mei_progresso` (Formalization Track Progress): Analytics and engagement tracking for the guided formalization track.
7. `categoria_servico` & `servico` (Service Category & Service): Portfolio of services offered by each provider.
8. `solicitacao` (Service Request): Lifecycle management for bookings and service dispatch.
9. `documento_fiscal` (Tax Document): Storage for generated receipts, invoices, and tax PDFs/XMLs.
10. `mensagem` & `avaliacao` (Message & Rating): Direct in-app chat communication and mutual user feedback.

---

## 🔌 API Endpoints

### 🔐 Authentication (`/auth`)
- `POST /auth/register` — Register a new user (`CLIENT` or `PROVIDER`)
- `POST /auth/login` — Authenticate user and issue a JWT token

### 📍 Address Management (`/address`)
- `GET /address/viacep/:cep` — Fetch address data by postal code (ViaCEP)
- `POST /address` — Link a new address to the authenticated user

### 👔 Service Providers & Business Verification (`/prestador`)
- `GET /prestador/cnpj/:cnpj` — Public/authenticated business tax ID query via BrasilAPI
- `POST /prestador/dados-fiscais` — Store/update provider tax details and registration status
- `POST /prestador/trilha-mei` — Record progress in the guided formalization track and financial simulator

### 🩺 System Health
- `GET /health` — API health check and real-time PostgreSQL database connection check

---

## 📂 Project Directory Structure

```text
limpex-api/
├── src/
│   ├── config/          # Database connection pool setup (PostgreSQL)
│   ├── controllers/     # HTTP request handlers
│   ├── middlewares/     # JWT authentication & validation middlewares
│   ├── repositories/    # Data access layer & SQL queries
│   ├── routes/          # Express route definitions
│   ├── services/        # External integration services (BrasilAPI, ViaCEP)
│   └── server.ts        # Application entry point
├── .env.example         # Template for environment variables
├── package.json         # Dependencies and scripts
└── tsconfig.json        # TypeScript compiler configuration


🚦 Getting Started
Prerequisites
Node.js (v18+ recommended)

PostgreSQL database running

Flutter SDK

Setup & Installation
Clone the repository:

Bash
git clone [https://github.com/MateusGeisel/HADS_MateusGeisel_LimpeX.git](https://github.com/MateusGeisel/HADS_MateusGeisel_LimpeX.git)
cd HADS_MateusGeisel_LimpeX
Backend Setup:

Bash
cd limpex-api
npm install
Configure Environment Variables:
Copy .env.example to .env and fill in your database credentials and JWT secret:

Snippet de código
PORT=3000
DATABASE_URL=postgres://user:password@localhost:5432/limpex_db
JWT_SECRET=your_jwt_secret_key
Run the API:

Bash
npm run dev
Frontend Setup:

Bash
cd ../limpex-app
flutter pub get
flutter run
🚧 Status
🚧 Under Development — Developed as part of an undergraduate Capstone Project (TCC).
