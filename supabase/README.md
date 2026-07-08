# World Cup Supabase Setup

1. Create a Supabase project.
2. Run the setup command from the project root:

```bash
npm run setup:supabase
```

The script asks for:

- Supabase access token
- Database password
- Optional football-data.org API token

It pushes migrations and deploys the `sync-football-data` Edge Function.

If the database is already set up and you only need to add or rotate the football-data.org token:

```bash
npm run setup:football-api
```

3. Copy the project URL and anon public key from **Project Settings > API**.
4. Create `.env` in the project root:

```bash
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

5. Restart the Astro dev server.
6. Open `/worldcup`.

Login:

- Participants: enter a name and any 4-digit PIN. The first login claims an empty slot, and the same name/PIN logs in again later.
- Operations account: use `관리자` with PIN `0000`. There is no separate admin button in the UI.

The app falls back to browser localStorage when Supabase env vars are empty.
