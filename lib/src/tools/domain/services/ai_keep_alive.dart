import 'dart:async';

/// Re-emits [source] and, whenever it has been quiet for [every], also emits
/// [beat] (given how long it has been quiet). Lets a listener tell "still
/// working, just slow" from "stuck": a long model load or indexing run produces
/// no events of its own. The beats stop when the source ends.
Stream<T> keepAlive<T>(
  Stream<T> source, {
  required Duration every,
  required T Function(Duration quietFor) beat,
}) {
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? timer;
  final quiet = Stopwatch()..start();

  void arm() {
    timer?.cancel();
    timer = Timer(every, () {
      if (controller.isClosed) return;
      controller.add(beat(quiet.elapsed));
      arm();
    });
  }

  controller = StreamController<T>(
    onListen: () {
      arm();
      sub = source.listen(
        (event) {
          quiet
            ..reset()
            ..start();
          controller.add(event);
          arm();
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () {
      timer?.cancel();
      return sub?.cancel();
    },
  );
  return controller.stream;
}
