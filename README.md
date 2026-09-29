# Shoot Renamer

Renames shoot assets in Google Drive to the convention
`YYMM_Shoot_Location_Subject_NN_Resolution.ext` without downloading anything.

One HTML file. No build, no server. Hosted on GitHub Pages.

## One-time setup

### 1. Google Cloud (about 10 minutes)

1. Go to https://console.cloud.google.com and create a new project (any name, e.g. `shoot-renamer`).
2. **APIs & Services → Library**, search "Google Drive API", click **Enable**.
3. **APIs & Services → OAuth consent screen**. User type: **External**. Fill app name and your email. Save.
   On the **Test users** step, add your own Google account. This keeps the app in testing mode, which is fine for personal use and avoids Google's verification process.
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**.
   Application type: **Web application**.
   Authorized JavaScript origins: add `https://YOUR-GITHUB-USERNAME.github.io`
   (and `http://localhost:8000` if you want to test locally).
   Create, then copy the **Client ID** (ends in `.apps.googleusercontent.com`).

### 2. GitHub Pages (about 5 minutes)

1. Create a new public repo, e.g. `shoot-renamer`.
2. Upload `index.html` and this README.
3. **Settings → Pages → Source: Deploy from a branch → main / root**. Save.
4. After a minute the tool is live at `https://YOUR-GITHUB-USERNAME.github.io/shoot-renamer/`.

### 3. First run

1. Open the page, click **Setup**, paste the Client ID. It is stored in your browser only.
2. Click **Sign in to Drive**. Google will warn the app is unverified because it is in testing mode. Click *Continue*.
3. Done. The token lasts an hour; click *Re-sign in* if calls start failing.

## Daily use

1. Fill **YYMM**, **Shoot**, and paste the shoot's root **Drive folder link**. Click **Load folder**.
2. Click a subfolder (iPhone, Images, Card 1...). The **Location** slot fills with the subfolder name. Edit it if needed.
3. Each card shows the thumbnail, real dimensions, orientation, and the auto-filled resolution suffix (long edge; `px` for images, `1080p` for 1920 videos). Edit per card if you want.
4. Type a subject in a card and press Enter to jump to the next card. Or tick several cards and click a subject chip to apply it to all of them. Chips remember every subject you have used.
5. Numbering per subject is automatic and continues from files already named in the folder.
6. Check the green preview names, then **Rename on Drive**. Files that already match the convention are greyed out and skipped.
7. **Export CSV** gives you the old → new mapping for the handover note.

## Notes

- Needs Editor access on the folder. Viewer or Commenter will fail on rename.
- Works on shared drives.
- Videos get a thumbnail once Drive has processed them; freshly uploaded ones may show "no preview" for a few minutes.
- The tool never downloads or modifies file contents, only the name.
