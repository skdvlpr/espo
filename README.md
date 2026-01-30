# EspoCRM Development Environment

This project is configured for collaborative development using [DDEV](https://ddev.com/).
It includes automated setup scripts to ensure every developer has a working environment immediately after cloning.

## Quick Start (For Developers)

1. **Clone the repository:**

   ```bash
   git clone <repo-url>
   cd <repo-dir>
   ```

2. **Start DDEV:**

   ```bash
   ddev start
   ```

   _This command will automatically:_
   - Create valid `data/config-internal.php`
   - Import the initial database (if your DB is empty)
   - Rebuild the system
   - Ensure the admin user exists

3. **Launch the site:**

   ```bash
   ddev launch
   ```

   **Login Credentials:**
   - **Username:** `admin`
   - **Password:** `toor`
   - _(If this is a fresh install and these don't work, try running `ddev exec php bin/command create-admin-user admin` and `ddev exec php bin/command set-password admin` manually, but the script should handle it.)_

## Project Structure

- `.ddev/` - DDEV configuration and automation scripts.
  - `init-espo.sh` - Initialization script run on `post-start`.
  - `init-db.sql.gz` - Initial database dump (imported automatically if DB is empty).
- `custom/` - Place for your custom EspoCRM code.

## Database Management

Each developer has their own local database.

- **To reset your database to the shared initial state:**

  ```bash
  ddev delete -y --omit-snapshot
  ddev start
  ```

- **To update the shared initial database (e.g. after schema changes):**
  ```bash
  ddev export-db --file=.ddev/init-db.sql.gz --gzip=true
  git add .ddev/init-db.sql.gz
  git commit -m "Update initial database dump"
  git push
  ```

## Troubleshooting

- **Error 500 / Bad Response:** Usually means `data/config-internal.php` is missing. Run `ddev restart` to trigger the fix script.
