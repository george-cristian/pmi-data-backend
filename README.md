# Development Environment Setup (Rust + Dev Containers)

This guide describes how to set up the development environment for this project using VS Code Dev Containers and Docker Compose.

---

## 🔧 Prerequisites

Before starting, ensure you have the following installed:

- [Docker](https://www.docker.com/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers Plugin]
- Git (with an SSH key configured, if you plan to push via SSH)

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone git@github.com:your-org/your-repo.git
cd your-repo
```

### 2. Start Required Containers

Start the **PostgreSQL database** and optional services (e.g., pgAdmin):

```bash
docker compose up -d postgres
```

> This also recreates the `pmi_network` Docker network needed by the Dev Container.

---

### 3. Open Project in VS Code Dev Container

- Open VS Code
- Press `F1` → `Dev Containers: Open Folder in Container...`
- Select the root of the project (where `.devcontainer/` is located)

VS Code will:
- Build the `Dockerfile-local` inside `.devcontainer/`
- Mount your source code
- Forward ports (e.g., 3000)
- Automatically connect to the `pmi_network` to access the running DB

---

## 🐘 Database Access

The app connects to a PostgreSQL container via Docker network:

```env
DATABASE_URL=postgres://<user>:<password>@postgres:5432/<db_name>
```

Make sure `.env` is correctly configured and mounted.

From inside the dev container, you can also connect with:

```bash
psql $DATABASE_URL
```

---

## ⚙️ Commands Inside Dev Container

### Build

```bash
cargo build
```

### Run

```bash
cargo run
```

### Hot Reload

```bash
cargo watch -x run
```

> `cargo-watch` is pre-installed in the Dev Container.

---

## 🧪 Optional SQLx Setup

You can use `sqlx-cli` inside the container:

```bash
sqlx database setup
sqlx migrate run
```

---

## 🧼 Cleaning Up

To stop and clean all containers:

```bash
docker compose down
```

If the Dev Container fails due to missing network, recreate it:

```bash
docker network create pmi_network
```

---

## ✅ You’re All Set

You can now develop inside a fully containerized Rust environment with access to PostgreSQL, hot reload, and Git tooling.

# 🛠 Database Migrations (with `sqlx`)

## 📌 1. Add a New Migration

To create a new migration, use the `sqlx` CLI:

```
sqlx migrate add <migration_name>
```

This will create a new SQL file in the `migrations/` folder, timestamped automatically.

➡️ Example:
```
sqlx migrate add add-user-table
```

Then edit the generated `.sql` file to include your schema changes.

> ℹ️ Make sure the `DATABASE_URL` environment variable is set before running `sqlx` commands. You can define it in a `.env` file or export it manually.

---

## 🚀 2. Apply Migrations (when setting up the project)

After cloning the repository and setting up your `.env` file:

```
# Start services
docker compose up -d

# Enter the web container
docker exec -it pmi_web bash

# Run migrations
sqlx migrate run
```

This will apply all pending migrations to the connected PostgreSQL database.
