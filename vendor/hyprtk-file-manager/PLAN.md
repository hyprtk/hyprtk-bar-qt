# hyprtk-file-manager — Plan

A file manager for the hyprtk desktop suite.
Qt/QML front end, Python backend. Simplistic in view, deep when invoked.

Status: v1.1.3 complete (2026-11-09) — Trash empty + tray toggle; power pass next
Owner: Kori Tk (hyprtk)
Location: `/home/hyprtk/Projects/AI-Projects/hyprtk-file-manager/`
Planned vendoring: `hyprtk-merged/installer/hyprtk-file-manager/` → `dotfiles` + live via `push-all`

---

## 0. M0 delivered (2026-11-09)

Spike harness in `spike/` (full results in `spike/RESULTS.md`):

- `bench_listing.py` — stage timings for 10k/50k directories.
- `rpc_server.py` — JSON-lines `ping` + paged `list` backend.
- `shell.qml` / `Main.qml` — Quickshell `FloatingWindow` end-to-end harness.
- `check_env.sh` — dependency, thumbnail, trash, and volume probe.

Measured on this machine (NVMe):

- 10k listing: 4.7 ms names, 6.8 ms +sort, 32.7 ms +stat-all.
- 200-row page: 7.3 ms backend at 10k, 40.2 ms at 50k, 21.8 KB JSON.
- End-to-end QML<->Python: 10k full window **85 ms**; 50k full window **400 ms**.
- `gio trash` + restore round-trip: OK. `udisksctl` volumes: OK. `bsdtar`/`7z`: OK.
- Thumbnails: vips (image) OK, pdftoppm (PDF) OK, ffmpeg (video fallback) OK.
- Missing tools with fallbacks: `fd` (use `rg --files`), `ffmpegthumbnailer`
  (use `ffmpeg`), `exiftool` (use `file` + Python).

Decisions locked: **Quickshell + Python backend**; **paged model** (200–500 rows),
per-directory sorted-name cache with inotify invalidation, async thumbnails,
optional external tools only. Drag-and-drop is the one unverified item (manual
test in M1).

---

## 0.1 M1 delivered (2026-11-09)

Core browser shipped and verified.

- Backend `backend/hyprtk_file_manager/`: paged listing with per-directory cache,
  places / bookmarks / drives, JSON-lines RPC, CLI, launcher.
- QML: `FloatingWindow` main window, per-pane tabs, breadcrumb + `Ctrl+L` path
  entry, list / grid / compact views, single and dual pane, sidebar, status bar.
- Selection: click, Ctrl-toggle, Shift-range, keyboard cursor/open; marquee deferred.
- Icons: Papirus via `QT_QPA_PLATFORMTHEME=gtk3`, set by the launcher (without it
  Qt has no icon theme and the provider returns a placeholder).
- Verified with `wtype`: path entry, navigation, new tab, hidden toggle; list /
  grid / dual screenshots. Real RPC at 10k entries: 47 ms first page, then
  **0.95–2.6 ms** cached pages (300 rows).
- 23 unit tests pass; installer round-trips (install + uninstall) in a temp HOME.

Carried forward: marquee selection, live inotify refresh, drag-and-drop manual
test, settings persistence, and the M2 operation engine.

---

## 0.2 M2 delivered (2026-11-09)

File operations shipped and verified.

- Backend job engine (`ops.py`): worker threads, stdin-safe event streaming,
  per-item progress, cancel, and partial-failure reporting.
- Operations: copy (recursive, symlink-safe), move, trash (`gio`), permanent
  delete, rename, new folder, new file.
- Conflicts: replace / skip / keep both / apply-to-all, with a modal dialog and
  `R` / `S` / `K` / `A` shortcuts.
- Multi-level undo for copy, move, trash, rename, mkdir, and new file; persisted
  journal at `~/.local/state/hyprtk-file-manager/journal.json`.
- Task tray with progress and cancel; finished jobs prune after 8 s.
- Clipboard copy/cut/paste across tabs and panes; `Ctrl+C/X/V`, `Ctrl+A`, `F2`,
  `Ctrl+Shift+N`, `Ctrl+Alt+N`, `Ctrl+Z`, `Delete` / `Shift+Delete`; right-click
  context menu and toolbar overflow menu.
- Safety: permanent delete is confirmed, copy-onto-self with Replace is a no-op,
  and destinations inside a source are rejected.
- Verified with `wtype` on the home filesystem: rename, trash, undo, copy,
  conflict keep-both, new folder, paste, delete, undo, and permanent-delete
  confirmation. 42 unit tests pass.

