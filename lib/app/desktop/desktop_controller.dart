// Connects the window, system tray, and engine: closing hides to the tray, the
// tray shows/hides the window, toggles ARGB, and shuts down the app cleanly.
import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

import '../../core/engine/engine_host.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/strings_provider.dart';
import '../../core/persistence/config_store.dart';
import '../../features/lighting/lighting.dart';
import '../../features/preferences/preferences.dart';
import 'desktop_actions.dart';

const _trayIcon = 'assets/icons/tray.png';
const _trayIconOff = 'assets/icons/tray-off.png';

class DesktopController with WindowListener implements DesktopActions {
  DesktopController(this._container);

  final ProviderContainer _container;

  // Keep references alive: native objects are released by the GC.
  tray.TrayIcon? _tray;
  tray.Menu? _menu;
  tray.MenuItem? _windowItem, _argbItem, _quitItem;
  bool _quitting = false;

  @override
  bool get trayAvailable => _tray != null;

  /// Prepares the window and system tray. With [startMinimized], the window stays
  /// hidden (the GTK runner does not show it), unless no system tray exists.
  Future<void> init({required bool startMinimized}) async {
    await windowManager.setMinimumSize(const Size(1040, 680));
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    _setUpTray();
    // Rewrite the labels when the interface language changes.
    _container.listen(stringsProvider, (_, _) => _syncTrayLabels());
    _container.listen(
      lightingProvider.select((s) => s.argbOff),
      (_, off) => _syncArgb(off),
      fireImmediately: true,
    );
    if (startMinimized && !trayAvailable) await showWindow();
  }

  AppStrings get _strings => _container.read(stringsProvider);

  void _setUpTray() {
    try {
      if (!tray.TrayManager.instance.isSupported()) return;
      final icon = tray.TrayIcon.create();
      if (icon == null) return;
      icon.setTooltip('Lumivent');
      icon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
      icon.addListener((e) {
        if (e is tray.TrayIconClickedEvent) unawaited(toggleWindow());
      });

      tray.MenuItem item(
        String label,
        tray.MenuItemType type,
        void Function() onClick,
      ) {
        final it = tray.MenuItem.createWithLabelAndType(label, type)!;
        it.addListener((e) {
          if (e is tray.MenuItemClickedEvent) onClick();
        });
        return it;
      }

      final strings = _strings.shell;
      _windowItem = item(
        strings.hideWindow,
        tray.MenuItemType.normal,
        () => unawaited(toggleWindow()),
      );
      _argbItem = item(strings.turnOffAllArgb, tray.MenuItemType.checkbox, () {
        final lighting = _container.read(lightingProvider.notifier);
        lighting.setArgbOff(!_container.read(lightingProvider).argbOff);
      });
      _quitItem = item(
        strings.quit,
        tray.MenuItemType.normal,
        () => unawaited(quit()),
      );
      _menu = tray.Menu.create()!
        ..addItem(_windowItem)
        ..addItem(_argbItem)
        ..addSeparator()
        ..addItem(_quitItem);
      icon.setContextMenu(_menu);
      icon.setVisible(true);
      _tray = icon;
      unawaited(_syncWindowItem());
    } on Object catch (e) {
      // Without a system tray the app keeps running, but closing it exits.
      debugPrint('system tray unavailable: $e');
      _tray = null;
    }
  }

  void _syncArgb(bool off) {
    _argbItem?.state = off
        ? tray.MenuItemState.checked
        : tray.MenuItemState.unchecked;
    final image = tray.ImageAsset.fromAsset(off ? _trayIconOff : _trayIcon);
    if (image != null) _tray?.icon = image;
  }

  Future<void> _syncWindowItem() async {
    final visible = await windowManager.isVisible();
    final strings = _strings.shell;
    _windowItem?.label = visible ? strings.hideWindow : strings.showWindow;
  }

  /// Re-applies the catalog after a language change (labels are native state).
  void _syncTrayLabels() {
    if (_tray == null) return;
    final strings = _strings.shell;
    _argbItem?.label = strings.turnOffAllArgb;
    _quitItem?.label = strings.quit;
    unawaited(_syncWindowItem());
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> toggleWindow() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await showWindow();
    }
  }

  @override
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    windowManager.removeListener(this);
    await _container.read(engineProvider).shutdown();
    await _container.read(configStoreProvider).flush();
    _tray?.setVisible(false);
    _tray?.dispose();
    _tray = null;
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
    // destroy() closes the window and GtkApplication exits; this is only a safeguard.
    exit(0);
  }

  // ── WindowListener ──────────────────────────────────────────────────────

  @override
  void onWindowClose() {
    if (_container.read(preferencesProvider).closeToTray && trayAvailable) {
      unawaited(windowManager.hide());
    } else {
      unawaited(quit());
    }
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'show' || eventName == 'hide') {
      unawaited(_syncWindowItem());
    }
  }
}
