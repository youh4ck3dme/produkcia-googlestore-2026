# Google Play — App Access Notes

Copy-paste text for **Play Console → App content → App access**.

## Credentials

| Field | Value |
|-------|-------|
| **Username** | `bizagent@bizagent.sk` |
| **Password** | See local file `.play_reviewer_password` (do not commit to git) |

Generate or refresh credentials:

```bash
bash scripts/seed_play_reviewer_account.sh
cat .play_reviewer_password   # paste into Play Console only
```

## Instructions for Google reviewers (English)

Paste this into the **Instructions** field:

```text
Login method: Email and password on the first screen (no Google Sign-In required).

Username: bizagent@bizagent.sk
Password: [paste from .play_reviewer_password]

There are no hidden gestures or easter eggs in the release build. Demo mode (triple-tap) is disabled in production builds.

The account has pre-loaded sample data:
- 2 invoices (Invoices tab)
- 1 expense (Expenses tab)
- 1 in-app notification
- Business profile with sample IČO/DIČ (Settings)

Suggested review path:
1. Sign in with the credentials above
2. Open Invoices — verify 2 sample invoices
3. Open Expenses — verify 1 sample expense
4. Open AI Assistant (BizBot) — ask a tax or invoice question
5. Optional: Settings → view business profile

If login fails, ensure the device has internet access. The app requires Supabase backend connectivity for authentication.
```

## Play Console form

1. **All or some functionality is restricted?** → Yes
2. **Username:** `bizagent@bizagent.sk`
3. **Password:** *(from `.play_reviewer_password`)*
4. **Instructions:** *(block above)*

## Before each submission

- [ ] Run `bash scripts/seed_play_reviewer_account.sh` (idempotent)
- [ ] Verify sign-in with `./build_release_aab.sh` build on a real device
- [ ] Update Play Console password if you used `--force-password`

## Related

- [DEMO_ACCOUNT_SETUP.md](./DEMO_ACCOUNT_SETUP.md) — full setup guide
- [GOOGLE_PLAY_UPLOAD_CHECKLIST.md](../GOOGLE_PLAY_UPLOAD_CHECKLIST.md) — upload checklist