Notes: `gio trash` follows the XDG spec and refuses system-internal mounts such
as `/tmp`; the error surfaces in the task tray. Redo and batch rename deferred.

---

## 0.3 M3 delivered (2026-11-09)

Inspect and find shipped and verified.

- Quick Look preview panel (`Space`): image / video / PDF thumbnails via
  `vipsthumbnail` / `ffmpeg` / `pdftoppm`, text preview, and metadata; graceful
  fallback to metadata when a renderer is missing.
- Async `preview` and `search` RPC so long operations never block the UI.
- Instant filename filter (`Ctrl+F`) with a 150 ms debounce and paged results.
- Recursive search panel (`Ctrl+Shift+F`): name search (`os.walk`) and content
  search (`rg --json`, path + line + line number); `Ctrl+1` / `Ctrl+2` switch
  mode. Activating a result reveals it in the folder.
- Command palette (`Ctrl+K`) with fuzzy matching over 26 actions.
- Batch rename dialog: find/replace, prefix/suffix, numbering, case, live
  preview, and undo; backend validates collisions and duplicate targets.
- `Space` now opens Quick Look; `Ctrl+Space` toggles selection.
- 55 unit tests pass; verified with `wtype` (preview, filter, batch rename +
  undo, name/content search, palette → grid).

Notes: name search walks the tree and does not honour `.gitignore`; content
search uses ripgrep and does. Preview thumbnails are cached on path+mtime+size.

---

## 0.4 M4 / v1.0 delivered (2026-11-09)

First release shipped.

- Settings persist to `~/.config/hyprtk-file-manager/config.json` (view, sort,
  hidden, icon size, dual pane, preview) with debounced atomic writes.
- Session restore: per-pane tabs, active tab, history, and paths persist to
  `~/.local/state/hyprtk-file-manager/session.json`.
- Live directory refresh via inotify, one watcher per pane, throttled and
  debounced; external file drops copy into the current folder.
- `scripts/qa.sh`: 60 unit tests, compile + shell syntax, 10k performance gate,
  installer install/uninstall round-trip.
- `scripts/perf.py`: 10k first page **44.9 ms** (budget 300), cached page
  **0.8 ms** (budget 50).
- `QA.md`: the v1.0 QA matrix and known gaps.
- Verified with `wtype` + screenshots: settings persisted (grid), live inotify
  addition, session restored on relaunch (two tabs, `sub` path, grid view).
- Release tag deferred: the project is not a git repository yet.

Deferred to v1.1: marquee selection, internal pane-to-pane drag and drag-out,
redo, properties/permissions/checksum dialogs.

---

## 0.5 v1.1 gap fixes delivered (2026-11-09)

Closed the four v1.0 gaps.

- Multi-level redo (`Ctrl+Shift+Z`), persisted with the journal; a new operation
  clears the redo stack. Copy redo re-copies from the source; move / trash /
  rename / mkdir / newfile re-apply with preconditions.
- Marquee selection in list and grid: drag empty space, `Shift`+drag from an
  entry, `Ctrl` adds to the current selection.
- Internal pane-to-pane drag moves the selection; drag-out exposes
  `text/uri-list`; external drops copy into the current folder.
- Properties dialog (`Alt+Return`): type, size, owner/group, times, inode,
  symbolic + octal permissions (`chmod`), and a SHA-256 checksum.
- Redo and Properties added to the context menu and command palette.
- 74 unit tests; the QA gate still passes.

Mouse gestures (marquee, drag) could not be automated in this session because
`/dev/uinput` is root-only; they are implemented against Qt Quick drag/drop
semantics and verified to load cleanly. Manual gesture check recommended.

---

## 0.6 v1.1.1 fixes delivered (2026-11-09)

Fixes from first-run testing.

- Dual pane: a pane activates on press; `Tab` switches panes; copy/cut/paste
  across panes verified with the real UI.
- Empty-area right-click opens the context menu; row right-click unchanged.
- Context menu gained **Open Terminal Here** and **Open as Root** (pkexec with
  the Wayland environment forwarded); the terminal resolver prefers
  `$TERMINAL`, Alacritty, kitty, foot, then WezTerm.
- Internal drag carries `application/x-hyprtk-fm-paths` so the target resolves
  the move from MIME data rather than drag timing.
- Properties gained **Make executable** (`0111`, `Ctrl+E`); the octal field syncs
  after `chmod`.
