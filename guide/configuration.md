# Configuration and data

Where Lumivent keeps its files, how it reads and writes them, and the keys you
can edit by hand.

## Files

| Path | Contents |
|---|---|
| `~/.config/lumivent/config.json` | preferences, lighting and fans |
| `~/.config/lumivent/config.json.before-import` | backup taken before an import |
| `~/.config/lumivent/config.json.bad` | a corrupted file, preserved |
| `~/.local/share/lumivent/effects/<id>/` | imported effects |
| `~/.config/systemd/user/lumivent.service` | autostart unit, when enabled |

Paths follow `XDG_CONFIG_HOME` and `XDG_DATA_HOME`. Uninstalling the package
does not delete them.

## How the configuration file is handled

- **Atomic writes**: the app writes a temporary file and renames it.
- **Tolerant reads**: a missing key, a wrong type or an unknown value falls back
  to the default, so older or hand-edited files still open.
- **Corruption**: invalid JSON is renamed to `config.json.bad` (never silently
  overwritten) and the app starts with defaults.
- **Import**: replaces the preferences, lighting and fans sections in a single
  write, after copying the current file to `config.json.before-import`. Files
  from a newer schema version are refused. The import applies immediately, with
  no restart.

Close the app before editing `config.json` by hand; otherwise the next save
overwrites your changes. For backups, prefer **Configurações → Configuração →
Exportar…** (Settings → Configuration → Export…).

## Preferences

The `preferences` section:

| Key | Type | Default | Description |
|---|---|---|---|
| `closeToTray` | bool | `true` | closing the window only hides it to the tray |
| `temperatureUnit` | `"celsius"` \| `"fahrenheit"` | `"celsius"` | unit shown in the interface |
| `effectsFps` | `15` \| `30` \| `60` | `30` | frame rate of the lighting loop |
| `language` | `"en"` \| `"pt"` | `"en"` | interface language; missing or invalid values fall back to English |

## Environment variables

| Variable | Effect |
|---|---|
| `XDG_CONFIG_HOME`, `XDG_DATA_HOME` | change the data directories |
| `LUMIVENT_FANS_TRACE=1` | prints one line per fan loop cycle to `stderr` |
| `LUMIVENT_LIGHTING_TRACE=1` | prints timings and latencies of the lighting loop |
| `LUMIVENT_NVME_SMART` | alternative path to the SMART helper |
| `LUMIVENT_HTML_EFFECT_WORKER=isolate` | runs HTML effects in an isolate instead of a separate worker process (debugging) |
