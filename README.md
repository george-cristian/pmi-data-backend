## 🛠 Database Migrations (with `sqlx`)

### 📌 1. Add a New Migration

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

### 🚀 2. Apply Migrations (when setting up the project)

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