- 77 unit tests; dual copy/paste and make-executable verified end-to-end.

---

## 0.7 v1.1.2 fixes delivered (2026-11-09)

- Drag/drop switched to Qt's Automatic platform drag (cross-pane), with
  `preventStealing` so the ListView no longer steals the drag. A drop activates
  the target pane, refreshes it, and selects/reveals the dropped file.
- Trash: sidebar place, **Open Trash** and **Restore from Trash** in the context
  menu and palette; restore reads `.trashinfo` and moves the file back.
- 79 unit tests; Trash view verified in the real UI; drop move verified in the
  journal (Downloads -> Music) and target reveal added.

---

## 0.8 v1.1.3 delivered (2026-11-09)

- Empty Trash: sidebar right-click, Trash view menu, palette, and
  `Ctrl+Shift+E`; confirmation dialog; runs as a job (`gio trash --empty`) so
  the tray reports progress and panes refresh.
- Transfers tray can be hidden/shown: `Ctrl+J`, tray Hide button, pane context
  menu, and palette; the setting persists.
- 81 unit tests.

---

## 1. Brief

| | |
|---|---|
| **Goal** | A daily-driver file manager that feels clean like Nautilus but keeps the power of Dolphin/Yazi one shortcut away. |
| **User and task** | hyprtk desktop users (distro default). Everyday task: find, preview, move, rename, and clean up files without leaving the keyboard or the desktop's look. |
| **Deliverables** | One app: browser window, preview panel, task queue, command palette, settings, installer, desktop entry, `hyprtk-fm` CLI. |
| **Lead** | The file listing. Everything else is quiet chrome around it. |
| **Content reality** | Zero files (empty folder), one file, 10,000 files, 400 GB directories, long unbreakable names, unicode/RTL filenames, permission-denied paths. |
| **Irreversible** | Delete (trash by default), permanent delete, overwrite, move across filesystems. All confirmed with a danger variant; all undoable where physically possible; failure states are explicit. |
| **Theme** | Existing hyprtk theme — live pywal via `Theme.qml`, dark first, light supported. Papirus icons. |
| **Platform floor** | Wayland/Hyprland on x86-64; Qt 6 + Quickshell already in the suite; Python 3.10+. |
| **Out of scope (v1)** | Cloud providers, cross-device libraries, network file drop, plugin marketplace, version history, semantic/AI search. |
| **Done when** | Core ops pass the safety + undo test suite, 10k-file directory meets the performance budget, `install.sh` is clean on a fresh Arch/Mint/Fedora container, and the manual QA matrix passes. |

---

## 2. Why this exists

Every Linux file manager picks a side. Nautilus chose clean-but-limited; Dolphin
chose powerful-but-busy; Yazi chose fast-but-terminal-only. The hyprtk desktop has
no file manager tuned to its own theme, keybind philosophy, or power-user needs —
Thunar is the practical default, and it shows.

The gap: **a clean single-pane default that does not punish power users.** The
advanced surface lives behind shortcuts, a command palette, and a preview/task
panel — not in the first screenful.

## 3. Research digest (2026)

| Manager | Strength worth borrowing | Weakness to avoid |
|---|---|---|
| Dolphin | Split view, tabs, embedded terminal, service menus, remote mounts | Dense UI; KDE dependency weight |
| Nemo | Dual pane, tree sidebar, open-as-root, scripts menu | Aging visual language |
| Thunar | Lightweight, best-in-class bulk renamer, custom actions | Feature-thin, basic search |
| Nautilus | Cleanest layout, search-first | Removed the features people wanted |
| Krusader / Double Commander | Twin-pane, archive depth, compare/sync | 2005 UI, steep learning curve |
| Yazi | Async I/O, instant fd/rg search, previews, cancellable task queue | Terminal-only, Vim tax |
| Spacedrive | Tags, libraries, modern UI, cross-device | Heavy, alpha-quality edges |
| New indie FMs (Commander, WhimFiles, Iruka, Furman, manycommander) | Every one converges on: undo, batch rename with preview, dual pane, command palette, archive-as-folder, terminal, compare | Fragmentation, licensing, single-maintainer risk |

**Convergent wishlist (ranked).** This is the feature list the plan is built from.

