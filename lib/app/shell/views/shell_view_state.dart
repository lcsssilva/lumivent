part of 'shell_view.dart';

class _ShellViewState extends ConsumerState<ShellView> {
  @override
  Widget build(BuildContext context) {
    // One notification per failed write: the provider emits a new event for
    // consecutive failures, and provider notifications reach the listener
    // without waiting for an unrelated frame or being dropped when a later
    // write succeeds first.
    ref.listen(configWriteFailuresProvider, (_, event) {
      if (event.value == null || !mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.strings.common.configWriteFailed)),
      );
    });
    final route = ref.watch(routeProvider);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: KeyedSubtree(
                      key: ValueKey(route),
                      child: _page(route),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _page(AppRoute route) => switch (route) {
    AppRoute.monitoring => const MonitoringView(),
    AppRoute.lighting => const LightingView(),
    AppRoute.fans => const FansView(),
    AppRoute.explore => const ExploreView(),
    AppRoute.settings => const SettingsView(),
  };
}
