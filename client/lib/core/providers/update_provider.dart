import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  noUpdate,
  downloading,
  downloadSuccess,
  error
}

class UpdateState {
  final UpdateStatus status;
  final UpdateInfo? updateInfo;
  final double downloadProgress;
  final String? localApkPath;
  final String? errorMessage;

  UpdateState({
    required this.status,
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.localApkPath,
    this.errorMessage,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateInfo? updateInfo,
    double? downloadProgress,
    String? localApkPath,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      localApkPath: localApkPath ?? this.localApkPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _service = UpdateService();

  UpdateNotifier() : super(UpdateState(status: UpdateStatus.idle));

  // Triggers update check process
  Future<void> checkForUpdates() async {
    state = state.copyWith(status: UpdateStatus.checking);
    try {
      final info = await _service.checkForUpdate();
      if (info != null) {
        state = state.copyWith(status: UpdateStatus.updateAvailable, updateInfo: info);
      } else {
        state = state.copyWith(status: UpdateStatus.noUpdate);
      }
    } catch (e) {
      state = state.copyWith(status: UpdateStatus.error, errorMessage: e.toString());
    }
  }

  // Starts direct download of update asset
  Future<void> startDownload() async {
    final info = state.updateInfo;
    if (info == null) return;

    state = state.copyWith(status: UpdateStatus.downloading, downloadProgress: 0.0);
    try {
      final path = await _service.downloadApk(info.downloadUrl, (progress) {
        state = state.copyWith(downloadProgress: progress);
      });
      state = state.copyWith(status: UpdateStatus.downloadSuccess, localApkPath: path);
    } catch (e) {
      state = state.copyWith(status: UpdateStatus.error, errorMessage: e.toString());
    }
  }

  // Opens/Installs local APK
  Future<void> installUpdate() async {
    final path = state.localApkPath;
    if (path == null) return;
    try {
      await _service.installApk(path);
    } catch (e) {
      state = state.copyWith(status: UpdateStatus.error, errorMessage: e.toString());
    }
  }
  
  // Resets updater status back to idle (allows dismissing)
  void dismissUpdate() {
    state = UpdateState(status: UpdateStatus.idle);
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier();
});