1. Async listing that never freezes
2. Tabs + back/forward/up + breadcrumb + `Ctrl+L`
3. Single/dual pane, drag and drop, marquee select
4. Core ops with conflict dialog, progress, cancel
5. Thumbnails + Quick Look (Space)
6. Sidebar places/volumes/bookmarks, hidden toggle
7. Keyboard-first + command palette
8. Trash, open-with, properties, permissions
9. Live pywal theming
10. **Undo for file operations** (the most-requested missing feature)
11. **Batch rename** with live preview and undo
12. **Instant filter + fd/rg search**, act on results
13. **Archive-as-folder**
14. **Integrated terminal that follows the cwd**
15. Session/tab restore and per-tab history
16. **Tags/smart folders**
17. Compare, checksums, duplicate finder, disk-usage treemap
18. **Git status badges**
19. **Custom scripts/actions**
20. Remote/cloud (deferred)

## 4. Scope

Selected advanced features (all on the roadmap; sequencing resolved below):
undo, batch rename, dual pane + tabs, rich previews, archive-as-folder,
integrated terminal, tags + smart folders, git badges, command palette, custom
scripts.

### v1.0 — Focused MVP (ship first)

The essentials that make it usable as a daily driver:

- [x] Async listing/model (virtualized), never blocks
- [x] Views: icon grid, details list, compact; sort; hidden toggle
- [x] Single pane default, optional dual pane
- [x] Tabs, history, breadcrumb + `Ctrl+L` path entry
- [x] Selection: click, ctrl/shift (marquee still pending)
- [x] Core ops: copy, move, trash, delete, rename, new folder/file
- [x] Conflict dialog: replace / skip / keep both / apply-to-all
- [x] Task queue: progress, cancel, partial-failure report
- [x] **Multi-level undo** of move/copy/trash/rename
- [x] **Batch rename** with find/replace, numbering, prefix/suffix, case, live preview
- [x] **Quick Look / preview panel**: image, video, PDF, text, code, metadata
- [x] Instant filename filter + optional ripgrep content search
- [x] **Command palette** over every action
- [x] Places sidebar, volumes (UDisks2), bookmarks
- [ ] Open-with done via `xdg-open`; properties, permissions, checksums still open
- [x] pywal theme, dark/light, Papirus icons

### v1.1 — Power pass

- [ ] **Archive-as-folder** (zip/tar/7z browse) + extract/create
- [ ] **Integrated terminal** that follows the cwd
- [ ] **Tags/color labels + smart folders** (saved searches)
- [ ] **Git status badges** + diff preview
- [ ] **Custom scripts/actions** + extension surface
- [x] Session/tab restore (landed in v1.0 / M4)
- [ ] File/folder compare, duplicate finder, disk-usage treemap
- [x] Marquee selection; internal pane-to-pane drag; drag-out (manual gesture check pending)
- [x] Redo stack
- [x] Properties / permissions / checksum dialogs
- [ ] Open-as-root (pkexec), if demanded

### v2 — Ambitious

- [ ] Remote panels: SFTP/SMB; MTP devices
- [ ] Cloud/virtual libraries, LAN drop
- [ ] Optional local-LLM tagging/search (the suite already has `llm-*`)

### Explicit non-goals for v1
Cloud, cross-device sync, semantic search, plugin marketplace, version history,
desktop icons, browser/web integration, macOS/Windows ports.

## 5. UX principles

1. **One thing leads** — the listing is the hero; chrome stays quiet.
2. **Simple surface, deep keyboard** — every action has a binding and a palette entry.
3. **Nothing surprises the user's data** — trash by default, confirm destructive,
   never silently overwrite, undo whenever physically possible.
4. **Panels, not dialogs** — preview and tasks dock at the edge; dialogs only for
   destructive or multi-field decisions.
5. **The desk's look** — colors come from the live theme; no hardcoded palette.
6. **Never block** — listing, thumbnails, search, and file ops are all async.

## 6. Architecture

Suite match: Quickshell QML front end + toolkit-free Python backend, same shape
as `hyprtk-bar-qt` and `config-manager`.

