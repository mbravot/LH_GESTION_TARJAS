import 'dart:async';

class LoadingManager {
  static final LoadingManager _instance = LoadingManager._internal();
  factory LoadingManager() => _instance;
  LoadingManager._internal();

  final List<String> _loadingQueue = [];
  bool _isProcessing = false;
  final Map<String, Completer<void>> _completers = {};

  /// Agregar una tarea de carga a la cola
  Future<void> addToQueue(String taskName, Future<void> Function() task) async {
    // Si ya está en la cola, esperar a que termine
    if (_loadingQueue.contains(taskName)) {
      if (_completers.containsKey(taskName)) {
        return _completers[taskName]!.future;
      }
    }

    _loadingQueue.add(taskName);
    final completer = Completer<void>();
    _completers[taskName] = completer;

    // Procesar la cola si no está siendo procesada
    if (!_isProcessing) {
      _processQueue(task);
    }

    return completer.future;
  }

  /// Procesar la cola de carga secuencialmente
  Future<void> _processQueue(Future<void> Function() task) async {
    if (_isProcessing || _loadingQueue.isEmpty) return;
    
    _isProcessing = true;

    while (_loadingQueue.isNotEmpty) {
      final taskName = _loadingQueue.removeAt(0);
      
      try {
        // EJECUTAR LA TAREA REAL
        await task();
        
        // Completar la tarea
        if (_completers.containsKey(taskName)) {
          _completers[taskName]!.complete();
          _completers.remove(taskName);
        }
      } catch (e) {
        if (_completers.containsKey(taskName)) {
          _completers[taskName]!.completeError(e);
          _completers.remove(taskName);
        }
      }
    }

    _isProcessing = false;
  }

  /// Limpiar la cola (útil para logout)
  void clearQueue() {
    _loadingQueue.clear();
    for (final completer in _completers.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _completers.clear();
    _isProcessing = false;
  }
}