```
shell.qml                      Quickshell entry — normal toplevel window
surface/
  MainWindow.qml               toolbar + path bar + split view + status
  BrowserView.qml              one pane: model, selection, drag/drop
  Sidebar.qml                  places, volumes, bookmarks, tags
  PathBar.qml                  breadcrumb <-> editable path
  PreviewPanel.qml             Quick Look dock
  TasksPanel.qml               operation queue + progress + cancel
  CommandPalette.qml           fuzzy action runner
  Settings.qml                 config panel
  dialogs/
    Conflict.qml               replace/skip/keep both/apply-to-all
    BatchRename.qml            live preview + undo
    Properties.qml  Permissions.qml
components/                    buttons, rows, glass panels, icons
theme/Theme.qml                singleton: live pywal + Qt config colours
config/Config.qml              singleton: own settings
data/Files.qml                 model bridge to backend (paged/streaming)
data/Tasks.qml                 operation queue state
data/Places.qml                mounts/volumes/bookmarks
backend/hyprtk_file_manager/
  listing.py                   scandir streaming, stat batching, sort, filter
  ops.py                       copy/move/trash/delete/rename engine
  journal.py                   persistable undo/redo journal
  conflicts.py                 resolution policy
  preview.py                   MIME sniff, thumbnails, text/code, metadata
  search.py                    incremental filter + fd/rg adapters
  archives.py                  archive read/extract (v1.1)
  places.py                    XDG dirs, bookmarks, GIO mounts, UDisks2
  tags.py                      labels + smart folders (v1.1)
  gitinfo.py                   status badges (v1.1)
  theme.py                     pywal color export
  rpc.py / server.py           JSON-RPC bridge
  cli.py                       `hyprtk-fm` open/version
tests/                         unit + integration on temp dirs
```

**Data flow.** QML <-> Python over JSON-lines RPC on stdio (proven in M0). The
model holds only a page (200-500 rows); the backend caches the sorted name list
per directory and invalidates it on inotify. `stat` is done only for the visible
window. File ops run in a worker pool and report progress events; the UI never
blocks.

**Performance budget.** First paint < 150 ms; 10k-file directory listed < 300 ms;
scroll at 60 fps; thumbnails async + cached; copy/move never on the UI thread.

**Safety model.** Trash by default via GIO; permanent delete behind confirmation;
operations journaled so undo can restore trashed items and reverse moves/copies;
conflicts always explicit; partial failures leave a clear report, never a silent
half-state.

**Packaging.** `install.sh` (no root) installs to
`~/.local/share/hyprtk-file-manager`, links `hyprtk-fm`, registers a desktop entry
and `inode/directory` association. Vendored into merged and shipped by `push-all`.
The launcher exports `QT_QPA_PLATFORMTHEME=gtk3` when unset so Qt resolves the
GTK icon theme (Papirus); without it every icon falls back to a placeholder.

## 7. Milestones

- **M0 — Spike (1-2 days).** Prove the risky bits before building:
  Quickshell normal-window + JSON-RPC throughput with a 10k listing; thumbnail
  dependency availability (vips/ffmpeg/poppler) with graceful fallback; GIO trash
  round-trip; Wayland internal/external drag-and-drop. Decide model strategy.
  Fallback if IPC latency fails: PySide6 in-process Qt Quick with the same QML.
- **M1 — Core browser.** Listing/model, views, tabs, single/dual pane, path bar,
  selection, sidebar, theming. Accept: browse a 10k dir within budget. — done
  2026-11-09 (47 ms first page, 0.95–2.6 ms cached pages).
- **M2 — Operations.** Copy/move/trash/delete/rename, conflict dialog, task queue,
  **journal + undo**. Accept: full op matrix + undo round-trips on temp dirs. —
  done 2026-11-09 (42 tests, verified end-to-end with `wtype`).
- **M3 — Inspect & find.** Previews/Quick Look, instant filter, rg search,
  command palette, batch rename. — done 2026-11-09 (55 tests, verified with
  `wtype`).
- **M4 — Ship v1.0.** Settings, session basics, installer, desktop entry, QA
  matrix, performance regression script. Tag v1.0. — done 2026-11-09 (tag
  deferred: not a git repo yet).
- **M5 — v1.1 power pass** (archives, terminal, tags/smart folders, git, scripts,
  compare/dupes/disk usage).

## 8. Risks and open questions

- **Quickshell vs in-process Qt Quick** — resolved in M0: `qs` IPC passes the 10k
  budget (85 ms end-to-end). Guardrail: always page, never dump a whole directory.
- **Undo of cross-filesystem moves** — may degrade to "re-move" with a notice.
- **Partial failures** — modelled per item; errors surface in the task tray.
- **Trash scope** — `gio trash` follows the XDG spec and refuses system-internal
  mounts (e.g. `/tmp`); the job reports the failure instead of dropping it.
- **Redo** — undo is multi-level; redo is deferred.
- **Thumbnail deps vary by distro** — fallback chain, never a hard dependency.
- **External drag-and-drop on Wayland** — verify early; offer copy-to-clipboard.
- **Permission-denied paths** — show them, do not hide them silently.
- **Archive writes** — v1.1 read/extract first; create later.
- **i18n** — strings centralized from day one, translations deferred.
- **Root actions** — pkexec flow deferred unless requested.

## 9. Testing / done-when

- `make test` (unittest): listing/sort/filter, conflicts, journal/undo, ops on temp trees.
- Integration: copy/move/trash/rename matrices, undo round-trips, permission-denied,
  symlinks, sparse/large files, unicode names.
- Performance: benchmark script asserts the budget on a synthetic 10k directory.
- QML smoke: `qs` launch + core flows.
- Manual QA matrix: empty/one/many, long names, RTL, removable volumes, drag-drop.
- Installer gate: clean `install.sh` on Arch/Mint/Fedora containers.

## 10. Assumptions

- **Focused MVP wins over feature-completeness.** All selected power features are
  delayed, not dropped; v1.0 ships the input-critical set.
- **Single-pane default** is the right read of "simplistic in view"; dual pane is
  a toggle, not the first impression.
- **Trash-by-default** is mandatory for a distro-default app.
- **Local-only v1** keeps the backend small; mounts come after the core is solid.
- **No index** — fd/rg is fast enough and avoids a daemon; revisit only if users
  demand full-text across the whole disk.
- **Suite theming** means pywal live colors, not a bespoke palette.

## Vendoring (2026-11-10)

Vendored into `hyprtk-merged/installer/hyprtk-file-manager/` and installed by
`1-install.sh` after the bar and config-manager. The suite uses it as the
default file manager: `Super+F`, the XDG `inode/directory` default, and the
bar's **Files** quick link, with Thunar kept as a fallback. The session exports
`FILEMANAGER=hyprtk-fm`. This standalone tree remains the source; re-vendor
after changes (rsync excluding `spike/`, caches, `.git`). `push-all` carries the
vendored copy to dotfiles + live.

## Sidebar 1.2.0 (2026-11-10)

Reworked the sidebar to match Thunar's model:

- **Places** = default XDG places + GTK bookmarks (shared with Thunar). Add via
  the sidebar `+` or the pane's **Add to Places**; remove custom entries from
  the right-click menu.
- **Devices** = `lsblk` volumes (mounted and unmounted, USB detection). Click a
  mounted device to open it; click an unmounted one to mount via `udisksctl`.
- **Network** = click the Network header to scan the local `/24` (TCP ports
  445/139/2049/548) plus Avahi service discovery. SMB/NFS/AFP hosts are listed;
  guest SMB shares are expanded. Clicking a host/share mounts through GVfs and
  navigates to the GVfs mount point.
- The old Bookmarks group is folded into Places; the old Drives list is replaced
  by Devices.
- 91 tests. Network scan/shares mount paths are best-effort: NFS exports need
  `showmount`, and SMB shares may prompt for credentials.

## Sidebar 1.2.1 (2026-11-10)

- Devices filters `/etc/fstab` (and `/etc/fstab.d/*`) volumes by mountpoint,
  `/dev` path, UUID, LABEL, PARTUUID, and PARTLABEL; fstab auto-mounts no longer
  clutter Devices.
- Network locations open a credentials dialog (username / password / workgroup
  or domain, plus Guest). The mount uses Gio's `MountOperation` so GVfs does not
  prompt separately; failures surface in the sidebar.
- 94 tests.

## Sidebar 1.2.2 (2026-11-10)

- Hide internal, non-removable volumes when unmounted; keep external USB/MMC and
  mounted volumes. `rm`/`tran` inherited from the parent disk so unmounted USB
  drives still appear with a mount action.
- 96 tests.

## Sidebar 1.2.3 (2026-11-10)

- File System (root) row in Devices, like Thunar.
- Eject icon on mounted external rows; right-click Eject Media; unmount then
  power-off (warning tolerated), and leave the mount if browsing it.
- Section headings left-aligned to the sidebar edge.
- 100 tests.

## Sidebar 1.2.4 (2026-11-10)

- Eject unmounts only; the external device remains in Devices as an inactive
  row with a mount action. No power-off/removal.

## Sidebar 1.2.5 (2026-11-10)

- Remove the Places **+** button; Add to Places remains in the folder context menu.

## Sidebar 1.2.6 (2026-11-10)

- All section headings use the same 8px left inset; Places/Network align with
  Devices.

## Sidebar 1.2.7 (2026-11-10)

- Section headings at 16px, matching the row icon inset.

## Sidebar 1.2.8 (2026-11-10)

- Heading inset via `leftPadding` (positioners ignore child `x`) so all section
  headings align at 16px with row icons.
